extends CanvasLayer
## Menu tạm dừng (Esc / P / nút II trên điện thoại).

const UI = preload("res://scripts/ui/ui.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")

var game = null
var _settings: CanvasLayer = null
var _menu_btn: Button = null


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var box := UI.overlay(self, 0.6)
	box.add_child(UI.label("Tạm dừng", 34, Color(1, 0.85, 0.4)))
	box.add_child(UI.center(UI.button("Tiếp tục", close)))
	box.add_child(UI.center(UI.button("Cài đặt", _on_settings)))
	_menu_btn = UI.button("Về sảnh (giữ lại xu)", _on_menu)
	box.add_child(UI.center(_menu_btn))
	_settings = SettingsMenu.new()
	add_child(_settings)


func _unhandled_input(event: InputEvent) -> void:
	if _settings != null and _settings.visible:
		return
	if event.is_action_pressed("pause"):
		if visible:
			close()
		elif game != null and game.can_pause():
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if game != null and not game.can_pause():
		return
	var online: bool = Net != null and Net.is_online()
	if _menu_btn != null:
		_menu_btn.text = "Rời phòng LAN" if online else "Về sảnh (giữ lại xu)"
	visible = true
	if not online:
		get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_settings() -> void:
	if _settings != null:
		_settings.open()


func _on_menu() -> void:
	close()
	if Net != null and Net.is_online():
		if Net.is_host():
			Global.end_run("bo_luot")
		Net.leave_room()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	game._on_menu()
