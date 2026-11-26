extends Node
## Kiểm thử thẻ G14: số phòng mỗi màn = 5 + min(level, 3) (<= 8) và số đợt giặc theo màn (1 / 2 / 3).
## Chạy: godot --headless --path . res://tests/pacing_test.tscn  -> in "PACING TEST OK"

const Dungeon = preload("res://scripts/game/dungeon.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

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
		print("PACING TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(1)
	await _run()
	if _fail == 0:
		print("PACING TEST OK")
		get_tree().quit(0)
	else:
		print("PACING TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	var levels: Array = [1, 2, 5, 13, 30]
	var expected_waves: Dictionary = {1: 2, 2: 2, 5: 3, 13: 4, 30: 4}
	for lv_val in levels:
		var lv: int = int(lv_val)
		var exp_rooms: int = 5 + mini(lv, 3)
		var exp_w: int = int(expected_waves[lv])
		print("== Kiểm tra màn %d (20 hạt giống): kỳ vọng %d phòng, %d đợt" % [lv, exp_rooms, exp_w])
		for s in 20:
			seed(lv * 1000 + s)
			var d: Node2D = Dungeon.new()
			add_child(d)
			d.generate(lv)
			var room_count: int = d.rooms.size()
			_check(room_count <= 8, "màn %d seed %d có %d phòng (> 8)" % [lv, s, room_count])
			_check(room_count == exp_rooms, "màn %d seed %d có %d phòng (kỳ vọng %d)" % [lv, s, room_count, exp_rooms])

			var combat_room = null
			for r in d.rooms.values():
				if r.kind == "combat":
					combat_room = r
					break
			_check(combat_room != null, "màn %d seed %d không có phòng combat" % [lv, s])
			if combat_room != null:
				combat_room._enter()
				var total_waves: int = int(combat_room._waves_left) + 1
				_check(total_waves == exp_w, "màn %d seed %d có %d đợt (kỳ vọng %d)" % [lv, s, total_waves, exp_w])
			d.queue_free()
		await _frames(1)

	# Kiểm tra thêm cấu trúc 5 màn/chương kiểu Soul Knight: 3-6 & 6-6 là Sảnh Khải Hoàn 2 phòng, 4-1+ là Thần Thoại 8 phòng 3 đợt
	for hall_lv in [16, 32]:
		var dh: Node2D = Dungeon.new()
		add_child(dh)
		dh.generate(hall_lv)
		_check(dh.rooms.size() == 2, "Sảnh Khải Hoàn màn %d phải có đúng 2 phòng (nhận %d)" % [hall_lv, dh.rooms.size()])
		var has_vh: bool = false
		for r in dh.rooms.values():
			if r.kind == "victory_hall":
				has_vh = true
		_check(has_vh, "màn %d thiếu phòng victory_hall" % hall_lv)
		dh.queue_free()
	await _frames(1)
	_check(EnemyData.is_boss_level(5) and EnemyData.is_boss_level(10) and EnemyData.is_boss_level(15), "1-5, 2-5, 3-5 phải là Boss")
	_check(EnemyData.is_boss_level(21) and EnemyData.is_boss_level(26) and EnemyData.is_boss_level(31), "4-5, 5-5, 6-5 phải là Boss Thần Thoại")
