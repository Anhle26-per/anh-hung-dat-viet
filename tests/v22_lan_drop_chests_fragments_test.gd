extends Node
## Kiểm thử tổng hợp v2.2.0:
##   (a) LAN drop_current_weapon() + full-slot _swap_or_pickup() authoritative pickup/swap sync,
##       chống nhặt trùng và chặn vứt khi chỉ còn 1 vũ khí.
##   (b) WeaponData.roll_chest_weapon() phân phối Tier 3-5, boss_motif nổ hũ, không rò basic/blueprint/merged,
##       cùng LootChest rơi vũ khí & blueprint_frag.
##   (c) Cổng bản vẽ chặt chẽ (discover không tự mở), ngưỡng mảnh Tier 1-5 (1, 1, 2, 3, 4, 5),
##       assemble_blueprint(), try_craft(), lưu/nạp bền vững và nút "Ghép Bản Vẽ" trên LobbyUI.
## Chạy: godot --headless --path . res://tests/v22_lan_drop_chests_fragments_test.tscn -> in "V22 LAN DROP CHESTS FRAGMENTS TEST OK"

const WeaponData = preload("res://scripts/data/weapons.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const LootChest = preload("res://scripts/entities/loot_chest.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const GameScene = preload("res://scenes/game.tscn")
const LobbyScene = preload("res://scenes/lobby.tscn")

const TEST_PORT: int = 17782
const HOST_SAVE: String = "user://v22_test_host_save.json"
const HOST_RUN_SAVE: String = "user://v22_test_host_run.json"
const CLIENT_SAVE: String = "user://v22_test_client_save.json"
const CLIENT_RUN_SAVE: String = "user://v22_test_client_run.json"
const CLIENT_RESULT: String = "user://v22_test_client_result.json"

var _is_client: bool = false
var _failed: bool = false
var _client_pid: int = -1
var _client_ready_game: bool = false
var _client_events: Dictionary = {}
var _client_game: Node = null
var _client_done: bool = false
var _client_ok: bool = true


func _ready() -> void:
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	_is_client = uargs.has("--lan-client")
	get_tree().create_timer(90.0).timeout.connect(func() -> void:
		_fail("Hết giờ kiểm thử v2.2.0 (90s) [role=%s]" % ("client" if _is_client else "host")))
	if _is_client:
		_run_client.call_deferred()
	else:
		_run_host.call_deferred()


func _fail(msg: String) -> void:
	if _failed:
		return
	_failed = true
	printerr("V22 TEST FAILED: ", msg)
	Net.leave_room()
	if not _is_client:
		_kill_client()
		_cleanup_files()
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> bool:
	if not cond:
		_fail(msg)
		return false
	return true


func _kill_client() -> void:
	if _client_pid > 0 and OS.is_process_running(_client_pid):
		OS.kill(_client_pid)
	_client_pid = -1


func _cleanup_files() -> void:
	for p in [HOST_SAVE, HOST_SAVE + ".tmp", HOST_RUN_SAVE, HOST_RUN_SAVE + ".tmp",
			CLIENT_SAVE, CLIENT_SAVE + ".tmp", CLIENT_RUN_SAVE, CLIENT_RUN_SAVE + ".tmp", CLIENT_RESULT]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if _failed:
			return false
		if bool(pred.call()):
			return true
		await get_tree().process_frame
	return bool(pred.call())


func _find_weapon_pickup(root: Node, wid: String, min_pid: int = 1) -> Node:
	if root == null:
		return null
	for pk in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pk) and str(pk.get("kind")) == "weapon" and str(pk.get("weapon_id")) == wid:
			if int(pk.get("pickup_id")) >= min_pid:
				return pk
	return null


func _count_weapon_pickups_with_pid(pid: int) -> int:
	var cnt: int = 0
	for pk in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pk) and str(pk.get("kind")) == "weapon" and int(pk.get("pickup_id")) == pid:
			cnt += 1
	return cnt


