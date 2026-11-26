extends Node2D
## Một phòng trong hầm ngục. Bước vào phòng có giặc: đóng cửa -> giặc tràn ra theo đợt
## -> dọn sạch thì mở cửa và hiện rương sơn mài.  kind: start, combat, treasure, shop, exit, boss, legend

signal portal_entered

const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Door = preload("res://scripts/entities/door.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Portal = preload("res://scripts/entities/portal.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const LootChest = preload("res://scripts/entities/loot_chest.gd")
const Shop = preload("res://scripts/game/shop.gd")
const Cover = preload("res://scripts/entities/cover.gd")
const Trap = preload("res://scripts/entities/trap.gd")
const VictoryAltar = preload("res://scripts/entities/victory_altar.gd")
const BlacksmithNpc = preload("res://scripts/entities/blacksmith_npc.gd")

const T := 16
const MAX_ENEMIES := 14

var rect := Rect2()
var kind := "combat"
var level := 1
var room_key: String = ""
var door_rects: Array = []
var state := "idle"          # idle, fighting, done
var visited := false
var player_inside := false

var _doors: Array = []
var _enemies: Array = []
var _waves_left := 0
var _chest: AnimatedSprite2D = null
var shop: Node2D = null
var blacksmith: Node2D = null
var legend_id := ""          # phòng Tam Yêu: mã yêu quái
var loot_chest: Node2D = null
var victory_altar: Node2D = null
var covers: Array = []
var traps: Array = []


func _ready() -> void:
	if kind in ["combat", "boss", "legend"]:
		_spawn_covers()
		_spawn_traps()
	if kind == "start":
		state = "done"
		# phòng đầu: màn 1 luôn có 1 vũ khí để nhặt (các màn sau 35%)
		var want_start_w: bool = (level == 1 or randf() < 0.35)
		if want_start_w and (not Net.is_online() or Net.is_host()):
			_spawn_weapon.call_deferred(rect.get_center() + Vector2(40, -10), 0)
	if kind == "shop":
		state = "done"
		shop = Shop.new()
		shop.level = level
		shop.room_key = room_key
		shop.position = rect.get_center() + Vector2(0, 6)
		add_child(shop)
		_spawn_blacksmith(rect.get_center() + Vector2(-95, -35))
	if kind == "exit" and randf() < 0.55:
		_spawn_blacksmith(rect.get_center() + Vector2(-70, 0))
	if kind == "victory_hall":
		state = "done"
		var vc: Vector2 = rect.get_center()
		victory_altar = VictoryAltar.new()
		victory_altar.mythic = (level >= 32)
		victory_altar.position = vc + Vector2(0, 14)
		get_parent().add_child.call_deferred(victory_altar)
		if level == 16:
			_spawn_portal.call_deferred(vc + Vector2(0, -56), "Cổng Thần Thoại (4-1)", true)
	if kind == "treasure":
		_chest = AnimatedSprite2D.new()
		_chest.sprite_frames = Art.frames("items/chest.png", 18, 11, {"closed": [[0], 1.0, false], "open": [[1], 1.0, false]})
		_chest.position = rect.get_center()
		_chest.scale = Vector2(1.5, 1.5)
		_chest.play("closed")
		add_child(_chest)


func _process(_delta: float) -> void:
	if kind == "start":
		queue_redraw()
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp):
		player_inside = rect.has_point(lp.global_position)
		if player_inside:
			visited = true
	if not Net.is_online():
		if lp == null:
			return
		if state == "idle" and not lp.dead and rect.grow(-T * 1.5).has_point(lp.global_position):
			_enter()
		return
	var inner_trigger: Rect2 = rect.grow(-T * 1.5)
	for pl in Global.all_players():
		if not is_instance_valid(pl):
			continue
		var ppos: Vector2 = (pl as Node2D).global_position
		if rect.has_point(ppos):
			visited = true
		if Net.is_host() and state == "idle" and not bool(pl.get("dead")) and not bool(pl.get("downed")) and inner_trigger.has_point(ppos):
			_enter()
			break


