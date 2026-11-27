extends Node2D
## Võ Đài Tỷ Thí tại Doanh Trại: hỗ trợ tập đối kháng với Võ Sư Thiên Nam (Solo) hoặc Tỷ Thí LAN không gây tử vong.

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const ARENA_RECT := Rect2(1000, 520, 280, 160)

var active: bool = false
var bot_dummy: Node2D = null
var _t: float = 0.0


static func is_in_arena(pos: Vector2) -> bool:
	return ARENA_RECT.has_point(pos)


func _ready() -> void:
	add_to_group("sparring_arena")
	z_index = -1


func _process(delta: float) -> void:
	_t += delta
	if active:
		queue_redraw()


func toggle_sparring() -> bool:
	active = not active
	var par: Node = get_parent() if get_parent() != null else self
	var center: Vector2 = ARENA_RECT.get_center()
	if active:
		Sfx.play("chest_open")
		Fx.float_text(par, center + Vector2(0, -32), "Bắt đầu Tỷ Thí!", Color(1.0, 0.86, 0.32), 16)
		Fx.burst(par, center, Color(1.0, 0.45, 0.25), 55.0, 0.45)
		if is_inside_tree():
			get_tree().call_group("hud", "show_banner", "Bắt đầu Tỷ Thí!")
		var is_solo: bool = Net == null or not Net.is_online() or Net.player_count() <= 1
		if is_solo:
			_spawn_bot_dummy()
	else:
		_despawn_bot_dummy()
		_heal_all_players()
		Sfx.play("pickup_weapon")
		Fx.float_text(par, center + Vector2(0, -32), "Kết thúc Tỷ Thí!", Color(0.55, 0.95, 0.72), 16)
		if is_inside_tree():
			get_tree().call_group("hud", "show_banner", "Kết thúc Tỷ Thí!")
	queue_redraw()
	return active


func _spawn_bot_dummy() -> void:
	_despawn_bot_dummy()
	var dummy := SparringDummy.new()
	dummy.arena = self
	dummy.position = ARENA_RECT.get_center() + Vector2(65, 0)
	var par: Node = get_parent() if get_parent() != null else self
	par.add_child(dummy)
	bot_dummy = dummy


func _despawn_bot_dummy() -> void:
	if bot_dummy != null and is_instance_valid(bot_dummy):
		bot_dummy.queue_free()
	bot_dummy = null


func _heal_all_players() -> void:
	if not is_inside_tree():
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			_heal_player_full(p)


func _heal_player_full(p: Node) -> void:
	if p == null or not is_instance_valid(p):
		return
	p.set("hp", int(p.get("max_hp")))
	p.set("armor", int(p.get("max_armor")))
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()


func apply_non_lethal_hit(target_player: Node, dmg: int, attacker_name: String = "") -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var par: Node = get_parent() if get_parent() != null else self
	var hit_dmg: int = maxi(1, dmg)
	var cur_hp: int = int(target_player.get("hp"))
	var next_hp: int = maxi(1, cur_hp - hit_dmg)
	target_player.set("hp", next_hp)
	if target_player.has_signal("stats_changed"):
		target_player.stats_changed.emit()
	Sfx.play("player_hurt")
	var tpos: Vector2 = (target_player as Node2D).global_position if target_player is Node2D else ARENA_RECT.get_center()
	Fx.float_text(par, tpos + Vector2(0, -22), "-%d" % hit_dmg, Color(1.0, 0.42, 0.32), 14)
	Fx.particles(par, tpos, Color(1.0, 0.42, 0.32), 6, 65.0, 0.35)

	if next_hp <= 1:
		var winner: String = attacker_name if attacker_name != "" else "Đối thủ"
		_declare_winner(winner, target_player)


func _declare_winner(winner: String, loser: Node = null) -> void:
	var par: Node = get_parent() if get_parent() != null else self
	var center: Vector2 = ARENA_RECT.get_center()
	var msg: String = "Chiến thắng Tỷ Thí: %s!" % winner
	Fx.float_text(par, center + Vector2(0, -40), msg, Color(1.0, 0.90, 0.32), 17)
	if is_inside_tree():
		get_tree().call_group("hud", "show_banner", msg)
	Sfx.play("chest_open")
	for off in [Vector2(-55, -25), Vector2(0, -40), Vector2(55, -25)]:
		Fx.burst(par, center + off, Color(1.0, 0.86, 0.28), 44.0, 0.55)
		Fx.particles(par, center + off, Color(1.0, 0.42, 0.38), 14, 110.0, 0.65, 40.0, 2.0, 180.0, Vector2.UP, Color(1.0, 0.92, 0.42))
	_heal_all_players()
	if loser != null and is_instance_valid(loser):
		_heal_player_full(loser)
	if bot_dummy != null and is_instance_valid(bot_dummy):
		bot_dummy.set("hp", int(bot_dummy.get("max_hp")))
		bot_dummy.queue_redraw()