func _collect_buttons(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	if root is Button:
		out.append(root)
	for ch in root.get_children():
		out.append_array(_collect_buttons(ch))
	return out


func _reset_offline_global() -> void:
	Global.coins = 0
	Global.run_coins = 0
	Global.best_level = 0
	Global.unlocked = ["hai_ba_trung", "ngo_quyen", "ba_trieu"]
	Global.selected_hero = "hai_ba_trung"
	Global.upgrades = {}
	Global.discovered = []
	Global.materials = {}
	Global.run_materials = {}
	Global.forged = ""
	Global.hero_levels = {}
	Global.weapon_ranks = {}
	Global.achievements_claimed = []
	Global.blueprints = []
	Global.blueprint_fragments = {}
	Global.stats = Global.DEFAULT_STATS.duplicate()
	Global.run_buffs = {}
	Global.resume_data = {}
	Global.selected_pet = ""
	Global.badass_mode = false


# ================================================================== HOST FLOW

func _run_host() -> void:
	_cleanup_files()
	Global.save_path = HOST_SAVE
	Global.run_save_path = HOST_RUN_SAVE
	_reset_offline_global()
	Global.coins = 500
	Global.save_game()

	print("== (a) Kiểm thử LAN 2 tiến trình: vứt vũ khí [G], nhặt/đổi 2 ô authoritative, chống nhặt trùng")
	Net.world_event_received.connect(_on_host_world_event)
	var err: int = Net.create_room("V22TestRoom", "ChuPhong", TEST_PORT)
	if not _assert(err == OK, "Host create_room thất bại: %d" % err):
		return

	var exe: String = OS.get_executable_path()
	var proj: String = ProjectSettings.globalize_path("res://")
	_client_pid = OS.create_process(exe, PackedStringArray([
		"--headless", "--path", proj, "res://tests/v22_lan_drop_chests_fragments_test.tscn", "--", "--lan-client"
	]))
	if not _assert(_client_pid > 0, "Không khởi tạo được tiến trình máy khách"):
		return

	var joined: bool = await _wait_until(func() -> bool:
		if Net.players.size() < 2:
			return false
		for pid in Net.players:
			if int(pid) != 1 and bool(Net.players[pid].get("ready", false)):
				return true
		return false, 15.0)
	if not _assert(joined, "Máy khách không sẵn sàng trong 15s"):
		return

	Net.host_start_match()
	var game: Node = GameScene.instantiate()
	add_child(game)
	await _frames(6)
	if not _assert(game.player != null and game.net_sync != null, "Game Host thiếu player hoặc net_sync"):
		return

	var client_game_ok: bool = await _wait_until(func() -> bool:
		return _client_ready_game, 15.0)
	if not _assert(client_game_ok, "Máy khách không vào GameScene kịp"):
		return

	# 1. Single-weapon drop guard
	var hp = game.player
	hp.weapons = ["kiem_dong", ""]
	hp.slot = 0
	hp._refresh_weapon_sprite()
	if not _assert(hp.held_weapon_count() == 1, "Host ban đầu phải cầm 1 vũ khí"):
		return
	if not _assert(not hp.can_drop_current_weapon() and not hp.drop_current_weapon(), "Không được phép vứt khi chỉ cầm 1 vũ khí"):
		return

	# 2. Host picks up 2nd weapon 'kiem' and drops it -> shared pickup synced to Client
	hp.pick_weapon("kiem")
	hp.slot = 1
	hp._refresh_weapon_sprite()
	if not _assert(hp.held_weapon_count() == 2 and hp.can_drop_current_weapon(), "Host cầm 2 vũ khí phải cho phép vứt"):
		return
	if not _assert(hp.drop_current_weapon(), "Host drop_current_weapon() thất bại"):
		return
	if not _assert(hp.held_weapon_count() == 1 and str(hp.weapons[0]) == "kiem_dong", "Sau khi vứt 'kiem', Host phải còn 'kiem_dong'"):
		return
	var pk_kiem: Node = _find_weapon_pickup(game.dungeon, "kiem", 1)
	if not _assert(pk_kiem != null and int(pk_kiem.get("pickup_id")) > 0, "Host phải tạo Pickup 'kiem' có pickup_id > 0"):
		return
	var kiem_pid: int = int(pk_kiem.get("pickup_id"))
	Net.send_world_event("test_check_pickup", {"step": "host_drop_kiem", "pid": kiem_pid, "wid": "kiem"}, false)
	var c1_ok: bool = await _wait_until(func() -> bool:
		return _client_events.has("host_drop_kiem"), 10.0)
	if not _assert(c1_ok and bool(_client_events["host_drop_kiem"].get("ok", false)),
			"Client không nhận đúng Pickup 'kiem' từ Host: %s" % str(_client_events.get("host_drop_kiem", {}))):
		return

	# 3. Client drops 'ma_tau' -> Host performs full-slot _swap_or_pickup() -> swaps 'gay_tre' onto floor
	Net.send_world_event("test_client_drop", {"wid": "ma_tau"}, false)
	var c_drop_ok: bool = await _wait_until(func() -> bool:
		return _client_events.has("client_drop_matau"), 10.0)
	if not _assert(c_drop_ok and bool(_client_events["client_drop_matau"].get("ok", false)),
			"Client drop_current_weapon thất bại: %s" % str(_client_events.get("client_drop_matau", {}))):
		return
	var got_matau: bool = await _wait_until(func() -> bool:
		return _find_weapon_pickup(game.dungeon, "ma_tau", 1) != null, 10.0)
	var pk_matau: Node = _find_weapon_pickup(game.dungeon, "ma_tau", 1)
	if not _assert(got_matau and pk_matau != null, "Host không nhận drop_weapon_req 'ma_tau' từ Client"):
		return
	var matau_pid: int = int(pk_matau.get("pickup_id"))
	hp.weapons = ["kiem_dong", "gay_tre"]
	hp.slot = 1
	hp._refresh_weapon_sprite()
	hp.global_position = (pk_matau as Node2D).global_position
	hp.nearby_pickup = pk_matau
	hp._swap_or_pickup()
	await _frames(3)
	if not _assert(str(hp.weapons[0]) == "kiem_dong" and str(hp.weapons[1]) == "ma_tau",
			"Full-slot _swap_or_pickup() trên Host phải đổi sang ma_tau: %s" % str(hp.weapons)):
		return
	if not _assert(game.net_sync.claimed_pickups.has(matau_pid), "Pickup ma_tau phải được đánh dấu đã claimed"):
		return
	var pk_gaytre: Node = _find_weapon_pickup(game.dungeon, "gay_tre", 1)
	if not _assert(pk_gaytre != null, "Full-slot swap phải thả vũ khí cũ 'gay_tre' xuống sàn"):
		return
	var gaytre_pid: int = int(pk_gaytre.get("pickup_id"))
	Net.send_world_event("test_check_swap", {"old_pid": matau_pid, "new_pid": gaytre_pid, "new_wid": "gay_tre"}, false)
	var c2_ok: bool = await _wait_until(func() -> bool:
		return _client_events.has("swap_sync"), 10.0)
	if not _assert(c2_ok and bool(_client_events["swap_sync"].get("ok", false)),
			"Client đồng bộ full-slot swap sai: %s" % str(_client_events.get("swap_sync", {}))):
		return

	# 4. Zero duplicate pickups: Host spawns 'dao', Client picks it up, duplicate claim is ignored
	var pk_dao: Node = game.host_spawn_shared_weapon("dao", hp.global_position + Vector2(60, 0))
	if not _assert(pk_dao != null, "host_spawn_shared_weapon('dao') thất bại"):
		return
	var dao_pid: int = int(pk_dao.get("pickup_id"))
	Net.send_world_event("test_client_pickup_dao", {"pid": dao_pid, "wid": "dao"}, false)
	var c3_ok: bool = await _wait_until(func() -> bool:
		return _client_events.has("client_picked_dao"), 10.0)
	if not _assert(c3_ok and bool(_client_events["client_picked_dao"].get("ok", false)),
			"Client nhặt 'dao' thất bại: %s" % str(_client_events.get("client_picked_dao", {}))):
		return
	if not _assert(game.net_sync.claimed_pickups.has(dao_pid) and _count_weapon_pickups_with_pid(dao_pid) == 0,
			"Pickup 'dao' phải biến mất và nằm trong claimed_pickups sau khi Client nhặt"):
		return
	# Simulate second peer attempting to claim same pickup_id
	var slots_before: Array = hp.weapons.duplicate()
	game.host_handle_weapon_pickup_req(1, {"pickup_id": dao_pid, "drop_wid": "", "x": 0.0, "y": 0.0})
	if not _assert(hp.weapons == slots_before, "Chống nhặt trùng thất bại: Host vẫn nhận vũ khí từ pickup_id đã claimed!"):
		return

	Net.send_world_event("test_done", {}, false)
	var c4_ok: bool = await _wait_until(func() -> bool:
		return FileAccess.file_exists(CLIENT_RESULT), 10.0)
	if not _assert(c4_ok, "Không nhận được file kết quả của Client"):
		return
	await get_tree().create_timer(0.15).timeout
	var cres: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLIENT_RESULT))
	if not _assert(typeof(cres) == TYPE_DICTIONARY and bool((cres as Dictionary).get("ok", false)),
			"Báo cáo Client thất bại: %s" % str(cres)):
		return

	game.queue_free()
	await _frames(3)
	Net.leave_room()
	_kill_client()
	print("[PASS] (a) LAN vứt [G], đổi vũ khí đầy ô & chống nhặt trùng hoạt động chính xác")

	# ================================================================== (b) CHEST DISTRIBUTION & LOOTCHEST
	print("== (b) Kiểm thử WeaponData.roll_chest_weapon() & LootChest")
	seed(2026220)
	var n_rolls: int = 2000
	var norm_t35: int = 0
	var norm_boss: int = 0
	for _i in n_rolls:
		var wid: String = WeaponData.roll_chest_weapon(5, false, false)
		var wd: Dictionary = WeaponData.DATA.get(wid, {})
		if not _assert(not wd.is_empty(), "roll_chest_weapon(normal) trả mã rỗng/không tồn tại: %s" % wid):
			return
		if not _assert(not bool(wd.get("basic", false)) and not bool(wd.get("blueprint", false)) and not bool(wd.get("merged", false)),
				"roll_chest_weapon(normal) rò vũ khí cấm: %s" % wid):
			return
		if int(wd.get("tier", 1)) >= 3:
			norm_t35 += 1
		if bool(wd.get("boss_motif", false)):
			norm_boss += 1
	var norm_t35_pct: float = float(norm_t35) / float(n_rolls)
	print("   Rương thường (2000 lần): Tier3-5=%.1f%%, boss_motif=%d" % [norm_t35_pct * 100.0, norm_boss])
	if not _assert(norm_t35_pct > 0.45, "Rương thường Tier 3-5 phải > 45%% (hiện %.1f%%)" % (norm_t35_pct * 100.0)):
		return
	if not _assert(norm_boss > 0, "Rương thường phải có cơ hội nổ hũ boss_motif"):
		return

	var tr_t35: int = 0
	var tr_t5: int = 0
	var tr_boss: int = 0
	for _j in n_rolls:
		var wid_t: String = WeaponData.roll_chest_weapon(5, true, false)
		var wd_t: Dictionary = WeaponData.DATA.get(wid_t, {})
		if not _assert(not wd_t.is_empty(), "roll_chest_weapon(treasure) trả mã rỗng/không tồn tại: %s" % wid_t):
			return
		if not _assert(not bool(wd_t.get("basic", false)) and not bool(wd_t.get("blueprint", false)) and not bool(wd_t.get("merged", false)),
				"roll_chest_weapon(treasure) rò vũ khí cấm: %s" % wid_t):
			return
		var tier_t: int = int(wd_t.get("tier", 1))
		if tier_t >= 3:
			tr_t35 += 1
		if tier_t >= 5:
			tr_t5 += 1
		if bool(wd_t.get("boss_motif", false)):
			tr_boss += 1
	var tr_t35_pct: float = float(tr_t35) / float(n_rolls)
	var tr_t5_pct: float = float(tr_t5) / float(n_rolls)
	print("   Rương báu (2000 lần): Tier3-5=%.1f%%, Tier5=%.1f%%, boss_motif=%d" % [tr_t35_pct * 100.0, tr_t5_pct * 100.0, tr_boss])
	if not _assert(tr_t35_pct > 0.75, "Rương báu Tier 3-5 phải > 75%% (hiện %.1f%%)" % (tr_t35_pct * 100.0)):
		return
	if not _assert(tr_t5_pct > 0.10, "Rương báu Tier 5 phải > 10%% (hiện %.1f%%)" % (tr_t5_pct * 100.0)):
		return
	if not _assert(tr_boss > 0, "Rương báu phải có nổ hũ boss_motif"):
		return

	# LootChest spawning weapon + blueprint_frag pickups
	Global.save_path = HOST_SAVE
	Global.run_save_path = HOST_RUN_SAVE
	_reset_offline_global()
	Global.level = 5
	var chest_arena := Node2D.new()
	add_child(chest_arena)
	var seen_chest_weapon: bool = false
	var seen_chest_bp: bool = false
	for k in 25:
		var ch := LootChest.new()
		ch.level = 5
		ch.chest_id = "test_chest_%d" % k
		ch.position = Vector2(100 + k * 10, 100)
		chest_arena.add_child(ch)
		ch.interact()
		for node in chest_arena.get_children():
			if node is Pickup:
				var pk_c := node as Pickup
				if pk_c.kind == "weapon" and WeaponData.DATA.has(pk_c.weapon_id):
					seen_chest_weapon = true
				elif pk_c.kind == "blueprint_frag" and WeaponData.DATA.has(pk_c.blueprint_id):
					seen_chest_bp = true
				chest_arena.remove_child(pk_c)
				pk_c.free()
		if seen_chest_weapon and seen_chest_bp:
			break
	chest_arena.queue_free()
	await _frames(2)
	if not _assert(seen_chest_weapon, "LootChest không rơi Pickup vũ khí trong 25 lần mở"):
		return
	if not _assert(seen_chest_bp, "LootChest không rơi Pickup mảnh bản vẽ (blueprint_frag) trong 25 lần mở"):
		return
	print("[PASS] (b) Phân phối Rương T3-5 / boss_motif & LootChest rơi vũ khí + mảnh bản vẽ chuẩn")

	# ================================================================== (c) STRICT BLUEPRINT GATE & FRAGMENT ASSEMBLY + LOBBY UI
	print("== (c) Kiểm thử cổng bản vẽ chặt, ngưỡng mảnh T1-5, ghép, rèn, lưu/nạp & LobbyUI")
	_reset_offline_global()
	Global.coins = 9999
	for mid in MaterialData.ORDER:
		Global.materials[str(mid)] = 99
	Global.save_game()

	# Strict gate
	Global.discover("dao")
	if not _assert(not Global.owns_blueprint("dao") and not Global.can_craft("dao") and not Global.try_craft("dao"),
			"discover('dao') không được tự mở bản vẽ hay cho phép rèn"):
		return

	# Tier 1-5 fragment thresholds (0 basic, 1, 1, 2, 3, 4, 5 boss_motif/merged)
	if not _assert(MaterialData.fragments_needed("kiem_dong") == 0, "Vũ khí cơ bản phải cần 0 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("gay_tre") == 1, "Cấp 1 phải cần 1 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("kiem") == 1, "Cấp 2 phải cần 1 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("dao") == 2, "Cấp 3 phải cần 2 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("kinh_van_hoa") == 3, "Cấp 4 phải cần 3 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("banh_xe_phong_hoa") == 4, "Cấp 5 thường phải cần 4 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("huyet_dao_to_dinh") == 5, "Cấp 5 boss_motif phải cần 5 mảnh"):
		return
	if not _assert(MaterialData.fragments_needed("thai_cuc_kiem") == 5, "Cấp 5 merged phải cần 5 mảnh"):
		return

	# Add fragments for T1/T2 (auto-unlock) and T5 boss_motif (5 fragments)
	var r_t1: Dictionary = Global.add_blueprint_fragment("gay_tre", 1)
	if not _assert(bool(r_t1.get("unlocked_now", false)) and Global.owns_blueprint("gay_tre"), "1 mảnh T1 phải mở ngay bản vẽ"):
		return
	Global.start_run()
	Global.run_coins = 0
	var r_dup: Dictionary = Global.add_blueprint_fragment("gay_tre", 1)
	if not _assert(bool(r_dup.get("already_owned", false)) and Global.run_coins == 12, "Nhặt trùng bản vẽ đã sở hữu phải cộng +12 xu lượt"):
		return

	for step_i in range(1, 5):
		var r_b: Dictionary = Global.add_blueprint_fragment("huyet_dao_to_dinh", 1)
		if not _assert(Global.fragment_count("huyet_dao_to_dinh") == step_i and not bool(r_b.get("ready_to_assemble", false)),
				"Huyết Đao ở mảnh %d/5 chưa được sẵn sàng ghép" % step_i):
			return
		if not _assert(not Global.assemble_blueprint("huyet_dao_to_dinh"), "Chưa đủ 5 mảnh không được ghép"):
			return
	var r_b5: Dictionary = Global.add_blueprint_fragment("huyet_dao_to_dinh", 1)
	if not _assert(bool(r_b5.get("ready_to_assemble", false)) and Global.can_assemble_blueprint("huyet_dao_to_dinh"),
			"Đủ 5/5 mảnh phải cho phép ghép Huyết Đao"):
		return

	# Persistence before assemble
	Global.add_blueprint_fragment("dao", 2)
	Global.blueprint_fragments = {}
	Global.load_game()
	if not _assert(Global.fragment_count("huyet_dao_to_dinh") == 5 and Global.fragment_count("dao") == 2,
			"save/load làm mất blueprint_fragments"):
		return

	# Assemble & craft
	var asm_before: int = int(Global.stats.get("blueprints_assembled", 0))
	if not _assert(Global.assemble_blueprint("huyet_dao_to_dinh"), "assemble_blueprint('huyet_dao_to_dinh') thất bại"):
		return
	if not _assert(Global.owns_blueprint("huyet_dao_to_dinh") and Global.fragment_count("huyet_dao_to_dinh") == 0 \
			and int(Global.stats.get("blueprints_assembled", 0)) == asm_before + 1,
			"assemble_blueprint phải mở khóa, xóa mảnh và tăng blueprints_assembled"):
		return
	if not _assert(Global.try_craft("huyet_dao_to_dinh") and Global.forged == "huyet_dao_to_dinh",
			"Sau khi ghép bản vẽ phải rèn được Huyết Đao"):
		return
	Global.forged = ""
	Global.save_game()

	# LobbyUI "Ghép Bản Vẽ" interaction for 'dao' (currently 2/2 fragments)
	var lobby: Node = LobbyScene.instantiate()
	add_child(lobby)
	await _frames(4)
	lobby.ui.open_blueprints("fragments")
	await _frames(2)
	if not _assert(lobby.ui.is_open(), "LobbyUI.open_blueprints('fragments') không mở"):
		return
	var asm_btn: Button = null
	for b in _collect_buttons(lobby.ui._panel):
		if str((b as Button).text) == "Ghép Bản Vẽ" and not (b as Button).disabled:
			asm_btn = b as Button
			break
	if not _assert(asm_btn != null, "Thiếu nút 'Ghép Bản Vẽ' cho 'dao' trên Bàn Bản Vẽ"):
		return
	asm_btn.pressed.emit()
	await _frames(2)
	if not _assert(Global.owns_blueprint("dao") and Global.fragment_count("dao") == 0,
			"Bấm nút 'Ghép Bản Vẽ' trên LobbyUI không ghép được 'dao'"):
		return
	lobby.ui.close()
	lobby.queue_free()
	await _frames(2)

	# Verify save/load keeps assembled 'dao' & 'huyet_dao_to_dinh'
	Global.blueprints = []
	Global.load_game()
	if not _assert(Global.owns_blueprint("dao") and Global.owns_blueprint("huyet_dao_to_dinh"),
			"save/load sau khi ghép qua LobbyUI làm mất bản vẽ"):
		return

	_cleanup_files()
	print("[PASS] (c) Cổng bản vẽ, ngưỡng mảnh T1-5, lưu/nạp & LobbyUI 'Ghép Bản Vẽ' chính xác")
	print("V22 LAN DROP CHESTS FRAGMENTS TEST OK")
	get_tree().quit(0)


