extends Node2D
## Cọc Bạch Đằng: trồi lên khỏi mặt nước, đâm quái và chặn đạn, rồi chìm xuống.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const LIFE := 6.0
var life_time := LIFE
var stun_time := 0.0
var _life := LIFE
var _cd := {}
var _spr: AnimatedSprite2D
var _sinking := false


func _ready() -> void:
	_life = life_time
	z_index = 1
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("fx/stake.png", 14, 26, {
		"up": [[0, 1, 2], 16.0, false],
		"idle": [[2, 3], 3.0, true],
		"down": [[4, 5, 0], 10.0, false],
	})
	_spr.position = Vector2(0, -8)
	_spr.play("up")
	_spr.animation_finished.connect(func():
		if _spr.animation == "up":
			_spr.play("idle"))
	add_child(_spr)
	Fx.particles(get_parent(), position, Color(0.55, 0.85, 1.0), 6, 60.0, 0.4, 160.0, 1.5, 50.0)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.4 and not _sinking:
		_sinking = true
		_spr.play("down")
	if _life <= 0.0:
		queue_free()
		return
	if _sinking:
		return
	for k in _cd.keys():
		_cd[k] -= delta
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) < 10.0 + e.radius:
			var id: int = e.get_instance_id()
			if _cd.get(id, 0.0) <= 0.0:
				_cd[id] = 0.5
				e.take_damage(3, (e.global_position - global_position).normalized() * 160.0)
				if stun_time > 0.0 and is_instance_valid(e) and not e.dead and e.has_method("apply_stun"):
					e.apply_stun(stun_time)
				Fx.particles(get_parent(), global_position + Vector2(0, -6), Color(0.6, 0.85, 1.0), 4, 50.0, 0.3)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < 9.0:
			b.destroy()
