extends Node
## Kiểm thử thẻ G16 (Giai đoạn 1): rơi nguyên liệu, tỉ lệ 8% ở 2000 lính thường, lưu run.json, cộng kho cuối lượt, save cũ.
## Chạy: godot --headless --path . res://tests/craft_test.tscn  -> in "CRAFT TEST OK"

const MaterialData = preload("res://scripts/data/materials.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Player = preload("res://scripts/entities/player.gd")
const Art = preload("res://scripts/art/art.gd")
const TEST_SAVE := "user://craft_test_save.json"

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
	for p in [TEST_SAVE, Global.run_path(), TEST_SAVE + ".tmp", Global.run_path() + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _reset_all() -> void:
	Global.coins = 0
	Global.run_coins = 0
	Global.materials = {}
	Global.run_materials = {}
	Global.forged = ""
	Global.discovered = []
	Global.blueprints = []
	Global.upgrades = {}
	Global.resume_data = {}
	Global.selected_hero = "ngo_quyen"
	Global.level = 1


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func():
		print("CRAFT TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	_wipe()
	if _fail == 0:
		print("CRAFT TEST OK")
		get_tree().quit(0)
	else:
		print("CRAFT TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	Global.save_path = TEST_SAVE
	_wipe()
	_reset_all()

	print("== 1. Kiểm tra ảnh và âm thanh nguyên liệu")
	for mid in MaterialData.ORDER:
		var info: Dictionary = MaterialData.DATA[mid]
		var ipath: String = "res://assets/sprites/" + str(info.icon)
		_check(FileAccess.file_exists(ipath), "thiếu biểu tượng: " + ipath)
		_check(Art.tex(str(info.icon)) != null, "không nạp được texture: " + ipath)
	_check(Sfx.SFX_FILES.has("pickup_material") and Sfx.SFX_FILES.has("forge"), "thiếu âm thanh mới trong Sfx")

	print("== 2. Thống kê giết 2000 lính thường -> tỉ lệ rơi ~8% (±1.5%)")
	seed(202616)
	var holder := Node2D.new()
	add_child(holder)
	var p := Player.new()
	p.setup("ngo_quyen")
	holder.add_child(p)
	var mat_drops: int = 0
	for i in 2000:
		var e := Enemy.new()
		e.setup("bo_binh", 1, p)
		holder.add_child(e)
		e._drop_loot()
		for ch in holder.get_children():
			if ch != p and ch != e:
				if ch is Pickup and ch.kind == "material":
					mat_drops += 1
				holder.remove_child(ch)
				ch.free()
		holder.remove_child(e)
		e.free()
	var rate: float = float(mat_drops) / 2000.0
	print("   mat_drops = %d / 2000 (%.2f%%)" % [mat_drops, rate * 100.0])
	_check(absf(rate - 0.08) <= 0.015, "tỉ lệ rơi lính thường lệch 8%% ±1.5%%: %.4f" % rate)

	print("== 3. Tam Yêu chắc chắn rơi 1 ngọc thần và 2 yêu hồn")
	var leg := Enemy.new()
	leg.setup("legend:ho_tinh_vuong", 5, p)
	holder.add_child(leg)
	leg._drop_loot()
	var leg_counts: Dictionary = {}
	for ch in holder.get_children():
		if ch != p and ch != leg:
			if ch is Pickup and ch.kind == "material":
				leg_counts[ch.material_id] = int(leg_counts.get(ch.material_id, 0)) + 1
			holder.remove_child(ch)
			ch.free()
	holder.remove_child(leg)
	leg.free()
	_check(int(leg_counts.get("ngoc_than", 0)) == 1 and int(leg_counts.get("yeu_hon", 0)) == 2,
		"Tam Yêu rơi sai: %s" % str(leg_counts))

	print("== 4. Nhặt vật phẩm material -> run_materials -> cộng kho khi end_run & abandon_run")
	Global.start_run()
	var pk := Pickup.new()
	pk.kind = "material"
	pk.material_id = "dong"
	pk.amount = 2
	pk.position = p.global_position
	holder.add_child(pk)
	pk._collect(p)
	_check(int(Global.run_materials.get("dong", 0)) == 2, "nhặt không tăng run_materials")
	Global.add_run_material("sat", 3)

	# Lưu run.json và nạp lại kiểm tra giữ nguyên liệu
	_check(Global.save_run(p), "save_run thất bại")
	Global.run_materials = {}
	_check(Global.load_run(), "load_run thất bại")
	_check(int(Global.run_materials.get("dong", 0)) == 2 and int(Global.run_materials.get("sat", 0)) == 3,
		"run.json không giữ nguyên liệu: %s" % str(Global.run_materials))

	# end_run cộng vào kho
	Global.end_run()
	_check(Global.material_count("dong") == 2 and Global.material_count("sat") == 3,
		"end_run không cộng kho: %s" % str(Global.materials))
	_check(Global.run_materials.is_empty(), "end_run chưa xóa run_materials")

	# abandon_run cộng tiếp vào kho
	Global.start_run()
	Global.add_run_material("dong", 1)
	Global.add_run_material("ngoc_than", 2)
	Global.save_run(p)
	Global.run_materials = {}
	Global.abandon_run()
	_check(Global.material_count("dong") == 3 and Global.material_count("ngoc_than") == 2,
		"abandon_run không cộng kho: %s" % str(Global.materials))
	holder.queue_free()
	await _frames(2)

	print("== 5. Tệp lưu cũ thiếu materials và forged vẫn nạp được")
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 88, "unlocked": ["ngo_quyen"], "selected_hero": "ngo_quyen"}))
	f.close()
	Global.materials = {"dong": 99}
	Global.forged = "kiem"
	Global.coins = 0
	Global.load_game()
	_check(Global.coins == 88, "tệp cũ mất xu")
	_check(Global.materials.is_empty(), "tệp cũ không đặt materials về rỗng")
	_check(Global.forged == "", "tệp cũ không đặt forged về rỗng")

	print("== 6. Vũ khí cơ bản & chưa mở bản vẽ không rèn được; mở khóa bản vẽ rồi mới rèn được")
	_reset_all()
	Global.coins = 9999
	for mid in MaterialData.ORDER:
		Global.materials[mid] = 99
	Global.discovered = ["kiem_dong", "gay_tre", "kiem"]
	var forgeables: Array = Global.forgeable_weapons()
	_check(not forgeables.has("kiem_dong") and not Global.try_craft("kiem_dong"), "vũ khí cơ bản rèn được")
	_check(not forgeables.has("gay_tre") and not Global.can_craft("gay_tre") and not Global.try_craft("gay_tre"),
		"chỉ discover('gay_tre') không được phép rèn khi chưa mở bản vẽ")
	_check(not forgeables.has("kiem") and not Global.can_craft("kiem") and not Global.try_craft("kiem"),
		"chỉ discover('kiem') không được phép rèn khi chưa mở bản vẽ")
	_check(not forgeables.has("ma_tau") and not Global.try_craft("ma_tau"), "vũ khí chưa sưu tầm rèn được")
	Global.unlock_blueprint("gay_tre")
	Global.unlock_blueprint("kiem")
	forgeables = Global.forgeable_weapons()
	_check(forgeables.has("gay_tre") and Global.can_craft("gay_tre"), "vũ khí cấp 1 gay_tre phải rèn được sau unlock_blueprint")
	_check(forgeables.has("kiem"), "vũ khí cấp 2 đã mở bản vẽ thiếu trong danh sách rèn")
	var r_t1: Dictionary = MaterialData.recipe_for("gay_tre")
	_check(int(r_t1.get("coins", 0)) == 25 and int(r_t1.get("mats", {}).get("dong", 0)) == 2 and int(r_t1.get("mats", {}).get("go_lim", 0)) == 1,
		"công thức cấp 1 gay_tre sai: %s" % str(r_t1))
	_check(Global.try_craft("gay_tre") and Global.forged == "gay_tre", "rèn cấp 1 gay_tre thất bại")
	_check(Global.coins == 9999 - 25 and Global.material_count("dong") == 97 and Global.material_count("go_lim") == 98,
		"trừ xu/nguyên liệu gay_tre sai")
	Global.forged = ""

	print("== 7. Công thức cấp 2-5 phân biệt hỏa khí (hỏa dược), phép/thần (yêu hồn/ngọc thần) và cận chiến (gỗ lim)")
	var r_t2: Dictionary = MaterialData.recipe_for("kiem")
	_check(int(r_t2.get("coins", 0)) == 55 and int(r_t2.get("mats", {}).get("dong", 0)) == 3 and int(r_t2.get("mats", {}).get("sat", 0)) == 2 and int(r_t2.get("mats", {}).get("go_lim", 0)) == 2,
		"công thức cấp 2 kiem sai: %s" % str(r_t2))
	var r_gun: Dictionary = MaterialData.recipe_for("tieu_lien")
	var r_blade: Dictionary = MaterialData.recipe_for("dao")
	_check(int(r_gun.get("coins", 0)) == 130 and int(r_gun.mats.get("hoa_duoc", 0)) == 3 and int(r_gun.mats.get("sat", 0)) == 4 and not r_gun.mats.has("go_lim"),
		"công thức tiểu liên sai: %s" % str(r_gun))
	_check(int(r_blade.get("coins", 0)) == 130 and int(r_blade.mats.get("go_lim", 0)) == 3 and int(r_blade.mats.get("sat", 0)) == 4 and not r_blade.mats.has("hoa_duoc"),
		"công thức đại đao sai: %s" % str(r_blade))
	var r_t4: Dictionary = MaterialData.recipe_for("sung_tesla")
	_check(int(r_t4.get("coins", 0)) == 320 and int(r_t4.mats.get("sat", 0)) == 6 and int(r_t4.mats.get("dong", 0)) == 5 and int(r_t4.mats.get("yeu_hon", 0)) >= 3 and int(r_t4.mats.get("ngoc_than", 0)) >= 2,
		"công thức cấp 4 sung_tesla sai: %s" % str(r_t4))
	var r_t5: Dictionary = MaterialData.recipe_for("kiem_thoi_khong")
	_check(int(r_t5.get("coins", 0)) == 850 and int(r_t5.mats.get("sat", 0)) >= 12 and int(r_t5.mats.get("dong", 0)) >= 10 and int(r_t5.mats.get("yeu_hon", 0)) >= 8 and int(r_t5.mats.get("ngoc_than", 0)) >= 6,
		"công thức cấp 5 kiem_thoi_khong sai: %s" % str(r_t5))

	print("== 8. Thiếu nguyên liệu hoặc xu thì không rèn được và không trừ")
	_reset_all()
	Global.discovered = ["kiem", "ma_tau"]
	Global.blueprints = ["kiem", "ma_tau"]
	Global.coins = 54
	Global.materials = {"dong": 3, "sat": 2, "go_lim": 2}
	_check(not Global.can_craft("kiem") and not Global.try_craft("kiem"), "rèn được khi thiếu xu")
	_check(Global.coins == 54 and Global.material_count("dong") == 3 and Global.material_count("go_lim") == 2, "bị trừ nhầm khi thiếu xu")
	Global.coins = 100
	Global.materials = {"dong": 2, "sat": 2, "go_lim": 2}
	_check(not Global.can_craft("kiem") and not Global.try_craft("kiem"), "rèn được khi thiếu nguyên liệu")
	_check(Global.coins == 100 and Global.material_count("dong") == 2 and Global.forged == "", "bị trừ nhầm khi thiếu nguyên liệu")

	print("== 9. Đủ đồ rèn thành công, trừ kho + xu, lưu forged")
	Global.coins = 100
	Global.materials = {"dong": 4, "sat": 3, "go_lim": 3}
	_check(Global.try_craft("kiem"), "rèn kiem thất bại dù đủ đồ")
	_check(Global.coins == 45, "trừ xu sai sau rèn: %d" % Global.coins)
	_check(Global.material_count("dong") == 1 and Global.material_count("sat") == 1 and Global.material_count("go_lim") == 1,
		"trừ nguyên liệu sai sau rèn: %s" % str(Global.materials))
	_check(Global.forged == "kiem", "Global.forged không phải kiem")
	Global.coins = 0
	Global.materials = {}
	Global.forged = ""
	Global.load_game()
	_check(Global.coins == 45 and Global.material_count("dong") == 1 and Global.material_count("go_lim") == 1 and Global.forged == "kiem",
		"save_game/load_game không giữ trạng thái sau rèn")

	print("== 10. Đang có binh khí chờ ra trận thì không rèn thêm được")
	Global.coins = 500
	Global.materials = {"dong": 10, "sat": 10, "go_lim": 10}
	_check(not Global.can_craft("ma_tau") and not Global.try_craft("ma_tau"),
		"rèn thêm được khi đã có forged")
	_check(Global.coins == 500 and Global.forged == "kiem", "đổi forged khi đang bị khóa")

	print("== 11. Bắt đầu lượt mới trao vũ khí đã rèn vào ô 2 và xóa forged")
	Global.start_run()
	var g1 = load("res://scenes/game.tscn").instantiate()
	add_child(g1)
	await _frames(4)
	_check(g1.player.weapons[1] == "kiem", "ô vũ khí 2 không nhận kiem: %s" % str(g1.player.weapons))
	Global.load_game()
	_check(Global.forged == "", "Global.forged chưa xóa sau khi vào trận mới: %s" % Global.forged)
	g1.queue_free()
	await _frames(2)

	print("== 12. Chơi tiếp lượt dở không trao thêm vũ khí đang chờ")
	Global.forged = "ma_tau"
	Global.save_game()
	_check(Global.load_run(), "load_run thất bại ở bước Chơi tiếp")
	var g2 = load("res://scenes/game.tscn").instantiate()
	add_child(g2)
	await _frames(4)
	_check(g2.player.weapons[1] == "kiem", "Chơi tiếp ghi đè ô 2: %s" % str(g2.player.weapons))
	Global.load_game()
	_check(Global.forged == "ma_tau", "Chơi tiếp xóa nhầm forged: %s" % Global.forged)
	g2.queue_free()
	await _frames(2)

	print("== 13. Giao diện Lò rèn tab Rèn binh khí và Giá binh khí trong sảnh")
	Global.resume_data = {}
	var lb = load("res://scenes/lobby.tscn").instantiate()
	add_child(lb)
	await _frames(5)
	_check(lb._forged_icon != null and lb._forged_icon.visible, "giá binh khí không hiện vũ khí chờ")
	lb.ui.open_forge("craft")
	await _frames(3)
	var btns: Array = _collect_buttons(lb.ui._panel)
	var has_wait_btn := false
	for b in btns:
		if b.text == "Đã có binh khí chờ ra trận" and b.disabled:
			has_wait_btn = true
	_check(has_wait_btn, "thiếu nút khóa 'Đã có binh khí chờ ra trận'")
	lb.ui.close()
	Global.forged = ""
	lb.refresh_forged_display()
	_check(not lb._forged_icon.visible, "giá binh khí vẫn hiện khi forged rỗng")
	lb.ui.open_forge("craft")
	await _frames(3)
	var btns2: Array = _collect_buttons(lb.ui._panel)
	var has_craft_btn := false
	for b in btns2:
		if b.text == "Rèn":
			has_craft_btn = true
	_check(has_craft_btn, "thiếu nút 'Rèn' khi forged rỗng")
	lb.ui.close()
	lb.queue_free()
	await _frames(2)


func _collect_buttons(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	if root is Button:
		out.append(root)
	for ch in root.get_children():
		out.append_array(_collect_buttons(ch))
	return out
