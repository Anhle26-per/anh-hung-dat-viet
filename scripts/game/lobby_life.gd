extends Node2D
## Các thứ làm doanh trại sống động: thảm đỏ, ao cá koi + chuồn chuồn, lính tuần tra,
## gà trống, gà con, cún vàng, mèo tam thể, hạc trắng, và 5 NPC doanh trại hoạt ảnh.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const NPC_KINDS := [
	"npc_blacksmith",
	"npc_tea_lady",
	"npc_strategist",
	"npc_scholar",
	"npc_guard",
]

var kind := "carpet"
var size := Vector2(100, 30)      # thảm / ao: kích thước
var a := Vector2.ZERO             # lính tuần: điểm đầu
var b := Vector2.ZERO             # lính tuần: điểm cuối
var _t := 0.0
var _spr: AnimatedSprite2D
var _shadow: Sprite2D
var _amb_pt: CPUParticles2D
var _base_spr_y := 0.0
var _resting_hidden: bool = false
var _kois: Array = []
var _dragonflies: Array = []
var _dir := 1.0
var _target := Vector2.ZERO
var _wait := 0.0
var _home := Vector2.ZERO
var _feed_t := 0.0
var _feed_pos := Vector2(0, -24)
var _happy_t := 0.0
var _look_t := 0.0
var _step_dust_t := 0.0
var _npc_fx_t := 0.0


func set_resting_hidden(hidden: bool) -> void:
	_resting_hidden = hidden
	visible = not hidden
	if _amb_pt != null and is_instance_valid(_amb_pt):
		_amb_pt.emitting = not hidden
	set_process(not hidden)


func trigger_koi_feed() -> void:
	_feed_t = 5.5
	if get_parent() != null:
		var wp: Vector2 = global_position + _feed_pos
		Fx.burst(get_parent(), wp, Color(0.55, 0.92, 1.0), 26.0, 0.45)
		Fx.particles(get_parent(), wp, Color(0.75, 0.96, 1.0), 14, 52.0, 0.55, 45.0, 1.8)
		Fx.particles(get_parent(), wp, Color(1.0, 0.88, 0.42), 8, 36.0, 0.5, 25.0, 1.5)


func trigger_happy(dur: float = 2.8) -> void:
	_happy_t = maxf(_happy_t, dur)
	if get_parent() != null:
		var wp: Vector2 = global_position + Vector2(0, -10)
		Fx.burst(get_parent(), wp, Color(1.0, 0.55, 0.78), 26.0, 0.45)
		Fx.particles(get_parent(), wp, Color(1.0, 0.65, 0.84), 12, 60.0, 0.65, -24.0, 1.8)
		Fx.particles(get_parent(), wp, Color(1.0, 0.9, 0.45), 8, 48.0, 0.55, -28.0, 1.5)


func _add_shadow(pos: Vector2, sc := Vector2.ONE) -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = Art.tex("fx/shadow.png")
	_shadow.position = pos
	_shadow.scale = sc
	_shadow.z_index = -1
	add_child(_shadow)


func _add_npc_particles(pos: Vector2, col: Color, col_end: Color, amount: int, life: float, spd: float, grav_y: float) -> void:
	var pt := CPUParticles2D.new()
	pt.position = pos
	pt.amount = amount
	pt.lifetime = life
	pt.direction = Vector2.UP
	pt.spread = 32.0
	pt.gravity = Vector2(0.0, grav_y)
	pt.initial_velocity_min = spd * 0.5
	pt.initial_velocity_max = spd
	pt.scale_amount_min = 1.0
	pt.scale_amount_max = 1.8
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, col_end)
	pt.color_ramp = g
	pt.material = Art.additive()
	pt.z_index = 3
	pt.emitting = not _resting_hidden
	add_child(pt)
	_amb_pt = pt


