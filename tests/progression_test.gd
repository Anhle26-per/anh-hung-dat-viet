extends Node
## Kiểm thử thẻ G19: Tu luyện tướng (cấp 1–5) & Rèn binh khí khởi đầu (bậc 1–5), 10 đặc tính, lưu trữ, giao diện.
## Chạy: godot --headless --path . res://tests/progression_test.tscn -> in "PROGRESSION TEST OK"

const ProgressionData = preload("res://scripts/data/progression.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const Player = preload("res://scripts/entities/player.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Art = preload("res://scripts/art/art.gd")
const TEST_SAVE := "user://progression_test_save.json"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _reset_all() -> void:
	Global.coins = 0
	Global.materials = {}
	Global.hero_levels = {}
	Global.weapon_ranks = {}
	Global.upgrades = {}
	Global.unlocked = ["hai_ba_trung", "ba_trieu", "ngo_quyen", "ly_thuong_kiet", "quang_trung", "hoang_hoa_tham"]
	Global.selected_hero = "ngo_quyen"


func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func():
		print("PROGRESSION TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0:
		print("PROGRESSION TEST OK")
		get_tree().quit(0)
	else:
		print("PROGRESSION TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	_reset_all()

	print("== 1. Ảnh biến thể _b3 và _b5 cho 10 vũ khí khởi đầu")
	for hid in HeroData.ORDER:
		var wid: String = str(HeroData.DATA[hid].weapon)
		_check(Art.tex("weapons/%s_b3.png" % wid) != null, "thiếu _b3: " + wid)
		_check(Art.tex("weapons/%s_b5.png" % wid) != null, "thiếu _b5: " + wid)

	print("== 2. Nâng cấp trừ đúng xu + nguyên liệu, thiếu/khóa/tối đa không nâng và không trừ")
	_check(not Global.try_upgrade_hero("chien_si_dien_bien"), "nâng được tướng bị khóa")
	Global.coins = 100
	_check(not Global.try_upgrade_hero("ngo_quyen") and Global.coins == 100, "nâng tướng khi thiếu xu")
	Global.coins = 150 + 300 + 500 + 800 + 50
	Global.materials = {"yeu_hon": 2, "ngoc_than": 1}
	for lv in [2, 3, 4, 5]:
		_check(Global.try_upgrade_hero("ngo_quyen"), "nâng tướng cấp %d thất bại" % lv)
		_check(Global.hero_level("ngo_quyen") == lv, "cấp tướng không phải %d" % lv)
	_check(Global.coins == 50 and Global.material_count("yeu_hon") == 0 and Global.material_count("ngoc_than") == 0,
		"trừ xu/nguyên liệu tướng sai: coins=%d mats=%s" % [Global.coins, str(Global.materials)])
	_check(not Global.try_upgrade_hero("ngo_quyen") and Global.hero_level("ngo_quyen") == 5, "vượt quá cấp 5")

	Global.coins = 99
	Global.materials = {"dong": 3}
	_check(not Global.try_upgrade_weapon("ngo_quyen") and Global.coins == 99 and Global.material_count("dong") == 3,
		"rèn bậc vũ khí khi thiếu xu")
	Global.coins = 100 + 220 + 400 + 700 + 20
	Global.materials = {"dong": 5, "sat": 19, "yeu_hon": 5, "ngoc_than": 2}
	for r in [2, 3, 4, 5]:
		_check(Global.try_upgrade_weapon("ngo_quyen"), "rèn vũ khí bậc %d thất bại" % r)
		_check(Global.weapon_rank("ngo_quyen") == r, "bậc vũ khí không phải %d" % r)
	_check(Global.coins == 20 and Global.materials.is_empty(),
		"trừ tài nguyên vũ khí sai: coins=%d mats=%s" % [Global.coins, str(Global.materials)])
	_check(not Global.try_upgrade_weapon("ngo_quyen") and Global.weapon_rank("ngo_quyen") == 5, "vượt quá bậc 5")

	print("== 3. Máu/giáp/năng lượng cộng dồn Lò rèn + Tu luyện và giảm hồi chiêu ×0.85")
	Global.upgrades = {"mau": 2, "giap": 1, "nang_luong": 1}
	var world := Node2D.new()
	add_child(world)
	var pn := Player.new()
	pn.setup("ngo_quyen")
	world.add_child(pn)
	var base_nq: Dictionary = HeroData.DATA["ngo_quyen"]
	_check(pn.max_hp == int(base_nq.hp) + 2 + 1, "max_hp=%d" % pn.max_hp)
	_check(pn.max_armor == int(base_nq.armor) + 1 + 1, "max_armor=%d" % pn.max_armor)
	_check(pn.max_energy == int(base_nq.energy) + 40 + 30, "max_energy=%d" % pn.max_energy)
	pn._use_skill()
	_check(is_equal_approx(pn.skill_timer, float(base_nq.skill_cd) * 0.85),
		"skill_timer=%.3f (kỳ vọng %.3f)" % [pn.skill_timer, float(base_nq.skill_cd) * 0.85])
	pn.queue_free()
	await _frames(2)

	print("== 4. Sát thương làm tròn lên & cooldown bậc 1..5, vũ khí khác và tướng khác không đổi")
	var expected_dmg := [0, 4, 5, 6, 8, 9]
	var expected_cd := [0.0, 0.38, 0.38, 0.38 * 0.92, 0.38 * 0.88, 0.38 * 0.85]
	var pcheck := Player.new()
	pcheck.setup("ngo_quyen")
	world.add_child(pcheck)
	for r2 in [1, 2, 3, 4, 5]:
		Global.weapon_ranks["ngo_quyen"] = r2
		var ew: Dictionary = pcheck.effective_weapon("giao_tre")
		_check(int(ew.damage) == expected_dmg[r2] and is_equal_approx(float(ew.cooldown), expected_cd[r2]),
			"bậc %d sai: dmg=%d cd=%.4f" % [r2, int(ew.damage), float(ew.cooldown)])
	var other_w: Dictionary = pcheck.effective_weapon("kiem")
	_check(int(other_w.damage) == int(WeaponData.DATA["kiem"].damage), "vũ khí khác bị đổi")
	var pother := Player.new()
	pother.setup("ba_trieu")
	world.add_child(pother)
	_check(int(pother.effective_weapon("giao_tre").damage) == 4, "tướng khác hưởng bậc của ngo_quyen")
	pcheck.queue_free()
	pother.queue_free()
	await _frames(2)

	print("== 5. Từng Đặc tính hoạt động & Synergy vẫn bằng 2")
	# Cận chiến Đ1 reach +15% & Đ2 nhát thứ 3 phóng sword_wave
	Global.weapon_ranks["hai_ba_trung"] = 5
	_check(SynergyData.level("hai_ba_trung", "kiem_dong") == 2, "synergy vũ khí nâng bậc != 2")
	var ph := Player.new()
	ph.setup("hai_ba_trung")
	world.add_child(ph)
	var kd := ph.effective_weapon("kiem_dong")
	_check(is_equal_approx(float(kd.reach), float(WeaponData.DATA["kiem_dong"].reach) * 1.15), "Đ1 cận chiến reach sai")
	ph._melee(kd)
	ph._melee(kd)
	var sw_before: int = 0
	for ch in world.get_children():
		if ch is Bullet and ch.proj == "sword_wave":
			sw_before += 1
	ph._melee(kd)
	var sw_after: int = 0
	for ch in world.get_children():
		if ch is Bullet and ch.proj == "sword_wave":
			sw_after += 1
	_check(sw_before == 0 and sw_after == 1, "Đ2 cận chiến nhát 3 không phóng sword_wave: %d->%d" % [sw_before, sw_after])
	ph.queue_free()

	# Nỏ tay: Đ1 xuyên 1, Đ2 2 mũi ±6°
	Global.weapon_ranks["ly_thuong_kiet"] = 5
	var pl := Player.new()
	pl.setup("ly_thuong_kiet")
	world.add_child(pl)
	pl._shoot(pl.effective_weapon("no_tay"))
	var arrows: Array = []
	for ch in world.get_children():
		if ch is Bullet and ch.proj == "arrow":
			arrows.append(ch)
	_check(arrows.size() == 2 and arrows[0].pierce == 1, "Nỏ tay Đ1/Đ2 sai: cnt=%d" % arrows.size())
	pl.queue_free()

	# Ống lửa: Đ1 burn ×2 (4.4s), Đ2 tầm ×1.5
	Global.weapon_ranks["quang_trung"] = 5
	var pq := Player.new()
	pq.setup("quang_trung")
	world.add_child(pq)
	pq._shoot(pq.effective_weapon("ong_lua"))
	var fb: Bullet = null
	for ch in world.get_children():
		if ch is Bullet and ch.proj == "fireball":
			fb = ch
	_check(fb != null and is_equal_approx(fb.burn_duration, 4.4) and is_equal_approx(fb.life, 0.45),
		"Ống lửa Đ1/Đ2 sai: burn=%.2f life=%.2f" % [fb.burn_duration if fb else 0.0, fb.life if fb else 0.0])
	pq.queue_free()

	# Súng Yên Thế: Đ1 xuyên 1, Đ2 phát thứ 4 nổ bán kính 24
	Global.weapon_ranks["hoang_hoa_tham"] = 5
	var phh := Player.new()
	phh.setup("hoang_hoa_tham")
	world.add_child(phh)
	var cbs: Array = []
	for k in 4:
		phh._shoot(phh.effective_weapon("hoa_mai_yen_the"))
	for ch in world.get_children():
		if ch is Bullet and ch.proj == "cannonball":
			cbs.append(ch)
	_check(cbs.size() == 4 and cbs[0].pierce == 1 and is_equal_approx(cbs[0].explode_radius, 0.0) and is_equal_approx(cbs[3].explode_radius, 24.0),
		"Súng Đ1/Đ2 sai: cbs=%d r3=%.1f" % [cbs.size(), cbs[3].explode_radius if cbs.size() >= 4 else -1.0])
	phh.queue_free()
	world.queue_free()
	await _frames(2)

	print("== 6. Tệp lưu cũ thiếu hero_levels & weapon_ranks vẫn nạp được")
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 77, "unlocked": ["ngo_quyen"], "selected_hero": "ngo_quyen"}))
	f.close()
	Global.hero_levels = {"ngo_quyen": 5}
	Global.weapon_ranks = {"ngo_quyen": 5}
	Global.load_game()
	_check(Global.coins == 77 and Global.hero_level("ngo_quyen") == 1 and Global.weapon_rank("ngo_quyen") == 1,
		"tệp cũ nạp sai cấp/bậc")

	print("== 7. Mở và đóng thẻ Tu luyện trong sảnh không lỗi")
	Global.hero_levels["ngo_quyen"] = 5
	Global.weapon_ranks["ngo_quyen"] = 5
	var lb = load("res://scenes/lobby.tscn").instantiate()
	add_child(lb)
	await _frames(5)
	lb.ui.open_hero("ngo_quyen", "train")
	await _frames(3)
	_check(lb.ui.is_open(), "không mở được thẻ Tu luyện")
	var txt := _collect_texts(lb.ui._panel)
	_check(txt.has("Đã viên mãn") and txt.has("Đã thức tỉnh"), "thiếu nhãn Đã viên mãn / Đã thức tỉnh")
	lb.ui.close()
	await _frames(2)
	_check(not lb.ui.is_open(), "không đóng được thẻ Tu luyện")
	lb.queue_free()
	await _frames(2)


func _collect_texts(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	if root is Label or root is Button:
		out.append(root.text)
	for ch in root.get_children():
		out.append_array(_collect_texts(ch))
	return out
