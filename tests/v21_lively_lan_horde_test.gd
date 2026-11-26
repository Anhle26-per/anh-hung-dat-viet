extends Node
## Kiểm thử tổng hợp v2.1.0 ("Vạn Binh Khởi Trận"):
##   1) 13 Trùm Pha 1 + Pha 2 (26 tờ): 36 khung + chuyển mượt qua 10 trạng thái hành động
##   2) Sảnh solo click-to-select & cổng xác nhận (hero_confirmed), 5 NPC mới, LobbyLife.set_resting_hidden,
##      Linh thú đồng hành theo người chơi từ Sảnh xuống Tầng Hầm
##   3) LAN Co-op: chọn trùng tướng, host_enter_lobby(), in_lobby, request_set_pet(), all_peers_confirmed()
##   4) Nhịp độ Horde: MAX_ENEMIES == 28, waves_for_level, >= 8 giặc/đợt ở màn 1, vòng báo 0.55s, gọi đợt sớm khi <= 2 giặc
## Chạy: godot --headless --path . res://tests/v21_lively_lan_horde_test.tscn -> "V21 LIVELY LAN HORDE TEST OK"

const VersionData = preload("res://scripts/data/version.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")
const LobbyLife = preload("res://scripts/game/lobby_life.gd")
const RoomScript = preload("res://scripts/game/room.gd")
const DungeonScript = preload("res://scripts/game/dungeon.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")

const TEST_SAVE := "user://v21_test_save.json"
const CLIENT_SAVE := "user://v21_test_client_save.json"
const TEST_PORT := 17779

var _fail: int = 0
var _completed: bool = false
var _is_client: bool = false
var _client_pid: int = -1
var _client_entered_lobby: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _phys_frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(pred.call()):
			return true
		await get_tree().process_frame
	return bool(pred.call())


func _kill_client() -> void:
	if _client_pid > 0 and OS.is_process_running(_client_pid):
		OS.kill(_client_pid)
	_client_pid = -1


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", CLIENT_SAVE, CLIENT_SAVE + ".tmp",
			"user://v21_test_save_run.json", "user://v21_test_client_save_run.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	_is_client = uargs.has("--v21-lan-client")
	get_tree().create_timer(60.0).timeout.connect(func():
		print("V21 LIVELY LAN HORDE TEST FAILED: quá thời gian")
		_kill_client()
		Net.leave_room()
		_wipe()
		get_tree().quit(1))
	if _is_client:
		_run_lan_client.call_deferred()
		return
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	await _frames(2)
	await _run()
	_kill_client()
	Net.leave_room()
	_wipe()
	if _fail == 0 and _completed:
		print("V21 LIVELY LAN HORDE TEST OK")
		get_tree().quit(0)
	else:
		print("V21 LIVELY LAN HORDE TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	_wipe()
	print("== 1. Kiểm tra Version 2.1.0 (BUILD 210) & HotpatchSync")
	_check(VersionData.VERSION == "2.1.0", "VERSION phải là 2.1.0 (hiện %s)" % VersionData.VERSION)
	_check(VersionData.BUILD == 210, "BUILD phải là 210 (hiện %d)" % VersionData.BUILD)
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "HotpatchSync.needs_autoload_sync phải false trên v2.1.0")

	await _test_boss_36_frames()
	await _test_lobby_select_npcs_pet()
	await _test_lan_duplicate_and_lobby()
	await _test_horde_waves()
	_completed = true


