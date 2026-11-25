extends Node2D
## Các thứ làm doanh trại sống động: thảm đỏ, ao cá koi + chuồn chuồn, lính tuần tra,
## gà trống, gà con, cún vàng, mèo tam thể, hạc trắng.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var kind := "carpet"
var size := Vector2(100, 30)      # thảm / ao: kích thước
var a := Vector2.ZERO             # lính tuần: điểm đầu
var b := Vector2.ZERO             # lính tuần: điểm cuối
var _t := 0.0
var _spr: AnimatedSprite2D
var _kois: Array = []
var _dragonflies: Array = []
var _dir := 1.0
var _target := Vector2.ZERO
var _wait := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
	_t = randf() * 10.0
	match kind:
		"carpet":
			z_index = 0
		"pond":
			z_index = 0
			_build_pond()
		"patrol":
			z_index = 1
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.strip("fx/ally.png", 18, 20, 8.0, true)
			_spr.play("play")
			_spr.position = Vector2(0, -6)
			add_child(_spr)
			var sh := Sprite2D.new()
			sh.texture = Art.tex("fx/shadow.png")
			sh.position = Vector2(0, 4)
			sh.z_index = -1
			add_child(sh)
			position = a
		"chicken", "chick":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_chick.png", 16, 15, {
				"walk": [[0, 1], 6.0, true],
				"hop": [[2, 0], 5.0, true],
				"peck": [[3, 0], 4.0, true],
			})
			_spr.position = Vector2(0, -5)
			_spr.play("walk")
			add_child(_spr)
		"rooster":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_rooster.png", 24, 24, {
				"walk": [[0, 1], 6.0, true],
				"strut": [[2, 0], 3.0, true],
				"peck": [[3, 0], 4.0, true],
			})
			_spr.position = Vector2(0, -9)
			_spr.play("strut")
			add_child(_spr)
		"dog":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_dog.png", 26, 22, {
				"walk": [[0, 1], 7.0, true],
				"sit": [[2, 3], 4.0, true],
			})
			_spr.position = Vector2(0, -8)
			_spr.play("sit")
			add_child(_spr)
		"cat":
			z_index = 1
			_home = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_cat.png", 24, 20, {
				"idle": [[0, 0, 1, 0, 2], 3.0, true],
				"nap": [[3], 1.0, false],
			})
			_spr.position = Vector2(0, -7)
			_spr.play("idle" if randf() < 0.6 else "nap")
			_wait = randf_range(3.0, 6.0)
			add_child(_spr)
		"crane":
			z_index = 1
			_home = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_crane.png", 26, 34, {
				"idle": [[0, 0, 1, 0, 2, 0, 3], 2.5, true],
			})
			_spr.position = Vector2(0, -14)
			_spr.play("idle")
			add_child(_spr)


func _build_pond() -> void:
	for i in 8:
		var leaf := Sprite2D.new()
		leaf.texture = Art.tex("world/lotus_leaf.png")
		var ang := TAU * i / 8.0 + randf() * 0.4
		leaf.position = Vector2(cos(ang) * size.x * 0.34, sin(ang) * size.y * 0.32)
		leaf.flip_h = randf() < 0.5
		add_child(leaf)
		if i % 2 == 0:
			var fl := Sprite2D.new()
			fl.texture = Art.tex("world/lotus.png")
			fl.position = leaf.position + Vector2(0, -4)
			add_child(fl)
	var koi_sheets := [
		"world/animal_koi_red.png",
		"world/animal_koi_calico.png",
		"world/animal_koi_gold.png",
		"world/animal_koi_red.png",
	]
	for i in koi_sheets.size():
		var k := AnimatedSprite2D.new()
		k.sprite_frames = Art.strip(koi_sheets[i], 22, 12, 6.0, true)
		k.play("play")
		k.frame = i % 4
		add_child(k)
		_kois.append(k)
	for i in 2:
		var df := AnimatedSprite2D.new()
		df.sprite_frames = Art.strip("world/animal_dragonfly.png", 14, 12, 16.0, true)
		df.play("play")
		df.z_index = 4
		add_child(df)
		_dragonflies.append(df)
	var ff := CPUParticles2D.new()
	ff.amount = 12
	ff.lifetime = 3.0
	ff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ff.emission_rect_extents = size * 0.52
	ff.direction = Vector2.UP
	ff.spread = 180.0
	ff.gravity = Vector2.ZERO
	ff.initial_velocity_min = 4.0
	ff.initial_velocity_max = 10.0
	ff.scale_amount_min = 1.5
	ff.scale_amount_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 1.0, 0.4, 0.0))
	g.add_point(0.5, Color(0.9, 1.0, 0.5, 1.0))
	g.set_color(g.get_point_count() - 1, Color(0.8, 1.0, 0.4, 0.0))
	ff.color_ramp = g
	ff.material = Art.additive()
	ff.z_index = 5
	add_child(ff)


