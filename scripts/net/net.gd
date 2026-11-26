extends Node
## Quản lý mạng LAN (autoload "Net"):
## ENetMultiplayerPeer (cổng 7777), tối đa 4 người, Chủ phòng làm máy chủ & nắm hồ sơ lưu game.

const DEFAULT_PORT: int = 7777
const DISCOVERY_PORT: int = 7778
const MAX_PLAYERS: int = 4
const PLAYER_COLORS: Array[Color] = [
	Color(1.0, 0.88, 0.35),
	Color(0.42, 0.86, 1.0),
	Color(0.55, 1.0, 0.55),
	Color(1.0, 0.58, 0.78),
]
const RECONNECT_GRACE_MS: int = 60000

const DiscoveryScript = preload("res://scripts/net/discovery.gd")
const HeroData = preload("res://scripts/data/heroes.gd")

signal lobby_updated()
signal entered_lan_lobby()
signal match_started(seed_val: int, level: int)
signal host_left(reason: String)
signal player_disconnected_midrun(peer_id: int, pname: String)
signal player_reconnected_midrun(peer_id: int, info: Dictionary)
signal player_state_received(peer_id: int, state: Dictionary)
signal player_action_received(peer_id: int, kind: String, data: Dictionary)
signal enemy_batch_received(batch: Array)
signal enemy_event_received(kind: String, data: Dictionary)
signal world_event_received(kind: String, data: Dictionary)
signal down_event_received(kind: String, peer_id: int, data: Dictionary)
signal connection_failed(reason: String)
signal connected_to_room()

var players: Dictionary = {}             # peer_id: int -> {id, name, hero, ready, color, downed, slot_idx}
var disconnected_slots: Dictionary = {}  # player_name: String -> {hero, color, slot_idx, expires_ms}
var host_profile: Dictionary = {}        # {unlocked, upgrades, hero_levels, weapon_ranks, difficulty}
var match_seed: int = 0
var in_lobby: bool = false
var in_match: bool = false
var room_name: String = ""
var ping_ms: int = 0
var disconnect_notice: String = ""

var _local_player_name: String = "Anh Hùng"
var _discovery: Node = null
var _ping_timer: float = 0.0
var _game_port: int = DEFAULT_PORT
var _leaving: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_discovery = DiscoveryScript.new()
	add_child(_discovery)


func _exit_tree() -> void:
	leave_room()


func _process(delta: float) -> void:
	if not is_online():
		_ping_timer = 0.0
		return
	if is_host():
		_prune_disconnected_slots()
		ping_ms = 0
	else:
		_ping_timer += delta
		if _ping_timer >= 1.0:
			_ping_timer = 0.0
			_rpc_ping.rpc_id(1, Time.get_ticks_msec())


# ------------------------------------------------------------------ Hàm trợ giúp trạng thái

func is_online() -> bool:
	return multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func is_host() -> bool:
	return not is_online() or multiplayer.is_server()


func local_peer_id() -> int:
	return multiplayer.get_unique_id() if is_online() else 1


func player_count() -> int:
	return maxi(1, players.size()) if is_online() else 1


func local_lan_ips() -> PackedStringArray:
	var priv: PackedStringArray = PackedStringArray()
	var other: PackedStringArray = PackedStringArray()
	for raw_addr in IP.get_local_addresses():
		var s: String = str(raw_addr)
		if not s.contains(".") or s.contains(":"):
			continue
		if s == "127.0.0.1" or s == "0.0.0.0" or s.begins_with("169.254."):
			continue
		if s.begins_with("192.168.") or s.begins_with("10.") or s.begins_with("172."):
			if not priv.has(s):
				priv.append(s)
		else:
			if not other.has(s):
				other.append(s)
	var out: PackedStringArray = PackedStringArray()
	for a in priv:
		out.append(a)
	for b in other:
		out.append(b)
	return out


# ------------------------------------------------------------------ Tạo / Vào / Rời phòng

