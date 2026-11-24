extends Node
## Kiểm thử thẻ G17: tách đổi vũ khí (lăn chuột / Q, có khoảng nghỉ 0.15s) và tương tác (E).
## Chạy: godot --headless --path . res://tests/input_test.tscn -> in "INPUT TEST OK"

const Player = preload("res://scripts/entities/player.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")

var _fail: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		push_error("KIỂM THỬ THẤT BẠI: " + msg)
		print("  THẤT BẠI: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _send_wheel(btn: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = btn
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev_up := InputEventMouseButton.new()
	ev_up.button_index = btn
	ev_up.pressed = false
	Input.parse_input_event(ev_up)


func _send_key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev_up := InputEventKey.new()
	ev_up.physical_keycode = k
	ev_up.pressed = false
	Input.parse_input_event(ev_up)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(30.0).timeout.connect(func():
		print("INPUT TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0:
		print("INPUT TEST OK")
		get_tree().quit(0)
	else:
		print("INPUT TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("ngo_quyen")
	p.weapons = ["giao_tre", "kiem"]
	world.add_child(p)
	p.slot = 0
	p._refresh_weapon_sprite()
	await _frames(2)

	print("== 1. Lăn chuột 1 lần đổi vũ khí")
	_send_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _frames(2)
	_check(p.slot == 1, "lăn chuột không đổi sang ô 1: slot=%d" % p.slot)

	print("== 2. Lăn chuột 2 lần trong 0.1 giây chỉ đổi 1 lần")
	await get_tree().create_timer(0.2).timeout
	_send_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await get_tree().create_timer(0.05).timeout
	_send_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _frames(2)
	_check(p.slot == 0, "lăn chuột 2 lần trong 0.1s lại đổi 2 lần: slot=%d" % p.slot)

	print("== 3. E khi có vũ khí dưới chân thì nhặt")
	var pk := Pickup.new()
	pk.kind = "weapon"
	pk.weapon_id = "ma_tau"
	pk.position = p.global_position
	world.add_child(pk)
	await _frames(3)
	_check(p.nearby_pickup == pk, "không nhận ra vũ khí dưới chân")
	_send_key(KEY_E)
	await _frames(2)
	_check(p.weapons[0] == "ma_tau", "bấm E không nhặt vũ khí: weapons=%s" % str(p.weapons))
	for ch in world.get_children():
		if ch is Pickup:
			ch.queue_free()
	p.nearby_pickup = null
	await _frames(2)

	print("== 4. E khi không có gì dưới chân KHÔNG đổi ô")
	var before_slot: int = p.slot
	_send_key(KEY_E)
	await _frames(2)
	_check(p.slot == before_slot, "bấm E khi trống lại đổi ô từ %d sang %d" % [before_slot, p.slot])

	print("== 5. Lăn chuột khi game tạm dừng không đổi vũ khí")
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = true
	_send_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _frames(2)
	get_tree().paused = false
	_check(p.slot == before_slot, "lăn chuột khi tạm dừng vẫn đổi ô: slot=%d" % p.slot)

	world.queue_free()
	await _frames(2)
