extends CanvasLayer
## Menu tạm dừng (Esc / P / nút II trên điện thoại).

const UI = preload("res://scripts/ui/ui.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")

var game = null
var _settings: CanvasLayer = null
var _menu_btn: Button = null
var _leaving: bool = false


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
	if _leaving or not is_inside_tree():
		return
	if _settings != null and _settings.visible:
		return
	if event.is_action_pressed("pause"):
		if visible:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			close()
		elif game != null and is_instance_valid(game) and game.can_pause():
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			open()


func open() -> void:
	if _leaving or not is_inside_tree():
		return
	if game != null and (not is_instance_valid(game) or not game.can_pause()):
		return
	var online: bool = Net != null and Net.is_online()
	if _menu_btn != null:
		_menu_btn.text = "Rời phòng LAN" if online else "Về sảnh (giữ lại xu)"
	visible = true
	if not online:
		get_tree().paused = true


func close() -> void:
	visible = false
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false


func _on_settings() -> void:
	if _leaving:
		return
	if _settings != null:
		_settings.open()


func _on_menu() -> void:
	if _leaving:
		return
	_leaving = true
	set_process_unhandled_input(false)
	close()
	if Net != null and Net.is_online():
		if Net.is_host():
			Global.end_run("bo_luot")
		Net.leave_room()
		if is_inside_tree():
			get_tree().paused = false
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		return
	if game != null and is_instance_valid(game):
		game._on_menu()
	elif is_inside_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
