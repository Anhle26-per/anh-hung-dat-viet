extends CanvasLayer
## Giao diện trong trận: Máu/Giáp/Năng lượng, xu, màn, bản đồ nhỏ, vũ khí (màu theo cấp),
## kỹ năng, thanh máu trùm, thông báo, giới thiệu chương, băng chân dung khi tung chiêu.

const WeaponData = preload("res://scripts/data/weapons.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

var player = null
var _banner := ""
var _banner_t := 0.0
var _chapter: Dictionary = {}
var _chapter_num := 0
var _chapter_t := 0.0
var _cutin_hero := ""
var _cutin_t := 0.0
var _icons := {}


class HudView extends Control:
	var hud

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		hud.draw_hud(self)


func _ready() -> void:
	layer = 10
	add_to_group("hud")
	for k in ["heart", "shield", "energy", "skull"]:
		_icons[k] = Art.tex("ui/icon_%s.png" % k)
	_icons["coin"] = Art.tex("items/coin.png")
	var view := HudView.new()
	view.hud = self
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)


func show_banner(text: String) -> void:
	_banner = text
	_banner_t = 2.4


func show_chapter(num: int, ch: Dictionary) -> void:
	_chapter = ch
	_chapter_num = num
	_chapter_t = 3.6


func show_cutin(hero_id: String) -> void:
	_cutin_hero = hero_id
	_cutin_t = 0.9


func _process(delta: float) -> void:
	_banner_t -= delta
	_chapter_t -= delta
	_cutin_t -= delta


