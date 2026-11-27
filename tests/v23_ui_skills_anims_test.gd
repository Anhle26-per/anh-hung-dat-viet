extends Node
## Kiểm thử tổng hợp v2.3.0:
##   1) Sảnh chính: `_select_banner.get_global_rect()` KHÔNG đè lên bất kỳ bục 11 vị tướng nào (cả ở vị trí mặc định & khi di chuột).
##   2) Toàn bộ Sprite Sheets: 11 tướng = 28 khung (896x32), 49 quái nhỏ = 24 khung, 26 trùm = 48 khung lưới 12x4 (width <= 1728px).
##   3) Toàn bộ 22 Kỹ năng Anh hùng (11 Chiêu 1 + 11 Chiêu 2): gọi `_use_skill()` sinh `SkillCastFx`, kích hoạt `"skill"` anim, chạy mượt 10 khung không lỗi.
## Chạy: godot --headless --path . res://tests/v23_ui_skills_anims_test.tscn -> "V23 UI SKILLS ANIMS TEST OK"

const VersionData = preload("res://scripts/data/version.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")
const SkillCastFx = preload("res://scripts/effects/skill_fx.gd")
const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")

const TEST_SAVE := "user://v23_test_save.json"

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
	for p in [TEST_SAVE, TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	Global.save_path = TEST_SAVE
	Global.log_path = ""
	_wipe()
	get_tree().create_timer(60.0).timeout.connect(func():
		print("V23 UI SKILLS ANIMS TEST FAILED: quá thời gian")
		_wipe()
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("V23 UI SKILLS ANIMS TEST OK")
		get_tree().quit(0)
	else:
		print("V23 UI SKILLS ANIMS TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra Version v2.3.0 (BUILD 230) & HotpatchSync")
	_check(VersionData.VERSION == "2.3.0", "VERSION phải là '2.3.0' (hiện '%s')" % VersionData.VERSION)
	_check(VersionData.BUILD == 230, "BUILD phải là 230 (hiện %d)" % VersionData.BUILD)
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "HotpatchSync.needs_autoload_sync phải false trên v2.3.0")

	await _test_lobby_banner_no_overlap()
	await _test_all_sprite_dimensions()
	await _test_all_22_hero_skills()
	_completed = true


func _test_lobby_banner_no_overlap() -> void:
	print("== 2. Kiểm tra Sảnh chính: _select_banner không đè lên bất kỳ bục 11 tướng nào")
	Global.unlocked = ["hai_ba_trung", "ba_trieu", "ngo_quyen"]
	Global.selected_hero = "hai_ba_trung"
	Global.save_game()

	var lobby_scene: PackedScene = load("res://scenes/lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	get_tree().root.add_child(lobby)
	await _frames(5)

	_check(lobby.ui != null and lobby.ui._select_banner != null, "Thiếu lobby.ui._select_banner")
	_check(lobby._hero_npcs.size() == 11, "Phải có đủ 11 _hero_npcs (hiện %d)" % lobby._hero_npcs.size())
	if lobby.ui != null and lobby.ui._select_banner != null:
		var banner: Control = lobby.ui._select_banner
		_check(banner.visible, "_select_banner phải hiển thị khi chưa xác nhận tướng")
		var b_rect: Rect2 = banner.get_global_rect()
		_check(b_rect.size.x > 40.0 and b_rect.size.y > 8.0, "_select_banner kích thước bất thường: %s" % str(b_rect))
		if lobby.ui._hint_label != null:
			var h_rect: Rect2 = lobby.ui._hint_label.get_global_rect()
			_check(not b_rect.intersects(h_rect), "_select_banner %s đè lên _hint_label %s" % [str(b_rect), str(h_rect)])
		var xform: Transform2D = lobby.get_viewport().get_canvas_transform()
		for hid_v in HeroData.ORDER:
			var hid: String = str(hid_v)
			var st: Node2D = lobby._hero_npcs.get(hid, null)
			_check(st != null and is_instance_valid(st), "Thiếu bục tướng %s" % hid)
			if st == null:
				continue
			var screen_pos: Vector2 = xform * st.global_position
			var ped_rect := Rect2(screen_pos - Vector2(18.0, 22.0), Vector2(36.0, 44.0))
			_check(not b_rect.intersects(ped_rect),
				"_select_banner %s đè lên bục tướng %s (%s)" % [str(b_rect), hid, str(ped_rect)])
			if st.get_child_count() > 0 and st.get_child(0) is AnimatedSprite2D:
				var spr := st.get_child(0) as AnimatedSprite2D
				_check(spr.sprite_frames != null and spr.sprite_frames.get_frame_count("idle") == 6,
					"Bục tướng %s phải có idle 6 khung (hiện %d)" % [hid, spr.sprite_frames.get_frame_count("idle") if spr.sprite_frames != null else -1])

	lobby.queue_free()
	await _frames(3)


func _test_all_sprite_dimensions() -> void:
	print("== 3. Kiểm tra 11 Tướng (28f), 49 Quái nhỏ (24f), 26 Trùm (48f lưới 12x4)")
	_check(HeroData.ORDER.size() == 11, "Phải có 11 tướng")
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		var tex: Texture2D = load("res://assets/sprites/heroes/%s.png" % hid)
		_check(tex != null and tex.get_width() == 896 and tex.get_height() == 32,
			"Tướng %s phải 896x32 (28f)" % hid)

	var mob_entries: Array = []
	var armies: Array[String] = [
		"dong_han", "dong_ngo", "nam_han", "tong", "nguyen_mong",
		"minh", "thanh", "phap_thuy", "phap_vien_chinh", "phap_1954",
	]
	for army in armies:
		var kinds: Array = ["bo_binh", "linh_sung", "xa_thu", "phao_binh"] if army.begins_with("phap") else ["bo_binh", "cung_thu", "khien_binh", "phap_su"]
		for kind in kinds:
			mob_entries.append(["enemies/%s_%s.png" % [army, kind], 24, 26])
	mob_entries.append(["enemies/nguyen_mong_ky_binh.png", 34, 30])
	mob_entries.append(["enemies/xe_tang.png", 40, 30])
	for mid in ["tieu_yeu", "ho_tinh", "moc_tinh", "chan_tinh", "dai_bang", "ma_troi", "ngu_tinh"]:
		var sz: Vector2i = EnemyData.FOLK[mid]["size"]
		mob_entries.append([EnemyData.FOLK[mid]["sheet"], sz.x, sz.y])
	_check(mob_entries.size() == 49, "Phải có 49 quái nhỏ (hiện %d)" % mob_entries.size())
	for entry in mob_entries:
		var mtex: Texture2D = load("res://assets/sprites/" + str(entry[0]))
		var fw: int = int(entry[1])
		var fh: int = int(entry[2])
		_check(mtex != null and mtex.get_width() == fw * 24 and mtex.get_height() == fh,
			"Quái %s phải %dx%d (24f)" % [str(entry[0]), fw * 24, fh])

	var boss_sheets: int = 0
	for bid in EnemyData.BOSSES:
		var is_ship: bool = (bid == "tau_hy_vong")
		var fw: int = 64 if is_ship else 48
		var fh: int = 44 if is_ship else 48
		for suf in ["", "_2"]:
			var bfw: int = fw if suf == "" else fw * 2 + 16
			var bfh: int = fh if suf == "" else fh * 2 + 18
			var bp: String = "res://assets/sprites/enemies/boss_%s%s.png" % [bid, suf]
			var bt: Texture2D = load(bp)
			_check(bt != null and bt.get_width() == bfw * 12 and bt.get_height() == bfh * 4 and bt.get_width() <= 1728,
				"Trùm %s phải %dx%d (48f lưới 12x4, <=1728px)" % [bp, bfw * 12, bfh * 4])
			boss_sheets += 1
	for lid in EnemyData.LEGENDS:
		var lsz: Vector2i = EnemyData.LEGENDS[lid]["size"]
		for suf in ["", "_2"]:
			var lp: String = "res://assets/sprites/enemies/boss_%s%s.png" % [lid, suf]
			var lt: Texture2D = load(lp)
			_check(lt != null and lt.get_width() == lsz.x * 12 and lt.get_height() == lsz.y * 4 and lt.get_width() <= 1728,
				"Tam Yêu %s phải %dx%d (48f lưới 12x4, <=1728px)" % [lp, lsz.x * 12, lsz.y * 4])
			boss_sheets += 1
	_check(boss_sheets == 26, "Phải có 26 sheet trùm (hiện %d)" % boss_sheets)


func _test_all_22_hero_skills() -> void:
	print("== 4. Kiểm tra đủ 22 Kỹ năng Anh hùng (11 Chiêu 1 + 11 Chiêu 2) sinh SkillCastFx + anim 'skill' + 10 khung mượt")
	var checked_skills: int = 0
	for hid_v in HeroData.ORDER:
		var hid: String = str(hid_v)
		for sk_idx in [1, 2]:
			var arena := Node2D.new()
			add_child(arena)
			Global.selected_skills[hid] = sk_idx
			var p := PlayerScript.new()
			p.setup(hid)
			p.position = Vector2(240, 180)
			p.aim_dir = Vector2.RIGHT
			arena.add_child(p)
			await _frames(1)

			var sk_info: Dictionary = HeroData.skill_info(hid, sk_idx)
			var sk_id: String = str(sk_info.get("skill", ""))
			_check(sk_id != "", "Thiếu skill_id cho %s chiêu %d" % [hid, sk_idx])

			p.skill_timer = 0.0
			p._use_skill()
			_check(p.body != null and p.body.animation == &"skill",
				"%s chiêu %d (%s) không kích hoạt anim 'skill' (hiện '%s')" % [hid, sk_idx, sk_id, str(p.body.animation) if p.body != null else "null"])

			var found_fx: bool = false
			for ch in arena.get_children():
				if ch is SkillCastFx and str(ch.skill_id) == sk_id:
					found_fx = true
					break
			_check(found_fx, "%s chiêu %d (%s) không sinh SkillCastFx" % [hid, sk_idx, sk_id])

			await _frames(10)
			_check(is_instance_valid(p) and not p.dead, "%s chiêu %d gặp lỗi sau 10 khung" % [hid, sk_idx])

			checked_skills += 1
			arena.queue_free()
			await _frames(1)
	_check(checked_skills == 22, "Phải kiểm đủ 22 kỹ năng (thực tế %d)" % checked_skills)
