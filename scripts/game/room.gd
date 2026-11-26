extends Node2D
## Một phòng trong hầm ngục. Bước vào phòng có giặc: đóng cửa -> giặc tràn ra theo đợt
## -> dọn sạch thì mở cửa và hiện rương sơn mài.  kind: start, combat, treasure, shop, exit, boss, legend

signal portal_entered

const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const WeaponEvolutions = preload("res://scripts/data/weapon_evolutions.gd")
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
const EventAltar = preload("res://scripts/entities/event_altar.gd")
const MountPickup = preload("res://scripts/entities/mount_pickup.gd")
const BattlefieldHazard = preload("res://scripts/entities/battlefield_hazard.gd")

const T := 16
const MAX_ENEMIES := 28
const SPAWN_TELEGRAPH_DUR := 0.55

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
var _wave_idx := 0
var _spawn_queue: Array = []
var _next_wave_t: float = 0.0
var _chest: AnimatedSprite2D = null
var shop: Node2D = null
var blacksmith: Node2D = null
var event_altar: Node2D = null
var _challenge_altar: Node2D = null
var legend_id := ""          # phòng Tam Yêu: mã yêu quái
var loot_chest: Node2D = null
var victory_altar: Node2D = null
var covers: Array = []
var traps: Array = []
var hazards: Array = []
var _treasure_req_sent: bool = false


func _is_badass() -> bool:
	return Global != null and bool(Global.get("badass_mode"))


func _is_boss_rush() -> bool:
	return Global != null and Global.has_method("is_boss_rush") and Global.is_boss_rush()


func _has_mutator(mid: String) -> bool:
	return Global != null and Global.has_method("has_mutator") and Global.has_mutator(mid)


func _ready() -> void:
	if kind in ["combat", "boss", "legend"]:
		_spawn_covers()
		_spawn_traps()
		_spawn_biome_hazards()
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
		if randf() < 0.15 and (not Net.is_online() or Net.is_host()):
			_spawn_mount_pickup.call_deferred(rect.get_center() + Vector2(98, -26))
	if kind == "event":
		state = "done"
		_spawn_event_altar()
		if randf() < 0.28 and (not Net.is_online() or Net.is_host()):
			_spawn_mount_pickup.call_deferred(rect.get_center() + Vector2(78, 12))
	if kind == "exit" and randf() < 0.55 and not _is_boss_rush():
		_spawn_blacksmith(rect.get_center() + Vector2(-70, 0))
	if kind == "victory_hall":
		state = "done"
		var vc: Vector2 = rect.get_center()
		victory_altar = VictoryAltar.new()
		victory_altar.mythic = (level >= 32)
		victory_altar.position = vc + Vector2(0, 14)
		get_parent().add_child.call_deferred(victory_altar)
		if level == 16 and not _is_boss_rush():
			_spawn_portal.call_deferred(vc + Vector2(0, -56), "Cổng Thần Thoại (4-1)", true)
	if kind == "treasure":
		_chest = AnimatedSprite2D.new()
		_chest.sprite_frames = Art.frames("items/chest.png", 18, 11, {"closed": [[0], 1.0, false], "open": [[1], 1.0, false]})
		_chest.position = rect.get_center()
		_chest.scale = Vector2(1.5, 1.5)
		_chest.play("closed")
		add_child(_chest)
		if randf() < 0.25 and (not Net.is_online() or Net.is_host()):
			_spawn_mount_pickup.call_deferred(rect.get_center() + Vector2(68, 14))


