extends "res://scripts/entities/interactable.gd"
## Bàn thờ / NPC Sự Kiện [!] trong phòng Event:
##   reforge_furnace (Lò Rèn Cổ), decomposer (Bệ Phân Tách), statue_shrine (Miếu Thần Việt),
##   mentor_npc (Quân Sư Truyền Nghệ), rescue_camp (Trại Quân Y), challenge_arena (Đài Thách Đấu).

signal challenge_triggered(altar)

const WeaponData = preload("res://scripts/data/weapons.gd")
const WeaponEvolutions = preload("res://scripts/data/weapon_evolutions.gd")
const HeroSkillsExt = preload("res://scripts/data/hero_skills_ext.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Ally = preload("res://scripts/entities/ally.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const KINDS: Array[String] = [
	"reforge_furnace",
	"decomposer",
	"statue_shrine",
	"mentor_npc",
	"rescue_camp",
	"challenge_arena",
]

var kind: String = "reforge_furnace"
var level: int = 1
var room = null
var used: bool = false
var cost: int = 0
var selected_statue: String = ""
var arena_active: bool = false
var arena_cleared: bool = false

var _arena_enemies: Array = []
var _light: PointLight2D = null
var _spr: Sprite2D = null


func _ready() -> void:
	add_to_group("event_altars")
	z_index = 2
	radius = 25.0
	_init_kind_defaults()
	var spr_path: String = "res://assets/sprites/world/%s.png" % kind
	if ResourceLoader.exists(spr_path):
		_spr = Sprite2D.new()
		_spr.texture = Art.tex("world/%s.png" % kind)
		_spr.position = Vector2(0, -10)
		add_child(_spr)
	var lcol: Color = _accent_color()
	_light = Art.light(lcol, 1.35, 0.85)
	_light.position = Vector2(0, -8)
	add_child(_light)


func _init_kind_defaults() -> void:
	match kind:
		"reforge_furnace":
			cost = 24 + level * 2
		"decomposer":
			cost = 0
		"statue_shrine":
			var order: Array = HeroSkillsExt.STATUE_ORDER
			if not order.is_empty():
				if selected_statue == "" or not order.has(selected_statue):
					selected_statue = str(order.pick_random())
			elif selected_statue == "":
				selected_statue = "lac_long"
			cost = _statue_cost(selected_statue)
		"mentor_npc":
			cost = 35 + level
		"rescue_camp":
			cost = 0
		"challenge_arena":
			cost = 0


func _statue_info(sid: String) -> Dictionary:
	if HeroSkillsExt.STATUES.has(sid):
		return HeroSkillsExt.STATUES[sid]
	return HeroSkillsExt.STATUES["lac_long"]


func _statue_cost(sid: String) -> int:
	return int(_statue_info(sid).get("cost", 30))


func _title() -> String:
	match kind:
		"reforge_furnace":
			return "Lò Rèn Cổ"
		"decomposer":
			return "Bệ Phân Tách"
		"statue_shrine":
			return str(_statue_info(selected_statue).get("name", "Miếu Thần Việt"))
		"mentor_npc":
			return "Quân Sư Truyền Nghệ"
		"rescue_camp":
			return "Trại Quân Y"
		"challenge_arena":
			return "Đài Thách Đấu"
	return "Di Tích"


func _accent_color() -> Color:
	match kind:
		"reforge_furnace":
			return Color(1.0, 0.56, 0.22)
		"decomposer":
			return Color(0.42, 0.88, 0.96)
		"statue_shrine":
			return _statue_info(selected_statue).get("color", Color(1.0, 0.86, 0.35)) as Color
		"mentor_npc":
			return Color(0.74, 0.55, 1.0)
		"rescue_camp":
			return Color(0.42, 0.95, 0.55)
		"challenge_arena":
			return Color(1.0, 0.32, 0.32)
	return Color(1.0, 0.88, 0.45)


