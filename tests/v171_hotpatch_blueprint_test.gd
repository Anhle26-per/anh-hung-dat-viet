extends Node
## Kiểm thử v1.7.1: đồng bộ hotpatch (--main-pack / CACHE_MODE_REPLACE), idempotency InputMap,
## và tương tác bấm E ở Bàn Bản Vẽ, Bia Thành Tựu, Bảo Tàng Binh Khí trong Tầng Hầm Chiến Tích.
## Chạy: godot --headless --path . res://tests/v171_hotpatch_blueprint_test.tscn -> "V171 HOTPATCH BLUEPRINT TEST OK"

const HotpatchSync = preload("res://scripts/autoload/hotpatch_sync.gd")
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
	print("== 1. Kiểm tra HotpatchSync.is_booted_from_main_pack & needs_autoload_sync")
	var gpath: String = ProjectSettings.globalize_path("user://patch.pck")
	var win_path: String = gpath.replace("/", "\\")
	_check(HotpatchSync.is_booted_from_main_pack("user://patch.pck", PackedStringArray(["--main-pack", gpath])), "phải nhận diện đường dẫn POSIX")
	_check(HotpatchSync.is_booted_from_main_pack("user://patch.pck", PackedStringArray(["--main-pack", win_path])), "phải nhận diện đường dẫn Windows")
	_check(not HotpatchSync.is_booted_from_main_pack("user://patch.pck", PackedStringArray(["--main-pack", "other.pck"])), "không được nhận nhầm gói khác")
	_check(not HotpatchSync.is_booted_from_main_pack("user://patch.pck", PackedStringArray([])), "rỗng phải trả về false")
	_check(not HotpatchSync.needs_autoload_sync(get_tree()), "phiên bản hiện tại không được cần đồng bộ lại autoload")

	print("== 2. Kiểm tra _setup_inputs() chạy lại không trùng sự kiện")
	var before_n: int = InputMap.action_get_events("interact").size()
	Global._setup_inputs()
	var after_n: int = InputMap.action_get_events("interact").size()
	_check(before_n == after_n and before_n > 0, "InputMap.action_get_events('interact') bị trùng sau _setup_inputs (%d -> %d)" % [before_n, after_n])

	print("== 3. Kiểm tra vào Tầng Hầm và bấm E tại Bàn Bản Vẽ + 6 tab, Bia Thành Tựu, Bảo Tàng")
	var lobby = LobbyScene.instantiate()
	add_child(lobby)
	await _frames(3)
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
