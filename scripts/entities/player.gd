extends CharacterBody2D
## Nhân vật người chơi: hoạt ảnh pixel, vũ khí xoay theo hướng ngắm, 4 kỹ năng có hiệu ứng riêng.

signal stats_changed
signal hurt
signal died

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Stake = preload("res://scripts/entities/stake.gd")
const Ally = preload("res://scripts/entities/ally.gd")
const Beam = preload("res://scripts/effects/beam.gd")
const WaveRing = preload("res://scripts/effects/wave_ring.gd")
const RockSpike = preload("res://scripts/effects/rock_spike.gd")
const Lightning = preload("res://scripts/effects/lightning.gd")
const DrumSigil = preload("res://scripts/effects/drum_sigil.gd")
const ReflectRing = preload("res://scripts/effects/reflect_ring.gd")
const OrbitBlades = preload("res://scripts/effects/orbit_blades.gd")
const FireZone = preload("res://scripts/effects/fire_zone.gd")
const Tiger = preload("res://scripts/effects/tiger.gd")
const Turret = preload("res://scripts/effects/turret.gd")
const StatusFx = preload("res://scripts/effects/status_fx.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")

const RADIUS := 7.0
const AUTO_AIM_RANGE := 230.0
const ARMOR_REGEN_DELAY := 3.5

var hero_id := ""
var hero: Dictionary = {}
var max_hp := 6
var hp := 6
var max_armor := 5
var armor := 5
var max_energy := 180
var energy := 180
var speed := 95.0

var weapons: Array = ["", ""]
var slot := 0
var aim_dir := Vector2.RIGHT
var nearby_pickup = null
var interact_target = null   # điểm tương tác trong sảnh (tướng, lò rèn...)
var dead := false

# Trạng thái chơi chung qua mạng LAN
var peer_id: int = 1
var is_local: bool = true
var display_name: String = ""
var name_color: Color = Color(1.0, 0.88, 0.35)
var downed: bool = false
var revive_progress: float = 0.0
var _net_send_t: float = 0.0
var _remote_pos: Vector2 = Vector2.ZERO
var _has_remote_pos: bool = false
var _remote_anim: String = "idle"

var skill_timer := 0.0
var buff_timer := 0.0
var twin_timer := 0.0          # Song Trưng: Trưng Nhị đánh theo
var rapid_reload_timer := 0.0
var last_hit_enemy = null
var last_skill_syn := 0
var last_skill_imprint := ""
var _twin_syn := 0
var _dash_syn := 0
var _dash_armor_gained := 0
var _reflect_timer := 0.0
var _reflect_syn := 0
var _than_toc_syn := 0
var _trail_fire_cd := 0.0
var _burn_double_timer := 0.0
var _free_shots := 0
var _stun_shot := 0.0
var _mark_timer := 0.0
var _melee_swing_count: int = 0
var _ranged_shot_count: int = 0
var _weapon_light: PointLight2D = null
var twin: AnimatedSprite2D
var _regen_acc := 0.0
var _fire_timer := 0.0
var _invuln := 0.0
var _flash := 0.0
var _armor_regen := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_hit: Array = []
var _horse_time: float = 0.0
var _horse_syn: int = 0
var _horse_fire_cd: float = 0.0
var _msg_cd := 0.0
var _fx_t := 0.0
var _swing_sign := 1.0
var _htk_cd: float = 0.0
var _anim_lock_t: float = 0.0

# Phần hình
var body: AnimatedSprite2D
var elephant: AnimatedSprite2D
var iron_horse: AnimatedSprite2D
var aura: AnimatedSprite2D
var shadow: Sprite2D
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var light: PointLight2D
var status: Node2D            # trạng thái cháy / trúng độc
var _mat: ShaderMaterial
var swing := 0.0     # góc vung thêm (hoạt ảnh chém)
var thrust := 0.0    # đẩy vũ khí ra trước (hoạt ảnh đâm)
var _recoil := 0.0


func setup(id: String) -> void:
	hero_id = id
	hero = HeroData.DATA[id]
	max_hp = hero.hp
	hp = max_hp
	max_armor = hero.armor
	armor = max_armor
	max_energy = hero.energy
	energy = max_energy
	speed = hero.speed
	weapons = [hero.weapon, ""]
	slot = 0
	# nâng cấp vĩnh viễn từ Lò rèn + Tu luyện tướng (cộng dồn; LAN lấy theo Chủ phòng)
	var hb: Dictionary = ProgressionData.hero_bonuses(Global.eff_hero_level(id))
	max_hp += Global.eff_upgrade("mau") + int(hb.hp)
	hp = max_hp
	max_armor += Global.eff_upgrade("giap") + int(hb.armor)
	armor = max_armor
	max_energy += 40 * Global.eff_upgrade("nang_luong") + int(hb.energy)
	energy = max_energy
	Global.discover(hero.weapon)


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	z_index = 2

	shadow = Sprite2D.new()
	shadow.texture = Art.tex("fx/shadow.png")
	shadow.position = Vector2(0, 8)
	shadow.z_index = -2
	add_child(shadow)

	aura = AnimatedSprite2D.new()
	aura.sprite_frames = Art.strip("fx/aura.png", 40, 40, 14.0, true)
	aura.position = Vector2(0, -2)
	aura.material = Art.additive()
	aura.z_index = -1
	aura.visible = false
	add_child(aura)

	elephant = AnimatedSprite2D.new()
	elephant.sprite_frames = Art.strip("fx/elephant.png", 40, 30, 14.0, true)
	elephant.position = Vector2(0, -2)
	elephant.visible = false
	add_child(elephant)

	iron_horse = AnimatedSprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/fx/iron_horse.png"):
		iron_horse.sprite_frames = Art.strip("fx/iron_horse.png", 40, 30, 14.0, true)
	else:
		iron_horse.sprite_frames = elephant.sprite_frames
	iron_horse.position = Vector2(0, -2)
	iron_horse.visible = false
	add_child(iron_horse)

	_mat = Art.flash_material()
	body = AnimatedSprite2D.new()
	var hero_tex: Texture2D = Art.tex("heroes/%s.png" % hero_id)
	var frame_count: int = int(hero_tex.get_width() / 32) if hero_tex != null else 9
	var anims: Dictionary = {
		"idle": [[0, 1, 2, 3], 3.0, true],
		"walk": [[4, 5, 6, 7], 10.0, true],
		"hurt": [[8], 1.0, false],
		"attack": [[9, 10] if frame_count >= 11 else [4, 5], 14.0, false],
		"skill": [[11, 12] if frame_count >= 13 else [0, 1], 10.0, false],
		"down": [[13, 14, 15] if frame_count >= 16 else [8], 8.0, false],
	}
	body.sprite_frames = Art.frames("heroes/%s.png" % hero_id, 32, 32, anims)
	body.position = Vector2(0, -6)
	body.material = _mat
	body.play("idle")
	add_child(body)

	twin = AnimatedSprite2D.new()
	twin.sprite_frames = body.sprite_frames
	twin.modulate = Color(1.0, 0.85, 0.95, 0.9)
	twin.visible = false
	twin.z_index = -1
	add_child(twin)

	weapon_pivot = Node2D.new()
	weapon_pivot.position = Vector2(0, 0)
	add_child(weapon_pivot)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.centered = false
	weapon_pivot.add_child(weapon_sprite)
	_refresh_weapon_sprite()

	light = Art.light(Color(1.0, 0.88, 0.7), 2.8, 0.85)
	add_child(light)

	status = StatusFx.new()
	status.unit = self
	status.head = 26.0
	add_child(status)
	_remote_pos = global_position


func effective_weapon(id: String) -> Dictionary:
	var base: Dictionary = WeaponData.get_data(id)
	if base.is_empty():
		return base
	var out: Dictionary = base
	if id == str(hero.get("weapon", "")):
		out = ProgressionData.apply_weapon_rank(id, base, Global.eff_weapon_rank(hero_id))
	var mod_id: String = Global.get_weapon_mod(id)
	if mod_id != "":
		out = WeaponMods.apply(out, mod_id)
	return out


func current_weapon() -> Dictionary:
	return effective_weapon(weapons[slot])


const SWAP_COOLDOWN := 0.15
var _swap_cd := 0.0


func _refresh_weapon_sprite() -> void:
	if weapon_sprite == null:
		return
	var id: String = weapons[slot]
	if id == "":
		weapon_sprite.texture = null
		if _weapon_light != null:
			_weapon_light.visible = false
		return
	var is_starter: bool = (id == str(hero.get("weapon", "")))
	var r: int = Global.eff_weapon_rank(hero_id) if is_starter else 1
	weapon_sprite.texture = Art.tex(ProgressionData.weapon_texture_path(id, r))
	if is_starter and r >= 5:
		if _weapon_light == null and weapon_pivot != null:
			_weapon_light = Art.light(Color(1.0, 0.86, 0.35), 0.75, 0.6)
			weapon_pivot.add_child(_weapon_light)
		if _weapon_light != null:
			_weapon_light.visible = true
	elif _weapon_light != null:
		_weapon_light.visible = false


# ------------------------------------------------------------------ Vòng lặp

func _physics_process(delta: float) -> void:
	if dead:
		return
	if downed:
		velocity = Vector2.ZERO
		var rescuer_near: bool = false
		for other in Global.all_players():
			if other == self or bool(other.get("dead")) or bool(other.get("downed")):
				continue
			var o2d: Node2D = other as Node2D
			if o2d != null and global_position.distance_to(o2d.global_position) <= 28.0:
				rescuer_near = true
				break
		if rescuer_near:
			revive_progress += delta
			if revive_progress >= 3.0:
				revive_from_down(true)
		else:
			revive_progress = maxf(revive_progress - delta * 0.5, 0.0)
		if not is_local:
			if _has_remote_pos:
				if global_position.distance_to(_remote_pos) > 160.0:
					global_position = _remote_pos
				else:
					global_position = global_position.lerp(_remote_pos, clampf(delta * 18.0, 0.0, 1.0))
		elif Net != null and Net.is_online():
			_net_send_t += delta
			if _net_send_t >= 0.05:
				_net_send_t = 0.0
				_send_net_state()
		return
	if not is_local:
		_dash_time = maxf(_dash_time - delta, 0.0)
		_horse_time = maxf(_horse_time - delta, 0.0)
		buff_timer = maxf(buff_timer - delta, 0.0)
		twin_timer = maxf(twin_timer - delta, 0.0)
		_invuln = maxf(_invuln - delta, 0.0)
		_trail_fire_cd = maxf(_trail_fire_cd - delta, 0.0)
		_horse_fire_cd = maxf(_horse_fire_cd - delta, 0.0)
		var prev_p: Vector2 = global_position
		if _has_remote_pos:
			if global_position.distance_to(_remote_pos) > 160.0:
				global_position = _remote_pos
			else:
				global_position = global_position.lerp(_remote_pos, clampf(delta * 18.0, 0.0, 1.0))
		if buff_timer > 0.0 and _than_toc_syn == 2 and global_position.distance_to(prev_p) > 0.5 and _trail_fire_cd <= 0.0 and get_parent() != null:
			_trail_fire_cd = 0.2
			var rtf := _RemoteFirePotFx.new()
			rtf.instant = true
			rtf.radius = 12.0
			rtf.life = 1.5
			rtf.position = global_position
			rtf.target = global_position
			get_parent().add_child(rtf)
		if _horse_time > 0.0 and _horse_syn == 2 and _horse_fire_cd <= 0.0 and get_parent() != null:
			_horse_fire_cd = 0.16
			var rhf := _RemoteFirePotFx.new()
			rhf.instant = true
			rhf.radius = 14.0
			rhf.life = 2.0
			rhf.position = global_position
			rhf.target = global_position
			get_parent().add_child(rhf)
		if body != null and _anim_lock_t <= 0.0 and _remote_anim != "" and body.animation != _remote_anim:
			body.play(_remote_anim)
		return
	_fire_timer -= delta
	_invuln -= delta
	_msg_cd -= delta
	_swap_cd = maxf(_swap_cd - delta, 0.0)
	_htk_cd = maxf(_htk_cd - delta, 0.0)
	skill_timer = maxf(skill_timer - delta, 0.0)
	buff_timer = maxf(buff_timer - delta, 0.0)
	twin_timer = maxf(twin_timer - delta, 0.0)
	rapid_reload_timer = maxf(rapid_reload_timer - delta, 0.0)
	_reflect_timer = maxf(_reflect_timer - delta, 0.0)
	_burn_double_timer = maxf(_burn_double_timer - delta, 0.0)
	_mark_timer = maxf(_mark_timer - delta, 0.0)
	_trail_fire_cd = maxf(_trail_fire_cd - delta, 0.0)
	if buff_timer > 0.0 and _than_toc_syn == 2 and velocity.length() > 10.0 and _trail_fire_cd <= 0.0 and get_parent() != null:
		_trail_fire_cd = 0.2
		var tf := FireZone.new()
		tf.instant = true
		tf.radius = 12.0
		tf.life = 1.5
		tf.position = global_position
		tf.target = global_position
		get_parent().add_child(tf)

	if buff("ngoc_bich") > 0 and energy < max_energy:
		_regen_acc += delta * 2.0 * buff("ngoc_bich")
		if _regen_acc >= 1.0:
			energy = mini(energy + int(_regen_acc), max_energy)
			_regen_acc -= int(_regen_acc)
			stats_changed.emit()
	_armor_regen -= delta
	if _armor_regen <= 0.0 and armor < max_armor:
		armor += 1
		_armor_regen = 1.0
		stats_changed.emit()

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Global.joy_vector != Vector2.ZERO:
		move = Global.joy_vector

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * speed * 3.2
		_dash_damage()
	elif _horse_time > 0.0:
		_horse_time -= delta
		velocity = _dash_dir * 300.0
		_horse_damage()
		if _horse_syn == 2 and get_parent() != null:
			_horse_fire_cd -= delta
			if _horse_fire_cd <= 0.0:
				_horse_fire_cd = 0.16
				var hf := FireZone.new()
				hf.instant = true
				hf.radius = 14.0
				hf.life = 2.0
				hf.position = global_position
				hf.target = global_position
				get_parent().add_child(hf)
	else:
		var mult := 1.6 if buff_timer > 0.0 else 1.0
		mult *= 1.0 + 0.12 * buff("ngua_o")
		velocity = move * speed * mult
	move_and_slide()
	_update_aim(move)

	var want_attack := Global.touch_attack
	if not Global.touch_mode and Input.is_action_pressed("attack"):
		want_attack = true
	if want_attack and _dash_time <= 0.0 and _horse_time <= 0.0:
		_try_attack()

	if Input.is_action_just_pressed("skill") or Global.touch_skill:
		Global.touch_skill = false
		_use_skill()

	if nearby_pickup != null and not is_instance_valid(nearby_pickup):
		nearby_pickup = null
	if Global.touch_swap:
		Global.touch_swap = false
		_swap_or_pickup()

	if Net != null and Net.is_online():
		_net_send_t += delta
		if _net_send_t >= 0.05:
			_net_send_t = 0.0
			_send_net_state()