func _process(delta: float) -> void:
	if kind == "start":
		queue_redraw()
	var lp: Node = Global.local_player()
	if lp != null and is_instance_valid(lp):
		player_inside = rect.has_point(lp.global_position)
		if player_inside:
			visited = true
	if not Net.is_online():
		if lp != null and state == "idle" and not lp.dead and rect.grow(-T * 1.5).has_point(lp.global_position):
			_enter()
	else:
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
		if not Net.is_host() and kind == "treasure" and state == "idle" and not _treasure_req_sent:
			if lp != null and is_instance_valid(lp) and not bool(lp.get("dead")) and not bool(lp.get("downed")) and inner_trigger.has_point((lp as Node2D).global_position):
				request_open_treasure()

	if state == "fighting" and (not Net.is_online() or Net.is_host()):
		if not _spawn_queue.is_empty():
			var remaining: Array = []
			for entry in _spawn_queue:
				var w: float = float(entry.get("wait", 0.0))
				if w > 0.0:
					entry["wait"] = maxf(w - delta, 0.0)
					remaining.append(entry)
				else:
					var t_left: float = float(entry.get("t", 0.0)) - delta
					if t_left <= 0.0:
						spawn_enemy(str(entry["kind"]), entry["pos"] as Vector2, bool(entry["elite"]))
					else:
						entry["t"] = t_left
						remaining.append(entry)
			_spawn_queue = remaining
			queue_redraw()
		elif kind == "combat":
			var active_mobs: int = _active_non_boss_count()
			if _waves_left > 0 and active_mobs <= 2:
				if _next_wave_t <= 0.0:
					_next_wave_t = 0.45
				else:
					_next_wave_t -= delta
					if _next_wave_t <= 0.0:
						_spawn_wave()
			elif _waves_left <= 0 and _enemies.is_empty():
				_clear.call_deferred()


static func waves_for_level(lv: int) -> int:
	if lv <= 2:
		return 2
	if lv <= 9:
		return 3
	return 4


func _effective_max_enemies() -> int:
	var cap: int = MAX_ENEMIES
	if _is_badass() or _has_mutator("elite_swarm"):
		cap += 6
	if Net.is_online() and Net.player_count() > 1:
		cap += 4 * (Net.player_count() - 1)
	return cap


func _active_non_boss_count() -> int:
	var cnt: int = 0
	for e in _enemies:
		if is_instance_valid(e) and not bool(e.get("dead")) and not e.is_boss():
			cnt += 1
	return cnt


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


func _play_combat_room_music() -> void:
	var seq: int = 1
	var gm: Node = get_tree().get_first_node_in_group("game") if is_inside_tree() else null
	if gm != null and gm.has_method("next_combat_room_music_seq"):
		seq = int(gm.next_combat_room_music_seq())
	if Sfx.has_method("play_stage_music"):
		Sfx.play_stage_music(level, seq)


func _play_boss_room_music(rkind: String) -> void:
	if Sfx.has_method("play_boss_music"):
		Sfx.play_boss_music(level, rkind, false)
	else:
		Sfx.play_music("boss")


func _enter() -> void:
	match kind:
		"combat":
			state = "fighting"
			_lock()
			if Net.is_online() and Net.is_host():
				_pull_all_players_inside()
				Net.send_world_event("room_lock", {"key": room_key, "kind": kind, "legend_id": legend_id}, false)
			_play_combat_room_music()
			_waves_left = waves_for_level(level)
			_spawn_wave()
		"boss":
			state = "fighting"
			_lock()
			if Net.is_online() and Net.is_host():
				_pull_all_players_inside()
				Net.send_world_event("room_lock", {"key": room_key, "kind": kind, "legend_id": legend_id}, false)
			Sfx.play("boss_appear")
			_play_boss_room_music("boss")
			var dbl: bool = _has_mutator("double_boss")
			var bpos: Vector2 = rect.get_center() + (Vector2(-38, -20) if dbl else Vector2(0, -20))
			spawn_enemy("boss", bpos)
			if dbl:
				spawn_enemy("boss", rect.get_center() + Vector2(38, -20))
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
			_play_boss_room_music("legend")
			var dbl_l: bool = _has_mutator("double_boss")
			var lpos: Vector2 = rect.get_center() + (Vector2(-38, -20) if dbl_l else Vector2(0, -20))
			spawn_enemy("legend:" + legend_id, lpos)
			if dbl_l:
				spawn_enemy("legend:" + legend_id, rect.get_center() + Vector2(38, -20))
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
			if Net.is_online() and not Net.is_host():
				request_open_treasure()
			else:
				open_treasure_authoritative()
		"exit":
			state = "done"
			if _is_boss_rush():
				var ec: Vector2 = rect.get_center()
				_spawn_portal(ec + Vector2(0, -24))
				if not Net.is_online() or Net.is_host():
					loot_chest = LootChest.new()
					loot_chest.level = level
					loot_chest.chest_id = room_key + "_br"
					loot_chest.position = ec + Vector2(-42, 18)
					get_parent().add_child(loot_chest)
					if randf() < 0.30:
						_spawn_mount_pickup(ec + Vector2(48, 18))
			else:
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
	if rkind == "combat":
		_play_combat_room_music()
	elif rkind == "boss":
		Sfx.play("boss_appear")
		_play_boss_room_music("boss")
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
		_play_boss_room_music("legend")
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
		Sfx.play_music("victory")
		var is_m: bool = EnemyData.is_mythic_level(level)
		var plabel: String = "Sảnh Khải Hoàn (3-6)" if level == 15 else ("Sảnh Huyền Thoại (6-6)" if level == 31 else "")
		_spawn_portal(c + Vector2(0, -30), plabel, is_m or level == 31)
		get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
	elif kind == "legend":
		Sfx.play("level_clear")
		Sfx.play_music("victory")
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


