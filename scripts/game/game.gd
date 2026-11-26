extends Node2D
## Màn chơi chính: hầm ngục, người chơi, camera, ánh sáng, giao diện; chuyển màn; thua/hồi sinh; LAN Co-op.

const Dungeon = preload("res://scripts/game/dungeon.gd")
const Player = preload("res://scripts/entities/player.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const UI = preload("res://scripts/ui/ui.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffSelect = preload("res://scripts/ui/buff_select.gd")
const NetSync = preload("res://scripts/net/net_sync.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Pet = preload("res://scripts/entities/pet.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")

const SPAWN_OFFSETS: Array[Vector2] = [
	Vector2(-18.0, 0.0),
	Vector2(18.0, 0.0),
	Vector2(0.0, -18.0),
	Vector2(0.0, 18.0),
]

var world: Node2D
var player
var dungeon
var camera: Camera2D
var hud
var touch
var pause_menu
var darkness: CanvasModulate
var buff_ui
var pet: Node = null
var net_sync: Node = null
var players_by_peer: Dictionary = {}
var _game_over: CanvasLayer = null
var _victory_ui: CanvasLayer = null
var _copy_btn: Button = null
var _shake := 0.0
var _start_bonus := false
var _buff_done_peers: Dictionary = {}
var _portal_triggered: bool = false
var _team_wiped: bool = false
var _combat_room_music_seq: int = 0


func _ready() -> void:
	if HotpatchSync.sync_and_reload_scene_if_needed(get_tree(), "res://scenes/game.tscn"):
		return
	add_to_group("game")
	get_tree().paused = false
	world = Node2D.new()
	add_child(world)
	darkness = CanvasModulate.new()
	add_child(darkness)

	var resuming: bool = (not Net.is_online()) and (not Global.resume_data.is_empty())
	if Net.is_online():
		net_sync = NetSync.new()
		net_sync.game = self
		add_child(net_sync)
		var local_pid: int = Net.local_peer_id()
		var peer_keys: Array = Net.players.keys()
		peer_keys.sort()
		for k in peer_keys:
			var pid: int = int(k)
			var info: Dictionary = Net.players[k]
			var p: Node = _spawn_net_player(pid, info)
			if pid == local_pid:
				player = p
		if player == null:
			var fallback_info: Dictionary = {
				"id": local_pid,
				"name": str(Global.settings.get("player_name", "Anh Hùng")),
				"hero": Global.selected_hero,
				"color": Net.PLAYER_COLORS[0],
				"slot_idx": 0,
			}
			player = _spawn_net_player(local_pid, fallback_info)
		_connect_net_signals()
	else:
		player = Player.new()
		player.setup(Global.selected_hero)
		if resuming:
			player.restore(Global.resume_data)    # "Chơi tiếp": máu, giáp, vũ khí như lúc lưu
		else:
			var fw: String = Global.consume_forged()
			if fw != "" and WeaponData.DATA.has(fw):
				player.weapons[1] = fw
				Global.discover(fw)
		world.add_child(player)
		if not resuming and (Net == null or not Net.is_online() or Net.is_host()):
			Global.apply_lobby_bonuses(player)
		if Global.selected_pet != "" and Global.PETS.has(Global.selected_pet):
			_spawn_pet()

	player.died.connect(_on_player_died)
	player.hurt.connect(func(): add_shake(4.0))

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	player.add_child(camera)
	apply_camera_zoom()

	hud = HUD.new()
	add_child(hud)
	hud.player = player

	touch = TouchControls.new()
	add_child(touch)
	touch.player = player
	touch.pause_pressed.connect(func(): pause_menu.open())

	buff_ui = BuffSelect.new()
	add_child(buff_ui)
	buff_ui.chosen.connect(_on_buff_chosen)

	pause_menu = PauseMenu.new()
	pause_menu.game = self
	add_child(pause_menu)

	_build_level()
	# Lễ xuất quân: chọn 1 phúc lành ngay từ đầu
	if not resuming and Global.eff_upgrade("khoi_dau") > 0 and Global.level == 1 and Global.run_buffs.is_empty():
		_start_buff.call_deferred()


func _exit_tree() -> void:
	_disconnect_net_signals()


func apply_camera_zoom() -> void:
	if camera != null and is_instance_valid(camera):
		var z: float = Global.camera_zoom()
		camera.zoom = Vector2(z, z)


func _spawn_net_player(pid: int, info: Dictionary) -> Node:
	var p := Player.new()
	var hid: String = str(info.get("hero", Global.selected_hero))
	p.peer_id = pid
	p.is_local = (pid == Net.local_peer_id())
	p.display_name = str(info.get("name", "Anh Hùng"))
	var col_v: Variant = info.get("color", Net.PLAYER_COLORS[0])
	if col_v is Color:
		p.name_color = col_v
	p.setup(hid)
	world.add_child(p)
	players_by_peer[pid] = p
	return p


func _connect_net_signals() -> void:
	Net.player_state_received.connect(_on_net_player_state)
	Net.player_action_received.connect(_on_net_player_action)
	Net.world_event_received.connect(_on_net_world_event)
	Net.down_event_received.connect(_on_net_down_event)
	Net.host_left.connect(_on_net_host_left)
	Net.player_disconnected_midrun.connect(_on_net_player_disconnected)
	Net.player_reconnected_midrun.connect(_on_net_player_reconnected)


func _disconnect_net_signals() -> void:
	if Net.player_state_received.is_connected(_on_net_player_state):
		Net.player_state_received.disconnect(_on_net_player_state)
	if Net.player_action_received.is_connected(_on_net_player_action):
		Net.player_action_received.disconnect(_on_net_player_action)
	if Net.world_event_received.is_connected(_on_net_world_event):
		Net.world_event_received.disconnect(_on_net_world_event)
	if Net.down_event_received.is_connected(_on_net_down_event):
		Net.down_event_received.disconnect(_on_net_down_event)
	if Net.host_left.is_connected(_on_net_host_left):
		Net.host_left.disconnect(_on_net_host_left)
	if Net.player_disconnected_midrun.is_connected(_on_net_player_disconnected):
		Net.player_disconnected_midrun.disconnect(_on_net_player_disconnected)
	if Net.player_reconnected_midrun.is_connected(_on_net_player_reconnected):
		Net.player_reconnected_midrun.disconnect(_on_net_player_reconnected)


func _spawn_pet() -> void:
	if player == null or not is_instance_valid(player):
		return
	if pet != null and is_instance_valid(pet):
		pet.queue_free()
	var p := Pet.new()
	p.setup(Global.selected_pet, player)
	world.add_child(p)
	pet = p


func _start_buff() -> void:
	_start_bonus = true
	if not Net.is_online() and Global.challenge_code != "":
		seed(Global.challenge_seed(Global.challenge_code) + 7919 + 17)
	if not buff_ui.open("Lễ xuất quân"):
		_start_bonus = false


func add_shake(amount: float) -> void:
	if not bool(Global.settings.get("shake", true)):
		_shake = 0.0
		return
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if player != null and is_instance_valid(player) and not player.dead and not get_tree().paused:
		Global.run_elapsed += delta
	if _shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 22.0)
	else:
		camera.offset = Vector2.ZERO


func next_combat_room_music_seq() -> int:
	_combat_room_music_seq += 1
	return _combat_room_music_seq


func _build_level() -> void:
	_combat_room_music_seq = 0
	_portal_triggered = false
	_buff_done_peers.clear()
	if hud != null and hud.has_method("clear_boss_intro"):
		hud.clear_boss_intro()
	if net_sync != null:
		net_sync.is_clearing_level = true
		net_sync.clear_level_maps()
	for pk in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pk):
			pk.set("_net_claimed_by_other", true)
	var keep_players: Array = players_by_peer.values()
	for c in world.get_children():
		if c != player and c != pet and not keep_players.has(c):
			c.queue_free()
	var ch := EnemyData.chapter(Global.level)
	darkness.color = ch.dark
	if Global.level == 16 or Global.level >= 32:
		Sfx.play_music("victory")
	elif Sfx.has_method("play_stage_music"):
		Sfx.play_stage_music(Global.level, 0)
	else:
		Sfx.play_music("battle")
	dungeon = Dungeon.new()
	world.add_child(dungeon)
	world.move_child(dungeon, 0)
	if Net.is_online():
		seed(Net.match_seed + Global.level * 1009)
	elif Global.challenge_code != "":
		seed(Global.challenge_seed(Global.challenge_code) + Global.level * 1009)
	dungeon.generate(Global.level)
	dungeon.portal_entered.connect(_on_portal)
	if net_sync != null:
		net_sync.set_deferred("is_clearing_level", false)
	var start_pos: Vector2 = dungeon.start_position()
	if Net.is_online():
		var idx: int = 0
		var peer_keys: Array = players_by_peer.keys()
		peer_keys.sort()
		for k in peer_keys:
			var pid: int = int(k)
			var pl: Node = players_by_peer[k]
			if pl != null and is_instance_valid(pl):
				var pinfo: Dictionary = Net.players.get(pid, {})
				var sidx: int = int(pinfo.get("slot_idx", idx)) % SPAWN_OFFSETS.size()
				var pos: Vector2 = start_pos + SPAWN_OFFSETS[sidx]
				(pl as Node2D).global_position = pos
				pl.set("_remote_pos", pos)
				pl.nearby_pickup = null
				if bool(pl.get("downed")):
					if pl.has_method("revive_from_down"):
						pl.revive_from_down(false)
					else:
						pl.set("downed", false)
						pl.hp = maxi(2, int(pl.get("hp")))
			idx += 1
	else:
		player.global_position = start_pos
		player.nearby_pickup = null
		if pet != null and is_instance_valid(pet):
			(pet as Node2D).global_position = start_pos + Vector2(-18.0, 12.0)
	camera.reset_smoothing()
	if not Net.is_online() or Net.is_host():
		Global.save_run(player)     # điểm lưu đầu mỗi màn (tắt game thì "Chơi tiếp" từ đây)
	var stage := EnemyData.stage_in_chapter(Global.level)
	var chn := EnemyData.stage_chapter_num(Global.level)
	if Global.level == 16:
		hud.show_banner("Màn 3-6  -  Sảnh Khải Hoàn!")
	elif Global.level >= 32:
		hud.show_banner("Màn 6-6  -  Sảnh Huyền Thoại!")
	elif stage == 1:
		hud.show_chapter(chn, ch)
	else:
		var prefix: String = "Thần thoại " if EnemyData.is_mythic_level(Global.level) else "Màn "
		hud.show_banner("%s%d-%d%s" % [prefix, chn, stage, "  -  Trận quyết chiến!" if EnemyData.is_boss_level(Global.level) else ""])