func _unhandled_input(event: InputEvent) -> void:
	if not is_local or dead or downed or get_tree().paused or not is_physics_processing():
		return
	if event.is_action_pressed("swap_weapon"):
		if swap_weapon():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if interact_only():
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_mat.set_shader_parameter("flash", _flash)
	_recoil = move_toward(_recoil, 0.0, delta * 40.0)
	if dead or downed:
		if body.animation != "down":
			body.play("down")
		if weapon_pivot != null:
			weapon_pivot.visible = false
		if (Net != null and Net.is_online()) or display_name != "" or downed:
			queue_redraw()
		return

	_anim_lock_t = maxf(_anim_lock_t - delta, 0.0)
	var face_left := aim_dir.x < 0.0
	body.flip_h = face_left
	elephant.flip_h = face_left
	if iron_horse != null:
		iron_horse.flip_h = face_left
	if not is_local:
		if _anim_lock_t <= 0.0 and (body.animation != "hurt" or _flash <= 0.1):
			if _remote_anim != "" and body.animation != _remote_anim:
				body.play(_remote_anim)
	else:
		var moving := velocity.length() > 5.0
		if _anim_lock_t <= 0.0 and (body.animation != "hurt" or _flash <= 0.1):
			body.play("walk" if moving else "idle")

	# vũ khí xoay theo hướng ngắm
	var w := current_weapon()
	var id: String = weapons[slot]
	weapon_pivot.visible = _dash_time <= 0.0 and _horse_time <= 0.0 and id != ""
	weapon_pivot.position = Vector2(-2.0 if face_left else 2.0, 1.0)
	weapon_pivot.rotation = aim_dir.angle() + swing * (-1.0 if face_left else 1.0)
	weapon_pivot.z_index = -1 if aim_dir.y < -0.45 else 0
	if weapon_sprite.texture != null:
		var g := WeaponData.grip(id)
		var h := float(weapon_sprite.texture.get_height())
		weapon_sprite.flip_v = face_left
		weapon_sprite.offset = Vector2(-g.x, -(h - g.y) if face_left else -g.y)
		weapon_sprite.position = Vector2(thrust - _recoil, 0)

	# chớp nháy khi bất tử
	if _invuln > 0.0 and _dash_time <= 0.0 and _horse_time <= 0.0:
		modulate.a = 0.5 if int(_invuln * 16.0) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0

	# hiệu ứng kỹ năng đang chạy
	_fx_t -= delta
	if _dash_time > 0.0:
		elephant.visible = true
		elephant.play("play")
		if iron_horse != null:
			iron_horse.visible = false
		body.position = Vector2(-1, -17)
		if _fx_t <= 0.0:
			_fx_t = 0.04
			Fx.anim(get_parent(), global_position + Vector2(-_dash_dir.x * 12.0, 10 + randf_range(-3, 3)), "fx/dust.png", 10, 10, 12.0, 1.5)
			Fx.afterimage(get_parent(), elephant, global_position, Color(1, 0.6, 0.4, 0.5), 0.25)
	elif _horse_time > 0.0:
		elephant.visible = false
		if iron_horse != null:
			iron_horse.visible = true
			iron_horse.play("play")
		body.position = Vector2(-1, -17)
		if _fx_t <= 0.0:
			_fx_t = 0.04
			Fx.particles(get_parent(), global_position + Vector2(-_dash_dir.x * 10.0, 6), Color(1.0, 0.65, 0.2), 4, 65.0, 0.3, -40.0, 1.8, 50.0, -_dash_dir, Color(0.85, 0.2, 0.1))
			if iron_horse != null:
				Fx.afterimage(get_parent(), iron_horse, global_position, Color(1.0, 0.55, 0.2, 0.55), 0.25)
	else:
		elephant.visible = false
		if iron_horse != null:
			iron_horse.visible = false
		body.position = Vector2(0, -6)
	twin.visible = twin_timer > 0.0
	if twin.visible:
		twin.flip_h = body.flip_h
		twin.position = _twin_offset() + Vector2(0, -6) + Vector2(0, sin(Time.get_ticks_msec() / 200.0))
		twin.play(body.animation)
		twin.frame = body.frame
		twin.modulate.a = 0.9 if twin_timer > 1.0 else 0.4 + 0.5 * absf(sin(twin_timer * 12.0))
	aura.visible = buff_timer > 0.0
	if buff_timer > 0.0:
		aura.play("play")
		if _fx_t <= 0.0:
			_fx_t = 0.05
			Fx.afterimage(get_parent(), body, global_position, Color(1, 0.8, 0.3, 0.6), 0.28)
			if randf() < 0.4:
				Fx.particles(get_parent(), global_position + Vector2(randf_range(-6, 6), 6), Color(1, 0.95, 0.5), 3, 50.0, 0.3, -40.0, 1.0, 40.0)
	if (Net != null and Net.is_online()) or display_name != "" or downed:
		queue_redraw()


func _draw() -> void:
	if display_name != "":
		Art.draw_text(self, Vector2(0, -24), display_name, 11, name_color, true)
	if downed:
		var pulse: float = 0.65 + 0.35 * sin(Time.get_ticks_msec() / 160.0)
		var red_col := Color(1.0, 0.25, 0.25, pulse)
		Art.draw_text(self, Vector2(0, -36), "GỤC - Đứng cạnh 3s để cứu", 10, red_col, true)
		var pct: float = clampf(revive_progress / 3.0, 0.0, 1.0)
		draw_arc(Vector2(0, -2), 14.0, 0.0, TAU, 32, Color(1.0, 0.25, 0.25, 0.35 * pulse), 1.5)
		if pct > 0.0:
			draw_arc(Vector2(0, -2), 14.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 32, Color(0.45, 1.0, 0.55, 0.95), 2.5)
		var bw: float = 34.0
		var bx: float = -bw * 0.5
		var by: float = -21.0
		draw_rect(Rect2(bx - 1.0, by - 1.0, bw + 2.0, 5.0), Color(0.05, 0.02, 0.05, 0.85))
		draw_rect(Rect2(bx, by, bw, 3.0), Color(0.28, 0.08, 0.08, 0.9))
		draw_rect(Rect2(bx, by, bw * pct, 3.0), Color(0.45, 1.0, 0.55, 0.95))


func _update_aim(move: Vector2) -> void:
	if _dash_time > 0.0 or _horse_time > 0.0:
		return
	if Global.auto_aim():
		var target = nearest_enemy()
		if target != null:
			aim_dir = (target.global_position - global_position).normalized()
		elif move.length() > 0.1:
			aim_dir = move.normalized()
	else:
		var d := get_global_mouse_position() - global_position
		if d.length() > 4.0:
			aim_dir = d.normalized()


func nearest_enemy():
	var best = null
	var best_d := AUTO_AIM_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.is_spawning():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


# ------------------------------------------------------------------ Tấn công

func _try_attack() -> void:
	if _fire_timer > 0.0:
		return
	var w := current_weapon()
	if w.is_empty():
		return
	var is_free: bool = _free_shots > 0
	var shot_stun: float = _stun_shot if is_free else 0.0
	var cost: int = w.get("energy", 0)
	if buff_timer > 0.0 or is_free:
		cost = 0
	if cost > energy:
		_fire_timer = 0.25
		if _msg_cd <= 0.0:
			_msg_cd = 1.2
			Fx.float_text(get_parent(), global_position + Vector2(0, -22), "Hết năng lượng!", Color(0.5, 0.75, 1.0))
		return
	energy -= cost
	var cd: float = w.cooldown
	var rate_mult: float = float(SynergyData.IMPRINTS["sung"].fire_rate_mult) if rapid_reload_timer > 0.0 else 1.0
	if is_free:
		_free_shots -= 1
		if _free_shots > 0:
			_fire_timer = 0.0
		else:
			_fire_timer = cd * (0.5 if buff_timer > 0.0 else 1.0) * pow(0.87, buff("giay_co")) / rate_mult
			_stun_shot = 0.0
	else:
		_fire_timer = cd * (0.5 if buff_timer > 0.0 else 1.0) * pow(0.87, buff("giay_co")) / rate_mult
	match w.type:
		"melee":
			_melee(w, Vector2.ZERO, shot_stun)
			if twin_timer > 0.0:
				_melee(w, _twin_offset(), shot_stun)
		"ranged":
			_shoot(w, Vector2.ZERO, shot_stun)
			if twin_timer > 0.0:
				_shoot(w, _twin_offset(), shot_stun)
		"beam":
			_beam(w)
		"wave":
			_wave(w)
		"spikes":
			_spikes(w)
	if body != null and not dead:
		_anim_lock_t = 0.18
		body.play("attack")
		body.frame = 0
	if w.has("shake"):
		Fx.shake(get_tree(), w.shake)
	if cost > 0:
		stats_changed.emit()


func _muzzle_pos() -> Vector2:
	var id: String = weapons[slot]
	var tex := weapon_sprite.texture
	var reach := 10.0
	if tex != null:
		reach = float(tex.get_width()) - WeaponData.grip(id).x
	return global_position + weapon_pivot.position + aim_dir * reach


func _tier_color(w: Dictionary) -> Color:
	var t: int = w.get("tier", 1)
	return Color.WHITE if t <= 1 else WeaponData.TIER_COLORS[t].lightened(0.3)


