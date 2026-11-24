extends Area2D
## Viên đạn / mũi tên / cầu lửa... Hình đạn chọn theo `proj`.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

# Hình đạn: ảnh, số khung, va chạm, cộng sáng, ánh sáng
const PROJ := {
	"arrow": {"tex": "fx/arrow.png", "r": 3.0},
	"stone": {"tex": "fx/stone.png", "r": 3.0},
	"dart": {"tex": "fx/dart.png", "r": 3.0},
	"bullet": {"tex": "fx/bullet.png", "r": 2.5, "add": true},
	"pellet": {"tex": "fx/pellet.png", "r": 2.0, "add": true},
	"cannonball": {"tex": "fx/cannonball.png", "r": 4.0},
	"fireball": {"tex": "fx/fireball.png", "n": 3, "r": 4.0, "add": true, "light": Color(1, 0.55, 0.2), "status": "burn"},
	"rocket": {"tex": "fx/rocket.png", "n": 2, "r": 3.5, "trail": true},
	"grenade": {"tex": "fx/grenade.png", "n": 4, "r": 4.0, "spin": true, "grenade": true},
	"plasma": {"tex": "fx/plasma.png", "n": 2, "r": 4.0, "add": true, "light": Color(0.7, 0.4, 1.0)},
	"orb_pink": {"tex": "fx/orb_pink.png", "n": 2, "r": 3.5, "add": true},
	"orb_poison": {"tex": "fx/orb_pink.png", "n": 2, "r": 3.5, "add": true, "tint": Color(0.45, 1.0, 0.35), "status": "poison"},
	"orb_water": {"tex": "fx/orb_water.png", "n": 2, "r": 3.5, "add": true},
	"sword_wave": {"tex": "fx/sword_wave.png", "n": 2, "r": 9.0, "add": true},
	"water_wave": {"tex": "fx/sword_wave.png", "n": 2, "r": 11.0, "add": true, "scale": 1.5, "tint": Color(0.4, 0.8, 1.0)},
	"axe": {"tex": "weapons/riu_thach_sanh.png", "r": 9.0, "spin": true},
}

var from_player := true
var dir := Vector2.RIGHT
var speed := 300.0
var damage := 1
var life := 1.0
var proj := "orb_pink"
var color := Color.WHITE
var pierce := 0
var explode_radius := 0.0
var knock := 60.0
var homing := 0.0
var boomerang := false
var owner_node = null
var stun_duration := 0.0
var burn_duration := 2.2
var _hit: Array = []
var _done := false
var _t := 0.0
var _returning := false
var _start_life := 1.0
var _spr: Node2D
var _trail_t := 0.0


func setup(player_owned: bool, pos: Vector2, direction: Vector2, spd: float, dmg: int, lifetime: float, kind: String) -> void:
	from_player = player_owned
	position = pos
	dir = direction
	speed = spd
	damage = dmg
	life = lifetime
	proj = kind