static func waves_for_level(lv: int) -> int:
	if lv <= 1:
		return 1
	if lv <= 10:
		return 2
	return 3


func _pull_all_players_inside() -> void:
	var safe_rect: Rect2 = rect.grow(-T * 2.0)
	for pl in Global.all_players():
		if not is_instance_valid(pl) or bool(pl.get("dead")):
			continue
		var n2: Node2D = pl as Node2D
		if not safe_rect.has_point(n2.global_position):
			var clamped: Vector2 = n2.global_position.clamp(safe_rect.position, safe_rect.end)
			n2.global_position = clamped
			if not bool(pl.get("is_local")):
				pl.set("_remote_pos", clamped)


func _enter() -> void:
	match kind:
		"combat":
			state = "fighting"
			_lock()
			if Net.is_online() and Net.is_host():
				_pull_all_players_inside()
				Net.send_world_event("room_lock", {"key": room_key, "kind": kind, "legend_id": legend_id}, false)
			_waves_left = waves_for_level(level)
			_spawn_wave()
		"boss":
			state = "fighting"
			_lock()
			if Net.is_online() and Net.is_host():
				_pull_all_players_inside()
				Net.send_world_event("room_lock", {"key": room_key, "kind": kind, "legend_id": legend_id}, false)
			Sfx.play("boss_appear")
			Sfx.play_music("boss")
			var bpos: Vector2 = rect.get_center() + Vector2(0, -20)
			spawn_enemy("boss", bpos)
			var bid := EnemyData.boss_id(level)
			var b: Dictionary = EnemyData.MYTHIC_BOSSES[bid] if EnemyData.MYTHIC_BOSSES.has(bid) else EnemyData.BOSSES[bid]
			var is_mythic_b: bool = EnemyData.MYTHIC_BOSSES.has(bid) or EnemyData.is_mythic_level(level)
			var bcol: Color = Color(0.84, 0.45, 1.0) if is_mythic_b else Color(1.0, 0.35, 0.25)
			var bsheet: String = str(b.get("sheet", "enemies/boss_%s.png" % bid))
			var bsize: Vector2i = b.get("size", Vector2i(48, 48))
			Fx.shake(get_tree(), 6.5)
			Fx.burst(get_parent(), bpos, bcol, 88.0, 0.7)
			Fx.burst(get_parent(), bpos, Color.WHITE, 46.0, 0.45)
			Fx.anim(get_parent(), bpos, "fx/poof.png", 28, 28, 16.0, 2.2, 0.0, bcol)
			Fx.particles(get_parent(), bpos, bcol, 28, 120.0, 0.8, -50.0, 2.5)
			get_tree().call_group("hud", "show_boss_intro", str(b.name), str(b.title), is_mythic_b, str(b.get("intro", "")), bsheet, bsize)
		"legend":
			state = "fighting"
			_lock()
			if Net.is_online() and Net.is_host():
				_pull_all_players_inside()
				Net.send_world_event("room_lock", {"key": room_key, "kind": kind, "legend_id": legend_id}, false)
			Sfx.play("boss_appear")
			Sfx.play_music("boss")
			var lpos: Vector2 = rect.get_center() + Vector2(0, -20)
			spawn_enemy("legend:" + legend_id, lpos)
			var lg: Dictionary = EnemyData.LEGENDS[legend_id]
			var is_mythic_l: bool = EnemyData.is_mythic_level(level)
			var lcol: Color = Color(0.86, 0.48, 1.0)
			var lsheet: String = "enemies/boss_%s.png" % legend_id
			var lsize: Vector2i = lg.get("size", Vector2i(84, 60))
			Fx.shake(get_tree(), 6.5)
			Fx.burst(get_parent(), lpos, lcol, 88.0, 0.7)
			Fx.burst(get_parent(), lpos, Color.WHITE, 46.0, 0.45)
			Fx.anim(get_parent(), lpos, "fx/poof.png", 28, 28, 16.0, 2.2, 0.0, lcol)
			Fx.particles(get_parent(), lpos, lcol, 26, 115.0, 0.75, -45.0, 2.5)
			get_tree().call_group("hud", "show_boss_intro", str(lg.name), str(lg.title), is_mythic_l, str(lg.get("intro", "")), lsheet, lsize)
		"treasure":
			state = "done"
			_chest.play("open")
			Sfx.play("chest_open")
			var c := rect.get_center()
			_spawn_weapon(c + Vector2(0, 18), 1)
			_drop("potion", 2, c + Vector2(-16, 16))
			Fx.particles(get_parent(), c, Color(1, 0.85, 0.3), 24, 120.0, 0.7, -40.0, 2.0)
			Fx.burst(get_parent(), c, Color(1, 0.85, 0.3), 40.0, 0.5)
			if Net.is_online() and Net.is_host():
				Net.send_world_event("room_treasure", {"key": room_key}, false)
		"exit":
			state = "done"
			_spawn_portal(rect.get_center())
			if Net.is_online() and Net.is_host():
				Net.send_world_event("room_exit", {"key": room_key}, false)


