extends CanvasLayer
## Điều khiển cảm ứng cho điện thoại: cần gạt nổi bên trái, các nút bên phải.
## Chỉ hiện khi Global.touch_mode = true (tự bật khi chạm màn hình).

signal pause_pressed

const WeaponData = preload("res://scripts/data/weapons.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Art = preload("res://scripts/art/art.gd")
const BASE_JOY_R := 40.0
const BASE_RADII := {"attack": 30.0, "skill": 22.0, "swap": 18.0, "pause": 13.0}

var player = null
var _joy_finger := -1
var _joy_center := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _buttons := {}
var _last_scale := 1.0


class PadView extends Node2D:
	var tc

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		tc.draw_pad(self)


func _ready() -> void:
	layer = 15
	_buttons = {
		"attack": {"r": 30.0, "finger": -1, "pos": Vector2.ZERO},
		"skill": {"r": 22.0, "finger": -1, "pos": Vector2.ZERO},
		"swap": {"r": 18.0, "finger": -1, "pos": Vector2.ZERO},
		"pause": {"r": 13.0, "finger": -1, "pos": Vector2.ZERO},
	}
	var view := PadView.new()
	view.tc = self
	add_child(view)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _scale_val() -> float:
	return float(Global.settings.get("touch_scale", 1.0))


func _joy_r() -> float:
	return BASE_JOY_R * _scale_val()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var sc := _scale_val()
	_last_scale = sc
	for id in _buttons:
		_buttons[id].r = float(BASE_RADII[id]) * sc
	_buttons.attack.pos = Vector2(s.x - 62 * sc, s.y - 62 * sc)
	_buttons.skill.pos = Vector2(s.x - 130 * sc, s.y - 38 * sc)
	_buttons.swap.pos = Vector2(s.x - 38 * sc, s.y - 128 * sc)
	_buttons.pause.pos = Vector2(s.x - 118, 20)


## Thả hết các nút (khi tạm dừng / thua) để không bị kẹt nút.
func reset() -> void:
	_joy_finger = -1
	Global.joy_vector = Vector2.ZERO
	Global.touch_attack = false
	for b in _buttons.values():
		b.finger = -1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			for id in _buttons:
				var b: Dictionary = _buttons[id]
				if b.finger == -1 and event.position.distance_to(b.pos) <= b.r * 1.35:
					b.finger = event.index
					_on_button(id, true)
					return
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.5 and _joy_finger == -1:
				_joy_finger = event.index
				_joy_center = event.position
				_joy_pos = event.position
		else:
			if event.index == _joy_finger:
				_joy_finger = -1
				Global.joy_vector = Vector2.ZERO
			for id in _buttons:
				if _buttons[id].finger == event.index:
					_buttons[id].finger = -1
					_on_button(id, false)
	elif event is InputEventScreenDrag and event.index == _joy_finger:
		_joy_pos = event.position
		var jr := _joy_r()
		var v: Vector2 = (_joy_pos - _joy_center) / jr
		if v.length() > 1.0:
			# Cần gạt đi theo ngón tay khi kéo quá xa
			v = v.normalized()
			_joy_center = _joy_pos - v * jr
		Global.joy_vector = v


func _on_button(id: String, pressed: bool) -> void:
	match id:
		"attack":
			Global.touch_attack = pressed
		"skill":
			if pressed:
				Global.touch_skill = true
		"swap":
			if pressed:
				Global.touch_swap = true
		"pause":
			if pressed:
				reset()
				pause_pressed.emit()


func draw_pad(ci: Node2D) -> void:
	if not Global.touch_mode:
		return
	if not is_equal_approx(_last_scale, _scale_val()):
		_layout()
	var s := get_viewport().get_visible_rect().size
	var ui_sc := _scale_val()
	var jr := _joy_r()
	var active := _joy_finger != -1
	var center := _joy_center if active else Vector2(80 * ui_sc, s.y - 80 * ui_sc)
	var knob := _joy_pos if active else center
	if active and knob.distance_to(center) > jr:
		knob = center + (knob - center).normalized() * jr
	ci.draw_circle(center, jr, Color(1, 1, 1, 0.10))
	ci.draw_arc(center, jr, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
	ci.draw_circle(knob, 16.0 * ui_sc, Color(1, 1, 1, 0.35 if active else 0.2))

	for id in _buttons:
		var b: Dictionary = _buttons[id]
		var pressed: bool = b.finger != -1
		ci.draw_circle(b.pos, b.r, Color(1, 1, 1, 0.32 if pressed else 0.16))
		ci.draw_arc(b.pos, b.r, 0.0, TAU, 28, Color(1, 1, 1, 0.45), 1.5)
		var text := ""
		var valid: bool = player != null and is_instance_valid(player)
		match id:
			"attack":
				if valid and player.weapons[player.slot] != "":
					var wid: String = player.weapons[player.slot]
					var tex := Art.tex("weapons/%s.png" % wid)
					var sc := minf(40.0 / tex.get_width(), 22.0 / tex.get_height())
					ci.draw_texture_rect(tex, Rect2(b.pos - Vector2(tex.get_width(), tex.get_height()) * sc / 2.0, Vector2(tex.get_width(), tex.get_height()) * sc), false)
					Art.draw_text(ci, b.pos + Vector2(0, b.r + 12), player.current_weapon().name, 13, WeaponData.tier_color(wid))
				else:
					text = "Đánh"
			"skill":
				if valid:
					var icon := Art.tex("ui/skill_%s.png" % player.hero.skill)
					ci.draw_texture_rect(icon, Rect2(b.pos - Vector2(16.5, 16.5), Vector2(33, 33)), false)
					if player.skill_timer > 0.0:
						var k: float = player.skill_timer / player.hero.skill_cd
						ci.draw_circle(b.pos, b.r - 2.0, Color(0, 0, 0, 0.55))
						ci.draw_arc(b.pos, b.r - 3.0, -PI / 2.0, -PI / 2.0 + TAU * k, 24, Color(1, 0.85, 0.4, 0.8), 3.0)
						text = "%d" % ceili(player.skill_timer)
			"swap":
				if valid and player.interact_target != null:
					text = "Dùng"
				elif valid and player.nearby_pickup != null:
					text = "Nhặt"
					ci.draw_arc(b.pos, b.r + 3.0, 0.0, TAU, 24, Color(1, 0.85, 0.3, 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)), 2.0)
				else:
					text = "Đổi"
			"pause":
				text = "II"
		if text != "":
			Art.draw_text(ci, b.pos + Vector2(0, 5), text, 16, Color.WHITE)