func _on_portal() -> void:
	if _portal_triggered:
		return
	if Net.is_online():
		if not Net.is_host():
			return
		_portal_triggered = true
		if Global.level == 16 or Global.level == 31:
			var next_lvl: int = Global.level + 1
			Net.send_world_event("advance", {"level": next_lvl}, false)
			_advance_to.call_deferred(next_lvl)
			return
		_buff_done_peers.clear()
		Net.send_world_event("portal_open_buffs", {"level": Global.level}, false)
		_open_lan_buffs.call_deferred()
		return
	Sfx.play("level_clear")
	touch.reset()
	if Global.level == 16 or Global.level == 31:
		_advance.call_deferred()
		return
	# qua màn: chọn 1 phúc lành rồi mới sang màn mới
	var title: String
	if Global.level == 15:
		title = "Sảnh Khải Hoàn (Màn 3-6)"
	else:
		var nxt := EnemyData.chapter(Global.level + 1)
		title = "%s - %s" % [nxt.name, nxt.year]
	_open_buffs.call_deferred(title)


func _is_boss_cleared_level() -> bool:
	if EnemyData.is_boss_level(Global.level):
		return true
	if dungeon != null:
		for c in dungeon.rooms:
			var r = dungeon.rooms[c]
			if str(r.kind) in ["boss", "legend"] and str(r.state) == "done":
				return true
	return false