func _ready() -> void:
	_t = randf() * 10.0
	_look_t = randf_range(2.0, 5.0)
	match kind:
		"carpet":
			z_index = 0
		"pond":
			z_index = 0
			_build_pond()
		"patrol":
			z_index = 1
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("fx/ally.png", 18, 20, {
				"walk": [[0, 1, 2, 3], 9.0, true],
				"idle": [[4, 4, 5, 4], 4.0, true],
			})
			_spr.play("walk")
			_base_spr_y = -6.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(0, 4))
			position = a
		"chicken", "chick":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_chick.png", 16, 15, {
				"walk": [[0, 1], 6.5, true],
				"hop": [[2, 0], 5.5, true],
				"peck": [[3, 0], 4.5, true],
			})
			_base_spr_y = -5.0
			_spr.position = Vector2(0, _base_spr_y)
			_spr.play("walk")
			add_child(_spr)
			_add_shadow(Vector2(0, 2), Vector2(0.75, 0.75))
		"rooster":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_rooster.png", 24, 24, {
				"walk": [[0, 1], 6.5, true],
				"strut": [[2, 0], 3.5, true],
				"peck": [[3, 0], 4.5, true],
			})
			_base_spr_y = -9.0
			_spr.position = Vector2(0, _base_spr_y)
			_spr.play("strut")
			add_child(_spr)
			_add_shadow(Vector2(0, 2), Vector2(0.95, 0.85))
		"dog":
			z_index = 1
			_home = position
			_target = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_dog.png", 26, 22, {
				"walk": [[0, 1], 7.5, true],
				"sit": [[2, 3], 4.5, true],
			})
			_base_spr_y = -8.0
			_spr.position = Vector2(0, _base_spr_y)
			_spr.play("sit")
			add_child(_spr)
			_add_shadow(Vector2(0, 2), Vector2(1.0, 0.9))
		"cat":
			z_index = 1
			_home = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_cat.png", 24, 20, {
				"idle": [[0, 0, 1, 0, 2], 3.5, true],
				"nap": [[3], 1.0, false],
			})
			_base_spr_y = -7.0
			_spr.position = Vector2(0, _base_spr_y)
			_spr.play("idle" if randf() < 0.6 else "nap")
			_wait = randf_range(3.0, 6.0)
			add_child(_spr)
			_add_shadow(Vector2(0, 2), Vector2(0.9, 0.85))
		"crane":
			z_index = 1
			_home = position
			_spr = AnimatedSprite2D.new()
			_spr.sprite_frames = Art.frames("world/animal_crane.png", 26, 34, {
				"idle": [[0, 0, 1, 0, 2, 0, 3], 2.8, true],
			})
			_base_spr_y = -14.0
			_spr.position = Vector2(0, _base_spr_y)
			_spr.play("idle")
			add_child(_spr)
			_add_shadow(Vector2(0, 2), Vector2(0.95, 0.85))
		"npc_blacksmith":
			z_index = 1
			_spr = _make_npc_anim("world/npc_blacksmith.png", 28, 30)
			_base_spr_y = -12.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(2, 3), Vector2(1.2, 0.95))
			_add_npc_particles(Vector2(8, -10), Color(1.0, 0.86, 0.35, 0.95), Color(1.0, 0.35, 0.1, 0.0), 8, 0.9, 18.0, -24.0)
			var gl := Art.light(Color(1.0, 0.58, 0.24), 0.75, 0.55)
			gl.position = Vector2(6, -10)
			add_child(gl)
		"npc_tea_lady":
			z_index = 1
			_spr = _make_npc_anim("world/npc_tea_lady.png", 24, 30)
			_base_spr_y = -12.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(2, 3), Vector2(1.05, 0.9))
			_add_npc_particles(Vector2(6, -15), Color(0.95, 0.98, 1.0, 0.6), Color(0.95, 0.98, 1.0, 0.0), 6, 1.4, 8.0, -10.0)
		"npc_strategist":
			z_index = 1
			_spr = _make_npc_anim("world/npc_strategist.png", 24, 30)
			_base_spr_y = -12.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(2, 3), Vector2(1.05, 0.9))
			_add_npc_particles(Vector2(0, -16), Color(0.55, 0.9, 1.0, 0.75), Color(0.95, 0.85, 0.45, 0.0), 6, 1.5, 10.0, -12.0)
		"npc_scholar":
			z_index = 1
			_spr = _make_npc_anim("world/npc_scholar.png", 24, 30)
			_base_spr_y = -12.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(2, 3), Vector2(1.05, 0.9))
			_add_npc_particles(Vector2(5, -14), Color(1.0, 0.9, 0.45, 0.8), Color(1.0, 0.85, 0.3, 0.0), 6, 1.6, 8.0, -10.0)
		"npc_guard":
			z_index = 1
			_spr = _make_npc_anim("world/npc_guard.png", 24, 30)
			_base_spr_y = -12.0
			_spr.position = Vector2(0, _base_spr_y)
			add_child(_spr)
			_add_shadow(Vector2(2, 3), Vector2(1.1, 0.92))
			_add_npc_particles(Vector2(5, -22), Color(1.0, 0.92, 0.55, 0.65), Color(1.0, 0.55, 0.25, 0.0), 4, 1.2, 8.0, -8.0)
	if _resting_hidden:
		set_resting_hidden(true)


