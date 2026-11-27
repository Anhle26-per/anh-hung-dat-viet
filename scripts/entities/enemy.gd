extends CharacterBody2D
## Kẻ địch: lính các đạo quân xâm lược, yêu quái do tà thuật gọi ra, và trùm.
## Thông số lấy từ scripts/data/enemies.gd. Kiểu AI:
##   chase (lao vào đánh), shoot (giữ khoảng cách bắn tên), tank (khiên đỡ đòn phía trước),
##   caster (pháp sư: bắn vòng đạn + gọi yêu quái), charge (kỵ binh lấy đà rồi xông tới),
##   ring (bắn vòng đạn), ngu (thủy quái), boss (trùm, theo danh sách chiêu)

signal killed(enemy)

const EnemyData = preload("res://scripts/data/enemies.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const MortarStrike = preload("res://scripts/effects/mortar_strike.gd")
const StatusFx = preload("res://scripts/effects/status_fx.gd")
const Miasma = preload("res://scripts/effects/miasma.gd")

var kind := "bo_binh"
var data: Dictionary = {}
var hp := 1
var max_hp := 1
var radius := 7.0
var speed := 60.0
var dead := false
var room = null
var player = null
var level := 1
var elite := false   # giặc tinh nhuệ: to hơn, trâu hơn, viền vàng, dễ rơi vũ khí

var spr: AnimatedSprite2D
var _mat: ShaderMaterial
var _spawn_t := 0.6
var _shoot_t := 1.0
var _summon_t := 5.0
var _contact_t := 0.0
var _flash := 0.0
var _stun_t := 0.0
var _knock := Vector2.ZERO
var _wander := Vector2.ZERO
var _wander_t := 0.0
var _face := 1.0
var _attack_anim_t := 0.0
var _hurt_anim_t := 0.0
# lấy đà / xông tới
var _charge_state := ""
var _charge_t := 0.0
var _charge_dir := Vector2.ZERO
# trùm
var _phase := -1
var _phase_t := 0.0
var _spiral := 0.0
var _volleys := 0
var _special_used := false
var _special_t := 0.0
var _special := ""
var _burst_left := 0
var _burst_t := 0.0
var _burst_spread := 6.0
var _slowed := false
# trùm nổi giận: thêm 1 bộ đếm chiêu độc lập (chướng khí / hỏa tiễn) chạy song song
var enraged := false
var _rage_t := 2.0
var _rage_n := 0
var status: Node2D
# biến hình (hiện nguyên hình) khi còn nửa máu
var transformed := false
var _morph_t := 0.0
var _shadow: Sprite2D
var _shape: CircleShape2D
var _submerged := false     # Ngư Tinh lặn: không trúng đòn
var _hp_bar_t: float = 0.0
var last_hit_crit: bool = false
var net_id: int = 0
var is_replica: bool = false
var _net_pos: Vector2 = Vector2.ZERO
var _net_anim: String = "walk"
var _hurtbox: Area2D
var _hurtbox_cs: CollisionShape2D
var _hurtbox_shape: RectangleShape2D
var _hb_size: Vector2 = Vector2(16.0, 20.0)
var _hb_offset: Vector2 = Vector2(0.0, -6.0)
var _strafe_dir: float = 1.0
var _strafe_t: float = 0.0
var _steer_sign: float = 0.0
var _steer_t: float = 0.0
var _flank_sign: float = 1.0
var _boss_t: float = 0.0
var _boss_fx_t: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _base_spr_y: float = 0.0
var _anim_scale: Vector2 = Vector2.ONE
var _step_t: float = 0.0
var _step_dust_t: float = 0.0
var _leap_state: String = ""
var _leap_t: float = 0.0
var _leap_z: float = 0.0
var _leap_start: Vector2 = Vector2.ZERO
var _leap_target: Vector2 = Vector2.ZERO
var _dash_hit_wall: bool = false
var _windup_glint_done: bool = false
var _hazard_slow_t: float = 0.0
var _hazard_slow_mult: float = 1.0
var _aggro_reveal_t: float = 0.0
var _action_anim: String = ""
var _action_anim_t: float = 0.0
var _prev_net_anim: String = ""
var _spiral_fx_t: float = 0.0


func setup(k: String, lvl: int, target) -> void:
	kind = k
	level = lvl
	data = EnemyData.info(k, lvl)
	max_hp = data.hp
	if Net.is_online() and Net.player_count() > 1:
		max_hp = int(round(float(max_hp) * (1.0 + 0.5 * float(Net.player_count() - 1))))
	if Global != null and bool(Global.get("badass_mode")):
		max_hp = int(round(float(max_hp) * 1.45))
	hp = max_hp
	radius = data.radius
	speed = data.speed
	if Global != null and bool(Global.get("badass_mode")):
		speed *= 1.18
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("hyper_speed"):
		speed *= 1.35
	player = target
	_shoot_t = randf_range(0.8, 1.8)
	if Global != null and bool(Global.get("badass_mode")):
		_shoot_t *= 0.8
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("elite_swarm"):
		_shoot_t *= 0.85
	_summon_t = randf_range(4.0, 6.0)
	_strafe_dir = -1.0 if randf() < 0.5 else 1.0
	_strafe_t = randf_range(1.4, 2.6)
	_flank_sign = -1.0 if randf() < 0.5 else 1.0
	if is_boss():
		_spawn_t = 1.2


## Biến thành giặc tinh nhuệ (gọi trước khi thêm vào cây cảnh)
func make_elite() -> void:
	if elite:
		return
	elite = true
	max_hp = int(max_hp * 2.4)
	hp = max_hp
	radius *= 1.2
	speed *= 1.1


## Bậc sức mạnh của trùm = thứ tự gặp trong lượt (0 = trùm đầu tiên)
func power() -> float:
	return float(data.get("power", 0))


func is_boss() -> bool:
	return data.get("boss", false)


func is_spawning() -> bool:
	return _spawn_t > 0.0


func display_name() -> String:
	return data.name


func title() -> String:
	return data.get("title", "")


func _ready() -> void:
	add_to_group("enemies")
	if is_boss():
		add_to_group("boss")
	# Thân CharacterBody2D chỉ dùng để né tường/vật cản ở chân; hitbox nhận đòn phủ toàn thân bằng Area2D
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = radius * 0.72
	_shape = shape
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	z_index = 1

	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 4
	_hurtbox.collision_mask = 0
	_hurtbox.monitorable = true
	_hurtbox.monitoring = false
	_hurtbox.set_meta("enemy", self)
	_hurtbox.add_to_group("enemy_hurtboxes")
	_hurtbox_shape = RectangleShape2D.new()
	_hurtbox_cs = CollisionShape2D.new()
	_hurtbox_cs.shape = _hurtbox_shape
	_hurtbox.add_child(_hurtbox_cs)
	add_child(_hurtbox)

	var sh := Sprite2D.new()
	_shadow = sh
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, radius * 0.9)
	sh.scale = Vector2(radius / 7.0, radius / 7.0)
	sh.z_index = -2
	add_child(sh)

	var size: Vector2i = data.size
	var n: int = data.get("frames", 4)
	var anims := _build_anims(n)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Art.frames(data.sheet, size.x, size.y, anims)
	spr.position = Vector2(0, radius - size.y / 2.0)
	_mat = Art.flash_material()
	spr.material = _mat
	spr.play("walk")
	spr.frame = randi() % (8 if n >= 16 else 4)
	spr.modulate = Color(1, 1, 1, 0)
	add_child(spr)
	if elite:
		spr.scale = Vector2(1.25, 1.25)
		spr.position.y *= 1.25
		_mat.set_shader_parameter("flash_color", Color(1.0, 0.8, 0.25))
		var glow := Art.light(Color(1.0, 0.75, 0.3), 0.8, 0.7)
		add_child(glow)
	_base_scale = spr.scale
	_anim_scale = _base_scale
	_base_spr_y = spr.position.y
	Fx.anim(get_parent(), position, "fx/poof.png", 28, 28, 16.0, radius / 8.0, 0.0, Color(1, 0.6, 0.6) if not is_boss() else Color(1, 0.4, 0.4))
	status = StatusFx.new()
	status.unit = self
	status.tick_damage = 2 + int(level / 4)
	add_child(status)
	_sync_hurtbox(size)
	if _net_pos == Vector2.ZERO:
		_net_pos = global_position


func _reset_motion_fx() -> void:
	_leap_state = ""
	_leap_t = 0.0
	_leap_z = 0.0
	_dash_hit_wall = false
	_windup_glint_done = false
	_action_anim = ""
	_action_anim_t = 0.0
	_anim_scale = _base_scale
	if spr != null:
		spr.scale = _base_scale
		spr.position = Vector2(0.0, _base_spr_y)
	if _shadow != null:
		_shadow.scale = Vector2(radius / 7.0, radius / 7.0)


func _sync_hurtbox(cur_size: Vector2i) -> void:
	var sc: float = 1.25 if (elite and not is_boss()) else 1.0
	_hb_size = Vector2(
		maxf(float(cur_size.x) * sc * 0.74, radius * 1.9),
		maxf(float(cur_size.y) * sc * 0.80, radius * 2.1)
	)
	var base_y: float = spr.position.y if spr != null else 0.0
	_hb_offset = Vector2(0.0, base_y + float(cur_size.y) * sc * 0.04)
	if _hurtbox_shape != null:
		_hurtbox_shape.size = _hb_size
	if _hurtbox_cs != null:
		_hurtbox_cs.position = _hb_offset
	if status != null:
		status.head = maxf(12.0, -(_hb_offset.y - _hb_size.y * 0.5) + 4.0)


func hurtbox_rect() -> Rect2:
	return Rect2(global_position + _hb_offset - _hb_size * 0.5, _hb_size)


func hurtbox_center() -> Vector2:
	return global_position + _hb_offset


func closest_point_on_hurtbox(pt: Vector2) -> Vector2:
	var r: Rect2 = hurtbox_rect()
	return Vector2(clampf(pt.x, r.position.x, r.end.x), clampf(pt.y, r.position.y, r.end.y))


func distance_to_hurtbox(pt: Vector2) -> float:
	return pt.distance_to(closest_point_on_hurtbox(pt))


func _touches_player(ppos: Vector2) -> bool:
	var c := global_position + Vector2(0.0, -_hb_size.y * 0.12)
	var rx: float = maxf(radius, _hb_size.x * 0.44) + 5.0
	var ry: float = maxf(radius * 0.85, _hb_size.y * 0.30) + 5.0
	var dx: float = (ppos.x - c.x) / rx
	var dy: float = (ppos.y - c.y) / ry
	return dx * dx + dy * dy <= 1.0


func _boss_color() -> Color:
	var bid: String = str(data.get("id", ""))
	if bid in ["cuu_vi_ho", "ho_tinh_vuong"]:
		return Color(0.84, 0.34, 1.0) if transformed else Color(1.0, 0.38, 0.72)
	if bid in ["xuong_cuong", "moc_tinh_vuong"]:
		return Color(1.0, 0.38, 0.22) if transformed else Color(0.32, 0.92, 0.45)
	if bid in ["hac_hai_ngu", "ngu_tinh_vuong"]:
		return Color(0.45, 0.48, 1.0) if transformed else Color(0.28, 0.80, 1.0)
	return Color(0.88, 0.26, 0.96) if transformed else Color(1.0, 0.44, 0.24)


func current_anim_name() -> String:
	if spr != null:
		return str(spr.animation)
	return "walk"


func apply_net_state(pos: Vector2, new_hp: int, new_max_hp: int, anim: String, face: float, is_trans: bool, sub: bool) -> void:
	_net_pos = pos
	if new_max_hp > 0:
		max_hp = new_max_hp
	if new_hp < hp and not is_boss():
		_hp_bar_t = 3.0
		queue_redraw()
	hp = new_hp
	_net_anim = anim
	_face = face
	if is_trans and not transformed and data.has("sheet2"):
		_finish_morph()
	_submerged = sub


