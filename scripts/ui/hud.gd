extends CanvasLayer
## Giao diện trong trận: Máu/Giáp/Năng lượng, xu, màn, bản đồ nhỏ, vũ khí (màu theo cấp),
## kỹ năng, thanh máu trùm, thông báo, giới thiệu chương, băng chân dung khi tung chiêu.

const WeaponData = preload("res://scripts/data/weapons.gd")
const HeroData = preload("res://scripts/data/heroes.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const HeroSkillsExt = preload("res://scripts/data/hero_skills_ext.gd")
const Art = preload("res://scripts/art/art.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const RelicData = preload("res://scripts/data/relics.gd")
const HaoKhiData = preload("res://scripts/data/hao_khi_data.gd")
const CoLoaData = preload("res://scripts/data/co_loa_data.gd")
const DefenseTower = preload("res://scripts/entities/defense_tower.gd")

const MOUNT_NAMES := {
	"voi_chien_mount": "Voi Chiến",
	"ngua_sat_mount": "Ngựa Sắt",
	"xe_tang_mount": "Xe Tăng Chiến",
}

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
var _boss_intro_desc := ""
var _boss_intro_sheet := ""
var _boss_intro_fsize := Vector2i(48, 48)
var _bgm_toast_id: String = ""
var _bgm_toast_title: String = ""
var _bgm_toast_t: float = 0.0
var _coop_combo_name: String = ""
var _coop_combo_sub: String = ""
var _coop_combo_col: Color = Color(1.0, 0.85, 0.35)
var _coop_combo_t: float = 0.0
var _chronicle_toast_title: String = ""
var _chronicle_toast_t: float = 0.0
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
	if Sfx != null and Sfx.has_signal("music_changed") and not Sfx.music_changed.is_connected(show_music_toast):
		Sfx.music_changed.connect(show_music_toast)
	for k in ["heart", "shield", "energy", "skull"]:
		_icons[k] = Art.tex("ui/icon_%s.png" % k)
	_icons["coin"] = Art.tex("items/coin.png")
	var view := HudView.new()
	view.hud = self
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)


func _exit_tree() -> void:
	if Sfx != null and Sfx.has_signal("music_changed") and Sfx.music_changed.is_connected(show_music_toast):
		Sfx.music_changed.disconnect(show_music_toast)


func show_music_toast(track_id: String, title: String) -> void:
	if track_id == "" or title == "":
		return
	_bgm_toast_id = track_id
	_bgm_toast_title = title
	_bgm_toast_t = 3.0


func show_coop_combo(combo_name: String, subtitle: String, col: Color = Color(1.0, 0.85, 0.35)) -> void:
	if combo_name == "":
		return
	_coop_combo_name = combo_name
	_coop_combo_sub = subtitle
	_coop_combo_col = col
	_coop_combo_t = 2.6


func show_chronicle_toast(title: String) -> void:
	if title == "":
		return
	_chronicle_toast_title = title
	_chronicle_toast_t = 3.2


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


func show_boss_intro(bname: String, btitle: String, mythic: bool = false, intro_desc: String = "", sheet_path: String = "", frame_size: Vector2i = Vector2i(48, 48)) -> void:
	_boss_intro_name = bname
	_boss_intro_title = btitle
	_boss_intro_mythic = mythic
	_boss_intro_desc = intro_desc
	_boss_intro_sheet = sheet_path
	_boss_intro_fsize = frame_size
	_boss_intro_t = 3.4


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
	_bgm_toast_t = maxf(_bgm_toast_t - delta, 0.0)
	_coop_combo_t = maxf(_coop_combo_t - delta, 0.0)
	_chronicle_toast_t = maxf(_chronicle_toast_t - delta, 0.0)


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
		ci.draw_texture_rect(icon, Rect2(bx0, by0, 16, 16), false)
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
	if bool(player.get("sprinting")):
		_panel(ci, Rect2(4, left_y, 118, 16))
		Art.draw_text(ci, Vector2(10, left_y + 12), "Tăng tốc [Shift]", 12, Color(0.45, 0.90, 1.0), false)
		left_y += 18.0

	# --- Lướt né (Dodge Dash cooldown gauge)
	var dash_cd_v: Variant = player.get("dash_cd_left")
	var dash_cd: float = maxf(0.0, float(dash_cd_v)) if dash_cd_v != null else 0.0
	var dash_pct: float = 1.0 - clampf(dash_cd / 1.6, 0.0, 1.0)
	_panel(ci, Rect2(4, left_y, 118, 16))
	ci.draw_rect(Rect2(7, left_y + 11, 112.0 * dash_pct, 3.0), Color(0.42, 0.92, 1.0) if dash_cd <= 0.0 else Color(0.62, 0.68, 0.78))
	var dash_lbl: String = "Lướt [Space]: Sẵn" if dash_cd <= 0.0 else "Lướt [Space]: %.1fs" % dash_cd
	Art.draw_text(ci, Vector2(10, left_y + 10), dash_lbl, 11, Color(0.65, 0.96, 1.0) if dash_cd <= 0.0 else Color(0.75, 0.78, 0.82), false)
	left_y += 18.0

	# --- Thú cưỡi (Mount badge & HP)
	var mount_v: Variant = player.get("mount_id")
	var m_id: String = str(mount_v) if mount_v != null else Global.active_mount
	if m_id != "":
		var m_hp_v: Variant = player.get("mount_hp")
		var m_max_v: Variant = player.get("mount_max_hp")
		var m_hp: int = int(m_hp_v) if m_hp_v != null else Global.active_mount_hp
		var m_max: int = maxi(1, int(m_max_v) if m_max_v != null else maxi(1, m_hp))
		var m_pct: float = clampf(float(m_hp) / float(m_max), 0.0, 1.0)
		_panel(ci, Rect2(4, left_y, 132, 20))
		ci.draw_rect(Rect2(8, left_y + 14, 124.0 * m_pct, 3.0), Color(1.0, 0.76, 0.32))
		Art.draw_text(ci, Vector2(10, left_y + 12), "%s (%d/%d)" % [str(MOUNT_NAMES.get(m_id, m_id)), m_hp, m_max], 11, Color(1.0, 0.88, 0.45), false)
		left_y += 22.0

	# --- Tượng Thần Việt & Quân Sư
	if Global.statue_id != "" or Global.mentor_upgraded:
		var st_parts: PackedStringArray = []
		var st_col := Color(0.98, 0.84, 0.42)
		if Global.statue_id != "":
			var sdata: Dictionary = HeroSkillsExt.STATUES.get(Global.statue_id, {})
			st_parts.append(str(sdata.get("name", Global.statue_id)))
			if sdata.get("color") is Color:
				st_col = sdata.get("color") as Color
		if Global.mentor_upgraded:
			st_parts.append("Quân Sư ★")
		var st_txt: String = " | ".join(st_parts)
		var st_w: float = clampf(Art.text_width(st_txt, 11) + 14.0, 118.0, 185.0)
		_panel(ci, Rect2(4, left_y, st_w, 16))
		Art.draw_text(ci, Vector2(10, left_y + 12), st_txt, 11, st_col, false)
		left_y += 18.0

	# --- Cổ Vật Sử Việt (Relics)
	var relics_raw: Variant = Global.get("run_relics")
	if relics_raw is Array and not (relics_raw as Array).is_empty():
		var r_arr: Array = relics_raw as Array
		var badge_sz: float = 13.0
		var cols_per_row: int = 8
		var rows_r: int = (r_arr.size() + cols_per_row - 1) / cols_per_row
		var r_box_w: float = clampf(float(mini(r_arr.size(), cols_per_row)) * 16.0 + 10.0, 72.0, 142.0)
		var r_box_h: float = 15.0 + float(rows_r) * 15.0
		_panel(ci, Rect2(4.0, left_y, r_box_w, r_box_h))
		Art.draw_text(ci, Vector2(9.0, left_y + 10.0), "Cổ Vật (%d)" % r_arr.size(), 10, Color(1.0, 0.86, 0.42), false)
		for ri in r_arr.size():
			var rid: String = str(r_arr[ri])
			var rinfo: Dictionary = RelicData.get_relic(rid)
			var rcol: Color = rinfo.get("color", Color(0.95, 0.80, 0.35)) as Color
			var rname_ch: String = str(rinfo.get("name", rid)).substr(0, 1).to_upper()
			var rx: float = 10.0 + float(ri % cols_per_row) * 16.0
			var ry: float = left_y + 14.0 + float(ri / cols_per_row) * 15.0
			var rrect := Rect2(rx, ry, badge_sz, badge_sz)
			ci.draw_rect(rrect, Color(rcol.r, rcol.g, rcol.b, 0.24))
			ci.draw_rect(rrect, rcol, false, 1.2)
			Art.draw_text(ci, rrect.get_center() + Vector2(0.0, 4.0), rname_ch, 10, rcol.lightened(0.25), true)
		left_y += r_box_h + 2.0

	# --- Trạng thái đồng đội trong phòng LAN
	if Net != null and Net.is_online():
		_draw_teammates(ci, left_y)

	# --- Màn + xu + bản đồ nhỏ
	_panel(ci, Rect2(w - 100, 4, 96, 104))
	var stage := EnemyData.stage_in_chapter(Global.level)
	var chn := EnemyData.stage_chapter_num(Global.level)
	var is_m_hud: bool = EnemyData.is_mythic_level(Global.level) or Global.level >= 32
	var stage_lbl: String = ("Thần %d-%d" if is_m_hud else "Màn %d-%d") % [chn, stage]
	var stage_col: Color = Color(0.92, 0.76, 1.0) if is_m_hud else Color(1, 0.92, 0.75)
	var stage_sz: int = 15 if is_m_hud else 16
	var is_coloa: bool = Global.has_method("is_co_loa") and Global.is_co_loa()
	if is_coloa:
		var coloa_n: Node = get_tree().get_first_node_in_group("co_loa_defense")
		var cw: int = int(coloa_n.get("wave")) if coloa_n != null else 0
		stage_lbl = "Cổ Loa #%d" % maxi(1, cw)
		stage_col = Color(1.0, 0.88, 0.36)
		stage_sz = 14
	elif Global.is_boss_rush():
		stage_lbl = "Khải Hoàn" if Global.level >= 13 else "Boss %d/12" % Global.level
		stage_col = Color(1.0, 0.88, 0.35) if Global.level >= 13 else Color(1.0, 0.44, 0.42)
		stage_sz = 14
	Art.draw_text(ci, Vector2(w - 92, 19), stage_lbl, stage_sz, stage_col, false)
	ci.draw_texture_rect_region(_icons.coin, Rect2(w - 92, 25, 9, 9), Rect2(0, 0, 9, 9))
	Art.draw_text(ci, Vector2(w - 79, 34), str(Global.run_coins), 16, Color(1, 0.88, 0.45), false)
	_draw_minimap(ci, Vector2(w - 96, 40), Vector2(88, 64))
	var right_y: float = 110.0
	var hk_lv: int = Global.eff_hao_khi_level() if Global.has_method("eff_hao_khi_level") else (int(Global.get("hao_khi_level")) if Global.get("hao_khi_level") != null else 0)
	if hk_lv > 0:
		_panel(ci, Rect2(w - 100, right_y, 96, 16))
		Art.draw_text(ci, Vector2(w - 52, right_y + 12), "Hào Khí Bậc %d" % hk_lv, 11, Color(1.0, 0.68, 0.28), true)
		right_y += 18.0
	if Global.badass_mode or not Global.active_mutators.is_empty():
		var mode_tags: PackedStringArray = []
		if Global.badass_mode:
			mode_tags.append("ÁC MỘNG")
		if not Global.active_mutators.is_empty():
			mode_tags.append("Biến×%d" % Global.active_mutators.size())
		_panel(ci, Rect2(w - 100, right_y, 96, 16))
		Art.draw_text(ci, Vector2(w - 52, right_y + 12), " ".join(mode_tags), 11, Color("ff384c") if Global.badass_mode else Color(0.65, 0.9, 1.0), true)
		right_y += 18.0
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
	var has_boss: bool = boss != null and not boss.is_spawning()
	if has_boss:
		var bw := 240.0
		var bx := (w - bw) / 2.0
		var p3_v: Variant = boss.get("phase3_enraged")
		var p3_enraged: bool = (p3_v is bool and bool(p3_v))
		var pulse_p3: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 85.0)
		var b_title_col: Color = Color(1.0, 0.88, 0.34).lerp(Color(0.88, 0.48, 1.0), pulse_p3) if p3_enraged else Color(1, 0.65, 0.5)
		var b_hdr: String = "%s - %s%s" % [boss.display_name(), boss.title(), " [CUỒNG NỘ]" if p3_enraged else ""]
		Art.draw_text(ci, Vector2(w / 2.0, 16), b_hdr, 16, b_title_col)
		if p3_enraged:
			ci.draw_rect(Rect2(bx - 3, 19, bw + 6, 12), Color(0.88, 0.44, 1.0).lerp(Color(1.0, 0.84, 0.28), pulse_p3), false, 1.4)
		ci.draw_rect(Rect2(bx - 2, 20, bw + 4, 10), Color(0.05, 0.02, 0.04))
		ci.draw_rect(Rect2(bx, 22, bw, 6), Color(0.20, 0.08, 0.26) if p3_enraged else Color(0.25, 0.08, 0.1))
		var b_fill: Color = Color(0.78, 0.34, 1.0).lerp(Color(1.0, 0.82, 0.26), pulse_p3) if p3_enraged else Color("e03a3a")
		var b_hi: Color = Color(1.0, 0.94, 0.65) if p3_enraged else Color("ff8a7a")
		ci.draw_rect(Rect2(bx, 22, bw * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), 6), b_fill)
		ci.draw_rect(Rect2(bx, 22, bw * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), 2), b_hi)

	# --- Thủ Thành Cổ Loa: Đợt & Máu Lõi Cổ Loa
	if is_coloa:
		var coloa: Node = get_tree().get_first_node_in_group("co_loa_defense")
		var core: Node = get_tree().get_first_node_in_group("co_loa_core")
		if coloa != null or core != null:
			var cl_w: int = int(coloa.get("wave")) if coloa != null else 0
			var cl_state: String = str(coloa.get("state")) if coloa != null else ""
			var cl_prep: float = float(coloa.get("prep_time")) if coloa != null else 0.0
			var chp: int = int(core.get("hp")) if core != null else 0
			var cmax: int = maxi(1, int(core.get("max_hp"))) if core != null else 250
			var gauge_w: float = 228.0
			var gx: float = (w - gauge_w) * 0.5
			var gy: float = 38.0 if has_boss else 4.0
			var gh: float = 36.0 if cl_state == "prep" else 25.0
			_panel(ci, Rect2(gx, gy, gauge_w, gh))
			var show_w: int = maxi(1, cl_w + (1 if cl_state == "prep" and cl_w == 0 else 0))
			var hdr_txt: String = "Đợt Cổ Loa %d  |  Nỏ Thần: %d/%d" % [show_w, chp, cmax]
			Art.draw_text(ci, Vector2(w * 0.5, gy + 11.5), hdr_txt, 11, Color(1.0, 0.90, 0.45), true)
			var cratio: float = clampf(float(chp) / float(cmax), 0.0, 1.0)
			var c_col: Color = Color(0.35, 0.92, 0.62) if cratio > 0.5 else (Color(1.0, 0.78, 0.28) if cratio > 0.25 else Color(0.96, 0.32, 0.30))
			ci.draw_rect(Rect2(gx + 10.0, gy + 16.0, gauge_w - 20.0, 5.0), Color(0.18, 0.08, 0.08))
			ci.draw_rect(Rect2(gx + 10.0, gy + 16.0, (gauge_w - 20.0) * cratio, 5.0), c_col)
			if cl_state == "prep":
				Art.draw_text(ci, Vector2(w * 0.5, gy + 30.0), "Chuẩn bị %.0fs — Nhấn [F] gọi đợt sớm" % maxf(0.0, cl_prep), 10, Color(0.55, 0.95, 1.0), true)

	# --- Thanh xây Tháp Cổ Loa góc dưới trái ([1]..[5])
	if is_coloa and not Global.touch_mode:
		_draw_coloa_build_bar(ci, w, h)

	# --- Vũ khí + kỹ năng (máy tính). Trên điện thoại thì nằm trên nút ảo.
	if not Global.touch_mode:
		var slot_cnt: int = mini(player.weapons.size(), 3)
		var panel_w: float = 230.0
		for i in slot_cnt:
			var id_chk: String = str(player.weapons[i])
			if id_chk == "":
				continue
			var wd_chk: Dictionary = player.effective_weapon(id_chk) if player.has_method("effective_weapon") else WeaponData.get_data(id_chk)
			var is_st: bool = (id_chk == str(player.hero.get("weapon", "")))
			var wr_chk: int = Global.eff_weapon_rank(player.hero_id) if is_st else 1
			var wn_chk: String = str(wd_chk.get("name", id_chk)) + (" (Bậc %d)" % wr_chk if is_st else "")
			if Global.is_weapon_evolved(id_chk) and not wn_chk.contains("Tiến Hóa"):
				wn_chk += " ★TH"
			var tx_chk: String = wn_chk + ("" if int(wd_chk.get("energy", 0)) == 0 else "  %d" % int(wd_chk.energy))
			var mod_chk: String = Global.get_weapon_mod(id_chk)
			var badge_w: float = Art.text_width("[%s]" % WeaponMods.mod_name(mod_chk), 12) + 8.0 if mod_chk != "" else 0.0
			var need_w: float = 54.0 + Art.text_width(tx_chk, 14) + badge_w + 12.0
			panel_w = maxf(panel_w, minf(need_w, 304.0))
		var panel_h: float = 72.0 + float(maxi(0, slot_cnt - 2)) * 18.0
		var px: float = w - panel_w - 4.0
		var panel_y: float = h - panel_h - 4.0
		if player.has_method("can_drop_current_weapon") and player.can_drop_current_weapon():
			Art.draw_text(ci, Vector2(px + 6.0, panel_y - 4.0), "[G] Vứt vũ khí", 12, Color(0.95, 0.86, 0.58), false)
		_panel(ci, Rect2(px, panel_y, panel_w, panel_h))
		for i in slot_cnt:
			var id: String = str(player.weapons[i])
			var y: float = h - panel_h + 2.0 + i * 18.0
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
			var wname: String = str(wd.get("name", id)) + (" (Bậc %d)" % wr if is_starter else "")
			if Global.is_weapon_evolved(id) and not wname.contains("Tiến Hóa"):
				wname += " ★TH"
			var txt: String = wname + ("" if int(wd.get("energy", 0)) == 0 else "  %d" % int(wd.energy))
			var tx_x: float = px + 46.0
			var is_boss_motif: bool = bool(wd.get("boss_motif", false))
			var wcol: Color = Color("ff384c") if is_boss_motif else WeaponData.tier_color(id)
			if is_boss_motif and sel:
				ci.draw_rect(Rect2(px + 4.0, y - 1.0, panel_w - 8.0, 17.0), Color(1.0, 0.22, 0.30, 0.16))
			Art.draw_text(ci, Vector2(tx_x, y + 12.0), txt, 14, wcol if sel else wcol.darkened(0.35), false)
			var mod_id: String = Global.get_weapon_mod(id)
			if mod_id != "":
				var badge: String = "[%s]" % WeaponMods.mod_name(mod_id)
				var bw_badge: float = Art.text_width(badge, 12)
				var bx_badge: float = minf(tx_x + Art.text_width(txt, 14) + 5.0, w - bw_badge - 10.0)
				var mcol: Color = WeaponMods.mod_color(mod_id) if sel else WeaponMods.mod_color(mod_id).darkened(0.3)
				ci.draw_rect(Rect2(bx_badge - 2.0, y + 1.0, bw_badge + 4.0, 13.0), Color(0.06, 0.03, 0.08, 0.72))
				Art.draw_text(ci, Vector2(bx_badge, y + 11.0), badge, 12, mcol, false)
		var sk_info: Dictionary = HeroData.skill_info(player.hero_id, Global.active_skill_index(player.hero_id))
		var sk_title: String = str(sk_info.get("skill_name", player.hero.skill_name))
		var ready: bool = player.skill_timer <= 0.0
		var sk: String = "Sẵn sàng" if ready else "%.1fs" % player.skill_timer
		Art.draw_text(ci, Vector2(px + 6.0, h - 22.0), "[K] %s: %s" % [sk_title, sk], 14, Color(0.6, 0.88, 1.0) if ready else Color(0.6, 0.6, 0.65), false)
		var cur_wid: String = str(player.weapons[player.slot])
		var syn_lv: int = SynergyData.level(player.hero_id, cur_wid)
		var syn_fam: String = SynergyData.family(cur_wid)
		var syn_txt: String = "★★ Tâm đắc" if syn_lv == 2 else ("★ Cùng hệ" if syn_lv == 1 else "Chưa đồng điệu")
		var syn_col: Color = Color(1.0, 0.88, 0.35) if syn_lv == 2 else (Color(0.84, 0.88, 0.96) if syn_lv == 1 else Color(0.62, 0.62, 0.66))
		Art.draw_text(ci, Vector2(px + 6.0, h - 7.0), syn_txt, 12, syn_col, false)
		Art.draw_text(ci, Vector2(px + 116.0, h - 7.0), "Ấn: %s" % SynergyData.imprint_name(cur_wid), 12, SynergyData.family_color(syn_fam), false)

	# --- Thanh Tụ lực vũ khí (Charge bar)
	var charge_v: Variant = player.get("charge_ratio")
	var charge_r: float = clampf(float(charge_v), 0.0, 1.0) if charge_v != null else 0.0
	if charge_r > 0.0:
		var cw: float = 56.0
		var cx_b: float = (w - cw) * 0.5
		var cy_b: float = h * 0.5 + 22.0
		ci.draw_rect(Rect2(cx_b - 1.0, cy_b - 1.0, cw + 2.0, 7.0), Color(0.04, 0.02, 0.05, 0.9))
		ci.draw_rect(Rect2(cx_b, cy_b, cw, 5.0), Color(0.18, 0.12, 0.18, 0.85))
		var ccol: Color = Color("ff384c") if charge_r >= 0.99 else Color(1.0, 0.85, 0.32)
		ci.draw_rect(Rect2(cx_b, cy_b, cw * charge_r, 5.0), ccol)
		if charge_r >= 0.99:
			ci.draw_rect(Rect2(cx_b - 1.0, cy_b - 1.0, cw + 2.0, 7.0), Color(1.0, 0.92, 0.45), false, 1.0)

	# --- Gợi ý Hợp nhất vũ khí ([R] Hợp nhất)
	if player.has_method("can_merge_nearby"):
		var merge_info: Dictionary = player.can_merge_nearby()
		if not merge_info.is_empty():
			var rec: Dictionary = merge_info.get("recipe", {})
			var res_id: String = str(rec.get("result", ""))
			var mname: String = str(rec.get("name", ""))
			if mname == "" and res_id != "":
				mname = str(WeaponData.get_data(res_id).get("name", res_id))
			var mkey := "Bấm HỢP NHẤT" if Global.touch_mode else "[R] Hợp nhất"
			var pulse_m: float = 0.72 + 0.28 * sin(Time.get_ticks_msec() / 130.0)
			Art.draw_text(ci, Vector2(w / 2.0, h - 94.0), "%s → %s" % [mkey, mname], 16, Color(0.45, 1.0, 0.86, pulse_m))

	# --- Gợi ý nhặt vũ khí hoặc Thẻ soi hàng Thương Nhân ---
	if player.interact_target != null and is_instance_valid(player.interact_target) and player.interact_target.has_method("inspect_info"):
		_draw_shop_inspect(ci, w, h, player.interact_target)
	elif player.nearby_pickup != null and is_instance_valid(player.nearby_pickup):
		var pid: String = player.nearby_pickup.weapon_id
		var pwd: Dictionary = WeaponData.get_data(pid)
		var key := "Bấm ĐỔI" if Global.touch_mode else "Nhấn E"
		var pcol_w: Color = Color("ff384c") if bool(pwd.get("boss_motif", false)) else WeaponData.tier_color(pid)
		Art.draw_text(ci, Vector2(w / 2.0, h - 76), "%s để nhặt: %s" % [key, str(pwd.get("name", pid))], 18, pcol_w)

	# --- Băng chân dung khi tung chiêu
	if _cutin_t > 0.0 and _cutin_hero != "":
		_draw_cutin(ci, w, h)

	# --- Thông báo đổi nhạc nền (góc dưới phải, phía trên bảng vũ khí)
	if _bgm_toast_t > 0.0 and _bgm_toast_title != "":
		_draw_music_toast(ci, w, h)

	# --- Biểu ngữ Hợp Chiêu Đại Việt (Co-op Synergy Ultimate)
	if _coop_combo_t > 0.0 and _coop_combo_name != "":
		_draw_coop_combo(ci, w, h)

	# --- Thông báo khai mở Hồn Sử mới (không chặn combat)
	if _chronicle_toast_t > 0.0 and _chronicle_toast_title != "":
		_draw_chronicle_toast(ci, w, h)

	# --- Giới thiệu chương / Trùm xuất hiện
	if _boss_intro_t > 0.0:
		_draw_boss_intro(ci, w, h)
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
		if is_coloa:
			var b_sz: int = 12 if _banner.length() > 30 else 14
			var b_y: float = 80.0 if has_boss else 54.0
			var bw_pill: float = clampf(float(_banner.length()) * 6.8 + 26.0, 180.0, 292.0)
			ci.draw_rect(Rect2((w - bw_pill) * 0.5, b_y - 11.0, bw_pill, 22.0), Color(0.05, 0.03, 0.04, 0.78 * a2))
			ci.draw_rect(Rect2((w - bw_pill) * 0.5, b_y - 11.0, bw_pill, 22.0), Color(0.95, 0.78, 0.32, 0.50 * a2), false, 1.0)
			Art.draw_text(ci, Vector2(w * 0.5, b_y + 3.0), _banner, b_sz, Color(1, 0.85, 0.4, a2))
		else:
			var b_sz: int = 18 if _banner.length() > 34 else 24
			Art.draw_text(ci, Vector2(w / 2.0, h * 0.30), _banner, b_sz, Color(1, 0.85, 0.4, a2))


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
	if not HeroData.DATA.has(_cutin_hero):
		return
	var hero: Dictionary = HeroData.DATA[_cutin_hero]
	var sk_idx: int = Global.active_skill_index(_cutin_hero)
	var sk_info: Dictionary = HeroData.skill_info(_cutin_hero, sk_idx)
	var sk_id: String = str(sk_info.get("skill", hero.get("skill", "")))
	var sk_name: String = str(sk_info.get("skill_name", hero.get("skill_name", "")))

	var t: float = 0.9 - _cutin_t
	var enter: float = clampf(t / 0.16, 0.0, 1.0)
	var slide: float = 1.0 - pow(1.0 - enter, 3.0)
	var a: float = clampf(_cutin_t / 0.18, 0.0, 1.0)
	var y: float = h - 116.0
	var bw: float = minf(336.0, w * 0.58)
	var x: float = lerpf(-bw - 20.0, 0.0, slide)
	var col: Color = hero.get("color", Color(0.75, 0.25, 0.25)) as Color
	var accent: Color = hero.get("accent", Color(1.0, 0.85, 0.4)) as Color

	# Nền băng chuyển sắc nhiều lớp theo màu bản mệnh tướng
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(x, y - 2.0),
		Vector2(x + bw + 14.0, y - 8.0),
		Vector2(x + bw - 14.0, y + 42.0),
		Vector2(x, y + 44.0),
	]), Color(col.darkened(0.68), 0.88 * a))
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(x, y),
		Vector2(x + bw * 0.68, y - 5.0),
		Vector2(x + bw * 0.56, y + 38.0),
		Vector2(x, y + 40.0),
	]), Color(col.darkened(0.32), 0.72 * a))
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(x, y + 4.0),
		Vector2(x + 92.0, y + 2.0),
		Vector2(x + 74.0, y + 36.0),
		Vector2(x, y + 36.0),
	]), Color(accent.r, accent.g, accent.b, 0.22 * a))

	# Vệt tốc độ động lực học lướt ngang băng chân dung
	for li in 7:
		var spd: float = 2.6 + float(li % 3) * 0.9
		var prog: float = fmod(t * spd + float(li) * 0.17, 1.0)
		var lx0: float = x + 16.0 + prog * (bw - 70.0)
		var len_l: float = 28.0 + float((li * 13) % 26)
		var ly: float = y + 3.0 + float(li) * 5.2
		var l_col := Color(1.0, 0.96, 0.78, (0.42 - prog * 0.28) * a) if li % 2 == 0 else Color(accent.r, accent.g, accent.b, (0.48 - prog * 0.3) * a)
		ci.draw_line(Vector2(lx0, ly), Vector2(minf(x + bw - 10.0, lx0 + len_l), ly - 1.5), l_col, 1.6 if li % 2 == 0 else 1.1)

	# Viền vàng kép trên & dưới
	ci.draw_line(Vector2(x, y - 2.0), Vector2(x + bw + 14.0, y - 8.0), Color(accent.r, accent.g, accent.b, 0.95 * a), 2.0)
	ci.draw_line(Vector2(x, y + 44.0), Vector2(x + bw - 14.0, y + 42.0), Color(accent.r, accent.g, accent.b, 0.95 * a), 2.0)
	ci.draw_line(Vector2(x, y + 2.0), Vector2(x + bw, y - 4.0), Color(1.0, 0.95, 0.78, 0.35 * a), 1.0)

	# Khung chân dung tướng ở khung "skill" (frame 12 khi dải >= 13*32, dự phòng frame 0)
	var tex := Art.tex("heroes/%s.png" % _cutin_hero)
	var port_c := Vector2(x + 32.0, y + 14.0)
	ci.draw_circle(port_c, 22.0, Color(accent.r, accent.g, accent.b, 0.28 * a))
	ci.draw_circle(port_c, 15.0, Color(1.0, 0.96, 0.85, 0.16 * a))
	if tex != null:
		var frame_idx: int = 12 if tex.get_width() >= 13 * 32 else 0
		var cols: int = maxi(1, int(tex.get_width()) / 32)
		var src := Rect2((frame_idx % cols) * 32, (int(frame_idx) / cols) * 32, 32, 32)
		ci.draw_texture_rect_region(tex, Rect2(x + 6.0, y - 14.0, 52.0, 52.0), src, Color(1.0, 1.0, 1.0, a))

	# Biểu tượng chiêu & tên chiêu sắc nét
	var icon := Art.tex("ui/skill_%s.png" % sk_id)
	if icon == null:
		icon = Art.tex("ui/skill_%s.png" % str(hero.get("skill", "")))
	if icon != null:
		ci.draw_rect(Rect2(x + 61.0, y + 7.0, 24.0, 24.0), Color(0.05, 0.02, 0.05, 0.75 * a))
		ci.draw_rect(Rect2(x + 61.0, y + 7.0, 24.0, 24.0), Color(accent.r, accent.g, accent.b, 0.85 * a), false, 1.0)
		ci.draw_texture_rect(icon, Rect2(x + 63.0, y + 9.0, 20.0, 20.0), false, Color(1.0, 1.0, 1.0, a))

	var title_up: String = sk_name.to_upper()
	var title_sz: int = 23 if Art.text_width(title_up, 23) <= (bw - 102.0) else 19
	Art.draw_text(ci, Vector2(x + 92.0, y + 21.0), title_up, title_sz, Color(1.0, 0.94, 0.56, a), false)
	Art.draw_text(ci, Vector2(x + 93.0, y + 36.0), "%s  •  Chiêu %d" % [str(hero.get("name", "")), sk_idx], 13, Color(0.96, 0.94, 0.92, 0.95 * a), false)