func net_apply_lock(rkind: String, leg_id: String) -> void:
	if state != "idle":
		return
	state = "fighting"
	visited = true
	_lock()
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")):
		var safe_rect: Rect2 = rect.grow(-T * 2.0)
		var l2: Node2D = lp as Node2D
		if not safe_rect.has_point(l2.global_position):
			l2.global_position = l2.global_position.clamp(safe_rect.position, safe_rect.end)
	if rkind == "boss":
		Sfx.play("boss_appear")
		Sfx.play_music("boss")
		var bid: String = EnemyData.boss_id(level)
		var b: Dictionary = EnemyData.MYTHIC_BOSSES[bid] if EnemyData.MYTHIC_BOSSES.has(bid) else EnemyData.BOSSES[bid]
		var is_mythic_b: bool = EnemyData.MYTHIC_BOSSES.has(bid) or EnemyData.is_mythic_level(level)
		var bsheet: String = str(b.get("sheet", "enemies/boss_%s.png" % bid))
		var bsize: Vector2i = b.get("size", Vector2i(48, 48))
		Fx.shake(get_tree(), 6.5)
		get_tree().call_group("hud", "show_boss_intro", str(b.name), str(b.title), is_mythic_b, str(b.get("intro", "")), bsheet, bsize)
	elif rkind == "legend":
		if leg_id != "":
			legend_id = leg_id
		Sfx.play("boss_appear")
		Sfx.play_music("boss")
		if EnemyData.LEGENDS.has(legend_id):
			var lg: Dictionary = EnemyData.LEGENDS[legend_id]
			var lsheet: String = "enemies/boss_%s.png" % legend_id
			var lsize: Vector2i = lg.get("size", Vector2i(84, 60))
			Fx.shake(get_tree(), 6.5)
			get_tree().call_group("hud", "show_boss_intro", str(lg.name), str(lg.title), EnemyData.is_mythic_level(level), str(lg.get("intro", "")), lsheet, lsize)


func net_apply_clear() -> void:
	if state == "done":
		return
	state = "done"
	for d in _doors:
		if is_instance_valid(d):
			Fx.anim(get_parent(), d.position + d.size / 2.0, "fx/poof.png", 28, 28, 16.0)
			d.queue_free()
	_doors.clear()
	var p: Node = Global.local_player()
	var c := rect.get_center()
	var near: Vector2 = (p as Node2D).global_position if (p != null and is_instance_valid(p)) else c
	for i in 3:
		_drop_local("energy", 5, near)
	if p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("hut_nang_luong") > 0 and p.has_method("restore_armor"):
		p.restore_armor(2 * p.buff("hut_nang_luong"))
	if kind == "boss":
		Sfx.play("level_clear")
		Sfx.play_music("battle")
		var is_m: bool = EnemyData.is_mythic_level(level)
		var plabel: String = "Sảnh Khải Hoàn (3-6)" if level == 15 else ("Sảnh Huyền Thoại (6-6)" if level == 31 else "")
		_spawn_portal(c + Vector2(0, -30), plabel, is_m or level == 31)
		get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
	elif kind == "legend":
		Sfx.play("level_clear")
		Sfx.play_music("battle")
		_spawn_portal(c + Vector2(0, -30), "", EnemyData.is_mythic_level(level))
		for i in 5:
			_drop_local("coin", 2, c)
		get_tree().call_group("hud", "show_banner", "Diệt yêu trừ hại, như Lạc Long Quân năm xưa!")
	else:
		loot_chest = LootChest.new()
		loot_chest.level = level
		loot_chest.chest_id = room_key
		loot_chest.position = c
		get_parent().add_child(loot_chest)


