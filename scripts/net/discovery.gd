extends Node
## Tự động tìm phòng chơi qua mạng LAN bằng gói UDP quảng bá (cổng 7778).

signal rooms_changed(rooms: Array)

const MAGIC: String = "AHDV_LAN_V1"
const DEFAULT_DISCOVERY_PORT: int = 7778
const BROADCAST_INTERVAL: float = 1.0
const ROOM_TTL_MS: int = 3500

var rooms: Dictionary = {}  # "ip:port" -> {name, ip, port, players, max_players, in_match, last_seen_ms}

var _broadcaster: PacketPeerUDP = null
var _listener: PacketPeerUDP = null
var _disc_port: int = DEFAULT_DISCOVERY_PORT
var _broadcast_timer: float = 0.0
var _room_name: String = ""
var _game_port: int = 7777
var _player_count: int = 1
var _max_players: int = 4
var _in_match: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	stop()


func start_broadcast(rname: String, game_port: int, player_count: int, max_players: int, in_match: bool = false, disc_port: int = DEFAULT_DISCOVERY_PORT) -> void:
	stop_broadcast()
	_room_name = rname
	_game_port = game_port
	_player_count = player_count
	_max_players = max_players
	_in_match = in_match
	_disc_port = disc_port
	_broadcaster = PacketPeerUDP.new()
	_broadcaster.set_broadcast_enabled(true)
	_broadcast_timer = 0.0
	_send_beacon()


func update_broadcast(rname: String, player_count: int, max_players: int, in_match: bool) -> void:
	_room_name = rname
	_player_count = player_count
	_max_players = max_players
	_in_match = in_match
	if _broadcaster != null:
		_send_beacon()


func stop_broadcast() -> void:
	if _broadcaster != null:
		_broadcaster.close()
		_broadcaster = null


func start_listen(disc_port: int = DEFAULT_DISCOVERY_PORT) -> int:
	stop_listen()
	_disc_port = disc_port
	rooms.clear()
	var udp := PacketPeerUDP.new()
	var err: int = udp.bind(disc_port)
	if err != OK:
		udp.close()
		return err
	_listener = udp
	rooms_changed.emit(get_rooms_list())
	return OK


func stop_listen() -> void:
	if _listener != null:
		_listener.close()
		_listener = null
	if not rooms.is_empty():
		rooms.clear()
		rooms_changed.emit([])


func stop() -> void:
	stop_broadcast()
	stop_listen()


func get_rooms_list() -> Array:
	var out: Array = []
	for k in rooms:
		out.append(rooms[k])
	out.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a
		var db: Dictionary = b
		var na: String = str(da.get("name", ""))
		var nb: String = str(db.get("name", ""))
		if na != nb:
			return na < nb
		return str(da.get("ip", "")) < str(db.get("ip", "")))
	return out


func _process(delta: float) -> void:
	if _broadcaster != null:
		_broadcast_timer += delta
		if _broadcast_timer >= BROADCAST_INTERVAL:
			_broadcast_timer = 0.0
			_send_beacon()
	if _listener != null:
		_poll_listener()


func _send_beacon() -> void:
	if _broadcaster == null:
		return
	var payload: Dictionary = {
		"magic": MAGIC,
		"name": _room_name,
		"port": _game_port,
		"players": _player_count,
		"max": _max_players,
		"in_match": _in_match,
	}
	var raw: PackedByteArray = JSON.stringify(payload).to_utf8_buffer()
	var targets: PackedStringArray = PackedStringArray(["255.255.255.255"])
	for addr in IP.get_local_addresses():
		var s: String = str(addr)
		if s.contains(".") and not s.contains(":") and not s.begins_with("127.") and not s.begins_with("169.254."):
			var parts: PackedStringArray = s.split(".")
			if parts.size() == 4:
				var bcast: String = "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]
				if not targets.has(bcast):
					targets.append(bcast)
	for dst in targets:
		if _broadcaster.set_dest_address(dst, _disc_port) == OK:
			_broadcaster.put_packet(raw)


func _poll_listener() -> void:
	var changed: bool = false
	var now: int = Time.get_ticks_msec()
	while _listener != null and _listener.get_available_packet_count() > 0:
		var pkt: PackedByteArray = _listener.get_packet()
		var sender_ip: String = _listener.get_packet_ip()
		if sender_ip == "" or pkt.is_empty():
			continue
		var txt: String = pkt.get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(txt)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = parsed
		if str(d.get("magic", "")) != MAGIC:
			continue
		var gport: int = clampi(int(d.get("port", 7777)), 1024, 65535)
		var rname: String = str(d.get("name", "Phòng LAN")).strip_edges()
		if rname == "":
			rname = "Phòng LAN"
		var pcnt: int = maxi(1, int(d.get("players", 1)))
		var pmax: int = clampi(int(d.get("max", 4)), 2, 4)
		var running: bool = bool(d.get("in_match", false))
		var key: String = "%s:%d" % [sender_ip, gport]
		var entry: Dictionary = {
			"name": rname,
			"ip": sender_ip,
			"port": gport,
			"players": pcnt,
			"max_players": pmax,
			"in_match": running,
			"last_seen_ms": now,
		}
		if not rooms.has(key):
			changed = true
		else:
			var prev: Dictionary = rooms[key]
			if str(prev.get("name", "")) != rname or int(prev.get("players", 0)) != pcnt or bool(prev.get("in_match", false)) != running:
				changed = true
		rooms[key] = entry

	var expired: Array = []
	for k in rooms:
		var item: Dictionary = rooms[k]
		if now - int(item.get("last_seen_ms", 0)) > ROOM_TTL_MS:
			expired.append(k)
	for k in expired:
		rooms.erase(k)
		changed = true

	if changed:
		rooms_changed.emit(get_rooms_list())
