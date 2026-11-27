extends Node
## Kiểm thử tổng hợp v3.0.0 ("Giang Sơn Gấm Vóc") — Toàn bộ 4 Trụ Cột:
##   0) Version 3.0.0 (BUILD 300) & HotpatchSync DATA_SCRIPTS / SCENE_SCRIPTS
##   1) Pillar 1: CoLoaDefense (Core + 8 pads + 5 tháp Lv1..3 + Wave 1 & Wave 5 Boss + best_co_loa_wave),
##      PingMarker (4 loại), MatchSummary MVP, SparringArena non-lethal HP >= 1
##   2) Pillar 2: 14 tướng 896x32 28f, Lobby zero banner-hero overlap, 28 kỹ năng SkillCastFx,
##      14 HeroSkins, 15 Relics, 16 SkillTree nodes (4 nhánh), 12 WeaponMods + 8 Affixes + 8 vũ khí mới
##   3) Pillar 3: Portal.entered_branch, 2 Secret Biomes (thuy_cung, dinh_tan_vien),
##      48f 12x4 bosses thuy_tinh & thien_loi, HaoKhiData 1..10, Boss Phase 3 phase3_enraged <= 25% HP
##   4) Pillar 4: 4 Awakened Pets + evo sprites, 4 Rescue NPCs (than_y_tue_tinh 3->6 garden_plots, linh_chi_vang, hoa_uu_dam),
##      Level 33 True Ending Boss hon_mang_yeu_de (48f 12x4) + thai_to_thien_kiem + 24 Chronicles + 30 Achievements + v2.4.0 save migration
## Chạy: godot --headless --path . res://tests/v30_mega_expansion_test.tscn -> "V30 MEGA EXPANSION TEST OK"