func net_apply_treasure() -> void:
	if state == "done":
		return
	state = "done"
	visited = true
	if _chest != null:
		_chest.play("open")
	Sfx.play("chest_open")
	var c := rect.get_center()
	Fx.particles(get_parent(), c, Color(1, 0.85, 0.3), 24, 120.0, 0.7, -40.0, 2.0)
	Fx.burst(get_parent(), c, Color(1, 0.85, 0.3), 40.0, 0.5)


func net_apply_exit() -> void:
	if state == "done":
		return
	state = "done"
	visited = true
	_spawn_portal(rect.get_center())


func register_replica_enemy(e: Node) -> void:
	_enemies.append(e)


func _spawn_wave() -> void:
	if state != "fighting":
		return
	if Net.is_online() and not Net.is_host():
		return
	_waves_left -= 1
	var pool := EnemyData.pool(level)
	var n: int
	var elite_chance: float
	if EnemyData.is_mythic_level(level):
		var mdepth: int = level - 17
		n = mini(7 + int(mdepth / 4) + randi() % 3, 12)
		elite_chance = clampf(0.36 + 0.012 * float(mdepth), 0.36, 0.52)
	else:
		var depth: int = mini(maxi(level - 1, 0), 15)
		n = mini(4 + int(depth / 3) + randi() % 3, 10)
		elite_chance = minf(0.10 + 0.022 * float(depth), 0.42)
	for i in n:
		spawn_enemy(pool.pick_random(), _random_point(), randf() < elite_chance)


func spawn_enemy(k: String, pos: Vector2, elite := false) -> void:
	if Net.is_online() and not Net.is_host():
		return
	if _enemies.size() >= MAX_ENEMIES and k != "boss" and not k.begins_with("legend:"):
		return
	var inner := rect.grow(-T * 1.5)
	var clamped_pos: Vector2 = pos.clamp(inner.position, inner.end)
	var e := Enemy.new()
	e.setup(k, level, Global.nearest_player(clamped_pos))
	if elite and k != "boss" and not k.begins_with("legend:"):
		e.make_elite()
	e.position = clamped_pos
	e.room = self
	e.killed.connect(_on_enemy_killed)
	if Net.is_online() and Net.is_host():
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			e.net_id = ns.alloc_enemy_id()
			ns.register_enemy(e)
	_enemies.append(e)
	get_parent().add_child(e)
	if Net.is_online() and Net.is_host() and e.net_id > 0:
		Net.send_enemy_event("spawn", {
			"id": e.net_id,
			"kind": k,
			"level": level,
			"x": e.position.x,
			"y": e.position.y,
			"elite": elite,
			"room": room_key,
			"max_hp": e.max_hp,
		}, false)


func _random_point() -> Vector2:
	var inner := rect.grow(-T * 2.0)
	var d = get_parent()
	var pos := inner.get_center()
	for i in 20:
		pos = Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y))
		var np: Node = Global.nearest_player(pos)
		var ok := np == null or pos.distance_to((np as Node2D).global_position) > 90.0
		if ok and d != null and d.get("tiles") != null:
			var tl: TileMapLayer = d.tiles
			var cell: Vector2i = tl.local_to_map(tl.to_local(pos))
			if tl.get_cell_source_id(cell) == -1 or tl.get_cell_atlas_coords(cell).x in [4, 5, 6, 7, 8]:
				ok = false
		if ok:
			for c in covers:
				if is_instance_valid(c) and pos.distance_to(c.global_position) < 24.0:
					ok = false
					break
		if ok:
			break
	return pos


