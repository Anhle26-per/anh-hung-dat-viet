extends Node2D
## Sinh hầm ngục ngẫu nhiên: các phòng nối nhau bằng hành lang.
## Phòng đầu = an toàn, phòng xa nhất = cổng ra (mỗi 3 màn là phòng trùm),
## một phòng cụt = phòng kho báu, có thể có phòng gánh hàng rong, còn lại = phòng đánh quái.

signal portal_entered

const Room = preload("res://scripts/game/room.gd")
const Decor = preload("res://scripts/game/decor.gd")
const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

const T := 16          # kích thước 1 ô (pixel)
const ROOM_W := 21     # chiều rộng phòng (ô)
const ROOM_H := 15     # chiều cao phòng (ô)
const GAP := 6         # độ dài hành lang (ô)
const CORR := 3        # bề rộng hành lang (ô)
const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

var tiles: TileMapLayer
var rooms: Dictionary = {}    # ô lưới (Vector2i) -> Room
var links: Array = []         # các cặp [ô, ô] được nối với nhau


func _ready() -> void:
	add_to_group("dungeon")


func generate(level: int) -> void:
	tiles = TileMapLayer.new()
	tiles.tile_set = _make_tileset()
	var chapter := EnemyData.chapter(level)
	var row: int = chapter.theme
	add_child(tiles)

	# 1) Chọn vị trí các phòng trên lưới
	var count := 5 + mini(level, 5)
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

	# 3) Đặt sàn cho phòng + hành lang, ghi lại vị trí cửa
	var floor_cells := {}
	var doors := {}
	for c in cells:
		doors[c] = []
		var o := _origin(c)
		for x in ROOM_W:
			for y in ROOM_H:
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
					floor_cells[Vector2i(x, y0 + i)] = true
			doors[a].append(Rect2(Vector2(oa.x + ROOM_W, y0) * T, Vector2(1, CORR) * T))
			doors[b].append(Rect2(Vector2(ob.x - 1, y0) * T, Vector2(1, CORR) * T))
		else:  # hành lang dọc
			var x0 := oa.x + ROOM_W / 2 - 1
			for y in range(oa.y + ROOM_H, ob.y):
				for i in CORR:
					floor_cells[Vector2i(x0 + i, y)] = true
			doors[a].append(Rect2(Vector2(x0, oa.y + ROOM_H) * T, Vector2(CORR, 1) * T))
			doors[b].append(Rect2(Vector2(x0, ob.y - 1) * T, Vector2(CORR, 1) * T))

	# 4) Vẽ ô gạch: sàn, tường cao 2 ô ở phía trên, nóc tường, bóng đổ, chi tiết rải sàn
	paint(tiles, floor_cells, row)
	var shade := TileMapLayer.new()
	shade.tile_set = tiles.tile_set
	add_child(shade)
	paint_shadows(shade, floor_cells)
	_scatter_details(floor_cells, chapter)

	# 5) Tạo các phòng
	for c in cells:
		var r := Room.new()
		r.rect = Rect2(Vector2(_origin(c)) * T, Vector2(ROOM_W, ROOM_H) * T)
		r.level = level
		r.door_rects = doors[c]
		if c == Vector2i.ZERO:
			r.kind = "start"
		elif c == exit_cell:
			r.kind = "boss" if level % 3 == 0 else "exit"
			# màn giữa chương: có thể gặp 1 trong Tam Yêu canh giữ cổng
			if level % 3 == 2 and randf() < Global.legend_chance:
				r.kind = "legend"
				r.legend_id = Global.pick_legend()
		elif c == treasure_cell:
			r.kind = "treasure"
		elif c == shop_cell:
			r.kind = "shop"
		else:
			r.kind = "combat"
		r.portal_entered.connect(func(): portal_entered.emit())
		add_child(r)
		rooms[c] = r
		_decorate(c, r.kind, doors[c], chapter)


func start_position() -> Vector2:
	return rooms[Vector2i.ZERO].rect.get_center()


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
func _scatter_details(floor_cells: Dictionary, chapter: Dictionary) -> void:
	var by_theme := {0: [0, 1, 2, 3, 4], 1: [0, 2, 6], 2: [0, 4, 2], 3: [0, 3, 4], 4: [0, 1, 1, 3, 7],
		5: [0, 4, 5], 6: [0, 4, 5, 6, 7]}
	var opts: Array = by_theme.get(int(chapter.theme), [0, 4])
	var tex := Art.tex("world/details.png")
	for p in floor_cells:
		if randf() < 0.07:
			var s := Sprite2D.new()
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(int(opts.pick_random()) * T, 0, T, T)
			s.texture = at
			s.position = Vector2(p) * T + Vector2(T, T) / 2.0
			s.flip_h = randf() < 0.5
			add_child(s)


func _floor_variant() -> int:
	var r := randf()
	if r < 0.62:
		return 0
	elif r < 0.77:
		return 1
	elif r < 0.92:
		return 2
	return 3


## Trang trí phòng: đuốc + cờ/đèn lồng trên tường trên, chum ở góc, cây ở góc.
func _decorate(c: Vector2i, kind: String, door_list: Array, chapter: Dictionary) -> void:
	var o := _origin(c)
	var top_y := (o.y - 1) * T
	var blocked := []
	for r in door_list:
		blocked.append(r)
	var hang: Array = chapter.decor
	var i := 0
	for x in range(o.x + 2, o.x + ROOM_W - 1, 4):
		var px := Vector2(x * T + T / 2.0, top_y)
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
	for k in corners.size():
		if randf() < 0.55:
			var d2 := Decor.new()
			var props := hang.filter(func(x): return x == "pot" or x == "crate" or x == "sandbag")
			if not plants.is_empty() and k < 2 and randf() < 0.7:
				d2.kind = plants[0]
			elif not props.is_empty():
				d2.kind = props.pick_random()
			else:
				continue
			d2.position = corners[k] * T
			add_child(d2)
