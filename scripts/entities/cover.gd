extends StaticBody2D
## Vật cản che đạn thuần Việt trong phòng:
##   - Cổ/Trung đại: chum gốm ("pot", vỡ sau 3 đòn), bia đá ("stele", không vỡ)
##   - Cận/Hiện đại: thùng gỗ ("crate", vỡ sau 4 đòn), ụ bao cát ("sandbag", không vỡ)

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
	elif kind == "stele":
		destructible = false
		max_hp = 999
		radius = 7.5
	elif kind == "sandbag":
		destructible = false
		max_hp = 999
		radius = 9.0
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
	else:
		var c := CircleShape2D.new()
		c.radius = radius
		cs.shape = c
	add_child(cs)

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 4)
	sh.scale = Vector2(1.4 if kind == "sandbag" else 1.1, 0.9)
	sh.z_index = -1
	add_child(sh)

	_spr = Sprite2D.new()
	_spr.texture = Art.tex("world/%s.png" % kind)
	if kind == "stele":
		_spr.scale = Vector2(0.75, 0.75)
		_spr.position = Vector2(0, -7)
	else:
		_spr.position = Vector2(0, -4)
	add_child(_spr)


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
		Fx.particles(par, global_position, _debris_color(), 10, 95.0, 0.4, 140.0, 2.0, 160.0, Vector2.UP)
		if kind == "pot":
			Fx.particles(par, global_position, Color(0.2, 0.42, 0.78), 4, 80.0, 0.35, 120.0, 1.6, 160.0, Vector2.UP)
		Fx.anim(par, global_position, "fx/poof.png", 28, 28, 18.0, 0.55)
		if randf() < 0.30:
			_spawn_loot.call_deferred(par, global_position)
	queue_free()


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
