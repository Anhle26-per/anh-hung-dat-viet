extends Node2D
## Sinh hầm ngục ngẫu nhiên: các phòng nối nhau bằng hành lang.
## Phòng đầu = an toàn, phòng xa nhất = cổng ra (mỗi 3 màn là phòng trùm),
## một phòng cụt = phòng kho báu, có thể có phòng gánh hàng rong, còn lại = phòng đánh quái.

signal portal_entered

const Room = preload("res://scripts/game/room.gd")
const Decor = preload("res://scripts/game/decor.gd")
const Cover = preload("res://scripts/entities/cover.gd")
const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

const T := 16          # kích thước 1 ô (pixel)
const ROOM_W := 29     # chiều rộng phòng (ô) - rộng rãi để né đạn, né bẫy & chiến đấu
const ROOM_H := 21     # chiều cao phòng (ô)
const GAP := 6         # độ dài hành lang (ô)
const CORR := 3        # bề rộng hành lang (ô)
const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

var tiles: TileMapLayer
var rooms: Dictionary = {}    # ô lưới (Vector2i) -> Room
var rooms_by_key: Dictionary = {}   # khóa phòng "x,y" -> Room
var links: Array = []         # các cặp [ô, ô] được nối với nhau


class DungeonBackdrop extends Node2D:
	## Phông nền không gian bên ngoài các phòng (thay khoảng đen đơn điệu bằng cảnh núi rừng/sông/thành mờ).
	var bounds: Rect2 = Rect2()
	var theme_id: int = 0
	var seed_val: int = 1

	func _draw() -> void:
		if bounds.size == Vector2.ZERO:
			return
		var bg_cols: Array[Color] = [
			Color(0.08, 0.12, 0.09), # 0 rừng núi
			Color(0.06, 0.10, 0.16), # 1 sông nước
			Color(0.13, 0.07, 0.09), # 2 Thăng Long
			Color(0.10, 0.09, 0.14), # 3 Đống Đa
			Color(0.11, 0.10, 0.07), # 4 làng quê
			Color(0.09, 0.10, 0.11), # 5 đồn Pháp
			Color(0.10, 0.08, 0.06), # 6 chiến hào
			Color(0.12, 0.08, 0.08), # 7 doanh trại
		]
		var acc_cols: Array[Color] = [
			Color(0.14, 0.22, 0.14), Color(0.11, 0.20, 0.30), Color(0.24, 0.11, 0.12), Color(0.22, 0.15, 0.20),
			Color(0.18, 0.20, 0.11), Color(0.15, 0.17, 0.16), Color(0.18, 0.14, 0.10), Color(0.22, 0.12, 0.11),
		]
		var bg: Color = bg_cols[theme_id % bg_cols.size()]
		var ac: Color = acc_cols[theme_id % acc_cols.size()]
		draw_rect(bounds, bg)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		# Các dải đồi / tán cây / sóng nước mềm ở nền xa
		var y_step: float = 95.0
		var y: float = bounds.position.y + 40.0
		var band: int = 0
		while y < bounds.end.y:
			var ridge: PackedVector2Array = PackedVector2Array()
			ridge.append(Vector2(bounds.position.x, y + 60.0))
			var x: float = bounds.position.x
			while x <= bounds.end.x + 60.0:
				var wave: float = sin(x * 0.012 + float(band) * 1.7) * 18.0 + cos(x * 0.029 - float(band)) * 9.0
				ridge.append(Vector2(x, y + wave))
				x += 48.0
			ridge.append(Vector2(bounds.end.x, y + 60.0))
			var shade: Color = ac.lerp(bg, 0.35 + 0.18 * float(band % 3))
			draw_colored_polygon(ridge, Color(shade.r, shade.g, shade.b, 0.45))
			if theme_id == 1:
				for k in 8:
					var wx: float = rng.randf_range(bounds.position.x, bounds.end.x)
					draw_rect(Rect2(wx, y + 10.0, rng.randf_range(24.0, 56.0), 2.0), Color(0.35, 0.58, 0.78, 0.18))
			y += y_step
			band += 1
		# Đốm sương / tán cây mờ tạo chiều sâu
		for i in 42:
			var p := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
			var rad: float = rng.randf_range(22.0, 54.0)
			draw_circle(p, rad, Color(ac.r, ac.g, ac.b, 0.16))


