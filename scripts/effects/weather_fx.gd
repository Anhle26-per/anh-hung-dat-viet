extends Node2D
## Hiệu ứng thời tiết theo từng chương lịch sử & Thần Thoại + ánh sáng WorldEnvironment dịu mắt.

const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

var level_id: int = 1
var weather_area: Rect2 = Rect2(0, 0, 640, 360)
var preset: Dictionary = {}

var _t: float = 0.0
var _motes: Array[Dictionary] = []
var _particles: Array[CPUParticles2D] = []


## Trả về cấu hình thời tiết {kind, label, tint, intensity} theo chương của màn chơi.
static func preset_for_level(level: int) -> Dictionary:
	var ch: Dictionary = EnemyData.chapter(level)
	var ch_name: String = str(ch.get("name", ""))
	var weather_id: String = str(ch.get("weather", ""))
	match weather_id:
		"abyss_bubbles":
			return {
				"kind": "abyss_bubbles",
				"label": ch_name if ch_name != "" else "Thủy Cung Bạch Đằng",
				"tint": Color(0.32, 0.92, 1.0, 0.92),
				"intensity": 1.0,
			}
		"thunder_peak":
			return {
				"kind": "thunder_peak",
				"label": ch_name if ch_name != "" else "Đỉnh Tản Viên",
				"tint": Color(0.56, 0.80, 1.0, 0.94),
				"intensity": 1.0,
			}
		"cosmic_embers":
			return {
				"kind": "cosmic_embers",
				"label": ch_name if ch_name != "" else "Đỉnh Hồng Lĩnh — Cửu Trùng",
				"tint": Color(0.88, 0.62, 1.0, 0.95),
				"intensity": 1.05,
			}
	if EnemyData.is_mythic_level(level) or level >= 19 or bool(ch.get("mythic", false)):
		return {
			"kind": "mythic_snow",
			"label": "Tuyết linh %s" % (ch_name if ch_name != "" else "Thần Thoại"),
			"tint": Color(0.82, 0.90, 1.0, 0.90),
			"intensity": 1.0,
		}
	match ch_name:
		"Mê Linh":
			return {
				"kind": "petals",
				"label": "Hoa đào Mê Linh",
				"tint": Color(1.0, 0.78, 0.86, 0.85),
				"intensity": 0.85,
			}
		"Núi Nưa":
			return {
				"kind": "petals",
				"label": "Hoa rừng Núi Nưa",
				"tint": Color(1.0, 0.86, 0.72, 0.85),
				"intensity": 0.80,
			}
		"Sông Bạch Đằng":
			return {
				"kind": "rain_mist",
				"label": "Mưa sương Bạch Đằng",
				"tint": Color(0.72, 0.86, 1.0, 0.85),
				"intensity": 0.95,
			}
		"Sông Như Nguyệt":
			return {
				"kind": "rain_mist",
				"label": "Mưa đêm Như Nguyệt",
				"tint": Color(0.76, 0.88, 1.0, 0.85),
				"intensity": 0.90,
			}
		"Vàm Nhật Tảo":
			return {
				"kind": "rain_mist",
				"label": "Mưa sông Nhật Tảo",
				"tint": Color(0.68, 0.82, 0.98, 0.85),
				"intensity": 0.95,
			}
		"Thành Thăng Long":
			return {
				"kind": "embers",
				"label": "Tro lửa Thăng Long",
				"tint": Color(1.0, 0.64, 0.28, 0.90),
				"intensity": 0.90,
			}
		"Ải Chi Lăng":
			return {
				"kind": "embers",
				"label": "Lửa phục kích Chi Lăng",
				"tint": Color(1.0, 0.58, 0.24, 0.90),
				"intensity": 0.85,
			}
		"Gò Đống Đa":
			return {
				"kind": "embers",
				"label": "Tàn lửa Đống Đa",
				"tint": Color(1.0, 0.52, 0.22, 0.95),
				"intensity": 0.95,
			}
		"Điện Biên Phủ":
			return {
				"kind": "embers",
				"label": "Khói lửa Điện Biên Phủ",
				"tint": Color(1.0, 0.62, 0.30, 0.90),
				"intensity": 1.0,
			}
		"Rừng Yên Thế":
			return {
				"kind": "bamboo_leaves",
				"label": "Lá tre Rừng Yên Thế",
				"tint": Color(0.68, 0.92, 0.48, 0.85),
				"intensity": 0.85,
			}
		_:
			return {
				"kind": "petals",
				"label": ch_name if ch_name != "" else "Gió Đại Việt",
				"tint": Color(1.0, 0.86, 0.78, 0.80),
				"intensity": 0.80,
			}


