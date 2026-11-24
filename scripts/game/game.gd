extends Node2D
## Màn chơi chính: hầm ngục, người chơi, camera, ánh sáng, giao diện; chuyển màn; thua/hồi sinh.

const Dungeon = preload("res://scripts/game/dungeon.gd")
const Player = preload("res://scripts/entities/player.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const UI = preload("res://scripts/ui/ui.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const BuffSelect = preload("res://scripts/ui/buff_select.gd")

var world: Node2D
var player
var dungeon
var camera: Camera2D
var hud
var touch
var pause_menu
var darkness: CanvasModulate
var buff_ui
var _game_over: CanvasLayer = null
var _shake := 0.0
var _start_bonus := false


func _ready() -> void:
	add_to_group("game")
	get_tree().paused = false
	world = Node2D.new()
	add_child(world)
	darkness = CanvasModulate.new()
	add_child(darkness)

	player = Player.new()
	player.setup(Global.selected_hero)
	var resuming := not Global.resume_data.is_empty()
	if resuming:
		player.restore(Global.resume_data)    # "Chơi tiếp": máu, giáp, vũ khí như lúc lưu
	else:
		var fw: String = Global.consume_forged()
		if fw != "" and WeaponData.DATA.has(fw):
			player.weapons[1] = fw
			Global.discover(fw)
	world.add_child(player)
	player.died.connect(_on_player_died)
	player.hurt.connect(func(): add_shake(4.0))

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	player.add_child(camera)

	hud = HUD.new()
	add_child(hud)
	hud.player = player

	touch = TouchControls.new()
	add_child(touch)
	touch.player = player
	touch.pause_pressed.connect(func(): pause_menu.open())

	buff_ui = BuffSelect.new()
	add_child(buff_ui)
	buff_ui.chosen.connect(_on_buff_chosen)

	pause_menu = PauseMenu.new()
	pause_menu.game = self
	add_child(pause_menu)

	_build_level()
	# Lễ xuất quân: chọn 1 phúc lành ngay từ đầu
	if not resuming and Global.upgrade("khoi_dau") > 0 and Global.level == 1 and Global.run_buffs.is_empty():
		_start_buff.call_deferred()


func _start_buff() -> void:
	_start_bonus = true
	if not buff_ui.open("Lễ xuất quân"):
		_start_bonus = false


func add_shake(amount: float) -> void:
	if not bool(Global.settings.get("shake", true)):
		_shake = 0.0
		return
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if _shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 22.0)
	else:
		camera.offset = Vector2.ZERO


func _build_level() -> void:
	for c in world.get_children():
		if c != player:
			c.queue_free()
	var ch := EnemyData.chapter(Global.level)
	darkness.color = ch.dark
	Sfx.play_music("battle")
	dungeon = Dungeon.new()
	world.add_child(dungeon)
	world.move_child(dungeon, 0)
	dungeon.generate(Global.level)
	dungeon.portal_entered.connect(_on_portal)
	player.global_position = dungeon.start_position()
	player.nearby_pickup = null
	camera.reset_smoothing()
	Global.save_run(player)     # điểm lưu đầu mỗi màn (tắt game thì "Chơi tiếp" từ đây)
	var stage := (Global.level - 1) % 3 + 1
	if stage == 1:
		hud.show_chapter(EnemyData.chapter_index(Global.level) + 1, ch)
	else:
		hud.show_banner("Màn %d-%d%s" % [EnemyData.chapter_index(Global.level) + 1, stage, "  -  Trận quyết chiến!" if stage == 3 else ""])


func _on_portal() -> void:
	# qua màn: chọn 1 phúc lành rồi mới sang màn mới
	Sfx.play("level_clear")
	touch.reset()
	var nxt := EnemyData.chapter(Global.level + 1)
	var title := "%s - %s" % [nxt.name, nxt.year]
	_open_buffs.call_deferred(title)


func _open_buffs(title: String) -> void:
	if not buff_ui.open(title):
		_advance()


func _on_buff_chosen(id: String) -> void:
	player.apply_buff(id)
	if _start_bonus:
		_start_bonus = false
		Global.save_run(player)
		return
	_advance.call_deferred()


func _advance() -> void:
	Global.level += 1
	Global.best_level = maxi(Global.best_level, Global.level)
	_build_level()


func can_pause() -> bool:
	return not player.dead and _game_over == null and not buff_ui.visible


# ------------------------------------------------------------------ Thua cuộc

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	_show_game_over()


func _show_game_over() -> void:
	if _game_over != null:
		return
	touch.reset()
	_game_over = CanvasLayer.new()
	_game_over.layer = 30
	add_child(_game_over)
	var box := UI.overlay(_game_over, 0.7)
	box.add_child(UI.label("Tướng quân đã ngã xuống!", 34, Color(1, 0.55, 0.45)))
	var ch := EnemyData.chapter(Global.level)
	box.add_child(UI.label("%s - %s  |  Nhặt được %d xu" % [ch.name, ch.year, Global.run_coins], 18))
	if Global.free_revives > 0:
		box.add_child(UI.center(UI.button("Hồi sinh (Thuốc hồi sinh)", _on_free_revive)))
	elif not Global.revived:
		box.add_child(UI.center(UI.button("Hồi sinh (xem quảng cáo)", _on_revive)))
	box.add_child(UI.center(UI.button("Chơi lại", _on_restart)))
	box.add_child(UI.center(UI.button("Về sảnh", _on_menu)))


func _on_free_revive() -> void:
	Global.free_revives -= 1
	player.revive()
	if _game_over != null:
		_game_over.queue_free()
		_game_over = null


func _on_revive() -> void:
	Global.show_rewarded_ad(_do_revive)


func _do_revive() -> void:
	Global.revived = true
	player.revive()
	if _game_over != null:
		_game_over.queue_free()
		_game_over = null


func _on_restart() -> void:
	Global.end_run()
	Global.start_run()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	Global.end_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
