extends Node
## Kiểm thử thẻ G14: số phòng mỗi màn = 5 + min(level, 3) (<= 8) và số đợt giặc theo màn (1 / 2 / 3).
## Chạy: godot --headless --path . res://tests/pacing_test.tscn  -> in "PACING TEST OK"

const Dungeon = preload("res://scripts/game/dungeon.gd")
const Room = preload("res://scripts/game/room.gd")

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
	var expected_waves: Dictionary = {1: 1, 2: 2, 5: 2, 13: 3, 30: 3}
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