func _open_buffs(title: String) -> void:
	if Global.challenge_code != "":
		seed(Global.challenge_seed(Global.challenge_code) + Global.level * 7919 + 31)
	if not buff_ui.open(title, _is_boss_cleared_level()):
		_advance()


func _open_lan_buffs() -> void:
	Sfx.play("level_clear")
	touch.reset()
	var nxt := EnemyData.chapter(Global.level + 1)
	var title := "%s - %s" % [nxt.name, nxt.year]
	if not buff_ui.open(title, _is_boss_cleared_level()):
		_notify_buff_done()


func _on_buff_chosen(id: String) -> void:
	player.apply_buff(id)
	if _start_bonus:
		_start_bonus = false
		if not Net.is_online() or Net.is_host():
			Global.save_run(player)
		return
	if Net.is_online():
		_notify_buff_done()
		return
	_advance.call_deferred()


func _notify_buff_done() -> void:
	if Net.is_host():
		_buff_done_peers[Net.local_peer_id()] = true
		_check_all_buffs_done()
	else:
		Net.send_world_event("buff_done", {}, true)
		hud.show_banner("Đã chọn phúc lành - Chờ đồng đội...")


func _check_all_buffs_done() -> void:
	if not Net.is_online() or not Net.is_host() or not _portal_triggered:
		return
	for pid_v in Net.players.keys():
		var pid: int = int(pid_v)
		if not _buff_done_peers.has(pid):
			hud.show_banner("Đã chọn phúc lành - Chờ đồng đội (%d/%d)..." % [_buff_done_peers.size(), Net.players.size()])
			return
	var next_lvl: int = Global.level + 1
	Net.send_world_event("advance", {"level": next_lvl}, false)
	_advance_to.call_deferred(next_lvl)