func _twin_offset() -> Vector2:
	return Vector2(14.0 if body.flip_h else -14.0, 6.0)


func _shoot(w: Dictionary, offset := Vector2.ZERO, shot_stun: float = 0.0) -> void:
	if offset == Vector2.ZERO:
		var proj_kind: String = str(w.get("proj", "bullet"))
		Sfx.play("arrow" if proj_kind in ["arrow", "stone", "dart", "axe"] else "shoot")
	var count: int = w.get("count", 1) + buff("ten_doi")
	var spread := deg_to_rad(w.get("spread", 0.0))
	if buff("ten_doi") > 0 and spread == 0.0:
		spread = deg_to_rad(10.0 * buff("ten_doi"))
	var inacc := deg_to_rad(w.get("inaccuracy", 3.0))
	var start := _muzzle_pos() + offset
	var life_mult: float = 1.0
	if buff_timer > 0.0 and SynergyData.family(weapons[slot]) == "hoa_khi" and _than_toc_syn >= 1:
		life_mult = 2.0 if _than_toc_syn == 2 else 1.5
	var burn_mult: float = float(w.get("burn_mult", 1.0))
	var extra_explode: float = 0.0
	if offset == Vector2.ZERO and bool(w.get("trait_explode4", false)):
		_ranged_shot_count += 1
		if _ranged_shot_count % 4 == 0:
			extra_explode = 24.0 * (1.0 + 0.35 * buff("hoa_duoc"))
	var net_shots: Array = []
	var broadcast_net: bool = is_local and Net != null and Net.is_online()
	for i in count:
		var a := aim_dir.angle()
		if count > 1:
			a += lerpf(-spread / 2.0, spread / 2.0, float(i) / float(count - 1))
		a += randf_range(-inacc, inacc)
		var dir := Vector2.from_angle(a)
		var b := Bullet.new()
		var b_pos: Vector2 = start - aim_dir * 4.0
		var b_life: float = float(w.life) * life_mult
		var b_proj: String = str(w.get("proj", "bullet"))
		b.setup(true, b_pos, dir, w.speed, w.damage, b_life, b_proj)
		b.spawn_origin = global_position + offset
		b.pierce = int(w.get("pierce", 0)) + (int(SynergyData.IMPRINTS["sung"].pierce) if rapid_reload_timer > 0.0 else 0)
		b.explode_radius = maxf(w.get("explode", 0.0) * (1.0 + 0.35 * buff("hoa_duoc")), extra_explode)
		b.knock = w.get("knock", 60.0)
		b.homing = w.get("homing", 0.0)
		b.color = w.get("color", Color.WHITE)
		if bool(w.get("mod_fire", false)):
			b.force_burn = true
			if b.color == Color.WHITE:
				b.color = Color(1.0, 0.72, 0.45)
		b.stun_duration = shot_stun
		b.burn_duration = 2.2 * burn_mult
		b.owner_node = self
		if w.get("boomerang", false):
			b.boomerang = true
		get_parent().add_child(b)
		if broadcast_net:
			net_shots.append([b_pos.x, b_pos.y, dir.x, dir.y, float(b.speed), b_life, b_proj, b.pierce, b.explode_radius, b.homing, b.boomerang, b.color.to_html(true)])
	if _reflect_timer > 0.0 and _reflect_syn == 2 and offset == Vector2.ZERO:
		for sgn in [-1.0, 1.0]:
			var ea := aim_dir.angle() + deg_to_rad(12.0 * sgn)
			var ed: Vector2 = Vector2.from_angle(ea)
			var epos: Vector2 = start - aim_dir * 4.0
			var eb := Bullet.new()
			eb.setup(true, epos, ed, 440.0, maxi(3, int(round(float(w.damage) * 0.8))), 0.75, "arrow")
			eb.spawn_origin = global_position + offset
			eb.pierce = int(SynergyData.IMPRINTS["sung"].pierce) if rapid_reload_timer > 0.0 else 0
			eb.owner_node = self
			get_parent().add_child(eb)
			if broadcast_net:
				net_shots.append([epos.x, epos.y, ed.x, ed.y, 440.0, 0.75, "arrow", eb.pierce, 0.0, 0.0, false, Color.WHITE.to_html(true)])
	_recoil = w.get("recoil", 1.5)
	if broadcast_net:
		Net.send_player_action("shoot", {
			"shots": net_shots,
			"muzzle": str(w.get("muzzle", "")),
			"mx": start.x,
			"my": start.y,
			"ax": aim_dir.x,
			"ay": aim_dir.y,
			"recoil": _recoil,
			"sfx": "arrow" if str(w.get("proj", "bullet")) in ["arrow", "stone", "dart", "axe"] else "shoot",
			"silent": offset != Vector2.ZERO,
		})
	match w.get("muzzle", ""):
		"flash":
			Fx.anim(get_parent(), start, "fx/muzzle.png", 12, 10, 24.0, 1.0, aim_dir.angle(), Color.WHITE, true, 6)
			Fx.particles(get_parent(), global_position, Color(1, 0.85, 0.4), 1, 60.0, 0.5, 200.0, 1.5, 30.0, Vector2(-aim_dir.x, -1))
		"smoke":
			Fx.anim(get_parent(), start, "fx/poof.png", 28, 28, 18.0, 0.55, 0.0, Color(1, 1, 1, 0.8))
		"fire":
			Fx.particles(get_parent(), start, Color(1, 0.7, 0.3), 2, 60.0, 0.25, -60.0, 1.5, 40.0, aim_dir, Color(0.8, 0.2, 0.1))


func _melee(w: Dictionary, offset := Vector2.ZERO, hit_stun: float = 0.0) -> void:
	if offset == Vector2.ZERO:
		Sfx.play("slash")
	var reach: float = w.reach * (1.0 + 0.2 * buff("da_mai"))
	var arc := deg_to_rad(w.arc)
	var dmg: int = int(w.damage * (1.0 + 0.15 * buff("da_mai")))
	var hits: int = w.get("hits", 1)
	var knock: float = w.get("knock", 140.0)
	var style: String = w.get("style", "swing")
	var first_hit = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if _in_arc(e.global_position - offset, reach + e.radius, arc, e.radius):
			var hit_dmg: int = dmg * burn_bonus_mult(e)
			for i in hits:
				e.take_damage(hit_dmg, (e.global_position - global_position).normalized() * knock)
			if hit_stun > 0.0 and is_instance_valid(e) and not e.dead and e.has_method("apply_stun"):
				e.apply_stun(hit_stun)
			if bool(w.get("mod_fire", false)) and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status("burn", 2.2)
			on_hit_enemy(e)
			if first_hit == null:
				first_hit = e
			Fx.anim(get_parent(), e.global_position, "fx/spark.png", 15, 15, 24.0, 1.0, 0.0, Color(1, 0.95, 0.7), true)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if _in_arc(b.global_position - offset, reach + 4.0, arc, 4.0):
			b.destroy()
	for c in get_tree().get_nodes_in_group("cover"):
		if is_instance_valid(c) and c.destructible and _in_arc(c.global_position - offset, reach + c.radius, arc, c.radius):
			c.take_hit(dmg, c.global_position, aim_dir)
	if first_hit != null and offset == Vector2.ZERO:
		Sfx.play("hit_flesh")
		for ch in get_children():
			if ch is OrbitBlades:
				ch.trigger_launch(first_hit)
	var broadcast_net: bool = is_local and Net != null and Net.is_online()
	var net_waves: Array = []
	if twin_timer > 0.0 and _twin_syn == 2:
		var tw_b := Bullet.new()
		var tw_pos: Vector2 = global_position + offset + aim_dir * 14.0
		tw_b.setup(true, tw_pos, aim_dir, 300.0, maxi(1, int(round(float(dmg) * 0.5))), 0.7, "sword_wave")
		tw_b.spawn_origin = global_position + offset
		tw_b.pierce = 99
		tw_b.knock = knock
		tw_b.color = Color(1, 0.75, 0.85) if offset != Vector2.ZERO else _tier_color(w)
		tw_b.owner_node = self
		get_parent().add_child(tw_b)
		if broadcast_net:
			net_waves.append([tw_pos.x, tw_pos.y, aim_dir.x, aim_dir.y, 300.0, 0.7, "sword_wave", tw_b.color.to_html(true)])
	if offset != Vector2.ZERO:
		Fx.slash(get_parent(), global_position + offset, aim_dir, reach, arc, Color(1, 0.7, 0.85), style)
		if broadcast_net:
			Net.send_player_action("melee", {
				"ox": offset.x, "oy": offset.y, "ax": aim_dir.x, "ay": aim_dir.y,
				"reach": reach, "arc": arc, "style": style, "col": Color(1, 0.7, 0.85).to_html(true),
				"fire": false, "waves": net_waves, "lpts": [],
			})
		return
	# hoạt ảnh vũ khí
	var tw := create_tween()
	match style:
		"thrust":
			tw.tween_property(self, "thrust", reach * 0.35, 0.06)
			tw.tween_property(self, "thrust", 0.0, 0.12)
		"spin":
			swing = 0.0
			tw.tween_property(self, "swing", TAU, 0.2)
			tw.tween_callback(func(): swing = 0.0)
		_:
			_swing_sign = -_swing_sign
			swing = -arc * 0.5 * _swing_sign
			tw.tween_property(self, "swing", arc * 0.5 * _swing_sign, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "swing", 0.0, 0.14)
	var slash_col: Color = _tier_color(w)
	Fx.slash(get_parent(), global_position + weapon_pivot.position, aim_dir, reach, arc, slash_col, style)
	if w.has("wave"):
		var b := Bullet.new()
		var kind: String = w.wave
		var wpos: Vector2 = global_position + aim_dir * 14.0
		var wspd: float = 300.0 if kind == "sword_wave" else 240.0
		b.setup(true, wpos, aim_dir, wspd, int(dmg * 0.8), 0.7, kind)
		b.spawn_origin = global_position
		b.pierce = 99
		b.knock = knock
		b.color = slash_col
		get_parent().add_child(b)
		if broadcast_net:
			net_waves.append([wpos.x, wpos.y, aim_dir.x, aim_dir.y, wspd, 0.7, kind, b.color.to_html(true)])
	if bool(w.get("trait_wave3", false)):
		_melee_swing_count += 1
		if _melee_swing_count % 3 == 0:
			var bw := Bullet.new()
			var bwpos: Vector2 = global_position + aim_dir * 14.0
			bw.setup(true, bwpos, aim_dir, 300.0, maxi(1, int(ceil(float(dmg) * 0.6))), 0.7, "sword_wave")
			bw.spawn_origin = global_position
			bw.pierce = 99
			bw.knock = knock
			bw.color = Color(1.0, 0.88, 0.35)
			if bool(w.get("trait_fire_wave", false)) or bool(w.get("mod_fire", false)):
				bw.force_burn = true
				bw.color = Color(1.0, 0.58, 0.22)
			bw.owner_node = self
			get_parent().add_child(bw)
			if broadcast_net:
				net_waves.append([bwpos.x, bwpos.y, aim_dir.x, aim_dir.y, 300.0, 0.7, "sword_wave", bw.color.to_html(true)])
	if w.get("fire", false):
		for i in 5:
			var p := global_position + Vector2.from_angle(aim_dir.angle() + lerpf(-arc / 2.0, arc / 2.0, i / 4.0)) * reach * 0.8
			Fx.particles(get_parent(), p, Color(1, 0.75, 0.3), 4, 50.0, 0.4, -80.0, 2.0, 60.0, Vector2.UP, Color(0.8, 0.2, 0.1))
	var chain_pts: Array = []
	if w.has("chain") and first_hit != null:
		chain_pts = _chain_lightning(first_hit, int(w.chain), int(dmg * 0.7))
	if broadcast_net:
		var lpts_ser: Array = []
		for pt in chain_pts:
			var v: Vector2 = pt
			lpts_ser.append([v.x, v.y])
		Net.send_player_action("melee", {
			"ox": 0.0, "oy": 0.0, "ax": aim_dir.x, "ay": aim_dir.y,
			"reach": reach, "arc": arc, "style": style, "col": slash_col.to_html(true),
			"fire": bool(w.get("fire", false)), "waves": net_waves, "lpts": lpts_ser,
		})