func create_room(rname: String, pname: String, port: int = DEFAULT_PORT) -> int:
	leave_room()
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_game_port = port
	_local_player_name = _sanitize_name(pname)
	var clean_rname: String = rname.strip_edges()
	room_name = clean_rname if clean_rname != "" else "Phòng của %s" % _local_player_name
	host_profile = _build_host_profile()
	match_seed = 0
	in_lobby = false
	in_match = false
	ping_ms = 0
	disconnect_notice = ""
	disconnected_slots.clear()
	players.clear()

	var hero_id: String = _default_hero_from_profile()
	var pet_id: String = Global.selected_pet if Global.PETS.has(Global.selected_pet) else ""
	Global.selected_hero = hero_id
	players[1] = {
		"id": 1,
		"name": _local_player_name,
		"hero": hero_id,
		"pet": pet_id,
		"hero_confirmed": false,
		"ready": true,
		"color": PLAYER_COLORS[0],
		"downed": false,
		"slot_idx": 0,
	}
	if _discovery != null:
		_discovery.start_broadcast(room_name, _game_port, players.size(), MAX_PLAYERS, in_match, DISCOVERY_PORT)
	lobby_updated.emit()
	return OK


func join_room(ip: String, pname: String, port: int = DEFAULT_PORT) -> int:
	leave_room()
	var clean_ip: String = ip.strip_edges()
	if clean_ip == "":
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_client(clean_ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_game_port = port
	_local_player_name = _sanitize_name(pname)
	room_name = ""
	host_profile = {}
	match_seed = 0
	in_lobby = false
	in_match = false
	ping_ms = 0
	disconnect_notice = ""
	disconnected_slots.clear()
	players.clear()
	return OK


func leave_room() -> void:
	_leaving = true
	if _discovery != null:
		_discovery.stop()
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	disconnected_slots.clear()
	host_profile.clear()
	match_seed = 0
	in_lobby = false
	in_match = false
	room_name = ""
	ping_ms = 0
	_ping_timer = 0.0
	_leaving = false
	lobby_updated.emit()


# ------------------------------------------------------------------ Sảnh chờ & Bắt đầu trận

func request_set_hero(hid: String) -> void:
	if not is_online():
		return
	if not HeroData.DATA.has(hid):
		return
	var unlocked_list: Array = host_profile.get("unlocked", [])
	if not unlocked_list.has(hid):
		return
	if is_host():
		_apply_set_hero(1, hid)
	else:
		_rpc_set_hero.rpc_id(1, hid)


func request_set_ready(ready: bool) -> void:
	if not is_online():
		return
	if is_host():
		_apply_set_ready(1, ready)
	else:
		_rpc_set_ready.rpc_id(1, ready)


func request_set_pet(pet_id: String) -> void:
	if not is_online():
		return
	if pet_id != "" and not Global.PETS.has(pet_id):
		return
	if is_host():
		_apply_set_pet(1, pet_id)
	else:
		_rpc_set_pet.rpc_id(1, pet_id)


func all_peers_confirmed() -> bool:
	if players.is_empty():
		return false
	for pid in players:
		if not bool(players[pid].get("hero_confirmed", false)):
			return false
	return true


func host_enter_lobby() -> void:
	if not is_online() or not is_host():
		return
	in_lobby = true
	in_match = false
	host_profile = _build_host_profile()
	for pid in players:
		var info: Dictionary = players[pid]
		info["hero_confirmed"] = false
		if int(pid) != 1:
			info["ready"] = false
		players[pid] = info
	_update_discovery()
	_rpc_enter_lan_lobby.rpc(room_name, host_profile, players, in_lobby)


func host_start_match() -> void:
	if not is_online() or not is_host():
		return
	host_profile = _build_host_profile()
	if players.has(1):
		Global.selected_hero = str(players[1].get("hero", _default_hero_from_profile()))
	match_seed = randi() & 0x7FFFFFFF
	if match_seed == 0:
		match_seed = 1
	in_lobby = false
	in_match = true
	Global.start_run()
	seed(match_seed)
	Global.boss_order = []
	Global.boss_at(0)
	for pid in players:
		var pinfo: Dictionary = players[pid]
		pinfo["downed"] = false
		players[pid] = pinfo
	_update_discovery()
	_rpc_start_match.rpc(match_seed, Global.level, Global.boss_order, host_profile, players)


# ------------------------------------------------------------------ Truyền tin trong trận (Relay)

func send_player_state(state: Dictionary) -> void:
	if not is_online():
		return
	_rpc_player_state.rpc(state)


func send_player_action(kind: String, data: Dictionary) -> void:
	if not is_online():
		return
	_rpc_player_action.rpc(kind, data)


func send_enemy_batch(batch: Array) -> void:
	if not is_online() or not is_host():
		return
	_rpc_enemy_batch.rpc(batch)


func send_enemy_event(kind: String, data: Dictionary, to_host_only: bool = false) -> void:
	if not is_online():
		return
	if to_host_only:
		_rpc_enemy_req.rpc_id(1, kind, data)
	elif is_host():
		_rpc_enemy_ev.rpc(kind, data)


func send_world_event(kind: String, data: Dictionary, to_host_only: bool = false) -> void:
	if not is_online():
		return
	if to_host_only:
		_rpc_world_req.rpc_id(1, kind, data)
	elif is_host():
		_rpc_world_ev.rpc(kind, data)


func send_down_event(kind: String, target_peer: int, data: Dictionary = {}) -> void:
	if not is_online():
		return
	if is_host():
		var payload: Dictionary = data.duplicate()
		if not payload.has("sender"):
			payload["sender"] = 1
		_rpc_down_ev.rpc(kind, target_peer, payload)
	else:
		_rpc_down_req.rpc_id(1, kind, target_peer, data)


# ------------------------------------------------------------------ RPC Sảnh chờ & Ping

@rpc("any_peer", "call_remote", "reliable")
func _rpc_register_player(pname: String) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 1:
		return
	var clean_name: String = _sanitize_name(pname)
	_prune_disconnected_slots()

	if in_match:
		if disconnected_slots.has(clean_name):
			var slot: Dictionary = disconnected_slots[clean_name]
			disconnected_slots.erase(clean_name)
			var hero_id: String = str(slot.get("hero", _default_hero_from_profile()))
			var unlocked_list: Array = host_profile.get("unlocked", [])
			if not unlocked_list.has(hero_id):
				hero_id = _default_hero_from_profile()
			var sidx: int = int(slot.get("slot_idx", _allocate_slot_idx()))
			var col: Color = slot.get("color", PLAYER_COLORS[sidx % PLAYER_COLORS.size()])
			var info: Dictionary = {
				"id": sender,
				"name": clean_name,
				"hero": hero_id,
				"pet": str(slot.get("pet", "")),
				"hero_confirmed": true,
				"ready": true,
				"color": col,
				"downed": false,
				"slot_idx": sidx,
			}
			players[sender] = info
			_update_discovery()
			_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)
			_rpc_start_match.rpc_id(sender, match_seed, Global.level, Global.boss_order, host_profile, players)
			_rpc_player_reconnected.rpc(sender, info)
			return
		_rpc_kicked.rpc_id(sender, "Trận đấu đã bắt đầu.")
		_disconnect_client_later(sender)
		return

	if players.size() >= MAX_PLAYERS:
		_rpc_kicked.rpc_id(sender, "Phòng đã đủ %d người." % MAX_PLAYERS)
		_disconnect_client_later(sender)
		return

	var unique_name: String = _make_unique_name(clean_name)
	var slot_idx: int = _allocate_slot_idx()
	var hero_id: String = _pick_open_hero()
	var col: Color = PLAYER_COLORS[slot_idx % PLAYER_COLORS.size()]
	players[sender] = {
		"id": sender,
		"name": unique_name,
		"hero": hero_id,
		"pet": "",
		"hero_confirmed": false,
		"ready": false,
		"color": col,
		"downed": false,
		"slot_idx": slot_idx,
	}
	_update_discovery()
	_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)
	if in_lobby and not in_match:
		_rpc_enter_lan_lobby.rpc_id(sender, room_name, host_profile, players, in_lobby)