func _draw() -> void:
	if not active:
		return
	var pulse: float = 0.72 + 0.28 * sin(_t * 4.5)
	draw_rect(ARENA_RECT, Color(0.55, 0.12, 0.14, 0.14))
	var inner_rect: Rect2 = ARENA_RECT.grow(-5.0)
	draw_rect(inner_rect, Color(1.0, 0.82, 0.32, 0.28 * pulse), false, 1.5)
	draw_rect(ARENA_RECT, Color(0.95, 0.26, 0.22, 0.85 * pulse), false, 3.0)
	draw_rect(ARENA_RECT.grow(2.0), Color(1.0, 0.86, 0.34, 0.65 * pulse), false, 1.4)

	# 4 cột võ đài góc
	for corner in [
		ARENA_RECT.position,
		Vector2(ARENA_RECT.end.x, ARENA_RECT.position.y),
		Vector2(ARENA_RECT.position.x, ARENA_RECT.end.y),
		ARENA_RECT.end,
	]:
		draw_circle(corner, 5.5, Color(0.95, 0.26, 0.22, 0.95))
		draw_circle(corner, 3.0, Color(1.0, 0.88, 0.36, 0.95))

	Art.draw_text(self, Vector2(ARENA_RECT.get_center().x, ARENA_RECT.position.y - 10.0), "VÕ ĐÀI TỶ THÍ", 14, Color(1.0, 0.88, 0.38))


class SparringDummy extends StaticBody2D:
	const ArtRef = preload("res://scripts/art/art.gd")
	const FxRef = preload("res://scripts/effects/fx.gd")

	var arena: Node2D = null
	var dead: bool = false
	var radius: float = 12.0
	var hp: int = 120
	var max_hp: int = 120
	var last_hit_crit: bool = false
	var _t: float = 0.0
	var _shoot_cd: float = 1.4
	var _flash_t: float = 0.0
	var _wobble_t: float = 0.0

	func _ready() -> void:
		add_to_group("sparring_target")
		add_to_group("enemies")
		collision_layer = 4
		collision_mask = 0
		z_index = 2
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(0, -6)
		add_child(cs)

	func hurtbox_rect() -> Rect2:
		return Rect2(global_position + Vector2(-12.0, -24.0), Vector2(24.0, 28.0))

	func hurtbox_center() -> Vector2:
		return global_position + Vector2(0.0, -8.0)

	func closest_point_on_hurtbox(pt: Vector2) -> Vector2:
		var r: Rect2 = hurtbox_rect()
		return Vector2(clampf(pt.x, r.position.x, r.end.x), clampf(pt.y, r.position.y, r.end.y))

	func distance_to_hurtbox(pt: Vector2) -> float:
		return pt.distance_to(closest_point_on_hurtbox(pt))

	func is_spawning() -> bool:
		return false

	func _process(delta: float) -> void:
		_t += delta
		_flash_t = maxf(0.0, _flash_t - delta)
		_wobble_t = maxf(0.0, _wobble_t - delta)
		if arena == null or not is_instance_valid(arena) or not bool(arena.get("active")):
			return
		_shoot_cd -= delta
		if _shoot_cd <= 0.0:
			_shoot_cd = 1.4
			_fire_training_orb()
		queue_redraw()

	func _fire_training_orb() -> void:
		var target: Node2D = Global.local_player() as Node2D
		if target == null or not is_instance_valid(target):
			return
		if target.global_position.distance_to(global_position) > 360.0:
			return
		var dir: Vector2 = (target.global_position - global_position).normalized()
		if dir.length_squared() < 0.01:
			dir = Vector2.LEFT
		var orb := TrainingOrb.new()
		orb.arena = arena
		orb.dir = dir
		orb.position = global_position + Vector2(0, -8) + dir * 14.0
		var par: Node = get_parent() if get_parent() != null else arena
		par.add_child(orb)

	func take_damage(amount: int, _knock := Vector2.ZERO) -> void:
		var dmg: int = maxi(1, amount)
		hp = maxi(1, hp - dmg)
		_flash_t = 0.16
		_wobble_t = 0.25
		last_hit_crit = false
		Sfx.play("hit_flesh")
		var par: Node = get_parent() if get_parent() != null else self
		FxRef.float_text(par, global_position + Vector2(0, -28), str(dmg), Color(1.0, 0.92, 0.48), 14)
		FxRef.particles(par, global_position + Vector2(0, -8), Color(1.0, 0.72, 0.35), 6, 70.0, 0.35)
		if hp <= 1:
			var lp: Node = Global.local_player()
			var p_name: String = str(Global.settings.get("player_name", "Anh Hùng")) if Global != null else "Anh Hùng"
			if lp != null and is_instance_valid(lp) and str(lp.get("hero_id")) != "" and p_name == "":
				p_name = str(lp.get("hero_id"))
			if arena != null and arena.has_method("_declare_winner"):
				arena._declare_winner(p_name, null)
			hp = max_hp
		queue_redraw()

	func dot_damage(amount: int, _kind: String) -> void:
		take_damage(amount)

	func apply_status(_kind: String, _duration: float = 2.0) -> void:
		pass

	func apply_stun(_t_stun: float) -> void:
		var par: Node = get_parent() if get_parent() != null else self
		FxRef.float_text(par, global_position + Vector2(0, -34), "Choáng!", Color(1.0, 0.95, 0.5), 11)

	func _draw() -> void:
		var bob: float = sin(_t * 4.0) * 1.5
		var lean: float = sin(_t * 36.0) * 2.5 if _wobble_t > 0.0 else 0.0
		var body_col: Color = Color(1.0, 0.95, 0.78) if _flash_t > 0.0 else Color(0.86, 0.24, 0.24)
		var trim_col: Color = Color(1.0, 0.86, 0.35)
		# Bóng dưới chân
		draw_circle(Vector2(0, 6), 10.0, Color(0.08, 0.05, 0.12, 0.45))
		# Thân Võ Sư Thiên Nam
		draw_rect(Rect2(-7 + lean, -14 + bob, 14, 18), body_col)
		draw_rect(Rect2(-7 + lean, -14 + bob, 14, 18), trim_col, false, 1.2)
		# Đai vàng & đầu + khăn đỏ
		draw_rect(Rect2(-7 + lean, -4 + bob, 14, 3), trim_col)
		draw_circle(Vector2(lean, -20 + bob), 6.5, Color(0.96, 0.80, 0.64))
		draw_rect(Rect2(-6 + lean, -25 + bob, 12, 3), Color(0.88, 0.20, 0.22))
		draw_circle(Vector2(-2.5 + lean, -20 + bob), 1.0, Color(0.14, 0.10, 0.16))
		draw_circle(Vector2(2.5 + lean, -20 + bob), 1.0, Color(0.14, 0.10, 0.16))
		# Thanh máu trên đầu
		var bw: float = 34.0
		var frac: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
		draw_rect(Rect2(-bw * 0.5, -33, bw, 4), Color(0.1, 0.08, 0.14, 0.85))
		draw_rect(Rect2(-bw * 0.5, -33, bw * frac, 4), Color(1.0, 0.78, 0.28))
		ArtRef.draw_text(self, Vector2(0, -37), "Võ Sư Thiên Nam", 10, Color(1.0, 0.92, 0.62))