func _make_npc_anim(rel: String, fw: int, fh: int) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	var tex: Texture2D = Art.tex(rel)
	if tex != null and tex.get_width() >= fw * 8:
		a.sprite_frames = Art.frames(rel, fw, fh, {
			"idle": [[0, 1, 2, 3], 4.4, true],
			"action": [[4, 5, 6, 7], 7.8, true],
		})
		a.play("idle")
	else:
		a.sprite_frames = Art.strip(rel, fw, fh, 4.5, true)
		a.play("play")
	return a


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
		_spr.position.y = _base_spr_y - absf(sin(_t * 14.0)) * 1.6
		_step_dust_t -= delta
		if _step_dust_t <= 0.0 and get_parent() != null:
			_step_dust_t = 0.36
			Fx.particles(get_parent(), global_position + Vector2(0, 2), Color(0.86, 0.8, 0.68, 0.55), 2, 16.0, 0.25, -4.0, 1.2)
	else:
		var breath_bob := sin(_t * 3.2) * 0.6
		_spr.position.y = _base_spr_y + breath_bob
		_look_t -= delta
		if _look_t <= 0.0:
			_look_t = randf_range(2.2, 4.8)
			if randf() < 0.5:
				_spr.flip_h = not _spr.flip_h
		if _wait <= 0.0:
			if randf() < 0.55:
				_spr.play(str(idle_anims[randi() % idle_anims.size()]))
				_wait = randf_range(1.4, 3.0)
			else:
				_target = _home + Vector2(randf_range(-range_xy.x, range_xy.x), randf_range(-range_xy.y, range_xy.y))
				_wait = randf_range(0.6, 1.6)


