extends CanvasLayer
## Giao diện trong trận: Máu/Giáp/Năng lượng, xu, màn, bản đồ nhỏ, vũ khí (màu theo cấp),
## kỹ năng, thanh máu trùm, thông báo, giới thiệu chương, băng chân dung khi tung chiêu.

const WeaponData = preload("res://scripts/data/weapons.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")

var player = null
var _banner := ""
var _banner_t := 0.0
var _banner_queue: Array[String] = []
var _chapter: Dictionary = {}
var _chapter_num := 0
var _chapter_t := 0.0
var _cutin_hero := ""
var _cutin_t := 0.0
var _boss_intro_t := 0.0
var _boss_intro_name := ""
var _boss_intro_title := ""
var _boss_intro_mythic := false
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
	if _banner_t > 0.0:
		if _banner_queue.size() < 3:
			_banner_queue.append(text)
	else:
		_banner = text
		_banner_t = 2.0


func show_chapter(num: int, ch: Dictionary) -> void:
	_chapter = ch
	_chapter_num = num
	_chapter_t = 3.6


func show_cutin(hero_id: String) -> void:
	_cutin_hero = hero_id
	_cutin_t = 0.9


func show_boss_intro(bname: String, btitle: String, mythic: bool = false) -> void:
	_boss_intro_name = bname
	_boss_intro_title = btitle
	_boss_intro_mythic = mythic
	_boss_intro_t = 3.2


func clear_boss_intro() -> void:
	_boss_intro_t = 0.0
	_chapter_t = 0.0
	_banner_t = 0.0
	_banner_queue.clear()


func _process(delta: float) -> void:
	_banner_t -= delta
	if _banner_t <= 0.0 and not _banner_queue.is_empty():
		_banner = _banner_queue.pop_front()
		_banner_t = 2.0
	_chapter_t -= delta
	_cutin_t -= delta
	_boss_intro_t -= delta


