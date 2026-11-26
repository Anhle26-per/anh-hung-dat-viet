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
var pickup_id: int = 0
var _claim_pending: bool = false
var _net_claimed_by_other: bool = false
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
			var wd := WeaponData.get_data(weapon_id)
			var tier := int(wd.get("tier", 1))
			var is_boss_motif := bool(wd.get("boss_motif", false))
			var tcol: Color = Color("ff384c") if is_boss_motif else WeaponData.tier_color(weapon_id)
			if tier >= 3 or is_boss_motif:
				var l := Art.light(tcol, 1.55 if is_boss_motif else (1.35 if tier >= 5 else 0.9), 1.45 if is_boss_motif else (1.3 if tier >= 5 else 0.9))
				add_child(l)
			if tier >= 5 or is_boss_motif:
				var leg_pt := CPUParticles2D.new()
				leg_pt.amount = 16 if is_boss_motif else 14
				leg_pt.lifetime = 1.2
				leg_pt.direction = Vector2.UP
				leg_pt.spread = 30.0
				leg_pt.gravity = Vector2(0, -32)
				leg_pt.initial_velocity_min = 12.0
				leg_pt.initial_velocity_max = 26.0
				leg_pt.scale_amount_min = 1.4
				leg_pt.scale_amount_max = 2.4
				var lg := Gradient.new()
				if is_boss_motif:
					lg.set_color(0, Color("ff384c"))
					lg.set_color(1, Color(0.6, 0.04, 0.14, 0.0))
				else:
					lg.set_color(0, Color(1.0, 0.86, 0.35, 0.95))
					lg.set_color(1, Color(1.0, 0.55, 0.15, 0.0))
				leg_pt.color_ramp = lg
				leg_pt.material = Art.additive()
				leg_pt.z_index = 2
				add_child(leg_pt)
				_play_legendary_reveal.call_deferred()
	add_child(_spr)
	if kind == "coin" or kind == "energy" or kind == "material":
		_vel = Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0)


func _play_legendary_reveal() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var par := get_parent()
	var w := WeaponData.get_data(weapon_id)
	var wname: String = str(w.get("name", weapon_id))
	var is_boss_motif: bool = bool(w.get("boss_motif", false))
	if is_boss_motif:
		var c_red := Color("ff384c")
		Fx.burst(par, global_position, c_red, 62.0, 0.65)
		Fx.burst(par, global_position, Color(1.0, 0.72, 0.76), 36.0, 0.4)
		Fx.particles(par, global_position, c_red, 26, 125.0, 0.75, -55.0, 2.2)
		Fx.float_text(par, global_position + Vector2(0, -26), "★ THẦN BINH TRÙM: %s ★" % wname, c_red, 16)
		Fx.shake(get_tree(), 4.8)
		Sfx.play("chest_open")
		get_tree().call_group("hud", "show_banner", "★ Rơi Thần Binh Trùm: %s! ★" % wname)
		return
	Fx.burst(par, global_position, Color(1.0, 0.65, 0.18), 58.0, 0.65)
	Fx.burst(par, global_position, Color(1.0, 0.94, 0.55), 34.0, 0.4)
	Fx.particles(par, global_position, Color(1.0, 0.82, 0.25), 24, 120.0, 0.75, -55.0, 2.2)
	Fx.float_text(par, global_position + Vector2(0, -26), "★ HUYỀN THOẠI: %s ★" % wname, Color(1.0, 0.85, 0.28), 16)
	Fx.shake(get_tree(), 4.5)
	Sfx.play("chest_open")
	get_tree().call_group("hud", "show_banner", "★ Xuất hiện binh khí Huyền Thoại: %s! ★" % wname)


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
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p) or bool(p.get("dead")) or bool(p.get("downed")):
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
				if Net.is_online() and pickup_id > 0:
					if _claim_pending:
						return
					if Net.is_host():
						var ns: Node = get_tree().get_first_node_in_group("net_sync")
						if ns != null:
							if ns.claimed_pickups.has(pickup_id):
								net_remove_claimed()
								return
							ns.claimed_pickups[pickup_id] = true
						Net.send_world_event("pickup_claimed", {"id": pickup_id, "claimer": Net.local_peer_id()}, false)
						_collect(p)
					else:
						_claim_pending = true
						Net.send_world_event("pickup_claim", {"id": pickup_id}, true)
				else:
					_collect(p)
		"weapon":
			_near = d < 22.0
			if _near:
				if p.nearby_pickup == null or not is_instance_valid(p.nearby_pickup) or p.nearby_pickup == self \
						or d < p.global_position.distance_to(p.nearby_pickup.global_position):
					p.nearby_pickup = self
			elif p.nearby_pickup == self:
				p.nearby_pickup = null


func net_collect_approved() -> void:
	var p: Node = Global.local_player()
	if p != null and is_instance_valid(p) and not bool(p.get("dead")):
		_collect(p)
	else:
		queue_free()


func net_remove_claimed() -> void:
	_net_claimed_by_other = true
	var p: Node = Global.local_player() if is_inside_tree() else null
	if p != null and is_instance_valid(p) and p.nearby_pickup == self:
		p.nearby_pickup = null
	queue_free()


