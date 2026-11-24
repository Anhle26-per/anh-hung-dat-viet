extends Node
## Kiểm thử tự động: 10 tướng (mỗi tướng thử chiêu), cả 67 vũ khí,
## đủ 10 chương / 10 trùm (kể cả chiêu đặc biệt của trùm), chết rồi hồi sinh.
## Chạy: godot --headless --path . res://tests/smoke_test.tscn

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")

var _fail := 0


func _ready() -> void:
	# dùng tệp lưu riêng và trạng thái sạch, không đụng tệp lưu của người chơi
	Global.save_path = "user://smoke_test_save.json"
	Global.coins = 0
	Global.upgrades = {}
	Global.discovered = []
	Global.stats = {"runs": 0, "kills": 0, "bosses": 0}
	# tự dừng nếu bị treo quá 12 phút
	get_tree().create_timer(1800.0, true, false, true).timeout.connect(func():
		print("SMOKE TEST FAILED: quá thời gian")
		get_tree().quit(2))
	_run.call_deferred()


var _shops := 0
var _chests := 0
var _last_boss_enraged := false
var _boss_hp: Array = []
var _legends := {}
var _morphs := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run() -> void:
	# Các màn hình menu mở được
	for path in ["res://scenes/main_menu.tscn", "res://scenes/hero_select.tscn"]:
		var scene = load(path)
		_check(scene != null, "không mở được " + path)
		if scene != null:
			var s = scene.instantiate()
			add_child(s)
			await _frames(3)
			s.queue_free()
			await _frames(1)

	# Sảnh chính: mở mọi điểm tương tác, mua nâng cấp, đổi tướng, đánh hình nhân
	var lobby = load("res://scenes/lobby.tscn").instantiate()
	add_child(lobby)
	await _frames(10)
	for s in lobby.stations:
		if s.visible:
			s.interact()
			await _frames(3)
			_check(lobby.ui.is_open(), "không mở được bảng " + s.kind)
			lobby.ui.close()
			await _frames(2)
	Global.coins += 2000
	_check(Global.try_upgrade("mau"), "không mua được nâng cấp")
	lobby.select_hero("ba_trieu")
	await _frames(5)
	_check(lobby.player.hero_id == "ba_trieu", "không đổi được tướng trong sảnh")
	var dummies := get_tree().get_nodes_in_group("enemies")
	_check(dummies.size() >= 2, "thiếu hình nhân tập võ")
	lobby.player.global_position = dummies[0].global_position + Vector2(-20, 0)
	for i in 5:
		lobby.player._fire_timer = 0.0
		lobby.player.aim_dir = Vector2.RIGHT
		lobby.player._try_attack()
		await _frames(4)
	lobby.queue_free()
	await _frames(3)

	for hi in HeroData.ORDER.size():
		var hero_id: String = HeroData.ORDER[hi]
		print("== Thử tướng: ", hero_id)
		Global.selected_hero = hero_id
		Global.start_run()
		Global.legend_chance = 1.0 if hi == 0 else 0.0
		var scene = load("res://scenes/game.tscn")
		if scene == null:
			print("SMOKE TEST FAILED: không nạp được game.tscn")
			get_tree().quit(1)
			return
		var game = scene.instantiate()
		add_child(game)
		await _frames(5)
		var p = game.player

		# Mọi vũ khí đều đánh/bắn được (thử 1 lần với tướng đầu)
		for wid in (WeaponData.DATA.keys() if hi == 0 else []):
			p.weapons[0] = wid
			p.slot = 0
			p.energy = p.max_energy
			p._fire_timer = 0.0
			p._try_attack()
			await _frames(3)
		p.weapons[0] = HeroData.DATA[hero_id].weapon

		# Kỹ năng
		p.skill_timer = 0.0
		p._use_skill()
		_check(p.skill_timer > 0.0, "kỹ năng không chạy: " + hero_id)
		await _frames(40)
		_check(p.skill_timer > 0.0, "kỹ năng chưa hồi chiêu")

		# Nhặt vũ khí + đổi ô
		var pk = load("res://scripts/entities/pickup.gd").new()
		pk.kind = "weapon"
		pk.weapon_id = "no_lien_chau"
		pk.position = p.global_position
		game.world.add_child(pk)
		await _frames(3)
		_check(p.nearby_pickup == pk, "không phát hiện vũ khí dưới chân")
		p._swap_or_pickup()
		_check(p.weapons[1] == "no_lien_chau", "không nhặt được vũ khí")
		p._swap_or_pickup()
		_check(p.slot == 0, "không đổi được vũ khí")

		# Trạng thái: trúng độc / cháy trừ giáp rồi máu; chướng khí gây độc
		if hi == 0:
			p.armor = 0
			p.hp = p.max_hp
			p._armor_regen = 99.0
			p.status.apply("poison", 2.0)
			await _frames(70)
			_check(p.hp < p.max_hp, "trúng độc không mất máu")
			p.status.clear()
			p.hp = p.max_hp
			var m = load("res://scripts/effects/miasma.gd").new()
			m.position = p.global_position
			game.world.add_child(m)
			await _frames(40)
			_check(p.status.has("poison"), "chướng khí không gây độc")
			p.status.clear()
			p.hp = p.max_hp
			p.armor = p.max_armor

		# Tướng đầu đi hết 10 chương (30 màn, 10 trùm), các tướng khác đánh 1 màn
		var levels := 30 if hi == 0 else 1
		for i in levels:
			await _clear_level(game, p)
		_check(Global.level == levels + 1, "không qua được %d màn, đang ở màn %d" % [levels, Global.level])
		if hi == 0:
			_check(Global.run_buffs.size() > 0, "không nhận được phúc lành nào")
			_check(_shops > 0, "30 màn mà không gặp gánh hàng rong nào")
			_check(_chests > 0, "không mở được rương nào")
			print("   gánh hàng: %d, rương: %d" % [_shops, _chests])
			# trùm ngẫu nhiên, không trùng trong 10 trận, máu tăng dần theo thứ tự gặp
			var first10: Array = Global.boss_order.slice(0, 10)
			var uniq := {}
			for b in first10:
				uniq[b] = true
			_check(uniq.size() == 10, "10 trùm đầu bị trùng: %s" % str(first10))
			_check(_boss_hp.size() == 10, "không gặp đủ 10 trùm (%d)" % _boss_hp.size())
			for i in range(1, _boss_hp.size()):
				_check(_boss_hp[i] > _boss_hp[i - 1], "máu trùm không tăng dần: %s" % str(_boss_hp))
			print("   thứ tự trùm: ", first10)
			print("   máu trùm: ", _boss_hp)
			_check(_legends.size() == 3, "không gặp đủ Tam Yêu: %s" % str(_legends.keys()))
			_check(_morphs == 20, "phải biến hình đủ 20 lần (10 trùm + 10 Tam Yêu), mới có %d" % _morphs)
			print("   Tam Yêu: ", _legends.keys(), "  số lần biến hình: ", _morphs)

		# Chết rồi hồi sinh
		Global.run_buffs.erase("bua_ho_menh")   # bỏ né đòn để thử chết
		Global.run_buffs.erase("khien_chan")
		p._invuln = 0.0
		p.armor = 0
		p.take_damage(999)
		_check(p.dead, "người chơi không chết")
		await _frames(80)
		_check(game._game_over != null, "không hiện màn hình thua")
		game._on_revive()
		_check(not p.dead and p.hp == p.max_hp, "hồi sinh lỗi")
		await _frames(5)

		game.queue_free()
		await _frames(5)

	if _fail == 0:
		print("SMOKE TEST OK")
	else:
		print("SMOKE TEST FAILED: %d lỗi" % _fail)
	get_tree().quit(1 if _fail > 0 else 0)


