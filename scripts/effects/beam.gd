extends Node2D
## Tia laze / điện từ: vẽ một đường sáng rồi tắt dần.

var end_point := Vector2(100, 0)
var width := 3.0
var color := Color(0.3, 0.9, 1.0)
var _t := 0.0
const DUR := 0.18


func _ready() -> void:
	z_index = 7
	material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / DUR
	var w := width * (0.6 + 0.4 * k)
	draw_line(Vector2.ZERO, end_point, Color(color, 0.35 * k), w * 2.6)
	draw_line(Vector2.ZERO, end_point, Color(color, 0.9 * k), w)
	draw_line(Vector2.ZERO, end_point, Color(1, 1, 1, k), maxf(1.0, w * 0.35))
	draw_circle(end_point, w * 1.4, Color(1, 1, 1, k))
	draw_circle(Vector2.ZERO, w * 1.2, Color(color, k))
