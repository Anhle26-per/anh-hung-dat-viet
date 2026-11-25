extends "res://scripts/entities/interactable.gd"
## Đài Chiến Thắng xuất hiện sau khi hạ Trùm Chương 3 (Màn 3-3):
## Chạm vào để nhận phần thưởng Khải Hoàn hoặc bước tiếp vào Cổng Vô Tận.

var _used: bool = false


func _ready() -> void:
	add_to_group("victory_altars")
	z_index = 2
	radius = 28.0
	add_child(Art.light(Color(1.0, 0.86, 0.35), 1.8, 1.3))


func hint() -> String:
	return "Chạm Đài Chiến Thắng — Khải Hoàn!"


func interact() -> void:
	if _used:
		return
	_used = true
	enabled = false
	near = false
	Sfx.play("level_clear")
	get_tree().call_group("game", "show_victory")


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	# Bóng đổ & hào quang vàng dưới chân đài
	draw_circle(Vector2(0, 6), 19.0, Color(0.0, 0.0, 0.0, 0.32))
	var pulse: float = 0.35 + 0.25 * sin(_t * 4.0)
	draw_arc(Vector2(0, 4), 22.0, 0.0, TAU, 28, Color(1.0, 0.88, 0.36, pulse), 1.8)

	# Bệ đá 2 tầng chạm viền vàng đồng
	draw_rect(Rect2(-15, 0, 30, 8), Color("58545a"))
	draw_rect(Rect2(-15, 0, 30, 2), Color("88828a"))
	draw_rect(Rect2(-11, -7, 22, 7), Color("706a72"))
	draw_rect(Rect2(-11, -7, 22, 2), Color("d8a83a"))

	# Cúp Trống Đồng / Ngọc Lạc Việt bay lơ lửng phát sáng ở đỉnh đài
	var bob: float = sin(_t * 3.2) * 2.5
	var ctr := Vector2(0, -18.0 + bob)
	draw_circle(ctr, 9.0, Color(1.0, 0.86, 0.35, 0.22))
	var diamond := PackedVector2Array([
		ctr + Vector2(0, -8),
		ctr + Vector2(7, 0),
		ctr + Vector2(0, 8),
		ctr + Vector2(-7, 0),
	])
	draw_colored_polygon(diamond, Color("ffd24a"))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("fff4b8"), 1.5, true)
	draw_circle(ctr, 2.8, Color("ffffff"))

	Art.draw_text(self, Vector2(0, -34), "Đài Chiến Thắng", 12, Color(1.0, 0.9, 0.42))
	draw_hint(-47.0)