func _chain_lightning(start, count: int, dmg: int) -> Array:
	var pts: Array = [global_position + aim_dir * 10.0, start.global_position]
	var done: Array = [start]
	var cur = start
	for i in count - 1:
		var best = null
		var best_d := 110.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if done.has(e):
				continue
			var d: float = cur.global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			break
		done.append(best)
		pts.append(best.global_position)
		best.take_damage(dmg, Vector2.ZERO)
		cur = best
	var l := Lightning.new()
	l.points = pts
	get_parent().add_child(l)
	Fx.particles(get_parent(), start.global_position, Color(0.6, 0.9, 1.0), 8, 90.0, 0.3)
	return pts


func _beam(w: Dictionary) -> void:
	Sfx.play("shoot")
	var start := _muzzle_pos()
	var length: float = w.length
	var end := start + aim_dir * length
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, end, 1)
	q.hit_from_inside = true
	var res := space.intersect_ray(q)
	if not res.is_empty():
		var hit_pos: Vector2 = res["position"]
		end = hit_pos
		if (hit_pos - global_position).dot(aim_dir) < (start - global_position).dot(aim_dir):
			start = hit_pos
		var col: Object = res["collider"]
		if col is Node and (col as Node).is_in_group("cover") and col.has_method("take_hit"):
			col.take_hit(w.damage, hit_pos, aim_dir)
		elif col is Node and (col as Node).is_in_group("doors"):
			Sfx.play("hit_wood")
		else:
			Sfx.play("hit_wall")
	var width: float = w.get("width", 3.0)
	var seg := end - start
	for e in get_tree().get_nodes_in_group("enemies"):
		var rel: Vector2 = e.global_position - start
		var t := clampf(rel.dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
		if (start + seg * t).distance_to(e.global_position) <= width + e.radius:
			e.take_damage(w.damage, aim_dir * 80.0)
			if bool(w.get("mod_fire", false)) and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status("burn", 2.2)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		var relb: Vector2 = b.global_position - start
		var tb := clampf(relb.dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
		if (start + seg * tb).distance_to(b.global_position) <= width + 3.0:
			b.destroy()
	var fx := Beam.new()
	fx.position = start
	fx.end_point = end - start
	fx.width = width
	fx.color = w.get("color", Color(0.3, 0.9, 1.0))
	get_parent().add_child(fx)
	Fx.anim(get_parent(), end, "fx/spark.png", 15, 15, 24.0, 1.3, 0.0, fx.color, true)
	_recoil = 3.0
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("beam", {
			"sx": start.x, "sy": start.y, "ex": end.x, "ey": end.y,
			"width": width, "col": fx.color.to_html(true),
		})


func _wave(w: Dictionary) -> void:
	Sfx.play("skill")
	var r := WaveRing.new()
	r.position = global_position
	r.radius = w.get("radius", 110.0)
	r.damage = w.damage
	r.stun = w.get("stun", 0.0)
	r.color = w.get("color", Color(1.0, 0.75, 0.35))
	r.notes = w.has("stun")
	get_parent().add_child(r)
	Fx.shake(get_tree(), 2.0)
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("wave", {
			"x": global_position.x, "y": global_position.y,
			"radius": r.radius, "col": r.color.to_html(true), "notes": r.notes,
		})


func _spikes(w: Dictionary) -> void:
	Sfx.play("explode")
	var count: int = w.get("count", 6)
	var spacing: float = w.get("spacing", 18.0)
	var dir := aim_dir
	var origin := global_position
	var wr: WeakRef = weakref(get_parent())
	var dmg: int = w.damage
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var net_pts: Array = []
	for i in count:
		var pos := origin + dir * spacing * (i + 1)
		var q := PhysicsRayQueryParameters2D.create(origin, pos, 1)
		q.hit_from_inside = true
		var res: Dictionary = space.intersect_ray(q)
		if not res.is_empty():
			var col: Object = res["collider"]
			if col is Node and (col as Node).is_in_group("cover") and col.has_method("take_hit") and col.destructible:
				if not col.take_hit(dmg, res["position"], dir):
					break
			else:
				break
		net_pts.append([pos.x, pos.y])
		get_tree().create_timer(0.05 * i).timeout.connect(func():
			var par = wr.get_ref()
			if par == null:
				return
			var s := RockSpike.new()
			s.position = pos
			s.damage = dmg
			par.add_child(s))
	if is_local and Net != null and Net.is_online() and not net_pts.is_empty():
		Net.send_player_action("spikes", {"pts": net_pts})


func _in_arc(pos: Vector2, max_dist: float, arc: float, size: float) -> bool:
	var to := pos - global_position
	if to.length() > max_dist:
		return false
	if to.length() < size + RADIUS:
		return true
	return absf(angle_difference(aim_dir.angle(), to.angle())) <= arc / 2.0 + 0.15


# ------------------------------------------------------------------ Kỹ năng

func _use_skill() -> void:
	if skill_timer > 0.0 or dead:
		return
	var cur_id: String = weapons[slot]
	var syn: int = SynergyData.level(hero_id, cur_id)
	var fam: String = SynergyData.family(cur_id)
	var cw: Dictionary = current_weapon()
	last_skill_syn = syn
	last_skill_imprint = fam
	if syn >= 0 and syn <= 2:
		Global.run_syn_counts[syn] = int(Global.run_syn_counts[syn]) + 1
	var hb: Dictionary = ProgressionData.hero_bonuses(Global.eff_hero_level(hero_id))
	skill_timer = hero.skill_cd * pow(0.8, buff("tra_tim_sen")) * float(hb.cd_mult)
	Sfx.play("skill")
	if body != null and not dead:
		_anim_lock_t = 0.28
		body.play("skill")
		body.frame = 0
	var parent := get_parent()
	var wr: WeakRef = weakref(parent)
	match hero.skill:
		"coc_bach_dang":
			# Nước dâng, cọc nhọn trồi lên thành 2 vòng (mức 2 thêm vòng ngoài 8 cọc)
			Fx.anim(parent, global_position + Vector2(0, 6), "fx/ripple.png", 72, 34, 12.0, 1.6)
			Fx.particles(parent, global_position, Color(0.5, 0.8, 1.0), 20, 110.0, 0.6, 150.0, 2.0, 180.0, Vector2.UP, Color(0.9, 1, 1))
			var s_life: float = 9.0 if syn == 2 else 6.0
			var s_stun: float = 1.0 if syn == 2 else (0.5 if syn == 1 else 0.0)
			for i in 14:
				var ring := 30.0 if i % 2 == 0 else 50.0
				var ang := TAU * i / 14.0
				var pos := global_position + Vector2(cos(ang), sin(ang) * 0.8) * ring
				get_tree().create_timer(0.025 * i).timeout.connect(func():
					var par = wr.get_ref()
					if par == null:
						return
					var s := Stake.new()
					s.life_time = s_life
					s.stun_time = s_stun
					s.position = pos
					par.add_child(s))
			if syn == 2:
				for i in 8:
					var ang2 := TAU * i / 8.0 + 0.2
					var pos2 := global_position + Vector2(cos(ang2), sin(ang2) * 0.8) * 70.0
					get_tree().create_timer(0.025 * (14 + i)).timeout.connect(func():
						var par = wr.get_ref()
						if par == null:
							return
						var s := Stake.new()
						s.life_time = s_life
						s.stun_time = s_stun
						s.position = pos2
						par.add_child(s))
			Fx.shake(get_tree(), 3.0)
		"voi_chien":
			_dash_time = 0.55
			_dash_dir = aim_dir
			_dash_hit.clear()
			_dash_syn = syn
			_dash_armor_gained = 0
			Fx.burst(parent, global_position, Color(1, 0.8, 0.5), 40.0, 0.4)
			Fx.float_text(parent, global_position + Vector2(20 * aim_dir.x, -30), "Hống!", Color(1, 0.9, 0.6), 20)
			Fx.shake(get_tree(), 4.0)
		"hich_tuong_si":
			var sig := DrumSigil.new()
			sig.position = global_position + Vector2(0, 6)
			parent.add_child(sig)
			var here := global_position
			for k in 3:
				get_tree().create_timer(0.2 * k).timeout.connect(func():
					var par = wr.get_ref()
					if par != null:
						Fx.burst(par, here, Color(1, 0.8, 0.3), 46.0 + k * 10.0, 0.45))
			var ally_cnt: int = 4 if syn >= 1 else 3
			var ally_dmg: int = 5 if syn == 2 else 3
			var ally_focus: bool = (syn == 2)
			for i in ally_cnt:
				var pos2 := global_position + Vector2.from_angle(TAU * i / float(ally_cnt) - PI / 2.0) * 22.0
				get_tree().create_timer(0.3 + 0.12 * i).timeout.connect(func():
					var par = wr.get_ref()
					if par == null:
						return
					Fx.anim(par, pos2, "fx/poof.png", 28, 28, 18.0)
					var a := Ally.new()
					a.damage = ally_dmg
					a.focus_player_target = ally_focus
					a.position = pos2
					par.add_child(a))
			Fx.particles(parent, global_position, Color(1, 0.85, 0.4), 24, 120.0, 0.7, -30.0, 2.0)
		"song_trung":
			_twin_syn = syn
			twin_timer = 11.0 if syn == 2 else (10.0 if syn == 1 else 8.0)
			Fx.anim(parent, global_position + _twin_offset(), "fx/poof.png", 28, 28, 16.0, 1.2, 0.0, Color(1, 0.7, 0.85))
			Fx.particles(parent, global_position, Color(1, 0.6, 0.8), 20, 110.0, 0.6, -30.0, 2.0)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Trưng Nhị!", Color(1, 0.75, 0.85), 18)
		"nam_quoc_son_ha":
			_reflect_syn = syn
			_reflect_timer = 5.0
			var ring := ReflectRing.new()
			ring.damage_mult = 2.0 if syn == 2 else (1.5 if syn == 1 else 1.0)
			ring.pierce_bonus = 1 if syn == 2 else 0
			add_child(ring)
			Fx.burst(parent, global_position, Color(1, 0.85, 0.35), 50.0, 0.5)
		"thuan_thien_kiem":
			var ob := OrbitBlades.new()
			ob.count = 5 if syn == 2 else (4 if syn == 1 else 3)
			ob.launch_on_melee = (syn == 2)
			add_child(ob)
			Fx.burst(parent, global_position, Color(1, 0.95, 0.6), 44.0, 0.45)
			Fx.particles(parent, global_position, Color(1, 0.95, 0.6), 22, 120.0, 0.6)
		"hoa_hong":
			var pot_cnt: int = 12 if syn == 2 else (10 if syn == 1 else 8)
			if syn == 2:
				_burn_double_timer = 4.0
			for i in pot_cnt:
				var fz := FireZone.new()
				fz.position = global_position
				fz.target = global_position + Vector2.from_angle(TAU * float(i) / float(pot_cnt)) * 54.0
				parent.add_child(fz)
			Fx.shake(get_tree(), 2.0)
		"hum_thieng":
			if syn >= 1:
				_free_shots = 3 if syn == 2 else 2
				_stun_shot = 0.8 if syn == 2 else 0.0
				_fire_timer = 0.0
			var roar := WaveRing.new()
			roar.position = global_position
			roar.radius = 120.0
			roar.damage = 3
			roar.stun = 2.0
			roar.color = Color(1, 0.65, 0.25)
			parent.add_child(roar)
			var tg := Tiger.new()
			tg.position = global_position
			tg.dir = aim_dir
			parent.add_child(tg)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Gầm!", Color(1, 0.75, 0.3), 22)
			Fx.shake(get_tree(), 4.0)
		"keo_phao":
			var tu := Turret.new()
			tu.fire_cd = 0.7 / 1.4 if syn == 2 else (0.7 / 1.2 if syn == 1 else 0.7)
			tu.use_marked = (syn == 2)
			if syn == 2:
				_mark_timer = 9.0
			tu.position = global_position + aim_dir * 16.0
			parent.add_child(tu)
		"than_toc":
			_than_toc_syn = syn
			buff_timer = 5.0
			Fx.burst(parent, global_position, Color(1, 0.9, 0.3), 36.0, 0.35)
			Fx.particles(parent, global_position, Color(1, 0.95, 0.5), 18, 140.0, 0.5, 0.0, 2.0)
		"ngua_sat":
			_horse_time = 0.65
			_invuln = maxf(_invuln, 0.75)
			_dash_dir = aim_dir
			_horse_syn = syn
			_horse_fire_cd = 0.0
			_dash_hit.clear()
			var fb_cnt: int = 8 if syn == 2 else (5 if syn == 1 else 3)
			var spread_deg: float = 56.0 if syn == 2 else (44.0 if syn == 1 else 30.0)
			for i in fb_cnt:
				var frac: float = 0.5 if fb_cnt <= 1 else float(i) / float(fb_cnt - 1)
				var ang: float = aim_dir.angle() + deg_to_rad(lerpf(-spread_deg * 0.5, spread_deg * 0.5, frac))
				var fdir: Vector2 = Vector2.from_angle(ang)
				var fb := Bullet.new()
				fb.setup(true, global_position + fdir * 12.0, fdir, 260.0, 5, 0.55, "fireball")
				fb.spawn_origin = global_position
				fb.owner_node = self
				parent.add_child(fb)
			Fx.burst(parent, global_position, Color(1.0, 0.55, 0.2), 44.0, 0.4)
			Fx.float_text(parent, global_position + Vector2(20 * aim_dir.x, -30), "Hí! Phun lửa!", Color(1.0, 0.78, 0.28), 18)
			Fx.shake(get_tree(), 4.0)
	_trigger_imprint(fam, cw)
	if syn == 2:
		Fx.burst(parent, global_position, Color(1.0, 0.85, 0.25), 42.0, 0.4)
		Fx.float_text(parent, global_position + Vector2(0, -42), "Tâm đắc!", Color(1.0, 0.88, 0.35), 16)
	elif syn == 1:
		Fx.float_text(parent, global_position + Vector2(0, -42), "Đồng điệu!", Color(0.82, 0.88, 0.96), 14)
	var imp: Dictionary = SynergyData.IMPRINTS.get(fam, SynergyData.IMPRINTS["kiem"])
	Fx.float_text(parent, global_position + Vector2(0, -54), "Ấn: %s" % imp.name, SynergyData.family_color(fam), 13)
	get_tree().call_group("hud", "show_cutin", hero_id)
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("skill", {
			"skill": str(hero.skill),
			"syn": syn,
			"fam": fam,
			"x": global_position.x,
			"y": global_position.y,
			"ax": aim_dir.x,
			"ay": aim_dir.y,
		})


func _trigger_imprint(fam: String, cw: Dictionary) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var imp: Dictionary = SynergyData.IMPRINTS.get(fam, SynergyData.IMPRINTS["kiem"])
	match fam:
		"kiem":
			var n: int = int(imp.waves)
			var dmg: int = maxi(int(imp.min_dmg), int(cw.get("damage", 4)))
			for i in n:
				var d := Vector2.from_angle(TAU * float(i) / float(n))
				var b := Bullet.new()
				b.setup(true, global_position + d * 12.0, d, 300.0, dmg, 0.65, "sword_wave")
				b.pierce = 99
				b.color = SynergyData.family_color(fam)
				b.owner_node = self
				parent.add_child(b)
		"truong":
			var wr := WaveRing.new()
			wr.position = global_position
			wr.radius = float(imp.radius)
			wr.damage = int(imp.damage)
			wr.knock = float(imp.knock)
			wr.stun = float(imp.stun)
			wr.color = SynergyData.family_color(fam)
			parent.add_child(wr)
		"cung_no":
			var cnt: int = int(imp.count)
			var dur: float = float(imp.duration)
			var rad: float = float(imp.radius)
			var admg: int = int(imp.damage)
			var wrp: WeakRef = weakref(parent)
			var wrs: WeakRef = weakref(self)
			for i in cnt:
				var delay: float = dur * float(i) / float(cnt)
				get_tree().create_timer(delay).timeout.connect(func():
					var par = wrp.get_ref()
					var me = wrs.get_ref()
					if par == null or me == null or me.dead:
						return
					var target_pos: Vector2 = me.global_position + Vector2.from_angle(randf() * TAU) * randf_range(14.0, rad)
					var cand: Array = []
					for e in me.get_tree().get_nodes_in_group("enemies"):
						if is_instance_valid(e) and not e.dead and not e.is_spawning() and me.global_position.distance_to(e.global_position) <= rad:
							cand.append(e)
					if not cand.is_empty():
						var pick = cand.pick_random()
						target_pos = pick.global_position
					var ab := Bullet.new()
					ab.setup(true, target_pos + Vector2(0, -28), Vector2.DOWN, 320.0, admg, 0.35, "arrow")
					ab.color = SynergyData.family_color("cung_no")
					ab.owner_node = me
					ab.add_to_group("imprint_arrows")
					par.add_child(ab))
		"hoa_khi":
			var cnt_f: int = int(imp.count)
			var dist_f: float = float(imp.dist)
			for i in cnt_f:
				var fz := FireZone.new()
				fz.instant = true
				fz.radius = float(imp.radius)
				fz.life = float(imp.life)
				fz.position = global_position + Vector2.from_angle(TAU * float(i) / float(cnt_f) - PI / 2.0) * dist_f
				fz.target = fz.position
				parent.add_child(fz)
		"sung":
			rapid_reload_timer = float(imp.duration)
		"than_khi":
			add_energy(int(imp.energy))
			skill_timer *= float(imp.cd_mult)


func _dash_damage() -> void:
	var dash_dmg: int = 16 if _dash_syn == 2 else (13 if _dash_syn == 1 else 10)
	for e in get_tree().get_nodes_in_group("enemies"):
		if _dash_hit.has(e):
			continue
		if global_position.distance_to(e.global_position) < RADIUS + e.radius + 14.0:
			_dash_hit.append(e)
			e.take_damage(dash_dmg, _dash_dir * 340.0)
			if _dash_syn == 2 and _dash_armor_gained < 3:
				_dash_armor_gained += 1
				if armor < max_armor:
					armor = mini(armor + 1, max_armor)
					stats_changed.emit()
			Fx.anim(get_parent(), e.global_position, "fx/spark.png", 15, 15, 24.0, 1.4, 0.0, Color(1, 0.9, 0.6), true)
			Fx.shake(get_tree(), 2.0)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < 20.0:
			b.destroy()


func _horse_damage() -> void:
	var ram_dmg: int = 10 + 3 * _horse_syn
	for e in get_tree().get_nodes_in_group("enemies"):
		if _dash_hit.has(e):
			continue
		if global_position.distance_to(e.global_position) < RADIUS + e.radius + 14.0:
			_dash_hit.append(e)
			e.take_damage(ram_dmg, _dash_dir * 300.0)
			if is_instance_valid(e) and not e.dead and e.has_method("apply_status"):
				e.apply_status("burn", 2.5)
			Fx.anim(get_parent(), e.global_position, "fx/spark.png", 15, 15, 24.0, 1.4, 0.0, Color(1.0, 0.6, 0.2), true)
			Fx.shake(get_tree(), 2.0)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < 20.0:
			b.destroy()


# ------------------------------------------------------------------ Vũ khí

func swap_weapon() -> bool:
	if dead or get_tree().paused or not is_physics_processing() or _swap_cd > 0.0 or weapons[1 - slot] == "":
		return false
	var g = get_tree().get_first_node_in_group("game")
	if g != null and not g.can_pause():
		return false
	slot = 1 - slot
	_swap_cd = SWAP_COOLDOWN
	_fire_timer = 0.1
	_ranged_shot_count = 0
	_melee_swing_count = 0
	_refresh_weapon_sprite()
	stats_changed.emit()
	return true


func interact_only() -> bool:
	if dead or get_tree().paused or not is_physics_processing():
		return false
	if interact_target != null and is_instance_valid(interact_target):
		interact_target.interact()
		return true
	if nearby_pickup != null and is_instance_valid(nearby_pickup):
		pick_weapon(nearby_pickup.weapon_id)
		nearby_pickup.queue_free()
		nearby_pickup = null
		return true
	return false


func _swap_or_pickup() -> void:
	if interact_target != null and is_instance_valid(interact_target):
		interact_target.interact()
		return
	if nearby_pickup != null:
		pick_weapon(nearby_pickup.weapon_id)
		nearby_pickup.queue_free()
		nearby_pickup = null
	elif weapons[1 - slot] != "":
		slot = 1 - slot
		_fire_timer = 0.1
		_refresh_weapon_sprite()
		stats_changed.emit()


## Trạng thái nhân vật để lưu lượt chơi dở
func snapshot() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"armor": armor, "max_armor": max_armor,
		"energy": energy, "max_energy": max_energy,
		"weapons": weapons.duplicate(), "slot": slot,
	}


## Nạp lại trạng thái đã lưu (gọi sau setup(), trước khi thêm vào cây cảnh)
func restore(d: Dictionary) -> void:
	max_hp = maxi(1, int(d.get("max_hp", max_hp)))
	hp = clampi(int(d.get("hp", max_hp)), 1, max_hp)
	max_armor = maxi(0, int(d.get("max_armor", max_armor)))
	armor = clampi(int(d.get("armor", max_armor)), 0, max_armor)
	max_energy = maxi(1, int(d.get("max_energy", max_energy)))
	energy = clampi(int(d.get("energy", max_energy)), 0, max_energy)
	var ws: Array = d.get("weapons", [])
	if ws.size() == 2 and str(ws[0]) != "":
		weapons = [str(ws[0]), str(ws[1])]
	slot = clampi(int(d.get("slot", 0)), 0, 1)
	if weapons[slot] == "":
		slot = 0


func pick_weapon(id: String) -> void:
	if weapons[1] == "":
		weapons[1] = id
		slot = 1
	else:
		var drop := Pickup.new()
		drop.kind = "weapon"
		drop.weapon_id = weapons[slot]
		drop.position = global_position + Vector2(0, 12)
		get_parent().add_child(drop)
		weapons[slot] = id
	var w := WeaponData.get_data(id)
	if not Global.discovered.has(id):
		Global.discover(id)
		Fx.float_text(get_parent(), global_position + Vector2(0, -36), "Vũ khí mới vào kho!", Color(0.7, 1.0, 0.7), 13)
	Fx.float_text(get_parent(), global_position + Vector2(0, -24), w.name, WeaponData.tier_color(id), 16)
	if int(w.tier) >= 4:
		Fx.particles(get_parent(), global_position, WeaponData.tier_color(id), 16, 90.0, 0.6, -40.0, 2.0)
	Sfx.play("pickup_weapon")
	_refresh_weapon_sprite()
	stats_changed.emit()


# ------------------------------------------------------------------ Máu, giáp

func _nearest_attacker_name() -> String:
	var best = null
	var best_d := 260.0
	if is_inside_tree():
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.dead:
				var d: float = global_position.distance_to(e.global_position)
				if d < best_d:
					best_d = d
					best = e
	if best != null and best.has_method("display_name"):
		return best.display_name()
	return "Giặc"


func take_damage(amount: int, source: String = "") -> void:
	if dead or downed or _invuln > 0.0 or _dash_time > 0.0 or _horse_time > 0.0:
		return
	if Net != null and Net.is_online() and not is_local:
		return
	if randf() < minf(0.12 * buff("bua_ho_menh"), 0.45):
		_invuln = 0.3
		Fx.float_text(get_parent(), global_position + Vector2(0, -22), "Né!", Color(0.7, 0.9, 1.0), 16)
		return
	var dmg: int = Global.scale_enemy_damage(amount)
	if dmg <= 0:
		return
	Global.run_last_hit = source if source != "" else _nearest_attacker_name()
	if buff("khien_chan") > 0:
		var ring := WaveRing.new()
		ring.position = global_position
		ring.radius = 70.0
		ring.damage = 4
		ring.color = Color(0.5, 0.75, 1.0)
		get_parent().add_child(ring)
	if buff("ho_tam_kinh") > 0 and _htk_cd <= 0.0 and armor > 0 and armor < dmg:
		armor = 0
		_armor_regen = ARMOR_REGEN_DELAY
		_htk_cd = 8.0
		_invuln = 0.5
		_flash = 0.5
		Sfx.play("hit_metal")
		Fx.float_text(get_parent(), global_position + Vector2(0, -26), "Hộ tâm kính!", Color(1.0, 0.88, 0.35), 15)
		Fx.burst(get_parent(), global_position, Color(1.0, 0.88, 0.35), 32.0, 0.35)
		Fx.particles(get_parent(), global_position, Color(1.0, 0.92, 0.45), 12, 95.0, 0.4, 0.0, 2.0)
		stats_changed.emit()
		return
	_invuln = 0.7
	_flash = 1.0
	_armor_regen = ARMOR_REGEN_DELAY
	var absorbed := mini(armor, dmg)
	armor -= absorbed
	hp -= dmg - absorbed
	_anim_lock_t = 0.0
	body.play("hurt")
	hurt.emit()
	Sfx.play("player_hurt")
	Fx.particles(get_parent(), global_position, Color(1, 0.3, 0.3) if absorbed < dmg else Color(0.7, 0.8, 1.0), 8, 80.0, 0.35)
	_check_death()


## Sát thương theo nhịp từ cháy / độc: trừ giáp trước, không làm bất tử tạm thời
func dot_damage(amount: int, kind: String) -> void:
	if dead or downed or _dash_time > 0.0 or _horse_time > 0.0:
		return
	if Net != null and Net.is_online() and not is_local:
		return
	var dmg: int = Global.scale_enemy_damage(amount)
	if dmg <= 0:
		return
	Global.run_last_hit = "Cháy" if kind == "burn" else "Độc"
	_flash = 0.6
	_armor_regen = ARMOR_REGEN_DELAY
	var absorbed := mini(armor, dmg)
	armor -= absorbed
	hp -= dmg - absorbed
	Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -20), "-%d" % dmg, Color(1, 0.6, 0.25) if kind == "burn" else Color(0.6, 1.0, 0.35), 12)
	_check_death()


