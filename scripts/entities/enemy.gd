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


func setup(k: String, lvl: int, target) -> void:
	kind = k
	level = lvl
	data = EnemyData.info(k, lvl)
	max_hp = data.hp
	if Net.is_online() and Net.player_count() > 1:
		max_hp = int(round(float(max_hp) * (1.0 + 0.5 * float(Net.player_count() - 1))))
	hp = max_hp
	radius = data.radius
	speed = data.speed
	player = target
	_shoot_t = randf_range(0.8, 1.8)
	_summon_t = randf_range(4.0, 6.0)
	if is_boss():
		_spawn_t = 1.2


## Biến thành giặc tinh nhuệ (gọi trước khi thêm vào cây cảnh)
func make_elite() -> void:
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
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = radius * 0.8
	_shape = shape
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	z_index = 1

	var sh := Sprite2D.new()
	_shadow = sh
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, radius * 0.9)
	sh.scale = Vector2(radius / 7.0, radius / 7.0)
	sh.z_index = -2
	add_child(sh)

	var size: Vector2i = data.size
	var n: int = data.get("frames", 4)
	var anims := {"walk": [[0, 1, 2, 3], 8.0, true]}
	if n == 5:
		anims["attack"] = [[4], 1.0, false]
	if n >= 6:
		anims["attack"] = [[4], 1.0, false]
		anims["rage"] = [[5], 1.0, false]
	if n >= 7:
		anims["special"] = [[6], 1.0, false]
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Art.frames(data.sheet, size.x, size.y, anims)
	spr.position = Vector2(0, radius - size.y / 2.0)
	_mat = Art.flash_material()
	spr.material = _mat
	spr.play("walk")
	spr.frame = randi() % 4
	spr.modulate = Color(1, 1, 1, 0)
	add_child(spr)
	if elite:
		spr.scale = Vector2(1.25, 1.25)
		spr.position.y *= 1.25
		_mat.set_shader_parameter("flash_color", Color(1.0, 0.8, 0.25))
		var glow := Art.light(Color(1.0, 0.75, 0.3), 0.8, 0.7)
		add_child(glow)
	Fx.anim(get_parent(), position, "fx/poof.png", 28, 28, 16.0, radius / 8.0, 0.0, Color(1, 0.6, 0.6) if not is_boss() else Color(1, 0.4, 0.4))
	status = StatusFx.new()
	status.unit = self
	status.head = float(size.y) * (1.25 if elite else 1.0) - radius + 4.0
	status.tick_damage = 2 + int(level / 4)
	add_child(status)
	if _net_pos == Vector2.ZERO:
		_net_pos = global_position


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
	if _hp_bar_t > 0.0:
		_hp_bar_t = maxf(_hp_bar_t - delta, 0.0)
		queue_redraw()
	_flash = maxf(_flash - delta * 8.0, 0.0)
	var base_glow := 0.18 + 0.1 * sin(Time.get_ticks_msec() / 150.0) if elite else 0.0
	_mat.set_shader_parameter("flash", maxf(_flash, base_glow))
	_attack_anim_t -= delta
	player = Global.nearest_player(global_position)
	if is_replica:
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
			if int(_morph_t * 20.0) % 2 == 0:
				Fx.particles(get_parent(), global_position + Vector2(randf_range(-16, 16), randf_range(-24, 4)), Color(0.55, 0.2, 0.7), 3, 50.0, 0.6, -50.0, 2.5)
			if _morph_t <= 0.0 and not transformed and data.has("sheet2"):
				_finish_morph()
			return
		spr.modulate.a = 0.25 if _submerged else 1.0
		if _net_anim != "" and spr.sprite_frames.has_animation(_net_anim) and spr.animation != _net_anim:
			spr.play(_net_anim)
		_contact_t -= delta
		if not _submerged and _contact_t <= 0.0:
			var lp: Node = Global.local_player()
			if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")) and not bool(lp.get("downed")):
				if global_position.distance_to((lp as Node2D).global_position) < radius + 7.0:
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
			_update_anim()
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
			Fx.particles(get_parent(), global_position + Vector2(0, -radius * 2.0), Color(1, 0.95, 0.4), 1, 30.0, 0.4, 0.0, 1.0)
	elif player != null and is_instance_valid(player) and not player.dead:
		spr.modulate = Color.WHITE
		var to: Vector2 = player.global_position - global_position
		var dist := to.length()
		var dir := to / maxf(dist, 0.001)
		_face = 1.0 if to.x >= 0.0 else -1.0
		match data.ai:
			"chase":
				desired = (dir + _wander_vec(delta) * 0.35).normalized() * speed
			"shoot":
				desired = _keep_distance(delta, dir, dist, 150.0, 80.0)
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 1.7) * randf_range(0.8, 1.2)
					_fire(dir.angle(), 150.0, data.get("proj", "arrow"))
					_attack_anim_t = 0.3
			"tank":
				desired = (dir + _wander_vec(delta) * 0.2).normalized() * speed
			"caster":
				desired = _keep_distance(delta, dir, dist, 140.0, 100.0)
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 2.8) * randf_range(0.8, 1.2)
					_fire_ring(8, randf() * TAU, 95.0, "orb_poison")
					_attack_anim_t = 0.3
				_summon_t -= delta
				if _summon_t <= 0.0 and room != null:
					_summon_t = randf_range(6.0, 8.0)
					var folk: Array = EnemyData.chapter(level).folk
					var p := global_position + Vector2.from_angle(randf() * TAU) * 26.0
					Fx.particles(get_parent(), p, Color(0.8, 0.4, 1.0), 16, 90.0, 0.5)
					room.spawn_enemy(folk.pick_random(), p)
			"ring":
				desired = (dir + _wander_vec(delta) * 0.5).normalized() * speed
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 2.8) * randf_range(0.8, 1.2)
					_fire_ring(8, randf() * TAU, 100.0, "orb_pink")
			"charge":
				desired = _charge_ai(delta, dir, dist, 4.0)
			"rifle":
				desired = _keep_distance(delta, dir, dist, 170.0, 90.0)
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 1.5) * randf_range(0.8, 1.2)
					_fire(dir.angle() + randf_range(-0.05, 0.05), 210.0, "bullet")
					_attack_anim_t = 0.2
			"mg":
				desired = _keep_distance(delta, dir, dist, 170.0, 110.0) * 0.6
				_shoot_t -= delta
				if _shoot_t <= 0.0 and _burst_left == 0:
					_shoot_t = data.get("shoot_cd", 2.6) * randf_range(0.8, 1.2)
					_start_burst(6, 8.0)
			"mortar":
				desired = _keep_distance(delta, dir, dist, 190.0, 120.0)
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 3.2) * randf_range(0.8, 1.2)
					_mortar(player.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 1.0)
			"tank_elite":
				desired = (dir + _wander_vec(delta) * 0.2).normalized() * speed
				_shoot_t -= delta
				if _shoot_t <= 0.0:
					_shoot_t = data.get("shoot_cd", 2.4) * randf_range(0.8, 1.2)
					if randf() < 0.5:
						_cannon(dir, 1)
					else:
						_start_burst(8, 14.0)
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
		if Net.is_online():
			var lp: Node = Global.local_player()
			if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")) and not bool(lp.get("downed")) and global_position.distance_to((lp as Node2D).global_position) < radius + 7.0 and _contact_t <= 0.0:
				lp.take_damage((2 + int(power() / 5.0)) if is_boss() else (2 if elite else 1))
				_contact_t = 0.8
				_attack_anim_t = 0.3
		elif dist < radius + 7.0 and _contact_t <= 0.0:
			player.take_damage((2 + int(power() / 5.0)) if is_boss() else (2 if elite else 1))
			_contact_t = 0.8
			_attack_anim_t = 0.3

	_update_burst(delta)
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	velocity = desired + _knock
	move_and_slide()
	_update_anim()


