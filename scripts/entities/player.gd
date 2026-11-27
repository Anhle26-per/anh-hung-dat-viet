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
const WeaponEvolutions = preload("res://scripts/data/weapon_evolutions.gd")
const HeroSkillsExt = preload("res://scripts/data/hero_skills_ext.gd")
const SpiritBlade = preload("res://scripts/effects/spirit_blade.gd")
const SkillCastFx = preload("res://scripts/effects/skill_fx.gd")

const RADIUS := 7.0
const AUTO_AIM_RANGE := 230.0
const ARMOR_REGEN_DELAY := 3.5
const SPRINT_SPEED_MULT := 1.48
const SPRINT_ENERGY_COST := 18.0
const DODGE_DASH_DUR := 0.16
const DODGE_DASH_IFRAME := 0.18
const DODGE_DASH_CD := 1.6

const MOUNTS := {
	"voi_chien_mount": {"name": "Voi Chiến", "hp": 12, "speed": 1.15, "color": Color(0.85, 0.72, 0.52)},
	"ngua_sat_mount": {"name": "Ngựa Sắt", "hp": 10, "speed": 1.32, "color": Color(0.95, 0.55, 0.25)},
	"xe_tang_mount": {"name": "Xe Tăng Chiến", "hp": 18, "speed": 0.92, "color": Color(0.45, 0.65, 0.35)},
}

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
var _cast_pulse_t: float = 0.0
var _cast_pulse_col: Color = Color(1.0, 0.88, 0.7)
var _kinetic_charge: float = 0.0
var _frenzy_timer: float = 0.0
var _lightning_cd: float = 0.0
var _gold_armor_bonus: int = 0
var _coin_armor_acc: int = 0
var _elem_idx: int = 0
var _elem_cd: float = 0.0
var _qigong_shots: int = 0
var _spirit_blade: Node2D = null
var sprinting: bool = false
var _sprint_drain_acc: float = 0.0
var _sprint_fx_t: float = 0.0
var _lively_t: float = 0.0
var _step_dust_t: float = 0.0
var _footstep_decal_t: float = 0.0
var _idle_sparkle_t: float = 0.75
var _lobby_test_backup: Array = []

# v2.0.0 Shared Contracts & Combat state
var dash_cd_left: float = 0.0
var charge_ratio: float = 0.0
var mount_id: String = ""
var mount_hp: int = 0
var mount_max_hp: int = 0
var in_trench: bool = false
var in_stealth_bush: bool = false
var in_water: bool = false
var melee_combo_phase: int = 0

