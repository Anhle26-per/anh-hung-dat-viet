extends CanvasLayer
## Màn hình Thử thách & Chế độ v2.0: Badass Mode, Boss Rush (12 Trùm), 8 Biến số (Mutators),
## Thử thách Hằng ngày, Mã thử thách & Bảng điểm cục bộ.

signal closed

const UI = preload("res://scripts/ui/ui.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const RunModes = preload("res://scripts/data/run_modes.gd")

var _tab: String = "modes"
var _body_box: VBoxContainer = null
var _tab_modes_btn: Button = null
var _tab_board_btn: Button = null
var _code_input: LineEdit = null
var _status_label: Label = null
var _list_box: VBoxContainer = null
var _copy_btn: Button = null
var _selected_idx: int = 0
var _row_btns: Array = []


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.76)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = UI.make_theme()
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(592, 336)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	box.add_child(UI.label("THỬ THÁCH & CHẾ ĐỘ CHIẾN ĐẤU", 22, Color(1.0, 0.85, 0.35)))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	_tab_modes_btn = UI.button("Chế độ & Biến số", _switch_tab.bind("modes"), 14, 180.0)
	_tab_modes_btn.custom_minimum_size = Vector2(180, 26)
	tabs.add_child(_tab_modes_btn)
	_tab_board_btn = UI.button("Mã & Bảng điểm", _switch_tab.bind("board"), 14, 180.0)
	_tab_board_btn.custom_minimum_size = Vector2(180, 26)
	tabs.add_child(_tab_board_btn)

	_body_box = VBoxContainer.new()
	_body_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_box.add_theme_constant_override("separation", 4)
	box.add_child(_body_box)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	_copy_btn = UI.button("Chép kết quả", _on_copy_selected, 14, 150.0)
	_copy_btn.custom_minimum_size = Vector2(150, 26)
	actions.add_child(_copy_btn)
	var close_btn := UI.button("Đóng", close, 14, 120.0)
	close_btn.custom_minimum_size = Vector2(120, 26)
	actions.add_child(close_btn)
	box.add_child(actions)

	refresh()


func _switch_tab(tab_name: String) -> void:
	_tab = tab_name
	refresh()


