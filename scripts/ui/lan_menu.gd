extends Control
## Màn hình Chơi chung qua mạng LAN: tìm/tạo phòng, vào bằng IP, chọn tướng theo kho Chủ phòng.

const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const DiscoveryScript = preload("res://scripts/net/discovery.gd")

var _discovery: Node = null
var _name_input: LineEdit = null
var _room_name_input: LineEdit = null
var _ip_input: LineEdit = null
var _notice_lbl: Label = null

var _browser_box: VBoxContainer = null
var _rooms_list: VBoxContainer = null

var _room_box: VBoxContainer = null
var _room_title_lbl: Label = null
var _ip_info_lbl: Label = null
var _players_title_lbl: Label = null
var _players_list: VBoxContainer = null
var _heroes_grid: GridContainer = null
var _ready_btn: Button = null
var _start_btn: Button = null


class LanBackdrop extends Control:
	const Art = preload("res://scripts/art/art.gd")
	var t: float = 0.0
	var drum: Texture2D

	func _ready() -> void:
		drum = Art.tex("fx/drum.png")

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.04, 0.07))
		for i in 6:
			draw_rect(Rect2(0, h * i / 12.0, w, h / 12.0), Color(0.15 - i * 0.012, 0.05, 0.08))
		var c := Vector2(w * 0.5, h * 0.52)
		draw_set_transform(c, t * 0.03, Vector2(4.2, 4.2))
		draw_texture(drum, -Vector2(32, 32), Color(1.0, 0.65, 0.35, 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ready() -> void:
	theme = UI.make_theme()
	get_tree().paused = false
	Sfx.play_music("lobby")

	var bg := LanBackdrop.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_discovery = DiscoveryScript.new()
	add_child(_discovery)
	_discovery.rooms_changed.connect(_on_rooms_changed)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(604, 336)
	center.add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 5)
	panel.add_child(root_box)

	# Thanh tiêu đề + tên người chơi
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	var title := UI.label("CHƠI CHUNG QUA MẠNG LAN", 22, Color(1.0, 0.84, 0.32))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var name_lbl := UI.label("Tên:", 15, Color(0.95, 0.9, 0.8))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(name_lbl)

	var saved_name: String = str(Global.settings.get("player_name", "Anh Hùng"))
	_name_input = _make_line_edit("Anh Hùng", saved_name, 130.0)
	_name_input.max_length = 16
	_name_input.text_changed.connect(_on_name_changed)
	top_bar.add_child(_name_input)
	root_box.add_child(top_bar)

	# Dòng thông báo trạng thái / mất kết nối
	_notice_lbl = UI.label("", 14, Color(1.0, 0.72, 0.45))
	_notice_lbl.visible = false
	root_box.add_child(_notice_lbl)

	# Chế độ 1: Tìm / Tạo phòng
	_browser_box = VBoxContainer.new()
	_browser_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_browser_box.add_theme_constant_override("separation", 6)
	root_box.add_child(_browser_box)
	_build_browser_ui(_browser_box, saved_name)

	# Chế độ 2: Bên trong phòng LAN
	_room_box = VBoxContainer.new()
	_room_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room_box.add_theme_constant_override("separation", 5)
	_room_box.visible = false
	root_box.add_child(_room_box)
	_build_room_ui(_room_box)

	Net.lobby_updated.connect(_on_lobby_updated)
	Net.entered_lan_lobby.connect(_on_entered_lan_lobby)
	Net.match_started.connect(_on_match_started)
	Net.host_left.connect(_on_host_left)
	Net.connection_failed.connect(_on_connection_failed)

	if Net.disconnect_notice != "":
		_show_notice(Net.disconnect_notice, Color(1.0, 0.55, 0.45))
		Net.disconnect_notice = ""

	if Net.is_online() and Net.in_lobby and not Net.in_match:
		_on_entered_lan_lobby.call_deferred()
		return

	_refresh_view()


func _exit_tree() -> void:
	if Net.lobby_updated.is_connected(_on_lobby_updated):
		Net.lobby_updated.disconnect(_on_lobby_updated)
	if Net.entered_lan_lobby.is_connected(_on_entered_lan_lobby):
		Net.entered_lan_lobby.disconnect(_on_entered_lan_lobby)
	if Net.match_started.is_connected(_on_match_started):
		Net.match_started.disconnect(_on_match_started)
	if Net.host_left.is_connected(_on_host_left):
		Net.host_left.disconnect(_on_host_left)
	if Net.connection_failed.is_connected(_on_connection_failed):
		Net.connection_failed.disconnect(_on_connection_failed)


func _build_browser_ui(parent: VBoxContainer, saved_name: String) -> void:
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 10)
	parent.add_child(cols)

	# Cột trái: Tạo phòng + Vào bằng IP
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(258, 0)
	left.add_theme_constant_override("separation", 5)
	cols.add_child(left)

	var create_panel := _make_subpanel()
	left.add_child(create_panel)
	var cbox := VBoxContainer.new()
	cbox.add_theme_constant_override("separation", 5)
	create_panel.add_child(cbox)
	var clbl := UI.label("Tạo phòng mới (Chủ phòng)", 16, Color(1.0, 0.86, 0.42))
	clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cbox.add_child(clbl)
	_room_name_input = _make_line_edit("Tên phòng...", "Phòng của %s" % saved_name, 236.0)
	_room_name_input.max_length = 24
	cbox.add_child(_room_name_input)
	var create_btn := UI.button("Tạo phòng LAN", _on_create_room, 18, 236.0)
	create_btn.custom_minimum_size = Vector2(236, 28)
	cbox.add_child(create_btn)

	var ip_panel := _make_subpanel()
	left.add_child(ip_panel)
	var ibox := VBoxContainer.new()
	ibox.add_theme_constant_override("separation", 5)
	ip_panel.add_child(ibox)
	var ilbl := UI.label("Vào bằng IP thủ công", 16, Color(1.0, 0.86, 0.42))
	ilbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ibox.add_child(ilbl)
	_ip_input = _make_line_edit("192.168.1.x hoặc 127.0.0.1", "127.0.0.1", 236.0)
	_ip_input.max_length = 40
	_ip_input.text_submitted.connect(func(_t: String) -> void: _on_join_ip())
	ibox.add_child(_ip_input)
	var join_btn := UI.button("Vào bằng IP", _on_join_ip, 18, 236.0)
	join_btn.custom_minimum_size = Vector2(236, 28)
	ibox.add_child(join_btn)

	var hint := UI.label("Cùng Wi-Fi/LAN • Cổng %d (tự tìm %d)" % [Net.DEFAULT_PORT, Net.DISCOVERY_PORT], 13, Color(0.78, 0.75, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(hint)

	# Cột phải: Danh sách phòng tự tìm
	var right_panel := _make_subpanel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(right_panel)

	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 5)
	right_panel.add_child(rbox)

	var rtitle := UI.label("Phòng LAN đang mở (tự tìm)", 16, Color(1.0, 0.86, 0.42))
	rtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rbox.add_child(rtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rbox.add_child(scroll)

	_rooms_list = VBoxContainer.new()
	_rooms_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rooms_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_rooms_list)

	# Nút Quay lại
	var back_btn := UI.button("Quay lại", _on_back, 18, 160.0)
	back_btn.custom_minimum_size = Vector2(160, 28)
	parent.add_child(UI.center(back_btn))


func _build_room_ui(parent: VBoxContainer) -> void:
	# Thanh thông tin phòng + IP
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	_room_title_lbl = UI.label("Phòng LAN", 18, Color(1.0, 0.88, 0.42))
	_room_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_room_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_room_title_lbl)

	_ip_info_lbl = UI.label("", 14, Color(0.55, 0.9, 1.0))
	_ip_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_row.add_child(_ip_info_lbl)
	parent.add_child(info_row)

	var rule_lbl := UI.label("Phòng dùng kho tướng & nâng cấp của Chủ phòng", 14, Color(0.98, 0.88, 0.62))
	rule_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(rule_lbl)

	# Nội dung 2 cột: Người chơi (trái) + Chọn tướng (phải)
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 8)
	parent.add_child(mid)

	var p_panel := _make_subpanel()
	p_panel.custom_minimum_size = Vector2(236, 0)
	p_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(p_panel)

	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 4)
	p_panel.add_child(pbox)
	_players_title_lbl = UI.label("Thành viên (1/4)", 15, Color(1.0, 0.86, 0.42))
	_players_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pbox.add_child(_players_title_lbl)

	_players_list = VBoxContainer.new()
	_players_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_players_list.add_theme_constant_override("separation", 4)
	pbox.add_child(_players_list)

	var h_panel := _make_subpanel()
	h_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(h_panel)

	var hbox := VBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	h_panel.add_child(hbox)
	var htitle := UI.label("Chọn tướng (kho của Chủ phòng)", 15, Color(1.0, 0.86, 0.42))
	htitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(htitle)

	var hscroll := ScrollContainer.new()
	hscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hbox.add_child(hscroll)

	_heroes_grid = GridContainer.new()
	_heroes_grid.columns = 2
	_heroes_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heroes_grid.add_theme_constant_override("h_separation", 6)
	_heroes_grid.add_theme_constant_override("v_separation", 5)
	hscroll.add_child(_heroes_grid)

	# Thanh nút dưới cùng
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	_ready_btn = UI.button("Sẵn sàng", _on_toggle_ready, 17, 150.0)
	_ready_btn.custom_minimum_size = Vector2(150, 28)
	actions.add_child(_ready_btn)
	_start_btn = UI.button("Vào Doanh Trại", _on_enter_lobby, 17, 170.0)
	_start_btn.custom_minimum_size = Vector2(170, 28)
	actions.add_child(_start_btn)
	var leave_btn := UI.button("Rời phòng", _on_leave_room, 17, 140.0)
	leave_btn.custom_minimum_size = Vector2(140, 28)
	actions.add_child(leave_btn)
	parent.add_child(actions)


