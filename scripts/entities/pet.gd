extends CharacterBody2D
## Linh thú đồng hành theo người chơi vào hầm ngục (Cún Vàng, Mèo Tam Thể, Gà Trống Chọi, Chim Hạc Trắng).

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const CampNpcs = preload("res://scripts/data/camp_npcs.gd")

var pet_id: String = "dog"
var owner_player: Node = null
var in_lobby: bool = false
var awakened: bool = false
var _spr: AnimatedSprite2D
var _atk_cd: float = 0.0
var _support_cd: float = 6.0
var _t: float = 0.0
var _lunge: float = 0.0
var _blink_timer: float = 2.6
var _blink_pulse: float = 0.0
var _happy_t: float = 0.0
var _lobby_happy_cd: float = 3.6
var _dust_t: float = 0.0
var _sparkle_t: float = 0.9
var _base_spr_y: float = -6.0


func setup(id: String, owner: Node) -> void:
	pet_id = id if Global.PETS.has(id) else "dog"
	owner_player = owner


func _check_awakened() -> bool:
	if awakened:
		return true
	if _is_remote_pet():
		return bool(owner_player.get("pet_awakened")) or bool(owner_player.get("awakened"))
	if Global != null and Global.has_method("is_pet_awakened"):
		return bool(Global.is_pet_awakened(pet_id))
	return false


func _ready() -> void:
	add_to_group("allies")
	add_to_group("pets")
	collision_layer = 8
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	z_index = 2

	awakened = _check_awakened()

	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 6)
	sh.z_index = -1
	add_child(sh)

	_spr = AnimatedSprite2D.new()
	var evo_info: Dictionary = CampNpcs.AWAKENED_PETS.get(pet_id, {})
	var evo_sprite: String = str(evo_info.get("sprite", ""))
	var use_evo: bool = awakened and evo_sprite != "" and ResourceLoader.exists("res://assets/sprites/" + evo_sprite)
	var spr_path: String = evo_sprite if use_evo else ""
	match pet_id:
		"cat":
			var fw_c: int = int(evo_info.get("fw", 26)) if use_evo else 24
			var fh_c: int = int(evo_info.get("fh", 22)) if use_evo else 20
			_spr.sprite_frames = Art.frames(spr_path if use_evo else "world/animal_cat.png", fw_c, fh_c, {
				"walk": [[0, 1, 2], 7.0, true],
				"idle": [[0, 0, 1, 2], 3.0, true],
			})
			_spr.position = Vector2(0, -6 if use_evo else -5)
		"rooster":
			var fw_r: int = int(evo_info.get("fw", 26)) if use_evo else 24
			var fh_r: int = int(evo_info.get("fh", 26)) if use_evo else 24
			_spr.sprite_frames = Art.frames(spr_path if use_evo else "world/animal_rooster.png", fw_r, fh_r, {
				"walk": [[0, 1], 9.0, true],
				"idle": [[2, 0], 4.0, true],
			})
			_spr.position = Vector2(0, -8 if use_evo else -7)
		"crane":
			var fw_cr: int = int(evo_info.get("fw", 28)) if use_evo else 26
			var fh_cr: int = int(evo_info.get("fh", 36)) if use_evo else 34
			_spr.sprite_frames = Art.frames(spr_path if use_evo else "world/animal_crane.png", fw_cr, fh_cr, {
				"walk": [[0, 1, 2, 3], 5.0, true],
				"idle": [[0, 0, 1, 0, 2, 0, 3], 3.0, true],
			})
			_spr.position = Vector2(0, -13 if use_evo else -12)
		_:
			var fw_d: int = int(evo_info.get("fw", 28)) if use_evo else 26
			var fh_d: int = int(evo_info.get("fh", 24)) if use_evo else 22
			_spr.sprite_frames = Art.frames(spr_path if use_evo else "world/animal_dog.png", fw_d, fh_d, {
				"walk": [[0, 1], 8.0, true],
				"idle": [[2, 3], 4.0, true],
			})
			_spr.position = Vector2(0, -7 if use_evo else -6)
	_spr.play("idle")
	_base_spr_y = _spr.position.y
	add_child(_spr)


func trigger_happy(dur: float = 2.2) -> void:
	_happy_t = maxf(_happy_t, dur)
	if get_parent() != null:
		Fx.particles(get_parent(), global_position + Vector2(0, -10), Color(1.0, 0.72, 0.86), 8, 46.0, 0.5, -20.0, 1.5)
	queue_redraw()


