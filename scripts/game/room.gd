extends Node2D
## Một phòng trong hầm ngục. Bước vào phòng có giặc: đóng cửa -> giặc tràn ra theo đợt
## -> dọn sạch thì mở cửa và hiện rương sơn mài.  kind: start, combat, treasure, shop, exit, boss, legend

signal portal_entered

const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Door = preload("res://scripts/entities/door.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Portal = preload("res://scripts/entities/portal.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const LootChest = preload("res://scripts/entities/loot_chest.gd")
const Shop = preload("res://scripts/game/shop.gd")

const T := 16
const MAX_ENEMIES := 14

var rect := Rect2()
var kind := "combat"
var level := 1
var door_rects: Array = []
var state := "idle"          # idle, fighting, done
var visited := false
var player_inside := false

var _doors: Array = []
var _enemies: Array = []
var _waves_left := 0
var _chest: AnimatedSprite2D = null
var shop: Node2D = null
var legend_id := ""          # phòng Tam Yêu: mã yêu quái
var loot_chest: Node2D = null


func _ready() -> void:
	if kind == "start":
		state = "done"
		# phòng đầu: màn 1 luôn có 1 vũ khí để nhặt (các màn sau 35%)
		if level == 1 or randf() < 0.35:
			_spawn_weapon.call_deferred(rect.get_center() + Vector2(40, -10), 0)
	if kind == "shop":
		state = "done"
		shop = Shop.new()
		shop.level = level
		shop.position = rect.get_center() + Vector2(0, 6)
		add_child(shop)
	if kind == "treasure":
		_chest = AnimatedSprite2D.new()
		_chest.sprite_frames = Art.frames("items/chest.png", 18, 11, {"closed": [[0], 1.0, false], "open": [[1], 1.0, false]})
		_chest.position = rect.get_center()
		_chest.scale = Vector2(1.5, 1.5)
		_chest.play("closed")
		add_child(_chest)


func _process(_delta: float) -> void:
	if kind == "start":
		queue_redraw()
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	player_inside = rect.has_point(p.global_position)
	if player_inside:
		visited = true
	if state == "idle" and not p.dead and rect.grow(-T * 1.5).has_point(p.global_position):
		_enter()


func _enter() -> void:
	match kind:
		"combat":
			state = "fighting"
			_lock()
			_waves_left = 1 if level == 1 else (2 if level < 7 else 3)
			_spawn_wave()
		"boss":
			state = "fighting"
			_lock()
			spawn_enemy("boss", rect.get_center() + Vector2(0, -20))
			var bid := EnemyData.boss_id(level)
			var b: Dictionary = EnemyData.BOSSES[bid]
			var n := EnemyData.boss_index(level) + 1
			get_tree().call_group("hud", "show_banner", "Trùm thứ %d: %s - %s" % [n, b.name, b.title])
		"legend":
			state = "fighting"
			_lock()
			spawn_enemy("legend:" + legend_id, rect.get_center() + Vector2(0, -20))
			var lg: Dictionary = EnemyData.LEGENDS[legend_id]
			get_tree().call_group("hud", "show_banner", "Tam Yêu xuất hiện: %s - %s" % [lg.name, lg.title])
		"treasure":
			state = "done"
			_chest.play("open")
			var c := rect.get_center()
			_spawn_weapon(c + Vector2(0, 18), 2)
			_drop("potion", 2, c + Vector2(-16, 16))
			Fx.particles(get_parent(), c, Color(1, 0.85, 0.3), 24, 120.0, 0.7, -40.0, 2.0)
			Fx.burst(get_parent(), c, Color(1, 0.85, 0.3), 40.0, 0.5)
		"exit":
			state = "done"
			_spawn_portal(rect.get_center())


func _spawn_wave() -> void:
	if state != "fighting":
		return
	_waves_left -= 1
	var pool := EnemyData.pool(level)
	var depth := (level - 1) % 30
	var n := mini(3 + int(depth / 3) + randi() % 3, 10)
	for i in n:
		spawn_enemy(pool.pick_random(), _random_point(), randf() < 0.06 + 0.01 * depth)


func spawn_enemy(k: String, pos: Vector2, elite := false) -> void:
	if _enemies.size() >= MAX_ENEMIES and k != "boss" and not k.begins_with("legend:"):
		return
	var inner := rect.grow(-T * 1.5)
	var e := Enemy.new()
	e.setup(k, level, get_tree().get_first_node_in_group("player"))
	if elite and k != "boss" and not k.begins_with("legend:"):
		e.make_elite()
	e.position = pos.clamp(inner.position, inner.end)
	e.room = self
	e.killed.connect(_on_enemy_killed)
	_enemies.append(e)
	get_parent().add_child(e)


func _random_point() -> Vector2:
	var inner := rect.grow(-T * 2.0)
	var p = get_tree().get_first_node_in_group("player")
	var pos := inner.get_center()
	for i in 20:
		pos = Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y))
		if p == null or pos.distance_to(p.global_position) > 90.0:
			break
	return pos