func _clear_level(game, p) -> void:
	var d = game.dungeon
	var level_before: int = Global.level
	var kinds := {}
	for cell in d.rooms:
		var r = d.rooms[cell]
		kinds[r.kind] = true
		if r.kind in ["exit", "boss", "legend"]:
			continue
		await _visit(p, r)
	# Phòng cuối cùng (cổng / trùm)
	for cell in d.rooms:
		var r = d.rooms[cell]
		if r.kind in ["exit", "boss", "legend"]:
			await _visit(p, r)
	_check(kinds.has("boss") == (level_before % 3 == 0), "phòng trùm sai ở màn %d" % level_before)
	if Global.legend_chance >= 1.0:
		_check(kinds.has("legend") == (level_before % 3 == 2), "phòng Tam Yêu sai ở màn %d" % level_before)
	var portals := get_tree().get_nodes_in_group("portals")
	_check(portals.size() > 0, "không có cổng ở màn %d" % level_before)
	if portals.is_empty():
		return
	p.global_position = portals[0].global_position
	# chờ màn chọn phúc lành hiện ra (cổng chỉ mở sau 0.5 giây) rồi chọn thẻ đầu
	var wait := 0
	while not game.buff_ui.visible and wait < 180:
		wait += 1
		await _frames(1)
	_check(game.buff_ui.visible, "không hiện màn chọn phúc lành")
	game.buff_ui.pick(0)
	await _frames(20)
	_check(Global.level == level_before + 1, "vào cổng không sang màn mới")
	await _frames(5)


