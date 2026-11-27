extends Node2D
## Đấu trường Thủ Thành Cổ Loa (v3.0.0): bảo vệ Nỏ Thần Cổ Loa qua các đợt tiến công vô tận.

signal portal_entered
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal core_destroyed

const CoLoaData = preload("res://scripts/data/co_loa_data.gd")
const CoLoaCore = preload("res://scripts/entities/co_loa_core.gd")
const DefenseTower = preload("res://scripts/entities/defense_tower.gd")
const Dungeon = preload("res://scripts/game/dungeon.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const T := 16
const HALF_W := 34
const HALF_H := 24
const PREP_DURATION := 10.0


class ArenaRoom extends RefCounted:
	var rect: Rect2 = CoLoaData.ARENA_RECT
	var kind: String = "start"
	var visited: bool = true
	var player_inside: bool = true


var wave: int = 0
var state: String = "prep"      # "prep" | "fighting" | "gameover"
var prep_time: float = PREP_DURATION
var core: Node = null
var towers: Array = []
var tiles: TileMapLayer = null
var rooms: Dictionary = {}
var links: Array = []

var _enemies: Array = []
var _spawn_queue: Array[String] = []
var _spawn_t: float = 0.0
var _spawn_interval: float = 0.8
var _elite_chance: float = 0.08
var _lane_cursor: int = 0
var _start_f_down: bool = false


func _ready() -> void:
	add_to_group("dungeon")
	add_to_group("co_loa_defense")
	setup_arena()


func setup_arena() -> void:
	if tiles != null and is_instance_valid(tiles):
		return
	var ar := ArenaRoom.new()
	ar.rect = CoLoaData.ARENA_RECT
	rooms[Vector2i.ZERO] = ar

	tiles = TileMapLayer.new()
	tiles.tile_set = _make_tileset()
	tiles.z_index = -2
	add_child(tiles)

	var floor_cells: Dictionary = {}
	for x in range(-HALF_W, HALF_W + 1):
		for y in range(-HALF_H, HALF_H + 1):
			floor_cells[Vector2i(x, y)] = true

	Dungeon.paint(tiles, floor_cells, 2)
	var shade := TileMapLayer.new()
	shade.tile_set = tiles.tile_set
	shade.z_index = -1
	add_child(shade)
	Dungeon.paint_shadows(shade, floor_cells)

	core = CoLoaCore.new()
	core.position = CoLoaData.CORE_POS
	var pc: int = Net.player_count() if Net != null else 1
	core.setup(pc)
	core.destroyed.connect(_on_core_destroyed)
	add_child(core)

	towers.clear()
	for i in CoLoaData.PAD_POSITIONS.size():
		var tw := DefenseTower.new()
		tw.pad_id = i
		tw.position = CoLoaData.PAD_POSITIONS[i]
		add_child(tw)
		towers.append(tw)

	state = "prep"
	prep_time = PREP_DURATION
	queue_redraw()


func start_position() -> Vector2:
	return Vector2(0.0, 56.0)


func neighbors_of(_c: Vector2i) -> Array:
	return []


func get_towers_summary() -> Array:
	var out: Array = []
	for t in towers:
		if t != null and is_instance_valid(t) and t.has_method("export_state"):
			out.append(t.export_state())
	return out


func start_next_wave() -> void:
	if state != "prep":
		return
	wave += 1
	state = "fighting"
	var cfg: Dictionary = CoLoaData.wave_config(wave)
	_spawn_queue.clear()
	for k in cfg.get("spawns", []):
		_spawn_queue.append(str(k))
	_spawn_interval = float(cfg.get("spawn_interval", 0.75))
	_elite_chance = float(cfg.get("elite_chance", 0.08))
	_spawn_t = 0.25
	wave_started.emit(wave)
	if is_inside_tree():
		var msg: String = "Đợt %d — %s" % [wave, "ĐẠI TƯỚNG CÔNG THÀNH!" if bool(cfg.get("is_boss", false)) else "Quân giặc tràn vào Cổ Loa!"]
		get_tree().call_group("hud", "show_banner", msg)
	if Sfx != null:
		Sfx.play("boss_appear" if bool(cfg.get("is_boss", false)) else "door_close")
	queue_redraw()


func _process(delta: float) -> void:
	if state == "gameover":
		return
	var is_auth: bool = Net == null or not Net.is_online() or Net.is_host()
	if state == "prep":
		if is_auth:
			prep_time -= delta
			var f_pressed: bool = Input.is_physical_key_pressed(KEY_F)
			var action_pressed: bool = InputMap.has_action("start_wave") and Input.is_action_just_pressed("start_wave")
			if action_pressed or (f_pressed and not _start_f_down):
				_start_f_down = f_pressed
				start_next_wave()
				return
			_start_f_down = f_pressed
			if prep_time <= 0.0:
				start_next_wave()
		queue_redraw()
	elif state == "fighting" and is_auth:
		_process_fighting(delta)


func _physics_process(delta: float) -> void:
	if state != "fighting":
		return
	if Net != null and Net.is_online() and not Net.is_host():
		return
	_update_enemy_pressure(delta)


func _process_fighting(delta: float) -> void:
	if not _spawn_queue.is_empty():
		_spawn_t -= delta
		if _spawn_t <= 0.0:
			_spawn_t = _spawn_interval
			var next_kind: String = str(_spawn_queue.pop_front())
			_spawn_lane_enemy(next_kind)
	_prune_enemies()
	if _spawn_queue.is_empty() and _enemies.is_empty():
		_on_wave_cleared()


func _spawn_lane_enemy(kind: String) -> void:
	if CoLoaData.SPAWN_LANES.is_empty():
		return
	var lane_pos: Vector2 = CoLoaData.SPAWN_LANES[_lane_cursor % CoLoaData.SPAWN_LANES.size()]
	_lane_cursor += 1
	var jitter := Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
	var spawn_pos: Vector2 = lane_pos + jitter
	var eff_level: int = maxi(1, wave)

	var actual_kind: String = kind
	if kind == "boss":
		var boss_keys: Array = EnemyData.BOSSES.keys()
		if not boss_keys.is_empty():
			var idx: int = int(maxi(0, (wave / 5) - 1)) % boss_keys.size()
			if Global != null and Global.has_method("boss_at"):
				Global.boss_at(idx)
		actual_kind = "boss"

	var e := Enemy.new()
	var target_node: Node = Global.nearest_player(spawn_pos) if Global != null else null
	if target_node == null:
		target_node = core
	e.setup(actual_kind, eff_level, target_node)
	if actual_kind != "boss" and randf() < _elite_chance:
		e.make_elite()
	e.position = spawn_pos
	e.killed.connect(_on_enemy_killed)
	_enemies.append(e)
	add_child(e)
	Fx.burst(self, spawn_pos, Color(0.95, 0.35, 0.32), 20.0, 0.28)


func _update_enemy_pressure(delta: float) -> void:
	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	for e in _enemies:
		if not is_instance_valid(e) or bool(e.get("dead")) or (e.has_method("is_spawning") and e.is_spawning()):
			continue
		var e2: Node2D = e as Node2D
		var eradius: float = float(e.get("radius"))
		# Nếu người chơi ở xa, kéo nhẹ giặc tiến về Nỏ Thần Cổ Loa
		var np: Node = Global.nearest_player(e2.global_position) if Global != null else null
		var dist_player: float = e2.global_position.distance_to((np as Node2D).global_position) if (np != null and is_instance_valid(np)) else INF
		if dist_player > 165.0 and core != null and is_instance_valid(core):
			var to_core: Vector2 = (core as Node2D).global_position - e2.global_position
			if to_core.length_squared() > 4.0:
				var spd: float = clampf(float(e.get("speed")) * 0.5, 16.0, 44.0)
				e2.global_position += to_core.normalized() * spd * delta

		# Tấn công cận chiến vào Nỏ Thần Cổ Loa
		if core != null and is_instance_valid(core) and core.has_method("distance_to_hurtbox"):
			if float(core.distance_to_hurtbox(e2.global_position)) <= eradius + 10.0:
				var cd_until: float = float(e.get_meta("coloa_core_cd", 0.0))
				if now_sec >= cd_until:
					e.set_meta("coloa_core_cd", now_sec + 1.1)
					var dmg_core: int = 3 if (e.has_method("is_boss") and e.is_boss()) else (2 if bool(e.get("elite")) else 1)
					core.take_damage(dmg_core)

		# Tấn công vào Tháp phòng thủ lân cận
		for tw in towers:
			if tw == null or not is_instance_valid(tw) or int(tw.get("tier")) <= 0:
				continue
			if e2.global_position.distance_to((tw as Node2D).global_position) <= eradius + 16.0:
				var tw_cd: float = float(e.get_meta("coloa_tw_cd", 0.0))
				if now_sec >= tw_cd:
					e.set_meta("coloa_tw_cd", now_sec + 1.1)
					var dmg_tw: int = 4 if (e.has_method("is_boss") and e.is_boss()) else (2 if bool(e.get("elite")) else 1)
					tw.take_damage(dmg_tw)
				break


func _on_enemy_killed(e: Node) -> void:
	_enemies.erase(e)


func _prune_enemies() -> void:
	var alive: Array = []
	for e in _enemies:
		if is_instance_valid(e) and not bool(e.get("dead")):
			alive.append(e)
	_enemies = alive


func _on_wave_cleared() -> void:
	var cfg: Dictionary = CoLoaData.wave_config(wave)
	var reward: int = int(cfg.get("reward_coins", 25 + wave * 6))
	if Global != null:
		Global.run_coins += reward
		Global.stats["best_co_loa_wave"] = maxi(int(Global.stats.get("best_co_loa_wave", 0)), wave)
		var lp: Node = Global.local_player()
		if lp != null and is_instance_valid(lp) and lp.has_signal("stats_changed"):
			lp.stats_changed.emit()

	# Rơi nguyên liệu quanh tâm
	var mat_pool: Array = MaterialData.ORDER
	if not mat_pool.is_empty():
		var pk := Pickup.new()
		pk.kind = "material"
		pk.material_id = str(mat_pool[wave % mat_pool.size()])
		pk.amount = 1 + (1 if wave % 5 == 0 else 0)
		pk.position = Vector2(randf_range(-32.0, 32.0), 34.0)
		add_child(pk)

	# Mỗi 4 đợt tặng Cổ Vật nếu hệ thống Cổ Vật sẵn sàng
	if wave % 4 == 0:
		_roll_wave_relic()

	if Sfx != null:
		Sfx.play("level_clear")
	if is_inside_tree():
		get_tree().call_group("hud", "show_banner", "Vượt Đợt %d! (+%d xu)  [F] Gọi đợt kế" % [wave, reward])
	wave_cleared.emit(wave)
	state = "prep"
	prep_time = PREP_DURATION
	queue_redraw()


func _roll_wave_relic() -> void:
	var relic_path := "res://scripts/data/relics.gd"
	if not ResourceLoader.exists(relic_path):
		return
	var rscript := load(relic_path)
	if rscript == null or not rscript.has_method("roll_relic"):
		return
	var owned: Array = []
	if Global != null and Global.get("run_relics") is Array:
		owned = Global.get("run_relics") as Array
	var rid: String = str(rscript.roll_relic(owned))
	if rid == "":
		return
	var rinfo: Dictionary = rscript.get_relic(rid) if rscript.has_method("get_relic") else {}
	if Global != null and Global.has_method("add_relic"):
		Global.call("add_relic", rid)
	elif Global != null and Global.get("run_relics") is Array:
		(Global.get("run_relics") as Array).append(rid)
	var rname: String = str(rinfo.get("name", rid))
	var rcol: Color = rinfo.get("color", Color(1.0, 0.85, 0.35))
	Fx.float_text(self, Vector2(0.0, -36.0), "★ Cổ Vật: %s ★" % rname, rcol, 15)


func _on_core_destroyed() -> void:
	state = "gameover"
	_spawn_queue.clear()
	core_destroyed.emit()
	if is_inside_tree():
		get_tree().call_group("hud", "show_banner", "Nỏ Thần Cổ Loa đã thất thủ ở Đợt %d!" % wave)
	queue_redraw()


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = Art.tex("world/tiles.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var h := T / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for row in int(src.texture.get_height() / T):
		for col in int(src.texture.get_width() / T):
			src.create_tile(Vector2i(col, row))
			if col >= 4 and col <= 8:
				var td := src.get_tile_data(Vector2i(col, row), 0)
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, square)
	var sh := TileSetAtlasSource.new()
	sh.texture = Art.tex("world/shadows.png")
	sh.texture_region_size = Vector2i(T, T)
	ts.add_source(sh, 1)
	for i in 3:
		sh.create_tile(Vector2i(i, 0))
	return ts


func _draw() -> void:
	# 4 đường hành quân dẫn vào Nỏ Thần
	var road_col := Color(0.86, 0.68, 0.32, 0.14)
	draw_line(Vector2(0.0, -340.0), Vector2(0.0, 340.0), road_col, 24.0)
	draw_line(Vector2(-490.0, 0.0), Vector2(490.0, 0.0), road_col, 24.0)
	draw_arc(CoLoaData.CORE_POS, 120.0, 0.0, TAU, 48, Color(0.95, 0.78, 0.34, 0.18), 2.0)
	draw_arc(CoLoaData.CORE_POS, 245.0, 0.0, TAU, 56, Color(0.95, 0.78, 0.34, 0.10), 1.5)
	for lane in CoLoaData.SPAWN_LANES:
		draw_circle(lane, 18.0, Color(0.95, 0.30, 0.26, 0.18))
		draw_arc(lane, 18.0, 0.0, TAU, 24, Color(1.0, 0.44, 0.34, 0.55), 1.5)
	if state == "prep":
		Art.draw_text(self, Vector2(0.0, -56.0), "Chuẩn bị Đợt %d (%.0fs) — [F] Gọi giặc ngay" % [wave + 1, maxf(0.0, prep_time)], 13, Color(1.0, 0.92, 0.55), true)
	elif state == "fighting":
		Art.draw_text(self, Vector2(0.0, -56.0), "Đợt %d — Đang giao chiến (%d giặc)" % [wave, _spawn_queue.size() + _enemies.size()], 13, Color(1.0, 0.58, 0.44), true)