class RoomOverlay extends Node2D:
	## Lớp trang trí mượt (hình tròn/bát giác sân giữa, vệt sáng ấm, chuyển sắc góc phòng) để bớt cảm giác vuông khối.
	var items: Array = []

	func _draw() -> void:
		for it in items:
			var c: Vector2 = it["center"]
			var kind: String = it["kind"]
			var col: Color = it["accent"]
			var shape_kind: String = it["shape"]
			# Mảng màu ấm nhẹ giữa phòng phá cảm giác đơn sắc
			var glow_col: Color = Color(1.0, 0.85, 0.55, 0.08) if kind in ["treasure", "shop", "start"] else Color(col.r, col.g, col.b, 0.07)
			if kind == "boss" or kind == "legend":
				glow_col = Color(0.95, 0.32, 0.28, 0.09)
			draw_circle(c, 58.0, glow_col)
			draw_circle(c, 34.0, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * 1.15))
			# Vòng hoa văn sân tròn / trống đồng giữa phòng
			var ring_col: Color = Color(0.95, 0.78, 0.36, 0.26) if kind in ["boss", "legend", "treasure", "shop"] else Color(col.r, col.g, col.b, 0.18)
			var pts := PackedVector2Array()
			var sides: int = 8 if shape_kind == "octagon" else 24
			var r_out: float = 54.0 if kind in ["boss", "legend"] else 38.0
			for i in range(sides + 1):
				var a: float = TAU * float(i) / float(sides)
				pts.append(c + Vector2(cos(a) * r_out, sin(a) * r_out * 0.78))
			draw_polyline(pts, ring_col, 1.5, true)
			if kind in ["boss", "legend", "treasure", "start"]:
				var inner := PackedVector2Array()
				for i in range(sides + 1):
					var a2: float = TAU * float(i) / float(sides)
					inner.append(c + Vector2(cos(a2) * (r_out * 0.62), sin(a2) * (r_out * 0.62 * 0.78)))
				draw_polyline(inner, Color(ring_col.r, ring_col.g, ring_col.b, ring_col.a * 0.75), 1.0, true)


func _ready() -> void:
	add_to_group("dungeon")


