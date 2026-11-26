extends Node2D
## Địa hình & Bẫy chiến trường theo chương lịch sử:
##   1) Sông nước: water_zone (làm chậm địch), bach_dang_stake (cọc đâm/làm chậm địch & chặn đạn)
##   2) Núi rừng / Sương mù: stealth_bush (ẩn thân +tỉ lệ chí mạng / giảm aggro), falling_boulder (đá lở)
##   3) Tết / Thành cổ: fire_brazier (châm lửa đạn người chơi bay qua)
##   4) Điện Biên Phủ: trench (chiến hào giảm sát thương/né đạn), mortar_flare (pháo kích cảnh báo -> nổ)

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var kind: String = "water_zone"
var room = null
var size: Vector2 = Vector2(78, 42)
var radius: float = 20.0
var phase_offset: float = 0.0

var _t: float = 0.0
var _phase: int = 0          # cho falling_boulder / mortar_flare: 0=nghỉ, 1=cảnh báo, 2=nổ
var _stake_cd: float = 0.0
var _slowed_enemies: Dictionary = {}


func _ready() -> void:
	add_to_group("battlefield_hazards")
	z_index = 0 if kind in ["water_zone", "trench", "falling_boulder", "mortar_flare"] else 1
	_t = phase_offset
	if kind == "stealth_bush":
		radius = 24.0
	elif kind == "fire_brazier":
		radius = 18.0
		var l := Art.light(Color(1.0, 0.58, 0.22), 1.25, 0.85)
		l.position = Vector2(0, -6)
		add_child(l)
	elif kind == "bach_dang_stake":
		radius = 15.0
	elif kind == "falling_boulder":
		radius = 26.0
	elif kind == "mortar_flare":
		radius = 28.0


func _exit_tree() -> void:
	if kind == "stealth_bush":
		_sync_player_stealth(false)
	elif kind == "trench":
		_sync_player_trench(false)
	elif kind == "water_zone":
		_sync_player_water(false)
	for eid in _slowed_enemies.keys():
		var e: Variant = instance_from_id(int(eid))
		if e != null and is_instance_valid(e):
			_restore_enemy_speed(e as Node)
	_slowed_enemies.clear()


func _process(delta: float) -> void:
	_t += delta
	_stake_cd = maxf(0.0, _stake_cd - delta)
	match kind:
		"water_zone":
			_tick_water_zone()
		"bach_dang_stake":
			_tick_stake()
		"stealth_bush":
			_tick_stealth_bush()
		"falling_boulder":
			_tick_periodic_strike(4.2, 1.15, true)
		"fire_brazier":
			_tick_fire_brazier()
		"trench":
			_tick_trench()
		"mortar_flare":
			_tick_periodic_strike(4.6, 1.25, false)
	queue_redraw()


func _contains_point_rect(pos: Vector2) -> bool:
	var local_p: Vector2 = pos - global_position
	return absf(local_p.x) <= size.x * 0.5 and absf(local_p.y) <= size.y * 0.5


func _tick_water_zone() -> void:
	var p: Node = Global.local_player()
	if p != null and is_instance_valid(p) and not bool(p.get("dead")):
		_sync_player_water(_contains_point_rect((p as Node2D).global_position))
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var inside: bool = _contains_point_rect((e as Node2D).global_position)
		if e.has_method("apply_hazard_slow"):
			if inside:
				e.apply_hazard_slow(0.65, 0.25)
			continue
		var eid: int = e.get_instance_id()
		if inside and not _slowed_enemies.has(eid):
			var spd: float = float(e.get("speed"))
			var cut: float = spd * 0.30
			_slowed_enemies[eid] = cut
			e.set("speed", maxf(12.0, spd - cut))
		elif not inside and _slowed_enemies.has(eid):
			_restore_enemy_speed(e)
			_slowed_enemies.erase(eid)


