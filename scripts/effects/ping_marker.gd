extends Node2D
## Điểm Ping chiến thuật LAN Co-op: vòng đèn hiệu + cột sáng + nhãn chữ tự biến mất sau 4.5s.

const Art = preload("res://scripts/art/art.gd")

const PING_TYPES: Dictionary = {
	"focus": {"label": "Tập trung!", "color": Color(1.0, 0.78, 0.28)},
	"danger": {"label": "Nguy hiểm!", "color": Color(1.0, 0.34, 0.36)},
	"loot": {"label": "Nhặt đồ!", "color": Color(0.45, 0.96, 0.72)},
	"combo": {"label": "Hợp chiêu!", "color": Color(0.55, 0.86, 1.0)},
}
const PING_ORDER: Array = ["focus", "danger", "loot", "combo"]
const DURATION := 4.5


class PingWheel extends Control:
	signal ping_selected(kind: String)

	var selected_kind: String = "focus"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(180.0, 180.0)
		size = Vector2(180.0, 180.0)
		visible = false

	func open_at(screen_pos: Vector2) -> void:
		position = screen_pos - size * 0.5
		visible = true
		queue_redraw()

	func close() -> void:
		visible = false

	func _gui_input(event: InputEvent) -> void:
		if not visible:
			return
		var center: Vector2 = size * 0.5
		if event is InputEventMouseMotion:
			var d: Vector2 = (event as InputEventMouseMotion).position - center
			selected_kind = _kind_from_vec(d)
			queue_redraw()
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				selected_kind = _kind_from_vec(mb.position - center)
				ping_selected.emit(selected_kind)
				close()
				accept_event()

	func _kind_from_vec(v: Vector2) -> String:
		if absf(v.x) > absf(v.y):
			return "combo" if v.x >= 0.0 else "loot"
		return "focus" if v.y < 0.0 else "danger"

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		draw_circle(c, 74.0, Color(0.06, 0.03, 0.08, 0.86))
		draw_arc(c, 74.0, 0.0, TAU, 36, Color(0.95, 0.78, 0.36, 0.85), 2.0)
		var dirs: Dictionary = {
			"focus": Vector2(0.0, -44.0),
			"danger": Vector2(0.0, 44.0),
			"loot": Vector2(-46.0, 0.0),
			"combo": Vector2(46.0, 0.0),
		}
		for k in PING_ORDER:
			var info: Dictionary = PING_TYPES[k]
			var col: Color = info["color"]
			var p: Vector2 = c + (dirs[k] as Vector2)
			var active: bool = (k == selected_kind)
			draw_circle(p, 24.0 if active else 19.0, Color(col.r, col.g, col.b, 0.32 if active else 0.14))
			draw_arc(p, 24.0 if active else 19.0, 0.0, TAU, 24, col, 2.0 if active else 1.2)
			Art.draw_text(self, p + Vector2(0.0, 4.0), str(info["label"]), 11, col, true)


var kind: String = "focus"
var sender_name: String = ""
var ping_color: Color = Color(1.0, 0.78, 0.28)
var _t: float = 0.0


static func cycle_ping_kind(cur: String) -> String:
	var idx: int = PING_ORDER.find(cur)
	if idx < 0:
		return str(PING_ORDER[0])
	return str(PING_ORDER[(idx + 1) % PING_ORDER.size()])


static func spawn_ping(parent: Node, pos: Vector2, p_kind: String = "focus", p_sender: String = "", col_override: Color = Color(0, 0, 0, 0)) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var valid_kind: String = p_kind if PING_TYPES.has(p_kind) else "focus"
	var node := load("res://scripts/effects/ping_marker.gd").new() as Node2D
	node.position = pos
	node.kind = valid_kind
	node.sender_name = p_sender
	var base_col: Color = PING_TYPES[valid_kind]["color"]
	node.ping_color = col_override if col_override.a > 0.01 else base_col
	node.z_index = 8
	parent.add_child(node)
	return node


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf((DURATION - _t) / 0.6, 0.0, 1.0)
	var pulse: float = fmod(_t * 1.8, 1.0)
	var info: Dictionary = PING_TYPES.get(kind, PING_TYPES["focus"])
	var col := Color(ping_color.r, ping_color.g, ping_color.b, fade)

	# Cột sáng đứng
	draw_rect(Rect2(-4.0, -56.0, 8.0, 56.0), Color(col.r, col.g, col.b, 0.16 * fade))
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -56.0), Color(col.r, col.g, col.b, 0.75 * fade), 2.0)
	draw_circle(Vector2.ZERO, 6.0, Color(col.r, col.g, col.b, 0.55 * fade))

	# Vòng lan tỏa
	draw_arc(Vector2.ZERO, 8.0 + pulse * 24.0, 0.0, TAU, 28, Color(col.r, col.g, col.b, (1.0 - pulse) * 0.85 * fade), 1.6)
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, col, 1.4)

	var label_txt: String = str(info["label"])
	if sender_name != "":
		Art.draw_text(self, Vector2(0.0, -68.0), sender_name, 11, Color(1.0, 0.96, 0.82, fade), true)
		Art.draw_text(self, Vector2(0.0, -56.0), label_txt, 13, col, true)
	else:
		Art.draw_text(self, Vector2(0.0, -60.0), label_txt, 13, col, true)
