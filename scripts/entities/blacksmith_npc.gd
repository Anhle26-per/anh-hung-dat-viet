extends "res://scripts/entities/interactable.gd"
## Thợ rèn lưu động: gắn 1 bùa cường hóa ngẫu nhiên lên vũ khí đang cầm trong lượt chơi.

const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var level: int = 1
var price: int = 20
var used: bool = false
var applied_mod: String = ""

var _forge: AnimatedSprite2D = null
var _light: PointLight2D = null


func _ready() -> void:
	z_index = 1
	radius = 24.0
	price = 18 + level * 2

	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 6)
	sh.scale = Vector2(1.9, 1.05)
	sh.z_index = -1
	add_child(sh)

	_forge = AnimatedSprite2D.new()
	_forge.sprite_frames = Art.strip("world/forge.png", 32, 28, 8.0, true)
	_forge.scale = Vector2(0.85, 0.85)
	_forge.position = Vector2(0, -6)
	_forge.play("play")
	add_child(_forge)

	_light = Art.light(Color(1.0, 0.62, 0.28), 1.0, 0.75)
	_light.position = Vector2(0, -6)
	add_child(_light)


func hint() -> String:
	if used:
		return "Đã rèn xong"
	return "Gắn bùa vũ khí (%d xu)" % price


func _fx_parent() -> Node:
	var par: Node = get_parent()
	return par if par != null else self


func interact() -> void:
	if used:
		return
	var p: Node = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var wid: String = str(p.weapons[p.slot])
	var par: Node = _fx_parent()
	if wid == "":
		Sfx.play("buy_fail")
		Fx.float_text(par, global_position + Vector2(0, -28), "Chưa cầm vũ khí!", Color(1.0, 0.5, 0.4), 13)
		return
	if Global.run_coins < price:
		Sfx.play("buy_fail")
		Fx.float_text(par, global_position + Vector2(0, -28), "Không đủ xu!", Color(1.0, 0.5, 0.4), 13)
		return

	var cur_mod: String = Global.get_weapon_mod(wid)
	var pool: Array = []
	for m in WeaponMods.ORDER:
		var mid: String = str(m)
		if mid != cur_mod:
			pool.append(mid)
	if pool.is_empty():
		pool = WeaponMods.ORDER.duplicate()
	var mod_id: String = str(pool.pick_random())

	Global.run_coins -= price
	Global.set_weapon_mod(wid, mod_id)
	used = true
	enabled = false
	near = false
	applied_mod = mod_id

	Sfx.play("forge")
	var col: Color = WeaponMods.mod_color(mod_id)
	Fx.particles(par, global_position + Vector2(0, -6), col, 20, 95.0, 0.55, -35.0, 2.2)
	Fx.particles(par, global_position + Vector2(0, -6), Color(1.0, 0.86, 0.35), 12, 70.0, 0.45, -25.0, 1.8)
	Fx.burst(par, global_position, col, 32.0, 0.35)
	Fx.float_text(par, global_position + Vector2(0, -32), "Đã gắn: %s!" % WeaponMods.mod_name(mod_id), col, 15)
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	if _light != null:
		_light.energy = 0.28
	queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	if not used:
		var a: float = 0.32 + 0.2 * sin(_t * 3.8)
		draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(1.0, 0.68, 0.28, a), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Art.draw_text(self, Vector2(0, -24), "Thợ rèn lưu động", 12, Color(1.0, 0.84, 0.45))
	if used:
		Art.draw_text(self, Vector2(0, 18), "Đã rèn xong", 11, Color(0.75, 0.72, 0.68, 0.8))
	else:
		var ctex: Texture2D = Art.tex("items/coin.png")
		var txt: String = "%d xu" % price
		var w: float = Art.text_width(txt, 12) + 10.0
		draw_texture_rect_region(ctex, Rect2(-w / 2.0, 11, 9, 9), Rect2(0, 0, 9, 9))
		Art.draw_text(self, Vector2(-w / 2.0 + 11.0, 19), txt, 12,
			Color(1.0, 0.88, 0.45) if Global.run_coins >= price else Color(1.0, 0.5, 0.45), false)
	draw_hint(-36.0)