var _dodge_dash_t: float = 0.0
var _dodge_dash_dir: Vector2 = Vector2.RIGHT
var _dodge_afterimage_t: float = 0.0
var _lunge_t: float = 0.0
var _lunge_dir: Vector2 = Vector2.RIGHT
var _charging: bool = false
var _charge_weapon_snap: Dictionary = {}
var _melee_combo: int = 0
var _melee_combo_reset_t: float = 0.0
var _qi_slash_cd: float = 0.0
var _statue_cd: float = 0.0
var _total_attack_count: int = 0
var _stealth_skill_t: float = 0.0
var _stealth_skill_active: bool = false
var _post_dash_boost: bool = false
var _passive_kill_count: int = 0
var _tg_bonus_hp: int = 0
var mount_sprite: AnimatedSprite2D = null

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

	mount_sprite = AnimatedSprite2D.new()
	mount_sprite.position = Vector2(0, -2)
	mount_sprite.z_index = -1
	mount_sprite.visible = false
	add_child(mount_sprite)

	_mat = Art.flash_material()
	body = AnimatedSprite2D.new()
	var hero_tex: Texture2D = Art.tex("heroes/%s.png" % hero_id)
	var frame_count: int = int(float(hero_tex.get_width()) / 32.0) if hero_tex != null else 9
	var anims: Dictionary
	if frame_count >= 28:
		anims = {
			"idle": [[0, 1, 16, 2, 17, 3], 5.0, true],
			"walk": [[4, 18, 5, 19, 6, 20, 7, 21], 13.5, true],
			"hurt": [[8], 1.0, false],
			"attack": [[9, 10, 22, 23], 16.0, false],
			"skill": [[24, 11, 12, 25], 11.0, false],
			"dash": [[26, 27], 16.0, false],
			"down": [[13, 14, 15], 8.0, false],
		}
	else:
		anims = {
			"idle": [[0, 1, 2, 3], 3.0, true],
			"walk": [[4, 5, 6, 7], 10.0, true],
			"hurt": [[8], 1.0, false],
			"attack": [[9, 10] if frame_count >= 11 else [4, 5], 14.0, false],
			"skill": [[11, 12] if frame_count >= 13 else [0, 1], 10.0, false],
			"dash": [[4, 5], 14.0, false],
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
	_sync_weapon_slots()
	if buff("phi_kiem") > 0:
		_ensure_spirit_blade()
	sync_gold_armor()
	if Global != null and str(Global.get("active_mount")) != "" and int(Global.get("active_mount_hp")) > 0:
		board_mount(str(Global.get("active_mount")), int(Global.get("active_mount_hp")))
	elif mount_id != "" and mount_hp > 0:
		_refresh_mount_visual()


func max_weapon_slots() -> int:
	return 3 if buff("song_kiem_hop") > 0 else 2


func _sync_weapon_slots() -> void:
	var target_n: int = max_weapon_slots()
	while weapons.size() < target_n:
		weapons.append("")
	if weapons.size() > target_n and target_n >= 2:
		weapons = weapons.slice(0, target_n)
	slot = clampi(slot, 0, maxi(0, weapons.size() - 1))


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
	if Global != null and Global.has_method("is_weapon_evolved") and Global.is_weapon_evolved(id):
		var bonus: Dictionary = WeaponEvolutions.evolved_bonus(id)
		out = out.duplicate()
		out["damage"] = maxi(1, int(round(float(out.get("damage", 1)) * float(bonus.get("dmg_mult", 1.35)))))
		out["pierce"] = int(out.get("pierce", 0)) + int(bonus.get("pierce_add", 1))
		out["evolved_scale"] = float(bonus.get("scale_mult", 1.28))
		out["name"] = str(out.get("name", id)) + str(bonus.get("suffix", " ★Tiến Hóa"))
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("melee_master") and str(out.get("type", "")) == "melee":
		out = out.duplicate()
		out["damage"] = maxi(1, int(round(float(out.get("damage", 1)) * 1.5)))
		out["reach"] = float(out.get("reach", 32.0)) * 1.35
		out["cooldown"] = float(out.get("cooldown", 0.35)) * 0.75
	return out


func current_weapon() -> Dictionary:
	return effective_weapon(weapons[slot])


const SWAP_COOLDOWN := 0.15
var _swap_cd := 0.0
var _drop_input_guard: bool = false


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
	var is_boss_motif: bool = bool(WeaponData.get_data(id).get("boss_motif", false))
	if (is_starter and r >= 5) or is_boss_motif:
		var lcol: Color = Color("ff384c") if is_boss_motif else Color(1.0, 0.86, 0.35)
		if _weapon_light == null and weapon_pivot != null:
			_weapon_light = Art.light(lcol, 0.85 if is_boss_motif else 0.75, 0.65 if is_boss_motif else 0.6)
			weapon_pivot.add_child(_weapon_light)
		if _weapon_light != null:
			_weapon_light.color = lcol
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
	_frenzy_timer = maxf(_frenzy_timer - delta, 0.0)
	_lightning_cd = maxf(_lightning_cd - delta, 0.0)
	_elem_cd = maxf(_elem_cd - delta, 0.0)
	dash_cd_left = maxf(dash_cd_left - delta, 0.0)
	_dodge_afterimage_t = maxf(_dodge_afterimage_t - delta, 0.0)
	_qi_slash_cd = maxf(_qi_slash_cd - delta, 0.0)
	_statue_cd = maxf(_statue_cd - delta, 0.0)
	if _melee_combo_reset_t > 0.0:
		_melee_combo_reset_t -= delta
		if _melee_combo_reset_t <= 0.0:
			_melee_combo = 0
	if _stealth_skill_t > 0.0:
		_stealth_skill_t -= delta
		if _stealth_skill_t <= 0.0 and _stealth_skill_active:
			_stealth_skill_active = false
			in_stealth_bush = false
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
		_armor_regen = 0.85 if hero_id == "ly_thuong_kiet" else 1.0
		stats_changed.emit()

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Global.joy_vector != Vector2.ZERO:
		move = Global.joy_vector

	var want_dash: bool = (InputMap.has_action("dash") and Input.is_action_just_pressed("dash")) or bool(Global.get("touch_dash"))
	if Global.get("touch_dash") != null:
		Global.set("touch_dash", false)
	if want_dash and dash_cd_left <= 0.0 and _dodge_dash_t <= 0.0 and _dash_time <= 0.0 and _horse_time <= 0.0:
		_start_dodge_dash(move)

	var want_merge: bool = (InputMap.has_action("merge_weapon") and Input.is_action_just_pressed("merge_weapon")) or bool(Global.get("touch_merge"))
	if Global.get("touch_merge") != null:
		Global.set("touch_merge", false)
	if want_merge:
		try_merge_weapon()

	var want_drop: bool = (bool(Global.get("touch_drop_weapon")) or (InputMap.has_action("drop_weapon") and Input.is_action_just_pressed("drop_weapon"))) and not _drop_input_guard
	_drop_input_guard = false
	if Global.get("touch_drop_weapon") != null:
		Global.set("touch_drop_weapon", false)
	if want_drop and is_inside_tree() and get_tree().get_first_node_in_group("lobby") == null:
		drop_current_weapon()

	sprinting = false
	if _dodge_dash_t > 0.0:
		_dodge_dash_t = maxf(_dodge_dash_t - delta, 0.0)
		velocity = _dodge_dash_dir * speed * 3.4
		if _dodge_afterimage_t <= 0.0 and get_parent() != null and body != null:
			_dodge_afterimage_t = 0.032
			Fx.afterimage(get_parent(), body, global_position, Color(0.55, 0.92, 1.0, 0.65), 0.22)
	elif _lunge_t > 0.0:
		_lunge_t = maxf(_lunge_t - delta, 0.0)
		velocity = _lunge_dir * speed * 1.85
	elif _dash_time > 0.0:
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
		if _frenzy_timer > 0.0:
			mult *= 1.15
		if Global != null and Global.has_method("has_mutator") and Global.has_mutator("hyper_speed"):
			mult *= 1.3
		match hero_id:
			"ngo_quyen":
				if in_water:
					mult *= 1.18
			"quang_trung":
				mult *= 1.15
			"thanh_giong":
				mult *= 1.10
		if mount_id != "" and mount_hp > 0:
			mult *= float(MOUNTS.get(mount_id, {}).get("speed", 1.15))
		var inf_energy: bool = Global != null and Global.has_method("has_mutator") and Global.has_mutator("infinite_energy")
		if move.length_squared() > 0.01 and Input.is_action_pressed("sprint"):
			var in_lobby: bool = is_inside_tree() and get_tree().get_first_node_in_group("lobby") != null
			if in_lobby or inf_energy or energy > 0:
				sprinting = true
				mult *= SPRINT_SPEED_MULT
				if not in_lobby and not inf_energy:
					_sprint_drain_acc += delta * SPRINT_ENERGY_COST
					if _sprint_drain_acc >= 1.0:
						var drain: int = int(_sprint_drain_acc)
						_sprint_drain_acc -= float(drain)
						energy = maxi(0, energy - drain)
						stats_changed.emit()
			elif _msg_cd <= 0.0 and get_parent() != null:
				_msg_cd = 1.2
				Fx.float_text(get_parent(), global_position + Vector2(0, -18), "Hết năng lượng!", Color(0.5, 0.85, 1.0), 12)
		velocity = move * speed * mult
	move_and_slide()
	if buff("tich_luc") > 0:
		if velocity.length() > 10.0 and _kinetic_charge < 100.0:
			_kinetic_charge = minf(100.0, _kinetic_charge + delta * 55.0)
		queue_redraw()
	if _frenzy_timer > 0.0 and _fx_t <= 0.0 and get_parent() != null and randf() < 0.45:
		Fx.particles(get_parent(), global_position + Vector2(randf_range(-5, 5), 2), Color(1.0, 0.28, 0.32), 2, 42.0, 0.25, -45.0, 1.4, 35.0)
	_update_aim(move)

	var want_attack := Global.touch_attack
	if not Global.touch_mode and Input.is_action_pressed("attack"):
		want_attack = true
	var cw_atk := current_weapon()
	var charge_max: float = float(cw_atk.get("charge_max", 0.0))
	if charge_max > 0.0 and _dash_time <= 0.0 and _horse_time <= 0.0 and _dodge_dash_t <= 0.0:
		if want_attack:
			if _fire_timer <= 0.0:
				_charging = true
				_charge_weapon_snap = cw_atk
				var cspd: float = (1.0 / charge_max) * (1.25 if _frenzy_timer > 0.0 else 1.0) * pow(1.15, buff("giay_co"))
				charge_ratio = minf(1.0, charge_ratio + delta * cspd)
				queue_redraw()
		elif _charging:
			_release_charged_attack(cw_atk, charge_ratio)
			_charging = false
			charge_ratio = 0.0
			queue_redraw()
	else:
		if _charging:
			_charging = false
			charge_ratio = 0.0
			queue_redraw()
		if want_attack and _dash_time <= 0.0 and _horse_time <= 0.0 and _dodge_dash_t <= 0.0:
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


func _start_dodge_dash(move: Vector2) -> void:
	_dodge_dash_dir = move.normalized() if move.length_squared() > 0.01 else aim_dir.normalized()
	if _dodge_dash_dir.length_squared() < 0.01:
		_dodge_dash_dir = Vector2.RIGHT
	_dodge_dash_t = DODGE_DASH_DUR
	_invuln = maxf(_invuln, DODGE_DASH_IFRAME)
	dash_cd_left = DODGE_DASH_CD
	_dodge_afterimage_t = 0.0
	_anim_lock_t = 0.0
	if body != null and not dead:
		body.play("dash")
		body.frame = 0
	if hero_id == "quang_trung":
		_post_dash_boost = true
	Sfx.play("slash")
	if get_parent() != null:
		Fx.anim(get_parent(), global_position + Vector2(0, 6), "fx/dust.png", 10, 10, 14.0, 1.3)
		Fx.particles(get_parent(), global_position, Color(0.55, 0.92, 1.0), 8, 70.0, 0.25)
		if body != null:
			Fx.afterimage(get_parent(), body, global_position, Color(0.55, 0.92, 1.0, 0.7), 0.22)


func _unhandled_input(event: InputEvent) -> void:
	if not is_local or dead or downed or get_tree().paused or not is_physics_processing():
		return
	if event.is_action_pressed("swap_weapon"):
		if swap_weapon():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if interact_only():
			get_viewport().set_input_as_handled()
	elif InputMap.has_action("merge_weapon") and event.is_action_pressed("merge_weapon"):
		if try_merge_weapon():
			get_viewport().set_input_as_handled()
	elif InputMap.has_action("drop_weapon") and event.is_action_pressed("drop_weapon"):
		if get_tree().get_first_node_in_group("lobby") == null and drop_current_weapon():
			_drop_input_guard = true
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_lively_t += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_mat.set_shader_parameter("flash", _flash)
	_recoil = move_toward(_recoil, 0.0, delta * 40.0)
	if dead or downed:
		sprinting = false
		if body != null:
			body.scale = Vector2.ONE
		if body.animation != "down":
			body.play("down")
		if weapon_pivot != null:
			weapon_pivot.visible = false
		if (Net != null and Net.is_online()) or display_name != "" or downed:
			queue_redraw()
		return

	_anim_lock_t = maxf(_anim_lock_t - delta, 0.0)
	_cast_pulse_t = maxf(_cast_pulse_t - delta, 0.0)
	var face_left := aim_dir.x < 0.0
	body.flip_h = face_left
	elephant.flip_h = face_left
	if iron_horse != null:
		iron_horse.flip_h = face_left
	var moving := false
	if not is_local:
		moving = global_position.distance_to(_remote_pos) > 2.5 or _remote_anim == "walk"
		if _anim_lock_t <= 0.0 and (body.animation != "hurt" or _flash <= 0.1):
			if _remote_anim != "" and body.animation != _remote_anim:
				body.play(_remote_anim)
	else:
		moving = velocity.length() > 5.0
		if _anim_lock_t <= 0.0 and (body.animation != "hurt" or _flash <= 0.1):
			if _dodge_dash_t > 0.0:
				if body.animation != "dash":
					body.play("dash")
				body.speed_scale = 1.0
			else:
				body.play("walk" if moving else "idle")
				body.speed_scale = 1.45 if (sprinting and moving) else 1.0

	# Co giãn & nhịp thở / bước chạy sinh động cho nhân vật & vũ khí
	var breath: float = sin(_lively_t * 3.6)
	var step_wave: float = absf(sin(_lively_t * (16.0 if sprinting else 12.0)))
	var body_bob_y: float = 0.0
	var b_sx: float = 1.0
	var b_sy: float = 1.0
	if _cast_pulse_t > 0.0:
		var cp: float = 1.0 - clampf(_cast_pulse_t / 0.44, 0.0, 1.0)
		if cp < 0.28:
			var k: float = sin((cp / 0.28) * PI * 0.5)
			b_sx = 1.0 + 0.14 * k
			b_sy = 1.0 - 0.12 * k
		else:
			var k2: float = sin(((cp - 0.28) / 0.72) * PI)
			b_sx = 1.0 - 0.10 * k2
			b_sy = 1.0 + 0.15 * k2
	elif _anim_lock_t > 0.0:
		var punch: float = clampf(_anim_lock_t * 3.5, 0.0, 1.0)
		b_sx = 1.0 + 0.10 * punch
		b_sy = 1.0 - 0.09 * punch
	elif _dodge_dash_t > 0.0:
		b_sx = 1.12
		b_sy = 0.90
	elif moving and _dash_time <= 0.0 and _horse_time <= 0.0:
		body_bob_y = -step_wave * (2.6 if sprinting else 1.6)
		var amp: float = 0.065 if sprinting else 0.042
		b_sx = 1.0 + (0.5 - step_wave) * amp
		b_sy = 1.0 - (0.5 - step_wave) * amp
	else:
		b_sx = 1.0 - breath * 0.028
		b_sy = 1.0 + breath * 0.032
		body_bob_y = breath * 0.4
	body.scale = Vector2(b_sx, b_sy)
	if light != null:
		if _cast_pulse_t > 0.0:
			var lp: float = sin(clampf(_cast_pulse_t / 0.44, 0.0, 1.0) * PI)
			light.energy = lerpf(0.85, 1.45, lp)
			light.texture_scale = lerpf(2.8, 3.6, lp)
			light.color = Color(1.0, 0.88, 0.7).lerp(_cast_pulse_col, lp * 0.65)
		else:
			light.energy = 0.85
			light.texture_scale = 2.8
			light.color = Color(1.0, 0.88, 0.7)

	# vũ khí xoay theo hướng ngắm + nhịp vung nhẹ khi đứng/chạy
	var w := current_weapon()
	var id: String = weapons[slot]
	weapon_pivot.visible = _dash_time <= 0.0 and _horse_time <= 0.0 and id != ""
	var wp_bob_y: float = (-step_wave * 1.1) if moving else (breath * 0.7)
	var wp_sway: float = (sin(_lively_t * 11.0) * 0.06) if moving else (cos(_lively_t * 3.2) * 0.025)
	weapon_pivot.position = Vector2(-2.0 if face_left else 2.0, 1.0 + wp_bob_y)
	weapon_pivot.rotation = aim_dir.angle() + (swing + wp_sway) * (-1.0 if face_left else 1.0)
	weapon_pivot.z_index = 1
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

	# hiệu ứng kỹ năng, bụi bước chân & lấp lánh đứng yên
	_fx_t -= delta
	_sprint_fx_t -= delta
	_step_dust_t -= delta
	_footstep_decal_t -= delta
	_idle_sparkle_t -= delta
	if _dash_time > 0.0:
		elephant.visible = true
		elephant.play("play")
		if iron_horse != null:
			iron_horse.visible = false
		if mount_sprite != null:
			mount_sprite.visible = false
		body.position = Vector2(-1, -17)
		if _fx_t <= 0.0 and visible and get_parent() != null:
			_fx_t = 0.04
			Fx.anim(get_parent(), global_position + Vector2(-_dash_dir.x * 12.0, 10 + randf_range(-3, 3)), "fx/dust.png", 10, 10, 12.0, 1.5)
			Fx.afterimage(get_parent(), elephant, global_position, Color(1, 0.6, 0.4, 0.5), 0.25)
	elif _horse_time > 0.0:
		elephant.visible = false
		if iron_horse != null:
			iron_horse.visible = true
			iron_horse.play("play")
		if mount_sprite != null:
			mount_sprite.visible = false
		body.position = Vector2(-1, -17)
		if _fx_t <= 0.0 and visible and get_parent() != null:
			_fx_t = 0.04
			Fx.particles(get_parent(), global_position + Vector2(-_dash_dir.x * 10.0, 6), Color(1.0, 0.65, 0.2), 4, 65.0, 0.3, -40.0, 1.8, 50.0, -_dash_dir, Color(0.85, 0.2, 0.1))
			if iron_horse != null:
				Fx.afterimage(get_parent(), iron_horse, global_position, Color(1.0, 0.55, 0.2, 0.55), 0.25)
	else:
		elephant.visible = false
		if iron_horse != null:
			iron_horse.visible = false
		if mount_id != "" and mount_hp > 0:
			if mount_sprite != null:
				mount_sprite.visible = true
				mount_sprite.flip_h = face_left
				if moving:
					mount_sprite.play("play")
				else:
					mount_sprite.stop()
			body.position = Vector2(0, -14 + body_bob_y * 0.5)
		else:
			if mount_sprite != null:
				mount_sprite.visible = false
			body.position = Vector2(0, -6 + body_bob_y)
		if visible and get_parent() != null:
			if sprinting and moving and _sprint_fx_t <= 0.0:
				_sprint_fx_t = 0.09
				Fx.anim(get_parent(), global_position + Vector2(randf_range(-4.0, 4.0), 6.0), "fx/dust.png", 10, 10, 14.0, 0.95, 0.0, Color(0.75, 0.92, 1.0, 0.85))
				Fx.particles(get_parent(), global_position + Vector2(0.0, 4.0), Color(0.42, 0.86, 1.0), 2, 42.0, 0.22, -20.0, 1.4, 40.0, -velocity.normalized())
				Fx.afterimage(get_parent(), body, global_position, Color(0.38, 0.84, 1.0, 0.35), 0.16)
			if sprinting and moving and velocity.length() > speed * 1.1 and mount_id == "" and _footstep_decal_t <= 0.0:
				_footstep_decal_t = 0.22
				Fx.decal(get_parent(), global_position + Vector2(randf_range(-2.0, 2.0), 7.0), "footstep", Color(0.75, 0.72, 0.65, 0.55), 0.9, velocity.angle())
			elif moving and not sprinting and _step_dust_t <= 0.0:
				_step_dust_t = 0.24
				Fx.anim(get_parent(), global_position + Vector2(randf_range(-3.0, 3.0), 7.0), "fx/dust.png", 10, 10, 14.0, 0.72, 0.0, Color(0.92, 0.88, 0.8, 0.55))
			elif not moving and _idle_sparkle_t <= 0.0:
				_idle_sparkle_t = randf_range(0.95, 1.65)
				var hcol: Color = hero.get("color", Color(1.0, 0.88, 0.45))
				Fx.particles(get_parent(), global_position + Vector2(randf_range(-6.0, 6.0), -8.0), hcol, 2, 22.0, 0.45, -18.0, 1.3)
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
	if charge_ratio > 0.02 and not dead and not downed:
		var cc: Color = Color(1.0, 0.92, 0.35) if charge_ratio >= 0.9 else Color(0.45, 0.88, 1.0)
		draw_arc(Vector2(0, 2), 13.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(charge_ratio, 0.0, 1.0), 24, Color(cc, 0.85), 1.8)
	if in_stealth_bush and not dead and not downed:
		draw_arc(Vector2(0, 4), 12.0, 0.0, TAU, 20, Color(0.45, 0.88, 0.55, 0.45), 1.2)
	if in_trench and not dead and not downed:
		draw_arc(Vector2(0, 5), 11.0, 0.0, PI, 16, Color(0.76, 0.62, 0.42, 0.55), 1.4)
	if buff("tich_luc") > 0 and not dead and not downed:
		var kpct: float = clampf(_kinetic_charge / 100.0, 0.0, 1.0)
		if kpct >= 1.0:
			var pulse_k: float = 0.65 + 0.35 * sin(Time.get_ticks_msec() / 120.0)
			draw_arc(Vector2(0, 5), 11.0, 0.0, TAU, 24, Color(1.0, 0.88, 0.25, 0.85 * pulse_k), 1.6)
		elif kpct > 0.02:
			draw_arc(Vector2(0, 5), 10.0, -PI * 0.5, -PI * 0.5 + TAU * kpct, 20, Color(1.0, 0.82, 0.35, 0.65), 1.2)
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
			var tpos: Vector2 = target.hurtbox_center() if target.has_method("hurtbox_center") else target.global_position
			aim_dir = (tpos - global_position).normalized()
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
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to(e.global_position)
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
	if buff_timer > 0.0 or is_free or (Global != null and Global.has_method("has_mutator") and Global.has_mutator("infinite_energy")):
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
	var frenzy_cd_mult: float = 0.8 if _frenzy_timer > 0.0 else 1.0
	var passive_cd_mult: float = 0.9 if hero_id == "hai_ba_trung" else 1.0
	var trench_cd_mult: float = 0.9 if in_trench else 1.0
	var eff_cd: float = cd * (0.5 if buff_timer > 0.0 else 1.0) * pow(0.87, buff("giay_co")) * frenzy_cd_mult * passive_cd_mult * trench_cd_mult / rate_mult
	if is_free:
		_free_shots -= 1
		if _free_shots > 0:
			_fire_timer = 0.0
		else:
			_fire_timer = eff_cd
			_stun_shot = 0.0
	else:
		_fire_timer = eff_cd
	_execute_weapon_attack(w, shot_stun)
	if cost > 0:
		stats_changed.emit()


func _release_charged_attack(w: Dictionary, ratio: float) -> void:
	if w.is_empty() or dead or downed:
		return
	var is_free: bool = _free_shots > 0
	var shot_stun: float = _stun_shot if is_free else 0.0
	var cost: int = int(w.get("energy", 0))
	if buff_timer > 0.0 or is_free or (Global != null and Global.has_method("has_mutator") and Global.has_mutator("infinite_energy")):
		cost = 0
	if cost > energy:
		if _msg_cd <= 0.0:
			_msg_cd = 1.2
			Fx.float_text(get_parent(), global_position + Vector2(0, -22), "Hết năng lượng!", Color(0.5, 0.75, 1.0))
		return
	energy -= cost
	if is_free:
		_free_shots -= 1
	var cw := w.duplicate()
	var dmg_scale: float = lerpf(0.75, 2.25, clampf(ratio, 0.0, 1.0))
	cw["damage"] = maxi(1, int(round(float(w.get("damage", 4)) * dmg_scale)))
	if cw.has("speed"):
		cw["speed"] = float(cw["speed"]) * lerpf(0.95, 1.38, ratio)
	if ratio >= 0.85:
		cw["pierce"] = int(cw.get("pierce", 0)) + 1
		cw["stun"] = maxf(float(cw.get("stun", 0.0)), 0.35)
	cw["_charge_scale"] = lerpf(0.95, 1.55, ratio)
	if cw.has("width"):
		cw["width"] = float(cw["width"]) * lerpf(1.0, 1.7, ratio)
	var rate_mult: float = float(SynergyData.IMPRINTS["sung"].fire_rate_mult) if rapid_reload_timer > 0.0 else 1.0
	_fire_timer = maxf(0.18, float(w.get("cooldown", 0.45)) * 0.65 * pow(0.87, buff("giay_co")) / rate_mult)
	if get_parent() != null and ratio >= 0.85:
		Fx.burst(get_parent(), _muzzle_pos(), Color(1.0, 0.88, 0.35), 24.0, 0.25)
	_execute_weapon_attack(cw, shot_stun)
	if cost > 0:
		stats_changed.emit()


func _execute_weapon_attack(w: Dictionary, shot_stun: float = 0.0) -> void:
	_total_attack_count += 1
	var w_exec := w
	if _post_dash_boost:
		_post_dash_boost = false
		w_exec = w_exec.duplicate()
		w_exec["damage"] = maxi(1, int(round(float(w_exec.get("damage", 1)) * 1.3)))
	if buff("lien_kich_ba") > 0 and _total_attack_count % 3 == 0:
		w_exec = w.duplicate()
		w_exec["damage"] = maxi(1, int(round(float(w_exec.get("damage", 1)) * 1.3)))
		if str(w_exec.get("type", "")) == "ranged":
			w_exec["count"] = int(w_exec.get("count", 1)) + 1
			if float(w_exec.get("spread", 0.0)) <= 0.0:
				w_exec["spread"] = 14.0
	if hero_id == "thanh_giong" and _total_attack_count % 5 == 0 and get_parent() != null:
		var wr_tg := WaveRing.new()
		wr_tg.position = global_position
		wr_tg.radius = 52.0
		wr_tg.damage = maxi(2, int(w_exec.get("damage", 4)))
		wr_tg.knock = 220.0
		wr_tg.color = Color(1.0, 0.72, 0.25)
		get_parent().add_child(wr_tg)
	if str(w_exec.get("type", "")) == "ranged" and _has_enemy_within(26.0) and _qi_slash_cd <= 0.0:
		_close_range_qi_slash(w_exec)
	match w_exec.type:
		"melee":
			_melee(w_exec, Vector2.ZERO, shot_stun)
			if twin_timer > 0.0:
				_melee(w_exec, _twin_offset(), shot_stun)
		"ranged":
			_shoot(w_exec, Vector2.ZERO, shot_stun)
			if twin_timer > 0.0:
				_shoot(w_exec, _twin_offset(), shot_stun)
		"beam":
			_beam(w_exec)
		"wave":
			_wave(w_exec)
		"spikes":
			_spikes(w_exec)
	if body != null and not dead:
		_anim_lock_t = 0.18
		body.play("attack")
		body.frame = 0
	if w_exec.has("shake"):
		Fx.shake(get_tree(), w_exec.shake)


func _has_enemy_within(max_d: float) -> bool:
	if not is_inside_tree():
		return false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var d_center: float = global_position.distance_to((e as Node2D).global_position)
		var d_hb: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else d_center
		if minf(d_center, d_hb) < max_d:
			return true
	return false


func _close_range_qi_slash(w: Dictionary) -> void:
	_qi_slash_cd = 0.22
	var reach: float = 30.0
	var arc: float = deg_to_rad(150.0)
	var dmg: int = maxi(3, int(round(float(w.get("damage", 4)) * 0.8)))
	if get_parent() != null:
		Fx.slash(get_parent(), global_position + weapon_pivot.position, aim_dir, reach, arc, Color(0.55, 0.95, 1.0), "swing")
	Sfx.play("slash")
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var hit_pt: Vector2 = e.closest_point_on_hurtbox(global_position) if e.has_method("closest_point_on_hurtbox") else (e as Node2D).global_position
		if _in_arc(hit_pt, reach + 4.0, arc, 4.0):
			e.take_damage(dmg, (hit_pt - global_position).normalized() * 140.0)
			on_hit_enemy(e)
			if get_parent() != null:
				Fx.anim(get_parent(), hit_pt, "fx/spark.png", 15, 15, 24.0, 0.9, 0.0, Color(0.55, 0.95, 1.0), true)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if is_instance_valid(b) and _in_arc((b as Node2D).global_position, reach + 4.0, arc, 4.0):
			b.destroy()


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
		Sfx.play_weapon(str(weapons[slot]), w)
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
		var b_dmg: int = int(w.damage)
		if hero_id == "quang_trung" and (b_proj == "fireball" or float(w.get("explode", 0.0)) > 0.0 or str(w.get("status", "")) == "burn"):
			b_dmg = maxi(b_dmg + 1, int(round(float(b_dmg) * 1.2)))
		elif hero_id == "nguyen_trung_truc" and (b_proj == "fireball" or str(w.get("status", "")) == "burn"):
			b_dmg = maxi(b_dmg + 1, int(round(float(b_dmg) * 1.2)))
		elif hero_id == "chien_si_dien_bien" and (b_proj == "bullet" or float(w.get("explode", 0.0)) > 0.0):
			b_dmg = maxi(b_dmg + 1, int(round(float(b_dmg) * 1.15)))
		b.setup(true, b_pos, dir, w.speed, b_dmg, b_life, b_proj)
		b.spawn_origin = global_position + offset
		b.pierce = int(w.get("pierce", 0)) + (int(SynergyData.IMPRINTS["sung"].pierce) if rapid_reload_timer > 0.0 else 0)
		b.explode_radius = maxf(w.get("explode", 0.0) * (1.0 + 0.35 * buff("hoa_duoc")), extra_explode)
		b.knock = w.get("knock", 60.0) * (1.15 if hero_id == "thanh_giong" else 1.0)
		b.homing = w.get("homing", 0.0)
		b.color = w.get("color", Color.WHITE)
		b.boss_motif = bool(w.get("boss_motif", false))
		b.bullet_scale = float(w.get("evolved_scale", 1.0)) * float(w.get("_charge_scale", 1.0))
		if bool(w.get("mod_fire", false)):
			b.force_burn = true
			if b.color == Color.WHITE:
				b.color = Color(1.0, 0.72, 0.45)
		b.stun_duration = maxf(shot_stun, float(w.get("stun", 0.0)))
		b.burn_duration = 2.2 * burn_mult
		b.status_kind = str(w.get("status", ""))
		b.slow_duration = float(w.get("slow", 0.0))
		if buff("bang_tam") > 0:
			b.slow_duration = maxf(b.slow_duration, 2.0)
			if b.status_kind == "":
				b.status_kind = "slow"
		b.chain_count = int(w.get("chain", 0))
		b.owner_node = self
		var w_bounces: int = int(w.get("bounce", w.get("bounces", 0)))
		if w_bounces > 0:
			b.bounces = maxi(b.bounces, w_bounces)
		if buff("dan_nay") > 0 and not w.get("boomerang", false):
			b.bounces = maxi(b.bounces, 1)
		if buff("khuc_xa") > 0 and not w.get("boomerang", false):
			b.bounces += 2 * buff("khuc_xa")
			b.refract_boost = true
		if buff("phan_tach") > 0:
			b.split_on_hit = 2 * buff("phan_tach")
		if buff("xuyen_tam") > 0:
			b.crit_pierce = true
		if w.get("boomerang", false):
			b.boomerang = true
		get_parent().add_child(b)
		if broadcast_net:
			net_shots.append([b_pos.x, b_pos.y, dir.x, dir.y, float(b.speed), b_life, b_proj, b.pierce, b.explode_radius, b.homing, b.boomerang, b.color.to_html(true)])
	if buff("noi_cong") > 0 and offset == Vector2.ZERO:
		_qigong_shots += 1
		if _qigong_shots % 4 == 0:
			var qpos: Vector2 = start - aim_dir * 4.0
			var qb := Bullet.new()
			qb.setup(true, qpos, aim_dir, 260.0, maxi(4, int(round(float(w.damage) * 0.7))), 0.6, "sword_wave")
			qb.spawn_origin = global_position
			qb.pierce = 99
			qb.qi_wave = true
			qb.knock = 180.0
			qb.color = Color(0.45, 0.95, 1.0)
			qb.owner_node = self
			get_parent().add_child(qb)
			if broadcast_net:
				net_shots.append([qpos.x, qpos.y, aim_dir.x, aim_dir.y, 260.0, 0.6, "sword_wave", 99, 0.0, 0.0, false, qb.color.to_html(true)])
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
			"wid": str(weapons[slot]),
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
		Sfx.play_weapon(str(weapons[slot]), w)
	var combo_phase: int = _melee_combo % 3
	if offset == Vector2.ZERO:
		melee_combo_phase = combo_phase
		_melee_combo = (_melee_combo + 1) % 3
		_melee_combo_reset_t = 1.1
	var reach: float = w.reach * (1.0 + 0.2 * buff("da_mai")) * (1.1 if hero_id == "le_loi" else 1.0)
	var arc := deg_to_rad(w.arc)
	var dmg: int = int(w.damage * (1.0 + 0.15 * buff("da_mai")))
	if hero_id == "hai_ba_trung":
		dmg += 1
	elif hero_id == "ba_trieu":
		dmg = maxi(dmg + 1, int(round(float(dmg) * 1.15)))
	var hits: int = w.get("hits", 1)
	var knock: float = w.get("knock", 140.0) * (1.15 if hero_id == "thanh_giong" else 1.0)
	var style: String = w.get("style", "swing")
	if offset == Vector2.ZERO:
		match combo_phase:
			0:
				arc *= 1.22
			1:
				reach *= 1.22
				dmg = maxi(dmg + 1, int(round(float(dmg) * 1.15)))
				if style != "spin":
					style = "thrust"
				_lunge_t = 0.07
				_lunge_dir = aim_dir
			2:
				reach *= 1.28
				arc = TAU
				dmg = maxi(dmg + 1, int(round(float(dmg) * 1.35)))
				style = "spin"
				if get_parent() != null:
					var cwr := WaveRing.new()
					cwr.position = global_position
					cwr.radius = reach * 1.15
					cwr.damage = maxi(2, int(round(float(dmg) * 0.5)))
					cwr.knock = knock * 1.15
					cwr.color = _tier_color(w)
					get_parent().add_child(cwr)
	var is_boss_motif: bool = bool(w.get("boss_motif", false))
	var is_high_tier: bool = int(w.get("tier", 1)) >= 4 or is_boss_motif
	var trail_col: Color = Color("ff384c") if is_boss_motif else _tier_color(w)
	var first_hit = null
	for e in get_tree().get_nodes_in_group("enemies"):
		var has_hb: bool = e.has_method("closest_point_on_hurtbox")
		var hit_pt: Vector2 = e.closest_point_on_hurtbox(global_position + offset) if has_hb else e.global_position
		var pad: float = 4.0 if has_hb else float(e.radius)
		if _in_arc(hit_pt - offset, reach + pad, arc, pad):
			var hit_dmg: int = dmg * burn_bonus_mult(e)
			for i in hits:
				e.take_damage(hit_dmg, (hit_pt - global_position).normalized() * knock)
			if bool(w.get("mod_fire", false)) and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status("burn", 2.2)
			var eff_stun: float = maxf(hit_stun, float(w.get("stun", 0.0)))
			if eff_stun > 0.0 and is_instance_valid(e) and not e.dead and e.has_method("apply_stun"):
				e.apply_stun(eff_stun)
			var mst: String = str(w.get("status", ""))
			if (mst == "burn" or mst == "poison") and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status(mst, 2.2)
			elif (mst == "slow" or float(w.get("slow", 0.0)) > 0.0 or buff("bang_tam") > 0) and is_instance_valid(e):
				_apply_enemy_slow(e, maxf(float(w.get("slow", 0.0)), 2.0))
			on_hit_enemy(e)
			var lhc: Variant = e.get("last_hit_crit") if is_instance_valid(e) else null
			var lc: Variant = e.get("last_crit") if is_instance_valid(e) else null
			var was_crit: bool = (typeof(lhc) == TYPE_BOOL and (lhc as bool)) or (typeof(lc) == TYPE_BOOL and (lc as bool))
			var is_heavy_hit: bool = offset == Vector2.ZERO and (combo_phase == 2 or float(w.get("_charge_scale", 1.0)) >= 1.2 or int(w.get("damage", 0)) >= 10)
			if (was_crit or is_heavy_hit) and get_parent() != null:
				Fx.decal(get_parent(), hit_pt, "slash_mark", Color(1.0, 0.88, 0.35) if was_crit else trail_col, 1.15 if was_crit else 0.95, aim_dir.angle())
			if first_hit == null:
				first_hit = e
			Fx.anim(get_parent(), hit_pt, "fx/spark.png", 15, 15, 24.0, 1.0, 0.0, Color(1, 0.95, 0.7), true)
	var clear_reach: float = reach * (1.2 if hero_id == "le_loi" else 1.0)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if _in_arc(b.global_position - offset, clear_reach + 4.0, arc, 4.0):
			if buff("kiem_phan_dan") > 0:
				var ref_dir: Vector2 = -Vector2(b.get("dir"))
				if ref_dir.length_squared() < 0.01:
					ref_dir = (b.global_position - global_position).normalized()
				var rb := Bullet.new()
				rb.setup(true, b.global_position, ref_dir, 260.0, maxi(4, int(b.get("damage")) * 3), 0.9, "orb_water")
				rb.color = Color(1.0, 0.9, 0.4)
				rb.owner_node = self
				get_parent().add_child(rb)
				Sfx.play("hit_metal")
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
	if is_high_tier and get_parent() != null and weapon_sprite != null and weapon_sprite.texture != null and weapon_pivot != null:
		Fx.weapon_trail(get_parent(), weapon_sprite.texture, weapon_sprite.global_position, weapon_pivot.rotation + swing, weapon_sprite.scale, weapon_sprite.flip_v, trail_col, 0.22, weapon_sprite.offset, weapon_sprite.centered)
		if style != "thrust" and is_inside_tree():
			var wr_me: WeakRef = weakref(self)
			var wr_par: WeakRef = weakref(get_parent())
			get_tree().create_timer(0.05).timeout.connect(func():
				var me: Variant = wr_me.get_ref()
				var par: Variant = wr_par.get_ref()
				if me == null or par == null or not is_instance_valid(me) or not is_instance_valid(par):
					return
				if me.weapon_sprite != null and me.weapon_sprite.texture != null and me.weapon_pivot != null and not me.dead:
					Fx.weapon_trail(par as Node, me.weapon_sprite.texture, me.weapon_sprite.global_position, me.weapon_pivot.rotation + me.swing, me.weapon_sprite.scale, me.weapon_sprite.flip_v, trail_col, 0.22, me.weapon_sprite.offset, me.weapon_sprite.centered))
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
		b.owner_node = self
		b.status_kind = str(w.get("status", ""))
		b.slow_duration = float(w.get("slow", 0.0))
		b.stun_duration = float(w.get("stun", 0.0))
		get_parent().add_child(b)
		if broadcast_net:
			net_waves.append([wpos.x, wpos.y, aim_dir.x, aim_dir.y, wspd, 0.7, kind, b.color.to_html(true)])
	if buff("noi_cong") > 0:
		var qb := Bullet.new()
		var qpos: Vector2 = global_position + aim_dir * 14.0
		qb.setup(true, qpos, aim_dir, 260.0, maxi(4, int(round(float(dmg) * 0.65))), 0.6, "sword_wave")
		qb.spawn_origin = global_position
		qb.pierce = 99
		qb.qi_wave = true
		qb.knock = 180.0
		qb.color = Color(0.45, 0.95, 1.0)
		qb.owner_node = self
		get_parent().add_child(qb)
		if broadcast_net:
			net_waves.append([qpos.x, qpos.y, aim_dir.x, aim_dir.y, 260.0, 0.6, "sword_wave", qb.color.to_html(true)])
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
			"wid": str(weapons[slot]),
		})


