extends Node2D
## Sóng lan ra (Trống đồng thần, Đàn thần Thạch Sanh): gây sát thương, làm choáng, xóa đạn.

const Art = preload("res://scripts/art/art.gd")

var radius := 110.0
var damage := 5
var stun := 0.0
var color := Color(1.0, 0.8, 0.4)
var notes := false
var _r := 6.0
var _hit: Array = []
var _t := 0.0
const DUR := 0.4


func _ready() -> void:
	z_index = 4
	material = Art.additive()


func _process(delta: float) -> void:
	_t += delta
	_r = lerpf(6.0, radius, minf(_t / DUR, 1.0))
	for e in get_tree().get_nodes_in_group("enemies"):
		if _hit.has(e):
			continue
		if global_position.distance_to(e.global_position) <= _r + e.radius:
			_hit.append(e)
			e.take_damage(damage, (e.global_position - global_position).normalized() * 120.0)
			if stun > 0.0 and e.has_method("apply_stun"):
				e.apply_stun(stun)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) <= _r:
			b.destroy()
	if _t >= DUR + 0.15:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - clampf((_t - DUR * 0.6) / (DUR * 0.6), 0.0, 1.0)
	draw_arc(Vector2.ZERO, _r, 0.0, TAU, 64, Color(color, 0.85 * a), 3.0)
	draw_arc(Vector2.ZERO, _r * 0.82, 0.0, TAU, 64, Color(color, 0.4 * a), 2.0)
	# vạch hoa văn trống đồng / nốt nhạc quanh vòng
	for i in 16:
		var ang := TAU * i / 16.0 + _t * 2.0
		var p := Vector2.from_angle(ang) * _r
		if notes:
			draw_circle(p, 2.0, Color(color, a))
			draw_line(p + Vector2(1.5, 0), p + Vector2(1.5, -6), Color(color, a), 1.0)
		else:
			draw_line(p * 0.92, p * 1.06, Color(1, 1, 0.8, a), 2.0)