func _physics_process(delta: float) -> void:
	if dead:
		return
	_boss_t += delta
	if _hp_bar_t > 0.0:
		_hp_bar_t = maxf(_hp_bar_t - delta, 0.0)
		queue_redraw()
	if is_boss() or _charge_state != "" or _leap_state != "" or _submerged:
		queue_redraw()
	_flash = maxf(_flash - delta * 8.0, 0.0)
	var base_glow := 0.18 + 0.1 * sin(Time.get_ticks_msec() / 150.0) if elite else 0.0
	_mat.set_shader_parameter("flash", maxf(_flash, base_glow))
	_attack_anim_t -= delta
	_hurt_anim_t = maxf(_hurt_anim_t - delta, 0.0)
	_hazard_slow_t = maxf(_hazard_slow_t - delta, 0.0)
	_aggro_reveal_t = maxf(_aggro_reveal_t - delta, 0.0)
	if _hazard_slow_t <= 0.0:
		_hazard_slow_mult = 1.0
	if is_boss() and (enraged or transformed) and not _submerged and _spawn_t <= 0.0 and _morph_t <= 0.0:
		_boss_fx_t -= delta
		if _boss_fx_t <= 0.0:
			_boss_fx_t = 0.18
			var hb: Rect2 = hurtbox_rect()
			var rpos := Vector2(randf_range(hb.position.x, hb.end.x), randf_range(hb.position.y + hb.size.y * 0.25, hb.end.y))
			Fx.particles(get_parent(), rpos, _boss_color(), 2, 34.0, 0.45, -36.0, 1.8)
	player = Global.nearest_player(global_position)
	if is_replica:
		var prev_pos: Vector2 = global_position
		global_position = global_position.lerp(_net_pos, clampf(delta * 16.0, 0.0, 1.0))
		spr.flip_h = _face < 0.0
		if _spawn_t > 0.0:
			_spawn_t -= delta
			spr.modulate.a = 1.0 - clampf(_spawn_t / 0.6, 0.0, 1.0)
			return
		if _morph_t > 0.0:
			_morph_t -= delta
			_flash = 0.5 + 0.5 * sin(_morph_t * 30.0)
			spr.position.x = sin(_morph_t * 60.0) * 1.5
			var rage_anim := _resolve_anim("rage")
			if spr.sprite_frames.has_animation(rage_anim) and spr.animation != rage_anim:
				spr.play(rage_anim)
			if int(_morph_t * 20.0) % 2 == 0:
				Fx.particles(get_parent(), global_position + Vector2(randf_range(-16, 16), randf_range(-24, 4)), Color(0.55, 0.2, 0.7), 3, 50.0, 0.6, -50.0, 2.5)
			if _morph_t <= 0.0 and not transformed and data.has("sheet2"):
				_finish_morph()
			return
		spr.modulate.a = 0.25 if _submerged else 1.0
		if _net_anim != "":
			var net_resolved := _resolve_anim(_net_anim)
			if spr.sprite_frames.has_animation(net_resolved):
				if spr.animation != net_resolved or (_net_anim != _prev_net_anim and not spr.sprite_frames.get_animation_loop(net_resolved)):
					spr.frame = 0
					spr.play(net_resolved)
				_prev_net_anim = _net_anim
		var rep_spd: float = (global_position - prev_pos).length() / maxf(delta, 0.001)
		_apply_lively_motion(delta, rep_spd)
		_contact_t -= delta
		if not _submerged and _contact_t <= 0.0:
			var lp: Node = Global.local_player()
			if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")) and not bool(lp.get("downed")):
				if _touches_player((lp as Node2D).global_position):
					lp.take_damage((2 + int(power() / 5.0)) if is_boss() else (2 if elite else 1))
					_contact_t = 0.8
		return
	if _spawn_t > 0.0:
		_spawn_t -= delta
		spr.modulate.a = 1.0 - clampf(_spawn_t / 0.6, 0.0, 1.0)
		return
	spr.modulate.a = 1.0
	if is_boss():
		if _morph_t > 0.0:
			_morph_t -= delta
			_flash = 0.5 + 0.5 * sin(_morph_t * 30.0)
			spr.position.x = sin(_morph_t * 60.0) * 1.5
			if int(_morph_t * 20.0) % 2 == 0:
				Fx.particles(get_parent(), global_position + Vector2(randf_range(-16, 16), randf_range(-24, 4)), Color(0.55, 0.2, 0.7), 3, 50.0, 0.6, -50.0, 2.5)
			if _morph_t <= 0.0:
				_finish_morph()
			velocity = Vector2.ZERO
			move_and_slide()
			_update_anim(delta)
			return
		if hp < max_hp / 2 and not transformed and data.has("sheet2"):
			_stun_t = 0.0
			_start_morph()
			return

	var desired := Vector2.ZERO
	if _stun_t > 0.0:
		_stun_t -= delta
		spr.modulate = Color(0.75, 0.75, 1.0)
		if int(_stun_t * 6.0) % 3 == 0 and randf() < 0.2:
			Fx.particles(get_parent(), Vector2(global_position.x, hurtbox_rect().position.y - 4.0), Color(1, 0.95, 0.4), 1, 30.0, 0.4, 0.0, 1.0)
	elif player != null and is_instance_valid(player) and not player.dead:
		spr.modulate = Color.WHITE
		var to: Vector2 = player.global_position - global_position
		var dist := to.length()
		var dir := to / maxf(dist, 0.001)
		_face = 1.0 if to.x >= 0.0 else -1.0
		var stealthed: bool = bool(player.get("in_stealth_bush")) and _aggro_reveal_t <= 0.0 and dist > 75.0
		if stealthed:
			desired = _wander_vec(delta) * speed * 0.35
		else:
			var _badass: bool = Global != null and bool(Global.get("badass_mode"))
			var _hspd: bool = Global != null and Global.has_method("has_mutator") and Global.has_mutator("hyper_speed")
			var _esw: bool = Global != null and Global.has_method("has_mutator") and Global.has_mutator("elite_swarm")
			var shoot_rate_mult: float = (0.8 if _badass else 1.0) * (0.85 if _hspd else 1.0) * (0.9 if _esw else 1.0)
			if bool(player.get("in_stealth_bush")):
				shoot_rate_mult *= 1.35
			match data.ai:
				"chase":
					desired = _chase_dir(delta, dir, dist, 0.30, 0.24)
				"shoot":
					desired = _keep_distance(delta, dir, dist, 160.0, 85.0)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 1.35) * randf_range(0.8, 1.15) * shoot_rate_mult
						var edmg: int = 2 if (elite and level >= 4) else 1
						var epj: String = str(data.get("proj", "arrow"))
						if level >= 4 and not elite:
							_fire(dir.angle() - 0.12, 185.0, epj, edmg)
							_fire(dir.angle() + 0.12, 185.0, epj, edmg)
						elif elite:
							for si in range(-1, 2):
								_fire(dir.angle() + float(si) * 0.14, 190.0, epj, edmg)
						else:
							_fire(dir.angle(), 185.0, epj, edmg)
						_trigger_mob_attack(0.32, Vector2(1.14, 0.88))
						Fx.anim(get_parent(), global_position + dir * radius, "fx/muzzle.png", 12, 10, 24.0, 0.9, dir.angle(), Color(1.0, 0.85, 0.55) if epj == "arrow" else Color(1.0, 0.55, 0.9), true, 6)
				"tank":
					desired = _chase_dir(delta, dir, dist, 0.18, 0.18)
				"caster":
					desired = _keep_distance(delta, dir, dist, 150.0, 95.0)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 2.2) * randf_range(0.8, 1.15) * shoot_rate_mult
						_fire_ring(10, randf() * TAU, 115.0, "orb_poison")
						_trigger_mob_attack(0.34, Vector2(0.90, 1.16))
						Fx.burst(get_parent(), global_position, Color(0.75, 0.4, 1.0), 22.0, 0.28)
					_summon_t -= delta
					if _summon_t <= 0.0 and room != null:
						_summon_t = randf_range(5.0, 7.0)
						var folk: Array = EnemyData.chapter(level).folk
						var p := global_position + Vector2.from_angle(randf() * TAU) * 26.0
						_trigger_mob_attack(0.40, Vector2(0.88, 1.18))
						Fx.particles(get_parent(), p, Color(0.8, 0.4, 1.0), 16, 90.0, 0.5)
						room.spawn_enemy(folk.pick_random(), p)
				"ring":
					desired = _chase_dir(delta, dir, dist, 0.42, 0.25)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 2.2) * randf_range(0.8, 1.15) * shoot_rate_mult
						_fire_ring(10, randf() * TAU, 120.0, "orb_pink")
						_trigger_mob_attack(0.34, Vector2(0.90, 1.16))
						Fx.burst(get_parent(), global_position, Color(1.0, 0.5, 0.78), 22.0, 0.26)
				"charge":
					desired = _charge_ai(delta, dir, dist, 4.2)
				"rifle":
					desired = _keep_distance(delta, dir, dist, 175.0, 90.0)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 1.2) * randf_range(0.8, 1.15) * shoot_rate_mult
						_fire(dir.angle() + randf_range(-0.04, 0.04), 245.0, "bullet", 2 if elite else 1)
						_trigger_mob_attack(0.24, Vector2(1.15, 0.87))
						Fx.anim(get_parent(), global_position + dir * radius, "fx/muzzle.png", 12, 10, 24.0, 1.0, dir.angle(), Color.WHITE, true, 6)
				"mg":
					desired = _keep_distance(delta, dir, dist, 175.0, 110.0) * 0.6
					_shoot_t -= delta
					if _shoot_t <= 0.0 and _burst_left == 0:
						_shoot_t = data.get("shoot_cd", 2.1) * randf_range(0.8, 1.15) * shoot_rate_mult
						_start_burst(7, 8.0)
				"mortar":
					desired = _keep_distance(delta, dir, dist, 190.0, 120.0)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 2.5) * randf_range(0.8, 1.15) * shoot_rate_mult
						_mortar(player.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.9)
				"tank_elite":
					desired = _chase_dir(delta, dir, dist, 0.16, 0.16)
					_shoot_t -= delta
					if _shoot_t <= 0.0:
						_shoot_t = data.get("shoot_cd", 2.0) * randf_range(0.8, 1.15) * shoot_rate_mult
						if randf() < 0.5:
							_cannon(dir, 2)
						else:
							_start_burst(9, 14.0)
				"slam":
					desired = _slam_ai(delta, dir, dist)
				"kamikaze":
					desired = (dir + _wander_vec(delta) * 0.25).normalized() * speed * (1.6 if dist < 60.0 else 1.0)
					if dist < radius + 12.0:
						if dist < radius + 12.0 and player.global_position.distance_to(global_position) < 26.0:
							player.take_damage(1)
						Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 20.0, 0.7, 0.0, Color(0.6, 0.85, 1.0))
						Sfx.play("explode")
						die(false)
						return
				"ngu":
					desired = _ngu(delta, dir)
				"boss":
					desired = _boss(delta, dir, dist)
		_contact_t -= delta
		if not _submerged and _leap_state != "air":
			if Net.is_online():
				var lp: Node = Global.local_player()
				if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")) and not bool(lp.get("downed")) and _touches_player((lp as Node2D).global_position) and _contact_t <= 0.0:
					lp.take_damage((2 + int(power() / 5.0)) if is_boss() else (2 if elite else 1))
					_contact_t = 0.8
					if is_boss():
						_trigger_action_anim("melee_sweep", 0.35)
						Fx.slash(get_parent(), hurtbox_center() + Vector2(_face * radius * 0.6, 0.0), Vector2(_face, 0.0), maxf(radius * 1.9, 30.0), deg_to_rad(120.0), _boss_color(), "swing")
					else:
						_trigger_mob_attack(0.32, Vector2(1.18, 0.85))
						Fx.slash(get_parent(), hurtbox_center() + Vector2(_face * radius * 0.7, 0.0), Vector2(_face, 0.0), maxf(radius * 2.0, 18.0), deg_to_rad(110.0), Color(1.0, 0.75, 0.5), "swing")
			elif _touches_player(player.global_position) and _contact_t <= 0.0:
				player.take_damage((2 + int(power() / 5.0)) if is_boss() else (2 if elite else 1))
				_contact_t = 0.8
				if is_boss():
					_trigger_action_anim("melee_sweep", 0.35)
					Fx.slash(get_parent(), hurtbox_center() + Vector2(_face * radius * 0.6, 0.0), Vector2(_face, 0.0), maxf(radius * 1.9, 30.0), deg_to_rad(120.0), _boss_color(), "swing")
				else:
					_trigger_mob_attack(0.32, Vector2(1.18, 0.85))
					Fx.slash(get_parent(), hurtbox_center() + Vector2(_face * radius * 0.7, 0.0), Vector2(_face, 0.0), maxf(radius * 2.0, 18.0), deg_to_rad(110.0), Color(1.0, 0.75, 0.5), "swing")

	_update_burst(delta)
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	var is_dashing: bool = (_charge_state == "dash" or _special == "ong_dong")
	if _stun_t <= 0.0 and not is_dashing and not _submerged and _leap_state != "air":
		desired += _separation_vec()
		desired = _avoid_obstacles(desired, delta)
	if _hazard_slow_t > 0.0:
		desired *= _hazard_slow_mult
	var accel: float = 1200.0 if is_dashing else (360.0 if (is_boss() or data.ai in ["tank", "tank_elite"]) else 540.0)
	velocity = velocity.move_toward(desired + _knock, accel * delta)
	if _leap_state != "air":
		move_and_slide()
	_update_anim(delta)