func _make_subpanel() -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.11, 0.05, 0.08, 0.82)
	st.border_color = Color(0.55, 0.4, 0.2, 0.85)
	st.set_border_width_all(1)
	st.set_corner_radius_all(3)
	st.content_margin_left = 7
	st.content_margin_right = 7
	st.content_margin_top = 5
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	return p


func _make_line_edit(placeholder: String, initial: String, width: float) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.text = initial
	le.custom_minimum_size = Vector2(width, 25)
	le.add_theme_font_size_override("font_size", 16)
	le.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	le.add_theme_color_override("font_placeholder_color", Color(0.68, 0.63, 0.56))
	var normal_st := StyleBoxFlat.new()
	normal_st.bg_color = Color(0.13, 0.06, 0.09, 0.96)
	normal_st.border_color = Color(0.72, 0.54, 0.26)
	normal_st.set_border_width_all(2)
	normal_st.set_corner_radius_all(3)
	normal_st.content_margin_left = 6
	normal_st.content_margin_right = 6
	normal_st.content_margin_top = 1
	normal_st.content_margin_bottom = 1
	le.add_theme_stylebox_override("normal", normal_st)
	var focus_st := normal_st.duplicate() as StyleBoxFlat
	focus_st.border_color = Color(1.0, 0.84, 0.38)
	le.add_theme_stylebox_override("focus", focus_st)
	return le


