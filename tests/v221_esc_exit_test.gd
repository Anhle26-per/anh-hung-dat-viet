extends Node
## Kiểm thử hồi quy v2.2.1 cho toàn bộ đường thoát / đóng UI bằng phím ESC:
## MainMenu (Settings, ChallengeMenu, echo ESC), Lobby (chưa chọn tướng, đã chọn tướng,
## modal, tầng hầm trong & sau chuyển cảnh, LAN Host, double-ESC), LAN Menu (LineEdit focus),
## HeroSelect, Game PauseMenu (mở/đóng, Settings, Về sảnh, Rời LAN, double-ESC, echo ESC),
## ShopUI và BuffSelect.
## Chạy: godot --headless --path . res://tests/v221_esc_exit_test.tscn -> in "V221 ESC EXIT TEST OK"

const ShopUIScript = preload("res://scripts/ui/shop_ui.gd")

const TEST_SAVE := "user://v221_esc_test_save.json"
const TEST_LOG := "user://v221_esc_test_log.csv"


class EscRunner extends Node:
	var _fail: int = 0
	var _step: String = "init"

	func _check(cond: bool, msg: String) -> void:
		if not cond:
			_fail += 1
			push_error("V221 ESC FAIL [%s]: %s" % [_step, msg])
			print("  THAT BAI [%s]: %s" % [_step, msg])

	func _frames(n: int = 3) -> void:
		for _i in n:
			await get_tree().process_frame

	func _send_esc(pressed: bool = true, echo: bool = false) -> void:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.physical_keycode = KEY_ESCAPE
		ev.pressed = pressed
		ev.echo = echo
		get_tree().root.push_input(ev)

	func _press_esc(echo_count: int = 0) -> void:
		_send_esc(true, false)
		for _i in echo_count:
			_send_esc(true, true)
		_send_esc(false, false)

	func _wipe() -> void:
		for p in [TEST_SAVE, TEST_SAVE + ".tmp", TEST_SAVE.get_basename() + "_run.json",
				TEST_SAVE.get_basename() + "_run.json.tmp", TEST_LOG]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

	func _ready() -> void:
		get_tree().create_timer(90.0, true, false, true).timeout.connect(func():
			print("V221 ESC EXIT TEST FAILED: qua thoi gian tai buoc=", _step)
			_wipe()
			get_tree().quit(2))
		_run.call_deferred()

	func _load_scene_and_wait(path: String, wait_frames: int = 8) -> Node:
		var tree := get_tree()
		var err := tree.change_scene_to_file(path)
		_check(err == OK, "khong nap duoc %s (err=%d)" % [path, err])
		await _frames(wait_frames)
		return tree.current_scene

	func _assert_scene(suffix: String, msg: String) -> void:
		var cs := get_tree().current_scene
		_check(cs != null and cs.scene_file_path.ends_with(suffix),
			"%s (hien tai: %s)" % [msg, cs.scene_file_path if cs != null else "null"])

	func _run() -> void:
		Global.save_path = TEST_SAVE
		Global.log_path = TEST_LOG
		_wipe()
		Global.coins = 500
		Global.unlocked = ["hai_ba_trung", "ngo_quyen"]
		Global.selected_hero = "hai_ba_trung"
		Global.upgrades = {}
		Global.hero_levels = {}
		Global.weapon_ranks = {}
		Global.garden_plots = []
		Global.ensure_garden_plots()
		Global.save_game()

		var tree := get_tree()

		# 1. MainMenu: Settings ESC, ChallengeMenu (echo + ESC), plain ESC + echo ESC
		_step = "main_menu_esc"
		var mm := await _load_scene_and_wait("res://scenes/main_menu.tscn", 6)
		_assert_scene("main_menu.tscn", "chua vao duoc MainMenu")

		mm._on_settings()
		await _frames(3)
		_check(mm._settings.visible, "Settings tren MainMenu khong mo")
		_press_esc()
		await _frames(3)
		_check(not mm._settings.visible, "ESC khong dong Settings tren MainMenu")

		mm._on_challenge()
		await _frames(3)
		_check(mm._challenge.visible, "ChallengeMenu khong mo")
		_send_esc(true, true) # held echo ESC khong duoc dong nham hoac loi
		_send_esc(false, false)
		await _frames(2)
		_check(mm._challenge.visible, "echo ESC khong nen dong ChallengeMenu")
		_press_esc()
		await _frames(3)
		_check(not mm._challenge.visible, "ESC khong dong ChallengeMenu")

		_press_esc(3)
		await _frames(3)
		_assert_scene("main_menu.tscn", "ESC tren MainMenu lam mat scene")

		# 2. Lobby chua xac nhan tuong -> ESC ve MainMenu
		_step = "lobby_unconfirmed_esc"
		var lb := await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
		_check(lb != null and lb.is_in_group("lobby"), "chua vao Lobby (unconfirmed)")
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "Lobby chua chon tuong ESC khong ve MainMenu")

		# 3. Lobby da xac nhan tuong -> ESC ve MainMenu
		_step = "lobby_confirmed_esc"
		lb = await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
		lb.confirm_hero(Global.selected_hero)
		await _frames(4)
		_check(bool(lb.get("hero_confirmed")), "Lobby chua xac nhan tuong")
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "Lobby da chon tuong ESC khong ve MainMenu")

		# 4. Lobby mo modal -> ESC dong modal (o lai Lobby) -> ESC ve MainMenu
		_step = "lobby_modal_esc"
		lb = await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
		lb.confirm_hero(Global.selected_hero)
		await _frames(4)
		lb.ui.open_forge()
		await _frames(3)
		_check(lb.ui.is_open(), "modal lo ren trong Lobby khong mo")
		_press_esc()
		await _frames(4)
		_check(not lb.ui.is_open(), "ESC dau khong dong modal Lobby")
		_check(tree.current_scene != null and tree.current_scene.is_in_group("lobby"),
			"ESC dong modal lai thoat khoi Lobby")
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "ESC thu hai sau dong modal khong ve MainMenu")

		# 5. Lobby tang ham (ESC khi dang chuyen canh + ESC trong tang ham)
		_step = "lobby_basement_esc"
		lb = await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
		lb.confirm_hero(Global.selected_hero)
		await _frames(4)
		lb.enter_basement(false)
		await _frames(2)
		if bool(lb.get("_transitioning")):
			_press_esc() # trong luc dang tween chuyen canh: khong duoc loi hoac vang
		var t_wait := 0
		while tree.current_scene != null and tree.current_scene.is_in_group("lobby") and tree.current_scene.get("_transitioning") and t_wait < 120:
			await _frames(1)
			t_wait += 1
		await _frames(3)
		_check(tree.current_scene != null and tree.current_scene.is_in_group("lobby") and bool(tree.current_scene.get("in_basement")),
			"khong hoan tat vao tang ham sau ESC luc dang chuyen canh")
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "ESC trong tang ham khong ve MainMenu")

		# 6. Lobby double-ESC nhanh cung frame & lien tiep + held echo
		_step = "lobby_double_echo_esc"
		await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
		_send_esc(true, false)
		_send_esc(true, false)
		_send_esc(true, true)
		_send_esc(false, false)
		await _frames(1)
		_press_esc(2)
		await _frames(8)
		_assert_scene("main_menu.tscn", "double/echo ESC o Lobby khong ve MainMenu sach")

		# 7. Lobby LAN Host -> ESC thoat phong va ve MainMenu
		_step = "lobby_lan_host_esc"
		var host_err: int = Net.create_room("EscTestRoom", "Host", 17783)
		_check(host_err == OK, "Net.create_room that bai: %d" % host_err)
		if host_err == OK:
			Net.host_enter_lobby()
			await _load_scene_and_wait("res://scenes/lobby.tscn", 8)
			_press_esc()
			await _frames(8)
			_check(not Net.is_online(), "Net van online sau khi ESC khoi Lobby LAN")
			_assert_scene("main_menu.tscn", "ESC khoi Lobby LAN khong ve MainMenu")

		# 8. LAN Menu (LineEdit focus release -> ESC back) & HeroSelect ESC
		_step = "lan_menu_hero_select_esc"
		var lan_menu := await _load_scene_and_wait("res://scenes/lan_lobby.tscn", 6)
		if lan_menu._name_input != null:
			lan_menu._name_input.grab_focus()
			await _frames(2)
			_press_esc()
			await _frames(3)
			_assert_scene("lan_lobby.tscn", "ESC luc LineEdit dang focus phai o lai LAN Menu")
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "ESC lan hai o LAN Menu khong ve MainMenu")

		await _load_scene_and_wait("res://scenes/hero_select.tscn", 6)
		_press_esc()
		await _frames(8)
		_assert_scene("main_menu.tscn", "ESC o HeroSelect khong ve MainMenu")

		# 9. Game PauseMenu: mo/dong bang ESC, Settings ESC, double/echo ESC, Ve sanh
		_step = "game_pause_menu_esc"
		Global.start_run()
		var game := await _load_scene_and_wait("res://scenes/game.tscn", 8)
		_check(game != null and game.is_in_group("game"), "chua vao duoc Game")
		if game.buff_ui != null and game.buff_ui.visible:
			game.buff_ui.pick(0)
			await _frames(4)
		_press_esc()
		await _frames(3)
		_check(game.pause_menu.visible and tree.paused, "ESC khong mo PauseMenu hoac khong pause")
		game.pause_menu._on_settings()
		await _frames(3)
		_check(game.pause_menu._settings.visible, "PauseMenu Settings khong mo")
		_press_esc()
		await _frames(3)
		_check(not game.pause_menu._settings.visible and game.pause_menu.visible,
			"ESC khong dong Settings ma giu PauseMenu")
		_press_esc()
		await _frames(3)
		_check(not game.pause_menu.visible and not tree.paused, "ESC lan hai khong dong PauseMenu")

		# Rapid double-ESC + echo ESC tren PauseMenu
		_send_esc(true, false)
		_send_esc(true, false)
		_send_esc(false, false)
		await _frames(2)
		_send_esc(true, false)
		_send_esc(true, true)
		_send_esc(true, true)
		_send_esc(false, false)
		await _frames(3)
		if not game.pause_menu.visible:
			game.pause_menu.open()
			await _frames(2)
		game.pause_menu._on_menu() # Ve sanh
		await _frames(8)
		_check(not tree.paused, "tree van paused sau Ve sanh")
		_assert_scene("lobby.tscn", "Ve sanh khong quay ve Lobby")

		# 10. Game LAN Host PauseMenu -> Roi LAN
		_step = "game_lan_roi_lan"
		host_err = Net.create_room("EscTestRoom2", "Host", 17784)
		_check(host_err == OK, "Net.create_room(2) that bai: %d" % host_err)
		if host_err == OK:
			Net.host_start_match()
			game = await _load_scene_and_wait("res://scenes/game.tscn", 8)
			_press_esc()
			await _frames(3)
			_check(game.pause_menu.visible, "PauseMenu LAN khong mo bang ESC")
			game.pause_menu._on_menu() # Roi LAN
			await _frames(8)
			_check(not Net.is_online(), "Net van online sau Roi LAN")
			_check(not tree.paused, "tree van paused sau Roi LAN")
			_assert_scene("main_menu.tscn", "Roi LAN khong quay ve MainMenu")

		# 11. ShopUI & BuffSelect ESC
		_step = "shop_ui_and_buff_esc"
		Global.start_run()
		game = await _load_scene_and_wait("res://scenes/game.tscn", 8)
		if game.buff_ui != null and game.buff_ui.visible:
			game.buff_ui.pick(0)
			await _frames(3)
		var shop_ui: CanvasLayer = ShopUIScript.new()
		game.add_child(shop_ui)
		await _frames(4)
		_check(tree.paused, "ShopUI khong pause game")
		_press_esc()
		await _frames(4)
		_check(not is_instance_valid(shop_ui), "ShopUI khong dong bang ESC")
		_check(not tree.paused, "tree van paused sau khi dong ShopUI bang ESC")
		_check(not game.pause_menu.visible, "PauseMenu mo nham khi ESC dong ShopUI")

		if game.buff_ui != null:
			game.buff_ui.open("Man 1-2", false)
			await _frames(4)
			_press_esc()
			await _frames(4)
			_check(not game.pause_menu.visible, "PauseMenu mo nham khi BuffSelect dang mo")
			game.buff_ui.pick(0)
			await _frames(3)
			_check(not tree.paused, "tree van paused sau khi chon buff")

		# Ket thuc sach
		Net.leave_room()
		_wipe()
		if _fail == 0:
			print("V221 ESC EXIT TEST OK")
			tree.quit(0)
		else:
			print("V221 ESC EXIT TEST FAILED: %d loi" % _fail)
			tree.quit(1)


func _ready() -> void:
	var runner := EscRunner.new()
	runner.name = "V221EscRunner"
	runner.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child.call_deferred(runner)