func _sync_player_water(inside: bool) -> void:
	var p: Node = Global.local_player() if is_inside_tree() else null
	if p == null or not is_instance_valid(p):
		return
	if inside:
		p.set("in_water", true)
		return
	var any_other: bool = false
	if is_inside_tree():
		for h in get_tree().get_nodes_in_group("battlefield_hazards"):
			if h != self and is_instance_valid(h) and str(h.get("kind")) == "water_zone":
				if h.has_method("_contains_point_rect") and h._contains_point_rect((p as Node2D).global_position):
					any_other = true
					break
	if not any_other:
		p.set("in_water", false)


func _restore_enemy_speed(e: Node) -> void:
	var eid: int = e.get_instance_id()
	if _slowed_enemies.has(eid):
		var cut: float = float(_slowed_enemies[eid])
		e.set("speed", float(e.get("speed")) + cut)


func _tick_stake() -> void:
	if is_inside_tree():
		for b in get_tree().get_nodes_in_group("enemy_bullets"):
			if is_instance_valid(b) and (b as Node2D).global_position.distance_to(global_position) <= 10.0:
				if b.has_method("destroy"):
					b.destroy()
	if _stake_cd > 0.0:
		return
	var hit_any: bool = false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		if e.has_method("is_spawning") and e.is_spawning():
			continue
		var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else ((e as Node2D).global_position.distance_to(global_position) - float(e.get("radius")) * 0.5)
		if dist_e <= radius:
			hit_any = true
			if not Net.is_online() or Net.is_host():
				var knock_v: Vector2 = ((e as Node2D).global_position - global_position).normalized() * 120.0
				if e.has_method("apply_hazard_damage"):
					e.apply_hazard_damage(4, knock_v)
				else:
					e.take_damage(4, knock_v)
				if is_instance_valid(e) and not bool(e.get("dead")) and e.has_method("apply_status"):
					e.apply_status("slow", 1.2)
			if get_parent() != null:
				Fx.particles(get_parent(), global_position + Vector2(0, -4), Color(0.65, 0.88, 1.0), 4, 45.0, 0.3)
	if hit_any:
		_stake_cd = 0.65


func _tick_stealth_bush() -> void:
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p) or bool(p.get("dead")):
		return
	var inside: bool = (p as Node2D).global_position.distance_to(global_position) <= radius
	_sync_player_stealth(inside)


func _sync_player_stealth(inside: bool) -> void:
	var p: Node = Global.local_player() if is_inside_tree() else null
	if p == null or not is_instance_valid(p):
		return
	if inside:
		p.set("in_stealth_bush", true)
		return
	var any_other: bool = false
	if is_inside_tree():
		for h in get_tree().get_nodes_in_group("battlefield_hazards"):
			if h != self and is_instance_valid(h) and str(h.get("kind")) == "stealth_bush":
				if (p as Node2D).global_position.distance_to((h as Node2D).global_position) <= float(h.get("radius")):
					any_other = true
					break
	if not any_other:
		p.set("in_stealth_bush", false)


func _tick_trench() -> void:
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p) or bool(p.get("dead")):
		return
	var inside: bool = _contains_point_rect((p as Node2D).global_position)
	_sync_player_trench(inside)


func _sync_player_trench(inside: bool) -> void:
	var p: Node = Global.local_player() if is_inside_tree() else null
	if p == null or not is_instance_valid(p):
		return
	if inside:
		p.set("in_trench", true)
		return
	var any_other: bool = false
	if is_inside_tree():
		for h in get_tree().get_nodes_in_group("battlefield_hazards"):
			if h != self and is_instance_valid(h) and str(h.get("kind")) == "trench":
				if h.has_method("_contains_point_rect") and h._contains_point_rect((p as Node2D).global_position):
					any_other = true
					break
	if not any_other:
		p.set("in_trench", false)