func _draw_coloa_build_bar(ci: Control, _w: float, h: float) -> void:
	var sel_idx: int = DefenseTower.shared_choice_idx % maxi(1, CoLoaData.TOWER_ORDER.size())
	var slot_w: float = 54.0
	var slot_h: float = 36.0
	var gap: float = 3.0
	var bx0: float = 4.0
	var by0: float = h - slot_h - 4.0
	for i in CoLoaData.TOWER_ORDER.size():
		var tid: String = str(CoLoaData.TOWER_ORDER[i])
		var info: Dictionary = CoLoaData.tower_info(tid)
		var cost: int = CoLoaData.tower_upgrade_cost(tid, 1)
		var col: Color = info.get("color", Color(0.95, 0.80, 0.35))
		var active: bool = (i == sel_idx)
		var can_buy: bool = Global.run_coins >= cost
		var rx: float = bx0 + float(i) * (slot_w + gap)
		var rect := Rect2(rx, by0, slot_w, slot_h)
		ci.draw_rect(rect, Color(0.14, 0.08, 0.09, 0.90) if active else Color(0.06, 0.04, 0.07, 0.78))
		ci.draw_rect(rect, Color(1.0, 0.88, 0.36) if active else Color(col.r, col.g, col.b, 0.45), false, 1.5 if active else 1.0)
		Art.draw_text(ci, Vector2(rx + 4.0, by0 + 10.0), "[%d]" % (i + 1), 9, Color(1.0, 0.92, 0.48) if active else Color(0.75, 0.75, 0.80), false)
		var trel: String = str(info.get("sprite", ""))
		if trel != "" and ResourceLoader.exists("res://assets/sprites/" + trel):
			var tex: Texture2D = Art.tex(trel)
			if tex != null:
				ci.draw_texture_rect(tex, Rect2(rx + 26.0, by0 + 2.0, 18.0, 18.0), false)
		var slbl: String = str(info.get("short_label", tid))
		Art.draw_text(ci, Vector2(rx + slot_w * 0.5, by0 + 24.0), slbl, 9, Color(0.96, 0.92, 0.84), true)
		Art.draw_text(ci, Vector2(rx + slot_w * 0.5, by0 + 33.0), "%dxu" % cost, 9, Color(0.55, 1.0, 0.65) if can_buy else Color(1.0, 0.48, 0.45), true)


