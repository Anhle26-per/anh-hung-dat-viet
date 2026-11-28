extends StaticBody2D
## Nỏ Thần Cổ Loa — Đền thờ Nỏ Thần Kim Quy: tự phóng tia hộ vệ & cho phép tu sửa bằng xu (v3.0.0).

signal damaged(cur_hp: int, max_hp: int)
signal destroyed

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Interactable = preload("res://scripts/entities/interactable.gd")

const CORE_SPRITE_PATH := "res://assets/sprites/world/coloa_core.png"
const SELF_DEFENSE_RANGE := 180.0
const SELF_DEFENSE_CD := 2.8
const MANUAL_REPAIR_COST := 20
const MANUAL_REPAIR_HP := 35

var max_hp: int = 250
var hp: int = 250
var radius: float = 24.0
var _t: float = 0.0
var _flash: float = 0.0
var _shot_cd: float = 1.6
var _pulse_shot: float = 0.0

var _spr: Node2D = null
var _light: PointLight2D = null
var _repair_pad: Node2D = null
var _destroyed: bool = false


class CoreRepairInteractable extends "res://scripts/entities/interactable.gd":
	var core_ref: Node = null

	func _ready() -> void:
		radius = 44.0

	func hint() -> String:
		if core_ref == null or int(core_ref.get("hp")) >= int(core_ref.get("max_hp")):
			return ""
		return "Tu sửa Nỏ Thần +%d máu (%dxu)" % [MANUAL_REPAIR_HP, MANUAL_REPAIR_COST]

	func interact() -> void:
		if core_ref != null and core_ref.has_method("manual_repair"):
			core_ref.manual_repair()

	func _process(delta: float) -> void:
		enabled = core_ref != null and not bool(core_ref.get("_destroyed")) and int(core_ref.get("hp")) < int(core_ref.get("max_hp"))
		super._process(delta)

	func _draw() -> void:
		draw_hint(-54.0)


func _ready() -> void:
	add_to_group("co_loa_core")
	collision_layer = 2
	collision_mask = 0
	z_index = 1

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	cs.shape = shape
	add_child(cs)

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0.0, 14.0)
	sh.scale = Vector2(3.6, 2.0)
	sh.z_index = -2
	add_child(sh)

	if ResourceLoader.exists(CORE_SPRITE_PATH):
		var tex: Texture2D = Art.tex("world/coloa_core.png")
		if tex != null and tex.get_width() >= 256:
			var anim := AnimatedSprite2D.new()
			anim.sprite_frames = Art.strip("world/coloa_core.png", 64, 64, 6.0, true)
			anim.play("play")
			anim.position = Vector2(0.0, -8.0)
			add_child(anim)
			_spr = anim
		else:
			var st := Sprite2D.new()
			st.texture = tex
			st.position = Vector2(0.0, -8.0)
			add_child(st)
			_spr = st

	_light = Art.light(Color(0.38, 0.96, 0.84), 2.0, 1.15)
	_light.position = Vector2(0.0, -8.0)
	add_child(_light)

	_repair_pad = CoreRepairInteractable.new()
	_repair_pad.core_ref = self
	add_child(_repair_pad)


func setup(players_count: int = 1) -> void:
	var pc: int = maxi(1, players_count)
	max_hp = 250 + (pc - 1) * 75
	hp = max_hp
	_destroyed = false
	_flash = 0.0
	_shot_cd = 1.6
	queue_redraw()


func manual_repair() -> bool:
	if _destroyed or hp >= max_hp or Global == null:
		return false
	if Global.run_coins < MANUAL_REPAIR_COST:
		if Sfx != null:
			Sfx.play("buy_fail")
		if get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -34.0), "Cần %dxu!" % MANUAL_REPAIR_COST, Color(1.0, 0.45, 0.4), 12)
		return false
	Global.run_coins -= MANUAL_REPAIR_COST
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp) and lp.has_signal("stats_changed"):
		lp.stats_changed.emit()
	repair(MANUAL_REPAIR_HP)
	if Sfx != null:
		Sfx.play("forge")
	if get_parent() != null:
		Fx.burst(get_parent(), global_position, Color(0.45, 0.96, 0.85), 42.0, 0.42)
	return true


func take_damage(amount: int) -> void:
	if _destroyed or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	_flash = 1.0
	damaged.emit(hp, max_hp)
	queue_redraw()
	if is_inside_tree() and get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0.0, -34.0), "-%d" % amount, Color(1.0, 0.42, 0.36), 13)
		Fx.particles(get_parent(), global_position, Color(1.0, 0.75, 0.3), 5, 60.0, 0.35)
	if Sfx != null:
		Sfx.play("hit_metal")
	if hp <= 0:
		_destroyed = true
		if is_inside_tree() and get_parent() != null:
			Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 16.0, 1.8)
			Fx.burst(get_parent(), global_position, Color(1.0, 0.55, 0.25), 76.0, 0.65)
			Fx.shake(get_tree(), 6.5)
		if Sfx != null:
			Sfx.play("explode")
		destroyed.emit()


func repair(amount: int) -> int:
	if _destroyed or amount <= 0 or hp >= max_hp:
		return 0
	var before: int = hp
	hp = mini(max_hp, hp + amount)
	var gained: int = hp - before
	if gained > 0:
		queue_redraw()
		if is_inside_tree() and get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -34.0), "+%d Nỏ Thần" % gained, Color(0.55, 1.0, 0.68), 12)
	return gained


func hurtbox_center() -> Vector2:
	return global_position + Vector2(0.0, -6.0)