func _show_notice(text: String, col: Color = Color(1.0, 0.78, 0.45)) -> void:
	if _notice_lbl == null:
		return
	_notice_lbl.text = text
	_notice_lbl.add_theme_color_override("font_color", col)
	_notice_lbl.visible = text != ""


func _current_player_name() -> String:
	var n: String = _name_input.text.strip_edges() if _name_input != null else "Anh Hùng"
	return n if n != "" else "Anh Hùng"


func _refresh_view() -> void:
	var inside: bool = Net.is_online() and not Net.players.is_empty()
	_browser_box.visible = not inside
	_room_box.visible = inside
	_name_input.editable = not inside

	if not inside:
		if _discovery != null:
			_discovery.start_listen(Net.DISCOVERY_PORT)
			_on_rooms_changed(_discovery.get_rooms_list())
		return

	if _discovery != null:
		_discovery.stop_listen()

	_room_title_lbl.text = "Phòng: %s" % (Net.room_name if Net.room_name != "" else "Phòng LAN")
	if Net.is_host():
		var ips: PackedStringArray = Net.local_lan_ips()
		var ip_txt: String = ", ".join(ips) if not ips.is_empty() else "127.0.0.1"
		_ip_info_lbl.text = "IP máy chủ: %s:%d" % [ip_txt, Net.DEFAULT_PORT]
	else:
		_ip_info_lbl.text = "Đã kết nối Chủ phòng"

	_refresh_players_list()
	_refresh_hero_buttons()

	var my_id: int = Net.local_peer_id()
	var my_ready: bool = false
	if Net.players.has(my_id):
		my_ready = bool(Net.players[my_id].get("ready", false))
	_ready_btn.text = "Hủy sẵn sàng" if my_ready else "Sẵn sàng"
	_ready_btn.visible = not Net.is_host()

	_start_btn.visible = Net.is_host()
	_start_btn.disabled = false
	_start_btn.text = "Vào Doanh Trại"


