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
const Cover = preload("res://scripts/entities/cover.gd")
const BlacksmithNpc = preload("res://scripts/entities/blacksmith_npc.gd")

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
var blacksmith: Node2D = null
var legend_id := ""          # phòng Tam Yêu: mã yêu quái
var loot_chest: Node2D = null
var covers: Array = []


func _ready() -> void:
	if kind == "combat":
		_spawn_covers()
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
		_spawn_blacksmith(rect.get_center() + Vector2(-95, -35))
	if kind == "exit" and randf() < 0.55:
		_spawn_blacksmith(rect.get_center() + Vector2(-70, 0))
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


static func waves_for_level(lv: int) -> int:
	if lv <= 1:
		return 1
	if lv <= 12:
		return 2
	return 3


func _enter() -> void:
	match kind:
		"combat":
			state = "fighting"
			_lock()
			_waves_left = waves_for_level(level)
			_spawn_wave()
		"boss":
			state = "fighting"
			_lock()
			Sfx.play("boss_appear")
			Sfx.play_music("boss")
			spawn_enemy("boss", rect.get_center() + Vector2(0, -20))
			var bid := EnemyData.boss_id(level)
			var b: Dictionary = EnemyData.BOSSES[bid]
			var n := EnemyData.boss_index(level) + 1
			get_tree().call_group("hud", "show_banner", "Trùm thứ %d: %s - %s" % [n, b.name, b.title])
		"legend":
			state = "fighting"
			_lock()
			Sfx.play("boss_appear")
			Sfx.play_music("boss")
			spawn_enemy("legend:" + legend_id, rect.get_center() + Vector2(0, -20))
			var lg: Dictionary = EnemyData.LEGENDS[legend_id]
			get_tree().call_group("hud", "show_banner", "Tam Yêu xuất hiện: %s - %s" % [lg.name, lg.title])
		"treasure":
			state = "done"
			_chest.play("open")
			Sfx.play("chest_open")
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
	var d = get_parent()
	var pos := inner.get_center()
	for i in 20:
		pos = Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y))
		var ok := p == null or pos.distance_to(p.global_position) > 90.0
		if ok and d != null and d.get("tiles") != null:
			var tl: TileMapLayer = d.tiles
			var cell: Vector2i = tl.local_to_map(tl.to_local(pos))
			if tl.get_cell_source_id(cell) == -1 or tl.get_cell_atlas_coords(cell).x in [4, 5, 6, 7, 8]:
				ok = false
		if ok:
			for c in covers:
				if is_instance_valid(c) and pos.distance_to(c.global_position) < 24.0:
					ok = false
					break
		if ok:
			break
	return pos


func _spawn_covers() -> void:
	var modern: bool = bool(EnemyData.chapter(level).get("modern", false))
	var dest_kind: String = "crate" if modern else "pot"
	var solid_kind: String = "sandbag" if modern else "stele"
	var c: Vector2 = rect.get_center()
	var layouts: Array = [
		[[Vector2(-72, -46), solid_kind], [Vector2(72, 46), solid_kind], [Vector2(72, -46), dest_kind], [Vector2(-72, 46), dest_kind]],
		[[Vector2(-68, -42), solid_kind], [Vector2(68, 42), solid_kind], [Vector2(-68, 42), dest_kind], [Vector2(68, -42), dest_kind]],
		[[Vector2(-76, -42), solid_kind], [Vector2(76, 42), solid_kind], [Vector2(64, -48), dest_kind], [Vector2(-64, 48), dest_kind]],
	]
	var chosen: Array = layouts[randi() % layouts.size()]
	for item in chosen:
		var pos: Vector2 = c + (item[0] as Vector2)
		var near_door: bool = false
		for dr in door_rects:
			if (dr as Rect2).grow(44.0).has_point(pos):
				near_door = true
				break
		if near_door:
			continue
		var cv := Cover.new()
		cv.kind = str(item[1])
		cv.position = pos
		add_child(cv)
		covers.append(cv)


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
		Sfx.play("level_clear")
		Sfx.play_music("battle")
		_spawn_portal(c + Vector2(0, -30))
		_spawn_weapon(c + Vector2(0, 24), 3)
		get_tree().call_group("hud", "show_banner", "Đại thắng! Giặc tan tác!")
	elif kind == "legend":
		Sfx.play("level_clear")
		Sfx.play_music("battle")
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
	if not door_rects.is_empty():
		Sfx.play("door_close")
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


func _spawn_blacksmith(pos: Vector2) -> void:
	var bn := BlacksmithNpc.new()
	bn.level = level
	bn.position = pos
	add_child(bn)
	blacksmith = bn


func _draw() -> void:
	if kind != "start":
		return
	var c := rect.get_center()
	var lines: Array
	if Global.touch_mode:
		lines = ["Cần gạt trái: di chuyển (tự ngắm giặc gần nhất)",
			"Nút phải: Đánh - Kỹ năng - Đổi/Nhặt vũ khí"]
	else:
		lines = ["WASD: di chuyển  -  Chuột trái: tấn công  -  Chuột phải / Space: kỹ năng",
			"Lăn chuột / Q: đổi vũ khí  -  E: nhặt / dùng  -  Esc: dừng"]
	for i in lines.size():
		Art.draw_text(self, c + Vector2(0, 62 + i * 13), lines[i], 13, Color(1, 1, 1, 0.6))
