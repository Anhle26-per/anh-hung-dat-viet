extends Node
## Kiểm thử thẻ G03: lưu/nạp cài đặt, tệp lưu cũ, nhân máu/sát thương theo độ khó, tắt tiếng bus Music, mở/đóng SettingsMenu.
## Chạy: godot --headless --path . res://tests/settings_test.tscn  -> in "SETTINGS TEST OK"

const EnemyData = preload("res://scripts/data/enemies.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
const TEST_SAVE := "user://settings_test_save.json"

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
	for p in [TEST_SAVE, TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(func():
		print("SETTINGS TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	_wipe()
	if _fail == 0:
		print("SETTINGS TEST OK")
		get_tree().quit(0)
	else:
		print("SETTINGS TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()

	print("== (a) Lưu và nạp lại đủ 6 cài đặt")
	Global.set_setting("music", 0.35)
	Global.set_setting("sfx", 0.55)
	Global.set_setting("shake", false)
	Global.set_setting("fullscreen", true)
	Global.set_setting("touch_scale", 1.25)
	Global.set_setting("difficulty", "kho")
	Global.save_game()

	# Đặt sang giá trị khác rồi load_game() để chắc chắn nạp từ tệp
	Global.settings = Global.DEFAULT_SETTINGS.duplicate()
	Global.load_game()
	_check(absf(float(Global.settings.get("music", -1.0)) - 0.35) < 0.01, "sai music sau load_game")
	_check(absf(float(Global.settings.get("sfx", -1.0)) - 0.55) < 0.01, "sai sfx sau load_game")
	_check(not bool(Global.settings.get("shake", true)), "sai shake sau load_game")
	_check(bool(Global.settings.get("fullscreen", false)), "sai fullscreen sau load_game")
	_check(absf(float(Global.settings.get("touch_scale", 0.0)) - 1.25) < 0.01, "sai touch_scale sau load_game")
	_check(str(Global.settings.get("difficulty", "")) == "kho", "sai difficulty sau load_game")

	print("== (b) Tệp lưu cũ thiếu settings -> mặc định, giữ nguyên xu và tướng")
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"coins": 777,
		"unlocked": ["hai_ba_trung", "ly_thuong_kiet"],
		"selected_hero": "ly_thuong_kiet",
	}))
	f.close()
	Global.coins = 0
	Global.unlocked = ["hai_ba_trung"]
	Global.load_game()
	_check(Global.coins == 777, "tệp cũ mất xu: %d" % Global.coins)
	_check(Global.unlocked.has("ly_thuong_kiet"), "tệp cũ mất tướng đã mở")
	_check(absf(float(Global.settings.get("music", 0.0)) - 0.8) < 0.01, "sai mặc định music")
	_check(absf(float(Global.settings.get("sfx", 0.0)) - 0.9) < 0.01, "sai mặc định sfx")
	_check(bool(Global.settings.get("shake", false)), "sai mặc định shake")
	_check(not bool(Global.settings.get("fullscreen", true)), "sai mặc định fullscreen")
	_check(absf(float(Global.settings.get("touch_scale", 0.0)) - 1.0) < 0.01, "sai mặc định touch_scale")
	_check(str(Global.settings.get("difficulty", "")) == "thuong", "sai mặc định difficulty")

	print("== (c) Máu lính và trùm theo độ khó (0.7 / 1.0 / 1.4)")
	Global.boss_order = ["to_dinh", "luc_dan"]
	Global.set_setting("difficulty", "thuong")
	var mob_norm: int = int(EnemyData.info("bo_binh", 5).hp)
	var boss_norm: int = int(EnemyData.info("boss", 3).hp)
	var leg_norm: int = int(EnemyData.info("legend:ho_tinh_vuong", 5).hp)
	_check(boss_norm == 300, "máu trùm đầu tiên mức Thường phải là 300, nhận %d" % boss_norm)

	Global.set_setting("difficulty", "de")
	var mob_easy: int = int(EnemyData.info("bo_binh", 5).hp)
	var boss_easy: int = int(EnemyData.info("boss", 3).hp)
	var leg_easy: int = int(EnemyData.info("legend:ho_tinh_vuong", 5).hp)
	_check(mob_easy == int(round(float(mob_norm) * 0.7)), "sai máu lính Dễ: %d vs %d" % [mob_easy, mob_norm])
	_check(boss_easy == int(round(float(boss_norm) * 0.7)), "sai máu trùm Dễ: %d vs %d" % [boss_easy, boss_norm])
	_check(leg_easy == int(round(float(leg_norm) * 0.7)), "sai máu Tam Yêu Dễ: %d vs %d" % [leg_easy, leg_norm])

	Global.set_setting("difficulty", "kho")
	var mob_hard: int = int(EnemyData.info("bo_binh", 5).hp)
	var boss_hard: int = int(EnemyData.info("boss", 3).hp)
	var leg_hard: int = int(EnemyData.info("legend:ho_tinh_vuong", 5).hp)
	_check(mob_hard == int(round(float(mob_norm) * 1.4)), "sai máu lính Khó: %d vs %d" % [mob_hard, mob_norm])
	_check(boss_hard == int(round(float(boss_norm) * 1.4)), "sai máu trùm Khó: %d vs %d" % [boss_hard, boss_norm])
	_check(leg_hard == int(round(float(leg_norm) * 1.4)), "sai máu Tam Yêu Khó: %d vs %d" % [leg_hard, leg_norm])

	print("== (d) Sát thương độ khó: Khó ~5.0, Dễ ~3.0 với 1000 lần 4 sát thương")
	seed(202603)
	Global.set_setting("difficulty", "kho")
	var sum_hard: int = 0
	for i in 1000:
		sum_hard += Global.scale_enemy_damage(4)
	var avg_hard: float = float(sum_hard) / 1000.0
	print("   avg_hard = %.3f" % avg_hard)
	_check(absf(avg_hard - 5.0) <= 0.2, "trung bình Khó lệch 5.0: %.3f" % avg_hard)

	Global.set_setting("difficulty", "de")
	var sum_easy: int = 0
	for i in 1000:
		sum_easy += Global.scale_enemy_damage(4)
	var avg_easy: float = float(sum_easy) / 1000.0
	print("   avg_easy = %.3f" % avg_easy)
	_check(absf(avg_easy - 3.0) <= 0.2, "trung bình Dễ lệch 3.0: %.3f" % avg_easy)

	print("== (e) Âm lượng nhạc = 0 tắt tiếng bus Music")
	var music_idx: int = AudioServer.get_bus_index("Music")
	_check(music_idx != -1, "thiếu bus Music")
	Global.set_setting("music", 0.0)
	_check(AudioServer.is_bus_mute(music_idx), "music=0 không mute bus Music")
	Global.set_setting("music", 0.8)
	_check(not AudioServer.is_bus_mute(music_idx), "music=0.8 không unmute bus Music")

	print("== (f) Mở và đóng màn hình Cài đặt không lỗi")
	var sm: CanvasLayer = SettingsMenu.new()
	add_child(sm)
	await _frames(2)
	sm.open()
	await _frames(2)
	_check(sm.visible, "không mở được SettingsMenu")
	sm.close()
	await _frames(2)
	_check(not sm.visible, "không đóng được SettingsMenu")
	sm.queue_free()
	await _frames(2)
	Global.settings = Global.DEFAULT_SETTINGS.duplicate()
	Global.apply_settings()