func _refresh_players_list() -> void:
	for c in _players_list.get_children():
		c.queue_free()
	var list: Array = []
	for pid in Net.players:
		list.append(Net.players[pid])
	list.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("slot_idx", 0)) < int((b as Dictionary).get("slot_idx", 0)))
	_players_title_lbl.text = "Thành viên (%d/%d)" % [list.size(), Net.MAX_PLAYERS]
	for item in list:
		var info: Dictionary = item
		var pid: int = int(info.get("id", 0))
		var pname: String = str(info.get("name", "Anh Hùng"))
		var hid: String = str(info.get("hero", "ngo_quyen"))
		var hname: String = str(HeroData.DATA[hid].name) if HeroData.DATA.has(hid) else hid
		var is_ready: bool = bool(info.get("ready", false))
		var col: Color = info.get("color", Color(1.0, 0.88, 0.35))

		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var line1 := HBoxContainer.new()
		line1.add_theme_constant_override("separation", 4)
		var tag: String = " [Chủ]" if pid == 1 else ""
		var nl := UI.label("● %s%s" % [pname, tag], 15, col)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		line1.add_child(nl)
		var rl := UI.label("Sẵn sàng" if is_ready else "Chờ...", 13, Color(0.5, 1.0, 0.55) if is_ready else Color(0.75, 0.72, 0.68))
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line1.add_child(rl)
		row.add_child(line1)

		var hl := UI.label("   Tướng: %s" % hname, 13, Color(0.92, 0.88, 0.8))
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(hl)
		_players_list.add_child(row)