## Tạo WorldEnvironment với hiệu ứng bloom dịu mắt (bỏ qua trong headless để tránh cảnh báo).
static func apply_glow_environment(parent: Node, intensity: float = 0.42, bloom: float = 0.10) -> WorldEnvironment:
	if DisplayServer.get_name() == "headless":
		return null
	if parent != null and is_instance_valid(parent):
		for child in parent.get_children():
			if child is WorldEnvironment:
				return child as WorldEnvironment
	var we := WorldEnvironment.new()
	we.name = "WeatherGlowEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = intensity
	env.glow_bloom = bloom
	env.glow_hdr_threshold = 0.92
	we.environment = env
	if parent != null and is_instance_valid(parent):
		parent.add_child(we)
	return we


## Khởi tạo hạt thời tiết và lớp vẽ nhẹ ở z_index = 9 trên vùng area.
func setup(level: int, area: Rect2) -> void:
	level_id = level
	if area.size.x > 1.0 and area.size.y > 1.0:
		weather_area = area
	else:
		weather_area = Rect2(0.0, 0.0, 640.0, 360.0)
	z_index = 9
	preset = preset_for_level(level)

	for old_p in _particles:
		if old_p != null and is_instance_valid(old_p):
			old_p.queue_free()
	_particles.clear()
	_motes.clear()

	var kind: String = str(preset.get("kind", "petals"))
	var tint: Color = preset.get("tint", Color(1.0, 0.85, 0.88, 0.85))
	var inten: float = float(preset.get("intensity", 0.85))

	_spawn_particles(kind, tint, inten)
	_seed_motes(kind, inten)
	queue_redraw()