func _on_enemy_killed(e) -> void:
	_enemies.erase(e)
	if e.is_boss():
		_waves_left = 0
		for other in _enemies.duplicate():
			if is_instance_valid(other):
				other.die(false)
		_enemies.clear()
	if _enemies.is_empty():
		if _waves_left > 0:
			get_tree().create_timer(0.7).timeout.connect(_spawn_wave)
		else:
			_clear.call_deferred()


func _clear() -> void:
	if state == "done":
		return
	state = "done"
	for d in _doors:
		if is_instance_valid(d):
			Fx.anim(get_parent(), d.position + d.size / 2.0, "fx/poof.png", 28, 28, 16.0)
			d.queue_free()
	_doors.clear()
	var p = get_tree().get_first_node_in_group("player")
	var c := rect.get_center()
	var near: Vector2 = p.global_position if p != null else c
	for i in 3:
		_drop("energy", 5, near)
	if kind == "boss":
		_spawn_portal(c + Vector2(0, -30))
		_spawn_weapon(c + Vector2(0, 24), 3)
		get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
	elif kind == "legend":
		_spawn_portal(c + Vector2(0, -30))
		_spawn_weapon(c + Vector2(0, 24), 2)
		for i in 12:
			_drop("coin", 2, c)
		get_tree().call_group("hud", "show_banner", "Diệt yêu trừ hại, như Lạc Long Quân năm xưa!")
	else:
		# rương sơn mài chiến lợi phẩm sau mỗi phòng dọn sạch
		loot_chest = LootChest.new()
		loot_chest.level = level
		loot_chest.position = c
		get_parent().add_child(loot_chest)


func _lock() -> void:
	for r in door_rects:
		var d := Door.new()
		d.size = r.size
		d.position = r.position
		get_parent().add_child(d)
		_doors.append(d)


func drop_weapon_at(pos: Vector2, bonus: int) -> void:
	_spawn_weapon.call_deferred(pos, bonus)


func _spawn_weapon(pos: Vector2, bonus: int) -> void:
	var p := Pickup.new()
	p.kind = "weapon"
	p.weapon_id = WeaponData.roll(level, bonus)
	p.position = pos
	get_parent().add_child(p)


func _drop(k: String, amount: int, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = k
	p.amount = amount
	p.position = pos
	get_parent().add_child(p)


func _spawn_portal(pos: Vector2) -> void:
	var portal := Portal.new()
	portal.position = pos
	portal.entered.connect(func(): portal_entered.emit())
	get_parent().add_child(portal)


func _draw() -> void:
	if kind != "start":
		return
	var c := rect.get_center()
	var lines: Array
	if Global.touch_mode:
		lines = ["Cần gạt trái: di chuyển (tự ngắm giặc gần nhất)",
			"Nút phải: Đánh - Kỹ năng - Đổi/Nhặt vũ khí"]
	else:
		lines = ["WASD: di chuyển  -  Chuột trái: tấn công",
			"Chuột phải / Space: kỹ năng  -  E: nhặt/đổi vũ khí  -  Esc: dừng"]
	for i in lines.size():
		Art.draw_text(self, c + Vector2(0, 62 + i * 13), lines[i], 13, Color(1, 1, 1, 0.6))