func _exit_tree() -> void:
	if pickup_id <= 0 or not Net.is_online() or not is_inside_tree():
		return
	var ns: Node = get_tree().get_first_node_in_group("net_sync")
	if ns != null:
		ns.unregister_pickup(pickup_id)
	if kind == "weapon" and not _net_claimed_by_other and ns != null and not bool(ns.get("is_clearing_level")):
		var p: Node = Global.local_player()
		if p != null and is_instance_valid(p) and p.global_position.distance_to(global_position) < 48.0:
			if Net.is_host():
				if not ns.claimed_pickups.has(pickup_id):
					ns.claimed_pickups[pickup_id] = true
					Net.send_world_event("pickup_claimed", {"id": pickup_id, "claimer": Net.local_peer_id()}, false)
			else:
				Net.send_world_event("pickup_claim", {"id": pickup_id}, true)


func _collect(p) -> void:
	match kind:
		"coin":
			Sfx.play("coin")
			var v := amount * Global.coin_mult()
			var gained: int = int(v) + (1 if randf() < v - int(v) else 0)
			Global.run_coins += gained
			if p.has_method("on_coins_collected"):
				p.on_coins_collected(gained)
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
	var is_boss_motif: bool = bool(w.get("boss_motif", false))
	var col: Color = Color("ff384c") if is_boss_motif else WeaponData.tier_color(weapon_id)
	# cột sáng theo cấp (cấp 5 Huyền Thoại / Thần binh Trùm có chùm sáng vút trời)
	var h := 130.0 if (tier >= 5 or is_boss_motif) else (10.0 + tier * 6.0)
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	if is_boss_motif:
		draw_rect(Rect2(-9.0, -h, 18.0, h), Color(1.0, 0.16, 0.26, 0.10 + 0.06 * pulse))
		draw_rect(Rect2(-4.5, -h * 0.92, 9.0, h * 0.92), Color(1.0, 0.28, 0.36, 0.22 + 0.12 * pulse))
		draw_rect(Rect2(-1.5, -h * 0.85, 3.0, h * 0.85), Color(1.0, 0.82, 0.85, 0.45 + 0.22 * pulse))
		draw_arc(Vector2(0, 4), 14.0 + pulse * 3.0, 0.0, TAU, 24, Color(1.0, 0.22, 0.30, 0.65 + 0.25 * pulse), 1.6)
	elif tier >= 5:
		draw_rect(Rect2(-9.0, -h, 18.0, h), Color(1.0, 0.62, 0.16, 0.08 + 0.05 * pulse))
		draw_rect(Rect2(-4.5, -h * 0.92, 9.0, h * 0.92), Color(1.0, 0.84, 0.36, 0.18 + 0.10 * pulse))
		draw_rect(Rect2(-1.5, -h * 0.85, 3.0, h * 0.85), Color(1.0, 0.96, 0.78, 0.42 + 0.20 * pulse))
		draw_arc(Vector2(0, 4), 13.0 + pulse * 3.0, 0.0, TAU, 24, Color(1.0, 0.82, 0.28, 0.55 + 0.25 * pulse), 1.4)
	for i in 6:
		var k := float(i) / 6.0
		draw_rect(Rect2(-3.0 + k * 1.5, -h * (1.0 - k) - 2.0, 6.0 - k * 3.0, h * (1.0 - k) * 0.25), Color(col, (0.12 + 0.1 * pulse) * (1.0 - k)))
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 12.0 if (tier >= 5 or is_boss_motif) else 9.0, Color(col, 0.36 if (tier >= 5 or is_boss_motif) else 0.25 + 0.15 * pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# mũi tên nhấp nhô chỉ vào vũ khí
	var ay := -20.0 - absf(sin(_t * 5.0)) * 4.0
	draw_colored_polygon(PackedVector2Array([Vector2(-4, ay), Vector2(4, ay), Vector2(0, ay + 5)]), col)
	if is_showing_label():
		var p: Node = Global.local_player()
		var syn_line: String = ""
		var syn_c := Color(0.8, 0.9, 1.0)
		var imp_name: String = SynergyData.imprint_name(weapon_id)
		var y_top: float = -54.0
		if p != null:
			var merge_info: Dictionary = p.can_merge_nearby() if p.has_method("can_merge_nearby") else {}
			if not merge_info.is_empty() and merge_info.get("pickup", null) == self:
				var rec: Dictionary = merge_info.get("recipe", {})
				var rname: String = str(rec.get("name", ""))
				if rname == "":
					var rw: Dictionary = WeaponData.get_data(str(rec.get("result", "")))
					rname = str(rw.get("name", ""))
				var merge_hint: String = "[R] Hợp nhất -> %s" % rname if rname != "" else "[R] Hợp nhất"
				Art.draw_text(self, Vector2(0, -64.0), merge_hint, 13, Color(0.45, 1.0, 0.72))
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
			Art.draw_text(self, Vector2(0, y_top), syn_line, 11, syn_c)
		var tname: String = WeaponData.tier_name(weapon_id)
		Art.draw_text(self, Vector2(0, -44), w.name, 16, col)
		Art.draw_text(self, Vector2(0, -34), "[%s] %s" % [tname, w.desc], 12, Color(1.0, 0.78, 0.82) if is_boss_motif else Color(0.95, 0.9, 0.8))
		var stats := "Sát thương %d   Tốc độ %.2fs   Năng lượng %d" % [int(w.damage) * int(w.get("count", 1)), float(w.cooldown), int(w.get("energy", 0))]
		Art.draw_text(self, Vector2(0, -25), stats, 12, Color(0.7, 0.88, 1.0))


func is_showing_label() -> bool:
	if not _near or not is_inside_tree():
		return false
	var p: Node = Global.local_player()
	return p != null and is_instance_valid(p) and p.nearby_pickup == self
