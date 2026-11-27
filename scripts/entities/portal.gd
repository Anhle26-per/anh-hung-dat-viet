extends Node2D
## Cổng dịch chuyển sang màn tiếp theo.

signal entered
signal entered_branch(branch_kind: String)

const Art = preload("res://scripts/art/art.gd")

var label := "Cổng sang màn sau"
var mythic: bool = false
var branch_kind: String = "standard"
var portal_color: Color = Color(0, 0, 0, 0)
var subtitle: String = ""
var _base_label := ""
var _t := 0.0
var _used := false
var _counting: bool = false
var _countdown: float = 10.0


func _ready() -> void:
	add_to_group("portals")
	_base_label = label
	var has_custom_col: bool = portal_color.a > 0.01
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Art.strip("fx/portal.png", 44, 44, 12.0, true)
	if has_custom_col:
		s.modulate = portal_color
	elif mythic:
		s.modulate = Color(0.86, 0.55, 1.0)
	s.play("play")
	add_child(s)
	var light_col: Color = portal_color if has_custom_col else (Color(0.76, 0.45, 1.0) if mythic else Color(0.4, 0.8, 1.0))
	add_child(Art.light(light_col, 1.8 if (mythic or has_custom_col) else 1.6, 1.4 if (mythic or has_custom_col) else 1.2))
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _emit_enter() -> void:
	_used = true
	entered_branch.emit(branch_kind)
	entered.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _used or _t < 0.5:
		return
	if not Net.is_online():
		var p: Node = Global.local_player()
		if p != null and is_instance_valid(p) and not p.dead and p.global_position.distance_to(global_position) < 16.0:
			_emit_enter()
		return
	var living: int = 0
	var inside: int = 0
	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")) or bool(pl.get("downed")):
			continue
		living += 1
		if (pl as Node2D).global_position.distance_to(global_position) < 22.0:
			inside += 1
	var total: int = maxi(1, living)
	if inside >= 1:
		if not _counting:
			_counting = true
			_countdown = 10.0
		_countdown = maxf(_countdown - delta, 0.0)
		label = "Cổng: %d/%d (%.0fs)" % [inside, total, ceilf(_countdown)]
		if Net.is_host() and (inside >= total or _countdown <= 0.0):
			_emit_enter()
	else:
		_counting = false
		_countdown = 10.0
		label = _base_label if _base_label != "" else "Cổng sang màn sau"


func _draw() -> void:
	var has_custom_col: bool = portal_color.a > 0.01
	var p: float = 0.5 + 0.5 * sin(_t * 4.2)
	if has_custom_col:
		draw_circle(Vector2.ZERO, 20.0, Color(portal_color.r, portal_color.g, portal_color.b, 0.12 + 0.08 * p))
		draw_arc(Vector2.ZERO, 24.0 + p * 3.0, 0.0, TAU, 32, Color(portal_color.r, portal_color.g, portal_color.b, 0.68), 1.9)
		draw_arc(Vector2.ZERO, 18.0 - p * 2.0, 0.0, TAU, 28, Color(1.0, 0.96, 0.80, 0.52), 1.2)
	elif mythic:
		draw_arc(Vector2.ZERO, 24.0 + p * 3.0, 0.0, TAU, 32, Color(0.76, 0.42, 1.0, 0.55), 1.8)
		draw_arc(Vector2.ZERO, 19.0 - p * 2.0, 0.0, TAU, 28, Color(1.0, 0.86, 0.42, 0.55), 1.2)
	var lbl_col: Color = portal_color.lightened(0.35) if has_custom_col else (Color(0.95, 0.82, 1.0) if mythic else Color(0.8, 0.95, 1.0))
	Art.draw_text(self, Vector2(0, -28), label, 13 if has_custom_col else 14, lbl_col)
	if subtitle != "":
		var sub_col: Color = Color(lbl_col.r, lbl_col.g, lbl_col.b, 0.88)
		Art.draw_text(self, Vector2(0, 29), subtitle, 11, sub_col)
