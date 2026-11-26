extends Node
## Kiểm thử v1.2.8:
##   1) Random 10 chương kiểu Soul Knight (Cổ Đại -> Trung Đại -> Cận Đại, không trùng 10 chương đầu)
##   2) Tỉ lệ rơi vũ khí hiếm chuẩn (Huyền thoại Cấp 5 rất hiếm, không tràn lan)
##   3) Phòng rộng 29x21, vật cản phá được / không phá được + bẫy ngẫu nhiên giữa các phòng
##   4) Thùng thuốc nổ & Đài Chiến Thắng ở Boss màn 9 (3-3)

const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const LobbyLife = preload("res://scripts/game/lobby_life.gd")
const TEST_SAVE := "user://dungeon_rework_test_save.json"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", TEST_SAVE.get_basename() + "_run.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(func():
		print("DUNGEON REWORK TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	_wipe()
	if _fail == 0:
		print("DUNGEON REWORK TEST OK")
		get_tree().quit(0)
	else:
		print("DUNGEON REWORK TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	Global.coins = 100
	Global.unlocked = ["hai_ba_trung"]
	Global.selected_hero = "hai_ba_trung"
	Global.save_game()

	print("== 1. Kiểm tra Random 10 chương kiểu Soul Knight")
	for trial in 10:
		Global.start_run()
		var c0: int = Global.chapter_at(0)
		var c1: int = Global.chapter_at(1)
		var c2: int = Global.chapter_at(2)
		_check(c0 in [0, 1, 2], "chương 1 phải thuộc Cổ Đại (nhận %d)" % c0)
		_check(c1 in [3, 4, 5, 6], "chương 2 phải thuộc Trung Đại (nhận %d)" % c1)
		_check(c2 in [7, 8, 9], "chương 3 phải thuộc Cận Đại (nhận %d)" % c2)
		var uniq := {}
		for ci in 10:
			uniq[Global.chapter_at(ci)] = true
		_check(uniq.size() == 10, "10 chương đầu không được trùng: %s" % str(Global.chapter_order.slice(0, 10)))
	_check(EnemyData.stage_chapter_num(1) == 1 and EnemyData.stage_chapter_num(5) == 1 and EnemyData.stage_chapter_num(15) == 3, "stage_chapter_num lịch sử sai")
	_check(EnemyData.stage_chapter_num(17) == 4 and EnemyData.stage_chapter_num(31) == 6 and EnemyData.stage_in_chapter(16) == 6, "stage Thần Thoại / 3-6 sai")

	print("== 2. Kiểm tra tỉ lệ rơi vũ khí hiếm (Huyền thoại Cấp 5)")
	seed(202611)
	var t_counts_lv1: Array[int] = [0, 0, 0, 0, 0, 0]
	for _i in 2000:
		var w1: String = WeaponData.roll(1, 0)
		var tier1: int = int(WeaponData.DATA[w1].tier)
		t_counts_lv1[tier1] += 1
	var pct_t5_lv1: float = float(t_counts_lv1[5]) / 2000.0 * 100.0
	var pct_low_lv1: float = float(t_counts_lv1[1] + t_counts_lv1[2]) / 2000.0 * 100.0
	print("   lv1 bonus=0 (2000 lần): T1=%d T2=%d T3=%d T4=%d T5=%d (%.2f%%)" % [t_counts_lv1[1], t_counts_lv1[2], t_counts_lv1[3], t_counts_lv1[4], t_counts_lv1[5], pct_t5_lv1])
	_check(pct_t5_lv1 < 2.5, "T5 lv1 bonus=0 quá cao: %.2f%%" % pct_t5_lv1)
	_check(pct_low_lv1 > 70.0, "T1+T2 lv1 phải > 70%%: %.1f%%" % pct_low_lv1)

	var t5_boss9: int = 0
	for _i in 1000:
		var wb: String = WeaponData.roll(9, 2)
		if int(WeaponData.DATA[wb].tier) == 5:
			t5_boss9 += 1
	print("   lv9 bonus=2 (1000 lần): T5=%d (%.1f%%)" % [t5_boss9, float(t5_boss9) / 10.0])
	_check(float(t5_boss9) / 10.0 < 12.0, "T5 Boss màn 9 quá cao: %.1f%%" % (float(t5_boss9) / 10.0))

	print("== 3. Kiểm tra phòng rộng 29x21, vật cản mới và bẫy ngẫu nhiên")
	_check(Dungeon.ROOM_W == 29 and Dungeon.ROOM_H == 21, "kích thước phòng phải là 29x21")
	var total_combat: int = 0
	var rooms_with_traps: int = 0
	var rooms_without_traps: int = 0
	var saw_wall: bool = false
	var saw_barrel: bool = false
	for lv in [1, 3, 5, 7, 9]:
		var d := Dungeon.new()
		add_child(d)
		d.generate(lv)
		await _frames(2)
		for cell in d.rooms:
			var r = d.rooms[cell]
			if r.kind == "combat":
				total_combat += 1
				_check(not r.covers.is_empty(), "phòng combat màn %d thiếu vật cản" % lv)
				if r.traps.is_empty():
					rooms_without_traps += 1
				else:
					rooms_with_traps += 1
					for tp in r.traps:
						var tpos: Vector2 = tp.global_position
						_check(tpos.distance_to(r.rect.get_center()) >= 44.0, "bẫy đặt quá gần tâm phòng")
						for dr in r.door_rects:
							_check(not (dr as Rect2).grow(48.0).has_point(tpos), "bẫy đặt quá gần cửa phòng")
				for cv in r.covers:
					if str(cv.kind) in ["wall_h", "wall_v", "pillar"]:
						saw_wall = true
					if str(cv.kind) == "barrel_boom":
						saw_barrel = true
			elif r.kind == "boss":
				_check(not r.covers.is_empty(), "phòng trùm màn %d phải có cột/vật cản che đạn" % lv)
		d.queue_free()
		await _frames(1)
	print("   phòng combat=%d | có bẫy=%d | không bẫy=%d" % [total_combat, rooms_with_traps, rooms_without_traps])
	_check(saw_wall, "chưa thấy tường ngắn/cột đá không phá được")
	_check(saw_barrel, "chưa thấy thùng thuốc nổ phá được")
	_check(rooms_with_traps > 0 and rooms_without_traps > 0, "bẫy phải xuất hiện ngẫu nhiên (vừa có phòng có vừa có phòng không)")

	print("== 4. Kiểm tra Sảnh 3-6, Cổng Thần Thoại (4-1..6-6), Boss Thần Thoại & rớt nguyên liệu hiếm")
	_check(int(EnemyData.info("bo_binh", 17).hp) > int(EnemyData.info("bo_binh", 15).hp), "Quái 4-1 phải khỏe hơn 3-5")
	_check(int(EnemyData.info("boss", 21).hp) == 920 and int(EnemyData.info("boss", 26).hp) == 1180 and int(EnemyData.info("boss", 31).hp) == 1450, "Máu 3 Boss Thần Thoại sai")
	seed(4242)
	var rare_norm: int = 0
	var rare_myth: int = 0
	for _i in 300:
		for m1 in MaterialData.roll_enemy_drops(false, false, false, true, false, false):
			if str(m1) in ["yeu_hon", "ngoc_than"]:
				rare_norm += 1
		for m2 in MaterialData.roll_enemy_drops(false, false, false, true, false, true):
			if str(m2) in ["yeu_hon", "ngoc_than"]:
				rare_myth += 1
	_check(rare_myth > rare_norm, "Nguyên liệu hiếm ở Thần Thoại (%d) phải cao hơn thường (%d)" % [rare_myth, rare_norm])

	Global.start_run()
	Global.level = 16
	var coins_before: int = Global.coins
	var ngoc_before: int = Global.material_count("ngoc_than")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = game_scene.instantiate()
	add_child(game)
	await _frames(4)
	_check(game.dungeon.rooms.size() == 2, "Sảnh 3-6 phải có đúng 2 phòng")
	var hall_room = null
	for cell in game.dungeon.rooms:
		var rm = game.dungeon.rooms[cell]
		if rm.kind == "victory_hall":
			hall_room = rm
			break
	_check(hall_room != null, "màn 16 (3-6) phải có phòng victory_hall")
	if hall_room != null:
		_check(hall_room.victory_altar != null and is_instance_valid(hall_room.victory_altar), "3-6 phải có Đài Chiến Thắng")
		_check(get_tree().get_nodes_in_group("portals").size() >= 1, "3-6 phải có Cổng Thần Thoại")
		if hall_room.victory_altar != null:
			hall_room.victory_altar.interact()
			await _frames(2)
			_check(game._victory_ui != null, "chạm Đài 3-6 không mở bảng lựa chọn")
			_check(Global.coins == coins_before + 50, "Đài 3-6 phải thưởng đúng +50 xu (đã tinh chỉnh không tràn lan)")
			_check(Global.material_count("ngoc_than") == ngoc_before + 1, "Đài 3-6 phải thưởng +1 Ngọc thần")
			game._on_victory_continue()
			await _frames(2)
			_check(game._victory_ui == null, "chọn tiếp Thần Thoại phải đóng bảng tổng kết")

	# Kiểm tra HUD Boss Intro & Rơi vũ khí Huyền Thoại Cấp 5 & Pet Tim
	game.hud.show_boss_intro("Cửu Vĩ Hồ Vương", "Thần Thoại", true)
	_check(game.hud._boss_intro_t > 0.0 and game.hud._boss_intro_mythic, "show_boss_intro không bật")
	var leg_pk := Pickup.new()
	leg_pk.kind = "weapon"
	leg_pk.weapon_id = "thuan_thien"
	leg_pk.position = game.player.global_position + Vector2(36, 0)
	game.world.add_child(leg_pk)
	await _frames(3)
	_check(is_instance_valid(leg_pk), "vũ khí Huyền Thoại Cấp 5 bị lỗi khi tạo")
	var pet_life := LobbyLife.new()
	pet_life.kind = "dog"
	pet_life.position = Vector2(100, 100)
	game.world.add_child(pet_life)
	await _frames(1)
	pet_life.trigger_happy(2.5)
	_check(pet_life._happy_t > 0.0, "hiệu ứng vuốt ve thú cưng không kích hoạt")

	# Kiểm tra Màn 6-6 (Sảnh Huyền Thoại Đợt Hai: chỉ có Đài Huyền Thoại, không còn cổng tiếp)
	var coins_m0: int = Global.coins
	var yeu_m0: int = Global.material_count("yeu_hon")
	Global.level = 32
	game._build_level()
	await _frames(4)
	_check(game.dungeon.rooms.size() == 2, "6-6 phải có 2 phòng")
	_check(get_tree().get_nodes_in_group("portals").is_empty(), "6-6 không được có cổng đi tiếp")
	var altars6: Array = get_tree().get_nodes_in_group("victory_altars")
	_check(altars6.size() == 1 and bool(altars6[0].mythic), "6-6 phải có Đài Huyền Thoại")
	if not altars6.is_empty():
		altars6[0].interact()
		await _frames(2)
		_check(game._victory_ui != null, "chạm Đài 6-6 không mở Đại Thắng Thần Thoại")
		_check(Global.coins == coins_m0 + 90 and Global.material_count("yeu_hon") == yeu_m0 + 2, "Thưởng 6-6 sai")

	print("== 5. Kiểm tra bẫy, thùng thuốc nổ và thú cưng gây sát thương địch không lỗi")
	var dummy_e = load("res://scripts/entities/enemy.gd").new()
	dummy_e.setup("bo_binh", 1, game.player)
	dummy_e._spawn_t = 0.0
	dummy_e.position = Vector2(200, 200)
	game.world.add_child(dummy_e)
	await _frames(1)
	var hp0: int = int(dummy_e.hp)
	var tr_t = load("res://scripts/entities/trap.gd").new()
	tr_t.kind = "fire_vent"
	tr_t.position = dummy_e.position
	game.world.add_child(tr_t)
	await _frames(1)
	tr_t._apply_damage()
	_check(int(dummy_e.hp) < hp0, "bẫy lửa phải gây sát thương cho địch")
	var hp1: int = int(dummy_e.hp)
	var pet_t = load("res://scripts/entities/pet.gd").new()
	pet_t.setup("dog", game.player)
	pet_t.position = dummy_e.position
	game.world.add_child(pet_t)
	await _frames(1)
	pet_t._attack_enemy(dummy_e, Vector2.RIGHT)
	_check(int(dummy_e.hp) < hp1, "thú cưng phải gây sát thương cho địch")
	var brl = load("res://scripts/entities/cover.gd").new()
	brl.kind = "barrel_boom"
	brl.position = dummy_e.position + Vector2(10, 0)
	game.world.add_child(brl)
	await _frames(1)
	brl.take_hit(10, brl.position, Vector2.RIGHT)
	_check(not is_instance_valid(dummy_e) or dummy_e.dead or int(dummy_e.hp) == 0, "thùng thuốc nổ phải hạ địch hp thấp")

	print("== 6. Kiểm tra hitbox toàn thân, né vật cản/tách đàn và hiệu ứng Boss")
	var Bullet = load("res://scripts/entities/bullet.gd")
	var mob_hb = load("res://scripts/entities/enemy.gd").new()
	mob_hb.setup("bo_binh", 1, game.player)
	mob_hb._spawn_t = 0.0
	mob_hb.position = Vector2(260, 260)
	game.world.add_child(mob_hb)
	await _frames(1)
	var m_rect: Rect2 = mob_hb.hurtbox_rect()
	_check(m_rect.size.x >= 16.0 and m_rect.size.y >= 18.0, "hitbox lính phải phủ thân (%s)" % str(m_rect))
	var m_hp0: int = int(mob_hb.hp)
	var upper_b = Bullet.new()
	upper_b.setup(true, Vector2(m_rect.position.x - 10.0, m_rect.position.y + 3.0), Vector2.RIGHT, 320.0, 3, 0.6, "arrow")
	upper_b.owner_node = game.player
	game.world.add_child(upper_b)
	for _k in 8:
		await get_tree().physics_frame
	_check(not is_instance_valid(mob_hb) or mob_hb.dead or int(mob_hb.hp) < m_hp0, "đạn bắn phần đầu/trên thân lính phải trúng hitbox")
	if is_instance_valid(mob_hb):
		mob_hb.queue_free()

	var boss_hb = load("res://scripts/entities/enemy.gd").new()
	boss_hb.setup("boss", 21, game.player)
	boss_hb._spawn_t = 0.0
	boss_hb.position = Vector2(360, 260)
	game.world.add_child(boss_hb)
	await _frames(1)
	var b_rect1: Rect2 = boss_hb.hurtbox_rect()
	_check(b_rect1.size.x >= 45.0 and b_rect1.size.y >= 42.0, "hitbox Boss phải phủ toàn thân (%s)" % str(b_rect1))
	var b_hp0: int = int(boss_hb.hp)
	var boss_top_b = Bullet.new()
	boss_top_b.setup(true, Vector2(b_rect1.position.x - 10.0, b_rect1.position.y + 5.0), Vector2.RIGHT, 340.0, 5, 0.6, "arrow")
	boss_top_b.owner_node = game.player
	game.world.add_child(boss_top_b)
	for _k in 8:
		await get_tree().physics_frame
	_check(int(boss_hb.hp) < b_hp0, "đạn bắn phần trên thân Boss phải trúng")
	# Cận chiến vào mép trên/bên hitbox Boss
	var b_hp1: int = int(boss_hb.hp)
	game.player.global_position = Vector2(b_rect1.position.x - 16.0, b_rect1.position.y + 6.0)
	game.player.aim_dir = Vector2.RIGHT
	game.player._melee({"reach": 36.0, "arc": 120.0, "damage": 6, "knock": 0.0, "style": "swing"})
	_check(int(boss_hb.hp) < b_hp1, "đánh cận chiến chạm rìa trên hitbox Boss phải trúng")
	boss_hb._finish_morph()
	_check(boss_hb.hurtbox_rect().size.x >= 45.0, "hitbox Boss sau biến hình không hợp lệ")
	boss_hb._charge_state = "windup"
	boss_hb._charge_dir = Vector2.RIGHT
	boss_hb._special = "tran_khien"
	boss_hb._special_t = 2.0
	_check(boss_hb._boss_color().a > 0.0, "_boss_color lỗi")
	boss_hb.queue_free()

	# Kiểm tra mọi Boss đều có chiêu lao tới / nhảy đập / lặn tập kích + kiểm tra cơ chế dash & leap_slam
	var mob_moves := ["charge", "leap_slam", "dive"]
	for bid in EnemyData.BOSSES:
		var bc: Dictionary = EnemyData.BOSSES[bid]
		var has1: bool = false
		var has2: bool = false
		for pm in mob_moves:
			if pm in bc.patterns:
				has1 = true
			if pm in bc.patterns2:
				has2 = true
		_check(has1 and has2, "Boss %s thiếu chiêu lao tới ở giai đoạn 1 hoặc 2" % str(bid))
	for lid in EnemyData.LEGENDS:
		var lc: Dictionary = EnemyData.LEGENDS[lid]
		var lh1: bool = false
		var lh2: bool = false
		for pm in mob_moves:
			if pm in lc.patterns:
				lh1 = true
			if pm in lc.patterns2:
				lh2 = true
		_check(lh1 and lh2, "Tam Yêu %s thiếu chiêu lao tới" % str(lid))
	for mid in EnemyData.MYTHIC_BOSSES:
		var mc: Dictionary = EnemyData.MYTHIC_BOSSES[mid]
		var mh1: bool = false
		var mh2: bool = false
		for pm in mob_moves:
			if pm in mc.patterns:
				mh1 = true
			if pm in mc.patterns2:
				mh2 = true
		_check(mh1 and mh2, "Boss Thần Thoại %s thiếu chiêu lao tới" % str(mid))

	var b_dash = load("res://scripts/entities/enemy.gd").new()
	b_dash.setup("boss", 21, game.player)
	b_dash._spawn_t = 0.0
	b_dash.position = Vector2(340, 260)
	game.world.add_child(b_dash)
	await _frames(1)
	b_dash._charge_state = ""
	b_dash._charge_ai(0.016, Vector2.RIGHT, 120.0, 5.5)
	_check(b_dash._charge_state == "windup", "Boss phải vào windup trước khi lao")
	b_dash._charge_t = 0.01
	var dash_vel: Vector2 = b_dash._charge_ai(0.05, Vector2.RIGHT, 120.0, 5.5)
	_check(b_dash._charge_state == "dash", "Boss phải chuyển sang dash sau windup")
	dash_vel = b_dash._charge_ai(0.05, Vector2.RIGHT, 120.0, 5.5)
	_check(dash_vel.length() >= 230.0, "Tốc độ lao của Boss phải đủ mạnh (%s)" % str(dash_vel.length()))
	_check(b_dash._anim_scale.x > b_dash._base_scale.x, "Boss phải kéo giãn hình thể khi lao")
	b_dash.queue_free()

	var b_leap = load("res://scripts/entities/enemy.gd").new()
	b_leap.setup("boss", 26, game.player)
	b_leap._spawn_t = 0.0
	b_leap.position = Vector2(360, 260)
	game.world.add_child(b_leap)
	await _frames(1)
	b_leap._leap_state = ""
	b_leap._leap_slam_ai(0.016, Vector2.RIGHT, 90.0)
	_check(b_leap._leap_state == "windup", "leap_slam phải bắt đầu bằng windup")
	b_leap._leap_t = 0.01
	b_leap._leap_slam_ai(0.05, Vector2.RIGHT, 90.0)
	_check(b_leap._leap_state == "air", "leap_slam phải nhảy lên không")
	b_leap._leap_slam_ai(0.20, Vector2.RIGHT, 90.0)
	_check(b_leap._leap_z > 10.0, "Boss phải nhấc cao khỏi mặt đất khi nhảy (%s)" % str(b_leap._leap_z))
	b_leap._leap_t = 0.01
	b_leap._leap_slam_ai(0.05, Vector2.RIGHT, 90.0)
	_check(b_leap._leap_state == "land" and is_zero_approx(b_leap._leap_z), "Boss phải đáp đất an toàn sau leap_slam")
	b_leap.queue_free()

	# Tách đàn & né vật cản không sinh NaN
	var sep_a = load("res://scripts/entities/enemy.gd").new()
	var sep_b = load("res://scripts/entities/enemy.gd").new()
	sep_a.setup("bo_binh", 1, game.player)
	sep_b.setup("bo_binh", 1, game.player)
	sep_a._spawn_t = 0.0
	sep_b._spawn_t = 0.0
	sep_a.position = Vector2(450, 260)
	sep_b.position = Vector2(451, 260)
	game.world.add_child(sep_a)
	game.world.add_child(sep_b)
	await _frames(1)
	var sv: Vector2 = sep_a._separation_vec()
	var av: Vector2 = sep_a._avoid_obstacles(Vector2(60, 0), 0.016)
	_check(sv.length() > 1.0 and not is_nan(av.x) and not is_nan(av.y), "tách đàn/né vật cản không hoạt động (%s, %s)" % [str(sv), str(av)])
	sep_a.queue_free()
	sep_b.queue_free()

	game.queue_free()
	await _frames(2)
