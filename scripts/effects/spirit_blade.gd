extends Node2D
## Phi kiếm (Phúc lành Ngự kiếm phi hành): bay quanh người chơi và tự phóng đâm giặc mỗi 1,1s.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const ORBIT_RADIUS := 19.0
const DETECT_RANGE := 165.0
const FIRE_CD := 1.1
const BASE_DMG := 5

var player: Node = null
var _spr: Sprite2D = null
var _angle: float = 0.0
var _cd: float = 0.4
var _state: String = "orbit"  # orbit, strike, return
var _strike_pos: Vector2 = Vector2.ZERO
var _target: Node = null
var _strike_t: float = 0.0


func _ready() -> void:
	z_index = 4
	_spr = Sprite2D.new()
	_spr.texture = Art.tex("weapons/thuan_thien.png")
	_spr.scale = Vector2(0.7, 0.7)
	_spr.modulate = Color(0.55, 1.0, 0.85)
	_spr.material = Art.additive()
	add_child(_spr)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	var dead_or_down: bool = bool(player.get("dead")) or bool(player.get("downed"))
	visible = not dead_or_down
	if dead_or_down:
		_state = "orbit"
		return

	_angle += delta * 3.6
	var orbit_local: Vector2 = Vector2.from_angle(_angle) * ORBIT_RADIUS

	match _state:
		"orbit":
			_spr.position = orbit_local
			_spr.rotation = _angle + PI * 0.5
			if not bool(player.get("is_local")):
				return
			_cd -= delta
			if _cd <= 0.0:
				var tgt: Node = _find_target()
				if tgt != null:
					_target = tgt
					_strike_pos = player.to_local((tgt as Node2D).global_position)
					_state = "strike"
					_strike_t = 0.0
		"strike":
			_strike_t += delta
			var dest: Vector2 = _strike_pos
			if _target != null and is_instance_valid(_target) and not bool(_target.get("dead")):
				dest = player.to_local((_target as Node2D).global_position)
				_strike_pos = dest
			var dvec: Vector2 = dest - _spr.position
			var dist: float = dvec.length()
			if dist > 6.0 and _strike_t < 0.35:
				var step: float = minf(dist, 420.0 * delta)
				_spr.position += dvec.normalized() * step
				_spr.rotation = dvec.angle()
			else:
				_hit_target(dest)
				_state = "return"
				_strike_t = 0.0
		"return":
			_strike_t += delta
			var rvec: Vector2 = orbit_local - _spr.position
			var rdist: float = rvec.length()
			if rdist <= 6.0 or _strike_t >= 0.35:
				_spr.position = orbit_local
				_state = "orbit"
				_cd = FIRE_CD
			else:
				_spr.position += rvec.normalized() * minf(rdist, 360.0 * delta)
				_spr.rotation = rvec.angle()


func _find_target() -> Node:
	var best: Node = null
	var best_d: float = DETECT_RANGE
	var ppos: Vector2 = (player as Node2D).global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or e.is_spawning():
			continue
		var d: float = ppos.distance_to((e as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _hit_target(local_dest: Vector2) -> void:
	var par: Node = player.get_parent()
	var world_pos: Vector2 = player.to_global(local_dest)
	if par != null:
		Fx.anim(par, world_pos, "fx/spark.png", 15, 15, 24.0, 0.85, 0.0, Color(0.55, 1.0, 0.85), true)
	if _target != null and is_instance_valid(_target) and not bool(_target.get("dead")):
		var kdir: Vector2 = (world_pos - (player as Node2D).global_position).normalized()
		_target.take_damage(BASE_DMG, kdir * 80.0)
		if player.has_method("on_hit_enemy"):
			player.on_hit_enemy(_target)
	_target = null
