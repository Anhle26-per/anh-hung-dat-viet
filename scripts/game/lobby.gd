extends Node2D
## Sảnh chính "Doanh trại Anh Hùng" 4 phòng kiểu Soul Knight (1360 x 760):
##   - Đại Sảnh Anh Hùng (giữa): 14 vị tướng, trống đồng, trà đạo, đài thiên phú, 3 hành lang nối
##   - Vườn Sen & Chiến Tích (tây): Hồ sen, Bia ghi công, Giếng Ước, Bảng Khiêu Chiến, Đài Thức Tỉnh
##   - Xưởng Rèn & Võ Đường (đông): Lò rèn, Giá binh khí, Bách Khoa Toàn Thư, 3 Hình nhân, Võ Đài Tỷ Thí
##   - Đại Cổng Xuất Trận (bắc): Cổng thời gian bắt đầu hành trình

const Player = preload("res://scripts/entities/player.gd")
const Pet = preload("res://scripts/entities/pet.gd")
const Portal = preload("res://scripts/entities/portal.gd")
const Decor = preload("res://scripts/game/decor.gd")
const Station = preload("res://scripts/game/station.gd")
const Dummy = preload("res://scripts/game/dummy.gd")
const LobbyLife = preload("res://scripts/game/lobby_life.gd")
const Ambience = preload("res://scripts/game/ambience.gd")
const LobbyUI = preload("res://scripts/ui/lobby_ui.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const HeroSkins = preload("res://scripts/data/hero_skins.gd")
const CampNpcs = preload("res://scripts/data/camp_npcs.gd")
const SparringArena = preload("res://scripts/entities/sparring_arena.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const Art = preload("res://scripts/art/art.gd")

static func _hotpatch_sync() -> Script:
	var gdc_path := "res://scripts/autoload/hotpatch_sync.gdc"
	var gd_path := "res://scripts/autoload/hotpatch_sync.gd"
	var load_path := gdc_path if FileAccess.file_exists(gdc_path) else gd_path
	var fresh := ResourceLoader.load(load_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if fresh != null:
		fresh.take_over_path(gdc_path)
		fresh.take_over_path(gd_path)
	return fresh

const SIZE := Vector2(1360, 760)
const HALL_CENTER := Vector2(680, 446)
const SPAWN_POS := Vector2(680, 524)
const BASEMENT_ORIGIN := Vector2(240, 900)
const BASEMENT_RECT := Rect2(240, 900, 880, 560)
const BASEMENT_SPAWN := Vector2(680, 1020)
const SURFACE_RETURN_POS := Vector2(680, 622)

const ROOMS: Array[Dictionary] = [
	{"id": "center", "name": "Đại Sảnh Anh Hùng", "rect": Rect2(460, 250, 440, 440)},
	{"id": "west", "name": "Vườn Sen & Chiến Tích", "rect": Rect2(40, 250, 380, 440)},
	{"id": "east", "name": "Xưởng Rèn & Võ Đường", "rect": Rect2(940, 250, 380, 440)},
	{"id": "north", "name": "Đại Cổng Xuất Trận", "rect": Rect2(460, 20, 440, 190)},
]

const HERO_SPOTS: Array[Vector2] = [
	Vector2(502, 328), Vector2(552, 328), Vector2(602, 328),
	Vector2(522, 382), Vector2(582, 382),
	Vector2(760, 328), Vector2(810, 328), Vector2(860, 328),
	Vector2(780, 382), Vector2(840, 382),
	Vector2(504, 534), Vector2(558, 534),
	Vector2(802, 534), Vector2(856, 534),
]

var world: Node2D
var player
var lobby_pet: Node = null
var camera: Camera2D
var ui
var touch
var stations: Array = []
var stair_stations: Array = []
var in_basement: bool = false
var hero_confirmed: bool = false
var well_uses: int = 3
var supply_claimed: bool = false
var garden_watered: bool = false
var fortune_rolled: bool = false
var pet_gifts: Dictionary = {}
var koi_fed: bool = false
var merchant_deal: String = ""
var merchant_bundle_bought: bool = false
var remote_players: Dictionary = {}
var remote_pets: Dictionary = {}
var _hero_npcs := {}
var _npc_nodes: Dictionary = {}
var _rescued_npc_nodes: Dictionary = {}
var _animal_nodes: Dictionary = {}
var _pet_stations: Array = []
var _basement_stations: Array = []
var _basement_down_st: Node2D = null
var _basement_up_st: Node2D = null
var _north_portal: Node2D = null
var _hero_overlay: Node2D = null
var _trophy_wall: Node2D = null
var _trophies_count: int = 0
var _sparring_arena: Node2D = null
var _garden_wrap: Node2D = null
var _hovered_hero_id: String = ""
var _cursor_hero_idx: int = 0
var _canvas_mod: CanvasModulate = null
var _transitioning: bool = false
var _leaving := false


class HeroRingOverlay extends Node2D:
	var lobby = null
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if lobby == null:
			return
		var hovered: String = str(lobby.get("_hovered_hero_id"))
		var confirmed: bool = bool(lobby.get("hero_confirmed"))
		for id in lobby._hero_npcs:
			var st: Node2D = lobby._hero_npcs[id]
			if st == null or not is_instance_valid(st) or not st.visible:
				continue
			var pos: Vector2 = st.position + Vector2(0, 8)
			var is_hov: bool = (str(id) == hovered)
			var unl: bool = lobby._is_hero_unlocked(str(id))
			var pulse: float = 0.72 + 0.28 * sin(t * 7.5)
			var hcol := Color(0.45, 0.96, 1.0, pulse) if unl else Color(1.0, 0.72, 0.35, pulse)

			if is_hov:
				# Cột sáng mềm phía sau vị tướng đang trỏ
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(-11.0, 2.0),
					pos + Vector2(11.0, 2.0),
					pos + Vector2(6.5, -40.0),
					pos + Vector2(-6.5, -40.0),
				]), Color(hcol.r, hcol.g, hcol.b, 0.13 * pulse))
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(-6.0, 1.0),
					pos + Vector2(6.0, 1.0),
					pos + Vector2(3.5, -34.0),
					pos + Vector2(-3.5, -34.0),
				]), Color(1.0, 0.96, 0.78, 0.10 * pulse))

			var base_a: float = (0.45 if unl else 0.22) if not confirmed else 0.18
			var base_col := Color(1.0, 0.86, 0.38, base_a) if unl else Color(0.65, 0.65, 0.7, base_a)
			draw_set_transform(pos, 0.0, Vector2(1.0, 0.42))
			if is_hov:
				draw_circle(Vector2.ZERO, 19.0 + sin(t * 6.0) * 1.0, Color(hcol.r, hcol.g, hcol.b, 0.18 * pulse))
			draw_arc(Vector2.ZERO, 13.0 + sin(t * 3.0) * 0.8, 0.0, TAU, 24, base_col, 1.4)
			if is_hov:
				draw_arc(Vector2.ZERO, 17.5 + sin(t * 6.0) * 1.2, 0.0, TAU, 28, hcol, 2.2)
				draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(1.0, 0.95, 0.75, 0.55 * pulse), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			# Mũi tên vàng nhấp nháy nhẹ trên đầu các tướng đã mở khi chưa xác nhận
			if (not confirmed and unl) or is_hov:
				var bob: float = sin((t * 6.5 if is_hov else t * 4.2) + st.position.x * 0.03) * (2.0 if is_hov else 1.4)
				var tip: Vector2 = st.position + Vector2(0, -24.0 + bob)
				var hw: float = 4.2 if is_hov else 2.8
				var hh: float = 5.0 if is_hov else 3.4
				var c_a: float = 0.96 if is_hov else (0.58 + 0.28 * sin(t * 4.0 + st.position.x * 0.02))
				var c_col := Color(1.0, 0.92, 0.42, c_a) if unl else Color(1.0, 0.74, 0.36, c_a)
				draw_colored_polygon(PackedVector2Array([
					tip + Vector2(-hw, -hh),
					tip + Vector2(hw, -hh),
					tip,
				]), c_col)

			# Nhãn gọn dưới chân khi hover để không che mặt hay tướng bên cạnh
			if is_hov:
				var tag_pos: Vector2 = pos + Vector2(0, 12.0)
				var tag_txt: String = "Nhấp chọn" if unl else "Mở khóa"
				var tag_col: Color = Color(0.60, 0.98, 1.0, 0.98) if unl else Color(1.0, 0.82, 0.40, 0.98)
				var tw: float = Art.text_width(tag_txt, 10) + 8.0
				draw_rect(Rect2(tag_pos.x - tw * 0.5, tag_pos.y - 8.5, tw, 11.0), Color(0.06, 0.03, 0.08, 0.84))
				draw_rect(Rect2(tag_pos.x - tw * 0.5, tag_pos.y - 8.5, tw, 11.0), Color(tag_col.r, tag_col.g, tag_col.b, 0.65), false, 1.0)
				Art.draw_text(self, tag_pos, tag_txt, 10, tag_col)