func hint() -> String:
	if used:
		return "Đã hoàn thành" if (kind == "challenge_arena" and arena_cleared) else ("Đang giao chiến!" if arena_active else "Đã sử dụng")
	var p: Node = Global.local_player()
	var wid: String = ""
	if p != null and is_instance_valid(p) and p.get("weapons") is Array:
		var ws: Array = p.weapons
		var sl: int = int(p.get("slot"))
		if sl >= 0 and sl < ws.size():
			wid = str(ws[sl])
	match kind:
		"reforge_furnace":
			if wid != "" and _can_evolve_weapon(wid):
				return "Tiến hóa %s (%d xu)" % [str(WeaponData.get_data(wid).get("name", wid)), cost]
			return "Rèn lại binh khí (%d xu)" % cost
		"decomposer":
			if wid == "":
				return "Phân tách binh khí"
			return "Phân tách %s" % str(WeaponData.get_data(wid).get("name", wid))
		"statue_shrine":
			return "Thỉnh %s (%d xu)" % [_title(), cost]
		"mentor_npc":
			return "Bái sư truyền nghệ (%d xu)" % cost
		"rescue_camp":
			return "Trị thương & Chiêu mộ binh sĩ"
		"challenge_arena":
			return "Khiêu chiến Tinh Nhuệ!"
	return "Tương tác"


func _can_evolve_weapon(wid: String) -> bool:
	if wid == "":
		return false
	var evo_map: Variant = Global.get("evolved_weapons")
	var dict_map: Dictionary = evo_map as Dictionary if typeof(evo_map) == TYPE_DICTIONARY else {}
	return WeaponEvolutions.can_evolve(wid, dict_map)


func _fx_parent() -> Node:
	var par: Node = get_parent()
	return par if par != null else self


func interact() -> void:
	if used:
		return
	var p: Node = Global.local_player()
	if p == null or not is_instance_valid(p):
		return
	var par: Node = _fx_parent()
	match kind:
		"reforge_furnace":
			_interact_reforge(p, par)
		"decomposer":
			_interact_decomposer(p, par)
		"statue_shrine":
			_interact_statue(p, par)
		"mentor_npc":
			_interact_mentor(p, par)
		"rescue_camp":
			_interact_rescue(p, par)
		"challenge_arena":
			_interact_challenge(p, par)
	queue_redraw()


func _spend_coins(p: Node, par: Node, price: int) -> bool:
	if Global.run_coins < price:
		Sfx.play("buy_fail")
		Fx.float_text(par, global_position + Vector2(0, -30), "Không đủ xu!", Color(1.0, 0.45, 0.4), 13)
		return false
	Global.run_coins -= price
	if p.has_method("sync_gold_armor"):
		p.sync_gold_armor()
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	return true


func _mark_used() -> void:
	used = true
	enabled = false
	near = false
	if _light != null:
		_light.energy = 0.25


func _interact_reforge(p: Node, par: Node) -> void:
	var ws: Array = p.weapons
	var sl: int = int(p.slot)
	var wid: String = str(ws[sl]) if sl >= 0 and sl < ws.size() else ""
	if wid == "":
		Sfx.play("buy_fail")
		Fx.float_text(par, global_position + Vector2(0, -30), "Chưa cầm vũ khí!", Color(1.0, 0.5, 0.4), 13)
		return
	if not _spend_coins(p, par, cost):
		return
	if _can_evolve_weapon(wid):
		if Global.has_method("evolve_weapon"):
			Global.call("evolve_weapon", wid)
		else:
			var evo_map: Variant = Global.get("evolved_weapons")
			if typeof(evo_map) == TYPE_DICTIONARY:
				(evo_map as Dictionary)[wid] = true
		var wname: String = str(WeaponData.get_data(wid).get("name", wid))
		Sfx.play("forge")
		Fx.particles(par, global_position + Vector2(0, -8), Color(1.0, 0.78, 0.28), 24, 110.0, 0.6, -45.0, 2.4)
		Fx.burst(par, global_position, Color(1.0, 0.65, 0.2), 42.0, 0.45)
		Fx.float_text(par, global_position + Vector2(0, -34), "★ Tiến Hóa: %s!" % wname, Color(1.0, 0.88, 0.35), 15)
	else:
		var cur_tier: int = int(WeaponData.get_data(wid).get("tier", 1))
		var new_wid: String = wid
		for _i in 8:
			var cand: String = WeaponData.roll(level + 2, 2)
			if cand != wid and int(WeaponData.get_data(cand).get("tier", 1)) >= mini(5, cur_tier):
				new_wid = cand
				break
		if new_wid == wid:
			new_wid = WeaponData.roll(level + 2, 2)
		ws[sl] = new_wid
		Global.discover(new_wid)
		if p.has_method("_refresh_weapon_sprite"):
			p._refresh_weapon_sprite()
		var nname: String = str(WeaponData.get_data(new_wid).get("name", new_wid))
		Sfx.play("forge")
		Fx.particles(par, global_position + Vector2(0, -8), WeaponData.tier_color(new_wid), 20, 95.0, 0.55, -35.0, 2.2)
		Fx.float_text(par, global_position + Vector2(0, -34), "Rèn thành: %s!" % nname, WeaponData.tier_color(new_wid), 15)
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	_mark_used()