func request_open_treasure() -> void:
	if state == "done" or _treasure_req_sent:
		return
	_treasure_req_sent = true
	var parts: PackedStringArray = room_key.split(",")
	var gx: int = int(parts[0]) if parts.size() >= 2 else 0
	var gy: int = int(parts[1]) if parts.size() >= 2 else 0
	Net.send_world_event("treasure_open_req", {"key": room_key, "gx": gx, "gy": gy}, true)


func open_treasure_authoritative() -> void:
	if state == "done":
		return
	if Net.is_online() and not Net.is_host():
		request_open_treasure()
		return
	state = "done"
	visited = true
	if _chest != null:
		_chest.play("open")
	Sfx.play("chest_open")
	var c := rect.get_center()
	var chest_wid: String = WeaponData.roll_chest_weapon(level, true, _is_badass())
	_spawn_weapon(c + Vector2(0, 18), 2 if _is_badass() else 1, chest_wid)
	_drop("potion", 2, c + Vector2(-16, 16))
	_spawn_personal_blueprint_frag(c + Vector2(18, 16), "treasure")
	Fx.particles(get_parent(), c, Color(1, 0.85, 0.3), 24, 120.0, 0.7, -40.0, 2.0)
	Fx.burst(get_parent(), c, Color(1, 0.85, 0.3), 40.0, 0.5)
	if Net.is_online() and Net.is_host():
		Net.send_world_event("room_treasure", {"key": room_key}, false)


func _spawn_personal_blueprint_frag(pos: Vector2, source: String = "treasure") -> void:
	if Global == null or not Global.has_method("roll_blueprint_drop") or get_parent() == null:
		return
	var mythic: bool = EnemyData.is_mythic_level(level)
	var bp_wid: String = str(Global.roll_blueprint_drop(level, source, mythic))
	if bp_wid == "":
		return
	var p := Pickup.new()
	p.kind = "blueprint_frag"
	p.blueprint_id = bp_wid
	p.amount = 1
	p.position = pos
	get_parent().add_child(p)


func net_apply_treasure() -> void:
	if state == "done":
		return
	state = "done"
	visited = true
	if _chest != null:
		_chest.play("open")
	Sfx.play("chest_open")
	var c := rect.get_center()
	_spawn_personal_blueprint_frag(c + Vector2(18, 16), "treasure")
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


func _build_wave_composition(n: int) -> Array[String]:
	var pool := EnemyData.pool(level)
	var melee: Array[String] = []
	var ranged: Array[String] = []
	var support: Array[String] = []
	for k_v in pool:
		var k: String = str(k_v)
		if k in ["bo_binh", "ky_binh", "tieu_yeu", "dai_bang", "ma_troi", "chan_tinh"]:
			if not melee.has(k):
				melee.append(k)
		elif k in ["cung_thu", "linh_sung", "xa_thu", "phao_binh", "ho_tinh"]:
			if not ranged.has(k):
				ranged.append(k)
		elif k in ["khien_binh", "phap_su", "moc_tinh", "xe_tang", "ngu_tinh"]:
			if not support.has(k):
				support.append(k)
	var ch: Dictionary = EnemyData.chapter(level)
	if support.is_empty() and not bool(ch.get("modern", false)) and (level >= 2 or _wave_idx >= 2):
		support.append("khien_binh")
		support.append("phap_su")
	var out: Array[String] = []
	var sup_target: int = 0
	if not support.is_empty() and n >= 6:
		sup_target = 2 if n >= 11 else 1
	for _i in sup_target:
		out.append(support[randi() % support.size()])
	var melee_target: int = maxi(2, int(round(float(n) * 0.45))) if not melee.is_empty() else 0
	var ranged_target: int = maxi(2, int(round(float(n) * 0.35))) if not ranged.is_empty() else 0
	for _i in melee_target:
		if out.size() >= n:
			break
		out.append(melee[randi() % melee.size()])
	for _i in ranged_target:
		if out.size() >= n:
			break
		out.append(ranged[randi() % ranged.size()])
	while out.size() < n:
		out.append(str(pool[randi() % pool.size()]))
	out.shuffle()
	return out