func _on_host_world_event(kind: String, data: Dictionary) -> void:
	match kind:
		"test_client_game_ready":
			_client_ready_game = true
		"test_client_report":
			var tag: String = str(data.get("tag", ""))
			if tag != "":
				_client_events[tag] = data.duplicate(true)


# ================================================================== CLIENT FLOW

func _on_client_world_event(kind: String, data: Dictionary) -> void:
	match kind:
		"test_check_pickup":
			var pid: int = int(data.get("pid", 0))
			var wid: String = str(data.get("wid", ""))
			var ok: bool = false
			if _client_game != null and _client_game.net_sync != null:
				var pk: Node = _client_game.net_sync.get_pickup(pid)
				ok = pk != null and str(pk.get("kind")) == "weapon" and str(pk.get("weapon_id")) == wid
			if not ok:
				_client_ok = false
			Net.send_world_event("test_client_report", {"tag": "host_drop_kiem", "ok": ok}, true)
		"test_client_drop":
			var wid_d: String = str(data.get("wid", "ma_tau"))
			var ok_d: bool = false
			var dbg: Dictionary = {}
			if _client_game != null and _client_game.player != null:
				var cp = _client_game.player
				cp.weapons = ["kiem_dong", wid_d]
				cp.slot = 1
				cp._refresh_weapon_sprite()
				dbg["can_drop"] = cp.can_drop_current_weapon()
				dbg["can_pause"] = _client_game.can_pause()
				dbg["is_local"] = cp.is_local
				dbg["net_online"] = Net.is_online()
				dbg["net_host"] = Net.is_host()
				ok_d = cp.drop_current_weapon() and cp.held_weapon_count() == 1
			if not ok_d:
				_client_ok = false
			Net.send_world_event("test_client_report", {"tag": "client_drop_matau", "ok": ok_d, "dbg": dbg}, true)
		"test_check_swap":
			var old_pid: int = int(data.get("old_pid", 0))
			var new_pid: int = int(data.get("new_pid", 0))
			var new_wid: String = str(data.get("new_wid", ""))
			var ok_s: bool = false
			if _client_game != null and _client_game.net_sync != null:
				var old_pk: Node = _client_game.net_sync.get_pickup(old_pid)
				var new_pk: Node = _client_game.net_sync.get_pickup(new_pid)
				ok_s = (old_pk == null) and (new_pk != null) and str(new_pk.get("weapon_id")) == new_wid
			if not ok_s:
				_client_ok = false
			Net.send_world_event("test_client_report", {"tag": "swap_sync", "ok": ok_s}, true)
		"test_client_pickup_dao":
			var pid_dao: int = int(data.get("pid", 0))
			var wid_dao: String = str(data.get("wid", "dao"))
			if _client_game != null and _client_game.net_sync != null and _client_game.player != null:
				var pk_d: Node = _client_game.net_sync.get_pickup(pid_dao)
				if pk_d != null:
					var cp2 = _client_game.player
					cp2.weapons = ["kiem_dong", ""]
					cp2.slot = 0
					cp2.global_position = (pk_d as Node2D).global_position
					cp2.nearby_pickup = pk_d
					cp2._swap_or_pickup()
					var deadline: int = Time.get_ticks_msec() + 3000
					while Time.get_ticks_msec() < deadline:
						if str(cp2.weapons[1]) == wid_dao:
							break
						await get_tree().process_frame
					await _frames(2)
					var ok_p: bool = (str(cp2.weapons[1]) == wid_dao) and (_client_game.net_sync.get_pickup(pid_dao) == null)
					if not ok_p:
						_client_ok = false
					Net.send_world_event("test_client_report", {"tag": "client_picked_dao", "ok": ok_p, "weapons": cp2.weapons}, true)
				else:
					_client_ok = false
					Net.send_world_event("test_client_report", {"tag": "client_picked_dao", "ok": false, "err": "missing_dao_pk"}, true)
		"test_done":
			_client_done = true