func _interact_decomposer(p: Node, par: Node) -> void:
	var ws: Array = p.weapons
	var sl: int = int(p.slot)
	var wid: String = str(ws[sl]) if sl >= 0 and sl < ws.size() else ""
	if wid == "":
		Sfx.play("buy_fail")
		Fx.float_text(par, global_position + Vector2(0, -30), "Chưa cầm vũ khí!", Color(1.0, 0.5, 0.4), 13)
		return
	var non_empty: int = 0
	for wv in ws:
		if str(wv) != "":
			non_empty += 1
	var yld: Dictionary = _get_decompose_yield(wid)
	var c_gain: int = int(yld.get("coins", 8))
	var mats: Dictionary = yld.get("mats", {}) as Dictionary
	Global.run_coins += c_gain
	var mat_parts: Array[String] = []
	for mk in mats:
		var qty: int = int(mats[mk])
		if qty > 0:
			Global.add_run_material(str(mk), qty)
			var mname: String = str(MaterialData.DATA.get(str(mk), {}).get("name", str(mk)))
			mat_parts.append("+%d %s" % [qty, mname])
	ws[sl] = ""
	if non_empty <= 1:
		var starter: String = str(p.hero.get("weapon", "kiem_dong"))
		var pk := Pickup.new()
		pk.kind = "weapon"
		pk.weapon_id = starter
		pk.position = global_position + Vector2(0, 18)
		par.add_child(pk)
	else:
		for i in ws.size():
			if str(ws[i]) != "":
				p.slot = i
				break
	if p.has_method("_refresh_weapon_sprite"):
		p._refresh_weapon_sprite()
	if p.has_method("sync_gold_armor"):
		p.sync_gold_armor()
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	Sfx.play("forge")
	Fx.particles(par, global_position + Vector2(0, -8), Color(0.45, 0.9, 1.0), 20, 90.0, 0.5, -35.0, 2.0)
	var summary := "+%d xu %s" % [c_gain, " ".join(mat_parts)]
	Fx.float_text(par, global_position + Vector2(0, -32), "Phân tách: %s" % summary.strip_edges(), Color(0.55, 0.95, 1.0), 14)
	_mark_used()


func _get_decompose_yield(wid: String) -> Dictionary:
	return MaterialData.decompose_yield(wid)


func _interact_statue(p: Node, par: Node) -> void:
	if not _spend_coins(p, par, cost):
		return
	Global.set("statue_id", selected_statue)
	var sinfo: Dictionary = _statue_info(selected_statue)
	var scol: Color = sinfo.get("color", Color(1.0, 0.86, 0.35)) as Color
	Sfx.play("level_clear")
	Fx.particles(par, global_position + Vector2(0, -10), scol, 24, 105.0, 0.65, -45.0, 2.2)
	Fx.burst(par, global_position, scol, 42.0, 0.45)
	Fx.float_text(par, global_position + Vector2(0, -34), "Phù hộ: %s!" % str(sinfo.get("name", selected_statue)), scol, 15)
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	_mark_used()


