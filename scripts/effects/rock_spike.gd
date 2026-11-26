extends Node2D
## Gai đá trồi lên (Gậy thần Sơn Tinh).

const Fx = preload("res://scripts/effects/fx.gd")

var damage := 10
var hostile := false     # true: rễ cây của yêu quái, chỉ hại người chơi
var _t := 0.0
const LIFE := 0.7


func _ready() -> void:
	z_index = 2
	if hostile:
		Fx.particles(get_parent(), global_position + Vector2(0, 4), Color(0.45, 0.32, 0.2), 6, 60.0, 0.4, 120.0, 2.0, 70.0)
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else (global_position.distance_to(e.global_position) - e.radius)
		if dist_e < 15.0:
			var e_ctr: Vector2 = e.hurtbox_center() if e.has_method("hurtbox_center") else e.global_position
			e.take_damage(damage, Vector2(0, -1) * 60.0 + (e_ctr - global_position).normalized() * 80.0)
	Fx.particles(get_parent(), global_position + Vector2(0, 4), Color(0.75, 0.68, 0.55), 6, 60.0, 0.4, 120.0, 2.0, 70.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var grow := minf(_t / 0.08, 1.0)
	var fade := 1.0 - clampf((_t - LIFE * 0.6) / (LIFE * 0.4), 0.0, 1.0)
	var h := 16.0 * grow * fade
	var base := Color(0.45, 0.3, 0.18) if hostile else Color(0.55, 0.5, 0.42)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 5), Vector2(-1, 5 - h), Vector2(1, 5)]), base.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 5), Vector2(3, 5 - h * 1.25), Vector2(8, 5)]), base)
	draw_line(Vector2(3, 5 - h * 1.25), Vector2(1, 5 - h * 0.5), base.lightened(0.35), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(4, 5), Vector2(8, 5 - h * 0.7), Vector2(10, 5)]), base.darkened(0.35))
