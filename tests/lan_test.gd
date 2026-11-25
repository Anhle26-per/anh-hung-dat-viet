extends Node
## Kiểm thử toàn diện LAN Co-op (N1–N8) với 2 tiến trình ENet thật trên 127.0.0.1:
## 1. N1 + Savegame theo Chủ phòng: tạo phòng, khách kết nối, nhận host_profile, chọn tướng của Chủ phòng, sẵn sàng, bắt đầu trận.
## 2. N2: cùng match_seed sinh lưới phòng & loại phòng giống hệt nhau trên cả Chủ phòng và Máy khách.
## 3. N3 + N4 + N5: máu giặc 2 người nhân x1.5; Gánh hàng rong 2 người có 4 kệ (3 + (2-1)); đạn visual_only không gây sát thương kép.
## 4. N7: gục ngã (downed == true, không thua) + đồng đội đứng cạnh cứu trong 3.0s (hp == 2, armor == 0, _invuln >= 1.4).
## 5. N8: rời phòng / rớt mạng đặt Net.is_online() == false, thông báo "Chủ phòng đã rời", tệp save.json của máy khách không bị ghi đè.

const Dungeon = preload("res://scripts/game/dungeon.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const Shop = preload("res://scripts/game/shop.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Player = preload("res://scripts/entities/player.gd")

const TEST_PORT: int = 17777
const HOST_SAVE: String = "user://lan_test_host_save.json"
const CLIENT_SAVE: String = "user://lan_test_client_save.json"
const CLIENT_RESULT: String = "user://lan_test_client_result.json"

var _is_client: bool = false
var _failed: bool = false
var _client_pid: int = -1
var _client_report: Dictionary = {}
var _client_match_started: bool = false
var _client_host_left_reason: String = ""
var _client_host_left_hit: bool = false


func _ready() -> void:
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	_is_client = uargs.has("--lan-client")
	# Bộ đếm 60s tự dừng tránh treo mãi
	get_tree().create_timer(60.0).timeout.connect(func() -> void:
		_fail("Hết giờ kiểm thử LAN (60s) [role=%s]" % ("client" if _is_client else "host")))
	if _is_client:
		_run_client.call_deferred()
	else:
		_run_host.call_deferred()


func _fail(msg: String) -> void:
	if _failed:
		return
	_failed = true
	printerr("LAN TEST THẤT BẠI: ", msg)
	Net.leave_room()
	if not _is_client:
		_kill_client()
		_cleanup_files()
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> bool:
	if not cond:
		_fail(msg)
		return false
	return true


func _kill_client() -> void:
	if _client_pid > 0 and OS.is_process_running(_client_pid):
		OS.kill(_client_pid)
	_client_pid = -1


func _cleanup_files() -> void:
	for p in [HOST_SAVE, CLIENT_SAVE, CLIENT_RESULT, "user://lan_test_host_save_run.json", "user://lan_test_client_save_run.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _dungeon_signature(seed_val: int, lvl: int) -> String:
	var holder := Node2D.new()
	add_child(holder)
	var d := Dungeon.new()
	holder.add_child(d)
	seed(seed_val + lvl * 1009)
	d.generate(lvl)
	var parts: Array[String] = []
	for cell_k in d.rooms:
		var cell: Vector2i = cell_k
		var rm: Node = d.rooms[cell_k]
		var rkind: String = str(rm.get("kind"))
		var rkey: String = str(rm.get("room_key"))
		parts.append("%s:%d,%d:%s" % [rkey, cell.x, cell.y, rkind])
	parts.sort()
	var spos: Vector2 = d.start_position()
	var sig: String = "S=%.1f,%.1f|" % [spos.x, spos.y] + ";".join(parts)
	holder.queue_free()
	return sig


func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if _failed:
			return false
		if bool(pred.call()):
			return true
		await get_tree().process_frame
	return bool(pred.call())


# ================================================================== TIẾN TRÌNH CHỦ PHÒNG (HOST)

func _run_host() -> void:
	_cleanup_files()
	# Chuẩn bị savegame riêng cho Chủ phòng (mở khóa thêm le_loi & thanh_giong + nâng cấp riêng)
	Global.save_path = HOST_SAVE
	Global.run_save_path = "user://lan_test_host_save_run.json"
	Global.coins = 500
	Global.unlocked = ["ngo_quyen", "ba_trieu", "hai_ba_trung", "le_loi", "thanh_giong"]
	Global.upgrades = {"mau": 2, "giap": 1, "nang_luong": 1, "khoi_dau": 0, "hoi_sinh": 0}
	Global.hero_levels = {"le_loi": 4, "ngo_quyen": 2}
	Global.weapon_ranks = {"le_loi": 3, "ngo_quyen": 2}
	Global.settings["difficulty"] = "kho"
	Global.selected_hero = "ngo_quyen"
	Global.save_game()

	Net.world_event_received.connect(_on_host_world_event)

	# --- TEST 1: N1 + Savegame Chủ phòng ---
	var err: int = Net.create_room("PhongTestLAN", "ChuPhong", TEST_PORT)
	if not _assert(err == OK, "create_room thất bại: err=%d" % err):
		return
	if not _assert(Net.is_online() and Net.is_host(), "Host phải is_online & is_host"):
		return
	if not _assert(Net.host_profile.get("unlocked", []).has("le_loi"), "host_profile thiếu le_loi"):
		return
	if not _assert(int(Net.host_profile.get("upgrades", {}).get("mau", 0)) == 2, "host_profile thiếu upgrades.mau==2"):
		return

	# Khởi chạy tiến trình máy khách kết nối tới 127.0.0.1:17777
	var exe: String = OS.get_executable_path()
	var proj: String = ProjectSettings.globalize_path("res://")
	var args: PackedStringArray = PackedStringArray([
		"--headless", "--path", proj, "res://tests/lan_test.tscn", "--", "--lan-client"
	])
	_client_pid = OS.create_process(exe, args)
	if not _assert(_client_pid > 0, "Không khởi chạy được tiến trình máy khách LAN"):
		return

	# Chờ khách kết nối, chọn tướng le_loi (từ kho Chủ phòng) và bấm Sẵn sàng
	var client_ready: bool = await _wait_until(func() -> bool:
		if Net.players.size() < 2:
			return false
		for pid in Net.players:
			if int(pid) != 1:
				var info: Dictionary = Net.players[pid]
				if str(info.get("hero", "")) == "le_loi" and bool(info.get("ready", false)):
					return true
		return false, 15.0)
	if not _assert(client_ready, "Máy khách không vào phòng / chọn le_loi / sẵn sàng kịp trong 15s (players=%s)" % str(Net.players)):
		return

	var client_peer_id: int = 0
	for pid in Net.players:
		if int(pid) != 1:
			client_peer_id = int(pid)
			break

	# Chủ phòng bắt đầu trận
	Net.host_start_match()
	if not _assert(Net.in_match and Net.match_seed > 0, "host_start_match không đặt in_match/match_seed"):
		return

	# Chờ báo cáo N1 + N2 từ máy khách
	var got_report: bool = await _wait_until(func() -> bool:
		return not _client_report.is_empty(), 15.0)
	if not _assert(got_report, "Không nhận được báo cáo N1/N2 từ máy khách"):
		return

	if not _assert(bool(_client_report.get("profile_ok", false)), "Máy khách nhận sai host_profile: %s" % str(_client_report)):
		return
	if not _assert(int(_client_report.get("match_seed", 0)) == Net.match_seed, "match_seed máy khách lệch Chủ phòng"):
		return
	print("[PASS] Test 1 (N1 + Host Savegame): 2-peer ENet 127.0.0.1:%d, khách dùng kho tướng & nâng cấp Chủ phòng" % TEST_PORT)

	# --- TEST 2: N2 cùng match_seed sinh bản đồ giống hệt ---
	var host_sig: String = _dungeon_signature(Net.match_seed, 1)
	var client_sig: String = str(_client_report.get("map_sig", ""))
	if not _assert(host_sig != "" and host_sig == client_sig, "Bản đồ lệch giữa Chủ phòng và Máy khách!\nHost: %s\nClient: %s" % [host_sig, client_sig]):
		return
	print("[PASS] Test 2 (N2): Bản đồ cùng seed giống hệt nhau trên cả 2 tiến trình (%d ký tự)" % host_sig.length())

	# --- TEST 3: N3 + N4 + N5 (Máu giặc x1.5, Gánh hàng 4 kệ, Đạn visual_only không sát thương kép) ---
	var arena := Node2D.new()
	add_child(arena)

	var base_info: Dictionary = EnemyData.info("bo_binh", 1)
	var expected_hp: int = int(round(float(int(base_info.hp)) * 1.5))
	var e := Enemy.new()
	e.setup("bo_binh", 1, null)
	e.position = Vector2(200, 200)
	arena.add_child(e)
	e._spawn_t = 0.0
	if not _assert(e.max_hp == expected_hp and e.hp == expected_hp, "Máu giặc 2 người sai: got %d, want %d (base %d)" % [e.max_hp, expected_hp, int(base_info.hp)]):
		return

	var shop := Shop.new()
	shop.level = 1
	shop.room_key = "0,0"
	shop.position = Vector2(400, 200)
	arena.add_child(shop)
	if not _assert(shop.stands.size() == 4, "Gánh hàng rong 2 người phải có 4 kệ, got %d" % shop.stands.size()):
		return

	# Đạn visual_only chạm giặc không được trừ máu
	var hp_before: int = e.hp
	var vb := Bullet.new()
	vb.setup(true, e.position, Vector2.RIGHT, 200.0, 10, 1.0, "bullet")
	vb.visual_only = true
	arena.add_child(vb)
	vb._on_body_entered(e)
	if not _assert(e.hp == hp_before, "Đạn visual_only đã làm giảm máu giặc (%d -> %d)!" % [hp_before, e.hp]):
		return

	# Đạn thật (visual_only == false) vẫn phải trừ máu bình thường
	var rb := Bullet.new()
	rb.setup(true, e.position, Vector2.RIGHT, 200.0, 4, 1.0, "bullet")
	rb.visual_only = false
	arena.add_child(rb)
	rb._on_body_entered(e)
	if not _assert(e.hp < hp_before, "Đạn thật không gây sát thương cho giặc!"):
		return
	print("[PASS] Test 3 (N3+N4+N5): Máu giặc 2 người=%d (x1.5), Gánh hàng=%d kệ, visual_only không gây sát thương kép" % [e.max_hp, shop.stands.size()])

	# --- TEST 4: N7 Gục ngã & Cứu đồng đội 3.0s ---
	Global.free_revives = 0
	var p1 := Player.new()
	p1.peer_id = 1
	p1.is_local = true
	p1.display_name = "ChuPhong"
	p1.setup("ngo_quyen")
	p1.position = Vector2(100, 100)
	arena.add_child(p1)

	var p2 := Player.new()
	p2.peer_id = client_peer_id
	p2.is_local = false
	p2.display_name = "BanBe"
	p2.setup("le_loi")
	p2.position = Vector2(220, 100)
	p2._remote_pos = Vector2(220, 100)
	arena.add_child(p2)

	var died_emitted: bool = false
	p1.died.connect(func() -> void: died_emitted = true)

	p1._invuln = 0.0
	p1.take_damage(999, "Test")
	if not _assert(p1.downed and not p1.dead and not died_emitted, "Khi còn đồng đội sống, hp<=0 phải vào trạng thái downed chứ không chết hẳn"):
		return
	if not _assert(p1.hp == 0 and p1.armor == 0, "Khi downed, hp & armor phải = 0"):
		return

	# Đồng đội tiến sát trong 28px và đứng cứu 3.0s
	p2.global_position = p1.global_position + Vector2(14.0, 0.0)
	p2._remote_pos = p2.global_position
	var steps: int = 0
	while p1.downed and steps < 35:
		p1._physics_process(0.1)
		steps += 1
	if not _assert(not p1.downed and not p1.dead, "Đồng đội đứng cạnh 3.0s phải cứu sống người gục (revive_progress=%.2f)" % p1.revive_progress):
		return
	if not _assert(p1.hp == 2 and p1.armor == 0 and p1._invuln >= 1.4, "Sau khi được cứu: hp=%d (want 2), armor=%d (want 0), _invuln=%.2f (want >=1.4)" % [p1.hp, p1.armor, p1._invuln]):
		return
	print("[PASS] Test 4 (N7): Gục ngã (downed) không thua, đồng đội cứu sau %.1fs -> hp=%d, armor=%d, _invuln=%.2f" % [float(steps) * 0.1, p1.hp, p1.armor, p1._invuln])

	arena.queue_free()
	await get_tree().process_frame

	# --- TEST 5: N8 Rời phòng sạch + Chủ phòng rời báo cho khách + save.json máy khách không bị ghi đè ---
	Net.leave_room()
	if not _assert(not Net.is_online() and Net.players.is_empty(), "Sau leave_room(), Net.is_online() phải == false"):
		return

	# Chờ máy khách xử lý sự kiện Chủ phòng rời và ghi kết quả kiểm tra
	var got_client_res: bool = await _wait_until(func() -> bool:
		return FileAccess.file_exists(CLIENT_RESULT), 10.0)
	if not _assert(got_client_res, "Không nhận được kết quả N8 từ tiến trình máy khách"):
		return

	# Đợi nhẹ cho máy khách ghi xong file
	await get_tree().create_timer(0.15).timeout
	var raw_res: String = FileAccess.get_file_as_string(CLIENT_RESULT)
	var parsed: Variant = JSON.parse_string(raw_res)
	if not _assert(typeof(parsed) == TYPE_DICTIONARY, "Kết quả N8 của máy khách không hợp lệ: %s" % raw_res):
		return
	var cres: Dictionary = parsed as Dictionary
	if not _assert(bool(cres.get("ok", false)), "Kiểm tra N8 phía máy khách thất bại: %s" % str(cres)):
		return
	if not _assert(str(cres.get("notice", "")) == "Chủ phòng đã rời", "Thông báo mất Chủ phòng sai: '%s'" % str(cres.get("notice", ""))):
		return
	if not _assert(bool(cres.get("offline_after_dc", false)), "Máy khách không reset về is_online()==false sau khi Chủ phòng rời"):
		return
	if not _assert(bool(cres.get("save_untouched", false)), "save.json của máy khách bị ghi đè trong LAN!"):
		return
	print("[PASS] Test 5 (N8): leave_room sạch, máy khách nhận 'Chủ phòng đã rời', save.json máy khách nguyên vẹn")

	_kill_client()
	_cleanup_files()
	print("LAN TEST OK")
	get_tree().quit(0)


func _on_host_world_event(kind: String, data: Dictionary) -> void:
	if kind == "test_client_report":
		_client_report = data.duplicate(true)


# ================================================================== TIẾN TRÌNH MÁY KHÁCH (CLIENT)

func _run_client() -> void:
	# Tạo savegame riêng cho máy khách: chỉ có 77 xu và 3 tướng cơ bản (KHÔNG có le_loi)
	Global.save_path = CLIENT_SAVE
	Global.run_save_path = "user://lan_test_client_save_run.json"
	Global.coins = 77
	Global.unlocked = ["ngo_quyen", "ba_trieu", "hai_ba_trung"]
	Global.upgrades = {"mau": 0, "giap": 0, "nang_luong": 0, "khoi_dau": 0, "hoi_sinh": 0}
	Global.hero_levels = {}
	Global.weapon_ranks = {}
	Global.settings["difficulty"] = "de"
	Global.selected_hero = "ngo_quyen"
	Global.save_game()
	var orig_save_text: String = FileAccess.get_file_as_string(CLIENT_SAVE)

	Net.match_started.connect(func(_s: int, _l: int) -> void:
		_client_match_started = true)
	Net.host_left.connect(func(reason: String) -> void:
		_client_host_left_reason = reason
		_client_host_left_hit = true)

	var err: int = Net.join_room("127.0.0.1", "BanBe", TEST_PORT)
	if not _assert(err == OK, "Client join_room thất bại: err=%d" % err):
		return

	# Chờ nhận host_profile và vào danh sách players
	var joined: bool = await _wait_until(func() -> bool:
		return Net.is_online() and Net.players.has(Net.local_peer_id()) and Net.host_profile.has("unlocked"), 12.0)
	if not _assert(joined, "Client không nhận được lobby/host_profile từ Chủ phòng"):
		return

	# Kiểm tra host_profile: thấy le_loi & thanh_giong + nâng cấp của Chủ phòng
	var unl: Array = Net.host_profile.get("unlocked", [])
	var profile_ok: bool = (
		unl.has("le_loi")
		and unl.has("thanh_giong")
		and Global.eff_upgrade("mau") == 2
		and Global.eff_hero_level("le_loi") == 4
		and Global.eff_weapon_rank("le_loi") == 3
		and Global.eff_difficulty() == "kho"
	)

	# Chọn tướng le_loi (chỉ có trong kho Chủ phòng!) và bấm Sẵn sàng
	Net.request_set_hero("le_loi")
	Net.request_set_ready(true)

	# Chờ Chủ phòng bắt đầu trận
	var started: bool = await _wait_until(func() -> bool:
		return _client_match_started and Net.match_seed > 0, 15.0)
	if not _assert(started, "Client không nhận được match_started từ Chủ phòng"):
		return

	# Kiểm tra N8: gọi end_run / save_run khi đang là máy khách LAN KHÔNG được ghi đè save.json
	Global.run_coins = 999
	Global.end_run("bo_luot")

	# Sinh bản đồ với cùng match_seed và gửi báo cáo cho Chủ phòng
	var map_sig: String = _dungeon_signature(Net.match_seed, 1)
	Net.send_world_event("test_client_report", {
		"profile_ok": profile_ok,
		"match_seed": Net.match_seed,
		"map_sig": map_sig,
	}, true)

	# Chờ Chủ phòng rời phòng (Test 5)
	var host_left_ok: bool = await _wait_until(func() -> bool:
		return _client_host_left_hit, 20.0)

	var after_save_text: String = FileAccess.get_file_as_string(CLIENT_SAVE)
	var save_untouched: bool = (after_save_text == orig_save_text) and not FileAccess.file_exists("user://lan_test_client_save_run.json")
	var notice_val: String = Net.disconnect_notice if Net.disconnect_notice != "" else _client_host_left_reason

	var out: Dictionary = {
		"ok": host_left_ok and (not Net.is_online()) and (notice_val == "Chủ phòng đã rời") and save_untouched,
		"host_left_ok": host_left_ok,
		"offline_after_dc": not Net.is_online(),
		"notice": notice_val,
		"save_untouched": save_untouched,
	}
	var f := FileAccess.open(CLIENT_RESULT, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))
		f.close()
	get_tree().quit(0)