func _draw_coloa_minimap(ci: Control, origin: Vector2, area: Vector2) -> void:
	ci.draw_rect(Rect2(origin, area), Color(0.04, 0.06, 0.08, 0.86))
	ci.draw_rect(Rect2(origin, area), Color(0.65, 0.52, 0.28, 0.7), false, 1.0)
	var b: Rect2 = CoLoaData.ARENA_RECT
	var to_map := func(wp: Vector2) -> Vector2:
		var nx: float = clampf((wp.x - b.position.x) / b.size.x, 0.04, 0.96)
		var ny: float = clampf((wp.y - b.position.y) / b.size.y, 0.06, 0.94)
		return origin + Vector2(nx * area.x, ny * area.y)
	var ctr: Vector2 = to_map.call(Vector2.ZERO)
	# 4 trục đường & vòng hào nước Cổ Loa thu nhỏ
	ci.draw_line(to_map.call(Vector2(0.0, -360.0)), to_map.call(Vector2(0.0, 360.0)), Color(0.45, 0.36, 0.24, 0.55), 2.0)
	ci.draw_line(to_map.call(Vector2(-500.0, 0.0)), to_map.call(Vector2(500.0, 0.0)), Color(0.45, 0.36, 0.24, 0.55), 2.0)
	ci.draw_arc(ctr, minf(area.x, area.y) * 0.34, 0.0, TAU, 24, Color(0.24, 0.72, 0.92, 0.55), 1.4)
	# 8 bệ tháp
	for tw in get_tree().get_nodes_in_group("defense_towers"):
		if not is_instance_valid(tw):
			continue
		var tp: Vector2 = to_map.call((tw as Node2D).global_position)
		var tw_tier: int = int(tw.get("tier"))
		if tw_tier <= 0:
			ci.draw_circle(tp, 1.6, Color(0.55, 0.52, 0.48, 0.65))
		else:
			var tinfo: Dictionary = CoLoaData.tower_info(str(tw.get("tower_id")))
			var tcol: Color = tinfo.get("color", Color(0.95, 0.80, 0.35))
			ci.draw_rect(Rect2(tp - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), tcol)
			if tw_tier >= 3:
				ci.draw_rect(Rect2(tp - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), Color(1.0, 0.92, 0.42), false, 1.0)
	# Nỏ Thần trung tâm
	ci.draw_colored_polygon(PackedVector2Array([
		ctr + Vector2(0.0, -4.0), ctr + Vector2(4.0, 0.0), ctr + Vector2(0.0, 4.0), ctr + Vector2(-4.0, 0.0),
	]), Color(0.38, 0.98, 0.88))
	# Giặc & Boss công thành
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var ep: Vector2 = to_map.call((e as Node2D).global_position)
		if e.has_method("is_boss") and e.is_boss():
			ci.draw_rect(Rect2(ep - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(1.0, 0.22, 0.36))
		else:
			ci.draw_circle(ep, 1.4, Color(1.0, 0.38, 0.30))
	# Người chơi
	for pl in Global.all_players():
		if is_instance_valid(pl) and not bool(pl.get("dead")):
			var pp: Vector2 = to_map.call((pl as Node2D).global_position)
			ci.draw_circle(pp, 2.4, Color.WHITE)


func _draw_minimap(ci: Control, origin: Vector2, area: Vector2) -> void:
	if Global.has_method("is_co_loa") and Global.is_co_loa():
		_draw_coloa_minimap(ci, origin, area)
		return
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
		elif r.kind == "event":
			col = Color(1.0, 0.62, 0.25)
		elif r.kind == "victory_hall":
			col = Color(1.0, 0.88, 0.38)
		if r.player_inside:
			col = Color.WHITE
		var mr := Rect2(off + Vector2(c - lo) * cs + Vector2(1.5, 1.5), Vector2(cs - 3, cs * 0.75 - 1))
		ci.draw_rect(mr, col)
		if r.kind == "event":
			Art.draw_text(ci, mr.get_center() + Vector2(0, 3), "!", 9, Color(0.1, 0.04, 0.04))


func get_wayfinder_targets() -> Array:
	return []


func _wrap_intro_text(txt: String, max_w: float, sz: int) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in txt.split(" "):
		var cand: String = word if cur == "" else (cur + " " + word)
		if Art.text_width(cand, sz) <= max_w or cur == "":
			cur = cand
		else:
			out.append(cur)
			cur = word
	if cur != "":
		out.append(cur)
	return out


func _draw_boss_intro(ci: Control, w: float, h: float) -> void:
	var elapsed: float = 3.4 - _boss_intro_t
	var enter_t: float = clampf(elapsed / 0.28, 0.0, 1.0)
	var ease_in: float = 1.0 - pow(1.0 - enter_t, 3.0)
	var leave_t: float = clampf(_boss_intro_t / 0.55, 0.0, 1.0)
	var a: float = ease_in * leave_t
	var b_bg := Color(0.11, 0.03, 0.17, 0.90 * a) if _boss_intro_mythic else Color(0.16, 0.02, 0.04, 0.88 * a)
	var b_edge := Color(0.84, 0.48, 1.0, a) if _boss_intro_mythic else Color(1.0, 0.48, 0.24, a)
	var gold := Color(1.0, 0.86, 0.42, a)

	# Dải khung điện ảnh trên và dưới
	var bar_h: float = 14.0 * a
	ci.draw_rect(Rect2(0.0, 0.0, w, bar_h), Color(0.03, 0.01, 0.04, 0.72 * a))
	ci.draw_rect(Rect2(0.0, h - bar_h, w, bar_h), Color(0.03, 0.01, 0.04, 0.72 * a))
	ci.draw_line(Vector2(0.0, bar_h), Vector2(w, bar_h), Color(b_edge.r, b_edge.g, b_edge.b, 0.45 * a), 1.0)
	ci.draw_line(Vector2(0.0, h - bar_h), Vector2(w, h - bar_h), Color(b_edge.r, b_edge.g, b_edge.b, 0.45 * a), 1.0)

	# Thẻ giới thiệu Boss (tránh đè thanh máu góc trái và bản đồ nhỏ góc phải)
	var card_w: float = minf(436.0, w - 120.0)
	var slide_x: float = (1.0 - ease_in) * 140.0 - (1.0 - leave_t) * 80.0
	var card_x: float = minf((w - card_w) * 0.5, w - card_w - 106.0) + slide_x
	var card_y: float = clampf(h * 0.20, 72.0, 96.0)
	var card_h: float = 84.0
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(card_x + 8.0, card_y),
		Vector2(card_x + card_w, card_y),
		Vector2(card_x + card_w - 8.0, card_y + card_h),
		Vector2(card_x, card_y + card_h),
	]), b_bg)
	ci.draw_polyline(PackedVector2Array([
		Vector2(card_x + 8.0, card_y),
		Vector2(card_x + card_w, card_y),
		Vector2(card_x + card_w - 8.0, card_y + card_h),
		Vector2(card_x, card_y + card_h),
		Vector2(card_x + 8.0, card_y),
	]), b_edge, 2.0)
	ci.draw_polyline(PackedVector2Array([
		Vector2(card_x + 11.0, card_y + 3.0),
		Vector2(card_x + card_w - 4.0, card_y + 3.0),
		Vector2(card_x + card_w - 11.0, card_y + card_h - 3.0),
		Vector2(card_x + 4.0, card_y + card_h - 3.0),
		Vector2(card_x + 11.0, card_y + 3.0),
	]), Color(gold.r, gold.g, gold.b, 0.42 * a), 1.0)

	# Vạch năng lượng trượt dọc viền trên & dưới
	var stripe_off: float = fmod(float(Time.get_ticks_msec()) * 0.09, 24.0)
	var sx: float = card_x + 16.0 + stripe_off
	while sx < card_x + card_w - 18.0:
		ci.draw_line(Vector2(sx, card_y + 2.0), Vector2(sx - 6.0, card_y + 7.0), Color(gold.r, gold.g, gold.b, 0.45 * a), 1.4)
		ci.draw_line(Vector2(sx, card_y + card_h - 7.0), Vector2(sx - 6.0, card_y + card_h - 2.0), Color(gold.r, gold.g, gold.b, 0.45 * a), 1.4)
		sx += 24.0

	var has_port: bool = _boss_intro_sheet != ""
	if has_port:
		var box_x: float = card_x + 14.0
		var box_y: float = card_y + 8.0
		var box_sz: float = 68.0
		ci.draw_rect(Rect2(box_x, box_y, box_sz, box_sz), Color(0.05, 0.01, 0.06, 0.86 * a))
		ci.draw_rect(Rect2(box_x, box_y, box_sz, box_sz), gold, false, 1.4)
		ci.draw_circle(Vector2(box_x + box_sz * 0.5, box_y + box_sz * 0.5), 28.0, Color(b_edge.r, b_edge.g, b_edge.b, 0.24 * a))
		var btex := Art.tex(_boss_intro_sheet)
		if btex != null and _boss_intro_fsize.x > 0 and _boss_intro_fsize.y > 0:
			var frame_idx: int = 4 if btex.get_width() >= _boss_intro_fsize.x * 5 else 0
			var sc: float = minf(60.0 / float(_boss_intro_fsize.x), 60.0 / float(_boss_intro_fsize.y))
			var dw: float = float(_boss_intro_fsize.x) * sc
			var dh: float = float(_boss_intro_fsize.y) * sc
			var dst := Rect2(box_x + (box_sz - dw) * 0.5, box_y + (box_sz - dh) * 0.5, dw, dh)
			var src := Rect2(float(frame_idx * _boss_intro_fsize.x), 0.0, float(_boss_intro_fsize.x), float(_boss_intro_fsize.y))
			ci.draw_texture_rect_region(btex, dst, src, Color(1.0, 1.0, 1.0, a))

	var tx: float = card_x + (90.0 if has_port else card_w * 0.5)
	var max_tw: float = card_w - 104.0 if has_port else card_w - 28.0
	var centered_txt: bool = not has_port
	var tag: String = "★ YÊU VƯƠNG THẦN THOẠI XUẤT HIỆN ★" if _boss_intro_mythic else "★ CẢNH BÁO TRÙM XUẤT HIỆN ★"
	Art.draw_text(ci, Vector2(tx, card_y + 18.0), tag, 11, gold, centered_txt)
	Art.draw_text(ci, Vector2(tx, card_y + 37.0), _boss_intro_name.to_upper(), 22, Color(0.96, 0.84, 1.0, a) if _boss_intro_mythic else Color(1.0, 0.80, 0.48, a), centered_txt)
	Art.draw_text(ci, Vector2(tx, card_y + 51.0), _boss_intro_title, 12, Color(0.95, 0.90, 0.86, a), centered_txt)
	if _boss_intro_desc != "":
		var div_x0: float = tx if has_port else card_x + 28.0
		ci.draw_line(Vector2(div_x0, card_y + 56.0), Vector2(card_x + card_w - 18.0, card_y + 56.0), Color(b_edge.r, b_edge.g, b_edge.b, 0.5 * a), 1.0)
		var lines: Array[String] = _wrap_intro_text(_boss_intro_desc, max_tw, 11)
		var desc_col := Color(0.84, 0.94, 1.0, a) if _boss_intro_mythic else Color(0.96, 0.92, 0.76, a)
		for li in mini(lines.size(), 2):
			Art.draw_text(ci, Vector2(tx, card_y + 68.0 + float(li) * 11.0), lines[li], 11, desc_col, centered_txt)