func _ready() -> void:
	var info: Dictionary = PROJ.get(proj, PROJ["orb_pink"])
	_start_life = life
	var shape := CircleShape2D.new()
	shape.radius = info.get("r", 3.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	monitorable = false
	collision_layer = 0
	collision_mask = 1 | (4 if from_player else 2)
	if not from_player:
		add_to_group("enemy_bullets")
	else:
		add_to_group("player_bullets")
	body_entered.connect(_on_body_entered)
	var tex := Art.tex(info.tex)
	var n: int = info.get("n", 1)
	if n > 1:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = Art.strip(info.tex, int(tex.get_width() / n), tex.get_height(), 12.0, true)
		a.play("play")
		_spr = a
	else:
		var s := Sprite2D.new()
		s.texture = tex
		_spr = s
	_spr.modulate = color * info.get("tint", Color.WHITE)
	var sc: float = info.get("scale", 1.0)
	_spr.scale = Vector2(sc, sc)
	if info.get("add", false):
		_spr.material = Art.additive()
	add_child(_spr)
	if info.has("light"):
		add_child(Art.light(info.light, 0.5, 0.7))
	if not info.get("spin", false):
		rotation = dir.angle()
	z_index = 3


func _physics_process(delta: float) -> void:
	_t += delta
	var info: Dictionary = PROJ.get(proj, {})
	if info.get("spin", false):
		_spr.rotation += delta * 18.0
	if info.get("grenade", false):
		speed = maxf(speed - 300.0 * delta, 30.0)
	if homing > 0.0 and from_player:
		var target = _nearest_enemy()
		if target != null:
			var want: float = (target.global_position - global_position).angle()
			var a := dir.angle()
			a += clampf(angle_difference(a, want), -homing * delta, homing * delta)
			dir = Vector2.from_angle(a)
			rotation = a
	if boomerang:
		if not _returning and _t > _start_life * 0.45:
			_returning = true
			_hit.clear()
		if _returning and owner_node != null and is_instance_valid(owner_node):
			var to: Vector2 = owner_node.global_position - global_position
			dir = to.normalized()
			if to.length() < 12.0:
				queue_free()
				return
		life = 99.0
	if info.get("trail", false):
		_trail_t -= delta
		if _trail_t <= 0.0:
			_trail_t = 0.03
			Fx.anim(get_parent(), global_position - dir * 6.0, "fx/poof.png", 28, 28, 18.0, 0.3, 0.0, Color(1, 1, 1, 0.7))
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		_finish()


func _nearest_enemy():
	var best = null
	var best_d := 170.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if _hit.has(e) or e.is_spawning():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if from_player and body.is_in_group("enemies"):
		if _hit.has(body):
			return
		_hit.append(body)
		Sfx.play("hit_bullet")
		body.take_damage(damage, dir * knock)
		if stun_duration > 0.0 and is_instance_valid(body) and not body.dead and body.has_method("apply_stun"):
			body.apply_stun(stun_duration)
		if owner_node != null and is_instance_valid(owner_node) and owner_node.has_method("on_hit_enemy") and is_instance_valid(body):
			owner_node.on_hit_enemy(body)
		var st: String = PROJ.get(proj, {}).get("status", "")
		if st != "" and is_instance_valid(body):
			body.apply_status(st, burn_duration if st == "burn" else 2.2)
		Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 24.0, 1.0, 0.0, color.lerp(Color(1, 0.9, 0.6), 0.5), true)
		if pierce > 0:
			pierce -= 1
			return
		_finish()
	elif not from_player and body.is_in_group("player"):
		body.take_damage(damage)
		var st2: String = PROJ.get(proj, {}).get("status", "")
		if st2 != "":
			body.status.apply(st2, 1.6 if st2 == "burn" else 2.8)
		_finish()
	elif body is TileMapLayer or body is StaticBody2D:
		Sfx.play("hit_wall")
		if boomerang:
			_returning = true
			return
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	if explode_radius > 0.0:
		Sfx.play("explode")
		if from_player:
			for e in get_tree().get_nodes_in_group("enemies"):
				if global_position.distance_to(e.global_position) < explode_radius + e.radius:
					e.take_damage(damage, (e.global_position - global_position).normalized() * 220.0)
		else:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and global_position.distance_to(p.global_position) < explode_radius + 6.0:
				p.take_damage(damage)
		var sc := explode_radius / 22.0
		Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 18.0, sc, 0.0, Color.WHITE, false, 6)
		Fx.particles(get_parent(), global_position, Color(1, 0.7, 0.3), 14, 140.0, 0.5, 0.0, 2.0, 180.0, Vector2.UP, Color(0.5, 0.4, 0.5))
		Fx.shake(get_tree(), minf(explode_radius / 12.0, 5.0))
		var l := Art.light(Color(1, 0.6, 0.3), explode_radius / 30.0, 1.6)
		l.position = global_position
		get_parent().add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "energy", 0.0, 0.35)
		tw.tween_callback(l.queue_free)
	elif not from_player:
		Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 24.0, 0.7, 0.0, Color(1, 0.6, 0.8), true)
	queue_free()


## Xóa đạn không nổ (bị chém tan, bị cọc chặn...)
func destroy() -> void:
	if _done:
		return
	_done = true
	Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 24.0, 0.8, 0.0, Color(0.8, 0.9, 1.0), true)
	queue_free()