func _update_anim() -> void:
	spr.flip_h = _face < 0.0
	if _special in ["ong_dong", "ham_chi_huy", "boc_chay", "cuu_vi", "rung_gia", "song_than"] and _special_t > 0.0 and spr.sprite_frames.has_animation("special"):
		spr.play("special")
	elif _attack_anim_t > 0.0 and spr.sprite_frames.has_animation("attack"):
		spr.play("attack")
	elif hp < max_hp / 2 and is_boss() and spr.sprite_frames.has_animation("rage") and _attack_anim_t > -0.4:
		spr.play("rage")
	else:
		spr.play("walk")
		spr.speed_scale = clampf(velocity.length() / maxf(speed, 1.0), 0.3, 2.0)


func _keep_distance(delta: float, dir: Vector2, dist: float, far: float, near: float) -> Vector2:
	if dist > far:
		return dir * speed
	elif dist < near:
		return -dir * speed
	return _wander_vec(delta) * speed * 0.6


func _wander_vec(delta: float) -> Vector2:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(0.6, 1.4)
		_wander = Vector2.from_angle(randf() * TAU)
	return _wander


func _charge_ai(delta: float, dir: Vector2, dist: float, mult: float) -> Vector2:
	match _charge_state:
		"windup":
			_charge_t -= delta
			_flash = 0.35 + 0.35 * sin(_charge_t * 40.0)
			if _charge_t <= 0.0:
				_charge_state = "dash"
				_charge_t = 0.5
			_charge_dir = dir
			return Vector2.ZERO
		"dash":
			_charge_t -= delta
			if _charge_t <= 0.0:
				_charge_state = "rest"
				_charge_t = 1.2
			if int(_charge_t * 30.0) % 2 == 0:
				Fx.anim(get_parent(), global_position + Vector2(0, radius), "fx/dust.png", 10, 10, 14.0, 1.2)
			return _charge_dir * speed * mult
		"rest":
			_charge_t -= delta
			if _charge_t <= 0.0:
				_charge_state = ""
			return dir * speed * 0.4
	if dist < 150.0:
		_charge_state = "windup"
		_charge_t = 0.45
	return (dir + _wander_vec(delta) * 0.3).normalized() * speed