func _build_anims(n: int) -> Dictionary:
	var anims := {"walk": [[0, 1, 2, 3], 9.0 if n == 8 else 8.0, true]}
	if n >= 48:
		anims["idle"] = [[0, 1, 2, 3, 4, 5], 6.5, true]
		anims["walk"] = [[6, 7, 8, 9, 10, 11, 12, 13], 13.0, true]
		anims["windup"] = [[14, 15, 16, 17, 18, 19], 13.0, false]
		anims["melee_sweep"] = [[20, 21, 22, 23, 24, 25], 16.0, false]
		anims["attack"] = [[20, 21, 22, 23, 24, 25], 16.0, false]
		anims["ranged_shot"] = [[26, 27, 28, 29, 30, 31], 15.0, false]
		anims["cast_summon"] = [[32, 33, 34, 35], 11.0, false]
		anims["dash"] = [[36, 37, 38, 39], 16.0, true]
		anims["leap"] = [[40, 41, 42, 43], 12.0, false]
		anims["rage"] = [[44, 45], 9.0, true]
		anims["special"] = [[46, 47], 9.0, true]
		return anims
	if n >= 36:
		anims["idle"] = [[0, 1, 2, 3], 6.0, true]
		anims["walk"] = [[4, 5, 6, 7, 8, 9, 10, 11], 13.0, true]
		anims["windup"] = [[12, 13, 14, 15], 12.0, false]
		anims["melee_sweep"] = [[16, 17, 18, 19], 15.0, false]
		anims["attack"] = [[16, 17, 18, 19], 15.0, false]
		anims["ranged_shot"] = [[20, 21, 22, 23], 14.0, false]
		anims["cast_summon"] = [[24, 25, 26, 27], 11.0, false]
		anims["dash"] = [[28, 29], 14.0, true]
		anims["leap"] = [[30, 31, 32], 10.0, false]
		anims["rage"] = [[33, 15], 8.0, true]
		anims["special"] = [[34, 35], 8.0, true]
		return anims
	if n >= 24:
		anims["idle"] = [[20, 21, 22, 23], 6.0, true]
		anims["walk"] = [[0, 1, 2, 3, 4, 5, 6, 7], 13.0, true]
		anims["windup"] = [[8, 16, 9, 17], 13.0, false]
		anims["attack"] = [[10, 11, 18, 12, 19, 13], 16.0, false]
		anims["hurt"] = [[14, 15], 10.0, false]
		return anims
	if n == 16:
		anims["walk"] = [[0, 1, 2, 3, 4, 5, 6, 7], 13.0, true]
		anims["windup"] = [[8, 9], 10.0, false]
		if str(data.get("id", "")) == "ngu_tinh":
			anims["attack"] = [[10, 11, 12], 14.0, false]
			anims["rage"] = [[13], 1.0, false]
		else:
			anims["attack"] = [[10, 11, 12, 13], 15.0, false]
		anims["hurt"] = [[14, 15], 10.0, false]
		return anims
	if n == 5:
		anims["attack"] = [[4], 1.0, false]
	elif n == 8:
		anims["windup"] = [[4], 1.0, false]
		anims["attack"] = [[4, 5, 6], 11.0, false]
		anims["hurt"] = [[7], 1.0, false]
		if str(data.get("id", "")) == "ngu_tinh":
			anims["rage"] = [[6], 1.0, false]
	elif n >= 6:
		anims["attack"] = [[4], 1.0, false]
		anims["rage"] = [[5], 1.0, false]
	if n == 7:
		anims["special"] = [[6], 1.0, false]
	return anims


func _resolve_anim(anim: String) -> String:
	if spr == null or spr.sprite_frames == null:
		return anim
	if spr.sprite_frames.has_animation(anim):
		return anim
	if anim == "idle" and spr.sprite_frames.has_animation("walk"):
		return "walk"
	if anim in ["melee_sweep", "ranged_shot", "cast_summon"] and spr.sprite_frames.has_animation("attack"):
		return "attack"
	if spr.sprite_frames.has_animation("walk"):
		return "walk"
	return anim


func _trigger_action_anim(anim: String, dur: float) -> void:
	_action_anim = anim
	_action_anim_t = dur
	if anim in ["melee_sweep", "ranged_shot", "cast_summon", "attack"]:
		_attack_anim_t = maxf(_attack_anim_t, dur)
	if spr != null and spr.sprite_frames != null:
		var resolved := _resolve_anim(anim)
		if spr.sprite_frames.has_animation(resolved):
			if spr.animation == resolved:
				spr.frame = 0
			spr.play(resolved)


func _trigger_mob_attack(dur: float, squash_mult: Vector2 = Vector2(1.16, 0.86)) -> void:
	_attack_anim_t = maxf(_attack_anim_t, dur)
	_anim_scale = Vector2(_base_scale.x * squash_mult.x, _base_scale.y * squash_mult.y)
	if spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation("attack"):
		if spr.animation == "attack":
			spr.frame = 0
		spr.play("attack")


func _apply_lively_motion(delta: float, cur_spd: float) -> void:
	if spr == null:
		return
	_anim_scale = _anim_scale.lerp(_base_scale, clampf(delta * 11.0, 0.0, 1.0))
	var final_scale: Vector2 = _anim_scale
	if is_boss():
		if _morph_t <= 0.0 and _stun_t <= 0.0 and not _submerged:
			var bob_y: float = 0.0
			if _leap_state == "air":
				spr.position.y = _base_spr_y - _leap_z
				if _shadow != null:
					_shadow.scale = Vector2(radius / 7.0, radius / 7.0) * clampf(1.0 - _leap_z / 75.0, 0.45, 1.0)
			else:
				if _shadow != null:
					_shadow.scale = Vector2(radius / 7.0, radius / 7.0)
				var spd_r: float = clampf(cur_spd / maxf(speed, 1.0), 0.0, 2.4)
				if spd_r > 0.15 and _charge_state != "windup":
					_step_t += delta * (7.5 + 3.5 * spd_r)
					bob_y = -absf(sin(_step_t)) * (2.6 if _charge_state != "dash" else 1.0)
					var w_sq: float = sin(_step_t * 2.0) * 0.045
					final_scale = Vector2(_anim_scale.x * (1.0 - w_sq), _anim_scale.y * (1.0 + w_sq))
					_step_dust_t -= delta
					if spd_r > 0.25 and _step_dust_t <= 0.0 and _charge_state != "dash":
						_step_dust_t = 0.28
						Fx.anim(get_parent(), global_position + Vector2(randf_range(-6.0, 6.0), radius * 0.85), "fx/dust.png", 10, 10, 14.0, 1.15)
						if transformed or enraged:
							Fx.particles(get_parent(), global_position + Vector2(0.0, radius * 0.7), _boss_color(), 2, 28.0, 0.3, -18.0, 1.6)
				else:
					var br: float = sin(_boss_t * 4.2) * 0.032
					final_scale = Vector2(_anim_scale.x * (1.0 - br * 0.65), _anim_scale.y * (1.0 + br))
				spr.position.y = _base_spr_y + bob_y
	elif _morph_t <= 0.0:
		var phase_off: float = float(get_instance_id() % 17) * 0.37
		if cur_spd > 8.0 and _stun_t <= 0.0 and _hurt_anim_t <= 0.0 and _charge_state != "windup":
			_step_t += delta * (8.5 + 3.5 * clampf(cur_spd / maxf(speed, 1.0), 0.0, 2.0))
			spr.position.y = _base_spr_y - absf(sin(_step_t)) * 2.1
			var m_sq: float = sin(_step_t * 2.0) * 0.06
			final_scale = Vector2(_anim_scale.x * (1.0 - m_sq), _anim_scale.y * (1.0 + m_sq))
			_step_dust_t -= delta
			if cur_spd > 28.0 and _step_dust_t <= 0.0:
				_step_dust_t = 0.20 if _charge_state == "dash" else 0.44
				Fx.anim(get_parent(), global_position + Vector2(randf_range(-4.0, 4.0), radius * 0.8), "fx/dust.png", 10, 10, 14.0, 0.9)
		else:
			spr.position.y = _base_spr_y
			var m_br: float = sin(_boss_t * 4.8 + phase_off) * 0.045
			final_scale = Vector2(_anim_scale.x * (1.0 - m_br * 0.6), _anim_scale.y * (1.0 + m_br))
	spr.scale = final_scale

	var target_tilt: float = 0.0
	if _charge_state == "dash" and is_boss() and _charge_dir.length_squared() > 0.01:
		target_tilt = clampf(_charge_dir.x * 0.14, -0.16, 0.16)
	elif _stun_t <= 0.0 and _morph_t <= 0.0 and not _submerged and cur_spd > 8.0:
		var vx: float = _charge_dir.x * cur_spd if is_replica and _charge_dir.length_squared() > 0.01 else velocity.x
		target_tilt = clampf(vx / maxf(speed, 45.0) * 0.065, -0.08, 0.08)
	spr.rotation = lerpf(spr.rotation, target_tilt, clampf(delta * 10.0, 0.0, 1.0))


func _update_anim(delta: float = 0.016) -> void:
	spr.flip_h = _face < 0.0
	_action_anim_t = maxf(_action_anim_t - delta, 0.0)
	if _action_anim_t <= 0.0:
		_action_anim = ""
	if is_boss():
		var target_anim: String = ""
		var spd_scale: float = 1.0
		if _morph_t > 0.0:
			target_anim = "rage"
		elif _special != "" and _special_t > 0.0:
			target_anim = "special"
		elif _charge_state == "windup" or _leap_state == "windup":
			target_anim = "windup"
		elif _leap_state in ["air", "land"]:
			target_anim = "leap"
		elif _charge_state in ["dash", "under"]:
			target_anim = "dash"
		elif _action_anim != "" and _action_anim_t > 0.0:
			target_anim = _action_anim
		elif velocity.length_squared() > 16.0:
			target_anim = "walk"
			spd_scale = clampf(velocity.length() / maxf(speed, 1.0), 0.45, 2.0)
		else:
			target_anim = "idle"
		var resolved := _resolve_anim(target_anim)
		if spr.sprite_frames.has_animation(resolved) and spr.animation != resolved:
			spr.play(resolved)
		spr.speed_scale = spd_scale
	else:
		if _hurt_anim_t > 0.0 and spr.sprite_frames.has_animation("hurt"):
			if spr.animation != "hurt":
				spr.play("hurt")
			spr.speed_scale = 1.0
		elif _charge_state == "windup" and spr.sprite_frames.has_animation("windup"):
			if spr.animation != "windup":
				spr.play("windup")
			spr.speed_scale = 1.0
		elif _attack_anim_t > 0.0 and spr.sprite_frames.has_animation("attack"):
			if spr.animation != "attack":
				spr.play("attack")
			spr.speed_scale = 1.0
		elif velocity.length() < 8.0 and spr.sprite_frames.has_animation("idle"):
			if spr.animation != "idle":
				spr.play("idle")
			spr.speed_scale = 1.0
		else:
			if spr.animation != "walk":
				spr.play("walk")
			spr.speed_scale = clampf(velocity.length() / maxf(speed, 1.0), 0.35, 2.0)
	_apply_lively_motion(delta, velocity.length())


func _chase_dir(delta: float, dir: Vector2, dist: float, wander_w: float, flank_w: float) -> Vector2:
	var v: Vector2 = dir + _wander_vec(delta) * wander_w
	if dist > 60.0:
		v += dir.rotated(PI * 0.5 * _flank_sign) * flank_w
	return v.normalized() * speed


func _keep_distance(delta: float, dir: Vector2, dist: float, far: float, near: float) -> Vector2:
	_strafe_t -= delta
	if _strafe_t <= 0.0 or get_slide_collision_count() > 0:
		_strafe_dir = -_strafe_dir
		_strafe_t = randf_range(1.6, 2.8)
	if dist > far:
		return (dir + dir.rotated(PI * 0.5 * _strafe_dir) * 0.25).normalized() * speed
	elif dist < near:
		return (-dir + dir.rotated(PI * 0.5 * _strafe_dir) * 0.35).normalized() * speed
	return dir.rotated(PI * 0.5 * _strafe_dir) * speed * 0.72


func _boss_strafe(delta: float, dir: Vector2, dist: float, spd_mult: float = 0.55) -> Vector2:
	_strafe_t -= delta
	if _strafe_t <= 0.0 or get_slide_collision_count() > 0:
		_strafe_dir = -_strafe_dir
		_strafe_t = randf_range(1.8, 3.0)
	var tangent: Vector2 = dir.rotated(PI * 0.5 * _strafe_dir) * 0.75
	var radial: Vector2 = dir * 0.5 if dist > 135.0 else (-dir * 0.45 if dist < 68.0 else Vector2.ZERO)
	return (tangent + radial).normalized() * speed * spd_mult


func _separation_vec() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var push := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var diff: Vector2 = global_position - (e as Node2D).global_position
		var d_sq: float = diff.length_squared()
		var min_d: float = radius + float(e.get("radius")) + 6.0
		if d_sq > 0.01 and d_sq < min_d * min_d:
			var d: float = sqrt(d_sq)
			push += (diff / d) * (1.0 - d / min_d)
	var lim: float = speed * 0.55
	var res: Vector2 = push * speed * 0.5
	if res.length() > lim:
		res = res.normalized() * lim
	return res


func _avoid_obstacles(desired: Vector2, delta: float) -> Vector2:
	_steer_t = maxf(0.0, _steer_t - delta)
	if desired.length_squared() < 64.0 or not is_inside_tree():
		return desired
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return desired
	var spd: float = desired.length()
	var dir: Vector2 = desired / spd
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * 24.0, 1)
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty() and get_slide_collision_count() == 0:
		return desired
	if _steer_t <= 0.0 or absf(_steer_sign) < 0.5:
		var left_dir: Vector2 = dir.rotated(-0.96)
		var right_dir: Vector2 = dir.rotated(0.96)
		var hl: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + left_dir * 28.0, 1))
		var hr: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + right_dir * 28.0, 1))
		if hl.is_empty() and not hr.is_empty():
			_steer_sign = -1.0
		elif hr.is_empty() and not hl.is_empty():
			_steer_sign = 1.0
		else:
			var dl: float = global_position.distance_to(hl["position"]) if not hl.is_empty() else 28.0
			var dr: float = global_position.distance_to(hr["position"]) if not hr.is_empty() else 28.0
			_steer_sign = -1.0 if dl >= dr else 1.0
		_steer_t = 0.55
	var steered: Vector2 = dir.rotated(_steer_sign * 0.96)
	return (dir * 0.2 + steered * 0.8).normalized() * spd


func _wander_vec(delta: float) -> Vector2:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(0.6, 1.4)
		_wander = Vector2.from_angle(randf() * TAU)
	return _wander