func _is_remote_pet() -> bool:
	return Net != null and Net.is_online() and owner_player != null and is_instance_valid(owner_player) and not bool(owner_player.get("is_local"))


func _physics_process(delta: float) -> void:
	_t += delta
	_atk_cd = maxf(0.0, _atk_cd - delta)
	_support_cd = maxf(0.0, _support_cd - delta)
	_lunge = move_toward(_lunge, 0.0, delta * 36.0)
	_dust_t = maxf(0.0, _dust_t - delta)
	_sparkle_t -= delta

	# Chớp mắt định kỳ sinh động
	if _blink_pulse > 0.0:
		_blink_pulse = maxf(0.0, _blink_pulse - delta)
	else:
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			_blink_timer = randf_range(2.4, 4.2)
			_blink_pulse = 0.11

	if owner_player == null or not is_instance_valid(owner_player):
		owner_player = Global.local_player()
	if owner_player == null or not is_instance_valid(owner_player) or bool(owner_player.get("dead")):
		return

	if in_lobby:
		visible = bool(owner_player.get("visible"))
		if not visible:
			velocity = Vector2.ZERO
			return

	var owner_pos: Vector2 = (owner_player as Node2D).global_position
	if global_position.distance_to(owner_pos) > 260.0:
		global_position = owner_pos + Vector2(-18.0, 12.0)

	var remote_pet: bool = _is_remote_pet()

	# Hỗ trợ định kỳ của Gà Trống (+15 năng lượng mỗi 12s; Thức tỉnh: +30 khí + tăng tốc đánh 3s mỗi 10s)
	# và Chim Hạc (+1 giáp mỗi 16s; Thức tỉnh: xóa đạn quanh chủ +2 giáp mỗi 12s)
	if not in_lobby and not remote_pet:
		var evo_cfg: Dictionary = CampNpcs.AWAKENED_PETS.get(pet_id, {}) if awakened else {}
		if pet_id == "rooster" and _support_cd <= 0.0:
			var need_energy: bool = int(owner_player.get("energy")) < int(owner_player.get("max_energy"))
			if awakened and (_has_active_enemy() or need_energy):
				_support_cd = float(evo_cfg.get("support_cd", 10.0))
				var egain: int = int(evo_cfg.get("energy_gain", 30))
				if owner_player.has_method("add_energy"):
					owner_player.add_energy(egain)
				var hdur: float = float(evo_cfg.get("haste_dur", 3.0))
				owner_player.set("_frenzy_timer", maxf(float(owner_player.get("_frenzy_timer")), hdur))
				Fx.float_text(get_parent(), global_position + Vector2(0, -14), "Ò ó o! +%d khí & Tốc đánh!" % egain, Color(1.0, 0.88, 0.30), 11)
				Fx.particles(get_parent(), global_position, Color(1.0, 0.78, 0.25), 10, 48.0, 0.5, -22.0, 1.9)
			elif not awakened and need_energy:
				_support_cd = 12.0
				if owner_player.has_method("add_energy"):
					owner_player.add_energy(15)
				Fx.float_text(get_parent(), global_position + Vector2(0, -14), "Ò ó o! +15 khí", Color(1.0, 0.86, 0.35), 11)
				Fx.particles(get_parent(), global_position, Color(1.0, 0.8, 0.35), 8, 42.0, 0.45, -20.0, 1.8)
		elif pet_id == "crane" and _support_cd <= 0.0:
			var cur_arm: int = int(owner_player.get("armor"))
			var max_arm: int = int(owner_player.get("max_armor"))
			if awakened and _has_active_enemy():
				var clear_r: float = float(evo_cfg.get("clear_radius", 95.0))
				var cleared: int = _clear_enemy_bullets_near(owner_pos, clear_r)
				if cur_arm < max_arm or cleared > 0:
					_support_cd = float(evo_cfg.get("support_cd", 12.0))
					var again: int = int(evo_cfg.get("armor_gain", 2))
					owner_player.set("armor", mini(max_arm, cur_arm + again))
					if owner_player.has_signal("stats_changed"):
						owner_player.stats_changed.emit()
					var msg: String = "Lạc Điểu +%d Giáp & Xóa Đạn!" % again if cleared > 0 else "Lạc Điểu +%d Giáp!" % again
					Fx.burst(get_parent(), owner_pos, Color(0.55, 0.94, 1.0), clear_r * 0.65, 0.35)
					Fx.float_text(get_parent(), global_position + Vector2(0, -16), msg, Color(0.62, 0.96, 1.0), 11)
					Fx.particles(get_parent(), global_position, Color(0.62, 0.95, 1.0), 12, 52.0, 0.55, -24.0, 1.9)
			elif not awakened and _has_active_enemy() and cur_arm < max_arm:
				_support_cd = 16.0
				owner_player.set("armor", mini(max_arm, cur_arm + 1))
				if owner_player.has_signal("stats_changed"):
					owner_player.stats_changed.emit()
				Fx.float_text(get_parent(), global_position + Vector2(0, -16), "+1 Giáp Hạc", Color(0.62, 0.95, 1.0), 11)
				Fx.particles(get_parent(), global_position, Color(0.62, 0.95, 1.0), 10, 46.0, 0.5, -24.0, 1.8)

	velocity = Vector2.ZERO
	var did_action: bool = false

	# 1. Cún Vàng ưu tiên chạy nhặt xu / tinh thể / nguyên liệu rơi quanh chủ (không chạy trong sảnh)
	if not in_lobby and not remote_pet and pet_id == "dog":
		var pk: Node2D = _find_pickup(owner_pos)
		if pk != null:
			did_action = true
			var to_pk: Vector2 = pk.global_position - global_position
			_spr.flip_h = to_pk.x < 0.0
			if to_pk.length() < 16.0:
				if pk.has_method("_collect") and not bool(pk.get("_net_claimed_by_other")):
					pk._collect(owner_player)
			else:
				var pk_spd: float = float(CampNpcs.AWAKENED_PETS["dog"].get("move_speed", 188.0)) if awakened else 155.0
				velocity = to_pk.normalized() * pk_spd

	# 2. Cún / Mèo / Gà Trống lao vào đánh giặc gần chủ (trong sảnh không đánh hình nhân / địch)
	if not in_lobby and not remote_pet and not did_action and pet_id != "crane":
		var target = _find_enemy(owner_pos)
		if target != null:
			did_action = true
			var tpos: Vector2 = target.hurtbox_center() if target.has_method("hurtbox_center") else target.global_position
			var to_e: Vector2 = tpos - global_position
			_spr.flip_h = to_e.x < 0.0
			var dist_hb: float = target.distance_to_hurtbox(global_position) if target.has_method("distance_to_hurtbox") else (to_e.length() - float(target.get("radius")))
			if dist_hb < (20.0 if awakened else 16.0):
				if _atk_cd <= 0.0:
					_attack_enemy(target, to_e.normalized())
			else:
				var spd: float = 148.0 if pet_id == "rooster" else (140.0 if pet_id == "cat" else 132.0)
				if awakened:
					spd += 16.0
				velocity = to_e.normalized() * spd

	# 3. Nếu rảnh (hoặc Chim Hạc / đang ở sảnh): theo sát bên chủ
	if not did_action:
		var anchor: Vector2 = owner_pos + (Vector2(-24.0, -10.0) if pet_id == "crane" else Vector2(-20.0, 10.0))
		var to_p: Vector2 = anchor - global_position
		var keep_dist: float = 10.0 if pet_id == "crane" else 14.0
		if to_p.length() > keep_dist:
			velocity = to_p.normalized() * (135.0 if to_p.length() > 80.0 else 108.0)
			_spr.flip_h = to_p.x < 0.0

	var moving: bool = velocity.length() > 4.0
	if moving:
		if _spr.animation != "walk":
			_spr.play("walk")
		if pet_id != "crane" and _dust_t <= 0.0 and get_parent() != null:
			_dust_t = 0.28
			Fx.anim(get_parent(), global_position + Vector2(0, 6), "fx/dust.png", 10, 10, 14.0, 0.55, 0.0, Color(0.95, 0.9, 0.82, 0.45))
	else:
		if _spr.animation != "idle":
			_spr.play("idle")
		if in_lobby:
			_lobby_happy_cd -= delta
			if _lobby_happy_cd <= 0.0:
				_lobby_happy_cd = randf_range(4.2, 7.0)
				_happy_t = maxf(_happy_t, 1.8)

	if _happy_t > 0.0:
		_happy_t = maxf(0.0, _happy_t - delta)

	if _sparkle_t <= 0.0:
		_sparkle_t = randf_range(1.1, 2.0) if in_lobby else randf_range(1.8, 3.0)
		if get_parent() != null and visible:
			var pcol: Color = CampNpcs.AWAKENED_PETS.get(pet_id, {}).get("color", Color(1.0, 0.9, 0.4)) if awakened else Global.PETS.get(pet_id, {}).get("color", Color(1.0, 0.9, 0.5))
			Fx.particles(get_parent(), global_position + Vector2(randf_range(-6.0, 6.0), -6.0), pcol, 3 if awakened else 2, 24.0, 0.45, -18.0, 1.3)

	# Nhảy nhót & co giãn sinh động (squash-stretch + chớp mắt + bay lượn)
	var bob_y: float = 0.0
	var sx: float = 1.0
	var sy: float = 1.0
	if pet_id == "crane":
		bob_y = sin(_t * 4.5) * 3.0
		sx = 1.0 + sin(_t * 4.5) * 0.04
		sy = 1.0 - sin(_t * 4.5) * 0.04
	elif moving:
		var hop: float = absf(sin(_t * 14.0))
		bob_y = -hop * 3.2
		sx = 1.0 + (0.5 - hop) * 0.14
		sy = 1.0 - (0.5 - hop) * 0.12
	else:
		var breath: float = sin(_t * 4.2)
		sx = 1.0 - breath * 0.04
		sy = 1.0 + breath * 0.045
		if _happy_t > 0.0:
			bob_y = -absf(sin(_t * 12.0)) * 4.2
			sx += 0.06 * sin(_t * 15.0)
			sy -= 0.05 * sin(_t * 15.0)
	if _blink_pulse > 0.0:
		sy *= 0.80
		sx *= 1.06
	_spr.scale = Vector2(sx, sy)
	_spr.position.y = _base_spr_y + bob_y
	_spr.position.x = _lunge * (-1.0 if _spr.flip_h else 1.0)
	move_and_slide()
	if _happy_t > 0.0 or in_lobby or awakened:
		queue_redraw()


