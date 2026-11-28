extends "res://scripts/entities/interactable.gd"
## Bệ Tháp Phòng Thủ Cổ Loa: xây, sửa, nâng cấp (Cấp 1..3), hoạt ảnh theo cấp & chiến đấu tự động.

const CoLoaData = preload("res://scripts/data/co_loa_data.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const MortarStrike = preload("res://scripts/effects/mortar_strike.gd")

const REPAIR_COST := 12

static var shared_choice_idx: int = 0

var pad_id: int = 0
var tower_id: String = ""
var tier: int = 0
var hp: int = 0
var max_hp: int = 0
var _atk_cd: float = 0.0
var _aura_cd: float = 0.0

var _spr: Node2D = null
var _light: PointLight2D = null
var _flash: float = 0.0
var _recoil_t: float = 0.0
var _regen_cd: float = 0.0


func _ready() -> void:
	radius = 28.0
	z_index = 1
	add_to_group("defense_towers")
	_refresh_visual()


static func set_shared_choice(idx: int) -> String:
	if CoLoaData.TOWER_ORDER.is_empty():
		return ""
	shared_choice_idx = clampi(idx, 0, CoLoaData.TOWER_ORDER.size() - 1)
	return str(CoLoaData.TOWER_ORDER[shared_choice_idx])


func selected_tower_id() -> String:
	if CoLoaData.TOWER_ORDER.is_empty():
		return ""
	return str(CoLoaData.TOWER_ORDER[shared_choice_idx % CoLoaData.TOWER_ORDER.size()])


func cycle_build_choice() -> String:
	if CoLoaData.TOWER_ORDER.is_empty():
		return ""
	shared_choice_idx = (shared_choice_idx + 1) % CoLoaData.TOWER_ORDER.size()
	if Sfx != null:
		Sfx.play("ui_click")
	queue_redraw()
	return selected_tower_id()


func hint() -> String:
	if tier == 0:
		var tid: String = selected_tower_id()
		var info: Dictionary = CoLoaData.tower_info(tid)
		var cost: int = CoLoaData.tower_upgrade_cost(tid, 1)
		return "Xây %s (%dxu) | [1-5 / Q] đổi" % [str(info.get("name", tid)), cost]
	var info2: Dictionary = CoLoaData.tower_info(tower_id)
	var tname: String = str(info2.get("name", tower_id))
	if hp < max_hp:
		return "Sửa %s (%dxu) [%d/%d]" % [tname, REPAIR_COST, hp, max_hp]
	var max_t: int = int(info2.get("max_tier", 3))
	if tier < max_t:
		var up_cost: int = CoLoaData.tower_upgrade_cost(tower_id, tier + 1)
		return "Nâng %s Cấp %d (%dxu)" % [tname, tier + 1, up_cost]
	return "%s Cấp %d (Tối đa)" % [tname, tier]


func interact() -> void:
	if tier == 0:
		var tid: String = selected_tower_id()
		if not build_tower(tid):
			var cost: int = CoLoaData.tower_upgrade_cost(tid, 1)
			if Sfx != null:
				Sfx.play("buy_fail")
			if get_parent() != null:
				Fx.float_text(get_parent(), global_position + Vector2(0.0, -24.0), "Cần %dxu!" % cost, Color(1.0, 0.45, 0.4), 12)
	else:
		repair_or_upgrade()


func build_tower(tid: String) -> bool:
	if tier != 0 or not CoLoaData.TOWERS.has(tid):
		return false
	var cost: int = CoLoaData.tower_upgrade_cost(tid, 1)
	if Global == null or Global.run_coins < cost:
		return false
	Global.run_coins -= cost
	_notify_local_stats()
	var info: Dictionary = CoLoaData.tower_info(tid)
	tower_id = tid
	tier = 1
	max_hp = int(info.get("hp", 100))
	hp = max_hp
	_atk_cd = 0.25
	_aura_cd = 1.5
	_regen_cd = 4.0
	_recoil_t = 0.28
	_refresh_visual()
	if Sfx != null:
		Sfx.play("tower_build")
	if get_parent() != null:
		var col: Color = info.get("color", Color(1.0, 0.85, 0.35))
		Fx.burst(get_parent(), global_position, col, 36.0, 0.38)
		Fx.particles(get_parent(), global_position, col, 10, 75.0, 0.45, -24.0, 1.8)
		Fx.float_text(get_parent(), global_position + Vector2(0.0, -28.0), "Đã xây %s!" % str(info.get("name", tid)), col, 13)
	queue_redraw()
	return true


func upgrade_tower() -> bool:
	if tier <= 0 or not CoLoaData.TOWERS.has(tower_id):
		return false
	var info: Dictionary = CoLoaData.tower_info(tower_id)
	var max_t: int = int(info.get("max_tier", 3))
	if tier >= max_t:
		return false
	var cost: int = CoLoaData.tower_upgrade_cost(tower_id, tier + 1)
	if Global == null or Global.run_coins < cost:
		if Sfx != null:
			Sfx.play("buy_fail")
		if get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -24.0), "Cần %dxu!" % cost, Color(1.0, 0.45, 0.4), 12)
		return false
	Global.run_coins -= cost
	_notify_local_stats()
	tier += 1
	max_hp = int(info.get("hp", 100)) * tier
	hp = max_hp
	_recoil_t = 0.34
	_refresh_visual()
	if Sfx != null:
		Sfx.play("tower_upgrade")
	if get_parent() != null:
		var col: Color = info.get("color", Color(1.0, 0.85, 0.35))
		Fx.burst(get_parent(), global_position, col, 44.0, 0.42)
		Fx.particles(get_parent(), global_position, Color(1.0, 0.90, 0.45), 14, 90.0, 0.5, -28.0, 2.0)
		Fx.float_text(get_parent(), global_position + Vector2(0.0, -28.0), "%s Cấp %d!" % [str(info.get("name", tower_id)), tier], col, 13)
	queue_redraw()
	return true