func draw_hud(ci: Control) -> void:
	if player == null or not is_instance_valid(player):
		return
	var w := ci.size.x
	var h := ci.size.y

	# --- Máu / Giáp / Năng lượng + tên tướng & cấp
	_panel(ci, Rect2(4, 4, 162, 66))
	Art.draw_text(ci, Vector2(10, 16), "%s  Cấp %d" % [player.hero.name, Global.eff_hero_level(player.hero_id)], 13, Color(1, 0.88, 0.45), false)
	_bar(ci, Vector2(10, 21), player.hp, player.max_hp, Color("d83a3a"), _icons.heart)
	_bar(ci, Vector2(10, 36), player.armor, player.max_armor, Color("9aa4bc"), _icons.shield)
	_bar(ci, Vector2(10, 51), player.energy, player.max_energy, Color("3a8ae8"), _icons.energy)

	# --- Phúc lành đang có
	var bx0 := 6.0
	var by0 := 74.0
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
	var left_y: float = by0 + (20.0 if not Global.run_buffs.is_empty() else 0.0)
	if player.rapid_reload_timer > 0.0:
		_panel(ci, Rect2(4, left_y, 118, 16))
		Art.draw_text(ci, Vector2(10, left_y + 12), "Nạp nhanh %.1fs" % player.rapid_reload_timer, 12, SynergyData.family_color("sung"), false)
		left_y += 20.0
	if player.has_method("buff") and player.buff("tich_luc") > 0:
		var kpct: float = clampf(float(player.get("_kinetic_charge")) / 100.0, 0.0, 1.0)
		_panel(ci, Rect2(4, left_y, 118, 16))
		ci.draw_rect(Rect2(8, left_y + 11, 110.0 * kpct, 3.0), Color(1.0, 0.88, 0.3) if kpct >= 1.0 else Color(0.85, 0.65, 0.25))
		Art.draw_text(ci, Vector2(10, left_y + 10), "Xung kích: %d%%" % int(round(kpct * 100.0)), 11, Color(1.0, 0.92, 0.45), false)
		left_y += 18.0
	if float(player.get("_frenzy_timer")) > 0.0:
		_panel(ci, Rect2(4, left_y, 118, 16))
		Art.draw_text(ci, Vector2(10, left_y + 12), "Cuồng chiến %.1fs" % float(player.get("_frenzy_timer")), 12, Color(1.0, 0.42, 0.45), false)
		left_y += 18.0

	# --- Trạng thái đồng đội trong phòng LAN
	if Net != null and Net.is_online():
		_draw_teammates(ci, left_y)

	# --- Màn + xu + bản đồ nhỏ
	_panel(ci, Rect2(w - 100, 4, 96, 104))
	var stage := EnemyData.stage_in_chapter(Global.level)
	var chn := EnemyData.stage_chapter_num(Global.level)
	var is_m_hud: bool = EnemyData.is_mythic_level(Global.level) or Global.level >= 32
	var stage_lbl: String = ("Thần %d-%d" if is_m_hud else "Màn %d-%d") % [chn, stage]
	Art.draw_text(ci, Vector2(w - 92, 19), stage_lbl, 15 if is_m_hud else 16, Color(0.92, 0.76, 1.0) if is_m_hud else Color(1, 0.92, 0.75), false)
	ci.draw_texture_rect_region(_icons.coin, Rect2(w - 92, 25, 9, 9), Rect2(0, 0, 9, 9))
	Art.draw_text(ci, Vector2(w - 79, 34), str(Global.run_coins), 16, Color(1, 0.88, 0.45), false)
	_draw_minimap(ci, Vector2(w - 96, 40), Vector2(88, 64))
	var right_y: float = 110.0
	if not Global.run_materials.is_empty():
		var items: Array = []
		for mid in MaterialData.ORDER:
			var cnt: int = int(Global.run_materials.get(mid, 0))
			if cnt > 0:
				items.append([mid, cnt])
		if not items.is_empty():
			var rows: int = (items.size() + 1) / 2
			var mat_h: float = float(rows * 14 + 6)
			_panel(ci, Rect2(w - 100, right_y, 96, mat_h))
			for idx in items.size():
				var pair: Array = items[idx]
				var mid: String = str(pair[0])
				var cnt: int = int(pair[1])
				var md: Dictionary = MaterialData.DATA[mid]
				var col_idx: int = idx % 2
				var row_idx: int = idx / 2
				var mx: float = w - 95.0 + col_idx * 46.0
				var my: float = right_y + 4.0 + row_idx * 14.0
				ci.draw_texture_rect(Art.tex(md.icon), Rect2(mx, my, 10, 10), false)
				Art.draw_text(ci, Vector2(mx + 12, my + 9), str(cnt), 13, md.color, false)
			right_y += mat_h + 2.0
	if Net != null and Net.is_online():
		_panel(ci, Rect2(w - 100, right_y, 96, 16))
		var ping_col: Color = Color(0.55, 1.0, 0.55) if Net.ping_ms < 80 else (Color(1.0, 0.88, 0.35) if Net.ping_ms < 180 else Color(1.0, 0.45, 0.4))
		Art.draw_text(ci, Vector2(w - 52, right_y + 12), "LAN: %d ms" % Net.ping_ms, 12, ping_col, true)

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
		var panel_w: float = 230.0
		for i in 2:
			var id_chk: String = str(player.weapons[i])
			if id_chk == "":
				continue
			var mod_chk: String = Global.get_weapon_mod(id_chk)
			if mod_chk != "":
				var wd_chk: Dictionary = player.effective_weapon(id_chk) if player.has_method("effective_weapon") else WeaponData.get_data(id_chk)
				var is_st: bool = (id_chk == str(player.hero.get("weapon", "")))
				var wr_chk: int = Global.eff_weapon_rank(player.hero_id) if is_st else 1
				var wn_chk: String = str(wd_chk.name) + (" (Bậc %d)" % wr_chk if is_st else "")
				var tx_chk: String = wn_chk + ("" if int(wd_chk.get("energy", 0)) == 0 else "  %d" % int(wd_chk.energy))
				var badge_chk: String = "[%s]" % WeaponMods.mod_name(mod_chk)
				var need_w: float = 54.0 + Art.text_width(tx_chk, 14) + Art.text_width(badge_chk, 12) + 12.0
				panel_w = maxf(panel_w, minf(need_w, 296.0))
		var px: float = w - panel_w - 4.0
		_panel(ci, Rect2(px, h - 76, panel_w, 72))
		for i in 2:
			var id: String = str(player.weapons[i])
			var y: float = h - 70.0 + i * 18.0
			var sel: bool = i == player.slot
			if sel:
				ci.draw_rect(Rect2(px + 4.0, y - 1.0, panel_w - 8.0, 17.0), Color(1, 0.85, 0.4, 0.15))
			if id == "":
				Art.draw_text(ci, Vector2(px + 44.0, y + 12.0), "(trống)", 14, Color(0.6, 0.6, 0.6), false)
				continue
			var wd: Dictionary = player.effective_weapon(id) if player.has_method("effective_weapon") else WeaponData.get_data(id)
			var is_starter: bool = (id == str(player.hero.get("weapon", "")))
			var wr: int = Global.eff_weapon_rank(player.hero_id) if is_starter else 1
			var tex: Texture2D = Art.tex(ProgressionData.weapon_texture_path(id, wr))
			var sc: float = minf(36.0 / tex.get_width(), 16.0 / tex.get_height())
			ci.draw_texture_rect(tex, Rect2(px + 6.0, y + 8.0 - tex.get_height() * sc / 2.0, tex.get_width() * sc, tex.get_height() * sc), false)
			var wname: String = str(wd.name) + (" (Bậc %d)" % wr if is_starter else "")
			var txt: String = wname + ("" if int(wd.get("energy", 0)) == 0 else "  %d" % int(wd.energy))
			var tx_x: float = px + 46.0
			Art.draw_text(ci, Vector2(tx_x, y + 12.0), txt, 14, WeaponData.tier_color(id) if sel else WeaponData.tier_color(id).darkened(0.35), false)
			var mod_id: String = Global.get_weapon_mod(id)
			if mod_id != "":
				var badge: String = "[%s]" % WeaponMods.mod_name(mod_id)
				var bw_badge: float = Art.text_width(badge, 12)
				var bx_badge: float = minf(tx_x + Art.text_width(txt, 14) + 5.0, w - bw_badge - 10.0)
				var mcol: Color = WeaponMods.mod_color(mod_id) if sel else WeaponMods.mod_color(mod_id).darkened(0.3)
				ci.draw_rect(Rect2(bx_badge - 2.0, y + 1.0, bw_badge + 4.0, 13.0), Color(0.06, 0.03, 0.08, 0.72))
				Art.draw_text(ci, Vector2(bx_badge, y + 11.0), badge, 12, mcol, false)
		var ready: bool = player.skill_timer <= 0.0
		var sk: String = "Sẵn sàng" if ready else "%.1fs" % player.skill_timer
		Art.draw_text(ci, Vector2(px + 6.0, h - 22.0), "[Space] %s: %s" % [player.hero.skill_name, sk], 14, Color(0.6, 0.88, 1.0) if ready else Color(0.6, 0.6, 0.65), false)
		var cur_wid: String = str(player.weapons[player.slot])
		var syn_lv: int = SynergyData.level(player.hero_id, cur_wid)
		var syn_fam: String = SynergyData.family(cur_wid)
		var syn_txt: String = "★★ Tâm đắc" if syn_lv == 2 else ("★ Cùng hệ" if syn_lv == 1 else "Chưa đồng điệu")
		var syn_col: Color = Color(1.0, 0.88, 0.35) if syn_lv == 2 else (Color(0.84, 0.88, 0.96) if syn_lv == 1 else Color(0.62, 0.62, 0.66))
		Art.draw_text(ci, Vector2(px + 6.0, h - 7.0), syn_txt, 12, syn_col, false)
		Art.draw_text(ci, Vector2(px + 116.0, h - 7.0), "Ấn: %s" % SynergyData.imprint_name(cur_wid), 12, SynergyData.family_color(syn_fam), false)

	# --- Mũi tên chỉ đường tới phòng quan trọng khi không giao tranh
	_draw_wayfinders(ci, w, h)

	# --- Gợi ý nhặt vũ khí hoặc Thẻ soi hàng Thương Nhân ---
	if player.interact_target != null and is_instance_valid(player.interact_target) and player.interact_target.has_method("inspect_info"):
		_draw_shop_inspect(ci, w, h, player.interact_target)
	elif player.nearby_pickup != null and is_instance_valid(player.nearby_pickup):
		var pid: String = player.nearby_pickup.weapon_id
		var key := "Bấm ĐỔI" if Global.touch_mode else "Nhấn E"
		Art.draw_text(ci, Vector2(w / 2.0, h - 76), "%s để nhặt: %s" % [key, WeaponData.get_data(pid).name], 18, WeaponData.tier_color(pid))

	# --- Băng chân dung khi tung chiêu
	if _cutin_t > 0.0 and _cutin_hero != "":
		_draw_cutin(ci, w, h)

	# --- Giới thiệu chương / Trùm xuất hiện
	if _boss_intro_t > 0.0:
		var ba := clampf(_boss_intro_t / 0.5, 0.0, 1.0) * clampf((3.2 - _boss_intro_t) / 0.3, 0.0, 1.0)
		var b_bg := Color(0.14, 0.04, 0.18, 0.84 * ba) if _boss_intro_mythic else Color(0.18, 0.03, 0.04, 0.84 * ba)
		var b_edge := Color(0.84, 0.48, 1.0, ba) if _boss_intro_mythic else Color(1.0, 0.48, 0.25, ba)
		ci.draw_rect(Rect2(0, h * 0.17, w, 62), b_bg)
		ci.draw_rect(Rect2(0, h * 0.17, w, 2), b_edge)
		ci.draw_rect(Rect2(0, h * 0.17 + 60, w, 2), b_edge)
		var tag: String = "★ YÊU VƯƠNG THẦN THOẠI XUẤT HIỆN ★" if _boss_intro_mythic else "★ CẢNH BÁO TRÙM XUẤT HIỆN ★"
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.17 + 16), tag, 13, Color(1.0, 0.86, 0.45, ba))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.17 + 37), _boss_intro_name.to_upper(), 26, Color(0.96, 0.84, 1.0, ba) if _boss_intro_mythic else Color(1.0, 0.78, 0.45, ba))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.17 + 53), _boss_intro_title, 13, Color(0.95, 0.9, 0.86, ba))
	elif _chapter_t > 0.0:
		var a := clampf(_chapter_t / 0.6, 0.0, 1.0) * clampf((3.6 - _chapter_t) / 0.4, 0.0, 1.0)
		ci.draw_rect(Rect2(0, h * 0.24, w, 64), Color(0.05, 0.02, 0.04, 0.7 * a))
		ci.draw_rect(Rect2(0, h * 0.24, w, 2), Color(0.9, 0.7, 0.3, a))
		ci.draw_rect(Rect2(0, h * 0.24 + 62, w, 2), Color(0.9, 0.7, 0.3, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 18), "CHƯƠNG %d  -  %s" % [_chapter_num, _chapter.year], 16, Color(1, 0.8, 0.5, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 38), _chapter.name.to_upper(), 28, Color(1, 0.88, 0.4, a))
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.24 + 56), _chapter.intro, 14, Color(0.95, 0.9, 0.85, a))
	elif _banner_t > 0.0:
		var a2 := clampf(_banner_t / 0.5, 0.0, 1.0)
		var b_sz: int = 18 if _banner.length() > 34 else 26
		Art.draw_text(ci, Vector2(w / 2.0, h * 0.3), _banner, b_sz, Color(1, 0.85, 0.4, a2))