func _start_burst(n: int, spread_deg: float) -> void:
	_burst_left = n
	_burst_t = 0.0
	_burst_spread = spread_deg
	_attack_anim_t = 0.6


func _update_burst(delta: float) -> void:
	if _burst_left <= 0 or player == null or not is_instance_valid(player) or _stun_t > 0.0:
		return
	_burst_t -= delta
	if _burst_t <= 0.0:
		_burst_t = 0.09
		_burst_left -= 1
		var a: float = (player.global_position - global_position).angle() + deg_to_rad(randf_range(-_burst_spread, _burst_spread))
		_fire(a, 230.0, "bullet")


func _mortar(pos: Vector2, delay: float) -> void:
	var m := MortarStrike.new()
	m.position = pos
	m.delay = delay
	get_parent().add_child(m)
	Fx.anim(get_parent(), global_position + Vector2(0, -radius), "fx/poof.png", 28, 28, 18.0, 0.5)
	_attack_anim_t = 0.3
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
	_attack_anim_t = 0.3
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
	if _special == "tron_chay" and _special_t <= 0.0:
		spr.modulate.a = 1.0
	if _special_t > 0.0:
		_special_t -= delta
		match _special:
			"ong_dong":
				# lăn lông lốc khắp phòng, nảy vào tường
				if get_slide_collision_count() > 0:
					_charge_dir = _charge_dir.bounce(get_slide_collision(0).get_normal())
				return _charge_dir * speed * 3.0
			"bo_chay":
				return -dir * speed * 2.4
			"tron_chay":
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
	_shoot_t -= delta
	var cd_mult := 0.7 if rage else 1.0
	# trùm càng về sau ra chiêu càng dồn dập (tối đa nhanh hơn ~40%)
	cd_mult /= 1.0 + 0.06 * minf(power(), 12.0)
	if _slowed:
		cd_mult *= 1.3
	match patterns[_phase]:
		"broadside":   # loạt đại bác mạn tàu
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.8 * cd_mult
				_volleys += 1
				for i in 5:
					var bdir := Vector2.from_angle(dir.angle() + deg_to_rad(lerpf(-40, 40, i / 4.0)))
					_cannon(bdir, 1)
			return Vector2.ZERO
		"burst":
			if _shoot_t <= 0.0 and _volleys < 3 and _burst_left == 0:
				_shoot_t = 0.7 * cd_mult
				_volleys += 1
				_start_burst(7, 10.0)
			return dir * speed * 0.3
		"mortar":
			if _shoot_t <= 0.0 and _volleys < 5:
				_shoot_t = 0.35 * cd_mult
				_volleys += 1
				_mortar(player.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)), 1.0)
			return Vector2.ZERO
		"sweep":   # quét nửa vòng đạn về phía người chơi
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.6 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.3
				for i in 9:
					_fire(dir.angle() + deg_to_rad(lerpf(-55, 55, i / 8.0)), 130.0)
			return dir * speed * 0.4
		"charge":
			return _charge_ai(delta, dir, 0.0, 5.5)
		"ring":
			if _shoot_t <= 0.0:
				_shoot_t = 0.8 * cd_mult
				_attack_anim_t = 0.3
				_fire_ring(16 if rage else 12, randf() * TAU, 105.0)
			return dir * speed * 0.5
		"summon":
			if _shoot_t <= 0.0 and _volleys == 0 and room != null:
				_volleys = 1
				_attack_anim_t = 0.5
				for i in (3 if rage else 2) + int(power() / 4.0):
					var p := global_position + Vector2.from_angle(randf() * TAU) * 40.0
					room.spawn_enemy(data.summon, p)
			return Vector2.ZERO
		"spiral":
			if _shoot_t <= 0.0:
				_shoot_t = 0.07 * cd_mult
				_spiral += 0.3
				_fire(_spiral, 120.0, "orb_water")
				_fire(_spiral + PI, 120.0, "orb_water")
				if rage:
					_fire(_spiral + PI / 2.0, 120.0, "orb_water")
			return Vector2.ZERO
		"volley":  # 3 loạt tên nhắm thẳng
			if _shoot_t <= 0.0 and _volleys < 4:
				_shoot_t = 0.45 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.25
				for i in 5:
					_fire(dir.angle() + deg_to_rad(lerpf(-16, 16, i / 4.0)), 190.0, "arrow")
			return dir * speed * 0.3
		"cannon":  # đạn pháo nổ
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.7 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.3
				var cpos: Vector2 = global_position + dir * radius
				var b := Bullet.new()
				b.setup(false, cpos, dir, 150.0, 2, 3.0, "cannonball")
				get_parent().add_child(b)
				Fx.anim(get_parent(), cpos, "fx/poof.png", 28, 28, 18.0, 0.6)
				if Net.is_online() and Net.is_host():
					Net.send_enemy_event("bullet", {
						"x": cpos.x, "y": cpos.y, "dx": dir.x, "dy": dir.y,
						"spd": 150.0, "dmg": 2, "life": 3.0, "proj": "cannonball",
						"exp": 0.0, "ox": global_position.x, "oy": global_position.y, "muzzle": false,
					}, false)
			return -dir * speed * 0.3 if dist < 90.0 else Vector2.ZERO
		"tails":   # Hồ Tinh: quạt lửa hồ ly theo số đuôi
			if _shoot_t <= 0.0 and _volleys < 3:
				_shoot_t = 0.65 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.35
				var nt := 9 if transformed else 5
				_spiral += 0.4
				for i in nt:
					_fire(_spiral + TAU * i / nt, 105.0, "fireball")
			return dir * speed * 0.3
		"clone":   # Hồ Tinh: phân thân thành bầy cáo ảo
			if _shoot_t <= 0.0 and _volleys == 0 and room != null:
				_volleys = 1
				_attack_anim_t = 0.5
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
				_attack_anim_t = 0.4
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
			return Vector2.ZERO
		"dive":    # Ngư Tinh: lặn xuống, trồi lên dưới chân người chơi tung vòng nước
			match _charge_state:
				"":
					_charge_state = "under"
					_charge_t = 1.3
					_submerged = true
					spr.modulate.a = 0.25
					Fx.particles(get_parent(), global_position, Color(0.5, 0.8, 1.0), 18, 100.0, 0.5, 140.0, 2.5)
				"under":
					_charge_t -= delta
					spr.modulate.a = 0.25
					if randf() < 0.3:
						Fx.particles(get_parent(), global_position + Vector2(randf_range(-14, 14), 6), Color(0.5, 0.8, 1.0), 2, 30.0, 0.4, -40.0, 2.0)
					if _charge_t <= 0.0:
						_charge_state = "rest"
						_charge_t = 0.9
						_submerged = false
						spr.modulate.a = 1.0
						_attack_anim_t = 0.5
						_fire_ring(18 if transformed else 14, randf() * TAU, 110.0, "orb_water")
						Fx.particles(get_parent(), global_position, Color(0.5, 0.8, 1.0), 24, 140.0, 0.6, 160.0, 2.5)
						Fx.shake(get_tree(), 3.0)
					return dir * speed * 2.4
				"rest":
					_charge_t -= delta
					if _charge_t <= 0.0:
						_charge_state = "done"
			return Vector2.ZERO
		"tidal":   # Ngư Tinh: tường nước có 1 khe hở để né
			if _shoot_t <= 0.0 and _volleys < 2:
				_shoot_t = 1.6 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.4
				_tidal_wall()
			return Vector2.ZERO
		"fan":     # quạt gió: quạt đạn rộng và chậm
			if _shoot_t <= 0.0 and _volleys < 2:
				_shoot_t = 0.9 * cd_mult
				_volleys += 1
				_attack_anim_t = 0.4
				for i in 14:
					_fire(dir.angle() + deg_to_rad(lerpf(-75, 75, i / 13.0)), 85.0)
			return Vector2.ZERO
	return Vector2.ZERO


