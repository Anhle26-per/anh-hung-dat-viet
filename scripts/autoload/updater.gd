extends Node
## Tự động kiểm tra và tải bản vá .pck từ GitHub Releases (không đụng tới save.json).
## Phải đứng đầu [autoload] để nạp user://patch.pck trước khi Global và MainMenu tải tài nguyên.

signal check_finished(has_update: bool, info: Dictionary, error_msg: String)
signal update_available(info: Dictionary)
signal download_progress(downloaded: int, total: int)
signal download_finished(ok: bool, message: String)

const VersionData = preload("res://scripts/data/version.gd")
const Art = preload("res://scripts/art/art.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")

var patch_path: String = "user://patch.pck"
var patch_tmp_path: String = "user://patch.pck.tmp"
var patch_meta_path: String = "user://patch_meta.json"
var manifest_url: String = VersionData.MANIFEST_URL

var base_version: String = VersionData.VERSION
var base_build: int = VersionData.BUILD
var current_version: String = VersionData.VERSION
var current_build: int = VersionData.BUILD
var patch_loaded: bool = false
var latest_info: Dictionary = {}
var state: String = "idle" # idle, checking, available, up_to_date, downloading, ready_restart, error, engine_too_old
var _checked_auto: bool = false
var _popup_shown_once: bool = false

var _chk_req: HTTPRequest = null
var _dl_req: HTTPRequest = null
var _dl_info: Dictionary = {}
var _dl_expected_bytes: int = 0
var _last_prog_bytes: int = -1


func _enter_tree() -> void:
	if not OS.has_feature("editor") and DisplayServer.get_name() != "headless":
		try_mount_saved_patch()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if state == "downloading" and _dl_req != null and is_instance_valid(_dl_req):
		var got: int = _dl_req.get_downloaded_bytes()
		var tot: int = _dl_req.get_body_size()
		if tot <= 0:
			tot = _dl_expected_bytes
		if got != _last_prog_bytes:
			_last_prog_bytes = got
			download_progress.emit(got, tot)