func _spawn_wave() -> void:
	if state != "fighting":
		return
	if Net.is_online() and not Net.is_host():
		return
	_waves_left -= 1
	_wave_idx += 1
	_next_wave_t = 0.0
	var n: int
	var elite_chance: float
	if level <= 3:
		n = clampi(8 + (level - 1) + randi_range(0, 2), 8, 12)
		elite_chance = 0.10 + 0.03 * float(level - 1)
	elif level <= 10:
		n = clampi(11 + int((level - 4) / 2) + randi_range(0, 2), 11, 16)
		elite_chance = minf(0.16 + 0.025 * float(level - 4), 0.36)
	else:
		var depth11: int = level - 11
		n = clampi(14 + int(depth11 / 3) + randi_range(0, 2), 14, 22)
		elite_chance = clampf(0.34 + 0.012 * float(depth11), 0.34, 0.54)
	if _is_badass():
		n += 2
		elite_chance = clampf(elite_chance + 0.22, 0.0, 0.85)
	if _has_mutator("elite_swarm"):
		n += 3
		elite_chance = maxf(elite_chance, 0.80)
	if Net.is_online() and Net.player_count() > 1:
		n += 2 * (Net.player_count() - 1)
	var avail: int = maxi(1, _effective_max_enemies() - _active_non_boss_count() - _spawn_queue.size())
	n = mini(n, avail)
	var comp: Array[String] = _build_wave_composition(n)
	for i in comp.size():
		var pt: Vector2 = _random_point()
		for _retry in 4:
			var too_close: bool = false
			for q in _spawn_queue:
				if pt.distance_to(q["pos"] as Vector2) < 18.0:
					too_close = true
					break
			if not too_close:
				break
			pt = _random_point()
		_spawn_queue.append({
			"kind": comp[i],
			"pos": pt,
			"elite": randf() < elite_chance,
			"wait": float(int(i / 5)) * 0.16,
			"t": SPAWN_TELEGRAPH_DUR,
			"dur": SPAWN_TELEGRAPH_DUR,
		})
	queue_redraw()


func spawn_enemy(k: String, pos: Vector2, elite := false) -> void:
	if Net.is_online() and not Net.is_host():
		return
	var eff_max: int = _effective_max_enemies()
	if _enemies.size() >= eff_max and k != "boss" and not k.begins_with("legend:"):
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
	if is_inside_tree() and k != "boss" and not k.begins_with("legend:"):
		Fx.burst(get_parent(), clamped_pos, Color(1.0, 0.82, 0.3) if elite else Color(0.95, 0.35, 0.3), 18.0, 0.24)
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
		var other_boss_alive: bool = false
		for other_e in _enemies:
			if is_instance_valid(other_e) and not bool(other_e.get("dead")) and other_e.is_boss():
				other_boss_alive = true
				break
		if not other_boss_alive:
			_waves_left = 0
			_spawn_queue.clear()
			for other in _enemies.duplicate():
				if is_instance_valid(other):
					other.die(false)
			_enemies.clear()
	if _enemies.is_empty() and _spawn_queue.is_empty():
		if _waves_left > 0:
			if _next_wave_t <= 0.0:
				_next_wave_t = 0.45
		else:
			_clear.call_deferred()


