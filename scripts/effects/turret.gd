extends Node2D
## "Kéo pháo vào trận": khẩu pháo dã chiến tự động bắn vào giặc gần nhất.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")

var life := 9.0
var _cd := 0.4
var _spr: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("fx/turret.png", 30, 20, {"idle": [[0], 1.0, false], "fire": [[1, 0], 10.0, false]})
	_spr.play("idle")
	add_child(_spr)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.anim(get_parent(), position, "fx/dust.png", 10, 10, 12.0, 2.5)


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, 1.2)
		queue_free()
		return
	if life < 1.0:
		modulate.a = 0.5 + 0.5 * sin(life * 30.0)
	_cd -= delta
	var target = null
	var best := 260.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_spawning():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best:
			best = d
			target = e
	if target == null:
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	_spr.flip_h = dir.x < 0.0
	if _cd <= 0.0:
		_cd = 0.7
		var b := Bullet.new()
		b.setup(true, global_position + dir * 14.0 + Vector2(0, -4), dir, 340.0, 10, 1.0, "cannonball")
		b.explode_radius = 30.0
		get_parent().add_child(b)
		_spr.play("fire")
		Fx.anim(get_parent(), global_position + dir * 16.0 + Vector2(0, -4), "fx/muzzle.png", 12, 10, 24.0, 1.2, dir.angle(), Color.WHITE, true, 6)
		Fx.shake(get_tree(), 1.5)
