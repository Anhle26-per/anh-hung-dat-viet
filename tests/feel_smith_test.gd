extends Node
## Kiểm thử Game Feel (Hitstop, Thanh máu quái, Mũi tên chỉ đường) & Thợ rèn lưu động / Bùa vũ khí.
## Chạy: godot --headless --path . res://tests/feel_smith_test.tscn -> in "FEEL SMITH TEST OK"

const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const BlacksmithNpc = preload("res://scripts/entities/blacksmith_npc.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Player = preload("res://scripts/entities/player.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const TEST_SAVE := "user://feel_smith_test_save.json"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _cleanup_saves() -> void:
	var paths: Array[String] = [TEST_SAVE, Global.run_path()]
	for p in paths:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func():
		print("FEEL SMITH TEST FAILED: quá thời gian")
		get_tree().quit(1))
	Global.save_path = TEST_SAVE
	_cleanup_saves()
	await _frames(2)
	await _run()
	_cleanup_saves()
	if _fail == 0:
		print("FEEL SMITH TEST OK")
		get_tree().quit(0)
	else:
		print("FEEL SMITH TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra 4 bùa vũ khí trong WeaponMods.apply()")
	var base: Dictionary = {"name": "Thử", "damage": 5, "energy": 2, "cooldown": 1.0}
	var m_dmg: Dictionary = WeaponMods.apply(base, "da_mai")
	_check(int(m_dmg.get("damage", 0)) == 7, "da_mai phải cộng +2 sát thương (nhận %d)" % int(m_dmg.get("damage", 0)))
	_check(int(base.get("damage", 0)) == 5, "WeaponMods.apply() không được sửa dict gốc")

	var m_en: Dictionary = WeaponMods.apply(base, "ngoc_tiet_kiem")
	_check(int(m_en.get("energy", -1)) == 1, "ngoc_tiet_kiem phải giảm -1 năng lượng (nhận %d)" % int(m_en.get("energy", -1)))
	var zero_en: Dictionary = WeaponMods.apply({"energy": 0}, "ngoc_tiet_kiem")
	_check(int(zero_en.get("energy", -1)) == 0, "ngoc_tiet_kiem tối thiểu 0 năng lượng (nhận %d)" % int(zero_en.get("energy", -1)))

	var m_cd: Dictionary = WeaponMods.apply(base, "long_chim")
	_check(is_equal_approx(float(m_cd.get("cooldown", 0.0)), 0.83), "long_chim phải nhân cooldown * 0.83 (nhận %.3f)" % float(m_cd.get("cooldown", 0.0)))

	var m_fire: Dictionary = WeaponMods.apply(base, "hoa_thach")
	_check(bool(m_fire.get("mod_fire", false)) == true, "hoa_thach phải đặt mod_fire == true")

	for mid in WeaponMods.ORDER:
		var m_str: String = str(mid)
		_check(WeaponMods.mod_name(m_str) != "", "mod_name rỗng cho %s" % m_str)
		_check(WeaponMods.mod_color(m_str) != Color.WHITE, "mod_color phải có màu riêng cho %s" % m_str)

	print("== 2. Kiểm tra lưu/nạp run_weapon_mods qua Global.save_run / load_run")
	Global.start_run()
	_check(Global.run_weapon_mods.is_empty(), "start_run() phải xóa sạch run_weapon_mods")
	var p := Player.new()
	p.setup("ngo_quyen")
	add_child(p)
	await _frames(2)
	var wid: String = str(p.weapons[p.slot])
	Global.set_weapon_mod(wid, "hoa_thach")
	_check(Global.get_weapon_mod(wid) == "hoa_thach", "get_weapon_mod không trả về hoa_thach")
	var saved_ok: bool = Global.save_run(p)
	_check(saved_ok, "save_run(p) thất bại")
	Global.run_weapon_mods = {}
	_check(Global.get_weapon_mod(wid) == "", "xóa bộ nhớ tạm run_weapon_mods thất bại")
	var loaded_ok: bool = Global.load_run()
	_check(loaded_ok, "load_run() thất bại")
	_check(Global.get_weapon_mod(wid) == "hoa_thach", "run_weapon_mods không giữ lại sau load_run() (nhận '%s')" % Global.get_weapon_mod(wid))
	Global.end_run("bo_luot")
	_check(Global.run_weapon_mods.is_empty(), "end_run() phải xóa sạch run_weapon_mods")

	print("== 3. Kiểm tra Thợ rèn lưu động (BlacksmithNpc.interact + spawn trong phòng)")
	Global.start_run()
	Global.run_coins = 5
	var smith := BlacksmithNpc.new()
	smith.level = 2
	smith.position = Vector2(40, 0)
	add_child(smith)
	await _frames(2)
	_check(smith.price == 22, "giá thợ rèn màn 2 phải là 22 xu (nhận %d)" % smith.price)
	smith.interact()
	_check(not smith.used and Global.run_coins == 5 and Global.get_weapon_mod(wid) == "", "thiếu xu không được rèn hoặc trừ xu")

	Global.run_coins = 50
	smith.interact()
	var got_mod: String = Global.get_weapon_mod(wid)
	_check(smith.used and not smith.enabled, "sau khi rèn xong phải khóa smith (used=true, enabled=false)")
	_check(smith.hint() == "Đã rèn xong", "hint sau khi rèn xong sai: '%s'" % smith.hint())
	_check(Global.run_coins == 28, "phải trừ đúng 22 xu (còn %d)" % Global.run_coins)
	_check(WeaponMods.ORDER.has(got_mod), "bùa gắn phải nằm trong WeaponMods.ORDER (nhận '%s')" % got_mod)

	# Gọi lần 2 không được trừ thêm xu hay đổi bùa
	smith.interact()
	_check(Global.run_coins == 28 and Global.get_weapon_mod(wid) == got_mod, "không được phép dùng lại thợ rèn lần 2")
	smith.queue_free()

	# Kiểm tra sinh thợ rèn trong phòng shop và phòng exit
	var shop_seen: int = 0
	var shop_with_smith: int = 0
	var exit_seen: int = 0
	var exit_with_smith: int = 0
	for s in range(18):
		seed(700 + s)
		var d_chk := Dungeon.new()
		add_child(d_chk)
		d_chk.generate(4)
		await _frames(1)
		for cell in d_chk.rooms:
			var r = d_chk.rooms[cell]
			if r.kind == "shop":
				shop_seen += 1
				if r.blacksmith != null and is_instance_valid(r.blacksmith):
					shop_with_smith += 1
					for dr in r.door_rects:
						_check(not (dr as Rect2).grow(28.0).has_point(r.blacksmith.global_position), "thợ rèn trong chợ quá gần cửa")
			elif r.kind == "exit":
				exit_seen += 1
				if r.blacksmith != null and is_instance_valid(r.blacksmith):
					exit_with_smith += 1
		d_chk.queue_free()
		await _frames(1)
	_check(shop_seen > 0 and shop_with_smith == shop_seen, "mọi phòng shop phải có Thợ rèn lưu động (%d/%d)" % [shop_with_smith, shop_seen])
	_check(exit_seen > 0 and exit_with_smith > 0 and exit_with_smith < exit_seen, "phòng exit phải có xác suất ~55%% sinh thợ rèn (%d/%d)" % [exit_with_smith, exit_seen])

	print("== 4. Kiểm tra thanh máu mini của quái & Fx.hitstop() an toàn headless")
	var en := Enemy.new()
	en.setup("bo_binh", 1, p)
	en.position = Vector2(120, 0)
	add_child(en)
	en._spawn_t = 0.0
	await _frames(1)
	_check(en._hp_bar_t == 0.0, "quái mới sinh chưa trúng đòn phải có _hp_bar_t == 0")
	en.take_damage(1)
	_check(en._hp_bar_t > 0.0, "quái thường trúng đòn phải bật _hp_bar_t > 0")
	en._hp_bar_t = 0.0
	en.dot_damage(1, "burn")
	_check(en._hp_bar_t > 0.0, "quái thường trúng cháy (dot_damage) phải bật _hp_bar_t > 0")

	var boss := Enemy.new()
	boss.setup("boss", 3, p)
	boss.position = Vector2(180, 0)
	add_child(boss)
	boss._spawn_t = 0.0
	await _frames(1)
	boss.take_damage(1)
	_check(boss._hp_bar_t == 0.0, "trùm không dùng thanh máu mini (_hp_bar_t phải bằng 0)")
	en.queue_free()
	boss.queue_free()

	Fx.hitstop(get_tree(), 0.05)
	_check(is_equal_approx(Engine.time_scale, 1.0), "Fx.hitstop() ở headless phải giữ Engine.time_scale == 1.0")
	_check(not Fx._hitstop_active, "Fx._hitstop_active phải là false ở headless")

	print("== 5. Kiểm tra đã bỏ mũi tên chỉ đường rương/phòng & huy hiệu bùa trên HUD")
	seed(4242)
	var d := Dungeon.new()
	add_child(d)
	d.generate(2)
	p.global_position = d.start_position()
	var hud := HUD.new()
	hud.player = p
	add_child(hud)
	await _frames(3)

	var targets_done: Array = hud.get_wayfinder_targets()
	_check(targets_done.is_empty(), "HUD không còn vẽ mũi tên chỉ rương/phòng khi an toàn (nhận %d)" % targets_done.size())

	var start_room = d.rooms[Vector2i.ZERO]
	start_room.state = "fighting"
	start_room.player_inside = true
	await _frames(2)
	var targets_fight: Array = hud.get_wayfinder_targets()
	_check(targets_fight.is_empty(), "khi đang giao tranh cũng phải trống mục tiêu mũi tên (nhận %d)" % targets_fight.size())

	start_room.state = "done"
	Global.set_weapon_mod(wid, "da_mai")
	await _frames(3)
	hud.queue_free()
	d.queue_free()
	p.queue_free()
	await _frames(1)