func _start_morph() -> void:
	_morph_t = 1.4
	Sfx.play("boss_morph")
	_burst_left = 0
	_charge_state = ""
	_submerged = false
	spr.modulate.a = 1.0
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
	var anims := {"walk": [[0, 1, 2, 3], 8.0, true], "attack": [[4], 1.0, false], "rage": [[5], 1.0, false], "special": [[6], 1.0, false]}
	spr.sprite_frames = Art.frames(data.sheet2, size2.x, size2.y, anims)
	radius = float(data.get("radius2", radius))
	_shape.radius = radius * 0.8
	spr.position = Vector2(0, radius - size2.y / 2.0)
	_shadow.position = Vector2(0, radius * 0.9)
	_shadow.scale = Vector2(radius / 7.0, radius / 7.0)
	status.head = float(size2.y) - radius - 6.0
	data["patterns"] = data.get("patterns2", data.patterns)
	_phase = -1
	_phase_t = 0.0
	_volleys = 0
	Fx.burst(get_parent(), global_position, Color(0.75, 0.35, 1.0), 90.0, 0.6)
	Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 18.0, 2.0, 0.0, Color(0.8, 0.5, 1.0))
	Fx.particles(get_parent(), global_position, Color(0.6, 0.25, 0.8), 40, 160.0, 0.8, -20.0, 3.0)
	Fx.shake(get_tree(), 8.0)
	get_tree().call_group("hud", "show_banner", "%s hiện nguyên hình: %s!" % [data.name, data.get("form2", "")])
	data["name"] = "%s (%s)" % [data.name, data.get("form2", "")]
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
	_rage_t = 1.5
	_mat.set_shader_parameter("flash_color", Color(1.0, 0.25, 0.2))
	_flash = 1.0
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
	if _rage_n % 2 == 1:
		# chướng khí: đám mây độc lan ra ngay dưới chân người chơi
		var m := Miasma.new()
		m.position = player.global_position
		m.from_player = false
		m.color = Color(0.45, 0.85, 0.3) if not EnemyData.chapter(level).get("modern", false) else Color(0.75, 0.8, 0.5)
		get_parent().add_child(m)
		Fx.float_text(get_parent(), global_position + Vector2(0, -radius - 20), "Chướng khí!", Color(0.6, 1.0, 0.4), 13)
		if Net.is_online() and Net.is_host():
			Net.send_enemy_event("miasma", {"x": m.position.x, "y": m.position.y, "r": m.color.r, "g": m.color.g, "b": m.color.b}, false)
	else:
		# hỏa tiễn: quạt 5 quả cầu lửa gây cháy
		var a: float = (player.global_position - global_position).angle()
		for i in 5:
			_fire(a + deg_to_rad(lerpf(-30, 30, i / 4.0)), 140.0, "fireball")
		_attack_anim_t = 0.4


