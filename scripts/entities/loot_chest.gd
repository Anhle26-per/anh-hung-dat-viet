extends "res://scripts/entities/interactable.gd"
## Rương sơn mài chiến lợi phẩm: hiện ra sau mỗi phòng đã dọn sạch giặc.
## Mở ra ngẫu nhiên theo tỉ lệ: xu + linh khí (nhiều nhất), hồ lô thuốc, hoặc vũ khí.

const WeaponData = preload("res://scripts/data/weapons.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var level := 1
var opened := false
var _spr: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	radius = 22.0
	var sh := Sprite2D.new()
	sh.texture = Art.tex("fx/shadow.png")
	sh.position = Vector2(0, 8)
	sh.scale = Vector2(1.6, 1.2)
	sh.z_index = -1
	add_child(sh)
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = Art.frames("items/loot_chest.png", 22, 20, {"closed": [[0], 1.0, false], "open": [[1, 2, 3], 14.0, false]})
	_spr.play("closed")
	_spr.scale = Vector2(1.3, 1.3)
	add_child(_spr)
	# rơi từ trên xuống cho có cảm giác "phần thưởng"
	_spr.position.y = -40.0
	_spr.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_spr, "position:y", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(_spr, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func(): Fx.anim(get_parent(), global_position + Vector2(0, 6), "fx/dust.png", 10, 10, 14.0, 2.0))


func hint() -> String:
	return "Mở rương sơn mài"


func interact() -> void:
	if opened:
		return
	opened = true
	enabled = false
	near = false
	_spr.play("open")
	Sfx.play("chest_open")
	var par := get_parent()
	var c := global_position + Vector2(0, 14)
	Fx.particles(par, global_position, Color(1, 0.85, 0.35), 18, 90.0, 0.6, -50.0, 2.0)
	var r := randf()
	if r < 0.58:
		for i in randi_range(6, 10):
			_drop("coin", 1, c)
		for i in 3:
			_drop("energy", 5, c)
	elif r < 0.85:
		var q := randf()
		if q < 0.45:
			_drop("potion", 2, c)
		elif q < 0.8:
			_drop("potion_energy", 80, c)
		else:
			_drop("potion_big", 5, c)
		for i in 3:
			_drop("coin", 1, c)
	else:
		var p := Pickup.new()
		p.kind = "weapon"
		p.weapon_id = WeaponData.roll(level, 1 if level >= 10 else 0)
		p.position = c
		par.add_child(p)
		Fx.burst(par, global_position, WeaponData.tier_color(p.weapon_id), 40.0, 0.5)
	queue_redraw()
	# rương mở xong mờ dần
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func _drop(k: String, amount: int, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = pos
	get_parent().add_child(p)


func _draw() -> void:
	if not opened:
		var a := 0.35 + 0.25 * sin(_t * 4.0)
		draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1, 0.8, 0.35, a), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hint(-22.0)