class TrophyWallDisplay extends Node2D:
	## Kệ Kỷ Vật Hồn Sử Đại Việt treo dọc tường Bắc Đại Sảnh (y = 258, 24 vị trí trên 2 tầng giá)
	const CHRONICLES_SCRIPT := "res://scripts/data/chronicles.gd"
	const SLOT_XS: Array[float] = [
		-186.0, -166.0, -146.0, -126.0, -106.0, -86.0,
		86.0, 106.0, 126.0, 146.0, 166.0, 186.0,
		-186.0, -166.0, -146.0, -126.0, -106.0, -86.0,
		86.0, 106.0, 126.0, 146.0, 166.0, 186.0,
	]

	var t: float = 0.0
	var _cdata = null

	func _ready() -> void:
		z_index = 1
		if ResourceLoader.exists(CHRONICLES_SCRIPT):
			_cdata = load(CHRONICLES_SCRIPT)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _unlocked_list() -> Array:
		var raw: Variant = Global.get("unlocked_chronicles")
		return raw if raw is Array else []

	func trophy_count() -> int:
		return _unlocked_list().size()

	func _entry_info(cid: String) -> Dictionary:
		if _cdata != null:
			var d: Variant = _cdata.get("DATA")
			if d is Dictionary and (d as Dictionary).has(cid):
				return (d as Dictionary)[cid]
		return {}

	func _ordered_ids() -> Array:
		if _cdata != null:
			var ord: Variant = _cdata.get("ORDER")
			if ord is Array and not (ord as Array).is_empty():
				return ord as Array
		return _unlocked_list()

	func _shield_colors(info: Dictionary) -> Dictionary:
		var cat: String = str(info.get("category", "boss"))
		var base_col: Color = info.get("color", Color(1.0, 0.82, 0.28))
		if cat == "mythic":
			return {
				"rim": Color(0.86, 0.62, 1.0),
				"fill": base_col.lerp(Color(0.56, 0.24, 0.84), 0.35),
				"gem": Color(0.95, 0.72, 1.0),
			}
		if cat == "relic":
			return {
				"rim": Color(1.0, 0.92, 0.48),
				"fill": base_col.lerp(Color(0.95, 0.74, 0.22), 0.35),
				"gem": Color(0.52, 0.96, 1.0),
			}
		return {
			"rim": Color(1.0, 0.84, 0.34),
			"fill": base_col.lerp(Color(0.76, 0.18, 0.18), 0.25),
			"gem": Color(1.0, 0.94, 0.62),
		}

	func _draw() -> void:
		# Thanh gỗ sơn son thếp vàng (2 tầng x 2 bên tường Bắc Đại Sảnh, sức chứa 24 kỷ vật)
		for row_y in [-6.0, 8.0]:
			for side in [-1.0, 1.0]:
				var bx: float = -196.0 if side < 0.0 else 68.0
				draw_rect(Rect2(bx, row_y - 4.0, 128.0, 8.0), Color(0.22, 0.11, 0.07, 0.88))
				draw_rect(Rect2(bx, row_y - 4.0, 128.0, 8.0), Color(0.76, 0.56, 0.22, 0.58), false, 1.0)
				draw_rect(Rect2(bx + 2.0, row_y - 3.0, 124.0, 1.0), Color(1.0, 0.84, 0.42, 0.35))

		var unlocked: Array = _unlocked_list()
		var order: Array = _ordered_ids()
		var slot_count: int = SLOT_XS.size()
		for i in slot_count:
			var sx: float = SLOT_XS[i]
			var sy: float = -6.0 if i < 12 else 8.0
			var cid: String = str(order[i]) if i < order.size() else ""
			var has_trophy: bool = (cid != "" and unlocked.has(cid))
			if not has_trophy:
				draw_rect(Rect2(sx - 3.5, sy - 3.5, 7.0, 7.0), Color(0.14, 0.08, 0.06, 0.72))
				draw_rect(Rect2(sx - 3.5, sy - 3.5, 7.0, 7.0), Color(0.55, 0.42, 0.22, 0.35), false, 1.0)
				draw_circle(Vector2(sx, sy - 0.5), 0.9, Color(0.78, 0.62, 0.28, 0.42))
				continue

			var info: Dictionary = _entry_info(cid)
			var pal: Dictionary = _shield_colors(info)
			var rim: Color = pal.rim
			var fill: Color = pal.fill
			var gem: Color = pal.gem
			var pulse: float = 0.65 + 0.35 * sin(t * 2.8 + float(i) * 0.9)

			draw_circle(Vector2(sx, sy), 7.5, Color(rim.r, rim.g, rim.b, 0.14 * pulse))

			var outer := PackedVector2Array([
				Vector2(sx - 4.8, sy - 5.2),
				Vector2(sx + 4.8, sy - 5.2),
				Vector2(sx + 4.8, sy + 0.8),
				Vector2(sx, sy + 5.6),
				Vector2(sx - 4.8, sy + 0.8),
			])
			var inner := PackedVector2Array([
				Vector2(sx - 3.4, sy - 3.8),
				Vector2(sx + 3.4, sy - 3.8),
				Vector2(sx + 3.4, sy + 0.4),
				Vector2(sx, sy + 4.1),
				Vector2(sx - 3.4, sy + 0.4),
			])
			draw_colored_polygon(outer, rim)
			draw_colored_polygon(inner, fill)
			draw_circle(Vector2(sx, sy - 0.8), 1.4, gem)
			var gleam: float = maxf(0.0, sin(t * 1.9 - float(i) * 0.55))
			if gleam > 0.78:
				var ga: float = (gleam - 0.78) / 0.22
				draw_line(Vector2(sx - 3.0, sy - 3.0), Vector2(sx + 2.5, sy + 1.8), Color(1.0, 1.0, 0.95, 0.75 * ga), 1.2)
var _forged_icon: Sprite2D
var _garden_sprites: Array[Sprite2D] = []
var _garden_sparkles: Array[CPUParticles2D] = []
var _sway_nodes: Array = []
var _sway_t: float = 0.0
var _well_pos := Vector2(245, 345)
var _forge_pos := Vector2(1032, 345)
var _mat_shop_pos := Vector2(1204, 452)


func _ready() -> void:
	var hs := _hotpatch_sync()
	if hs != null and hs.sync_and_reload_scene_if_needed(get_tree(), "res://scenes/lobby.tscn"):
		return
	add_to_group("lobby")
	get_tree().paused = false
	Sfx.play_music("lobby")
	world = Node2D.new()
	add_child(world)
	var dark := CanvasModulate.new()
	dark.color = Color(0.96, 0.93, 0.88)
	add_child(dark)
	_canvas_mod = dark
	var deal_pool: Array = preload("res://scripts/data/materials.gd").ORDER
	merchant_deal = str(deal_pool[randi() % deal_pool.size()])
	_build_room()
	_decorate()
	var secret_unlocked: bool = false
	if Global.best_level >= 6 and not Global.unlocked.has("thanh_giong"):
		Global.unlocked.append("thanh_giong")
		Global.save_game()
		secret_unlocked = true
	_build_stations()
	_refresh_rescued_npcs()
	if _trophy_wall != null and is_instance_valid(_trophy_wall):
		_trophies_count = _trophy_wall.trophy_count()
	_hero_overlay = HeroRingOverlay.new()
	_hero_overlay.lobby = self
	_hero_overlay.z_index = 0
	world.add_child(_hero_overlay)

	hero_confirmed = false
	_cursor_hero_idx = maxi(0, HeroData.ORDER.find(Global.selected_hero))
	_spawn_player(SPAWN_POS, true)
	set_player_active(false)
	_refresh_heroes()
	refresh_pet_stations()
	if secret_unlocked:
		var gpos: Vector2 = _hero_npcs["thanh_giong"].global_position if _hero_npcs.has("thanh_giong") else SPAWN_POS
		Fx.particles(world, gpos, Color(1.0, 0.82, 0.28), 24, 90.0, 0.7, -30.0, 2.0)
		Fx.float_text(world, SPAWN_POS + Vector2(0, -32), "Mở khóa tướng ẩn: Thánh Gióng!", Color(1.0, 0.88, 0.35), 16)

	camera = Camera2D.new()
	camera.position = HALL_CENTER
	camera.zoom = Vector2(1.0, 1.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(SIZE.x)
	camera.limit_bottom = int(SIZE.y)
	world.add_child(camera)
	camera.make_current()

	touch = TouchControls.new()
	add_child(touch)
	touch.player = player
	touch.pause_pressed.connect(_back_to_menu)
	ui = LobbyUI.new()
	ui.lobby = self
	add_child(ui)

	if Net != null and Net.is_online():
		_connect_net_signals()
		if Global.selected_pet != "" and Global.PETS.has(Global.selected_pet):
			Net.request_set_pet(Global.selected_pet)
		_sync_remote_lobby_peers()


func _exit_tree() -> void:
	_disconnect_net_signals()


func room_at(pos: Vector2) -> Dictionary:
	if in_basement or BASEMENT_RECT.has_point(pos):
		return {"id": "basement", "name": "Tầng Hầm Chiến Tích", "rect": BASEMENT_RECT}
	for r in ROOMS:
		var rect: Rect2 = r.rect
		if rect.has_point(pos):
			return r
	return {"id": "corridor", "name": "Hành Lang Doanh Trại", "rect": Rect2()}


func _add_wall_rect(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	body.add_child(cs)
	world.add_child(body)


func _build_room() -> void:
	var bg := Sprite2D.new()
	bg.texture = Art.tex("world/lobby_bg.png")
	bg.centered = false
	bg.z_index = -5
	world.add_child(bg)

	var walls: Array[Rect2] = [
		# Đại Sảnh (chừa 3 cửa rộng 90px: Bắc x 635..725, Tây/Đông y 425..515)
		Rect2(444, 234, 190, 16), Rect2(726, 234, 190, 16),
		Rect2(444, 690, 472, 18),
		Rect2(444, 250, 16, 174), Rect2(444, 516, 16, 174),
		Rect2(900, 250, 16, 174), Rect2(900, 516, 16, 174),
		# Vườn Sen (Tây: 40..420 x 250..690)
		Rect2(24, 234, 412, 16), Rect2(24, 690, 412, 18),
		Rect2(24, 250, 16, 440),
		Rect2(420, 250, 16, 174), Rect2(420, 516, 16, 174),
		# Xưởng Rèn & Võ Đường (Đông: 940..1320 x 250..690)
		Rect2(924, 234, 412, 16), Rect2(924, 690, 412, 18),
		Rect2(1320, 250, 16, 440),
		Rect2(924, 250, 16, 174), Rect2(924, 516, 16, 174),
		# Đại Cổng Xuất Trận (Bắc: 460..900 x 20..210)
		Rect2(444, 4, 472, 40),
		Rect2(444, 20, 16, 190), Rect2(900, 20, 16, 190),
		Rect2(444, 210, 190, 16), Rect2(726, 210, 190, 16),
		# Thành hai bên 3 hành lang nối phòng
		Rect2(420, 408, 40, 16), Rect2(420, 516, 40, 16),
		Rect2(900, 408, 40, 16), Rect2(900, 516, 40, 16),
		Rect2(618, 210, 16, 40), Rect2(726, 210, 16, 40),
		# Mặt hồ sen không đi lọt xuống nước
		Rect2(146, 542, 138, 86),
	]
	for r in walls:
		_add_wall_rect(r)

	# Tầng Hầm Chiến Tích (bên dưới Doanh Trại)
	var b_bg := Sprite2D.new()
	b_bg.texture = Art.tex("world/basement_bg.png")
	b_bg.centered = false
	b_bg.position = BASEMENT_ORIGIN
	b_bg.z_index = -5
	world.add_child(b_bg)

	var b_walls: Array[Rect2] = [
		Rect2(224, 884, 912, 36),   # tường Bắc tầng hầm
		Rect2(224, 1444, 912, 32),  # tường Nam tầng hầm
		Rect2(224, 900, 32, 560),   # tường Tây tầng hầm
		Rect2(1104, 900, 32, 560),  # tường Đông tầng hầm
	]
	for br in b_walls:
		_add_wall_rect(br)


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


func _anim_prop(rel: String, fw: int, fh: int, fps: float, pos: Vector2, light_col: Color = Color.TRANSPARENT) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Art.strip(rel, fw, fh, fps, true)
	a.play("play")
	a.position = pos
	world.add_child(a)
	if light_col != Color.TRANSPARENT:
		var lt := Art.light(light_col, 1.0, 0.75)
		lt.position = Vector2(0, -6)
		a.add_child(lt)
	return a


func _sway_prop(rel: String, pos: Vector2, offset := Vector2.ZERO) -> Sprite2D:
	var pivot := Node2D.new()
	pivot.position = pos
	world.add_child(pivot)
	var sp := _sprite(rel, offset)
	pivot.add_child(sp)
	_sway_nodes.append(pivot)
	return sp


func _sign_label(text: String, pos: Vector2, col := Color(1.0, 0.9, 0.62)) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = pos - Vector2(68, 8)
	lb.size = Vector2(136, 16)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.add_theme_font_size_override("font_size", 11)
	lb.add_theme_color_override("font_color", col)
	lb.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.06, 0.95))
	lb.add_theme_constant_override("outline_size", 3)
	lb.z_index = 4
	world.add_child(lb)