func _wander_animal(delta: float, walk_speed: float, range_xy: Vector2, idle_anims: Array) -> void:
	_wait -= delta
	var to := _target - position
	if to.length() > 2.0:
		position += to.normalized() * walk_speed * delta
		_spr.flip_h = to.x < 0.0
		_spr.play("walk")
		_spr.position.y = (-5.0 if kind in ["chicken", "chick"] else -8.0) - absf(sin(_t * 14.0)) * 1.5
	else:
		_spr.position.y = -5.0 if kind in ["chicken", "chick"] else (-9.0 if kind == "rooster" else -8.0)
		if _wait <= 0.0:
			if randf() < 0.55:
				_spr.play(str(idle_anims[randi() % idle_anims.size()]))
				_wait = randf_range(1.4, 3.0)
			else:
				_target = _home + Vector2(randf_range(-range_xy.x, range_xy.x), randf_range(-range_xy.y, range_xy.y))
				_wait = randf_range(0.6, 1.6)


func _process(delta: float) -> void:
	_t += delta
	match kind:
		"pond":
			for i in _kois.size():
				var k: AnimatedSprite2D = _kois[i]
				var sp := 0.42 + i * 0.18
				var sgn := 1.0 if i % 2 == 0 else -1.0
				var ang := _t * sp * sgn + i * 1.6
				var p := Vector2(cos(ang) * size.x * 0.3, sin(ang * 1.3) * size.y * 0.24)
				var vel := Vector2(-sin(ang) * sp * sgn * size.x * 0.3, cos(ang * 1.3) * 1.3 * sp * sgn * size.y * 0.24)
				k.flip_h = vel.x < 0.0
				k.rotation = clampf(vel.y / maxf(8.0, absf(vel.x)), -0.35, 0.35) * (-1.0 if k.flip_h else 1.0)
				k.position = p
			for i in _dragonflies.size():
				var df: AnimatedSprite2D = _dragonflies[i]
				var s := i * 3.1 + 1.0
				var dp := Vector2(sin(_t * 1.4 + s) * size.x * 0.35, -6.0 + cos(_t * 2.1 + s) * size.y * 0.26)
				df.flip_h = cos(_t * 1.4 + s) < 0.0
				df.position = dp
			queue_redraw()
		"patrol":
			var target := b if _dir > 0.0 else a
			var to := target - position
			if _wait > 0.0:
				_wait -= delta
				_spr.speed_scale = 0.0
			elif to.length() < 2.0:
				_dir = -_dir
				_wait = 1.5
			else:
				position += to.normalized() * 30.0 * delta
				_spr.flip_h = to.x < 0.0
				_spr.speed_scale = 1.0
		"chicken", "chick":
			_wander_animal(delta, 24.0, Vector2(36, 22), ["peck", "hop"])
		"rooster":
			_wander_animal(delta, 28.0, Vector2(46, 24), ["strut", "peck"])
		"dog":
			_wander_animal(delta, 36.0, Vector2(52, 26), ["sit"])
		"cat":
			_wait -= delta
			if _wait <= 0.0:
				_spr.play("nap" if randf() < 0.45 else "idle")
				_wait = randf_range(3.5, 7.0)


func _draw() -> void:
	match kind:
		"carpet":
			var r := Rect2(-size / 2.0, size)
			draw_rect(r, Color(0.55, 0.12, 0.14))
			draw_rect(r.grow(-2), Color(0.68, 0.16, 0.18))
			draw_rect(r.grow(-2), Color(0.9, 0.7, 0.3), false, 1.0)
			draw_rect(r.grow(-5), Color(0.9, 0.7, 0.3, 0.6), false, 1.0)
			var step := 18.0
			var x := r.position.x + 12.0
			while x < r.end.x - 8.0:
				var c := Vector2(x, 0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4), c + Vector2(-4, 0)]), Color(0.9, 0.7, 0.3, 0.55))
				x += step
		"pond":
			var pts := PackedVector2Array()
			for i in 32:
				var ang := TAU * i / 32.0
				pts.append(Vector2(cos(ang) * (size.x / 2.0 + 3), sin(ang) * (size.y / 2.0 + 3)))
			draw_colored_polygon(pts, Color(0.45, 0.42, 0.38))
			var pts2 := PackedVector2Array()
			for i in 32:
				var ang := TAU * i / 32.0
				pts2.append(Vector2(cos(ang) * size.x / 2.0, sin(ang) * size.y / 2.0))
			draw_colored_polygon(pts2, Color(0.16, 0.36, 0.5))
			for k in 3:
				var rr := fmod(_t * 6.0 + k * 9.0, 26.0)
				var ctr := Vector2(sin(k * 2.1) * size.x * 0.2, cos(k * 1.7) * size.y * 0.15)
				draw_arc(ctr, rr, 0.0, TAU, 20, Color(0.6, 0.85, 1.0, 0.35 * (1.0 - rr / 26.0)), 1.0)
			# viền đá cuội
			for i in 16:
				var ang := TAU * i / 16.0
				draw_circle(Vector2(cos(ang) * (size.x / 2.0 + 2), sin(ang) * (size.y / 2.0 + 2)), 2.5, Color(0.6, 0.58, 0.52))
