extends Node2D
## Vật phẩm rơi: xu cổ, tinh thể năng lượng, bầu hồ lô hồi máu, vũ khí (có cột sáng theo cấp).

const WeaponData = preload("res://scripts/data/weapons.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

var kind := "coin"     # coin, energy, potion, potion_big, potion_energy, weapon, material
var amount := 1
var weapon_id := ""
var material_id := ""
var _t := 0.0
var _vel := Vector2.ZERO
var _near := false
var _spr: Node2D


func _ready() -> void:
	add_to_group("pickups")
	z_index = 1
	match kind:
		"coin":
			_spr = _anim("items/coin.png", 9, 9, 10.0)
		"energy":
			_spr = _anim("items/energy.png", 7, 9, 8.0)
		"potion", "potion_big", "potion_energy":
			_spr = Sprite2D.new()
			_spr.texture = Art.tex("items/%s.png" % kind)
		"material":
			_spr = Sprite2D.new()
			var minfo: Dictionary = MaterialData.DATA.get(material_id, {})
			_spr.texture = Art.tex(str(minfo.get("icon", "items/mat_dong.png")))
		"weapon":
			_spr = Sprite2D.new()
			_spr.texture = Art.tex("weapons/%s.png" % weapon_id)
			_spr.rotation = -0.35
			var tier := int(WeaponData.get_data(weapon_id).get("tier", 1))
			if tier >= 3:
				var l := Art.light(WeaponData.tier_color(weapon_id), 0.9, 0.9)
				add_child(l)
	add_child(_spr)
	if kind == "coin" or kind == "energy" or kind == "material":
		_vel = Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0)


func _anim(rel: String, fw: int, fh: int, fps: float) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Art.strip(rel, fw, fh, fps, true)
	a.play("play")
	a.frame = randi() % 4
	return a


func _process(delta: float) -> void:
	_t += delta
	_spr.position.y = sin(_t * 4.0) * 1.5 - (3.0 if kind == "weapon" else 0.0)
	if kind == "weapon":
		queue_redraw()
	var p = get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	var to: Vector2 = p.global_position - global_position
	var d := to.length()
	match kind:
		"coin", "energy", "material":
			if _t > 0.35 and d < 80.0:
				_vel = to.normalized() * 240.0
			else:
				_vel = _vel.move_toward(Vector2.ZERO, 160.0 * delta)
			position += _vel * delta
			if d < 9.0:
				_collect(p)
		"potion", "potion_big", "potion_energy":
			if d < 12.0:
				_collect(p)
		"weapon":
			_near = d < 22.0
			if _near:
				if p.nearby_pickup == null or not is_instance_valid(p.nearby_pickup) or p.nearby_pickup == self \
						or d < p.global_position.distance_to(p.nearby_pickup.global_position):
					p.nearby_pickup = self
			elif p.nearby_pickup == self:
				p.nearby_pickup = null


func _collect(p) -> void:
	match kind:
		"coin":
			Sfx.play("coin")
			var v := amount * Global.coin_mult()
			Global.run_coins += int(v) + (1 if randf() < v - int(v) else 0)
			p.stats_changed.emit()
			Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 30.0, 0.6, 0.0, Color(1, 0.9, 0.4), true)
		"energy":
			Sfx.play("coin")
			p.add_energy(amount)
			Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 30.0, 0.6, 0.0, Color(0.5, 0.8, 1.0), true)
		"potion", "potion_big":
			Sfx.play("pickup_weapon")
			p.heal(amount)
			p.status.clear()
		"potion_energy":
			Sfx.play("pickup_weapon")
			p.add_energy(amount)
			Fx.float_text(get_parent(), global_position + Vector2(0, -16), "+%d linh khí" % amount, Color(0.5, 0.8, 1.0))
			Fx.particles(get_parent(), global_position, Color(0.5, 0.8, 1.0), 10, 50.0, 0.6, -60.0, 2.0)
		"material":
			var minfo: Dictionary = MaterialData.DATA.get(material_id, {})
			var mname: String = str(minfo.get("name", material_id))
			var mcol: Color = minfo.get("color", Color(0.9, 0.9, 1.0))
			Global.add_run_material(material_id, amount)
			Sfx.play("pickup_material")
			Fx.float_text(get_parent(), global_position + Vector2(0, -14), "+%d %s" % [amount, mname], mcol, 12)
			Fx.anim(get_parent(), global_position, "fx/spark.png", 15, 15, 30.0, 0.6, 0.0, mcol, true)
	queue_free()


func _draw() -> void:
	if kind != "weapon":
		return
	var w := WeaponData.get_data(weapon_id)
	var tier := int(w.get("tier", 1))
	var col: Color = WeaponData.TIER_COLORS[tier]
	# cột sáng theo cấp
	var h := 10.0 + tier * 6.0
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	for i in 6:
		var k := float(i) / 6.0
		draw_rect(Rect2(-3.0 + k * 1.5, -h * (1.0 - k) - 2.0, 6.0 - k * 3.0, h * (1.0 - k) * 0.25), Color(col, (0.12 + 0.1 * pulse) * (1.0 - k)))
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 9.0, Color(col, 0.25 + 0.15 * pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# mũi tên nhấp nhô chỉ vào vũ khí
	var ay := -20.0 - absf(sin(_t * 5.0)) * 4.0
	draw_colored_polygon(PackedVector2Array([Vector2(-4, ay), Vector2(4, ay), Vector2(0, ay + 5)]), col)
	if is_showing_label():
		var p = get_tree().get_first_node_in_group("player")
		var syn_line: String = ""
		var syn_c := Color(0.8, 0.9, 1.0)
		var imp_name: String = SynergyData.imprint_name(weapon_id)
		if p != null:
			var slv: int = SynergyData.level(p.hero_id, weapon_id)
			if slv == 2:
				syn_line = "★★ Binh khí định mệnh  |  Ấn: %s" % imp_name
				syn_c = Color(1.0, 0.88, 0.35)
			elif slv == 1:
				syn_line = "★ Hợp chiêu  |  Ấn: %s" % imp_name
				syn_c = Color(0.84, 0.9, 0.98)
			else:
				syn_line = "Ấn: %s" % imp_name
				syn_c = SynergyData.family_color(SynergyData.family(weapon_id))
			Art.draw_text(self, Vector2(0, -54), syn_line, 11, syn_c)
		Art.draw_text(self, Vector2(0, -44), w.name, 16, col)
		Art.draw_text(self, Vector2(0, -34), "[%s] %s" % [WeaponData.TIER_NAMES[tier], w.desc], 12, Color(0.95, 0.9, 0.8))
		var stats := "Sát thương %d   Tốc độ %.2fs   Năng lượng %d" % [int(w.damage) * int(w.get("count", 1)), float(w.cooldown), int(w.get("energy", 0))]
		Art.draw_text(self, Vector2(0, -25), stats, 12, Color(0.7, 0.88, 1.0))


func is_showing_label() -> bool:
	if not _near or not is_inside_tree():
		return false
	var p = get_tree().get_first_node_in_group("player")
	return p != null and is_instance_valid(p) and p.nearby_pickup == self