func _advance() -> void:
	if pet != null and is_instance_valid(pet) and pet.has_method("on_next_level"):
		pet.on_next_level()
	Global.level += 1
	Global.best_level = maxi(Global.best_level, Global.level)
	_build_level()


func _advance_to(lvl: int) -> void:
	Global.level = lvl
	Global.best_level = maxi(Global.best_level, Global.level)
	_build_level()


func can_pause() -> bool:
	return not player.dead and _game_over == null and _victory_ui == null and not buff_ui.visible and get_tree().get_nodes_in_group("shop_ui_open").is_empty()


# ------------------------------------------------------------------ Mạng LAN

func _on_net_player_state(peer_id: int, state: Dictionary) -> void:
	var rp: Variant = players_by_peer.get(peer_id, null)
	if rp != null and is_instance_valid(rp) and not bool(rp.get("is_local")):
		rp.apply_remote_state(state)


func _on_net_player_action(peer_id: int, kind: String, data: Dictionary) -> void:
	var rp: Variant = players_by_peer.get(peer_id, null)
	if rp != null and is_instance_valid(rp) and not bool(rp.get("is_local")):
		rp.play_remote_action(kind, data)


func _on_net_world_event(kind: String, data: Dictionary) -> void:
	match kind:
		"room_lock":
			if Net.is_host() or dungeon == null:
				return
			var rm: Node = dungeon.get_room_by_key(str(data.get("key", "")))
			if rm != null and rm.has_method("net_apply_lock"):
				rm.net_apply_lock(str(data.get("kind", "")), str(data.get("legend_id", "")))
		"room_clear":
			if Net.is_host() or dungeon == null:
				return
			var rm2: Node = dungeon.get_room_by_key(str(data.get("key", "")))
			if rm2 != null and rm2.has_method("net_apply_clear"):
				rm2.net_apply_clear()
		"room_treasure":
			if Net.is_host() or dungeon == null:
				return
			var rm3: Node = dungeon.get_room_by_key(str(data.get("key", "")))
			if rm3 != null and rm3.has_method("net_apply_treasure"):
				rm3.net_apply_treasure()
		"room_exit":
			if Net.is_host() or dungeon == null:
				return
			var rm4: Node = dungeon.get_room_by_key(str(data.get("key", "")))
			if rm4 != null and rm4.has_method("net_apply_exit"):
				rm4.net_apply_exit()
		"spawn_pickup":
			if Net.is_host() or dungeon == null:
				return
			var pid: int = int(data.get("id", 0))
			if pid > 0 and net_sync != null and net_sync.get_pickup(pid) != null:
				return
			var pk := Pickup.new()
			pk.pickup_id = pid
			pk.kind = str(data.get("kind", "coin"))
			pk.amount = int(data.get("amount", 1))
			pk.weapon_id = str(data.get("weapon_id", ""))
			pk.material_id = str(data.get("material_id", ""))
			pk.position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
			dungeon.add_child(pk)
			if pid > 0 and net_sync != null:
				net_sync.register_pickup(pk)
		"pickup_claim":
			if not Net.is_host() or net_sync == null:
				return
			var pid2: int = int(data.get("id", 0))
			var sender: int = int(data.get("sender", 0))
			if pid2 <= 0 or net_sync.claimed_pickups.has(pid2):
				return
			net_sync.claimed_pickups[pid2] = true
			Net.send_world_event("pickup_claimed", {"id": pid2, "claimer": sender}, false)
			var existing: Node = net_sync.get_pickup(pid2)
			if existing != null and existing.has_method("net_remove_claimed"):
				existing.net_remove_claimed()
		"pickup_claimed":
			if Net.is_host() or net_sync == null:
				return
			var pid3: int = int(data.get("id", 0))
			var claimer: int = int(data.get("claimer", 0))
			var pk2: Node = net_sync.get_pickup(pid3)
			if pk2 != null:
				if claimer == Net.local_peer_id() and str(pk2.get("kind")) != "weapon":
					pk2.net_collect_approved()
				else:
					pk2.net_remove_claimed()
		"chest_open_req":
			if not Net.is_host():
				return
			var cid: String = str(data.get("id", ""))
			for ch_node in get_tree().get_nodes_in_group("loot_chests"):
				if is_instance_valid(ch_node) and str(ch_node.get("chest_id")) == cid:
					if not bool(ch_node.get("opened")) and ch_node.has_method("host_open_and_broadcast"):
						ch_node.host_open_and_broadcast()
					break
		"chest_open":
			if Net.is_host():
				return
			var cid2: String = str(data.get("id", ""))
			var drops: Array = data.get("drops", [])
			for ch_node2 in get_tree().get_nodes_in_group("loot_chests"):
				if is_instance_valid(ch_node2) and str(ch_node2.get("chest_id")) == cid2:
					if ch_node2.has_method("apply_open_drops"):
						ch_node2.apply_open_drops(drops)
					break
		"shop_buy":
			if not Net.is_host() or net_sync == null:
				return
			var sid: String = str(data.get("id", ""))
			var buyer: int = int(data.get("sender", 0))
			if sid == "" or net_sync.sold_stands.has(sid):
				return
			for st in get_tree().get_nodes_in_group("shop_stands"):
				if is_instance_valid(st) and str(st.get("stand_id")) == sid:
					if not bool(st.get("sold")) and st.has_method("host_approve_buy"):
						net_sync.sold_stands[sid] = true
						st.host_approve_buy(buyer)
					break
		"shop_sold":
			if Net.is_host():
				return
			var sid2: String = str(data.get("id", ""))
			var buyer2: int = int(data.get("buyer", 0))
			for st2 in get_tree().get_nodes_in_group("shop_stands"):
				if is_instance_valid(st2) and str(st2.get("stand_id")) == sid2:
					if st2.has_method("client_apply_sold"):
						st2.client_apply_sold(buyer2)
					break
		"portal_open_buffs":
			if Net.is_host() or _portal_triggered:
				return
			_portal_triggered = true
			_open_lan_buffs.call_deferred()
		"buff_done":
			if not Net.is_host():
				return
			var bsender: int = int(data.get("sender", 0))
			if bsender > 0:
				_buff_done_peers[bsender] = true
				_check_all_buffs_done()
		"advance":
			if Net.is_host():
				return
			var next_lvl: int = int(data.get("level", Global.level + 1))
			_advance_to.call_deferred(next_lvl)