func die() -> void:
	if dead:
		return
	hp = 0
	dead = true
	_anim_lock_t = 0.0
	status.clear()
	velocity = Vector2.ZERO
	weapon_pivot.visible = false
	aura.visible = false
	elephant.visible = false
	_horse_time = 0.0
	if iron_horse != null:
		iron_horse.visible = false
	body.position = Vector2(0, -6)
	body.rotation = 0.0
	body.play("down")
	body.modulate = Color(0.7, 0.6, 0.7)
	Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 14.0, 1.5)
	Sfx.play("player_die")
	died.emit()


func _check_death() -> void:
	if hp <= 0 and not dead and not downed:
		var can_down: bool = Net != null and Net.is_online() and maxi(Net.player_count(), Global.all_players().size()) > 1 and Global.free_revives <= 0
		if can_down:
			enter_downed(true)
		else:
			die()
	stats_changed.emit()


func enter_downed(broadcast: bool = true) -> void:
	if downed or dead:
		return
	downed = true
	hp = 0
	armor = 0
	revive_progress = 0.0
	_anim_lock_t = 0.0
	_dash_time = 0.0
	_horse_time = 0.0
	velocity = Vector2.ZERO
	if status != null:
		status.clear()
	if weapon_pivot != null:
		weapon_pivot.visible = false
	if aura != null:
		aura.visible = false
	if elephant != null:
		elephant.visible = false
	if iron_horse != null:
		iron_horse.visible = false
	if body != null:
		body.position = Vector2(0, -6)
		body.rotation = 0.0
		body.play("down")
		body.modulate = Color(0.85, 0.55, 0.55)
	if get_parent() != null:
		Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 14.0, 1.2)
		Fx.float_text(get_parent(), global_position + Vector2(0, -26), "Gục ngã!", Color(1.0, 0.4, 0.4), 16)
	Sfx.play("player_die")
	stats_changed.emit()
	if broadcast and Net != null and Net.is_online():
		Net.send_down_event("down", peer_id, {})