func _boss_motif_weapon(bid: String) -> String:
	return WeaponEvolutions.boss_weapon_for(bid)


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
		Sfx.play_music("victory")
		var bonus_tier: int = 3 if _is_badass() else 2
		if _is_boss_rush():
			_spawn_weapon(c + Vector2(-28, 24), bonus_tier)
			get_tree().call_group("hud", "show_banner", "Hạ Trùm Vượt Ải %d! Tiến sang cửa kế!" % level)
		elif level == 15:
			_spawn_portal(c + Vector2(0, -30), "Sảnh Khải Hoàn (3-6)")
			_spawn_weapon(c + Vector2(-28, 24), bonus_tier)
			get_tree().call_group("hud", "show_banner", "Đại thắng 3 Chương! Bước qua cổng vào Sảnh Khải Hoàn (3-6)!")
		elif level == 31:
			_spawn_portal(c + Vector2(0, -30), "Sảnh Huyền Thoại (6-6)", true)
			_spawn_weapon(c + Vector2(-28, 24), bonus_tier)
			get_tree().call_group("hud", "show_banner", "ĐẠI THẮNG THẦN THOẠI! Vào Sảnh Huyền Thoại (6-6)!")
		else:
			_spawn_portal(c + Vector2(0, -30), "", EnemyData.is_mythic_level(level))
			_spawn_weapon(c + Vector2(-28, 24), bonus_tier)
			get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
		# Rương sơn mài thưởng Trùm + cơ hội rớt Thần Binh Trùm (Motif Weapon)
		loot_chest = LootChest.new()
		loot_chest.level = level
		loot_chest.chest_id = room_key + "_boss"
		loot_chest.position = c + Vector2(0, 14)
		get_parent().add_child(loot_chest)
		var bid: String = EnemyData.boss_id(level)
		var motif_wid: String = _boss_motif_weapon(bid)
		var milestone: bool = _is_boss_rush() and (level % 3 == 0 or level >= 10)
		var motif_chance: float = 1.0 if milestone else (0.65 if _is_badass() else (0.50 if _is_boss_rush() else 0.35))
		if motif_wid != "" and randf() < motif_chance:
			_spawn_specific_weapon(c + Vector2(30, 24), motif_wid)
	elif kind == "legend":
		Sfx.play("level_clear")
		Sfx.play_music("victory")
		_spawn_portal(c + Vector2(0, -30), "", EnemyData.is_mythic_level(level))
		_spawn_weapon(c + Vector2(0, 24), 2 if _is_badass() else 1)
		for i in 5:
			_drop_local("coin", 2, c)
		get_tree().call_group("hud", "show_banner", "Diệt yêu trừ hại, như Lạc Long Quân năm xưa!")
	else:
		# Rương sơn mài chiến lợi phẩm sau mỗi phòng dọn sạch
		loot_chest = LootChest.new()
		loot_chest.level = level
		loot_chest.chest_id = room_key
		loot_chest.position = c + Vector2(-30, 18) if _challenge_altar != null else c
		get_parent().add_child(loot_chest)
		if _is_badass():
			_drop_local("coin", 2, c + Vector2(14, 12))
		if _challenge_altar != null and is_instance_valid(_challenge_altar):
			if _challenge_altar.has_method("mark_arena_cleared"):
				_challenge_altar.mark_arena_cleared()
			_challenge_altar = null
			_spawn_weapon(c + Vector2(28, 18), 3 if _is_badass() else 2)
			var ch_bid: String = EnemyData.boss_id(level)
			var ch_motif: String = _boss_motif_weapon(ch_bid)
			if ch_motif != "" and randf() < (0.45 if _is_badass() else 0.25):
				_spawn_specific_weapon(c + Vector2(0, 26), ch_motif)
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


func _spawn_weapon(pos: Vector2, bonus: int, wid_override: String = "") -> void:
	var wid: String = wid_override if wid_override != "" else WeaponData.roll(level, bonus)
	_spawn_specific_weapon(pos, wid)


func _spawn_specific_weapon(pos: Vector2, wid: String) -> void:
	if wid == "":
		return
	var p := Pickup.new()
	p.kind = "weapon"
	p.weapon_id = wid
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


func _spawn_event_altar() -> void:
	var candidates: Array[String] = EventAltar.KINDS.duplicate()
	if bool(Global.get("mentor_upgraded")):
		candidates.erase("mentor_npc")
	var ea := EventAltar.new()
	ea.kind = candidates[randi() % candidates.size()]
	ea.level = level
	ea.room = self
	ea.position = rect.get_center() + Vector2(0, 4)
	add_child(ea)
	event_altar = ea


func _spawn_mount_pickup(pos: Vector2, mid: String = "") -> void:
	var mp := MountPickup.new()
	mp.mount_id = mid if mid != "" else MountPickup.MOUNT_ORDER[randi() % MountPickup.MOUNT_ORDER.size()]
	mp.position = pos
	get_parent().add_child(mp)