func _interact_mentor(p: Node, par: Node) -> void:
	if bool(Global.get("mentor_upgraded")):
		Fx.float_text(par, global_position + Vector2(0, -30), "Đã truyền thụ rồi!", Color(0.8, 0.72, 1.0), 13)
		_mark_used()
		return
	if not _spend_coins(p, par, cost):
		return
	Global.set("mentor_upgraded", true)
	if p.get("skill_timer") != null:
		p.skill_timer = 0.0
	Sfx.play("level_clear")
	Fx.particles(par, global_position + Vector2(0, -10), Color(0.75, 0.55, 1.0), 24, 105.0, 0.65, -45.0, 2.2)
	Fx.burst(par, global_position, Color(0.75, 0.55, 1.0), 42.0, 0.45)
	Fx.float_text(par, global_position + Vector2(0, -34), "Quân Sư truyền nghệ: +Sức mạnh kỹ năng!", Color(0.85, 0.72, 1.0), 15)
	if p.has_signal("stats_changed"):
		p.stats_changed.emit()
	_mark_used()


func _interact_rescue(p: Node, par: Node) -> void:
	var heal_amt: int = maxi(2, int(ceil(float(p.max_hp) * 0.5)))
	if p.has_method("heal"):
		p.heal(heal_amt)
	if p.has_method("restore_armor"):
		p.restore_armor(p.max_armor)
	if p.get("status") != null and p.status.has_method("clear"):
		p.status.clear()
	var ally := Ally.new()
	ally.owner_player = p
	ally.damage = 4 + int(level / 3)
	ally._life = 28.0
	ally.position = global_position + Vector2(20, 8)
	par.add_child(ally)
	Sfx.play("pickup_weapon")
	Fx.particles(par, global_position + Vector2(0, -8), Color(0.45, 0.95, 0.55), 20, 90.0, 0.55, -40.0, 2.0)
	Fx.float_text(par, global_position + Vector2(0, -34), "Quân Y: Hồi phục & Binh sĩ chi viện!", Color(0.5, 1.0, 0.62), 15)
	_mark_used()


func _interact_challenge(p: Node, par: Node) -> void:
	arena_active = true
	used = true
	enabled = false
	near = false
	Sfx.play("boss_appear")
	Fx.shake(get_tree(), 4.5)
	Fx.burst(par, global_position, Color(1.0, 0.35, 0.25), 54.0, 0.55)
	Fx.float_text(par, global_position + Vector2(0, -34), "Đài Thách Đấu: Quân tinh nhuệ tập kích!", Color(1.0, 0.45, 0.35), 15)
	challenge_triggered.emit(self)
	if room != null and is_instance_valid(room) and room.has_method("start_challenge_arena"):
		room.start_challenge_arena(self)
	else:
		_spawn_standalone_challenge_wave(p, par)


func _spawn_standalone_challenge_wave(p: Node, par: Node) -> void:
	var EnemyRes: Script = load("res://scripts/entities/enemy.gd") as Script
	var pool: Array = EnemyData.pool(level)
	_arena_enemies.clear()
	for i in 3:
		var ang: float = TAU * float(i) / 3.0
		var e: Node2D = EnemyRes.new()
		e.setup(str(pool.pick_random()), level, p)
		e.make_elite()
		e.position = global_position + Vector2.from_angle(ang) * 64.0
		e.killed.connect(_on_standalone_enemy_killed)
		_arena_enemies.append(e)
		par.add_child(e)


func _on_standalone_enemy_killed(e) -> void:
	_arena_enemies.erase(e)
	if _arena_enemies.is_empty() and not arena_cleared:
		mark_arena_cleared()