func revive_from_down(broadcast: bool = true) -> void:
	if not downed:
		return
	downed = false
	dead = false
	hp = 2
	armor = 0
	revive_progress = 0.0
	_invuln = 1.5
	_anim_lock_t = 0.0
	if status != null:
		status.clear()
	if body != null:
		body.rotation = 0.0
		body.modulate = Color.WHITE
		body.play("idle")
	if weapon_pivot != null:
		weapon_pivot.visible = true
	if get_parent() != null:
		Fx.burst(get_parent(), global_position, Color(0.55, 1.0, 0.65), 42.0, 0.45)
		Fx.float_text(get_parent(), global_position + Vector2(0, -26), "Đã được cứu!", Color(0.55, 1.0, 0.65), 16)
	Sfx.play("pickup_coin")
	stats_changed.emit()
	if broadcast and Net != null and Net.is_online():
		Net.send_down_event("revive", peer_id, {})


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	Fx.float_text(get_parent(), global_position + Vector2(0, -22), "+%d máu" % amount, Color(1, 0.45, 0.45))
	Fx.particles(get_parent(), global_position, Color(1, 0.5, 0.5), 10, 50.0, 0.6, -60.0, 2.0)
	stats_changed.emit()


func add_energy(amount: int) -> void:
	energy = mini(energy + amount, max_energy)
	stats_changed.emit()


func revive() -> void:
	dead = false
	downed = false
	revive_progress = 0.0
	Global.run_last_hit = ""
	hp = max_hp
	armor = max_armor
	energy = maxi(energy, max_energy / 2)
	_invuln = 2.5
	_anim_lock_t = 0.0
	_htk_cd = 0.0
	status.clear()
	body.rotation = 0.0
	body.modulate = Color.WHITE
	body.play("idle")
	weapon_pivot.visible = true
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.destroy()
	Fx.burst(get_parent(), global_position, Color(1, 0.9, 0.4), 60.0, 0.6)
	Fx.particles(get_parent(), global_position, Color(1, 0.9, 0.5), 30, 140.0, 0.8, -30.0, 2.0)
	stats_changed.emit()


# ------------------------------------------------------------------ Phúc lành

func buff(id: String) -> int:
	return int(Global.run_buffs.get(id, 0))


func damage_mult() -> float:
	return 1.0 + 0.2 * buff("ruou_thuoc")


func crit_chance() -> float:
	return 0.12 * buff("mat_than")


func apply_buff(id: String) -> void:
	Global.run_buffs[id] = buff(id) + 1
	match id:
		"banh_chung":
			max_hp += 2
			hp = max_hp
		"giap_dong":
			max_armor += 2
			armor = max_armor
		"linh_khi":
			max_energy += 60
			energy = max_energy
	Fx.particles(get_parent(), global_position, Color(1, 0.9, 0.5), 24, 120.0, 0.7, -40.0, 2.0)
	stats_changed.emit()


## Gọi khi hạ được 1 kẻ địch
func on_kill() -> void:
	if buff("huyet_sam") > 0 and randf() < 0.08 * buff("huyet_sam"):
		heal(1)


func burn_bonus_mult(target) -> int:
	if _burn_double_timer > 0.0 and target != null and is_instance_valid(target) and target.get("status") != null and target.status.has("burn"):
		return 2
	return 1


func on_hit_enemy(e) -> void:
	if is_instance_valid(e) and not e.dead:
		last_hit_enemy = e
		if _mark_timer > 0.0:
			e.set_meta("marked_until", Time.get_ticks_msec() + 3000)


# ------------------------------------------------------------------ Đồng bộ LAN (N2/N4/N6)

func _send_net_state() -> void:
	if Net == null or not Net.is_online():
		return
	var anim_name: String = body.animation if body != null else "idle"
	var flip: bool = body.flip_h if body != null else (aim_dir.x < 0.0)
	Net.send_player_state({
		"x": global_position.x,
		"y": global_position.y,
		"ax": aim_dir.x,
		"ay": aim_dir.y,
		"anim": anim_name,
		"flip": flip,
		"w": str(weapons[slot]),
		"dash": _dash_time,
		"horse": _horse_time,
		"buff": buff_timer,
		"twin": twin_timer,
		"hp": hp,
		"max_hp": max_hp,
		"armor": armor,
		"max_armor": max_armor,
		"downed": downed,
		"dead": dead,
		"rev": revive_progress,
	})


func apply_remote_state(st: Dictionary) -> void:
	if is_local:
		return
	if st.has("pos") and st["pos"] is Vector2:
		_remote_pos = st["pos"] as Vector2
	else:
		_remote_pos = Vector2(float(st.get("x", global_position.x)), float(st.get("y", global_position.y)))
	_has_remote_pos = true
	var ad := Vector2(float(st.get("ax", aim_dir.x)), float(st.get("ay", aim_dir.y)))
	if ad.length_squared() > 0.0001:
		aim_dir = ad.normalized()
	_remote_anim = str(st.get("anim", "idle"))
	if body != null:
		body.flip_h = bool(st.get("flip", aim_dir.x < 0.0))
	var wid: String = str(st.get("w", weapons[slot]))
	if wid != str(weapons[slot]):
		weapons[slot] = wid
		_refresh_weapon_sprite()
	_dash_time = float(st.get("dash", 0.0))
	_horse_time = float(st.get("horse", 0.0))
	buff_timer = float(st.get("buff", buff_timer))
	twin_timer = float(st.get("twin", twin_timer))
	hp = int(st.get("hp", hp))
	max_hp = maxi(1, int(st.get("max_hp", max_hp)))
	armor = int(st.get("armor", armor))
	max_armor = maxi(0, int(st.get("max_armor", max_armor)))
	var new_downed: bool = bool(st.get("downed", false))
	if new_downed and not downed:
		enter_downed(false)
	elif not new_downed and downed:
		revive_from_down(false)
	if st.has("rev") and downed:
		revive_progress = maxf(revive_progress, float(st.get("rev", 0.0)))
	var new_dead: bool = bool(st.get("dead", false))
	if new_dead and not dead:
		dead = true
		if body != null:
			body.play("down")
			body.modulate = Color(0.7, 0.6, 0.7)
		if weapon_pivot != null:
			weapon_pivot.visible = false
	elif not new_dead and dead:
		dead = false
		if body != null:
			body.modulate = Color.WHITE
			body.play("idle")


