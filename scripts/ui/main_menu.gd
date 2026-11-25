extends Control
## Màn hình chính.

const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
const ChallengeMenu = preload("res://scripts/ui/challenge_menu.gd")

var _settings: CanvasLayer = null
var _challenge: CanvasLayer = null


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
	Sfx.play_music("lobby")
	var bg := Backdrop.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 11 vị tướng đứng dưới chân núi
	var row := Node2D.new()
	add_child(row)
	var vw := get_viewport_rect().size
	var hero_cnt: int = HeroData.ORDER.size()
	for i in hero_cnt:
		var id: String = HeroData.ORDER[i]
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Art.frames("heroes/%s.png" % id, 32, 32, {"idle": [[0, 1, 2, 3], 3.0 + i * 0.3, true]})
		s.play("idle")
		s.scale = Vector2(1.5, 1.5)
		s.position = Vector2(vw.x * 0.5 + (i - (hero_cnt - 1) * 0.5) * 46.0, vw.y - 32)
		s.flip_h = i >= int(hero_cnt / 2)
		row.add_child(s)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -60
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	center.add_child(box)
	box.add_child(UI.label("ANH HÙNG ĐẤT VIỆT", 52, Color(1.0, 0.82, 0.3)))
	box.add_child(UI.label("Cùng các vị tướng Việt đánh tan giặc ngoại xâm", 18, Color(0.98, 0.88, 0.75)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	# Lượt chơi dở: Chơi tiếp hoặc Bỏ lượt (nhận xu đã nhặt)
	var run := Global.peek_run()
	if not run.is_empty():
		var lv: int = int(run.level)
		var hero_name: String = HeroData.DATA[str(run.hero)].name
		var stage := "%d-%d" % [EnemyData.chapter_index(lv) + 1, (lv - 1) % 3 + 1]
		box.add_child(UI.center(UI.button("Chơi tiếp (Màn %s - %s)" % [stage, hero_name], _on_continue, 20, 260.0)))
		box.add_child(UI.center(UI.button("Bỏ lượt (nhận %d xu)" % int(run.get("run_coins", 0)), _on_abandon, 15, 220.0)))
	box.add_child(UI.center(UI.button("Vào doanh trại", _on_play, 22, 240.0)))
	box.add_child(UI.center(UI.button("Thử thách & Bảng điểm", _on_challenge, 20, 240.0)))
	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 8)
	var show_quit: bool = not OS.has_feature("mobile") and not OS.has_feature("web")
	bottom_row.add_child(UI.button("Cài đặt", _on_settings, 18, 116.0 if show_quit else 240.0))
	if show_quit:
		bottom_row.add_child(UI.button("Thoát", func(): get_tree().quit(), 18, 116.0))
	box.add_child(bottom_row)
	box.add_child(UI.label("Xu: %d   -   Màn cao nhất: %d" % [Global.coins, Global.best_level], 16, Color(1, 0.88, 0.5)))
	_settings = SettingsMenu.new()
	add_child(_settings)
	_challenge = ChallengeMenu.new()
	add_child(_challenge)


func _on_continue() -> void:
	if Global.load_run():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		get_tree().reload_current_scene()


func _on_abandon() -> void:
	Global.abandon_run()
	get_tree().reload_current_scene()


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_settings() -> void:
	if _settings != null:
		_settings.open()


func _on_challenge() -> void:
	if _challenge != null:
		_challenge.open()