func _start_special(sp: String) -> void:
	_special_used = true
	_submerged = false
	spr.modulate.a = 1.0
	_charge_state = ""
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


func take_damage(amount: int, knock := Vector2.ZERO) -> void:
	if dead or _spawn_t > 0.0:
		return
	if _morph_t > 0.0 or _submerged:
		return
	if is_replica:
		if net_id > 0:
			Net.send_enemy_event("dmg_req", {"id": net_id, "dmg": amount, "kx": knock.x, "ky": knock.y}, true)
		_flash = 1.0
		if not is_boss():
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
		dmg = int(round(float(amount) * dmg_mult))
		var forced_crit: bool = player.has_method("is_kinetic_ready") and player.is_kinetic_ready()
		if forced_crit:
			dmg = (dmg + 8) * 2
			crit = true
		elif randf() < player.crit_chance():
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
		_hp_bar_t = 3.0
		queue_redraw()
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
	Fx.float_text(get_parent(), global_position + Vector2(0, -radius - 6.0), ("%d!" % dmg) if crit else str(dmg), Color(1, 1, 1) if dmg < 10 else Color(1, 0.85, 0.3), 14 if dmg < 10 else 18)
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
		_hp_bar_t = 3.0
		queue_redraw()
	Fx.float_text(get_parent(), global_position + Vector2(randf_range(-6, 6), -radius - 6.0), str(dmg), Color(1, 0.6, 0.25) if kind == "burn" else Color(0.6, 1.0, 0.35), 11)
	if hp <= 0:
		die()