func mark_arena_cleared() -> void:
	if arena_cleared:
		return
	arena_active = false
	arena_cleared = true
	var par: Node = _fx_parent()
	Fx.particles(par, global_position, Color(1.0, 0.85, 0.3), 24, 110.0, 0.65, -45.0, 2.2)
	Fx.float_text(par, global_position + Vector2(0, -32), "Thắng Đài Thách Đấu!", Color(1.0, 0.88, 0.35), 15)
	if room == null or not is_instance_valid(room):
		var pk := Pickup.new()
		pk.kind = "weapon"
		pk.weapon_id = WeaponData.roll(level + 2, 2)
		pk.position = global_position + Vector2(0, 18)
		par.add_child(pk)
	queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	var acc: Color = _accent_color()
	var pulse: float = 0.5 + 0.5 * sin(_t * 3.8)
	draw_circle(Vector2(0, 6), 16.0, Color(0.0, 0.0, 0.0, 0.32))
	if not used:
		draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, 19.0 + pulse * 1.5, 0.0, TAU, 24, Color(acc, 0.35 + 0.25 * pulse), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _spr == null:
		match kind:
			"reforge_furnace":
				draw_rect(Rect2(-11, -6, 22, 13), Color("44383c"))
				draw_rect(Rect2(-9, -12, 18, 9), Color("625256"))
				draw_rect(Rect2(-6, -10, 12, 5), Color("ff8a2b") if not used else Color("3a241c"))
				if not used:
					draw_circle(Vector2(0, -14 - pulse * 2.0), 4.0, Color(1.0, 0.68, 0.22, 0.85))
					draw_rect(Rect2(-4, -18, 8, 3), Color("c4ccd8"))
			"decomposer":
				draw_rect(Rect2(-12, -4, 24, 10), Color("283c48"))
				draw_rect(Rect2(-9, -10, 18, 7), Color("3c6278"))
				var bob: float = sin(_t * 3.0) * 2.0
				draw_circle(Vector2(0, -16 + bob), 5.5, Color(0.32, 0.88, 1.0, 0.85 if not used else 0.3))
				draw_arc(Vector2(0, -16 + bob), 8.0, _t * 2.0, _t * 2.0 + PI, 12, Color("b4f4ff"), 1.4)
			"statue_shrine":
				draw_rect(Rect2(-12, -2, 24, 9), Color("5a5458"))
				draw_rect(Rect2(-8, -18, 16, 16), Color("7d767c"))
				draw_circle(Vector2(0, -22), 6.0, Color("968e94"))
				draw_circle(Vector2(0, -13), 4.0, Color(acc, 0.85 if not used else 0.35))
				draw_line(Vector2(-7, -2), Vector2(-7, -18), Color(acc, 0.6), 1.2)
				draw_line(Vector2(7, -2), Vector2(7, -18), Color(acc, 0.6), 1.2)
			"mentor_npc":
				draw_rect(Rect2(-7, -10, 14, 16), Color("3c2b5e"))
				draw_rect(Rect2(-5, -8, 10, 13), Color("6848a4"))
				draw_circle(Vector2(0, -15), 5.0, Color("f0ccb0"))
				draw_polygon(PackedVector2Array([Vector2(-7, -17), Vector2(7, -17), Vector2(0, -23)]), PackedColorArray([Color("261b3e"), Color("4a3278"), Color("d8a838")]))
				draw_rect(Rect2(5, -12, 3, 14), Color("c49242"))
			"rescue_camp":
				draw_polygon(PackedVector2Array([Vector2(-14, 4), Vector2(14, 4), Vector2(0, -19)]), PackedColorArray([Color("2a5234"), Color("22442c"), Color("3e784c")]))
				draw_rect(Rect2(-4, -10, 8, 3), Color("ff4c4c"))
				draw_rect(Rect2(-1.5, -12.5, 3, 8), Color("ff4c4c"))
			"challenge_arena":
				draw_rect(Rect2(-13, -3, 26, 9), Color("3c1c1e"))
				draw_rect(Rect2(-9, -9, 18, 7), Color("5e2428"))
				draw_line(Vector2(-6, -24), Vector2(6, -10), Color("d8dde8"), 2.0)
				draw_line(Vector2(6, -24), Vector2(-6, -10), Color("d8dde8"), 2.0)
				if not used:
					draw_circle(Vector2(0, -17), 5.0 + pulse * 1.5, Color(1.0, 0.3, 0.25, 0.35))

	Art.draw_text(self, Vector2(0, -30), _title(), 12, acc)
	if not used and cost > 0:
		var c_col: Color = Color(1.0, 0.88, 0.45) if Global.run_coins >= cost else Color(1.0, 0.48, 0.44)
		Art.draw_text(self, Vector2(0, 17), "%d xu" % cost, 11, c_col)
	elif used:
		var st_lbl: String = "Đã thắng!" if arena_cleared else ("Đang chiến đấu..." if arena_active else "Đã dùng")
		Art.draw_text(self, Vector2(0, 17), st_lbl, 11, Color(0.75, 0.72, 0.68, 0.85))
	draw_hint(-42.0)