func _read_meta() -> Dictionary:
	if not FileAccess.file_exists(patch_meta_path):
		return {}
	var f: FileAccess = FileAccess.open(patch_meta_path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return (parsed as Dictionary) if parsed is Dictionary else {}


func try_mount_saved_patch() -> bool:
	if HotpatchSync.is_booted_from_main_pack(patch_path):
		patch_loaded = true
		current_version = base_version
		current_build = base_build
		return true
	if not FileAccess.file_exists(patch_path) or not FileAccess.file_exists(patch_meta_path):
		return false
	var meta: Dictionary = _read_meta()
	if meta.is_empty():
		clear_saved_patch()
		return false
	var p_build: int = int(meta.get("build", 0))
	var p_ver: String = str(meta.get("version", ""))
	if p_ver == "":
		clear_saved_patch()
		return false
	# Nếu người chơi cài bản đầy đủ mới hơn bản vá cũ -> tự dọn bản vá cũ
	if (p_build > 0 and base_build > 0 and p_build <= base_build) or (p_build <= 0 and compare_semver(p_ver, base_version) <= 0):
		clear_saved_patch()
		return false
	var min_eng: String = str(meta.get("min_engine", ""))
	if not is_engine_compatible(min_eng):
		clear_saved_patch()
		return false
	var expected_sha: String = str(meta.get("sha256", "")).strip_edges().to_lower()
	if expected_sha != "":
		var actual_sha: String = compute_sha256(patch_path)
		if actual_sha == "" or actual_sha != expected_sha:
			clear_saved_patch()
			return false
	if ProjectSettings.load_resource_pack(patch_path, true):
		patch_loaded = true
		current_version = p_ver
		current_build = p_build if p_build > 0 else base_build
		Art.clear_cache()
		return true
	clear_saved_patch()
	return false


func clear_saved_patch() -> void:
	for p in [patch_path, patch_tmp_path, patch_meta_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	patch_loaded = false
	current_version = base_version
	current_build = base_build


static func compute_sha256(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var ctx := HashingContext.new()
	if ctx.start(HashingContext.HASH_SHA256) != OK:
		f.close()
		return ""
	while f.get_position() < f.get_length():
		var chunk: PackedByteArray = f.get_buffer(65536)
		if chunk.is_empty():
			break
		ctx.update(chunk)
	f.close()
	var digest: PackedByteArray = ctx.finish()
	return digest.hex_encode().to_lower()


static func parse_semver(v: String) -> Array[int]:
	var s: String = v.strip_edges()
	if s.begins_with("v") or s.begins_with("V"):
		s = s.substr(1)
	var dash: int = s.find("-")
	if dash >= 0:
		s = s.substr(0, dash)
	var out: Array[int] = [0, 0, 0]
	var parts: PackedStringArray = s.split(".")
	for i in mini(parts.size(), 3):
		out[i] = int(parts[i])
	return out


static func compare_semver(a: String, b: String) -> int:
	var pa: Array[int] = parse_semver(a)
	var pb: Array[int] = parse_semver(b)
	for i in 3:
		if pa[i] > pb[i]:
			return 1
		if pa[i] < pb[i]:
			return -1
	return 0


static func is_newer(remote_info: Dictionary, cur_build: int, cur_ver: String) -> bool:
	var r_build: int = int(remote_info.get("build", 0))
	if r_build > 0 and cur_build > 0:
		return r_build > cur_build
	var r_ver: String = str(remote_info.get("version", ""))
	if r_ver == "":
		return false
	return compare_semver(r_ver, cur_ver) > 0


static func current_engine_version() -> String:
	var vi: Dictionary = Engine.get_version_info()
	return "%d.%d.%d" % [int(vi.get("major", 4)), int(vi.get("minor", 7)), int(vi.get("patch", 0))]


static func is_engine_compatible(min_eng: String) -> bool:
	var m: String = min_eng.strip_edges()
	if m == "":
		return true
	return compare_semver(current_engine_version(), m) >= 0


func mark_popup_shown() -> void:
	_popup_shown_once = true


func should_auto_show_popup() -> bool:
	return not _popup_shown_once


func check_for_updates(force: bool = false, custom_url: String = "") -> void:
	if not force and (_checked_auto or DisplayServer.get_name() == "headless"):
		return
	if state == "checking" or state == "downloading":
		return
	_checked_auto = true
	state = "checking"
	var url: String = custom_url if custom_url != "" else manifest_url
	if _chk_req != null and is_instance_valid(_chk_req):
		_chk_req.queue_free()
	_chk_req = HTTPRequest.new()
	_chk_req.timeout = 10.0
	_chk_req.max_redirects = 8
	add_child(_chk_req)
	_chk_req.request_completed.connect(_on_check_completed)
	var headers := PackedStringArray(["User-Agent: AnhHungDatViet-Updater", "Accept: application/json"])
	var err: int = _chk_req.request(url, headers)
	if err != OK:
		state = "error"
		_cleanup_check_req()
		check_finished.emit(false, {}, "Không gửi được yêu cầu kiểm tra (mã %d)." % err)


func _cleanup_check_req() -> void:
	if _chk_req != null and is_instance_valid(_chk_req):
		_chk_req.queue_free()
		_chk_req = null


func _on_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_cleanup_check_req()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		state = "error"
		check_finished.emit(false, {}, "Không kết nối được máy chủ cập nhật (HTTP %d)." % response_code)
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		state = "error"
		check_finished.emit(false, {}, "Dữ liệu version.json không hợp lệ.")
		return
	var info: Dictionary = parsed as Dictionary
	var r_ver: String = str(info.get("version", ""))
	var pck_url: String = str(info.get("pck_url", ""))
	if r_ver == "" or pck_url == "":
		state = "error"
		check_finished.emit(false, {}, "Thiếu thông tin phiên bản trong version.json.")
		return
	if is_newer(info, current_build, current_version):
		latest_info = info
		if not is_engine_compatible(str(info.get("min_engine", ""))):
			state = "engine_too_old"
		else:
			state = "available"
		update_available.emit(info)
		check_finished.emit(true, info, "")
	else:
		latest_info = info
		state = "up_to_date"
		check_finished.emit(false, info, "")


func start_download(info: Dictionary = {}) -> void:
	var target: Dictionary = info if not info.is_empty() else latest_info
	var pck_url: String = str(target.get("pck_url", ""))
	if pck_url == "":
		state = "error"
		download_finished.emit(false, "Không có đường dẫn tải bản cập nhật.")
		return
	if state == "downloading":
		return
	_dl_info = target.duplicate()
	_dl_expected_bytes = int(target.get("size_bytes", 0))
	_last_prog_bytes = -1
	if FileAccess.file_exists(patch_tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(patch_tmp_path))
	state = "downloading"
	if _dl_req != null and is_instance_valid(_dl_req):
		_dl_req.queue_free()
	_dl_req = HTTPRequest.new()
	_dl_req.timeout = 120.0
	_dl_req.max_redirects = 8
	_dl_req.download_file = patch_tmp_path
	add_child(_dl_req)
	_dl_req.request_completed.connect(_on_download_completed)
	var headers := PackedStringArray(["User-Agent: AnhHungDatViet-Updater"])
	var err: int = _dl_req.request(pck_url, headers)
	if err != OK:
		state = "error"
		_cleanup_dl_req()
		download_finished.emit(false, "Không bắt đầu được quá trình tải (mã %d)." % err)


func _cleanup_dl_req() -> void:
	if _dl_req != null and is_instance_valid(_dl_req):
		_dl_req.queue_free()
		_dl_req = null


func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_cleanup_dl_req()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if FileAccess.file_exists(patch_tmp_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(patch_tmp_path))
		state = "error"
		download_finished.emit(false, "Tải bản vá thất bại (HTTP %d)." % response_code)
		return
	if not FileAccess.file_exists(patch_tmp_path):
		state = "error"
		download_finished.emit(false, "Không tìm thấy tệp tạm sau khi tải.")
		return
	var f_chk: FileAccess = FileAccess.open(patch_tmp_path, FileAccess.READ)
	var actual_size: int = int(f_chk.get_length()) if f_chk != null else 0
	if f_chk != null:
		f_chk.close()
	if actual_size <= 0:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(patch_tmp_path))
		state = "error"
		download_finished.emit(false, "Tệp bản vá tải về bị rỗng.")
		return
	var expected_sha: String = str(_dl_info.get("sha256", "")).strip_edges().to_lower()
	if expected_sha != "":
		var actual_sha: String = compute_sha256(patch_tmp_path)
		if actual_sha == "" or actual_sha != expected_sha:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(patch_tmp_path))
			state = "error"
			download_finished.emit(false, "Tệp tải về bị lỗi kiểm tra SHA-256. Vui lòng thử lại.")
			return
	var abs_final: String = ProjectSettings.globalize_path(patch_path)
	var abs_tmp: String = ProjectSettings.globalize_path(patch_tmp_path)
	if FileAccess.file_exists(patch_path):
		DirAccess.remove_absolute(abs_final)
	var rn_err: int = DirAccess.rename_absolute(abs_tmp, abs_final)
	if rn_err != OK:
		state = "error"
		download_finished.emit(false, "Không thể lưu tệp bản vá (mã %d)." % rn_err)
		return
	var meta: Dictionary = {
		"version": str(_dl_info.get("version", current_version)),
		"build": int(_dl_info.get("build", current_build + 1)),
		"sha256": expected_sha if expected_sha != "" else compute_sha256(patch_path),
		"min_engine": str(_dl_info.get("min_engine", VersionData.MIN_ENGINE)),
		"notes": str(_dl_info.get("notes", "")),
	}
	var mf: FileAccess = FileAccess.open(patch_meta_path, FileAccess.WRITE)
	if mf == null:
		state = "error"
		download_finished.emit(false, "Không ghi được tệp patch_meta.json.")
		return
	mf.store_string(JSON.stringify(meta, "\t"))
	mf.close()
	state = "ready_restart"
	download_finished.emit(true, "Tải xong bản v%s!" % str(meta.version))


func restart_to_apply() -> void:
	if DisplayServer.get_name() == "headless":
		try_mount_saved_patch()
		return
	if OS.has_feature("mobile"):
		try_mount_saved_patch()
		HotpatchSync.ensure_autoloads_synced(get_tree())
		get_tree().reload_current_scene()
		return
	if FileAccess.file_exists(patch_path):
		OS.set_restart_on_exit(true, PackedStringArray(["--main-pack", ProjectSettings.globalize_path(patch_path)]))
	else:
		OS.set_restart_on_exit(true)
	get_tree().quit()