func generate(level: int) -> void:
	tiles = TileMapLayer.new()
	tiles.tile_set = _make_tileset()
	tiles.z_index = -2
	var chapter := EnemyData.chapter(level)
	var row: int = chapter.theme
	add_child(tiles)

	# 1) Chọn vị trí các phòng trên lưới
	var count := 5 + mini(level, 3)
	var cells: Array = [Vector2i.ZERO]
	var guard := 0
	while cells.size() < count and guard < 2000:
		guard += 1
		var from: Vector2i = cells.pick_random() if randf() < 0.4 else cells.back()
		var to: Vector2i = from + DIRS.pick_random()
		if cells.has(to) or _neighbor_count(to, cells) > 1:
			continue
		cells.append(to)
		links.append([from, to])

	# 2) Tính khoảng cách từ phòng đầu để tìm phòng xa nhất
	var adj := {}
	for c in cells:
		adj[c] = []
	for l in links:
		adj[l[0]].append(l[1])
		adj[l[1]].append(l[0])
	var dist := {Vector2i.ZERO: 0}
	var queue: Array = [Vector2i.ZERO]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in adj[c]:
			if not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var exit_cell := Vector2i.ZERO
	var best := -1
	for c in cells:
		if dist[c] > best:
			best = dist[c]
			exit_cell = c
	var others := cells.filter(func(c): return c != Vector2i.ZERO and c != exit_cell)
	var leaves := others.filter(func(c): return adj[c].size() == 1)
	var treasure_cell := Vector2i(9999, 9999)
	if not leaves.is_empty():
		treasure_cell = leaves.pick_random()
	elif others.size() >= 3:
		treasure_cell = others.pick_random()

	# phòng gánh hàng rong (từ màn 2, 65%): ưu tiên phòng cụt khác phòng kho báu
	var shop_cell := Vector2i(9999, 9999)
	if level >= 2 and randf() < 0.65:
		var cand := leaves.filter(func(c): return c != treasure_cell)
		if cand.is_empty() and others.size() >= 4:
			cand = others.filter(func(c): return c != treasure_cell)
		if not cand.is_empty():
			shop_cell = cand.pick_random()

	# 3) Đặt sàn cho phòng + hành lang với kiến trúc vát góc / hốc / trụ tường, ghi lại vị trí cửa
	var floor_cells := {}
	var corridor_cells := {}
	var doors := {}
	var room_kinds := {}
	var room_shapes := {}
	for c in cells:
		var k: String = "combat"
		if c == Vector2i.ZERO:
			k = "start"
		elif c == exit_cell:
			k = "boss" if level % 3 == 0 else "exit"
			if level % 3 == 2 and randf() < Global.legend_chance:
				k = "legend"
		elif c == treasure_cell:
			k = "treasure"
		elif c == shop_cell:
			k = "shop"
		room_kinds[c] = k
		if k in ["boss", "legend", "treasure", "start", "exit"]:
			room_shapes[c] = "octagon"
		elif k == "shop":
			room_shapes[c] = "buttress"
		else:
			var roll: float = randf()
			room_shapes[c] = "octagon" if roll < 0.45 else ("alcove" if roll < 0.75 else "buttress")

	for c in cells:
		doors[c] = []
		var o := _origin(c)
		var sh: String = str(room_shapes[c])
		for x in ROOM_W:
			for y in ROOM_H:
				if _is_carved(x, y, sh, adj[c], c):
					continue
				floor_cells[o + Vector2i(x, y)] = true
	for l in links:
		var a: Vector2i = l[0]
		var b: Vector2i = l[1]
		if b.x < a.x or b.y < a.y:
			var tmp := a
			a = b
			b = tmp
		var oa := _origin(a)
		var ob := _origin(b)
		if a.y == b.y:  # hành lang ngang
			var y0 := oa.y + ROOM_H / 2 - 1
			for x in range(oa.x + ROOM_W, ob.x):
				for i in CORR:
					var cp := Vector2i(x, y0 + i)
					floor_cells[cp] = true
					corridor_cells[cp] = true
			doors[a].append(Rect2(Vector2(oa.x + ROOM_W, y0) * T, Vector2(1, CORR) * T))
			doors[b].append(Rect2(Vector2(ob.x - 1, y0) * T, Vector2(1, CORR) * T))
		else:  # hành lang dọc
			var x0 := oa.x + ROOM_W / 2 - 1
			for y in range(oa.y + ROOM_H, ob.y):
				for i in CORR:
					var cp2 := Vector2i(x0 + i, y)
					floor_cells[cp2] = true
					corridor_cells[cp2] = true
			doors[a].append(Rect2(Vector2(x0, oa.y + ROOM_H) * T, Vector2(CORR, 1) * T))
			doors[b].append(Rect2(Vector2(x0, ob.y - 1) * T, Vector2(CORR, 1) * T))

	# 4) Phông nền ngoại cảnh, xếp ô gạch đa sắc, bóng đổ mềm, vòng trang trí và chi tiết rải sàn
	_add_backdrop(floor_cells, row, level)
	paint(tiles, floor_cells, row)
	_paint_zones(floor_cells, corridor_cells, cells, room_kinds, doors, row)
	var shade := TileMapLayer.new()
	shade.tile_set = tiles.tile_set
	shade.z_index = -1
	add_child(shade)
	paint_shadows(shade, floor_cells)
	var walkway_set: Dictionary = _collect_walkways(corridor_cells, cells, doors)
	_scatter_details(floor_cells, walkway_set, chapter)

	# 5) Tạo các phòng
	var overlay := RoomOverlay.new()
	overlay.z_index = 0
	var theme_accents: Array[Color] = [
		Color("72b84a"), Color("62a8d8"), Color("f0b84e"), Color("f4a0c0"),
		Color("74b844"), Color("9aa878"), Color("e0a850"), Color("f0b84e"),
	]
	var ov_items: Array = []
	for c in cells:
		var r := Room.new()
		r.rect = Rect2(Vector2(_origin(c)) * T, Vector2(ROOM_W, ROOM_H) * T)
		r.level = level
		r.room_key = "%d,%d" % [c.x, c.y]
		r.door_rects = doors[c]
		r.kind = str(room_kinds[c])
		if r.kind == "legend":
			r.legend_id = Global.pick_legend()
		r.portal_entered.connect(func(): portal_entered.emit())
		add_child(r)
		rooms[c] = r
		rooms_by_key[r.room_key] = r
		_decorate(c, r.kind, doors[c], chapter, floor_cells)
		ov_items.append({"center": r.rect.get_center(), "kind": r.kind, "shape": str(room_shapes[c]), "accent": theme_accents[row % theme_accents.size()]})
		if r.kind in ["start", "treasure", "shop", "boss", "legend"]:
			var lcol: Color = Color(1.0, 0.55, 0.35) if r.kind in ["boss", "legend"] else Color(1.0, 0.86, 0.55)
			var pl := Art.light(lcol, 0.42 if r.kind == "boss" else 0.52, 2.2)
			pl.position = r.rect.get_center()
			add_child(pl)
	overlay.items = ov_items
	add_child(overlay)
	move_child(overlay, shade.get_index() + 1)


