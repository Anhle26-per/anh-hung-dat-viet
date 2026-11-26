extends Node
## Kiểm thử tổng hợp v1.3.0:
##   1) 200 vũ khí, 14 bản vẽ (không rơi trong roll()), 10 loại đạn mới, SynergyData, weapon_pivot.z_index >= 0 khi ngắm lên
##   2) 31 biểu tượng phúc lành 32x32, BuffSelect open/reroll/pick
##   3) Tầng Hầm Chiến Tích: enter_basement()/exit_basement(), camera, minimap & 4 trạm tương tác
##   4) 24 Thành tựu, nhận thưởng xu/nguyên liệu/bản vẽ Cơ bản & Nâng cao, lưu/nạp, rèn vũ khí bản vẽ
## Chạy: godot --headless --path . res://tests/v13_features_test.tscn -> in "V13 FEATURES TEST OK"

const WeaponData = preload("res://scripts/data/weapons.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const AchievementData = preload("res://scripts/data/achievements.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Player = preload("res://scripts/entities/player.gd")
const BuffSelect = preload("res://scripts/ui/buff_select.gd")
const Art = preload("res://scripts/art/art.gd")

const TEST_SAVE := "user://v13_features_test_save.json"

const EXPECTED_BASIC_BPS := [
	"truong_hoa_cau", "dua_bang_suong", "bua_tran_yeu", "sung_bong_bong",
	"luan_hoi_ban", "bai_tu_sac", "long_den_ma_troi",
]
const EXPECTED_ADV_BPS := [
	"guong_bat_quai", "sach_sao_bang", "sung_tesla", "truong_ho_den",
	"kiem_thoi_khong", "luoi_hai_tu_than", "dai_bac_long_vuong",
]
const NEW_PROJS := [
	"orb_ice", "orb_void", "orb_star", "orb_lightning", "talisman",
	"chakram", "card", "bubble", "soul_bolt", "sawblade",
]

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
	Global.unlocked = ["hai_ba_trung"]
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
	Global.stats = Global.DEFAULT_STATS.duplicate()
	Global.run_buffs = {}
	Global.resume_data = {}
	Global.garden_plots = []
	Global.ensure_garden_plots()
	Global.selected_pet = ""


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func():
		print("V13 FEATURES TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V13 FEATURES TEST OK")
		get_tree().quit(0)
	else:
		print("V13 FEATURES TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	_reset_global()
	Global.save_game()

	print("== 1. Kiểm tra 200 vũ khí, 14 bản vẽ, 10 loại đạn mới, SynergyData & weapon_pivot khi ngắm lên")
	_check(WeaponData.DATA.size() == 200, "WeaponData.DATA.size() phải bằng 200 (hiện %d)" % WeaponData.DATA.size())

	var grips_file: FileAccess = FileAccess.open("res://assets/sprites/weapons/grips.json", FileAccess.READ)
	_check(grips_file != null, "không mở được grips.json")
	var grips_dict: Dictionary = {}
	if grips_file != null:
		var parsed: Variant = JSON.parse_string(grips_file.get_as_text())
		grips_file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			grips_dict = parsed

	var bp_count: int = 0
	for wid_v in WeaponData.DATA:
		var wid: String = str(wid_v)
		var sp_path: String = "res://assets/sprites/weapons/%s.png" % wid
		_check(FileAccess.file_exists(sp_path), "thiếu sprite vũ khí: " + sp_path)
		_check(Art.tex("weapons/%s.png" % wid) != null, "Art.tex thất bại cho vũ khí: " + wid)
		_check(grips_dict.has(wid), "grips.json thiếu vũ khí: " + wid)
		var gp: Vector2 = WeaponData.grip(wid)
		_check(gp.x >= 0.0 and gp.y >= 0.0, "grip không hợp lệ cho: " + wid)
		var fam: String = SynergyData.family(wid)
		_check(SynergyData.FAMILY_ORDER.has(fam), "SynergyData.family(%s) trả về hệ không hợp lệ: %s" % [wid, fam])
		if bool(WeaponData.DATA[wid].get("blueprint", false)):
			bp_count += 1

	_check(bp_count == 14, "số vũ khí blueprint phải bằng 14 (hiện %d)" % bp_count)
	for wid in EXPECTED_BASIC_BPS:
		_check(WeaponData.DATA.has(wid) and bool(WeaponData.DATA[wid].get("blueprint", false)), "thiếu blueprint cơ bản: " + wid)
		_check(MaterialData.requires_blueprint(wid) and MaterialData.blueprint_grade(wid) == "Cơ bản", "grade Cơ bản sai cho: " + wid)
	for wid in EXPECTED_ADV_BPS:
		_check(WeaponData.DATA.has(wid) and bool(WeaponData.DATA[wid].get("blueprint", false)), "thiếu blueprint nâng cao: " + wid)
		_check(MaterialData.requires_blueprint(wid) and MaterialData.blueprint_grade(wid) == "Nâng cao", "grade Nâng cao sai cho: " + wid)

	seed(2026130)
	for _r in 600:
		var rolled: String = WeaponData.roll(10, 2)
		_check(WeaponData.DATA.has(rolled), "WeaponData.roll() trả về mã không tồn tại: " + rolled)
		_check(not bool(WeaponData.DATA[rolled].get("blueprint", false)), "WeaponData.roll() không được rơi vũ khí bản vẽ: " + rolled)

	for pk_v in Bullet.PROJ:
		var pk: String = str(pk_v)
		var pinfo: Dictionary = Bullet.PROJ[pk]
		var tpath: String = str(pinfo.get("tex", ""))
		_check(tpath != "" and Art.tex(tpath) != null, "Bullet.PROJ[%s] không nạp được texture: %s" % [pk, tpath])
	for np in NEW_PROJS:
		_check(Bullet.PROJ.has(np), "thiếu loại đạn mới trong Bullet.PROJ: " + np)

	var p_holder := Node2D.new()
	add_child(p_holder)
	var p := Player.new()
	p.setup("hai_ba_trung")
	p_holder.add_child(p)
	await _frames(2)
	p.aim_dir = Vector2.UP
	p._process(0.016)
	_check(p.weapon_pivot.z_index >= 0, "khi ngắm lên (Vector2.UP) weapon_pivot.z_index phải >= 0 (đang %d)" % p.weapon_pivot.z_index)
	p_holder.queue_free()
	await _frames(2)

	print("== 2. Kiểm tra 31 biểu tượng phúc lành 32x32 & BuffSelect")
	_check(BuffData.DATA.size() == 31, "BuffData.DATA phải có 31 phúc lành (hiện %d)" % BuffData.DATA.size())
	for bid_v in BuffData.DATA:
		var bid: String = str(bid_v)
		var bpath: String = "res://assets/sprites/ui/buff_%s.png" % bid
		_check(FileAccess.file_exists(bpath), "thiếu icon buff: " + bpath)
		var bimg: Image = Image.load_from_file(ProjectSettings.globalize_path(bpath))
		_check(bimg != null and bimg.get_width() == 32 and bimg.get_height() == 32,
			"icon buff %s phải 32x32 (thực tế %s)" % [bid, "null" if bimg == null else "%dx%d" % [bimg.get_width(), bimg.get_height()]])
		var btex: Texture2D = Art.tex("ui/buff_%s.png" % bid)
		_check(btex != null and btex.get_width() == 32 and btex.get_height() == 32, "Art.tex buff %s phải 32x32" % bid)

	Global.start_run()
	Global.run_coins = 50
	var bsel := BuffSelect.new()
	add_child(bsel)
	await _frames(2)
	var chosen_list: Array[String] = []
	bsel.chosen.connect(func(picked_id: String): chosen_list.append(picked_id))
	_check(bsel.open("Màn 2", true) and bsel.visible, "BuffSelect.open() thất bại")
	var opts_before: Array = bsel._options.duplicate()
	_check(bsel.reroll() and Global.run_coins == 35, "BuffSelect.reroll() thất bại hoặc trừ sai xu")
	_check(bsel._options != opts_before, "BuffSelect.reroll() phải đổi bộ thẻ")
	bsel.pick(0)
	_check(not bsel.visible and not get_tree().paused and chosen_list.size() == 1, "BuffSelect.pick(0) không đóng hoặc không phát tín hiệu chosen")
	bsel.queue_free()
	await _frames(2)

	print("== 3. Kiểm tra Tầng Hầm Chiến Tích: chuyển cảnh & 4 trạm tương tác")
	_reset_global()
	Global.save_game()
	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(4)

	_check(not lobby.in_basement, "sảnh mới mở không được ở sẵn trong tầng hầm")
	var saw_down: bool = false
	var saw_up: bool = false
	for st in lobby.stair_stations:
		if str(st.kind) == "basement_down":
			saw_down = true
		elif str(st.kind) == "basement_up":
			saw_up = true
	_check(saw_down and saw_up, "thiếu trạm cầu thang basement_down / basement_up")

	await lobby.enter_basement(true)
	await _frames(2)
	_check(lobby.in_basement, "enter_basement() phải bật in_basement = true")
	_check(str(lobby.room_at(lobby.player.global_position).get("id", "")) == "basement", "room_at sau enter_basement phải là basement")
	_check(lobby.camera.limit_top == int(lobby.BASEMENT_RECT.position.y) and lobby.camera.limit_bottom == int(lobby.BASEMENT_RECT.end.y),
		"giới hạn camera tầng hầm chưa đúng")

	var basement_modals := {"basement_achieve": false, "basement_blueprint": false, "basement_gallery": false}
	for st in lobby.stations:
		var sk: String = str(st.kind)
		if basement_modals.has(sk):
			_check(st.visible, "trạm tầng hầm %s phải hiển thị khi đang ở tầng hầm" % sk)
			st.interact()
			await _frames(2)
			_check(lobby.ui.is_open(), "trạm tầng hầm %s không mở UI" % sk)
			basement_modals[sk] = lobby.ui.is_open()
			lobby.ui.close()
			await _frames(1)
	for sk in basement_modals:
		_check(bool(basement_modals[sk]), "chưa kiểm tra mở được UI của trạm %s" % sk)

	# Trạm thứ 4 ở tầng hầm: cầu thang lên Đại Sảnh
	var up_station: Node = null
	for st in lobby.stair_stations:
		if str(st.kind) == "basement_up":
			up_station = st
			break
	_check(up_station != null and up_station.visible, "trạm basement_up phải hiển thị khi đang ở tầng hầm")
	if up_station != null:
		up_station.interact()
		await _frames(3)
	if lobby.in_basement:
		await lobby.exit_basement(true)
		await _frames(2)
	_check(not lobby.in_basement, "exit_basement() phải đưa về Đại Sảnh (in_basement = false)")
	_check(str(lobby.room_at(lobby.player.global_position).get("id", "")) == "center", "sau exit_basement() phải ở phòng center")

	print("== 4. Kiểm tra 24 Thành tựu, nhận thưởng, lưu/nạp & chế tạo bản vẽ")
	_check(AchievementData.ORDER.size() == 24, "AchievementData.ORDER phải có 24 mốc (hiện %d)" % AchievementData.ORDER.size())
	_check(AchievementData.BLUEPRINT_TIERS["basic"].size() == 7 and AchievementData.BLUEPRINT_TIERS["advanced"].size() == 7,
		"BLUEPRINT_TIERS phải có 7 cơ bản + 7 nâng cao")

	_reset_global()
	Global.stats["kills"] = 100
	Global.stats["bosses"] = 1
	Global.stats["mythic_bosses"] = 1
	Global.best_level = 15
	Global.save_game()

	_check(Global.achievement_progress("kills_100") == 100 and Global.can_claim_achievement("kills_100"), "kills_100 phải đủ điều kiện nhận")
	_check(Global.can_claim_achievement("bosses_1"), "bosses_1 phải đủ điều kiện nhận")
	_check(Global.can_claim_achievement("mythic_1"), "mythic_1 phải đủ điều kiện nhận")
	_check(Global.can_claim_achievement("level_15"), "level_15 phải đủ điều kiện nhận")
	_check(not Global.has_blueprint("truong_hoa_cau") and not Global.has_blueprint("truong_ho_den"), "bản vẽ không được mở trước khi nhận thưởng")

	var rew_basic: Dictionary = Global.claim_achievement("kills_100")
	_check(str(rew_basic.get("blueprint", "")) == "truong_hoa_cau" and Global.has_blueprint("truong_hoa_cau"), "kills_100 phải mở bản vẽ truong_hoa_cau")
	_check(Global.coins == 60 and Global.material_count("dong") == 3 and Global.material_count("sat") == 2,
		"kills_100 trả thưởng xu/nguyên liệu sai")
	_check(not Global.can_claim_achievement("kills_100") and Global.claim_achievement("kills_100").is_empty(), "không được nhận trùng thành tựu")

	var rew_adv: Dictionary = Global.claim_achievement("mythic_1")
	_check(str(rew_adv.get("blueprint", "")) == "truong_ho_den" and Global.has_blueprint("truong_ho_den"), "mythic_1 phải mở bản vẽ nâng cao truong_ho_den")
	_check(Global.material_count("ngoc_than") >= 2 and Global.material_count("yeu_hon") >= 3, "mythic_1 phải cộng Ngọc thần & Yêu hồn")

	var claimed_rest: Array = Global.claim_all_achievements()
	_check(claimed_rest.size() >= 3 and Global.has_blueprint("dua_bang_suong") and Global.has_blueprint("sung_tesla"),
		"claim_all_achievements() phải nhận hết các mốc còn lại và mở dua_bang_suong + sung_tesla")

	# Kiểm tra lưu/nạp giữ nguyên achievements_claimed & blueprints
	var saved_coins: int = Global.coins
	var saved_claimed_cnt: int = Global.achievements_claimed.size()
	var saved_bp_cnt: int = Global.blueprints.size()
	Global.coins = 0
	Global.achievements_claimed = []
	Global.blueprints = []
	Global.load_game()
	_check(Global.coins == saved_coins and Global.achievements_claimed.size() == saved_claimed_cnt and Global.blueprints.size() == saved_bp_cnt,
		"load_game() không giữ được achievements_claimed / blueprints")
	_check(Global.has_blueprint("truong_hoa_cau") and Global.has_blueprint("truong_ho_den") and Global.has_blueprint("sung_tesla"),
		"load_game() bị mất bản vẽ đã mở")

	# Chế tạo vũ khí bản vẽ: bị khóa khi chưa mở, chế tạo thành công khi đã mở & đủ nguyên liệu
	Global.forged = ""
	Global.coins = 9999
	for mid in MaterialData.ORDER:
		Global.materials[mid] = 20
	_check(not Global.has_blueprint("kiem_thoi_khong") and not Global.can_craft("kiem_thoi_khong") and not Global.try_craft("kiem_thoi_khong"),
		"không được chế tạo vũ khí bản vẽ khi chưa mở khóa")
	_check(Global.can_craft("sung_tesla") and Global.try_craft("sung_tesla"), "phải chế tạo được sung_tesla sau khi mở bản vẽ")
	_check(Global.forged == "sung_tesla" and int(Global.stats.get("crafted", 0)) >= 1, "try_craft bản vẽ phải gán Global.forged và tăng stats.crafted")

	# Kiểm tra giao diện open_forge('craft'), open_blueprints(), open_weapon_gallery() không lỗi khi có dữ liệu thật
	lobby.ui.open_blueprints("all")
	await _frames(2)
	_check(lobby.ui.is_open(), "open_blueprints() không mở")
	lobby.ui.open_weapon_gallery(0, true)
	await _frames(2)
	_check(lobby.ui.is_open(), "open_weapon_gallery(0, true) không mở")
	Global.forged = ""
	lobby.ui.open_forge("craft")
	await _frames(2)
	_check(lobby.ui.is_open(), "open_forge('craft') không mở")
	lobby.ui.close()

	lobby.queue_free()
	await _frames(2)

	# Tương thích save cũ không có achievements_claimed / blueprints / mythic_bosses
	var f_old: FileAccess = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f_old.store_string(JSON.stringify({"coins": 77, "unlocked": ["hai_ba_trung"], "selected_hero": "hai_ba_trung"}))
	f_old.close()
	Global.achievements_claimed = ["kills_100"]
	Global.blueprints = ["truong_hoa_cau"]
	Global.load_game()
	_check(Global.coins == 77 and Global.achievements_claimed.is_empty() and Global.blueprints.is_empty(),
		"save cũ phải reset achievements_claimed và blueprints về rỗng an toàn")
	_check(int(Global.stats.get("mythic_bosses", -1)) == 0 and int(Global.stats.get("crafted", -1)) == 0,
		"save cũ phải gán mặc định mythic_bosses=0 và crafted=0")

	_completed = true