func draw_hud(ci: Control) -> void:
	if player == null or not is_instance_valid(player):
		return
	var w := ci.size.x
	var h := ci.size.y

	# --- Máu / Giáp / Năng lượng
	_panel(ci, Rect2(4, 4, 150, 52))
	_bar(ci, Vector2(10, 9), player.hp, player.max_hp, Color("d83a3a"), _icons.heart)
	_bar(ci, Vector2(10, 24), player.armor, player.max_armor, Color("9aa4bc"), _icons.shield)
	_bar(ci, Vector2(10, 39), player.energy, player.max_energy, Color("3a8ae8"), _icons.energy)

	# --- Phúc lành đang có
	var bx0 := 6.0
	var by0 := 60.0
	for id in Global.run_buffs:
		var icon := Art.tex("ui/buff_%s.png" % id)
		ci.draw_texture(icon, Vector2(bx0, by0))
		var n: int = Global.run_buffs[id]
		if n > 1:
			Art.draw_text(ci, Vector2(bx0 + 12, by0 + 17), str(n), 12, Color(1, 0.95, 0.7))
		bx0 += 18.0
		if bx0 > 140.0:
			bx0 = 6.0
			by0 += 18.0

	# --- Màn + xu + bản đồ nhỏ
	_panel(ci, Rect2(w - 100, 4, 96, 104))
	var stage := (Global.level - 1) % 3 + 1
	var chn := EnemyData.chapter_index(Global.level) + 1
	Art.draw_text(ci, Vector2(w - 92, 19), "Màn %d-%d" % [chn, stage], 16, Color(1, 0.92, 0.75), false)
	ci.draw_texture_rect_region(_icons.coin, Rect2(w - 92, 25, 9, 9), Rect2(0, 0, 9, 9))
	Art.draw_text(ci, Vector2(w - 79, 34), str(Global.run_coins), 16, Color(1, 0.88, 0.45), false)
	_draw_minimap(ci, Vector2(w - 96, 40), Vector2(88, 64))

	# --- Thanh máu trùm
	var boss = get_tree().get_first_node_in_group("boss")
	if boss != null and not boss.is_spawning():
		var bw := 240.0
		var bx := (w - bw) / 2.0
		Art.draw_text(ci, Vector2(w / 2.0, 16), "%s - %s" % [boss.display_name(), boss.title()], 16, Color(1, 0.65, 0.5))
		ci.draw_rect(Rect2(bx - 2, 20, bw + 4, 10), Color(0.05, 0.02, 0.04))
		ci.draw_rect(Rect2(bx, 22, bw, 6), Color(0.25, 0.08, 0.1))
		ci.draw_rect(Rect2(bx, 22, bw * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), 6), Color("e03a3a"))
		ci.draw_rect(Rect2(bx, 22, bw * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), 2), Color("ff8a7a"))

	# --- Vũ khí + kỹ năng (máy tính). Trên điện thoại thì nằm trên nút ảo.
	if not Global.touch_mode:
		_panel(ci, Rect2(w - 214, h - 62, 210, 58))
		for i in 2:
			var id: String = player.weapons[i]
			var y := h - 56 + i * 18
			var sel: bool = i == player.slot
			if sel:
				ci.draw_rect(Rect2(w - 210, y - 1, 202, 17), Color(1, 0.85, 0.4, 0.15))
			if id == "":
				Art.draw_text(ci, Vector2(w - 170, y + 12), "(trống)", 14, Color(0.6, 0.6, 0.6), false)
				continue
			var wd := WeaponData.get_data(id)
			var tex := Art.tex("weapons/%s.png" % id)
			var sc := minf(36.0 / tex.get_width(), 16.0 / tex.get_height())
			ci.draw_texture_rect(tex, Rect2(w - 208, y + 8 - tex.get_height() * sc / 2.0, tex.get_width() * sc, tex.get_height() * sc), false)
			var txt: String = wd.name + ("" if int(wd.get("energy", 0)) == 0 else "  %d" % int(wd.energy))
			Art.draw_text(ci, Vector2(w - 168, y + 12), txt, 15, WeaponData.tier_color(id) if sel else WeaponData.tier_color(id).darkened(0.35), false)
		var ready: bool = player.skill_timer <= 0.0
		var sk := "Sẵn sàng" if ready else "%.1fs" % player.skill_timer
		Art.draw_text(ci, Vector2(w - 208, h - 9), "[Space] %s: %s" % [player.hero.skill_name, sk], 14, Color(0.6, 0.88, 1.0) if ready else Color(0.6, 0.6, 0.65), false)

	# --- Gợi ý nhặt vũ khí
	if player.nearby_pickup != null and is_instance_valid(player.nearby_pickup):
		var pid: String = player.nearby_pickup.weapon_id
		var key := "Bấm ĐỔI" if Global.touch_mode else "Nhấn E"
		Art.draw_text(ci, Vector2(w / 2.0, h - 76), "%s để nhặt: %s" % [key, WeaponData.get_data(pid).name], 18, WeaponData.tier_color(pid))

	# --- Băng chân dung khi tung chiêu
	if _cutin_t > 0.0 and _cutin_hero != "":
		_draw_cutin(ci, w, h)

	# --- Giới thiệu chương
	if _chapter_t > 0.0:
		var a := clampf(_chapter_t / 0.6, 0.0, 1.0) * clampf((3.6 - _chapter_t) / 0.4, 0.0, 1.0)
		ci.draw_rect(Rect2(0, h * 0.24, w, 64), Color(0.05, 0.02, 0.04, 0.7 * a))
		ci.draw_rect(Rect2(0, h * 0.24, w, 2), Color(0.9, 0.7, 0.3, a))
		ci.draw_rect(Rect2(0, h * 0.24 + 62, w, 2), Color(0.9, 0.7, 0.3, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 18), "CHƯƠNG %d  -  %s" % [_chapter_num, _chapter.year], 16, Color(1, 0.8, 0.5, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 38), _chapter.name.to_upper(), 28, Color(1, 0.88, 0.4, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 56), _chapter.intro, 14, Color(0.95, 0.9, 0.85, a))
	elif _banner_t > 0.0:
		var a2 := clampf(_banner_t / 0.5, 0.0, 1.0)
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.3), _banner, 26, Color(1, 0.85, 0.4, a2))


func _panel(ci: Control, r: Rect2) -> void:
	ci.draw_rect(r, Color(0.08, 0.04, 0.07, 0.78))
	ci.draw_rect(r, Color(0.66, 0.42, 0.16, 0.9), false, 1.0)
	ci.draw_rect(r.grow(-2), Color(0.3, 0.18, 0.12, 0.6), false, 1.0)


