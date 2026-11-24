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
