extends Node2D
## Bẫy ngẫu nhiên trong phòng hầm ngục: Bẫy Chông ("spike"), Lỗ Phun Lửa ("fire_vent"), Hố Chướng Khí ("poison_vent").
## Chỉ kích hoạt theo chu kỳ khi phòng đang giao tranh (room.state == "fighting").

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var kind: String = "spike"
var room = null
var phase_offset: float = 0.0

var _t: float = 0.0
var _phase: int = 0          # 0 = nghỉ, 1 = cảnh báo, 2 = kích hoạt
var _player_cd: Dictionary = {}
var _enemy_cd: float = 0.0


func _ready() -> void:
	add_to_group("traps")
	z_index = 0
	_t = phase_offset


func is_active() -> bool:
	return _phase == 2


func _process(delta: float) -> void:
	var fighting: bool = (room != null and is_instance_valid(room) and str(room.get("state")) == "fighting")
	if not fighting:
		_phase = 0
		_player_cd.clear()
		_enemy_cd = 0.0
		queue_redraw()
		return

	_t += delta
	_enemy_cd = maxf(0.0, _enemy_cd - delta)
	for pk in _player_cd.keys():
		var left: float = float(_player_cd[pk]) - delta
		if left <= 0.0:
			_player_cd.erase(pk)
		else:
			_player_cd[pk] = left

	var cyc: float = fmod(_t, 3.8)
	var prev_phase: int = _phase
	if cyc < 1.95:
		_phase = 0
	elif cyc < 2.60:
		_phase = 1
	else:
		_phase = 2

	if _phase == 2:
		if prev_phase != 2:
			_on_activate_fx()
		_apply_damage()
	queue_redraw()


func _on_activate_fx() -> void:
	var par: Node = get_parent()
	if par == null:
		return
	match kind:
		"fire_vent":
			Fx.particles(par, global_position, Color(1.0, 0.48, 0.16), 8, 55.0, 0.45, -35.0, 1.8)
		"poison_vent":
			Fx.particles(par, global_position, Color(0.55, 0.92, 0.35), 8, 45.0, 0.55, -20.0, 1.8)
		_:
			Fx.particles(par, global_position, Color(0.84, 0.88, 0.96), 5, 36.0, 0.28, 30.0, 1.4)


func _trap_name() -> String:
	match kind:
		"fire_vent":
			return "Lỗ Phun Lửa"
		"poison_vent":
			return "Hố Chướng Khí"
	return "Bẫy Chông"


func _hit_radius() -> float:
	match kind:
		"fire_vent":
			return 18.0
		"poison_vent":
			return 22.0
	return 16.0


func _apply_damage() -> void:
	var rad: float = _hit_radius()
	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")) or bool(pl.get("downed")):
			continue
		var p2: Node2D = pl as Node2D
		if p2 == null or p2.global_position.distance_to(global_position) > rad:
			continue
		var pid: int = pl.get_instance_id()
		if _player_cd.has(pid):
			continue
		_player_cd[pid] = 0.85
		match kind:
			"fire_vent":
				if pl.has_method("buff") and pl.buff("khien_lua") > 0:
					continue
				pl.take_damage(1, _trap_name())
				if pl.get("status") != null and pl.status.has_method("apply"):
					pl.status.apply("burn", 2.0)
			"poison_vent":
				if pl.has_method("buff") and pl.buff("khien_doc") > 0:
					continue
				if pl.get("status") != null and pl.status.has_method("apply"):
					pl.status.apply("poison", 2.5)
				else:
					pl.take_damage(1, _trap_name())
			_:
				pl.take_damage(1, _trap_name())

	if _enemy_cd <= 0.0 and (not Net.is_online() or Net.is_host()):
		var hit_any: bool = false
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or bool(e.get("dead")):
				continue
			if e.has_method("is_spawning") and e.is_spawning():
				continue
			var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else (e.global_position.distance_to(global_position) - float(e.get("radius")) * 0.5)
			if dist_e <= rad:
				hit_any = true
				match kind:
					"fire_vent":
						e.take_damage(5, Vector2.ZERO)
						if is_instance_valid(e) and e.has_method("apply_status"):
							e.apply_status("burn", 2.5)
					"poison_vent":
						e.take_damage(3, Vector2.ZERO)
						if is_instance_valid(e) and e.has_method("apply_status"):
							e.apply_status("poison", 3.0)
					_:
						e.take_damage(4, Vector2.ZERO)
		if hit_any:
			_enemy_cd = 0.70


func _draw() -> void:
	match kind:
		"fire_vent":
			draw_rect(Rect2(-12, -10, 24, 20), Color("36282a"))
			draw_rect(Rect2(-10, -8, 20, 16), Color("58403e"))
			draw_circle(Vector2.ZERO, 6.0, Color("201414"))
			if _phase == 1:
				var a: float = 0.45 + 0.35 * sin(_t * 28.0)
				draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, Color(1.0, 0.48, 0.16, a), 1.8)
				draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.65, 0.2, 0.8))
			elif _phase == 2:
				var r_pulse: float = 16.0 + sin(_t * 24.0) * 2.0
				draw_circle(Vector2.ZERO, r_pulse, Color(1.0, 0.42, 0.12, 0.55))
				draw_circle(Vector2(0, -3), 10.0, Color(1.0, 0.75, 0.22, 0.82))
				draw_circle(Vector2(0, -5), 5.0, Color(1.0, 0.96, 0.65, 0.95))
		"poison_vent":
			draw_circle(Vector2.ZERO, 12.0, Color("2c362e"))
			draw_circle(Vector2.ZERO, 9.0, Color("1a261e"))
			if _phase == 1:
				var a2: float = 0.45 + 0.35 * sin(_t * 28.0)
				draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 22, Color(0.55, 0.95, 0.35, a2), 1.8)
				draw_circle(Vector2(-3, -1), 2.5, Color(0.65, 1.0, 0.42, 0.85))
				draw_circle(Vector2(3, 2), 2.0, Color(0.65, 1.0, 0.42, 0.85))
			elif _phase == 2:
				var pr: float = 20.0 + sin(_t * 18.0) * 2.0
				draw_circle(Vector2.ZERO, pr, Color(0.42, 0.88, 0.32, 0.38))
				draw_circle(Vector2(-5, -3), 9.0, Color(0.58, 0.96, 0.42, 0.5))
				draw_circle(Vector2(6, 2), 8.0, Color(0.68, 0.44, 0.92, 0.4))
		_:
			# Bẫy chông sắt
			draw_rect(Rect2(-12, -10, 24, 20), Color("3c3944"))
			draw_rect(Rect2(-10, -8, 20, 16), Color("54505c"))
			var pts: Array[Vector2] = [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 4), Vector2(6, 4), Vector2(0, 0)]
			for sp in pts:
				draw_circle(sp, 2.2, Color("1c1a22"))
				if _phase == 1:
					draw_circle(sp, 1.5, Color(1.0, 0.4, 0.3, 0.9))
				elif _phase == 2:
					draw_polygon(PackedVector2Array([sp + Vector2(-2.5, 2), sp + Vector2(2.5, 2), sp + Vector2(0, -8)]), PackedColorArray([Color("8890a4"), Color("b4bcd0"), Color("f0f4ff")]))
			if _phase == 1:
				var a3: float = 0.5 + 0.4 * sin(_t * 30.0)
				draw_rect(Rect2(-13, -11, 26, 22), Color(1.0, 0.35, 0.28, a3), false, 1.5)