func _decorate() -> void:
	# Biển chỉ đường nhẹ ở 3 cửa thông từ Đại Sảnh
	_sign_label("▲ Xuất Trận", Vector2(680, 232), Color(0.62, 0.95, 1.0))
	_sign_label("◀ Vườn Sen", Vector2(440, 412), Color(0.72, 0.96, 0.64))
	_sign_label("Xưởng Rèn ▶", Vector2(920, 412), Color(1.0, 0.8, 0.5))

	# ---- 1. Đại Sảnh Anh Hùng ----
	for x in [492.0, 588.0, 772.0, 868.0]:
		_decor("lantern", Vector2(x, 266))
	_decor("drum", Vector2(680, 470))
	var inc := _prop("world/incense.png", Vector2(680, 396))
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(0, -8)
	smoke.amount = 14
	smoke.lifetime = 2.6
	smoke.direction = Vector2.UP
	smoke.spread = 14.0
	smoke.gravity = Vector2(4, -6)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 2.6
	var sg := Gradient.new()
	sg.set_color(0, Color(0.92, 0.88, 0.95, 0.7))
	sg.set_color(1, Color(0.92, 0.88, 0.95, 0.0))
	smoke.color_ramp = sg
	inc.add_child(smoke)
	inc.add_child(Art.light(Color(1, 0.65, 0.35), 0.8, 0.75))
	_prop("world/drum_stand.png", Vector2(616, 434))
	_prop("world/drum_stand.png", Vector2(744, 434))
	# Nội thất Đại Sảnh: đỉnh lửa, cờ & cột cửa
	for bp in [Vector2(618, 270), Vector2(742, 270)]:
		_anim_prop("world/prop_brazier.png", 26, 32, 6.0, bp, Color(1.0, 0.62, 0.28))
	_prop("world/prop_flag_stand.png", Vector2(476, 430), Vector2(0, -10))
	_prop("world/prop_flag_stand.png", Vector2(884, 430), Vector2(0, -10))
	for pp in [Vector2(472, 412), Vector2(888, 412), Vector2(472, 526), Vector2(888, 526)]:
		_prop("world/pillar.png", pp, Vector2(0, -14))
	# Cột đèn lồng gỗ sơn son & bonsai, khóm hoa, thú cưng Đại Sảnh
	for lp in [Vector2(476, 654), Vector2(884, 654), Vector2(630, 534), Vector2(730, 534)]:
		_anim_prop("world/prop_wood_lamp.png", 30, 52, 4.0, lp + Vector2(0, -18), Color(1.0, 0.56, 0.34))
	_prop("world/lobby_bonsai.png", Vector2(490, 294), Vector2(0, -12))
	_prop("world/lobby_bonsai.png", Vector2(870, 294), Vector2(0, -12))
	_prop("world/lobby_bush_gold.png", Vector2(624, 672), Vector2(0, -8))
	_prop("world/lobby_bush_red.png", Vector2(736, 672), Vector2(0, -8))
	for p in [Vector2(492, 654), Vector2(868, 654)]:
		_decor("pot", p)
	_animal_nodes["dog"] = _life("dog", Vector2(680, 622))
	_animal_nodes["cat_hall"] = _life("cat", Vector2(598, 628))
	var pa := _life("patrol", Vector2.ZERO)
	pa.a = Vector2(510, 672)
	pa.b = Vector2(850, 672)
	pa.position = pa.a

	# ---- 2. Đại Cổng Xuất Trận (Bắc) ----
	for x in [506.0, 600.0, 760.0, 854.0]:
		_decor("lantern", Vector2(x, 42))
	for bp in [Vector2(594, 152), Vector2(766, 152)]:
		_anim_prop("world/prop_brazier.png", 26, 32, 6.0, bp, Color(1.0, 0.62, 0.28))
	_prop("world/prop_flag_stand.png", Vector2(496, 124), Vector2(0, -10))
	_prop("world/prop_flag_stand.png", Vector2(864, 124), Vector2(0, -10))
	_prop("world/nghe.png", Vector2(618, 118))
	_prop("world/nghe.png", Vector2(742, 118))
	_prop("world/drum_stand.png", Vector2(546, 182))
	_prop("world/drum_stand.png", Vector2(814, 182))
	for lp in [Vector2(486, 184), Vector2(874, 184)]:
		_anim_prop("world/prop_stone_lantern.png", 32, 48, 4.0, lp + Vector2(0, -14), Color(1.0, 0.78, 0.42))
	for lp in [Vector2(630, 194), Vector2(730, 194)]:
		_anim_prop("world/prop_wood_lamp.png", 30, 52, 4.0, lp + Vector2(0, -18), Color(1.0, 0.56, 0.34))
	_prop("world/lobby_bush_red.png", Vector2(594, 186), Vector2(0, -8))
	_prop("world/lobby_bush_gold.png", Vector2(766, 186), Vector2(0, -8))
	_decor("banner", Vector2(618, 76))
	_decor("banner", Vector2(742, 76))

	# ---- 3. Vườn Sen & Chiến Tích (Tây) ----
	_animal_nodes["pond"] = _life("pond", Vector2(215, 585), Vector2(130, 74))
	for lp in [Vector2(72, 368), Vector2(398, 368), Vector2(114, 578), Vector2(318, 578)]:
		_anim_prop("world/prop_stone_lantern.png", 32, 48, 4.0, lp + Vector2(0, -14), Color(1.0, 0.78, 0.42))
	_prop("world/prop_bench.png", Vector2(215, 512), Vector2(0, -4))
	_prop("world/prop_bench.png", Vector2(356, 592), Vector2(0, -4))
	# Cây Đào, Cây Mai, Khóm Tre, Bonsai, Thùng nước & Khóm Hoa chi tiết
	_prop("world/garden_barrel.png", Vector2(262, 446), Vector2(0, -10))
	_sway_prop("world/lobby_peach.png", Vector2(72, 550), Vector2(0, -24))
	_sway_prop("world/lobby_peach.png", Vector2(382, 514), Vector2(0, -24))
	_sway_prop("world/lobby_apricot.png", Vector2(382, 636), Vector2(0, -24))
	_sway_prop("world/lobby_apricot.png", Vector2(78, 648), Vector2(0, -24))
	_sway_prop("world/lobby_bamboo.png", Vector2(64, 286), Vector2(0, -22))
	_sway_prop("world/lobby_bamboo.png", Vector2(396, 286), Vector2(0, -22))
	_prop("world/lobby_bonsai.png", Vector2(386, 412), Vector2(0, -12))
	_prop("world/lobby_bonsai.png", Vector2(146, 528), Vector2(0, -12))
	_prop("world/lobby_bush_red.png", Vector2(298, 404), Vector2(0, -8))
	_prop("world/lobby_bush_red.png", Vector2(282, 522), Vector2(0, -8))
	_prop("world/lobby_bush_gold.png", Vector2(354, 548), Vector2(0, -8))
	_prop("world/lobby_bush_gold.png", Vector2(142, 654), Vector2(0, -8))
	_prop("world/lobby_bush_red.png", Vector2(308, 658), Vector2(0, -8))
	# Đàn động vật sống động trong Vườn Sen
	_animal_nodes["rooster"] = _life("rooster", Vector2(318, 466))
	for cp in [Vector2(294, 488), Vector2(328, 492), Vector2(348, 474)]:
		_life("chick", cp)
	_animal_nodes["crane"] = _life("crane", Vector2(146, 616))
	_animal_nodes["cat_garden"] = _life("cat", Vector2(246, 506))

	# ---- 4. Xưởng Rèn & Võ Đường (Đông) ----
	for p in [Vector2(968, 274), Vector2(1292, 274)]:
		_decor("torch", p)
	for lp in [Vector2(956, 424), Vector2(1304, 424)]:
		_anim_prop("world/prop_wood_lamp.png", 30, 52, 4.0, lp + Vector2(0, -18), Color(1.0, 0.56, 0.34))
	_prop("world/prop_coal_pile.png", Vector2(976, 372), Vector2(0, -4))
	_decor("crate", Vector2(1086, 378))
	_decor("pot", Vector2(968, 418))
	_prop("world/prop_flag_stand.png", Vector2(1300, 480), Vector2(0, -10))
	# Góc trang trí tỉ mỉ cho Gian Hàng Thương Nhân Nguyên Liệu (phải Bàn Phù Phép)
	var shop_carpet := _prop("world/shop_mat_carpet.png", Vector2(1204, 466))
	shop_carpet.z_index = -1
	_anim_prop("world/shop_banner.png", 24, 48, 4.5, Vector2(1134, 434), Color.TRANSPARENT)
	_prop("world/shop_ore_crates.png", Vector2(1148, 462), Vector2(0, -10))
	_anim_prop("world/shop_gem_rack.png", 32, 44, 4.0, Vector2(1264, 446), Color(0.45, 0.95, 0.88))
	var shop_motes := CPUParticles2D.new()
	shop_motes.position = Vector2(1264, 434)
	shop_motes.amount = 8
	shop_motes.lifetime = 1.6
	shop_motes.direction = Vector2.UP
	shop_motes.spread = 28.0
	shop_motes.gravity = Vector2(0, -14)
	shop_motes.initial_velocity_min = 4.0
	shop_motes.initial_velocity_max = 10.0
	shop_motes.scale_amount_min = 1.0
	shop_motes.scale_amount_max = 1.8
	var smg := Gradient.new()
	smg.set_color(0, Color(0.55, 1.0, 0.85, 0.9))
	smg.set_color(1, Color(0.95, 0.72, 1.0, 0.0))
	shop_motes.color_ramp = smg
	shop_motes.material = Art.additive()
	shop_motes.z_index = 4
	world.add_child(shop_motes)
	for bp in [Vector2(978, 514), Vector2(1284, 514), Vector2(978, 650), Vector2(1284, 650)]:
		_prop("world/prop_weapon_barrel.png", bp, Vector2(0, -6))
	_prop("world/sandbag.png", Vector2(1048, 520))
	_prop("world/sandbag.png", Vector2(1238, 506))
	_prop("world/lobby_bonsai.png", Vector2(964, 668), Vector2(0, -12))
	_prop("world/lobby_bonsai.png", Vector2(1296, 668), Vector2(0, -12))

	var embers := CPUParticles2D.new()
	embers.position = _forge_pos + Vector2(-8, -16)
	embers.amount = 14
	embers.lifetime = 1.6
	embers.direction = Vector2.UP
	embers.spread = 32.0
	embers.gravity = Vector2(4, -24)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 22.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.1
	var eg := Gradient.new()
	eg.set_color(0, Color(1, 0.85, 0.35, 1))
	eg.set_color(1, Color(1, 0.3, 0.1, 0))
	embers.color_ramp = eg
	embers.material = Art.additive()
	embers.z_index = 6
	world.add_child(embers)

	# 5 NPC sinh động ở các khu vực trong doanh trại
	_npc_nodes["npc_tea_lady"] = _life("npc_tea_lady", Vector2(588, 604))
	_npc_nodes["npc_strategist"] = _life("npc_strategist", Vector2(838, 622))
	_npc_nodes["npc_blacksmith"] = _life("npc_blacksmith", Vector2(1068, 352))
	_npc_nodes["npc_scholar"] = _life("npc_scholar", Vector2(168, 354))
	_npc_nodes["npc_guard"] = _life("npc_guard", Vector2(640, 148))

	# Không khí: bướm, lá và cánh hoa bay khắp 4 phòng
	var amb := Ambience.new()
	amb.area = Rect2(Vector2(40, 20), Vector2(1280, 680))
	world.add_child(amb)
	if amb != null and amb.has_method("enable_glow"):
		amb.enable_glow()

	# Bảng Kỷ Vật Hồn Sử treo tường Bắc Đại Sảnh (y = 258, trên các bục tướng y = 338)
	_trophy_wall = TrophyWallDisplay.new()
	_trophy_wall.position = Vector2(680, 258)
	world.add_child(_trophy_wall)

	# Biển cầu thang xuống Tầng Hầm tại Đại Sảnh Anh Hùng
	_sign_label("▼ Tầng Hầm", Vector2(680, 690), Color(1.0, 0.82, 0.42))

	# ---- 5. Trang trí Tầng Hầm Chiến Tích ----
	_sign_label("▲ Lên Sảnh", Vector2(680, 926), Color(1.0, 0.86, 0.45))
	for tp in [Vector2(316, 932), Vector2(540, 932), Vector2(820, 932), Vector2(1044, 932)]:
		_decor("torch", tp)
	for bp in [Vector2(304, 1030), Vector2(1056, 1030), Vector2(304, 1380), Vector2(1056, 1380)]:
		_anim_prop("world/prop_brazier.png", 26, 32, 6.0, bp, Color(1.0, 0.64, 0.28))
	for pp in [Vector2(356, 944), Vector2(1004, 944)]:
		_prop("world/pillar.png", pp, Vector2(0, -14))
	for kp in [Vector2(284, 1170), Vector2(1076, 1170)]:
		_decor("pot", kp)
	for flp in [Vector2(618, 938), Vector2(742, 938)]:
		_decor("banner", flp)

	var bmotes := CPUParticles2D.new()
	bmotes.position = BASEMENT_RECT.get_center()
	bmotes.amount = 28
	bmotes.lifetime = 4.5
	bmotes.preprocess = 4.5
	bmotes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bmotes.emission_rect_extents = Vector2(BASEMENT_RECT.size.x * 0.45, BASEMENT_RECT.size.y * 0.45)
	bmotes.direction = Vector2.UP
	bmotes.spread = 180.0
	bmotes.gravity = Vector2(0, -3)
	bmotes.initial_velocity_min = 2.0
	bmotes.initial_velocity_max = 6.0
	bmotes.scale_amount_min = 1.0
	bmotes.scale_amount_max = 1.8
	var bmg := Gradient.new()
	bmg.set_color(0, Color(1.0, 0.88, 0.42, 0.0))
	bmg.add_point(0.5, Color(1.0, 0.88, 0.42, 0.85))
	bmg.set_color(bmg.get_point_count() - 1, Color(1.0, 0.88, 0.42, 0.0))
	bmotes.color_ramp = bmg
	bmotes.material = Art.additive()
	bmotes.z_index = 6
	world.add_child(bmotes)


