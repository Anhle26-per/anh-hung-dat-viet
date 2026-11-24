extends Node2D
## Đạn cối / pháo kích: vòng đỏ báo trước, sau đó nổ tại chỗ.

const Fx = preload("res://scripts/effects/fx.gd")
const RockSpike = preload("res://scripts/effects/rock_spike.gd")

var radius := 26.0
var damage := 1
var delay := 1.0
var root := false        # true: rễ cây Mộc Tinh trồi lên (vòng xanh, gai gỗ) thay vì nổ
var _t := 0.0


func _ready() -> void:
	z_index = 0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= delay:
		var p = get_tree().get_first_node_in_group("player")
		if p != null and global_position.distance_to(p.global_position) < radius + 6.0:
			p.take_damage(damage)
		if root:
			var s := RockSpike.new()
			s.hostile = true
			s.position = global_position
			get_parent().add_child(s)
			queue_free()
			return
		Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 18.0, radius / 20.0)
		Fx.particles(get_parent(), global_position, Color(0.75, 0.65, 0.5), 10, 110.0, 0.5, 120.0, 2.0)
		Fx.shake(get_tree(), 2.0)
		queue_free()


func _draw() -> void:
	var k := clampf(_t / delay, 0.0, 1.0)
	var c := Color(0.45, 0.9, 0.3) if root else Color(1, 0.3, 0.2)
	draw_circle(Vector2.ZERO, radius, Color(c, 0.12 + 0.12 * k))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(c, 0.8), 1.5)
	draw_arc(Vector2.ZERO, radius * k, 0.0, TAU, 32, Color(c.lightened(0.3), 0.9), 1.0)
	if not root:
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1, 0.4, 0.3), 1.0)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color(1, 0.4, 0.3), 1.0)