func _visit(p, r) -> void:
	p.global_position = r.rect.get_center()
	await _frames(4)
	var guard := 0
	if r.kind == "boss" or r.kind == "legend":
		# đánh trùm xuống dưới nửa máu -> hiện nguyên hình -> dưới 40% tung chiêu đặc biệt
		await _frames(80)
		var boss = get_tree().get_first_node_in_group("boss")
		_check(boss != null, "không thấy trùm")
		if boss != null:
			if r.kind == "boss":
				_boss_hp.append(boss.max_hp)
			else:
				_legends[boss.data.id] = true
			boss._submerged = false
			boss.hp = int(boss.max_hp * 0.45)   # đặt thẳng máu (phúc lành tăng sát thương có thể giết luôn)
			await _frames(3)
			if is_instance_valid(boss) and not boss.dead:
				_check(boss._morph_t > 0.0, "trùm %s không hiện nguyên hình" % boss.data.id)
				var hp_before: int = boss.hp
				boss.take_damage(50)
				_check(boss.hp == hp_before, "đang biến hình mà vẫn trúng đòn")
				await _frames(95)
				_check(boss.transformed, "trùm %s biến hình không xong" % boss.data.id)
				if boss.transformed:
					_morphs += 1
				boss._submerged = false
				boss.take_damage(int(boss.max_hp * 0.2))
			await _frames(2)
			_last_boss_enraged = not is_instance_valid(boss) or boss.dead or boss.enraged
			# cho bộ chiêu nổi giận chạy 1 lượt
			if is_instance_valid(boss) and not boss.dead:
				boss._rage_t = 0.0
			await _frames(90)
			# trùm có thể đã chết luôn vì phúc lành tăng sát thương
			_check(not is_instance_valid(boss) or boss.dead or boss._special_used, "trùm không dùng chiêu đặc biệt")
	while r.state == "fighting" and guard < 900:
		guard += 1
		p.hp = p.max_hp
		p._invuln = 1.0
		p.aim_dir = Vector2.RIGHT
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.is_spawning():
				e.take_damage(100000)
		await _frames(1)
	await _frames(2)
	_check(r.state == "done", "phòng %s không xong (state=%s)" % [r.kind, r.state])
	if r.kind == "boss" or r.kind == "legend":
		_check(_last_boss_enraged, "trùm không nổi giận khi còn nửa máu")
	if r.kind == "combat":
		# rương sơn mài hiện ra sau khi dọn sạch phòng
		await _frames(30)
		_check(r.loot_chest != null and is_instance_valid(r.loot_chest), "không có rương sau phòng đánh")
		if r.loot_chest != null and is_instance_valid(r.loot_chest):
			p.global_position = r.loot_chest.global_position + Vector2(0, 6)
			await _frames(3)
			_check(p.interact_target == r.loot_chest, "rương không nhận tương tác")
			p._swap_or_pickup()
			_check(r.loot_chest.opened, "không mở được rương")
			_chests += 1
			await _frames(40)
	if r.kind == "shop":
		_shops += 1
		Global.run_coins += 500
		for st in r.shop.stands:
			p.global_position = st.global_position + Vector2(0, 4)
			await _frames(3)
			_check(p.interact_target == st, "kệ hàng không nhận tương tác")
			var before: int = Global.run_coins
			p._swap_or_pickup()
			_check(st.sold and Global.run_coins == before - st.price, "mua hàng lỗi (%s)" % st.good)
		await _frames(5)