func _make_columns_row(vals: Array, col: Color, font_sz: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var widths: Array[int] = [30, 84, 140, 42, 46, 56, 74]
	for i in vals.size():
		var l := UI.label(str(vals[i]), font_sz, col)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.clip_text = true
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if (i == 1 or i == 2) else HORIZONTAL_ALIGNMENT_CENTER
		if i == 2:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			l.custom_minimum_size = Vector2(widths[i], 0)
		h.add_child(l)
	return h


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and ke.physical_keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause") and (_code_input == null or not _code_input.has_focus()):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _copy_btn != null:
		_copy_btn.text = "Chép kết quả"
	refresh()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func refresh() -> void:
	if _body_box == null:
		return
	for c in _body_box.get_children():
		c.queue_free()
	_code_input = null
	_status_label = null
	_list_box = null
	_row_btns.clear()
	if _tab_modes_btn != null:
		_tab_modes_btn.disabled = (_tab == "modes")
	if _tab_board_btn != null:
		_tab_board_btn.disabled = (_tab == "board")
	if _tab == "modes":
		_build_modes_tab()
	else:
		_build_board_tab()


func _build_modes_tab() -> void:
	if _copy_btn != null:
		_copy_btn.visible = false

	# Hàng 1: Badass Mode + Boss Rush + Thử thách Hằng ngày
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 6)
	_body_box.add_child(top_row)

	var b_badass := UI.button("Ác Mộng (Badass): BẬT" if Global.badass_mode else "Ác Mộng (Badass): TẮT", _on_toggle_badass, 13, 184.0)
	b_badass.custom_minimum_size = Vector2(184, 28)
	b_badass.modulate = Color(1.0, 0.38, 0.42) if Global.badass_mode else Color(0.84, 0.84, 0.9)
	top_row.add_child(b_badass)

	var b_boss := UI.button("Boss Rush (12 Trùm)", _on_start_boss_rush, 13, 178.0)
	b_boss.custom_minimum_size = Vector2(178, 28)
	b_boss.modulate = Color(1.0, 0.68, 0.35)
	top_row.add_child(b_boss)

	var b_daily := UI.button("Thử thách Hôm Nay", _on_start_daily, 13, 178.0)
	b_daily.custom_minimum_size = Vector2(178, 28)
	b_daily.modulate = Color(0.48, 0.94, 1.0)
	top_row.add_child(b_daily)

	var daily_ids: Array = RunModes.daily_mutators()
	var daily_names: PackedStringArray = []
	for mid in daily_ids:
		daily_names.append(RunModes.mutator_name(str(mid)))
	var daily_lbl := UI.label("Hôm nay (%s): %s" % [RunModes.daily_seed_code(), ", ".join(daily_names)], 12, Color(0.72, 0.92, 1.0))
	_body_box.add_child(daily_lbl)

	# Hàng 2: Chọn 8 Biến số (Mutators)
	var sel_cnt: int = Global.pending_mutators.size()
	var mut_hdr := UI.label("Chọn Biến Số (%d/8 đã bật):" % sel_cnt, 13, Color(1.0, 0.88, 0.45))
	_body_box.add_child(mut_hdr)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	_body_box.add_child(grid)

	for mid_v in RunModes.MUTATOR_ORDER:
		var mid: String = str(mid_v)
		var minfo: Dictionary = RunModes.MUTATORS.get(mid, {})
		var on: bool = Global.pending_mutators.has(mid)
		var mcol: Color = RunModes.mutator_color(mid)
		var card := Button.new()
		card.custom_minimum_size = Vector2(276, 36)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(_on_toggle_mutator.bind(mid))
		card.modulate = Color(1.0, 1.0, 1.0) if on else Color(0.72, 0.72, 0.78)
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 6
		vb.offset_right = -6
		vb.offset_top = 2
		vb.offset_bottom = -2
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_theme_constant_override("separation", 0)
		var t_lbl := UI.label(("%s [BẬT]" if on else "%s") % str(minfo.get("name", mid)), 12, mcol if on else Color(0.9, 0.88, 0.84))
		t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		t_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(t_lbl)
		var d_lbl := UI.label(str(minfo.get("desc", "")), 10, Color(0.84, 0.84, 0.82))
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		d_lbl.clip_text = true
		d_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(d_lbl)
		card.add_child(vb)
		grid.add_child(card)

	var launch_row := HBoxContainer.new()
	launch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	launch_row.add_theme_constant_override("separation", 10)
	_body_box.add_child(launch_row)
	var b_normal := UI.button("Xuất trận với Biến số", _on_start_mutated_normal, 14, 210.0)
	b_normal.custom_minimum_size = Vector2(210, 26)
	launch_row.add_child(b_normal)
	var b_clear := UI.button("Xóa chọn Biến số", _on_clear_mutators, 13, 150.0)
	b_clear.custom_minimum_size = Vector2(150, 26)
	b_clear.disabled = Global.pending_mutators.is_empty()
	launch_row.add_child(b_clear)


func _build_board_tab() -> void:
	if _copy_btn != null:
		_copy_btn.visible = true

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	var code_lbl := UI.label("Mã thử thách:", 15, Color(0.95, 0.9, 0.8))
	code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	input_row.add_child(code_lbl)

	_code_input = LineEdit.new()
	_code_input.placeholder_text = "VD: TET2027"
	_code_input.max_length = 20
	_code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_input.custom_minimum_size = Vector2(150, 26)
	_code_input.add_theme_font_size_override("font_size", 17)
	_code_input.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	_code_input.add_theme_color_override("font_placeholder_color", Color(0.7, 0.65, 0.58))
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.12, 0.06, 0.09, 0.95)
	input_style.border_color = Color(0.75, 0.58, 0.28)
	input_style.set_border_width_all(2)
	input_style.set_corner_radius_all(3)
	input_style.content_margin_left = 8
	input_style.content_margin_right = 8
	input_style.content_margin_top = 2
	input_style.content_margin_bottom = 2
	_code_input.add_theme_stylebox_override("normal", input_style)
	var focus_style := input_style.duplicate() as StyleBoxFlat
	focus_style.border_color = Color(1.0, 0.84, 0.38)
	_code_input.add_theme_stylebox_override("focus", focus_style)
	_code_input.text_submitted.connect(_on_code_submitted)
	input_row.add_child(_code_input)

	var start_btn := UI.button("Bắt đầu thử thách", _on_start_challenge, 15, 172.0)
	start_btn.custom_minimum_size = Vector2(172, 26)
	input_row.add_child(start_btn)
	_body_box.add_child(input_row)

	_status_label = UI.label("Nhập cùng mã với bạn bè để chung bản đồ, thứ tự trùm và phúc lành.", 13, Color(0.86, 0.82, 0.75))
	_body_box.add_child(_status_label)

	var header := _make_columns_row(["#", "Mã", "Tướng", "Màn", "Giặc", "T.gian", "Điểm"], Color(1.0, 0.86, 0.45), 14)
	_body_box.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(548, 134)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_box.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 3)
	scroll.add_child(_list_box)

	if Global.leaderboard.is_empty():
		_selected_idx = 0
		var empty_lbl := UI.label("Chưa có thành tích nào. Hãy chinh chiến để ghi danh!", 15, Color(0.8, 0.76, 0.7))
		empty_lbl.custom_minimum_size = Vector2(0, 40)
		_list_box.add_child(empty_lbl)
		if _copy_btn != null:
			_copy_btn.disabled = true
		return

	_selected_idx = clampi(_selected_idx, 0, Global.leaderboard.size() - 1)
	if _copy_btn != null:
		_copy_btn.disabled = false
	for i in Global.leaderboard.size():
		var item: Variant = Global.leaderboard[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		var code_txt: String = str(entry.get("code", ""))
		if code_txt == "":
			code_txt = "Thường"
		var hero_id: String = str(entry.get("hero", ""))
		var hero_name: String = str(HeroData.DATA[hero_id].name) if HeroData.DATA.has(hero_id) else hero_id
		var lv_txt: String = str(int(entry.get("level", 1)))
		var kills_txt: String = str(int(entry.get("kills", 0)))
		var time_txt: String = Global.format_time(float(entry.get("time", 0.0)))
		var score_txt: String = str(int(entry.get("score", 0)))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 24)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_select_row.bind(i))
		var row_col := Color(1.0, 0.94, 0.65) if i == 0 else Color(0.95, 0.92, 0.86)
		var row := _make_columns_row(["#%d" % (i + 1), code_txt, hero_name, lv_txt, kills_txt, time_txt, score_txt], row_col, 14)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6
		row.offset_right = -6
		btn.add_child(row)
		_list_box.add_child(btn)
		_row_btns.append(btn)
	_update_selection_visuals()