func _tick_fire_brazier() -> void:
	if not is_inside_tree():
		return
	for b in get_tree().get_nodes_in_group("player_bullets"):
		if not is_instance_valid(b) or b.has_meta("brazier_ignited"):
			continue
		if (b as Node2D).global_position.distance_to(global_position) <= radius + 4.0:
			b.set_meta("brazier_ignited", true)
			if b.has_method("ignite_fire"):
				b.ignite_fire()
			else:
				b.set("force_burn", true)
				if "fire_ignited" in b:
					b.set("fire_ignited", true)
				b.set("damage", maxi(1, int(round(float(b.get("damage")) * 1.25))))
				b.set("color", Color(1.0, 0.58, 0.2))
				var spr: Variant = b.get("_spr")
				if spr is CanvasItem:
					(spr as CanvasItem).modulate = Color(1.0, 0.62, 0.22)
				if get_parent() != null:
					Fx.particles(get_parent(), (b as Node2D).global_position, Color(1.0, 0.55, 0.18), 4, 48.0, 0.25)


func _tick_periodic_strike(period: float, warn_dur: float, is_boulder: bool) -> void:
	var fighting: bool = room == null or not is_instance_valid(room) or str(room.get("state")) == "fighting"
	if not fighting:
		_phase = 0
		return
	var cyc: float = fmod(_t, period)
	var warn_start: float = period - warn_dur - 0.15
	var prev_phase: int = _phase
	if cyc < warn_start:
		_phase = 0
	elif cyc < period - 0.15:
		_phase = 1
	else:
		_phase = 2
	if _phase == 2 and prev_phase != 2:
		trigger_strike(is_boulder)


func trigger_strike(is_boulder: bool = (kind == "falling_boulder")) -> void:
	var par: Node = get_parent() if get_parent() != null else self
	if is_boulder:
		Fx.anim(par, global_position, "fx/dust.png", 10, 10, 14.0, 2.4)
		Fx.particles(par, global_position, Color(0.62, 0.56, 0.48), 12, 100.0, 0.45, -35.0, 2.2)
		Fx.shake(get_tree(), 3.2)
		Sfx.play("hit_wall")
	else:
		Fx.anim(par, global_position, "fx/explosion.png", 44, 44, 18.0, radius / 20.0)
		Fx.particles(par, global_position, Color(1.0, 0.65, 0.28), 14, 115.0, 0.5, -45.0, 2.2)
		Fx.shake(get_tree(), 3.8)
		Sfx.play("explode")

	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")) or bool(pl.get("downed")):
			continue
		if (pl as Node2D).global_position.distance_to(global_position) <= radius:
			pl.take_damage(1, "Đá lở" if is_boulder else "Pháo kích")

	if not Net.is_online() or Net.is_host():
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or bool(e.get("dead")):
				continue
			if e.has_method("is_spawning") and e.is_spawning():
				continue
			var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else ((e as Node2D).global_position.distance_to(global_position) - float(e.get("radius")) * 0.5)
			if dist_e <= radius + 4.0:
				e.take_damage(10 if is_boulder else 12, ((e as Node2D).global_position - global_position).normalized() * 140.0)
				if is_boulder and is_instance_valid(e) and not bool(e.get("dead")) and e.has_method("apply_stun"):
					e.apply_stun(0.75)