func _charge_ai(delta: float, dir: Vector2, dist: float, mult: float) -> Vector2:
	var boss := is_boss()
	match _charge_state:
		"windup":
			_charge_t -= delta
			_flash = 0.35 + 0.35 * sin(_charge_t * 40.0)
			if boss:
				if not _windup_glint_done:
					_windup_glint_done = true
					Fx.burst(get_parent(), hurtbox_center() + _charge_dir * 8.0, Color(1.0, 0.92, 0.45), 22.0, 0.28)
					Sfx.play("hit_metal")
				if _charge_t > 0.16 and dir.length_squared() > 0.01:
					_charge_dir = _charge_dir.lerp(dir, clampf(delta * 10.0, 0.0, 1.0)).normalized()
				_anim_scale = _anim_scale.lerp(Vector2(_base_scale.x * 1.16, _base_scale.y * 0.84), clampf(delta * 14.0, 0.0, 1.0))
				if int(_boss_t * 30.0) % 2 == 0:
					Fx.particles(get_parent(), global_position + _charge_dir.rotated(randf_range(-1.2, 1.2)) * 22.0, _boss_color(), 2, 42.0, 0.25, 0.0, 1.6, 25.0, -_charge_dir)
			else:
				_charge_dir = dir
			if _charge_t <= 0.0:
				_charge_state = "dash"
				_charge_t = 0.46 if boss else 0.5
				_dash_hit_wall = false
				if boss:
					_trigger_action_anim("dash", 0.50)
					_anim_scale = Vector2(_base_scale.x * 1.24, _base_scale.y * 0.80)
					Fx.burst(get_parent(), global_position, _boss_color(), 42.0, 0.30)
					Fx.particles(get_parent(), global_position + Vector2(0.0, radius * 0.7), Color(0.9, 0.85, 0.75), 10, 95.0, 0.35, 0.0, 2.2, 65.0, -_charge_dir)
					Fx.shake(get_tree(), 2.5)
				else:
					_trigger_mob_attack(0.45, Vector2(1.20, 0.82))
					Fx.particles(get_parent(), global_position + Vector2(0.0, radius * 0.6), Color(0.9, 0.85, 0.75), 6, 70.0, 0.3, 0.0, 1.8, 55.0, -_charge_dir)
			if boss and _charge_t > 0.30:
				return -_charge_dir * 12.0
			return Vector2.ZERO
		"dash":
			_charge_t -= delta
			if boss:
				_attack_anim_t = maxf(_attack_anim_t, 0.12)
				_anim_scale = _anim_scale.lerp(Vector2(_base_scale.x * 1.22, _base_scale.y * 0.82), clampf(delta * 14.0, 0.0, 1.0))
				if int(_boss_t * 45.0) % 2 == 0:
					Fx.afterimage(get_parent(), spr, global_position, Color(_boss_color(), 0.65), 0.30)
				if int(_boss_t * 40.0) % 2 == 0:
					Fx.particles(get_parent(), global_position + Vector2(0.0, radius * 0.4), _boss_color(), 2, 70.0, 0.32, 0.0, 2.0, 35.0, -_charge_dir)
				if not _dash_hit_wall and get_slide_collision_count() > 0:
					_dash_hit_wall = true
					_charge_t = 0.0
					Fx.shake(get_tree(), 5.5)
					Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.5), 52.0, 0.35)
					Fx.particles(get_parent(), global_position, Color(0.85, 0.78, 0.68), 16, 130.0, 0.45, 160.0, 2.4)
			elif int(_boss_t * 30.0) % 3 == 0:
				Fx.afterimage(get_parent(), spr, global_position, Color(_boss_color(), 0.55), 0.28)
			if int(_charge_t * 30.0) % 2 == 0:
				Fx.anim(get_parent(), global_position + Vector2(0, radius), "fx/dust.png", 10, 10, 14.0, 1.25 if boss else 1.2)
			if _charge_t <= 0.0:
				_charge_state = "rest"
				_charge_t = 0.85 if boss else 1.2
				if boss:
					_trigger_action_anim("melee_sweep", 0.30)
					_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.85)
					Fx.burst(get_parent(), global_position + _charge_dir * radius, _boss_color(), 48.0, 0.32)
					Fx.slash(get_parent(), hurtbox_center() + _charge_dir * (radius * 0.7), _charge_dir, maxf(radius * 2.2, 34.0), deg_to_rad(130.0), _boss_color(), "swing")
					Fx.shake(get_tree(), 3.6)
					if enraged or transformed:
						for fi in 5:
							_fire(_charge_dir.angle() + deg_to_rad(lerpf(-36.0, 36.0, float(fi) / 4.0)), 145.0, "orb_pink")
			var dash_spd: float = clampf(speed * mult, 240.0, 305.0) if boss else speed * mult
			return _charge_dir * dash_spd
		"rest":
			_charge_t -= delta
			if _charge_t <= 0.0:
				_charge_state = ""
			return dir * speed * 0.4
	if dist < 150.0:
		_charge_state = "windup"
		_charge_t = 0.58 if boss else 0.45
		_charge_dir = dir if dir.length_squared() > 0.01 else Vector2.RIGHT
		_windup_glint_done = false
		_dash_hit_wall = false
	return (dir + _wander_vec(delta) * 0.3).normalized() * speed


func _leap_slam_ai(delta: float, dir: Vector2, _dist: float) -> Vector2:
	match _leap_state:
		"":
			_leap_state = "windup"
			_leap_t = 0.45
			_leap_z = 0.0
			_leap_start = global_position
			var tgt: Vector2 = player.global_position if (player != null and is_instance_valid(player)) else (global_position + dir * 70.0)
			if room != null:
				var rr: Rect2 = room.rect.grow(-28.0)
				tgt = Vector2(clampf(tgt.x, rr.position.x, rr.end.x), clampf(tgt.y, rr.position.y, rr.end.y))
			_leap_target = tgt
			_anim_scale = Vector2(_base_scale.x * 1.22, _base_scale.y * 0.76)
			Fx.burst(get_parent(), global_position, _boss_color(), 30.0, 0.28)
			return Vector2.ZERO
		"windup":
			_leap_t -= delta
			_flash = 0.25 + 0.25 * sin(_leap_t * 36.0)
			if _leap_t > 0.20 and player != null and is_instance_valid(player):
				var tgt2: Vector2 = _leap_target.lerp(player.global_position, clampf(delta * 8.0, 0.0, 1.0))
				if room != null:
					var rr2: Rect2 = room.rect.grow(-28.0)
					tgt2 = Vector2(clampf(tgt2.x, rr2.position.x, rr2.end.x), clampf(tgt2.y, rr2.position.y, rr2.end.y))
				_leap_target = tgt2
			_anim_scale = _anim_scale.lerp(Vector2(_base_scale.x * 1.22, _base_scale.y * 0.76), clampf(delta * 14.0, 0.0, 1.0))
			if _leap_t <= 0.0:
				_leap_state = "air"
				_leap_t = 0.48
				_leap_start = global_position
				_trigger_action_anim("leap", 0.55)
				_anim_scale = Vector2(_base_scale.x * 0.82, _base_scale.y * 1.26)
				Fx.anim(get_parent(), global_position + Vector2(0.0, radius * 0.8), "fx/dust.png", 10, 10, 14.0, 1.6)
				Fx.burst(get_parent(), global_position, Color(0.9, 0.85, 0.7), 34.0, 0.25)
			return Vector2.ZERO
		"air":
			_leap_t -= delta
			var p: float = clampf(1.0 - _leap_t / 0.48, 0.0, 1.0)
			_leap_z = sin(p * PI) * 44.0
			global_position = _leap_start.lerp(_leap_target, p)
			if int(_boss_t * 36.0) % 3 == 0:
				Fx.afterimage(get_parent(), spr, global_position + Vector2(0.0, -_leap_z), Color(_boss_color(), 0.55), 0.24)
			if _leap_t <= 0.0:
				_leap_state = "land"
				_leap_t = 0.65
				_leap_z = 0.0
				spr.position.y = _base_spr_y
				if _shadow != null:
					_shadow.scale = Vector2(radius / 7.0, radius / 7.0)
				_anim_scale = Vector2(_base_scale.x * 1.32, _base_scale.y * 0.72)
				Fx.shake(get_tree(), 5.8)
				Fx.burst(get_parent(), global_position, _boss_color(), 72.0, 0.42)
				Fx.burst(get_parent(), global_position, Color(1.0, 0.92, 0.65), 42.0, 0.28)
				Fx.particles(get_parent(), global_position + Vector2(0.0, radius * 0.6), _boss_color(), 20, 145.0, 0.55, 160.0, 2.5)
				Sfx.play("explode")
				_fire_ring(16 if (enraged or transformed) else 12, randf() * TAU, 115.0, "orb_pink")
				if player != null and is_instance_valid(player) and not player.dead and player.global_position.distance_to(global_position) < 48.0:
					player.take_damage(2 + int(power() / 5.0))
			return Vector2.ZERO
		"land":
			_leap_t -= delta
			if _leap_t <= 0.0:
				_leap_state = "done"
			return Vector2.ZERO
	return _boss_strafe(delta, dir, _dist, 0.55)


func _start_burst(n: int, spread_deg: float) -> void:
	_burst_left = n
	_burst_t = 0.0
	_burst_spread = spread_deg
	if is_boss():
		_trigger_action_anim("ranged_shot", 0.60)
		_anim_scale = Vector2(_base_scale.x * 1.12, _base_scale.y * 0.88)
	else:
		_trigger_mob_attack(0.60, Vector2(1.12, 0.88))


func _update_burst(delta: float) -> void:
	if _burst_left <= 0 or player == null or not is_instance_valid(player) or _stun_t > 0.0:
		return
	_burst_t -= delta
	if _burst_t <= 0.0:
		_burst_t = 0.08
		_burst_left -= 1
		var a: float = (player.global_position - global_position).angle() + deg_to_rad(randf_range(-_burst_spread, _burst_spread))
		_fire(a, 255.0, "bullet", 2 if (elite and level >= 5) else 1)
		if _burst_left % 2 == 0:
			Fx.anim(get_parent(), global_position + Vector2.from_angle(a) * radius, "fx/muzzle.png", 12, 10, 24.0, 1.0, a, Color.WHITE, true, 6)


func _mortar(pos: Vector2, delay: float) -> void:
	var m := MortarStrike.new()
	m.position = pos
	m.delay = delay
	get_parent().add_child(m)
	Fx.anim(get_parent(), global_position + Vector2(0, -radius), "fx/poof.png", 28, 28, 18.0, 0.5)
	Fx.particles(get_parent(), global_position + Vector2(0, -radius), Color(1.0, 0.72, 0.35), 6, 55.0, 0.3, -60.0, 1.8)
	if is_boss():
		_trigger_action_anim("ranged_shot", 0.35)
		_anim_scale = Vector2(_base_scale.x * 0.90, _base_scale.y * 1.14)
	else:
		_trigger_mob_attack(0.32, Vector2(0.90, 1.14))
	if Net.is_online() and Net.is_host():
		Net.send_enemy_event("mortar", {"x": pos.x, "y": pos.y, "delay": delay, "root": false, "radius": 0.0}, false)


func _cannon(dir: Vector2, dmg: int) -> void:
	var bpos: Vector2 = global_position + dir * (radius + 4.0)
	var b := Bullet.new()
	b.setup(false, bpos, dir, 160.0, dmg, 3.0, "cannonball")
	b.spawn_origin = global_position
	b.explode_radius = 22.0
	get_parent().add_child(b)
	Fx.anim(get_parent(), bpos, "fx/muzzle.png", 12, 10, 24.0, 1.4, dir.angle(), Color.WHITE, true, 6)
	Fx.particles(get_parent(), bpos, Color(1.0, 0.72, 0.30), 6, 65.0, 0.28, 0.0, 1.8, 35.0, dir)
	if is_boss():
		_trigger_action_anim("ranged_shot", 0.35)
		_anim_scale = Vector2(_base_scale.x * 1.14, _base_scale.y * 0.86)
	else:
		_trigger_mob_attack(0.32, Vector2(1.14, 0.86))
	if Net.is_online() and Net.is_host():
		Net.send_enemy_event("bullet", {
			"x": bpos.x, "y": bpos.y, "dx": dir.x, "dy": dir.y,
			"spd": 160.0, "dmg": dmg, "life": 3.0, "proj": "cannonball",
			"exp": 22.0, "ox": global_position.x, "oy": global_position.y, "muzzle": true,
		}, false)


func _slam_ai(delta: float, dir: Vector2, dist: float) -> Vector2:
	_shoot_t -= delta
	if _charge_state == "windup":
		_charge_t -= delta
		_flash = 0.3 + 0.3 * sin(_charge_t * 40.0)
		if _charge_t <= 0.0:
			_charge_state = ""
			_trigger_mob_attack(0.35, Vector2(1.24, 0.78))
			_fire_ring(14, randf() * TAU, 110.0, "orb_pink")
			Fx.burst(get_parent(), global_position, Color(0.6, 0.9, 0.5), 60.0, 0.4)
			Fx.particles(get_parent(), global_position + Vector2(0, radius), Color(0.6, 0.5, 0.35), 14, 120.0, 0.5, 150.0, 2.0)
			Fx.shake(get_tree(), 3.0)
		return Vector2.ZERO
	if _shoot_t <= 0.0 and dist < 90.0:
		_shoot_t = data.get("shoot_cd", 3.5)
		_charge_state = "windup"
		_charge_t = 0.55
	return (dir + _wander_vec(delta) * 0.3).normalized() * speed