func _draw_heart(pos: Vector2, sz: float, col: Color) -> void:
	var r: float = sz * 0.36
	draw_circle(pos + Vector2(-r * 0.85, -r * 0.2), r, col)
	draw_circle(pos + Vector2(r * 0.85, -r * 0.2), r, col)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-r * 1.72, 0.0),
		pos + Vector2(r * 1.72, 0.0),
		pos + Vector2(0.0, sz * 0.95),
	]), col)


func _draw() -> void:
	if awakened:
		var aura_col: Color = CampNpcs.AWAKENED_PETS.get(pet_id, {}).get("color", Color(1.0, 0.85, 0.30))
		var pulse: float = 0.42 + 0.18 * sin(_t * 3.6)
		var ring_r: float = 12.5 + sin(_t * 4.0) * 1.0
		draw_circle(Vector2(0, 4), ring_r, Color(aura_col.r, aura_col.g, aura_col.b, 0.10 * pulse))
		draw_arc(Vector2(0, 4), ring_r, 0.0, TAU, 24, Color(1.0, 0.86, 0.32, pulse), 1.4)
		for mi in 2:
			var ang: float = _t * 2.6 + float(mi) * PI
			draw_circle(Vector2(cos(ang) * (ring_r + 1.5), 4.0 + sin(ang) * 4.5), 1.4, Color(1.0, 0.94, 0.55, 0.8))

	if _happy_t > 0.0:
		var fade: float = clampf(_happy_t * 1.4, 0.0, 1.0)
		for hi in 2:
			var phase: float = fmod(_t * 0.9 + float(hi) * 0.5, 1.0)
			var hx: float = sin(_t * 3.2 + float(hi) * 2.0) * 7.0 + float(hi - 0.5) * 6.0
			var hy: float = -18.0 - phase * 16.0
			_draw_heart(Vector2(hx, hy), 4.6, Color(1.0, 0.45, 0.72, fade * sin(phase * PI)))
		draw_circle(Vector2(cos(_t * 4.0) * 11.0, -14.0), 1.6, Color(1.0, 0.92, 0.45, 0.85 * fade))
	elif in_lobby:
		var sp_a: float = 0.35 + 0.35 * sin(_t * 3.5)
		draw_circle(Vector2(sin(_t * 2.3) * 9.0, -15.0 + cos(_t * 3.1) * 3.0), 1.3, Color(1.0, 0.92, 0.55, sp_a))