func _add_station(kind: String, data: String, title: String, hint: String, pos: Vector2, sprite: Node2D, label_y: float = -24.0) -> Node2D:
	var s := Station.new()
	s.kind = kind
	s.data = data
	s.title = title
	s.hint = hint
	s.position = pos
	s.label_offset_y = label_y
	if sprite != null:
		s.add_child(sprite)
	s.used.connect(_on_station)
	world.add_child(s)
	stations.append(s)
	return s


func _build_stations() -> void:
	# 14 vị tướng trên các bục gỗ trong Đại Sảnh
	for i in HeroData.ORDER.size():
		var id: String = HeroData.ORDER[i]
		var h: Dictionary = HeroData.DATA[id]
		var a := AnimatedSprite2D.new()
		var htex: Texture2D = Art.tex("heroes/%s.png" % id)
		var fcount: int = (maxi(1, int(htex.get_width()) / 32) * maxi(1, int(htex.get_height()) / 32)) if htex != null else 4
		var idle_seq: Array = [0, 1, 16, 2, 17, 3] if fcount >= 28 else [0, 1, 2, 3]
		var act_seq: Array = [4, 5, 18, 19, 20, 21, 6, 7] if fcount >= 28 else [0, 1, 2, 3]
		var idle_fps: float = (4.8 if fcount >= 28 else 3.0) + float(i) * 0.18
		a.sprite_frames = Art.frames("heroes/%s.png" % id, 32, 32, {
			"idle": [idle_seq, idle_fps, true],
			"action": [act_seq, 7.5, true],
		})
		a.play("idle")
		a.position = Vector2(0, -10)
		var spot: Vector2 = HERO_SPOTS[i] if i < HERO_SPOTS.size() else SPAWN_POS
		var s := _add_station("hero", id, h.name, "Xem tướng", spot, a)
		s.title_when_near = true
		s.radius = 22.0
		_hero_npcs[id] = s
	_refresh_heroes()

	# Đại Sảnh (giữa-bắc): Đài Thiên Phú Đại Việt
	var stree_st := _add_station("skill_tree", "", "Đài Thiên Phú", "Cây Thiên Phú Đại Việt", Vector2(680, 326), _sprite("world/lobby_skill_tree.png", Vector2(0, -16)), -46.0)
	stree_st.radius = 28.0
	var stl_tree := Art.light(Color(0.45, 0.95, 0.68), 0.85, 0.65)
	stl_tree.position = Vector2(680, 316)
	world.add_child(stl_tree)

	# Xưởng Rèn (phòng Đông - nửa trên)
	var forge := AnimatedSprite2D.new()
	forge.sprite_frames = Art.strip("world/lobby_forge.png", 56, 48, 7.0, true)
	forge.play("play")
	forge.position = Vector2(0, -14)
	var forge_st := _add_station("forge", "", "Lò rèn", "Nâng cấp & Rèn", _forge_pos, forge, -44.0)
	forge_st.radius = 30.0
	var fl := Art.light(Color(1, 0.58, 0.28), 1.4, 1.0)
	fl.position = _forge_pos
	world.add_child(fl)

	var rack := _add_station("rack", "", "Giá binh khí", "Xem kho vũ khí", Vector2(1145, 345), _sprite("world/lobby_rack.png", Vector2(0, -14)), -42.0)
	rack.radius = 28.0
	_forged_icon = Sprite2D.new()
	_forged_icon.position = Vector2(0, -24)
	_forged_icon.scale = Vector2(0.75, 0.75)
	_forged_icon.z_index = 2
	rack.add_child(_forged_icon)
	refresh_forged_display()

	var codex_st := _add_station("codex", "", "Bách Khoa", "Phúc lành, Cổ Vật & Trùm", Vector2(1252, 345), _sprite("world/lobby_codex.png", Vector2(0, -14)), -44.0)
	codex_st.radius = 28.0
	var cl := Art.light(Color(1.0, 0.85, 0.52), 0.8, 0.65)
	cl.position = Vector2(1240, 342)
	world.add_child(cl)

	# Võ Đường (phòng Đông - nửa dưới): 3 hình nhân rơm đánh thử, Giá Thử Binh Khí & Võ Đài Tỷ Thí
	var wtest_spr := _sprite("world/weapon_rack.png", Vector2(0, -10))
	var wtest_st := _add_station("weapon_test", "", "Thử Binh Khí", "Đổi vũ khí tập võ", Vector2(1008, 492), wtest_spr, -32.0)
	wtest_st.radius = 24.0
	var wtl := Art.light(Color(0.45, 0.92, 1.0), 0.72, 0.55)
	wtl.position = Vector2(1008, 484)
	world.add_child(wtl)

	for p in [Vector2(1040, 580), Vector2(1140, 560), Vector2(1220, 610)]:
		var dm := Dummy.new()
		dm.position = p
		world.add_child(dm)

	_sparring_arena = SparringArena.new()
	world.add_child(_sparring_arena)
	var spar_st := _add_station("sparring", "", "Võ Đài Tỷ Thí", "Bật/Tắt Tỷ Thí", Vector2(1140, 654), _sprite("world/lobby_sparring_banner.png", Vector2(0, -16)), -44.0)
	spar_st.radius = 28.0
	var spl := Art.light(Color(1.0, 0.45, 0.32), 0.85, 0.65)
	spl.position = Vector2(1140, 644)
	world.add_child(spl)

	# Vườn Sen & Chiến Tích (phòng Tây)
	var stele_st := _add_station("stele", "", "Bia ghi công", "Xem thành tích", Vector2(135, 345), _sprite("world/lobby_stele.png", Vector2(0, -18)), -50.0)
	stele_st.radius = 28.0
	var stl := Art.light(Color(1.0, 0.86, 0.45), 0.7, 0.55)
	stl.position = Vector2(135, 336)
	world.add_child(stl)

	var well_spr := AnimatedSprite2D.new()
	well_spr.sprite_frames = Art.strip("world/lobby_well.png", 54, 56, 4.0, true)
	well_spr.play("play")
	well_spr.position = Vector2(0, -18)
	var well_st := _add_station("well", "", "Giếng Ước", "Thả 10 xu cầu may", _well_pos, well_spr, -50.0)
	well_st.radius = 30.0
	var wl := Art.light(Color(0.45, 0.92, 1.0), 0.9, 0.8)
	wl.position = _well_pos
	world.add_child(wl)
	var well_motes := CPUParticles2D.new()
	well_motes.position = _well_pos + Vector2(0, -10)
	well_motes.amount = 8
	well_motes.lifetime = 1.4
	well_motes.direction = Vector2.UP
	well_motes.spread = 24.0
	well_motes.gravity = Vector2(0, -18)
	well_motes.initial_velocity_min = 6.0
	well_motes.initial_velocity_max = 12.0
	well_motes.scale_amount_min = 1.0
	well_motes.scale_amount_max = 1.8
	var wg := Gradient.new()
	wg.set_color(0, Color(0.6, 0.98, 1.0, 0.9))
	wg.set_color(1, Color(0.6, 0.98, 1.0, 0.0))
	well_motes.color_ramp = wg
	well_motes.material = Art.additive()
	well_motes.z_index = 4
	world.add_child(well_motes)

	var chal_st := _add_station("challenge", "", "Bảng Khiêu Chiến", "Độ khó & Thử thách", Vector2(345, 345), _sprite("world/lobby_challenge.png", Vector2(0, -16)), -46.0)
	chal_st.radius = 28.0

	# ---- 6 công trình chức năng mới cho từng phòng ----
	# Đại Sảnh (giữa): Quán Trà & Sa Bàn Quân Sự
	var tea_st := _add_station("tea", "", "Quán Trà", "Uống đặc sản tăng lực", Vector2(558, 608), _sprite("world/lobby_tea.png", Vector2(0, -12)), -38.0)
	tea_st.radius = 28.0
	var steam := CPUParticles2D.new()
	steam.position = Vector2(2, -16)
	steam.amount = 6
	steam.lifetime = 1.8
	steam.direction = Vector2.UP
	steam.spread = 15.0
	steam.gravity = Vector2(2, -8)
	steam.initial_velocity_min = 4.0
	steam.initial_velocity_max = 8.0
	steam.scale_amount_min = 1.0
	steam.scale_amount_max = 2.0
	var stg := Gradient.new()
	stg.set_color(0, Color(0.95, 0.96, 1.0, 0.55))
	stg.set_color(1, Color(0.95, 0.96, 1.0, 0.0))
	steam.color_ramp = stg
	tea_st.add_child(steam)

	var war_st := _add_station("war_table", "", "Sa Bàn Quân Sự", "Mã Seed & Bảng Vinh Danh", Vector2(808, 626), _sprite("world/lobby_war_table.png", Vector2(0, -12)), -38.0)
	war_st.radius = 28.0

	var chron_spr := _sprite("world/stele.png", Vector2(0, -12))
	chron_spr.modulate = Color(1.08, 0.96, 0.78)
	var chron_st := _add_station("chronicles", "", "Hồn Sử", "Sử Ký & Kỷ Vật", Vector2(492, 616), chron_spr, -36.0)
	chron_st.radius = 26.0
	chron_st.title_color = Color(1.0, 0.88, 0.42)
	var chl := Art.light(Color(1.0, 0.86, 0.42), 0.72, 0.55)
	chl.position = Vector2(492, 608)
	world.add_child(chl)

	# Vườn Sen (tây): Vườn Thảo Dược (3 luống mặc định, 6 luống khi giải cứu Danh Y Tuệ Tĩnh)
	_garden_wrap = Node2D.new()
	_garden_sprites.clear()
	_garden_sparkles.clear()
	var garden_st := _add_station("garden", "", "Vườn Thảo Dược", "Trồng & thu hoạch linh thảo", Vector2(154, 446), _garden_wrap, -46.0)
	garden_st.radius = 48.0
	refresh_garden_display()

	# Vườn Sen (tây): Đài Thức Tỉnh Thần Thú
	var pshrine_st := _add_station("pet_shrine", "", "Đài Thức Tỉnh", "Thức tỉnh Thần Thú", Vector2(356, 446), _sprite("world/lobby_pet_shrine.png", Vector2(0, -16)), -44.0)
	pshrine_st.radius = 28.0
	var pshl := Art.light(Color(0.42, 0.94, 0.88), 0.85, 0.65)
	pshl.position = Vector2(356, 436)
	world.add_child(pshl)

	# Xưởng Rèn (đông): Bàn Phù Phép Binh Khí
	var enc_spr := AnimatedSprite2D.new()
	enc_spr.sprite_frames = Art.strip("world/lobby_enchant.png", 52, 46, 5.0, true)
	enc_spr.play("play")
	enc_spr.position = Vector2(0, -14)
	var enc_st := _add_station("enchant", "", "Bàn Phù Phép", "Gắn bùa cho vũ khí", Vector2(1032, 444), enc_spr, -44.0)
	enc_st.radius = 28.0
	var el := Art.light(Color(0.32, 0.92, 0.98), 0.9, 0.75)
	el.position = Vector2(1032, 434)
	world.add_child(el)

	# Xưởng Rèn (đông): Thương Nhân Nguyên Liệu
	var shop_spr := AnimatedSprite2D.new()
	shop_spr.sprite_frames = Art.strip("world/lobby_mat_shop.png", 84, 68, 4.5, true)
	shop_spr.play("play")
	shop_spr.position = Vector2(0, -18)
	var shop_st := _add_station("mat_merchant", "", "Thương Nhân Nguyên Liệu", "Mua bán & Đổi nguyên liệu", _mat_shop_pos, shop_spr, -58.0)
	shop_st.radius = 36.0
	var slt := Art.light(Color(1.0, 0.78, 0.38), 1.25, 0.85)
	slt.position = _mat_shop_pos + Vector2(0, -18)
	world.add_child(slt)

	# Đại Cổng Xuất Trận (bắc): Tượng Thần Hộ Mệnh & Rương Quân Nhu
	var shrine_st := _add_station("shrine", "", "Tượng Thần Hộ Mệnh", "Cầu thần phúc xuất trận", Vector2(546, 128), _sprite("world/lobby_shrine.png", Vector2(0, -18)), -48.0)
	shrine_st.radius = 28.0
	var shl := Art.light(Color(1.0, 0.85, 0.42), 0.85, 0.7)
	shl.position = Vector2(546, 118)
	world.add_child(shl)

	var supply_st := _add_station("supply", "", "Rương Quân Nhu", "Tiếp tế & đổi nguyên liệu", Vector2(814, 128), _sprite("world/lobby_supply.png", Vector2(0, -14)), -40.0)
	supply_st.radius = 28.0

	# Đại Cổng Xuất Trận (phòng Bắc)
	var portal := Portal.new()
	portal.position = Vector2(680, 115)
	portal.label = "Cổng xuất trận"
	portal.entered.connect(_start_run)
	world.add_child(portal)
	_north_portal = portal

	# Tương tác Linh Thú & Hồ Cá Koi
	var animal_defs: Array[Dictionary] = [
		{"key": "dog", "pet_id": "dog", "rad": 28.0},
		{"key": "cat_hall", "pet_id": "cat", "rad": 26.0},
		{"key": "rooster", "pet_id": "rooster", "rad": 28.0},
		{"key": "crane", "pet_id": "crane", "rad": 34.0},
		{"key": "cat_garden", "pet_id": "cat", "rad": 26.0},
	]
	for ad in animal_defs:
		var akey: String = str(ad.key)
		var pid: String = str(ad.pet_id)
		var nd: Node2D = _animal_nodes.get(akey, null) as Node2D
		if nd == null or not Global.PETS.has(pid):
			continue
		var pinfo: Dictionary = Global.PETS[pid]
		var st := _add_station("pet", pid, str(pinfo.name), "Vuốt ve & Đồng hành", nd.position, null, -24.0)
		st.title_when_near = true
		st.radius = float(ad.rad)
		_pet_stations.append({"station": st, "node": nd, "pet_id": pid})

	var pond_st := _add_station("pond", "", "Hồ Cá Koi", "Cho cá ăn cầu lộc", Vector2(215, 526), null, -22.0)
	pond_st.title_when_near = true
	pond_st.radius = 30.0
	refresh_pet_stations()

	# Cầu thang xuống Tầng Hầm (Đại Sảnh) & lên Đại Sảnh (Tầng Hầm)
	var down_st := _add_stair_station("basement_down", "Tầng Hầm", "Thành tựu & Bản vẽ", Vector2(680, 662), _sprite("world/lobby_stairs_down.png", Vector2(0, -10)), -38.0, 28.0)
	down_st.visible = true
	_basement_down_st = down_st
	var bdl := Art.light(Color(1.0, 0.72, 0.32), 0.9, 0.72)
	bdl.position = Vector2(680, 654)
	world.add_child(bdl)

	var up_st := _add_stair_station("basement_up", "Lên Đại Sảnh", "Quay về sảnh chính", Vector2(680, 972), _sprite("world/basement_stairs_up.png", Vector2(0, -14)), -44.0, 30.0)
	up_st.visible = false
	_basement_up_st = up_st
	var bul := Art.light(Color(1.0, 0.78, 0.38), 1.0, 0.75)
	bul.position = Vector2(680, 964)
	world.add_child(bul)

	# 3 trạm tương tác trong Tầng Hầm Chiến Tích
	_basement_stations.clear()
	var ach_st := _add_station("basement_achieve", "", "Bia Thành Tựu", "Mốc chiến tích & Nhận thưởng", Vector2(430, 1170), _sprite("world/basement_trophy_stele.png", Vector2(0, -16)), -50.0)
	ach_st.radius = 32.0
	ach_st.visible = false
	_basement_stations.append(ach_st)
	var achl := Art.light(Color(1.0, 0.84, 0.35), 1.0, 0.75)
	achl.position = Vector2(430, 1156)
	world.add_child(achl)

	var bp_st := _add_station("basement_blueprint", "", "Bàn Bản Vẽ", "Bản vẽ Cơ bản & Nâng cao", Vector2(680, 1275), _sprite("world/basement_blueprint_desk.png", Vector2(0, -12)), -42.0)
	bp_st.radius = 32.0
	bp_st.visible = false
	_basement_stations.append(bp_st)
	var bpl := Art.light(Color(0.45, 0.88, 1.0), 1.0, 0.75)
	bpl.position = Vector2(680, 1264)
	world.add_child(bpl)

	var gal_st := _add_station("basement_gallery", "", "Bảo Tàng Binh Khí", "Bộ sưu tập 200 vũ khí", Vector2(930, 1170), _sprite("world/basement_armory_shelf.png", Vector2(0, -14)), -46.0)
	gal_st.radius = 32.0
	gal_st.visible = false
	_basement_stations.append(gal_st)
	var gall := Art.light(Color(1.0, 0.72, 0.38), 1.0, 0.75)
	gall.position = Vector2(930, 1156)
	world.add_child(gall)