func _music_toast_palette(track_id: String) -> Dictionary:
	match track_id:
		"boss_frenzy":
			return {
				"bg": Color(0.20, 0.03, 0.05),
				"border": Color(1.0, 0.28, 0.32),
				"text": Color(1.0, 0.86, 0.86),
			}
		"boss", "boss_legend", "boss_mythic":
			return {
				"bg": Color(0.16, 0.06, 0.03),
				"border": Color(1.0, 0.62, 0.20),
				"text": Color(1.0, 0.90, 0.72),
			}
		"victory":
			return {
				"bg": Color(0.14, 0.10, 0.03),
				"border": Color(1.0, 0.86, 0.30),
				"text": Color(1.0, 0.96, 0.78),
			}
		_:
			return {
				"bg": Color(0.05, 0.09, 0.12),
				"border": Color(0.48, 0.88, 0.95),
				"text": Color(0.90, 0.97, 0.98),
			}


func _draw_music_toast(ci: Control, w: float, h: float) -> void:
	var elapsed: float = 3.0 - _bgm_toast_t
	var fade_in: float = clampf(elapsed / 0.25, 0.0, 1.0)
	var fade_out: float = clampf(_bgm_toast_t / 0.45, 0.0, 1.0)
	var alpha: float = minf(fade_in, fade_out)
	if alpha <= 0.01:
		return
	var pal: Dictionary = _music_toast_palette(_bgm_toast_id)
	var bg_col: Color = pal.bg as Color
	var edge_col: Color = pal.border as Color
	var txt_col: Color = pal.text as Color
	var label: String = "♪ " + _bgm_toast_title
	var txt_w: float = Art.text_width(label, 13)
	var pill_w: float = clampf(txt_w + 18.0, 108.0, w * 0.46)
	var pill_h: float = 19.0
	var sc: float = float(Global.settings.get("touch_scale", 1.0))
	var bottom_clear_y: float = (h - 152.0 * sc) if Global.touch_mode else (h - 80.0)
	var slide_x: float = (1.0 - fade_in) * 16.0
	var px: float = w - pill_w - 6.0 + slide_x
	var py: float = maxf(140.0, bottom_clear_y - pill_h)
	var rect := Rect2(px, py, pill_w, pill_h)
	ci.draw_rect(rect, Color(bg_col.r, bg_col.g, bg_col.b, 0.86 * alpha))
	ci.draw_rect(Rect2(px, py, 3.0, pill_h), Color(edge_col.r, edge_col.g, edge_col.b, 0.95 * alpha))
	ci.draw_rect(rect, Color(edge_col.r, edge_col.g, edge_col.b, 0.88 * alpha), false, 1.0)
	ci.draw_rect(rect.grow(-2.0), Color(edge_col.r, edge_col.g, edge_col.b, 0.22 * alpha), false, 1.0)
	Art.draw_text(ci, Vector2(px + 9.0, py + 13.5), label, 13, Color(txt_col.r, txt_col.g, txt_col.b, alpha), false)