func distance_to_hurtbox(pt: Vector2) -> float:
	return maxf(0.0, pt.distance_to(hurtbox_center()) - radius)


func _process(delta: float) -> void:
	_t += delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
	if _pulse_shot > 0.0:
		_pulse_shot = maxf(0.0, _pulse_shot - delta * 3.0)
	if _spr != null and is_instance_valid(_spr):
		_spr.modulate = Color(1.0, 0.45, 0.35).lerp(Color.WHITE, 1.0 - _flash) if _flash > 0.0 else Color.WHITE
		var sc_x: float = 1.0 + _pulse_shot * 0.08
		_spr.scale = Vector2(sc_x, 1.0 - _pulse_shot * 0.06)
	if _light != null:
		_light.energy = 1.05 + 0.22 * sin(_t * 3.6) + _pulse_shot * 0.55

	var is_auth: bool = not _destroyed and is_inside_tree() and (Net == null or not Net.is_online() or Net.is_host())
	if is_auth:
		for b in get_tree().get_nodes_in_group("enemy_bullets"):
			if not is_instance_valid(b):
				continue
			if (b as Node2D).global_position.distance_to(global_position) <= radius + 4.0:
				var dmg: int = maxi(1, int(b.get("damage")))
				take_damage(dmg)
				if b.has_method("destroy"):
					b.destroy()
		_tick_self_defense(delta)
	queue_redraw()


func _tick_self_defense(delta: float) -> void:
	var arena: Node = get_tree().get_first_node_in_group("co_loa_defense")
	if arena != null and str(arena.get("state")) != "fighting":
		return
	_shot_cd -= delta
	if _shot_cd > 0.0:
		return
	var target: Node = null
	var best_d: float = SELF_DEFENSE_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to((e as Node2D).global_position)
		if d <= best_d:
			best_d = d
			target = e
	if target == null:
		return
	_shot_cd = SELF_DEFENSE_CD
	_pulse_shot = 1.0
	if get_parent() == null:
		return
	var tpos: Vector2 = target.hurtbox_center() if target.has_method("hurtbox_center") else (target as Node2D).global_position
	var base_dir: Vector2 = (tpos - global_position).normalized()
	if base_dir.length_squared() < 0.001:
		base_dir = Vector2.RIGHT
	for off in [-0.12, 0.0, 0.12]:
		var b := Bullet.new()
		var sdir: Vector2 = base_dir.rotated(off)
		b.setup(true, global_position + Vector2(0.0, -14.0) + sdir * 14.0, sdir, 360.0, 7, 1.0, "arrow")
		b.pierce = 2
		b.color = Color(0.45, 1.0, 0.90)
		b.knock = 75.0
		get_parent().add_child(b)
	Fx.burst(get_parent(), global_position + Vector2(0.0, -10.0), Color(0.45, 1.0, 0.90), 34.0, 0.3)
	if Sfx != null:
		Sfx.play("arrow")


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * 3.2)
	# Vòng hào quang Đông Sơn đồng cổ & ánh ngọc Kim Quy
	draw_circle(Vector2.ZERO, radius + 8.0, Color(0.88, 0.64, 0.22, 0.10 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, radius + 6.0 + pulse * 2.0, 0.0, TAU, 36, Color(0.98, 0.78, 0.32, 0.52 + 0.25 * pulse), 1.6)
	draw_arc(Vector2.ZERO, radius - 2.0, 0.0, TAU, 28, Color(0.38, 0.96, 0.88, 0.42 + _pulse_shot * 0.4), 1.3)
	for i in 8:
		var ang: float = float(i) * TAU / 8.0 + _t * 0.45
		var p1: Vector2 = Vector2.from_angle(ang) * (radius - 2.0)
		var p2: Vector2 = Vector2.from_angle(ang) * (radius + 4.0)
		draw_line(p1, p2, Color(0.98, 0.82, 0.36, 0.5), 1.2)

	if _spr == null:
		var base_col: Color = Color(1.0, 0.45, 0.35) if _flash > 0.2 else Color(0.74, 0.54, 0.20)
		draw_circle(Vector2(0.0, -4.0), 17.0, Color(0.24, 0.16, 0.08))
		draw_circle(Vector2(0.0, -4.0), 14.0, base_col)
		draw_circle(Vector2(0.0, -4.0), 7.0, Color(0.32, 0.92, 0.86, 0.85))
		draw_arc(Vector2(0.0, -4.0), 14.0, 0.0, TAU, 24, Color(1.0, 0.88, 0.44), 1.5)

	# Thanh máu Nỏ Thần Cổ Loa phía trên
	var bw: float = 88.0
	var bx: float = -bw * 0.5
	var by: float = -44.0
	var ratio: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	var bar_col: Color = Color(0.35, 0.92, 0.62) if ratio > 0.5 else (Color(1.0, 0.78, 0.26) if ratio > 0.25 else Color(0.96, 0.30, 0.28))
	draw_rect(Rect2(bx - 1.0, by - 1.0, bw + 2.0, 7.0), Color(0.05, 0.02, 0.04, 0.92))
	draw_rect(Rect2(bx, by, bw, 5.0), Color(0.22, 0.10, 0.10, 0.92))
	draw_rect(Rect2(bx, by, bw * ratio, 5.0), bar_col)
	Art.draw_text(self, Vector2(0.0, by - 4.0), "Nỏ Thần Cổ Loa: %d/%d" % [hp, max_hp], 11, Color(1.0, 0.92, 0.68), true)
