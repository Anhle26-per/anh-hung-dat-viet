extends StaticBody2D
## Cửa song gỗ đóng lại khi vào phòng có giặc, mở ra khi dọn sạch.

var size := Vector2(16, 48)
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("doors")
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = size / 2.0
	add_child(cs)
	z_index = 1


func _process(delta: float) -> void:
	_t = minf(_t + delta * 6.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var horizontal := size.x > size.y
	var dark := Color(0.16, 0.09, 0.05, _t)
	var wood := Color(0.62, 0.40, 0.20, _t)
	var lite := Color(0.82, 0.6, 0.32, _t)
	draw_rect(r, dark)
	var n := int((size.x if horizontal else size.y) / 5.0)
	for i in n:
		var k := (i + 0.5) / n
		if horizontal:
			draw_rect(Rect2(size.x * k - 1.5, 0, 3, size.y), wood)
			draw_rect(Rect2(size.x * k - 1.5, 0, 1, size.y), lite)
		else:
			draw_rect(Rect2(0, size.y * k - 1.5, size.x, 3), wood)
			draw_rect(Rect2(0, size.y * k - 1.5, size.x, 1), lite)
	var gold := Color(0.9, 0.7, 0.3, _t)
	if horizontal:
		draw_rect(Rect2(0, size.y / 2.0 - 1, size.x, 2), gold)
	else:
		draw_rect(Rect2(size.x / 2.0 - 1, 0, 2, size.y), gold)
	draw_rect(r, Color(0.06, 0.03, 0.05, _t), false, 1.0)