func _spawn_covers() -> void:
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	var dest_kind: String = "crate" if modern else "pot"
	var solid_kind: String = "sandbag" if modern else "stele"
	var c: Vector2 = rect.get_center()
	var layouts: Array = []
	if kind == "boss" or kind == "legend":
		layouts = [
			[[Vector2(-126, -78), "pillar"], [Vector2(126, -78), "pillar"], [Vector2(-126, 78), "pillar"], [Vector2(126, 78), "pillar"], [Vector2(-152, 0), "barrel_boom"], [Vector2(152, 0), "barrel_boom"]],
			[[Vector2(-112, -76), "wall_h"], [Vector2(112, 76), "wall_h"], [Vector2(112, -76), "pillar"], [Vector2(-112, 76), "pillar"], [Vector2(-78, 84), "barrel_boom"], [Vector2(78, -84), "barrel_boom"]],
			[[Vector2(-122, -74), solid_kind], [Vector2(122, -74), solid_kind], [Vector2(-122, 74), solid_kind], [Vector2(122, 74), solid_kind], [Vector2(-86, 82), "barrel_boom"], [Vector2(86, -82), "barrel_boom"]],
		]
	else:
		layouts = [
			[[Vector2(-120, -68), "wall_h"], [Vector2(120, 68), "wall_h"], [Vector2(120, -64), "wall_v"], [Vector2(-120, 64), "wall_v"], [Vector2(-68, 74), "barrel_boom"], [Vector2(68, -74), "barrel_boom"], [Vector2(68, 74), dest_kind], [Vector2(-68, -74), dest_kind]],
			[[Vector2(-108, -66), "pillar"], [Vector2(108, -66), "pillar"], [Vector2(-108, 66), "pillar"], [Vector2(108, 66), "pillar"], [Vector2(-148, 0), "wall_v"], [Vector2(148, 0), "wall_v"], [Vector2(-66, -74), "barrel_boom"], [Vector2(66, 74), "barrel_boom"]],
			[[Vector2(-86, -76), "wall_h"], [Vector2(86, 76), "wall_h"], [Vector2(144, 0), "pillar"], [Vector2(-144, 0), "pillar"], [Vector2(-128, 64), "barrel_boom"], [Vector2(128, -64), "barrel_boom"], [Vector2(-86, 76), dest_kind], [Vector2(86, -76), dest_kind]],
			[[Vector2(-124, -78), "wall_h"], [Vector2(124, -78), "wall_h"], [Vector2(-124, 78), "wall_h"], [Vector2(124, 78), "wall_h"], [Vector2(-86, -78), dest_kind], [Vector2(86, 78), dest_kind], [Vector2(-116, 42), "barrel_boom"], [Vector2(116, -42), "barrel_boom"]],
			[[Vector2(-136, -68), "pillar"], [Vector2(0, -82), "pillar"], [Vector2(136, -68), "pillar"], [Vector2(-136, 68), "pillar"], [Vector2(0, 82), "pillar"], [Vector2(136, 68), "pillar"], [Vector2(-84, 0), "barrel_boom"], [Vector2(84, 0), "barrel_boom"]],
			[[Vector2(-98, -60), "wall_v"], [Vector2(98, 60), "wall_v"], [Vector2(114, -64), solid_kind], [Vector2(-114, 64), solid_kind], [Vector2(-72, 68), "barrel_boom"], [Vector2(72, -68), "barrel_boom"], [Vector2(142, 0), "barrel_boom"], [Vector2(-142, 0), dest_kind]],
		]
	var chosen: Array = layouts[randi() % layouts.size()]
	for item in chosen:
		var pos: Vector2 = c + (item[0] as Vector2)
		if pos.distance_to(c) < 48.0:
			continue
		var near_door: bool = false
		for dr in door_rects:
			if (dr as Rect2).grow(54.0).has_point(pos):
				near_door = true
				break
		if near_door:
			continue
		var cv := Cover.new()
		cv.kind = str(item[1])
		cv.position = pos
		add_child(cv)
		covers.append(cv)