func _test_boss_36_frames() -> void:
	print("== 2. Kiểm tra 13 Trùm (Pha 1 + Pha 2 = 26 tờ) đủ 36 khung & 10 trạng thái hành động")
	var all_boss_ids: Array[String] = []
	for bid in EnemyData.BOSSES.keys():
		all_boss_ids.append(str(bid))
	for mid in EnemyData.MYTHIC_BOSSES.keys():
		all_boss_ids.append(str(mid))
	_check(all_boss_ids.size() == 13, "Tổng số trùm phải là 13 (hiện %d)" % all_boss_ids.size())

	for bid in EnemyData.BOSSES.keys():
		_check(int(EnemyData.BOSSES[bid].get("frames", 0)) == 36, "BOSSES[%s].frames phải là 36" % str(bid))
	for lid in EnemyData.LEGENDS.keys():
		_check(int(EnemyData.LEGENDS[lid].get("frames", 0)) == 36, "LEGENDS[%s].frames phải là 36" % str(lid))
	for mid in EnemyData.MYTHIC_BOSSES.keys():
		_check(int(EnemyData.MYTHIC_BOSSES[mid].get("frames", 0)) == 36, "MYTHIC_BOSSES[%s].frames phải là 36" % str(mid))

	var arena := Node2D.new()
	add_child(arena)
	var req_anims: Array[String] = ["idle", "walk", "windup", "melee_sweep", "ranged_shot", "cast_summon", "dash", "leap", "rage", "special"]
	var expected_counts := {"idle": 4, "walk": 8, "windup": 4, "melee_sweep": 4, "ranged_shot": 4, "cast_summon": 4, "dash": 2, "leap": 3, "rage": 2, "special": 2}

	# Kiểm tra 10 trùm lịch sử (Pha 1 + Pha 2) & 3 Tam Yêu (Pha 1 + Pha 2)
	var entries: Array[Dictionary] = []
	for bid in EnemyData.BOSSES.keys():
		entries.append({"kind": "boss", "boss_id": str(bid), "lvl": 5})
	for lid in EnemyData.LEGENDS.keys():
		entries.append({"kind": "legend:" + str(lid), "boss_id": str(lid), "lvl": 6})

	for ent in entries:
		var bid: String = str(ent["boss_id"])
		if str(ent["kind"]) == "boss":
			Global.boss_order = [bid]
		var e = EnemyScript.new()
		e.setup(str(ent["kind"]), int(ent["lvl"]), null)
		e.position = Vector2(200, 200)
		arena.add_child(e)
		await _frames(1)
		for ph in [1, 2]:
			var sf: SpriteFrames = e.spr.sprite_frames
			for aname in req_anims:
				_check(sf.has_animation(aname), "%s Pha %d thiếu animation '%s'" % [bid, ph, aname])
				if sf.has_animation(aname):
					_check(sf.get_frame_count(aname) == int(expected_counts[aname]),
						"%s Pha %d animation '%s' có %d khung (cần %d)" % [bid, ph, aname, sf.get_frame_count(aname), int(expected_counts[aname])])
			# Kiểm tra chuyển trạng thái
			e._morph_t = 0.0
			e._special = ""
			e._special_t = 0.0
			e._charge_state = ""
			e._leap_state = ""
			e.velocity = Vector2.ZERO
			e._action_anim = ""
			e._action_anim_t = 0.0
			e._update_anim(0.016)
			_check(e.spr.animation == &"idle", "%s Pha %d đứng yên phải chạy idle (got %s)" % [bid, ph, str(e.spr.animation)])
			e.velocity = Vector2(50, 0)
			e._update_anim(0.016)
			_check(e.spr.animation == &"walk", "%s Pha %d di chuyển phải chạy walk" % [bid, ph])
			e.velocity = Vector2.ZERO
			for act in ["melee_sweep", "ranged_shot", "cast_summon"]:
				e._trigger_action_anim(act, 0.3)
				e._update_anim(0.016)
				_check(e.spr.animation == StringName(act), "%s Pha %d không chuyển sang %s" % [bid, ph, act])
			e._action_anim = ""
			e._action_anim_t = 0.0
			e._charge_state = "windup"
			e._update_anim(0.016)
			_check(e.spr.animation == &"windup", "%s Pha %d không chuyển sang windup" % [bid, ph])
			e._charge_state = "dash"
			e._update_anim(0.016)
			_check(e.spr.animation == &"dash", "%s Pha %d không chuyển sang dash" % [bid, ph])
			e._charge_state = ""
			e._leap_state = "air"
			e._update_anim(0.016)
			_check(e.spr.animation == &"leap", "%s Pha %d không chuyển sang leap" % [bid, ph])
			e._leap_state = ""
			e._morph_t = 0.2
			e._update_anim(0.016)
			_check(e.spr.animation == &"rage", "%s Pha %d không chuyển sang rage" % [bid, ph])
			e._morph_t = 0.0
			e._special = "test_sig"
			e._special_t = 0.5
			e._update_anim(0.016)
			_check(e.spr.animation == &"special", "%s Pha %d không chuyển sang special" % [bid, ph])
			e._special = ""
			e._special_t = 0.0
			if ph == 1:
				e._finish_morph()
				await _frames(1)
		e.queue_free()
	arena.queue_free()
	await _frames(2)