func _is_hero_unlocked(id: String) -> bool:
	if Net != null and Net.is_online() and Net.host_profile.has("unlocked"):
		var h_unl: Variant = Net.host_profile.get("unlocked", [])
		if h_unl is Array:
			return (h_unl as Array).has(id)
	return Global.unlocked.has(id)


func _hero_skin_modulate(id: String) -> Color:
	var sid: String = HeroSkins.DEFAULT_SKIN
	if Global.has_method("get_selected_skin"):
		sid = str(Global.call("get_selected_skin", id))
	else:
		var smap: Variant = Global.get("selected_skins")
		if smap is Dictionary and (smap as Dictionary).has(id):
			sid = str((smap as Dictionary)[id])
	var skin: Dictionary = HeroSkins.get_skin(id, sid)
	var c: Variant = skin.get("modulate", Color.WHITE)
	return c as Color if c is Color else Color.WHITE


func _is_npc_rescued(npc_id: String) -> bool:
	var arr: Variant = Global.get("rescued_npcs")
	return arr is Array and (arr as Array).has(npc_id)


func refresh_hero_appearance(id: String = "") -> void:
	_refresh_heroes()
	if player != null and is_instance_valid(player) and (id == "" or id == Global.selected_hero):
		if "body" in player and player.body != null and is_instance_valid(player.body):
			player.body.modulate = _hero_skin_modulate(Global.selected_hero)


func _refresh_heroes() -> void:
	for id in _hero_npcs:
		var s = _hero_npcs[id]
		var unlocked: bool = _is_hero_unlocked(str(id))
		s.visible = true if (not hero_confirmed or (Net != null and Net.is_online())) else (id != Global.selected_hero)
		var spr: AnimatedSprite2D = s.get_child(0)
		spr.material = null if unlocked else Art.stone_material()
		spr.modulate = _hero_skin_modulate(str(id)) if unlocked else Color.WHITE
		spr.play("idle")
		s.title_color = Color(1, 0.9, 0.6) if unlocked else Color(0.8, 0.78, 0.75)
		s.title = HeroData.DATA[id].name if unlocked else "%s - %d xu" % [HeroData.DATA[id].name, HeroData.DATA[id].cost]


func _spawn_player(pos: Vector2, force_pos: bool = false) -> void:
	if player != null:
		if not force_pos:
			pos = player.global_position
		player.queue_free()
	player = Player.new()
	if Net != null and Net.is_online():
		var local_pid: int = Net.local_peer_id()
		player.peer_id = local_pid
		player.is_local = true
		var pinfo: Dictionary = Net.players.get(local_pid, {})
		player.display_name = str(pinfo.get("name", Global.settings.get("player_name", "Anh Hùng")))
		var col_v: Variant = pinfo.get("color", Net.PLAYER_COLORS[0])
		if col_v is Color:
			player.name_color = col_v
	player.setup(Global.selected_hero)
	if "body" in player and player.body != null and is_instance_valid(player.body):
		player.body.modulate = _hero_skin_modulate(Global.selected_hero)
	if Global.lobby_weapon_mod != "" and player.weapons.size() > 0 and str(player.weapons[0]) != "":
		Global.set_weapon_mod(str(player.weapons[0]), Global.lobby_weapon_mod)
	player.position = pos
	player.visible = hero_confirmed
	world.add_child(player)
	if touch != null:
		touch.player = player
	if lobby_pet != null and is_instance_valid(lobby_pet):
		lobby_pet.owner_player = player