func _fire(angle: float, spd: float, proj := "orb_pink", dmg := 1) -> void:
	var dir := Vector2.from_angle(angle)
	if EnemyData.is_mythic_level(level):
		spd *= 1.12
	if Global != null and bool(Global.get("badass_mode")):
		spd *= 1.15
		if is_boss() or elite:
			dmg += 1
	if Global != null and Global.has_method("has_mutator") and Global.has_mutator("hyper_speed"):
		spd *= 1.2
	if is_boss():
		spd *= 1.0 + 0.035 * minf(power(), 10.0)   # đạn trùm sau bay nhanh hơn
	var bpos: Vector2 = global_position + dir * radius
	var b := Bullet.new()
	b.setup(false, bpos, dir, spd, dmg, 4.0, proj)
	b.spawn_origin = global_position
	if proj == "arrow" or proj == "bullet":
		b.color = Color(1, 0.55, 0.5)
	get_parent().add_child(b)
	if Net.is_online() and Net.is_host():
		Net.send_enemy_event("bullet", {
			"x": bpos.x, "y": bpos.y, "dx": dir.x, "dy": dir.y,
			"spd": spd, "dmg": dmg, "life": 4.0, "proj": proj,
			"exp": 0.0, "ox": global_position.x, "oy": global_position.y, "muzzle": false,
		}, false)


func _fire_ring(n: int, offset: float, spd: float, proj := "orb_pink") -> void:
	for i in n:
		_fire(offset + TAU * i / n, spd, proj)


# ------------------------------------------------------------------ Thủy quái Ngư Tinh

func _ngu(delta: float, dir: Vector2) -> Vector2:
	var rage := hp < max_hp / 2
	_phase_t -= delta
	if _phase_t <= 0.0:
		_phase = (_phase + 1) % 3
		_phase_t = [3.0, 2.5, 1.6][_phase]
		_shoot_t = 0.3
	_shoot_t -= delta
	match _phase:
		0:
			if _shoot_t <= 0.0:
				_shoot_t = 0.6 if rage else 0.85
				_fire_ring(14 if rage else 10, randf() * TAU, 110.0, "orb_water")
				_attack_anim_t = 0.3
			return dir * speed * 0.6
		1:
			if _shoot_t <= 0.0:
				_shoot_t = 0.08
				_spiral += 0.32
				_fire(_spiral, 120.0, "orb_water")
				_fire(_spiral + PI, 120.0, "orb_water")
			return Vector2.ZERO
		2:
			return _charge_ai(delta, dir, 0.0, 5.0)
	return Vector2.ZERO


# ------------------------------------------------------------------ Trùm

func _boss(delta: float, dir: Vector2, dist: float) -> Vector2:
	var rage := hp < max_hp / 2
	# hiện nguyên hình: đứng yên, bất khả xâm phạm, khói tà khí rồi đổi hình
	if _morph_t > 0.0:
		_morph_t -= delta
		_flash = 0.5 + 0.5 * sin(_morph_t * 30.0)
		spr.position.x = sin(_morph_t * 60.0) * 1.5
		if int(_morph_t * 20.0) % 2 == 0:
			Fx.particles(get_parent(), global_position + Vector2(randf_range(-16, 16), randf_range(-24, 4)), Color(0.55, 0.2, 0.7), 3, 50.0, 0.6, -50.0, 2.5)
		if _morph_t <= 0.0:
			_finish_morph()
		return Vector2.ZERO
	if rage and not transformed and data.has("sheet2"):
		_start_morph()
		return Vector2.ZERO
	if rage and not enraged:
		_enrage()
	if enraged and _special_t <= 0.0:
		_rage_skill(delta)
	# chiêu đặc biệt mỗi trùm (1 lần)
	if not _special_used:
		var sp: String = data.get("special", "")
		var low := hp < max_hp * 0.4
		if (low and sp in ["tran_khien", "tron_chay", "mua_ten", "sa_lay", "boc_chay", "phao_kich", "ham_chi_huy", "cuu_vi", "rung_gia", "song_than"]) or (sp == "thuy_quai" and rage) or (sp == "ong_dong" and hp < max_hp * 0.35) or (sp == "bo_chay" and hp < max_hp * 0.3):
			_start_special(sp)
	if _special != "" and _special_t <= 0.0:
		if _special == "tron_chay":
			spr.modulate.a = 1.0
		_special = ""
	if _special_t > 0.0:
		_special_t -= delta
		match _special:
			"ong_dong":
				# lăn lông lốc khắp phòng, nảy vào tường
				if get_slide_collision_count() > 0:
					_charge_dir = _charge_dir.bounce(get_slide_collision(0).get_normal())
				if int(_boss_t * 30.0) % 3 == 0:
					Fx.afterimage(get_parent(), spr, global_position, Color(_boss_color(), 0.55), 0.28)
				return _charge_dir * speed * 3.0
			"bo_chay":
				if int(_boss_t * 20.0) % 4 == 0:
					Fx.anim(get_parent(), global_position + Vector2(0, radius * 0.8), "fx/dust.png", 10, 10, 14.0, 1.1)
				return -dir * speed * 2.4
			"tron_chay":
				if int(_boss_t * 20.0) % 4 == 0:
					Fx.anim(get_parent(), global_position + Vector2(0, radius * 0.8), "fx/dust.png", 10, 10, 14.0, 1.0)
				return (-dir + _wander_vec(delta)).normalized() * speed * 1.8
			"mua_ten":
				_shoot_t -= delta
				if _shoot_t <= 0.0 and room != null:
					_shoot_t = 0.07
					var r: Rect2 = room.rect.grow(-20.0)
					var mpos := Vector2(randf_range(r.position.x, r.end.x), r.position.y)
					var b := Bullet.new()
					b.setup(false, mpos, Vector2.DOWN, 170.0, 1, 2.5, "arrow")
					b.color = Color(1, 0.55, 0.5)
					get_parent().add_child(b)
					if Net.is_online() and Net.is_host():
						Net.send_enemy_event("bullet", {
							"x": mpos.x, "y": mpos.y, "dx": 0.0, "dy": 1.0,
							"spd": 170.0, "dmg": 1, "life": 2.5, "proj": "arrow",
							"exp": 0.0, "ox": mpos.x, "oy": mpos.y, "muzzle": false,
						}, false)
				return Vector2.ZERO
			"boc_chay":
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = 0.25
					hp -= maxi(1, max_hp / 120)
					_fire(randf() * TAU, 120.0, "orb_pink")
					Fx.particles(get_parent(), global_position + Vector2(randf_range(-20, 20), -10), Color(1, 0.6, 0.2), 4, 40.0, 0.5, -80.0, 2.0)
					if hp <= 0:
						die()
						return Vector2.ZERO
				return Vector2.ZERO
			"cuu_vi":   # chín đuôi xoay, lửa hồ ly bắn tứ phía
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = 0.11
					_spiral += 0.45
					for k in 3:
						_fire(_spiral + TAU * k / 3.0, 115.0, "fireball")
				return Vector2.ZERO
			"rung_gia":
				return Vector2.ZERO
			"song_than":   # sóng thần: ba bức tường nước tràn qua phòng
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = 1.0
					_tidal_wall()
				return Vector2.ZERO
			"phao_kich":
				_shoot_t -= delta
				if _shoot_t <= 0.0 and room != null:
					_shoot_t = 0.3
					var r2: Rect2 = room.rect.grow(-24.0)
					_mortar(Vector2(randf_range(r2.position.x, r2.end.x), randf_range(r2.position.y, r2.end.y)), 1.1)
				return Vector2.ZERO
			"ham_chi_huy":
				_shoot_t -= delta
				if _shoot_t <= 0.0 and _burst_left == 0:
					_shoot_t = 0.9
					_start_burst(7, 12.0)
				return Vector2.ZERO
		return Vector2.ZERO

	var patterns: Array = data.patterns
	_phase_t -= delta
	if _phase_t <= 0.0:
		_phase = (_phase + 1) % patterns.size()
		_phase_t = 3.0
		_shoot_t = 0.4
		_volleys = 0
		_charge_state = ""
		_reset_motion_fx()
	_shoot_t -= delta
	var cd_mult := 0.65 if rage else 0.9
	if bool(data.get("mythic", false)) or EnemyData.is_mythic_level(level):
		cd_mult *= 0.85
	# trùm càng về sau ra chiêu càng dồn dập (tối đa nhanh hơn ~45%)
	cd_mult /= 1.0 + 0.07 * minf(power(), 12.0)
	if _slowed:
		cd_mult *= 1.3
	match patterns[_phase]:
		"broadside":   # loạt đại bác mạn tàu
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.8 * cd_mult
				_volleys += 1
				_trigger_action_anim("ranged_shot", 0.42)
				Fx.burst(get_parent(), global_position, _boss_color(), 34.0, 0.35)
				for i in 5:
					var bdir := Vector2.from_angle(dir.angle() + deg_to_rad(lerpf(-40, 40, i / 4.0)))
					_cannon(bdir, 1)
			return _boss_strafe(delta, dir, dist, 0.35)
		"burst":
			if _shoot_t <= 0.0 and _volleys < 3 and _burst_left == 0:
				_shoot_t = 0.7 * cd_mult
				_volleys += 1
				_start_burst(7, 10.0)
			return _boss_strafe(delta, dir, dist, 0.5)
		"mortar":
			if _shoot_t <= 0.0 and _volleys < 5:
				_shoot_t = 0.35 * cd_mult
				_volleys += 1
				_mortar(player.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)), 1.0)
			return -dir * speed * 0.45 if dist < 85.0 else _boss_strafe(delta, dir, dist, 0.35)
		"sweep":   # quét nửa vòng đạn về phía người chơi
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.6 * cd_mult
				_volleys += 1
				_trigger_action_anim("melee_sweep", 0.36)
				_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.86)
				Fx.slash(get_parent(), hurtbox_center() + dir * (radius * 0.5), dir, maxf(radius * 2.4, 38.0), deg_to_rad(140.0), _boss_color(), "swing")
				Fx.burst(get_parent(), global_position, _boss_color(), 30.0, 0.3)
				for i in 9:
					_fire(dir.angle() + deg_to_rad(lerpf(-55, 55, i / 8.0)), 130.0)
			return _boss_strafe(delta, dir, dist, 0.55)
		"charge":
			return _charge_ai(delta, dir, 0.0, 5.5)
		"leap_slam":
			return _leap_slam_ai(delta, dir, dist)
		"ring":
			if _shoot_t <= 0.0:
				_shoot_t = 0.8 * cd_mult
				_trigger_action_anim("cast_summon", 0.36)
				_anim_scale = Vector2(_base_scale.x * 0.88, _base_scale.y * 1.18)
				Fx.burst(get_parent(), global_position, _boss_color(), 38.0, 0.35)
				_fire_ring(16 if rage else 12, randf() * TAU, 105.0)
			return _boss_strafe(delta, dir, dist, 0.6)
		"summon":
			if _shoot_t <= 0.0 and _volleys == 0 and room != null:
				_volleys = 1
				_trigger_action_anim("cast_summon", 0.50)
				_anim_scale = Vector2(_base_scale.x * 0.86, _base_scale.y * 1.20)
				Fx.burst(get_parent(), global_position, _boss_color(), 46.0, 0.45)
				Fx.particles(get_parent(), global_position, _boss_color(), 14, 70.0, 0.5, -40.0, 2.0)
				for i in (3 if rage else 2) + int(power() / 4.0):
					var p := global_position + Vector2.from_angle(randf() * TAU) * 40.0
					room.spawn_enemy(data.summon, p)
			return Vector2.ZERO
		"spiral":
			_spiral_fx_t -= delta
			if _shoot_t <= 0.0:
				_shoot_t = 0.07 * cd_mult
				_spiral += 0.3
				_trigger_action_anim("cast_summon", 0.25)
				if _spiral_fx_t <= 0.0:
					_spiral_fx_t = 0.35
					Fx.particles(get_parent(), hurtbox_center(), _boss_color(), 4, 48.0, 0.35, -20.0, 1.8)
				_fire(_spiral, 120.0, "orb_water")
				_fire(_spiral + PI, 120.0, "orb_water")
				if rage:
					_fire(_spiral + PI / 2.0, 120.0, "orb_water")
			return Vector2.ZERO
		"volley":  # 3 loạt tên nhắm thẳng
			if _shoot_t <= 0.0 and _volleys < 4:
				_shoot_t = 0.45 * cd_mult
				_volleys += 1
				_trigger_action_anim("ranged_shot", 0.30)
				_anim_scale = Vector2(_base_scale.x * 1.12, _base_scale.y * 0.88)
				Fx.anim(get_parent(), global_position + dir * radius, "fx/muzzle.png", 12, 10, 24.0, 1.2, dir.angle(), _boss_color(), true, 6)
				for i in 5:
					_fire(dir.angle() + deg_to_rad(lerpf(-16, 16, i / 4.0)), 190.0, "arrow")
			return _boss_strafe(delta, dir, dist, 0.5)
		"cannon":  # đạn pháo nổ
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.7 * cd_mult
				_volleys += 1
				_trigger_action_anim("ranged_shot", 0.35)
				_anim_scale = Vector2(_base_scale.x * 1.16, _base_scale.y * 0.86)
				var cpos: Vector2 = global_position + dir * radius
				var b := Bullet.new()
				b.setup(false, cpos, dir, 150.0, 2, 3.0, "cannonball")
				get_parent().add_child(b)
				Fx.anim(get_parent(), cpos, "fx/muzzle.png", 12, 10, 24.0, 1.5, dir.angle(), Color.WHITE, true, 6)
				Fx.anim(get_parent(), cpos, "fx/poof.png", 28, 28, 18.0, 0.6)
				if Net.is_online() and Net.is_host():
					Net.send_enemy_event("bullet", {
						"x": cpos.x, "y": cpos.y, "dx": dir.x, "dy": dir.y,
						"spd": 150.0, "dmg": 2, "life": 3.0, "proj": "cannonball",
						"exp": 0.0, "ox": global_position.x, "oy": global_position.y, "muzzle": true,
					}, false)
			return -dir * speed * 0.45 if dist < 90.0 else _boss_strafe(delta, dir, dist, 0.35)
		"tails":   # Hồ Tinh: quạt lửa hồ ly theo số đuôi
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.65 * cd_mult
				_volleys += 1
				_trigger_action_anim("ranged_shot", 0.38)
				_anim_scale = Vector2(_base_scale.x * 1.16, _base_scale.y * 0.86)
				var nt := 9 if transformed else 5
				_spiral += 0.4
				Fx.burst(get_parent(), hurtbox_center(), _boss_color(), 34.0, 0.35)
				Fx.particles(get_parent(), hurtbox_center(), Color(1.0, 0.55, 0.25), 8, 75.0, 0.4, -25.0, 2.0)
				for i in nt:
					_fire(_spiral + TAU * i / nt, 105.0, "fireball")
			return _boss_strafe(delta, dir, dist, 0.55)
		"clone":   # Hồ Tinh: phân thân thành bầy cáo ảo
			if _shoot_t <= 0.0 and _volleys == 0 and room != null:
				_volleys = 1
				_trigger_action_anim("cast_summon", 0.50)
				_anim_scale = Vector2(_base_scale.x * 0.86, _base_scale.y * 1.20)
				Fx.burst(get_parent(), hurtbox_center(), _boss_color(), 44.0, 0.45)
				for i in (3 if transformed else 2) + int(power() / 4.0):
					var cp := global_position + Vector2.from_angle(TAU * i / 3.0 + randf()) * 36.0
					Fx.anim(get_parent(), cp, "fx/poof.png", 28, 28, 16.0, 1.0, 0.0, Color(0.85, 0.6, 1.0))
					room.spawn_enemy(data.summon, cp)
				_fire_ring(10, randf() * TAU, 95.0, "orb_pink")
			return Vector2.ZERO
		"roots":   # Mộc Tinh: rễ cây trồi lên thành hàng về phía người chơi
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 1.0 * cd_mult
				_volleys += 1
				_trigger_action_anim("cast_summon", 0.45)
				_anim_scale = Vector2(_base_scale.x * 0.88, _base_scale.y * 1.18)
				Fx.burst(get_parent(), global_position, _boss_color(), 36.0, 0.4)
				Fx.particles(get_parent(), global_position, _boss_color(), 12, 60.0, 0.45, -20.0, 2.0)
				var lines := 2 if transformed else 1
				for ln in lines:
					var ld := dir.rotated((ln - (lines - 1) / 2.0) * 0.5)
					for i in 7:
						var m := MortarStrike.new()
						m.root = true
						m.radius = 12.0
						m.delay = 0.55 + 0.1 * i
						m.position = global_position + ld * (24.0 + i * 22.0)
						get_parent().add_child(m)
						if Net.is_online() and Net.is_host():
							Net.send_enemy_event("mortar", {"x": m.position.x, "y": m.position.y, "delay": m.delay, "root": true, "radius": 12.0}, false)
			return -dir * speed * 0.35 if dist < 80.0 else Vector2.ZERO
		"dive":    # Ngư Tinh: lấy đà -> lặn xuống tạo sóng ngầm rồi phóng vọt lên phun cột nước
			match _charge_state:
				"":
					_charge_state = "windup"
					_charge_t = 0.24
					_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.82)
					Fx.burst(get_parent(), global_position, Color(0.35, 0.85, 1.0), 28.0, 0.25)
				"windup":
					_charge_t -= delta
					_flash = 0.25 + 0.25 * sin(_charge_t * 36.0)
					if _charge_t <= 0.0:
						_charge_state = "under"
						_charge_t = 1.25
						_submerged = true
						spr.modulate.a = 0.25
						Fx.burst(get_parent(), global_position, Color(0.35, 0.85, 1.0), 42.0, 0.35)
						Fx.particles(get_parent(), global_position, Color(0.5, 0.85, 1.0), 20, 110.0, 0.5, 140.0, 2.5)
				"under":
					_charge_t -= delta
					spr.modulate.a = 0.25
					if int(_boss_t * 30.0) % 2 == 0:
						Fx.particles(get_parent(), global_position + Vector2(randf_range(-10, 10), 6), Color(0.55, 0.9, 1.0), 3, 55.0, 0.35, -35.0, 2.2)
						Fx.particles(get_parent(), global_position + Vector2(randf_range(-6, 6), 8), Color.WHITE, 1, 30.0, 0.25, -20.0, 1.5)
					if _charge_t <= 0.0:
						_charge_state = "rest"
						_charge_t = 0.9
						_submerged = false
						spr.modulate.a = 1.0
						_trigger_action_anim("cast_summon", 0.45)
						_anim_scale = Vector2(_base_scale.x * 0.84, _base_scale.y * 1.24)
						_fire_ring(18 if transformed else 14, randf() * TAU, 110.0, "orb_water")
						Fx.burst(get_parent(), global_position, Color(0.35, 0.85, 1.0), 68.0, 0.42)
						Fx.burst(get_parent(), global_position, Color.WHITE, 38.0, 0.28)
						Fx.particles(get_parent(), global_position, Color(0.55, 0.9, 1.0), 26, 175.0, 0.65, 220.0, 2.6, 38.0, Vector2.UP)
						Fx.shake(get_tree(), 4.8)
					return dir * speed * 2.75
				"rest":
					_charge_t -= delta
					if _charge_t <= 0.0:
						_charge_state = "done"
			return Vector2.ZERO
		"tidal":   # Ngư Tinh: tường nước có 1 khe hở để né
			if _shoot_t <= 0.0 and _volleys < 2:
				_shoot_t = 1.6 * cd_mult
				_volleys += 1
				_trigger_action_anim("cast_summon", 0.45)
				_anim_scale = Vector2(_base_scale.x * 0.88, _base_scale.y * 1.18)
				Fx.burst(get_parent(), global_position, _boss_color(), 42.0, 0.45)
				Fx.particles(get_parent(), global_position, Color(0.35, 0.85, 1.0), 12, 80.0, 0.4, -20.0, 2.0)
				_tidal_wall()
			return Vector2.ZERO
		"fan":     # quạt gió: quạt đạn rộng và chậm
			if _shoot_t <= 0.0 and _volleys < 2:
				_shoot_t = 0.9 * cd_mult
				_volleys += 1
				_trigger_action_anim("melee_sweep", 0.40)
				_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.84)
				Fx.slash(get_parent(), hurtbox_center() + dir * (radius * 0.5), dir, maxf(radius * 2.5, 42.0), deg_to_rad(155.0), _boss_color(), "swing")
				Fx.burst(get_parent(), hurtbox_center(), _boss_color(), 34.0, 0.35)
				for i in 14:
					_fire(dir.angle() + deg_to_rad(lerpf(-75, 75, i / 13.0)), 85.0)
			return _boss_strafe(delta, dir, dist, 0.45)
	return Vector2.ZERO