func _draw_coop_combo(ci: Control, w: float, _h: float) -> void:
	var elapsed: float = 2.6 - _coop_combo_t
	var enter_t: float = clampf(elapsed / 0.22, 0.0, 1.0)
	var ease_in: float = 1.0 - pow(1.0 - enter_t, 3.0)
	var fade_out: float = clampf(_coop_combo_t / 0.45, 0.0, 1.0)
	var a: float = ease_in * fade_out
	if a <= 0.01:
		return
	var title_txt: String = "★ HỢP CHIÊU ĐẠI VIỆT: %s ★" % _coop_combo_name.to_upper()
	var title_sz: int = 15 if Art.text_width(title_txt, 15) <= 278.0 else 13
	var need_w: float = maxf(Art.text_width(title_txt, title_sz), Art.text_width(_coop_combo_sub, 11)) + 54.0
	var bw: float = clampf(need_w, 232.0, minf(336.0, w - 274.0))
	var bh: float = 42.0 if _coop_combo_sub != "" else 28.0
	var has_boss: bool = get_tree().get_first_node_in_group("boss") != null
	var bx: float = (w - bw) * 0.5
	var by: float = (34.0 if has_boss else 14.0) - (1.0 - ease_in) * 14.0

	var bg_col := Color(_coop_combo_col.darkened(0.76), 0.92 * a)
	var edge_col := Color(_coop_combo_col.r, _coop_combo_col.g, _coop_combo_col.b, 0.96 * a)
	var gold_col := Color(1.0, 0.90, 0.46, 0.95 * a)
	var poly := PackedVector2Array([
		Vector2(bx + 10.0, by),
		Vector2(bx + bw - 10.0, by),
		Vector2(bx + bw, by + bh * 0.5),
		Vector2(bx + bw - 10.0, by + bh),
		Vector2(bx + 10.0, by + bh),
		Vector2(bx, by + bh * 0.5),
	])
	ci.draw_colored_polygon(poly, bg_col)
	var ring := poly.duplicate()
	ring.append(poly[0])
	ci.draw_polyline(ring, edge_col, 2.0)
	var inner := PackedVector2Array([
		Vector2(bx + 13.0, by + 3.0),
		Vector2(bx + bw - 13.0, by + 3.0),
		Vector2(bx + bw - 4.0, by + bh * 0.5),
		Vector2(bx + bw - 13.0, by + bh - 3.0),
		Vector2(bx + 13.0, by + bh - 3.0),
		Vector2(bx + 4.0, by + bh * 0.5),
		Vector2(bx + 13.0, by + 3.0),
	])
	ci.draw_polyline(inner, Color(gold_col.r, gold_col.g, gold_col.b, 0.42 * a), 1.0)

	# Hai cặp mũi tên (chevrons) kẹp hai bên nhấp nháy theo nhịp
	var pulse: float = 0.72 + 0.28 * sin(elapsed * 9.0)
	var chev_shift: float = sin(elapsed * 7.5) * 2.5
	var chev_col := Color(gold_col.r, gold_col.g, gold_col.b, pulse * a)
	var cy_mid: float = by + bh * 0.5
	for ci_idx in 2:
		var lx: float = bx + 15.0 + float(ci_idx) * 6.0 - chev_shift
		ci.draw_polyline(PackedVector2Array([
			Vector2(lx + 4.0, cy_mid - 6.0),
			Vector2(lx, cy_mid),
			Vector2(lx + 4.0, cy_mid + 6.0),
		]), chev_col, 1.8)
		var rx: float = bx + bw - 15.0 - float(ci_idx) * 6.0 + chev_shift
		ci.draw_polyline(PackedVector2Array([
			Vector2(rx - 4.0, cy_mid - 6.0),
			Vector2(rx, cy_mid),
			Vector2(rx - 4.0, cy_mid + 6.0),
		]), chev_col, 1.8)

	Art.draw_text(ci, Vector2(w * 0.5, by + 18.0), title_txt, title_sz, Color(1.0, 0.94, 0.58, a), true)
	if _coop_combo_sub != "":
		Art.draw_text(ci, Vector2(w * 0.5, by + 34.0), _coop_combo_sub, 11, Color(0.98, 0.95, 0.86, 0.95 * a), true)


