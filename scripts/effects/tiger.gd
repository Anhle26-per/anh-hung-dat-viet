extends Node2D
## "Hùm thiêng Yên Thế": hổ thần lao về phía trước, vồ mọi kẻ trên đường.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var dir := Vector2.RIGHT
var _life := 0.9
var _hit: Array = []
var _spr: AnimatedSprite2D
var _dt := 0.0


func _ready() -> void:
	z_index = 3
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.strip("fx/tiger.png", 40, 24, 14.0, true)
	_spr.flip_h = dir.x < 0.0
	_spr.play("play")
	_spr.modulate = Color(1, 0.9, 0.6, 0.95)
	add_child(_spr)
	add_child(Art.light(Color(1, 0.7, 0.3), 1.0, 0.8))


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, 1.4, 0.0, Color(1, 0.8, 0.5))
		queue_free()
		return
	position += dir * 300.0 * delta
	_dt -= delta
	if _dt <= 0.0:
		_dt = 0.05
		Fx.afterimage(get_parent(), _spr, global_position, Color(1, 0.6, 0.2, 0.5), 0.25)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not _hit.has(e) and global_position.distance_to(e.global_position) < 16.0 + e.radius:
			_hit.append(e)
			e.take_damage(14, dir * 300.0)
			Fx.anim(get_parent(), e.global_position, "fx/spark.png", 15, 15, 24.0, 1.4, 0.0, Color(1, 0.8, 0.4), true)
