extends Node2D
## Sảnh chính "Doanh trại Anh Hùng": tranh nền vẽ nguyên bức (đình làng, sân khấu gỗ,
## sân gạch Bát Tràng, võ đường, khu cổng, vườn), đi lại tự do và tương tác:
##   - 10 vị tướng trên sân khấu (tướng chưa mở là tượng đá): xem, đổi tướng, mở khóa
##   - Lò rèn: nâng cấp vĩnh viễn      - Giá binh khí: bộ sưu tập vũ khí
##   - Hình nhân rơm: đánh thử          - Bia ghi công: thống kê
##   - Cổng xuất trận: bắt đầu lượt chơi

const Player = preload("res://scripts/entities/player.gd")
const Portal = preload("res://scripts/entities/portal.gd")
const Decor = preload("res://scripts/game/decor.gd")
const Station = preload("res://scripts/game/station.gd")
const Dummy = preload("res://scripts/game/dummy.gd")
const LobbyLife = preload("res://scripts/game/lobby_life.gd")
const Ambience = preload("res://scripts/game/ambience.gd")
const LobbyUI = preload("res://scripts/ui/lobby_ui.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const Art = preload("res://scripts/art/art.gd")

const SIZE := Vector2(416, 240)

var world: Node2D
var player
var camera: Camera2D
var ui
var touch
var stations: Array = []
var _hero_npcs := {}
var _leaving := false


func _ready() -> void:
	add_to_group("lobby")
	get_tree().paused = false
	Sfx.play_music("lobby")
	world = Node2D.new()
	add_child(world)
	var dark := CanvasModulate.new()
	dark.color = Color(0.96, 0.93, 0.88)
	add_child(dark)
	_build_room()
	_decorate()
	_build_stations()
	_spawn_player(Vector2(208, 178))

	camera = Camera2D.new()
	camera.position = SIZE / 2.0
	camera.zoom = Vector2(1.5, 1.5)
	world.add_child(camera)
	camera.make_current()

	touch = TouchControls.new()
	add_child(touch)
	touch.player = player
	touch.pause_pressed.connect(_back_to_menu)
	ui = LobbyUI.new()
	ui.lobby = self
	add_child(ui)


func _build_room() -> void:
	var bg := Sprite2D.new()
	bg.texture = Art.tex("world/lobby_bg.png")
	bg.centered = false
	bg.z_index = -5
	world.add_child(bg)
	# tường chắn: mặt tiền đình, hai bên, lan can
	for r in [Rect2(0, 0, SIZE.x, 72), Rect2(0, 0, 12, SIZE.y), Rect2(SIZE.x - 12, 0, 12, SIZE.y), Rect2(0, 222, SIZE.x, 18)]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = r.size
		cs.shape = sh
		cs.position = r.get_center()
		body.add_child(cs)
		world.add_child(body)


func _life(kind: String, pos: Vector2, size := Vector2.ZERO) -> Node2D:
	var n := LobbyLife.new()
	n.kind = kind
	n.position = pos
	n.size = size
	world.add_child(n)
	return n


func _sprite(rel: String, offset := Vector2.ZERO) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = Art.tex(rel)
	sp.position = offset
	return sp


func _prop(rel: String, pos: Vector2, offset := Vector2.ZERO) -> Sprite2D:
	var s := _sprite(rel, offset)
	s.position = pos + offset
	world.add_child(s)
	return s


func _decor(kind: String, pos: Vector2) -> void:
	var d := Decor.new()
	d.kind = kind
	d.position = pos
	world.add_child(d)


func _decorate() -> void:
	# đèn lồng treo dưới hiên
	for x in [52.0, 140.0, 276.0, 364.0]:
		_decor("lantern", Vector2(x, 33))
	# thảm đỏ từ giữa sân tới cổng, mặt trống đồng giữa sân
	_life("carpet", Vector2(290, 160), Vector2(150, 18))
	_decor("drum", Vector2(208, 158))
	# lư hương tỏa khói trước bậc thềm, trống đồng trên giá hai bên
	var inc := _prop("world/incense.png", Vector2(208, 122))
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(0, -8)
	smoke.amount = 12
	smoke.lifetime = 2.5
	smoke.direction = Vector2.UP
	smoke.spread = 12.0
	smoke.gravity = Vector2(4, -6)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 2.5
	var sg := Gradient.new()
	sg.set_color(0, Color(0.9, 0.88, 0.92, 0.7))
	sg.set_color(1, Color(0.9, 0.88, 0.92, 0.0))
	smoke.color_ramp = sg
	inc.add_child(smoke)
	inc.add_child(Art.light(Color(1, 0.6, 0.3), 0.7, 0.6))
	_prop("world/drum_stand.png", Vector2(172, 124))
	_prop("world/drum_stand.png", Vector2(244, 124))
	# nghê đá canh cổng
	_prop("world/nghe.png", Vector2(334, 138))
	_prop("world/nghe.png", Vector2(334, 184))
	# ao sen ở vườn
	_life("pond", Vector2(208, 214), Vector2(70, 16))
	# cây cối
	_decor("peach", Vector2(160, 206))
	_decor("peach", Vector2(256, 206))
	_decor("bamboo", Vector2(22, 214))
	_decor("bamboo", Vector2(394, 214))
	for p in [Vector2(150, 118), Vector2(266, 118), Vector2(390, 120)]:
		_prop("world/bonsai.png", p)
	for p in [Vector2(24, 112), Vector2(130, 192), Vector2(392, 196)]:
		_decor("pot", p)
	# lính tuần tra và gà con
	var pa := _life("patrol", Vector2.ZERO)
	pa.a = Vector2(160, 196)
	pa.b = Vector2(320, 196)
	pa.position = pa.a
	for i in 3:
		_life("chicken", Vector2(60 + i * 18, 214 + (i % 2) * 2))
	# không khí: vệt nắng, bụi lấp lánh, bướm, lá và cánh hoa rơi
	var amb := Ambience.new()
	amb.area = Rect2(Vector2.ZERO, SIZE)
	world.add_child(amb)
	# tàn lửa bốc lên từ lò rèn
	var embers := CPUParticles2D.new()
	embers.position = Vector2(30, 120)
	embers.amount = 10
	embers.lifetime = 1.6
	embers.direction = Vector2.UP
	embers.spread = 30.0
	embers.gravity = Vector2(4, -24)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 22.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.0
	var eg := Gradient.new()
	eg.set_color(0, Color(1, 0.85, 0.35, 1))
	eg.set_color(1, Color(1, 0.3, 0.1, 0))
	embers.color_ramp = eg
	embers.material = Art.additive()
	embers.z_index = 6
	world.add_child(embers)


func _add_station(kind: String, data: String, title: String, hint: String, pos: Vector2, sprite: Node2D) -> Node2D:
	var s := Station.new()
	s.kind = kind
	s.data = data
	s.title = title
	s.hint = hint
	s.position = pos
	if sprite != null:
		s.add_child(sprite)
	s.used.connect(_on_station)
	world.add_child(s)
	stations.append(s)
	return s


func _build_stations() -> void:
	# 10 vị tướng đứng thành hàng trên sân khấu
	for i in HeroData.ORDER.size():
		var id: String = HeroData.ORDER[i]
		var h: Dictionary = HeroData.DATA[id]
		var a := AnimatedSprite2D.new()
		a.sprite_frames = Art.frames("heroes/%s.png" % id, 32, 32, {"idle": [[0, 1, 2, 3], 3.0 + i * 0.2, true]})
		a.play("idle")
		a.position = Vector2(0, -10)
		var s := _add_station("hero", id, h.name, "Xem tướng", Vector2(48.0 + i * 35.5, 92.0), a)
		s.title_when_near = true
		s.radius = 18.0
		_hero_npcs[id] = s
	_refresh_heroes()
	# võ đường: lò rèn, giá binh khí, 2 hình nhân
	var forge := AnimatedSprite2D.new()
	forge.sprite_frames = Art.strip("world/forge.png", 32, 28, 8.0, true)
	forge.play("play")
	forge.position = Vector2(0, -8)
	_add_station("forge", "", "Lò rèn", "Nâng cấp", Vector2(34, 132), forge)
	var fl := Art.light(Color(1, 0.6, 0.3), 1.2, 0.9)
	fl.position = Vector2(28, 132)
	world.add_child(fl)
	_add_station("rack", "", "Giá binh khí", "Xem kho vũ khí", Vector2(112, 128), _sprite("world/weapon_rack.png", Vector2(0, -8)))
	for x in [56.0, 100.0]:
		var dm := Dummy.new()
		dm.position = Vector2(x, 182)
		world.add_child(dm)
	_add_station("stele", "", "Bia ghi công", "Xem thành tích", Vector2(296, 196), _sprite("world/stele.png", Vector2(0, -8)))
	# cổng xuất trận trên vòng đá
	var portal := Portal.new()
	portal.position = Vector2(370, 158)
	portal.label = "Cổng xuất trận"
	portal.entered.connect(_start_run)
	world.add_child(portal)


func _refresh_heroes() -> void:
	for id in _hero_npcs:
		var s = _hero_npcs[id]
		var unlocked: bool = Global.unlocked.has(id)
		s.visible = id != Global.selected_hero
		var spr: AnimatedSprite2D = s.get_child(0)
		# tướng chưa mở khóa là tượng đá đứng yên
		spr.material = null if unlocked else Art.stone_material()
		if unlocked:
			spr.play("idle")
		else:
			spr.stop()
		s.title_color = Color(1, 0.9, 0.6) if unlocked else Color(0.8, 0.78, 0.75)
		s.title = HeroData.DATA[id].name if unlocked else "%s - %d xu" % [HeroData.DATA[id].name, HeroData.DATA[id].cost]


func _spawn_player(pos: Vector2) -> void:
	if player != null:
		pos = player.global_position
		player.queue_free()
	player = Player.new()
	player.setup(Global.selected_hero)
	player.position = pos
	world.add_child(player)
	if touch != null:
		touch.player = player


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var best = null
	var best_d := 9999.0
	for s in stations:
		s.near = false
		if not s.visible:
			continue
		var d: float = s.global_position.distance_to(player.global_position)
		if d < s.radius and d < best_d:
			best = s
			best_d = d
	if best != null:
		best.near = true
	player.interact_target = best


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not ui.is_open():
		_back_to_menu()


func _on_station(s) -> void:
	touch.reset()
	match s.kind:
		"hero":
			ui.open_hero(s.data)
		"forge":
			ui.open_forge()
		"rack":
			ui.open_rack()
		"stele":
			ui.open_stele()


## Gọi từ bảng tướng khi bấm "Chọn tướng này"
func select_hero(id: String) -> void:
	Global.selected_hero = id
	Global.save_game()
	_spawn_player(Vector2.ZERO)
	_refresh_heroes()


func set_player_active(on: bool) -> void:
	if player != null and is_instance_valid(player):
		player.set_physics_process(on)
		player.velocity = Vector2.ZERO


func _start_run() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play("level_clear")
	Global.save_game()
	Global.start_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _back_to_menu() -> void:
	Global.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