func start_challenge_arena(altar: Node2D) -> void:
	if Net.is_online() and not Net.is_host():
		return
	_challenge_altar = altar
	state = "fighting"
	_waves_left = 0
	_lock()
	_play_combat_room_music()
	var pool := EnemyData.pool(level)
	var cnt: int = 4 if _is_badass() else 3
	for i in cnt:
		spawn_enemy(pool.pick_random(), _random_point(), true)


func _is_safe_hazard_pos(pos: Vector2) -> bool:
	var inner: Rect2 = rect.grow(-T * 2.5)
	if not inner.has_point(pos):
		return false
	if pos.distance_to(rect.get_center()) < 40.0:
		return false
	for dr in door_rects:
		if (dr as Rect2).grow(50.0).has_point(pos):
			return false
	for cv in covers:
		if is_instance_valid(cv) and pos.distance_to((cv as Node2D).global_position) < 26.0:
			return false
	return true


func _add_hazard(hkind: String, pos: Vector2, phase_off: float = 0.0, h_size: Vector2 = Vector2(78, 42)) -> void:
	if not _is_safe_hazard_pos(pos):
		return
	var hz := BattlefieldHazard.new()
	hz.kind = hkind
	hz.room = self
	hz.size = h_size
	hz.phase_offset = phase_off
	hz.position = pos
	add_child(hz)
	hazards.append(hz)


func _spawn_biome_hazards() -> void:
	var ch: Dictionary = EnemyData.chapter(level)
	var theme: int = int(ch.get("theme", 0))
	var c: Vector2 = rect.get_center()
	match theme:
		1:
			# Sông nước: vùng nước làm chậm + cọc Bạch Đằng
			var w_off := Vector2(-84, -42) if randf() < 0.5 else Vector2(84, 42)
			_add_hazard("water_zone", c + w_off, 0.0, Vector2(74, 40))
			_add_hazard("bach_dang_stake", c + Vector2(-78, 48), 0.0)
			_add_hazard("bach_dang_stake", c + Vector2(78, -48), 0.3)
		0, 5, 4:
			# Núi rừng / sương mù: bụi ẩn thân + đá lở
			_add_hazard("stealth_bush", c + Vector2(-92, -46), 0.0)
			_add_hazard("stealth_bush", c + Vector2(92, 46), 0.0)
			if theme in [0, 5] and randf() < 0.7:
				_add_hazard("falling_boulder", c + Vector2(0, -64), 0.4)
				_add_hazard("falling_boulder", c + Vector2(0, 64), 2.1)
		2, 3:
			# Tết / Thành cổ: chậu lửa châm đạn
			_add_hazard("fire_brazier", c + Vector2(-74, -26), 0.0)
			_add_hazard("fire_brazier", c + Vector2(74, 26), 0.4)
		6:
			# Điện Biên Phủ: chiến hào + pháo kích
			_add_hazard("trench", c + Vector2(-86, 0), 0.0, Vector2(64, 28))
			_add_hazard("trench", c + Vector2(86, 0), 0.0, Vector2(64, 28))
			_add_hazard("mortar_flare", c + Vector2(0, -66), 0.6)
			_add_hazard("mortar_flare", c + Vector2(0, 66), 2.3)


func _draw() -> void:
	if not _spawn_queue.is_empty():
		for entry in _spawn_queue:
			if float(entry.get("wait", 0.0)) > 0.0:
				continue
			var lpos: Vector2 = to_local(entry["pos"] as Vector2)
			var dur: float = maxf(float(entry.get("dur", SPAWN_TELEGRAPH_DUR)), 0.01)
			var p: float = clampf(1.0 - float(entry.get("t", 0.0)) / dur, 0.0, 1.0)
			var is_el: bool = bool(entry.get("elite", false))
			var col: Color = Color(1.0, 0.78, 0.25) if is_el else Color(0.96, 0.30, 0.26)
			draw_set_transform(lpos, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, 13.0, Color(col.r, col.g, col.b, 0.14 + 0.16 * p))
			draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.78), 1.6)
			draw_arc(Vector2.ZERO, lerpf(18.0, 5.0, p), 0.0, TAU, 20, Color(1.0, 0.92, 0.65, 0.92), 1.4)
			draw_line(Vector2(-5.0, 0.0), Vector2(5.0, 0.0), Color(col.r, col.g, col.b, 0.7), 1.2)
			draw_line(Vector2(0.0, -5.0), Vector2(0.0, 5.0), Color(col.r, col.g, col.b, 0.7), 1.2)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