func _draw_shop_inspect(ci: Control, _w: float, h: float, target: Node) -> void:
	var info: Dictionary = target.inspect_info(player)
	if bool(info.get("sold", false)):
		return
	var cw: float = 282.0
	var ch: float = 76.0
	var cx: float = 8.0
	var cy: float = h - ch - (92.0 if Global.touch_mode else 6.0)
	var bcol: Color = info.get("badge_color", Color(0.9, 0.75, 0.35)) as Color
	ci.draw_rect(Rect2(cx, cy, cw, ch), Color(0.09, 0.04, 0.07, 0.90))
	ci.draw_rect(Rect2(cx, cy, cw, ch), bcol, false, 1.5)
	ci.draw_rect(Rect2(cx + 2, cy + 2, cw - 4, ch - 4), Color(bcol, 0.32), false, 1.0)

	var ic_box := Rect2(cx + 8, cy + 12, 34, 34)
	ci.draw_rect(ic_box, Color(0.05, 0.02, 0.05, 0.9))
	ci.draw_rect(ic_box, Color(bcol, 0.7), false, 1.0)
	var tex_v: Variant = info.get("icon", null)
	if tex_v is Texture2D:
		var tex: Texture2D = tex_v as Texture2D
		var sc: float = minf(28.0 / maxf(1.0, float(tex.get_width())), 28.0 / maxf(1.0, float(tex.get_height())))
		var sz := Vector2(tex.get_width(), tex.get_height()) * sc
		ci.draw_texture_rect(tex, Rect2(ic_box.get_center() - sz * 0.5, sz), false)

	var tx: float = cx + 48.0
	var tcol: Color = info.get("title_color", Color.WHITE) as Color
	Art.draw_text(ci, Vector2(tx, cy + 16), str(info.get("title", "")), 14, tcol, false)
	Art.draw_text(ci, Vector2(tx, cy + 28), str(info.get("badge", "")), 10, bcol, false)
	var sub_line: String = str(info.get("stats", ""))
	if sub_line == "":
		sub_line = str(info.get("desc", ""))
	if sub_line.length() > 42:
		sub_line = sub_line.substr(0, 41) + "…"
	Art.draw_text(ci, Vector2(tx, cy + 41), sub_line, 11, Color(0.88, 0.9, 0.94), false)
	var syn_s: String = str(info.get("synergy", ""))
	if syn_s != "":
		var sc_col: Color = info.get("synergy_color", Color(1.0, 0.88, 0.4)) as Color
		Art.draw_text(ci, Vector2(tx, cy + 53), syn_s, 10, sc_col, false)
	else:
		var d2: String = str(info.get("desc", ""))
		if d2 != sub_line:
			if d2.length() > 42:
				d2 = d2.substr(0, 41) + "…"
			Art.draw_text(ci, Vector2(tx, cy + 53), d2, 10, Color(0.82, 0.8, 0.76), false)

	var pr: int = int(info.get("price", 0))
	var key_lbl: String = "DÙNG" if Global.touch_mode else "E"
	var pcol: Color = Color(0.55, 1.0, 0.65) if Global.run_coins >= pr else Color(1.0, 0.45, 0.42)
	Art.draw_text(ci, Vector2(tx, cy + 68), "[%s] Mua: %d xu" % [key_lbl, pr], 12, pcol, false)


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


