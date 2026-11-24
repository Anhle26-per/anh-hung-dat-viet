extends CharacterBody2D
## Binh sĩ Đại Việt được gọi ra bởi "Hịch tướng sĩ".

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var _life := 10.0
var damage := 3
var focus_player_target := false
var _atk := 0.0
var _target = null
var _spr: AnimatedSprite2D
var _lunge := 0.0


func _ready() -> void:
	add_to_group("allies")
	collision_layer = 8
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	z_index = 1
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 7)
	sh.z_index = -2
	add_child(sh)
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.strip("fx/ally.png", 18, 20, 10.0, true)
	_spr.position = Vector2(0, -3)
	_spr.play("play")
	add_child(_spr)


func _physics_process(delta: float) -> void:
	_life -= delta
	_atk -= delta
	_lunge = move_toward(_lunge, 0.0, delta * 40.0)
	if _life <= 0.0:
		Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0)
		queue_free()
		return
	if _life < 1.0:
		_spr.modulate.a = 0.5 + 0.5 * sin(_life * 30.0)
	if focus_player_target:
		var pl = get_tree().get_first_node_in_group("player")
		if pl != null and pl.last_hit_enemy != null and is_instance_valid(pl.last_hit_enemy) and not pl.last_hit_enemy.dead:
			_target = pl.last_hit_enemy
	if _target == null or not is_instance_valid(_target) or _target.dead:
		_target = _find_target()
	velocity = Vector2.ZERO
	if _target != null:
		var to: Vector2 = _target.global_position - global_position
		_spr.flip_h = to.x < 0.0
		if to.length() < 16.0 + _target.radius:
			if _atk <= 0.0:
				_atk = 0.6
				_lunge = 6.0
				_target.take_damage(damage, to.normalized() * 100.0)
				Fx.slash(get_parent(), global_position, to.normalized(), 26.0, 0.4, Color(1, 0.9, 0.7), "thrust")
		else:
			velocity = to.normalized() * 125.0
	else:
		var p = get_tree().get_first_node_in_group("player")
		if p != null:
			var to_p: Vector2 = p.global_position - global_position
			if to_p.length() > 30.0:
				velocity = to_p.normalized() * 115.0
				_spr.flip_h = to_p.x < 0.0
	_spr.position.x = _lunge * (-1.0 if _spr.flip_h else 1.0)
	_spr.speed_scale = 1.0 if velocity.length() > 1.0 else 0.0
	move_and_slide()


func _find_target():
	var best = null
	var best_d := 260.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_spawning():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
