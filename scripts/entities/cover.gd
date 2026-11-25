extends StaticBody2D
## Vật cản che đạn thuần Việt trong phòng:
##   - Cổ/Trung đại: chum gốm ("pot", vỡ sau 3 đòn), bia đá ("stele", không vỡ), cột đá ("pillar"), tường ngắn ("wall_h"/"wall_v")
##   - Cận/Hiện đại: thùng gỗ ("crate", vỡ sau 4 đòn), ụ bao cát ("sandbag", không vỡ)
##   - Chiến thuật: thùng thuốc nổ ("barrel_boom", vỡ sẽ nổ tung gây sát thương & cháy!)

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")

var kind: String = "pot"
var destructible: bool = true
var hp: int = 3
var max_hp: int = 3
var radius: float = 7.5

var _spr: Sprite2D = null
var _dead: bool = false
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	add_to_group("cover")
	if kind == "pot":
		destructible = true
		max_hp = 3
		radius = 7.0
	elif kind == "crate":
		destructible = true
		max_hp = 4
		radius = 7.5
	elif kind == "barrel_boom":
		destructible = true
		max_hp = 2
		radius = 8.0
	elif kind == "stele":
		destructible = false
		max_hp = 999
		radius = 7.5
	elif kind == "sandbag":
		destructible = false
		max_hp = 999
		radius = 9.0
	elif kind == "wall_h":
		destructible = false
		max_hp = 999
		radius = 22.0
	elif kind == "wall_v":
		destructible = false
		max_hp = 999
		radius = 20.0
	elif kind == "pillar":
		destructible = false
		max_hp = 999
		radius = 10.0
	hp = max_hp

	var cs := CollisionShape2D.new()
	if kind == "crate":
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 10)
		cs.shape = r
	elif kind == "sandbag":
		var r2 := RectangleShape2D.new()
		r2.size = Vector2(18, 10)
		cs.shape = r2
	elif kind == "wall_h":
		var r3 := RectangleShape2D.new()
		r3.size = Vector2(46, 16)
		cs.shape = r3
	elif kind == "wall_v":
		var r4 := RectangleShape2D.new()
		r4.size = Vector2(16, 42)
		cs.shape = r4
	elif kind == "pillar":
		var r5 := RectangleShape2D.new()
		r5.size = Vector2(18, 18)
		cs.shape = r5
	else:
		var c := CircleShape2D.new()
		c.radius = radius
		cs.shape = c
	add_child(cs)

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 6 if kind in ["wall_h", "wall_v", "pillar"] else 4)
	sh.scale = Vector2(2.8, 1.1) if kind == "wall_h" else (Vector2(1.4, 1.1) if kind in ["sandbag", "pillar", "wall_v"] else Vector2(1.1, 0.9))
	sh.z_index = -1
	add_child(sh)

	if kind in ["pot", "crate", "stele", "sandbag"]:
		_spr = Sprite2D.new()
		_spr.texture = Art.tex("world/%s.png" % kind)
		if kind == "stele":
			_spr.scale = Vector2(0.75, 0.75)
			_spr.position = Vector2(0, -7)
		else:
			_spr.position = Vector2(0, -4)
		add_child(_spr)


func _process(delta: float) -> void:
	if kind == "barrel_boom":
		_t += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		"wall_h":
			# Mảng tường đá / gạch cổ nằm ngang (46x22) không thể phá
			draw_rect(Rect2(-23, -12, 46, 20), Color("3c3944"))
			draw_rect(Rect2(-22, -11, 44, 10), Color("706a76"))
			draw_rect(Rect2(-22, -11, 44, 3), Color("96909c"))
			draw_rect(Rect2(-22, -1, 44, 8), Color("524d58"))
			for bx in [-12, 0, 12]:
				draw_line(Vector2(bx, -11), Vector2(bx, 7), Color("3c3944"), 1.0)
		"wall_v":
			# Mảng tường ngắn dựng dọc (16x42)
			draw_rect(Rect2(-8, -22, 16, 43), Color("3c3944"))
			draw_rect(Rect2(-7, -21, 14, 34), Color("706a76"))
			draw_rect(Rect2(-7, -21, 14, 4), Color("96909c"))
			draw_rect(Rect2(-7, 13, 14, 7), Color("524d58"))
			for by in [-10, 2]:
				draw_line(Vector2(-7, by), Vector2(7, by), Color("3c3944"), 1.0)
		"pillar":
			# Cột đá chạm khắc vững chắc (18x26)
			draw_rect(Rect2(-9, -18, 18, 27), Color("38343e"))
			draw_rect(Rect2(-8, -17, 16, 18), Color("68626e"))
			draw_rect(Rect2(-9, -19, 18, 5), Color("9a949e"))
			draw_rect(Rect2(-6, -12, 12, 10), Color("7c7682"))
			draw_rect(Rect2(-8, 1, 16, 7), Color("4f4a56"))
			draw_rect(Rect2(-3, -9, 6, 4), Color("d6a43e"))
		"barrel_boom":
			# Thùng thuốc nổ đỏ cam có đai sắt & ngòi cháy nhấp nháy
			draw_rect(Rect2(-7, -10, 14, 15), Color("4a1614"))
			draw_rect(Rect2(-6, -9, 12, 13), Color("c43228"))
			draw_rect(Rect2(-6, -9, 5, 13), Color("e65038"))
			draw_rect(Rect2(-6, -6, 12, 2), Color("565a6a"))
			draw_rect(Rect2(-6, 1, 12, 2), Color("565a6a"))
			draw_rect(Rect2(-3, -3, 6, 4), Color("ffd84a"))
			var spark_c := Color("fff298") if int(_t * 10.0) % 2 == 0 else Color("ff922c")
			draw_line(Vector2(0, -9), Vector2(2, -13), Color("c8b482"), 1.2)
			draw_circle(Vector2(2, -13), 1.8, spark_c)


