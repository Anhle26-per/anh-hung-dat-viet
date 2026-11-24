extends Sprite2D
## Ấn trống đồng hiện dưới chân khi Trần Hưng Đạo đọc Hịch tướng sĩ.

const Art = preload("res://scripts/art/art.gd")


func _ready() -> void:
	texture = Art.tex("fx/drum.png")
	material = Art.additive()
	z_index = -1
	scale = Vector2(0.2, 0.1)
	modulate = Color(1, 0.85, 0.5, 0.9)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.6, 0.8), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation", 0.6, 1.4)
	var tw2 := create_tween()
	tw2.tween_interval(0.9)
	tw2.tween_property(self, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(queue_free)