func _attack_enemy(e: Node, dir: Vector2) -> void:
	_lunge = 5.0
	if awakened:
		var evo: Dictionary = CampNpcs.AWAKENED_PETS.get(pet_id, {})
		var dmg: int = int(evo.get("dmg", 8))
		_atk_cd = float(evo.get("atk_cd", 0.75))
		match pet_id:
			"cat":
				e.take_damage(dmg, dir * 145.0)
				Fx.slash(get_parent(), global_position, dir.rotated(0.18), 24.0, 0.40, Color(1.0, 0.86, 0.36), "swing")
				Fx.slash(get_parent(), global_position, dir.rotated(-0.18), 24.0, 0.40, Color(0.45, 0.95, 0.76), "swing")
			"rooster":
				e.take_damage(dmg, dir * 75.0)
				Fx.slash(get_parent(), global_position, dir, 22.0, 0.35, Color(1.0, 0.78, 0.25), "thrust")
			_:
				e.take_damage(dmg, dir * 105.0)
				if is_instance_valid(e) and not bool(e.get("dead")) and e.has_method("apply_stun"):
					e.apply_stun(float(evo.get("stun", 0.45)))
				Fx.slash(get_parent(), global_position, dir, 25.0, 0.40, Color(1.0, 0.52, 0.18), "thrust")
				Fx.particles(get_parent(), global_position + dir * 8.0, Color(1.0, 0.52, 0.18), 7, 75.0, 0.35)
		return
	match pet_id:
		"cat":
			_atk_cd = 0.95
			e.take_damage(4, dir * 130.0)
			Fx.slash(get_parent(), global_position, dir, 22.0, 0.35, Color(1.0, 0.78, 0.45), "swing")
		"rooster":
			_atk_cd = 0.55
			e.take_damage(3, dir * 60.0)
			Fx.slash(get_parent(), global_position, dir, 20.0, 0.3, Color(1.0, 0.45, 0.32), "thrust")
		_:
			_atk_cd = 0.85
			e.take_damage(3, dir * 70.0)
			Fx.slash(get_parent(), global_position, dir, 22.0, 0.35, Color(1.0, 0.9, 0.42), "thrust")