func hit_sfx() -> String:
	return "hit_wood" if kind == "crate" else "hit_wall"


func _debris_color() -> Color:
	match kind:
		"pot":
			return Color(0.85, 0.88, 0.96)
		"crate":
			return Color(0.68, 0.44, 0.24)
		"stele":
			return Color(0.75, 0.72, 0.68)
		"sandbag":
			return Color(0.8, 0.68, 0.45)
		"barrel_boom":
			return Color(1.0, 0.48, 0.18)
		"wall_h", "wall_v", "pillar":
			return Color(0.72, 0.7, 0.74)
	return Color(0.8, 0.8, 0.8)


func take_hit(dmg: int, _hit_pos: Vector2 = Vector2.ZERO, hit_dir: Vector2 = Vector2.ZERO) -> bool:
	if _dead:
		return false
	Sfx.play(hit_sfx())
	var bounce_dir: Vector2 = (-hit_dir.normalized()) if hit_dir.length() > 0.05 else Vector2.UP
	var par: Node = get_parent()
	if par != null:
		Fx.particles(par, global_position + Vector2(0, -3), _debris_color(), 4, 55.0, 0.25, 90.0, 1.5, 55.0, bounce_dir)
	if _spr != null and is_instance_valid(_spr):
		_spr.position.x = clampf(hit_dir.x * 1.4, -1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(_spr, "position:x", 0.0, 0.08)
	if not destructible:
		return false
	hp -= 2 if dmg >= 10 else 1
	if hp <= 0:
		_break()
		return true
	return false


func _break() -> void:
	if _dead:
		return
	_dead = true
	var par: Node = get_parent()
	if par != null:
		if kind == "barrel_boom":
			_explode(par)
			queue_free()
			return
		Fx.particles(par, global_position, _debris_color(), 10, 95.0, 0.4, 140.0, 2.0, 160.0, Vector2.UP)
		if kind == "pot":
			Fx.particles(par, global_position, Color(0.2, 0.42, 0.78), 4, 80.0, 0.35, 120.0, 1.6, 160.0, Vector2.UP)
		Fx.anim(par, global_position, "fx/poof.png", 28, 28, 18.0, 0.55)
		if randf() < 0.30:
			_spawn_loot.call_deferred(par, global_position)
	queue_free()


func _explode(par: Node) -> void:
	Sfx.play("explode")
	Fx.shake(get_tree(), 4.5)
	Fx.anim(par, global_position, "fx/explosion.png", 44, 44, 22.0, 1.35)
	Fx.burst(par, global_position, Color(1.0, 0.55, 0.18), 58.0, 0.4)
	Fx.particles(par, global_position, Color(1.0, 0.6, 0.2), 16, 120.0, 0.5, 160.0, 2.2)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var e2: Node2D = e as Node2D
		if e2 != null and e2.global_position.distance_to(global_position) <= 58.0:
			var push_dir: Vector2 = (e2.global_position - global_position).normalized()
			e.take_damage(18, push_dir * 160.0)
			if is_instance_valid(e) and e.has_method("apply_status"):
				e.apply_status("burn", 3.0)
	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")) or bool(pl.get("downed")):
			continue
		var p2: Node2D = pl as Node2D
		if p2 != null and p2.global_position.distance_to(global_position) <= 44.0:
			pl.take_damage(1, "Thùng thuốc nổ")
	for cv in get_tree().get_nodes_in_group("cover"):
		if cv != self and is_instance_valid(cv) and not bool(cv.get("_dead")):
			var c2: Node2D = cv as Node2D
			if c2 != null and c2.global_position.distance_to(global_position) <= 56.0:
				cv.take_hit(20, global_position, (c2.global_position - global_position).normalized())


func _spawn_loot(par: Node, pos: Vector2) -> void:
	if not is_instance_valid(par):
		return
	var pk := Pickup.new()
	if randf() < 0.5:
		pk.kind = "coin"
		pk.amount = 1
	else:
		pk.kind = "energy"
		pk.amount = 4
	pk.position = pos
	par.add_child(pk)
