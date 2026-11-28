extends Node
## Kiểm thử tổng hợp v1.4.0:
##   1) 11 âm thanh kỹ năng tướng riêng biệt & hợp lệ trong Sfx.SFX_FILES
##   2) 200 vũ khí có hồ sơ âm thanh Sfx.weapon_sfx_profile(wid, w) hợp lệ và phân biệt
##   3) 190 bản vẽ rèn (can_forge_weapon == true), 10 vũ khí cơ bản không rèn
##   4) discover() tự mở bản vẽ vũ khí thường; 14 bản vẽ thành tựu vẫn khóa theo mốc
##   5) Công thức Huyền thoại (Cấp 5): coins == 850, sat >= 12, dong >= 10, yeu_hon >= 8, ngoc_than >= 6; rèn thành công/thất bại đúng
##   6) Global.roll_boss_blueprint() mở khóa một bản vẽ chưa sở hữu
##   7) lobby_ui.open_blueprints() và open_forge("craft") mở sạch sẽ không lỗi
## Chạy: godot --headless --path . res://tests/v14_audio_blueprints_test.tscn -> in "V14 AUDIO BLUEPRINTS TEST OK"

const HeroesData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const MaterialData = preload("res://scripts/data/materials.gd")

const TEST_SAVE := "user://v14_audio_blueprints_test_save.json"

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
		print("V14 AUDIO BLUEPRINTS TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V14 AUDIO BLUEPRINTS TEST OK")
		get_tree().quit(0)
	else:
		print("V14 AUDIO BLUEPRINTS TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	_reset_global()
	Global.save_game()

	print("== 1. Kiểm tra kỹ năng tướng có khóa SFX hợp lệ trong SFX_FILES")
	_check(HeroesData.ORDER.size() >= 11, "HeroesData.ORDER phải có >= 11 tướng (hiện %d)" % HeroesData.ORDER.size())
	var skill_keys: Dictionary = {}
	for hid_v in HeroesData.ORDER:
		var hid: String = str(hid_v)
		var sid: String = Sfx.skill_sfx_id(hid)
		_check(sid != "", "Sfx.skill_sfx_id(%s) trả về rỗng" % hid)
		_check(Sfx.SFX_FILES.has(sid), "SFX_FILES thiếu khóa kỹ năng %s của %s" % [sid, hid])
		var spath: String = str(Sfx.SFX_FILES.get(sid, ""))
		_check(spath != "" and FileAccess.file_exists(spath), "thiếu tệp wav cho %s: %s" % [sid, spath])
		if sid != "skill":
			_check(not skill_keys.has(sid), "khóa SFX kỹ năng trùng nhau: %s (%s và %s)" % [sid, str(skill_keys.get(sid, "")), hid])
			skill_keys[sid] = hid
		Sfx.play_skill(hid)
		await _frames(1)
	Sfx.stop_all_sfx()
	_check(skill_keys.size() >= 14, "phải có >= 14 khóa SFX kỹ năng riêng biệt (hiện %d)" % skill_keys.size())

	print("== 2. Kiểm tra toàn bộ vũ khí có weapon_sfx_profile hợp lệ & phân biệt")
	_check(WeaponData.DATA.size() >= 217, "WeaponData.DATA phải có >= 217 vũ khí (hiện %d)" % WeaponData.DATA.size())
	var profile_sigs: Dictionary = {}
	for wid_v in WeaponData.DATA:
		var wid: String = str(wid_v)
		var w: Dictionary = WeaponData.DATA[wid]
		var prof: Dictionary = Sfx.weapon_sfx_profile(wid, w)
		var sid: String = str(prof.get("id", ""))
		var pitch: float = float(prof.get("pitch", 0.0))
		var vol: float = float(prof.get("vol", 0.0))
		_check(sid != "" and Sfx.SFX_FILES.has(sid), "weapon_sfx_profile(%s) có id không hợp lệ: %s" % [wid, sid])
		_check(pitch > 0.3 and pitch < 3.0, "weapon_sfx_profile(%s) pitch bất thường: %.4f" % [wid, pitch])
		_check(vol >= -30.0 and vol <= 12.0, "weapon_sfx_profile(%s) vol bất thường: %.2f" % [wid, vol])
		var sig: String = "%s|%.4f|%.2f" % [sid, pitch, vol]
		_check(not profile_sigs.has(sig), "profile âm thanh trùng giữa %s và %s: %s" % [str(profile_sigs.get(sig, "")), wid, sig])
		profile_sigs[sig] = wid
	_check(profile_sigs.size() >= 217, "phải có >= 217 profile âm thanh phân biệt (hiện %d)" % profile_sigs.size())
	Sfx.play_weapon("kiem_dong", WeaponData.DATA["kiem_dong"])
	Sfx.play_weapon("gay_tre", WeaponData.DATA["gay_tre"])
	await _frames(1)
	Sfx.stop_all_sfx()

	print("== 3. Kiểm tra vũ khí bản vẽ rèn (can_forge_weapon == true)")
	var all_bps: Array = MaterialData.all_blueprint_weapons()
	_check(all_bps.size() >= 207, "MaterialData.all_blueprint_weapons().size() phải >= 207 (hiện %d)" % all_bps.size())
	var basic_cnt: int = 0
	for wid_v in WeaponData.DATA:
		var wid: String = str(wid_v)
		var w: Dictionary = WeaponData.DATA[wid]
		if bool(w.get("basic", false)):
			basic_cnt += 1
			_check(not MaterialData.can_forge_weapon(wid), "vũ khí cơ bản %s không được can_forge_weapon" % wid)
			_check(not all_bps.has(wid), "all_blueprint_weapons không được chứa vũ khí cơ bản %s" % wid)
		else:
			_check(MaterialData.can_forge_weapon(wid), "vũ khí %s phải can_forge_weapon == true" % wid)
			_check(all_bps.has(wid), "all_blueprint_weapons thiếu %s" % wid)
	_check(basic_cnt >= 10, "phải có >= 10 vũ khí cơ bản (hiện %d)" % basic_cnt)

	_check(MaterialData.blueprint_tier_label("gay_tre") == "Cơ bản", "tier label cấp 1 phải là Cơ bản")
	_check(MaterialData.blueprint_tier_label("dao") == "Trung cấp", "tier label cấp 3 phải là Trung cấp")
	_check(MaterialData.blueprint_tier_label("sung_tesla") == "Nâng cao", "tier label cấp 4 phải là Nâng cao")
	_check(MaterialData.blueprint_tier_label("kiem_thoi_khong") == "★ Huyền thoại", "tier label cấp 5 phải là ★ Huyền thoại")

	print("== 4. Kiểm tra discover() không tự mở bản vẽ (cả thường lẫn 14 bản vẽ thành tựu)")
	_reset_global()
	Global.save_game()
	var ach_bp_cnt: int = 0
	var non_ach_checked: int = 0
	for wid_v in all_bps:
		var wid: String = str(wid_v)
		if MaterialData.is_achievement_blueprint(wid):
			ach_bp_cnt += 1
			Global.discover(wid)
			_check(not Global.has_blueprint(wid) and not Global.owns_blueprint(wid), "bản vẽ thành tựu %s không được tự mở khi discover()" % wid)
		elif non_ach_checked < 10:
			non_ach_checked += 1
			Global.discover(wid)
			_check(not Global.has_blueprint(wid) and not Global.owns_blueprint(wid), "discover(%s) không được tự mở bản vẽ trong v2.2.0" % wid)
	_check(ach_bp_cnt == 14, "phải có đúng 14 bản vẽ thành tựu (hiện %d)" % ach_bp_cnt)

	print("== 5. Kiểm tra công thức Cấp 5 Huyền thoại & rèn thành công/thất bại")
	_reset_global()
	var t5_wids: Array = []
	for wid_v in all_bps:
		var wid: String = str(wid_v)
		if int(WeaponData.DATA[wid].get("tier", 1)) == 5:
			t5_wids.append(wid)
			var rec: Dictionary = MaterialData.recipe_for(wid)
			var mats: Dictionary = rec.get("mats", {})
			_check(int(rec.get("coins", 0)) == 850, "cấp 5 %s phải tốn 850 xu (hiện %s)" % [wid, str(rec.get("coins", 0))])
			_check(int(mats.get("sat", 0)) >= 12, "cấp 5 %s phải cần sat >= 12" % wid)
			_check(int(mats.get("dong", 0)) >= 10, "cấp 5 %s phải cần dong >= 10" % wid)
			_check(int(mats.get("yeu_hon", 0)) >= 8, "cấp 5 %s phải cần yeu_hon >= 8" % wid)
			_check(int(mats.get("ngoc_than", 0)) >= 6, "cấp 5 %s phải cần ngoc_than >= 6" % wid)
	_check(t5_wids.size() > 0, "không tìm thấy vũ khí cấp 5 nào")

	var target_t5: String = ""
	for wid_v in t5_wids:
		var wid: String = str(wid_v)
		if not MaterialData.is_achievement_blueprint(wid):
			target_t5 = wid
			break
	if target_t5 != "":
		var rec5: Dictionary = MaterialData.recipe_for(target_t5)
		var mats5: Dictionary = rec5.get("mats", {})
		Global.coins = 9999
		for mid_v in MaterialData.ORDER:
			Global.materials[str(mid_v)] = 99
		# Chưa có bản vẽ -> rèn thất bại (dù đã discover)
		_check(not Global.can_craft(target_t5) and not Global.try_craft(target_t5), "chưa có bản vẽ %s không được rèn" % target_t5)
		Global.discover(target_t5)
		_check(not Global.owns_blueprint(target_t5) and not Global.can_craft(target_t5), "discover(%s) không được phép mở khóa rèn" % target_t5)
		# Thu thập đủ mảnh & ghép bản vẽ, nhưng thiếu nguyên liệu -> thất bại
		var need_t5: int = Global.fragments_needed(target_t5)
		Global.add_blueprint_fragment(target_t5, need_t5)
		_check(Global.assemble_blueprint(target_t5) and Global.owns_blueprint(target_t5), "ghép bản vẽ %s phải thành công" % target_t5)
		Global.materials["ngoc_than"] = 0
		_check(not Global.can_craft(target_t5) and not Global.try_craft(target_t5), "thiếu ngoc_than không được rèn %s" % target_t5)
		# Đủ xu + nguyên liệu -> thành công và trừ đúng
		Global.coins = 900
		for mid_v in MaterialData.ORDER:
			Global.materials[str(mid_v)] = 20
		_check(Global.can_craft(target_t5) and Global.try_craft(target_t5), "đủ bản vẽ & nguyên liệu phải rèn được %s" % target_t5)
		_check(Global.forged == target_t5, "Global.forged phải là %s" % target_t5)
		_check(Global.coins == 50, "rèn cấp 5 phải trừ 850 xu (còn %d)" % Global.coins)
		for m_k in mats5:
			_check(Global.material_count(str(m_k)) == 20 - int(mats5[m_k]), "trừ nguyên liệu %s sai" % str(m_k))

	print("== 6. Kiểm tra Global.roll_boss_blueprint()")
	_reset_global()
	Global.save_game()
	var rolled1: String = Global.roll_boss_blueprint(false)
	_check(rolled1 != "" and Global.has_blueprint(rolled1), "roll_boss_blueprint(false) phải mở bản vẽ hợp lệ (nhận '%s')" % rolled1)
	_check(not MaterialData.is_achievement_blueprint(rolled1), "roll_boss_blueprint không được mở bản vẽ thành tựu: %s" % rolled1)
	var rolled2: String = Global.roll_boss_blueprint(true)
	_check(rolled2 != "" and rolled2 != rolled1 and Global.has_blueprint(rolled2), "roll_boss_blueprint(true) phải mở thêm bản vẽ mới (nhận '%s')" % rolled2)

	print("== 7. Kiểm tra lobby_ui.open_blueprints() và open_forge('craft')")
	Global.forged = ""
	Global.coins = 5000
	for mid_v in MaterialData.ORDER:
		Global.materials[str(mid_v)] = 30
	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(4)
	lobby.ui.open_blueprints("all")
	await _frames(2)
	_check(lobby.ui.is_open(), "lobby_ui.open_blueprints('all') không mở")
	var bp_texts: Array = _collect_texts(lobby.ui._panel)
	_check(_has_substr(bp_texts, "/ %d" % all_bps.size()), "open_blueprints() thiếu tiêu đề X / %d" % all_bps.size())
	_check(_has_substr(bp_texts, "Huyền Thoại"), "open_blueprints() thiếu tab Huyền Thoại")
	lobby.ui.open_blueprints("legendary")
	await _frames(2)
	_check(lobby.ui.is_open(), "lobby_ui.open_blueprints('legendary') không mở")
	var leg_texts: Array = _collect_texts(lobby.ui._panel)
	_check(_has_substr(leg_texts, "850 xu") or _has_substr(leg_texts, "Cấp 5"), "open_blueprints('legendary') thiếu thẻ Cấp 5")
	lobby.ui.open_forge("craft")
	await _frames(2)
	_check(lobby.ui.is_open(), "lobby_ui.open_forge('craft') không mở")
	lobby.ui.close()
	lobby.queue_free()
	await _frames(2)

	_completed = true


func _collect_texts(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	if root is Label or root is Button:
		out.append(str(root.text))
	for ch in root.get_children():
		out.append_array(_collect_texts(ch))
	return out


func _has_substr(arr: Array, sub: String) -> bool:
	for s in arr:
		if str(s).find(sub) != -1:
			return true
	return false
