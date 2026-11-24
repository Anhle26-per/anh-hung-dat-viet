extends Node2D
## Điểm tương tác trong sảnh (tướng, lò rèn, giá binh khí, bia đá...).
## Đứng gần và bấm E (nút Dùng trên điện thoại) để dùng.

const Art = preload("res://scripts/art/art.gd")

signal used(station)

var kind := ""
var data := ""
var title := ""
var hint := ""
var radius := 24.0
var near := false
var title_color := Color(1, 0.9, 0.6)
var title_when_near := false   # chỉ hiện tên khi đến gần (tránh chữ chồng nhau)
var _t := 0.0


func _ready() -> void:
	z_index = 1


func interact() -> void:
	used.emit(self)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var p = get_tree().get_first_node_in_group("player")
	var show_near: bool = near and (p == null or not is_instance_valid(p) or p.interact_target == self)
	if show_near:
		var a := 0.5 + 0.3 * sin(_t * 6.0)
		draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1, 0.85, 0.4, a), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var key := "Bấm DÙNG" if Global.touch_mode else "E"
		Art.draw_text(self, Vector2(0, -34), "%s: %s" % [key, hint], 13, Color(1, 0.95, 0.75))
	if show_near or not title_when_near:
		Art.draw_text(self, Vector2(0, -24), title, 12, title_color)