func repair_or_upgrade() -> bool:
	if tier <= 0:
		return false
	if hp < max_hp:
		if Global == null or Global.run_coins < REPAIR_COST:
			if Sfx != null:
				Sfx.play("buy_fail")
			if get_parent() != null:
				Fx.float_text(get_parent(), global_position + Vector2(0.0, -24.0), "Cần %dxu!" % REPAIR_COST, Color(1.0, 0.45, 0.4), 12)
			return false
		Global.run_coins -= REPAIR_COST
		_notify_local_stats()
		hp = max_hp
		if Sfx != null:
			Sfx.play("core_repair")
		if get_parent() != null:
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -24.0), "Đã tu sửa!", Color(0.55, 1.0, 0.65), 12)
		queue_redraw()
		return true
	return upgrade_tower()


func take_damage(amount: int) -> void:
	if tier <= 0 or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	_flash = 1.0
	queue_redraw()
	if hp <= 0:
		if is_inside_tree() and get_parent() != null:
			Fx.anim(get_parent(), global_position, "fx/explosion.png", 44, 44, 18.0, 0.9)
			Fx.float_text(get_parent(), global_position + Vector2(0.0, -22.0), "Tháp bị phá!", Color(1.0, 0.4, 0.35), 13)
		tower_id = ""
		tier = 0
		hp = 0
		max_hp = 0
		_refresh_visual()
		queue_redraw()


func export_state() -> Dictionary:
	return {
		"pad_id": pad_id,
		"tower_id": tower_id,
		"tier": tier,
		"hp": hp,
		"max_hp": max_hp,
	}


