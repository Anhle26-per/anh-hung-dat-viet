extends Control
## Màn hình chính.

const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")
const HeroData = preload("res://scripts/data/heroes.gd")


class Backdrop extends Control:
	## Nền: mặt trời đỏ, núi non, cánh chim Lạc, mặt trống đồng mờ.
	const Art = preload("res://scripts/art/art.gd")
	var t := 0.0
	var drum: Texture2D

	func _ready() -> void:
		drum = Art.tex("fx/drum.png")

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.05, 0.08))
		for i in 6:
			draw_rect(Rect2(0, h * i / 12.0, w, h / 12.0), Color(0.16 - i * 0.012, 0.06, 0.09))
		var c := Vector2(w * 0.5, h * 0.6)
		draw_set_transform(c, t * 0.05, Vector2(3.4, 3.4))
		draw_texture(drum, -Vector2(32, 32), Color(1, 0.6, 0.4, 0.12))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(c, 92.0, Color(0.55, 0.12, 0.10))
		draw_circle(c, 82.0, Color(0.78, 0.2, 0.12))
		draw_circle(c, 70.0, Color(0.88, 0.32, 0.14))
		var layers := [[0.70, Color(0.2, 0.09, 0.12), 0.0], [0.80, Color(0.13, 0.06, 0.09), 1.7], [0.91, Color(0.07, 0.03, 0.06), 3.1]]
		for l in layers:
			var pts := PackedVector2Array([Vector2(0, h)])
			for i in 33:
				var x := w * i / 32.0
				var y: float = h * l[0] - absf(sin(i * 0.65 + l[2])) * 42.0 - absf(sin(i * 1.9 + l[2])) * 10.0
				pts.append(Vector2(x, y))
			pts.append(Vector2(w, h))
			draw_colored_polygon(pts, l[1])
		for i in 4:
			var x := fmod(t * 14.0 + i * 170.0, w + 60.0) - 30.0
			var y := h * 0.22 + i * 14.0 + sin(t * 1.3 + i) * 4.0
			var f := sin(t * 6.0 + i) * 3.0
			draw_line(Vector2(x - 7, y + f), Vector2(x, y), Color(0.05, 0.02, 0.04, 0.8), 2.0)
			draw_line(Vector2(x, y), Vector2(x + 7, y + f), Color(0.05, 0.02, 0.04, 0.8), 2.0)


func _ready() -> void:
	theme = UI.make_theme()
	get_tree().paused = false
	var bg := Backdrop.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 10 vị tướng đứng dưới chân núi
	var row := Node2D.new()
	add_child(row)
	var vw := get_viewport_rect().size
	for i in HeroData.ORDER.size():
		var id: String = HeroData.ORDER[i]
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Art.frames("heroes/%s.png" % id, 32, 32, {"idle": [[0, 1, 2, 3], 3.0 + i * 0.3, true]})
		s.play("idle")
		s.scale = Vector2(1.5, 1.5)
		s.position = Vector2(vw.x * 0.5 + (i - 4.5) * 50.0, vw.y - 32)
		s.flip_h = i >= 5
		row.add_child(s)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -60
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)
	box.add_child(UI.label("ANH HÙNG ĐẤT VIỆT", 56, Color(1.0, 0.82, 0.3)))
	box.add_child(UI.label("Cùng các vị tướng Việt đánh tan giặc ngoại xâm", 18, Color(0.98, 0.88, 0.75)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	box.add_child(spacer)
	box.add_child(UI.center(UI.button("Vào doanh trại", _on_play, 22)))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		box.add_child(UI.center(UI.button("Thoát", func(): get_tree().quit(), 18)))
	box.add_child(UI.label("Xu: %d   -   Màn cao nhất: %d" % [Global.coins, Global.best_level], 16, Color(1, 0.88, 0.5)))


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
