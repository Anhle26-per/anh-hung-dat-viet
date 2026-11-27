extends CanvasLayer
## Giao diện Sạp Thương Nhân Đại Việt (mở khi bấm E cạnh bà hàng).

const Art = preload("res://scripts/art/art.gd")
const UI = preload("res://scripts/ui/ui.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")

var shop: Node2D = null
var _root: Control = null
var _closing: bool = false


func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_ui_open")
	if Net == null or not Net.is_online():
		get_tree().paused = true
	_rebuild()


func _exit_tree() -> void:
	if (Net == null or not Net.is_online()) and is_inside_tree() and get_tree() != null:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if _closing or not is_inside_tree():
		return
	if event.is_action_pressed("pause"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	set_process_unhandled_input(false)
	if (Net == null or not Net.is_online()) and is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	queue_free()


func _panel_style(border_col: Color, bg_col: Color, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _rebuild() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UI.make_theme()
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.76)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(598, 298)
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.92, 0.72, 0.28), Color(0.14, 0.06, 0.09, 0.97), 2))
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	frame.add_child(vbox)

	# --- Đầu sạp: Chân dung + Tên + Xu + Giảm giá ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var portrait_box := PanelContainer.new()
	portrait_box.custom_minimum_size = Vector2(44, 44)
	portrait_box.add_theme_stylebox_override("panel", _panel_style(Color(0.85, 0.65, 0.25), Color(0.24, 0.10, 0.14, 0.95), 1))
	var at := AtlasTexture.new()
	at.atlas = Art.tex("world/merchant.png")
	at.region = Rect2(0, 0, 32, 32)
	var portrait := TextureRect.new()
	portrait.texture = at
	portrait.custom_minimum_size = Vector2(34, 34)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_box.add_child(portrait)
	header.add_child(portrait_box)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	header.add_child(title_col)

	var t_lbl := UI.label("SẠP THƯƠNG NHÂN ĐẠI VIỆT", 22, Color(1.0, 0.86, 0.36))
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_col.add_child(t_lbl)

	var p: Node = Global.local_player()
	var has_discount: bool = p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("thuong_khach") > 0
	var sub_txt: String = "Ưu đãi Khách quý: Giảm 30% mọi món hàng!" if has_discount else "\"Hàng tuyển chọn khắp đất Việt, mời tướng quân xem qua!\""
	var sub_col: Color = Color(0.55, 1.0, 0.65) if has_discount else Color(0.92, 0.86, 0.78)
	var s_lbl := UI.label(sub_txt, 13, sub_col)
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_col.add_child(s_lbl)

	var coin_pill := PanelContainer.new()
	coin_pill.add_theme_stylebox_override("panel", _panel_style(Color(0.9, 0.72, 0.28), Color(0.22, 0.14, 0.08, 0.95), 1))
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 5)
	var c_at := AtlasTexture.new()
	c_at.atlas = Art.tex("items/coin.png")
	c_at.region = Rect2(0, 0, 9, 9)
	var c_ic := TextureRect.new()
	c_ic.texture = c_at
	c_ic.custom_minimum_size = Vector2(14, 14)
	c_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(c_ic)
	coin_row.add_child(UI.label("%d xu" % Global.run_coins, 16, Color(1.0, 0.88, 0.42)))
	coin_pill.add_child(coin_row)
	header.add_child(coin_pill)

	# --- Danh sách thẻ hàng ---
	var stands: Array = shop.stands if (shop != null and is_instance_valid(shop)) else []
	var scroller := ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(576, 194)
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroller)

	var cards_row := HBoxContainer.new()
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 8)
	scroller.add_child(cards_row)

	for st_v in stands:
		if is_instance_valid(st_v):
			cards_row.add_child(_item_card(st_v, p))

	# --- Chân sạp: Đổi hàng + Đóng ---
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	vbox.add_child(footer)

	if shop != null and is_instance_valid(shop) and shop.has_method("can_reroll"):
		var can_rr: bool = shop.can_reroll()
		var rr_cost: int = shop.reroll_cost()
		var rr_left: int = shop.rerolls_left()
		var rr_label: String = "Hết lượt đổi" if rr_left <= 0 else ("Đổi hàng (Miễn phí!)" if rr_cost == 0 else "Đổi hàng (%d xu)" % rr_cost)
		var rr_btn := UI.button(rr_label, func(): _on_reroll(), 15, 200.0)
		rr_btn.disabled = (not can_rr) or (Global.run_coins < rr_cost) or (Net.is_online() and not Net.is_host())
		footer.add_child(rr_btn)

	footer.add_child(UI.button("Đóng (Esc)", close, 15, 140.0))


func _item_card(st: Node, p: Node) -> Control:
	var info: Dictionary = st.inspect_info(p)
	var bcol: Color = info.get("badge_color", Color(0.85, 0.72, 0.45)) as Color
	var is_sold: bool = bool(info.get("sold", false))
	var price_val: int = int(info.get("price", 0))
	var base_val: int = int(info.get("base_price", price_val))
	var afford: bool = Global.run_coins >= price_val

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(178, 186)
	var bg_col := Color(0.11, 0.08, 0.10, 0.88) if is_sold else Color(0.17, 0.09, 0.13, 0.96)
	card.add_theme_stylebox_override("panel", _panel_style(bcol.darkened(0.45) if is_sold else bcol, bg_col, 2))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)

	var tag := UI.label(str(info.get("badge", "")), 11, bcol)
	v.add_child(tag)

	var ic_rect := TextureRect.new()
	var tex_v: Variant = info.get("icon", null)
	if tex_v is Texture2D:
		ic_rect.texture = tex_v as Texture2D
	ic_rect.custom_minimum_size = Vector2(0, 38)
	ic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if is_sold:
		ic_rect.modulate = Color(0.45, 0.45, 0.45, 0.65)
	v.add_child(ic_rect)

	var title_col: Color = (info.get("title_color", Color.WHITE) as Color) if not is_sold else Color(0.6, 0.58, 0.56)
	v.add_child(UI.label(str(info.get("title", "")), 15, title_col, true))

	var stats_s: String = str(info.get("stats", ""))
	if stats_s != "":
		v.add_child(UI.label(stats_s, 11, Color(0.74, 0.9, 1.0)))

	var syn_s: String = str(info.get("synergy", ""))
	if syn_s != "":
		var syn_c: Color = info.get("synergy_color", Color(0.85, 0.9, 1.0)) as Color
		v.add_child(UI.label(syn_s, 11, syn_c))

	var desc_l := UI.label(str(info.get("desc", "")), 11, Color(0.9, 0.88, 0.84), true)
	desc_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc_l)

	if is_sold:
		var sold_btn := UI.button("Đã bán", func(): pass, 13, 150.0)
		sold_btn.disabled = true
		v.add_child(sold_btn)
	else:
		var price_txt: String = "Mua · %d xu" % price_val
		if price_val < base_val:
			price_txt = "Mua · %d xu (-30%%)" % price_val
		var buy_btn := UI.button(price_txt, func(): _on_buy(st), 13, 154.0)
		buy_btn.disabled = not afford
		if not afford:
			buy_btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.48, 0.45))
		v.add_child(buy_btn)

	return card


func _on_buy(st: Node) -> void:
	if st == null or not is_instance_valid(st):
		return
	st.interact()
	_rebuild()


func _on_reroll() -> void:
	if shop == null or not is_instance_valid(shop):
		return
	if shop.try_reroll():
		_rebuild()
