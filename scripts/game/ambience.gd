extends Node2D
## Không khí sống động cho doanh trại: vệt nắng xiên, bụi lấp lánh, bướm bay, lá và cánh hoa rơi.

const Art = preload("res://scripts/art/art.gd")
const WeatherFx = preload("res://scripts/effects/weather_fx.gd")

const LOTUS_POND_RECT := Rect2(120, 480, 200, 140)
const BRONZE_DRUM_POS := Vector2(680, 446)

var area := Rect2(0, 0, 544, 304)
var _t := 0.0
var _butterflies: Array = []
var _fireflies: Array = []
var _rays: Node2D
var _glow_env: WorldEnvironment = null


class Rays extends Node2D:
	## Vệt nắng chiếu xiên từ trên xuống, nhấp nháy nhẹ
	var area: Rect2
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 4:
			var x := area.position.x + area.size.x * (0.14 + i * 0.24)
			var a := 0.035 + 0.02 * sin(t * 0.7 + i * 1.7)
			var w := 26.0 + 8.0 * float(i % 3)
			var tilt := 50.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, area.position.y), Vector2(x + w, area.position.y),
				Vector2(x + w + tilt, area.end.y), Vector2(x + tilt, area.end.y)]), Color(1.0, 0.92, 0.7, a))


func _ready() -> void:
	z_index = 9
	_rays = Rays.new()
	_rays.area = area
	_rays.material = Art.additive()
	add_child(_rays)
	add_child(_falling("fx/leaf.png", 10, 11.0, [Color(0.95, 0.65, 0.2), Color(0.85, 0.45, 0.15), Color(0.55, 0.75, 0.3)]))
	add_child(_falling("fx/petal.png", 18, 9.0, [Color(1, 0.8, 0.88), Color(1, 0.7, 0.8)]))
	add_child(_motes())
	add_child(_pond_fireflies())
	add_child(_drum_incense_smoke())
	for i in 10:
		_fireflies.append({
			"seed": randf() * 25.0,
			"freq": randf_range(1.6, 3.2),
			"col": Color(0.92, 1.0, 0.56) if i % 2 == 0 else Color(1.0, 0.88, 0.48),
		})
	for i in 6:
		_butterflies.append({"p": Vector2.ZERO, "seed": randf() * 20.0, "col": [
			Color(1.0, 0.85, 0.28),
			Color(0.55, 0.88, 1.0),
			Color(1.0, 0.58, 0.78),
			Color(0.98, 0.96, 0.92),
			Color(1.0, 0.68, 0.28),
			Color(0.75, 0.65, 1.0),
		][i]})


func enable_glow() -> void:
	if _glow_env != null and is_instance_valid(_glow_env):
		return
	if WeatherFx != null:
		_glow_env = WeatherFx.apply_glow_environment(self, 0.35, 0.08)


func _falling(tex: String, amount: int, life: float, colors: Array) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = Art.tex(tex)
	p.position = Vector2(area.get_center().x, area.position.y - 10)
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(area.size.x * 0.6, 4)
	p.direction = Vector2(0.4, 1)
	p.spread = 25.0
	p.gravity = Vector2(5, 9)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 16.0
	p.angular_velocity_min = -160.0
	p.angular_velocity_max = 160.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.orbit_velocity_min = -0.02
	p.orbit_velocity_max = 0.02
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[colors.size() - 1])
	p.color_initial_ramp = g
	return p


func _motes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = area.get_center()
	p.amount = 24
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, -2)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.5
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.95, 0.75, 0.0))
	g.add_point(0.5, Color(1, 0.95, 0.75, 0.8))
	g.set_color(g.get_point_count() - 1, Color(1, 0.95, 0.75, 0.0))
	p.color_ramp = g
	p.material = Art.additive()
	return p


func _pond_fireflies() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = LOTUS_POND_RECT.get_center()
	p.amount = 14
	p.lifetime = 3.8
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = LOTUS_POND_RECT.size * 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, -1.5)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 8.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	var g := Gradient.new()
	g.set_color(0, Color(0.92, 1.0, 0.55, 0.0))
	g.add_point(0.5, Color(0.95, 1.0, 0.60, 0.85))
	g.set_color(g.get_point_count() - 1, Color(1.0, 0.88, 0.45, 0.0))
	p.color_ramp = g
	p.material = Art.additive()
	return p


func _drum_incense_smoke() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = BRONZE_DRUM_POS
	p.amount = 14
	p.lifetime = 3.4
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.direction = Vector2(0.08, -1.0)
	p.spread = 18.0
	p.gravity = Vector2(3.5, -5.0)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 13.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.2
	var g := Gradient.new()
	g.set_color(0, Color(0.92, 0.88, 0.96, 0.0))
	g.add_point(0.25, Color(0.92, 0.88, 0.96, 0.26))
	g.set_color(g.get_point_count() - 1, Color(0.92, 0.88, 0.96, 0.0))
	p.color_ramp = g
	return p


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# Đom đóm phát sáng dịu quanh hồ sen phía tây
	var pond_c := LOTUS_POND_RECT.get_center()
	var pond_half := LOTUS_POND_RECT.size * 0.44
	for f in _fireflies:
		var s: float = float(f.seed)
		var freq: float = float(f.freq)
		var fp := pond_c + Vector2(sin(_t * 0.45 + s) * pond_half.x, cos(_t * 0.62 + s * 1.3) * pond_half.y)
		var glow := maxf(0.08, 0.5 + 0.5 * sin(_t * freq + s))
		var fcol: Color = f.col
		draw_circle(fp, 4.5 * glow, Color(fcol.r, fcol.g, fcol.b, 0.14 * glow))
		draw_circle(fp, 1.3, Color(1.0, 1.0, 0.82, 0.78 * glow))

	# bướm 2 đôi cánh có đốm màu bay lượn quanh 4 phòng
	for b in _butterflies:
		var s: float = b.seed
		var c := area.get_center()
		var p := c + Vector2(sin(_t * 0.28 + s) * area.size.x * 0.44, sin(_t * 0.49 + s * 1.7) * area.size.y * 0.40 + sin(_t * 3.0 + s) * 4.0)
		var flap := maxf(0.15, absf(sin(_t * 14.0 + s)))
		var col: Color = b.col
		var w_top := 3.6 * flap
		var w_bot := 2.4 * flap
		# Cánh trên + cánh dưới hai bên
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-w_top, -3.2 * flap), p + Vector2(-w_top * 0.8, 0.5)]), col)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-w_bot, 0.6), p + Vector2(-w_bot * 0.7, 2.8)]), col.darkened(0.16))
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(w_top, -3.2 * flap), p + Vector2(w_top * 0.8, 0.5)]), col.darkened(0.08))
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(w_bot, 0.6), p + Vector2(w_bot * 0.7, 2.8)]), col.darkened(0.24))
		# Chấm sáng trên cánh & thân bướm
		if flap > 0.45:
			draw_circle(p + Vector2(-w_top * 0.55, -1.2 * flap), 0.7, Color(1, 1, 1, 0.75))
			draw_circle(p + Vector2(w_top * 0.55, -1.2 * flap), 0.7, Color(1, 1, 1, 0.75))
		draw_rect(Rect2(p - Vector2(0.5, 1.5), Vector2(1.0, 3.5)), Color(0.14, 0.08, 0.16))
