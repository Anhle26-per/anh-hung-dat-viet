extends Node2D
## Hiệu ứng Hợp Chiêu Đại Việt:
## Dây năng lượng nhịp đập nối hai người chơi, ấn sao Trống Đồng Đông Sơn nở rộng ở tâm,
## sóng xung kích đồng tâm và mưa hạt rực rỡ kéo dài ~1.4 giây.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const DURATION: float = 1.4

var local_a: Vector2 = Vector2.ZERO
var local_b: Vector2 = Vector2.ZERO
var combo_color: Color = Color(1.0, 0.84, 0.34)
var max_radius: float = 160.0
var _t: float = 0.0
var _mid_burst_done: bool = false
var _glow_layer: Node2D = null
var _pulse_light: PointLight2D = null


class _GlowLayer extends Node2D:
	var owner_fx = null

	func _draw() -> void:
		if owner_fx != null and is_instance_valid(owner_fx):
			owner_fx._draw_glow(self)


static func spawn(parent: Node, pos_a: Vector2, pos_b: Vector2, combo: Dictionary) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var mid: Vector2 = (pos_a + pos_b) * 0.5
	var fx := new()
	fx.position = mid
	fx.local_a = pos_a - mid
	fx.local_b = pos_b - mid
	var c_val: Variant = combo.get("color", Color(1.0, 0.84, 0.34))
	fx.combo_color = c_val as Color if c_val is Color else Color(1.0, 0.84, 0.34)
	fx.max_radius = clampf(float(combo.get("radius", 160.0)), 90.0, 260.0)
	parent.add_child(fx)
	return fx


func _ready() -> void:
	z_index = 6
	_glow_layer = _GlowLayer.new()
	_glow_layer.owner_fx = self
	_glow_layer.z_index = 1
	_glow_layer.material = Art.additive()
	add_child(_glow_layer)

	var gold := Color(1.0, 0.86, 0.34)
	_pulse_light = Art.light(combo_color.lerp(gold, 0.4), 3.0, 1.35)
	add_child(_pulse_light)

	if is_inside_tree() and get_parent() != null:
		var par := get_parent()
		Fx.particles(par, global_position, gold, 24, 155.0, 0.75, -18.0, 2.4, 180.0, Vector2.UP, combo_color)
		Fx.particles(par, global_position + local_a, combo_color, 14, 105.0, 0.55, -12.0, 2.0, 180.0, Vector2.UP, gold)
		if local_a.distance_to(local_b) > 8.0:
			Fx.particles(par, global_position + local_b, combo_color, 14, 105.0, 0.55, -12.0, 2.0, 180.0, Vector2.UP, gold)


func _process(delta: float) -> void:
	_t += delta
	var p: float = clampf(_t / DURATION, 0.0, 1.0)
	if not _mid_burst_done and p >= 0.32:
		_mid_burst_done = true
		if is_inside_tree() and get_parent() != null:
			var gold := Color(1.0, 0.88, 0.42)
			Fx.particles(get_parent(), global_position, combo_color, 26, 185.0, 0.72, 0.0, 2.6, 180.0, Vector2.UP, gold)
	if _pulse_light != null:
		var env: float = sin(p * PI)
		_pulse_light.energy = env * 1.55
		_pulse_light.texture_scale = 2.4 + env * 2.2
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()
	if _glow_layer != null:
		_glow_layer.queue_redraw()


func _draw() -> void:
	var p: float = clampf(_t / DURATION, 0.0, 1.0)
	_draw_layers(self, p, false)


func _draw_glow(ci: CanvasItem) -> void:
	var p: float = clampf(_t / DURATION, 0.0, 1.0)
	_draw_layers(ci, p, true)