func _test_lobby_select_npcs_pet() -> void:
	print("== 3. Kiểm tra Sảnh Solo click-to-select, 5 NPC mới, set_resting_hidden & Linh thú theo xuống Tầng Hầm")
	Global.coins = 500
	Global.unlocked = ["hai_ba_trung", "ngo_quyen", "ba_trieu"]
	Global.selected_hero = "hai_ba_trung"
	Global.selected_pet = "dog"
	Global.save_game()

	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(4)

	# Chưa xác nhận tướng: player bị ẩn và khóa di chuyển, tất cả 11 NPC tướng hiện diện
	_check(not lobby.hero_confirmed, "Vào sảnh solo ban đầu hero_confirmed phải == false")
	_check(lobby.player != null and not lobby.player.visible and not lobby.player.is_physics_processing(),
		"Khi chưa xác nhận tướng, player phải ẩn và khóa physics_process")
	_check(lobby._hero_npcs.size() == 11, "Phải có đủ 11 _hero_npcs trong Đại Sảnh (hiện %d)" % lobby._hero_npcs.size())
	for hid in lobby._hero_npcs:
		_check(lobby._hero_npcs[hid].visible, "NPC tướng %s phải hiện trên bục khi chưa xác nhận" % str(hid))

	# 5 NPC mới trong LobbyLife
	for nkind in LobbyLife.NPC_KINDS:
		_check(lobby._npc_nodes.has(nkind) and is_instance_valid(lobby._npc_nodes[nkind]), "Thiếu NPC sảnh: " + str(nkind))
	_check(lobby._npc_nodes.size() == 5, "Phải có đủ 5 NPC sảnh mới (hiện %d)" % lobby._npc_nodes.size())

	# Linh thú nghỉ trong sảnh ban đầu hiện (chưa confirm_hero)
	var dog_rest: Node2D = lobby._animal_nodes.get("dog", null)
	var cat_rest: Node2D = lobby._animal_nodes.get("cat_hall", null)
	_check(dog_rest != null and dog_rest.visible, "Cún Vàng nghỉ ngơi phải hiện trước khi xác nhận tướng")

	# Mô phỏng click chọn tướng ngo_quyen trong Đại Sảnh
	var ngo_spot: Vector2 = lobby._hero_npcs["ngo_quyen"].global_position
	var hit_id: String = lobby._hero_at_world_pos(ngo_spot, 28.0)
	_check(hit_id == "ngo_quyen", "Click tọa độ bục Ngô Quyền phải bắt đúng 'ngo_quyen' (got '%s')" % hit_id)
	lobby.ui.open_hero(hit_id)
	await _frames(2)
	_check(lobby.ui.is_open(), "Mở bảng chọn tướng Ngô Quyền thất bại")
	lobby.confirm_hero("ngo_quyen")
	lobby.ui.close()
	await _frames(3)

	_check(lobby.hero_confirmed and lobby.player.visible and lobby.player.is_physics_processing(),
		"Sau confirm_hero, hero_confirmed phải true và player mở khóa di chuyển")
	_check(lobby.player.hero_id == "ngo_quyen", "Tướng đang điều khiển phải là ngo_quyen")
	_check(lobby.lobby_pet != null and is_instance_valid(lobby.lobby_pet) and bool(lobby.lobby_pet.in_lobby),
		"Phải sinh lobby_pet (in_lobby=true) theo người chơi sau confirm_hero")
	_check(str(lobby.lobby_pet.pet_id) == "dog", "lobby_pet phải là 'dog'")
	_check(dog_rest != null and bool(dog_rest._resting_hidden) and not dog_rest.visible,
		"Khi mang Cún Vàng đi theo, NPC Cún Vàng đang nghỉ phải bị ẩn qua set_resting_hidden(true)")

	# Đổi sang Mèo Tam Thể -> Cún Vàng nghỉ hiện lại, Mèo nghỉ ẩn đi
	Global.select_pet("cat")
	lobby.refresh_pet_stations()
	await _frames(2)
	_check(dog_rest != null and not bool(dog_rest._resting_hidden) and dog_rest.visible,
		"Sau khi đổi sang Mèo, Cún Vàng nghỉ phải hiện lại")
	_check(cat_rest != null and bool(cat_rest._resting_hidden) and not cat_rest.visible,
		"Sau khi đổi sang Mèo, Mèo nghỉ phải bị ẩn")
	_check(lobby.lobby_pet != null and str(lobby.lobby_pet.pet_id) == "cat", "lobby_pet phải đổi sang 'cat'")

	# Đi xuống Tầng Hầm & quay lại: lobby_pet phải theo cùng người chơi
	await lobby.enter_basement(true)
	await _frames(2)
	_check(lobby.in_basement, "Không vào được Tầng Hầm")
	_check(lobby.lobby_pet != null and (lobby.lobby_pet as Node2D).global_position.distance_to(lobby.player.global_position) < 48.0,
		"Linh thú phải đi theo người chơi xuống Tầng Hầm")
	await lobby.exit_basement(true)
	await _frames(2)
	_check(not lobby.in_basement, "Không lên lại được Đại Sảnh")
	_check(lobby.lobby_pet != null and (lobby.lobby_pet as Node2D).global_position.distance_to(lobby.player.global_position) < 48.0,
		"Linh thú phải theo người chơi về lại Đại Sảnh")

	lobby.queue_free()
	await _frames(3)