class TrainingOrb extends Area2D:
	const FxRef = preload("res://scripts/effects/fx.gd")

	var arena: Node2D = null
	var dir: Vector2 = Vector2.RIGHT
	var speed: float = 115.0
	var damage: int = 2
	var life: float = 2.4
	var _t: float = 0.0
	var _done: bool = false

	func _ready() -> void:
		add_to_group("enemy_bullets")
		collision_layer = 0
		collision_mask = 1 | 2
		monitorable = false
		z_index = 4
		var shape := CircleShape2D.new()
		shape.radius = 5.0
		var cs := CollisionShape2D.new()
		cs.shape = shape
		add_child(cs)
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		life -= delta
		if life <= 0.0:
			destroy()
			return
		position += dir * speed * delta
		queue_redraw()

	func _on_body_entered(body: Node) -> void:
		if _done or body == null:
			return
		if body.is_in_group("player"):
			if arena != null and arena.has_method("apply_non_lethal_hit"):
				arena.apply_non_lethal_hit(body, damage, "Võ Sư Thiên Nam")
			destroy()
		elif body is TileMapLayer or body is StaticBody2D:
			destroy()

	func destroy() -> void:
		if _done:
			return
		_done = true
		if is_inside_tree() and get_parent() != null:
			FxRef.particles(get_parent(), global_position, Color(1.0, 0.76, 0.28), 5, 55.0, 0.28)
		queue_free()

	func _draw() -> void:
		var r: float = 4.8 + sin(_t * 14.0) * 0.6
		draw_circle(Vector2.ZERO, r + 2.0, Color(1.0, 0.45, 0.22, 0.35))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.84, 0.32))
		draw_circle(Vector2.ZERO, r * 0.45, Color(1.0, 0.98, 0.84))