@rpc("authority", "call_local", "reliable")
func _rpc_sync_lobby(rname: String, profile: Dictionary, p_map: Dictionary, running: bool, lobby_flag: bool = false) -> void:
	room_name = rname
	host_profile = profile.duplicate(true)
	players = _normalize_players_dict(p_map)
	in_match = running
	in_lobby = lobby_flag
	var my_id: int = local_peer_id()
	if players.has(my_id):
		Global.selected_hero = str(players[my_id].get("hero", Global.selected_hero))
	lobby_updated.emit()


@rpc("authority", "call_local", "reliable")
func _rpc_enter_lan_lobby(rname: String, profile: Dictionary, p_map: Dictionary, lobby_flag: bool) -> void:
	room_name = rname
	host_profile = profile.duplicate(true)
	players = _normalize_players_dict(p_map)
	in_lobby = lobby_flag
	in_match = false
	var my_id: int = local_peer_id()
	if players.has(my_id):
		Global.selected_hero = str(players[my_id].get("hero", Global.selected_hero))
	entered_lan_lobby.emit()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_hero(hid: String) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_apply_set_hero(sender, hid)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_ready(ready: bool) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_apply_set_ready(sender, ready)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_pet(pet_id: String) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_apply_set_pet(sender, pet_id)


@rpc("authority", "call_local", "reliable")
func _rpc_start_match(seed_val: int, level_val: int, b_order: Array, profile: Dictionary, p_map: Dictionary) -> void:
	match_seed = seed_val
	in_lobby = false
	in_match = true
	host_profile = profile.duplicate(true)
	players = _normalize_players_dict(p_map)
	if not is_host():
		var my_id: int = local_peer_id()
		if players.has(my_id):
			Global.selected_hero = str(players[my_id].get("hero", "ngo_quyen"))
		Global.level = level_val
		Global.boss_order = []
		for b in b_order:
			Global.boss_order.append(str(b))
		Global.resume_data = {}
		Global.run_coins = 0
		Global.revived = false
		Global.run_buffs = {}
		Global.run_materials = {}
		Global.run_weapon_mods = {}
		var ups: Dictionary = host_profile.get("upgrades", {})
		Global.free_revives = int(ups.get("hoi_sinh", 0))
		Global.challenge_code = ""
	match_started.emit(seed_val, level_val)


