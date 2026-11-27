extends StaticBody2D
## Hình nhân rơm tập võ: nhận đòn, hiện số sát thương và sát thương mỗi giây, không bao giờ chết.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const StatusFx = preload("res://scripts/effects/status_fx.gd")

const DPS_WINDOW := 3.0
const TOTAL_RESET_IDLE := 4.5
const PEAK_RESET_IDLE := 10.0

var dead := false
var radius := 8.0
var dps: float = 0.0
var peak_dps: float = 0.0
var total_dmg: int = 0
var last_hit: int = 0
var last_crit: bool = false
var status: Node2D
var _hits: Array = []   # [thời điểm, sát thương]
var _spr: AnimatedSprite2D
var _hit_t := 0.0
var _wobble_t := 0.0
var _t := 0.0
var _idle_t := 0.0
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
	status = StatusFx.new()
	status.unit = self
	status.head = 20.0
	status.tick_damage = 2
	add_child(status)
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


func _prune_hits() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while not _hits.is_empty() and now - float(_hits[0][0]) > DPS_WINDOW:
		_hits.pop_front()


func current_dps() -> float:
	_prune_hits()
	var sum := 0
	for h in _hits:
		sum += int(h[1])
	return float(sum) / DPS_WINDOW


func reset_dps() -> void:
	_hits.clear()
	dps = 0.0
	peak_dps = 0.0
	total_dmg = 0
	last_hit = 0
	last_crit = false
	_idle_t = 0.0
	if status != null and is_instance_valid(status):
		status.clear()
	queue_redraw()


func _record_damage(dmg: int, crit: bool) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_hits.append([now, dmg])
	total_dmg += dmg
	last_hit = dmg
	last_crit = crit
	_idle_t = 0.0
	dps = current_dps()
	if dps > peak_dps:
		peak_dps = dps
	queue_redraw()


func take_damage(amount: int, _knock := Vector2.ZERO) -> void:
	var p = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	var dmg := amount
	var crit := false
	if p != null:
		if p.has_method("damage_mult"):
			dmg = int(round(amount * p.damage_mult()))
		if p.has_method("crit_chance") and randf() < p.crit_chance():
			dmg *= 2
			crit = true
	dmg = maxi(1, dmg)
	_record_damage(dmg, crit)
	_hit_t = 0.2
	_wobble_t = 0.38
	if _spr != null:
		_spr.play("hit")
	Sfx.play("hit_wood")
	if get_parent() != null:
		Fx.particles(get_parent(), global_position + Vector2(0, -10), Color(0.95, 0.8, 0.42), 8, 72.0, 0.42, 85.0, 1.8, 130.0, Vector2.UP, Color(0.75, 0.56, 0.24))
		Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -26), ("%d!" % dmg) if crit else str(dmg), Color(1, 0.85, 0.3) if crit else Color.WHITE, 14)


func dot_damage(amount: int, kind: String) -> void:
	var dmg := maxi(1, amount)
	var p = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if kind == "burn" and p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("khien_lua") > 0:
		dmg = int(round(float(dmg) * 1.5))
	_record_damage(dmg, false)
	_hit_t = maxf(_hit_t, 0.12)
	_wobble_t = maxf(_wobble_t, 0.18)
	if get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -24), str(dmg), Color(1, 0.6, 0.25) if kind == "burn" else Color(0.6, 1.0, 0.35), 11)


func apply_status(kind: String, duration: float = 2.0) -> void:
	if kind == "slow":
		if get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0, -32), "Chậm!", Color(0.6, 0.9, 1.0), 11)
		return
	if status != null and is_instance_valid(status):
		status.apply(kind, duration)


func apply_stun(_t_stun: float) -> void:
	if get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0, -36), "Choáng!", Color(1, 0.95, 0.5), 12)