func _draw_teammates(ci: Control, start_y: float) -> void:
	var ty: float = start_y
	for other in Global.all_players():
		if other == player:
			continue
		var card_w: float = 138.0
		var card_h: float = 24.0
		_panel(ci, Rect2(4.0, ty, card_w, card_h))
		var tname: String = str(other.get("display_name"))
		if tname == "":
			var hdict: Variant = other.get("hero")
			tname = str((hdict as Dictionary).get("name", "Đồng đội")) if typeof(hdict) == TYPE_DICTIONARY else "Đồng đội"
		var ncol: Color = other.get("name_color") as Color
		Art.draw_text(ci, Vector2(9.0, ty + 11.0), tname, 12, ncol, false)
		var is_downed: bool = bool(other.get("downed"))
		var is_dead: bool = bool(other.get("dead"))
		if is_downed:
			var pulse: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 150.0)
			ci.draw_rect(Rect2(100.0, ty + 3.0, 38.0, 12.0), Color(0.75, 0.1, 0.12, 0.85 * pulse))
			Art.draw_text(ci, Vector2(119.0, ty + 12.0), "GỤC!", 11, Color(1.0, 0.92, 0.88, pulse), true)
			var rpct: float = clampf(float(other.get("revive_progress")) / 3.0, 0.0, 1.0)
			ci.draw_rect(Rect2(9.0, ty + 16.0, 126.0, 4.0), Color(0.25, 0.07, 0.08))
			if rpct > 0.0:
				ci.draw_rect(Rect2(9.0, ty + 16.0, 126.0 * rpct, 4.0), Color(0.45, 1.0, 0.55))
		elif is_dead:
			Art.draw_text(ci, Vector2(119.0, ty + 15.0), "NGÃ", 11, Color(0.75, 0.45, 0.45), true)
		else:
			var ohp: int = int(other.get("hp"))
			var omax_hp: int = maxi(1, int(other.get("max_hp")))
			var oarm: int = int(other.get("armor"))
			var omax_arm: int = maxi(0, int(other.get("max_armor")))
			var hp_r := Rect2(9.0, ty + 15.0, 74.0, 5.0)
			ci.draw_rect(hp_r.grow(1.0), Color(0.04, 0.02, 0.04))
			ci.draw_rect(hp_r, Color("d83a3a").darkened(0.7))
			var hk: float = clampf(float(ohp) / float(omax_hp), 0.0, 1.0)
			ci.draw_rect(Rect2(hp_r.position, Vector2(hp_r.size.x * hk, hp_r.size.y)), Color("d83a3a"))
			if omax_arm > 0:
				var pip_x: float = 88.0
				var max_pips: int = mini(omax_arm, 8)
				for i in max_pips:
					var filled: bool = i < oarm
					ci.draw_rect(Rect2(pip_x + float(i) * 6.0, ty + 15.0, 4.0, 5.0), Color("9aa4bc") if filled else Color(0.25, 0.27, 0.34, 0.7))
		ty += card_h + 2.0


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