func _apply_enemy_slow(e: Node, dur: float) -> void:
	if e == null or not is_instance_valid(e) or bool(e.get("dead")) or dur <= 0.0:
		return
	var spd_val: Variant = e.get("speed")
	if spd_val == null:
		return
	if not e.has_meta("weapon_slowed"):
		var cur_spd: float = float(spd_val)
		var cut: float = cur_spd * 0.35
		e.set_meta("weapon_slowed", true)
		e.set_meta("weapon_slow_cut", cut)
		e.set("speed", maxf(10.0, cur_spd - cut))
	e.set_meta("weapon_slow_until", Time.get_ticks_msec() + int(dur * 1000.0))
	if get_parent() != null:
		Fx.particles(get_parent(), (e as Node2D).global_position, Color(0.55, 0.9, 1.0), 4, 40.0, 0.35)
	var wr: WeakRef = weakref(e)
	if is_inside_tree():
		get_tree().create_timer(dur + 0.05).timeout.connect(func():
			var ref: Variant = wr.get_ref()
			if ref == null or not is_instance_valid(ref) or bool(ref.get("dead")):
				return
			if Time.get_ticks_msec() >= int(ref.get_meta("weapon_slow_until", 0)) and ref.has_meta("weapon_slowed"):
				var cut2: float = float(ref.get_meta("weapon_slow_cut", 0.0))
				ref.set("speed", float(ref.get("speed")) + cut2)
				ref.remove_meta("weapon_slowed")
				ref.remove_meta("weapon_slow_cut")
				ref.remove_meta("weapon_slow_until"))