func _start_morph() -> void:
	_morph_t = 1.4
	Sfx.play("boss_morph")
	_burst_left = 0
	_charge_state = ""
	_submerged = false
	spr.modulate.a = 1.0
	_reset_motion_fx()
	_mat.set_shader_parameter("flash_color", Color(0.7, 0.3, 1.0))
	var what := "Tà thuật trỗi dậy" if not data.get("legend", false) else "Yêu khí bùng lên"
	get_tree().call_group("hud", "show_banner", "%s! %s đang hiện nguyên hình..." % [what, data.name])
	Fx.shake(get_tree(), 4.0)
	# xóa đạn để người chơi kịp thở
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.destroy()
	if Net.is_online() and Net.is_host() and net_id > 0:
		Net.send_enemy_event("morph", {"id": net_id, "phase": "start"}, false)


func net_start_morph() -> void:
	if transformed or _morph_t > 0.0:
		return
	_start_morph()


func net_finish_morph() -> void:
	if transformed:
		return
	_finish_morph()


func net_enrage() -> void:
	if enraged:
		return
	_enrage(true)


func net_special_banner(sp: String) -> void:
	var banners: Dictionary = {
		"cuu_vi": "Hồ Tinh xòe chín đuôi, lửa hồ ly ngập trời!",
		"rung_gia": "Mộc Tinh hút linh khí rừng già!",
		"song_than": "Ngư Tinh dâng sóng thần!",
		"tran_khien": "Lục Dận bày trận khiên!",
		"thuy_quai": "Hoằng Tháo gọi Thủy quái Ngư Tinh!",
		"ong_dong": "Thoát Hoan chui vào ống đồng!",
		"tron_chay": "Tô Định cắt tóc cạo râu, trà trộn bỏ chạy!",
		"mua_ten": "Quách Quỳ hạ lệnh bắn tên như mưa!",
		"sa_lay": "Liễu Thăng sa lầy ở ải Chi Lăng!",
		"boc_chay": "Tàu Hy Vọng bốc cháy ngùn ngụt!",
		"phao_kich": "Đồn trưởng gọi pháo kích!",
		"ham_chi_huy": "Đờ Cát rút vào hầm chỉ huy!",
		"bo_chay": "Tôn Sĩ Nghị bỏ cả ấn tín mà chạy!",
	}
	if banners.has(sp):
		get_tree().call_group("hud", "show_banner", str(banners[sp]))
	Fx.burst(get_parent(), global_position, Color(1, 0.4, 0.3), 50.0, 0.5)
	Fx.shake(get_tree(), 4.0)


func _finish_morph() -> void:
	transformed = true
	spr.position.x = 0.0
	var size2: Vector2i = data.get("size2", data.size)
	var anims := _build_anims(int(data.get("frames", 48 if is_boss() else 24)))
	spr.sprite_frames = Art.frames(data.sheet2, size2.x, size2.y, anims)
	radius = float(data.get("radius2", radius))
	_shape.radius = radius * 0.72
	spr.position = Vector2(0, radius - size2.y / 2.0)
	_base_scale = spr.scale
	_base_spr_y = spr.position.y
	_reset_motion_fx()
	_shadow.position = Vector2(0, radius * 0.9)
	_shadow.scale = Vector2(radius / 7.0, radius / 7.0)
	_sync_hurtbox(size2)
	data["patterns"] = data.get("patterns2", data.patterns)
	_phase = -1
	_phase_t = 0.0
	_volleys = 0
	var bcol: Color = _boss_color()
	Fx.burst(get_parent(), global_position, bcol, 96.0, 0.65)
	Fx.burst(get_parent(), global_position, Color.WHITE, 52.0, 0.45)
	Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 18.0, 2.0, 0.0, Color(0.8, 0.5, 1.0))
	Fx.particles(get_parent(), global_position, Color(0.6, 0.25, 0.8), 40, 160.0, 0.8, -20.0, 3.0)
	Fx.shake(get_tree(), 8.0)
	get_tree().call_group("hud", "show_banner", "%s hiện nguyên hình: %s!" % [data.name, data.get("form2", "")])
	data["name"] = "%s (%s)" % [data.name, data.get("form2", "")]
	if is_boss() and Sfx.has_method("play_boss_music"):
		Sfx.play_boss_music(level, "boss", true)
	_enrage(false)
	if Net.is_online() and Net.is_host() and net_id > 0:
		Net.send_enemy_event("morph", {"id": net_id, "phase": "finish"}, false)


## Sóng nước quét ngang phòng, chừa 1 khe để né
func _tidal_wall() -> void:
	if room == null:
		return
	var r: Rect2 = room.rect.grow(-18.0)
	var from_left := randf() < 0.5
	var x := r.position.x if from_left else r.end.x
	var d := Vector2.RIGHT if from_left else Vector2.LEFT
	var gap := randf_range(r.position.y + 30.0, r.end.y - 30.0)
	var y := r.position.y
	while y <= r.end.y:
		if absf(y - gap) > 22.0:
			var b := Bullet.new()
			b.setup(false, Vector2(x, y), d, 95.0, 1, 4.0, "orb_water")
			get_parent().add_child(b)
			if Net.is_online() and Net.is_host():
				Net.send_enemy_event("bullet", {
					"x": x, "y": y, "dx": d.x, "dy": d.y,
					"spd": 95.0, "dmg": 1, "life": 4.0, "proj": "orb_water",
					"exp": 0.0, "ox": x, "oy": y, "muzzle": false,
				}, false)
		y += 13.0


## Nổi giận khi còn nửa máu: viền đỏ, gầm lên, mở thêm bộ chiêu thứ hai
func _enrage(banner := true) -> void:
	enraged = true
	if is_boss() and Sfx.has_method("play_boss_music"):
		Sfx.play_boss_music(level, "boss", true)
	_rage_t = 1.5
	_mat.set_shader_parameter("flash_color", Color(1.0, 0.25, 0.2))
	_flash = 1.0
	_trigger_action_anim("rage", 0.55)
	_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.86)
	var glow := Art.light(Color(1.0, 0.3, 0.2), 1.6, 0.8)
	add_child(glow)
	if banner:
		get_tree().call_group("hud", "show_banner", "%s nổi giận!" % data.name)
		if Net.is_online() and Net.is_host() and net_id > 0:
			Net.send_enemy_event("morph", {"id": net_id, "phase": "enrage"}, false)
	Fx.burst(get_parent(), global_position, Color(1, 0.35, 0.25), 70.0, 0.5)
	Fx.shake(get_tree(), 5.0)
	# đẩy lùi đạn quanh mình
	for b in get_tree().get_nodes_in_group("player_bullets"):
		if b.global_position.distance_to(global_position) < 60.0:
			b.queue_free()