func start_position() -> Vector2:
	return rooms[Vector2i.ZERO].rect.get_center()


func get_room_by_key(key: String) -> Node:
	if rooms_by_key.has(key):
		var rm: Variant = rooms_by_key[key]
		if rm != null and is_instance_valid(rm):
			return rm as Node
	return null


func neighbors_of(c: Vector2i) -> Array:
	var out: Array = []
	for l in links:
		if l[0] == c:
			out.append(l[1])
		elif l[1] == c:
			out.append(l[0])
	return out


func _origin(c: Vector2i) -> Vector2i:
	return Vector2i(c.x * (ROOM_W + GAP), c.y * (ROOM_H + GAP))


func _neighbor_count(c: Vector2i, cells: Array) -> int:
	var n := 0
	for d in DIRS:
		if cells.has(c + d):
			n += 1
	return n


## Bộ ô gạch lấy từ assets/sprites/world/tiles.png (mỗi hàng 1 chương):
## cột 0-3: sàn, 4-5: mặt tường, 6-7: nóc tường.
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
	# nguồn 1: bóng đổ (trên, trái, góc), không va chạm
	var sh := TileSetAtlasSource.new()
	sh.texture = Art.tex("world/shadows.png")
	sh.texture_region_size = Vector2i(T, T)
	ts.add_source(sh, 1)
	for i in 3:
		sh.create_tile(Vector2i(i, 0))
	return ts


