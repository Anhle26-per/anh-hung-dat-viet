extends Node2D
## Đấu trường Thủ Thành Cổ Loa (v3.0.0): Thành Ốc 3 vòng, hào nước cầu gỗ, 4 cổng thành
## sống động & bảo vệ Nỏ Thần Cổ Loa qua các đợt tiến công vô tận.

signal portal_entered
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal core_destroyed

const CoLoaData = preload("res://scripts/data/co_loa_data.gd")
const CoLoaCore = preload("res://scripts/entities/co_loa_core.gd")
const DefenseTower = preload("res://scripts/entities/defense_tower.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const PREP_DURATION := 10.0
const COLOA_BG_PATH := "res://assets/sprites/world/coloa_bg.png"
const GATE_ARCH_PATH := "res://assets/sprites/world/coloa_gate_arch.png"


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

var _arena_built: bool = false
var _enemies: Array = []
var _spawn_queue: Array[String] = []
var _spawn_t: float = 0.0
var _spawn_interval: float = 0.8
var _elite_chance: float = 0.08
var _lane_cursor: int = 0
var _start_f_down: bool = false
var _fx_t: float = 0.0
var _sway_nodes: Array = []


func _ready() -> void:
	add_to_group("dungeon")
	add_to_group("co_loa_defense")
	setup_arena()


func setup_arena() -> void:
	if _arena_built:
		return
	_arena_built = true
	var ar := ArenaRoom.new()
	ar.rect = CoLoaData.ARENA_RECT
	rooms[Vector2i.ZERO] = ar

	if ResourceLoader.exists(COLOA_BG_PATH):
		var bg := Sprite2D.new()
		bg.texture = Art.tex("world/coloa_bg.png")
		bg.position = Vector2.ZERO
		bg.z_index = -5
		add_child(bg)

	_build_perimeter_walls()
	_build_fortress_props()

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

	if Global != null and Global.run_coins < 45:
		var bonus: int = 20 if (Global.rescued_npcs is Array and Global.rescued_npcs.has("quan_su_co_loa")) else 0
		Global.run_coins = 45 + bonus

	state = "prep"
	prep_time = PREP_DURATION
	queue_redraw()


func _add_wall_rect(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	body.add_child(cs)
	add_child(body)


func _build_perimeter_walls() -> void:
	var r: Rect2 = CoLoaData.ARENA_RECT
	var t: float = 24.0
	_add_wall_rect(Rect2(r.position.x - t, r.position.y - t, r.size.x + t * 2.0, t))
	_add_wall_rect(Rect2(r.position.x - t, r.end.y, r.size.x + t * 2.0, t))
	_add_wall_rect(Rect2(r.position.x - t, r.position.y, t, r.size.y))
	_add_wall_rect(Rect2(r.end.x, r.position.y, t, r.size.y))


func _prop(rel: String, pos: Vector2, z: int = 0) -> Sprite2D:
	if not ResourceLoader.exists("res://assets/sprites/" + rel):
		return null
	var sp := Sprite2D.new()
	sp.texture = Art.tex(rel)
	sp.position = pos
	sp.z_index = z
	add_child(sp)
	return sp


func _anim_prop(rel: String, fw: int, fh: int, fps: float, pos: Vector2, light_col: Color = Color.TRANSPARENT, z: int = 1) -> AnimatedSprite2D:
	if not ResourceLoader.exists("res://assets/sprites/" + rel):
		return null
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Art.strip(rel, fw, fh, fps, true)
	a.play("play")
	a.position = pos
	a.z_index = z
	add_child(a)
	if light_col != Color.TRANSPARENT:
		var lt := Art.light(light_col, 1.05, 0.78)
		lt.position = Vector2(0.0, -6.0)
		a.add_child(lt)
	return a


func _build_fortress_props() -> void:
	# 4 Cổng Thành mái ngói cong + Đỉnh lửa sáng rực
	var gate_positions: Array[Vector2] = [
		Vector2(0.0, -214.0),
		Vector2(0.0, 206.0),
		Vector2(-306.0, -4.0),
		Vector2(306.0, -4.0),
	]
	if ResourceLoader.exists(GATE_ARCH_PATH):
		for gp in gate_positions:
			_prop("world/coloa_gate_arch.png", gp + Vector2(0.0, -14.0), 3)

	var braziers: Array[Vector2] = [
		Vector2(-46.0, -196.0), Vector2(46.0, -196.0),
		Vector2(-46.0, 214.0), Vector2(46.0, 214.0),
		Vector2(-290.0, -42.0), Vector2(-290.0, 40.0),
		Vector2(290.0, -42.0), Vector2(290.0, 40.0),
		Vector2(-68.0, -48.0), Vector2(68.0, -48.0),
		Vector2(-68.0, 50.0), Vector2(68.0, 50.0),
	]
	for bp in braziers:
		_anim_prop("world/prop_brazier.png", 26, 32, 6.5, bp, Color(1.0, 0.60, 0.24), 1)

	# Tượng Nghê chầu Nỏ Thần & Cờ chiến Cổ Loa tại 4 góc quảng trường
	for np in [Vector2(-46.0, -6.0), Vector2(46.0, -6.0)]:
		var nsp := _prop("world/nghe.png", np, 1)
		if nsp != null and np.x < 0.0:
			nsp.flip_h = true
	for fp in [Vector2(-224.0, -146.0), Vector2(224.0, -146.0), Vector2(-224.0, 146.0), Vector2(224.0, 146.0)]:
		_prop("world/prop_flag_stand.png", fp + Vector2(0.0, -12.0), 1)
		_anim_prop("world/prop_stone_lantern.png", 32, 48, 4.0, fp + Vector2(24.0 if fp.x < 0.0 else -24.0, 6.0), Color(1.0, 0.78, 0.42), 1)

	# Bao cát phòng tuyến ngoài cầu & khóm tre xanh 4 góc đồng cỏ
	for sb in [
		Vector2(-42.0, -298.0), Vector2(42.0, -298.0),
		Vector2(-42.0, 298.0), Vector2(42.0, 298.0),
		Vector2(-404.0, -44.0), Vector2(-404.0, 44.0),
		Vector2(404.0, -44.0), Vector2(404.0, 44.0),
	]:
		_prop("world/sandbag.png", sb, 0)

	for cp in [
		Vector2(-485.0, -330.0), Vector2(-438.0, -345.0),
		Vector2(485.0, -330.0), Vector2(438.0, -345.0),
		Vector2(-485.0, 330.0), Vector2(-438.0, 345.0),
		Vector2(485.0, 330.0), Vector2(438.0, 345.0),
	]:
		var piv := Node2D.new()
		piv.position = cp
		add_child(piv)
		if ResourceLoader.exists("res://assets/sprites/world/lobby_bamboo.png"):
			var bsp := Sprite2D.new()
			bsp.texture = Art.tex("world/lobby_bamboo.png")
			bsp.position = Vector2(0.0, -22.0)
			piv.add_child(bsp)
		_sway_nodes.append(piv)

	# Đom đóm & tàn lửa vàng nhạt bay khắp chiến trường Cổ Loa
	var motes := CPUParticles2D.new()
	motes.position = Vector2.ZERO
	motes.amount = 34
	motes.lifetime = 4.2
	motes.preprocess = 4.2
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(520.0, 360.0)
	motes.direction = Vector2(0.3, -1.0)
	motes.spread = 35.0
	motes.gravity = Vector2(0.0, -6.0)
	motes.initial_velocity_min = 6.0
	motes.initial_velocity_max = 15.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.0
	var mg := Gradient.new()
	mg.set_color(0, Color(1.0, 0.88, 0.42, 0.0))
	mg.add_point(0.45, Color(1.0, 0.86, 0.42, 0.72))
	mg.set_color(mg.get_point_count() - 1, Color(1.0, 0.72, 0.28, 0.0))
	motes.color_ramp = mg
	motes.material = Art.additive()
	motes.z_index = 4
	add_child(motes)


func start_position() -> Vector2:
	return Vector2(0.0, 62.0)


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
		Sfx.play("war_drum")
		if bool(cfg.get("is_boss", false)):
			Sfx.play("boss_appear")
			Sfx.play_music("coloa_siege", 0.45)
	queue_redraw()


func _process(delta: float) -> void:
	_fx_t += delta
	for i in _sway_nodes.size():
		var nd: Node2D = _sway_nodes[i] as Node2D
		if nd != null and is_instance_valid(nd):
			nd.rotation = sin(_fx_t * 1.5 + float(i) * 1.2) * 0.03
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
	var jitter := Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
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
		var np: Node = Global.nearest_player(e2.global_position) if Global != null else null
		var dist_player: float = e2.global_position.distance_to((np as Node2D).global_position) if (np != null and is_instance_valid(np)) else INF
		if dist_player > 165.0 and core != null and is_instance_valid(core):
			var to_core: Vector2 = (core as Node2D).global_position - e2.global_position
			if to_core.length_squared() > 4.0:
				var spd: float = clampf(float(e.get("speed")) * 0.5, 16.0, 44.0)
				e2.global_position += to_core.normalized() * spd * delta

		if core != null and is_instance_valid(core) and core.has_method("distance_to_hurtbox"):
			if float(core.distance_to_hurtbox(e2.global_position)) <= eradius + 10.0:
				var cd_until: float = float(e.get_meta("coloa_core_cd", 0.0))
				if now_sec >= cd_until:
					e.set_meta("coloa_core_cd", now_sec + 1.1)
					var dmg_core: int = 3 if (e.has_method("is_boss") and e.is_boss()) else (2 if bool(e.get("elite")) else 1)
					core.take_damage(dmg_core)

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

	var mat_pool: Array = MaterialData.ORDER
	if not mat_pool.is_empty():
		var pk := Pickup.new()
		pk.kind = "material"
		pk.material_id = str(mat_pool[wave % mat_pool.size()])
		pk.amount = 1 + (1 if wave % 5 == 0 else 0)
		pk.position = Vector2(randf_range(-32.0, 32.0), 34.0)
		add_child(pk)

	if wave % 4 == 0:
		_roll_wave_relic()

	if Sfx != null:
		Sfx.play("level_clear")
		if bool(cfg.get("is_boss", false)):
			Sfx.play_music("coloa_defense", 0.75)
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
	Fx.float_text(self, Vector2(0.0, -48.0), "★ Cổ Vật: %s ★" % rname, rcol, 15)


func _on_core_destroyed() -> void:
	state = "gameover"
	_spawn_queue.clear()
	core_destroyed.emit()
	if is_inside_tree():
		get_tree().call_group("hud", "show_banner", "Nỏ Thần Cổ Loa đã thất thủ ở Đợt %d!" % wave)
	queue_redraw()


func _draw() -> void:
	# Dấu cổng tiến công 4 hướng (mũi tên cảnh báo hướng giặc xuất hiện)
	var pulse: float = 0.45 + 0.45 * sin(_fx_t * 5.0)
	var warn_col := Color(1.0, 0.42, 0.30, (0.35 + 0.45 * pulse) if state == "prep" else 0.32)
	for i in CoLoaData.SPAWN_LANES.size():
		var lane: Vector2 = CoLoaData.SPAWN_LANES[i]
		var inward: Vector2 = (-lane).normalized()
		var side := Vector2(-inward.y, inward.x)
		draw_circle(lane, 20.0, Color(0.95, 0.28, 0.24, 0.16))
		draw_arc(lane, 20.0, 0.0, TAU, 24, warn_col, 1.5)
		var tip: Vector2 = lane + inward * (28.0 + pulse * 5.0)
		draw_colored_polygon(PackedVector2Array([
			tip + inward * 8.0,
			tip - inward * 4.0 + side * 7.0,
			tip - inward * 4.0 - side * 7.0,
		]), warn_col)
		if i < CoLoaData.GATE_NAMES.size():
			Art.draw_text(self, lane + inward * 42.0, CoLoaData.GATE_NAMES[i], 10, Color(1.0, 0.82, 0.48, 0.85), true)
