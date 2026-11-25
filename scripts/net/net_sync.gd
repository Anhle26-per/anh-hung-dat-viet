extends Node
## Đồng bộ kẻ địch và vật phẩm giữa Chủ phòng (Host) và máy khách trong chế độ LAN.
## Chỉ được gắn vào game.gd khi Net.is_online() == true.

const Enemy = preload("res://scripts/entities/enemy.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const MortarStrike = preload("res://scripts/effects/mortar_strike.gd")
const Miasma = preload("res://scripts/effects/miasma.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const BATCH_INTERVAL: float = 1.0 / 15.0

var game: Node = null
var enemy_by_id: Dictionary = {}
var pickup_by_id: Dictionary = {}
var claimed_pickups: Dictionary = {}
var sold_stands: Dictionary = {}
var opened_chests: Dictionary = {}
var is_clearing_level: bool = false

var _batch_t: float = 0.0
var _next_enemy_id: int = 1
var _next_pickup_id: int = 1


func _ready() -> void:
	add_to_group("net_sync")
	Net.enemy_batch_received.connect(_on_enemy_batch)
	Net.enemy_event_received.connect(_on_enemy_event)


func _exit_tree() -> void:
	if Net.enemy_batch_received.is_connected(_on_enemy_batch):
		Net.enemy_batch_received.disconnect(_on_enemy_batch)
	if Net.enemy_event_received.is_connected(_on_enemy_event):
		Net.enemy_event_received.disconnect(_on_enemy_event)


func alloc_enemy_id() -> int:
	var id: int = _next_enemy_id
	_next_enemy_id += 1
	return id


func alloc_pickup_id() -> int:
	var id: int = _next_pickup_id
	_next_pickup_id += 1
	return id


func register_enemy(e: Node) -> void:
	if e != null and is_instance_valid(e):
		var nid: int = int(e.get("net_id"))
		if nid > 0:
			enemy_by_id[nid] = e


func unregister_enemy(net_id: int) -> void:
	enemy_by_id.erase(net_id)


func get_enemy(net_id: int) -> Node:
	if not enemy_by_id.has(net_id):
		return null
	var e: Variant = enemy_by_id[net_id]
	if e != null and is_instance_valid(e):
		return e as Node
	enemy_by_id.erase(net_id)
	return null


func register_pickup(p: Node) -> void:
	if p != null and is_instance_valid(p):
		var pid: int = int(p.get("pickup_id"))
		if pid > 0:
			pickup_by_id[pid] = p


func unregister_pickup(pid: int) -> void:
	pickup_by_id.erase(pid)


func get_pickup(pid: int) -> Node:
	if not pickup_by_id.has(pid):
		return null
	var p: Variant = pickup_by_id[pid]
	if p != null and is_instance_valid(p):
		return p as Node
	pickup_by_id.erase(pid)
	return null


func clear_level_maps() -> void:
	enemy_by_id.clear()
	pickup_by_id.clear()
	claimed_pickups.clear()
	sold_stands.clear()
	opened_chests.clear()


func _physics_process(delta: float) -> void:
	if not Net.is_online() or not Net.is_host():
		return
	_batch_t += delta
	if _batch_t < BATCH_INTERVAL:
		return
	_batch_t = 0.0
	var batch: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or bool(node.get("dead")):
			continue
		var nid: int = int(node.get("net_id"))
		if nid <= 0:
			continue
		var pos: Vector2 = (node as Node2D).global_position
		var anim_name: String = node.current_anim_name() if node.has_method("current_anim_name") else "walk"
		batch.append([
			nid,
			pos.x,
			pos.y,
			int(node.get("hp")),
			int(node.get("max_hp")),
			anim_name,
			float(node.get("_face")),
			bool(node.get("transformed")),
			bool(node.get("_submerged")),
		])
	if not batch.is_empty():
		Net.send_enemy_batch(batch)


func _on_enemy_batch(batch: Array) -> void:
	if Net.is_host():
		return
	for row in batch:
		if not (row is Array):
			continue
		var arr: Array = row
		if arr.size() < 9:
			continue
		var nid: int = int(arr[0])
		var e: Node = get_enemy(nid)
		if e != null and e.has_method("apply_net_state"):
			e.apply_net_state(
				Vector2(float(arr[1]), float(arr[2])),
				int(arr[3]),
				int(arr[4]),
				str(arr[5]),
				float(arr[6]),
				bool(arr[7]),
				bool(arr[8])
			)


func _on_enemy_event(kind: String, data: Dictionary) -> void:
	match kind:
		"dmg_req":
			if not Net.is_host():
				return
			var nid: int = int(data.get("id", 0))
			var dmg: int = clampi(int(data.get("dmg", 0)), 1, 250)
			var knock := Vector2(float(data.get("kx", 0.0)), float(data.get("ky", 0.0)))
			var e: Node = get_enemy(nid)
			if e != null and not bool(e.get("dead")):
				e.take_damage(dmg, knock)
		"stun_req":
			if not Net.is_host():
				return
			var nid2: int = int(data.get("id", 0))
			var dur: float = clampf(float(data.get("t", 0.0)), 0.0, 5.0)
			var e2: Node = get_enemy(nid2)
			if e2 != null and not bool(e2.get("dead")) and e2.has_method("apply_stun"):
				e2.apply_stun(dur)
		"status_req":
			if not Net.is_host():
				return
			var nid3: int = int(data.get("id", 0))
			var skind: String = str(data.get("kind", ""))
			var sdur: float = clampf(float(data.get("dur", 0.0)), 0.0, 10.0)
			var e3: Node = get_enemy(nid3)
			if e3 != null and not bool(e3.get("dead")) and e3.has_method("apply_status") and skind in ["burn", "poison"]:
				e3.apply_status(skind, sdur)
		"spawn":
			if Net.is_host():
				return
			_handle_client_spawn(data)
		"die":
			if Net.is_host():
				return
			var nid4: int = int(data.get("id", 0))
			var e4: Node = get_enemy(nid4)
			unregister_enemy(nid4)
			if e4 != null and not bool(e4.get("dead")) and e4.has_method("die_from_net"):
				e4.die_from_net(bool(data.get("drop", true)))
		"morph":
			if Net.is_host():
				return
			var nid5: int = int(data.get("id", 0))
			var phase: String = str(data.get("phase", "start"))
			var e5: Node = get_enemy(nid5)
			if e5 != null and not bool(e5.get("dead")):
				if phase == "start" and e5.has_method("net_start_morph"):
					e5.net_start_morph()
				elif phase == "finish" and e5.has_method("net_finish_morph"):
					e5.net_finish_morph()
				elif phase == "enrage" and e5.has_method("net_enrage"):
					e5.net_enrage()
				elif phase == "special" and e5.has_method("net_special_banner"):
					e5.net_special_banner(str(data.get("sp", "")))
		"bullet":
			if Net.is_host():
				return
			_handle_client_bullet(data)
		"mortar":
			if Net.is_host():
				return
			_handle_client_mortar(data)
		"miasma":
			if Net.is_host():
				return
			_handle_client_miasma(data)


func _world_parent() -> Node:
	if game == null or not is_instance_valid(game):
		return null
	var d: Variant = game.get("dungeon")
	if d != null and is_instance_valid(d):
		return d as Node
	var w: Variant = game.get("world")
	if w != null and is_instance_valid(w):
		return w as Node
	return null


func _handle_client_spawn(data: Dictionary) -> void:
	var nid: int = int(data.get("id", 0))
	if nid <= 0 or get_enemy(nid) != null:
		return
	var par: Node = _world_parent()
	if par == null:
		return
	var k: String = str(data.get("kind", "bo_binh"))
	var lvl: int = int(data.get("level", Global.level))
	var pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	var is_elite: bool = bool(data.get("elite", false))
	var rkey: String = str(data.get("room", ""))
	var mhp: int = int(data.get("max_hp", 0))
	var e := Enemy.new()
	e.net_id = nid
	e.is_replica = true
	e.setup(k, lvl, Global.nearest_player(pos))
	if is_elite and k != "boss" and not k.begins_with("legend:"):
		e.make_elite()
	if mhp > 0:
		e.max_hp = mhp
		e.hp = mhp
	e.position = pos
	e._net_pos = pos
	if par.has_method("get_room_by_key"):
		var rm: Node = par.get_room_by_key(rkey)
		e.room = rm
		if rm != null and rm.has_method("register_replica_enemy"):
			rm.register_replica_enemy(e)
	par.add_child(e)
	register_enemy(e)


func _handle_client_bullet(data: Dictionary) -> void:
	var par: Node = _world_parent()
	if par == null:
		return
	var pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	var dir := Vector2(float(data.get("dx", 1.0)), float(data.get("dy", 0.0))).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var spd: float = float(data.get("spd", 150.0))
	var dmg: int = int(data.get("dmg", 1))
	var life: float = float(data.get("life", 4.0))
	var proj: String = str(data.get("proj", "orb_pink"))
	var exp_r: float = float(data.get("exp", 0.0))
	var ox: float = float(data.get("ox", pos.x))
	var oy: float = float(data.get("oy", pos.y))
	var b := Bullet.new()
	b.setup(false, pos, dir, spd, dmg, life, proj)
	b.spawn_origin = Vector2(ox, oy)
	b.explode_radius = exp_r
	if proj == "arrow" or proj == "bullet":
		b.color = Color(1.0, 0.55, 0.5)
	par.add_child(b)
	if bool(data.get("muzzle", false)):
		Fx.anim(par, pos, "fx/muzzle.png", 12, 10, 24.0, 1.4, dir.angle(), Color.WHITE, true, 6)


func _handle_client_mortar(data: Dictionary) -> void:
	var par: Node = _world_parent()
	if par == null:
		return
	var m := MortarStrike.new()
	m.position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	m.delay = float(data.get("delay", 1.0))
	m.root = bool(data.get("root", false))
	var rad: float = float(data.get("radius", 0.0))
	if rad > 0.0:
		m.radius = rad
	par.add_child(m)


func _handle_client_miasma(data: Dictionary) -> void:
	var par: Node = _world_parent()
	if par == null:
		return
	var m := Miasma.new()
	m.position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	m.from_player = false
	m.color = Color(float(data.get("r", 0.45)), float(data.get("g", 0.85)), float(data.get("b", 0.3)))
	par.add_child(m)