const VersionData = preload("res://scripts/data/version.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")
const CoLoaData = preload("res://scripts/data/co_loa_data.gd")
const CoLoaDefense = preload("res://scripts/game/co_loa_defense.gd")
const PingMarker = preload("res://scripts/effects/ping_marker.gd")
const MatchSummary = preload("res://scripts/ui/match_summary.gd")
const SparringArena = preload("res://scripts/entities/sparring_arena.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const HeroSkins = preload("res://scripts/data/hero_skins.gd")
const RelicData = preload("res://scripts/data/relics.gd")
const SkillTreeData = preload("res://scripts/data/skill_tree.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const WeaponEvolutions = preload("res://scripts/data/weapon_evolutions.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const HaoKhiData = preload("res://scripts/data/hao_khi_data.gd")
const CampNpcs = preload("res://scripts/data/camp_npcs.gd")
const ChronicleData = preload("res://scripts/data/chronicles.gd")
const AchievementData = preload("res://scripts/data/achievements.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")
const PetScript = preload("res://scripts/entities/pet.gd")
const PortalScript = preload("res://scripts/entities/portal.gd")
const RescueNpcScript = preload("res://scripts/entities/rescue_npc.gd")
const DungeonScript = preload("res://scripts/game/dungeon.gd")
const SkillCastFx = preload("res://scripts/effects/skill_fx.gd")
const Art = preload("res://scripts/art/art.gd")

const TEST_SAVE := "user://v30_test_save.json"

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", Global.run_path(), Global.run_path() + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _reset_global() -> void:
	Global.coins = 0
	Global.run_coins = 0
	Global.best_level = 0
	Global.unlocked = ["hai_ba_trung", "ba_trieu", "ngo_quyen"]
	Global.selected_hero = "ngo_quyen"
	Global.upgrades = {}
	Global.discovered = []
	Global.materials = {}
	Global.run_materials = {}
	Global.forged = ""
	Global.hero_levels = {}
	Global.weapon_ranks = {}
	Global.achievements_claimed = []
	Global.unlocked_chronicles = []
	Global.blueprints = []
	Global.blueprint_fragments = {}
	Global.stats = Global.DEFAULT_STATS.duplicate()
	Global.run_buffs = {}
	Global.run_weapon_mods = {}
	Global.run_weapon_affixes = {}
	Global.run_relics = []
	Global.selected_skills = {}
	Global.unlocked_skins = {}
	Global.selected_skins = {}
	Global.skill_tree = {}
	Global.hao_khi_level = 0
	Global.awakened_pets = []
	Global.rescued_npcs = []
	Global.garden_plots = []
	Global.ensure_garden_plots()
	Global.selected_pet = ""
	Global.badass_mode = false
	Global.secret_biome_override = ""
	Global.next_branch_kind = "standard"
	Global.pending_run_mode = "normal"
	Global.run_mode = "normal"
	Global.active_mutators = []
	Global.pending_mutators = []


func _ready() -> void:
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	_wipe()
	get_tree().create_timer(90.0).timeout.connect(func():
		print("V30 MEGA EXPANSION TEST FAILED: quá thời gian")
		_wipe()
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V30 MEGA EXPANSION TEST OK")
		get_tree().quit(0)
	else:
		print("V30 MEGA EXPANSION TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	_reset_global()
	Global.save_game()

	_test_version_and_hotpatch()
	await _test_pillar1_coloa_ping_mvp_sparring()
	await _test_pillar2_heroes_skins_relics_skilltree_weapons()
	await _test_pillar3_branching_biomes_bosses_haokhi_phase3()
	await _test_pillar4_pets_npcs_true_ending_migration()
	_completed = true


func _test_version_and_hotpatch() -> void:
	print("== 0. Kiểm tra Version 3.0.0 (BUILD 300) & HotpatchSync")
	_check(VersionData.VERSION == "3.0.0", "VersionData.VERSION phải là '3.0.0' (hiện '%s')" % VersionData.VERSION)
	_check(VersionData.BUILD == 300, "VersionData.BUILD phải là 300 (hiện %d)" % VersionData.BUILD)
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "HotpatchSync.needs_autoload_sync phải false trên v3.0.0")
	_check(HotpatchSync.DATA_SCRIPTS.size() >= 25, "HotpatchSync.DATA_SCRIPTS thiếu mục")
	_check(HotpatchSync.SCENE_SCRIPTS.size() >= 40, "HotpatchSync.SCENE_SCRIPTS thiếu mục")
	for p_v in HotpatchSync.DATA_SCRIPTS:
		var p: String = str(p_v)
		_check(ResourceLoader.exists(p) and load(p) is Script, "DATA_SCRIPTS không nạp được: " + p)
	for p_v in HotpatchSync.SCENE_SCRIPTS:
		var p: String = str(p_v)
		_check(ResourceLoader.exists(p) and load(p) is Script, "SCENE_SCRIPTS không nạp được: " + p)


func _test_pillar1_coloa_ping_mvp_sparring() -> void:
	print("== 1. Trụ Cột 1: Cổ Loa Defense, PingMarker, MatchSummary MVP & SparringArena")
	_check(CoLoaData.TOWER_ORDER.size() == 5, "CoLoaData.TOWER_ORDER phải có 5 tháp (hiện %d)" % CoLoaData.TOWER_ORDER.size())
	_check(CoLoaData.PAD_POSITIONS.size() == 8, "CoLoaData.PAD_POSITIONS phải có 8 bệ")

	Global.pending_run_mode = "co_loa"
	Global.start_run()
	Global.run_coins = 5000
	var arena := CoLoaDefense.new()
	get_tree().root.add_child(arena)
	await _frames(3)

	_check(arena.core != null and is_instance_valid(arena.core), "CoLoaDefense thiếu core")
	_check(arena.towers.size() == 8, "CoLoaDefense phải tạo 8 bệ tháp (hiện %d)" % arena.towers.size())

	# Xây và nâng cấp đủ 5 loại tháp lên Cấp 3
	for i in CoLoaData.TOWER_ORDER.size():
		var tid: String = str(CoLoaData.TOWER_ORDER[i])
		var tw: Node = arena.towers[i]
		_check(tw.build_tower(tid), "Không xây được tháp %s" % tid)
		_check(tw.upgrade_tower() and tw.upgrade_tower(), "Không nâng được tháp %s lên cấp 3" % tid)
		_check(int(tw.tier) == 3, "Tháp %s phải đạt tier=3 (hiện %d)" % [tid, int(tw.tier)])

	# Chạy Đợt 1
	var started_waves: Array[int] = []
	var cleared_waves: Array[int] = []
	arena.wave_started.connect(func(w: int): started_waves.append(w))
	arena.wave_cleared.connect(func(w: int): cleared_waves.append(w))

	arena.start_next_wave()
	_check(arena.wave == 1 and arena.state == "fighting" and started_waves.has(1), "Wave 1 phải bắt đầu")
	for _i in 6:
		arena._process_fighting(0.8)
	_check(arena._enemies.size() >= 1, "Wave 1 phải sinh quái")
	arena._spawn_queue.clear()
	for e in arena._enemies:
		if is_instance_valid(e):
			e.dead = true
			e.queue_free()
	arena._enemies.clear()
	await _frames(1)
	arena._process_fighting(0.016)
	_check(cleared_waves.has(1) and arena.state == "prep", "Wave 1 phải clear xong và về prep")
	_check(int(Global.stats.get("best_co_loa_wave", 0)) >= 1, "best_co_loa_wave phải >= 1")

	# Chạy Đợt 5 (Siege Boss)
	arena.wave = 4
	arena.state = "prep"
	arena.start_next_wave()
	_check(arena.wave == 5 and started_waves.has(5), "Wave 5 phải bắt đầu")
	arena._process_fighting(0.3)
	var saw_boss: bool = false
	for e in arena._enemies:
		if is_instance_valid(e) and e.has_method("is_boss") and e.is_boss():
			saw_boss = true
			break
	_check(saw_boss, "Đợt 5 Cổ Loa phải triệu hồi Đại Tướng (Siege Boss)")
	arena._spawn_queue.clear()
	for e in arena._enemies:
		if is_instance_valid(e):
			e.dead = true
			e.queue_free()
	arena._enemies.clear()
	await _frames(1)
	arena._process_fighting(0.016)
	_check(cleared_waves.has(5), "Wave 5 phải clear thành công")
	_check(int(Global.stats.get("best_co_loa_wave", 0)) >= 5, "best_co_loa_wave phải >= 5 (hiện %d)" % int(Global.stats.get("best_co_loa_wave", 0)))

	arena.queue_free()
	Global.end_run()
	Global.pending_run_mode = "normal"
	await _frames(2)

	# PingMarker: 4 ping types
	_check(PingMarker.PING_ORDER.size() == 4, "PingMarker.PING_ORDER phải có 4 loại")
	var ping_host := Node2D.new()
	add_child(ping_host)
	for pk in ["focus", "danger", "loot", "combo"]:
		var pm: Node2D = PingMarker.spawn_ping(ping_host, Vector2(40, 40), pk, "Người Chơi")
		_check(pm != null and is_instance_valid(pm) and str(pm.get("kind")) == pk, "spawn_ping('%s') thất bại" % pk)
	_check(PingMarker.cycle_ping_kind("focus") == "danger", "cycle_ping_kind('focus') phải ra 'danger'")
	ping_host.queue_free()

	# MatchSummary MVP
	var peers := {
		1: {"hero": "an_duong_vuong", "name": "Hùng", "damage": 420, "kills": 18, "combos": 2, "revives": 1, "fragments": 3, "mvp_weapon": "no_co_loa"},
		2: {"hero": "lac_long_quan", "name": "Lan", "damage": 980, "kills": 34, "combos": 4, "revives": 2, "fragments": 5, "mvp_weapon": "long_uyen_kiem"},
	}
	var mvp_id: Variant = MatchSummary.compute_mvp_peer(peers)
	_check(int(mvp_id) == 2, "MatchSummary MVP phải là peer 2 (hiện %s)" % str(mvp_id))
	var panel: PanelContainer = MatchSummary.build_panel(peers)
	_check(panel != null and is_instance_valid(panel), "MatchSummary.build_panel trả về null")
	var panel_txt: String = _collect_ui_text(panel)
	_check(panel_txt.contains("★ MVP") and panel_txt.contains("Lan"), "MatchSummary panel thiếu nhãn MVP")
	panel.queue_free()

	# SparringArena non-lethal hit clamps HP >= 1
	var sp_host := Node2D.new()
	add_child(sp_host)
	var sp_arena := SparringArena.new()
	sp_host.add_child(sp_arena)
	var sp_player := PlayerScript.new()
	sp_player.setup("ngo_quyen")
	sp_host.add_child(sp_player)
	await _frames(2)
	sp_arena.apply_non_lethal_hit(sp_player, 999, "Võ Sư Thiên Nam")
	_check(sp_player.hp >= 1 and not sp_player.dead, "SparringArena.apply_non_lethal_hit phải giữ HP >= 1 và không chết (hp=%d)" % sp_player.hp)
	sp_host.queue_free()
	await _frames(2)


func _test_pillar2_heroes_skins_relics_skilltree_weapons() -> void:
	print("== 2. Trụ Cột 2: 14 Tướng, 28 Kỹ năng, Skins, 15 Cổ Vật, 16 Cây Thiên Phú, 12 Bùa + 8 Affixes + 8 Vũ Khí")
	_check(HeroData.ORDER.size() == 14, "HeroData.ORDER phải có đúng 14 tướng (hiện %d)" % HeroData.ORDER.size())
	for req_h in ["an_duong_vuong", "lac_long_quan", "son_tinh"]:
		_check(HeroData.ORDER.has(req_h) and HeroData.DATA.has(req_h), "Thiếu tướng mới: " + req_h)

	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		var tex: Texture2D = load("res://assets/sprites/heroes/%s.png" % hid)
		_check(tex != null and tex.get_width() == 896 and tex.get_height() == 32,
			"Tướng %s phải 896x32 (28f)" % hid)

	# Lobby zero banner overlap với 14 tướng
	Global.unlocked = HeroData.ORDER.duplicate()
	Global.selected_hero = "an_duong_vuong"
	Global.save_game()
	var lobby: Node = load("res://scenes/lobby.tscn").instantiate()
	get_tree().root.add_child(lobby)
	await _frames(5)
	_check(lobby._hero_npcs.size() == 14, "Lobby phải có đủ 14 _hero_npcs (hiện %d)" % lobby._hero_npcs.size())
	if lobby.ui != null and lobby.ui._select_banner != null:
		var b_rect: Rect2 = lobby.ui._select_banner.get_global_rect()
		var xform: Transform2D = lobby.get_viewport().get_canvas_transform()
		for hid_v in HeroData.ORDER:
			var hid: String = str(hid_v)
			var st: Node2D = lobby._hero_npcs.get(hid, null)
			_check(st != null and is_instance_valid(st), "Thiếu bục tướng " + hid)
			if st != null:
				var spos: Vector2 = xform * st.global_position
				var prect := Rect2(spos - Vector2(18.0, 22.0), Vector2(36.0, 44.0))
				_check(not b_rect.intersects(prect), "_select_banner %s đè lên bục tướng %s (%s)" % [str(b_rect), hid, str(prect)])
	lobby.queue_free()
	await _frames(3)

	# 28 kỹ năng trong SkillCastFx
	var checked_skills: int = 0
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		for sk_idx in [1, 2]:
			var sk_info: Dictionary = HeroData.skill_info(hid, sk_idx)
			var sk_id: String = str(sk_info.get("skill", ""))
			_check(SkillCastFx.SKILL_META.has(sk_id), "SkillCastFx.SKILL_META thiếu " + sk_id)
			var arena := Node2D.new()
			add_child(arena)
			Global.selected_skills[hid] = sk_idx
			var p := PlayerScript.new()
			p.setup(hid)
			p.position = Vector2(200, 180)
			p.aim_dir = Vector2.RIGHT
			arena.add_child(p)
			await _frames(1)
			p.skill_timer = 0.0
			p._use_skill()
			var found_fx: bool = false
			for ch in arena.get_children():
				if ch is SkillCastFx and str(ch.skill_id) == sk_id:
					found_fx = true
					break
			_check(found_fx, "%s chiêu %d (%s) không sinh SkillCastFx" % [hid, sk_idx, sk_id])
			checked_skills += 1
			arena.queue_free()
			await _frames(1)
	_check(checked_skills == 28, "Phải kiểm đủ 28 kỹ năng (hiện %d)" % checked_skills)
	Global.selected_skills = {}

	# HeroSkins: mở khóa & áp dụng cho 14 tướng
	Global.coins = 50000
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		var skins: Array = HeroSkins.skins_for(hid)
		_check(skins.size() >= 3, "%s phải có >= 3 skin" % hid)
		var paid_sid: String = str((skins[1] as Dictionary).get("id", ""))
		_check(Global.unlock_and_select_skin(hid, paid_sid), "Không mở khóa được skin %s cho %s" % [paid_sid, hid])
		_check(Global.get_selected_skin(hid) == paid_sid, "get_selected_skin(%s) sai" % hid)
	var sk_host := Node2D.new()
	add_child(sk_host)
	var sk_p := PlayerScript.new()
	sk_p.setup("lac_long_quan")
	sk_host.add_child(sk_p)
	await _frames(1)
	_check(sk_p.skin_id == Global.get_selected_skin("lac_long_quan"), "Player không nạp skin đã chọn")
	sk_host.queue_free()
	await _frames(1)

	# 15 Relics
	_check(RelicData.ORDER.size() == 15, "RelicData.ORDER phải có 15 cổ vật (hiện %d)" % RelicData.ORDER.size())
	Global.run_relics = []
	for rid_v in RelicData.ORDER:
		_check(Global.add_relic(str(rid_v)), "Global.add_relic(%s) thất bại" % str(rid_v))
	_check(Global.run_relics.size() == 15, "Global.run_relics phải đủ 15 cổ vật")
	var agg: Dictionary = RelicData.aggregate_stats(Global.run_relics)
	_check(int(agg.get("hp_add", 0)) > 0 and int(agg.get("boss_dmg_pct", 0)) > 0 and int(agg.get("poison_immune", 0)) == 1,
		"RelicData.aggregate_stats sai: " + str(agg))

	# 16 SkillTree nodes trên 4 nhánh
	_check(SkillTreeData.BRANCH_ORDER.size() == 4, "SkillTreeData phải có 4 nhánh")
	_check(SkillTreeData.NODE_ORDER.size() == 16, "SkillTreeData phải có 16 nút (hiện %d)" % SkillTreeData.NODE_ORDER.size())
	Global.coins = 50000
	for mk in MaterialData.ORDER:
		Global.materials[str(mk)] = 99
	Global.skill_tree = {}
	for nid_v in SkillTreeData.NODE_ORDER:
		var nid: String = str(nid_v)
		_check(Global.upgrade_skill_tree_node(nid), "upgrade_skill_tree_node(%s) thất bại" % nid)
	var st_bonuses: Dictionary = SkillTreeData.compute_bonuses(Global.skill_tree)
	_check(int(st_bonuses.get("dmg_pct", 0)) >= 6 and int(st_bonuses.get("hp_add", 0)) >= 1 and int(st_bonuses.get("energy_add", 0)) >= 25,
		"SkillTreeData.compute_bonuses sai: " + str(st_bonuses))

	# 12 WeaponMods + 8 Affixes + 8 vũ khí mới
	_check(WeaponMods.ORDER.size() == 12, "WeaponMods.ORDER phải có 12 bùa (hiện %d)" % WeaponMods.ORDER.size())
	_check(WeaponMods.AFFIX_ORDER.size() == 8, "WeaponMods.AFFIX_ORDER phải có 8 thuộc tính (hiện %d)" % WeaponMods.AFFIX_ORDER.size())
	var base_w: Dictionary = WeaponData.get_data("no_co_loa")
	for mid_v in WeaponMods.ORDER:
		var modded: Dictionary = WeaponMods.apply(base_w, str(mid_v))
		_check(not modded.is_empty(), "WeaponMods.apply(%s) rỗng" % str(mid_v))
	for aid_v in WeaponMods.AFFIX_ORDER:
		var affixed: Dictionary = WeaponMods.apply_affix(base_w, str(aid_v))
		_check(str(affixed.get("affix", "")) == str(aid_v), "WeaponMods.apply_affix(%s) sai" % str(aid_v))

	var new_weapons := [
		"no_co_loa", "long_uyen_kiem", "bua_tan_vien",
		"dinh_ba_thuy_tinh_than", "loi_chuy_thien_de", "thai_to_thien_kiem",
		"long_than_hai_kich", "thien_loi_than_cung",
	]
	for wid in new_weapons:
		_check(WeaponData.DATA.has(wid), "Thiếu vũ khí mới: " + wid)
		_check(Art.tex("weapons/%s.png" % wid) != null, "Thiếu sprite vũ khí mới: " + wid)
		_check(WeaponData.grip(wid).x >= 0.0, "Thiếu grip cho vũ khí mới: " + wid)


func _test_pillar3_branching_biomes_bosses_haokhi_phase3() -> void:
	print("== 3. Trụ Cột 3: Portal branching, 2 Bí Cảnh, 48f Trùm Bí Cảnh, Hào Khí 1..10 & Boss Phase 3")
	# Portal branching signal
	var p_host := Node2D.new()
	add_child(p_host)
	var portal := PortalScript.new()
	portal.branch_kind = "secret_thuy_cung"
	p_host.add_child(portal)
	var got_branch: Array[String] = []
	portal.entered_branch.connect(func(bk: String): got_branch.append(bk))
	portal._emit_enter()
	_check(got_branch.size() == 1 and got_branch[0] == "secret_thuy_cung", "Portal.entered_branch phải phát đúng branch_kind")
	p_host.queue_free()

	# 2 Secret Biomes & 48f 12x4 bosses thuy_tinh & thien_loi
	_check(EnemyData.SECRET_CHAPTERS.has("thuy_cung") and EnemyData.SECRET_CHAPTERS.has("dinh_tan_vien"),
		"EnemyData.SECRET_CHAPTERS thiếu thuy_cung hoặc dinh_tan_vien")
	for sb_pair in [["thuy_cung", "thuy_tinh"], ["dinh_tan_vien", "thien_loi"]]:
		var sb_id: String = str(sb_pair[0])
		var boss_id: String = str(sb_pair[1])
		Global.secret_biome_override = sb_id
		var ch: Dictionary = EnemyData.chapter(10)
		_check(str(ch.get("id", "")) == sb_id and str(EnemyData.boss_id(10)) == boss_id,
			"Secret biome %s không ánh xạ đúng boss %s" % [sb_id, boss_id])
		var d := DungeonScript.new()
		add_child(d)
		d.generate(10)
		_check(d.rooms.size() == 3, "Bí cảnh %s phải có 3 phòng (hiện %d)" % [sb_id, d.rooms.size()])
		d.queue_free()
		for suf in ["", "_2"]:
			var bpath := "res://assets/sprites/enemies/boss_%s%s.png" % [boss_id, suf]
			var btex: Texture2D = load(bpath)
			_check(btex != null and btex.get_width() == 84 * 12 and btex.get_height() == 64 * 4,
				"Trùm bí cảnh %s phải 48f 12x4 (%dx%d)" % [bpath, 84 * 12, 64 * 4])
		var b_ent := EnemyScript.new()
		b_ent.setup("boss", 10, null)
		add_child(b_ent)
		await _frames(1)
		_check(b_ent.is_boss() and str(b_ent.data.get("id", "")) == boss_id, "Enemy.setup boss bí cảnh sai: %s" % boss_id)
		_check(b_ent.spr.sprite_frames.has_animation("special") and b_ent.spr.sprite_frames.get_frame_count("idle") == 6,
			"Trùm %s thiếu animation 48f" % boss_id)
		b_ent.queue_free()
	Global.secret_biome_override = ""
	await _frames(2)

	# HaoKhiData levels 1..10
	_check(HaoKhiData.MAX_LEVEL == 10, "HaoKhiData.MAX_LEVEL phải == 10")
	var prev_hp: float = 1.0
	for lv in range(1, 11):
		var info: Dictionary = HaoKhiData.level_info(lv)
		_check(int(info.get("level", 0)) == lv, "HaoKhi level %d sai" % lv)
		_check(float(info.get("hp_mult", 0.0)) > prev_hp, "HaoKhi %d hp_mult không tăng dần" % lv)
		prev_hp = float(info.get("hp_mult", 1.0))
		if lv >= 4:
			_check(bool(info.get("phase3_enabled", false)), "HaoKhi >= 4 phải bật phase3_enabled")

	# Boss Phase 3 trigger at <= 25% HP
	Global.run_relics = []
	Global.skill_tree = {}
	Global.set_hao_khi_level(4)
	Global.boss_order = ["to_dinh"]
	var p3_host := Node2D.new()
	add_child(p3_host)
	var p3_player := PlayerScript.new()
	p3_player.setup("ngo_quyen")
	p3_player.position = Vector2(100, 0)
	p3_host.add_child(p3_player)
	var b3 := EnemyScript.new()
	b3.setup("boss", 5, p3_player)
	p3_host.add_child(b3)
	await _frames(1)
	b3._spawn_t = 0.0
	_check(not b3.phase3_enraged, "Boss mới sinh không được bật sẵn phase3_enraged")
	b3.transformed = true
	b3._morph_t = 0.0
	b3.hp = maxi(1, int(floor(float(b3.max_hp) * 0.20)))
	b3._physics_process(0.016)
	_check(b3.phase3_enraged, "Boss ở Hào Khí 4 khi <= 25%% HP phải kích hoạt phase3_enraged (hp=%d/%d)" % [b3.hp, b3.max_hp])
	p3_host.queue_free()
	Global.set_hao_khi_level(0)
	await _frames(2)


func _test_pillar4_pets_npcs_true_ending_migration() -> void:
	print("== 4. Trụ Cột 4: 4 Thần Thú Thức Tỉnh, 4 NPC Giải Cứu, Vườn 6 luống, Hỗn Mang Yêu Đế (Màn 33), 24 Hồn Sử, 30 Thành Tựu & Migration v2.4.0")
	# 4 Awakened Pets
	Global.coins = 5000
	for mk in MaterialData.ORDER:
		Global.materials[str(mk)] = 50
	Global.awakened_pets = []
	for pid in ["dog", "cat", "rooster", "crane"]:
		var evo: Dictionary = CampNpcs.get_awakened_pet(pid)
		_check(not evo.is_empty(), "CampNpcs thiếu awakened pet: " + pid)
		var evo_spr: String = str(evo.get("sprite", ""))
		_check(Art.tex(evo_spr) != null, "Thiếu sprite thú thức tỉnh: " + evo_spr)
		_check(Global.awaken_pet(pid) and Global.is_pet_awakened(pid), "Global.awaken_pet(%s) thất bại" % pid)
		var pet_node := PetScript.new()
		pet_node.pet_id = pid
		pet_node.in_lobby = false
		add_child(pet_node)
		await _frames(1)
		_check(pet_node.awakened, "Pet %s phải tự nhận trạng thái awakened=true" % pid)
		pet_node.queue_free()
	await _frames(1)

	# 4 Rescue NPCs & garden 3 -> 6 plots + 2 mythic herbs
	_check(CampNpcs.NPC_ORDER.size() == 4, "CampNpcs.NPC_ORDER phải có 4 NPC")
	Global.rescued_npcs = []
	Global.garden_plots = []
	Global.ensure_garden_plots()
	_check(Global.garden_plots.size() == 3, "Trước khi cứu Danh Y Tuệ Tĩnh, garden_plots phải có 3 ô")
	for nid_v in CampNpcs.NPC_ORDER:
		var nid: String = str(nid_v)
		var cage := RescueNpcScript.new()
		cage.setup(nid)
		add_child(cage)
		await _frames(1)
		cage.interact()
		_check(cage.rescued and Global.rescued_npcs.has(nid), "Giải cứu NPC %s thất bại" % nid)
		cage.queue_free()
	_check(Global.garden_plots.size() == 6, "Sau khi cứu than_y_tue_tinh, garden_plots phải mở rộng thành 6 ô (hiện %d)" % Global.garden_plots.size())
	_check(Global.GARDEN_PLANTS.has("linh_chi_vang") and Global.GARDEN_PLANTS.has("hoa_uu_dam"),
		"Global.GARDEN_PLANTS thiếu linh_chi_vang hoặc hoa_uu_dam")

	# Level 33 True Ending Boss hon_mang_yeu_de (48f 12x4) + thai_to_thien_kiem
	_check(EnemyData.is_boss_level(33) and EnemyData.boss_id(33) == "hon_mang_yeu_de",
		"Màn 33 phải là trùm hon_mang_yeu_de")
	for suf in ["", "_2"]:
		var hm_path := "res://assets/sprites/enemies/boss_hon_mang_yeu_de%s.png" % suf
		var hm_tex: Texture2D = load(hm_path)
		_check(hm_tex != null and hm_tex.get_width() == 96 * 12 and hm_tex.get_height() == 72 * 4,
			"Hỗn Mang Yêu Đế %s phải 48f 12x4 (%dx%d)" % [hm_path, 96 * 12, 72 * 4])
	_check(WeaponEvolutions.boss_weapon_for("hon_mang_yeu_de") == "thai_to_thien_kiem",
		"boss_weapon_for('hon_mang_yeu_de') phải là 'thai_to_thien_kiem'")

	var hm_node := EnemyScript.new()
	hm_node.setup("boss", 33, null)
	add_child(hm_node)
	await _frames(1)
	_check(str(hm_node.data.get("id", "")) == "hon_mang_yeu_de", "Enemy màn 33 phải là hon_mang_yeu_de")
	_check(hm_node.spr.sprite_frames.get_frame_count("special") == 2, "hon_mang_yeu_de thiếu animation special 48f")
	hm_node.queue_free()

	# 24 Chronicles & 30 Achievements
	_check(ChronicleData.total_count() == 24, "ChronicleData phải có đúng 24 trang (hiện %d)" % ChronicleData.total_count())
	_check(AchievementData.ORDER.size() == 30, "AchievementData.ORDER phải có đúng 30 mốc (hiện %d)" % AchievementData.ORDER.size())

	# Backwards-compatible v2.4.0 save.json migration
	var f240 := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f240.store_string(JSON.stringify({
		"coins": 1234,
		"best_level": 22,
		"unlocked": ["hai_ba_trung", "ngo_quyen", "thanh_giong"],
		"selected_hero": "thanh_giong",
		"upgrades": {"mau": 2, "giap": 1},
		"discovered": ["kiem_dong", "gay_tre"],
		"blueprints": ["truong_hoa_cau", "sung_tesla"],
		"unlocked_chronicles": ["hoang_thao", "coop_dong_tam"],
		"achievements_claimed": ["kills_100"],
		"selected_pet": "crane",
		"garden_plots": [
			{"plant": "huyet_sam", "stage": 2},
			{"plant": "", "stage": 0},
			{"plant": "tre_nga", "stage": 1},
		],
		"stats": {"runs": 8, "kills": 320, "bosses": 6, "mythic_bosses": 2},
	}))
	f240.close()
	Global.load_game()
	_check(Global.coins == 1234 and Global.best_level == 22 and Global.selected_hero == "thanh_giong",
		"Migration v2.4.0 mất thông tin cơ bản")
	_check(Global.has_blueprint("sung_tesla") and Global.has_chronicle("coop_dong_tam") and Global.selected_pet == "crane",
		"Migration v2.4.0 mất blueprints/chronicles/pet")
	_check(Global.garden_plots.size() == 3 and str(Global.garden_plots[0].get("plant", "")) == "huyet_sam",
		"Migration v2.4.0 sai garden_plots")
	_check(Global.hao_khi_level == 0 and Global.skill_tree.is_empty() and Global.awakened_pets.is_empty() and Global.rescued_npcs.is_empty(),
		"Migration v2.4.0 không khởi tạo mặc định an toàn cho các trường v3.0.0")
	await _frames(1)


func _collect_ui_text(node: Node) -> String:
	var out: PackedStringArray = []
	_walk_text(node, out)
	return "\n".join(out)


func _walk_text(n: Node, out: PackedStringArray) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is RichTextLabel:
		out.append((n as RichTextLabel).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_walk_text(c, out)
