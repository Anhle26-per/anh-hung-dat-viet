extends Node2D
## "Hỏa hồng Nhật Tảo": bầu lửa bay ra rồi bùng thành biển lửa.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var target := Vector2.ZERO
var radius := 20.0
var life := 4.0
var _burning := false
var _cd := {}
var _pt := 0.0
var _pot: Sprite2D


func _ready() -> void:
	z_index = 1
	_pot = Sprite2D.new()
	_pot.texture = Art.tex("fx/fire_pot.png")
	add_child(_pot)
	var tw := create_tween()
	tw.tween_property(self, "position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_pot, "position:y", -14.0, 0.17).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(_pot, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(_ignite)


func _ignite() -> void:
	_burning = true
	_pot.visible = false
	Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 20.0, 0.8)
	var l := Art.light(Color(1, 0.55, 0.2), 1.0, 0.9)
	add_child(l)


func _process(delta: float) -> void:
	if not _burning:
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_pt -= delta
	if _pt <= 0.0:
		_pt = 0.08
		var off := Vector2.from_angle(randf() * TAU) * randf() * radius
		Fx.particles(get_parent(), global_position + off, Color(1, 0.7, 0.25), 2, 30.0, 0.5, -70.0, 2.0, 30.0, Vector2.UP, Color(0.8, 0.15, 0.1))
	for k in _cd.keys():
		_cd[k] -= delta
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) < radius + e.radius:
			var id: int = e.get_instance_id()
			if _cd.get(id, 0.0) <= 0.0:
				_cd[id] = 0.4
				e.take_damage(3, Vector2.ZERO)
				if is_instance_valid(e) and not e.dead:
					e.apply_status("burn", 2.0)
	queue_redraw()


func _draw() -> void:
	if not _burning:
		return
	var a := clampf(life / 0.5, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(1, 0.4, 0.1, 0.22 * a))
	draw_circle(Vector2.ZERO, radius * 0.6, Color(1, 0.7, 0.2, 0.22 * a))
