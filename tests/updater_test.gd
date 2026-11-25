extends Node
## Kiểm thử Auto-Updater (so sánh phiên bản, SHA-256, tải bản vá qua HTTP loopback cục bộ, chống hỏng tệp, dọn bản vá cũ & UpdatePopup).
## Chạy: godot --headless --path . res://tests/updater_test.tscn -> in "UPDATER TEST OK"

const UpdatePopup = preload("res://scripts/ui/update_popup.gd")

const TEST_SAVE := "user://updater_test_save.json"
const TEST_PATCH := "user://updater_test_patch.pck"
const TEST_TMP := "user://updater_test_patch.pck.tmp"
const TEST_META := "user://updater_test_patch_meta.json"

var _fail: int = 0
var _server: TCPServer = null
var _port: int = 0
var _routes: Dictionary = {}
var _clients: Array = []


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _cleanup() -> void:
	if _server != null:
		_server.stop()
		_server = null
	_clients.clear()
	for p in [TEST_SAVE, TEST_PATCH, TEST_TMP, TEST_META]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	Updater.clear_saved_patch()
	Updater.patch_path = "user://patch.pck"
	Updater.patch_tmp_path = "user://patch.pck.tmp"
	Updater.patch_meta_path = "user://patch_meta.json"
	Updater.state = "idle"
	Updater.latest_info = {}


func _start_http_server() -> bool:
	_server = TCPServer.new()
	for p in range(18421, 18445):
		if _server.listen(p, "127.0.0.1") == OK:
			_port = p
			return true
	return false


func _process(_delta: float) -> void:
	if _server == null:
		return
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if peer != null:
			_clients.append({"peer": peer, "buf": ""})
	var keep: Array = []
	var now: int = Time.get_ticks_msec()
	for item_v in _clients:
		var item: Dictionary = item_v
		var peer: StreamPeerTCP = item["peer"]
		peer.poll()
		var st: int = peer.get_status()
		if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
			continue
		var close_at: int = int(item.get("close_at", 0))
		if close_at > 0:
			if now >= close_at:
				peer.disconnect_from_host()
				continue
			keep.append(item)
			continue
		var avail: int = peer.get_available_bytes()
		if avail > 0:
			var chunk: PackedByteArray = peer.get_data(avail)[1]
			item["buf"] = str(item["buf"]) + chunk.get_string_from_utf8()
			var req_txt: String = str(item["buf"])
			if req_txt.contains("\r\n\r\n") or req_txt.contains("\n\n"):
				_serve_http(peer, req_txt)
				item["close_at"] = now + 250
		keep.append(item)
	_clients = keep


func _serve_http(peer: StreamPeerTCP, req_txt: String) -> void:
	var first_line: String = req_txt.split("\n")[0].strip_edges()
	var parts: PackedStringArray = first_line.split(" ")
	var path: String = parts[1] if parts.size() >= 2 else "/"
	if not _routes.has(path):
		var nf := PackedByteArray("Not Found".to_utf8_buffer())
		var hdr: String = "HTTP/1.1 404 Not Found\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % nf.size()
		peer.put_data(hdr.to_utf8_buffer())
		peer.put_data(nf)
		return
	var route: Dictionary = _routes[path]
	var body: PackedByteArray = route["body"]
	var ctype: String = str(route.get("ctype", "application/octet-stream"))
	var hdr2: String = "HTTP/1.1 200 OK\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [ctype, body.size()]
	peer.put_data(hdr2.to_utf8_buffer())
	peer.put_data(body)