func _test_lan_duplicate_and_lobby() -> void:
	print("== 4. Kiểm tra LAN chọn trùng tướng, host_enter_lobby(), in_lobby, request_set_pet()")
	Global.unlocked = ["hai_ba_trung", "ngo_quyen", "ba_trieu"]
	Global.selected_hero = "hai_ba_trung"
	Global.save_game()

	var host_entered := [false]
	Net.entered_lan_lobby.connect(func(): host_entered[0] = true, CONNECT_ONE_SHOT)

	var err: int = Net.create_room("PhongV21", "ChuPhongV21", TEST_PORT)
	_check(err == OK, "Net.create_room thất bại: %d" % err)
	if err != OK:
		return

	var exe: String = OS.get_executable_path()
	var proj: String = ProjectSettings.globalize_path("res://")
	_client_pid = OS.create_process(exe, PackedStringArray([
		"--headless", "--path", proj, "res://tests/v21_lively_lan_horde_test.tscn", "--", "--v21-lan-client"
	]))
	_check(_client_pid > 0, "Không khởi chạy được client LAN v21")

	var client_joined: bool = await _wait_until(func() -> bool:
		return Net.players.size() >= 2, 12.0)
	_check(client_joined, "Client không kết nối kịp trong 12s")
	if not client_joined:
		return

	Net.host_enter_lobby()
	await _frames(3)
	_check(Net.in_lobby and bool(host_entered[0]), "host_enter_lobby() phải đặt Net.in_lobby = true và phát entered_lan_lobby")

	# Cả Host và Client đều chọn TRÙNG tướng "ngo_quyen" + pet khác nhau
	Net.request_set_hero("ngo_quyen")
	Net.request_set_pet("dog")
	Net.request_set_ready(true)

	var dup_ok: bool = await _wait_until(func() -> bool:
		if Net.players.size() < 2:
			return false
		var ngo_cnt: int = 0
		var pets_ok: bool = true
		for pid in Net.players:
			var info: Dictionary = Net.players[pid]
			if str(info.get("hero", "")) == "ngo_quyen":
				ngo_cnt += 1
			if int(pid) != 1 and str(info.get("pet", "")) != "cat":
				pets_ok = false
		return ngo_cnt >= 2 and pets_ok and Net.all_peers_confirmed(), 12.0)
	_check(dup_ok, "LAN phải cho phép chọn trùng tướng ngo_quyen + đồng bộ pet + all_peers_confirmed() (players=%s)" % str(Net.players))

	Net.leave_room()
	_kill_client()
	await _frames(2)


