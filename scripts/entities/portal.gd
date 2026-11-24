extends Node2D
## Cổng dịch chuyển sang màn tiếp theo.

signal entered

const Art = preload("res://scripts/art/art.gd")

var label := "Cổng sang màn sau"
var _t := 0.0
var _used := false


func _ready() -> void:
	add_to_group("portals")
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Art.strip("fx/portal.png", 44, 44, 12.0, true)
	s.play("play")
	add_child(s)
	add_child(Art.light(Color(0.4, 0.8, 1.0), 1.6, 1.2))
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _used or _t < 0.5:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and p.global_position.distance_to(global_position) < 16.0:
		_used = true
		entered.emit()


func _draw() -> void:
	Art.draw_text(self, Vector2(0, -28), label, 14, Color(0.8, 0.95, 1.0))