func _spawn_particles(kind: String, tint: Color, inten: float) -> void:
	var vis := _visible_rect()
	var extents := Vector2(clampf(vis.size.x * 0.52, 160.0, 480.0), clampf(vis.size.y * 0.52, 120.0, 320.0))

	match kind:
		"petals":
			var p := _make_emitter(vis.get_center(), extents, Art.tex("fx/petal.png"), maxi(12, int(round(24.0 * inten))), 7.5)
			p.direction = Vector2(0.45, 1.0)
			p.spread = 24.0
			p.gravity = Vector2(7.0, 10.0)
			p.initial_velocity_min = 8.0
			p.initial_velocity_max = 18.0
			p.angular_velocity_min = -140.0
			p.angular_velocity_max = 140.0
			p.orbit_velocity_min = -0.02
			p.orbit_velocity_max = 0.02
			p.scale_amount_min = 0.75
			p.scale_amount_max = 1.25
			p.color_ramp = _fade_ramp(tint, tint.lightened(0.15), 0.78)
			add_child(p)
			_particles.append(p)
		"rain_mist":
			var rain := _make_emitter(vis.get_center(), extents, Art.tex("fx/dust.png"), maxi(18, int(round(34.0 * inten))), 1.15)
			rain.direction = Vector2(-0.24, 1.0)
			rain.spread = 6.0
			rain.gravity = Vector2(-32.0, 260.0)
			rain.initial_velocity_min = 120.0
			rain.initial_velocity_max = 185.0
			rain.scale_amount_min = 0.55
			rain.scale_amount_max = 0.95
			rain.color_ramp = _fade_ramp(tint, Color(tint.r, tint.g, tint.b, 0.1), 0.55)
			add_child(rain)
			_particles.append(rain)

			var mist := _make_emitter(vis.get_center(), extents, Art.tex("fx/light.png"), maxi(8, int(round(12.0 * inten))), 4.8)
			mist.direction = Vector2(1.0, 0.05)
			mist.spread = 22.0
			mist.gravity = Vector2(4.0, -1.5)
			mist.initial_velocity_min = 6.0
			mist.initial_velocity_max = 14.0
			mist.scale_amount_min = 1.2
			mist.scale_amount_max = 2.2
			mist.color_ramp = _fade_ramp(Color(tint.r, tint.g, tint.b, 0.14), Color(0.85, 0.93, 1.0, 0.08), 0.16)
			add_child(mist)
			_particles.append(mist)
		"embers":
			var emb := _make_emitter(vis.get_center(), extents, Art.tex("fx/spark.png"), maxi(14, int(round(28.0 * inten))), 3.4)
			emb.direction = Vector2(0.18, -1.0)
			emb.spread = 32.0
			emb.gravity = Vector2(8.0, -24.0)
			emb.initial_velocity_min = 10.0
			emb.initial_velocity_max = 26.0
			emb.scale_amount_min = 0.6
			emb.scale_amount_max = 1.15
			emb.color_ramp = _fade_ramp(Color(1.0, 0.85, 0.38, 0.9), Color(1.0, 0.34, 0.12, 0.7), 0.85)
			emb.material = Art.additive()
			add_child(emb)
			_particles.append(emb)
		"bamboo_leaves":
			var lv := _make_emitter(vis.get_center(), extents, Art.tex("fx/leaf.png"), maxi(12, int(round(22.0 * inten))), 6.8)
			lv.direction = Vector2(0.55, 1.0)
			lv.spread = 28.0
			lv.gravity = Vector2(11.0, 12.0)
			lv.initial_velocity_min = 10.0
			lv.initial_velocity_max = 22.0
			lv.angular_velocity_min = -180.0
			lv.angular_velocity_max = 180.0
			lv.orbit_velocity_min = -0.03
			lv.orbit_velocity_max = 0.03
			lv.scale_amount_min = 0.8
			lv.scale_amount_max = 1.3
			lv.color_ramp = _fade_ramp(tint, Color(0.86, 0.82, 0.36), 0.80)
			add_child(lv)
			_particles.append(lv)
		"mythic_snow":
			var snow := _make_emitter(vis.get_center(), extents, Art.tex("fx/light.png"), maxi(16, int(round(30.0 * inten))), 5.6)
			snow.direction = Vector2(-0.15, 1.0)
			snow.spread = 26.0
			snow.gravity = Vector2(-4.0, 14.0)
			snow.initial_velocity_min = 8.0
			snow.initial_velocity_max = 18.0
			snow.orbit_velocity_min = -0.03
			snow.orbit_velocity_max = 0.03
			snow.scale_amount_min = 0.25
			snow.scale_amount_max = 0.55
			snow.color_ramp = _fade_ramp(tint, Color(0.95, 0.98, 1.0), 0.85)
			snow.material = Art.additive()
			add_child(snow)
			_particles.append(snow)
		"abyss_bubbles":
			var bub := _make_emitter(vis.get_center(), extents, Art.tex("fx/light.png"), maxi(16, int(round(28.0 * inten))), 4.8)
			bub.direction = Vector2(0.0, -1.0)
			bub.spread = 20.0
			bub.gravity = Vector2(0.0, -18.0)
			bub.initial_velocity_min = 10.0
			bub.initial_velocity_max = 24.0
			bub.orbit_velocity_min = -0.04
			bub.orbit_velocity_max = 0.04
			bub.scale_amount_min = 0.22
			bub.scale_amount_max = 0.52
			bub.color_ramp = _fade_ramp(tint, Color(0.55, 0.98, 1.0), 0.78)
			bub.material = Art.additive()
			add_child(bub)
			_particles.append(bub)
		"thunder_peak":
			var wind := _make_emitter(vis.get_center(), extents, Art.tex("fx/dust.png"), maxi(18, int(round(32.0 * inten))), 0.95)
			wind.direction = Vector2(-0.48, 1.0)
			wind.spread = 8.0
			wind.gravity = Vector2(-90.0, 240.0)
			wind.initial_velocity_min = 135.0
			wind.initial_velocity_max = 200.0
			wind.scale_amount_min = 0.55
			wind.scale_amount_max = 0.95
			wind.color_ramp = _fade_ramp(tint, Color(0.75, 0.92, 1.0, 0.14), 0.52)
			add_child(wind)
			_particles.append(wind)

			var spk := _make_emitter(vis.get_center(), extents, Art.tex("fx/spark.png"), maxi(10, int(round(18.0 * inten))), 1.4)
			spk.direction = Vector2(-0.2, -1.0)
			spk.spread = 50.0
			spk.gravity = Vector2(0.0, -12.0)
			spk.initial_velocity_min = 16.0
			spk.initial_velocity_max = 36.0
			spk.scale_amount_min = 0.55
			spk.scale_amount_max = 1.05
			spk.color_ramp = _fade_ramp(Color(0.55, 0.90, 1.0, 0.95), Color(1.0, 0.98, 0.65, 0.8), 0.9)
			spk.material = Art.additive()
			add_child(spk)
			_particles.append(spk)
		"cosmic_embers":
			var c_emb := _make_emitter(vis.get_center(), extents, Art.tex("fx/spark.png"), maxi(18, int(round(32.0 * inten))), 3.8)
			c_emb.direction = Vector2(0.08, -1.0)
			c_emb.spread = 34.0
			c_emb.gravity = Vector2(4.0, -26.0)
			c_emb.initial_velocity_min = 12.0
			c_emb.initial_velocity_max = 28.0
			c_emb.orbit_velocity_min = -0.02
			c_emb.orbit_velocity_max = 0.02
			c_emb.scale_amount_min = 0.65
			c_emb.scale_amount_max = 1.25
			c_emb.color_ramp = _fade_ramp(Color(1.0, 0.86, 0.36, 0.94), Color(0.78, 0.42, 1.0, 0.78), 0.90)
			c_emb.material = Art.additive()
			add_child(c_emb)
			_particles.append(c_emb)