func _hero_at_world_pos(wpos: Vector2, max_dist: float = 28.0) -> String:
	var best_id: String = ""
	var best_d: float = max_dist
	for id in _hero_npcs:
		var s: Node2D = _hero_npcs[id]
		if s == null or not is_instance_valid(s) or not s.visible:
			continue
		var d: float = wpos.distance_to(s.global_position)
		if d <= best_d:
			best_d = d
			best_id = str(id)
	return best_id


func _process(delta: float) -> void:
	_sway_t += delta
	for i in _sway_nodes.size():
		var nd: Node2D = _sway_nodes[i]
		if nd != null and is_instance_valid(nd):
			nd.rotation = sin(_sway_t * 1.4 + float(i) * 1.3) * 0.025
	for ps in _pet_stations:
		var st: Node2D = ps.get("station", null) as Node2D
		var an: Node2D = ps.get("node", null) as Node2D
		if st != null and is_instance_valid(st) and an != null and is_instance_valid(an):
			st.position = an.position

	# Hover chuột & hoạt ảnh nhún thở cho 11 vị tướng trên bục
	if (ui == null or not ui.is_open()) and not in_basement and not _transitioning and world != null:
		var mpos: Vector2 = world.get_global_mouse_position()
		var hit: String = _hero_at_world_pos(mpos, 28.0)
		if hit != "":
			_hovered_hero_id = hit
		elif not hero_confirmed and Global.using_pad and _cursor_hero_idx >= 0 and _cursor_hero_idx < HeroData.ORDER.size():
			_hovered_hero_id = HeroData.ORDER[_cursor_hero_idx]
		else:
			_hovered_hero_id = ""
	else:
		_hovered_hero_id = ""

	var h_idx: int = 0
	for id in _hero_npcs:
		var hs: Node2D = _hero_npcs[id]
		if hs != null and is_instance_valid(hs) and hs.visible and hs.get_child_count() > 0:
			var spr := hs.get_child(0) as AnimatedSprite2D
			if spr != null:
				var br: float = sin(_sway_t * 3.4 + float(h_idx) * 0.7) * 0.035
				var hov: bool = str(id) == _hovered_hero_id
				var hov_boost: float = 1.12 if hov else 1.0
				spr.scale = Vector2((1.0 - br) * hov_boost, (1.0 + br) * hov_boost)
				if player != null and is_instance_valid(player) and hero_confirmed:
					spr.flip_h = player.global_position.x < hs.global_position.x
				if spr.sprite_frames != null and spr.sprite_frames.has_animation("action"):
					var near_pl: bool = player != null and is_instance_valid(player) and hero_confirmed and hs.global_position.distance_to(player.global_position) < 62.0
					var train_pulse: bool = fmod(_sway_t + float(h_idx) * 1.15, 5.2) < 1.35
					spr.play("action" if (hov or near_pl or train_pulse) else "idle")
		h_idx += 1

	var r_idx: int = 0
	for rid in _rescued_npc_nodes:
		var rnd: Node2D = _rescued_npc_nodes[rid] as Node2D
		if rnd != null and is_instance_valid(rnd) and rnd.visible:
			var rspr: AnimatedSprite2D = rnd.get_meta("npc_spr", null) as AnimatedSprite2D
			if rspr != null and is_instance_valid(rspr):
				if player != null and is_instance_valid(player) and hero_confirmed:
					rspr.flip_h = player.global_position.x < rnd.global_position.x
				if rspr.sprite_frames != null and rspr.sprite_frames.has_animation("action"):
					var rnear: bool = player != null and is_instance_valid(player) and hero_confirmed and rnd.global_position.distance_to(player.global_position) < 72.0
					var ract: bool = rnear or fmod(_sway_t + float(r_idx) * 1.3, 4.4) < 1.8
					rspr.play("action" if ract else "idle")
				rspr.position.y = -12.0 + sin(_sway_t * 3.2 + float(r_idx)) * 0.7
		r_idx += 1

	if player == null or not is_instance_valid(player):
		return
	if camera != null and is_instance_valid(camera):
		camera.position = player.global_position if hero_confirmed else HALL_CENTER

	var best = null
	var best_d := 9999.0
	for arr in [stations, stair_stations]:
		for s in arr:
			s.near = (s.kind == "hero" and str(s.data) == _hovered_hero_id and not hero_confirmed)
			if not hero_confirmed or not s.visible:
				continue
			var d: float = s.global_position.distance_to(player.global_position)
			if d < s.radius and d < best_d:
				best = s
				best_d = d
	if best != null:
		best.near = true
	player.interact_target = best if hero_confirmed else null


