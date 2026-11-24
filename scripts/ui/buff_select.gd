extends CanvasLayer
## Màn chọn phúc lành sau mỗi màn: 3 thẻ, chọn 1.

signal chosen(id)

const BuffData = preload("res://scripts/data/buffs.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

var _options: Array = []
var _root: Control


func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(next_title: String) -> bool:
	_options = BuffData.offer(Global.run_buffs, 3)
	if _options.is_empty():
		return false
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UI.make_theme()
	add_child(_root)
	var box := UI.overlay(_root, 0.72)
	box.add_child(UI.label("Chọn một phúc lành", 32, Color(1, 0.85, 0.4)))
	box.add_child(UI.label("Tiếp theo: %s" % next_title, 16, Color(0.9, 0.85, 0.8)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for i in _options.size():
		row.add_child(_card(i, _options[i]))
	visible = true
	get_tree().paused = true
	return true


func _card(i: int, id: String) -> Control:
	var b: Dictionary = BuffData.DATA[id]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 180)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(pick.bind(i))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 10
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	btn.add_child(v)
	var icon := TextureRect.new()
	icon.texture = Art.tex("ui/buff_%s.png" % id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 56)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	for l in [UI.label(b.name, 22, Color(1, 0.9, 0.55)), UI.label(b.desc, 14, Color(0.95, 0.92, 0.88), true),
			UI.label("Đang có: %d / %d" % [int(Global.run_buffs.get(id, 0)), int(b.max)], 13, Color(0.7, 0.85, 1.0))]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	return btn


func pick(i: int) -> void:
	if not visible or i >= _options.size():
		return
	visible = false
	get_tree().paused = false
	chosen.emit(_options[i])