func play_remote_action(kind: String, data: Dictionary) -> void:
	if is_local or get_parent() == null:
		return
	var parent: Node = get_parent()
	match kind:
		"shoot":
			if not bool(data.get("silent", false)):
				Sfx.play(str(data.get("sfx", "shoot")))
			if body != null and not dead and not downed:
				_anim_lock_t = 0.18
				body.play("attack")
				body.frame = 0
			var ad := Vector2(float(data.get("ax", aim_dir.x)), float(data.get("ay", aim_dir.y)))
			if ad.length_squared() > 0.0001:
				aim_dir = ad.normalized()
			var shots_v: Variant = data.get("shots", [])
			if typeof(shots_v) == TYPE_ARRAY:
				for item in (shots_v as Array):
					if typeof(item) != TYPE_ARRAY:
						continue
					var s: Array = item
					if s.size() < 12:
						continue
					var b := Bullet.new()
					b.visual_only = true
					var bpos := Vector2(float(s[0]), float(s[1]))
					var bdir := Vector2(float(s[2]), float(s[3]))
					b.setup(true, bpos, bdir, float(s[4]), 0, float(s[5]), str(s[6]))
					b.spawn_origin = global_position
					b.pierce = int(s[7])
					b.explode_radius = float(s[8])
					b.homing = float(s[9])
					b.boomerang = bool(s[10])
					b.color = Color.html(str(s[11]))
					b.owner_node = self
					parent.add_child(b)
			_recoil = float(data.get("recoil", 1.5))
			var start := Vector2(float(data.get("mx", global_position.x)), float(data.get("my", global_position.y)))
			match str(data.get("muzzle", "")):
				"flash":
					Fx.anim(parent, start, "fx/muzzle.png", 12, 10, 24.0, 1.0, aim_dir.angle(), Color.WHITE, true, 6)
				"smoke":
					Fx.anim(parent, start, "fx/poof.png", 28, 28, 18.0, 0.55, 0.0, Color(1, 1, 1, 0.8))
				"fire":
					Fx.particles(parent, start, Color(1, 0.7, 0.3), 2, 60.0, 0.25, -60.0, 1.5, 40.0, aim_dir, Color(0.8, 0.2, 0.1))
		"melee":
			var off := Vector2(float(data.get("ox", 0.0)), float(data.get("oy", 0.0)))
			var ad2 := Vector2(float(data.get("ax", aim_dir.x)), float(data.get("ay", aim_dir.y)))
			if ad2.length_squared() > 0.0001:
				aim_dir = ad2.normalized()
			var reach: float = float(data.get("reach", 28.0))
			var arc: float = float(data.get("arc", 1.6))
			var style: String = str(data.get("style", "swing"))
			var col: Color = Color.html(str(data.get("col", "ffffffff")))
			if off == Vector2.ZERO:
				Sfx.play("slash")
				if body != null and not dead and not downed:
					_anim_lock_t = 0.18
					body.play("attack")
					body.frame = 0
				var tw := create_tween()
				match style:
					"thrust":
						tw.tween_property(self, "thrust", reach * 0.35, 0.06)
						tw.tween_property(self, "thrust", 0.0, 0.12)
					"spin":
						swing = 0.0
						tw.tween_property(self, "swing", TAU, 0.2)
						tw.tween_callback(func(): swing = 0.0)
					_:
						_swing_sign = -_swing_sign
						swing = -arc * 0.5 * _swing_sign
						tw.tween_property(self, "swing", arc * 0.5 * _swing_sign, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
						tw.tween_property(self, "swing", 0.0, 0.14)
				var wp_off: Vector2 = weapon_pivot.position if weapon_pivot != null else Vector2.ZERO
				Fx.slash(parent, global_position + wp_off, aim_dir, reach, arc, col, style)
			else:
				Fx.slash(parent, global_position + off, aim_dir, reach, arc, col, style)
			var waves_v: Variant = data.get("waves", [])
			if typeof(waves_v) == TYPE_ARRAY:
				for witem in (waves_v as Array):
					if typeof(witem) != TYPE_ARRAY:
						continue
					var ws: Array = witem
					if ws.size() < 8:
						continue
					var wb := Bullet.new()
					wb.visual_only = true
					wb.setup(true, Vector2(float(ws[0]), float(ws[1])), Vector2(float(ws[2]), float(ws[3])), float(ws[4]), 0, float(ws[5]), str(ws[6]))
					wb.spawn_origin = global_position + off
					wb.pierce = 99
					wb.color = Color.html(str(ws[7]))
					wb.owner_node = self
					parent.add_child(wb)
			if bool(data.get("fire", false)):
				for i in 5:
					var fp := global_position + Vector2.from_angle(aim_dir.angle() + lerpf(-arc / 2.0, arc / 2.0, float(i) / 4.0)) * reach * 0.8
					Fx.particles(parent, fp, Color(1, 0.75, 0.3), 4, 50.0, 0.4, -80.0, 2.0, 60.0, Vector2.UP, Color(0.8, 0.2, 0.1))
			var lpts_v: Variant = data.get("lpts", [])
			if typeof(lpts_v) == TYPE_ARRAY and not (lpts_v as Array).is_empty():
				var pts: Array = []
				for lp in (lpts_v as Array):
					if typeof(lp) == TYPE_ARRAY and (lp as Array).size() >= 2:
						pts.append(Vector2(float(lp[0]), float(lp[1])))
				if pts.size() >= 2:
					var ln := Lightning.new()
					ln.points = pts
					parent.add_child(ln)
		"beam":
			Sfx.play("shoot")
			var bstart := Vector2(float(data.get("sx", global_position.x)), float(data.get("sy", global_position.y)))
			var bend := Vector2(float(data.get("ex", global_position.x)), float(data.get("ey", global_position.y)))
			var bfx := Beam.new()
			bfx.position = bstart
			bfx.end_point = bend - bstart
			bfx.width = float(data.get("width", 3.0))
			bfx.color = Color.html(str(data.get("col", "4de6ffff")))
			parent.add_child(bfx)
			Fx.anim(parent, bend, "fx/spark.png", 15, 15, 24.0, 1.3, 0.0, bfx.color, true)
			_recoil = 3.0
		"wave":
			Sfx.play("skill")
			var rw := _RemoteWaveFx.new()
			rw.position = Vector2(float(data.get("x", global_position.x)), float(data.get("y", global_position.y)))
			rw.radius = float(data.get("radius", 110.0))
			rw.color = Color.html(str(data.get("col", "ffbf59ff")))
			rw.notes = bool(data.get("notes", false))
			parent.add_child(rw)
		"spikes":
			Sfx.play("explode")
			var spts_v: Variant = data.get("pts", [])
			if typeof(spts_v) == TYPE_ARRAY:
				var wr_par: WeakRef = weakref(parent)
				var spts: Array = spts_v
				for i in spts.size():
					var sp_item: Variant = spts[i]
					if typeof(sp_item) != TYPE_ARRAY or (sp_item as Array).size() < 2:
						continue
					var sp_pos := Vector2(float(sp_item[0]), float(sp_item[1]))
					get_tree().create_timer(0.05 * float(i)).timeout.connect(func():
						var par: Variant = wr_par.get_ref()
						if par == null:
							return
						var rs := _RemoteSpikeFx.new()
						rs.position = sp_pos
						(par as Node).add_child(rs))
		"skill":
			_play_remote_skill(data)


func _play_remote_skill(data: Dictionary) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var sk: String = str(data.get("skill", hero.get("skill", "")))
	var syn: int = int(data.get("syn", 0))
	var fam: String = str(data.get("fam", ""))
	var pos := Vector2(float(data.get("x", global_position.x)), float(data.get("y", global_position.y)))
	var dir := Vector2(float(data.get("ax", aim_dir.x)), float(data.get("ay", aim_dir.y)))
	if dir.length_squared() < 0.0001:
		dir = aim_dir
	else:
		dir = dir.normalized()
	aim_dir = dir
	Sfx.play("skill")
	if body != null and not dead and not downed:
		_anim_lock_t = 0.28
		body.play("skill")
		body.frame = 0
	var wr: WeakRef = weakref(parent)
	match sk:
		"coc_bach_dang":
			Fx.anim(parent, pos + Vector2(0, 6), "fx/ripple.png", 72, 34, 12.0, 1.6)
			Fx.particles(parent, pos, Color(0.5, 0.8, 1.0), 20, 110.0, 0.6, 150.0, 2.0, 180.0, Vector2.UP, Color(0.9, 1, 1))
			var s_life: float = 9.0 if syn == 2 else 6.0
			for i in 14:
				var ring: float = 30.0 if i % 2 == 0 else 50.0
				var ang: float = TAU * float(i) / 14.0
				var spos := pos + Vector2(cos(ang), sin(ang) * 0.8) * ring
				get_tree().create_timer(0.025 * float(i)).timeout.connect(func():
					var par: Variant = wr.get_ref()
					if par == null:
						return
					var st_fx := _RemoteStakeFx.new()
					st_fx.life_time = s_life
					st_fx.position = spos
					(par as Node).add_child(st_fx))
			if syn == 2:
				for i in 8:
					var ang2: float = TAU * float(i) / 8.0 + 0.2
					var spos2 := pos + Vector2(cos(ang2), sin(ang2) * 0.8) * 70.0
					get_tree().create_timer(0.025 * float(14 + i)).timeout.connect(func():
						var par: Variant = wr.get_ref()
						if par == null:
							return
						var st_fx2 := _RemoteStakeFx.new()
						st_fx2.life_time = s_life
						st_fx2.position = spos2
						(par as Node).add_child(st_fx2))
		"voi_chien":
			_dash_time = 0.55
			_dash_dir = dir
			Fx.burst(parent, pos, Color(1, 0.8, 0.5), 40.0, 0.4)
			Fx.float_text(parent, pos + Vector2(20 * dir.x, -30), "Hống!", Color(1, 0.9, 0.6), 20)
		"hich_tuong_si":
			var sig := DrumSigil.new()
			sig.position = pos + Vector2(0, 6)
			parent.add_child(sig)
			for k in 3:
				get_tree().create_timer(0.2 * float(k)).timeout.connect(func():
					var par: Variant = wr.get_ref()
					if par != null:
						Fx.burst(par as Node, pos, Color(1, 0.8, 0.3), 46.0 + float(k) * 10.0, 0.45))
			var ally_cnt: int = 4 if syn >= 1 else 3
			var wr_self: WeakRef = weakref(self)
			for i in ally_cnt:
				var pos2 := pos + Vector2.from_angle(TAU * float(i) / float(ally_cnt) - PI / 2.0) * 22.0
				get_tree().create_timer(0.3 + 0.12 * float(i)).timeout.connect(func():
					var par: Variant = wr.get_ref()
					if par == null:
						return
					Fx.anim(par as Node, pos2, "fx/poof.png", 28, 28, 18.0)
					var ra := _RemoteAllyFx.new()
					ra.owner_ref = wr_self
					ra.position = pos2
					(par as Node).add_child(ra))
			Fx.particles(parent, pos, Color(1, 0.85, 0.4), 24, 120.0, 0.7, -30.0, 2.0)
		"song_trung":
			_twin_syn = syn
			twin_timer = 11.0 if syn == 2 else (10.0 if syn == 1 else 8.0)
			Fx.anim(parent, pos + _twin_offset(), "fx/poof.png", 28, 28, 16.0, 1.2, 0.0, Color(1, 0.7, 0.85))
			Fx.particles(parent, pos, Color(1, 0.6, 0.8), 20, 110.0, 0.6, -30.0, 2.0)
			Fx.float_text(parent, pos + Vector2(0, -30), "Trưng Nhị!", Color(1, 0.75, 0.85), 18)
		"nam_quoc_son_ha":
			var rr := _RemoteReflectFx.new()
			add_child(rr)
			Fx.burst(parent, pos, Color(1, 0.85, 0.35), 50.0, 0.5)
		"thuan_thien_kiem":
			var ro := _RemoteOrbitFx.new()
			ro.count = 5 if syn == 2 else (4 if syn == 1 else 3)
			add_child(ro)
			Fx.burst(parent, pos, Color(1, 0.95, 0.6), 44.0, 0.45)
			Fx.particles(parent, pos, Color(1, 0.95, 0.6), 22, 120.0, 0.6)
		"hoa_hong":
			var pot_cnt: int = 12 if syn == 2 else (10 if syn == 1 else 8)
			for i in pot_cnt:
				var rfz := _RemoteFirePotFx.new()
				rfz.position = pos
				rfz.target = pos + Vector2.from_angle(TAU * float(i) / float(pot_cnt)) * 54.0
				parent.add_child(rfz)
		"hum_thieng":
			var rroar := _RemoteWaveFx.new()
			rroar.position = pos
			rroar.radius = 120.0
			rroar.color = Color(1, 0.65, 0.25)
			parent.add_child(rroar)
			var rtg := _RemoteTigerFx.new()
			rtg.position = pos
			rtg.dir = dir
			parent.add_child(rtg)
			Fx.float_text(parent, pos + Vector2(0, -30), "Gầm!", Color(1, 0.75, 0.3), 22)
		"keo_phao":
			var rtu := _RemoteTurretFx.new()
			rtu.position = pos + dir * 16.0
			parent.add_child(rtu)
		"than_toc":
			_than_toc_syn = syn
			buff_timer = 5.0
			Fx.burst(parent, pos, Color(1, 0.9, 0.3), 36.0, 0.35)
			Fx.particles(parent, pos, Color(1, 0.95, 0.5), 18, 140.0, 0.5, 0.0, 2.0)
		"ngua_sat":
			_horse_time = 0.65
			_dash_dir = dir
			_horse_syn = syn
			_horse_fire_cd = 0.0
			var fb_cnt: int = 8 if syn == 2 else (5 if syn == 1 else 3)
			var spread_deg: float = 56.0 if syn == 2 else (44.0 if syn == 1 else 30.0)
			for i in fb_cnt:
				var frac: float = 0.5 if fb_cnt <= 1 else float(i) / float(fb_cnt - 1)
				var ang: float = dir.angle() + deg_to_rad(lerpf(-spread_deg * 0.5, spread_deg * 0.5, frac))
				var fdir := Vector2.from_angle(ang)
				var fb := Bullet.new()
				fb.visual_only = true
				fb.setup(true, pos + fdir * 12.0, fdir, 260.0, 0, 0.55, "fireball")
				fb.spawn_origin = pos
				fb.owner_node = self
				parent.add_child(fb)
			Fx.burst(parent, pos, Color(1.0, 0.55, 0.2), 44.0, 0.4)
			Fx.float_text(parent, pos + Vector2(20 * dir.x, -30), "Hí! Phun lửa!", Color(1.0, 0.78, 0.28), 18)
	# Hiệu ứng ấn đồng điệu (chỉ hình ảnh, không gây sát thương kép)
	var imp: Dictionary = SynergyData.IMPRINTS.get(fam, {})
	if not imp.is_empty():
		match fam:
			"kiem":
				var n: int = int(imp.waves)
				for i in n:
					var d := Vector2.from_angle(TAU * float(i) / float(n))
					var b := Bullet.new()
					b.visual_only = true
					b.setup(true, pos + d * 12.0, d, 300.0, 0, 0.65, "sword_wave")
					b.pierce = 99
					b.color = SynergyData.family_color(fam)
					b.owner_node = self
					parent.add_child(b)
			"truong":
				var iwr := _RemoteWaveFx.new()
				iwr.position = pos
				iwr.radius = float(imp.radius)
				iwr.color = SynergyData.family_color(fam)
				parent.add_child(iwr)
			"hoa_khi":
				var cnt_f: int = int(imp.count)
				var dist_f: float = float(imp.dist)
				for i in cnt_f:
					var ifz := _RemoteFirePotFx.new()
					ifz.instant = true
					ifz.radius = float(imp.radius)
					ifz.life = float(imp.life)
					ifz.position = pos + Vector2.from_angle(TAU * float(i) / float(cnt_f) - PI / 2.0) * dist_f
					ifz.target = ifz.position
					parent.add_child(ifz)


# ------------------------------------------------------------------ Hiệu ứng kỹ năng chỉ hiển thị cho đồng đội LAN

class _RemoteWaveFx extends Node2D:
	var radius: float = 110.0
	var color: Color = Color(1.0, 0.8, 0.4)
	var notes: bool = false
	var _r: float = 6.0
	var _t: float = 0.0
	const DUR: float = 0.4

	func _ready() -> void:
		z_index = 4
		material = Art.additive()

	func _process(delta: float) -> void:
		_t += delta
		_r = lerpf(6.0, radius, minf(_t / DUR, 1.0))
		if _t >= DUR + 0.15:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a: float = 1.0 - clampf((_t - DUR * 0.6) / (DUR * 0.6), 0.0, 1.0)
		draw_arc(Vector2.ZERO, _r, 0.0, TAU, 64, Color(color, 0.85 * a), 3.0)
		draw_arc(Vector2.ZERO, _r * 0.82, 0.0, TAU, 64, Color(color, 0.4 * a), 2.0)
		for i in 16:
			var ang: float = TAU * float(i) / 16.0 + _t * 2.0
			var p := Vector2.from_angle(ang) * _r
			if notes:
				draw_circle(p, 2.0, Color(color, a))
				draw_line(p + Vector2(1.5, 0), p + Vector2(1.5, -6), Color(color, a), 1.0)
			else:
				draw_line(p * 0.92, p * 1.06, Color(1, 1, 0.8, a), 2.0)


class _RemoteSpikeFx extends Node2D:
	var _t: float = 0.0
	const LIFE: float = 0.7

	func _ready() -> void:
		z_index = 2
		if get_parent() != null:
			Fx.particles(get_parent(), global_position + Vector2(0, 4), Color(0.75, 0.68, 0.55), 6, 60.0, 0.4, 120.0, 2.0, 70.0)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var grow: float = minf(_t / 0.08, 1.0)
		var fade: float = 1.0 - clampf((_t - LIFE * 0.6) / (LIFE * 0.4), 0.0, 1.0)
		var h: float = 16.0 * grow * fade
		var base := Color(0.55, 0.5, 0.42)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 5), Vector2(-1, 5 - h), Vector2(1, 5)]), base.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 5), Vector2(3, 5 - h * 1.25), Vector2(8, 5)]), base)
		draw_line(Vector2(3, 5 - h * 1.25), Vector2(1, 5 - h * 0.5), base.lightened(0.35), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(4, 5), Vector2(8, 5 - h * 0.7), Vector2(10, 5)]), base.darkened(0.35))


