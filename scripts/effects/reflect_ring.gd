extends Node2D
## "Nam quốc sơn hà": vòng chữ thần quanh Lý Thường Kiệt, bật ngược đạn giặc.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const TEXT := "NAM QUỐC SƠN HÀ NAM ĐẾ CƯ  "

var life := 5.0
var radius := 30.0
var _t := 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var world := get_parent().get_parent()
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < radius + 3.0:
			var nb := Bullet.new()
			var dir: Vector2 = (b.global_position - global_position).normalized()
			nb.setup(true, b.global_position, dir, 320.0, 4, 0.8, b.proj)
			nb.color = Color(1, 0.85, 0.4)
			world.add_child(nb)
			b.destroy()
	queue_redraw()


func _draw() -> void:
	var a := clampf(life / 0.5, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1, 0.85, 0.35, 0.7 * a), 2.0)
	draw_arc(Vector2.ZERO, radius - 4, 0.0, TAU, 48, Color(1, 0.85, 0.35, 0.3 * a), 1.0)
	var f := Art.font()
	var n := TEXT.length()
	for i in n:
		var ang := _t * 1.2 + TAU * i / n
		var p := Vector2.from_angle(ang) * (radius + 6.0)
		draw_set_transform(p, ang + PI / 2.0, Vector2.ONE)
		draw_string(f, Vector2(-3, 4), TEXT[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.45, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
