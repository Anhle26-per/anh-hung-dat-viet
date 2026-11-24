extends Node2D
## Chữ/số bay lên rồi mờ dần (số sát thương, thông báo nhỏ).

const Art = preload("res://scripts/art/art.gd")

var text := ""
var color := Color.WHITE
var size := 14
var _t := 0.0


func _ready() -> void:
	z_index = 20
	scale = Vector2(1.4, 1.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.12)


func _process(delta: float) -> void:
	_t += delta
	position.y -= 22.0 * delta
	if _t > 0.7:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - clampf((_t - 0.35) / 0.35, 0.0, 1.0)
	Art.draw_text(self, Vector2.ZERO, text, size, Color(color, a))