func _rage_skill(delta: float) -> void:
	_rage_t -= delta * (1.3 if _slowed else 1.0)
	if _rage_t > 0.0 or player == null or not is_instance_valid(player):
		return
	_rage_t = 3.6
	_rage_n += 1
	_trigger_action_anim("rage", 0.45)
	_anim_scale = Vector2(_base_scale.x * 1.14, _base_scale.y * 0.88)
	if _rage_n % 2 == 1:
		# chướng khí: đám mây độc lan ra ngay dưới chân người chơi
		var m := Miasma.new()
		m.position = player.global_position
		m.from_player = false
		m.color = Color(0.45, 0.85, 0.3) if not EnemyData.chapter(level).get("modern", false) else Color(0.75, 0.8, 0.5)
		get_parent().add_child(m)
		Fx.burst(get_parent(), hurtbox_center(), Color(0.55, 0.95, 0.35), 32.0, 0.3)
		Fx.float_text(get_parent(), global_position + Vector2(0, -radius - 20), "Chướng khí!", Color(0.6, 1.0, 0.4), 13)
		if Net.is_online() and Net.is_host():
			Net.send_enemy_event("miasma", {"x": m.position.x, "y": m.position.y, "r": m.color.r, "g": m.color.g, "b": m.color.b}, false)
	else:
		# hỏa tiễn: quạt 5 quả cầu lửa gây cháy
		Fx.burst(get_parent(), hurtbox_center(), Color(1.0, 0.48, 0.2), 34.0, 0.3)
		var a: float = (player.global_position - global_position).angle()
		for i in 5:
			_fire(a + deg_to_rad(lerpf(-30, 30, i / 4.0)), 140.0, "fireball")


func _start_special(sp: String) -> void:
	_special_used = true
	_submerged = false
	spr.modulate.a = 1.0
	_charge_state = ""
	_reset_motion_fx()
	_special = sp
	match sp:
		"cuu_vi":
			get_tree().call_group("hud", "show_banner", "Hồ Tinh xòe chín đuôi, lửa hồ ly ngập trời!")
			_special_t = 3.5
			_shoot_t = 0.2
		"rung_gia":
			get_tree().call_group("hud", "show_banner", "Mộc Tinh hút linh khí rừng già!")
			_special_t = 2.0
			hp = mini(max_hp, hp + int(max_hp * 0.12))
			Fx.particles(get_parent(), global_position, Color(0.5, 1.0, 0.4), 30, 90.0, 0.8, -60.0, 2.5)
			if room != null:
				for i in 3:
					room.spawn_enemy("moc_tinh", global_position + Vector2.from_angle(TAU * i / 3.0) * 44.0)
		"song_than":
			get_tree().call_group("hud", "show_banner", "Ngư Tinh dâng sóng thần!")
			_special_t = 3.2
			_shoot_t = 0.1
		"tran_khien":
			get_tree().call_group("hud", "show_banner", "Lục Dận bày trận khiên!")
			if room != null:
				for i in 3:
					room.spawn_enemy("khien_binh@" + str(data.army), global_position + Vector2.from_angle(TAU * i / 3.0) * 34.0)
			speed *= 1.3
			_special_t = 1.0
		"thuy_quai":
			get_tree().call_group("hud", "show_banner", "Hoằng Tháo gọi Thủy quái Ngư Tinh!")
			if room != null:
				room.spawn_enemy("ngu_tinh", global_position + Vector2(0, -50))
			_special_t = 1.0
		"ong_dong":
			get_tree().call_group("hud", "show_banner", "Thoát Hoan chui vào ống đồng!")
			_special_t = 4.5
			_charge_dir = Vector2.from_angle(randf() * TAU)
		"tron_chay":
			get_tree().call_group("hud", "show_banner", "Tô Định cắt tóc cạo râu, trà trộn bỏ chạy!")
			_special_t = 4.0
			spr.modulate.a = 0.45
			if room != null:
				for i in 3:
					room.spawn_enemy("bo_binh@" + str(data.army), global_position + Vector2.from_angle(TAU * i / 3.0) * 30.0)
		"mua_ten":
			get_tree().call_group("hud", "show_banner", "Quách Quỳ hạ lệnh bắn tên như mưa!")
			_special_t = 3.0
			_shoot_t = 0.0
		"sa_lay":
			get_tree().call_group("hud", "show_banner", "Liễu Thăng sa lầy ở ải Chi Lăng!")
			_slowed = true
			speed *= 0.45
			_special_t = 1.0
		"boc_chay":
			get_tree().call_group("hud", "show_banner", "Tàu Hy Vọng bốc cháy ngùn ngụt!")
			_special_t = 6.0
		"phao_kich":
			get_tree().call_group("hud", "show_banner", "Đồn trưởng gọi pháo kích!")
			_special_t = 3.5
		"ham_chi_huy":
			get_tree().call_group("hud", "show_banner", "Đờ Cát rút vào hầm chỉ huy!")
			_special_t = 5.0
		"bo_chay":
			get_tree().call_group("hud", "show_banner", "Tôn Sĩ Nghị bỏ cả ấn tín mà chạy!")
			_special_t = 3.5
			for i in 8:
				_spawn_pickup("coin", 3)
	Fx.burst(get_parent(), global_position, Color(1, 0.4, 0.3), 50.0, 0.5)
	Fx.shake(get_tree(), 4.0)
	if Net.is_online() and Net.is_host() and net_id > 0:
		Net.send_enemy_event("morph", {"id": net_id, "phase": "special", "sp": sp}, false)


# ------------------------------------------------------------------ Trúng đòn, chết

func apply_stun(t: float) -> void:
	if is_replica:
		if net_id > 0:
			Net.send_enemy_event("stun_req", {"id": net_id, "t": t}, true)
		return
	if _morph_t > 0.0:
		return
	if is_boss():
		t *= 0.35
	_stun_t = maxf(_stun_t, t)
	_charge_state = ""
	_reset_motion_fx()


func is_slowed() -> bool:
	return _slowed or _hazard_slow_t > 0.0 or has_meta("weapon_slowed")


func apply_hazard_slow(factor: float = 0.5, dur: float = 0.4) -> void:
	if dead or _morph_t > 0.0 or _submerged:
		return
	var eff_factor: float = clampf(factor, 0.25, 1.0)
	_hazard_slow_mult = minf(_hazard_slow_mult, eff_factor) if _hazard_slow_t > 0.0 else eff_factor
	_hazard_slow_t = maxf(_hazard_slow_t, dur)


func apply_hazard_damage(dmg: int, knock_vec: Vector2 = Vector2.ZERO) -> void:
	if dead or is_replica or _spawn_t > 0.0 or _morph_t > 0.0 or _submerged:
		return
	take_damage(maxi(1, dmg), knock_vec)


func take_damage(amount: int, knock := Vector2.ZERO) -> void:
	if dead or _spawn_t > 0.0:
		return
	if _morph_t > 0.0 or _submerged:
		return
	_aggro_reveal_t = 2.5
	if is_replica:
		if net_id > 0:
			Net.send_enemy_event("dmg_req", {"id": net_id, "dmg": amount, "kx": knock.x, "ky": knock.y}, true)
		_flash = 1.0
		if not is_boss():
			_hurt_anim_t = 0.16
			_anim_scale = Vector2(_base_scale.x * 1.24, _base_scale.y * 0.76)
			_hp_bar_t = 3.0
			queue_redraw()
		Sfx.play("hit_boss" if is_boss() else "enemy_hurt")
		Fx.float_text(get_parent(), global_position + Vector2(0, -radius - 6.0), str(amount), Color(1, 1, 1) if amount < 10 else Color(1, 0.85, 0.3), 14 if amount < 10 else 18)
		return
	# phúc lành của người chơi: tăng sát thương, chí mạng
	last_hit_crit = false
	var crit := false
	var dmg := amount
	var dmg_mult: float = 1.0
	if player != null and is_instance_valid(player):
		dmg_mult *= player.damage_mult()
		if player.has_method("buff") and player.buff("ngu_hanh") > 0:
			var has_fx: bool = _stun_t > 0.0 or (status != null and (status.has("burn") or status.has("poison")))
			if has_fx:
				dmg_mult *= 1.3
		if (is_boss() or elite) and player.has_method("buff") and player.buff("cuong_no_trum") > 0:
			dmg_mult *= 1.0 + 0.35 * float(player.buff("cuong_no_trum"))
		if str(player.get("hero_id")) == "nguyen_trung_truc" and status != null and status.has("burn"):
			dmg_mult *= 1.25
		if player.has_method("buff") and player.buff("bang_tam") > 0 and is_slowed():
			dmg_mult *= 1.25
		dmg = int(round(float(amount) * dmg_mult))
		var forced_crit: bool = player.has_method("is_kinetic_ready") and player.is_kinetic_ready()
		var eff_crit: float = player.crit_chance()
		if player.has_method("buff") and player.buff("bang_tam") > 0 and is_slowed():
			eff_crit += 0.15
		if forced_crit:
			dmg = (dmg + 8) * 2
			crit = true
		elif randf() < eff_crit:
			dmg *= 2
			crit = true
	last_hit_crit = crit
	var blocked: bool = false
	if data.ai == "tank" and knock != Vector2.ZERO and _stun_t <= 0.0:
		# đòn đánh từ phía trước bị khiên đỡ bớt
		var facing := Vector2(_face, 0)
		if facing.dot(-knock.normalized()) > 0.2:
			dmg = maxi(1, int(amount * 0.35))
			blocked = true
			if randf() < 0.3:
				Fx.float_text(get_parent(), global_position + Vector2(0, -radius - 10), "Đỡ!", Color(0.7, 0.8, 1.0), 12)
	if _special in ["ong_dong", "ham_chi_huy", "rung_gia"] and _special_t > 0.0:
		dmg = maxi(1, int(amount * 0.2))
		blocked = true
	if _special == "tran_khien" and _special_t > 0.0:
		blocked = true
	if _slowed:
		dmg = int(dmg * 1.5)
	hp -= dmg
	_flash = 1.0
	if not is_boss():
		_hurt_anim_t = 0.16
		_anim_scale = Vector2(_base_scale.x * 1.24, _base_scale.y * 0.76)
		_hp_bar_t = 3.0
		queue_redraw()
	elif _morph_t <= 0.0 and _leap_state != "air":
		_anim_scale = Vector2(_base_scale.x * 1.08, _base_scale.y * 0.92)
	if blocked:
		Sfx.play("hit_metal")
	elif crit:
		Sfx.play("hit_crit")
		Fx.hitstop(get_tree(), 0.035)
		if player != null and is_instance_valid(player) and player.has_method("on_crit_enemy"):
			player.on_crit_enemy(self)
	elif is_boss():
		Sfx.play("hit_boss")
	else:
		Sfx.play("enemy_hurt")
	_knock += knock * (0.08 if is_boss() else (0.4 if data.ai == "tank" else 1.0))
	var top_pos := Vector2(global_position.x, hurtbox_rect().position.y - 4.0)
	Fx.float_text(get_parent(), top_pos, ("%d!" % dmg) if crit else str(dmg), Color(1, 1, 1) if dmg < 10 else Color(1, 0.85, 0.3), 14 if dmg < 10 else 18)
	if hp <= 0:
		die()


## Sát thương theo nhịp (cháy / độc): không đẩy lùi, không chí mạng
func dot_damage(amount: int, kind: String) -> void:
	if dead or is_replica or _spawn_t > 0.0 or _morph_t > 0.0 or _submerged:
		return
	var dmg := amount
	if kind == "burn" and player != null and is_instance_valid(player) and player.has_method("buff") and player.buff("khien_lua") > 0:
		dmg = int(round(float(dmg) * 1.5))
	if is_boss():
		dmg = maxi(1, dmg)
	hp -= dmg
	_flash = maxf(_flash, 0.4)
	if not is_boss():
		_hurt_anim_t = 0.16
		_anim_scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.82)
		_hp_bar_t = 3.0
		queue_redraw()
	var top_dot := Vector2(global_position.x + randf_range(-6, 6), hurtbox_rect().position.y - 4.0)
	Fx.float_text(get_parent(), top_dot, str(dmg), Color(1, 0.6, 0.25) if kind == "burn" else Color(0.6, 1.0, 0.35), 11)
	if hp <= 0:
		die()


func apply_status(kind: String, duration: float) -> void:
	if is_replica and net_id > 0:
		Net.send_enemy_event("status_req", {"id": net_id, "kind": kind, "dur": duration}, true)
	if dead:
		return
	if kind == "slow":
		apply_hazard_slow(0.55, duration)
		return
	if status != null:
		status.apply(kind, duration * (0.6 if is_boss() else 1.0))


func die(drop := true) -> void:
	if dead:
		return
	dead = true
	if Net.is_online() and Net.is_host() and net_id > 0:
		Net.send_enemy_event("die", {"id": net_id, "drop": drop}, false)
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			ns.unregister_enemy(net_id)
	_finish_die(drop, true)


func die_from_net(drop: bool) -> void:
	if dead:
		return
	dead = true
	_finish_die(drop, false)