func _process(delta: float) -> void:
	if _resting_hidden:
		return
	_t += delta
	match kind:
		"pond":
			if _feed_t > 0.0:
				_feed_t = maxf(0.0, _feed_t - delta)
			for i in _kois.size():
				var k: AnimatedSprite2D = _kois[i]
				var sp := (1.35 if _feed_t > 0.0 else 0.42) + i * 0.18
				var sgn := 1.0 if i % 2 == 0 else -1.0
				var ang := _t * sp * sgn + i * 1.6
				var p: Vector2
				var vel: Vector2
				if _feed_t > 0.0:
					var rad: float = 12.0 + float(i) * 4.5
					p = _feed_pos + Vector2(cos(ang) * rad, sin(ang * 1.2) * rad * 0.65)
					vel = Vector2(-sin(ang) * sp * sgn * rad, cos(ang * 1.2) * 1.2 * sp * sgn * rad * 0.65)
				else:
					p = Vector2(cos(ang) * size.x * 0.3, sin(ang * 1.3) * size.y * 0.24)
					vel = Vector2(-sin(ang) * sp * sgn * size.x * 0.3, cos(ang * 1.3) * 1.3 * sp * sgn * size.y * 0.24)
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
			if _spr == null:
				return
			var target := b if _dir > 0.0 else a
			var to := target - position
			if _wait > 0.0:
				_wait -= delta
				_spr.play("idle")
				_spr.position.y = _base_spr_y + sin(_t * 3.5) * 0.5
			elif to.length() < 2.0:
				_dir = -_dir
				_wait = 1.6
			else:
				position += to.normalized() * 30.0 * delta
				_spr.flip_h = to.x < 0.0
				_spr.play("walk")
				_spr.position.y = _base_spr_y - absf(sin(_t * 12.0)) * 1.0
				_step_dust_t -= delta
				if _step_dust_t <= 0.0 and get_parent() != null:
					_step_dust_t = 0.42
					Fx.particles(get_parent(), global_position + Vector2(0, 3), Color(0.84, 0.78, 0.66, 0.5), 2, 14.0, 0.24, -4.0, 1.2)
		"chicken", "chick":
			if _spr == null:
				return
			_wander_animal(delta, 24.0, Vector2(36, 22), ["peck", "hop"])
		"rooster":
			if _spr == null:
				return
			_wander_animal(delta, 28.0, Vector2(46, 24), ["strut", "peck"])
		"dog":
			if _spr == null:
				return
			_wander_animal(delta, 36.0, Vector2(52, 26), ["sit"])
		"cat":
			if _spr == null:
				return
			_wait -= delta
			_spr.position.y = _base_spr_y + sin(_t * 2.8) * 0.5
			if _wait <= 0.0:
				_spr.play("nap" if randf() < 0.45 else "idle")
				_wait = randf_range(3.5, 7.0)
				if _spr.animation == "idle" and randf() < 0.5:
					_spr.flip_h = not _spr.flip_h
		"crane":
			if _spr == null:
				return
			_spr.position.y = _base_spr_y + sin(_t * 2.2) * 0.7
			_look_t -= delta
			if _look_t <= 0.0:
				_look_t = randf_range(3.0, 6.0)
				_spr.flip_h = not _spr.flip_h
		"npc_blacksmith", "npc_tea_lady", "npc_strategist", "npc_scholar", "npc_guard":
			if _spr == null:
				return
			var breath := sin(_t * 3.4) * 0.03
			_spr.position.y = _base_spr_y + sin(_t * 3.4) * 0.7
			_spr.scale = Vector2(1.0 - breath * 0.5, 1.0 + breath)
			var np: Node = Global.nearest_player(global_position) if Global != null else null
			var p_near: bool = np != null and is_instance_valid(np) and global_position.distance_to((np as Node2D).global_position) < 76.0
			if p_near:
				_spr.flip_h = (np as Node2D).global_position.x < global_position.x
			var has_act: bool = _spr.sprite_frames != null and _spr.sprite_frames.has_animation("action")
			var acting: bool = p_near or fmod(_t, 4.6) < 2.2
			if has_act:
				_spr.play("action" if acting else "idle")
			if kind == "npc_blacksmith":
				_npc_fx_t -= delta
				if _npc_fx_t <= 0.0 and get_parent() != null and (not has_act or (_spr.animation == "action" and _spr.frame == 2)):
					_npc_fx_t = 0.52
					Fx.particles(get_parent(), global_position + Vector2(8, -10), Color(1.0, 0.85, 0.3), 5, 42.0, 0.32, 65.0, 1.4, 100.0, Vector2.UP, Color(1.0, 0.35, 0.1))
			elif kind == "npc_guard" and not p_near:
				_look_t -= delta
				if _look_t <= 0.0:
					_look_t = randf_range(3.5, 6.5)
					_spr.flip_h = not _spr.flip_h
	if _happy_t > 0.0:
		_happy_t = maxf(0.0, _happy_t - delta)
		if _spr != null:
			var jump: float = absf(sin(_t * 14.0)) * 5.0
			_spr.position.y = _base_spr_y - jump
			var sq: float = 0.08 * sin(_t * 16.0)
			_spr.scale = Vector2(1.0 + sq, 1.0 - sq * 0.8)
		queue_redraw()
	elif _spr != null and not (kind in NPC_KINDS):
		var idle_sq := sin(_t * 3.2) * 0.028
		_spr.scale = Vector2(1.0 - idle_sq * 0.6, 1.0 + idle_sq)
	if _shadow != null and is_instance_valid(_shadow):
		var sh_p := 1.0 + sin(_t * 3.2) * 0.05
		_shadow.scale = Vector2(sh_p, sh_p * 0.9)