func _refresh_hero_buttons() -> void:
	for c in _heroes_grid.get_children():
		c.queue_free()
	var unlocked: Array = Net.host_profile.get("unlocked", [])
	var my_id: int = Net.local_peer_id()
	var my_hero: String = str(Net.players[my_id].get("hero", "ngo_quyen")) if Net.players.has(my_id) else Global.selected_hero
	for hid in HeroData.ORDER:
		if not unlocked.has(hid):
			continue
		var hname: String = str(HeroData.DATA[hid].name)
		var selected: bool = (hid == my_hero)
		var label_txt: String = ("▶ " + hname) if selected else hname
		var btn := UI.button(label_txt, _on_select_hero.bind(hid), 15, 146.0)
		btn.custom_minimum_size = Vector2(146, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if selected:
			btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		_heroes_grid.add_child(btn)


# ------------------------------------------------------------------ Xử lý sự kiện

func _on_name_changed(new_text: String) -> void:
	var clean: String = new_text.strip_edges()
	if clean == "":
		clean = "Anh Hùng"
	Global.settings["player_name"] = clean
	Global.save_game()


func _on_create_room() -> void:
	_show_notice("")
	var pname: String = _current_player_name()
	var rname: String = _room_name_input.text.strip_edges()
	var err: int = Net.create_room(rname, pname, Net.DEFAULT_PORT)
	if err != OK:
		_show_notice("Không thể tạo phòng trên cổng %d (mã lỗi %d)." % [Net.DEFAULT_PORT, err], Color(1.0, 0.5, 0.45))
		return
	Net.host_enter_lobby()


func _on_join_ip() -> void:
	var raw: String = _ip_input.text.strip_edges()
	if raw == "":
		_show_notice("Hãy nhập địa chỉ IP của Chủ phòng.", Color(1.0, 0.6, 0.45))
		return
	var host_ip: String = raw
	var port: int = Net.DEFAULT_PORT
	if raw.contains(":"):
		var parts: PackedStringArray = raw.split(":")
		host_ip = parts[0].strip_edges()
		if parts.size() >= 2 and parts[1].is_valid_int():
			port = clampi(int(parts[1]), 1024, 65535)
	_join_target(host_ip, port)


func _join_target(ip: String, port: int) -> void:
	_show_notice("Đang kết nối tới %s:%d..." % [ip, port], Color(0.65, 0.9, 1.0))
	var err: int = Net.join_room(ip, _current_player_name(), port)
	if err != OK:
		_show_notice("Không kết nối được tới %s:%d (lỗi %d)." % [ip, port, err], Color(1.0, 0.5, 0.45))


func _on_rooms_changed(list: Array) -> void:
	if _rooms_list == null:
		return
	for c in _rooms_list.get_children():
		c.queue_free()
	if list.is_empty():
		var empty := UI.label("Đang tìm phòng trên mạng Wi-Fi...\n(Chưa thấy phòng nào đang mở)", 15, Color(0.78, 0.74, 0.68), true)
		empty.custom_minimum_size = Vector2(260, 64)
		_rooms_list.add_child(empty)
		return
	for item in list:
		var r: Dictionary = item
		var rname: String = str(r.get("name", "Phòng LAN"))
		var ip: String = str(r.get("ip", ""))
		var port: int = int(r.get("port", Net.DEFAULT_PORT))
		var pcnt: int = int(r.get("players", 1))
		var pmax: int = int(r.get("max_players", Net.MAX_PLAYERS))
		var running: bool = bool(r.get("in_match", false))
		var suffix: String = " [Đang đấu]" if running else ""
		var txt: String = "%s (%d/%d) - %s%s" % [rname, pcnt, pmax, ip, suffix]
		var btn := UI.button(txt, _join_target.bind(ip, port), 15, 270.0)
		btn.custom_minimum_size = Vector2(270, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rooms_list.add_child(btn)


func _on_select_hero(hid: String) -> void:
	Net.request_set_hero(hid)


func _on_toggle_ready() -> void:
	var my_id: int = Net.local_peer_id()
	var cur: bool = bool(Net.players[my_id].get("ready", false)) if Net.players.has(my_id) else false
	Net.request_set_ready(not cur)


func _on_enter_lobby() -> void:
	Net.host_enter_lobby()


func _on_start_match() -> void:
	Net.host_start_match()


func _on_leave_room() -> void:
	Net.leave_room()
	_show_notice("")
	_refresh_view()


func _on_back() -> void:
	Net.leave_room()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_lobby_updated() -> void:
	if Net.is_online() and Net.in_lobby and not Net.in_match:
		_on_entered_lan_lobby()
		return
	if Net.is_online() and not Net.players.is_empty():
		_show_notice("")
	_refresh_view()


func _on_entered_lan_lobby() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_match_started(_seed_val: int, _level: int) -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_host_left(reason: String) -> void:
	var msg: String = reason if reason != "" else "Chủ phòng đã rời"
	_show_notice(msg, Color(1.0, 0.55, 0.45))
	Net.disconnect_notice = ""
	_refresh_view()


func _on_connection_failed(reason: String) -> void:
	_show_notice(reason, Color(1.0, 0.55, 0.45))
	Net.disconnect_notice = ""
	_refresh_view()
