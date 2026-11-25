extends Node
## Kiểm thử v1.2.8:
##   1) Random 10 chương kiểu Soul Knight (Cổ Đại -> Trung Đại -> Cận Đại, không trùng 10 chương đầu)
##   2) Tỉ lệ rơi vũ khí hiếm chuẩn (Huyền thoại Cấp 5 rất hiếm, không tràn lan)
##   3) Phòng rộng 29x21, vật cản phá được / không phá được + bẫy ngẫu nhiên giữa các phòng
##   4) Thùng thuốc nổ & Đài Chiến Thắng ở Boss màn 9 (3-3)

const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
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
	_check(EnemyData.stage_chapter_num(1) == 1 and EnemyData.stage_chapter_num(9) == 3, "stage_chapter_num sai")

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

	print("== 4. Kiểm tra Đài Chiến Thắng & Màn hình Khải Hoàn ở Boss màn 9 (3-3)")
	Global.start_run()
	Global.level = 9
	var coins_before: int = Global.coins
	var ngoc_before: int = Global.material_count("ngoc_than")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = game_scene.instantiate()
	add_child(game)
	await _frames(4)
	var boss_room = null
	for cell in game.dungeon.rooms:
		var rm = game.dungeon.rooms[cell]
		if rm.kind == "boss":
			boss_room = rm
			break
	_check(boss_room != null, "màn 9 phải có phòng Boss")
	if boss_room != null:
		game.player.global_position = boss_room.rect.get_center()
		await _frames(5)
		var boss = get_tree().get_first_node_in_group("boss")
		_check(boss != null, "không sinh ra Boss ở màn 9")
		if boss != null:
			boss.die(false)
			await _frames(4)
		_check(boss_room.victory_altar != null and is_instance_valid(boss_room.victory_altar), "hạ Boss màn 9 phải hiện Đài Chiến Thắng")
		_check(get_tree().get_nodes_in_group("portals").size() >= 1, "hạ Boss màn 9 vẫn phải có Cổng Vô Tận")
		if boss_room.victory_altar != null:
			boss_room.victory_altar.interact()
			await _frames(2)
			_check(game._victory_ui != null, "tương tác Đài Chiến Thắng không mở màn hình Đại Thắng")
			_check(Global.coins >= coins_before + 150, "Đại Thắng phải thưởng +150 xu")
			_check(Global.material_count("ngoc_than") >= ngoc_before + 1, "Đại Thắng phải thưởng +1 Ngọc thần")

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
	game.queue_free()
	await _frames(2)