## Xếp gạch: sàn + tường. Tường phía trên sàn cao 2 ô (tầng dưới, tầng trên) + nóc;
## các phía còn lại là nóc tường. Dùng chung cho hầm ngục và doanh trại.
static func paint(tiles: TileMapLayer, floor_cells: Dictionary, row: int) -> void:
	for p in floor_cells:
		var r := randf()
		var v := 0 if r < 0.66 else (1 if r < 0.8 else (2 if r < 0.92 else 3))
		tiles.set_cell(p, 0, Vector2i(v, row))
	var face := {}
	for p in floor_cells:
		var above: Vector2i = p + Vector2i(0, -1)
		if not floor_cells.has(above):
			face[above] = 6 + (1 if randf() < 0.15 else 0)
			var up2: Vector2i = p + Vector2i(0, -2)
			if not floor_cells.has(up2) and not face.has(up2):
				face[up2] = 4 + (1 if randf() < 0.15 else 0)
	for q in face:
		tiles.set_cell(q, 0, Vector2i(face[q], row))
	for p in floor_cells:
		for dx in [-1, 0, 1]:
			for dy in [-3, -2, -1, 0, 1]:
				var q: Vector2i = p + Vector2i(dx, dy)
				if floor_cells.has(q) or face.has(q):
					continue
				if dy <= -2 and dx == 0 and not face.has(q + Vector2i(0, 1)):
					continue
				tiles.set_cell(q, 0, Vector2i(8, row))


static func paint_shadows(shade: TileMapLayer, floor_cells: Dictionary) -> void:
	for p in floor_cells:
		var top := not floor_cells.has(p + Vector2i(0, -1))
		var left := not floor_cells.has(p + Vector2i(-1, 0))
		if top and left:
			shade.set_cell(p, 1, Vector2i(2, 0))
		elif top:
			shade.set_cell(p, 1, Vector2i(0, 0))
		elif left:
			shade.set_cell(p, 1, Vector2i(1, 0))


## Rải chi tiết nhỏ trên sàn (sỏi, cỏ, lá, hoa, vết nứt...) theo bối cảnh
func _scatter_details(floor_cells: Dictionary, walkway_set: Dictionary, chapter: Dictionary) -> void:
	var by_theme := {0: [0, 1, 2, 3, 4], 1: [0, 2, 6], 2: [0, 4, 2], 3: [0, 3, 4], 4: [0, 1, 1, 3, 7],
		5: [0, 4, 5], 6: [0, 4, 5, 6, 7]}
	var opts: Array = by_theme.get(int(chapter.theme), [0, 4])
	var tex := Art.tex("world/details.png")
	for p in floor_cells:
		if walkway_set.has(p):
			continue
		if randf() < 0.12:
			var s := Sprite2D.new()
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(int(opts.pick_random()) * T, 0, T, T)
			s.texture = at
			s.position = Vector2(p) * T + Vector2(T, T) / 2.0
			s.flip_h = randf() < 0.5
			s.z_index = -1
			add_child(s)


func _is_carved(x: int, y: int, shape: String, neighbors: Array, cell: Vector2i) -> bool:
	var dx: int = mini(x, ROOM_W - 1 - x)
	var dy: int = mini(y, ROOM_H - 1 - y)
	if shape == "octagon":
		return dx + dy <= 1
	if shape == "alcove":
		return dx <= 2 and dy <= 1
	if shape == "buttress":
		if y == 0 and not neighbors.has(cell + Vector2i.UP) and (x == 5 or x == ROOM_W - 6):
			return true
		if y == ROOM_H - 1 and not neighbors.has(cell + Vector2i.DOWN) and (x == 5 or x == ROOM_W - 6):
			return true
		if x == 0 and not neighbors.has(cell + Vector2i.LEFT) and (y == 3 or y == ROOM_H - 4):
			return true
		if x == ROOM_W - 1 and not neighbors.has(cell + Vector2i.RIGHT) and (y == 3 or y == ROOM_H - 4):
			return true
	return false