func _mark_input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _change_scene_deferred(scene_path: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not is_inside_tree():
		return
	if event.is_action_pressed("pause") and (ui == null or not ui.is_open()) and not _transitioning:
		_mark_input_handled()
		_back_to_menu()
		return
	if _transitioning or (ui != null and ui.is_open()) or in_basement:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and world != null:
		var hit_m: String = _hero_at_world_pos(world.get_global_mouse_position(), 28.0)
		if hit_m != "":
			_cursor_hero_idx = maxi(0, HeroData.ORDER.find(hit_m))
			_hovered_hero_id = hit_m
			ui.open_hero(hit_m)
			_mark_input_handled()
			return
	elif event is InputEventScreenTouch and event.pressed:
		var wpos_t: Vector2 = get_canvas_transform().affine_inverse() * event.position
		var hit_t: String = _hero_at_world_pos(wpos_t, 28.0)
		if hit_t != "":
			_cursor_hero_idx = maxi(0, HeroData.ORDER.find(hit_t))
			_hovered_hero_id = hit_t
			ui.open_hero(hit_t)
			_mark_input_handled()
			return
	if not hero_confirmed:
		if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
			_cursor_hero_idx = posmod(_cursor_hero_idx - 1, HeroData.ORDER.size())
			_hovered_hero_id = HeroData.ORDER[_cursor_hero_idx]
			_mark_input_handled()
		elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
			_cursor_hero_idx = posmod(_cursor_hero_idx + 1, HeroData.ORDER.size())
			_hovered_hero_id = HeroData.ORDER[_cursor_hero_idx]
			_mark_input_handled()
		elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
			var pick_id: String = _hovered_hero_id if _hovered_hero_id != "" else HeroData.ORDER[_cursor_hero_idx]
			ui.open_hero(pick_id)
			_mark_input_handled()


func toggle_sparring() -> bool:
	if _sparring_arena != null and is_instance_valid(_sparring_arena) and _sparring_arena.has_method("toggle_sparring"):
		return bool(_sparring_arena.call("toggle_sparring"))
	return false


func _on_station(s) -> void:
	touch.reset()
	match s.kind:
		"hero":
			ui.open_hero(s.data)
		"skill_tree":
			if ui != null and ui.has_method("open_skill_tree"):
				ui.open_skill_tree()
		"pet_shrine":
			if ui != null and ui.has_method("open_pet_shrine"):
				ui.open_pet_shrine()
		"sparring":
			if ui != null and ui.has_method("open_sparring"):
				ui.open_sparring()
			else:
				toggle_sparring()
		"forge":
			ui.open_forge()
		"rack":
			ui.open_rack()
		"stele":
			ui.open_stele()
		"well":
			ui.open_well()
		"challenge":
			ui.open_challenge()
		"codex":
			ui.open_codex()
		"tea":
			ui.open_tea()
		"war_table":
			ui.open_war_table()
		"chronicles":
			if ui != null and ui.has_method("open_chronicles"):
				ui.open_chronicles()
		"weapon_test":
			if ui != null and ui.has_method("open_weapon_test_rack"):
				ui.open_weapon_test_rack()
		"garden":
			ui.open_garden()
		"enchant":
			ui.open_enchant()
		"mat_merchant":
			ui.open_mat_merchant()
		"shrine":
			ui.open_shrine()
		"supply":
			ui.open_supply()
		"pet":
			ui.open_pet(str(s.data))
		"pond":
			ui.open_pond()
		"basement_down":
			enter_basement()
		"basement_up":
			exit_basement()
		"basement_achieve":
			ui.open_achievements()
		"basement_blueprint":
			ui.open_blueprints()
		"basement_gallery":
			ui.open_weapon_gallery()


func _add_stair_station(kind: String, title: String, hint: String, pos: Vector2, sprite: Node2D, label_y: float, rad: float) -> Node2D:
	var s := Station.new()
	s.kind = kind
	s.title = title
	s.hint = hint
	s.position = pos
	s.label_offset_y = label_y
	s.radius = rad
	if sprite != null:
		s.add_child(sprite)
	s.used.connect(_on_station)
	world.add_child(s)
	stair_stations.append(s)
	return s


func _apply_basement_state(entering: bool, dest: Vector2) -> void:
	in_basement = entering
	if player != null and is_instance_valid(player):
		player.global_position = dest
		player.velocity = Vector2.ZERO
		player.interact_target = null
	if lobby_pet != null and is_instance_valid(lobby_pet):
		(lobby_pet as Node2D).global_position = dest + Vector2(-20.0, 10.0)
		lobby_pet.velocity = Vector2.ZERO
	if camera != null and is_instance_valid(camera):
		if entering:
			camera.limit_left = int(BASEMENT_RECT.position.x)
			camera.limit_top = int(BASEMENT_RECT.position.y)
			camera.limit_right = int(BASEMENT_RECT.end.x)
			camera.limit_bottom = int(BASEMENT_RECT.end.y)
		else:
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = int(SIZE.x)
			camera.limit_bottom = int(SIZE.y)
		camera.position = dest
		camera.reset_smoothing()
	if _canvas_mod != null and is_instance_valid(_canvas_mod):
		_canvas_mod.color = Color(0.86, 0.82, 0.78) if entering else Color(0.96, 0.93, 0.88)
	if _basement_down_st != null and is_instance_valid(_basement_down_st):
		_basement_down_st.visible = not entering
	if _basement_up_st != null and is_instance_valid(_basement_up_st):
		_basement_up_st.visible = entering
	for bs in _basement_stations:
		if bs != null and is_instance_valid(bs):
			bs.visible = entering


func _play_zone_music(entering: bool) -> void:
	if entering:
		Sfx.play_music("basement")
	else:
		Sfx.play_music("lobby")


func _transition_basement(entering: bool, dest: Vector2, banner: String, instant: bool) -> void:
	if instant or DisplayServer.get_name() == "headless" or not is_inside_tree():
		_apply_basement_state(entering, dest)
		_play_zone_music(entering)
		if is_inside_tree():
			Sfx.play("portal")
			if world != null:
				Fx.float_text(world, dest + Vector2(0, -28), banner, Color(1.0, 0.88, 0.42), 16)
		return
	_transitioning = true
	if ui != null and ui.is_open():
		ui.close()
	set_player_active(false)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var fade := ColorRect.new()
	fade.color = Color(0.03, 0.02, 0.05, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(fade)
	var tw_out := create_tween()
	tw_out.tween_property(fade, "color:a", 1.0, 0.18)
	await tw_out.finished
	if not is_inside_tree() or _leaving:
		if is_instance_valid(layer):
			layer.queue_free()
		_transitioning = false
		return
	_apply_basement_state(entering, dest)
	_play_zone_music(entering)
	Sfx.play("portal")
	if world != null:
		Fx.particles(world, dest, Color(1.0, 0.84, 0.36), 18, 70.0, 0.55, -20.0, 1.8)
		Fx.float_text(world, dest + Vector2(0, -28), banner, Color(1.0, 0.88, 0.42), 16)
	var tw_in := create_tween()
	tw_in.tween_property(fade, "color:a", 0.0, 0.20)
	await tw_in.finished
	if is_instance_valid(layer):
		layer.queue_free()
	if not is_inside_tree() or _leaving:
		_transitioning = false
		return
	set_player_active(true)
	_transitioning = false


func enter_basement(instant: bool = false) -> void:
	if in_basement or _transitioning:
		return
	if not hero_confirmed:
		confirm_hero(Global.selected_hero)
	await _transition_basement(true, BASEMENT_SPAWN, "Tầng Hầm Chiến Tích", instant)


func exit_basement(instant: bool = false) -> void:
	if not in_basement or _transitioning:
		return
	if not hero_confirmed:
		confirm_hero(Global.selected_hero)
	await _transition_basement(false, SURFACE_RETURN_POS, "Đại Sảnh Anh Hùng", instant)


## Xác nhận chọn tướng từ Đại Sảnh (Solo & LAN)
func confirm_hero(id: String) -> void:
	if not HeroData.DATA.has(id):
		return
	hero_confirmed = true
	Global.selected_hero = id
	if Net == null or not Net.is_online() or Net.is_host():
		Global.save_game()
	var target_pos: Vector2 = _hero_npcs[id].global_position if _hero_npcs.has(id) else SPAWN_POS
	_spawn_player(target_pos, true)
	set_player_active(true)
	if camera != null and is_instance_valid(camera):
		camera.position = player.global_position
	_refresh_heroes()
	refresh_lobby_pet()
	if Net != null and Net.is_online():
		Net.request_set_hero(id)
		Net.request_set_ready(true)
		if Global.selected_pet != "" and Global.PETS.has(Global.selected_pet):
			Net.request_set_pet(Global.selected_pet)
	if world != null:
		var hcol: Color = HeroData.DATA[id].get("color", Color(1.0, 0.88, 0.42))
		Fx.burst(world, target_pos, hcol, 32.0, 0.45)
		Fx.particles(world, target_pos, hcol, 18, 82.0, 0.55, -24.0, 2.0)
		Fx.float_text(world, target_pos + Vector2(0, -28), "Xuất chiến: %s!" % str(HeroData.DATA[id].name), Color(1.0, 0.92, 0.45), 16)


## Gọi từ bảng tướng hoặc bài kiểm thử cũ — chuyển thẳng về confirm_hero(id)
func select_hero(id: String) -> void:
	confirm_hero(id)


func on_progressed(hero_id: String, msg: String) -> void:
	var pos := Vector2.ZERO
	if _hero_npcs.has(hero_id) and _hero_npcs[hero_id].visible:
		pos = _hero_npcs[hero_id].global_position
	elif player != null and is_instance_valid(player):
		pos = player.global_position
	if hero_id == Global.selected_hero:
		_spawn_player(SPAWN_POS)
	if world != null:
		Fx.particles(world, pos, Color(1, 0.85, 0.3), 18, 80.0, 0.6, -30.0, 2.0)
		Fx.float_text(world, pos + Vector2(0, -24), msg, Color(1, 0.9, 0.4), 16)


func refresh_forged_display() -> void:
	if _forged_icon == null:
		return
	if Global.forged != "" and WeaponData.DATA.has(Global.forged):
		_forged_icon.texture = Art.tex("weapons/%s.png" % Global.forged)
		_forged_icon.visible = true
	else:
		_forged_icon.texture = null
		_forged_icon.visible = false


func _garden_tex_path(pid: String, stg: int) -> String:
	if pid == "":
		return "world/garden_plot_empty.png"
	if stg >= 2 and Global.GARDEN_PLANTS.has(pid):
		match pid:
			"linh_chi_vang":
				return "world/garden_linh_chi.png"
			"hoa_uu_dam":
				return "world/garden_uu_dam.png"
			_:
				return "world/garden_%s.png" % pid
	return "world/garden_plot_sprout.png"


func refresh_garden_display() -> void:
	Global.ensure_garden_plots()
	if _garden_wrap == null or not is_instance_valid(_garden_wrap):
		return
	var want_count: int = Global.garden_plots.size()
	while _garden_sprites.size() > want_count:
		var old_sp: Sprite2D = _garden_sprites.pop_back()
		if old_sp != null and is_instance_valid(old_sp):
			old_sp.queue_free()
	while _garden_sparkles.size() > want_count:
		var old_pt: CPUParticles2D = _garden_sparkles.pop_back()
		if old_pt != null and is_instance_valid(old_pt):
			old_pt.queue_free()
	while _garden_sprites.size() < want_count:
		var idx: int = _garden_sprites.size()
		var col_i: int = idx % 3
		var row_i: int = int(idx / 3)
		var ox: float = -60.0 + float(col_i) * 60.0
		var oy: float = -14.0 + float(row_i) * 28.0
		var p_spr := Sprite2D.new()
		p_spr.position = Vector2(ox, oy)
		_garden_wrap.add_child(p_spr)
		_garden_sprites.append(p_spr)
		var g_pt := CPUParticles2D.new()
		g_pt.position = Vector2(ox, oy - 6.0)
		g_pt.amount = 5
		g_pt.lifetime = 1.4
		g_pt.direction = Vector2.UP
		g_pt.spread = 35.0
		g_pt.gravity = Vector2(0, -12)
		g_pt.initial_velocity_min = 4.0
		g_pt.initial_velocity_max = 9.0
		g_pt.scale_amount_min = 1.0
		g_pt.scale_amount_max = 1.6
		var gg := Gradient.new()
		gg.set_color(0, Color(1.0, 0.94, 0.55, 0.9))
		gg.set_color(1, Color(1.0, 0.94, 0.55, 0.0))
		g_pt.color_ramp = gg
		g_pt.material = Art.additive()
		g_pt.z_index = 2
		g_pt.emitting = false
		_garden_wrap.add_child(g_pt)
		_garden_sparkles.append(g_pt)
	for i in mini(_garden_sprites.size(), Global.garden_plots.size()):
		var sd: Dictionary = Global.garden_plots[i]
		var pid: String = str(sd.get("plant", ""))
		var stg: int = int(sd.get("stage", 0))
		var tex_rel: String = _garden_tex_path(pid, stg)
		var ripe: bool = (pid != "" and stg >= 2 and Global.GARDEN_PLANTS.has(pid))
		_garden_sprites[i].texture = Art.tex(tex_rel)
		if i < _garden_sparkles.size():
			_garden_sparkles[i].emitting = ripe


func _refresh_rescued_npcs() -> void:
	if world == null:
		return
	var specs: Dictionary = {
		"than_y_tue_tinh": {"pos": Vector2(240, 466), "sheet": "world/npc_scholar.png", "fw": 24, "fh": 30},
		"nghe_nhan_phu_lang": {"pos": Vector2(384, 462), "sheet": "world/npc_blacksmith.png", "fw": 28, "fh": 30},
		"quan_su_co_loa": {"pos": Vector2(612, 616), "sheet": "world/npc_strategist.png", "fw": 24, "fh": 30},
		"vo_su_thien_nam": {"pos": Vector2(1184, 654), "sheet": "world/npc_guard.png", "fw": 24, "fh": 30},
	}
	for npc_id_v in CampNpcs.NPC_ORDER:
		var npc_id: String = str(npc_id_v)
		var unlocked_npc: bool = _is_npc_rescued(npc_id)
		var existing: Node2D = _rescued_npc_nodes.get(npc_id, null) as Node2D
		if not unlocked_npc:
			if existing != null and is_instance_valid(existing):
				existing.queue_free()
				_rescued_npc_nodes.erase(npc_id)
			continue
		if existing != null and is_instance_valid(existing):
			existing.visible = true
			continue
		var sp: Dictionary = specs.get(npc_id, {})
		var info: Dictionary = CampNpcs.get_npc(npc_id)
		var col: Color = info.get("color", Color(1.0, 0.9, 0.5)) as Color
		var nd := Node2D.new()
		nd.position = sp.get("pos", SPAWN_POS) as Vector2
		nd.z_index = 1
		var sh := Sprite2D.new()
		sh.texture = Art.tex("fx/shadow.png")
		sh.position = Vector2(0, 2)
		sh.z_index = -1
		nd.add_child(sh)
		var spr := AnimatedSprite2D.new()
		var npc_rel: String = str(sp.get("sheet", "world/npc_scholar.png"))
		var npc_fw: int = int(sp.get("fw", 24))
		var npc_fh: int = int(sp.get("fh", 30))
		var npc_tex: Texture2D = Art.tex(npc_rel)
		if npc_tex != null and npc_tex.get_width() >= npc_fw * 8:
			spr.sprite_frames = Art.frames(npc_rel, npc_fw, npc_fh, {
				"idle": [[0, 1, 2, 3], 4.4, true],
				"action": [[4, 5, 6, 7], 7.5, true],
			})
			spr.play("idle")
		else:
			spr.sprite_frames = Art.strip(npc_rel, npc_fw, npc_fh, 4.2, true)
			spr.play("play")
		spr.position = Vector2(0, -12)
		spr.modulate = col.lerp(Color.WHITE, 0.55)
		nd.add_child(spr)
		nd.set_meta("npc_spr", spr)
		var lb := Label.new()
		lb.text = CampNpcs.npc_name(npc_id)
		lb.position = Vector2(-56, -38)
		lb.size = Vector2(112, 14)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_font_size_override("font_size", 10)
		lb.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.3))
		lb.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.06, 0.95))
		lb.add_theme_constant_override("outline_size", 2)
		nd.add_child(lb)
		world.add_child(nd)
		_rescued_npc_nodes[npc_id] = nd
	refresh_garden_display()


func on_forged() -> void:
	refresh_forged_display()
	if world != null:
		Fx.particles(world, _forge_pos + Vector2(0, -8), Color(1, 0.72, 0.25), 14, 70.0, 0.55, -25.0, 2.0)
		Fx.particles(world, _forge_pos + Vector2(0, -8), Color(1, 0.94, 0.55), 10, 50.0, 0.4, -30.0, 1.5)


func on_well_result(msg: String, reward_col := Color(0.5, 0.95, 1.0)) -> void:
	on_station_fx(_well_pos, msg, reward_col)


func on_station_fx(pos: Vector2, msg: String, col := Color(1.0, 0.9, 0.45)) -> void:
	if world != null:
		Fx.burst(world, pos + Vector2(0, -4), col, 28.0, 0.45)
		Fx.particles(world, pos + Vector2(0, -6), col, 16, 72.0, 0.55, -24.0, 2.0)
		Fx.float_text(world, pos + Vector2(0, -26), msg, col, 14)