func _on_net_down_event(kind: String, target_peer: int, _data: Dictionary) -> void:
	if kind == "team_wipe":
		_trigger_team_wipe()
		return
	var rp: Variant = players_by_peer.get(target_peer, null)
	if rp != null and is_instance_valid(rp):
		if kind == "down":
			if not bool(rp.get("is_local")):
				if rp.has_method("enter_downed"):
					rp.enter_downed(false)
				else:
					rp.set("downed", true)
					rp.hp = 0
					rp.armor = 0
					if rp.body != null:
						rp.body.play("down")
				hud.show_banner("%s đã gục ngã! Đứng cạnh 3s để cứu!" % str(rp.get("display_name")))
		elif kind == "revive" or kind == "revived":
			if not bool(rp.get("is_local")):
				if rp.has_method("revive_from_down"):
					rp.revive_from_down(false)
				else:
					rp.set("downed", false)
					rp.dead = false
					rp.hp = 2
					rp.armor = 0
					if rp.body != null:
						rp.body.play("idle")
				hud.show_banner("%s đã được cứu!" % str(rp.get("display_name")))
	if kind == "down":
		_check_team_wipe()


func _check_team_wipe() -> void:
	if _team_wiped or not Net.is_online():
		return
	var all_pl: Array = Global.all_players()
	if all_pl.is_empty():
		return
	for pl in all_pl:
		if is_instance_valid(pl) and not bool(pl.get("dead")) and not bool(pl.get("downed")):
			return
	if Net.is_host():
		Net.send_down_event("team_wipe", 0, {})
	_trigger_team_wipe()