@rpc("authority", "call_remote", "reliable")
func _rpc_kicked(reason: String) -> void:
	disconnect_notice = reason
	leave_room()
	connection_failed.emit(reason)


@rpc("authority", "call_local", "reliable")
func _rpc_player_disconnected_midrun(peer_id: int, pname: String) -> void:
	players.erase(peer_id)
	player_disconnected_midrun.emit(peer_id, pname)


@rpc("authority", "call_local", "reliable")
func _rpc_player_reconnected(peer_id: int, info: Dictionary) -> void:
	players[peer_id] = info.duplicate(true)
	player_reconnected_midrun.emit(peer_id, players[peer_id])


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_ping(sent_ms: int) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender > 1:
		_rpc_pong.rpc_id(sender, sent_ms)


@rpc("authority", "call_remote", "unreliable")
func _rpc_pong(sent_ms: int) -> void:
	ping_ms = maxi(0, Time.get_ticks_msec() - sent_ms)


# ------------------------------------------------------------------ RPC Đồng bộ trận đấu

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_player_state(state: Dictionary) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	player_state_received.emit(sender, state)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_player_action(kind: String, data: Dictionary) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	player_action_received.emit(sender, kind, data)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_enemy_batch(batch: Array) -> void:
	enemy_batch_received.emit(batch)