func _spawn_traps() -> void:
	var chance: float = 0.35 if (kind == "boss" or kind == "legend") else 0.55
	if randf() >= chance:
		return
	var c: Vector2 = rect.get_center()
	var patterns: Array = [
		[Vector2(-88, -56), Vector2(88, -56), Vector2(-88, 56), Vector2(88, 56)],
		[Vector2(-132, -48), Vector2(132, 48), Vector2(-72, 68), Vector2(72, -68)],
		[Vector2(-104, 0), Vector2(104, 0), Vector2(0, -76), Vector2(0, 76)],
		[Vector2(-76, -54), Vector2(76, -54), Vector2(-76, 54), Vector2(76, 54), Vector2(0, -82), Vector2(0, 82)],
	]
	var trap_kinds: Array[String] = ["spike", "fire_vent", "poison_vent"]
	var primary: String = trap_kinds[randi() % trap_kinds.size()]
	var mix_other: bool = randf() < 0.35
	var chosen_pts: Array = patterns[randi() % patterns.size()]
	for idx in chosen_pts.size():
		var pos: Vector2 = c + (chosen_pts[idx] as Vector2)
		if pos.distance_to(c) < 48.0:
			continue
		var bad: bool = false
		for dr in door_rects:
			if (dr as Rect2).grow(52.0).has_point(pos):
				bad = true
				break
		if not bad:
			for cv in covers:
				if is_instance_valid(cv) and pos.distance_to((cv as Node2D).global_position) < 28.0:
					bad = true
					break
		if bad:
			continue
		var tp := Trap.new()
		tp.kind = trap_kinds[(trap_kinds.find(primary) + (idx % 2)) % trap_kinds.size()] if mix_other else primary
		tp.room = self
		tp.phase_offset = 0.0 if (idx % 2 == 0) else 1.9
		tp.position = pos
		add_child(tp)
		traps.append(tp)


func _on_enemy_killed(e) -> void:
	_enemies.erase(e)
	if Net.is_online() and not Net.is_host():
		return
	if e.is_boss():
		_waves_left = 0
		for other in _enemies.duplicate():
			if is_instance_valid(other):
				other.die(false)
		_enemies.clear()
	if _enemies.is_empty():
		if _waves_left > 0:
			get_tree().create_timer(0.7).timeout.connect(_spawn_wave)
		else:
			_clear.call_deferred()


func _clear() -> void:
	if state == "done":
		return
	state = "done"
	for d in _doors:
		if is_instance_valid(d):
			Fx.anim(get_parent(), d.position + d.size / 2.0, "fx/poof.png", 28, 28, 16.0)
			d.queue_free()
	_doors.clear()
	var p: Node = Global.local_player()
	var c := rect.get_center()
	var near: Vector2 = (p as Node2D).global_position if (p != null and is_instance_valid(p)) else c
	for i in 3:
		_drop_local("energy", 5, near)
	if p != null and is_instance_valid(p) and p.has_method("buff") and p.buff("hut_nang_luong") > 0 and p.has_method("restore_armor"):
		p.restore_armor(2 * p.buff("hut_nang_luong"))
	if kind == "boss":
		Sfx.play("level_clear")
		Sfx.play_music("battle")
		if level == 15:
			_spawn_portal(c + Vector2(0, -30), "Sảnh Khải Hoàn (3-6)")
			_spawn_weapon(c + Vector2(0, 24), 2)
			get_tree().call_group("hud", "show_banner", "Đại thắng 3 Chương! Bước qua cổng vào Sảnh Khải Hoàn (3-6)!")
		elif level == 31:
			_spawn_portal(c + Vector2(0, -30), "Sảnh Huyền Thoại (6-6)", true)
			_spawn_weapon(c + Vector2(0, 24), 2)
			get_tree().call_group("hud", "show_banner", "ĐẠI THẮNG THẦN THOẠI! Vào Sảnh Huyền Thoại (6-6)!")
		else:
			_spawn_portal(c + Vector2(0, -30), "", EnemyData.is_mythic_level(level))
			_spawn_weapon(c + Vector2(0, 24), 2)
			get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
	elif kind == "legend":
		Sfx.play("level_clear")
		Sfx.play_music("battle")
		_spawn_portal(c + Vector2(0, -30), "", EnemyData.is_mythic_level(level))
		_spawn_weapon(c + Vector2(0, 24), 1)
		for i in 5:
			_drop_local("coin", 2, c)
		get_tree().call_group("hud", "show_banner", "Diệt yêu trừ hại, như Lạc Long Quân năm xưa!")
	else:
		# rương sơn mài chiến lợi phẩm sau mỗi phòng dọn sạch
		loot_chest = LootChest.new()
		loot_chest.level = level
		loot_chest.chest_id = room_key
		loot_chest.position = c
		get_parent().add_child(loot_chest)
	if Net.is_online() and Net.is_host():
		Net.send_world_event("room_clear", {"key": room_key}, false)