func _chain_lightning(start, count: int, dmg: int) -> Array:
	var pts: Array = [global_position + aim_dir * 10.0, start.global_position]
	var done: Array = [start]
	var cur = start
	for i in count - 1:
		var best = null
		var best_d := 110.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()) or done.has(e):
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
	Sfx.play_weapon(str(weapons[slot]), w)
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
	var beam_hit: Array = []
	var bst: String = str(w.get("status", ""))
	var bstun: float = float(w.get("stun", 0.0))
	for e in get_tree().get_nodes_in_group("enemies"):
		var ctr: Vector2 = e.hurtbox_center() if e.has_method("hurtbox_center") else e.global_position
		var rel: Vector2 = ctr - start
		var t := clampf(rel.dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
		var seg_pt: Vector2 = start + seg * t
		var dist_e: float = e.distance_to_hurtbox(seg_pt) if e.has_method("distance_to_hurtbox") else (seg_pt.distance_to(e.global_position) - e.radius)
		if dist_e <= width:
			e.take_damage(w.damage, aim_dir * 80.0)
			if is_instance_valid(e) and not bool(e.get("dead")):
				beam_hit.append(e)
			if bool(w.get("mod_fire", false)) and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status("burn", 2.2)
			if (bst == "burn" or bst == "poison") and is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status(bst, 2.2)
			elif (bst == "slow" or float(w.get("slow", 0.0)) > 0.0) and is_instance_valid(e):
				_apply_enemy_slow(e, float(w.get("slow", 2.0)))
			if bstun > 0.0 and is_instance_valid(e) and not bool(e.get("dead")) and e.has_method("apply_stun"):
				e.apply_stun(bstun)
	if w.has("chain") and not beam_hit.is_empty():
		_chain_lightning(beam_hit[0], int(w.chain), maxi(1, int(round(float(w.damage) * 0.6))))
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
	if buff("khuc_xa") > 0 and not res.is_empty():
		var bnorm: Vector2 = res.get("normal", -aim_dir)
		var rdir: Vector2 = aim_dir.bounce(bnorm).normalized()
		var rend: Vector2 = end + rdir * (length * 0.65)
		var rq := PhysicsRayQueryParameters2D.create(end + bnorm * 2.0, rend, 1)
		var rres := space.intersect_ray(rq)
		if not rres.is_empty():
			rend = rres["position"]
		var rfx := Beam.new()
		rfx.position = end
		rfx.end_point = rend - end
		rfx.width = width * 0.85
		rfx.color = fx.color.lerp(Color(0.55, 0.95, 1.0), 0.4)
		get_parent().add_child(rfx)
		var rseg := rend - end
		for re in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(re) or bool(re.get("dead")):
				continue
			var rctr: Vector2 = re.hurtbox_center() if re.has_method("hurtbox_center") else (re as Node2D).global_position
			var rt: float = clampf((rctr - end).dot(rseg) / maxf(rseg.length_squared(), 1.0), 0.0, 1.0)
			var rdist: float = re.distance_to_hurtbox(end + rseg * rt) if re.has_method("distance_to_hurtbox") else ((end + rseg * rt).distance_to((re as Node2D).global_position) - re.radius)
			if rdist <= width:
				re.take_damage(maxi(1, int(round(float(w.damage) * 0.8))), rdir * 60.0)
	_recoil = 3.0
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("beam", {
			"sx": start.x, "sy": start.y, "ex": end.x, "ey": end.y,
			"width": width, "col": fx.color.to_html(true), "wid": str(weapons[slot]),
		})


func _wave(w: Dictionary) -> void:
	Sfx.play_weapon(str(weapons[slot]), w)
	var r := WaveRing.new()
	r.position = global_position
	r.radius = w.get("radius", 110.0)
	r.damage = w.damage
	r.knock = float(w.get("knock", 120.0))
	r.stun = w.get("stun", 0.0)
	r.color = w.get("color", Color(1.0, 0.75, 0.35))
	r.notes = w.has("stun")
	get_parent().add_child(r)
	if w.has("chain"):
		var near_e = null
		var near_d: float = r.radius + 16.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
				continue
			var d: float = global_position.distance_to((e as Node2D).global_position)
			if d < near_d:
				near_d = d
				near_e = e
		if near_e != null:
			_chain_lightning(near_e, int(w.chain), maxi(1, int(round(float(w.damage) * 0.7))))
	Fx.shake(get_tree(), 2.0)
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("wave", {
			"x": global_position.x, "y": global_position.y,
			"radius": r.radius, "col": r.color.to_html(true), "notes": r.notes,
			"wid": str(weapons[slot]),
		})


func _spikes(w: Dictionary) -> void:
	Sfx.play_weapon(str(weapons[slot]), w)
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
		Net.send_player_action("spikes", {"pts": net_pts, "wid": str(weapons[slot])})


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
	var sk_idx: int = Global.active_skill_index(hero_id) if Global.has_method("active_skill_index") else 1
	var sk_info: Dictionary = HeroData.skill_info(hero_id, sk_idx)
	var sk_id: String = str(sk_info.get("skill", hero.get("skill", "")))
	var base_cd: float = float(sk_info.get("skill_cd", hero.get("skill_cd", 10.0)))
	var mentor_up: bool = Global != null and bool(Global.get("mentor_upgraded"))
	var mentor_mult: float = 1.35 if mentor_up else 1.0
	var hb: Dictionary = ProgressionData.hero_bonuses(Global.eff_hero_level(hero_id))
	skill_timer = base_cd * pow(0.8, buff("tra_tim_sen")) * float(hb.cd_mult) * (0.85 if mentor_up else 1.0)
	Sfx.play_skill(hero_id)
	if body != null and not dead:
		_anim_lock_t = 0.44
		body.play("skill")
		body.frame = 0
	_cast_pulse_t = 0.44
	_cast_pulse_col = (hero.get("color", Color(1.0, 0.88, 0.7)) as Color).lightened(0.35)
	var parent := get_parent()
	SkillCastFx.spawn(parent, global_position, aim_dir, sk_id, Color(0, 0, 0, 0), syn)
	var wr: WeakRef = weakref(parent)
	var ally_passive_mult: float = 1.0
	match sk_id:
		"coc_bach_dang":
			# Nước dâng, cọc nhọn trồi lên thành 2 vòng (mức 2 thêm vòng ngoài 8 cọc)
			Fx.anim(parent, global_position + Vector2(0, 6), "fx/ripple.png", 72, 34, 12.0, 1.6)
			Fx.particles(parent, global_position, Color(0.5, 0.8, 1.0), 20, 110.0, 0.6, 150.0, 2.0, 180.0, Vector2.UP, Color(0.9, 1, 1))
			var s_life: float = (9.0 if syn == 2 else 6.0) * mentor_mult
			var s_stun: float = 1.0 if syn == 2 else (0.5 if syn == 1 else 0.0)
			for i in 14:
				var ring := (30.0 if i % 2 == 0 else 50.0) * (1.15 if mentor_up else 1.0)
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
			_dash_time = 0.55 * (1.15 if mentor_up else 1.0)
			_dash_dir = aim_dir
			_dash_hit.clear()
			_dash_syn = syn
			_dash_armor_gained = 0
			Fx.burst(parent, global_position, Color(1, 0.8, 0.5), 40.0 * mentor_mult, 0.4)
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
						Fx.burst(par, here, Color(1, 0.8, 0.3), (46.0 + k * 10.0) * mentor_mult, 0.45))
			var ally_cnt: int = (4 if syn >= 1 else 3) + (1 if mentor_up else 0)
			var ally_dmg: int = int(round(float(5 if syn == 2 else 3) * ally_passive_mult * mentor_mult))
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
			twin_timer = (11.0 if syn == 2 else (10.0 if syn == 1 else 8.0)) * mentor_mult
			Fx.anim(parent, global_position + _twin_offset(), "fx/poof.png", 28, 28, 16.0, 1.2, 0.0, Color(1, 0.7, 0.85))
			Fx.particles(parent, global_position, Color(1, 0.6, 0.8), 20, 110.0, 0.6, -30.0, 2.0)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Trưng Nhị!", Color(1, 0.75, 0.85), 18)
		"nam_quoc_son_ha":
			_reflect_syn = syn
			_reflect_timer = 5.0 * mentor_mult
			var ring := ReflectRing.new()
			ring.damage_mult = (2.0 if syn == 2 else (1.5 if syn == 1 else 1.0)) * mentor_mult
			ring.pierce_bonus = 1 if syn == 2 else 0
			add_child(ring)
			Fx.burst(parent, global_position, Color(1, 0.85, 0.35), 50.0 * mentor_mult, 0.5)
		"thuan_thien_kiem":
			var ob := OrbitBlades.new()
			ob.count = (5 if syn == 2 else (4 if syn == 1 else 3)) + (1 if mentor_up else 0)
			ob.launch_on_melee = (syn == 2)
			add_child(ob)
			Fx.burst(parent, global_position, Color(1, 0.95, 0.6), 44.0 * mentor_mult, 0.45)
			Fx.particles(parent, global_position, Color(1, 0.95, 0.6), 22, 120.0, 0.6)
		"hoa_hong":
			var pot_cnt: int = (12 if syn == 2 else (10 if syn == 1 else 8)) + (2 if mentor_up else 0)
			if syn == 2:
				_burn_double_timer = 4.0 * mentor_mult
			for i in pot_cnt:
				var fz := FireZone.new()
				fz.position = global_position
				fz.target = global_position + Vector2.from_angle(TAU * float(i) / float(pot_cnt)) * 54.0 * mentor_mult
				parent.add_child(fz)
			Fx.shake(get_tree(), 2.0)
		"hum_thieng":
			if syn >= 1:
				_free_shots = (3 if syn == 2 else 2) + (1 if mentor_up else 0)
				_stun_shot = 0.8 if syn == 2 else 0.0
				_fire_timer = 0.0
			var roar := WaveRing.new()
			roar.position = global_position
			roar.radius = 120.0 * mentor_mult
			roar.damage = int(round(3.0 * mentor_mult))
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
			tu.fire_cd = (0.7 / 1.4 if syn == 2 else (0.7 / 1.2 if syn == 1 else 0.7)) / mentor_mult
			tu.use_marked = (syn == 2)
			if syn == 2:
				_mark_timer = 9.0
			tu.position = global_position + aim_dir * 16.0
			parent.add_child(tu)
		"than_toc":
			_than_toc_syn = syn
			buff_timer = 5.0 * mentor_mult
			Fx.burst(parent, global_position, Color(1, 0.9, 0.3), 36.0 * mentor_mult, 0.35)
			Fx.particles(parent, global_position, Color(1, 0.95, 0.5), 18, 140.0, 0.5, 0.0, 2.0)
		"ngua_sat":
			_horse_time = 0.65 * (1.15 if mentor_up else 1.0)
			_invuln = maxf(_invuln, 0.75)
			_dash_dir = aim_dir
			_horse_syn = syn
			_horse_fire_cd = 0.0
			_dash_hit.clear()
			var fb_cnt: int = (8 if syn == 2 else (5 if syn == 1 else 3)) + (2 if mentor_up else 0)
			var spread_deg: float = 56.0 if syn == 2 else (44.0 if syn == 1 else 30.0)
			for i in fb_cnt:
				var frac: float = 0.5 if fb_cnt <= 1 else float(i) / float(fb_cnt - 1)
				var ang: float = aim_dir.angle() + deg_to_rad(lerpf(-spread_deg * 0.5, spread_deg * 0.5, frac))
				var fdir: Vector2 = Vector2.from_angle(ang)
				var fb := Bullet.new()
				fb.setup(true, global_position + fdir * 12.0, fdir, 260.0, int(round(5.0 * mentor_mult)), 0.55, "fireball")
				fb.spawn_origin = global_position
				fb.owner_node = self
				parent.add_child(fb)
			Fx.burst(parent, global_position, Color(1.0, 0.55, 0.2), 44.0 * mentor_mult, 0.4)
			Fx.float_text(parent, global_position + Vector2(20 * aim_dir.x, -30), "Hí! Phun lửa!", Color(1.0, 0.78, 0.28), 18)
			Fx.shake(get_tree(), 4.0)
		# --- 11 Skill 2s (v2.0.0) ---
		"co_lenh_me_linh":
			var wr_ml := WaveRing.new()
			wr_ml.position = global_position
			wr_ml.radius = 120.0 * mentor_mult
			wr_ml.damage = int(round(5.0 * mentor_mult))
			wr_ml.stun = 0.8
			wr_ml.color = Color(0.95, 0.35, 0.55)
			parent.add_child(wr_ml)
			buff_timer = maxf(buff_timer, 4.0 * mentor_mult)
			twin_timer = maxf(twin_timer, 5.0 * mentor_mult)
			for i in (3 if mentor_up else 2):
				var a := Ally.new()
				a.damage = int(round(4.0 * mentor_mult * ally_passive_mult))
				a.position = global_position + Vector2.from_angle(TAU * float(i) / 3.0) * 22.0
				parent.add_child(a)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Cờ lệnh Mê Linh!", Color(1.0, 0.48, 0.65), 18)
		"chieng_nui_nua":
			for k in 2:
				var gwr := WaveRing.new()
				gwr.position = global_position
				gwr.radius = (110.0 + float(k) * 35.0) * mentor_mult
				gwr.damage = int(round((7.0 + float(k) * 3.0) * mentor_mult))
				gwr.stun = 1.6
				gwr.knock = 280.0
				gwr.color = Color(1.0, 0.82, 0.25)
				parent.add_child(gwr)
			restore_armor(3 if mentor_up else 2)
			Fx.shake(get_tree(), 4.5)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Chiêng Núi Nưa!", Color(1.0, 0.86, 0.35), 18)
		"thuy_trieu_dang":
			var twr := WaveRing.new()
			twr.position = global_position
			twr.radius = 115.0 * mentor_mult
			twr.damage = int(round(5.0 * mentor_mult))
			twr.knock = 240.0
			twr.color = Color(0.35, 0.82, 1.0)
			parent.add_child(twr)
			var wcnt: int = 10 if mentor_up else 8
			for i in wcnt:
				var wd: Vector2 = Vector2.from_angle(TAU * float(i) / float(wcnt))
				var wb := Bullet.new()
				wb.setup(true, global_position + wd * 10.0, wd, 240.0, int(round(6.0 * mentor_mult)), 0.75, "water_wave")
				wb.spawn_origin = global_position
				wb.pierce = 99
				wb.slow_duration = 2.5
				wb.owner_node = self
				parent.add_child(wb)
			for i in 6:
				var sa: float = aim_dir.angle() + lerpf(-0.9, 0.9, float(i) / 5.0)
				var s := Stake.new()
				s.life_time = 6.0 * mentor_mult
				s.stun_time = 0.6
				s.position = global_position + Vector2.from_angle(sa) * 38.0
				parent.add_child(s)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Thủy Triều Dâng!", Color(0.45, 0.88, 1.0), 18)
		"tuong_nhu_nguyet":
			_reflect_syn = maxi(syn, 1)
			_reflect_timer = maxf(_reflect_timer, 3.5 * mentor_mult)
			for i in (9 if mentor_up else 7):
				var sa2: float = aim_dir.angle() + lerpf(-1.05, 1.05, float(i) / 6.0)
				var st := Stake.new()
				st.life_time = 7.5 * mentor_mult
				st.stun_time = 0.5
				st.position = global_position + Vector2.from_angle(sa2) * 34.0
				parent.add_child(st)
			for i in 9:
				var aa: float = aim_dir.angle() + lerpf(-0.6, 0.6, float(i) / 8.0)
				var ab := Bullet.new()
				ab.setup(true, global_position + Vector2.from_angle(aa) * 12.0, Vector2.from_angle(aa), 460.0, int(round(4.0 * mentor_mult)), 0.85, "arrow")
				ab.spawn_origin = global_position
				ab.pierce = 1
				ab.owner_node = self
				parent.add_child(ab)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Tường Như Nguyệt!", Color(0.75, 0.90, 1.0), 18)
		"hoa_cong_bach_dang":
			for i in (7 if mentor_up else 5):
				var fpos: Vector2 = global_position + aim_dir * (26.0 + float(i) * 24.0)
				var fz := FireZone.new()
				fz.instant = true
				fz.radius = 24.0 * mentor_mult
				fz.life = 4.5 * mentor_mult
				fz.position = fpos
				fz.target = fpos
				parent.add_child(fz)
			for i in 6:
				var fa: float = aim_dir.angle() + lerpf(-0.45, 0.45, float(i) / 5.0)
				var fb := Bullet.new()
				fb.setup(true, global_position + Vector2.from_angle(fa) * 12.0, Vector2.from_angle(fa), 290.0, int(round(7.0 * mentor_mult)), 0.9, "fireball")
				fb.spawn_origin = global_position
				fb.explode_radius = 30.0 * mentor_mult
				fb.force_burn = true
				fb.owner_node = self
				parent.add_child(fb)
			Fx.shake(get_tree(), 3.5)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Hỏa Công Bạch Đằng!", Color(1.0, 0.55, 0.2), 18)
		"kim_quy_ho_gia":
			_invuln = maxf(_invuln, 1.6 * mentor_mult)
			restore_armor(4 if mentor_up else 3)
			var ob_kq := OrbitBlades.new()
			ob_kq.count = 5 if mentor_up else 4
			ob_kq.radius = 34.0
			ob_kq.life = 6.5 * mentor_mult
			add_child(ob_kq)
			var kwr := WaveRing.new()
			kwr.position = global_position
			kwr.radius = 110.0 * mentor_mult
			kwr.damage = int(round(6.0 * mentor_mult))
			kwr.color = Color(1.0, 0.88, 0.3)
			parent.add_child(kwr)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Kim Quy Hộ Giá!", Color(1.0, 0.92, 0.38), 18)
		"hoa_ho_dai_phao":
			var c_cnt: int = 4 if mentor_up else 3
			for i in c_cnt:
				var ca: float = aim_dir.angle() + lerpf(-0.28, 0.28, 0.5 if c_cnt <= 1 else float(i) / float(c_cnt - 1))
				var cd2: Vector2 = Vector2.from_angle(ca)
				var cb := Bullet.new()
				cb.setup(true, global_position + cd2 * 14.0, cd2, 320.0, int(round(14.0 * mentor_mult)), 1.1, "cannonball")
				cb.spawn_origin = global_position
				cb.explode_radius = 52.0 * mentor_mult
				cb.force_burn = true
				cb.stun_duration = 0.65
				cb.owner_node = self
				parent.add_child(cb)
			_recoil = 6.0
			Fx.shake(get_tree(), 5.0)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Hỏa Hổ Đại Pháo!", Color(1.0, 0.45, 0.22), 18)
		"nhat_tao_xung_kich":
			_dash_time = 0.40 * (1.15 if mentor_up else 1.0)
			_invuln = maxf(_invuln, 0.5)
			_dash_dir = aim_dir
			_dash_hit.clear()
			_dash_syn = maxi(syn, 1)
			for i in (5 if mentor_up else 4):
				var fz2 := FireZone.new()
				fz2.instant = true
				fz2.radius = 22.0 * mentor_mult
				fz2.life = 3.5 * mentor_mult
				fz2.position = global_position + aim_dir * (float(i) * 20.0)
				fz2.target = fz2.position
				parent.add_child(fz2)
			for i in 5:
				var na: float = aim_dir.angle() + lerpf(-0.55, 0.55, float(i) / 4.0)
				var fb2 := Bullet.new()
				fb2.setup(true, global_position + Vector2.from_angle(na) * 12.0, Vector2.from_angle(na), 280.0, int(round(5.0 * mentor_mult)), 0.7, "fireball")
				fb2.spawn_origin = global_position
				fb2.owner_node = self
				parent.add_child(fb2)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Nhật Tảo Xung Kích!", Color(1.0, 0.55, 0.25), 18)
		"phuc_kich_yen_the":
			_stealth_skill_t = 3.0 * mentor_mult
			_stealth_skill_active = true
			in_stealth_bush = true
			_free_shots = 4 + (1 if mentor_up else 0)
			_stun_shot = 0.65
			_frenzy_timer = maxf(_frenzy_timer, 3.5 * mentor_mult)
			for i in 5:
				var da: float = aim_dir.angle() + lerpf(-0.4, 0.4, float(i) / 4.0)
				var db := Bullet.new()
				db.setup(true, global_position + Vector2.from_angle(da) * 12.0, Vector2.from_angle(da), 440.0, int(round(6.0 * mentor_mult)), 0.85, "dart")
				db.spawn_origin = global_position
				db.pierce = 2
				db.stun_duration = 0.8
				db.owner_node = self
				parent.add_child(db)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Phục Kích Yên Thế!", Color(0.55, 0.95, 0.65), 18)
		"boc_pha_nghin_can":
			var bpos: Vector2 = global_position + aim_dir * 42.0
			var bomb := Bullet.new()
			bomb.setup(true, bpos, aim_dir, 140.0, int(round(22.0 * mentor_mult)), 0.35, "grenade")
			bomb.spawn_origin = global_position
			bomb.explode_radius = 95.0 * mentor_mult
			bomb.stun_duration = 1.6
			bomb.force_burn = true
			bomb.owner_node = self
			parent.add_child(bomb)
			var bwr := WaveRing.new()
			bwr.position = global_position
			bwr.radius = 120.0 * mentor_mult
			bwr.damage = int(round(8.0 * mentor_mult))
			bwr.knock = 280.0
			bwr.color = Color(1.0, 0.68, 0.25)
			parent.add_child(bwr)
			Fx.shake(get_tree(), 6.0)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Bộc Phá Nghìn Cân!", Color(1.0, 0.72, 0.28), 18)
		"nho_tre_danh_giac":
			for i in (5 if mentor_up else 3):
				var wa: float = aim_dir.angle() + lerpf(-0.5, 0.5, float(i) / float(4 if mentor_up else 2))
				var wd2: Vector2 = Vector2.from_angle(wa)
				var wb2 := Bullet.new()
				wb2.setup(true, global_position + wd2 * 14.0, wd2, 330.0, int(round(12.0 * mentor_mult)), 0.75, "sword_wave")
				wb2.spawn_origin = global_position
				wb2.pierce = 99
				wb2.qi_wave = true
				wb2.knock = 320.0
				wb2.stun_duration = 1.0
				wb2.color = Color(0.45, 0.95, 0.48)
				wb2.owner_node = self
				parent.add_child(wb2)
			for i in 5:
				var rs := RockSpike.new()
				rs.position = global_position + aim_dir * (20.0 + float(i) * 20.0)
				rs.damage = int(round(10.0 * mentor_mult))
				parent.add_child(rs)
			Fx.slash(parent, global_position + weapon_pivot.position, aim_dir, 58.0, deg_to_rad(180.0), Color(0.45, 0.95, 0.48), "swing")
			Fx.shake(get_tree(), 4.5)
			Fx.float_text(parent, global_position + Vector2(0, -30), "Nhổ Tre Đánh Giặc!", Color(0.5, 1.0, 0.55), 18)
	_trigger_statue_effect()
	_trigger_imprint(fam, cw)
	if syn == 2:
		Fx.burst(parent, global_position, Color(1.0, 0.85, 0.25), 42.0, 0.4)
		Fx.float_text(parent, global_position + Vector2(0, -42), "Tâm đắc!", Color(1.0, 0.88, 0.35), 16)
	elif syn == 1:
		Fx.float_text(parent, global_position + Vector2(0, -42), "Đồng điệu!", Color(0.82, 0.88, 0.96), 14)
	var imp: Dictionary = SynergyData.IMPRINTS.get(fam, SynergyData.IMPRINTS["kiem"])
	Fx.float_text(parent, global_position + Vector2(0, -54), "Ấn: %s" % imp.name, SynergyData.family_color(fam), 13)
	get_tree().call_group("hud", "show_cutin", hero_id)
	if is_local and is_inside_tree():
		get_tree().call_group("game_controller", "on_local_skill_cast", hero_id, global_position)
	if is_local and Net != null and Net.is_online():
		Net.send_player_action("skill", {
			"skill": sk_id,
			"hero_id": hero_id,
			"syn": syn,
			"fam": fam,
			"x": global_position.x,
			"y": global_position.y,
			"ax": aim_dir.x,
			"ay": aim_dir.y,
		})


