extends Node
## Kiểm thử tổng hợp v2.0.0 ("Linh Hồn Chiến Trận"):
##   1) WeaponEvolutions: 18 công thức hợp nhất, 6 Thần binh Hợp nhất, 13 Thần binh Trùm (ff384c), tiến hóa, phân tách
##   2) HeroSkillsExt: 11 Nội tại, 11 Chiêu 2, 5 Tượng Thần Việt, 8 Phúc lành mới (gồm song_kiem_hop 3 ô)
##   3) Chiến đấu: Dodge Dash, Tụ lực (Charge), Combo 3 đòn cận chiến + xóa đạn, Kiếm khí tầm gần, Thú cưỡi (3 loại)
##   4) EventAltar (6 loại), BattlefieldHazard (7 loại), Dungeon Normal [!] + Boss Rush 1..13 + Badass + 8 Mutators
##   5) Tương thích ngược file lưu v1.2.9 và v1.7.2 + HotpatchSync + Version 2.0.0 (BUILD 200)
## Chạy: godot --headless --path . res://tests/v20_mega_update_test.tscn -> "V20 MEGA UPDATE TEST OK"

const VersionData = preload("res://scripts/data/version.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const WeaponEvolutions = preload("res://scripts/data/weapon_evolutions.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const HeroSkillsExt = preload("res://scripts/data/hero_skills_ext.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const RunModes = preload("res://scripts/data/run_modes.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")
const Player = preload("res://scripts/entities/player.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const EventAltar = preload("res://scripts/entities/event_altar.gd")
const MountPickup = preload("res://scripts/entities/mount_pickup.gd")
const BattlefieldHazard = preload("res://scripts/entities/battlefield_hazard.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
const ChallengeMenu = preload("res://scripts/ui/challenge_menu.gd")
const Art = preload("res://scripts/art/art.gd")

const TEST_SAVE := "user://v20_mega_test_save.json"

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


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func():
		print("V20 MEGA UPDATE TEST FAILED: quá thời gian")
		_wipe()
		get_tree().quit(1))
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V20 MEGA UPDATE TEST OK")
		get_tree().quit(0)
	else:
		print("V20 MEGA UPDATE TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	_wipe()
	_test_version_and_hotpatch()
	_test_weapons_evo_and_decompose()
	_test_heroes_skills_buffs_modes()
	await _test_combat_dash_charge_combo_mount()
	await _test_events_hazards_boss_rush()
	await _test_save_backcompat()
	_completed = true


func _test_version_and_hotpatch() -> void:
	print("== 1. Kiểm tra Version 2.0.0 (BUILD 200) & HotpatchSync")
	_check(VersionData.VERSION == "2.0.0", "VERSION phải là 2.0.0 (hiện %s)" % VersionData.VERSION)
	_check(VersionData.BUILD == 200, "BUILD phải là 200 (hiện %d)" % VersionData.BUILD)
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "HotpatchSync.needs_autoload_sync phải false trên bản gốc v2.0")
	_check(InputMap.has_action("dash") and InputMap.has_action("merge_weapon"), "InputMap thiếu dash hoặc merge_weapon")


func _test_weapons_evo_and_decompose() -> void:
	print("== 2. Kiểm tra 18 công thức hợp nhất, 6 Thần binh Hợp nhất, 13 Thần binh Trùm (ff384c), phân tách")
	_check(WeaponEvolutions.MERGE_RECIPES.size() == 18, "MERGE_RECIPES phải có 18 công thức (hiện %d)" % WeaponEvolutions.MERGE_RECIPES.size())
	var merged_mythics := ["thai_cuc_kiem", "cung_loi_hoa", "phao_thien_long", "luoi_hai_am_duong", "no_thien_co", "truong_ngu_hanh"]
	for mw in merged_mythics:
		_check(WeaponData.DATA.has(mw), "Thiếu Thần binh Hợp nhất: " + mw)
		_check(int(WeaponData.DATA[mw].get("tier", 0)) == 5, "%s phải là Tier 5" % mw)
		_check(Art.tex("weapons/%s.png" % mw) != null, "Thiếu sprite vũ khí hợp nhất: " + mw)
	for rec in WeaponEvolutions.MERGE_RECIPES:
		var a: String = str(rec["a"])
		var b: String = str(rec["b"])
		var res: String = str(rec["result"])
		_check(WeaponData.DATA.has(a) and WeaponData.DATA.has(b) and WeaponData.DATA.has(res), "Công thức hợp nhất không hợp lệ: %s + %s -> %s" % [a, b, res])
		_check(WeaponEvolutions.find_merge(a, b) == res, "find_merge(%s, %s) sai" % [a, b])
		_check(WeaponEvolutions.find_merge(b, a) == res, "find_merge(%s, %s) không đối xứng" % [b, a])

	_check(WeaponEvolutions.can_evolve("kiem_dong", {}), "can_evolve('kiem_dong', {}) phải true")
	_check(not WeaponEvolutions.can_evolve("kiem_dong", {"kiem_dong": true}), "can_evolve khi đã tiến hóa phải false")
	var eb: Dictionary = WeaponEvolutions.evolved_bonus("kiem_dong")
	_check(float(eb.get("dmg_mult", 0.0)) >= 1.3 and int(eb.get("pierce_add", 0)) >= 1, "evolved_bonus thiếu chỉ số")

	var all_boss_ids: Array = []
	for k in EnemyData.BOSSES.keys():
		all_boss_ids.append(str(k))
	for k in EnemyData.MYTHIC_BOSSES.keys():
		all_boss_ids.append(str(k))
	_check(all_boss_ids.size() == 13, "Tổng số trùm phải là 13 (hiện %d)" % all_boss_ids.size())
	_check(WeaponEvolutions.BOSS_MOTIF_BY_BOSS.size() == 13, "BOSS_MOTIF_BY_BOSS phải đủ 13 trùm")
	for bid in all_boss_ids:
		var bwid: String = WeaponEvolutions.boss_weapon_for(bid)
		_check(bwid != "" and WeaponData.DATA.has(bwid), "Thiếu Thần binh Trùm cho %s: %s" % [bid, bwid])
		var bw: Dictionary = WeaponData.DATA[bwid]
		_check(int(bw.get("tier", 0)) == 5 and bool(bw.get("boss_motif", false)), "%s phải có tier=5 và boss_motif=true" % bwid)
		_check(WeaponData.tier_color(bwid).is_equal_approx(Color("ff384c")), "%s tier_color phải là #ff384c" % bwid)
		_check(WeaponData.tier_name(bwid) == "Thần binh", "%s tier_name phải là Thần binh" % bwid)
		_check(Art.tex("weapons/%s.png" % bwid) != null, "Thiếu sprite Thần binh Trùm: " + bwid)

	var y1: Dictionary = MaterialData.decompose_yield("kiem_dong")
	var y5: Dictionary = MaterialData.decompose_yield("huyet_dao_to_dinh")
	_check(int(y1.get("coins", 0)) > 0 and not (y1.get("mats", {}) as Dictionary).is_empty(), "decompose_yield T1 rỗng")
	_check(int(y5.get("coins", 0)) > int(y1.get("coins", 0)) * 5, "decompose_yield T5 Boss Motif phải lớn hơn T1 nhiều")


func _test_heroes_skills_buffs_modes() -> void:
	print("== 3. Kiểm tra 11 Skill 2, 11 Passives, 5 Tượng, 8 Buffs mới, 8 Mutators & daily_mutators()")
	var expected_s2 := [
		"co_lenh_me_linh", "chieng_nui_nua", "thuy_trieu_dang", "tuong_nhu_nguyet",
		"hoa_cong_bach_dang", "kim_quy_ho_gia", "hoa_ho_dai_phao", "nhat_tao_xung_kich",
		"phuc_kich_yen_the", "boc_pha_nghin_can", "nho_tre_danh_giac",
	]
	_check(HeroData.ORDER.size() == 11, "HeroData.ORDER phải có 11 tướng")
	for i in HeroData.ORDER.size():
		var hid: String = str(HeroData.ORDER[i])
		var pinfo: Dictionary = HeroData.passive_info(hid)
		_check(str(pinfo.get("name", "")) != "" and str(pinfo.get("desc", "")) != "", "Thiếu nội tại cho " + hid)
		var s2: Dictionary = HeroData.skill_info(hid, 2)
		_check(str(s2.get("skill", "")) == expected_s2[i], "Skill 2 của %s sai: %s vs %s" % [hid, str(s2.get("skill", "")), expected_s2[i]])
		_check(Art.tex("ui/skill_%s.png" % expected_s2[i]) != null, "Thiếu icon ui/skill_%s.png" % expected_s2[i])

	_check(HeroSkillsExt.STATUE_ORDER.size() == 5, "STATUE_ORDER phải có 5 tượng")
	for sid_v in HeroSkillsExt.STATUE_ORDER:
		var sid: String = str(sid_v)
		_check(HeroSkillsExt.STATUES.has(sid), "Thiếu dữ liệu tượng: " + sid)
		_check(Art.tex("ui/statue_%s.png" % sid) != null, "Thiếu icon ui/statue_%s.png" % sid)

	var new_buffs := ["phan_tach", "khuc_xa", "bang_tam", "cuong_no_trum", "song_kiem_hop", "tuong_thach", "chien_xa_ben", "lien_kich_ba"]
	for bid in new_buffs:
		_check(BuffData.DATA.has(bid), "Thiếu buff mới: " + bid)
		_check(Art.tex("ui/buff_%s.png" % bid) != null, "Thiếu icon ui/buff_%s.png" % bid)

	_check(RunModes.BOSS_RUSH_CLEAR_LEVEL == 13, "BOSS_RUSH_CLEAR_LEVEL phải bằng 13")
	_check(RunModes.MUTATOR_ORDER.size() == 8, "MUTATOR_ORDER phải có 8 mutators")
	for mid_v in RunModes.MUTATOR_ORDER:
		_check(RunModes.MUTATORS.has(str(mid_v)), "Thiếu mutator: " + str(mid_v))
	var dm1: Array = RunModes.daily_mutators()
	var dm2: Array = RunModes.daily_mutators()
	_check(dm1.size() >= 2 and dm1.size() <= 3 and dm1 == dm2, "daily_mutators() không ổn định hoặc sai số lượng: " + str(dm1))


func _test_combat_dash_charge_combo_mount() -> void:
	print("== 4. Kiểm tra Dash, Charge, Combo 3 đòn + xóa đạn, Qi-Slash, 3 ô vũ khí, Hợp nhất, Mount, Skill 2 & Tượng")
	Global.run_buffs = {}
	Global.active_mutators = []
	Global.statue_id = ""
	Global.mentor_upgraded = false
	Global.evolved_weapons = {}
	Global.active_mount = ""
	Global.active_mount_hp = 0

	var arena := Node2D.new()
	add_child(arena)
	var p := Player.new()
	p.setup("ngo_quyen")
	p.position = Vector2(200, 200)
	arena.add_child(p)
	await _frames(2)

	# 3rd weapon slot via song_kiem_hop
	_check(p.weapons.size() == 2, "Mặc định phải có 2 ô vũ khí")
	p.apply_buff("song_kiem_hop")
	_check(p.weapons.size() == 3, "Buff song_kiem_hop phải mở ô vũ khí thứ 3")

	# Weapon Merge (equipped + nearby pickup)
	p.weapons[0] = "kiem_lua"
	p.slot = 0
	var pk := Pickup.new()
	pk.kind = "weapon"
	pk.weapon_id = "kiem_bang"
	pk.position = p.global_position + Vector2(12, 0)
	arena.add_child(pk)
	await _frames(2)
	var m_info: Dictionary = p.can_merge_nearby()
	_check(not m_info.is_empty(), "can_merge_nearby() phải phát hiện kiem_lua + kiem_bang")
	_check(p.try_merge_weapon(), "try_merge_weapon() phải hợp nhất thành công")
	_check(str(p.weapons[p.slot]) == "thai_cuc_kiem", "Kết quả hợp nhất phải là thai_cuc_kiem (hiện %s)" % str(p.weapons[p.slot]))

	# Dodge Dash
	_check(is_zero_approx(p.dash_cd_left), "dash_cd_left ban đầu phải 0")
	Input.action_press("dash")
	p._physics_process(0.016)
	Input.action_release("dash")
	_check(p.dash_cd_left > 1.0 and p._dodge_dash_t > 0.0, "Dodge Dash phải kích hoạt dash_cd_left & _dodge_dash_t")
	p._dodge_dash_t = 0.0
	p._invuln = 0.0

	# Charge Attack on Bow
	p.weapons[0] = "cung_dai"
	p.slot = 0
	p.energy = 100
	var b_cnt0: int = get_tree().get_nodes_in_group("player_bullets").size()
	p._release_charged_attack(WeaponData.get_data("cung_dai"), 1.0)
	await _frames(1)
	_check(get_tree().get_nodes_in_group("player_bullets").size() > b_cnt0, "Charge attack phải bắn ra đạn")

	# 3-hit melee combo + bullet clear
	p.weapons[0] = "kiem_dong"
	p.slot = 0
	var eb1 := Bullet.new()
	eb1.setup(false, p.global_position + Vector2(18, 0), Vector2.LEFT, 50.0, 1, 2.0, "orb_pink")
	arena.add_child(eb1)
	await _frames(1)
	p.aim_dir = Vector2.RIGHT
	p._melee_combo = 0
	p._melee(WeaponData.get_data("kiem_dong"))
	_check(p.melee_combo_phase == 0 and not is_instance_valid(eb1) or eb1.is_queued_for_deletion(), "Combo 0 phải chém và xóa đạn địch")
	p._melee(WeaponData.get_data("kiem_dong"))
	_check(p.melee_combo_phase == 1, "Combo phải lên phase 1")
	p._melee(WeaponData.get_data("kiem_dong"))
	_check(p.melee_combo_phase == 2, "Combo phải lên phase 2 (360°)")

	# Close-range Qi-Slash with ranged weapon when enemy < 26px
	var dummy_e := Enemy.new()
	dummy_e.setup("bo_binh", 1, p)
	dummy_e._spawn_t = 0.0
	dummy_e.position = p.global_position + Vector2(16, 0)
	arena.add_child(dummy_e)
	await _frames(1)
	var hp_e0: int = dummy_e.hp
	p.weapons[0] = "no_tay"
	p._qi_slash_cd = 0.0
	p._fire_timer = 0.0
	p._try_attack()
	_check(dummy_e.hp < hp_e0 and p._qi_slash_cd > 0.0, "Đánh tầm gần < 26px bằng vũ khí bắn xa phải kích Kiếm khí")
	if is_instance_valid(dummy_e):
		dummy_e.queue_free()

	# Mount boarding & damage absorption
	p.apply_buff("chien_xa_ben")
	p.board_mount("xe_tang_mount", 15)
	_check(p.mount_id == "xe_tang_mount" and p.mount_hp > 15, "chien_xa_ben phải tăng HP thú cưỡi > 15 (hiện %d)" % p.mount_hp)
	_check(Global.active_mount == "xe_tang_mount", "Global.active_mount phải đồng bộ")
	var hp_p0: int = p.hp
	var arm_p0: int = p.armor
	var mhp0: int = p.mount_hp
	p._invuln = 0.0
	p.take_damage(3)
	_check(p.mount_hp == mhp0 - 3 and p.armor == arm_p0 and p.hp == hp_p0, "Thú cưỡi phải hứng sát thương trước giáp/máu")
	p.board_mount("", 0)

	# Test all 11 Skill 2s & all 5 Statues executing without error
	for sid_v in HeroSkillsExt.STATUE_ORDER:
		Global.statue_id = str(sid_v)
		p._statue_cd = 0.0
		p.skill_timer = 0.0
		p._use_skill()
	Global.mentor_upgraded = true
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		Global.set_skill_index(hid, 2)
		var tp := Player.new()
		tp.setup(hid)
		tp.position = Vector2(220, 200)
		arena.add_child(tp)
		await _frames(1)
		tp.skill_timer = 0.0
		tp._use_skill()
		tp.queue_free()
		await _frames(1)

	Global.selected_skills = {}
	Global.statue_id = ""
	Global.mentor_upgraded = false
	arena.queue_free()
	await _frames(2)


func _test_events_hazards_boss_rush() -> void:
	print("== 5. Kiểm tra EventAltars (6 loại), MountPickup, Hazards (7 loại), Boss Rush 1..13 & Mutators")
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("le_loi")
	p.position = Vector2(300, 300)
	world.add_child(p)
	await _frames(2)

	Global.run_coins = 500
	for k in EventAltar.KINDS:
		var alt := EventAltar.new()
		alt.kind = k
		alt.level = 2
		alt.position = p.global_position
		world.add_child(alt)
		await _frames(1)
		p.weapons[0] = "kiem_dong"
		p.slot = 0
		alt.interact()
		await _frames(1)
		if k == "reforge_furnace":
			_check(Global.is_weapon_evolved("kiem_dong"), "reforge_furnace phải tiến hóa vũ khí")
		elif k == "statue_shrine":
			_check(Global.statue_id != "", "statue_shrine phải gán Global.statue_id")
		elif k == "mentor_npc":
			_check(Global.mentor_upgraded, "mentor_npc phải bật Global.mentor_upgraded")
		alt.queue_free()

	for mid in MountPickup.MOUNT_ORDER:
		var mp := MountPickup.new()
		mp.mount_id = mid
		mp.position = p.global_position
		world.add_child(mp)
		await _frames(1)
		mp.interact()
		_check(p.mount_id == mid, "MountPickup %s phải cho lên cưỡi" % mid)

	var hazards_ok := ["water_zone", "bach_dang_stake", "stealth_bush", "falling_boulder", "fire_brazier", "trench", "mortar_flare"]
	for hk in hazards_ok:
		var hz := BattlefieldHazard.new()
		hz.kind = hk
		hz.position = p.global_position
		world.add_child(hz)
		await _frames(2)
		if hk == "stealth_bush":
			_check(p.in_stealth_bush, "stealth_bush phải bật p.in_stealth_bush")
		elif hk == "trench":
			_check(p.in_trench, "trench phải bật p.in_trench")
		elif hk == "falling_boulder" or hk == "mortar_flare":
			hz.trigger_strike()
		hz.queue_free()
		await _frames(1)

	# Boss Rush Dungeon 1..12 & 13 (victory_hall)
	Global.pending_run_mode = "boss_rush"
	Global.pending_mutators = ["weapon_roulette", "glass_cannon", "infinite_energy", "big_bullets", "double_boss"]
	Global.badass_mode = true
	Global.start_run()
	_check(Global.is_boss_rush(), "Global.is_boss_rush() phải true")
	for lv in [1, 6, 12]:
		var d := Dungeon.new()
		world.add_child(d)
		d.generate(lv)
		await _frames(1)
		var has_boss: bool = false
		for cell in d.rooms:
			if str(d.rooms[cell].kind) == "boss":
				has_boss = true
		_check(d.rooms.size() == 3 and has_boss, "Boss Rush màn %d phải có 3 phòng và 1 phòng boss" % lv)
		d.queue_free()
		await _frames(1)

	var d13 := Dungeon.new()
	world.add_child(d13)
	d13.generate(13)
	await _frames(1)
	var has_vhall: bool = false
	for cell in d13.rooms:
		if str(d13.rooms[cell].kind) == "victory_hall":
			has_vhall = true
	_check(has_vhall, "Boss Rush màn 13 phải có victory_hall")
	d13.queue_free()

	# Weapon roulette stage swap
	p.weapons = ["kiem_dong", ""]
	p.slot = 0
	Global.level = 3
	Global.on_next_stage_mutators(p)
	_check(str(p.weapons[0]) != "", "weapon_roulette phải giữ vũ khí hợp lệ")

	# Normal mode Event Room [!]
	Global.pending_run_mode = "normal"
	Global.pending_mutators = []
	Global.badass_mode = false
	Global.start_run()
	var saw_event_room: bool = false
	for trial in 12:
		var dn := Dungeon.new()
		world.add_child(dn)
		seed(1000 + trial)
		dn.generate(2)
		for cell in dn.rooms:
			if str(dn.rooms[cell].kind) == "event":
				saw_event_room = true
		dn.queue_free()
	_check(saw_event_room, "Chế độ thường phải sinh ra phòng Sự kiện [!] ('event')")

	# ChallengeMenu open/close & toggles
	var cm := ChallengeMenu.new()
	add_child(cm)
	await _frames(1)
	cm.open()
	await _frames(2)
	_check(cm.visible, "ChallengeMenu phải mở được")
	cm._on_toggle_badass()
	_check(Global.badass_mode, "ChallengeMenu toggle Badass thất bại")
	cm._on_toggle_mutator("big_bullets")
	_check(Global.pending_mutators.has("big_bullets"), "ChallengeMenu toggle Mutator thất bại")
	cm.close()
	cm.queue_free()

	Global.badass_mode = false
	Global.pending_mutators = []
	Global.end_run()
	world.queue_free()
	await _frames(2)


func _test_save_backcompat() -> void:
	print("== 6. Kiểm tra tương thích ngược file lưu v1.2.9 và v1.7.2")
	# v1.2.9 minimal save (no blueprints, no garden_plots, no selected_skills, no badass_mode)
	var f129 := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f129.store_string(JSON.stringify({
		"coins": 456,
		"best_level": 9,
		"unlocked": ["hai_ba_trung", "ngo_quyen"],
		"selected_hero": "ngo_quyen",
		"upgrades": {"mau": 2},
		"discovered": ["giao_tre", "kiem_dong"],
	}))
	f129.close()
	Global.coins = 0
	Global.load_game()
	_check(Global.coins == 456 and Global.selected_hero == "ngo_quyen", "Nạp file lưu v1.2.9 thất bại")
	_check(Global.active_skill_index("ngo_quyen") == 1 and not Global.badass_mode, "v1.2.9 mặc định skill=1 và badass=false sai")
	_check(Global.garden_plots.size() == 3, "v1.2.9 thiếu garden_plots phải được khởi tạo 3 ô")

	# v1.7.2 save (has blueprints, hero_levels, garden_plots, no selected_skills/badass_mode)
	var f172 := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f172.store_string(JSON.stringify({
		"coins": 999,
		"best_level": 18,
		"unlocked": ["hai_ba_trung", "le_loi"],
		"selected_hero": "le_loi",
		"blueprints": ["thuan_thien", "sung_tesla"],
		"hero_levels": {"le_loi": 4},
		"selected_pet": "dog",
	}))
	f172.close()
	Global.load_game()
	_check(Global.coins == 999 and Global.selected_hero == "le_loi", "Nạp file lưu v1.7.2 thất bại")
	_check(Global.has_blueprint("thuan_thien") and Global.eff_hero_level("le_loi") == 4, "v1.7.2 mất dữ liệu blueprints/hero_levels")
	_check(Global.selected_pet == "dog" and Global.active_skill_index("le_loi") == 1, "v1.7.2 sai pet/skill mặc định")

	# v2.0.0 save/load round-trip
	Global.set_skill_index("le_loi", 2)
	Global.badass_mode = true
	Global.save_game()
	Global.selected_skills = {}
	Global.badass_mode = false
	Global.load_game()
	_check(Global.active_skill_index("le_loi") == 2 and Global.badass_mode, "Lưu/nạp v2.0 selected_skills & badass_mode thất bại")
	Global.badass_mode = false
	Global.selected_skills = {}
	await _frames(1)