func _lock() -> void:
	if not door_rects.is_empty():
		Sfx.play("door_close")
	for r in door_rects:
		var d := Door.new()
		d.size = r.size
		d.position = r.position
		get_parent().add_child(d)
		_doors.append(d)


func drop_weapon_at(pos: Vector2, bonus: int) -> void:
	_spawn_weapon.call_deferred(pos, bonus)


func _spawn_weapon(pos: Vector2, bonus: int) -> void:
	var p := Pickup.new()
	p.kind = "weapon"
	p.weapon_id = WeaponData.roll(level, bonus)
	p.position = pos
	if Net.is_online() and Net.is_host():
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			p.pickup_id = ns.alloc_pickup_id()
			get_parent().add_child(p)
			ns.register_pickup(p)
			Net.send_world_event("spawn_pickup", {
				"id": p.pickup_id,
				"kind": "weapon",
				"amount": 1,
				"weapon_id": p.weapon_id,
				"material_id": "",
				"x": pos.x,
				"y": pos.y,
			}, false)
			return
	get_parent().add_child(p)


func _drop(k: String, amount: int, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = pos
	if Net.is_online() and Net.is_host() and (k == "potion" or k == "potion_big" or k == "potion_energy"):
		var ns: Node = get_tree().get_first_node_in_group("net_sync")
		if ns != null:
			p.pickup_id = ns.alloc_pickup_id()
			get_parent().add_child(p)
			ns.register_pickup(p)
			Net.send_world_event("spawn_pickup", {
				"id": p.pickup_id,
				"kind": k,
				"amount": amount,
				"weapon_id": "",
				"material_id": "",
				"x": pos.x,
				"y": pos.y,
			}, false)
			return
	get_parent().add_child(p)


func _drop_local(k: String, amount: int, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = pos
	get_parent().add_child(p)


func _spawn_portal(pos: Vector2, portal_label: String = "", is_mythic: bool = false) -> void:
	var portal := Portal.new()
	portal.position = pos
	portal.mythic = is_mythic
	if portal_label != "":
		portal.label = portal_label
	portal.entered.connect(func(): portal_entered.emit())
	get_parent().add_child(portal)


func _spawn_blacksmith(pos: Vector2) -> void:
	var bn := BlacksmithNpc.new()
	bn.level = level
	bn.position = pos
	add_child(bn)
	blacksmith = bn


func _draw() -> void:
	if kind != "start":
		return
	var c := rect.get_center()
	var lines: Array
	if Global.touch_mode:
		lines = ["Cần gạt trái: di chuyển (tự ngắm giặc gần nhất)",
			"Nút phải: Đánh - Kỹ năng - Đổi/Nhặt vũ khí"]
	else:
		lines = ["WASD: di chuyển  -  Chuột trái: tấn công  -  Chuột phải / Space: kỹ năng",
			"Lăn chuột / Q: đổi vũ khí  -  E: nhặt / dùng  -  Esc: dừng"]
	for i in lines.size():
		Art.draw_text(self, c + Vector2(0, 62 + i * 13), lines[i], 13, Color(1, 1, 1, 0.6))
