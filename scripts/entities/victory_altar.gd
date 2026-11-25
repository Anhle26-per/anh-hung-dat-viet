extends "res://scripts/entities/interactable.gd"
## Đài Chiến Thắng xuất hiện tại Sảnh Khải Hoàn (Màn 3-6 hoặc 6-6):
## Chạm vào để nhận phần thưởng Khải Hoàn hoặc bước tiếp vào Cổng Thần Thoại (tại 3-6).

var _used: bool = false
var mythic: bool = false


func _ready() -> void:
	add_to_group("victory_altars")
	z_index = 2
	radius = 28.0
	add_child(Art.light(Color(0.82, 0.58, 1.0) if mythic else Color(1.0, 0.86, 0.35), 1.9 if mythic else 1.8, 1.35))


func hint() -> String:
	return "Chạm Đài Huyền Thoại — Về Sảnh Đợt Hai!" if mythic else "Chạm Đài Chiến Thắng — Tổng Kết!"


func interact() -> void:
	if _used:
		return
	_used = true
	enabled = false
	near = false
	Sfx.play("level_clear")
	get_tree().call_group("game", "show_victory", mythic)


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	# Bóng đổ & hào quang vàng dưới chân đài
	draw_circle(Vector2(0, 6), 19.0, Color(0.0, 0.0, 0.0, 0.32))
	var pulse: float = 0.35 + 0.25 * sin(_t * 4.0)
	var gcol: Color = Color(0.82, 0.56, 1.0) if mythic else Color(1.0, 0.88, 0.36)
	draw_arc(Vector2(0, 4), 22.0, 0.0, TAU, 28, Color(gcol.r, gcol.g, gcol.b, pulse), 1.8)

	# Bệ đá 2 tầng chạm viền vàng đồng
	draw_rect(Rect2(-15, 0, 30, 8), Color("58545a"))
	draw_rect(Rect2(-15, 0, 30, 2), Color("88828a"))
	draw_rect(Rect2(-11, -7, 22, 7), Color("706a72"))
	draw_rect(Rect2(-11, -7, 22, 2), Color("c47aff") if mythic else Color("d8a83a"))

	# Cúp Trống Đồng / Ngọc Lạc Việt bay lơ lửng phát sáng ở đỉnh đài
	var bob: float = sin(_t * 3.2) * 2.5
	var ctr := Vector2(0, -18.0 + bob)
	draw_circle(ctr, 9.0, Color(gcol.r, gcol.g, gcol.b, 0.24))
	var diamond := PackedVector2Array([
		ctr + Vector2(0, -8),
		ctr + Vector2(7, 0),
		ctr + Vector2(0, 8),
		ctr + Vector2(-7, 0),
	])
	draw_colored_polygon(diamond, Color("c47aff") if mythic else Color("ffd24a"))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("f4e6ff") if mythic else Color("fff4b8"), 1.5, true)
	draw_circle(ctr, 2.8, Color("ffffff"))

	Art.draw_text(self, Vector2(0, -34), "Đài Huyền Thoại" if mythic else "Đài Chiến Thắng", 12, Color(0.92, 0.78, 1.0) if mythic else Color(1.0, 0.9, 0.42))
	draw_hint(-47.0)