func _trigger_statue_effect() -> void:
	if Global == null or _statue_cd > 0.0:
		return
	var sid: String = str(Global.get("statue_id"))
	if sid == "" or get_parent() == null:
		return
	var scd: float = float(HeroSkillsExt.STATUES.get(sid, {}).get("cd", 8.0))
	_statue_cd = scd
	var parent := get_parent()
	match sid:
		"lac_long":
			var lwr := WaveRing.new()
			lwr.position = global_position
			lwr.radius = 95.0
			lwr.damage = 6
			lwr.color = Color(0.3, 0.78, 1.0)
			parent.add_child(lwr)
			for i in 8:
				var d: Vector2 = Vector2.from_angle(TAU * float(i) / 8.0)
				var b := Bullet.new()
				b.setup(true, global_position + d * 10.0, d, 250.0, 5, 0.7, "orb_water")
				b.spawn_origin = global_position
				b.owner_node = self
				parent.add_child(b)
			Fx.float_text(parent, global_position + Vector2(0, -64), "Tượng Lạc Long!", Color(0.45, 0.85, 1.0), 13)
		"au_co":
			if hp < max_hp:
				heal(1)
			else:
				restore_armor(2)
			for i in 2:
				var a := Ally.new()
				a.damage = 4
				a.position = global_position + Vector2(-16.0 if i == 0 else 16.0, 10.0)
				parent.add_child(a)
			Fx.float_text(parent, global_position + Vector2(0, -64), "Tượng Âu Cơ!", Color(1.0, 0.72, 0.88), 13)
		"son_tinh":
			restore_armor(1)
			for i in 6:
				var rs := RockSpike.new()
				rs.position = global_position + Vector2.from_angle(TAU * float(i) / 6.0) * 36.0
				rs.damage = 8
				parent.add_child(rs)
			Fx.float_text(parent, global_position + Vector2(0, -64), "Tượng Sơn Tinh!", Color(0.85, 0.68, 0.35), 13)
		"chu_dong_tu":
			add_energy(30)
			Global.run_coins += 2
			stats_changed.emit()
			Fx.burst(parent, global_position, Color(1.0, 0.88, 0.3), 38.0, 0.4)
			Fx.float_text(parent, global_position + Vector2(0, -64), "Tượng Chử Đồng Tử! +30 NL", Color(1.0, 0.9, 0.38), 13)
		"phu_dong":
			_frenzy_timer = maxf(_frenzy_timer, 3.5)
			var ne = nearest_enemy()
			if ne != null:
				_chain_lightning(ne, 3, 7)
			Fx.float_text(parent, global_position + Vector2(0, -64), "Tượng Phù Đổng!", Color(1.0, 0.42, 0.32), 13)


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


