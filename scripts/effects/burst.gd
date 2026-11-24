extends Node2D
## Vòng tròn lan ra rồi mờ dần (khi quái chết, khi nổ).

var color := Color.WHITE
var max_r := 16.0
var dur := 0.3
var _t := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	if _t >= dur:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / dur
	draw_circle(Vector2.ZERO, max_r * k, Color(color, 0.25 * (1.0 - k)))
	draw_arc(Vector2.ZERO, max_r * k, 0.0, TAU, 24, Color(color, 1.0 - k), 2.0)
