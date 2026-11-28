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
const CoopSynergyData = preload("res://scripts/data/coop_synergy.gd")
const CoopComboFx = preload("res://scripts/effects/coop_combo_fx.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const CoLoaDefense = preload("res://scripts/game/co_loa_defense.gd")
const PingMarker = preload("res://scripts/effects/ping_marker.gd")
const MatchSummary = preload("res://scripts/ui/match_summary.gd")
const RelicData = preload("res://scripts/data/relics.gd")

const COOP_COMBO_WINDOW: float = 2.4
const COOP_COMBO_MAX_DIST: float = 260.0
const COOP_COMBO_COOLDOWN: float = 12.0

static func _hotpatch_sync() -> Script:
	var gdc_path := "res://scripts/autoload/hotpatch_sync.gdc"
	var gd_path := "res://scripts/autoload/hotpatch_sync.gd"
	var load_path := gdc_path if FileAccess.file_exists(gdc_path) else gd_path
	var fresh := ResourceLoader.load(load_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if fresh != null:
		fresh.take_over_path(gdc_path)
		fresh.take_over_path(gd_path)
	return fresh

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
var pets_by_peer: Dictionary = {}
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
var _leaving: bool = false
var _weather_node: Node = null
var _recent_skill_casts: Dictionary = {}
var _coop_combo_cd: float = 0.0
var _coop_clock: float = 0.0
var _is_co_loa_mode: bool = false
var _ping_kind: String = "focus"


func _ready() -> void:
	var hs := _hotpatch_sync()
	if hs != null and hs.sync_and_reload_scene_if_needed(get_tree(), "res://scenes/game.tscn"):
		return
	add_to_group("game")
	add_to_group("game_controller")
	get_tree().paused = false
	world = Node2D.new()
	add_child(world)
	darkness = CanvasModulate.new()
	add_child(darkness)

	var resuming: bool = (not Net.is_online()) and (not Global.resume_data.is_empty())
	if not resuming and not Global._run_active:
		if Global.pending_run_mode != "normal":
			Global.run_mode = Global.pending_run_mode
			Global.pending_run_mode = "normal"
		if not Global.pending_mutators.is_empty():
			Global.active_mutators = Global.pending_mutators.duplicate()
			Global.pending_mutators = []
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
			_spawn_net_pet(pid, p, info)
		if player == null:
			var fallback_info: Dictionary = {
				"id": local_pid,
				"name": str(Global.settings.get("player_name", "Anh Hùng")),
				"hero": Global.selected_hero,
				"pet": Global.selected_pet,
				"color": Net.PLAYER_COLORS[0],
				"slot_idx": 0,
			}
			player = _spawn_net_player(local_pid, fallback_info)
			_spawn_net_pet(local_pid, player, fallback_info)
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
	touch.pause_pressed.connect(func():
		if pause_menu != null and is_instance_valid(pause_menu) and not _leaving:
			pause_menu.open())

	buff_ui = BuffSelect.new()
	add_child(buff_ui)
	buff_ui.chosen.connect(_on_buff_chosen)

	pause_menu = PauseMenu.new()
	pause_menu.game = self
	add_child(pause_menu)

	var wfx_script := _load_weather_script()
	if wfx_script != null:
		wfx_script.apply_glow_environment(self)

	_build_level()
	# Lễ xuất quân: chọn 1 phúc lành ngay từ đầu
	if not resuming and Global.eff_upgrade("khoi_dau") > 0 and Global.level == 1 and Global.run_buffs.is_empty():
		_start_buff.call_deferred()


func _exit_tree() -> void:
	_leaving = true
	_disconnect_net_signals()
	if get_tree() != null:
		get_tree().paused = false


func apply_camera_zoom() -> void:
	if camera != null and is_instance_valid(camera):
		var z: float = Global.camera_zoom()
		camera.zoom = Vector2(z, z)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not is_inside_tree() or get_tree().paused:
		return
	if player == null or not is_instance_valid(player) or bool(player.get("dead")):
		return
	if _game_over != null or _victory_ui != null:
		return
	var is_ping_key: bool = false
	var shift_held: bool = false
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.physical_keycode == KEY_T:
			is_ping_key = true
			shift_held = ke.shift_pressed
	elif InputMap.has_action("ping") and event.is_action_pressed("ping"):
		is_ping_key = true
	if is_ping_key:
		if shift_held:
			_ping_kind = PingMarker.cycle_ping_kind(_ping_kind)
			var pinfo: Dictionary = PingMarker.PING_TYPES.get(_ping_kind, {})
			if hud != null and hud.has_method("show_banner"):
				hud.show_banner("Ping: %s" % str(pinfo.get("label", _ping_kind)))
		else:
			trigger_tactical_ping()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func trigger_tactical_ping() -> void:
	if world == null or not is_instance_valid(world):
		return
	if player == null or not is_instance_valid(player) or bool(player.get("dead")):
		return
	for c in world.get_children():
		if c is PingMarker and float(c.get("_t")) < 0.08:
			return
	var ppos: Vector2 = (player as Node2D).global_position if Global.auto_aim() else world.get_global_mouse_position()
	var pname: String = str(player.get("display_name"))
	if pname == "":
		pname = str(Global.settings.get("player_name", "Anh Hùng"))
	var pcol: Color = player.get("name_color") as Color if player.get("name_color") is Color else Color(0, 0, 0, 0)
	PingMarker.spawn_ping(world, ppos, _ping_kind, pname, pcol)
	if Net != null and Net.is_online():
		Net.send_player_action("ping", {"kind": _ping_kind, "x": ppos.x, "y": ppos.y, "name": pname})
	_ping_kind = PingMarker.cycle_ping_kind(_ping_kind)


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
	if Net == null:
		return
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


func _spawn_net_pet(pid: int, owner_p: Node, info: Dictionary) -> void:
	if owner_p == null or not is_instance_valid(owner_p):
		return
	if pets_by_peer.has(pid):
		var old_pet: Variant = pets_by_peer[pid]
		pets_by_peer.erase(pid)
		if old_pet != null and is_instance_valid(old_pet):
			(old_pet as Node).queue_free()
	var pet_id: String = str(info.get("pet", ""))
	if pet_id == "" and pid == Net.local_peer_id():
		pet_id = Global.selected_pet
	if pet_id == "" or not Global.PETS.has(pet_id):
		if pid == Net.local_peer_id():
			pet = null
		return
	var p := Pet.new()
	p.setup(pet_id, owner_p)
	world.add_child(p)
	pets_by_peer[pid] = p
	if pid == Net.local_peer_id():
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
	if not get_tree().paused:
		_coop_clock += delta
		if _coop_combo_cd > 0.0:
			_coop_combo_cd = maxf(_coop_combo_cd - delta, 0.0)
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
	_recent_skill_casts.clear()
	if _weather_node != null and is_instance_valid(_weather_node):
		_weather_node.queue_free()
	_weather_node = null
	if hud != null and hud.has_method("clear_boss_intro"):
		hud.clear_boss_intro()
	if net_sync != null:
		net_sync.is_clearing_level = true
		net_sync.clear_level_maps()
	for pk in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pk):
			pk.set("_net_claimed_by_other", true)
	var keep_players: Array = players_by_peer.values()
	var keep_pets: Array = pets_by_peer.values()
	for c in world.get_children():
		if c != player and c != pet and not keep_players.has(c) and not keep_pets.has(c):
			c.queue_free()
	var co_loa_mode: bool = Global.has_method("is_co_loa") and Global.is_co_loa()
	_is_co_loa_mode = co_loa_mode
	if co_loa_mode:
		darkness.color = Color(0.84, 0.78, 0.70)
		if Sfx.has_method("play_music"):
			Sfx.play_music("coloa_defense")
		else:
			Sfx.play_stage_music(5, 0)
		dungeon = CoLoaDefense.new()
		world.add_child(dungeon)
		world.move_child(dungeon, 0)
		if dungeon.has_signal("core_destroyed"):
			dungeon.core_destroyed.connect(_on_co_loa_core_destroyed)
		if dungeon.has_signal("wave_started"):
			dungeon.wave_started.connect(func(w: int):
				if Net != null and Net.is_online() and Net.is_host():
					Net.send_world_event("co_loa_wave", {"wave": w, "state": "fighting", "prep_time": 0.0}, false))
		if dungeon.has_signal("wave_cleared"):
			dungeon.wave_cleared.connect(func(w: int):
				if Net != null and Net.is_online() and Net.is_host():
					Net.send_world_event("co_loa_wave", {"wave": w, "state": "prep", "prep_time": float(dungeon.get("prep_time"))}, false))
		if net_sync != null:
			net_sync.set_deferred("is_clearing_level", false)
		var cl_start: Vector2 = dungeon.start_position()
		_place_players_at(cl_start)
		camera.reset_smoothing()
		if not Net.is_online() or Net.is_host():
			Global.save_run(player)
		hud.show_banner("Thủ Thành Cổ Loa — Bảo vệ Lẫy Nỏ Thần!")
		return

	var ch := EnemyData.chapter(Global.level)
	darkness.color = ch.dark
	var is_br_hall: bool = Global.is_boss_rush() and Global.level >= 13
	var sb_music_raw: Variant = Global.get("secret_biome_override")
	var sb_music_id: String = str(sb_music_raw) if sb_music_raw != null else ""
	if is_br_hall or Global.level == 16 or Global.level == 32 or Global.level >= 34:
		Sfx.play_music("victory")
	elif sb_music_id != "" and Sfx.has_method("play_secret_biome_music"):
		Sfx.play_secret_biome_music(sb_music_id)
	elif Global.level == 33:
		Sfx.play_music("boss_hon_mang")
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
	if Global.get("next_branch_kind") != null:
		Global.set("next_branch_kind", "standard")
	dungeon.portal_entered.connect(_on_portal)
	if dungeon.has_signal("portal_entered_branch"):
		dungeon.portal_entered_branch.connect(_on_portal_branch)
	var wfx_script := _load_weather_script()
	if wfx_script != null:
		var wnode: Node = wfx_script.new()
		if wnode != null:
			world.add_child(wnode)
			if wnode.has_method("setup"):
				wnode.setup(Global.level, _compute_dungeon_bounds())
			_weather_node = wnode
	if net_sync != null:
		net_sync.set_deferred("is_clearing_level", false)
	var start_pos: Vector2 = dungeon.start_position()
	_place_players_at(start_pos)
	camera.reset_smoothing()
	if not Net.is_online() or Net.is_host():
		Global.save_run(player)     # điểm lưu đầu mỗi màn (tắt game thì "Chơi tiếp" từ đây)
	var sb_raw: Variant = Global.get("secret_biome_override")
	var sb_active: String = str(sb_raw) if sb_raw != null else ""
	var stage := EnemyData.stage_in_chapter(Global.level)
	var chn := EnemyData.stage_chapter_num(Global.level)
	if sb_active != "":
		hud.show_banner("Bí Cảnh: %s!" % str(ch.get("name", sb_active)))
	elif Global.level == 33:
		hud.show_banner("Đỉnh Hồng Lĩnh — Cửu Trùng! Đối mặt Hỗn Mang Yêu Đế!")
	elif Global.level >= 34:
		hud.show_banner("Cửu Trùng Khải Hoàn — Giang Sơn Gấm Vóc!")
	elif Global.is_boss_rush():
		if Global.level >= 13:
			hud.show_banner("Boss Rush 13/13  -  Sảnh Chiến Thần Khải Hoàn!")
		else:
			hud.show_banner("Boss Rush %d/12  -  Trận Quyết Chiến Trùm!" % Global.level)
	elif Global.level == 16:
		hud.show_banner("Màn 3-6  -  Sảnh Khải Hoàn!")
	elif Global.level >= 32:
		hud.show_banner("Màn 6-6  -  Sảnh Huyền Thoại!")
	elif stage == 1:
		hud.show_chapter(chn, ch)
	else:
		var prefix: String = "Thần thoại " if EnemyData.is_mythic_level(Global.level) else "Màn "
		hud.show_banner("%s%d-%d%s" % [prefix, chn, stage, "  -  Trận quyết chiến!" if EnemyData.is_boss_level(Global.level) else ""])


func _place_players_at(start_pos: Vector2) -> void:
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
				var pp: Variant = pets_by_peer.get(pid, null)
				if pp != null and is_instance_valid(pp):
					(pp as Node2D).global_position = pos + Vector2(-18.0, 12.0)
			idx += 1
	else:
		player.global_position = start_pos
		player.nearby_pickup = null
		if pet != null and is_instance_valid(pet):
			(pet as Node2D).global_position = start_pos + Vector2(-18.0, 12.0)


func _on_co_loa_core_destroyed() -> void:
	if _leaving or _game_over != null:
		return
	await get_tree().create_timer(1.0).timeout
	if _leaving or not is_inside_tree():
		return
	_show_game_over()


func _grant_bonus_relic() -> void:
	var owned: Array = []
	if Global.get("run_relics") is Array:
		owned = Global.get("run_relics") as Array
	var rid: String = RelicData.roll_relic(owned)
	if rid != "" and Global.has_method("add_relic"):
		Global.call("add_relic", rid)


func _on_portal() -> void:
	if _portal_triggered:
		return
	_on_portal_branch("standard")


func _on_portal_branch(bk: String) -> void:
	if _portal_triggered:
		return
	if Net.is_online() and not Net.is_host():
		return
	_portal_triggered = true

	var sb_raw: Variant = Global.get("secret_biome_override")
	var sb_cur: String = str(sb_raw) if sb_raw != null else ""

	if bk.begins_with("secret:"):
		var sb_id: String = bk.substr(7)
		if Global.get("secret_biome_override") != null:
			Global.set("secret_biome_override", sb_id)
		Sfx.play("level_clear")
		touch.reset()
		if Net.is_online() and Net.is_host():
			Net.send_world_event("secret_biome", {"id": sb_id}, false)
		_build_level.call_deferred()
		return

	if bk == "secret_return" or sb_cur != "":
		if Global.get("secret_biome_override") != null:
			Global.set("secret_biome_override", "")
		var sbb_v: Variant = Global.get("secret_bosses_beaten")
		if sbb_v != null:
			Global.set("secret_bosses_beaten", int(sbb_v) + 1)
		Global.stats["secret_bosses"] = int(Global.stats.get("secret_bosses", 0)) + 1
		Global.run_coins += 40
		_grant_bonus_relic()
	elif bk == "true_ending":
		if Global.get("secret_biome_override") != null:
			Global.set("secret_biome_override", "")
		Sfx.play("level_clear")
		touch.reset()
		if Net.is_online() and Net.is_host():
			Net.send_world_event("advance", {"level": 33}, false)
			_advance_to.call_deferred(33)
		else:
			_advance_to.call_deferred(33)
		return
	elif Global.get("next_branch_kind") != null:
		Global.set("next_branch_kind", bk)

	if Net.is_online():
		if Global.level == 16 or Global.level == 31 or Global.level == 33:
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
	if (Global.is_boss_rush() and Global.level >= 13) or Global.level == 16 or Global.level == 31 or Global.level == 33:
		_advance.call_deferred()
		return
	# qua màn: chọn 1 phúc lành rồi mới sang màn mới
	var title: String
	if Global.level == 15:
		title = "Sảnh Khải Hoàn (Màn 3-6)"
	elif Global.level == 31:
		title = "Sảnh Huyền Thoại (Màn 6-6)"
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
	for p_pet in pets_by_peer.values():
		if p_pet != null and is_instance_valid(p_pet) and p_pet != pet and p_pet.has_method("on_next_level"):
			p_pet.on_next_level()
	Global.level += 1
	Global.best_level = maxi(Global.best_level, Global.level)
	Global.on_next_stage_mutators(player)
	_build_level()


func _advance_to(lvl: int) -> void:
	if pet != null and is_instance_valid(pet) and pet.has_method("on_next_level"):
		pet.on_next_level()
	for p_pet in pets_by_peer.values():
		if p_pet != null and is_instance_valid(p_pet) and p_pet != pet and p_pet.has_method("on_next_level"):
			p_pet.on_next_level()
	Global.level = lvl
	Global.best_level = maxi(Global.best_level, Global.level)
	Global.on_next_stage_mutators(player)
	_build_level()


func can_pause() -> bool:
	if _leaving or not is_inside_tree():
		return false
	if player == null or not is_instance_valid(player) or player.dead:
		return false
	if _game_over != null or _victory_ui != null:
		return false
	if buff_ui != null and is_instance_valid(buff_ui) and buff_ui.visible:
		return false
	return get_tree().get_nodes_in_group("shop_ui_open").is_empty()


# ------------------------------------------------------------------ Mạng LAN

func _on_net_player_state(peer_id: int, state: Dictionary) -> void:
	var rp: Variant = players_by_peer.get(peer_id, null)
	if rp != null and is_instance_valid(rp) and not bool(rp.get("is_local")):
		rp.apply_remote_state(state)


func _on_net_player_action(peer_id: int, kind: String, data: Dictionary) -> void:
	var rp: Variant = players_by_peer.get(peer_id, null)
	if rp != null and is_instance_valid(rp) and not bool(rp.get("is_local")):
		rp.play_remote_action(kind, data)
		if kind == "ping" and world != null and is_instance_valid(world):
			var ppos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
			var pname: String = str(data.get("name", rp.get("display_name")))
			var pcol: Color = rp.get("name_color") as Color if rp.get("name_color") is Color else Color(0, 0, 0, 0)
			PingMarker.spawn_ping(world, ppos, str(data.get("kind", "focus")), pname, pcol)
	if kind == "skill" and (Net == null or not Net.is_online() or Net.is_host()):
		var hid: String = str(data.get("hero_id", ""))
		if hid == "" and rp != null and is_instance_valid(rp):
			hid = str(rp.get("hero_id"))
		var fallback_pos: Vector2 = (rp as Node2D).global_position if (rp != null and is_instance_valid(rp) and rp is Node2D) else Vector2.ZERO
		var pos := Vector2(float(data.get("x", fallback_pos.x)), float(data.get("y", fallback_pos.y)))
		_record_skill_cast(peer_id, hid, pos)


func host_spawn_shared_weapon(wid: String, pos: Vector2) -> Node:
	if wid == "" or not WeaponData.DATA.has(wid):
		return null
	var par: Node = dungeon if (dungeon != null and is_instance_valid(dungeon)) else (world if (world != null and is_instance_valid(world)) else self)
	var pk := Pickup.new()
	pk.kind = "weapon"
	pk.weapon_id = wid
	pk.position = pos
	if Net != null and Net.is_online() and Net.is_host() and net_sync != null:
		pk.pickup_id = net_sync.alloc_pickup_id()
		par.add_child(pk)
		net_sync.register_pickup(pk)
		Net.send_world_event("spawn_pickup", {
			"id": pk.pickup_id,
			"kind": "weapon",
			"amount": 1,
			"weapon_id": wid,
			"material_id": "",
			"blueprint_id": "",
			"x": pos.x,
			"y": pos.y,
		}, false)
		return pk
	par.add_child(pk)
	return pk


func host_handle_weapon_pickup_req(claimer_peer: int, data: Dictionary) -> void:
	if Net != null and Net.is_online() and not Net.is_host():
		return
	if net_sync == null:
		return
	var pid: int = int(data.get("pickup_id", 0))
	if pid <= 0 or net_sync.claimed_pickups.has(pid):
		return
	var pk: Node = net_sync.get_pickup(pid)
	if pk == null or not is_instance_valid(pk) or str(pk.get("kind")) != "weapon":
		return
	var wid: String = str(pk.get("weapon_id"))
	if wid == "":
		return
	net_sync.claimed_pickups[pid] = true
	var drop_wid: String = str(data.get("drop_wid", ""))
	var drop_pos := Vector2(float(data.get("x", (pk as Node2D).global_position.x)), float(data.get("y", (pk as Node2D).global_position.y)))
	Net.send_world_event("pickup_claimed", {"id": pid, "claimer": claimer_peer, "kind": "weapon", "weapon_id": wid}, false)
	if pk.has_method("net_remove_claimed"):
		pk.net_remove_claimed()
	else:
		pk.queue_free()
	if claimer_peer == Net.local_peer_id() and player != null and is_instance_valid(player) and player.has_method("net_apply_weapon_pickup"):
		player.net_apply_weapon_pickup(wid)
	if drop_wid != "" and WeaponData.DATA.has(drop_wid):
		host_spawn_shared_weapon(drop_wid, drop_pos)


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
			pk.blueprint_id = str(data.get("blueprint_id", ""))
			pk.position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
			dungeon.add_child(pk)
			if pid > 0 and net_sync != null:
				net_sync.register_pickup(pk)
		"drop_weapon_req":
			if not Net.is_host():
				return
			var d_wid: String = str(data.get("weapon_id", ""))
			var d_pos := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
			if d_wid != "" and WeaponData.DATA.has(d_wid):
				host_spawn_shared_weapon(d_wid, d_pos)
		"weapon_pickup_req":
			if not Net.is_host():
				return
			var sender_w: int = int(data.get("sender", 0))
			if sender_w > 0:
				host_handle_weapon_pickup_req(sender_w, data)
		"treasure_open_req":
			if not Net.is_host() or dungeon == null:
				return
			var rkey_t: String = str(data.get("key", ""))
			if rkey_t == "" and data.has("gx") and data.has("gy"):
				rkey_t = "%d,%d" % [int(data.get("gx", 0)), int(data.get("gy", 0))]
			var rm_t: Node = dungeon.get_room_by_key(rkey_t)
			if rm_t != null and rm_t.has_method("open_treasure_authoritative"):
				rm_t.open_treasure_authoritative()
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
			var claim_kind: String = str(data.get("kind", ""))
			var claim_wid: String = str(data.get("weapon_id", ""))
			var pk2: Node = net_sync.get_pickup(pid3)
			if claim_kind == "weapon":
				if claimer == Net.local_peer_id() and player != null and is_instance_valid(player) and player.has_method("net_apply_weapon_pickup"):
					var apply_wid: String = claim_wid if claim_wid != "" else (str(pk2.get("weapon_id")) if pk2 != null else "")
					if apply_wid != "":
						player.net_apply_weapon_pickup(apply_wid)
				if pk2 != null and pk2.has_method("net_remove_claimed"):
					pk2.net_remove_claimed()
			elif pk2 != null:
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
			var drop_bp: bool = bool(data.get("drop_bp", false))
			for ch_node2 in get_tree().get_nodes_in_group("loot_chests"):
				if is_instance_valid(ch_node2) and str(ch_node2.get("chest_id")) == cid2:
					if ch_node2.has_method("apply_open_drops"):
						ch_node2.apply_open_drops(drops, drop_bp)
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
		"secret_biome":
			if Net.is_host():
				return
			if Global.get("secret_biome_override") != null:
				Global.set("secret_biome_override", str(data.get("id", "")))
			_build_level.call_deferred()
		"co_loa_wave":
			if Net.is_host() or dungeon == null or not is_instance_valid(dungeon):
				return
			dungeon.set("wave", int(data.get("wave", 0)))
			dungeon.set("state", str(data.get("state", "prep")))
			dungeon.set("prep_time", float(data.get("prep_time", 0.0)))
		"co_loa_tower":
			if Net.is_host() or dungeon == null or not is_instance_valid(dungeon):
				return
			var pad_id: int = int(data.get("pad_id", -1))
			var tlist: Variant = dungeon.get("towers")
			if tlist is Array and pad_id >= 0 and pad_id < (tlist as Array).size():
				var tw: Variant = (tlist as Array)[pad_id]
				if tw != null and is_instance_valid(tw) and tw.has_method("apply_state"):
					tw.apply_state(data)
		"co_loa_core":
			if Net.is_host() or dungeon == null or not is_instance_valid(dungeon):
				return
			var cnode: Variant = dungeon.get("core")
			if cnode != null and is_instance_valid(cnode):
				cnode.set("max_hp", int(data.get("max_hp", 250)))
				cnode.set("hp", int(data.get("hp", 250)))
		"co_loa_tower_req":
			if not Net.is_host() or dungeon == null or not is_instance_valid(dungeon):
				return
			var pad_req: int = int(data.get("pad_id", -1))
			var tlist2: Variant = dungeon.get("towers")
			if tlist2 is Array and pad_req >= 0 and pad_req < (tlist2 as Array).size():
				var tw2: Variant = (tlist2 as Array)[pad_req]
				if tw2 != null and is_instance_valid(tw2):
					var op: String = str(data.get("op", ""))
					if op == "build" and tw2.has_method("build_tower"):
						tw2.build_tower(str(data.get("tower_id", "")))
					elif op == "interact" and tw2.has_method("interact"):
						tw2.interact()
					elif op == "cycle" and tw2.has_method("cycle_build_choice"):
						tw2.cycle_build_choice()
					if tw2.has_method("export_state"):
						Net.send_world_event("co_loa_tower", tw2.export_state(), false)
		"coop_combo":
			if Net.is_host():
				return
			var ha: String = str(data.get("hero_a", ""))
			var hb: String = str(data.get("hero_b", ""))
			var pa := Vector2(float(data.get("ax", 0.0)), float(data.get("ay", 0.0)))
			var pb := Vector2(float(data.get("bx", 0.0)), float(data.get("by", 0.0)))
			_execute_coop_combo(ha, hb, pa, pb, false)


func _load_weather_script() -> Script:
	var p := "res://scripts/effects/weather_fx.gd"
	if ResourceLoader.exists(p):
		return load(p) as Script
	return null


func _compute_dungeon_bounds() -> Rect2:
	if dungeon == null or not is_instance_valid(dungeon) or dungeon.rooms.is_empty():
		return Rect2(Vector2(-480.0, -360.0), Vector2(960.0, 720.0))
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for c in dungeon.rooms:
		var rm: Variant = dungeon.rooms[c]
		if rm != null and is_instance_valid(rm):
			var rect: Rect2 = rm.rect
			min_p.x = minf(min_p.x, rect.position.x)
			min_p.y = minf(min_p.y, rect.position.y)
			max_p.x = maxf(max_p.x, rect.end.x)
			max_p.y = maxf(max_p.y, rect.end.y)
	if min_p.x == INF:
		return Rect2(Vector2(-480.0, -360.0), Vector2(960.0, 720.0))
	var margin := Vector2(180.0, 180.0)
	return Rect2(min_p - margin, (max_p - min_p) + margin * 2.0)


func on_local_skill_cast(hero_id: String, pos: Vector2) -> void:
	var local_pid: int = Net.local_peer_id() if Net != null else 1
	_record_skill_cast(local_pid, hero_id, pos)


func trigger_coop_combo_test(hero_a: String, hero_b: String, pos_a: Vector2, pos_b: Vector2) -> Dictionary:
	return _execute_coop_combo(hero_a, hero_b, pos_a, pos_b, true)


func _record_skill_cast(peer_id: int, hero_id: String, pos: Vector2) -> void:
	var stale: Array = []
	for k in _recent_skill_casts:
		var entry: Dictionary = _recent_skill_casts[k]
		if _coop_clock - float(entry.get("t", 0.0)) > COOP_COMBO_WINDOW:
			stale.append(k)
	for k in stale:
		_recent_skill_casts.erase(k)
	_recent_skill_casts[peer_id] = {"hero": hero_id, "pos": pos, "t": _coop_clock}
	if Net != null and Net.is_online() and not Net.is_host():
		return
	if _coop_combo_cd > 0.0:
		return
	for k in _recent_skill_casts:
		var other_pid: int = int(k)
		if other_pid == peer_id:
			continue
		var other: Dictionary = _recent_skill_casts[k]
		if _coop_clock - float(other.get("t", 0.0)) > COOP_COMBO_WINDOW:
			continue
		var other_pos: Vector2 = other.get("pos", Vector2.ZERO)
		if pos.distance_to(other_pos) > COOP_COMBO_MAX_DIST:
			continue
		var hero_a: String = str(other.get("hero", ""))
		var hero_b: String = hero_id
		_recent_skill_casts.clear()
		_coop_combo_cd = COOP_COMBO_COOLDOWN
		_execute_coop_combo(hero_a, hero_b, other_pos, pos, true)
		if Net != null and Net.is_online() and Net.is_host():
			Net.send_world_event("coop_combo", {
				"hero_a": hero_a,
				"hero_b": hero_b,
				"ax": other_pos.x,
				"ay": other_pos.y,
				"bx": pos.x,
				"by": pos.y,
			}, false)
		break


func _execute_coop_combo(hero_a: String, hero_b: String, pos_a: Vector2, pos_b: Vector2, apply_damage: bool) -> Dictionary:
	var combo: Dictionary = CoopSynergyData.resolve(hero_a, hero_b)
	var mid: Vector2 = (pos_a + pos_b) * 0.5
	var rad: float = float(combo.get("radius", 160.0))
	var dmg: int = int(combo.get("damage", 30))
	var stun_dur: float = float(combo.get("stun_dur", 1.2))
	var combo_col: Color = combo.get("color", Color(1.0, 0.84, 0.34))
	var fx_parent: Node = world if (world != null and is_instance_valid(world)) else self
	CoopComboFx.spawn(fx_parent, pos_a, pos_b, combo)
	Sfx.play("skill")
	add_shake(6.0)
	Fx.float_text(fx_parent, mid + Vector2(0.0, -28.0), str(combo.get("name", "Hợp Chiêu Đại Việt")), combo_col, 18)

	if apply_damage and is_inside_tree():
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or bool(e.get("dead")):
				continue
			var dist_e: float = e.distance_to_hurtbox(mid) if e.has_method("distance_to_hurtbox") else (mid.distance_to((e as Node2D).global_position) - float(e.get("radius")))
			if dist_e <= rad:
				var e_ctr: Vector2 = e.hurtbox_center() if e.has_method("hurtbox_center") else (e as Node2D).global_position
				var kdir: Vector2 = (e_ctr - mid).normalized()
				if kdir.length_squared() < 0.0001:
					kdir = Vector2.RIGHT
				if e.has_method("take_damage"):
					e.take_damage(dmg, kdir * 220.0)
				if stun_dur > 0.0 and e.has_method("apply_stun"):
					e.apply_stun(stun_dur)

	if player != null and is_instance_valid(player) and not bool(player.get("dead")):
		var armor_b: int = int(combo.get("armor_bonus", 2))
		var energy_b: int = int(combo.get("energy_bonus", 40))
		var buff_d: float = float(combo.get("buff_dur", 4.0))
		player.armor = mini(int(player.armor) + armor_b, int(player.max_armor))
		if player.has_method("add_energy"):
			player.add_energy(energy_b)
		else:
			player.energy = mini(int(player.energy) + energy_b, int(player.max_energy))
		player.buff_timer = maxf(float(player.buff_timer), buff_d)
		if player.has_signal("stats_changed"):
			player.stats_changed.emit()

	if hud != null and is_instance_valid(hud):
		if hud.has_method("show_coop_combo"):
			hud.show_coop_combo(str(combo.get("name", "Hợp Chiêu Đại Việt")), str(combo.get("subtitle", "")), combo_col)
		elif hud.has_method("show_banner"):
			hud.show_banner("Hợp Chiêu: %s!" % str(combo.get("name", "Hợp Chiêu Đại Việt")))

	if Global != null:
		if Global.has_method("add_stat"):
			Global.add_stat("coop_combos")
		if Global.has_method("unlock_chronicle"):
			var res: Variant = Global.unlock_chronicle("coop_dong_tam")
			if typeof(res) == TYPE_DICTIONARY and bool((res as Dictionary).get("newly_unlocked", false)):
				if hud != null and is_instance_valid(hud) and hud.has_method("show_chronicle_toast"):
					hud.show_chronicle_toast(str((res as Dictionary).get("title", "")))
	return combo


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
	if _team_wiped or _leaving:
		return
	_team_wiped = true
	await get_tree().create_timer(1.0).timeout
	if _leaving or not is_inside_tree():
		return
	_show_game_over()


func _on_net_host_left(_reason: String) -> void:
	if _leaving:
		return
	_leaving = true
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu._leaving = true
		pause_menu.set_process_unhandled_input(false)
	if Net != null:
		if Net.is_host():
			Global.end_run("bo_luot")
		Net.leave_room()
	if is_inside_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")


func _on_net_player_disconnected(peer_id: int, pname: String) -> void:
	if players_by_peer.has(peer_id):
		var rp: Variant = players_by_peer[peer_id]
		players_by_peer.erase(peer_id)
		if rp != null and is_instance_valid(rp) and rp != player:
			(rp as Node).queue_free()
	if pets_by_peer.has(peer_id):
		var rpet: Variant = pets_by_peer[peer_id]
		pets_by_peer.erase(peer_id)
		if rpet != null and is_instance_valid(rpet) and rpet != pet:
			(rpet as Node).queue_free()
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
	_spawn_net_pet(peer_id, rp, info)
	if pets_by_peer.has(peer_id):
		var rpet2: Variant = pets_by_peer[peer_id]
		if rpet2 != null and is_instance_valid(rpet2):
			(rpet2 as Node2D).global_position = spawn_pos + Vector2(-18.0, 12.0)
	hud.show_banner("%s đã kết nối lại!" % str(info.get("name", "Đồng đội")))


# ------------------------------------------------------------------ Thua cuộc

func _on_player_died() -> void:
	if Net != null and Net.is_online() and Net.player_count() > 1:
		_check_team_wipe()
		return
	await get_tree().create_timer(1.0).timeout
	if _leaving or not is_inside_tree():
		return
	_show_game_over()


func _build_match_summary_panel() -> PanelContainer:
	var raw_stats: Variant = Global.get("run_player_stats")
	var pstats: Dictionary = (raw_stats as Dictionary).duplicate(true) if raw_stats is Dictionary else {}
	if pstats.is_empty():
		var mvp_wid: String = ""
		if player != null and is_instance_valid(player) and player.get("weapons") is Array:
			var ws: Array = player.weapons
			var sl: int = int(player.get("slot"))
			if sl >= 0 and sl < ws.size():
				mvp_wid = str(ws[sl])
		pstats[1] = {
			"hero": Global.selected_hero,
			"name": str(Global.settings.get("player_name", "Anh Hùng")),
			"damage": 0,
			"kills": Global.run_kills,
			"combos": 0,
			"revives": 0,
			"fragments": 0,
			"mvp_weapon": mvp_wid,
		}
	return MatchSummary.build_panel(pstats)


func show_victory(mythic: bool = false) -> void:
	if _victory_ui != null:
		return
	touch.reset()
	if hud != null and hud.has_method("clear_boss_intro"):
		hud.clear_boss_intro()
	var is_true_ending: bool = Global.level >= 34
	var bonus_coins: int = 150 if is_true_ending else (90 if mythic else 50)
	if not Net.is_online() or Net.is_host():
		Global.coins += bonus_coins
		Global.materials["ngoc_than"] = Global.material_count("ngoc_than") + (3 if is_true_ending else (2 if mythic else 1))
		if is_true_ending:
			Global.materials["yeu_hon"] = Global.material_count("yeu_hon") + 3
			Global.stats["mythic_clears"] = int(Global.stats.get("mythic_clears", 0)) + 1
			Global.stats["true_endings"] = int(Global.stats.get("true_endings", 0)) + 1
		elif mythic:
			Global.materials["yeu_hon"] = Global.material_count("yeu_hon") + 2
			Global.stats["mythic_clears"] = int(Global.stats.get("mythic_clears", 0)) + 1
	var entry: Dictionary = Global.record_score("thang")
	Global.save_game()
	_victory_ui = CanvasLayer.new()
	_victory_ui.layer = 30
	add_child(_victory_ui)
	var box := UI.overlay(_victory_ui, 0.72)
	box.add_theme_constant_override("separation", 4)
	if is_true_ending:
		box.add_child(UI.label("VẠN ĐẠI BÌNH YÊN! GIANG SƠN GẤM VÓC!", 24, Color(1.0, 0.90, 0.36)))
		box.add_child(UI.label("Đánh bại Hỗn Mang Yêu Đế tại Đỉnh Hồng Lĩnh — Cửu Trùng!", 14, Color(0.92, 0.86, 1.0)))
		box.add_child(UI.label("Thưởng Vạn Cổ: +150 xu, +3 Ngọc thần, +3 Yêu hồn  |  Xu trận: %d xu" % Global.run_coins, 13, Color(0.62, 0.98, 0.76)))
	elif mythic:
		box.add_child(UI.label("VANG DANH SỬ SÁCH! ĐẠI THẮNG THẦN THOẠI!", 24, Color(0.92, 0.72, 1.0)))
		box.add_child(UI.label("Chinh phục trọn vẹn 6 Chương & Yêu Vương Lĩnh Nam (Màn 4-1 → 6-6)!", 14, Color(0.86, 0.94, 0.98)))
		box.add_child(UI.label("Thưởng Huyền Thoại: +90 xu, +2 Ngọc thần, +2 Yêu hồn  |  Xu trận: %d xu" % Global.run_coins, 13, Color(0.62, 0.98, 0.76)))
	elif Global.is_boss_rush():
		box.add_child(UI.label("ĐẠI THẮNG BOSS RUSH! CHIẾN THẦN VÔ ĐỊCH!", 24, Color(1.0, 0.42, 0.44)))
		box.add_child(UI.label("Chinh phục trọn vẹn 12 Trùm liên hoàn!", 14, Color(0.86, 0.94, 0.98)))
		box.add_child(UI.label("Thưởng khải hoàn: +50 xu & +1 Ngọc thần  |  Tổng kết xu trận: %d xu" % Global.run_coins, 13, Color(0.55, 0.98, 0.72)))
	else:
		box.add_child(UI.label("ĐẠI THẮNG! KHẢI HOÀN!", 26, Color(1.0, 0.88, 0.35)))
		var ch := EnemyData.chapter(Global.level)
		box.add_child(UI.label("Hoàn thành 3 Chương (Màn 1-1 → 3-6) tại %s - %s!" % [ch.name, ch.year], 14, Color(0.86, 0.94, 0.98)))
		box.add_child(UI.label("Thưởng khải hoàn: +50 xu & +1 Ngọc thần  |  Tổng kết xu trận: %d xu" % Global.run_coins, 13, Color(0.55, 0.98, 0.72)))
	var score_line: String = "Thời gian: %s  |  Số giặc: %d  |  Điểm: %d" % [
		Global.format_time(float(entry.get("time", Global.run_elapsed))),
		int(entry.get("kills", Global.run_kills)),
		int(entry.get("score", 0)),
	]
	box.add_child(UI.label(score_line, 14, Color(1.0, 0.88, 0.45)))
	box.add_child(UI.center(_build_match_summary_panel()))
	var share_txt: String = Global.format_share_text(entry)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	_copy_btn = UI.button("Chép kết quả", func(): _on_copy_result(share_txt), 14, 140.0)
	btn_row.add_child(_copy_btn)
	if not Net.is_online():
		if is_true_ending or mythic or Global.is_boss_rush():
			btn_row.add_child(UI.button("Về Doanh Trại (Tổng kết xu)", _on_victory_lobby, 14, 240.0))
		else:
			btn_row.add_child(UI.button("Về Doanh Trại", _on_victory_lobby, 14, 150.0))
			btn_row.add_child(UI.button("Khởi Hành Thần Thoại (4-1 → 6-6)", _on_victory_continue, 14, 250.0))
	else:
		if not mythic and not is_true_ending:
			btn_row.add_child(UI.button("Khởi Hành Thần Thoại", _on_victory_continue, 14, 210.0))
		btn_row.add_child(UI.button("Rời phòng LAN", _on_menu, 14, 160.0))
	box.add_child(btn_row)


func _on_victory_lobby() -> void:
	if _leaving:
		return
	_leaving = true
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu._leaving = true
		pause_menu.set_process_unhandled_input(false)
	Global.end_run("thang")
	if is_inside_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/lobby.tscn")


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
	box.add_theme_constant_override("separation", 4)
	var heading: String = "Toàn đội đã gục ngã!" if (Net.is_online() and Net.player_count() > 1) else ("Thành Cổ Loa đã thất thủ!" if _is_co_loa_mode else "Tướng quân đã ngã xuống!")
	box.add_child(UI.label(heading, 26, Color(1, 0.55, 0.45)))
	var ch := EnemyData.chapter(Global.level)
	var sub: String = "%s - %s  |  Nhặt được %d xu" % [ch.name, ch.year, Global.run_coins]
	if _is_co_loa_mode and dungeon != null:
		sub = "Thủ Thành Cổ Loa — Đợt %d  |  Nhặt được %d xu" % [int(dungeon.get("wave")), Global.run_coins]
	elif Global.challenge_code != "":
		sub = "Mã thử thách: %s  |  %s" % [Global.challenge_code, sub]
	box.add_child(UI.label(sub, 14))
	var score_line: String = "Màn: %d  |  Thời gian: %s  |  Số giặc: %d  |  Điểm: %d" % [
		int(entry.get("level", Global.level)),
		Global.format_time(float(entry.get("time", Global.run_elapsed))),
		int(entry.get("kills", Global.run_kills)),
		int(entry.get("score", 0)),
	]
	box.add_child(UI.label(score_line, 15, Color(1.0, 0.88, 0.45)))
	box.add_child(UI.center(_build_match_summary_panel()))
	var share_txt: String = Global.format_share_text(entry)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	_copy_btn = UI.button("Chép kết quả", func(): _on_copy_result(share_txt), 14, 136.0)
	btn_row.add_child(_copy_btn)
	if not Net.is_online():
		if not _is_co_loa_mode and Global.free_revives > 0:
			btn_row.add_child(UI.button("Hồi sinh (Thuốc)", _on_free_revive, 14, 150.0))
		elif not _is_co_loa_mode and not Global.revived:
			btn_row.add_child(UI.button("Hồi sinh (QC)", _on_revive, 14, 140.0))
		btn_row.add_child(UI.button("Chơi lại", _on_restart, 14, 118.0))
		btn_row.add_child(UI.button("Về sảnh", _on_menu, 14, 118.0))
	else:
		btn_row.add_child(UI.button("Rời phòng LAN", _on_menu, 14, 160.0))
	box.add_child(btn_row)


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
	if _leaving:
		return
	_leaving = true
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu._leaving = true
		pause_menu.set_process_unhandled_input(false)
	var keep_code: String = Global.challenge_code
	var keep_mode: String = Global.run_mode
	var keep_muts: Array = Global.active_mutators.duplicate()
	Global.end_run()
	Global.pending_run_mode = keep_mode
	Global.pending_mutators = keep_muts
	Global.start_run(keep_code)
	if is_inside_tree():
		get_tree().paused = false
		get_tree().reload_current_scene.call_deferred()


func _on_menu() -> void:
	if _leaving:
		return
	_leaving = true
	if pause_menu != null and is_instance_valid(pause_menu):
		pause_menu._leaving = true
		pause_menu.set_process_unhandled_input(false)
	if Net != null and Net.is_online():
		if Net.is_host():
			Global.end_run("" if (_team_wiped or (player != null and is_instance_valid(player) and player.dead)) else "bo_luot")
		Net.leave_room()
		if is_inside_tree():
			get_tree().paused = false
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		return
	Global.end_run("" if (player != null and is_instance_valid(player) and player.dead) else "bo_luot")
	if is_inside_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/lobby.tscn")
