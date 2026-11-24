extends Node2D
## Chướng khí: đám mây độc loang ra rồi tan dần (như vòng độc trong các game roguelike,
## ở đây mang dáng sương lam chướng của rừng thiêng). Ai đứng trong sẽ trúng độc.

const Fx = preload("res://scripts/effects/fx.gd")

var radius := 34.0
var life := 4.5
var from_player := false     # true: chỉ hại giặc, false: chỉ hại người chơi
var color := Color(0.45, 0.85, 0.3)
var _t := 0.0
var _pt := 0.0
var _puffs: Array = []


func _ready() -> void:
	z_index = 0
	for i in 9:
		_puffs.append([Vector2.from_angle(randf() * TAU) * randf() * 0.7, randf_range(0.35, 0.6), randf() * TAU])


## Bán kính hiện tại: loang ra trong 0.6s, giữ, rồi co lại 0.8s cuối
func current_radius() -> float:
	var grow := clampf(_t / 0.6, 0.0, 1.0)
	var shrink := clampf((life - _t) / 0.8, 0.0, 1.0)
	return radius * minf(grow, shrink)


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	var r := current_radius()
	_pt -= delta
	if _pt <= 0.0:
		_pt = 0.1
		var off := Vector2.from_angle(randf() * TAU) * randf() * r
		Fx.particles(get_parent(), global_position + off, color.lightened(0.3), 1, 12.0, 0.8, -15.0, 2.0)
	if _t > 0.35:
		if from_player:
			for e in get_tree().get_nodes_in_group("enemies"):
				if global_position.distance_to(e.global_position) < r + e.radius:
					e.apply_status("poison", 1.5)
		else:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and not p.dead and global_position.distance_to(p.global_position) < r * 0.9:
				p.status.apply("poison", 2.0)
	queue_redraw()


func _draw() -> void:
	var r := current_radius()
	if r <= 1.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
	draw_circle(Vector2.ZERO, r, Color(color, 0.16))
	for p in _puffs:
		var c: Vector2 = p[0] * r + Vector2(sin(_t * 1.3 + p[2]), cos(_t + p[2])) * 3.0
		draw_circle(c, r * p[1], Color(color.darkened(0.15), 0.14))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color.lightened(0.2), 0.55), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