func _draw_layers(ci: CanvasItem, p: float, glow: bool) -> void:
	var env: float = _envelope(p)
	var gold := Color(1.0, 0.86, 0.32)
	var white_gold := Color(1.0, 0.97, 0.78)
	var eo: float = _ease_out_cubic(p)
	var sigil_pop: float = _ease_out_back(minf(p * 2.4, 1.0))

	# 1. Dây năng lượng nhịp đập nối hai người chơi
	var span: float = local_a.distance_to(local_b)
	if span > 4.0:
		var pulse: float = 0.72 + 0.28 * sin(_t * 26.0)
		var ab: Vector2 = (local_b - local_a).normalized()
		var perp := Vector2(-ab.y, ab.x)
		if glow:
			ci.draw_line(local_a, local_b, Color(combo_color, 0.42 * env * pulse), 9.0 * pulse)
			ci.draw_line(local_a, local_b, Color(white_gold, 0.75 * env), 3.0)
		else:
			ci.draw_line(local_a, local_b, Color(combo_color, 0.55 * env), 5.0 * pulse)
			ci.draw_line(local_a, local_b, Color(gold, 0.90 * env), 2.0)
		# Hai dải sóng năng lượng quấn quanh trục nối
		for strand in 2:
			var sgn: float = -1.0 if strand == 0 else 1.0
			var pts := PackedVector2Array()
			var segs: int = 18
			for i in range(segs + 1):
				var frac: float = float(i) / float(segs)
				var base_pt: Vector2 = local_a.lerp(local_b, frac)
				var amp: float = sin(frac * PI) * (9.5 + 3.5 * sin(_t * 18.0))
				var wave: float = sin(frac * TAU * 2.0 - _t * 14.0 * sgn) * amp
				pts.append(base_pt + perp * wave)
			var scol: Color = Color(gold if strand == 0 else combo_color, (0.65 if glow else 0.78) * env)
			ci.draw_polyline(pts, scol, 2.2 if glow else 1.6)
		# Vòng neo tại hai điểm đứng của đồng đội
		for anchor in [local_a, local_b]:
			var ar: float = (16.0 + 5.0 * sin(_t * 20.0)) * sigil_pop
			ci.draw_arc(anchor, ar, 0.0, TAU, 24, Color(combo_color, (0.55 if glow else 0.75) * env), 2.2)
			ci.draw_circle(anchor, 5.0 * pulse * env, Color(white_gold, (0.55 if glow else 0.80) * env))

	# 2. Sóng xung kích đồng tâm nở rộng từ tâm
	for ring_idx in 3:
		var delay: float = float(ring_idx) * 0.14
		var rp: float = clampf((p - delay) / maxf(1.0 - delay, 0.01), 0.0, 1.0)
		if rp <= 0.001 or rp >= 0.995:
			continue
		var r_cur: float = lerpf(12.0, max_radius * (1.0 - 0.12 * float(ring_idx)), _ease_out_cubic(rp))
		var r_alpha: float = (1.0 - rp) * (0.62 if glow else 0.85)
		var r_col: Color = gold if ring_idx == 1 else combo_color
		var r_thick: float = (4.2 - float(ring_idx) * 0.8) * (1.0 - 0.45 * rp)
		ci.draw_arc(Vector2.ZERO, r_cur, 0.0, TAU, 48, Color(r_col, r_alpha), r_thick)

	# 3. Ấn sao Trống Đồng Đông Sơn vàng rực ở trung điểm
	var sigil_r: float = lerpf(14.0, max_radius * 0.48, eo) * sigil_pop
	var rot: float = _t * 1.4
	if not glow:
		ci.draw_circle(Vector2.ZERO, sigil_r * 0.88, Color(combo_color, 0.14 * env))
		ci.draw_arc(Vector2.ZERO, sigil_r, 0.0, TAU, 40, Color(gold, 0.92 * env), 2.4)
		ci.draw_arc(Vector2.ZERO, sigil_r * 0.74, 0.0, TAU, 36, Color(combo_color, 0.78 * env), 1.6)
		ci.draw_arc(Vector2.ZERO, sigil_r * 0.36, 0.0, TAU, 24, Color(white_gold, 0.88 * env), 1.5)
	else:
		ci.draw_circle(Vector2.ZERO, sigil_r * 0.55, Color(gold, 0.20 * env))
		ci.draw_arc(Vector2.ZERO, sigil_r * 1.03, 0.0, TAU, 40, Color(gold, 0.58 * env), 4.0)

	# Tia khắc vòng ngoài kiểu mặt trống đồng
	var notches: int = 16
	for i in notches:
		var ang: float = rot * 0.6 + TAU * float(i) / float(notches)
		var dir_v := Vector2.from_angle(ang)
		var n_col := Color(gold if i % 2 == 0 else combo_color, (0.72 if glow else 0.92) * env)
		ci.draw_line(dir_v * (sigil_r * 0.76), dir_v * (sigil_r * 0.98), n_col, 2.0 if i % 2 == 0 else 1.2)

	# Mặt trời 12 cánh Đông Sơn ở tâm
	var star_col: Color = Color(white_gold if glow else gold, (0.72 if glow else 0.94) * env)
	_draw_star(ci, Vector2.ZERO, sigil_r * 0.66, sigil_r * 0.28, 12, rot, star_col)
	ci.draw_circle(Vector2.ZERO, sigil_r * 0.16, Color(white_gold, 0.95 * env))


static func _draw_star(ci: CanvasItem, pos: Vector2, r_outer: float, r_inner: float, spikes: int, rot: float, col: Color) -> void:
	if r_outer <= 0.4 or spikes < 3:
		return
	var pts := PackedVector2Array()
	var n: int = spikes * 2
	for i in n:
		var ang: float = rot + TAU * float(i) / float(n)
		var rr: float = r_outer if i % 2 == 0 else r_inner
		pts.append(pos + Vector2.from_angle(ang) * rr)
	ci.draw_colored_polygon(pts, col)


static func _envelope(p: float) -> float:
	if p < 0.12:
		return clampf(p / 0.12, 0.0, 1.0)
	if p > 0.72:
		return clampf(1.0 - (p - 0.72) / 0.28, 0.0, 1.0)
	return 1.0


static func _ease_out_cubic(x: float) -> float:
	var t := 1.0 - clampf(x, 0.0, 1.0)
	return 1.0 - t * t * t


static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var t := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + c3 * t * t * t + c1 * t * t
