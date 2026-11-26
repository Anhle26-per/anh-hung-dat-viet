extends StaticBody2D
## Hình nhân rơm tập võ: nhận đòn, hiện số sát thương và sát thương mỗi giây, không bao giờ chết.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var dead := false
var radius := 8.0
var _hits: Array = []   # [thời điểm, sát thương]
var _spr: AnimatedSprite2D
var _hit_t := 0.0
var _wobble_t := 0.0
var _t := 0.0
var _sway_phase := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	_sway_phase = randf() * TAU
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16.0, 24.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0.0, -6.0)
	add_child(cs)
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 7)
	sh.scale = Vector2(1.1, 0.9)
	sh.z_index = -1
	add_child(sh)
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("world/dummy.png", 20, 28, {"idle": [[0, 2, 0, 3], 3.2, true], "hit": [[1], 1.0, false]})
	_spr.position = Vector2(0, -6)
	_spr.play("idle")
	add_child(_spr)
	z_index = 1


func hurtbox_rect() -> Rect2:
	return Rect2(global_position + Vector2(-8.0, -18.0), Vector2(16.0, 24.0))


func hurtbox_center() -> Vector2:
	return global_position + Vector2(0.0, -6.0)


func closest_point_on_hurtbox(pt: Vector2) -> Vector2:
	var r: Rect2 = hurtbox_rect()
	return Vector2(clampf(pt.x, r.position.x, r.end.x), clampf(pt.y, r.position.y, r.end.y))


func distance_to_hurtbox(pt: Vector2) -> float:
	return pt.distance_to(closest_point_on_hurtbox(pt))


func is_spawning() -> bool:
	return false


func take_damage(amount: int, _knock := Vector2.ZERO) -> void:
	var p = get_tree().get_first_node_in_group("player")
	var dmg := amount
	var crit := false
	if p != null:
		dmg = int(round(amount * p.damage_mult()))
		if randf() < p.crit_chance():
			dmg *= 2
			crit = true
	_hits.append([Time.get_ticks_msec() / 1000.0, dmg])
	_hit_t = 0.2
	_wobble_t = 0.38
	_spr.play("hit")
	Sfx.play("hit_wood")
	if get_parent() != null:
		Fx.particles(get_parent(), global_position + Vector2(0, -10), Color(0.95, 0.8, 0.42), 8, 72.0, 0.42, 85.0, 1.8, 130.0, Vector2.UP, Color(0.75, 0.56, 0.24))
	Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -26), ("%d!" % dmg) if crit else str(dmg), Color(1, 0.85, 0.3) if crit else Color.WHITE, 14)


func apply_stun(_t_stun: float) -> void:
	Fx.float_text(get_parent(), global_position + Vector2(0, -36), "Choáng!", Color(1, 0.95, 0.5), 12)


func _process(delta: float) -> void:
	_t += delta
	_hit_t -= delta
	if _wobble_t > 0.0:
		_wobble_t = maxf(0.0, _wobble_t - delta)
		var damp := _wobble_t / 0.38
		_spr.rotation = sin(_t * 42.0) * 0.24 * damp
		_spr.scale = Vector2(1.0 + 0.14 * damp, 1.0 - 0.1 * damp)
	else:
		_spr.rotation = sin(_t * 2.4 + _sway_phase) * 0.045
		_spr.scale = Vector2.ONE
	if _hit_t <= 0.0 and _spr.animation == "hit":
		_spr.play("idle")
	var now := Time.get_ticks_msec() / 1000.0
	while not _hits.is_empty() and now - float(_hits[0][0]) > 3.0:
		_hits.pop_front()
	queue_redraw()


func _draw() -> void:
	var total := 0
	for h in _hits:
		total += int(h[1])
	if total > 0:
		Art.draw_text(self, Vector2(0, 22), "%.0f sát thương/giây" % (total / 3.0), 12, Color(0.7, 0.9, 1.0))