func _clear_enemy_bullets_near(center: Vector2, rad: float) -> int:
	var count: int = 0
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if not is_instance_valid(b):
			continue
		var b2d: Node2D = b as Node2D
		if b2d != null and b2d.global_position.distance_to(center) <= rad:
			if b.has_method("destroy"):
				b.destroy()
			else:
				b.queue_free()
			count += 1
	return count


func get_coin_bonus() -> float:
	if pet_id == "cat":
		return float(CampNpcs.AWAKENED_PETS["cat"].get("coin_bonus", 0.35)) if awakened else 0.15
	return 0.0


func get_crit_bonus() -> float:
	if awakened and pet_id == "cat":
		return float(CampNpcs.AWAKENED_PETS["cat"].get("crit_bonus", 0.10))
	return 0.0


func _find_pickup(owner_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var rng: float = float(CampNpcs.AWAKENED_PETS["dog"].get("pickup_range", 185.0)) if awakened else 115.0
	var owner_rng: float = rng if awakened else 135.0
	var best_d: float = rng
	for pk in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(pk):
			continue
		var p2d: Node2D = pk as Node2D
		if p2d == null:
			continue
		var kd: String = str(pk.get("kind"))
		if not (kd in ["coin", "energy", "material"]):
			continue
		if p2d.global_position.distance_to(owner_pos) > owner_rng:
			continue
		var d: float = global_position.distance_to(p2d.global_position)
		if d < best_d:
			best_d = d
			best = p2d
	return best


func _find_enemy(owner_pos: Vector2):
	var best = null
	var best_d: float = 175.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		if e.has_method("is_spawning") and e.is_spawning():
			continue
		var e2d: Node2D = e as Node2D
		var owner_dist: float = e.distance_to_hurtbox(owner_pos) if e.has_method("distance_to_hurtbox") else (e2d.global_position.distance_to(owner_pos) if e2d != null else 999.0)
		if e2d == null or owner_dist > 190.0:
			continue
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to(e2d.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _has_active_enemy() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		if e.has_method("is_spawning") and e.is_spawning():
			continue
		return true
	return false


func on_next_level() -> void:
	if pet_id != "crane" or owner_player == null or not is_instance_valid(owner_player):
		return
	var cur_hp: int = int(owner_player.get("hp"))
	var max_hp: int = int(owner_player.get("max_hp"))
	var heal_amt: int = int(CampNpcs.AWAKENED_PETS["crane"].get("next_level_heal", 2)) if awakened else 1
	if cur_hp < max_hp and owner_player.has_method("heal"):
		owner_player.heal(heal_amt)
		var msg: String = "Lạc Điểu +%d Máu" % heal_amt if awakened else "Hạc Tiên +1 Máu"
		Fx.float_text(get_parent(), global_position + Vector2(0, -18), msg, Color(0.65, 1.0, 0.78), 12)
