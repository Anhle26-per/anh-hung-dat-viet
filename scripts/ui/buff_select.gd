extends CanvasLayer
## Màn chọn phúc lành sau mỗi màn: 3 thẻ (có độ hiếm, hệ, hiệu ứng hoạt ảnh và nút Đổi vận).

signal chosen(id)

const BuffData = preload("res://scripts/data/buffs.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

const REROLL_COST := 15
const CARD_SIZE := Vector2(186, 214)

var _options: Array = []
var _next_title: String = ""
var _boss_bonus: bool = false
var _rerolled: bool = false
var _root: Control = null
var _fx_bg: Control = null
var _card_buttons: Array[Button] = []
var _card_fxs: Array[BuffCardFx] = []


class _BackdropFx extends Control:
	var boss_mode: bool = false
	var _t: float = 0.0
	var _embers: Array[Dictionary] = []

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		for i in 30:
			var seed_v: float = float(i) * 1.6180339
			var frac_x: float = fposmod(seed_v * 0.73, 1.0)
			var frac_y: float = fposmod(seed_v * 0.41, 1.0)
			_embers.append({
				"fx": frac_x,
				"y": frac_y,
				"vy": 0.055 + fposmod(seed_v * 0.29, 0.09),
				"r": 1.2 + fposmod(seed_v * 0.53, 1.8),
				"phase": seed_v * 6.28,
				"sway": 4.0 + fposmod(seed_v * 0.37, 8.0),
				"alpha": 0.35 + fposmod(seed_v * 0.19, 0.45),
			})

	func _process(delta: float) -> void:
		_t += delta
		for e in _embers:
			var ny: float = float(e["y"]) - float(e["vy"]) * delta
			if ny < -0.05:
				ny = 1.05
			e["y"] = ny
		queue_redraw()

	func _draw() -> void:
		var sz: Vector2 = size
		if sz.x <= 1.0 or sz.y <= 1.0:
			return
		var center := Vector2(sz.x * 0.5, sz.y * 0.46)
		var base_col: Color = Color(1.0, 0.78, 0.28) if boss_mode else Color(1.0, 0.72, 0.32)
		var accent_col: Color = Color(1.0, 0.42, 0.22) if boss_mode else Color(0.95, 0.65, 0.28)

		# Quầng sáng ấm sau bảng thẻ
		var pulse: float = 0.92 + 0.08 * sin(_t * 2.2)
		draw_circle(center, 220.0 * pulse, Color(base_col.r, base_col.g, base_col.b, 0.06))
		draw_circle(center, 140.0 * pulse, Color(base_col.r, base_col.g, base_col.b, 0.08))

		# Các tia hào quang vàng xoay chậm
		var ray_count: int = 12 if boss_mode else 10
		var rot_base: float = _t * (0.16 if boss_mode else 0.10)
		var max_r: float = maxf(sz.x, sz.y) * 0.82
		for i in ray_count:
			var ang: float = rot_base + float(i) * (TAU / float(ray_count))
			var spread: float = 0.085 if i % 2 == 0 else 0.055
			var p1: Vector2 = center + Vector2(cos(ang - spread), sin(ang - spread)) * max_r
			var p2: Vector2 = center + Vector2(cos(ang + spread), sin(ang + spread)) * max_r
			var alpha: float = (0.075 if i % 2 == 0 else 0.04) * (1.15 if boss_mode else 0.85)
			var tip_col := Color(base_col.r, base_col.g, base_col.b, 0.0)
			var mid_col := Color(base_col.r, base_col.g, base_col.b, alpha)
			draw_polygon(PackedVector2Array([center, p1, p2]), PackedColorArray([mid_col, tip_col, tip_col]))

		# Tàn lửa vàng cam bay lên
		for e in _embers:
			var ex: float = float(e["fx"]) * sz.x + sin(_t * 1.4 + float(e["phase"])) * float(e["sway"])
			var ey: float = float(e["y"]) * sz.y
			var er: float = float(e["r"])
			var ea: float = float(e["alpha"]) * (0.65 + 0.35 * sin(_t * 3.1 + float(e["phase"])))
			var ecol: Color = base_col.lerp(accent_col, 0.5 + 0.5 * sin(float(e["phase"])))
			draw_circle(Vector2(ex, ey), er * 2.4, Color(ecol.r, ecol.g, ecol.b, ea * 0.22))
			draw_circle(Vector2(ex, ey), er, Color(1.0, 0.94, 0.72, ea))


class BuffCardFx extends Control:
	var tier: int = 1
	var tier_col: Color = Color(0.84, 0.72, 0.52)
	var cat_col: Color = Color(1.0, 0.58, 0.38)
	var icon_anchor: Control = null
	var hovered: bool = false
	var hover_amt: float = 0.0
	var sheen_t: float = -1.0
	var _t: float = 0.0
	var _sparkles: Array[Dictionary] = []

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var count: int = 10 if tier >= 3 else (6 if tier == 2 else 3)
		for i in count:
			var s: float = float(i + 1) * 1.371
			_sparkles.append({
				"fx": 0.12 + fposmod(s * 0.43, 0.76),
				"y": fposmod(s * 0.67, 1.0),
				"vy": 0.14 + fposmod(s * 0.23, 0.18),
				"phase": s * 5.1,
				"size": 1.4 + fposmod(s * 0.31, 1.3),
			})

	func trigger_sheen() -> void:
		sheen_t = 0.0

	func _process(delta: float) -> void:
		_t += delta
		var target_hov: float = 1.0 if hovered else 0.0
		hover_amt = move_toward(hover_amt, target_hov, delta * 7.5)
		if sheen_t >= 0.0:
			sheen_t += delta * 2.2
			if sheen_t > 1.25:
				sheen_t = -1.0
		for sp in _sparkles:
			var ny: float = float(sp["y"]) - float(sp["vy"]) * delta
			if ny < 0.06:
				ny = 0.94
			sp["y"] = ny
		queue_redraw()

	func _icon_center(sz: Vector2) -> Vector2:
		if icon_anchor != null and is_instance_valid(icon_anchor) and icon_anchor.size.x > 1.0:
			var diff: Vector2 = icon_anchor.global_position - global_position
			return diff + icon_anchor.size * 0.5
		return Vector2(sz.x * 0.5, 62.0)

	func _draw() -> void:
		var sz: Vector2 = size
		if sz.x <= 2.0 or sz.y <= 2.0:
			return
		var ic: Vector2 = _icon_center(sz)
		var pulse: float = 0.5 + 0.5 * sin(_t * (3.2 if tier >= 3 else 2.2))
		var boost: float = 1.0 + hover_amt * 0.45

		# 1. Hào quang độ hiếm phía sau ảnh phúc lành 48x48
		var halo_base_a: float = (0.26 if tier >= 3 else (0.20 if tier == 2 else 0.13)) * boost
		var r_outer: float = (37.0 if tier >= 3 else (33.0 if tier == 2 else 28.0)) + pulse * 3.0
		draw_circle(ic, r_outer, Color(tier_col.r, tier_col.g, tier_col.b, halo_base_a * 0.35))
		draw_circle(ic, r_outer * 0.72, Color(tier_col.r, tier_col.g, tier_col.b, halo_base_a * 0.68))
		draw_circle(ic, 23.0, Color(0.05, 0.03, 0.08, 0.65))
		draw_arc(ic, 24.5, 0.0, TAU, 28, Color(tier_col.r, tier_col.g, tier_col.b, 0.45 + hover_amt * 0.3), 1.2)

		# 2. Vòng cổ ngữ ma pháp xoay (Tier 2 & Tier 3)
		if tier >= 2:
			var r1: float = 29.5
			var segs: int = 8 if tier >= 3 else 6
			var rot1: float = _t * (0.9 if tier >= 3 else 0.6)
			for i in segs:
				var a0: float = rot1 + float(i) * (TAU / float(segs))
				var arc_len: float = (TAU / float(segs)) * 0.52
				draw_arc(ic, r1, a0, a0 + arc_len, 8, Color(tier_col.r, tier_col.g, tier_col.b, 0.55 + 0.25 * pulse), 1.4)
				var pip: Vector2 = ic + Vector2(cos(a0 - 0.12), sin(a0 - 0.12)) * r1
				draw_circle(pip, 1.5, Color(1.0, 0.96, 0.82, 0.85))
		if tier >= 3:
			var r2: float = 34.5
			var rot2: float = -_t * 0.55
			for i in 8:
				var a: float = rot2 + float(i) * (TAU / 8.0)
				var p0: Vector2 = ic + Vector2(cos(a), sin(a)) * (r2 - 2.5)
				var p1: Vector2 = ic + Vector2(cos(a), sin(a)) * (r2 + 2.5)
				draw_line(p0, p1, Color(1.0, 0.92, 0.55, 0.65 + 0.25 * pulse), 1.4)
			draw_arc(ic, r2, 0.0, TAU, 36, Color(tier_col.r, tier_col.g, tier_col.b, 0.28 + hover_amt * 0.25), 1.0)

		# 3. Đom đóm lấp lánh bay lên
		for sp in _sparkles:
			var sx: float = float(sp["fx"]) * sz.x + sin(_t * 2.2 + float(sp["phase"])) * 3.0
			var sy: float = float(sp["y"]) * sz.y
			var sa: float = (0.35 + 0.45 * (0.5 + 0.5 * sin(_t * 4.0 + float(sp["phase"])))) * boost
			var ss: float = float(sp["size"])
			var scol: Color = tier_col.lerp(Color.WHITE, 0.55)
			scol.a = minf(sa, 0.95)
			draw_line(Vector2(sx - ss, sy), Vector2(sx + ss, sy), scol, 1.0)
			draw_line(Vector2(sx, sy - ss), Vector2(sx, sy + ss), scol, 1.0)

		# 4. Hoa văn góc thẻ (ornate corner brackets)
		var m: float = 6.0
		var b_len: float = 11.0 if tier >= 3 else 9.0
		var bcol: Color = tier_col.lightened(0.22 + hover_amt * 0.25)
		bcol.a = 0.72 + hover_amt * 0.28
		var corners: Array[Vector2] = [
			Vector2(m, m),
			Vector2(sz.x - m, m),
			Vector2(m, sz.y - m),
			Vector2(sz.x - m, sz.y - m),
		]
		var dirs: Array[Vector2] = [
			Vector2(1, 1),
			Vector2(-1, 1),
			Vector2(1, -1),
			Vector2(-1, -1),
		]
		for ci in 4:
			var cpos: Vector2 = corners[ci]
			var d: Vector2 = dirs[ci]
			draw_line(cpos, cpos + Vector2(d.x * b_len, 0.0), bcol, 1.6)
			draw_line(cpos, cpos + Vector2(0.0, d.y * b_len), bcol, 1.6)
			draw_circle(cpos + d * 3.0, 1.2, bcol)

		# 5. Vệt ánh sáng lướt chéo khi di chuột qua thẻ
		if sheen_t >= 0.0:
			var pad: float = 4.0
			var span: float = sz.x + sz.y * 0.55 + 48.0
			var band_w: float = 28.0
			var x_lead: float = -48.0 + sheen_t * span
			var skew: float = sz.y * 0.42
			var top_l: float = clampf(x_lead - band_w, pad, sz.x - pad)
			var top_r: float = clampf(x_lead, pad, sz.x - pad)
			var bot_l: float = clampf(x_lead - skew - band_w, pad, sz.x - pad)
			var bot_r: float = clampf(x_lead - skew, pad, sz.x - pad)
			if top_r > top_l + 1.0 or bot_r > bot_l + 1.0:
				var pts := PackedVector2Array([
					Vector2(top_l, pad),
					Vector2(top_r, pad),
					Vector2(bot_r, sz.y - pad),
					Vector2(bot_l, sz.y - pad),
				])
				var sc := Color(1.0, 0.96, 0.82, 0.20 * sin(clampf(sheen_t, 0.0, 1.0) * PI))
				draw_colored_polygon(pts, sc)


class _SelectionBurst extends Control:
	var origin: Vector2 = Vector2.ZERO
	var burst_col: Color = Color(1.0, 0.86, 0.35)
	var progress: float = 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a: float = clampf(1.0 - progress, 0.0, 1.0)
		var r: float = 18.0 + progress * 92.0
		draw_arc(origin, r, 0.0, TAU, 36, Color(burst_col.r, burst_col.g, burst_col.b, a * 0.9), 3.0 * (1.0 - progress * 0.6))
		draw_arc(origin, r * 0.62, 0.0, TAU, 28, Color(1.0, 0.98, 0.85, a * 0.75), 2.0)
		for i in 10:
			var ang: float = float(i) * (TAU / 10.0)
			var dist: float = 12.0 + progress * 76.0
			var p: Vector2 = origin + Vector2(cos(ang), sin(ang)) * dist
			draw_circle(p, 2.8 * a, Color(1.0, 0.94, 0.65, a))


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
	_card_buttons.clear()
	_card_fxs.clear()
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UI.make_theme()
	add_child(_root)

	var dim_bg := ColorRect.new()
	dim_bg.color = Color(0.03, 0.01, 0.04, 0.80)
	dim_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim_bg)

	var bg_fx := _BackdropFx.new()
	bg_fx.boss_mode = _boss_bonus
	_fx_bg = bg_fx
	_root.add_child(_fx_bg)

	var center := CenterContainer.new()
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = UI.make_theme()
	_root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var heading: String = "THƯỞNG HẠ TRÙM — CHỌN TUYỆT KỸ!" if _boss_bonus else "CHỌN MỘT PHÚC LÀNH"
	var hcol: Color = Color(1.0, 0.88, 0.32) if _boss_bonus else Color(1.0, 0.85, 0.42)
	box.add_child(UI.label(heading, 26, hcol))
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

	var bg_norm := Color(0.22, 0.08, 0.11, 0.94) if tr >= 3 else (Color(0.10, 0.15, 0.24, 0.94) if tr == 2 else Color(0.16, 0.10, 0.13, 0.94))
	var bg_hov := bg_norm.lightened(0.12)
	var bw: int = 3 if tr >= 3 else 2

	var slot := Control.new()
	slot.custom_minimum_size = CARD_SIZE
	slot.process_mode = Node.PROCESS_MODE_ALWAYS

	var btn := Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pivot_offset = CARD_SIZE * 0.5
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _card_style(tcol, bg_norm, bw))
	btn.add_theme_stylebox_override("hover", _card_style(tcol.lightened(0.25), bg_hov, bw))
	btn.add_theme_stylebox_override("pressed", _card_style(tcol, bg_norm.darkened(0.15), bw))
	btn.pressed.connect(pick.bind(i))
	slot.add_child(btn)

	var fx := BuffCardFx.new()
	fx.tier = tr
	fx.tier_col = tcol
	fx.cat_col = ccol
	btn.add_child(fx)

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

	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(62, 62)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = Art.tex("ui/buff_%s.png" % id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon)
	v.add_child(icon_box)
	fx.icon_anchor = icon_box

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

	_card_buttons.append(btn)
	_card_fxs.append(fx)

	# Hiệu ứng chia bài so le: trượt lên + phóng 0.86->1.0 + hiện dần (0.08s mỗi thẻ)
	btn.position.y = 24.0
	btn.scale = Vector2(0.86, 0.86)
	btn.modulate.a = 0.0
	var deal_tw: Tween = btn.create_tween()
	deal_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	deal_tw.set_parallel(true)
	var delay: float = float(i) * 0.08
	deal_tw.tween_property(btn, "position:y", 0.0, 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	deal_tw.tween_property(btn, "scale", Vector2.ONE, 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	deal_tw.tween_property(btn, "modulate:a", 1.0, 0.18).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var btn_ref: WeakRef = weakref(btn)
	var fx_ref: WeakRef = weakref(fx)
	btn.mouse_entered.connect(func():
		var b_node: Button = btn_ref.get_ref() as Button
		var f_node: BuffCardFx = fx_ref.get_ref() as BuffCardFx
		if b_node == null or f_node == null:
			return
		f_node.hovered = true
		f_node.trigger_sheen()
		var tw: Tween = b_node.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(b_node, "scale", Vector2(1.05, 1.05), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(b_node, "position:y", -5.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var b_node: Button = btn_ref.get_ref() as Button
		var f_node: BuffCardFx = fx_ref.get_ref() as BuffCardFx
		if b_node == null or f_node == null:
			return
		f_node.hovered = false
		var tw: Tween = b_node.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(b_node, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(b_node, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

	return slot


func _spawn_selection_burst(i: int, id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var host: Node = get_parent()
	if host == null or not is_instance_valid(host):
		return
	var center_pos := Vector2(320.0, 180.0)
	if i >= 0 and i < _card_buttons.size() and is_instance_valid(_card_buttons[i]):
		var b: Button = _card_buttons[i]
		center_pos = b.global_position + b.size * 0.5
	var burst_layer := CanvasLayer.new()
	burst_layer.layer = 29
	burst_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var burst := _SelectionBurst.new()
	burst.origin = center_pos
	burst.burst_col = BuffData.tier_color(id)
	burst_layer.add_child(burst)
	host.add_child(burst_layer)
	var layer_ref: WeakRef = weakref(burst_layer)
	var tw: Tween = burst.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(burst, "progress", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		var l_node: CanvasLayer = layer_ref.get_ref() as CanvasLayer
		if l_node != null and is_instance_valid(l_node):
			l_node.queue_free()
	)


func pick(i: int) -> void:
	if not visible or i < 0 or i >= _options.size():
		return
	var picked_id: String = str(_options[i])
	_spawn_selection_burst(i, picked_id)
	visible = false
	if not Net.is_online():
		get_tree().paused = false
	chosen.emit(picked_id)
