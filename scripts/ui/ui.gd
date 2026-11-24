extends RefCounted
## Giao diện: chủ đề (font pixel + khung sơn mài), hàm tạo nút, chữ, lớp phủ.

const Art = preload("res://scripts/art/art.gd")


## Chủ đề chung cho mọi nút / khung (Global gắn vào cửa sổ gốc khi mở game)
static var _theme: Theme = null


static func make_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	_theme = t
	t.default_font = Art.font()
	t.default_font_size = 18
	for st in [["normal", "ui/button.png"], ["hover", "ui/button_hover.png"], ["pressed", "ui/button_pressed.png"],
			["focus", "ui/button_hover.png"], ["disabled", "ui/button_pressed.png"]]:
		t.set_stylebox(st[0], "Button", _box(st[1], 5, Vector4(10, 4, 10, 5)))
	t.set_color("font_color", "Button", Color(1, 0.94, 0.8))
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.9))
	t.set_color("font_pressed_color", "Button", Color(1, 0.85, 0.6))
	t.set_color("font_outline_color", "Button", Color(0.1, 0.03, 0.05))
	t.set_constant("outline_size", "Button", 4)
	t.set_stylebox("panel", "PanelContainer", _box("ui/panel.png", 6, Vector4(8, 8, 8, 8)))
	t.set_color("font_outline_color", "Label", Color(0.06, 0.03, 0.08))
	t.set_constant("outline_size", "Label", 4)
	return t


static func _box(rel: String, margin: int, content: Vector4) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = Art.tex(rel)
	s.texture_margin_left = margin
	s.texture_margin_top = margin
	s.texture_margin_right = margin
	s.texture_margin_bottom = margin
	s.content_margin_left = content.x
	s.content_margin_top = content.y
	s.content_margin_right = content.z
	s.content_margin_bottom = content.w
	return s


static func panel_box(rel: String) -> StyleBoxTexture:
	return _box(rel, 6, Vector4(8, 8, 8, 8))


static func button(text: String, on_press: Callable, font_size := 20, width := 220.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 30)
	b.add_theme_font_size_override("font_size", font_size)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		var ml: MainLoop = Engine.get_main_loop()
		if ml is SceneTree:
			var sfx: Node = (ml as SceneTree).root.get_node_or_null("Sfx")
			if sfx != null:
				sfx.play("ui_click"))
	b.pressed.connect(on_press)
	return b


static func label(text: String, size := 18, color := Color.WHITE, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func center(c: Control) -> Control:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(c)
	return h


## Phủ một lớp tối toàn màn hình, trả về hộp dọc ở giữa.
static func overlay(parent: Node, dim := 0.6) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, dim)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.theme = make_theme()
	parent.add_child(c)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(box)
	return box
