extends Node
## Kiểm thử sảnh chính 4 phòng kiểu Soul Knight và tầm nhìn Camera hầm ngục.
## Chạy: godot --headless --path . res://tests/lobby_rooms_test.tscn -> in "LOBBY ROOMS TEST OK"

const TEST_SAVE := "user://lobby_rooms_test_save.json"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _phys_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func():
		print("LOBBY ROOMS TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	_wipe()
	if _fail == 0:
		print("LOBBY ROOMS TEST OK")
		get_tree().quit(0)
	else:
		print("LOBBY ROOMS TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _walk_line(player: CharacterBody2D, from_pos: Vector2, dir: Vector2, steps: int = 40) -> Vector2:
	player.position = from_pos
	for _i in steps:
		player.velocity = dir.normalized() * 140.0
		player.move_and_slide()
		await _phys_frames(1)
	player.velocity = Vector2.ZERO
	return player.position


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	Global.coins = 300
	Global.unlocked = ["hai_ba_trung"]
	Global.selected_hero = "hai_ba_trung"
	Global.upgrades = {}
	Global.hero_levels = {}
	Global.weapon_ranks = {}
	Global.garden_plots = []
	Global.ensure_garden_plots()
	Global.lobby_drink = ""
	Global.lobby_weapon_mod = ""
	Global.lobby_shrine_buff = ""
	Global.lobby_garden_buffs = []
	Global.pending_challenge_code = ""
	Global.forged = ""
	Global.materials.clear()
	Global.set_setting("camera_zoom", 0.85)
	Global.save_game()

	print("== (a) Nạp sảnh chính 4 phòng (1360x760)")
	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(3)

	_check(lobby.SIZE == Vector2(1360, 760), "kích thước lobby chưa phải 1360x760")
	_check(lobby.ROOMS.size() == 4, "số phòng không đủ 4: %d" % lobby.ROOMS.size())
	_check(lobby.camera != null and lobby.camera.zoom.is_equal_approx(Vector2(1.0, 1.0)), "camera lobby phải có zoom 1.0")
	_check(str(lobby.room_at(lobby.player.global_position).get("id", "")) == "center", "người chơi phải sinh tại Đại Sảnh")
	_check(str(lobby.room_at(Vector2(200, 400)).get("id", "")) == "west", "room_at Vườn Sen sai")
	_check(str(lobby.room_at(Vector2(1100, 400)).get("id", "")) == "east", "room_at Xưởng Rèn sai")
	_check(str(lobby.room_at(Vector2(680, 120)).get("id", "")) == "north", "room_at Cổng Bắc sai")

	print("== (b) Đi bộ thông qua 3 hành lang nối 4 phòng")
	lobby.player.set_physics_process(false)
	var pw_end: Vector2 = await _walk_line(lobby.player, Vector2(490, 470), Vector2.LEFT, 42)
	_check(pw_end.x < 420.0, "không đi qua được hành lang Tây sang Vườn Sen: x=%.1f" % pw_end.x)
	_check(str(lobby.room_at(pw_end).get("id", "")) == "west", "sau hành lang Tây chưa vào Vườn Sen")

	var pe_end: Vector2 = await _walk_line(lobby.player, Vector2(870, 470), Vector2.RIGHT, 42)
	_check(pe_end.x > 940.0, "không đi qua được hành lang Đông sang Xưởng Rèn: x=%.1f" % pe_end.x)
	_check(str(lobby.room_at(pe_end).get("id", "")) == "east", "sau hành lang Đông chưa vào Xưởng Rèn")

	var pn_end: Vector2 = await _walk_line(lobby.player, Vector2(680, 275), Vector2.UP, 42)
	_check(pn_end.y < 210.0, "không đi qua được hành lang Bắc lên Đại Cổng: y=%.1f" % pn_end.y)
	_check(str(lobby.room_at(pn_end).get("id", "")) == "north", "sau hành lang Bắc chưa vào Đại Cổng")
	lobby.player.set_physics_process(true)

	print("== (c) Tương tác tất cả trạm mới và cũ trong 4 phòng")
	var kinds_seen: Array[String] = []
	for s in lobby.stations:
		if not s.visible:
			continue
		kinds_seen.append(str(s.kind))
		s.interact()
		await _frames(1)
		_check(lobby.ui.is_open(), "trạm '%s' không mở bảng UI" % str(s.kind))
		lobby.ui.close()
		await _frames(1)
	for req in ["stele", "well", "challenge", "forge", "rack", "codex", "hero", "tea", "war_table", "garden", "enchant", "shrine", "supply"]:
		_check(kinds_seen.has(req), "thiếu trạm '%s' trong sảnh" % req)

	print("== (d) Kiểm tra Giếng Ước trừ xu và giảm lượt")
	var uses_before: int = int(lobby.well_uses)
	lobby.ui.open_well()
	await _frames(1)
	lobby.ui._do_wish()
	await _frames(1)
	_check(int(lobby.well_uses) == uses_before - 1, "Giếng Ước không giảm lượt dùng")
	lobby.ui.close()
	await _frames(1)

	print("== (d2) Kiểm tra Vườn Thảo Dược, Quán Trà, Phù Phép & Thần Hộ Mệnh")
	var h0: String = Global.harvest_garden(0)
	_check(h0 != "", "ô 0 khởi đầu phải thu hoạch được ngay")
	_check(Global.plant_garden(1, "huyet_sam"), "không trồng được Huyết Sâm vào ô 1")
	_check(Global.water_garden_plot(1), "không tưới nước chín được ô 1")
	var h1: String = Global.harvest_garden(1)
	_check(h1 != "" and Global.lobby_garden_buffs.has("banh_chung"), "thu hoạch Huyết Sâm phải cho banh_chung")
	Global.lobby_drink = "tra_sen"
	Global.lobby_weapon_mod = "da_mai"
	Global.lobby_shrine_buff = "ruou_thuoc"

	print("== (e) Kiểm tra 3 Hình Nhân ở Võ Đường phía Đông")
	var dummies: Array = get_tree().get_nodes_in_group("enemies")
	_check(dummies.size() >= 3, "Võ Đường cần ít nhất 3 hình nhân (có %d)" % dummies.size())
	if dummies.size() >= 1:
		_check(str(lobby.room_at(dummies[0].global_position).get("id", "")) == "east", "Hình nhân phải ở phòng Đông")

	lobby.queue_free()
	await _frames(2)

	print("== (f) Kiểm tra Camera & Tiền thưởng chuẩn bị áp dụng vào hầm ngục")
	Global.start_run()
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game: Node = game_scene.instantiate()
	get_tree().root.add_child(game)
	await _frames(3)
	_check(game.camera != null, "không tạo camera trong hầm ngục")
	_check(game.camera.zoom.is_equal_approx(Vector2(0.85, 0.85)), "zoom mặc định hầm ngục phải là 0.85, đang %.2f" % game.camera.zoom.x)
	_check(Global.lobby_drink == "" and Global.lobby_weapon_mod == "" and Global.lobby_shrine_buff == "", "thưởng chuẩn bị phải được tiêu thụ sau khi vào trận")
	_check(game.player.max_armor >= 7, "Trà Sen phải cộng +2 giáp tối đa (đang %d)" % game.player.max_armor)
	_check(Global.get_weapon_mod(str(game.player.weapons[0])) == "da_mai", "Phù phép da_mai không được gắn lên vũ khí khởi đầu")
	_check(game.player.buff("ruou_thuoc") >= 1, "Thần phúc ruou_thuoc không áp dụng")
	_check(game.player.buff("banh_chung") >= 1, "Thảo dược banh_chung không áp dụng")
	Global.set_setting("camera_zoom", 0.78)
	_check(game.camera.zoom.is_equal_approx(Vector2(0.78, 0.78)), "đổi tầm nhìn Rộng (0.78) không cập nhật ngay")
	Global.set_setting("camera_zoom", 1.0)
	_check(game.camera.zoom.is_equal_approx(Vector2(1.0, 1.0)), "đổi tầm nhìn Gần (1.0) không cập nhật ngay")
	game.queue_free()
	await _frames(1)
