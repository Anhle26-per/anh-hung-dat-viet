extends Node
## Kiểm thử thẻ G05: đạn hủy khi ra khỏi sàn hầm ngục, hàng đợi banner HUD, chữ hiện cho vật gần nhất.
## Chạy: godot --headless --path . res://tests/bugfix_test.tscn -> in "BUGFIX TEST OK"

const Dungeon = preload("res://scripts/game/dungeon.gd")
const Bullet = preload("res://scripts/entities/bullet.gd")
const HUD = preload("res://scripts/ui/hud.gd")
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


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func():
		print("BUGFIX TEST FAILED: quá thời gian")
		get_tree().quit(1))
	await _frames(2)
	await _run()
	if _fail == 0:
		print("BUGFIX TEST OK")
		get_tree().quit(0)
	else:
		print("BUGFIX TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Đạn ra vùng không có sàn bị hủy trong 1 giây")
	var d := Dungeon.new()
	add_child(d)
	d.generate(1)
	var b := Bullet.new()
	b.setup(true, Vector2(-600, -600), Vector2.LEFT, 100.0, 4, 5.0, "arrow")
	add_child(b)
	await get_tree().create_timer(0.45).timeout
	_check(not is_instance_valid(b), "đạn ngoài sàn không tự hủy trong 1s")
	d.queue_free()
	await _frames(2)

	print("== 2. Hàng đợi banner HUD: 5 lần gọi -> 1 đang hiện, tối đa 3 chờ, mỗi cái 2 giây")
	var hud := HUD.new()
	add_child(hud)
	for i in range(1, 6):
		hud.show_banner(str(i))
	_check(hud._banner == "1", "banner đầu tiên không phải '1': '%s'" % hud._banner)
	_check(hud._banner_queue.size() == 3 and Array(hud._banner_queue) == ["2", "3", "4"],
		"hàng đợi banner sai: %s" % str(hud._banner_queue))
	await get_tree().create_timer(2.1).timeout
	_check(hud._banner == "2" and hud._banner_queue.size() == 2,
		"banner sau 2s không chuyển sang '2': '%s' queue=%s" % [hud._banner, str(hud._banner_queue)])
	hud.queue_free()
	await _frames(2)

	print("== 3. 2 vũ khí cạnh nhau chỉ 1 cái gần nhất hiện chữ")
	var world := Node2D.new()
	add_child(world)
	var p := Player.new()
	p.setup("ngo_quyen")
	world.add_child(p)
	var pk_far := Pickup.new()
	pk_far.kind = "weapon"
	pk_far.weapon_id = "kiem"
	pk_far.position = Vector2(14, 0)
	world.add_child(pk_far)
	var pk_near := Pickup.new()
	pk_near.kind = "weapon"
	pk_near.weapon_id = "ma_tau"
	pk_near.position = Vector2(5, 0)
	world.add_child(pk_near)
	await _frames(3)
	_check(pk_near.is_showing_label() and not pk_far.is_showing_label(),
		"chữ hiện sai vật gần nhất: near=%s far=%s" % [str(pk_near.is_showing_label()), str(pk_far.is_showing_label())])
	world.queue_free()
	await _frames(2)