func get_wayfinder_targets() -> Array:
	var out: Array = []
	if player == null or not is_instance_valid(player) or player.dead:
		return out
	var d: Node = get_tree().get_first_node_in_group("dungeon")
	if d == null or d.rooms.is_empty():
		return out
	var ppos: Vector2 = player.global_position
	for c in d.rooms:
		var r = d.rooms[c]
		if str(r.state) == "fighting" and (bool(r.player_inside) or (r.rect as Rect2).has_point(ppos)):
			return out

	var portal: Node = get_tree().get_first_node_in_group("portals")
	var has_portal: bool = portal != null and is_instance_valid(portal)

	# (a) Cổng hoặc phòng exit / boss / legend
	if has_portal:
		var tpos: Vector2 = (portal as Node2D).global_position
		if tpos.distance_to(ppos) > 140.0:
			out.append({"pos": tpos, "label": "Cổng", "color": Color(0.4, 0.92, 1.0)})
	else:
		var best_main: Dictionary = {}
		var best_main_d: float = 1e9
		for c in d.rooms:
			var r = d.rooms[c]
			var rk: String = str(r.kind)
			if rk in ["exit", "boss", "legend"]:
				var rpos: Vector2 = (r.rect as Rect2).get_center()
				var rd: float = rpos.distance_to(ppos)
				if rd > 140.0 and rd < best_main_d:
					best_main_d = rd
					var lbl: String = "Cổng" if rk == "exit" else "Trùm"
					var col: Color = Color(0.4, 0.92, 1.0) if rk == "exit" else Color(1.0, 0.82, 0.32)
					best_main = {"pos": rpos, "label": lbl, "color": col}
		if not best_main.is_empty():
			out.append(best_main)

	# (b) Phòng kho báu hoặc chợ chưa vào
	var best_side: Dictionary = {}
	var best_side_d: float = 1e9
	for c in d.rooms:
		var r = d.rooms[c]
		var rk: String = str(r.kind)
		if not bool(r.visited) and rk in ["treasure", "shop"]:
			var rpos: Vector2 = (r.rect as Rect2).get_center()
			var rd: float = rpos.distance_to(ppos)
			if rd > 140.0 and rd < best_side_d and _is_distinct_target(out, rpos):
				best_side_d = rd
				var lbl: String = "Rương" if rk == "treasure" else "Chợ"
				best_side = {"pos": rpos, "label": lbl, "color": Color(1.0, 0.78, 0.28)}
	if not best_side.is_empty() and out.size() < 2:
		out.append(best_side)

	# (c) Phòng đánh quái chưa vào gần nhất nếu chưa mở cổng
	if not has_portal and out.size() < 2:
		var best_cb: Dictionary = {}
		var best_cb_d: float = 1e9
		for c in d.rooms:
			var r = d.rooms[c]
			if not bool(r.visited) and str(r.kind) == "combat":
				var rpos: Vector2 = (r.rect as Rect2).get_center()
				var rd: float = rpos.distance_to(ppos)
				if rd > 140.0 and rd < best_cb_d and _is_distinct_target(out, rpos):
					best_cb_d = rd
					best_cb = {"pos": rpos, "label": "", "color": Color(0.92, 0.95, 1.0, 0.85)}
		if not best_cb.is_empty():
			out.append(best_cb)

	return out