func _run_client() -> void:
	Global.save_path = CLIENT_SAVE
	Global.run_save_path = CLIENT_RUN_SAVE
	_reset_offline_global()
	Global.coins = 77
	Global.save_game()

	Net.world_event_received.connect(_on_client_world_event)

	var matched := {"started": false}
	Net.match_started.connect(func(_s: int, _l: int) -> void:
		matched["started"] = true)

	var err: int = Net.join_room("127.0.0.1", "BanBe", TEST_PORT)
	if not _assert(err == OK, "Client join_room thất bại: %d" % err):
		return
	var joined: bool = await _wait_until(func() -> bool:
		return Net.is_online() and Net.players.has(Net.local_peer_id()) and Net.host_profile.has("unlocked"), 12.0)
	if not _assert(joined, "Client không nhận host_profile"):
		return
	Net.request_set_hero("ba_trieu")
	Net.request_set_ready(true)

	var started: bool = await _wait_until(func() -> bool:
		return bool(matched["started"]), 15.0)
	if not _assert(started, "Client không nhận match_started"):
		return

	_client_game = GameScene.instantiate()
	add_child(_client_game)
	await _frames(6)
	if not _assert(_client_game.player != null and _client_game.net_sync != null, "Client GameScene thiếu player/net_sync"):
		return
	Net.send_world_event("test_client_game_ready", {}, true)

	await _wait_until(func() -> bool:
		return _client_done, 30.0)

	var f := FileAccess.open(CLIENT_RESULT, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"ok": _client_ok}))
		f.close()
	_client_game.queue_free()
	await _frames(2)
	Net.leave_room()
	get_tree().quit(0)