func _finish_die(drop: bool, spawn_shared_loot: bool) -> void:
	Sfx.play("explode" if is_boss() else "enemy_die")
	if drop:
		Global.add_stat("kills")
		if is_boss():
			Global.add_stat("bosses")
			var lp: Node = Global.local_player()
			Global.on_boss_killed(int(lp.get("hp")) if (lp != null and is_instance_valid(lp)) else 0)
			if Global.has_method("unlock_chronicle_for_boss"):
				var cres: Dictionary = Global.call("unlock_chronicle_for_boss", str(data.get("id", kind)))
				if bool(cres.get("newly_unlocked", false)) and is_inside_tree():
					get_tree().call_group("hud", "show_chronicle_toast", str(cres.get("title", "")))
	remove_from_group("enemies")
	remove_from_group("boss")
	Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, radius / 7.0)
	Fx.particles(get_parent(), global_position, Color(0.85, 0.3, 0.3), 10, 90.0, 0.5, 120.0, 2.0)
	Fx.decal(get_parent(), global_position, "armor_shards" if (elite or is_boss()) else "blood_ink", _boss_color() if is_boss() else Color(0.82, 0.22, 0.24), 1.35 if is_boss() else (1.1 if elite else 0.85))
	if elite and not is_boss():
		Fx.hitstop(get_tree(), 0.03)
	if is_boss() and data.get("id", "") == "do_cat":
		get_tree().call_group("hud", "show_banner", "Bắt sống Đờ Cát tại hầm chỉ huy!")
	if is_boss():
		Fx.hitstop(get_tree(), 0.075)
		Fx.burst(get_parent(), hurtbox_center(), _boss_color(), 88.0, 0.7)
		var wr: WeakRef = weakref(get_parent())
		for i in 5:
			var p := global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_tree().create_timer(0.12 * i).timeout.connect(func():
				var par = wr.get_ref()
				if par != null:
					Fx.anim(par, p, "fx/explosion.png", 44, 44, 18.0, 1.2))
		Fx.shake(get_tree(), 7.0)
	if drop:
		_drop_loot(spawn_shared_loot)
	killed.emit(self)
	queue_free()


func _drop_loot(spawn_shared_loot: bool = true) -> void:
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp):
		lp.on_kill(global_position)
	if elite:
		Fx.float_text(get_parent(), global_position + Vector2(0, -20), "Hạ tinh nhuệ!", Color(1, 0.85, 0.35), 16)
		if spawn_shared_loot and randf() < 0.45 and room != null:
			room.drop_weapon_at(global_position, 1)
	var pieces: int = 6 if is_boss() else maxi(1, int(data.coins)) * (2 if elite else 1)
	var coin_val: int = (3 if EnemyData.is_mythic_level(level) else 2) if is_boss() else 1
	for i in pieces:
		_spawn_pickup("coin", coin_val)
	for i in randi_range(1, 2):
		_spawn_pickup("energy", 5)
	if spawn_shared_loot and not is_boss() and randf() < 0.04:
		_spawn_shared_pickup("potion", 2)
	var is_legend: bool = bool(data.get("legend", false))
	var is_folk: bool = EnemyData.FOLK.has(kind)
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	var mythic: bool = EnemyData.is_mythic_level(level)
	for mid in MaterialData.roll_enemy_drops(is_boss(), is_legend, is_folk, elite, modern, mythic):
		_spawn_material(str(mid))
	if Global != null and Global.has_method("roll_blueprint_drop"):
		if is_legend:
			if mythic or randf() < 0.65:
				var bp_leg: String = str(Global.roll_blueprint_drop(level, "legend", mythic))
				if bp_leg != "":
					_spawn_blueprint_frag(bp_leg)
		elif is_boss():
			var bp_count: int = 2 if mythic else 1
			for bi in bp_count:
				var bp_boss: String = str(Global.roll_blueprint_drop(level, "boss", mythic))
				if bp_boss != "":
					_spawn_blueprint_frag(bp_boss, Vector2(float(bi) * 14.0 - 7.0, 0.0))
		elif elite:
			if randf() < 0.22:
				var bp_el: String = str(Global.roll_blueprint_drop(level, "elite", mythic))
				if bp_el != "":
					_spawn_blueprint_frag(bp_el)


func _spawn_shared_pickup(k: String, amount: int) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = global_position
	if Net.is_online() and Net.is_host():
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			p.pickup_id = ns.alloc_pickup_id()
			get_parent().add_child(p)
			ns.register_pickup(p)
			Net.send_world_event("spawn_pickup", {
				"id": p.pickup_id,
				"kind": k,
				"amount": amount,
				"weapon_id": "",
				"material_id": "",
				"x": global_position.x,
				"y": global_position.y,
			}, false)
			return
	get_parent().add_child(p)


func _spawn_material(mid: String) -> void:
	var p := Pickup.new()
	p.kind = "material"
	p.material_id = mid
	p.amount = 1
	p.position = global_position
	get_parent().add_child(p)


func _spawn_blueprint_frag(bp_wid: String, offset: Vector2 = Vector2.ZERO) -> void:
	if bp_wid == "" or get_parent() == null:
		return
	var p := Pickup.new()
	p.kind = "blueprint_frag"
	p.blueprint_id = bp_wid
	p.amount = 1
	p.position = global_position + offset
	get_parent().add_child(p)


func _spawn_pickup(k: String, amount: int) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = global_position
	get_parent().add_child(p)


func _draw() -> void:
	if dead:
		return
	if is_boss():
		_draw_boss_fx()
	elif _charge_state == "windup":
		if str(data.get("ai", "")) == "slam":
			var sr: float = 54.0 * clampf(1.0 - _charge_t / 0.55, 0.2, 1.0)
			draw_set_transform(Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.65))
			draw_arc(Vector2.ZERO, sr, 0.0, TAU, 28, Color(1.0, 0.35, 0.25, 0.8), 1.6)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			_draw_charge_lane(110.0)
	if is_boss() or _hp_bar_t <= 0.0 or hp >= max_hp or max_hp <= 0:
		return
	var bw: float = 24.0 if elite else 18.0
	var bh: float = 3.0
	var pos := Vector2(-bw / 2.0, (_hb_offset.y - _hb_size.y * 0.5) - 6.0)
	var a: float = clampf(_hp_bar_t / 0.4, 0.0, 1.0)
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos - Vector2(1.0, 1.0), Vector2(bw + 2.0, bh + 2.0)), Color(0.06, 0.02, 0.04, 0.92 * a))
	draw_rect(Rect2(pos, Vector2(bw, bh)), Color(0.24, 0.07, 0.09, 0.92 * a))
	var fw: float = bw * ratio
	if fw > 0.0:
		draw_rect(Rect2(pos, Vector2(fw, bh)), Color(0.86, 0.18, 0.22, a))
		draw_rect(Rect2(pos, Vector2(fw, 1.0)), Color(1.0, 0.48, 0.46, a))


func _draw_charge_lane(lane_len: float) -> void:
	if _charge_dir.length_squared() < 0.01:
		return
	var ang: float = _charge_dir.angle()
	var half_w: float = maxf(8.0, radius * 0.85)
	var pulse: float = 0.5 + 0.5 * sin(_boss_t * 18.0)
	draw_set_transform(Vector2(0.0, 2.0), ang, Vector2.ONE)
	draw_rect(Rect2(0.0, -half_w, lane_len, half_w * 2.0), Color(1.0, 0.2, 0.18, 0.20 + 0.12 * pulse))
	draw_line(Vector2(0.0, -half_w), Vector2(lane_len, -half_w), Color(1.0, 0.42, 0.30, 0.88), 1.6)
	draw_line(Vector2(0.0, half_w), Vector2(lane_len, half_w), Color(1.0, 0.42, 0.30, 0.88), 1.6)
	draw_polyline(PackedVector2Array([
		Vector2(lane_len - 8.0, -half_w),
		Vector2(lane_len + 6.0, 0.0),
		Vector2(lane_len - 8.0, half_w),
	]), Color(1.0, 0.85, 0.45, 0.90), 1.8)
	for ci in 3:
		var cx: float = fmod(_boss_t * 95.0 + float(ci) * (lane_len * 0.32), lane_len * 0.85) + 12.0
		draw_polyline(PackedVector2Array([
			Vector2(cx - 5.0, -half_w * 0.62),
			Vector2(cx + 5.0, 0.0),
			Vector2(cx - 5.0, half_w * 0.62),
		]), Color(1.0, 0.85, 0.50, 0.55 + 0.35 * pulse), 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_boss_fx() -> void:
	var bcol: Color = _boss_color()
	var fast: float = 2.6 if (enraged or transformed) else 1.4
	var pulse: float = 0.5 + 0.5 * sin(_boss_t * 4.5)
	if _submerged:
		for wi in 3:
			var wr: float = fmod(_boss_t * 28.0 + float(wi) * 14.0, 42.0)
			draw_set_transform(Vector2(0.0, 4.0), 0.0, Vector2(1.0, 0.55))
			draw_arc(Vector2.ZERO, wr, 0.0, TAU, 28, Color(0.42, 0.85, 1.0, 0.55 * (1.0 - wr / 42.0)), 1.6)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if _charge_state == "under" and _charge_t < 0.45:
			var warn_r: float = 48.0 * clampf(1.0 - _charge_t / 0.45, 0.2, 1.0)
			draw_arc(Vector2(0.0, 4.0), warn_r, 0.0, TAU, 32, Color(1.0, 0.32, 0.28, 0.85), 2.0)
		return
	var sig_r: float = maxf(radius * 1.45, _hb_size.x * 0.45)
	draw_set_transform(Vector2(0.0, 6.0), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, sig_r * 0.88, Color(bcol.r, bcol.g, bcol.b, 0.10 + (0.06 if (enraged or transformed) else 0.0) * pulse))
	draw_arc(Vector2.ZERO, sig_r, 0.0, TAU, 36, Color(bcol.r, bcol.g, bcol.b, 0.42 + 0.24 * pulse), 1.6)
	draw_arc(Vector2.ZERO, sig_r * 0.68, 0.0, TAU, 28, Color(bcol.r, bcol.g, bcol.b, 0.28 + 0.16 * pulse), 1.1)
	for ri in 6:
		var ra: float = _boss_t * fast + TAU * float(ri) / 6.0
		var p1: Vector2 = Vector2.from_angle(ra) * (sig_r * 0.72)
		var p2: Vector2 = Vector2.from_angle(ra) * (sig_r * 1.04)
		draw_line(p1, p2, Color(bcol.r, bcol.g, bcol.b, 0.72), 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _charge_state == "windup":
		_draw_charge_lane(175.0)
	elif _charge_state == "dash" and _charge_dir.length_squared() > 0.01:
		var nose: float = maxf(_hb_size.x, _hb_size.y) * 0.42
		draw_set_transform(_hb_offset, _charge_dir.angle(), Vector2.ONE)
		draw_polyline(PackedVector2Array([
			Vector2(nose - 26.0, -20.0),
			Vector2(nose + 12.0, 0.0),
			Vector2(nose - 26.0, 20.0),
		]), Color(bcol.r, bcol.g, bcol.b, 0.90), 2.4)
		draw_polyline(PackedVector2Array([
			Vector2(nose - 16.0, -13.0),
			Vector2(nose + 16.0, 0.0),
			Vector2(nose - 16.0, 13.0),
		]), Color(1.0, 0.95, 0.78, 0.92), 1.6)
		for si in 5:
			var sy: float = (float(si) - 2.0) * 7.5
			var sx: float = -nose * 0.7 - float((si * 7) % 12)
			draw_line(Vector2(sx, sy), Vector2(sx - 24.0 - float((si % 2) * 10), sy), Color(bcol.r, bcol.g, bcol.b, 0.75), 1.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _leap_state in ["windup", "air"]:
		var tgt_local: Vector2 = _leap_target - global_position
		var lp_t: float = clampf(1.0 - _leap_t / (0.45 if _leap_state == "windup" else 0.48), 0.0, 1.0)
		var l_col := Color(1.0, 0.82, 0.35, 0.88) if _leap_state == "air" else Color(1.0, 0.35, 0.25, 0.82)
		draw_set_transform(tgt_local, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, 46.0, Color(l_col.r, l_col.g, l_col.b, 0.14 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 36, l_col, 2.0)
		draw_arc(Vector2.ZERO, lerpf(42.0, 10.0, lp_t), 0.0, TAU, 28, Color(1.0, 0.95, 0.70, 0.92), 1.6)
		draw_line(Vector2(-10.0, 0.0), Vector2(10.0, 0.0), l_col, 1.4)
		draw_line(Vector2(0.0, -10.0), Vector2(0.0, 10.0), l_col, 1.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _morph_t > 0.0:
		var m_r: float = lerpf(64.0, 18.0, clampf(1.0 - _morph_t / 1.4, 0.0, 1.0))
		draw_rect(Rect2(-10.0, -110.0, 20.0, 118.0), Color(0.75, 0.35, 1.0, 0.18 + 0.12 * pulse))
		draw_arc(_hb_offset, m_r, 0.0, TAU, 32, Color(0.88, 0.55, 1.0, 0.85), 2.2)
		draw_arc(_hb_offset, m_r * 0.65, 0.0, TAU, 28, Color(1.0, 0.85, 0.4, 0.85), 1.5)
	if _special in ["ong_dong", "ham_chi_huy", "tran_khien", "rung_gia"] and _special_t > 0.0:
		var sh_r: float = maxf(_hb_size.x, _hb_size.y) * 0.58
		var sh_col := Color(0.45, 0.98, 0.55, 0.75) if _special == "rung_gia" else Color(1.0, 0.82, 0.35, 0.82)
		draw_arc(_hb_offset, sh_r, _boss_t * 3.0, _boss_t * 3.0 + PI * 1.6, 28, sh_col, 2.2)
		draw_arc(_hb_offset, sh_r - 3.5, -_boss_t * 2.2, -_boss_t * 2.2 + PI * 1.3, 24, Color(1.0, 1.0, 1.0, 0.45), 1.2)