func _process(delta: float) -> void:
	_t += delta
	_hit_t -= delta
	_idle_t += delta
	if _wobble_t > 0.0:
		_wobble_t = maxf(0.0, _wobble_t - delta)
		var damp := _wobble_t / 0.38
		if _spr != null:
			_spr.rotation = sin(_t * 42.0) * 0.24 * damp
			_spr.scale = Vector2(1.0 + 0.14 * damp, 1.0 - 0.1 * damp)
	elif _spr != null:
		_spr.rotation = sin(_t * 2.4 + _sway_phase) * 0.045
		_spr.scale = Vector2.ONE
	if _hit_t <= 0.0 and _spr != null and _spr.animation == "hit":
		_spr.play("idle")
	dps = current_dps()
	if dps > peak_dps:
		peak_dps = dps
	if _idle_t >= TOTAL_RESET_IDLE and (total_dmg > 0 or last_hit > 0):
		total_dmg = 0
		last_hit = 0
		last_crit = false
	if _idle_t >= PEAK_RESET_IDLE and peak_dps > 0.0:
		peak_dps = 0.0
	queue_redraw()


func _dps_color(val: float) -> Color:
	if val <= 40.0:
		return Color.WHITE.lerp(Color(0.35, 0.95, 1.0), clampf(val / 40.0, 0.0, 1.0))
	if val <= 115.0:
		return Color(0.35, 0.95, 1.0).lerp(Color(1.0, 0.84, 0.24), clampf((val - 40.0) / 75.0, 0.0, 1.0))
	return Color(1.0, 0.84, 0.24).lerp(Color(1.0, 0.24, 0.28), clampf((val - 115.0) / 85.0, 0.0, 1.0))


func _draw() -> void:
	var active := dps > 0.0 or peak_dps > 0.0 or total_dmg > 0
	var line1 := "DPS: %.0f | Đỉnh: %.0f" % [dps, peak_dps]
	var line2 := ("Tổng: %d (%d!)" % [total_dmg, last_hit]) if (last_crit and last_hit > 0 and _idle_t < 1.2) else ("Tổng: %d" % total_dmg)
	var pw := clampf(maxf(78.0, Art.text_width(line1, 10) + 10.0), 78.0, 96.0)
	var ph := 28.0
	var top_y := 11.0
	var rect := Rect2(-pw * 0.5, top_y, pw, ph)
	var tier_col := _dps_color(maxf(dps, peak_dps * 0.4)) if active else Color(0.55, 0.58, 0.65)

	# Khung bảng đo DPS gọn bên dưới hình nhân
	var bg_a := 0.86 if active else 0.58
	draw_rect(rect, Color(0.06, 0.04, 0.09, bg_a))
	var brd_a := (0.78 + 0.16 * sin(_t * 6.0)) if dps > 0.0 else (0.48 if active else 0.30)
	draw_rect(rect, Color(tier_col.r, tier_col.g, tier_col.b, brd_a), false, 1.0)

	var l1_col := _dps_color(dps) if active else Color(0.72, 0.75, 0.80, 0.78)
	var l2_col := Color(1.0, 0.92, 0.62) if (last_crit and _idle_t < 1.0) else (Color(0.84, 0.90, 0.98) if active else Color(0.62, 0.66, 0.74, 0.70))
	Art.draw_text(self, Vector2(0, top_y + 9.0), line1, 10, l1_col)
	Art.draw_text(self, Vector2(0, top_y + 19.0), line2, 10, l2_col)

	# Thanh năng lượng DPS phát sáng (trắng -> lam -> vàng -> đỏ thẫm tới 200+ DPS)
	var bar_w := pw - 10.0
	var bar_rect := Rect2(-bar_w * 0.5, top_y + 22.0, bar_w, 3.5)
	draw_rect(bar_rect, Color(0.14, 0.12, 0.20, 0.9))
	var fill := clampf(dps / 200.0, 0.0, 1.0)
	if fill > 0.0:
		var fw := maxf(2.0, bar_w * fill)
		var bar_col := _dps_color(dps)
		var pulse := 0.85 + 0.15 * sin(_t * 9.0) if dps >= 160.0 else 1.0
		draw_rect(Rect2(bar_rect.position.x - 1.0, bar_rect.position.y - 1.0, fw + 2.0, bar_rect.size.y + 2.0), Color(bar_col.r, bar_col.g, bar_col.b, 0.26 * pulse))
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, fw, bar_rect.size.y), Color(bar_col.r, bar_col.g, bar_col.b, 0.96))
		draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y, fw, 1.0), Color(1.0, 1.0, 1.0, 0.55))