func _draw_heart(pos: Vector2, sz: float, col: Color) -> void:
	var r: float = sz * 0.36
	var edge := Color(0.55, 0.08, 0.25, col.a)
	draw_circle(pos + Vector2(-r * 0.85, -r * 0.2), r + 1.0, edge)
	draw_circle(pos + Vector2(r * 0.85, -r * 0.2), r + 1.0, edge)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-r * 1.85, -0.4),
		pos + Vector2(r * 1.85, -0.4),
		pos + Vector2(0.0, sz * 1.08),
	]), edge)
	draw_circle(pos + Vector2(-r * 0.85, -r * 0.2), r, col)
	draw_circle(pos + Vector2(r * 0.85, -r * 0.2), r, col)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-r * 1.72, 0.0),
		pos + Vector2(r * 1.72, 0.0),
		pos + Vector2(0.0, sz * 0.95),
	]), col)
	draw_circle(pos + Vector2(-r * 0.85, -r * 0.35), r * 0.35, Color(1.0, 0.92, 0.96, col.a))


func _draw() -> void:
	if _happy_t > 0.0 and kind in ["chicken", "chick", "rooster", "dog", "cat", "crane"]:
		var fade: float = clampf(_happy_t * 1.4, 0.0, 1.0)
		for hi in 3:
			var phase: float = fmod((2.8 - _happy_t) * 1.1 + float(hi) * 0.33, 1.0)
			var hx: float = sin((_t * 3.0) + float(hi) * 2.1) * 10.0 + float(hi - 1) * 8.0
			var hy: float = -22.0 - phase * 24.0
			var ha: float = fade * sin(phase * PI)
			_draw_heart(Vector2(hx, hy), 6.2, Color(1.0, 0.44, 0.68, maxf(0.45, ha)))
		for si in 2:
			var sp_p: Vector2 = Vector2(cos(_t * 4.0 + float(si) * PI) * 15.0, -18.0 - float(si) * 10.0)
			draw_circle(sp_p, 2.0, Color(1.0, 0.92, 0.42, 0.9 * fade))
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
				var ctr := _feed_pos if _feed_t > 0.0 else Vector2(sin(k * 2.1) * size.x * 0.2, cos(k * 1.7) * size.y * 0.15)
				draw_arc(ctr, rr, 0.0, TAU, 20, Color(0.6, 0.85, 1.0, 0.35 * (1.0 - rr / 26.0)), 1.0)
			if _feed_t > 0.0:
				for crumb in 5:
					var ang_c := float(crumb) * 1.25 + _t * 1.5
					draw_circle(_feed_pos + Vector2(cos(ang_c) * 6.0, sin(ang_c) * 4.0), 1.4, Color(1.0, 0.88, 0.45, 0.9))
			# viền đá cuội
			for i in 16:
				var ang := TAU * i / 16.0
				draw_circle(Vector2(cos(ang) * (size.x / 2.0 + 2), sin(ang) * (size.y / 2.0 + 2)), 2.5, Color(0.6, 0.58, 0.52))