func _on_toggle_badass() -> void:
	Global.badass_mode = not Global.badass_mode
	Global.save_game()
	refresh()


func _on_toggle_mutator(mid: String) -> void:
	if Global.pending_mutators.has(mid):
		Global.pending_mutators.erase(mid)
	else:
		Global.pending_mutators.append(mid)
	refresh()


func _on_clear_mutators() -> void:
	Global.pending_mutators.clear()
	refresh()


func _on_start_boss_rush() -> void:
	Global.pending_run_mode = "boss_rush"
	Global.start_run("")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_start_daily() -> void:
	Global.pending_run_mode = "normal"
	Global.pending_mutators = RunModes.daily_mutators()
	Global.start_run(RunModes.daily_seed_code())
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_start_mutated_normal() -> void:
	Global.pending_run_mode = "normal"
	Global.start_run("")
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _update_selection_visuals() -> void:
	for i in _row_btns.size():
		var b: Button = _row_btns[i]
		b.modulate = Color(1.0, 0.92, 0.5) if i == _selected_idx else Color(0.78, 0.75, 0.74)


func _on_select_row(idx: int) -> void:
	_selected_idx = clampi(idx, 0, maxi(0, Global.leaderboard.size() - 1))
	_update_selection_visuals()
	if _copy_btn != null:
		_copy_btn.text = "Chép kết quả"


func _on_code_submitted(_text: String) -> void:
	_on_start_challenge()


func _on_start_challenge() -> void:
	var code: String = _code_input.text.strip_edges().to_upper() if _code_input != null else ""
	if code == "":
		if _status_label != null:
			_status_label.text = "Hãy nhập mã thử thách trước khi bắt đầu (VD: TET2027)!"
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		if _code_input != null:
			_code_input.grab_focus()
		return
	Global.pending_run_mode = "normal"
	Global.start_run(code)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_copy_selected() -> void:
	if Global.leaderboard.is_empty():
		return
	var idx: int = clampi(_selected_idx, 0, Global.leaderboard.size() - 1)
	var item: Variant = Global.leaderboard[idx]
	if typeof(item) != TYPE_DICTIONARY:
		return
	var share_txt: String = Global.format_share_text(item as Dictionary)
	if DisplayServer.get_name() != "headless":
		DisplayServer.clipboard_set(share_txt)
	if _copy_btn != null and is_instance_valid(_copy_btn):
		_copy_btn.text = "Đã chép!"
		var btn_ref: WeakRef = weakref(_copy_btn)
		get_tree().create_timer(1.5).timeout.connect(func():
			var b: Variant = btn_ref.get_ref()
			if b != null:
				(b as Button).text = "Chép kết quả")