func _draw_chronicle_toast(ci: Control, w: float, _h: float) -> void:
	var elapsed: float = 3.2 - _chronicle_toast_t
	var enter_t: float = clampf(elapsed / 0.25, 0.0, 1.0)
	var ease_in: float = 1.0 - pow(1.0 - enter_t, 3.0)
	var fade_out: float = clampf(_chronicle_toast_t / 0.5, 0.0, 1.0)
	var a: float = minf(ease_in, fade_out)
	if a <= 0.01:
		return
	var title_txt: String = "📖 Hồn Sử mới: %s" % _chronicle_toast_title
	var sub_txt: String = "Đã lưu trang sử & treo Kỷ Vật tại Đại Sảnh"
	var tw: float = maxf(Art.text_width(title_txt, 13), Art.text_width(sub_txt, 10))
	var pw: float = clampf(tw + 28.0, 200.0, minf(318.0, w - 274.0))
	var ph: float = 34.0
	var px: float = (w - pw) * 0.5
	var has_boss: bool = get_tree().get_first_node_in_group("boss") != null
	var base_y: float = 82.0 if _coop_combo_t > 0.0 else (34.0 if has_boss else 14.0)
	var py: float = base_y - (1.0 - ease_in) * 10.0
	var rect := Rect2(px, py, pw, ph)
	ci.draw_rect(rect, Color(0.18, 0.12, 0.06, 0.93 * a))
	ci.draw_rect(rect.grow(-2.0), Color(0.34, 0.24, 0.12, 0.28 * a))
	ci.draw_rect(Rect2(px, py, 3.0, ph), Color(1.0, 0.85, 0.36, 0.96 * a))
	ci.draw_rect(rect, Color(1.0, 0.85, 0.36, 0.94 * a), false, 1.5)
	ci.draw_rect(rect.grow(-2.5), Color(0.82, 0.62, 0.24, 0.45 * a), false, 1.0)
	Art.draw_text(ci, Vector2(px + pw * 0.5 + 1.0, py + 14.0), title_txt, 13, Color(1.0, 0.92, 0.54, a), true)
	Art.draw_text(ci, Vector2(px + pw * 0.5 + 1.0, py + 27.0), sub_txt, 10, Color(0.94, 0.89, 0.78, 0.92 * a), true)