func _trigger_team_wipe() -> void:
	if _team_wiped:
		return
	_team_wiped = true
	await get_tree().create_timer(1.0).timeout
	_show_game_over()


func _on_net_host_left(_reason: String) -> void:
	if Net.is_host():
		Global.end_run("bo_luot")
	Net.leave_room()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_net_player_disconnected(peer_id: int, pname: String) -> void:
	if players_by_peer.has(peer_id):
		var rp: Variant = players_by_peer[peer_id]
		players_by_peer.erase(peer_id)
		if rp != null and is_instance_valid(rp) and rp != player:
			(rp as Node).queue_free()
	hud.show_banner("%s đã mất kết nối (60s để vào lại)" % pname)
	if Net.is_host():
		_buff_done_peers.erase(peer_id)
		_check_all_buffs_done()
	_check_team_wipe()


func _on_net_player_reconnected(peer_id: int, info: Dictionary) -> void:
	if peer_id == Net.local_peer_id():
		return
	if players_by_peer.has(peer_id):
		var old_p: Variant = players_by_peer[peer_id]
		players_by_peer.erase(peer_id)
		if old_p != null and is_instance_valid(old_p) and old_p != player:
			(old_p as Node).queue_free()
	var rp: Node = _spawn_net_player(peer_id, info)
	var host_p: Variant = players_by_peer.get(1, player)
	var spawn_pos: Vector2 = dungeon.start_position() if dungeon != null else Vector2.ZERO
	if host_p != null and is_instance_valid(host_p):
		spawn_pos = (host_p as Node2D).global_position + Vector2(20.0, 0.0)
	(rp as Node2D).global_position = spawn_pos
	rp.set("_remote_pos", spawn_pos)
	hud.show_banner("%s đã kết nối lại!" % str(info.get("name", "Đồng đội")))


