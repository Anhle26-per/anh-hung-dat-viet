extends StaticBody2D
## Hình nhân rơm tập võ: nhận đòn, hiện số sát thương và sát thương mỗi giây, không bao giờ chết.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var dead := false
var radius := 8.0
var _hits: Array = []   # [thời điểm, sát thương]
var _spr: AnimatedSprite2D
var _hit_t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("world/dummy.png", 20, 28, {"idle": [[0], 1.0, false], "hit": [[1], 1.0, false]})
	_spr.position = Vector2(0, -6)
	add_child(_spr)
	z_index = 1


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
	_hit_t = 0.12
	_spr.play("hit")
	Sfx.play("hit_wood")
	Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -26), ("%d!" % dmg) if crit else str(dmg), Color(1, 0.85, 0.3) if crit else Color.WHITE, 14)


func apply_stun(_t: float) -> void:
	Fx.float_text(get_parent(), global_position + Vector2(0, -36), "Choáng!", Color(1, 0.95, 0.5), 12)


func _process(delta: float) -> void:
	_hit_t -= delta
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