func _bar(ci: Control, pos: Vector2, v: int, m: int, col: Color, icon: Texture2D) -> void:
	ci.draw_texture(icon, pos + Vector2(0, 1))
	var r := Rect2(pos + Vector2(14, 0), Vector2(126, 11))
	ci.draw_rect(r.grow(1), Color(0.04, 0.02, 0.04))
	ci.draw_rect(r, col.darkened(0.7))
	var k := clampf(float(v) / maxf(m, 1), 0.0, 1.0)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), col)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * k, 3)), col.lightened(0.35))
	Art.draw_text(ci, r.position + Vector2(r.size.x / 2.0, 10), "%d/%d" % [v, m], 14, Color.WHITE)


func _draw_cutin(ci: Control, w: float, h: float) -> void:
	var hero: Dictionary = HeroData.DATA[_cutin_hero]
	var t := 0.9 - _cutin_t
	var slide := clampf(t / 0.15, 0.0, 1.0)
	var a := clampf(_cutin_t / 0.15, 0.0, 1.0)
	var y := h - 112.0
	var bw := 300.0
	var x := lerpf(-bw, 0.0, slide)
	var col: Color = hero.color
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + bw, y - 6), Vector2(x + bw - 20, y + 34), Vector2(x, y + 38)]), Color(col.darkened(0.55), 0.88 * a))
	ci.draw_line(Vector2(x, y), Vector2(x + bw, y - 6), Color(1, 0.85, 0.4, a), 2.0)
	ci.draw_line(Vector2(x, y + 38), Vector2(x + bw - 20, y + 34), Color(1, 0.85, 0.4, a), 2.0)
	var tex := Art.tex("heroes/%s.png" % _cutin_hero)
	ci.draw_texture_rect_region(tex, Rect2(x + 8, y - 14, 48, 48), Rect2(0, 0, 32, 32), Color(1, 1, 1, a))
	var icon := Art.tex("ui/skill_%s.png" % hero.skill)
	ci.draw_texture_rect(icon, Rect2(x + 60, y + 8, 22, 22), false, Color(1, 1, 1, a))
	Art.draw_text(ci, Vector2(x + 88, y + 20), hero.skill_name.to_upper(), 24, Color(1, 0.9, 0.5, a), false)
	Art.draw_text(ci, Vector2(x + 90, y + 33), hero.name, 13, Color(1, 1, 1, a), false)


func _draw_minimap(ci: Control, origin: Vector2, area: Vector2) -> void:
	var d = get_tree().get_first_node_in_group("dungeon")
	if d == null or d.rooms.is_empty():
		return
	ci.draw_rect(Rect2(origin, area), Color(0, 0, 0, 0.4))
	var shown := {}
	for c in d.rooms:
		if d.rooms[c].visited:
			shown[c] = true
			for n in d.neighbors_of(c):
				shown[n] = true
	if shown.is_empty():
		return
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for c in shown:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var span := Vector2(hi - lo) + Vector2.ONE
	var cs := minf(minf((area.x - 6) / span.x, (area.y - 6) / span.y), 14.0)
	var off := origin + (area - span * cs) / 2.0
	for l in d.links:
		if shown.has(l[0]) and shown.has(l[1]) and (d.rooms[l[0]].visited or d.rooms[l[1]].visited):
			var p1 := off + (Vector2(l[0] - lo) + Vector2(0.5, 0.5)) * cs
			var p2 := off + (Vector2(l[1] - lo) + Vector2(0.5, 0.5)) * cs
			ci.draw_line(p1, p2, Color(0.6, 0.55, 0.5), 1.0)
	for c in shown:
		var r = d.rooms[c]
		var col := Color(0.32, 0.3, 0.3)
		if r.visited:
			col = Color(0.62, 0.58, 0.55)
		if r.kind == "boss":
			col = Color(0.85, 0.25, 0.25)
		elif r.kind == "exit":
			col = Color(0.35, 0.7, 1.0)
		elif r.kind == "treasure":
			col = Color(0.95, 0.8, 0.3)
		elif r.kind == "legend":
			col = Color(0.75, 0.4, 1.0)
		elif r.kind == "shop":
			col = Color(0.45, 0.85, 0.45)
		if r.player_inside:
			col = Color.WHITE
		ci.draw_rect(Rect2(off + Vector2(c - lo) * cs + Vector2(1.5, 1.5), Vector2(cs - 3, cs * 0.75 - 1)), col)