func _run_lan_client() -> void:
	Global.save_path = CLIENT_SAVE
	Global.unlocked = ["hai_ba_trung"]
	Global.selected_hero = "hai_ba_trung"
	Global.save_game()
	Net.entered_lan_lobby.connect(func(): _client_entered_lobby = true)
	var err: int = Net.join_room("127.0.0.1", "KhachV21", TEST_PORT)
	if err != OK:
		get_tree().quit(1)
		return
	var ok_in: bool = await _wait_until(func() -> bool:
		return Net.is_online() and Net.in_lobby and _client_entered_lobby, 12.0)
	if not ok_in:
		get_tree().quit(1)
		return
	Net.request_set_hero("ngo_quyen")
	Net.request_set_pet("cat")
	Net.request_set_ready(true)
	await _wait_until(func() -> bool: return not Net.is_online(), 10.0)
	get_tree().quit(0)


func _test_horde_waves() -> void:
	print("== 5. Kiểm tra nhịp độ Horde (MAX_ENEMIES==28, waves_for_level, >=8 giặc màn 1, vòng báo 0.55s, gọi đợt sớm)")
	_check(RoomScript.MAX_ENEMIES == 28, "Room.MAX_ENEMIES phải == 28 (hiện %d)" % RoomScript.MAX_ENEMIES)
	_check(is_equal_approx(RoomScript.SPAWN_TELEGRAPH_DUR, 0.55), "SPAWN_TELEGRAPH_DUR phải == 0.55")
	_check(RoomScript.waves_for_level(1) >= 2, "waves_for_level(1) phải >= 2 (hiện %d)" % RoomScript.waves_for_level(1))
	_check(RoomScript.waves_for_level(3) >= 3 and RoomScript.waves_for_level(10) >= 4, "waves_for_level(3/10) sai")

	Global.badass_mode = false
	Global.active_mutators = []
	var d := DungeonScript.new()
	add_child(d)
	seed(21021)
	d.generate(1)
	await _frames(2)

	var combat_room = null
	for r in d.rooms.values():
		if r.kind == "combat":
			combat_room = r
			break
	_check(combat_room != null, "Màn 1 phải có phòng combat")
	if combat_room != null:
		combat_room._enter()
		_check(combat_room._spawn_queue.size() >= 8, "Màn 1 đợt 1 phải có >= 8 giặc trong hàng chờ báo hiệu (hiện %d)" % combat_room._spawn_queue.size())
		# Chờ hết 0.55s vòng báo hiệu để giặc xuất hiện thật
		for _i in 45:
			await _phys_frames(1)
			combat_room._process(0.016)
		var spawned_cnt: int = combat_room._active_non_boss_count()
		_check(spawned_cnt >= 8, "Sau 0.55s báo hiệu phải sinh >= 8 giặc (hiện %d)" % spawned_cnt)

		# Hạ bớt để còn <= 2 giặc -> kích hoạt gọi đợt 2 sớm!
		var waves_before: int = combat_room._waves_left
		var kept: int = 0
		for e in combat_room._enemies:
			if is_instance_valid(e) and not e.dead:
				if kept < 2:
					kept += 1
				else:
					e.dead = true
					e.queue_free()
		await _frames(1)
		for _i in 35:
			combat_room._process(0.02)
		_check(combat_room._waves_left == waves_before - 1 and not combat_room._spawn_queue.is_empty(),
			"Khi còn <= 2 giặc phải tự động gọi sớm đợt 2 với vòng báo hiệu")

	d.queue_free()
	await _frames(2)