# ------------------------------------------------------------------ Thua cuộc

func _on_player_died() -> void:
	if Net.is_online() and Net.player_count() > 1:
		_check_team_wipe()
		return
	await get_tree().create_timer(1.0).timeout
	_show_game_over()


func show_victory(mythic: bool = false) -> void:
	if _victory_ui != null:
		return
	touch.reset()
	if hud != null and hud.has_method("clear_boss_intro"):
		hud.clear_boss_intro()
	var bonus_coins: int = 90 if mythic else 50
	if not Net.is_online() or Net.is_host():
		Global.coins += bonus_coins
		Global.materials["ngoc_than"] = Global.material_count("ngoc_than") + (2 if mythic else 1)
		if mythic:
			Global.materials["yeu_hon"] = Global.material_count("yeu_hon") + 2
			Global.stats["mythic_clears"] = int(Global.stats.get("mythic_clears", 0)) + 1
	var entry: Dictionary = Global.record_score("thang")
	Global.save_game()
	_victory_ui = CanvasLayer.new()
	_victory_ui.layer = 30
	add_child(_victory_ui)
	var box := UI.overlay(_victory_ui, 0.72)
	if mythic:
		box.add_child(UI.label("VANG DANH SỬ SÁCH! ĐẠI THẮNG THẦN THOẠI!", 26, Color(0.92, 0.72, 1.0)))
		box.add_child(UI.label("Chinh phục trọn vẹn 6 Chương & Yêu Vương Lĩnh Nam (Màn 4-1 → 6-6)!", 15, Color(0.86, 0.94, 0.98)))
		box.add_child(UI.label("Thưởng Huyền Thoại: +90 xu, +2 Ngọc thần, +2 Yêu hồn  |  Xu trận: %d xu" % Global.run_coins, 14, Color(0.62, 0.98, 0.76)))
	else:
		box.add_child(UI.label("ĐẠI THẮNG! KHẢI HOÀN!", 30, Color(1.0, 0.88, 0.35)))
		var ch := EnemyData.chapter(Global.level)
		box.add_child(UI.label("Hoàn thành 3 Chương (Màn 1-1 → 3-6) tại %s - %s!" % [ch.name, ch.year], 15, Color(0.86, 0.94, 0.98)))
		box.add_child(UI.label("Thưởng khải hoàn: +50 xu & +1 Ngọc thần  |  Tổng kết xu trận: %d xu" % Global.run_coins, 14, Color(0.55, 0.98, 0.72)))
	var score_line: String = "Thời gian: %s  |  Số giặc: %d  |  Điểm: %d" % [
		Global.format_time(float(entry.get("time", Global.run_elapsed))),
		int(entry.get("kills", Global.run_kills)),
		int(entry.get("score", 0)),
	]
	box.add_child(UI.label(score_line, 16, Color(1.0, 0.88, 0.45)))
	var share_txt: String = Global.format_share_text(entry)
	_copy_btn = UI.button("Chép kết quả", func(): _on_copy_result(share_txt), 16, 200.0)
	box.add_child(UI.center(_copy_btn))
	if not Net.is_online():
		if mythic:
			box.add_child(UI.center(UI.button("Chính Thức Về Sảnh Chính (Đợt Hai)", _on_victory_lobby, 16, 270.0)))
		else:
			box.add_child(UI.center(UI.button("Về Doanh Trại (Tổng kết xu)", _on_victory_lobby, 16, 250.0)))
			box.add_child(UI.center(UI.button("Khởi Hành Thần Thoại (4-1 → 6-6)", _on_victory_continue, 16, 270.0)))
	else:
		if not mythic:
			box.add_child(UI.center(UI.button("Khởi Hành Thần Thoại", _on_victory_continue, 16, 240.0)))
		box.add_child(UI.center(UI.button("Rời phòng LAN", _on_menu, 16, 220.0)))


