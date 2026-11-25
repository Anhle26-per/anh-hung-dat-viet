extends Node2D
## Cổng dịch chuyển sang màn tiếp theo.

signal entered

const Art = preload("res://scripts/art/art.gd")

var label := "Cổng sang màn sau"
var mythic: bool = false
var _t := 0.0
var _used := false
var _counting: bool = false
var _countdown: float = 10.0


func _ready() -> void:
	add_to_group("portals")
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Art.strip("fx/portal.png", 44, 44, 12.0, true)
	if mythic:
		s.modulate = Color(0.86, 0.55, 1.0)
	s.play("play")
	add_child(s)
	add_child(Art.light(Color(0.76, 0.45, 1.0) if mythic else Color(0.4, 0.8, 1.0), 1.8 if mythic else 1.6, 1.4 if mythic else 1.2))
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _used or _t < 0.5:
		return
	if not Net.is_online():
		var p: Node = Global.local_player()
		if p != null and is_instance_valid(p) and not p.dead and p.global_position.distance_to(global_position) < 16.0:
			_used = true
			entered.emit()
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
			_used = true
			entered.emit()
	else:
		_counting = false
		_countdown = 10.0
		label = "Cổng sang màn sau"


func _draw() -> void:
	if mythic:
		var p: float = 0.5 + 0.5 * sin(_t * 4.2)
		draw_arc(Vector2.ZERO, 24.0 + p * 3.0, 0.0, TAU, 32, Color(0.76, 0.42, 1.0, 0.55), 1.8)
		draw_arc(Vector2.ZERO, 19.0 - p * 2.0, 0.0, TAU, 28, Color(1.0, 0.86, 0.42, 0.55), 1.2)
	Art.draw_text(self, Vector2(0, -28), label, 14, Color(0.95, 0.82, 1.0) if mythic else Color(0.8, 0.95, 1.0))
