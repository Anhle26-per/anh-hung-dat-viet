extends Node
## Kiểm thử Thương Nhân (giao diện mới, giảm giá, Hộp Kỳ Duyên, Đổi hàng) & 31 Phúc Lành mới (Soul Knight style).
## Chạy: godot --headless --path . res://tests/merchant_buffs_test.tscn -> in "MERCHANT BUFFS TEST OK"

const BuffData = preload("res://scripts/data/buffs.gd")
const BuffSelect = preload("res://scripts/ui/buff_select.gd")
const Shop = preload("res://scripts/game/shop.gd")
const ShopUI = preload("res://scripts/ui/shop_ui.gd")
const Player = preload("res://scripts/entities/player.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const SpiritBlade = preload("res://scripts/effects/spirit_blade.gd")

const TEST_SAVE := "user://merchant_buffs_test_save.json"

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _cleanup_saves() -> void:
	var paths: Array[String] = [TEST_SAVE, Global.run_path()]
	for p in paths:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _ready() -> void:
	get_tree().create_timer(40.0).timeout.connect(func():
		print("MERCHANT BUFFS TEST FAILED: quá thời gian")
		get_tree().quit(1))
	Global.save_path = TEST_SAVE
	_cleanup_saves()
	await _frames(2)
	await _run()
	_cleanup_saves()
	if _fail == 0:
		print("MERCHANT BUFFS TEST OK")
		get_tree().quit(0)
	else:
		print("MERCHANT BUFFS TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra dữ liệu 39 phúc lành & ảnh icon")
	_check(BuffData.DATA.size() == 39, "phải có đủ 39 phúc lành (hiện có %d)" % BuffData.DATA.size())
	for bid_v in BuffData.DATA:
		var bid: String = str(bid_v)
		var b: Dictionary = BuffData.DATA[bid]
		_check(b.has("cat") and BuffData.CATEGORIES.has(str(b.cat)), "thiếu hệ cho buff %s" % bid)
		_check(int(b.get("tier", 0)) in [1, 2, 3], "sai độ hiếm tier cho buff %s" % bid)
		_check(ResourceLoader.exists("res://assets/sprites/ui/buff_%s.png" % bid), "thiếu ảnh buff_%s.png" % bid)
	for rel in ["world/merchant.png", "world/stand.png", "world/shop_lantern.png", "items/potion_full.png", "items/mystery_box.png"]:
		_check(ResourceLoader.exists("res://assets/sprites/%s" % rel), "thiếu ảnh %s" % rel)

	print("== 2. Kiểm tra BuffData.offer() & BuffSelect Đổi vận")
	for _trial in 8:
		var boss_opts: Array = BuffData.offer({}, 3, true)
		_check(boss_opts.size() == 3, "offer phải trả 3 thẻ")
		var has_t3: bool = false
		for opt_v in boss_opts:
			if BuffData.tier(str(opt_v)) >= 3:
				has_t3 = true
		_check(has_t3, "boss_bonus=true phải đảm bảo ít nhất 1 thẻ Tuyệt kỹ (Tier 3)")

	Global.start_run()
	Global.run_coins = 40
	var bsel := BuffSelect.new()
	add_child(bsel)
	await _frames(2)
	var opened: bool = bsel.open("Chương kế", true)
	_check(opened and bsel.visible, "BuffSelect.open() thất bại")
	var old_opts: Array = bsel._options.duplicate()
	var rr_ok: bool = bsel.reroll()
	_check(rr_ok and Global.run_coins == 25, "Đổi vận phải trừ 15 xu (còn %d)" % Global.run_coins)
	_check(bsel._options != old_opts, "Đổi vận phải ra bộ thẻ khác")
	_check(not bsel.reroll(), "Mỗi màn chỉ được Đổi vận 1 lần")
	bsel.pick(0)
	_check(not bsel.visible, "pick(0) phải đóng BuffSelect")
	bsel.queue_free()
	await _frames(2)

	print("== 3. Kiểm tra cơ chế 14 phúc lành mới trên Player / Enemy / Bullet")
	Global.start_run()
	Global.run_coins = 180
	var p := Player.new()
	p.setup("ngo_quyen")
	add_child(p)
	await _frames(2)

	# kim_giap: 180 xu -> +3 max_armor
	var arm_before: int = p.max_armor
	p.apply_buff("kim_giap")
	_check(p.max_armor == arm_before + 3, "kim_giap với 180 xu phải tăng +3 max_armor (%d -> %d)" % [arm_before, p.max_armor])
	# Nhặt thêm 15 xu hồi 1 giáp
	p.armor = maxi(0, p.max_armor - 2)
	var cur_arm: int = p.armor
	p.on_coins_collected(15)
	_check(p.armor == cur_arm + 1, "nhặt 15 xu với kim_giap phải hồi +1 giáp")

	# xuyen_tam: +8% crit & bullet crit_pierce
	var c0: float = p.crit_chance()
	p.apply_buff("xuyen_tam")
	_check(is_equal_approx(p.crit_chance(), c0 + 0.08), "xuyen_tam phải tăng +8% crit")

	# khien_lua & khien_doc: miễn nhiễm status
	p.apply_buff("khien_lua")
	p.apply_buff("khien_doc")
	p.status.apply("burn", 2.0)
	p.status.apply("poison", 2.0)
	_check(not p.status.has("burn"), "khien_lua phải miễn nhiễm cháy")
	_check(not p.status.has("poison"), "khien_doc phải miễn nhiễm độc")

	# tich_luc: di chuyển tích 100% -> forced crit + stun + shockwave
	p.apply_buff("tich_luc")
	p._kinetic_charge = 100.0
	_check(p.is_kinetic_ready(), "is_kinetic_ready() phải true khi charge = 100")
	var en := Enemy.new()
	en.setup("bo_binh", 1, p)
	en.max_hp = 500
	en.hp = 500
	en.position = Vector2(120, 0)
	add_child(en)
	en._spawn_t = 0.0
	await _frames(2)
	en.take_damage(5)
	_check(en.last_hit_crit, "Xung kích đầy phải ép đòn kế CHÍ MẠNG")
	p.on_hit_enemy(en)
	_check(p._kinetic_charge == 0.0 and en._stun_t > 0.0, "consume_kinetic_hit phải xả charge và làm choáng giặc")

	# ngu_hanh: luân phiên gắn hiệu ứng cháy -> độc -> choáng
	p.apply_buff("ngu_hanh")
	p._elem_cd = 0.0
	p.on_hit_enemy(en) # burn
	p._elem_cd = 0.0
	p.on_hit_enemy(en) # poison
	_check(en.status.has("burn") and en.status.has("poison"), "ngu_hanh phải truyền lần lượt Hỏa và Độc")

	# phi_kiem: sinh SpiritBlade
	p.apply_buff("phi_kiem")
	await _frames(2)
	_check(p._spirit_blade != null and is_instance_valid(p._spirit_blade) and p._spirit_blade is SpiritBlade, "phi_kiem phải triệu hồi SpiritBlade")

	# noi_cong & dan_nay: bắn phát thứ 4 tạo Chưởng Kình + đạn có bounces >= 1
	p.apply_buff("dan_nay")
	p.apply_buff("noi_cong")
	p.weapons[0] = "sung_truong_bo_binh"
	p.slot = 0
	p.energy = p.max_energy
	for _s in 4:
		p._fire_timer = 0.0
		p._try_attack()
	await _frames(2)
	var saw_bounce: bool = false
	var saw_qi: bool = false
	for pb in get_tree().get_nodes_in_group("player_bullets"):
		if int(pb.get("bounces")) >= 1:
			saw_bounce = true
		if bool(pb.get("qi_wave")):
			saw_qi = true
	_check(saw_bounce, "dan_nay phải gắn bounces >= 1 cho đạn")
	_check(saw_qi, "noi_cong phát thứ 4 phải phóng Chưởng Kình (qi_wave=true)")

	# kiem_phan_dan: chém phản đạn địch
	p.apply_buff("kiem_phan_dan")
	p.weapons[0] = "kiem_dong"
	var eb := Bullet.new()
	eb.setup(false, p.global_position + Vector2(14, 0), Vector2.LEFT, 100.0, 2, 2.0, "orb_pink")
	add_child(eb)
	await _frames(1)
	p.aim_dir = Vector2.RIGHT
	p._fire_timer = 0.0
	p._try_attack()
	await _frames(2)
	var reflected: bool = false
	for pb2 in get_tree().get_nodes_in_group("player_bullets"):
		if pb2.proj == "orb_water" and int(pb2.damage) >= 6:
			reflected = true
	_check(reflected, "kiem_phan_dan phải phản ngược đạn địch thành đạn của người chơi")

	# hut_nang_luong & huyet_nguyet: hạ giặc hồi 10 NL + bật cuồng chiến 3.5s
	p.apply_buff("hut_nang_luong")
	p.apply_buff("huyet_nguyet")
	p.energy = 10
	p.on_kill(p.global_position)
	_check(p.energy == 20, "hut_nang_luong phải hồi 10 NL khi hạ giặc")
	_check(p._frenzy_timer > 3.0, "huyet_nguyet phải kích hoạt Cuồng chiến 3.5s")

	# Đảm bảo không buff mới nào làm hỏng kiểm thử chết ở smoke_test
	p._invuln = 0.0
	p.armor = 0
	p.take_damage(999)
	_check(p.dead, "đòn 999 sát thương khi giáp=0 phải giết được người chơi")
	en.queue_free()
	p.queue_free()
	await _frames(2)

	print("== 4. Kiểm tra Sạp Thương Nhân mới, Hộp Kỳ Duyên, giảm giá -30% & ShopUI")
	Global.start_run()
	Global.run_coins = 500
	var p2 := Player.new()
	p2.setup("ngo_quyen")
	add_child(p2)
	await _frames(2)

	var sh := Shop.new()
	sh.level = 2
	sh.room_key = "shop_test"
	sh.position = Vector2(200, 120)
	add_child(sh)
	await _frames(2)
	_check(sh.stands.size() == 3, "Sạp solo phải có đúng 3 kệ hàng trong stands (%d)" % sh.stands.size())
	_check(sh._vendor_npc != null and not sh.stands.has(sh._vendor_npc), "NPC Thương nhân không được nằm trong shop.stands")

	# Kiểm tra tương tác kệ hàng không bị NPC cản
	var st0 = sh.stands[0]
	p2.global_position = st0.global_position + Vector2(0, 4)
	await _frames(3)
	_check(p2.interact_target == st0, "đứng gần kệ hàng phải nhận đúng shop_stand, không bị vendor cản")

	# Áp Khách quý: giảm 30% giá và Đổi hàng lần 1 miễn phí
	var raw_p: int = st0.base_price
	p2.apply_buff("thuong_khach")
	await _frames(2)
	_check(st0.price == maxi(1, int(round(float(raw_p) * 0.7))), "thuong_khach phải giảm 30%% giá kệ (%d -> %d)" % [raw_p, st0.price])
	_check(sh.reroll_cost() == 0, "thuong_khach phải cho Đổi hàng lần 1 miễn phí")

	# Thử Hộp Kỳ Duyên trừ đúng st.price tức thời
	st0.setup_good("mystery", "mystery_box", 2)
	var before_mys: int = Global.run_coins
	st0.interact()
	_check(st0.sold and Global.run_coins == before_mys - st0.price, "mua Hộp Kỳ Duyên phải sold=true và trừ đúng st0.price")

	# Mở ShopUI, thử đổi hàng miễn phí + đóng UI
	var sui := ShopUI.new()
	sui.shop = sh
	add_child(sui)
	await _frames(2)
	_check(not get_tree().get_nodes_in_group("shop_ui_open").is_empty(), "ShopUI phải nằm trong group shop_ui_open")
	var rr_free: bool = sh.try_reroll()
	_check(rr_free and sh.reroll_count == 1, "Đổi hàng qua sạp phải hoạt động")
	sui.close()
	sh.queue_free()
	p2.queue_free()
	await _frames(2)