func on_pet_interacted(pet_id: String, msg: String, col := Color(1.0, 0.6, 0.78)) -> void:
	var any_triggered: bool = false
	for ps in _pet_stations:
		if str(ps.get("pet_id", "")) != pet_id:
			continue
		var nd: Node2D = ps.get("node", null) as Node2D
		if nd != null and is_instance_valid(nd):
			if nd.has_method("trigger_happy"):
				nd.trigger_happy(2.8)
			if not any_triggered:
				on_station_fx(nd.position, msg, col)
				any_triggered = true
	if not any_triggered and player != null and is_instance_valid(player):
		on_station_fx(player.global_position, msg, col)


func refresh_lobby_pet() -> void:
	var active_pet: String = Global.selected_pet if (hero_confirmed and Global.selected_pet != "" and Global.PETS.has(Global.selected_pet)) else ""
	for ps in _pet_stations:
		var nd: Node2D = ps.get("node", null) as Node2D
		var ps_pid: String = str(ps.get("pet_id", ""))
		if nd == null or not is_instance_valid(nd):
			continue
		var hide_rest: bool = (active_pet != "" and ps_pid == active_pet)
		if nd.has_method("set_resting_hidden"):
			nd.set_resting_hidden(hide_rest)
		else:
			nd.visible = not hide_rest
	if active_pet != "" and player != null and is_instance_valid(player) and world != null:
		if lobby_pet != null and is_instance_valid(lobby_pet) and str(lobby_pet.get("pet_id")) == active_pet:
			lobby_pet.owner_player = player
			lobby_pet.in_lobby = true
		else:
			if lobby_pet != null and is_instance_valid(lobby_pet):
				lobby_pet.queue_free()
			var lp := Pet.new()
			lp.in_lobby = true
			lp.setup(active_pet, player)
			lp.position = player.global_position + Vector2(-20.0, 10.0)
			world.add_child(lp)
			lobby_pet = lp
	else:
		if lobby_pet != null and is_instance_valid(lobby_pet):
			lobby_pet.queue_free()
			lobby_pet = null


func refresh_pet_stations() -> void:
	for ps in _pet_stations:
		var st = ps.get("station", null)
		var pid: String = str(ps.get("pet_id", ""))
		if st == null or not is_instance_valid(st) or not Global.PETS.has(pid):
			continue
		var pinfo: Dictionary = Global.PETS[pid]
		var chosen: bool = (Global.selected_pet == pid)
		st.title = ("%s ★ (Đang theo)" % str(pinfo.name)) if chosen else str(pinfo.name)
		st.title_color = Color(1.0, 0.9, 0.35) if chosen else Color(0.88, 0.96, 0.92)
	refresh_lobby_pet()


func on_koi_fed() -> void:
	var pond_nd = _animal_nodes.get("pond", null)
	if pond_nd != null and is_instance_valid(pond_nd) and pond_nd.has_method("trigger_koi_feed"):
		pond_nd.trigger_koi_feed()
	on_station_fx(Vector2(215, 560), "Cá Koi chúc phúc! +10 xu", Color(0.55, 0.94, 1.0))


func set_player_active(on: bool) -> void:
	if player != null and is_instance_valid(player):
		var eff_on: bool = on and hero_confirmed
		player.set_physics_process(eff_on)
		player.visible = hero_confirmed
		player.velocity = Vector2.ZERO


func start_run_with_code(code: String) -> void:
	if _leaving:
		return
	if Net != null and Net.is_online():
		if not Net.is_host():
			return
		if not Net.all_peers_confirmed():
			if _north_portal != null and is_instance_valid(_north_portal):
				_north_portal.set("_used", false)
				_north_portal.set("_counting", false)
			if world != null:
				Fx.float_text(world, Vector2(680, 92), "Chờ đồng đội chọn & xác nhận tướng!", Color(1.0, 0.55, 0.35), 14)
			return
		if player != null and is_instance_valid(player) and player.has_method("restore_test_weapons"):
			player.restore_test_weapons()
		_leaving = true
		Sfx.play("level_clear")
		Net.host_start_match()
		return
	if player != null and is_instance_valid(player) and player.has_method("restore_test_weapons"):
		player.restore_test_weapons()
	_leaving = true
	set_process_unhandled_input(false)
	Sfx.play("level_clear")
	Global.pending_challenge_code = ""
	Global.save_game()
	Global.start_run(code)
	_change_scene_deferred("res://scenes/game.tscn")


func _start_run() -> void:
	start_run_with_code(Global.pending_challenge_code)


func _back_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	set_process_unhandled_input(false)
	if ui != null and is_instance_valid(ui) and ui.is_open():
		ui.close()
	if Net != null and Net.is_online():
		Net.leave_room()
	else:
		Global.save_game()
	_change_scene_deferred("res://scenes/main_menu.tscn")


# ------------------------------------------------------------------ Đồng bộ LAN trong Doanh Trại

func _connect_net_signals() -> void:
	if Net == null:
		return
	if not Net.lobby_updated.is_connected(_on_net_lobby_updated):
		Net.lobby_updated.connect(_on_net_lobby_updated)
	if not Net.match_started.is_connected(_on_net_match_started):
		Net.match_started.connect(_on_net_match_started)
	if not Net.host_left.is_connected(_on_net_host_left):
		Net.host_left.connect(_on_net_host_left)
	if not Net.player_state_received.is_connected(_on_net_player_state):
		Net.player_state_received.connect(_on_net_player_state)
	if not Net.player_action_received.is_connected(_on_net_player_action):
		Net.player_action_received.connect(_on_net_player_action)


func _disconnect_net_signals() -> void:
	if Net == null:
		return
	if Net.lobby_updated.is_connected(_on_net_lobby_updated):
		Net.lobby_updated.disconnect(_on_net_lobby_updated)
	if Net.match_started.is_connected(_on_net_match_started):
		Net.match_started.disconnect(_on_net_match_started)
	if Net.host_left.is_connected(_on_net_host_left):
		Net.host_left.disconnect(_on_net_host_left)
	if Net.player_state_received.is_connected(_on_net_player_state):
		Net.player_state_received.disconnect(_on_net_player_state)
	if Net.player_action_received.is_connected(_on_net_player_action):
		Net.player_action_received.disconnect(_on_net_player_action)


func _sync_remote_lobby_peers() -> void:
	if Net == null or not Net.is_online() or world == null:
		return
	var local_pid: int = Net.local_peer_id()
	var stale: Array = []
	for pid in remote_players:
		if not Net.players.has(pid):
			stale.append(pid)
	for pid in stale:
		var old_p: Variant = remote_players[pid]
		remote_players.erase(pid)
		if old_p != null and is_instance_valid(old_p):
			(old_p as Node).queue_free()
		if remote_pets.has(pid):
			var old_pet: Variant = remote_pets[pid]
			remote_pets.erase(pid)
			if old_pet != null and is_instance_valid(old_pet):
				(old_pet as Node).queue_free()

	for pid_v in Net.players:
		var pid: int = int(pid_v)
		if pid == local_pid:
			continue
		var info: Dictionary = Net.players[pid_v]
		var hid: String = str(info.get("hero", "ngo_quyen"))
		if not HeroData.DATA.has(hid):
			hid = "ngo_quyen"
		var confirmed: bool = bool(info.get("hero_confirmed", false))
		var sidx: int = int(info.get("slot_idx", 0))
		var rp: Node = remote_players.get(pid, null)
		if rp == null or not is_instance_valid(rp) or str(rp.get("hero_id")) != hid:
			var keep_pos: Vector2 = SPAWN_POS + Vector2(float(sidx - 1) * 24.0, 0.0)
			if rp != null and is_instance_valid(rp):
				keep_pos = (rp as Node2D).global_position
				rp.queue_free()
			var np := Player.new()
			np.peer_id = pid
			np.is_local = false
			np.display_name = str(info.get("name", "Đồng đội"))
			var col_v: Variant = info.get("color", Net.PLAYER_COLORS[sidx % Net.PLAYER_COLORS.size()])
			if col_v is Color:
				np.name_color = col_v
			np.setup(hid)
			if "body" in np and np.body != null and is_instance_valid(np.body):
				var rskin: Dictionary = HeroSkins.get_skin(hid, str(info.get("skin", HeroSkins.DEFAULT_SKIN)))
				var rcol: Variant = rskin.get("modulate", Color.WHITE)
				if rcol is Color:
					np.body.modulate = rcol as Color
			np.position = keep_pos
			np.set("_remote_pos", keep_pos)
			np.visible = confirmed
			world.add_child(np)
			remote_players[pid] = np
			rp = np
		else:
			rp.set("display_name", str(info.get("name", "Đồng đội")))
			rp.visible = confirmed
			if "body" in rp and rp.body != null and is_instance_valid(rp.body):
				var rskin2: Dictionary = HeroSkins.get_skin(hid, str(info.get("skin", HeroSkins.DEFAULT_SKIN)))
				var rcol2: Variant = rskin2.get("modulate", Color.WHITE)
				if rcol2 is Color:
					rp.body.modulate = rcol2 as Color

		var pet_id: String = str(info.get("pet", ""))
		var rpet: Node = remote_pets.get(pid, null)
		if confirmed and pet_id != "" and Global.PETS.has(pet_id):
			if rpet == null or not is_instance_valid(rpet) or str(rpet.get("pet_id")) != pet_id:
				if rpet != null and is_instance_valid(rpet):
					rpet.queue_free()
				var npet := Pet.new()
				npet.in_lobby = true
				npet.setup(pet_id, rp)
				npet.position = (rp as Node2D).global_position + Vector2(-20.0, 10.0)
				world.add_child(npet)
				remote_pets[pid] = npet
			else:
				rpet.set("owner_player", rp)
		elif rpet != null and is_instance_valid(rpet):
			remote_pets.erase(pid)
			rpet.queue_free()


func _on_net_lobby_updated() -> void:
	_sync_remote_lobby_peers()
	_refresh_heroes()


func _on_net_match_started(_seed_val: int, _level: int) -> void:
	if _leaving or not is_inside_tree():
		return
	if player != null and is_instance_valid(player) and player.has_method("restore_test_weapons"):
		player.restore_test_weapons()
	_leaving = true
	set_process_unhandled_input(false)
	_change_scene_deferred("res://scenes/game.tscn")


func _on_net_host_left(_reason: String) -> void:
	if _leaving:
		return
	_leaving = true
	set_process_unhandled_input(false)
	if Net != null:
		Net.leave_room()
	_change_scene_deferred("res://scenes/main_menu.tscn")


func _on_net_player_state(peer_id: int, state: Dictionary) -> void:
	var rp: Variant = remote_players.get(peer_id, null)
	if rp != null and is_instance_valid(rp):
		rp.apply_remote_state(state)
		var confirmed: bool = bool(Net.players.get(peer_id, {}).get("hero_confirmed", true))
		(rp as Node2D).visible = confirmed


func _on_net_player_action(peer_id: int, kind: String, data: Dictionary) -> void:
	var rp: Variant = remote_players.get(peer_id, null)
	if rp != null and is_instance_valid(rp):
		rp.play_remote_action(kind, data)
