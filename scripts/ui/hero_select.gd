extends Control
## Màn hình chọn tướng. Tướng bị khóa thì mở bằng xu kiếm được trong trận.

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

var _selected := ""
var _cards := {}
var _coin_label: Label
var _msg_label: Label
var _scroll: ScrollContainer


class Portrait extends Control:
	## Tướng phóng to 3 lần, đứng thở, cầm vũ khí; biểu tượng kỹ năng ở góc.
	const Art = preload("res://scripts/art/art.gd")
	const WeaponData = preload("res://scripts/data/weapons.gd")
	var hero_id := ""
	var hero: Dictionary
	var locked := false
	var t := 0.0
	var tex: Texture2D
	var wt: Texture2D
	var icon: Texture2D

	func _ready() -> void:
		# nạp ảnh trước khi vẽ (nạp trong _draw sẽ hiện ô trắng ở khung đầu)
		tex = Art.tex("heroes/%s.png" % hero_id)
		wt = Art.tex("weapons/%s.png" % hero.weapon)
		icon = Art.tex("ui/skill_%s.png" % hero.skill)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var f := int(t * 3.0) % 4
		var c := size / 2.0
		var mod := Color(0.25, 0.22, 0.28) if locked else Color.WHITE
		draw_set_transform(c + Vector2(0, 18), 0.0, Vector2(2.6, 1.0))
		draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var g := WeaponData.grip(hero.weapon)
		draw_set_transform(c + Vector2(6, 4), -0.5, Vector2(2.0, 2.0))
		draw_texture(wt, -g, mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture_rect_region(tex, Rect2(c - Vector2(32, 42), Vector2(64, 64)), Rect2(f * 32, 0, 32, 32), mod)
		draw_texture_rect(icon, Rect2(size.x - 26, 2, 22, 22), false, mod)
		if locked:
			Art.draw_text(self, c + Vector2(0, 2), "KHÓA", 22, Color(1, 0.85, 0.5))


func _ready() -> void:
	theme = UI.make_theme()
	_selected = Global.selected_hero if Global.unlocked.has(Global.selected_hero) else HeroData.ORDER[0]
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_right = -8
	root.offset_top = 4
	root.offset_bottom = -4
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := UI.label("Chọn tướng xuất trận", 26, Color(1, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_coin_label = UI.label("", 20, Color(1, 0.88, 0.45))
	top.add_child(_coin_label)

	# 10 tướng: dải thẻ cuộn ngang (vuốt trên điện thoại / lăn chuột)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 5)
	scroll.add_child(row)
	_scroll = scroll
	for id in HeroData.ORDER:
		row.add_child(_make_card(id))

	_msg_label = UI.label("Vuốt / lăn chuột để xem thêm tướng  |  " + SynergyData.IMPRINT_INTRO, 12, Color(0.82, 0.8, 0.74))
	root.add_child(_msg_label)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	bottom.add_child(UI.button("Quay lại", _on_back, 18, 130.0))
	bottom.add_child(UI.button("Xuất trận!", _on_start, 22, 180.0))
	_refresh()


func _make_card(id: String) -> Control:
	var h: Dictionary = HeroData.DATA[id]
	var w := WeaponData.get_data(h.weapon)
	var fam: String = SynergyData.family(h.weapon)
	var sig: String = SynergyData.signature_for(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(184, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var p := Portrait.new()
	p.hero_id = id
	p.hero = h
	p.custom_minimum_size = Vector2(0, 62)
	box.add_child(p)
	box.add_child(UI.label(h.name, 19, Color(1, 0.85, 0.4)))
	box.add_child(UI.label(h.era, 11, Color(0.78, 0.74, 0.72), true))
	box.add_child(UI.label("%s [%s]" % [w.name, SynergyData.family_name(fam)], 13, WeaponData.tier_color(h.weapon)))
	if sig != "" and WeaponData.DATA.has(sig):
		box.add_child(UI.label("Định mệnh: %s" % WeaponData.DATA[sig].name, 11, Color(1.0, 0.82, 0.35)))
	box.add_child(UI.label("Chiêu: %s" % h.skill_name, 14, Color(0.6, 0.88, 1.0)))
	var desc := UI.label(h.skill_desc, 11, Color(0.85, 0.82, 0.8), true)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	var syn_s := UI.label(str(h.get("synergy_desc", "")), 11, Color(0.95, 0.86, 0.55), true)
	box.add_child(syn_s)
	box.add_child(UI.label("Máu %d  Giáp %d  NL %d" % [h.hp, h.armor, h.energy], 12, Color(0.9, 0.78, 0.65)))
	var btn := UI.button("", _on_card_pressed.bind(id), 15, 128.0)
	box.add_child(UI.center(btn))
	_cards[id] = {"panel": panel, "button": btn, "portrait": p}
	return panel


func _refresh() -> void:
	_coin_label.text = "Xu: %d" % Global.coins
	for id in _cards:
		var c: Dictionary = _cards[id]
		var unlocked: bool = Global.unlocked.has(id)
		var sel: bool = id == _selected
		c.portrait.locked = not unlocked
		c.panel.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_red.png" if sel else "ui/panel.png"))
		if not unlocked:
			c.button.text = "Mở: %d xu" % HeroData.DATA[id].cost
		elif sel:
			c.button.text = "Đang chọn"
		else:
			c.button.text = "Chọn"


func _on_card_pressed(id: String) -> void:
	_msg_label.text = ""
	if not Global.unlocked.has(id):
		if Global.try_unlock(id):
			_msg_label.text = "Đã mở khóa %s!" % HeroData.DATA[id].name
		else:
			_msg_label.text = "Chưa đủ xu. Hãy vào trận để kiếm thêm xu!"
			_refresh()
			return
	_selected = id
	_refresh()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_start() -> void:
	Global.selected_hero = _selected
	Global.save_game()
	Global.start_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
