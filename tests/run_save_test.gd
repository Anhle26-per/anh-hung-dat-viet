extends Node
## Kiểm thử thẻ G01: lưu lượt chơi dở, nạp lại, bỏ lượt, tệp hỏng, đóng cửa sổ, tệp lưu cũ.
## Chạy: godot --headless --path . res://tests/run_save_test.tscn  -> in "RUN SAVE TEST OK"

const Player = preload("res://scripts/entities/player.gd")
const TEST_SAVE := "user://run_save_test_save.json"

var _fail := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	# tự dừng nếu treo
	get_tree().create_timer(120.0).timeout.connect(func():
		print("RUN SAVE TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	if _fail == 0:
		print("RUN SAVE TEST OK")
		get_tree().quit(0)
	else:
		print("RUN SAVE TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _wipe() -> void:
	for p in [TEST_SAVE, Global.run_path(), TEST_SAVE + ".tmp", Global.run_path() + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _reset_globals() -> void:
	Global.coins = 0
	Global.level = 1
	Global.run_coins = 0
	Global.run_buffs = {}
	Global.boss_order = []
	Global.legend_last = ""
	Global.revived = false
	Global.free_revives = 0
	Global.resume_data = {}


func _run() -> void:
	Global.save_path = TEST_SAVE
	_check(Global.run_path() != Global.RUN_SAVE_PATH, "test phải dùng tệp lượt chơi riêng")
	_wipe()
	_reset_globals()

	# 1) Lưu ở màn 4 với 123 xu rồi nạp lại
	print("== 1. Lưu và nạp lượt chơi")
	Global.selected_hero = "ngo_quyen"
	Global.level = 4
	Global.run_coins = 123
	Global.run_buffs = {"banh_chung": 1, "mat_than": 2}
	Global.boss_order = ["do_cat", "to_dinh"]
	Global.legend_last = "ho_tinh_vuong"
	Global.free_revives = 1
	var p := Player.new()
	p.setup("ngo_quyen")
	p.max_hp += 2
	p.hp = 3
	p.armor = 1
	p.energy = 77
	p.weapons = ["giao_tre", "no_lien_chau"]
	p.slot = 1
	_check(Global.save_run(p), "save_run trả về false")
	_check(Global.has_run(), "không thấy tệp lượt chơi sau khi lưu")
	_check(not FileAccess.file_exists(Global.run_path() + ".tmp"), "còn sót tệp .tmp")
	var snap: Dictionary = p.snapshot()
	p.free()
	_reset_globals()
	Global.selected_hero = "hai_ba_trung"
	_check(Global.load_run(), "load_run trả về false")
	_check(Global.selected_hero == "ngo_quyen", "sai tướng: " + Global.selected_hero)
	_check(Global.level == 4, "sai màn: %d" % Global.level)
	_check(Global.run_coins == 123, "sai xu lượt: %d" % Global.run_coins)
	_check(int(Global.run_buffs.get("mat_than", 0)) == 2 and int(Global.run_buffs.get("banh_chung", 0)) == 1, "sai phúc lành: %s" % str(Global.run_buffs))
	_check(Global.boss_order == ["do_cat", "to_dinh"], "sai thứ tự trùm: %s" % str(Global.boss_order))
	_check(Global.legend_last == "ho_tinh_vuong", "sai Tam Yêu")
	_check(Global.free_revives == 1, "sai lượt hồi sinh")

	# 2) Nạp trạng thái vào nhân vật mới
	print("== 2. Nạp lại nhân vật")
	var q := Player.new()
	q.setup(Global.selected_hero)
	q.restore(Global.resume_data)
	_check(q.max_hp == int(snap.max_hp) and q.hp == 3, "sai máu: %d/%d" % [q.hp, q.max_hp])
	_check(q.armor == 1 and q.energy == 77, "sai giáp/năng lượng")
	_check(q.weapons == ["giao_tre", "no_lien_chau"] and q.slot == 1, "sai vũ khí: %s" % str(q.weapons))
	q.free()

	# 3) Bỏ lượt: nhận đúng 123 xu, tệp lượt chơi bị xóa
	print("== 3. Bỏ lượt")
	Global.coins = 50
	var got := Global.abandon_run()
	_check(got == 123, "bỏ lượt trả về %d xu" % got)
	_check(Global.coins == 173, "xu sau khi bỏ lượt: %d (cần 173)" % Global.coins)
	_check(not Global.has_run(), "bỏ lượt mà tệp lượt chơi vẫn còn")

	# 4) Tệp hỏng / sai phiên bản / vũ khí lạ: bỏ qua, không văng game
	print("== 4. Tệp hỏng")
	var f := FileAccess.open(Global.run_path(), FileAccess.WRITE)
	f.store_string("{hỏng rồi")
	f.close()
	_check(Global.peek_run().is_empty(), "tệp hỏng mà peek_run vẫn trả dữ liệu")
	_check(not Global.load_run(), "tệp hỏng mà load_run vẫn thành công")
	f = FileAccess.open(Global.run_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 999, "hero": "ngo_quyen", "level": 2, "player": {}}))
	f.close()
	_check(not Global.load_run(), "sai phiên bản mà vẫn nạp")
	f = FileAccess.open(Global.run_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": Global.RUN_VERSION, "hero": "ngo_quyen", "level": 2,
		"player": {"hp": 4, "weapons": ["khong_co_vu_khi_nay", ""]}}))
	f.close()
	_check(Global.load_run(), "tệp hợp lệ (thiếu vài khóa) không nạp được")
	var r := Player.new()
	r.setup("ngo_quyen")
	r.restore(Global.resume_data)
	_check(r.weapons[0] != "khong_co_vu_khi_nay", "vũ khí lạ không bị loại")
	r.free()
	Global.clear_run()
	# start_run khi còn lượt dở: cộng xu lượt cũ, giữ tướng vừa chọn
	Global.level = 3
	Global.run_coins = 40
	Global.selected_hero = "ngo_quyen"
	var tmp_p := Player.new()
	tmp_p.setup("ngo_quyen")
	Global.save_run(tmp_p)
	tmp_p.free()
	Global.coins = 0
	Global.selected_hero = "hai_ba_trung"
	Global.start_run()
	_check(Global.coins == 40, "start_run không cộng xu lượt dở (xu = %d)" % Global.coins)
	_check(Global.selected_hero == "hai_ba_trung", "start_run làm đổi tướng đang chọn")
	_check(not Global.has_run() and Global.level == 1, "start_run không dọn lượt cũ")

	# 5) Đóng cửa sổ giữa trận: lưu lượt; đóng khi đã ngã: cộng xu
	print("== 5. Đóng cửa sổ giữa trận")
	_reset_globals()
	Global.selected_hero = "ngo_quyen"
	Global.start_run()
	Global.level = 2
	var game = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(game)
	await _frames(10)
	_check(Global.has_run(), "đầu màn không tự lưu")
	Global.run_coins = 77
	game.player.hp = 2
	Global.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var d := Global.peek_run()
	_check(int(d.get("run_coins", -1)) == 77 and int(d.get("level", 0)) == 2, "đóng cửa sổ không lưu đúng: %s" % str(d))
	_check(int(d.get("player", {}).get("hp", 0)) == 2, "đóng cửa sổ không lưu máu")
	Global.coins = 0
	game.player._invuln = 0.0
	game.player.armor = 0
	game.player.take_damage(999)
	_check(game.player.dead, "nhân vật không ngã")
	Global.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	_check(Global.coins == 77, "đóng cửa sổ khi đã ngã không cộng xu (xu = %d)" % Global.coins)
	_check(not Global.has_run(), "đã ngã mà vẫn còn lượt dở")
	game.queue_free()
	await _frames(5)

	# 6) Chơi tiếp qua game.tscn: nhân vật được nạp đúng
	print("== 6. Chơi tiếp")
	_reset_globals()
	Global.selected_hero = "ngo_quyen"
	Global.level = 5
	Global.run_coins = 9
	Global.resume_data = {"hp": 2, "max_hp": 9, "armor": 0, "max_armor": 5, "energy": 10, "max_energy": 200,
		"weapons": ["giao_tre", "no_lien_chau"], "slot": 1}
	Global.save_run()
	_reset_globals()
	_check(Global.load_run(), "không nạp được lượt để chơi tiếp")
	var g2 = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(g2)
	await _frames(10)
	_check(Global.level == 5, "chơi tiếp sai màn")
	_check(g2.player.hp == 2 and g2.player.max_hp == 9, "chơi tiếp sai máu: %d/%d" % [g2.player.hp, g2.player.max_hp])
	_check(g2.player.weapons[1] == "no_lien_chau" and g2.player.slot == 1, "chơi tiếp sai vũ khí")
	_check(Global.resume_data.is_empty() or Global.has_run(), "trạng thái chơi tiếp lỗi")
	g2.queue_free()
	await _frames(5)
	Global.clear_run()

	# 7) Tệp lưu cũ (không có khóa mới) vẫn nạp được
	print("== 7. Tệp lưu cũ")
	f = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 5, "unlocked": ["ngo_quyen"], "stats": {"runs": 3}}))
	f.close()
	Global.coins = 0
	Global.load_game()
	_check(Global.coins == 5, "tệp lưu cũ nạp sai xu: %d" % Global.coins)
	Global.save_game()
	_check(not FileAccess.file_exists(TEST_SAVE + ".tmp"), "save_game còn sót tệp .tmp")
	Global.load_game()
	_check(Global.coins == 5, "ghi rồi đọc lại tệp lưu sai")
	_wipe()