class _RemoteStakeFx extends Node2D:
	var life_time: float = 6.0
	var _life: float = 6.0
	var _spr: AnimatedSprite2D
	var _sinking: bool = false

	func _ready() -> void:
		_life = life_time
		z_index = 1
		_spr = AnimatedSprite2D.new()
		_spr.sprite_frames = Art.frames("fx/stake.png", 14, 26, {
			"up": [[0, 1, 2], 16.0, false],
			"idle": [[2, 3], 3.0, true],
			"down": [[4, 5, 0], 10.0, false],
		})
		_spr.position = Vector2(0, -8)
		_spr.play("up")
		_spr.animation_finished.connect(func():
			if _spr.animation == "up":
				_spr.play("idle"))
		add_child(_spr)
		if get_parent() != null:
			Fx.particles(get_parent(), position, Color(0.55, 0.85, 1.0), 6, 60.0, 0.4, 160.0, 1.5, 50.0)

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.4 and not _sinking:
			_sinking = true
			_spr.play("down")
		if _life <= 0.0:
			queue_free()


class _RemoteAllyFx extends Node2D:
	var owner_ref: WeakRef = null
	var _life: float = 10.0
	var _spr: AnimatedSprite2D

	func _ready() -> void:
		z_index = 1
		var sh := Sprite2D.new()
		sh.texture = Art.tex("fx/shadow.png")
		sh.position = Vector2(0, 7)
		sh.z_index = -2
		add_child(sh)
		_spr = AnimatedSprite2D.new()
		_spr.sprite_frames = Art.strip("fx/ally.png", 18, 20, 10.0, true)
		_spr.position = Vector2(0, -3)
		_spr.play("play")
		add_child(_spr)

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			if get_parent() != null:
				Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0)
			queue_free()
			return
		if _life < 1.0:
			_spr.modulate.a = 0.5 + 0.5 * sin(_life * 30.0)
		var owner_obj: Variant = owner_ref.get_ref() if owner_ref != null else null
		if owner_obj != null and owner_obj is Node2D:
			var to_p: Vector2 = (owner_obj as Node2D).global_position - global_position
			if to_p.length() > 32.0:
				position += to_p.normalized() * 110.0 * delta
				_spr.flip_h = to_p.x < 0.0
				_spr.speed_scale = 1.0
			else:
				_spr.speed_scale = 0.0


class _RemoteReflectFx extends Node2D:
	const TEXT := "NAM QUỐC SƠN HÀ NAM ĐẾ CƯ  "
	var life: float = 5.0
	var radius: float = 30.0
	var _t: float = 0.0

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a: float = clampf(life / 0.5, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1, 0.85, 0.35, 0.7 * a), 2.0)
		draw_arc(Vector2.ZERO, radius - 4.0, 0.0, TAU, 48, Color(1, 0.85, 0.35, 0.3 * a), 1.0)
		var f: Font = Art.font()
		var n: int = TEXT.length()
		for i in n:
			var ang: float = _t * 1.2 + TAU * float(i) / float(n)
			var p := Vector2.from_angle(ang) * (radius + 6.0)
			draw_set_transform(p, ang + PI / 2.0, Vector2.ONE)
			draw_string(f, Vector2(-3, 4), TEXT[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.45, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _RemoteOrbitFx extends Node2D:
	var life: float = 6.0
	var radius: float = 30.0
	var count: int = 3
	var _blades: Array = []
	var _t: float = 0.0

	func _ready() -> void:
		z_index = 5
		for i in count:
			var s := Sprite2D.new()
			s.texture = Art.tex("weapons/thuan_thien.png")
			s.material = Art.additive()
			s.modulate = Color(1, 0.95, 0.7)
			add_child(s)
			_blades.append(s)

	func _process(delta: float) -> void:
		_t += delta
		life -= delta
		if life <= 0.0:
			if get_parent() != null and get_parent().get_parent() != null:
				Fx.particles(get_parent().get_parent(), global_position, Color(1, 0.9, 0.5), 16, 100.0, 0.5)
			queue_free()
			return
		for i in _blades.size():
			var ang: float = _t * 5.0 + TAU * float(i) / float(maxi(1, _blades.size()))
			var s: Sprite2D = _blades[i]
			s.position = Vector2.from_angle(ang) * radius
			s.rotation = ang + PI / 2.0
		modulate.a = clampf(life / 0.4, 0.0, 1.0)


class _RemoteFirePotFx extends Node2D:
	var target: Vector2 = Vector2.ZERO
	var radius: float = 20.0
	var life: float = 4.0
	var instant: bool = false
	var _burning: bool = false
	var _pt: float = 0.0
	var _pot: Sprite2D

	func _ready() -> void:
		z_index = 1
		_pot = Sprite2D.new()
		_pot.texture = Art.tex("fx/fire_pot.png")
		add_child(_pot)
		if instant:
			_ignite()
			return
		var tw := create_tween()
		tw.tween_property(self, "position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_pot, "position:y", -14.0, 0.17).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(_pot, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
		tw.tween_callback(_ignite)

	func _ignite() -> void:
		_burning = true
		_pot.visible = false
		if get_parent() != null:
			Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 20.0, 0.8)
		add_child(Art.light(Color(1, 0.55, 0.2), 1.0, 0.9))

	func _process(delta: float) -> void:
		if not _burning:
			return
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		_pt -= delta
		if _pt <= 0.0 and get_parent() != null:
			_pt = 0.1
			var off := Vector2.from_angle(randf() * TAU) * randf() * radius
			Fx.particles(get_parent(), global_position + off, Color(1, 0.7, 0.25), 2, 30.0, 0.5, -70.0, 2.0, 30.0, Vector2.UP, Color(0.8, 0.15, 0.1))
		queue_redraw()

	func _draw() -> void:
		if not _burning:
			return
		var a: float = clampf(life / 0.5, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(1, 0.4, 0.1, 0.22 * a))
		draw_circle(Vector2.ZERO, radius * 0.6, Color(1, 0.7, 0.2, 0.22 * a))


class _RemoteTigerFx extends Node2D:
	var dir: Vector2 = Vector2.RIGHT
	var _life: float = 0.9
	var _spr: AnimatedSprite2D
	var _dt: float = 0.0

	func _ready() -> void:
		z_index = 3
		_spr = AnimatedSprite2D.new()
		_spr.sprite_frames = Art.strip("fx/tiger.png", 40, 24, 14.0, true)
		_spr.flip_h = dir.x < 0.0
		_spr.play("play")
		_spr.modulate = Color(1, 0.9, 0.6, 0.95)
		add_child(_spr)
		add_child(Art.light(Color(1, 0.7, 0.3), 1.0, 0.8))

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			if get_parent() != null:
				Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, 1.4, 0.0, Color(1, 0.8, 0.5))
			queue_free()
			return
		position += dir * 300.0 * delta
		_dt -= delta
		if _dt <= 0.0 and get_parent() != null:
			_dt = 0.05
			Fx.afterimage(get_parent(), _spr, global_position, Color(1, 0.6, 0.2, 0.5), 0.25)


class _RemoteTurretFx extends Node2D:
	var life: float = 9.0
	var _spr: AnimatedSprite2D

	func _ready() -> void:
		z_index = 1
		_spr = AnimatedSprite2D.new()
		_spr.sprite_frames = Art.frames("fx/turret.png", 30, 20, {"idle": [[0], 1.0, false], "fire": [[1, 0], 10.0, false]})
		_spr.play("idle")
		add_child(_spr)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if get_parent() != null:
			Fx.anim(get_parent(), position, "fx/dust.png", 10, 10, 12.0, 2.5)

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			if get_parent() != null:
				Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, 1.2)
			queue_free()
			return
		if life < 1.0:
			modulate.a = 0.5 + 0.5 * sin(life * 30.0)