func _add_backdrop(floor_cells: Dictionary, row: int, level: int) -> void:
	if floor_cells.is_empty():
		return
	var min_x: int = 999999
	var min_y: int = 999999
	var max_x: int = -999999
	var max_y: int = -999999
	for p in floor_cells:
		var vp: Vector2i = p
		min_x = mini(min_x, vp.x)
		min_y = mini(min_y, vp.y)
		max_x = maxi(max_x, vp.x)
		max_y = maxi(max_y, vp.y)
	var bd := DungeonBackdrop.new()
	bd.bounds = Rect2(Vector2(min_x * T - 220, min_y * T - 220), Vector2((max_x - min_x + 1) * T + 440, (max_y - min_y + 1) * T + 440))
	bd.theme_id = row
	bd.seed_val = level * 37 + row * 13
	bd.z_index = -10
	add_child(bd)
	move_child(bd, 0)


func _collect_walkways(corridor_cells: Dictionary, cells: Array, doors: Dictionary) -> Dictionary:
	var out: Dictionary = corridor_cells.duplicate()
	for c in cells:
		var o := _origin(c)
		var center := o + Vector2i(ROOM_W / 2, ROOM_H / 2)
		for dx in range(-3, 4):
			for dy in range(-2, 3):
				if abs(dx) + abs(dy) <= 4:
					out[center + Vector2i(dx, dy)] = true
		for dr in doors[c]:
			var r: Rect2 = dr
			var dc := Vector2i(int(r.get_center().x / T), int(r.get_center().y / T))
			var dir_x: int = signi(center.x - dc.x)
			var dir_y: int = signi(center.y - dc.y)
			var cur := dc
			while cur != center:
				for w in range(-1, 2):
					var off := Vector2i(0, w) if dir_x != 0 else Vector2i(w, 0)
					out[cur + off] = true
				if cur.x != center.x:
					cur.x += dir_x
				elif cur.y != center.y:
					cur.y += dir_y
	return out


func _paint_zones(floor_cells: Dictionary, corridor_cells: Dictionary, cells: Array, room_kinds: Dictionary, doors: Dictionary, row: int) -> void:
	# 1) Rìa phòng tiếp giáp tường: rêu/cỏ/viền đá (cột 11) và gạch điểm xuyết (cột 13)
	for p in floor_cells:
		if corridor_cells.has(p):
			continue
		var near_wall := false
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not floor_cells.has(p + d):
				near_wall = true
				break
		if near_wall and randf() < 0.65:
			tiles.set_cell(p, 0, Vector2i(11, row))
		elif randf() < 0.09:
			tiles.set_cell(p, 0, Vector2i(13, row))

	# 2) Lối đi nối cửa <-> tâm phòng và hành lang (cột 9)
	for p in corridor_cells:
		tiles.set_cell(p, 0, Vector2i(9, row))
	for c in cells:
		var o := _origin(c)
		var center := o + Vector2i(ROOM_W / 2, ROOM_H / 2)
		for dr in doors[c]:
			var r: Rect2 = dr
			var dc := Vector2i(int(r.get_center().x / T), int(r.get_center().y / T))
			var dir_x: int = signi(center.x - dc.x)
			var dir_y: int = signi(center.y - dc.y)
			var cur := dc
			while cur != center:
				for w in range(-1, 2):
					var off := Vector2i(0, w) if dir_x != 0 else Vector2i(w, 0)
					var tp: Vector2i = cur + off
					if floor_cells.has(tp):
						tiles.set_cell(tp, 0, Vector2i(9, row))
				if cur.x != center.x:
					cur.x += dir_x
				elif cur.y != center.y:
					cur.y += dir_y

		# 3) Sân trung tâm (cột 10 / thảm son vàng cột 12 cho phòng quan trọng)
		var k: String = str(room_kinds[c])
		var royal: bool = k in ["boss", "legend", "treasure", "shop"]
		for dx in range(-3, 4):
			for dy in range(-2, 3):
				if abs(dx) + abs(dy) > 4:
					continue
				var sp: Vector2i = center + Vector2i(dx, dy)
				if not floor_cells.has(sp):
					continue
				if royal:
					var inner: bool = abs(dx) <= 2 and abs(dy) <= 1
					tiles.set_cell(sp, 0, Vector2i(12 if inner else 10, row))
				else:
					var inner2: bool = abs(dx) <= 1 and abs(dy) <= 1
					tiles.set_cell(sp, 0, Vector2i(10 if inner2 else 9, row))


