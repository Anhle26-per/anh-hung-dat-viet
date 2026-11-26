extends Node
## Kiểm thử v1.7.2: đồng bộ hotpatch in-place (needs_autoload_sync / ensure_autoloads_synced), idempotency InputMap,
## khởi tạo MainMenu/Lobby không tự thoát, và tương tác bấm E ở Bàn Bản Vẽ, Bia Thành Tựu, Bảo Tàng Binh Khí.
## Chạy: godot --headless --path . res://tests/v171_hotpatch_blueprint_test.tscn -> "V171 HOTPATCH BLUEPRINT TEST OK"

const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")
const MainMenuScene = preload("res://scenes/main_menu.tscn")
const LobbyScene = preload("res://scenes/lobby.tscn")

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
	get_tree().create_timer(45.0).timeout.connect(func():
		print("V171 HOTPATCH BLUEPRINT TEST FAILED: quá thời gian")
		get_tree().quit(1))
	Global.save_path = "user://v171_hotpatch_test_save.json"
	await _frames(1)
	await _run()
	if _fail == 0:
		print("V171 HOTPATCH BLUEPRINT TEST OK")
		get_tree().quit(0)
	else:
		print("V171 HOTPATCH BLUEPRINT TEST FAILED: %d lỗi" % _fail)
		get_tree().quit(1)


func _run() -> void:
	print("== 1. Kiểm tra HotpatchSync.needs_autoload_sync & ensure_autoloads_synced")
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "phiên bản hiện tại không được cần đồng bộ lại autoload")
	_check(not HotpatchSync.ensure_autoloads_synced(get_tree()), "ensure_autoloads_synced() phải trả về false khi đã đồng bộ sẵn")

	print("== 2. Kiểm tra _setup_inputs() chạy lại không trùng sự kiện")
	var before_interact: int = InputMap.action_get_events("interact").size()
	var before_sprint: int = InputMap.action_get_events("sprint").size()
	Global._setup_inputs()
	var after_interact: int = InputMap.action_get_events("interact").size()
	var after_sprint: int = InputMap.action_get_events("sprint").size()
	_check(before_interact == after_interact and before_interact > 0, "InputMap.action_get_events('interact') bị trùng sau _setup_inputs (%d -> %d)" % [before_interact, after_interact])
	_check(before_sprint == after_sprint and before_sprint > 0, "InputMap.action_get_events('sprint') bị trùng sau _setup_inputs (%d -> %d)" % [before_sprint, after_sprint])

	print("== 3. Kiểm tra MainMenu khởi tạo và sống ổn định")
	var menu = MainMenuScene.instantiate()
	add_child(menu)
	await _frames(5)
	_check(is_instance_valid(menu) and not menu.is_queued_for_deletion(), "MainMenu phải giữ nguyên trạng thái sống sau khi khởi tạo")
	menu.queue_free()
	await _frames(2)

	print("== 4. Kiểm tra vào Tầng Hầm và bấm E tại Bàn Bản Vẽ + 6 tab, Bia Thành Tựu, Bảo Tàng")
	var lobby = LobbyScene.instantiate()
	add_child(lobby)
	await _frames(3)
	_check(is_instance_valid(lobby) and not lobby.is_queued_for_deletion(), "Lobby phải giữ nguyên trạng thái sống sau khi khởi tạo")
	await lobby.enter_basement(true)
	await _frames(2)
	_check(lobby.in_basement, "phải vào được Tầng Hầm")

	lobby.player.global_position = Vector2(680, 1275)
	await _frames(4)
	_check(lobby.player.interact_target != null and str(lobby.player.interact_target.kind) == "basement_blueprint", "player.interact_target phải trỏ tới basement_blueprint")
	var ok_bp: bool = lobby.player.interact_only()
	_check(ok_bp and lobby.ui.is_open(), "bấm E ở Bàn Bản Vẽ phải mở được bảng Bàn Bản Vẽ")
	for tab in ["owned", "basic", "mid", "advanced", "legendary", "all"]:
		lobby.ui.open_blueprints(tab, "")
		_check(lobby.ui.is_open(), "tab '%s' của Bàn Bản Vẽ phải mở ổn định" % tab)
	lobby.ui.close()
	await _frames(2)

	lobby.player.global_position = Vector2(430, 1170)
	await _frames(4)
	_check(lobby.player.interact_target != null and str(lobby.player.interact_target.kind) == "basement_achieve", "player.interact_target phải trỏ tới basement_achieve")
	_check(lobby.player.interact_only() and lobby.ui.is_open(), "bấm E ở Bia Thành Tựu phải mở được giao diện")
	lobby.ui.close()
	await _frames(2)

	lobby.player.global_position = Vector2(930, 1170)
	await _frames(4)
	_check(lobby.player.interact_target != null and str(lobby.player.interact_target.kind) == "basement_gallery", "player.interact_target phải trỏ tới basement_gallery")
	_check(lobby.player.interact_only() and lobby.ui.is_open(), "bấm E ở Bảo Tàng Binh Khí phải mở được giao diện")
	lobby.ui.close()

	lobby.queue_free()
	await _frames(2)