func _sha256_bytes(buf: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(buf)
	return ctx.finish().hex_encode().to_lower()


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func():
		print("UPDATER TEST FAILED: quá thời gian")
		_cleanup()
		get_tree().quit(1))
	Global.save_path = TEST_SAVE
	await _frames(2)
	await _run()
	_cleanup()
	if _fail == 0:
		print("UPDATER TEST OK")
		get_tree().quit(0)
	else:
		print("UPDATER TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra so sánh phiên bản & tương thích bộ máy")
	_check(Updater.compare_semver("1.2.1", "1.2.0") == 1, "1.2.1 phải lớn hơn 1.2.0")
	_check(Updater.compare_semver("v1.2.0", "1.2.0") == 0, "v1.2.0 phải bằng 1.2.0")
	_check(Updater.compare_semver("1.1.9", "1.2.0") == -1, "1.1.9 phải nhỏ hơn 1.2.0")
	_check(Updater.is_newer({"version": "1.2.1", "build": 121}, 120, "1.2.0"), "build 121 phải mới hơn 120")
	_check(not Updater.is_newer({"version": "1.2.0", "build": 120}, 120, "1.2.0"), "cùng build không phải bản mới")
	_check(Updater.is_engine_compatible("4.7.2"), "engine hiện tại phải tương thích >= 4.7.2")
	_check(not Updater.is_engine_compatible("9.9.0"), "engine 9.9.0 phải báo không tương thích")

	print("== 2. Kiểm tra compute_sha256")
	var sample := PackedByteArray("AnhHungDatVietPatchBytes".to_utf8_buffer())
	var f_sha := FileAccess.open(TEST_TMP, FileAccess.WRITE)
	f_sha.store_buffer(sample)
	f_sha.close()
	_check(Updater.compute_sha256(TEST_TMP) == _sha256_bytes(sample), "compute_sha256 không khớp")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_TMP))

	print("== 3. Kiểm tra tải kiểm tra cập nhật & SHA-256 qua HTTP loopback")
	var srv_ok: bool = _start_http_server()
	_check(srv_ok, "không mở được máy chủ HTTP loopback")
	if not srv_ok:
		return

	Updater.patch_path = TEST_PATCH
	Updater.patch_tmp_path = TEST_TMP
	Updater.patch_meta_path = TEST_META
	Updater.clear_saved_patch()

	var payload := PackedByteArray("FAKE_PCK_PAYLOAD_FOR_HTTP_TEST_123456".to_utf8_buffer())
	var good_sha: String = _sha256_bytes(payload)
	var base_url: String = "http://127.0.0.1:%d" % _port
	_routes["/AnhHungDatViet.pck"] = {"ctype": "application/octet-stream", "body": payload}
	_routes["/version.json"] = {
		"ctype": "application/json",
		"body": JSON.stringify({
			"version": "1.3.0",
			"build": 130,
			"min_engine": "4.7.2",
			"size_bytes": payload.size(),
			"sha256": good_sha,
			"pck_url": base_url + "/AnhHungDatViet.pck",
			"release_url": base_url + "/releases",
			"notes": "Thử nghiệm tự cập nhật qua HTTP!",
		}).to_utf8_buffer(),
	}

	var chk_done: Array = [false, false, ""]
	var on_chk := func(has_upd: bool, _info: Dictionary, err: String):
		chk_done[0] = true
		chk_done[1] = has_upd
		chk_done[2] = err
	Updater.check_finished.connect(on_chk, CONNECT_ONE_SHOT)
	Updater.check_for_updates(true, base_url + "/version.json")
	var t0: int = Time.get_ticks_msec()
	while not chk_done[0] and Time.get_ticks_msec() - t0 < 5000:
		await _frames(1)
	_check(bool(chk_done[0]) and bool(chk_done[1]), "check_for_updates phải phát hiện v1.3.0 (err=%s)" % str(chk_done[2]))
	_check(Updater.state == "available", "state phải là available (nhận %s)" % Updater.state)

	# Mở UpdatePopup xem hộp thoại
	var pop := UpdatePopup.new()
	add_child(pop)
	pop.open(Updater.latest_info)
	await _frames(2)
	_check(pop.visible and pop._btn_primary != null, "UpdatePopup phải mở hiển thị nút Cập nhật ngay")

	# Tải bản vá hợp lệ
	var dl_done: Array = [false, false, ""]
	var on_dl := func(ok: bool, msg: String):
		dl_done[0] = true
		dl_done[1] = ok
		dl_done[2] = msg
	Updater.download_finished.connect(on_dl, CONNECT_ONE_SHOT)
	Updater.start_download(Updater.latest_info)
	t0 = Time.get_ticks_msec()
	while not dl_done[0] and Time.get_ticks_msec() - t0 < 5000:
		await _frames(1)
	_check(bool(dl_done[0]) and bool(dl_done[1]), "tải bản vá hợp lệ thất bại: %s" % str(dl_done[2]))
	_check(Updater.state == "ready_restart", "state sau khi tải xong phải là ready_restart")
	_check(FileAccess.file_exists(TEST_PATCH) and FileAccess.file_exists(TEST_META), "phải lưu cả patch.pck và patch_meta.json")
	_check(Updater.compute_sha256(TEST_PATCH) == good_sha, "tệp tải về phải khớp SHA-256")
	pop.close()
	pop.queue_free()
	await _frames(2)

	print("== 4. Kiểm tra từ chối tệp hỏng SHA-256 & dọn bản vá cũ hơn bản gốc")
	var bad_info: Dictionary = Updater.latest_info.duplicate()
	bad_info["sha256"] = "0000000000000000000000000000000000000000000000000000000000000000"
	var bad_done: Array = [false, true, ""]
	Updater.download_finished.connect(func(ok: bool, msg: String):
		bad_done[0] = true
		bad_done[1] = ok
		bad_done[2] = msg, CONNECT_ONE_SHOT)
	Updater.start_download(bad_info)
	t0 = Time.get_ticks_msec()
	while not bad_done[0] and Time.get_ticks_msec() - t0 < 5000:
		await _frames(1)
	_check(bool(bad_done[0]) and not bool(bad_done[1]), "phải từ chối bản vá sai SHA-256")
	_check(not FileAccess.file_exists(TEST_TMP), "tệp tạm hỏng SHA-256 phải bị xóa ngay")

	# Stale patch cleanup: build <= base_build phải bị xóa sạch khi gọi try_mount_saved_patch()
	var stale_mf := FileAccess.open(TEST_META, FileAccess.WRITE)
	stale_mf.store_string(JSON.stringify({"version": "1.0.0", "build": 100, "sha256": good_sha, "min_engine": "4.7.2"}))
	stale_mf.close()
	var mounted_stale: bool = Updater.try_mount_saved_patch()
	_check(not mounted_stale and not FileAccess.file_exists(TEST_PATCH), "bản vá cũ hơn bản gốc phải bị tự dọn")

	# min_engine quá cao -> engine_too_old
	_routes["/version_old_eng.json"] = {
		"ctype": "application/json",
		"body": JSON.stringify({
			"version": "2.0.0",
			"build": 200,
			"min_engine": "9.9.9",
			"pck_url": base_url + "/AnhHungDatViet.pck",
			"notes": "Cần Godot mới.",
		}).to_utf8_buffer(),
	}
	var eng_done: Array = [false]
	Updater.check_finished.connect(func(_h: bool, _i: Dictionary, _e: String): eng_done[0] = true, CONNECT_ONE_SHOT)
	Updater.check_for_updates(true, base_url + "/version_old_eng.json")
	t0 = Time.get_ticks_msec()
	while not eng_done[0] and Time.get_ticks_msec() - t0 < 5000:
		await _frames(1)
	_check(Updater.state == "engine_too_old", "min_engine=9.9.9 phải đặt state = engine_too_old (nhận %s)" % Updater.state)
