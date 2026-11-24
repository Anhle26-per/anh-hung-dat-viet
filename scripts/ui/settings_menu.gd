extends CanvasLayer
## Màn hình Cài đặt: âm lượng, rung màn hình, toàn màn hình, cỡ nút cảm ứng, độ khó.

signal closed

const UI = preload("res://scripts/ui/ui.gd")

var _music_slider: HSlider = null
var _music_val: Label = null
var _sfx_slider: HSlider = null
var _sfx_val: Label = null
var _shake_btn: Button = null
var _fs_row: HBoxContainer = null
var _fs_btn: Button = null
var _touch_row: HBoxContainer = null
var _touch_btns: Dictionary = {}
var _diff_btns: Dictionary = {}
var _syncing: bool = false


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = UI.make_theme()
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	box.add_child(UI.label("CÀI ĐẶT", 28, Color(1.0, 0.85, 0.35)))

	# 1. Âm lượng nhạc
	var r_mus := _make_row("Âm lượng nhạc")
	_music_slider = HSlider.new()
	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.05
	_music_slider.custom_minimum_size = Vector2(130, 18)
	_music_slider.value_changed.connect(_on_music_changed)
	r_mus.add_child(_music_slider)
	_music_val = UI.label("80%", 16, Color(0.95, 0.9, 0.75))
	_music_val.custom_minimum_size = Vector2(44, 0)
	r_mus.add_child(_music_val)
	box.add_child(r_mus)

	# 2. Âm lượng hiệu ứng
	var r_sfx := _make_row("Âm lượng hiệu ứng")
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.custom_minimum_size = Vector2(130, 18)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	r_sfx.add_child(_sfx_slider)
	_sfx_val = UI.label("90%", 16, Color(0.95, 0.9, 0.75))
	_sfx_val.custom_minimum_size = Vector2(44, 0)
	r_sfx.add_child(_sfx_val)
	box.add_child(r_sfx)

	# 3. Rung màn hình
	var r_shake := _make_row("Rung màn hình")
	_shake_btn = UI.button("Bật", _on_toggle_shake, 16, 90.0)
	_shake_btn.custom_minimum_size = Vector2(90, 24)
	r_shake.add_child(_shake_btn)
	box.add_child(r_shake)

	# 4. Toàn màn hình (chỉ máy tính)
	_fs_row = _make_row("Toàn màn hình")
	_fs_btn = UI.button("Tắt", _on_toggle_fullscreen, 16, 90.0)
	_fs_btn.custom_minimum_size = Vector2(90, 24)
	_fs_row.add_child(_fs_btn)
	_fs_row.visible = not OS.has_feature("mobile") and not OS.has_feature("web")
	box.add_child(_fs_row)

	# 5. Cỡ nút cảm ứng (chỉ hiện khi bật touch_mode)
	_touch_row = _make_row("Cỡ nút cảm ứng")
	for spec in [[0.8, "Nhỏ"], [1.0, "Vừa"], [1.25, "Lớn"]]:
		var sc: float = float(spec[0])
		var lbl: String = str(spec[1])
		var b := UI.button(lbl, _on_touch_scale.bind(sc), 14, 54.0)
		b.custom_minimum_size = Vector2(54, 24)
		_touch_row.add_child(b)
		_touch_btns[sc] = b
	box.add_child(_touch_row)

	# 6. Độ khó
	var r_diff := _make_row("Độ khó")
	for pair in [["de", "Dễ"], ["thuong", "Thường"], ["kho", "Khó"]]:
		var did: String = str(pair[0])
		var dname: String = str(pair[1])
		var b := UI.button(dname, _on_difficulty.bind(did), 14, 62.0)
		b.custom_minimum_size = Vector2(62, 24)
		r_diff.add_child(b)
		_diff_btns[did] = b
	box.add_child(r_diff)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	box.add_child(spacer)
	box.add_child(UI.center(UI.button("Mở thư mục nhật ký", _on_open_log_dir, 14, 190.0)))
	box.add_child(UI.center(UI.button("Đóng", close, 18, 140.0)))

	refresh()


func _make_row(title: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var lbl := UI.label(title, 16, Color(0.95, 0.9, 0.8))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	return h


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	refresh()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	Global.save_game()
	closed.emit()


func refresh() -> void:
	_syncing = true
	var mv: float = float(Global.settings.get("music", 0.8))
	var sv: float = float(Global.settings.get("sfx", 0.9))
	_music_slider.value = mv
	_music_val.text = "%d%%" % int(round(mv * 100.0))
	_sfx_slider.value = sv
	_sfx_val.text = "%d%%" % int(round(sv * 100.0))
	_shake_btn.text = "Bật" if bool(Global.settings.get("shake", true)) else "Tắt"
	_fs_btn.text = "Bật" if bool(Global.settings.get("fullscreen", false)) else "Tắt"
	_touch_row.visible = Global.touch_mode
	var cur_ts: float = float(Global.settings.get("touch_scale", 1.0))
	for sc in _touch_btns:
		var b: Button = _touch_btns[sc]
		b.modulate = Color(1.0, 0.9, 0.45) if is_equal_approx(float(sc), cur_ts) else Color(0.75, 0.72, 0.7)
	var cur_diff: String = str(Global.settings.get("difficulty", "thuong"))
	for did in _diff_btns:
		var b2: Button = _diff_btns[did]
		b2.modulate = Color(1.0, 0.9, 0.45) if str(did) == cur_diff else Color(0.75, 0.72, 0.7)
	_syncing = false


func _on_music_changed(v: float) -> void:
	if _syncing:
		return
	Global.set_setting("music", v)
	_music_val.text = "%d%%" % int(round(v * 100.0))


func _on_sfx_changed(v: float) -> void:
	if _syncing:
		return
	Global.set_setting("sfx", v)
	_sfx_val.text = "%d%%" % int(round(v * 100.0))


func _on_toggle_shake() -> void:
	Global.set_setting("shake", not bool(Global.settings.get("shake", true)))
	refresh()


func _on_toggle_fullscreen() -> void:
	Global.set_setting("fullscreen", not bool(Global.settings.get("fullscreen", false)))
	refresh()


func _on_touch_scale(sc: float) -> void:
	Global.set_setting("touch_scale", sc)
	refresh()


func _on_difficulty(did: String) -> void:
	Global.set_setting("difficulty", did)
	refresh()


func _on_open_log_dir() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))