func _emit_dash_strike_fx(epos: Vector2) -> void:
	if get_parent() == null:
		return
	var cw: Dictionary = current_weapon()
	var is_bm: bool = bool(cw.get("boss_motif", false))
	if int(cw.get("tier", 1)) < 4 and not is_bm:
		return
	var tcol: Color = Color("ff384c") if is_bm else _tier_color(cw)
	if weapon_sprite != null and weapon_sprite.texture != null and weapon_pivot != null:
		Fx.weapon_trail(get_parent(), weapon_sprite.texture, weapon_sprite.global_position, weapon_pivot.rotation + swing, weapon_sprite.scale, weapon_sprite.flip_v, tcol, 0.22, weapon_sprite.offset, weapon_sprite.centered)
	Fx.decal(get_parent(), epos, "slash_mark", tcol, 1.05, _dash_dir.angle())


func _dash_damage() -> void:
	var dash_dmg: int = 16 if _dash_syn == 2 else (13 if _dash_syn == 1 else 10)
	for e in get_tree().get_nodes_in_group("enemies"):
		if _dash_hit.has(e):
			continue
		var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else (global_position.distance_to(e.global_position) - e.radius - 2.0)
		if dist_e < RADIUS + 12.0:
			_dash_hit.append(e)
			e.take_damage(dash_dmg, _dash_dir * 340.0)
			if _dash_syn == 2 and _dash_armor_gained < 3:
				_dash_armor_gained += 1
				if armor < max_armor:
					armor = mini(armor + 1, max_armor)
					stats_changed.emit()
			var epos: Vector2 = e.hurtbox_center() if e.has_method("hurtbox_center") else e.global_position
			_emit_dash_strike_fx(epos)
			Fx.anim(get_parent(), epos, "fx/spark.png", 15, 15, 24.0, 1.4, 0.0, Color(1, 0.9, 0.6), true)
			Fx.shake(get_tree(), 2.0)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < 20.0:
			b.destroy()


func _horse_damage() -> void:
	var ram_dmg: int = 10 + 3 * _horse_syn
	for e in get_tree().get_nodes_in_group("enemies"):
		if _dash_hit.has(e):
			continue
		var dist_e: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else (global_position.distance_to(e.global_position) - e.radius - 2.0)
		if dist_e < RADIUS + 12.0:
			_dash_hit.append(e)
			e.take_damage(ram_dmg, _dash_dir * 300.0)
			if is_instance_valid(e) and not e.dead and e.has_method("apply_status"):
				e.apply_status("burn", 2.5)
			var epos: Vector2 = e.hurtbox_center() if e.has_method("hurtbox_center") else e.global_position
			_emit_dash_strike_fx(epos)
			Fx.anim(get_parent(), epos, "fx/spark.png", 15, 15, 24.0, 1.4, 0.0, Color(1.0, 0.6, 0.2), true)
			Fx.shake(get_tree(), 2.0)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		if global_position.distance_to(b.global_position) < 20.0:
			b.destroy()


# ------------------------------------------------------------------ Vũ khí

func _next_filled_slot() -> int:
	_sync_weapon_slots()
	var n: int = weapons.size()
	if n <= 1:
		return -1
	for step in range(1, n):
		var idx: int = (slot + step) % n
		if str(weapons[idx]) != "":
			return idx
	return -1


func swap_weapon() -> bool:
	if dead or get_tree().paused or not is_physics_processing() or _swap_cd > 0.0:
		return false
	var nxt: int = _next_filled_slot()
	if nxt == -1:
		return false
	var g = get_tree().get_first_node_in_group("game")
	if g != null and not g.can_pause():
		return false
	slot = nxt
	_swap_cd = SWAP_COOLDOWN
	_fire_timer = 0.1
	_ranged_shot_count = 0
	_melee_swing_count = 0
	_charging = false
	charge_ratio = 0.0
	_refresh_weapon_sprite()
	stats_changed.emit()
	return true


func held_weapon_count() -> int:
	_sync_weapon_slots()
	var cnt: int = 0
	for w in weapons:
		if str(w) != "":
			cnt += 1
	return cnt


func can_drop_current_weapon() -> bool:
	if dead or downed:
		return false
	if is_inside_tree() and get_tree().get_first_node_in_group("lobby") != null:
		return false
	_sync_weapon_slots()
	return slot >= 0 and slot < weapons.size() and str(weapons[slot]) != "" and held_weapon_count() >= 2


func drop_current_weapon() -> bool:
	if not is_local or not can_drop_current_weapon():
		return false
	if is_inside_tree() and get_tree().paused:
		return false
	var g = get_tree().get_first_node_in_group("game") if is_inside_tree() else null
	if g != null and not g.can_pause():
		return false
	var dropped_wid: String = str(weapons[slot])
	var w_data: Dictionary = WeaponData.get_data(dropped_wid)
	var wname: String = str(w_data.get("name", dropped_wid))
	weapons[slot] = ""
	for i in weapons.size():
		if str(weapons[i]) != "":
			slot = i
			break
	_fire_timer = 0.1
	_ranged_shot_count = 0
	_melee_swing_count = 0
	_charging = false
	charge_ratio = 0.0
	_refresh_weapon_sprite()
	stats_changed.emit()
	Sfx.play("swap" if Sfx.SFX_FILES.has("swap") else "pickup_weapon")
	if get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0, -24), "Vứt: %s" % wname, WeaponData.tier_color(dropped_wid), 13)
	var dir: Vector2 = aim_dir.normalized() if aim_dir.length_squared() > 0.001 else Vector2.RIGHT
	var drop_pos: Vector2 = global_position + dir * 18.0
	if Net != null and Net.is_online():
		if Net.is_host():
			var gm: Node = get_tree().get_first_node_in_group("game_controller") if is_inside_tree() else null
			if gm == null and is_inside_tree():
				gm = get_tree().get_first_node_in_group("game")
			if gm != null and gm.has_method("host_spawn_shared_weapon"):
				gm.host_spawn_shared_weapon(dropped_wid, drop_pos)
			elif get_parent() != null:
				var drop_fb := Pickup.new()
				drop_fb.kind = "weapon"
				drop_fb.weapon_id = dropped_wid
				drop_fb.position = drop_pos
				get_parent().add_child(drop_fb)
		else:
			Net.send_world_event("drop_weapon_req", {"weapon_id": dropped_wid, "x": drop_pos.x, "y": drop_pos.y}, true)
		_send_net_state()
	elif get_parent() != null:
		var drop := Pickup.new()
		drop.kind = "weapon"
		drop.weapon_id = dropped_wid
		drop.position = drop_pos
		get_parent().add_child(drop)
	return true


