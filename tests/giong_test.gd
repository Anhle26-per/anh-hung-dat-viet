extends Node
## Kiểm thử thẻ G09: Tướng ẩn Thánh Gióng, kỹ năng Ngựa sắt phun lửa, đồng điệu,
## tiến triển Gậy tre bậc 1–5 và 4 bùa vũ khí (WeaponMods) trong player.gd & bullet.gd.
## Chạy: godot --headless --path . res://tests/giong_test.tscn -> in "GIONG TEST OK"

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const Player = preload("res://scripts/entities/player.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const FireZone = preload("res://scripts/effects/fire_zone.gd")
const Art = preload("res://scripts/art/art.gd")
const TEST_SAVE := "user://giong_test_save.json"

var _fail: int = 0
var _completed: bool = false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _phys_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wipe() -> void:
	for p in [TEST_SAVE, TEST_SAVE + ".tmp", TEST_SAVE.get_basename() + "_run.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	get_tree().create_timer(30.0).timeout.connect(func():
		print("GIONG TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	_wipe()
	if _fail == 0 and _completed:
		print("GIONG TEST OK")
		get_tree().quit(0)
	else:
		print("GIONG TEST FAILED: %d lỗi (completed=%s)" % [_fail, str(_completed)])
		get_tree().quit(1)


func _spawn_giong(wid: String) -> Array:
	var w := Node2D.new()
	add_child(w)
	var p := Player.new()
	p.setup("thanh_giong")
	p.weapons = [wid, ""]
	p.slot = 0
	p.aim_dir = Vector2.RIGHT
	w.add_child(p)
	return [w, p]


func _run() -> void:
	Global.weapon_ranks = {}
	Global.hero_levels = {}
	Global.upgrades = {}
	Global.run_buffs = {}
	if Global.has_method("set_weapon_mod"):
		Global.run_weapon_mods = {}

	print("== 1. Kiểm tra dữ liệu Thánh Gióng trong HeroData")
	_check(HeroData.ORDER.size() == 11, "số tướng phải là 11 (thực tế: %d)" % HeroData.ORDER.size())
	_check(HeroData.ORDER.has("thanh_giong"), "thiếu thanh_giong trong ORDER")
	_check(HeroData.DATA.has("thanh_giong"), "thiếu thanh_giong trong DATA")
	var hd: Dictionary = HeroData.DATA["thanh_giong"]
	_check(str(hd.get("weapon", "")) == "gay_tre", "vũ khí khởi đầu phải là gay_tre")
	_check(str(hd.get("skill", "")) == "ngua_sat", "kỹ năng phải là ngua_sat")
	_check(bool(hd.get("secret", false)), "secret phải là true")
	_check(int(hd.get("unlock_level", 0)) == 6, "unlock_level phải là 6")
	_check(Art.tex("heroes/thanh_giong.png") != null, "thiếu heroes/thanh_giong.png")
	_check(Art.tex("ui/skill_ngua_sat.png") != null, "thiếu ui/skill_ngua_sat.png")
	_check(Art.tex("fx/iron_horse.png") != null, "thiếu fx/iron_horse.png")

	print("== 2. Kiểm tra Đồng điệu (Synergy lv0/1/2) cho Thánh Gióng")
	_check(SynergyData.level("thanh_giong", "gay_tre") == 2, "gay_tre phải đồng điệu cấp 2")
	_check(SynergyData.level("thanh_giong", "roi_sat_giong") == 2, "roi_sat_giong phải đồng điệu cấp 2")
	_check(SynergyData.level("thanh_giong", "giao") == 1, "giao (cùng hệ côn thương) phải cấp 1")
	_check(SynergyData.level("thanh_giong", "trong_dong") == 1, "trong_dong (thần khí) phải cấp 1")
	_check(SynergyData.level("thanh_giong", "sung_ngan") == 0, "sung_ngan (khác hệ) phải cấp 0")

	print("== 3. Kiểm tra Progression Gậy tre bậc 1..5 & _b3/_b5 + sóng lửa bậc 5")
	_check(ProgressionData.TRAITS.has("gay_tre"), "thiếu gay_tre trong ProgressionData.TRAITS")
	_check(ProgressionData.weapon_texture_path("gay_tre", 3) == "weapons/gay_tre_b3.png", "đường dẫn _b3 sai")
	_check(ProgressionData.weapon_texture_path("gay_tre", 5) == "weapons/gay_tre_b5.png", "đường dẫn _b5 sai")
	_check(Art.tex("weapons/gay_tre_b3.png") != null, "thiếu ảnh weapons/gay_tre_b3.png")
	_check(Art.tex("weapons/gay_tre_b5.png") != null, "thiếu ảnh weapons/gay_tre_b5.png")
	var pair_prog: Array = _spawn_giong("gay_tre")
	var wp: Node2D = pair_prog[0]
	var pp: Player = pair_prog[1]
	var exp_dmg: Array = [0, 4, 5, 6, 8, 9]
	for r in [1, 2, 3, 4, 5]:
		Global.weapon_ranks["thanh_giong"] = r
		var ew: Dictionary = pp.effective_weapon("gay_tre")
		_check(int(ew.damage) == int(exp_dmg[r]), "gay_tre bậc %d dmg=%d (kỳ vọng %d)" % [r, int(ew.damage), int(exp_dmg[r])])
	Global.weapon_ranks["thanh_giong"] = 3
	var ew3: Dictionary = pp.effective_weapon("gay_tre")
	_check(is_equal_approx(float(ew3.reach), 40.0 * 1.15), "gay_tre Đ1 reach=%.2f" % float(ew3.reach))
	Global.weapon_ranks["thanh_giong"] = 5
	var ew5: Dictionary = pp.effective_weapon("gay_tre")
	_check(bool(ew5.get("trait_wave3", false)) and bool(ew5.get("trait_fire_wave", false)), "gay_tre Đ2 thiếu trait_wave3/trait_fire_wave")
	pp._melee(ew5)
	pp._melee(ew5)
	pp._melee(ew5)
	var fire_wave: Bullet = null
	for ch in wp.get_children():
		if ch is Bullet and ch.proj == "sword_wave":
			fire_wave = ch
	_check(fire_wave != null and fire_wave.force_burn, "nhát 3 gay_tre bậc 5 phải phóng sóng lửa có force_burn=true")
	wp.queue_free()
	Global.weapon_ranks = {}
	await _frames(2)

	print("== 4. Kiểm tra kỹ năng Ngựa sắt phun lửa (lv0/1/2, húc + cháy, rải lửa lv2, bất tử)")
	for cfg in [["sung_ngan", 0, 3, 10], ["giao", 1, 5, 13], ["gay_tre", 2, 8, 16]]:
		var wid: String = str(cfg[0])
		var exp_syn: int = int(cfg[1])
		var exp_fb: int = int(cfg[2])
		var exp_ram: int = int(cfg[3])
		var sp: Array = _spawn_giong(wid)
		var w0: Node2D = sp[0]
		var p0: Player = sp[1]
		var e0 := Enemy.new()
		e0.setup("bo_binh", 5, p0)
		e0.max_hp = 80
		e0.hp = 80
		e0.position = Vector2(10, 0)
		w0.add_child(e0)
		e0._spawn_t = 0.0
		await _frames(1)
		var hp_before: int = p0.hp
		var armor_before: int = p0.armor
		p0._use_skill()
		_check(p0.last_skill_syn == exp_syn, "syn %s = %d (kỳ vọng %d)" % [wid, p0.last_skill_syn, exp_syn])
		_check(p0._horse_time > 0.0, "ngua_sat phải bật _horse_time > 0")
		_check(p0._invuln > 0.0, "ngua_sat phải bật _invuln > 0")
		p0.take_damage(4)
		_check(p0.hp == hp_before and p0.armor == armor_before, "đang cưỡi ngựa sắt phải bất tử")
		var fb_cnt: int = 0
		for ch in w0.get_children():
			if ch is Bullet and ch.proj == "fireball":
				fb_cnt += 1
		_check(fb_cnt == exp_fb, "ngua_sat syn=%d phải phun %d cầu lửa (thực tế: %d)" % [exp_syn, exp_fb, fb_cnt])
		var e0_hp_pre_ram: int = e0.hp
		p0._horse_damage()
		var ram_dealt: int = e0_hp_pre_ram - e0.hp
		_check(ram_dealt == exp_ram, "ngua_sat syn=%d húc gây %d dmg (kỳ vọng %d)" % [exp_syn, ram_dealt, exp_ram])
		_check(e0.status.has("burn"), "ngua_sat húc phải gây trạng thái cháy")
		if exp_syn == 2:
			await _phys_frames(15)
			var fz_cnt: int = 0
			for ch in w0.get_children():
				if ch is FireZone:
					fz_cnt += 1
			_check(fz_cnt >= 1, "ngua_sat syn=2 phải rải FireZone dọc đường")
		w0.queue_free()
		await _frames(2)

	print("== 5. Kiểm tra 4 WeaponMods trên effective_weapon + Hỏa thạch gây cháy (bắn & cận chiến)")
	var mp: Array = _spawn_giong("sung_ngan")
	var wm: Node2D = mp[0]
	var pm: Player = mp[1]
	var base_gun: Dictionary = WeaponData.get_data("sung_ngan")
	Global.set_weapon_mod("sung_ngan", "da_mai")
	var w_dm: Dictionary = pm.effective_weapon("sung_ngan")
	_check(int(w_dm.damage) == int(base_gun.damage) + 2, "da_mai phải +2 dmg")

	Global.set_weapon_mod("sung_ngan", "ngoc_tiet_kiem")
	var w_ntk: Dictionary = pm.effective_weapon("sung_ngan")
	_check(int(w_ntk.energy) == maxi(0, int(base_gun.energy) - 1), "ngoc_tiet_kiem phải -1 energy")
	Global.set_weapon_mod("gay_tre", "ngoc_tiet_kiem")
	var w_ntk0: Dictionary = pm.effective_weapon("gay_tre")
	_check(int(w_ntk0.energy) == 0, "ngoc_tiet_kiem không được âm energy")

	Global.set_weapon_mod("sung_ngan", "long_chim")
	var w_lc: Dictionary = pm.effective_weapon("sung_ngan")
	_check(is_equal_approx(float(w_lc.cooldown), float(base_gun.cooldown) * 0.83), "long_chim phải giảm cd * 0.83")

	# Hỏa thạch trên súng: đạn có force_burn và gây cháy khi trúng giặc
	Global.set_weapon_mod("sung_ngan", "hoa_thach")
	var w_ht: Dictionary = pm.effective_weapon("sung_ngan")
	_check(bool(w_ht.get("mod_fire", false)), "hoa_thach phải đặt mod_fire=true")
	pm._shoot(w_ht)
	var mod_b: Bullet = null
	for ch in wm.get_children():
		if ch is Bullet and ch.proj == "bullet":
			mod_b = ch
	_check(mod_b != null and mod_b.force_burn, "đạn từ vũ khí gắn Hỏa thạch phải có force_burn=true")
	var e_ranged := Enemy.new()
	e_ranged.setup("bo_binh", 5, pm)
	e_ranged.max_hp = 80
	e_ranged.hp = 80
	e_ranged.position = Vector2(80, 0)
	wm.add_child(e_ranged)
	e_ranged._spawn_t = 0.0
	await _frames(1)
	if mod_b != null and is_instance_valid(mod_b):
		mod_b._on_body_entered(e_ranged)
	_check(e_ranged.status.has("burn"), "đạn Hỏa thạch trúng giặc phải gây cháy")

	# Hỏa thạch trên cận chiến: _melee gây cháy trực tiếp
	Global.set_weapon_mod("gay_tre", "hoa_thach")
	var e_melee := Enemy.new()
	e_melee.setup("bo_binh", 5, pm)
	e_melee.max_hp = 80
	e_melee.hp = 80
	e_melee.position = Vector2(20, 0)
	wm.add_child(e_melee)
	e_melee._spawn_t = 0.0
	await _frames(1)
	pm.weapons[0] = "gay_tre"
	pm._melee(pm.effective_weapon("gay_tre"))
	_check(e_melee.status.has("burn"), "cận chiến Hỏa thạch đánh trúng giặc phải gây cháy")
	Global.run_weapon_mods = {}
	wm.queue_free()
	await _frames(2)

	print("== 6. Kiểm tra tự động mở khóa Thánh Gióng ở sảnh khi best_level >= 6")
	Global.unlocked.erase("thanh_giong")
	Global.best_level = 6
	var lb = load("res://scenes/lobby.tscn").instantiate()
	add_child(lb)
	await _frames(4)
	_check(Global.unlocked.has("thanh_giong"), "vào sảnh với best_level >= 6 phải tự mở khóa thanh_giong")
	lb.queue_free()
	await _frames(2)

	_completed = true
