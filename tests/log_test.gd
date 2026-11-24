extends Node
## Kiểm thử thẻ G11 bước 1: Nhật ký trận user://nhat_ky.csv (14 cột), kẻ kết liễu, đường dẫn lỗi không văng game.
## Chạy: godot --headless --path . res://tests/log_test.tscn -> in "LOG TEST OK"

const Player = preload("res://scripts/entities/player.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const TEST_SAVE := "user://log_test_save.json"
const TEST_LOG := "user://log_test_nhat_ky.csv"

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
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", Global.run_path(), Global.run_path() + ".tmp", TEST_LOG]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func():
		print("LOG TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0:
		print("LOG TEST OK")
		get_tree().quit(0)
	else:
		print("LOG TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	Global.log_path = TEST_LOG
	_wipe()
	Global.unlocked = ["ngo_quyen", "ba_trieu"]
	Global.selected_hero = "ngo_quyen"
	Global.hero_levels["ngo_quyen"] = 3
	Global.weapon_ranks["ngo_quyen"] = 4
	Global.set_setting("difficulty", "kho")

	print("== 1. Lượt 1: đánh trùm, trúng đòn cuối từ Tô Định, lưu & nạp lại qua Chơi tiếp")
	Global.start_run()
	Global.boss_order = ["to_dinh"]
	Global.level = 3
	Global.run_coins = 42
	Global.add_run_material("dong", 2)
	Global.add_run_material("sat", 1)
	Global.run_buffs = {"banh_chung": 1, "da_mai": 2}
	Global.run_elapsed = 65.4
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("ngo_quyen")
	world.add_child(p)
	p._use_skill() # syn=2 -> [0,0,1]
	p.weapons[0] = "giao"
	p.skill_timer = 0.0
	p._use_skill() # syn=1 -> [0,1,1]
	var boss := Enemy.new()
	boss.setup("boss", 3, p)
	world.add_child(boss)
	boss._spawn_t = 0.0
	p.hp = 5
	boss.die(true)
	var killer := Enemy.new()
	killer.setup("boss", 3, p)
	world.add_child(killer)
	killer._spawn_t = 0.0
	p.take_damage(5)
	_check(Global.save_run(p), "save_run thất bại ở log_test")
	_check(Global.load_run(), "load_run thất bại ở log_test")
	Global.end_run()

	print("== 2. Lượt 2: bỏ lượt (abandon_run) ra bo_luot")
	Global.hero_levels["ngo_quyen"] = 2
	Global.weapon_ranks["ngo_quyen"] = 2
	Global.start_run()
	Global.level = 2
	Global.run_coins = 11
	Global.save_run(p)
	Global.abandon_run()
	world.queue_free()
	await _frames(2)

	print("== 3. Kiểm tra 1 dòng tiêu đề + 2 dòng dữ liệu, đủ 14 cột")
	_check(FileAccess.file_exists(TEST_LOG), "không tạo tệp nhật ký")
	var f := FileAccess.open(TEST_LOG, FileAccess.READ)
	var lines: Array = []
	while not f.eof_reached():
		var ln: String = f.get_line().strip_edges()
		if ln != "":
			lines.append(ln)
	f.close()
	_check(lines.size() == 3, "số dòng CSV = %d (kỳ vọng 3)" % lines.size())
	if lines.size() == 3:
		var h: PackedStringArray = str(lines[0]).split(",")
		var r1: PackedStringArray = str(lines[1]).split(",")
		var r2: PackedStringArray = str(lines[2]).split(",")
		_check(h.size() == 14 and h[13] == "cap_bac", "tiêu đề CSV sai: %s" % lines[0])
		_check(r1.size() == 14 and r2.size() == 14, "số cột dòng dữ liệu sai: %d / %d" % [r1.size(), r2.size()])
		if r1.size() >= 14 and r2.size() >= 14:
			_check(r1[1] == "ngo_quyen" and r1[2] == "kho" and r1[3] == "3" and r1[4] == "65", "r1 thông tin sai: %s" % lines[1])
			_check(r1[5] == "1" and r1[6] == "3" and r1[7] == "Tô Định" and r1[8] == "5", "r1 kills/boss death sai: %s" % lines[1])
			_check(r1[9] == "42" and r1[10] == "dong:2|sat:1" and r1[12] == "0|1|1" and r1[13] == "3/4",
				"r1 chi tiết sai: %s" % lines[1])
			_check(r2[7] == "bo_luot" and r2[13] == "2/2", "r2 bo_luot/cap_bac sai: %s" % lines[2])

	print("== 4. Đường dẫn không ghi được không văng game")
	Global.log_path = "Z:/khong_ton_tai_xyz_999/nhat_ky.csv"
	Global.start_run()
	Global.end_run("thang")
	Global.log_path = TEST_LOG
	_check(true, "vượt qua đường dẫn lỗi")
