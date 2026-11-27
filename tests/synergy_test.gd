extends Node
## Kiểm thử thẻ G18: 67 vũ khí đủ hệ, Đồng điệu (0/1/2) cho 10 tướng, 6 Ấn hệ, giữ mức khi đổi vũ khí.
## Chạy: godot --headless --path . res://tests/synergy_test.tscn -> in "SYNERGY TEST OK"

const SynergyData = preload("res://scripts/data/synergy.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const Player = preload("res://scripts/entities/player.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Stake = preload("res://scripts/entities/stake.gd")
const Ally = preload("res://scripts/entities/ally.gd")
const FireZone = preload("res://scripts/effects/fire_zone.gd")
const WaveRing = preload("res://scripts/effects/wave_ring.gd")
const OrbitBlades = preload("res://scripts/effects/orbit_blades.gd")
const ReflectRing = preload("res://scripts/effects/reflect_ring.gd")
const Turret = preload("res://scripts/effects/turret.gd")

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(func():
		print("SYNERGY TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0:
		print("SYNERGY TEST OK")
		get_tree().quit(0)
	else:
		print("SYNERGY TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _spawn_hero(hid: String, wid: String) -> Array:
	var w := Node2D.new()
	add_child(w)
	var p := Player.new()
	p.setup(hid)
	p.weapons = [wid, "kiem"]
	p.slot = 0
	w.add_child(p)
	return [w, p]


func _run() -> void:
	print("== 1. Đủ 217 vũ khí có hệ hợp lệ (FAMILIES không trùng + family() fallback)")
	var seen := {}
	for fam in SynergyData.FAMILY_ORDER:
		for wid in SynergyData.FAMILIES[fam].weapons:
			_check(not seen.has(wid), "vũ khí trùng hệ: " + str(wid))
			seen[wid] = fam
	for wid in WeaponData.DATA:
		var f: String = SynergyData.family(str(wid))
		_check(f in SynergyData.FAMILY_ORDER, "vũ khí thiếu hệ: " + str(wid))
	_check(WeaponData.DATA.size() >= 217, "số vũ khí = %d (kỳ vọng >= 217)" % WeaponData.DATA.size())

	print("== 2. SynergyData.level() đúng cho cả 10 tướng")
	for hid in HeroData.ORDER:
		var base_w: String = str(HeroData.DATA[hid].weapon)
		_check(SynergyData.level(hid, base_w) == 2, "%s khởi đầu != 2" % hid)
		_check(SynergyData.level(hid, "trong_dong") == 1, "%s thần khí != 1" % hid)
		var base_fam: String = SynergyData.family(base_w)
		var same_w := ""
		var diff_w := ""
		var sig: String = SynergyData.signature_for(hid)
		for wid in WeaponData.DATA:
			if wid == base_w or wid == sig:
				continue
			var f: String = SynergyData.family(wid)
			if same_w == "" and f == base_fam:
				same_w = str(wid)
			if diff_w == "" and f != base_fam and f != "than_khi":
				diff_w = str(wid)
		_check(SynergyData.level(hid, same_w) == 1, "%s cùng hệ %s != 1" % [hid, same_w])
		_check(SynergyData.level(hid, diff_w) == 0, "%s khác hệ %s != 0" % [hid, diff_w])
		if sig != "":
			_check(SynergyData.level(hid, sig) == 2, "%s định mệnh %s != 2" % [hid, sig])

	print("== 3. Đo khác biệt mức 0 và mức 2 cho cả 10 tướng")
	# 1) hai_ba_trung: thời gian Song Trưng 8 vs 11
	var r0 := _spawn_hero("hai_ba_trung", "sung_ngan")
	r0[1]._use_skill()
	var t0: float = r0[1].twin_timer
	r0[0].queue_free()
	var r2 := _spawn_hero("hai_ba_trung", "kiem_dong")
	r2[1]._use_skill()
	var t2: float = r2[1].twin_timer
	_check(is_equal_approx(t0, 8.0) and is_equal_approx(t2, 11.0), "Song Trưng %.1f vs %.1f" % [t0, t2])
	_check(r2[1].last_skill_syn == 2 and r2[1].last_skill_imprint == "kiem", "HBT thiếu Tâm đắc / Ấn")
	r2[0].queue_free()

	# 2) ba_trieu: sát thương voi 10 vs 16 + hồi giáp
	var bt0 := _spawn_hero("ba_trieu", "sung_ngan")
	var eb0 := Enemy.new()
	eb0.setup("bo_binh", 5, bt0[1])
	eb0.position = Vector2(10, 0)
	bt0[0].add_child(eb0)
	eb0._spawn_t = 0.0
	bt0[1]._use_skill()
	bt0[1]._dash_damage()
	var dmg0: int = eb0.max_hp - eb0.hp
	bt0[0].queue_free()
	await _frames(2)
	var bt2 := _spawn_hero("ba_trieu", "doan_dao")
	bt2[1].armor = 1
	bt2[1]._armor_regen = 5.0
	var eb2 := Enemy.new()
	eb2.setup("bo_binh", 5, bt2[1])
	eb2.position = Vector2(10, 0)
	bt2[0].add_child(eb2)
	eb2._spawn_t = 0.0
	bt2[1]._use_skill()
	bt2[1]._dash_damage()
	var dmg2: int = eb2.max_hp - eb2.hp
	_check(dmg0 == 10 and dmg2 == 16 and bt2[1].armor == 2, "Voi chiến dmg %d/%d armor=%d" % [dmg0, dmg2, bt2[1].armor])
	bt2[0].queue_free()

	# 3) ngo_quyen: số cọc 14 vs 22 và life 6 vs 9
	var nq0 := _spawn_hero("ngo_quyen", "sung_ngan")
	nq0[1]._use_skill()
	await get_tree().create_timer(0.75).timeout
	var st0: Array = []
	for ch in nq0[0].get_children():
		if ch is Stake:
			st0.append(ch)
	nq0[0].queue_free()
	var nq2 := _spawn_hero("ngo_quyen", "giao_tre")
	nq2[1]._use_skill()
	await get_tree().create_timer(0.75).timeout
	var st2: Array = []
	for ch in nq2[0].get_children():
		if ch is Stake:
			st2.append(ch)
	_check(st0.size() == 14 and st2.size() == 22, "Số cọc %d vs %d" % [st0.size(), st2.size()])
	if not st2.is_empty():
		_check(is_equal_approx(st2[0].life_time, 9.0) and is_equal_approx(st2[0].stun_time, 1.0), "Cọc bền/choáng sai")
	nq2[0].queue_free()

	# 4) ly_thuong_kiet: bật ngược dmg mult 1.0 vs 2.0 + pierce
	var lt0 := _spawn_hero("ly_thuong_kiet", "dao_gam")
	lt0[1]._use_skill()
	var rr0: ReflectRing = null
	for ch in lt0[1].get_children():
		if ch is ReflectRing:
			rr0 = ch
	lt0[0].queue_free()
	var lt2 := _spawn_hero("ly_thuong_kiet", "no_tay")
	lt2[1]._use_skill()
	var rr2: ReflectRing = null
	for ch in lt2[1].get_children():
		if ch is ReflectRing:
			rr2 = ch
	_check(rr0 != null and is_equal_approx(rr0.damage_mult, 1.0) and rr2 != null and is_equal_approx(rr2.damage_mult, 2.0) and rr2.pierce_bonus == 1, "Lý Thường Kiệt bật đạn sai")
	lt2[0].queue_free()

	# 5) tran_hung_dao: 3 vs 4 binh sĩ, dmg 3 vs 5
	var th0 := _spawn_hero("tran_hung_dao", "sung_ngan")
	th0[1]._use_skill()
	await get_tree().create_timer(0.9).timeout
	var al0: Array = []
	for ch in th0[0].get_children():
		if ch is Ally:
			al0.append(ch)
	th0[0].queue_free()
	var th2 := _spawn_hero("tran_hung_dao", "guom_lenh")
	th2[1]._use_skill()
	await get_tree().create_timer(0.9).timeout
	var al2: Array = []
	for ch in th2[0].get_children():
		if ch is Ally:
			al2.append(ch)
	_check(al0.size() == 3 and al2.size() == 4, "Số binh sĩ %d vs %d" % [al0.size(), al2.size()])
	if not al2.is_empty():
		_check(al2[0].damage == 5 and al2[0].focus_player_target, "Binh sĩ mức 2 dmg/focus sai")
	th2[0].queue_free()

	# 6) le_loi: 3 vs 5 gươm
	var ll0 := _spawn_hero("le_loi", "sung_ngan")
	ll0[1]._use_skill()
	var ob0: OrbitBlades = null
	for ch in ll0[1].get_children():
		if ch is OrbitBlades:
			ob0 = ch
	ll0[0].queue_free()
	var ll2 := _spawn_hero("le_loi", "con_lam_son")
	ll2[1]._use_skill()
	var ob2: OrbitBlades = null
	for ch in ll2[1].get_children():
		if ch is OrbitBlades:
			ob2 = ch
	_check(ob0 != null and ob0.count == 3 and ob2 != null and ob2.count == 5 and ob2.launch_on_melee, "Lê Lợi gươm %d vs %d" % [ob0.count, ob2.count])
	ll2[0].queue_free()

	# 7) quang_trung: tầm hỏa khí ×1 vs ×2
	var qt0 := _spawn_hero("quang_trung", "dao_gam")
	qt0[1]._use_skill()
	qt0[1].weapons[0] = "hoa_ho"
	qt0[1]._try_attack()
	var life_m0: float = 0.0
	for ch in qt0[0].get_children():
		if ch is Bullet and ch.proj == "fireball":
			life_m0 = ch.life
			break
	qt0[0].queue_free()
	var qt2 := _spawn_hero("quang_trung", "ong_lua")
	qt2[1]._use_skill()
	qt2[1].weapons[0] = "hoa_ho"
	qt2[1]._try_attack()
	var life_m2: float = 0.0
	for ch in qt2[0].get_children():
		if ch is Bullet and ch.proj == "fireball":
			life_m2 = ch.life
			break
	_check(life_m0 > 0.0 and is_equal_approx(life_m2, life_m0 * 2.0), "Quang Trung tầm lửa %.2f vs %.2f" % [life_m0, life_m2])
	qt2[0].queue_free()

	# 8) nguyen_trung_truc: số bầu lửa 8 vs 12
	var nt0 := _spawn_hero("nguyen_trung_truc", "sung_ngan")
	nt0[1]._use_skill()
	var fz0: int = 0
	for ch in nt0[0].get_children():
		if ch is FireZone:
			fz0 += 1
	nt0[0].queue_free()
	var nt2 := _spawn_hero("nguyen_trung_truc", "dao_rua")
	nt2[1]._use_skill()
	var fz2: int = 0
	for ch in nt2[0].get_children():
		if ch is FireZone and not ch.instant:
			fz2 += 1
	_check(fz0 == 8 and fz2 == 12, "Bầu lửa NTT %d vs %d" % [fz0, fz2])
	nt2[0].queue_free()

	# 9) hoang_hoa_tham: số phát không nạp (0 vs 3 phát liên tiếp)
	var hh0 := _spawn_hero("hoang_hoa_tham", "kiem_dong")
	hh0[1]._use_skill()
	hh0[1].weapons[0] = "hoa_mai_yen_the"
	for k in 3:
		hh0[1]._try_attack()
	var shots0: int = 0
	for ch in hh0[0].get_children():
		if ch is Bullet and ch.proj == "cannonball":
			shots0 += 1
	hh0[0].queue_free()
	var hh2 := _spawn_hero("hoang_hoa_tham", "hoa_mai_yen_the")
	hh2[1]._use_skill()
	for k in 3:
		hh2[1]._try_attack()
	var shots2: int = 0
	for ch in hh2[0].get_children():
		if ch is Bullet and ch.proj == "cannonball":
			shots2 += 1
	_check(shots0 == 1 and shots2 == 3, "Hùm thiêng phát liên tiếp %d vs %d" % [shots0, shots2])
	hh2[0].queue_free()

	# 10) chien_si_dien_bien: tốc độ pháo 0.7 vs 0.5 + marked
	var cs0 := _spawn_hero("chien_si_dien_bien", "kiem_dong")
	cs0[1]._use_skill()
	var tu0: Turret = null
	for ch in cs0[0].get_children():
		if ch is Turret:
			tu0 = ch
	cs0[0].queue_free()
	var cs2 := _spawn_hero("chien_si_dien_bien", "sung_truong_bo_binh")
	cs2[1]._use_skill()
	var tu2: Turret = null
	for ch in cs2[0].get_children():
		if ch is Turret:
			tu2 = ch
	_check(tu0 != null and is_equal_approx(tu0.fire_cd, 0.7) and tu2 != null and is_equal_approx(tu2.fire_cd, 0.5) and tu2.use_marked, "Pháo CD sai")
	cs2[0].queue_free()
	await _frames(2)

	print("== 4. Đo 6 Ấn hệ + giữ mức/hiệu ứng khi đổi vũ khí")
	# Kiếm khí: 6 sword_wave
	var ik := _spawn_hero("ngo_quyen", "kiem")
	ik[1]._use_skill()
	var sw_cnt: int = 0
	for ch in ik[0].get_children():
		if ch is Bullet and ch.proj == "sword_wave":
			sw_cnt += 1
	_check(sw_cnt == 6, "Ấn Kiếm khí số sóng = %d" % sw_cnt)
	ik[0].queue_free()

	# Trấn địa: WaveRing có choáng 0.6s
	var it := _spawn_hero("hai_ba_trung", "giao")
	it[1]._use_skill()
	var wr_node: WaveRing = null
	for ch in it[0].get_children():
		if ch is WaveRing:
			wr_node = ch
	_check(wr_node != null and is_equal_approx(wr_node.stun, 0.6) and is_equal_approx(wr_node.radius, 60.0), "Ấn Trấn địa sai")
	it[0].queue_free()

	# Hỏa ấn: 3 FireZone
	var ih := _spawn_hero("ngo_quyen", "phao_dong")
	ih[1]._use_skill()
	var fz_imp: int = 0
	for ch in ih[0].get_children():
		if ch is FireZone:
			fz_imp += 1
	_check(fz_imp == 3, "Ấn Hỏa ấn số vùng = %d" % fz_imp)
	ih[0].queue_free()

	# Linh khí: +40 năng lượng & hồi chiêu giảm 30%
	var il := _spawn_hero("hai_ba_trung", "trong_dong")
	il[1].energy = 50
	il[1]._use_skill()
	var exp_cd: float = float(HeroData.DATA["hai_ba_trung"].skill_cd) * 0.7
	_check(il[1].energy == 90 and is_equal_approx(il[1].skill_timer, exp_cd),
		"Ấn Linh khí energy=%d cd=%.2f (kỳ vọng %.2f)" % [il[1].energy, il[1].skill_timer, exp_cd])
	il[0].queue_free()

	# Mưa tên: 12 mũi tên trong 1.5s
	var ic := _spawn_hero("hai_ba_trung", "cung")
	var arrow_seen: Array = []
	ic[1]._use_skill()
	for step in 16:
		await get_tree().create_timer(0.1).timeout
		for b in get_tree().get_nodes_in_group("imprint_arrows"):
			var bid: int = b.get_instance_id()
			if not arrow_seen.has(bid):
				arrow_seen.append(bid)
	_check(arrow_seen.size() == 12, "Ấn Mưa tên số mũi tên = %d" % arrow_seen.size())
	ic[0].queue_free()

	# Nạp đạn thần tốc + đổi vũ khí giữa chừng không tắt hiệu ứng & không mất mức
	var isg := _spawn_hero("quang_trung", "sung_ngan")
	isg[1].weapons = ["sung_ngan", "ong_lua"]
	isg[1]._use_skill()
	_check(is_equal_approx(isg[1].rapid_reload_timer, 4.0), "Nạp đạn thần tốc không bật 4s")
	isg[1]._fire_timer = 0.0
	isg[1]._try_attack()
	var fast_cd: float = isg[1]._fire_timer
	var base_cd: float = float(WeaponData.get_data("sung_ngan").cooldown)
	_check(fast_cd < base_cd * 0.85, "Nạp đạn thần tốc không tăng tốc bắn: %.3f vs %.3f" % [fast_cd, base_cd])
	# Đổi sang vũ khí khác giữa chừng
	isg[1].swap_weapon()
	_check(isg[1].rapid_reload_timer > 3.5, "Đổi vũ khí làm mất Nạp đạn thần tốc")
	isg[1]._fire_timer = 0.0
	# Hết 4s quay lại bình thường
	await get_tree().create_timer(4.1).timeout
	_check(isg[1].rapid_reload_timer <= 0.0, "Nạp đạn thần tốc không hết sau 4s")
	isg[1]._fire_timer = 0.0
	isg[1].weapons[1] = "sung_ngan"
	isg[1]._try_attack()
	_check(is_equal_approx(isg[1]._fire_timer, base_cd * 0.5 if isg[1].buff_timer > 0.0 else base_cd),
		"Tốc bắn không trở lại bình thường sau 4s: %.3f" % isg[1]._fire_timer)
	isg[0].queue_free()
	await _frames(3)