func _make_emitter(pos: Vector2, extents: Vector2, tex: Texture2D, amount: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.texture = tex
	p.amount = amount
	p.lifetime = life
	p.preprocess = minf(life, 3.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.angle_min = 0.0
	p.angle_max = 360.0
	return p


func _fade_ramp(c0: Color, c1: Color, peak_alpha: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(c0.r, c0.g, c0.b, 0.0))
	g.add_point(0.25, Color(c0.r, c0.g, c0.b, peak_alpha))
	g.add_point(0.75, Color(c1.r, c1.g, c1.b, peak_alpha * 0.7))
	g.set_color(g.get_point_count() - 1, Color(c1.r, c1.g, c1.b, 0.0))
	return g


func _seed_motes(kind: String, inten: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_id * 4999 + kind.hash()
	var count: int = 24 if kind == "rain_mist" else 18
	count = maxi(10, int(round(float(count) * clampf(inten, 0.6, 1.2))))
	for i in count:
		_motes.append({
			"u": rng.randf(),
			"v": rng.randf(),
			"spd": rng.randf_range(0.65, 1.35),
			"sz": rng.randf_range(0.7, 1.35),
			"phase": rng.randf_range(0.0, TAU),
		})


func _visible_rect() -> Rect2:
	var vp := get_viewport()
	if vp != null:
		var cam := vp.get_camera_2d()
		if cam != null and is_instance_valid(cam):
			var vp_size := vp.get_visible_rect().size
			var z := cam.zoom
			if z.x > 0.01 and z.y > 0.01:
				var half := (vp_size / z) * 0.55
				var center := cam.get_screen_center_position()
				return Rect2(center - half, half * 2.0)
	if weather_area.size.x > 960.0 or weather_area.size.y > 640.0:
		var c := weather_area.get_center()
		return Rect2(c - Vector2(480.0, 320.0), Vector2(960.0, 640.0))
	return weather_area


func _process(delta: float) -> void:
	_t += delta
	var vis := _visible_rect()
	var center := vis.get_center()
	for p in _particles:
		if p != null and is_instance_valid(p):
			p.position = center
	queue_redraw()


func _draw() -> void:
	if _motes.is_empty():
		return
	var vis := _visible_rect()
	var kind: String = str(preset.get("kind", "petals"))
	var tint: Color = preset.get("tint", Color.WHITE)

	match kind:
		"rain_mist":
			# Dải sương mỏng trôi ngang trên mặt nước/trận địa
			for b in 3:
				var by := vis.position.y + vis.size.y * (0.22 + float(b) * 0.28) + sin(_t * 0.55 + float(b) * 2.1) * 14.0
				var bx := vis.position.x + fposmod(float(b) * 0.37 + _t * 0.04, 1.0) * vis.size.x - 90.0
				var mist_col := Color(tint.r, tint.g, tint.b, 0.055 + 0.025 * sin(_t * 0.9 + float(b)))
				draw_rect(Rect2(Vector2(bx, by), Vector2(180.0, 18.0)), mist_col)
			# Hạt mưa chéo mảnh
			for m in _motes:
				var spd: float = float(m.spd)
				var u := fposmod(float(m.u) - _t * 0.22 * spd, 1.0)
				var v := fposmod(float(m.v) + _t * 0.95 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var len_v := Vector2(-4.5, 16.0) * float(m.sz)
				draw_line(p, p + len_v, Color(tint.r, tint.g, tint.b, 0.28), 1.0)
		"embers":
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + sin(_t * 0.8 + ph) * 0.04 + _t * 0.02 * spd, 1.0)
				var v := fposmod(float(m.v) - _t * 0.14 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var flicker := 0.45 + 0.45 * sin(_t * 6.5 + ph)
				var sz: float = 1.4 * float(m.sz)
				draw_circle(p, sz * 2.0, Color(tint.r, tint.g * 0.75, 0.15, 0.12 * flicker))
				draw_circle(p, sz * 0.75, Color(1.0, 0.88, 0.48, 0.55 * flicker))
		"mythic_snow":
			for b in 2:
				var by := vis.position.y + vis.size.y * (0.30 + float(b) * 0.40) + cos(_t * 0.4 + float(b)) * 12.0
				draw_rect(Rect2(Vector2(vis.position.x, by), Vector2(vis.size.x, 14.0)), Color(tint.r, tint.g, tint.b, 0.04))
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + sin(_t * 0.7 + ph) * 0.03 - _t * 0.015 * spd, 1.0)
				var v := fposmod(float(m.v) + _t * 0.10 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var glint := 0.45 + 0.45 * sin(_t * 4.2 + ph)
				var r: float = 1.8 * float(m.sz)
				var col := Color(tint.r, tint.g, tint.b, 0.45 * glint)
				draw_line(p - Vector2(r, 0.0), p + Vector2(r, 0.0), col, 1.0)
				draw_line(p - Vector2(0.0, r), p + Vector2(0.0, r), col, 1.0)
		"bamboo_leaves":
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + _t * 0.08 * spd + sin(_t * 1.1 + ph) * 0.025, 1.0)
				var v := fposmod(float(m.v) + _t * 0.12 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var ang := _t * 1.6 + ph
				var dir := Vector2(cos(ang), sin(ang)) * (3.2 * float(m.sz))
				var perp := Vector2(-dir.y, dir.x) * 0.35
				var col := Color(tint.r, tint.g, tint.b, 0.42)
				draw_colored_polygon(PackedVector2Array([p - dir, p + perp, p + dir, p - perp]), col)
		"abyss_bubbles":
			# Sương thủy tảo trôi nhẹ ở Thủy Cung Bạch Đằng
			for b in 3:
				var by := vis.position.y + vis.size.y * (0.20 + float(b) * 0.30) + sin(_t * 0.6 + float(b) * 1.9) * 12.0
				var bx := vis.position.x + fposmod(float(b) * 0.34 + _t * 0.03, 1.0) * vis.size.x - 100.0
				draw_rect(Rect2(Vector2(bx, by), Vector2(200.0, 16.0)), Color(0.28, 0.88, 0.98, 0.055 + 0.02 * sin(_t + float(b))))
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + sin(_t * 1.2 + ph) * 0.03, 1.0)
				var v := fposmod(float(m.v) - _t * 0.13 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var r: float = 2.4 * float(m.sz)
				draw_circle(p, r, Color(0.26, 0.88, 1.0, 0.12))
				draw_arc(p, r, 0.0, TAU, 16, Color(0.48, 0.96, 1.0, 0.48), 1.0)
				draw_circle(p + Vector2(-r * 0.35, -r * 0.35), maxf(0.8, r * 0.28), Color(0.90, 1.0, 1.0, 0.55))
		"thunder_peak":
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) - _t * 0.36 * spd, 1.0)
				var v := fposmod(float(m.v) + _t * 0.85 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var len_v := Vector2(-8.0, 16.0) * float(m.sz)
				draw_line(p, p + len_v, Color(tint.r, tint.g, tint.b, 0.28), 1.0)
				var spark_pulse := sin(_t * 14.0 + ph)
				if spark_pulse > 0.72:
					var sp := vis.position + Vector2(fposmod(float(m.u) + _t * 0.05, 1.0) * vis.size.x, fposmod(float(m.v) + _t * 0.03, 1.0) * vis.size.y)
					draw_line(sp - Vector2(3.0, 1.5), sp + Vector2(1.0, -0.5), Color(0.65, 0.94, 1.0, 0.75), 1.2)
					draw_line(sp + Vector2(1.0, -0.5), sp + Vector2(3.5, 2.5), Color(1.0, 0.98, 0.72, 0.80), 1.2)
		"cosmic_embers":
			for b in 2:
				var by := vis.position.y + vis.size.y * (0.28 + float(b) * 0.42) + cos(_t * 0.45 + float(b)) * 10.0
				draw_rect(Rect2(Vector2(vis.position.x, by), Vector2(vis.size.x, 16.0)), Color(0.62, 0.34, 0.88, 0.045))
			for idx in _motes.size():
				var m: Dictionary = _motes[idx]
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + sin(_t * 0.85 + ph) * 0.035 + _t * 0.015 * spd, 1.0)
				var v := fposmod(float(m.v) - _t * 0.13 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var flicker := 0.48 + 0.48 * sin(_t * 5.8 + ph)
				var sz: float = 1.6 * float(m.sz)
				var is_gold: bool = (idx % 2 == 0)
				var c_outer := Color(1.0, 0.78, 0.24, 0.16 * flicker) if is_gold else Color(0.76, 0.42, 1.0, 0.16 * flicker)
				var c_core := Color(1.0, 0.94, 0.56, 0.65 * flicker) if is_gold else Color(0.92, 0.72, 1.0, 0.62 * flicker)
				draw_circle(p, sz * 2.1, c_outer)
				draw_circle(p, sz * 0.8, c_core)
		_:
			# "petals"
			for m in _motes:
				var spd: float = float(m.spd)
				var ph: float = float(m.phase)
				var u := fposmod(float(m.u) + _t * 0.05 * spd + sin(_t * 0.9 + ph) * 0.02, 1.0)
				var v := fposmod(float(m.v) + _t * 0.09 * spd, 1.0)
				var p := vis.position + Vector2(u * vis.size.x, v * vis.size.y)
				var ang := _t * 1.4 + ph
				var dir := Vector2(cos(ang), sin(ang)) * (2.4 * float(m.sz))
				draw_circle(p, 1.5 * float(m.sz), Color(tint.r, tint.g, tint.b, 0.38))
				draw_circle(p + dir * 0.45, 1.0 * float(m.sz), Color(1.0, 0.94, 0.96, 0.30))