func _floor_variant() -> int:
	var r := randf()
	if r < 0.62:
		return 0
	elif r < 0.77:
		return 1
	elif r < 0.92:
		return 2
	return 3


## Trang trí phòng: đuốc + cờ/đèn lồng trên tường trên (bám đúng tường đã vát góc), chum/bao cát ở góc an toàn.
func _decorate(c: Vector2i, kind: String, door_list: Array, chapter: Dictionary, floor_cells: Dictionary = {}) -> void:
	var o := _origin(c)
	var blocked := []
	for r in door_list:
		blocked.append(r)
	var hang: Array = chapter.decor
	var i := 0
	for x in range(o.x + 2, o.x + ROOM_W - 1, 4):
		var top_y_cell: int = o.y
		for y in range(o.y, o.y + 4):
			if floor_cells.is_empty() or floor_cells.has(Vector2i(x, y)):
				top_y_cell = y
				break
		var px := Vector2(x * T + T / 2.0, (top_y_cell - 1) * T)
		var ok := true
		for r in blocked:
			if r.grow(T * 1.5).has_point(px):
				ok = false
		if not ok:
			continue
		var d := Decor.new()
		if i % 2 == 0:
			d.kind = "torch"
		else:
			var opts := hang.filter(func(k): return k == "banner" or k == "lantern")
			d.kind = opts.pick_random() if not opts.is_empty() else "banner"
		d.position = px
		add_child(d)
		i += 1
	if kind == "start":
		var dr := Decor.new()
		dr.kind = "drum"
		dr.position = Vector2(o.x + ROOM_W / 2.0, o.y + ROOM_H / 2.0) * T
		add_child(dr)
	var corners := [Vector2(o.x + 1.5, o.y + 1.6), Vector2(o.x + ROOM_W - 1.5, o.y + 1.6),
		Vector2(o.x + 1.5, o.y + ROOM_H - 1.0), Vector2(o.x + ROOM_W - 1.5, o.y + ROOM_H - 1.0)]
	var plants := hang.filter(func(k): return k == "bamboo" or k == "peach")
	var allow_cover: bool = kind in ["combat", "treasure", "shop", "exit"]
	for k in corners.size():
		if randf() < 0.55:
			var pos: Vector2 = corners[k] * T
			var cell := Vector2i(int(pos.x / T), int(pos.y / T))
			var safe_floor: bool = floor_cells.is_empty() or (floor_cells.has(cell)
				and floor_cells.has(cell + Vector2i.LEFT) and floor_cells.has(cell + Vector2i.RIGHT)
				and floor_cells.has(cell + Vector2i.UP) and floor_cells.has(cell + Vector2i.DOWN))
			if not safe_floor:
				continue
			var props := hang.filter(func(x): return x == "pot" or x == "crate" or x == "sandbag")
			if not plants.is_empty() and k < 2 and randf() < 0.7:
				var d2 := Decor.new()
				d2.kind = plants[0]
				d2.position = pos
				add_child(d2)
			elif allow_cover and not props.is_empty():
				var ok_c := true
				for r in blocked:
					if (r as Rect2).grow(T * 2.5).has_point(pos):
						ok_c = false
						break
				if ok_c and rooms.has(c) and rooms[c].blacksmith != null and is_instance_valid(rooms[c].blacksmith):
					if pos.distance_to(rooms[c].blacksmith.global_position) < 28.0:
						ok_c = false
				if ok_c:
					var cv := Cover.new()
					cv.kind = props.pick_random()
					cv.position = pos
					add_child(cv)
					if rooms.has(c):
						rooms[c].covers.append(cv)