func apply_status(kind: String, duration: float) -> void:
	if is_replica and net_id > 0:
		Net.send_enemy_event("status_req", {"id": net_id, "kind": kind, "dur": duration}, true)
	if not dead and status != null:
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
	remove_from_group("enemies")
	remove_from_group("boss")
	Fx.anim(get_parent(), global_position, "fx/poof.png", 28, 28, 16.0, radius / 7.0)
	Fx.particles(get_parent(), global_position, Color(0.85, 0.3, 0.3), 10, 90.0, 0.5, 120.0, 2.0)
	if is_boss() and data.get("id", "") == "do_cat":
		get_tree().call_group("hud", "show_banner", "Bắt sống Đờ Cát tại hầm chỉ huy!")
	if is_boss():
		Fx.hitstop(get_tree(), 0.075)
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
	var pieces: int = 10 if is_boss() else data.coins * (3 if elite else 1)
	for i in pieces:
		_spawn_pickup("coin", 3 if is_boss() else 1)
	for i in randi_range(1, 2):
		_spawn_pickup("energy", 5)
	if spawn_shared_loot and not is_boss() and randf() < 0.04:
		_spawn_shared_pickup("potion", 2)
	var is_legend: bool = bool(data.get("legend", false))
	var is_folk: bool = EnemyData.FOLK.has(kind)
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	for mid in MaterialData.roll_enemy_drops(is_boss(), is_legend, is_folk, elite, modern):
		_spawn_material(str(mid))


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


func _spawn_pickup(k: String, amount: int) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = global_position
	get_parent().add_child(p)


func _draw() -> void:
	if dead or is_boss() or _hp_bar_t <= 0.0 or hp >= max_hp or max_hp <= 0:
		return
	var bw: float = 24.0 if elite else 18.0
	var bh: float = 3.0
	var pos := Vector2(-bw / 2.0, -radius - 12.0)
	var a: float = clampf(_hp_bar_t / 0.4, 0.0, 1.0)
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos - Vector2(1.0, 1.0), Vector2(bw + 2.0, bh + 2.0)), Color(0.06, 0.02, 0.04, 0.92 * a))
	draw_rect(Rect2(pos, Vector2(bw, bh)), Color(0.24, 0.07, 0.09, 0.92 * a))
	var fw: float = bw * ratio
	if fw > 0.0:
		draw_rect(Rect2(pos, Vector2(fw, bh)), Color(0.86, 0.18, 0.22, a))
		draw_rect(Rect2(pos, Vector2(fw, 1.0)), Color(1.0, 0.48, 0.46, a))
