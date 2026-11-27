extends StaticBody2D
## Nỏ Thần Cổ Loa — Trụ tâm cần bảo vệ trong chế độ Thủ Thành Cổ Loa (v3.0.0).

signal damaged(cur_hp: int, max_hp: int)
signal destroyed

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const CORE_SPRITE_PATH := "res://assets/sprites/world/coloa_core.png"

var max_hp: int = 250
var hp: int = 250
var radius: float = 22.0
var _t: float = 0.0
var _flash: float = 0.0

var _spr: Sprite2D = null
var _light: PointLight2D = null
var _destroyed: bool = false


func _ready() -> void:
	add_to_group("co_loa_core")
	collision_layer = 2
	collision_mask = 0
	z_index = 1

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	cs.shape = shape
	add_child(cs)

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0.0, 12.0)
	sh.scale = Vector2(3.2, 1.8)
	sh.z_index = -2
	add_child(sh)

	if ResourceLoader.exists(CORE_SPRITE_PATH):
		_spr = Sprite2D.new()
		_spr.texture = Art.tex("world/coloa_core.png")
		_spr.position = Vector2(0.0, -6.0)
		add_child(_spr)

	_light = Art.light(Color(0.98, 0.72, 0.30), 1.6, 1.1)
	_light.position = Vector2(0.0, -4.0)
	add_child(_light)


func setup(players_count: int = 1) -> void:
	var pc: int = maxi(1, players_count)
	max_hp = 250 + (pc - 1) * 75
	hp = max_hp
	_destroyed = false
	_flash = 0.0
	queue_redraw()


func take_damage(amount: int) -> void:
	if _destroyed or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	_flash = 1.0
	damaged.emit(hp, max_hp)
	queue_redraw()
	if is_inside_tree() and get_parent() != null:
		Fx.float_text(get_parent(), global_position + Vector2(0.0, -28.0), "-%d" % amount, Color(1.0, 0.42, 0.36), 13)
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
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -28.0), "+%d Nỏ Thần" % gained, Color(0.55, 1.0, 0.68), 12)
	return gained


func hurtbox_center() -> Vector2:
	return global_position + Vector2(0.0, -4.0)


func distance_to_hurtbox(pt: Vector2) -> float:
	return maxf(0.0, pt.distance_to(hurtbox_center()) - radius)


func _process(delta: float) -> void:
	_t += delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
	if _spr != null and is_instance_valid(_spr):
		_spr.modulate = Color(1.0, 0.45, 0.35).lerp(Color.WHITE, 1.0 - _flash) if _flash > 0.0 else Color.WHITE
	if not _destroyed and is_inside_tree() and (Net == null or not Net.is_online() or Net.is_host()):
		for b in get_tree().get_nodes_in_group("enemy_bullets"):
			if not is_instance_valid(b):
				continue
			if (b as Node2D).global_position.distance_to(global_position) <= radius + 4.0:
				var dmg: int = maxi(1, int(b.get("damage")))
				take_damage(dmg)
				if b.has_method("destroy"):
					b.destroy()
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * 3.2)
	# Vòng hào quang Đông Sơn đồng cổ
	draw_circle(Vector2.ZERO, radius + 6.0, Color(0.88, 0.64, 0.22, 0.10 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, radius + 4.0 + pulse * 2.0, 0.0, TAU, 32, Color(0.98, 0.78, 0.32, 0.45 + 0.25 * pulse), 1.6)
	draw_arc(Vector2.ZERO, radius - 4.0, 0.0, TAU, 24, Color(0.45, 0.92, 0.88, 0.35), 1.2)
	for i in 8:
		var ang: float = float(i) * TAU / 8.0 + _t * 0.45
		var p1: Vector2 = Vector2.from_angle(ang) * (radius - 3.0)
		var p2: Vector2 = Vector2.from_angle(ang) * (radius + 3.0)
		draw_line(p1, p2, Color(0.98, 0.82, 0.36, 0.45), 1.2)

	# Hình vẽ dự phòng nếu chưa có sprite coloa_core.png
	if _spr == null:
		var base_col: Color = Color(1.0, 0.45, 0.35) if _flash > 0.2 else Color(0.74, 0.54, 0.20)
		draw_circle(Vector2(0.0, -2.0), 17.0, Color(0.24, 0.16, 0.08))
		draw_circle(Vector2(0.0, -2.0), 14.0, base_col)
		draw_circle(Vector2(0.0, -2.0), 7.0, Color(0.32, 0.92, 0.86, 0.85))
		draw_arc(Vector2(0.0, -2.0), 14.0, 0.0, TAU, 24, Color(1.0, 0.88, 0.44), 1.5)

	# Thanh máu Nỏ Thần Cổ Loa phía trên
	var bw: float = 84.0
	var bx: float = -bw * 0.5
	var by: float = -34.0
	var ratio: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	var bar_col: Color = Color(0.35, 0.92, 0.62) if ratio > 0.5 else (Color(1.0, 0.78, 0.26) if ratio > 0.25 else Color(0.96, 0.30, 0.28))
	draw_rect(Rect2(bx - 1.0, by - 1.0, bw + 2.0, 7.0), Color(0.05, 0.02, 0.04, 0.9))
	draw_rect(Rect2(bx, by, bw, 5.0), Color(0.22, 0.10, 0.10, 0.9))
	draw_rect(Rect2(bx, by, bw * ratio, 5.0), bar_col)
	Art.draw_text(self, Vector2(0.0, by - 4.0), "Nỏ Thần Cổ Loa: %d/%d" % [hp, max_hp], 11, Color(1.0, 0.92, 0.68), true)