func _preview_weapon_slot_for(wid: String) -> Dictionary:
	_sync_weapon_slots()
	for i in weapons.size():
		if str(weapons[i]) == wid:
			return {"already_has": true, "target_slot": i, "drop_wid": ""}
	for i in weapons.size():
		if str(weapons[i]) == "":
			return {"already_has": false, "target_slot": i, "drop_wid": ""}
	return {"already_has": false, "target_slot": slot, "drop_wid": str(weapons[slot])}


func net_apply_weapon_pickup(wid: String) -> void:
	if wid == "" or not WeaponData.DATA.has(wid):
		return
	_sync_weapon_slots()
	var empty_idx: int = -1
	for i in weapons.size():
		if str(weapons[i]) == "":
			empty_idx = i
			break
	if empty_idx != -1:
		weapons[empty_idx] = wid
		slot = empty_idx
	else:
		weapons[slot] = wid
	var w := WeaponData.get_data(wid)
	var was_disc: bool = Global.discovered.has(wid)
	Global.discover(wid)
	if not was_disc and get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0, -36), "Vũ khí mới vào kho!", Color(0.7, 1.0, 0.7), 13)
	if get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0, -24), str(w.get("name", wid)), WeaponData.tier_color(wid), 16)
		if int(w.get("tier", 1)) >= 4:
			Fx.particles(get_parent(), global_position, WeaponData.tier_color(wid), 16, 90.0, 0.6, -40.0, 2.0)
	Sfx.play("pickup_weapon")
	_charging = false
	charge_ratio = 0.0
	_refresh_weapon_sprite()
	stats_changed.emit()


func _try_pickup_nearby_weapon() -> bool:
	if nearby_pickup == null or not is_instance_valid(nearby_pickup):
		return false
	var pk: Node = nearby_pickup
	var wid: String = str(pk.get("weapon_id"))
	if wid == "":
		return false
	var preview: Dictionary = _preview_weapon_slot_for(wid)
	if bool(preview.get("already_has", false)):
		if _msg_cd <= 0.0 and get_parent() != null:
			_msg_cd = 0.8
			Fx.float_text(get_parent(), global_position + Vector2(0, -24), "Đã có vũ khí này!", Color(1.0, 0.85, 0.4), 13)
		return true
	var pid: int = int(pk.get("pickup_id"))
	if Net != null and Net.is_online() and pid > 0:
		pk.set("net_handled_claim", true)
		nearby_pickup = null
		var drop_wid: String = str(preview.get("drop_wid", ""))
		var drop_pos: Vector2 = (pk as Node2D).global_position
		var payload: Dictionary = {
			"pickup_id": pid,
			"drop_wid": drop_wid,
			"x": drop_pos.x,
			"y": drop_pos.y,
		}
		if Net.is_host():
			var gm: Node = get_tree().get_first_node_in_group("game_controller") if is_inside_tree() else null
			if gm == null and is_inside_tree():
				gm = get_tree().get_first_node_in_group("game")
			if gm != null and gm.has_method("host_handle_weapon_pickup_req"):
				gm.host_handle_weapon_pickup_req(Net.local_peer_id(), payload)
			else:
				net_apply_weapon_pickup(wid)
				pk.queue_free()
		else:
			Net.send_world_event("weapon_pickup_req", payload, true)
		return true
	pick_weapon(wid)
	pk.queue_free()
	nearby_pickup = null
	return true


func interact_only() -> bool:
	if dead or get_tree().paused or not is_physics_processing():
		return false
	if interact_target != null and is_instance_valid(interact_target):
		interact_target.interact()
		return true
	return _try_pickup_nearby_weapon()


func _swap_or_pickup() -> void:
	if interact_target != null and is_instance_valid(interact_target):
		interact_target.interact()
		return
	if _try_pickup_nearby_weapon():
		return
	var nxt: int = _next_filled_slot()
	if nxt != -1:
		slot = nxt
		_fire_timer = 0.1
		_charging = false
		charge_ratio = 0.0
		_refresh_weapon_sprite()
		stats_changed.emit()


func _find_merge_recipe(w1: String, w2: String) -> Dictionary:
	if w1 == "" or w2 == "":
		return {}
	var res: String = str(WeaponEvolutions.find_merge(w1, w2))
	if res == "":
		return {}
	for r in WeaponEvolutions.MERGE_RECIPES:
		if typeof(r) == TYPE_DICTIONARY:
			var rd: Dictionary = r
			var ra: String = str(rd.get("a", ""))
			var rb: String = str(rd.get("b", ""))
			if (ra == w1 and rb == w2) or (ra == w2 and rb == w1):
				return rd
	var rname: String = str(WeaponData.get_data(res).get("name", res))
	return {"a": w1, "b": w2, "result": res, "name": rname}


func can_merge_nearby() -> Dictionary:
	_sync_weapon_slots()
	# 1. Check nearby weapon pickup (nearby_pickup first, then pickups group within 28px)
	var cand_pickups: Array = []
	if nearby_pickup != null and is_instance_valid(nearby_pickup) and str(nearby_pickup.get("kind")) == "weapon":
		cand_pickups.append(nearby_pickup)
	if is_inside_tree():
		for pk in get_tree().get_nodes_in_group("pickups"):
			if is_instance_valid(pk) and str(pk.get("kind")) == "weapon" and not cand_pickups.has(pk):
				if global_position.distance_to((pk as Node2D).global_position) < 28.0:
					cand_pickups.append(pk)
	var check_order: Array[int] = [slot]
	for i in weapons.size():
		if i != slot:
			check_order.append(i)
	for pk in cand_pickups:
		var pwid: String = str(pk.get("weapon_id"))
		if pwid == "":
			continue
		for si in check_order:
			var ewid: String = str(weapons[si])
			if ewid == "":
				continue
			var rec := _find_merge_recipe(ewid, pwid)
			if not rec.is_empty():
				return {"recipe": rec, "pickup": pk, "slot_a": si}
	# 2. Check equipped mainhand + offhand
	var cur_w: String = str(weapons[slot])
	if cur_w != "":
		for i in weapons.size():
			if i == slot:
				continue
			var ow: String = str(weapons[i])
			if ow != "":
				var rec2 := _find_merge_recipe(cur_w, ow)
				if not rec2.is_empty():
					return {"recipe": rec2, "pickup": null, "slot_a": slot, "slot_b": i}
	return {}


func try_merge_weapon() -> bool:
	if dead or downed:
		return false
	var info: Dictionary = can_merge_nearby()
	if info.is_empty():
		return false
	var rec: Dictionary = info.get("recipe", {})
	var res: String = str(rec.get("result", ""))
	if res == "" or not WeaponData.DATA.has(res):
		return false
	var pk: Variant = info.get("pickup", null)
	var slot_a: int = clampi(int(info.get("slot_a", slot)), 0, weapons.size() - 1)
	var slot_b: int = int(info.get("slot_b", -1))
	if pk != null and is_instance_valid(pk):
		var pk_pid: int = int(pk.get("pickup_id"))
		if Net != null and Net.is_online() and pk_pid > 0:
			if Net.is_host():
				var ns: Node = get_tree().get_first_node_in_group("net_sync") if is_inside_tree() else null
				if ns != null:
					if ns.claimed_pickups.has(pk_pid):
						return false
					ns.claimed_pickups[pk_pid] = true
				pk.set("net_handled_claim", true)
				Net.send_world_event("pickup_claimed", {"id": pk_pid, "claimer": Net.local_peer_id()}, false)
			else:
				pk.set("net_handled_claim", true)
				Net.send_world_event("pickup_claim", {"id": pk_pid}, true)
		weapons[slot_a] = res
		slot = slot_a
		if nearby_pickup == pk:
			nearby_pickup = null
		(pk as Node).queue_free()
	elif slot_b >= 0 and slot_b < weapons.size():
		weapons[slot_a] = res
		weapons[slot_b] = ""
		slot = slot_a
	else:
		return false
	Global.discover(res)
	_charging = false
	charge_ratio = 0.0
	_refresh_weapon_sprite()
	stats_changed.emit()
	var par := get_parent()
	if par != null:
		var rw := WeaponData.get_data(res)
		var tcol: Color = WeaponData.tier_color(res)
		Fx.burst(par, global_position, tcol, 56.0, 0.55)
		Fx.particles(par, global_position, tcol, 24, 120.0, 0.7, -40.0, 2.2)
		Fx.float_text(par, global_position + Vector2(0, -32), "✦ HỢP NHẤT: %s! ✦" % str(rw.get("name", res)), tcol, 16)
		Fx.shake(get_tree(), 3.5)
	Sfx.play("chest_open")
	return true


## Trạng thái nhân vật để lưu lượt chơi dở
func snapshot() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"armor": armor, "max_armor": max_armor,
		"energy": energy, "max_energy": max_energy,
		"weapons": weapons.duplicate(), "slot": slot,
		"mount_id": mount_id, "mount_hp": mount_hp, "mount_max_hp": mount_max_hp,
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
	if ws.size() >= 2 and str(ws[0]) != "":
		weapons = []
		for w_item in ws:
			weapons.append(str(w_item))
	_sync_weapon_slots()
	slot = clampi(int(d.get("slot", 0)), 0, maxi(0, weapons.size() - 1))
	if weapons[slot] == "":
		slot = 0
	var r_mid: String = str(d.get("mount_id", ""))
	var r_mhp: int = int(d.get("mount_hp", 0))
	if r_mid != "" and r_mhp > 0:
		mount_id = r_mid
		mount_hp = r_mhp
		mount_max_hp = maxi(r_mhp, int(d.get("mount_max_hp", r_mhp)))


func pick_weapon(id: String) -> void:
	_sync_weapon_slots()
	var empty_idx: int = -1
	for i in weapons.size():
		if str(weapons[i]) == "":
			empty_idx = i
			break
	if empty_idx != -1:
		weapons[empty_idx] = id
		slot = empty_idx
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


## Trang bị vũ khí thử nghiệm tại Võ Đường (không mở khóa bản vẽ hay rơi vũ khí cũ)
func equip_test_weapon(wid: String) -> bool:
	if not WeaponData.DATA.has(wid):
		return false
	_sync_weapon_slots()
	if _lobby_test_backup.is_empty():
		_lobby_test_backup = weapons.duplicate()
	slot = clampi(slot, 0, maxi(0, weapons.size() - 1))
	weapons[slot] = wid
	_fire_timer = 0.0
	_ranged_shot_count = 0
	_melee_swing_count = 0
	_charging = false
	charge_ratio = 0.0
	_refresh_weapon_sprite()
	stats_changed.emit()
	if get_parent() != null:
		var wname: String = str(WeaponData.get_data(wid).get("name", wid))
		Fx.float_text(get_parent(), global_position + Vector2(0, -26), "Thử: %s" % wname, WeaponData.tier_color(wid), 14)
	return true


## Khôi phục bộ vũ khí gốc sau khi rời Võ Đường / trước khi xuất trận
func restore_test_weapons() -> void:
	if _lobby_test_backup.is_empty():
		return
	weapons = _lobby_test_backup.duplicate()
	_lobby_test_backup.clear()
	_sync_weapon_slots()
	slot = clampi(slot, 0, maxi(0, weapons.size() - 1))
	if slot >= 0 and slot < weapons.size() and str(weapons[slot]) == "":
		for i in weapons.size():
			if str(weapons[i]) != "":
				slot = i
				break
	_fire_timer = 0.0
	_charging = false
	charge_ratio = 0.0
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


func _refresh_mount_visual() -> void:
	if mount_sprite == null:
		return
	if mount_id == "" or mount_hp <= 0:
		mount_sprite.visible = false
		return
	var rel_world: String = "world/%s.png" % mount_id
	if ResourceLoader.exists("res://assets/sprites/" + rel_world):
		var tex: Texture2D = Art.tex(rel_world)
		var fw: int = mini(32, tex.get_width()) if tex != null else 32
		var fh: int = tex.get_height() if tex != null else 32
		mount_sprite.sprite_frames = Art.strip(rel_world, fw, fh, 6.0, true)
	elif mount_id == "voi_chien_mount" and elephant != null:
		mount_sprite.sprite_frames = elephant.sprite_frames
	elif mount_id == "ngua_sat_mount" and iron_horse != null:
		mount_sprite.sprite_frames = iron_horse.sprite_frames
	elif ResourceLoader.exists("res://assets/sprites/enemies/xe_tang.png"):
		mount_sprite.sprite_frames = Art.strip("enemies/xe_tang.png", 40, 30, 8.0, true)
	mount_sprite.visible = true