func _draw() -> void:
	match kind:
		"water_zone":
			var hw: float = size.x * 0.5
			var hh: float = size.y * 0.5
			draw_rect(Rect2(-hw, -hh, size.x, size.y), Color(0.14, 0.42, 0.68, 0.44))
			draw_rect(Rect2(-hw, -hh, size.x, size.y), Color(0.45, 0.78, 0.96, 0.55), false, 1.4)
			for i in 4:
				var wy: float = -hh + 8.0 + float(i) * (size.y - 14.0) / 3.0
				var wx: float = sin(_t * 2.2 + float(i) * 1.4) * 8.0
				draw_line(Vector2(-hw * 0.6 + wx, wy), Vector2(hw * 0.5 + wx, wy), Color(0.72, 0.92, 1.0, 0.42), 1.4)
		"bach_dang_stake":
			draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 10.0 + sin(_t * 3.0) * 1.5, 0.0, TAU, 16, Color(0.6, 0.86, 1.0, 0.5), 1.2)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_polygon(PackedVector2Array([Vector2(-4, 4), Vector2(4, 4), Vector2(1, -15), Vector2(-1, -15)]), PackedColorArray([Color("4e3422"), Color("6c4a32"), Color("b0bec5"), Color("e2ecf4")]))
			draw_polygon(PackedVector2Array([Vector2(-2.2, -11), Vector2(2.2, -11), Vector2(0, -19)]), PackedColorArray([Color("8898a8"), Color("b8c8d8"), Color("ffffff")]))
		"stealth_bush":
			draw_circle(Vector2(-6, 2), 11.0, Color(0.10, 0.34, 0.14, 0.85))
			draw_circle(Vector2(7, 2), 10.0, Color(0.12, 0.38, 0.16, 0.85))
			draw_circle(Vector2(0, -4), 12.0, Color(0.16, 0.48, 0.22, 0.88))
			draw_circle(Vector2(-3, -6), 5.0, Color(0.32, 0.68, 0.32, 0.55))
			var p: Node = Global.local_player() if is_inside_tree() else null
			if p != null and is_instance_valid(p) and (p as Node2D).global_position.distance_to(global_position) <= radius:
				draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.55, 0.96, 0.62, 0.65), 1.3)
		"falling_boulder":
			draw_circle(Vector2(0, 2), 10.0, Color(0.24, 0.20, 0.18, 0.35))
			if _phase == 1:
				var a: float = 0.5 + 0.35 * sin(_t * 22.0)
				draw_circle(Vector2.ZERO, radius, Color(0.95, 0.42, 0.2, 0.16))
				draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.52, 0.22, a), 1.8)
				draw_circle(Vector2(0, -20.0 + sin(_t * 10.0) * 2.0), 8.0, Color("6c625a"))
			elif _phase == 2:
				draw_circle(Vector2.ZERO, radius, Color(0.82, 0.68, 0.48, 0.45))
				draw_circle(Vector2(0, -3), 11.0, Color("5a524a"))
		"fire_brazier":
			draw_rect(Rect2(-9, -2, 18, 8), Color("4e3e34"))
			draw_rect(Rect2(-11, -7, 22, 6), Color("88683a"))
			var f: float = sin(_t * 14.0) * 2.0
			draw_circle(Vector2(0, -10), 8.5, Color(1.0, 0.45, 0.12, 0.55))
			draw_polygon(PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(f * 0.5, -20)]), PackedColorArray([Color("ff5a1c"), Color("ff9e2c"), Color("fff28a")]))
			draw_arc(Vector2(0, -4), radius, 0.0, TAU, 24, Color(1.0, 0.58, 0.2, 0.25), 1.1)
		"trench":
			var hw2: float = size.x * 0.5
			var hh2: float = size.y * 0.5
			draw_rect(Rect2(-hw2, -hh2, size.x, size.y), Color("281f16"))
			draw_rect(Rect2(-hw2 + 3, -hh2 + 3, size.x - 6, size.y - 6), Color("1b150e"))
			var sx: float = -hw2 + 6.0
			while sx < hw2 - 6.0:
				draw_rect(Rect2(sx, -hh2 - 3, 12, 5), Color("8a7652"))
				draw_rect(Rect2(sx, hh2 - 2, 12, 5), Color("7a6848"))
				sx += 14.0
		"mortar_flare":
			draw_circle(Vector2.ZERO, 8.0, Color(0.32, 0.28, 0.24, 0.35))
			if _phase == 1:
				var a2: float = 0.55 + 0.35 * sin(_t * 26.0)
				draw_circle(Vector2.ZERO, radius, Color(1.0, 0.28, 0.22, 0.16))
				draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.38, 0.28, a2), 1.8)
				draw_line(Vector2(-6, 0), Vector2(6, 0), Color(1.0, 0.85, 0.5, a2), 1.4)
				draw_line(Vector2(0, -6), Vector2(0, 6), Color(1.0, 0.85, 0.5, a2), 1.4)
			elif _phase == 2:
				draw_circle(Vector2.ZERO, radius, Color(1.0, 0.55, 0.22, 0.55))