func _is_distinct_target(existing: Array, pos: Vector2) -> bool:
	for item in existing:
		var d: Dictionary = item
		var p: Vector2 = d["pos"]
		if p.distance_to(pos) < 40.0:
			return false
	return true


func _draw_wayfinders(ci: Control, w: float, h: float) -> void:
	var targets: Array = get_wayfinder_targets()
	if targets.is_empty():
		return
	var ppos: Vector2 = player.global_position
	var center := Vector2(w / 2.0, h / 2.0)
	var margin: float = 34.0
	var rx: float = maxf(w / 2.0 - margin, 24.0)
	var ry: float = maxf(h / 2.0 - margin, 24.0)
	var pulse: float = sin(Time.get_ticks_msec() / 180.0) * 3.0

	for item in targets:
		var t: Dictionary = item
		var tpos: Vector2 = t["pos"]
		var lbl: String = str(t.get("label", ""))
		var col: Color = t.get("color", Color.WHITE) as Color
		var delta: Vector2 = tpos - ppos
		if delta.length_squared() < 1.0:
			continue
		var dir: Vector2 = delta.normalized()
		var tx: float = rx / maxf(absf(dir.x), 0.001)
		var ty: float = ry / maxf(absf(dir.y), 0.001)
		var pos: Vector2 = center + dir * minf(tx, ty)

		# Tránh các khung HUD góc trên-trái, trên-phải, dưới-phải
		if pos.x < 178.0 and pos.y < 84.0:
			if absf(dir.y) > absf(dir.x):
				pos.x = 178.0
			else:
				pos.y = 84.0
		elif pos.x > w - 114.0 and pos.y < 120.0:
			if absf(dir.y) > absf(dir.x):
				pos.x = w - 114.0
			else:
				pos.y = 120.0
		elif not Global.touch_mode and pos.x > w - 246.0 and pos.y > h - 88.0:
			if absf(dir.y) > absf(dir.x):
				pos.x = w - 246.0
			else:
				pos.y = h - 88.0

		var tip_c: Vector2 = pos + dir * pulse
		var perp := Vector2(-dir.y, dir.x)
		var o_tip: Vector2 = tip_c + dir * 9.0
		var o_bl: Vector2 = tip_c - dir * 6.5 + perp * 7.0
		var o_br: Vector2 = tip_c - dir * 6.5 - perp * 7.0
		ci.draw_colored_polygon(PackedVector2Array([o_tip, o_bl, o_br]), Color(0.05, 0.02, 0.06, 0.85 * col.a))
		var tip: Vector2 = tip_c + dir * 7.0
		var back_l: Vector2 = tip_c - dir * 5.0 + perp * 5.2
		var back_r: Vector2 = tip_c - dir * 5.0 - perp * 5.2
		ci.draw_colored_polygon(PackedVector2Array([tip, back_l, back_r]), col)
		if lbl != "":
			var lbl_pos: Vector2 = pos - dir * 13.0 + Vector2(0, 4.0)
			Art.draw_text(ci, lbl_pos, lbl, 12, col, true)
