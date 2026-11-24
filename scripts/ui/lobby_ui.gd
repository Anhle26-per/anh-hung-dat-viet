extends CanvasLayer
## Giao diện sảnh chính: thanh trên cùng (xu, gợi ý) và các bảng: tướng, lò rèn, kho vũ khí, bia ghi công.

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

var lobby = null
var _panel: Control = null
var _coin_label: Label


func _ready() -> void:
	layer = 20
	var top := Control.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.theme = UI.make_theme()
	add_child(top)
	var title := UI.label("DOANH TRẠI ANH HÙNG", 22, Color(1, 0.82, 0.3))
	title.position = Vector2(8, 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(title)
	_coin_label = UI.label("", 18, Color(1, 0.88, 0.45))
	_coin_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coin_label.position = Vector2(-120, 4)
	_coin_label.size = Vector2(112, 20)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_coin_label)
	var hint := UI.label("Đến gần rồi bấm E / nút DÙNG để tương tác  -  Bước vào cổng xanh để xuất trận", 13, Color(0.95, 0.9, 0.8))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.position.y = -18
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(hint)


func _process(_delta: float) -> void:
	_coin_label.text = "Xu: %d" % Global.coins


func is_open() -> bool:
	return _panel != null


func _unhandled_input(event: InputEvent) -> void:
	if _panel != null and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _begin(title: String) -> VBoxContainer:
	close()
	lobby.set_player_active(false)
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UI.make_theme()
	add_child(_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png"))
	c.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)
	box.add_child(UI.label(title, 26, Color(1, 0.85, 0.4)))
	return box


func _end(box: VBoxContainer) -> void:
	box.add_child(UI.center(UI.button("Đóng", close, 18, 140.0)))


func close() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
	if lobby != null:
		lobby.set_player_active(true)


# ------------------------------------------------------------------ Tướng

func open_hero(id: String) -> void:
	var h: Dictionary = HeroData.DATA[id]
	var box := _begin(h.name)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var at := AtlasTexture.new()
	at.atlas = Art.tex("heroes/%s.png" % id)
	at.region = Rect2(0, 0, 32, 32)
	var pic := TextureRect.new()
	pic.texture = at
	pic.custom_minimum_size = Vector2(96, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(300, 0)
	row.add_child(info)
	var w := WeaponData.get_data(h.weapon)
	for l in [UI.label(h.era, 15, Color(0.85, 0.8, 0.75)),
			UI.label("Vũ khí cơ bản: %s" % w.name, 16, Color(0.9, 0.9, 0.95)),
			UI.label("Chiêu: %s" % h.skill_name, 17, Color(0.6, 0.88, 1.0)),
			UI.label(h.skill_desc, 14, Color(0.9, 0.88, 0.85), true),
			UI.label("Máu %d   Giáp %d   Năng lượng %d" % [h.hp, h.armor, h.energy], 14, Color(0.95, 0.8, 0.65))]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(l)
	var msg := UI.label("", 14, Color(1, 0.6, 0.5))
	box.add_child(msg)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	box.add_child(btns)
	if Global.unlocked.has(id):
		btns.add_child(UI.button("Chọn tướng này", func():
			lobby.select_hero(id)
			close(), 18, 180.0))
	else:
		btns.add_child(UI.button("Mở khóa: %d xu" % h.cost, func():
			if Global.try_unlock(id):
				lobby.select_hero(id)
				close()
			else:
				msg.text = "Chưa đủ xu. Hãy xuất trận để kiếm thêm!", 18, 180.0))
	btns.add_child(UI.button("Đóng", close, 18, 120.0))


# ------------------------------------------------------------------ Lò rèn

func open_forge() -> void:
	var box := _begin("Lò rèn - Nâng cấp vĩnh viễn")
	box.add_child(UI.label("Xu hiện có: %d" % Global.coins, 16, Color(1, 0.88, 0.45)))
	for id in Global.UPGRADES:
		var u: Dictionary = Global.UPGRADES[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var lv := Global.upgrade(id)
		var name_l := UI.label("%s  (%d/%d)" % [u.name, lv, int(u.max)], 17, Color(1, 0.9, 0.6))
		name_l.custom_minimum_size = Vector2(180, 0)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_l)
		var d := UI.label(u.desc, 14, Color(0.9, 0.88, 0.85))
		d.custom_minimum_size = Vector2(220, 0)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(d)
		if lv >= int(u.max):
			row.add_child(UI.label("Đã tối đa", 15, Color(0.6, 0.9, 0.6)))
		else:
			row.add_child(UI.button("%d xu" % Global.upgrade_cost(id), func():
				if Global.try_upgrade(id):
					open_forge(), 15, 100.0))
	_end(box)


# ------------------------------------------------------------------ Kho vũ khí

func open_rack() -> void:
	var box := _begin("Giá binh khí - Đã sưu tầm %d / %d" % [Global.discovered.size(), WeaponData.DATA.size()])
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var gridc := GridContainer.new()
	gridc.columns = 7
	gridc.add_theme_constant_override("h_separation", 4)
	gridc.add_theme_constant_override("v_separation", 4)
	scroll.add_child(gridc)
	var ids: Array = WeaponData.DATA.keys()
	ids.sort_custom(func(a, b): return int(WeaponData.DATA[a].tier) < int(WeaponData.DATA[b].tier))
	for wid in ids:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(76, 46)
		var icon := TextureRect.new()
		icon.texture = Art.tex("weapons/%s.png" % wid)
		icon.custom_minimum_size = Vector2(76, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var known: bool = Global.discovered.has(wid)
		icon.modulate = Color.WHITE if known else Color(0, 0, 0, 0.75)
		cell.add_child(icon)
		var nm := UI.label(WeaponData.DATA[wid].name if known else "???", 11, WeaponData.tier_color(wid) if known else Color(0.5, 0.5, 0.5), true)
		cell.add_child(nm)
		gridc.add_child(cell)
	_end(box)


# ------------------------------------------------------------------ Bia ghi công

func open_stele() -> void:
	var box := _begin("Bia ghi công")
	var lines := [
		"Số lượt xuất trận: %d" % int(Global.stats.get("runs", 0)),
		"Giặc đã hạ: %d" % int(Global.stats.get("kills", 0)),
		"Trùm đã đánh bại: %d" % int(Global.stats.get("bosses", 0)),
		"Màn cao nhất: %d" % Global.best_level,
		"Tướng đã mở: %d / %d" % [Global.unlocked.size(), HeroData.ORDER.size()],
		"Vũ khí đã sưu tầm: %d / %d" % [Global.discovered.size(), WeaponData.DATA.size()],
	]
	for t in lines:
		box.add_child(UI.label(t, 18, Color(0.95, 0.9, 0.82)))
	_end(box)