func board_mount(mid: String, mhp: int = -1) -> void:
	if mid == "":
		mount_id = ""
		mount_hp = 0
		mount_max_hp = 0
		if Global != null:
			Global.set("active_mount", "")
			Global.set("active_mount_hp", 0)
		_refresh_mount_visual()
		stats_changed.emit()
		return
	var info: Dictionary = MOUNTS.get(mid, {"name": mid, "hp": 10, "speed": 1.15, "color": Color(0.9, 0.8, 0.4)})
	var base_hp: int = mhp if mhp > 0 else int(info.get("hp", 10))
	if buff("chien_xa_ben") > 0:
		base_hp = int(round(float(base_hp) * (1.0 + 0.5 * float(buff("chien_xa_ben")))))
	mount_id = mid
	mount_max_hp = base_hp
	mount_hp = base_hp
	if Global != null:
		Global.set("active_mount", mount_id)
		Global.set("active_mount_hp", mount_hp)
	_refresh_mount_visual()
	if is_inside_tree() and get_parent() != null:
		Fx.burst(get_parent(), global_position, info.get("color", Color(1.0, 0.85, 0.4)), 38.0, 0.4)
		Fx.float_text(get_parent(), global_position + Vector2(0, -28), "Cưỡi %s!" % str(info.get("name", mid)), info.get("color", Color(1.0, 0.85, 0.4)), 15)
	Sfx.play("pickup_weapon")
	stats_changed.emit()


func take_damage(amount: int, source: String = "") -> void:
	if dead or downed or _invuln > 0.0 or _dash_time > 0.0 or _horse_time > 0.0 or _dodge_dash_t > 0.0:
		return
	if Net != null and Net.is_online() and not is_local:
		return
	var dodge_chance: float = minf(0.12 * buff("bua_ho_menh"), 0.45)
	if in_trench:
		dodge_chance += 0.40 if hero_id == "chien_si_dien_bien" else 0.25
	if in_stealth_bush and hero_id == "hoang_hoa_tham":
		dodge_chance += 0.15
	if randf() < minf(dodge_chance, 0.75):
		_invuln = 0.3
		Fx.float_text(get_parent(), global_position + Vector2(0, -22), "Né!", Color(0.7, 0.9, 1.0), 16)
		return
	var dmg: int = Global.scale_enemy_damage(amount)
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("glass_cannon"):
		dmg *= 2
	if buff("tuong_thach") > 0 and dmg > 1 and randf() < 0.25:
		dmg = maxi(1, dmg - 1)
	if hero_id == "ba_trieu" and armor >= max_armor and max_armor > 0 and dmg > 1:
		dmg = maxi(1, dmg - 1)
	if dmg <= 0:
		return
	Global.run_last_hit = source if source != "" else _nearest_attacker_name()
	if mount_id != "" and mount_hp > 0:
		var m_absorbed: int = mini(mount_hp, dmg)
		mount_hp -= m_absorbed
		dmg -= m_absorbed
		if Global != null:
			Global.set("active_mount_hp", mount_hp)
		if mount_hp <= 0:
			mount_id = ""
			mount_max_hp = 0
			if Global != null:
				Global.set("active_mount", "")
				Global.set("active_mount_hp", 0)
			_refresh_mount_visual()
			if get_parent() != null:
				Fx.burst(get_parent(), global_position, Color(1.0, 0.55, 0.25), 36.0, 0.35)
				Fx.float_text(get_parent(), global_position + Vector2(0, -28), "Thú cưỡi gục!", Color(1.0, 0.5, 0.35), 14)
		if dmg <= 0:
			_invuln = 0.45
			_flash = 0.7
			Sfx.play("hit_metal")
			Fx.particles(get_parent(), global_position, Color(0.9, 0.85, 0.5), 6, 65.0, 0.3)
			stats_changed.emit()
			return
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
	if dead or downed or _dash_time > 0.0 or _horse_time > 0.0 or _dodge_dash_t > 0.0:
		return
	if (kind == "burn" and (buff("khien_lua") > 0 or hero_id == "nguyen_trung_truc")) or (kind == "poison" and buff("khien_doc") > 0):
		return
	if Net != null and Net.is_online() and not is_local:
		return
	var dmg: int = Global.scale_enemy_damage(amount)
	if dmg <= 0:
		return
	Global.run_last_hit = "Cháy" if kind == "burn" else "Độc"
	_flash = 0.6
	_armor_regen = ARMOR_REGEN_DELAY
	if mount_id != "" and mount_hp > 0:
		var m_abs: int = mini(mount_hp, dmg)
		mount_hp -= m_abs
		dmg -= m_abs
		if Global != null:
			Global.set("active_mount_hp", mount_hp)
		if mount_hp <= 0:
			mount_id = ""
			mount_max_hp = 0
			if Global != null:
				Global.set("active_mount", "")
				Global.set("active_mount_hp", 0)
			_refresh_mount_visual()
		if dmg <= 0:
			stats_changed.emit()
			return
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
	var m: float = 1.0 + 0.2 * buff("ruou_thuoc")
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("glass_cannon"):
		m *= 2.0
	return m


func crit_chance() -> float:
	var c: float = 0.12 * buff("mat_than") + 0.08 * buff("xuyen_tam") + (0.15 if _frenzy_timer > 0.0 else 0.0)
	if hero_id == "ly_thuong_kiet" or hero_id == "hoang_hoa_tham":
		c += 0.10
	if hero_id == "tran_hung_dao" and is_inside_tree():
		var near_ally: bool = false
		for a in get_tree().get_nodes_in_group("allies"):
			if is_instance_valid(a) and global_position.distance_to((a as Node2D).global_position) <= 150.0:
				near_ally = true
				break
		if near_ally or skill_timer > 0.0:
			c += 0.15
	if in_stealth_bush:
		c += 0.35 if hero_id == "hoang_hoa_tham" else 0.25
	return c


func is_kinetic_ready() -> bool:
	return buff("tich_luc") > 0 and _kinetic_charge >= 100.0


func restore_armor(amount: int) -> void:
	if amount <= 0 or dead or downed:
		return
	var before: int = armor
	armor = mini(armor + amount, max_armor)
	if armor > before and get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0, -24), "+%d giáp" % (armor - before), Color(0.65, 0.85, 1.0), 13)
	stats_changed.emit()


func sync_gold_armor() -> void:
	var target: int = mini(4, int(Global.run_coins / 60)) if buff("kim_giap") > 0 else 0
	var diff: int = target - _gold_armor_bonus
	if diff != 0:
		max_armor = maxi(0, max_armor + diff)
		armor = clampi(armor + maxi(0, diff), 0, max_armor)
		_gold_armor_bonus = target
		stats_changed.emit()


func on_coins_collected(gained: int) -> void:
	if buff("kim_giap") <= 0 or gained <= 0:
		return
	sync_gold_armor()
	_coin_armor_acc += gained
	while _coin_armor_acc >= 15:
		_coin_armor_acc -= 15
		if armor < max_armor:
			restore_armor(1)


func _ensure_spirit_blade() -> void:
	if _spirit_blade != null and is_instance_valid(_spirit_blade):
		return
	var sb := SpiritBlade.new()
	sb.player = self
	add_child(sb)
	_spirit_blade = sb


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
		"phi_kiem":
			_ensure_spirit_blade()
		"kim_giap":
			sync_gold_armor()
		"song_kiem_hop":
			_sync_weapon_slots()
		"tuong_thach":
			max_armor += 2
			armor = mini(armor + 2, max_armor)
		"chien_xa_ben":
			if mount_id != "" and mount_max_hp > 0:
				var add_m: int = maxi(2, int(round(float(mount_max_hp) * 0.5)))
				mount_max_hp += add_m
				mount_hp += add_m
				if Global != null:
					Global.set("active_mount_hp", mount_hp)
		"thuong_khach":
			if is_inside_tree():
				get_tree().call_group("shop_stands", "refresh_price")
	Fx.particles(get_parent(), global_position, Color(1, 0.9, 0.5), 24, 120.0, 0.7, -40.0, 2.0)
	stats_changed.emit()


## Gọi khi hạ được 1 kẻ địch
func on_kill(pos: Vector2 = Vector2.ZERO) -> void:
	_passive_kill_count += 1
	if hero_id == "ly_thuong_kiet" and _passive_kill_count % 6 == 0:
		restore_armor(1)
	if hero_id == "thanh_giong" and _passive_kill_count % 10 == 0 and _tg_bonus_hp < 3:
		_tg_bonus_hp += 1
		max_hp += 1
		hp += 1
		stats_changed.emit()
	if hero_id == "le_loi" and randf() < 0.15:
		restore_armor(1)
	if buff("huyet_sam") > 0 and randf() < 0.08 * buff("huyet_sam"):
		heal(1)
	if buff("hut_nang_luong") > 0:
		add_energy(10 * buff("hut_nang_luong"))
	if buff("huyet_nguyet") > 0:
		var was_active: bool = _frenzy_timer > 0.0
		_frenzy_timer = 3.5
		if not was_active and get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0, -28), "Cuồng chiến!", Color(1.0, 0.35, 0.42), 14)
	if buff("loi_dinh") > 0 and _lightning_cd <= 0.0 and is_inside_tree():
		var origin: Vector2 = pos if pos != Vector2.ZERO else global_position
		var near_e: Node = null
		var near_d: float = 120.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and not e.dead:
				var d: float = origin.distance_to((e as Node2D).global_position)
				if d < near_d:
					near_d = d
					near_e = e
		if near_e != null:
			_lightning_cd = 0.6
			_chain_lightning(near_e, 3, 6)


func on_crit_enemy(e) -> void:
	if is_inside_tree():
		Fx.hitstop(get_tree(), 0.026)
	if buff("loi_dinh") > 0 and _lightning_cd <= 0.0 and is_instance_valid(e) and not e.dead:
		_lightning_cd = 0.6
		_chain_lightning(e, 3, 6)


func consume_kinetic_hit(e) -> void:
	if buff("tich_luc") <= 0 or _kinetic_charge < 100.0:
		return
	_kinetic_charge = 0.0
	if is_instance_valid(e) and not e.dead and e.has_method("apply_stun"):
		e.apply_stun(0.9)
	if get_parent() != null:
		var wr := WaveRing.new()
		wr.position = (e as Node2D).global_position if is_instance_valid(e) else global_position
		wr.radius = 58.0
		wr.damage = 6
		wr.color = Color(1.0, 0.88, 0.35)
		get_parent().add_child(wr)
		Fx.float_text(get_parent(), global_position + Vector2(0, -28), "Xung kích!", Color(1.0, 0.9, 0.3), 15)
	Fx.hitstop(get_tree(), 0.03)


func burn_bonus_mult(target) -> int:
	if _burn_double_timer > 0.0 and target != null and is_instance_valid(target) and target.get("status") != null and target.status.has("burn"):
		return 2
	return 1


func on_hit_enemy(e) -> void:
	if is_instance_valid(e) and not e.dead:
		last_hit_enemy = e
		if _mark_timer > 0.0:
			e.set_meta("marked_until", Time.get_ticks_msec() + 3000)
		if buff("khien_doc") > 0 and randf() < 0.20 and e.has_method("apply_status"):
			e.apply_status("poison", 3.0)
		if buff("ngu_hanh") > 0 and _elem_cd <= 0.0:
			_elem_cd = 0.45
			match _elem_idx:
				0:
					if e.has_method("apply_status"):
						e.apply_status("burn", 2.5)
				1:
					if e.has_method("apply_status"):
						e.apply_status("poison", 3.0)
				2:
					if e.has_method("apply_stun"):
						e.apply_stun(0.5)
					if get_parent() != null:
						Fx.particles(get_parent(), (e as Node2D).global_position, Color(1.0, 0.95, 0.45), 6, 70.0, 0.25)
			_elem_idx = (_elem_idx + 1) % 3
		consume_kinetic_hit(e)


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


func _play_remote_weapon_sfx(data: Dictionary, fallback_sfx: String = "shoot") -> void:
	var cur_wid: String = str(weapons[slot]) if slot >= 0 and slot < weapons.size() else ""
	var r_wid: String = str(data.get("wid", cur_wid))
	if r_wid != "":
		Sfx.play_weapon(r_wid, WeaponData.get_data(r_wid))
	else:
		Sfx.play(str(data.get("sfx", fallback_sfx)))


func play_remote_action(kind: String, data: Dictionary) -> void:
	if is_local or get_parent() == null:
		return
	var parent: Node = get_parent()
	match kind:
		"shoot":
			if not bool(data.get("silent", false)):
				_play_remote_weapon_sfx(data, "shoot")
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
				_play_remote_weapon_sfx(data, "slash")
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
			_play_remote_weapon_sfx(data, "shoot")
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
			_play_remote_weapon_sfx(data, "skill")
			var rw := _RemoteWaveFx.new()
			rw.position = Vector2(float(data.get("x", global_position.x)), float(data.get("y", global_position.y)))
			rw.radius = float(data.get("radius", 110.0))
			rw.color = Color.html(str(data.get("col", "ffbf59ff")))
			rw.notes = bool(data.get("notes", false))
			parent.add_child(rw)
		"spikes":
			_play_remote_weapon_sfx(data, "explode")
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
	Sfx.play_skill(str(data.get("hero_id", hero_id)))
	if body != null and not dead and not downed:
		_anim_lock_t = 0.44
		body.play("skill")
		body.frame = 0
	_cast_pulse_t = 0.44
	_cast_pulse_col = (hero.get("color", Color(1.0, 0.88, 0.7)) as Color).lightened(0.35)
	SkillCastFx.spawn(parent, pos, dir, sk, Color(0, 0, 0, 0), syn)
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
