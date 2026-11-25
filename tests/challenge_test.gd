extends Node
## Kiểm thử thẻ G06: mã thử thách cố định (trùm, bản đồ, phúc lành), bảng điểm lưu/nạp, định dạng chia sẻ, ChallengeMenu.
## Chạy: godot --headless --path . res://tests/challenge_test.tscn  -> in "CHALLENGE TEST OK"

const Dungeon = preload("res://scripts/game/dungeon.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const ChallengeMenu = preload("res://scripts/ui/challenge_menu.gd")
const TEST_SAVE := "user://challenge_test_save.json"

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
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", Global.run_path(), Global.run_path() + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func():
		print("CHALLENGE TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	_wipe()
	if _fail == 0:
		print("CHALLENGE TEST OK")
		get_tree().quit(0)
	else:
		print("CHALLENGE TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _snapshot_challenge(code: String, lv: int) -> Dictionary:
	Global.start_run(code)
	Global.level = lv
	var bosses: Array = Global.boss_order.duplicate()

	var d := Dungeon.new()
	add_child(d)
	seed(Global.challenge_seed(Global.challenge_code) + Global.level * 1009)
	d.generate(Global.level)
	var keys: Array = d.rooms.keys()
	var kinds: Dictionary = {}
	for k in keys:
		kinds[k] = str(d.rooms[k].kind)
	d.queue_free()

	seed(Global.challenge_seed(Global.challenge_code) + Global.level * 7919 + 31)
	var buffs: Array = BuffData.offer({}, 3)
	return {
		"code": Global.challenge_code,
		"seed": Global.challenge_seed(code),
		"bosses": bosses,
		"keys": keys,
		"kinds": kinds,
		"buffs": buffs,
	}


func _run() -> void:
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	_wipe()

	print("== 1. Cùng mã TET2027 hai lần -> trùng boss_order, phòng, loại phòng, phúc lành")
	var s1: Dictionary = _snapshot_challenge("TET2027", 2)
	await _frames(2)
	var s2: Dictionary = _snapshot_challenge("  tet2027  ", 2)
	await _frames(2)
	_check(str(s1.code) == "TET2027" and str(s2.code) == "TET2027", "chuẩn hóa mã thử thách sai")
	_check(int(s1.seed) == int(s2.seed) and int(s1.seed) > 0, "challenge_seed không ổn định")
	_check((s1.bosses as Array).size() >= 10, "boss_order chưa được sinh khi start_run với mã")
	_check(s1.bosses == s2.bosses, "cùng mã TET2027 nhưng boss_order khác nhau")
	_check(s1.keys == s2.keys, "cùng mã TET2027 nhưng dungeon.rooms.keys() khác nhau")
	_check(s1.kinds == s2.kinds, "cùng mã TET2027 nhưng loại phòng khác nhau")
	_check(s1.buffs == s2.buffs and (s1.buffs as Array).size() == 3, "cùng mã TET2027 nhưng phúc lành khác nhau")

	print("== 2. Mã khác XUAN2027 -> khác TET2027")
	var s3: Dictionary = _snapshot_challenge("XUAN2027", 2)
	await _frames(2)
	_check(int(s3.seed) != int(s1.seed), "challenge_seed trùng nhau giữa TET2027 và XUAN2027")
	_check(s3.bosses != s1.bosses, "boss_order trùng nhau giữa TET2027 và XUAN2027")
	_check(s3.keys != s1.keys or s3.kinds != s1.kinds or s3.buffs != s1.buffs, "bản đồ và phúc lành hoàn toàn trùng giữa hai mã khác nhau")

	print("== 2b. Lưu/nạp lượt dở giữ nguyên challenge_code")
	Global.start_run("TET2027")
	Global.resume_data = {"hp": 5, "max_hp": 6, "armor": 3, "max_armor": 5, "energy": 100, "max_energy": 180,
		"weapons": ["giao_tre", ""], "slot": 0}
	_check(Global.save_run(), "save_run thất bại")
	Global.challenge_code = ""
	_check(Global.load_run(), "load_run thất bại")
	_check(Global.challenge_code == "TET2027", "load_run không giữ challenge_code: " + Global.challenge_code)
	Global.clear_run()

	print("== 3. record_score lưu/nạp bảng điểm, tệp lưu cũ không có leaderboard, format_share_text")
	Global.leaderboard = []
	Global.selected_hero = "ngo_quyen"
	Global.start_run("TET2027")
	Global.level = 5
	Global.run_elapsed = 185.0
	Global.run_kills = 42
	var expected_score: int = Global.calc_score(5, 185.0, 42)
	var entry: Dictionary = Global.record_score("thua")
	_check(int(entry.get("score", 0)) == expected_score, "sai điểm: %d vs %d" % [int(entry.get("score", 0)), expected_score])
	_check(str(entry.get("code", "")) == "TET2027", "sai mã trong entry")
	_check(Global.leaderboard.size() == 1, "bảng điểm không có 1 mục sau record_score")

	# Thêm 25 mục để kiểm tra sắp xếp giảm dần và giới hạn 20 mục
	for i in 25:
		Global.start_run("M%02d" % i)
		Global.level = 1 + (i % 7)
		Global.run_elapsed = 100.0 + float(i) * 5.0
		Global.run_kills = i * 3
		Global.record_score("thua")
	_check(Global.leaderboard.size() == 20, "bảng điểm không giới hạn ở 20 mục: %d" % Global.leaderboard.size())
	var sorted_ok: bool = true
	for i in range(Global.leaderboard.size() - 1):
		var a: Dictionary = Global.leaderboard[i]
		var b: Dictionary = Global.leaderboard[i + 1]
		if int(a.get("score", 0)) < int(b.get("score", 0)):
			sorted_ok = false
			break
	_check(sorted_ok, "bảng điểm không được xếp giảm dần theo score")

	# Nạp lại từ save.json
	var top_before: Dictionary = (Global.leaderboard[0] as Dictionary).duplicate()
	Global.leaderboard = []
	Global.load_game()
	_check(Global.leaderboard.size() == 20, "load_game nạp sai số mục leaderboard: %d" % Global.leaderboard.size())
	_check(int((Global.leaderboard[0] as Dictionary).get("score", -1)) == int(top_before.get("score", -2)), "mục đầu bảng điểm sai sau load_game")

	# Tệp lưu cũ không có khóa "leaderboard" -> mặc định []
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 321, "unlocked": ["ngo_quyen"], "selected_hero": "ngo_quyen"}))
	f.close()
	Global.coins = 0
	Global.load_game()
	_check(Global.coins == 321, "tệp lưu cũ nạp sai xu")
	_check(Global.leaderboard.is_empty(), "tệp lưu cũ thiếu leaderboard nhưng không về []")

	# format_share_text chứa đủ mã, tên tướng, màn, số giặc, điểm
	var share: String = Global.format_share_text(entry)
	var hero_name: String = str(HeroData.DATA["ngo_quyen"].name)
	_check(share.contains("TET2027"), "format_share_text thiếu mã thử thách: " + share)
	_check(share.contains(hero_name), "format_share_text thiếu tên tướng: " + share)
	_check(share.contains("5"), "format_share_text thiếu màn: " + share)
	_check(share.contains("42"), "format_share_text thiếu số giặc: " + share)
	_check(share.contains(str(expected_score)), "format_share_text thiếu điểm: " + share)

	print("== 4. Mở và đóng ChallengeMenu headless không lỗi")
	Global.leaderboard = [entry]
	var cm: CanvasLayer = ChallengeMenu.new()
	add_child(cm)
	await _frames(2)
	cm.open()
	await _frames(2)
	_check(cm.visible, "không mở được ChallengeMenu")
	cm.close()
	await _frames(2)
	_check(not cm.visible, "không đóng được ChallengeMenu")
	cm.queue_free()
	await _frames(2)
