extends CanvasLayer
## Hộp thoại thông báo và tải bản vá .pck trong game.

const UI = preload("res://scripts/ui/ui.gd")
const VersionData = preload("res://scripts/data/version.gd")

var _info: Dictionary = {}
var _root: Control = null
var _status_lbl: Label = null
var _progress: ProgressBar = null
var _btn_primary: Button = null
var _btn_secondary: Button = null


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if not Updater.download_progress.is_connected(_on_dl_progress):
		Updater.download_progress.connect(_on_dl_progress)
	if not Updater.download_finished.is_connected(_on_dl_finished):
		Updater.download_finished.connect(_on_dl_finished)


func _exit_tree() -> void:
	if Updater.download_progress.is_connected(_on_dl_progress):
		Updater.download_progress.disconnect(_on_dl_progress)
	if Updater.download_finished.is_connected(_on_dl_finished):
		Updater.download_finished.disconnect(_on_dl_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Updater.state == "downloading":
		return
	if event.is_action_pressed("pause"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		close()


func open(info: Dictionary = {}) -> void:
	_info = info if not info.is_empty() else Updater.latest_info
	if _info.is_empty():
		return
	_rebuild()
	visible = true


func close() -> void:
	if Updater.state == "downloading":
		return
	visible = false


func _style(border_col: Color, bg_col: Color, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _rebuild() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UI.make_theme()
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(440, 0)
	frame.add_theme_stylebox_override("panel", _style(Color(0.95, 0.76, 0.30), Color(0.14, 0.06, 0.09, 0.97), 2))
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	frame.add_child(vbox)

	var new_ver: String = str(_info.get("version", "?"))
	var sz_bytes: int = int(_info.get("size_bytes", 0))
	var sz_txt: String = " (~%.1f MB)" % (float(sz_bytes) / 1048576.0) if sz_bytes > 0 else ""

	vbox.add_child(UI.label("CẬP NHẬT MỚI: v%s" % new_ver, 25, Color(1.0, 0.86, 0.35)))
	vbox.add_child(UI.label("Bản hiện tại: v%s  →  Mới: v%s%s" % [Updater.current_version, new_ver, sz_txt], 14, Color(0.88, 0.88, 0.94)))

	var notes_box := PanelContainer.new()
	notes_box.add_theme_stylebox_override("panel", _style(Color(0.55, 0.38, 0.22), Color(0.09, 0.04, 0.07, 0.9), 1))
	var notes_v := VBoxContainer.new()
	notes_v.add_theme_constant_override("separation", 3)
	notes_box.add_child(notes_v)
	notes_v.add_child(UI.label("Nội dung cập nhật:", 13, Color(1.0, 0.85, 0.45)))
	var notes_txt: String = str(_info.get("notes", "Bản vá cải tiến và sửa lỗi mới nhất."))
	var nl := UI.label(notes_txt, 14, Color(0.95, 0.92, 0.88), true)
	nl.custom_minimum_size = Vector2(390, 0)
	notes_v.add_child(nl)
	vbox.add_child(notes_box)

	vbox.add_child(UI.label("Dữ liệu lưu game (xu, tướng, vũ khí) được giữ nguyên 100%.", 13, Color(0.55, 1.0, 0.65)))

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(390, 16)
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.value = 0.0
	_progress.visible = false
	vbox.add_child(_progress)

	_status_lbl = UI.label("", 13, Color(1.0, 0.88, 0.55), true)
	_status_lbl.custom_minimum_size = Vector2(390, 0)
	vbox.add_child(_status_lbl)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 12)
	vbox.add_child(btns)

	_btn_primary = UI.button("Cập nhật ngay", _on_primary, 16, 196.0)
	_btn_secondary = UI.button("Để sau", close, 16, 130.0)
	btns.add_child(_btn_primary)
	btns.add_child(_btn_secondary)
	_sync_state("")


func _sync_state(msg: String) -> void:
	if not is_instance_valid(_btn_primary):
		return
	var st: String = Updater.state
	_btn_primary.disabled = false
	_btn_secondary.disabled = false
	match st:
		"engine_too_old":
			_progress.visible = false
			_status_lbl.text = "Phiên bản cần bộ máy mới hơn (%s). Vui lòng tải bản đầy đủ!" % str(_info.get("min_engine", ""))
			_btn_primary.text = "Mở trang tải bản đầy đủ"
			_btn_secondary.text = "Để sau"
		"downloading":
			_progress.visible = true
			_status_lbl.text = msg if msg != "" else "Đang tải bản vá..."
			_btn_primary.text = "Đang tải..."
			_btn_primary.disabled = true
			_btn_secondary.disabled = true
		"ready_restart":
			_progress.visible = true
			_progress.value = 100.0
			_status_lbl.text = msg if msg != "" else "Đã sẵn sàng! Khởi động lại để áp dụng bản mới."
			_btn_primary.text = "Áp dụng & Vào lại menu" if OS.has_feature("mobile") else "Khởi động lại ngay"
			_btn_secondary.text = "Để sau"
		"error":
			_progress.visible = false
			_status_lbl.text = msg if msg != "" else "Cập nhật không thành công."
			_btn_primary.text = "Thử lại"
			_btn_secondary.text = "Đóng"
		_:
			_progress.visible = false
			_status_lbl.text = ""
			_btn_primary.text = "Cập nhật ngay"
			_btn_secondary.text = "Để sau"


func _on_primary() -> void:
	match Updater.state:
		"engine_too_old":
			OS.shell_open(str(_info.get("release_url", VersionData.RELEASES_URL)))
		"ready_restart":
			Updater.restart_to_apply()
		"downloading":
			return
		_:
			Updater.start_download(_info)
			_sync_state("Đang kết nối...")


func _on_dl_progress(downloaded: int, total: int) -> void:
	if not visible or not is_instance_valid(_progress):
		return
	_progress.visible = true
	if total > 0:
		var pct: float = clampf(float(downloaded) * 100.0 / float(total), 0.0, 100.0)
		_progress.value = pct
		_status_lbl.text = "Đang tải: %.2f / %.2f MB (%d%%)" % [float(downloaded) / 1048576.0, float(total) / 1048576.0, int(round(pct))]
	else:
		_status_lbl.text = "Đang tải: %d KB..." % int(downloaded / 1024)


func _on_dl_finished(_ok: bool, message: String) -> void:
	if not visible:
		return
	_sync_state(message)