func apply_state(st: Dictionary) -> void:
	var old_tid: String = tower_id
	var old_tier: int = tier
	tower_id = str(st.get("tower_id", ""))
	tier = maxi(0, int(st.get("tier", 0)))
	max_hp = maxi(0, int(st.get("max_hp", 0)))
	hp = clampi(int(st.get("hp", 0)), 0, max_hp if max_hp > 0 else 0)
	if old_tid != tower_id or old_tier != tier or (tier == 0 and _spr != null):
		_refresh_visual()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event is InputEventKey:
		var kev: InputEventKey = event as InputEventKey
		if kev.pressed and not kev.echo:
			var digit_idx: int = -1
			match kev.physical_keycode:
				KEY_1:
					digit_idx = 0
				KEY_2:
					digit_idx = 1
				KEY_3:
					digit_idx = 2
				KEY_4:
					digit_idx = 3
				KEY_5:
					digit_idx = 4
			if digit_idx >= 0 and pad_id == 0:
				set_shared_choice(digit_idx)
				if Sfx != null:
					Sfx.play("ui_click")
				for tw in get_tree().get_nodes_in_group("defense_towers"):
					if is_instance_valid(tw):
						(tw as CanvasItem).queue_redraw()
				return
	if not near or tier != 0:
		return
	var p: Node = Global.local_player() if Global != null else null
	if p == null or not is_instance_valid(p) or p.interact_target != self:
		return
	var want_cycle: bool = false
	if event is InputEventKey:
		var kev2: InputEventKey = event as InputEventKey
		if kev2.pressed and not kev2.echo and kev2.physical_keycode == KEY_Q:
			want_cycle = true
	elif event is InputEventMouseButton:
		var mev: InputEventMouseButton = event as InputEventMouseButton
		if mev.pressed and mev.button_index == MOUSE_BUTTON_RIGHT:
			want_cycle = true
	if want_cycle:
		cycle_build_choice()
		for tw in get_tree().get_nodes_in_group("defense_towers"):
			if is_instance_valid(tw):
				(tw as CanvasItem).queue_redraw()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func _process(delta: float) -> void:
	super._process(delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
	if _recoil_t > 0.0:
		_recoil_t = maxf(0.0, _recoil_t - delta * 4.0)
	if _spr != null and is_instance_valid(_spr):
		_spr.modulate = Color(1.0, 0.45, 0.35).lerp(Color.WHITE, 1.0 - _flash) if _flash > 0.0 else Color.WHITE
		var sc: float = 1.0 + _recoil_t * 0.14
		_spr.scale = Vector2(sc, 1.0 - _recoil_t * 0.10)
	if tier <= 0 or tower_id == "":
		return
	if Net != null and Net.is_online() and not Net.is_host():
		return
	_run_tower_ai(delta)


func _run_tower_ai(delta: float) -> void:
	_atk_cd -= delta
	_aura_cd -= delta
	match tower_id:
		"thap_no_than":
			if _atk_cd <= 0.0:
				var rng_px: float = 230.0 + float(tier) * 30.0
				var target: Node = _nearest_enemy(rng_px)
				if target != null:
					_atk_cd = maxf(0.45, 1.05 - 0.15 * float(tier))
					_fire_no_than(target)
		"bai_coc_bach_dang":
			if _atk_cd <= 0.0:
				var rng_px2: float = 78.0 + float(tier) * 14.0
				var hits: Array = _enemies_in_range(rng_px2)
				if not hits.is_empty():
					_atk_cd = maxf(0.55, 1.6 - 0.25 * float(tier))
					_erupt_bach_dang(hits, rng_px2)
		"phao_dai_dien_bien":
			if _atk_cd <= 0.0:
				var target2: Node = _furthest_strongest_enemy(340.0)
				if target2 != null:
					_atk_cd = maxf(1.2, 2.3 - 0.25 * float(tier))
					_fire_dien_bien(target2)
		"luy_tre_nga":
			_regen_cd -= delta
			if _regen_cd <= 0.0:
				_regen_cd = 3.5
				if hp < max_hp:
					hp = mini(max_hp, hp + 2 * tier)
					queue_redraw()
			if _atk_cd <= 0.0:
				var near_e: Array = _enemies_in_range(48.0)
				if not near_e.is_empty():
					_atk_cd = 0.75
					_recoil_t = 0.25
					var tdmg: int = 3 + tier * 2
					for e in near_e:
						var epos: Vector2 = (e as Node2D).global_position
						var push_dir: Vector2 = (epos - global_position).normalized()
						if push_dir.length_squared() < 0.001:
							push_dir = Vector2.RIGHT
						if e.has_method("take_damage"):
							e.take_damage(tdmg, push_dir * 95.0)
						_slow_enemy(e, 1.3)
		"lo_ren_da_chien":
			if _aura_cd <= 0.0:
				_aura_cd = 4.5
				_pulse_lo_ren()


func _fire_no_than(target: Node) -> void:
	if get_parent() == null:
		return
	_recoil_t = 0.30
	var tpos: Vector2 = target.hurtbox_center() if target.has_method("hurtbox_center") else (target as Node2D).global_position
	var base_dir: Vector2 = (tpos - global_position).normalized()
	if base_dir.length_squared() < 0.001:
		base_dir = Vector2.RIGHT
	var count: int = 1 + tier
	var dmg: int = 5 + tier * 2
	for i in count:
		var spread: float = 0.0 if count == 1 else lerpf(-0.14, 0.14, float(i) / float(count - 1))
		var sdir: Vector2 = base_dir.rotated(spread)
		var b := Bullet.new()
		b.setup(true, global_position + Vector2(0.0, -8.0) + sdir * 10.0, sdir, 340.0, dmg, 1.1, "arrow")
		b.pierce = 1 + tier
		b.color = Color(1.0, 0.86, 0.36)
		b.knock = 65.0
		get_parent().add_child(b)
	Fx.particles(get_parent(), global_position + Vector2(0.0, -10.0), Color(1.0, 0.90, 0.42), 4, 48.0, 0.25)
	if Sfx != null:
		Sfx.play("core_crossbow" if tier >= 2 else "w_crossbow")


func _erupt_bach_dang(hits: Array, rng_px: float) -> void:
	_recoil_t = 0.32
	var dmg: int = 5 + tier * 3
	for e in hits:
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var epos: Vector2 = (e as Node2D).global_position
		var push_d: Vector2 = (epos - global_position).normalized()
		if e.has_method("take_damage"):
			e.take_damage(dmg, push_d * 80.0)
		_slow_enemy(e, 2.0)
	if get_parent() != null:
		Fx.burst(get_parent(), global_position, Color(0.42, 0.86, 1.0), rng_px, 0.32)
		Fx.particles(get_parent(), global_position, Color(0.6, 0.92, 1.0), 10, 90.0, 0.4, -30.0, 1.8)
	if Sfx != null:
		Sfx.play("hit_wood")


func _fire_dien_bien(target: Node) -> void:
	if get_parent() == null:
		return
	_recoil_t = 0.45
	var tpos: Vector2 = target.hurtbox_center() if target.has_method("hurtbox_center") else (target as Node2D).global_position
	var dir: Vector2 = (tpos - global_position).normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	var b := Bullet.new()
	b.setup(true, global_position + Vector2(0.0, -10.0) + dir * 12.0, dir, 240.0, 12 + tier * 5, 1.5, "cannonball")
	b.explode_radius = 34.0 + float(tier) * 8.0
	b.stun_duration = 0.35
	b.color = Color(1.0, 0.56, 0.28)
	b.knock = 160.0
	get_parent().add_child(b)
	Fx.particles(get_parent(), global_position + Vector2(0.0, -12.0), Color(1.0, 0.72, 0.36), 8, 65.0, 0.32)
	if Sfx != null:
		Sfx.play("w_cannon")


func _pulse_lo_ren() -> void:
	if not is_inside_tree():
		return
	_recoil_t = 0.26
	var healed_any: bool = false
	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")) or bool(pl.get("downed")):
			continue
		if (pl as Node2D).global_position.distance_to(global_position) <= 160.0:
			if pl.has_method("restore_armor"):
				pl.restore_armor(1)
			if pl.has_method("add_energy"):
				pl.add_energy(15)
			healed_any = true
	var core: Node = get_tree().get_first_node_in_group("co_loa_core")
	if core != null and is_instance_valid(core) and core.has_method("repair"):
		if int(core.repair(5 * tier)) > 0:
			healed_any = true
	if healed_any and get_parent() != null:
		Fx.burst(get_parent(), global_position, Color(1.0, 0.72, 0.32), 48.0, 0.45)


func _nearest_enemy(max_range: float) -> Node:
	if not is_inside_tree():
		return null
	var best: Node = null
	var best_d: float = max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to((e as Node2D).global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _furthest_strongest_enemy(max_range: float) -> Node:
	if not is_inside_tree():
		return null
	var best: Node = null
	var best_score: float = -1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to((e as Node2D).global_position)
		if d <= max_range:
			var sc: float = d + float(int(e.get("hp"))) * 2.0
			if sc > best_score:
				best_score = sc
				best = e
	return best


func _enemies_in_range(max_range: float) -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var d: float = e.distance_to_hurtbox(global_position) if e.has_method("distance_to_hurtbox") else global_position.distance_to((e as Node2D).global_position)
		if d <= max_range:
			out.append(e)
	return out


func _slow_enemy(e: Node, dur: float) -> void:
	if e == null or not is_instance_valid(e):
		return
	if e.has_method("apply_status"):
		e.apply_status("slow", dur)
	elif e.has_method("apply_hazard_slow"):
		e.apply_hazard_slow(0.55, dur)


func _notify_local_stats() -> void:
	if Global == null:
		return
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp) and lp.has_signal("stats_changed"):
		lp.stats_changed.emit()


func _refresh_visual() -> void:
	if _spr != null and is_instance_valid(_spr):
		_spr.queue_free()
		_spr = null
	if _light != null and is_instance_valid(_light):
		_light.queue_free()
		_light = null
	if tier <= 0 or tower_id == "":
		return
	var info: Dictionary = CoLoaData.tower_info(tower_id)
	var rel: String = CoLoaData.tower_tier_sprite(tower_id, tier)
	if rel != "" and ResourceLoader.exists("res://assets/sprites/" + rel):
		var tex: Texture2D = Art.tex(rel)
		if tex != null and tex.get_width() >= 88:
			var anim := AnimatedSprite2D.new()
			anim.sprite_frames = Art.strip(rel, 44, 44, 4.5, true)
			anim.play("play")
			anim.position = Vector2(0.0, -10.0)
			add_child(anim)
			_spr = anim
		else:
			var st := Sprite2D.new()
			st.texture = tex
			st.position = Vector2(0.0, -10.0)
			add_child(st)
			_spr = st
	if tier >= 2 or tower_id == "lo_ren_da_chien":
		var lcol: Color = info.get("color", Color(1.0, 0.85, 0.35))
		_light = Art.light(lcol, 0.9 + 0.25 * float(tier), 0.72)
		_light.position = Vector2(0.0, -10.0)
		add_child(_light)


func _draw() -> void:
	if tier == 0:
		var sel_id: String = selected_tower_id()
		var info: Dictionary = CoLoaData.tower_info(sel_id)
		var col: Color = info.get("color", Color(0.85, 0.72, 0.36))
		var pulse: float = 0.4 + 0.35 * sin(_t * 4.0)
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, (0.55 + 0.35 * pulse) if near else 0.34), 1.6)
		draw_line(Vector2(-5.0, 0.0), Vector2(5.0, 0.0), Color(col, 0.7), 1.3)
		draw_line(Vector2(0.0, -5.0), Vector2(0.0, 5.0), Color(col, 0.7), 1.3)
		if near:
			var prev_rel: String = str(info.get("sprite", ""))
			if prev_rel != "" and ResourceLoader.exists("res://assets/sprites/" + prev_rel):
				var ptex: Texture2D = Art.tex(prev_rel)
				if ptex != null:
					draw_texture_rect(ptex, Rect2(-18.0, -28.0, 36.0, 36.0), false, Color(col.r, col.g, col.b, 0.42 + 0.16 * pulse))
			var rng_r: float = float(info.get("range", 100.0))
			draw_arc(Vector2.ZERO, rng_r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.20), 1.2)
		draw_hint(-40.0)
		return

	var tinfo: Dictionary = CoLoaData.tower_info(tower_id)
	var tcol: Color = tinfo.get("color", Color(0.95, 0.80, 0.35))
	var tier_rim: Color = Color(1.0, 0.88, 0.36, 0.88) if tier >= 3 else Color(tcol.r, tcol.g, tcol.b, 0.65)
	draw_circle(Vector2.ZERO, 17.0, Color(tcol.r, tcol.g, tcol.b, 0.14))
	draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, tier_rim, 1.5 if tier >= 3 else 1.2)
	if near:
		var base_rng: float = float(tinfo.get("range", 120.0))
		if tower_id == "thap_no_than":
			base_rng = 230.0 + float(tier) * 30.0
		elif tower_id == "bai_coc_bach_dang":
			base_rng = 78.0 + float(tier) * 14.0
		draw_arc(Vector2.ZERO, base_rng, 0.0, TAU, 48, Color(tcol.r, tcol.g, tcol.b, 0.20), 1.2)
	if _spr == null:
		var body_col: Color = Color(1.0, 0.45, 0.35) if _flash > 0.2 else tcol.darkened(0.2)
		draw_rect(Rect2(-10.0, -14.0, 20.0, 20.0), body_col)
		draw_rect(Rect2(-10.0, -14.0, 20.0, 20.0), tcol, false, 1.4)
	# Chấm sao cấp tháp (1..3)
	for i in tier:
		var sx: float = (float(i) - float(tier - 1) * 0.5) * 7.0
		draw_circle(Vector2(sx, 13.0), 2.4, Color(0.22, 0.12, 0.04))
		draw_circle(Vector2(sx, 13.0), 1.8, Color(1.0, 0.90, 0.32))
	if hp < max_hp:
		var bw: float = 32.0
		var ratio: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
		draw_rect(Rect2(-bw * 0.5, -31.0, bw, 4.0), Color(0.08, 0.04, 0.04, 0.9))
		draw_rect(Rect2(-bw * 0.5, -31.0, bw * ratio, 4.0), Color(0.45, 0.92, 0.55))
	draw_hint(-40.0)