@rpc("any_peer", "call_local", "reliable")
func _rpc_enemy_req(kind: String, data: Dictionary) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = local_peer_id()
	var payload: Dictionary = data.duplicate()
	payload["sender"] = sender
	enemy_event_received.emit(kind, payload)


@rpc("authority", "call_remote", "reliable")
func _rpc_enemy_ev(kind: String, data: Dictionary) -> void:
	enemy_event_received.emit(kind, data)


@rpc("any_peer", "call_local", "reliable")
func _rpc_world_req(kind: String, data: Dictionary) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = local_peer_id()
	var payload: Dictionary = data.duplicate()
	payload["sender"] = sender
	world_event_received.emit(kind, payload)


@rpc("authority", "call_remote", "reliable")
func _rpc_world_ev(kind: String, data: Dictionary) -> void:
	world_event_received.emit(kind, data)


@rpc("any_peer", "call_local", "reliable")
func _rpc_down_req(kind: String, target_peer: int, data: Dictionary) -> void:
	if not is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = local_peer_id()
	var payload: Dictionary = data.duplicate()
	payload["sender"] = sender
	_rpc_down_ev.rpc(kind, target_peer, payload)


@rpc("authority", "call_local", "reliable")
func _rpc_down_ev(kind: String, target_peer: int, data: Dictionary) -> void:
	if players.has(target_peer):
		var info: Dictionary = players[target_peer]
		if kind == "down":
			info["downed"] = true
		elif kind == "revive" or kind == "revived":
			info["downed"] = false
		players[target_peer] = info
	down_event_received.emit(kind, target_peer, data)


# ------------------------------------------------------------------ Tín hiệu kết nối ENet

func _on_peer_connected(_peer_id: int) -> void:
	pass


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host() or not players.has(peer_id):
		return
	var info: Dictionary = players[peer_id]
	var pname: String = str(info.get("name", "Đồng đội"))
	players.erase(peer_id)
	if in_match:
		disconnected_slots[pname] = {
			"hero": str(info.get("hero", _default_hero_from_profile())),
			"pet": str(info.get("pet", "")),
			"color": info.get("color", PLAYER_COLORS[0]),
			"slot_idx": int(info.get("slot_idx", 1)),
			"expires_ms": Time.get_ticks_msec() + RECONNECT_GRACE_MS,
		}
		_rpc_player_disconnected_midrun.rpc(peer_id, pname)
	_update_discovery()
	_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)


func _on_connected_to_server() -> void:
	_rpc_register_player.rpc_id(1, _local_player_name)
	connected_to_room.emit()


func _on_connection_failed() -> void:
	if _leaving:
		return
	leave_room()
	connection_failed.emit("Không kết nối được tới máy chủ.")


func _on_server_disconnected() -> void:
	if _leaving:
		return
	disconnect_notice = "Chủ phòng đã rời"
	leave_room()
	host_left.emit("Chủ phòng đã rời")


# ------------------------------------------------------------------ Hàm nội bộ

func _apply_set_hero(pid: int, hid: String) -> void:
	if not players.has(pid) or not HeroData.DATA.has(hid):
		return
	var unlocked_list: Array = host_profile.get("unlocked", [])
	if not unlocked_list.has(hid):
		return
	var info: Dictionary = players[pid]
	info["hero"] = hid
	info["hero_confirmed"] = true
	players[pid] = info
	if pid == local_peer_id():
		Global.selected_hero = hid
	_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)


func _apply_set_ready(pid: int, ready: bool) -> void:
	if not players.has(pid):
		return
	var info: Dictionary = players[pid]
	info["ready"] = ready
	players[pid] = info
	_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)