func _on_victory_lobby() -> void:
	Global.end_run("thang")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_victory_continue() -> void:
	_copy_btn = null
	if _victory_ui != null:
		_victory_ui.queue_free()
		_victory_ui = null
	hud.show_banner("Bước vào Cổng Thần Thoại để đối mặt Yêu Vương Lĩnh Nam (4-1)!")


func _show_game_over() -> void:
	if _game_over != null:
		return
	touch.reset()
	var entry: Dictionary = Global.record_score("thua")
	_game_over = CanvasLayer.new()
	_game_over.layer = 30
	add_child(_game_over)
	var box := UI.overlay(_game_over, 0.7)
	var heading: String = "Toàn đội đã gục ngã!" if (Net.is_online() and Net.player_count() > 1) else "Tướng quân đã ngã xuống!"
	box.add_child(UI.label(heading, 32, Color(1, 0.55, 0.45)))
	var ch := EnemyData.chapter(Global.level)
	var sub: String = "%s - %s  |  Nhặt được %d xu" % [ch.name, ch.year, Global.run_coins]
	if Global.challenge_code != "":
		sub = "Mã thử thách: %s  |  %s" % [Global.challenge_code, sub]
	box.add_child(UI.label(sub, 16))
	var score_line: String = "Màn: %d  |  Thời gian: %s  |  Số giặc: %d  |  Điểm: %d" % [
		int(entry.get("level", Global.level)),
		Global.format_time(float(entry.get("time", Global.run_elapsed))),
		int(entry.get("kills", Global.run_kills)),
		int(entry.get("score", 0)),
	]
	box.add_child(UI.label(score_line, 18, Color(1.0, 0.88, 0.45)))
	var share_txt: String = Global.format_share_text(entry)
	_copy_btn = UI.button("Chép kết quả", func(): _on_copy_result(share_txt), 18, 220.0)
	box.add_child(UI.center(_copy_btn))
	if not Net.is_online():
		if Global.free_revives > 0:
			box.add_child(UI.center(UI.button("Hồi sinh (Thuốc hồi sinh)", _on_free_revive)))
		elif not Global.revived:
			box.add_child(UI.center(UI.button("Hồi sinh (xem quảng cáo)", _on_revive)))
		box.add_child(UI.center(UI.button("Chơi lại", _on_restart)))
		box.add_child(UI.center(UI.button("Về sảnh", _on_menu)))
	else:
		box.add_child(UI.center(UI.button("Rời phòng LAN", _on_menu)))


func _on_copy_result(share_txt: String) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.clipboard_set(share_txt)
	if _copy_btn != null and is_instance_valid(_copy_btn):
		_copy_btn.text = "Đã chép!"
		var btn_ref: WeakRef = weakref(_copy_btn)
		get_tree().create_timer(1.5).timeout.connect(func():
			var b: Variant = btn_ref.get_ref()
			if b != null:
				(b as Button).text = "Chép kết quả")


func _on_free_revive() -> void:
	Global.free_revives -= 1
	Global._run_score_recorded = false
	player.revive()
	_copy_btn = null
	if _game_over != null:
		_game_over.queue_free()
		_game_over = null


func _on_revive() -> void:
	Global.show_rewarded_ad(_do_revive)


func _do_revive() -> void:
	Global.revived = true
	Global._run_score_recorded = false
	player.revive()
	_copy_btn = null
	if _game_over != null:
		_game_over.queue_free()
		_game_over = null


func _on_restart() -> void:
	var keep_code: String = Global.challenge_code
	Global.end_run()
	Global.start_run(keep_code)
	get_tree().reload_current_scene()


func _on_menu() -> void:
	if Net.is_online():
		if Net.is_host():
			Global.end_run("" if (_team_wiped or (player != null and is_instance_valid(player) and player.dead)) else "bo_luot")
		Net.leave_room()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	Global.end_run("" if (player != null and is_instance_valid(player) and player.dead) else "bo_luot")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
