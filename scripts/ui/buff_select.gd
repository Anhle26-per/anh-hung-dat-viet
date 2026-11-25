extends CanvasLayer
## Màn chọn phúc lành sau mỗi màn: 3 thẻ (có độ hiếm, hệ và nút Đổi vận).

signal chosen(id)

const BuffData = preload("res://scripts/data/buffs.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

const REROLL_COST := 15

var _options: Array = []
var _next_title: String = ""
var _boss_bonus: bool = false
var _rerolled: bool = false
var _root: Control = null


func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(next_title: String, boss_bonus: bool = false) -> bool:
	_next_title = next_title
	_boss_bonus = boss_bonus
	_rerolled = false
	_options = BuffData.offer(Global.run_buffs, 3, boss_bonus)
	if _options.is_empty():
		return false
	_rebuild()
	visible = true
	if not Net.is_online():
		get_tree().paused = true
	return true


func reroll() -> bool:
	if not visible or _rerolled or Global.run_coins < REROLL_COST:
		return false
	var next_opts: Array = BuffData.offer(Global.run_buffs, 3, _boss_bonus, _options)
	if next_opts.is_empty():
		return false
	Global.run_coins = maxi(0, Global.run_coins - REROLL_COST)
	_rerolled = true
	_options = next_opts
	Sfx.play("ui_click")
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp) and lp.has_signal("stats_changed"):
		lp.stats_changed.emit()
	_rebuild()
	return true


func _rebuild() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UI.make_theme()
	add_child(_root)

	var box := UI.overlay(_root, 0.78)
	var heading: String = "THƯỞNG HẠ TRÙM — CHỌN TUYỆT KỸ!" if _boss_bonus else "CHỌN MỘT PHÚC LÀNH"
	var hcol: Color = Color(1.0, 0.88, 0.32) if _boss_bonus else Color(1.0, 0.85, 0.42)
	box.add_child(UI.label(heading, 28, hcol))
	box.add_child(UI.label("Tiếp theo: %s   |   Xu hiện có: %d" % [_next_title, Global.run_coins], 14, Color(0.92, 0.88, 0.82)))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for i in _options.size():
		row.add_child(_card(i, str(_options[i])))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var rr_txt: String = "Đã đổi vận" if _rerolled else "Đổi vận (%d xu)" % REROLL_COST
	var rr_btn: Button = UI.button(rr_txt, func(): reroll(), 15, 190.0)
	rr_btn.disabled = _rerolled or Global.run_coins < REROLL_COST
	footer.add_child(rr_btn)


func _card_style(border_col: Color, bg_col: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _card(i: int, id: String) -> Control:
	var b: Dictionary = BuffData.DATA[id]
	var tr: int = BuffData.tier(id)
	var tcol: Color = BuffData.tier_color(id)
	var ccol: Color = BuffData.category_color(id)
	var cname: String = BuffData.category_name(id)
	var tname: String = BuffData.tier_name(id)

	var bg_norm := Color(0.22, 0.08, 0.11, 0.96) if tr >= 3 else (Color(0.10, 0.15, 0.24, 0.95) if tr == 2 else Color(0.16, 0.10, 0.13, 0.95))
	var bg_hov := bg_norm.lightened(0.12)
	var bw: int = 3 if tr >= 3 else 2

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(186, 206)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _card_style(tcol, bg_norm, bw))
	btn.add_theme_stylebox_override("hover", _card_style(tcol.lightened(0.25), bg_hov, bw))
	btn.add_theme_stylebox_override("pressed", _card_style(tcol, bg_norm.darkened(0.15), bw))
	btn.pressed.connect(pick.bind(i))

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	btn.add_child(v)

	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = Color(tcol.r * 0.22, tcol.g * 0.22, tcol.b * 0.22, 0.95)
	pill_sb.border_color = tcol
	pill_sb.set_border_width_all(1)
	pill_sb.set_corner_radius_all(3)
	pill_sb.content_margin_left = 4
	pill_sb.content_margin_right = 4
	pill_sb.content_margin_top = 1
	pill_sb.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", pill_sb)
	var pill_lbl := UI.label("%s · %s" % [tname, cname], 11, ccol)
	pill_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(pill_lbl)
	v.add_child(pill)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(54, 54)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ib_sb := StyleBoxFlat.new()
	ib_sb.bg_color = Color(0.06, 0.03, 0.07, 0.9)
	ib_sb.border_color = tcol.darkened(0.15)
	ib_sb.set_border_width_all(1)
	ib_sb.set_corner_radius_all(4)
	icon_box.add_theme_stylebox_override("panel", ib_sb)
	var icon := TextureRect.new()
	icon.texture = Art.tex("ui/buff_%s.png" % id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon)
	v.add_child(icon_box)

	var title_l := UI.label(str(b.name), 18, tcol.lightened(0.2), true)
	title_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(title_l)

	var desc_l := UI.label(str(b.desc), 12, Color(0.95, 0.92, 0.88), true)
	desc_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc_l)

	var owned_cnt: int = int(Global.run_buffs.get(id, 0))
	var max_cnt: int = int(b.max)
	var stk_txt: String = "★ Độc nhất (1 lần)" if max_cnt == 1 else "Đang có: %d / %d" % [owned_cnt, max_cnt]
	var stk_col: Color = Color(1.0, 0.86, 0.35) if max_cnt == 1 else Color(0.7, 0.86, 1.0)
	var stk_l := UI.label(stk_txt, 11, stk_col)
	stk_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(stk_l)

	return btn


func pick(i: int) -> void:
	if not visible or i < 0 or i >= _options.size():
		return
	visible = false
	if not Net.is_online():
		get_tree().paused = false
	chosen.emit(str(_options[i]))