func _apply_set_pet(pid: int, pet_id: String) -> void:
	if not players.has(pid):
		return
	if pet_id != "" and not Global.PETS.has(pet_id):
		return
	var info: Dictionary = players[pid]
	info["pet"] = pet_id
	players[pid] = info
	if pid == local_peer_id():
		Global.selected_pet = pet_id
	_rpc_sync_lobby.rpc(room_name, host_profile, players, in_match, in_lobby)


func _build_host_profile() -> Dictionary:
	var unl: Array = []
	for hid in Global.unlocked:
		var s: String = str(hid)
		if HeroData.DATA.has(s) and not unl.has(s):
			unl.append(s)
	if unl.is_empty():
		for hid in HeroData.ORDER:
			if int(HeroData.DATA[hid].cost) == 0:
				unl.append(hid)
	return {
		"unlocked": unl,
		"upgrades": Global.upgrades.duplicate(true),
		"hero_levels": Global.hero_levels.duplicate(true),
		"weapon_ranks": Global.weapon_ranks.duplicate(true),
		"difficulty": str(Global.settings.get("difficulty", "thuong")),
	}


func _default_hero_from_profile() -> String:
	var unl: Array = host_profile.get("unlocked", [])
	if unl.has(Global.selected_hero):
		return Global.selected_hero
	if not unl.is_empty():
		return str(unl[0])
	return "ngo_quyen"


func _pick_open_hero() -> String:
	# Cho phép nhiều người chơi LAN chọn trùng cùng một tướng (miễn có trong kho Chủ phòng).
	return _default_hero_from_profile()


func _allocate_slot_idx() -> int:
	var used: Array = []
	for pid in players:
		used.append(int(players[pid].get("slot_idx", 0)))
	for pname in disconnected_slots:
		used.append(int(disconnected_slots[pname].get("slot_idx", 0)))
	for i in MAX_PLAYERS:
		if not used.has(i):
			return i
	for i in MAX_PLAYERS:
		var in_active: bool = false
		for pid in players:
			if int(players[pid].get("slot_idx", 0)) == i:
				in_active = true
				break
		if not in_active:
			return i
	return 0


func _sanitize_name(raw: String) -> String:
	var s: String = raw.strip_edges()
	if s.length() > 16:
		s = s.substr(0, 16)
	return s if s != "" else "Anh Hùng"


func _make_unique_name(base: String) -> String:
	var candidate: String = base
	var idx: int = 2
	while _name_in_use(candidate):
		candidate = "%s (%d)" % [base, idx]
		idx += 1
	return candidate


func _name_in_use(n: String) -> bool:
	for pid in players:
		if str(players[pid].get("name", "")) == n:
			return true
	return false


func _normalize_players_dict(raw: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in raw:
		var pid: int = int(k)
		var v: Variant = raw[k]
		if typeof(v) == TYPE_DICTIONARY:
			out[pid] = (v as Dictionary).duplicate(true)
	return out


func _prune_disconnected_slots() -> void:
	if disconnected_slots.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var expired: Array = []
	for pname in disconnected_slots:
		var slot: Dictionary = disconnected_slots[pname]
		if now > int(slot.get("expires_ms", 0)):
			expired.append(pname)
	for pname in expired:
		disconnected_slots.erase(pname)


func _update_discovery() -> void:
	if _discovery != null and is_host():
		_discovery.update_broadcast(room_name, players.size(), MAX_PLAYERS, in_match)


func _disconnect_client_later(peer_id: int) -> void:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer != null and not (peer is OfflineMultiplayerPeer):
		var wr: WeakRef = weakref(self)
		get_tree().create_timer(0.15).timeout.connect(func() -> void:
			var me: Node = wr.get_ref()
			if me != null and me.is_online() and me.is_host():
				var cur_peer: MultiplayerPeer = me.multiplayer.multiplayer_peer
				if cur_peer != null and not (cur_peer is OfflineMultiplayerPeer):
					cur_peer.disconnect_peer(peer_id))
