extends CanvasLayer
## Giao diện sảnh chính: tên phòng, bản đồ thu nhỏ 4 phòng, xu, và các bảng:
## tướng, lò rèn, giá binh khí, bia ghi công, giếng ước, bảng khiêu chiến, bách khoa.

const HeroData = preload("res://scripts/data/heroes.gd")
const HeroSkins = preload("res://scripts/data/hero_skins.gd")
const SkillTreeData = preload("res://scripts/data/skill_tree.gd")
const RelicData = preload("res://scripts/data/relics.gd")
const CampNpcs = preload("res://scripts/data/camp_npcs.gd")
const HaoKhiData = preload("res://scripts/data/hao_khi_data.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")
const MaterialData = preload("res://scripts/data/materials.gd")
const SynergyData = preload("res://scripts/data/synergy.gd")
const ProgressionData = preload("res://scripts/data/progression.gd")
const BuffData = preload("res://scripts/data/buffs.gd")
const EnemyData = preload("res://scripts/data/enemies.gd")
const WeaponMods = preload("res://scripts/data/weapon_mods.gd")
const AchievementData = preload("res://scripts/data/achievements.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")
const Fx = preload("res://scripts/effects/fx.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Art = preload("res://scripts/art/art.gd")

static var _chronicle_script: Script = null

static func _chronicle_data() -> Script:
	if _chronicle_script == null and ResourceLoader.exists("res://scripts/data/chronicles.gd"):
		_chronicle_script = load("res://scripts/data/chronicles.gd") as Script
	return _chronicle_script

static func _hotpatch_sync() -> Script:
	var gdc_path := "res://scripts/autoload/hotpatch_sync.gdc"
	var gd_path := "res://scripts/autoload/hotpatch_sync.gd"
	var load_path := gdc_path if FileAccess.file_exists(gdc_path) else gd_path
	var fresh := ResourceLoader.load(load_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if fresh != null:
		fresh.take_over_path(gdc_path)
		fresh.take_over_path(gd_path)
	return fresh

var lobby = null
var _panel: Control = null
var _coin_label: Label
var _room_label: Label
var _prep_label: Label
var _hint_label: Label = null
var _select_banner: PanelContainer = null
var _lan_panel: PanelContainer = null
var _lan_room_lbl: Label = null
var _lan_ip_lbl: Label = null
var _lan_peers_box: VBoxContainer = null
var _lan_start_btn: Button = null
var _minimap: Control = null
var _preview_skin_hero: String = ""
var _preview_skin_id: String = ""


func _is_npc_rescued(npc_id: String) -> bool:
	var arr: Variant = Global.get("rescued_npcs")
	return arr is Array and (arr as Array).has(npc_id)


func _get_selected_skin_id(hid: String) -> String:
	if Global.has_method("get_selected_skin"):
		return str(Global.call("get_selected_skin", hid))
	var map: Variant = Global.get("selected_skins")
	if map is Dictionary and (map as Dictionary).has(hid):
		return str((map as Dictionary)[hid])
	return HeroSkins.DEFAULT_SKIN


func _is_skin_unlocked(hid: String, sid: String) -> bool:
	if sid == HeroSkins.DEFAULT_SKIN or sid == "":
		return true
	if Global.has_method("is_skin_unlocked"):
		return bool(Global.call("is_skin_unlocked", hid, sid))
	var map: Variant = Global.get("unlocked_skins")
	if map is Dictionary and (map as Dictionary).has(hid):
		var arr: Variant = (map as Dictionary)[hid]
		if arr is Array:
			return (arr as Array).has(sid)
	return false


func _is_pet_awakened(pid: String) -> bool:
	if Global.has_method("is_pet_awakened"):
		return bool(Global.call("is_pet_awakened", pid))
	var arr: Variant = Global.get("awakened_pets")
	return arr is Array and (arr as Array).has(pid)


func _can_awaken_pet(pid: String) -> bool:
	if Global.has_method("can_awaken_pet"):
		return bool(Global.call("can_awaken_pet", pid))
	return false


func _hao_khi_level() -> int:
	var lv: Variant = Global.get("hao_khi_level")
	return clampi(int(lv) if lv != null else 0, 0, HaoKhiData.MAX_LEVEL)


func _skill_tree_dict() -> Dictionary:
	var raw: Variant = Global.get("skill_tree")
	return raw as Dictionary if raw is Dictionary else {}


class LobbyMinimap extends Control:
	var lobby = null

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.05, 0.09, 0.78))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.62, 0.35, 0.8), false, 1.0)
		if lobby == null:
			return
		if bool(lobby.get("in_basement")):
			var br: Rect2 = lobby.BASEMENT_RECT
			var pad: float = 5.0
			var sc: float = minf((size.x - pad * 2.0) / br.size.x, (size.y - pad * 2.0) / br.size.y)
			var bw: float = br.size.x * sc
			var bh: float = br.size.y * sc
			var bx: float = (size.x - bw) * 0.5
			var by: float = (size.y - bh) * 0.5
			draw_rect(Rect2(bx, by, bw, bh), Color(0.24, 0.20, 0.28, 0.95))
			draw_rect(Rect2(bx, by, bw, bh), Color(1.0, 0.85, 0.35), false, 1.2)
			var markers: Array = [
				[Vector2(680, 972), Color(0.55, 0.92, 1.0)],
				[Vector2(430, 1170), Color(1.0, 0.86, 0.35)],
				[Vector2(680, 1275), Color(0.45, 0.92, 0.98)],
				[Vector2(930, 1170), Color(1.0, 0.65, 0.32)],
			]
			for m in markers:
				var mp: Vector2 = m[0]
				var mc: Color = m[1]
				var dp_m := Vector2(bx + (mp.x - br.position.x) * sc, by + (mp.y - br.position.y) * sc)
				draw_rect(Rect2(dp_m - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), mc)
			var bp_pos := Vector2(680, 1020)
			if lobby.player != null and is_instance_valid(lobby.player):
				bp_pos = lobby.player.global_position
			var dp_b := Vector2(bx + (bp_pos.x - br.position.x) * sc, by + (bp_pos.y - br.position.y) * sc)
			draw_circle(dp_b, 2.8, Color(1.0, 0.92, 0.3))
			return
		var sx: float = (size.x - 8.0) / 1360.0
		var sy: float = (size.y - 8.0) / 760.0
		var ox: float = 4.0
		var oy: float = 4.0
		# 3 hành lang nối
		for cr in [Rect2(420, 425, 40, 90), Rect2(900, 425, 40, 90), Rect2(635, 210, 90, 40)]:
			var mr := Rect2(ox + cr.position.x * sx, oy + cr.position.y * sy, cr.size.x * sx, cr.size.y * sy)
			draw_rect(mr, Color(0.45, 0.38, 0.32, 0.9))
		var ppos := Vector2(680, 524)
		var cur_room: String = ""
		if lobby.player != null and is_instance_valid(lobby.player):
			ppos = lobby.player.global_position
			cur_room = str(lobby.room_at(ppos).get("id", ""))
		for r in lobby.ROOMS:
			var rr: Rect2 = r.rect
			var mr := Rect2(ox + rr.position.x * sx, oy + rr.position.y * sy, rr.size.x * sx, rr.size.y * sy)
			var active: bool = str(r.id) == cur_room
			var fill := Color(0.32, 0.3, 0.38, 0.95) if active else Color(0.18, 0.17, 0.22, 0.92)
			draw_rect(mr, fill)
			draw_rect(mr, Color(1.0, 0.85, 0.35) if active else Color(0.55, 0.52, 0.56), false, 1.0)
		# Điểm mốc: Cổng Bắc (xanh dương), Lò Rèn (cam), Shop Nguyên Liệu (vàng), Giếng Ước (ngọc), Đài Thiên Phú (lục), Đài Thức Tỉnh (ngọc lam), Võ Đài (đỏ), Cầu thang Tầng Hầm (hổ phách)
		draw_rect(Rect2(ox + 680 * sx - 2, oy + 115 * sy - 2, 4, 4), Color(0.45, 0.85, 1.0))
		draw_rect(Rect2(ox + 1032 * sx - 1.5, oy + 345 * sy - 1.5, 3, 3), Color(1.0, 0.58, 0.25))
		draw_rect(Rect2(ox + 1204 * sx - 1.5, oy + 452 * sy - 1.5, 3, 3), Color(1.0, 0.84, 0.28))
		draw_rect(Rect2(ox + 245 * sx - 1.5, oy + 345 * sy - 1.5, 3, 3), Color(0.45, 0.95, 0.88))
		draw_rect(Rect2(ox + 680 * sx - 1.5, oy + 326 * sy - 1.5, 3, 3), Color(0.42, 0.96, 0.62))
		draw_rect(Rect2(ox + 356 * sx - 1.5, oy + 446 * sy - 1.5, 3, 3), Color(0.38, 0.94, 0.90))
		draw_rect(Rect2(ox + 1140 * sx - 1.5, oy + 654 * sy - 1.5, 3, 3), Color(1.0, 0.42, 0.34))
		var st_x: float = ox + 680.0 * sx
		var st_y: float = oy + 662.0 * sy
		draw_rect(Rect2(st_x - 2.5, st_y - 2.0, 5.0, 4.0), Color(0.95, 0.72, 0.25))
		draw_line(Vector2(st_x - 1.5, st_y - 1.0), Vector2(st_x + 1.5, st_y - 1.0), Color(0.25, 0.14, 0.05), 1.0)
		draw_line(Vector2(st_x - 0.5, st_y + 0.5), Vector2(st_x + 1.5, st_y + 0.5), Color(0.25, 0.14, 0.05), 1.0)
		# Chấm vị trí người chơi
		var dp := Vector2(ox + ppos.x * sx, oy + ppos.y * sy)
		draw_circle(dp, 2.8, Color(1.0, 0.92, 0.3))


class HeroSkillPreview extends Control:
	const Art = preload("res://scripts/art/art.gd")
	const HeroData = preload("res://scripts/data/heroes.gd")
	const ProgressionData = preload("res://scripts/data/progression.gd")

	static var _sfx_script: Script = null

	var hero_id: String = "ngo_quyen"
	var weapon_rank: int = 1
	var skill_idx: int = 1
	var skin_modulate: Color = Color.WHITE
	var _t: float = 0.0
	var _phase_t: float = 0.0
	var _casting: bool = true

	static func _skill_fx() -> Script:
		if _sfx_script == null and ResourceLoader.exists("res://scripts/effects/skill_fx.gd"):
			_sfx_script = load("res://scripts/effects/skill_fx.gd") as Script
		return _sfx_script

	func _ready() -> void:
		clip_contents = true
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func setup(hid: String, wrank: int = 1, sk_idx: int = -1, sk_tint: Color = Color.WHITE) -> void:
		hero_id = hid if HeroData.DATA.has(hid) else "ngo_quyen"
		weapon_rank = clampi(wrank, 1, 5)
		skill_idx = clampi(sk_idx if sk_idx >= 1 else Global.active_skill_index(hero_id), 1, 2)
		skin_modulate = sk_tint
		replay()

	func replay() -> void:
		_casting = true
		_phase_t = 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		_phase_t += delta
		if _casting and _phase_t >= 2.05:
			_casting = false
			_phase_t = 0.0
		elif not _casting and _phase_t >= 0.95:
			_casting = true
			_phase_t = 0.0
		queue_redraw()

	func _draw_frame(tex: Texture2D, center: Vector2, fw: int, fh: int, idx: int, sc: float, flip_x: bool = false, tint: Color = Color.WHITE) -> void:
		if tex == null:
			return
		var cols: int = maxi(1, int(tex.get_width()) / fw)
		var rows: int = maxi(1, int(tex.get_height()) / fh)
		var total: int = maxi(1, cols * rows)
		var fidx: int = posmod(idx, total)
		var src := Rect2((fidx % cols) * fw, (int(fidx) / cols) * fh, fw, fh)
		var w: float = float(fw) * sc * (-1.0 if flip_x else 1.0)
		var h: float = float(fh) * sc
		var dst := Rect2(center.x - absf(w) * 0.5 + (absf(w) if flip_x else 0.0), center.y - h * 0.5, w, h)
		draw_texture_rect_region(tex, dst, src, tint)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.09, 0.08, 0.13))
		# Sàn gạch mờ
		var grid_col := Color(0.22, 0.19, 0.27, 0.45)
		var gx: float = 20.0
		while gx < size.x:
			draw_line(Vector2(gx, 0), Vector2(gx, size.y), grid_col, 1.0)
			gx += 22.0
		var gy: float = 18.0
		while gy < size.y:
			draw_line(Vector2(0, gy), Vector2(size.x, gy), grid_col, 1.0)
			gy += 20.0
		draw_rect(r, Color(0.8, 0.65, 0.32, 0.85), false, 1.5)

		var h: Dictionary = HeroData.DATA.get(hero_id, HeroData.DATA["ngo_quyen"])
		var sk_info: Dictionary = HeroData.skill_info(hero_id, skill_idx)
		var wid: String = str(h.get("weapon", "giao_tre"))
		var sk: String = str(sk_info.get("skill", h.get("skill", "coc_bach_dang")))
		var hero_tex := Art.tex("heroes/%s.png" % hero_id)
		var weap_tex := Art.tex(ProgressionData.weapon_texture_path(wid, weapon_rank))
		var dummy_tex := Art.tex("world/dummy.png")

		var base_hero_pos := Vector2(size.x * 0.25, size.y * 0.62)
		var dummy_pos := Vector2(size.x * 0.78, size.y * 0.62)
		var p: float = clampf(_phase_t / 1.9, 0.0, 1.0) if _casting else 0.0
		var hero_pos := base_hero_pos
		var dummy_hit: bool = false

		if _casting and (sk == "voi_chien" or sk == "ngua_sat" or sk == "than_toc" or sk == "nhat_tao_xung_kich"):
			var lunge: float = sin(minf(p * 1.3, 1.0) * PI)
			hero_pos.x += lunge * (size.x * 0.34)
			if p > 0.22 and p < 0.78:
				dummy_hit = true
		elif _casting and p > 0.25 and p < 0.85:
			dummy_hit = true

		# Bóng dưới chân & vòng sáng
		draw_circle(Vector2(hero_pos.x, size.y * 0.76), 11.0, Color(0, 0, 0, 0.35))
		draw_circle(Vector2(dummy_pos.x, size.y * 0.76), 9.0, Color(0, 0, 0, 0.35))
		if weapon_rank >= 3:
			var rcol := Color(1.0, 0.86, 0.32, 0.25) if weapon_rank >= 5 else Color(0.35, 0.82, 1.0, 0.22)
			draw_circle(hero_pos + Vector2(12, -2), 14.0, rcol)

		# Hình nhân mục tiêu bên phải
		var d_shake := Vector2(sin(_t * 48.0) * 2.0, 0.0) if dummy_hit else Vector2.ZERO
		var d_tint := Color(1.0, 0.72, 0.72) if dummy_hit else Color.WHITE
		_draw_frame(dummy_tex, dummy_pos + d_shake, 20, 28, 1 if dummy_hit else 0, 1.45, false, d_tint)

		var sfx_sc := _skill_fx()
		var has_preview_fx: bool = sfx_sc != null and sfx_sc.has_method("draw_preview_fx")

		# Hiệu ứng nền chiêu dự phòng khi chưa nạp SkillCastFx
		if _casting and not has_preview_fx:
			match sk:
				"hich_tuong_si":
					var drum_tex := Art.tex("fx/drum.png")
					if drum_tex != null:
						var ds: float = 0.85 + 0.1 * sin(p * 18.0)
						var dw := float(drum_tex.get_width()) * ds
						var dh := float(drum_tex.get_height()) * ds
						draw_texture_rect(drum_tex, Rect2(base_hero_pos + Vector2(-dw * 0.5, 4.0 - dh * 0.5), Vector2(dw, dh)), false, Color(1.0, 0.9, 0.55, 0.85))
					draw_arc(base_hero_pos + Vector2(0, 4), 14.0 + fmod(p * 3.0, 1.0) * 32.0, 0.0, TAU, 28, Color(1.0, 0.84, 0.32, 0.7), 1.5)
				"than_toc":
					var aura_tex := Art.tex("fx/aura.png")
					_draw_frame(aura_tex, hero_pos, 40, 40, int(_t * 14.0), 1.2, false, Color(1.0, 0.88, 0.38, 0.8))
					for ghost in 3:
						var gp := base_hero_pos.lerp(hero_pos, float(ghost) / 3.0)
						_draw_frame(hero_tex, gp, 32, 32, 4 + ghost, 1.65, false, Color(1.0, 0.55, 0.25, 0.32))

		# Nhân vật tướng (hỗ trợ 28 khung: idle [0,1,16,2,17,3], skill [24,11,12,25])
		var hero_frames: int = (maxi(1, int(hero_tex.get_width()) / 32) * maxi(1, int(hero_tex.get_height()) / 32)) if hero_tex != null else 4
		var h_frame: int = 0
		if _casting:
			if hero_frames >= 28:
				var sk_seq: Array[int] = [24, 11, 12, 25]
				h_frame = sk_seq[mini(3, int(p * 4.5))] if p < 0.72 else sk_seq[2 + (int(_t * 10.0) % 2)]
			else:
				h_frame = 11 if int(_t * 10.0) % 2 == 0 else 12
		else:
			var idle_seq: Array = [0, 1, 16, 2, 17, 3] if hero_frames >= 28 else [0, 1, 2, 3]
			h_frame = idle_seq[int(_t * 5.0) % idle_seq.size()]
		_draw_frame(hero_tex, hero_pos, 32, 32, h_frame, 1.75, false, skin_modulate)

		# Vũ khí đang cầm theo đúng bậc
		if weap_tex != null:
			var ws: float = 1.35
			var ww := float(weap_tex.get_width()) * ws
			var wh := float(weap_tex.get_height()) * ws
			var swing_off := Vector2(14.0, 2.0) + (Vector2(4.0, -3.0 * sin(_t * 18.0)) if _casting else Vector2.ZERO)
			draw_texture_rect(weap_tex, Rect2(hero_pos + swing_off - Vector2(ww * 0.3, wh * 0.5), Vector2(ww, wh)), false)

		# Hiệu ứng chính của chiêu thức (ưu tiên SkillCastFx cho đủ 22 chiêu)
		if _casting:
			if has_preview_fx:
				sfx_sc.draw_preview_fx(self, sk, hero_pos, dummy_pos, p, _t)
			else:
				match sk:
					"song_trung":
						var twin_pos := base_hero_pos + Vector2(-20.0, -8.0)
						_draw_frame(hero_tex, twin_pos, 32, 32, 11 if int(_t * 10.0) % 2 == 0 else 12, 1.6, false, Color(1.0, 0.72, 0.88, 0.82))
						var wave_tex := Art.tex("fx/sword_wave.png")
						for wi in 2:
							var wp := hero_pos.lerp(dummy_pos, clampf(p * 1.4 - wi * 0.22, 0.0, 1.0)) + Vector2(0, -6.0 + wi * 10.0)
							_draw_frame(wave_tex, wp, 16, 16, int(_t * 14.0), 1.4, false, Color(1.0, 0.84, 0.42))
					"voi_chien":
						var el_tex := Art.tex("fx/elephant.png")
						_draw_frame(el_tex, hero_pos + Vector2(6, -2), 40, 30, int(_t * 14.0), 1.45, false, Color(1.0, 0.96, 0.88, 0.92))
						draw_arc(hero_pos + Vector2(18, 4), 10.0 + p * 22.0, -0.8, 0.8, 12, Color(1.0, 0.84, 0.45, 0.85), 2.0)
					"coc_bach_dang":
						var st_tex := Art.tex("fx/stake.png")
						draw_arc(hero_pos + Vector2(0, 6), 16.0 + fmod(p * 2.5, 1.0) * 38.0, 0.0, TAU, 24, Color(0.45, 0.84, 1.0, 0.7), 1.5)
						for si in 5:
							var ang := -0.7 + float(si) * 0.35
							var sp_pos := hero_pos + Vector2(36.0 + cos(ang) * 28.0, sin(ang) * 24.0)
							_draw_frame(st_tex, sp_pos, 14, 26, 1 if p > 0.18 else 0, 1.15)
					"nam_quoc_son_ha":
						var ring_r := 26.0 + sin(p * PI) * 8.0
						draw_arc(hero_pos, ring_r, 0.0, TAU, 32, Color(1.0, 0.86, 0.35, 0.92), 2.2)
						draw_arc(hero_pos, ring_r - 5.0, _t * 3.0, _t * 3.0 + PI * 1.4, 20, Color(0.55, 0.92, 1.0, 0.7), 1.5)
						var bp: float = fmod(p * 2.0, 1.0)
						var orb := (dummy_pos.lerp(hero_pos + Vector2(ring_r, 0), bp * 2.0) if bp < 0.5 else (hero_pos + Vector2(ring_r, 0)).lerp(dummy_pos, (bp - 0.5) * 2.0))
						draw_circle(orb, 4.0, Color(1.0, 0.38, 0.32) if bp < 0.5 else Color(1.0, 0.9, 0.35))
					"hich_tuong_si":
						var ally_tex := Art.tex("fx/ally.png")
						for ai in 3:
							var ap := (base_hero_pos + Vector2(18.0 + ai * 14.0, -14.0 + ai * 14.0)).lerp(dummy_pos + Vector2(-12.0, -10.0 + ai * 10.0), clampf(p * 1.25 - ai * 0.1, 0.0, 1.0))
							_draw_frame(ally_tex, ap, 18, 20, int(_t * 10.0) + ai, 1.25)
					"thuan_thien_kiem":
						for bi in 3:
							var bang := _t * 6.5 + TAU * float(bi) / 3.0
							var bpos := hero_pos + Vector2(cos(bang) * 32.0, sin(bang) * 20.0)
							draw_line(bpos - Vector2.from_angle(bang) * 6.0, bpos + Vector2.from_angle(bang) * 9.0, Color(1.0, 0.92, 0.42), 2.6)
							draw_circle(bpos + Vector2.from_angle(bang) * 9.0, 2.2, Color(1.0, 1.0, 0.85))
					"than_toc":
						for fi in 4:
							var fpos := base_hero_pos.lerp(hero_pos, float(fi + 1) / 4.0) + Vector2(0, 8.0)
							draw_circle(fpos, 5.5 - float(fi) * 0.7, Color(1.0, 0.52, 0.18, 0.75))
					"hoa_hong":
						var pot_tex := Art.tex("fx/fire_pot.png")
						for hi in 4:
							var hpos := hero_pos.lerp(dummy_pos + Vector2(-12 + hi * 8, -8 + (hi % 2) * 16), clampf(p * 1.3, 0.0, 1.0))
							if p < 0.45 and pot_tex != null:
								draw_texture_rect(pot_tex, Rect2(hpos - Vector2(6, 6), Vector2(12, 12)), false)
							else:
								draw_circle(hpos + Vector2(0, 4), 7.0 + sin(_t * 14.0 + hi) * 2.0, Color(1.0, 0.48, 0.14, 0.75))
								draw_circle(hpos + Vector2(0, 2), 4.0, Color(1.0, 0.88, 0.35, 0.9))
					"hum_thieng":
						var tg_tex := Art.tex("fx/tiger.png")
						var tpos := hero_pos.lerp(dummy_pos + Vector2(12, 0), clampf(p * 1.35, 0.0, 1.0))
						_draw_frame(tg_tex, tpos, 40, 24, int(_t * 14.0), 1.25)
						draw_arc(hero_pos, 14.0 + p * 34.0, -0.9, 0.9, 14, Color(1.0, 0.72, 0.25, 0.7), 2.0)
					"keo_phao":
						var tu_tex := Art.tex("fx/turret.png")
						var tpos := base_hero_pos + Vector2(26.0, 6.0)
						_draw_frame(tu_tex, tpos, 30, 20, 1 if int(_t * 8.0) % 2 == 0 else 0, 1.2)
						var sp: float = fmod(p * 2.4, 1.0)
						var shell := tpos.lerp(dummy_pos, sp) + Vector2(0, -sin(sp * PI) * 14.0)
						draw_circle(shell, 3.2, Color(1.0, 0.85, 0.35))
						if sp > 0.82:
							draw_circle(dummy_pos, 10.0, Color(1.0, 0.52, 0.18, 0.75))
					"ngua_sat":
						var ih_tex := Art.tex("fx/iron_horse.png")
						_draw_frame(ih_tex, hero_pos + Vector2(4, 0), 40, 30, int(_t * 14.0), 1.35)
						for fb in 5:
							var fp: float = clampf(p * 1.6 - float(fb) * 0.1, 0.0, 1.0)
							var fpos := (hero_pos + Vector2(16, -2)).lerp(dummy_pos + Vector2(0, -10.0 + float(fb) * 5.0), fp)
							draw_circle(fpos, 4.5, Color(1.0, 0.45 + 0.1 * fb, 0.15, 0.85))
							draw_circle(fpos, 2.2, Color(1.0, 0.92, 0.45, 0.95))

		# Nhãn nhỏ trạng thái
		var tag_txt: String = "C%d: %s" % [skill_idx, "Đang tung chiêu!" if _casting else "Sẵn sàng"]
		var tag_col: Color = Color(1.0, 0.88, 0.36) if _casting else Color(0.7, 0.74, 0.82)
		Art.draw_text(self, Vector2(size.x * 0.5, 11.0), tag_txt, 10, tag_col)


func _ready() -> void:
	layer = 20
	var top := Control.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.theme = UI.make_theme()
	add_child(top)

	_room_label = UI.label("DOANH TRẠI — ĐẠI SẢNH ANH HÙNG", 18, Color(1, 0.82, 0.3))
	_room_label.position = Vector2(8, 3)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(_room_label)

	_prep_label = UI.label("", 11, Color(0.68, 0.96, 0.78))
	_prep_label.position = Vector2(8, 24)
	_prep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(_prep_label)

	_minimap = LobbyMinimap.new()
	_minimap.lobby = lobby
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-114, 6)
	_minimap.size = Vector2(106, 62)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_minimap)

	_coin_label = UI.label("", 17, Color(1, 0.88, 0.45))
	_coin_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coin_label.position = Vector2(-232, 4)
	_coin_label.size = Vector2(110, 20)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_coin_label)

	_hint_label = UI.label("Nhấp chuột vào vị tướng để xem & Xác nhận  -  Trái/Phải + Enter: Chọn nhanh  -  ESC: Quay lại", 12, Color(0.95, 0.9, 0.8))
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -17.0
	_hint_label.offset_bottom = 0.0
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_hint_label)

	# Biểu ngữ hướng dẫn chọn tướng đặt ở khoảng trống phía nam (không che 11 vị tướng)
	var sb_wrap := CenterContainer.new()
	sb_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sb_wrap.offset_left = 120.0
	sb_wrap.offset_right = -120.0
	sb_wrap.offset_top = -37.0
	sb_wrap.offset_bottom = -19.0
	sb_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sb_wrap)

	_select_banner = PanelContainer.new()
	var sb_st := StyleBoxFlat.new()
	sb_st.bg_color = Color(0.08, 0.04, 0.07, 0.90)
	sb_st.border_color = Color(1.0, 0.84, 0.34, 0.94)
	sb_st.set_border_width_all(1)
	sb_st.set_corner_radius_all(8)
	sb_st.content_margin_left = 12
	sb_st.content_margin_right = 12
	sb_st.content_margin_top = 2
	sb_st.content_margin_bottom = 2
	_select_banner.add_theme_stylebox_override("panel", sb_st)
	_select_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_lbl := UI.label("✨ Nhấp chuột vào vị tướng trên bục để xem & Xác nhận!", 12, Color(1.0, 0.92, 0.42))
	sb_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_banner.add_child(sb_lbl)
	sb_wrap.add_child(_select_banner)

	# Bảng trạng thái phòng LAN (góc trên bên trái, gọn gàng không che Đại Sảnh)
	_lan_panel = PanelContainer.new()
	var lp_st := StyleBoxFlat.new()
	lp_st.bg_color = Color(0.07, 0.04, 0.07, 0.84)
	lp_st.border_color = Color(0.45, 0.82, 1.0, 0.85)
	lp_st.set_border_width_all(1)
	lp_st.set_corner_radius_all(4)
	lp_st.content_margin_left = 8
	lp_st.content_margin_right = 8
	lp_st.content_margin_top = 5
	lp_st.content_margin_bottom = 6
	_lan_panel.add_theme_stylebox_override("panel", lp_st)
	_lan_panel.position = Vector2(8, 44)
	_lan_panel.custom_minimum_size = Vector2(186, 0)
	_lan_panel.visible = false
	top.add_child(_lan_panel)

	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 3)
	_lan_panel.add_child(lv)
	_lan_room_lbl = UI.label("Phòng LAN", 13, Color(1.0, 0.88, 0.42))
	_lan_room_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lv.add_child(_lan_room_lbl)
	_lan_ip_lbl = UI.label("", 11, Color(0.55, 0.92, 1.0))
	_lan_ip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lv.add_child(_lan_ip_lbl)
	_lan_peers_box = VBoxContainer.new()
	_lan_peers_box.add_theme_constant_override("separation", 2)
	lv.add_child(_lan_peers_box)
	var lan_btns := HBoxContainer.new()
	lan_btns.add_theme_constant_override("separation", 5)
	lv.add_child(lan_btns)
	_lan_start_btn = UI.button("Xuất trận", func():
		if lobby != null and lobby.has_method("_start_run"):
			lobby._start_run(), 12, 92.0)
	_lan_start_btn.custom_minimum_size = Vector2(92, 22)
	lan_btns.add_child(_lan_start_btn)
	var lan_leave_btn := UI.button("Rời LAN", func():
		if lobby != null and lobby.has_method("_back_to_menu"):
			lobby._back_to_menu(), 12, 76.0)
	lan_leave_btn.custom_minimum_size = Vector2(76, 22)
	lan_btns.add_child(lan_leave_btn)

	if Net != null and not Net.lobby_updated.is_connected(_refresh_lan_panel):
		Net.lobby_updated.connect(_refresh_lan_panel)
	_refresh_lan_panel()


func _exit_tree() -> void:
	if Net != null and Net.lobby_updated.is_connected(_refresh_lan_panel):
		Net.lobby_updated.disconnect(_refresh_lan_panel)


func _refresh_lan_panel() -> void:
	if _lan_panel == null or not is_instance_valid(_lan_panel):
		return
	var online: bool = Net != null and Net.is_online()
	_lan_panel.visible = online
	if not online:
		return
	var rname: String = Net.room_name if Net.room_name != "" else "Phòng LAN"
	_lan_room_lbl.text = "%s (%d/%d)" % [rname, Net.players.size(), Net.MAX_PLAYERS]
	if Net.is_host():
		var ips: PackedStringArray = Net.local_lan_ips()
		var ip_txt: String = ips[0] if not ips.is_empty() else "127.0.0.1"
		_lan_ip_lbl.text = "IP: %s:%d" % [ip_txt, Net.DEFAULT_PORT]
	else:
		_lan_ip_lbl.text = "Ping: %dms" % Net.ping_ms
	for c in _lan_peers_box.get_children():
		c.queue_free()
	var list: Array = Net.players.values()
	list.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("slot_idx", 0)) < int((b as Dictionary).get("slot_idx", 0)))
	for item in list:
		var info: Dictionary = item
		var pid: int = int(info.get("id", 0))
		var pname: String = str(info.get("name", "Anh Hùng"))
		var hid: String = str(info.get("hero", "ngo_quyen"))
		var hname: String = str(HeroData.DATA[hid].name) if HeroData.DATA.has(hid) else hid
		var pet_id: String = str(info.get("pet", ""))
		var confirmed: bool = bool(info.get("hero_confirmed", false))
		var col: Color = info.get("color", Color(1.0, 0.88, 0.35))
		var host_tag: String = " [Chủ]" if pid == 1 else ""
		var pet_tag: String = (" • " + str(Global.PETS[pet_id].name)) if (pet_id != "" and Global.PETS.has(pet_id)) else ""
		var st_icon: String = "✓" if confirmed else "…"
		var line := "%s ● %s%s\n   %s%s" % [st_icon, pname, host_tag, hname if confirmed else "Đang chọn...", pet_tag]
		var lb := UI.label(line, 11, col if confirmed else Color(0.8, 0.78, 0.72))
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_lan_peers_box.add_child(lb)
	var all_ok: bool = Net.all_peers_confirmed()
	_lan_start_btn.visible = Net.is_host()
	_lan_start_btn.disabled = not all_ok
	_lan_start_btn.text = "Xuất trận" if all_ok else "Chờ xác nhận"


func _process(_delta: float) -> void:
	_coin_label.text = "Xu: %d" % Global.coins
	var confirmed: bool = lobby == null or bool(lobby.get("hero_confirmed"))
	if _select_banner != null:
		_select_banner.visible = (not confirmed) and (not is_open())
	if _hint_label != null:
		if not confirmed:
			_hint_label.text = "Nhấp chuột vào vị tướng trong Đại Sảnh để chọn & Xác nhận  -  Mũi tên + Enter: Chọn nhanh  -  ESC: Quay lại"
		else:
			_hint_label.text = "WASD: đi quanh 4 phòng  -  Lăn chuột / Q: đổi vũ khí  -  E: tương tác  -  Cổng Bắc để xuất trận"
	if lobby != null and lobby.player != null and is_instance_valid(lobby.player):
		if not confirmed:
			_room_label.text = "DOANH TRẠI — CHỌN TƯỚNG XUẤT TRẬN"
		else:
			var rm: Dictionary = lobby.room_at(lobby.player.global_position)
			var rname: String = str(rm.get("name", "Doanh Trại Anh Hùng"))
			_room_label.text = "DOANH TRẠI — %s" % rname.to_upper()
		if _minimap != null:
			_minimap.lobby = lobby
			_minimap.queue_redraw()
	if _prep_label != null:
		var tags: PackedStringArray = []
		if Global.lobby_drink != "" and Global.LOBBY_DRINKS.has(Global.lobby_drink):
			tags.append("Trà: %s" % str(Global.LOBBY_DRINKS[Global.lobby_drink].name))
		if Global.lobby_weapon_mod != "" and WeaponMods.DATA.has(Global.lobby_weapon_mod):
			tags.append("Bùa: %s" % WeaponMods.mod_name(Global.lobby_weapon_mod))
		if Global.lobby_shrine_buff != "" and Global.SHRINE_BLESSINGS.has(Global.lobby_shrine_buff):
			tags.append(str(Global.SHRINE_BLESSINGS[Global.lobby_shrine_buff].name))
		if not Global.lobby_garden_buffs.is_empty():
			tags.append("Thảo dược x%d" % Global.lobby_garden_buffs.size())
		if Global.selected_pet != "" and Global.PETS.has(Global.selected_pet):
			tags.append("Linh thú: %s" % str(Global.PETS[Global.selected_pet].name))
		if Global.badass_mode:
			tags.append("Ác Mộng")
		if _hao_khi_level() > 0:
			tags.append("Hào Khí %d" % _hao_khi_level())
		if Global.pending_run_mode == "boss_rush":
			tags.append("Boss Rush")
		elif Global.pending_run_mode == "co_loa":
			tags.append("Cổ Loa")
		if not Global.pending_mutators.is_empty():
			tags.append("Biến số x%d" % Global.pending_mutators.size())
		if Global.pending_challenge_code != "":
			tags.append("Mã: %s" % Global.pending_challenge_code)
		_prep_label.text = "Chuẩn bị: %s" % " | ".join(tags) if not tags.is_empty() else ""


func is_open() -> bool:
	return _panel != null


func _unhandled_input(event: InputEvent) -> void:
	if _panel != null and event.is_action_pressed("pause"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		close()


func _begin(title: String) -> VBoxContainer:
	close()
	if lobby != null and is_instance_valid(lobby):
		lobby.set_player_active(false)
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.theme = UI.make_theme()
	add_child(_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(c)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png"))
	c.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)
	box.add_child(UI.label(title, 26, Color(1, 0.85, 0.4)))
	return box


func _end(box: VBoxContainer) -> void:
	box.add_child(UI.center(UI.button("Đóng", close, 18, 140.0)))


func close() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
	if lobby != null and is_instance_valid(lobby):
		lobby.set_player_active(true)


# ------------------------------------------------------------------ Tướng

func _do_train_hero(id: String) -> void:
	if Global.try_upgrade_hero(id):
		Sfx.play("forge")
		if lobby != null:
			lobby.on_progressed(id, "Cấp %d!" % Global.hero_level(id))
		open_hero(id, "train")


func _do_train_weapon(id: String) -> void:
	if Global.try_upgrade_weapon(id):
		Sfx.play("forge")
		if lobby != null:
			var r: int = Global.weapon_rank(id)
			lobby.on_progressed(id, "Thức tỉnh!" if r >= 5 else "Bậc %d!" % r)
		open_hero(id, "train")


func _add_cost_row(parent: Control, coins_need: int, mats: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	for mid in MaterialData.ORDER:
		if not mats.has(mid):
			continue
		var need: int = int(mats[mid])
		var have: int = Global.material_count(str(mid))
		var ok: bool = have >= need
		var mc := HBoxContainer.new()
		mc.add_theme_constant_override("separation", 2)
		mc.add_child(_mat_icon(str(mid), 11.0))
		mc.add_child(UI.label("%d/%d" % [have, need], 12, Color(0.88, 0.92, 0.88) if ok else Color(1, 0.35, 0.35)))
		row.add_child(mc)
	var ok_c: bool = Global.coins >= coins_need
	row.add_child(UI.label("%d xu" % coins_need, 12, Color(1, 0.88, 0.45) if ok_c else Color(1, 0.35, 0.35)))


func open_hero(id: String, tab: String = "info", preview_rank: int = -1) -> void:
	var h: Dictionary = HeroData.DATA[id]
	var unlocked: bool = lobby._is_hero_unlocked(id) if (lobby != null and lobby.has_method("_is_hero_unlocked")) else Global.unlocked.has(id)
	if not unlocked and tab == "train":
		tab = "info"
	var box := _begin(h.name)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var b_info := UI.button("Thông tin", open_hero.bind(id, "info", preview_rank), 13, 110.0)
	b_info.disabled = (tab == "info")
	tabs.add_child(b_info)
	var b_show := UI.button("Chiêu & Bậc vũ khí", open_hero.bind(id, "showcase", preview_rank), 13, 155.0)
	b_show.disabled = (tab == "showcase")
	tabs.add_child(b_show)
	if unlocked:
		var b_tr := UI.button("Tu luyện", open_hero.bind(id, "train", preview_rank), 13, 110.0)
		b_tr.disabled = (tab == "train")
		tabs.add_child(b_tr)
	if tab == "showcase":
		box.add_theme_constant_override("separation", 3)
		var sel_rank: int = clampi(preview_rank if preview_rank >= 1 else Global.weapon_rank(id), 1, 5)
		var wid: String = str(h.weapon)
		var base_w: Dictionary = WeaponData.get_data(wid)
		var ranked: Dictionary = ProgressionData.apply_weapon_rank(wid, base_w, sel_rank)
		var tr_w: Dictionary = ProgressionData.TRAITS.get(wid, {})

		# Hàng trên: Sân khấu hoạt ảnh tung chiêu + mô tả chiêu
		var sk_idx_s: int = Global.active_skill_index(id)
		var sk_info_s: Dictionary = HeroData.skill_info(id, sk_idx_s)
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)
		box.add_child(top_row)
		var preview := HeroSkillPreview.new()
		preview.custom_minimum_size = Vector2(204, 72)
		preview.setup(id, sel_rank, sk_idx_s)
		top_row.add_child(preview)

		var sk_box := VBoxContainer.new()
		sk_box.custom_minimum_size = Vector2(286, 0)
		sk_box.add_theme_constant_override("separation", 2)
		top_row.add_child(sk_box)
		var sk_hdr := HBoxContainer.new()
		sk_hdr.add_theme_constant_override("separation", 5)
		sk_box.add_child(sk_hdr)
		var sk_t := UI.label("%s (Hồi %.0fs)" % [str(sk_info_s.get("skill_name", h.skill_name)), float(sk_info_s.get("skill_cd", h.skill_cd))], 12, Color(0.6, 0.9, 1.0))
		sk_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sk_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sk_hdr.add_child(sk_t)
		var b_sk1_s := UI.button("C1", func():
			Global.set_skill_index(id, 1)
			open_hero(id, "showcase", sel_rank), 11, 30.0)
		b_sk1_s.disabled = (sk_idx_s == 1)
		sk_hdr.add_child(b_sk1_s)
		var b_sk2_s := UI.button("C2", func():
			Global.set_skill_index(id, 2)
			open_hero(id, "showcase", sel_rank), 11, 30.0)
		b_sk2_s.disabled = (sk_idx_s == 2)
		sk_hdr.add_child(b_sk2_s)
		sk_hdr.add_child(UI.button("▶ Xem", preview.replay, 11, 62.0))
		var sk_d := UI.label(str(sk_info_s.get("skill_desc", h.skill_desc)), 11, Color(0.92, 0.9, 0.86), true)
		sk_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sk_box.add_child(sk_d)

		# Chọn từng bậc 1 -> 5
		var rank_bar := HBoxContainer.new()
		rank_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		rank_bar.add_theme_constant_override("separation", 5)
		box.add_child(rank_bar)
		var owned_r: int = Global.weapon_rank(id) if unlocked else 0
		for r_i in range(1, 6):
			var r_lbl: String = ("Bậc 5 ★★" if r_i == 5 else ("Bậc 3 ★" if r_i == 3 else "Bậc %d" % r_i))
			if r_i == owned_r:
				r_lbl += " ✓"
			var rb := UI.button(r_lbl, open_hero.bind(id, "showcase", r_i), 11, 86.0)
			rb.disabled = (r_i == sel_rank)
			rank_bar.add_child(rb)

		# 3 cấp ngoại hình vũ khí đặt cạnh nhau (Bậc 1-2, Bậc 3-4, Bậc 5)
		var evo_row := HBoxContainer.new()
		evo_row.alignment = BoxContainer.ALIGNMENT_CENTER
		evo_row.add_theme_constant_override("separation", 8)
		box.add_child(evo_row)
		var tiers: Array[Dictionary] = [
			{"label": "Bậc 1–2: Nguyên bản", "tex_r": 1, "min_r": 1, "max_r": 2, "col": Color(0.84, 0.86, 0.9)},
			{"label": "Bậc 3–4: Khắc văn", "tex_r": 3, "min_r": 3, "max_r": 4, "col": Color(0.45, 0.86, 1.0)},
			{"label": "Bậc 5: Thức tỉnh ★", "tex_r": 5, "min_r": 5, "max_r": 5, "col": Color(1.0, 0.86, 0.35)},
		]
		for td in tiers:
			var is_cur_group: bool = sel_rank >= int(td.min_r) and sel_rank <= int(td.max_r)
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if is_cur_group else "ui/panel.png"))
			card.custom_minimum_size = Vector2(158, 0)
			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 0)
			var icon := TextureRect.new()
			icon.texture = Art.tex(ProgressionData.weapon_texture_path(wid, int(td.tex_r)))
			icon.custom_minimum_size = Vector2(42, 16)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cv.add_child(UI.center(icon))
			cv.add_child(UI.label(str(td.label), 10, td.col))
			card.add_child(cv)
			evo_row.add_child(card)

		# Chi tiết chỉ số & đặc tính của bậc đang xem
		var stat_card := PanelContainer.new()
		stat_card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
		box.add_child(stat_card)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 1)
		stat_card.add_child(sv)
		var r_info: Dictionary = ProgressionData.WEAPON_RANKS[sel_rank]
		var own_tag: String = "  (Đang sở hữu)" if (unlocked and Global.weapon_rank(id) == sel_rank) else ""
		var st_hdr := HBoxContainer.new()
		st_hdr.add_theme_constant_override("separation", 8)
		sv.add_child(st_hdr)
		var st_title := UI.label("%s — %s%s" % [str(base_w.get("name", wid)), str(r_info.name), own_tag], 12, Color(1.0, 0.88, 0.38) if sel_rank >= 5 else Color(0.78, 0.92, 1.0))
		st_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		st_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_hdr.add_child(st_title)
		if sel_rank > 1:
			_add_cost_row(st_hdr, int(r_info.coins), r_info.mats)
		var extra_stat: String = ""
		if ranked.has("reach"):
			extra_stat = "  |  Tầm: %d" % int(round(float(ranked.reach)))
		elif int(ranked.get("pierce", 0)) > 0 or int(ranked.get("count", 1)) > 1:
			extra_stat = "  |  Xuyên: %d  |  Đạn: %d" % [int(ranked.get("pierce", 0)), int(ranked.get("count", 1))]
		elif ranked.has("life") and str(base_w.get("proj", "")) == "fireball":
			extra_stat = "  |  Tầm phun: %.2fs" % float(ranked.life)
		var st_line := UI.label("Sát thương: %d (×%.2f)  |  Hồi đòn: %.2fs%s" % [int(ranked.get("damage", 1)), float(r_info.dmg_mult), float(ranked.get("cooldown", 0.3)), extra_stat], 11, Color(0.95, 0.92, 0.86))
		st_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sv.add_child(st_line)
		if not tr_w.is_empty():
			var d1_on: bool = sel_rank >= 3
			var d2_on: bool = sel_rank >= 5
			var l1 := UI.label(("✓ Đ1 (Bậc 3): " if d1_on else "○ Đ1 (Bậc 3): ") + str(tr_w.d1), 10, Color(0.58, 0.95, 0.68) if d1_on else Color(0.62, 0.64, 0.68))
			l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			sv.add_child(l1)
			var l2 := UI.label(("★ Đ2 (Bậc 5): " if d2_on else "○ Đ2 (Bậc 5): ") + str(tr_w.d2), 10, Color(1.0, 0.88, 0.38) if d2_on else Color(0.62, 0.64, 0.68))
			l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			sv.add_child(l2)

		var sh_btns := HBoxContainer.new()
		sh_btns.alignment = BoxContainer.ALIGNMENT_CENTER
		sh_btns.add_theme_constant_override("separation", 10)
		box.add_child(sh_btns)
		if unlocked:
			sh_btns.add_child(UI.button("Xác nhận tướng", func():
				lobby.confirm_hero(id)
				close(), 14, 150.0))
			sh_btns.add_child(UI.button("Sang Tu luyện", open_hero.bind(id, "train", sel_rank), 14, 140.0))
		elif Net != null and Net.is_online() and not Net.is_host():
			var b_lk := UI.button("Chủ phòng chưa mở", func(): pass, 14, 165.0)
			b_lk.disabled = true
			sh_btns.add_child(b_lk)
		else:
			sh_btns.add_child(UI.button("Mở khóa: %d xu" % h.cost, func():
				if Global.try_unlock(id):
					lobby.confirm_hero(id)
					close(), 14, 160.0))
		sh_btns.add_child(UI.button("Đóng", close, 14, 110.0))
		return
	if tab == "train":
		var inv := HBoxContainer.new()
		inv.alignment = BoxContainer.ALIGNMENT_CENTER
		inv.add_theme_constant_override("separation", 8)
		box.add_child(inv)
		inv.add_child(UI.label("Xu: %d" % Global.coins, 13, Color(1, 0.88, 0.45)))
		for mid in MaterialData.ORDER:
			var md: Dictionary = MaterialData.DATA[mid]
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 3)
			cell.add_child(_mat_icon(str(mid), 12.0))
			var cnt: int = Global.material_count(str(mid))
			cell.add_child(UI.label(str(cnt), 13, md.color if cnt > 0 else Color(0.55, 0.55, 0.55)))
			inv.add_child(cell)
		# Phần 1: Tu luyện tướng
		var hlv: int = Global.hero_level(id)
		var sec1 := PanelContainer.new()
		sec1.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
		box.add_child(sec1)
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 10)
		sec1.add_child(hrow)
		var hleft := VBoxContainer.new()
		hleft.custom_minimum_size = Vector2(360, 0)
		hleft.add_theme_constant_override("separation", 2)
		hrow.add_child(hleft)
		var t1 := UI.label("Tu luyện tướng  -  Cấp %d / 5" % hlv, 15, Color(1, 0.86, 0.4))
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hleft.add_child(t1)
		if hlv >= 5:
			var done1 := UI.label("Cấp tối đa: +1 máu, +1 giáp, +30 năng lượng, hồi chiêu ×0,85.", 12, Color(0.6, 0.95, 0.6), true)
			done1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			hleft.add_child(done1)
			var bmax1 := UI.button("Đã viên mãn", func(): pass, 13, 130.0)
			bmax1.disabled = true
			hrow.add_child(bmax1)
		else:
			var nh: Dictionary = ProgressionData.HERO_LEVELS[hlv + 1]
			var d1 := UI.label("Cấp %d: %s" % [hlv + 1, str(nh.desc)], 12, Color(0.9, 0.9, 0.88), true)
			d1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			hleft.add_child(d1)
			_add_cost_row(hleft, int(nh.coins), nh.mats)
			var bh := UI.button("Tu luyện", _do_train_hero.bind(id), 14, 130.0)
			bh.disabled = not Global.can_upgrade_hero(id)
			hrow.add_child(bh)
		# Phần 2: Binh khí khởi đầu
		var wr: int = Global.weapon_rank(id)
		var wid: String = str(h.weapon)
		var wd: Dictionary = WeaponData.get_data(wid)
		var tr: Dictionary = ProgressionData.TRAITS.get(wid, {})
		var sec2 := PanelContainer.new()
		sec2.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
		box.add_child(sec2)
		var wrow := HBoxContainer.new()
		wrow.add_theme_constant_override("separation", 10)
		sec2.add_child(wrow)
		var wleft := VBoxContainer.new()
		wleft.custom_minimum_size = Vector2(360, 0)
		wleft.add_theme_constant_override("separation", 2)
		wrow.add_child(wleft)
		var wtitle := HBoxContainer.new()
		wtitle.add_theme_constant_override("separation", 6)
		var wpic := TextureRect.new()
		wpic.texture = Art.tex(ProgressionData.weapon_texture_path(wid, wr))
		wpic.custom_minimum_size = Vector2(28, 16)
		wpic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wpic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wtitle.add_child(wpic)
		wtitle.add_child(UI.label("Binh khí: %s  (%s)" % [wd.name, "Thức tỉnh" if wr >= 5 else "Bậc %d / 5" % wr], 15, Color(1.0, 0.85, 0.35) if wr >= 5 else Color(0.75, 0.9, 1.0)))
		wleft.add_child(wtitle)
		if not tr.is_empty():
			var tr_line := "Đ1: %s  |  Đ2: %s" % [str(tr.d1), str(tr.d2)]
			var tl := UI.label(tr_line, 11, Color(0.82, 0.86, 0.92), true)
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			wleft.add_child(tl)
		if wr >= 5:
			var done2 := UI.label("Sát thương ×2,2, hồi đòn ×0,85, đủ 2 Đặc tính.", 12, Color(0.6, 0.95, 0.6), true)
			done2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			wleft.add_child(done2)
			var bmax2 := UI.button("Đã thức tỉnh", func(): pass, 13, 130.0)
			bmax2.disabled = true
			wrow.add_child(bmax2)
		else:
			var nw: Dictionary = ProgressionData.WEAPON_RANKS[wr + 1]
			var d2 := UI.label("Lên bậc %d: %s" % [wr + 1, str(nw.desc)], 12, Color(0.9, 0.9, 0.88), true)
			d2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			wleft.add_child(d2)
			_add_cost_row(wleft, int(nw.coins), nw.mats)
			var bw := UI.button("Rèn binh khí", _do_train_weapon.bind(id), 14, 130.0)
			bw.disabled = not Global.can_upgrade_weapon(id)
			wrow.add_child(bw)
		_end(box)
		return
	box.add_theme_constant_override("separation", 3)
	if _preview_skin_hero != id:
		_preview_skin_hero = id
		_preview_skin_id = _get_selected_skin_id(id)
	var skins_list: Array = HeroSkins.skins_for(id)
	var cur_skin_id: String = _preview_skin_id if _preview_skin_id != "" else _get_selected_skin_id(id)
	var cur_skin: Dictionary = HeroSkins.get_skin(id, cur_skin_id)
	var cur_skin_mod: Color = cur_skin.get("modulate", Color.WHITE) as Color
	var cur_skin_unlocked: bool = _is_skin_unlocked(id, str(cur_skin.get("id", HeroSkins.DEFAULT_SKIN)))
	var cur_skin_active: bool = (_get_selected_skin_id(id) == str(cur_skin.get("id", HeroSkins.DEFAULT_SKIN)))
	var cur_skin_cost: int = int(cur_skin.get("cost", 0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 3)
	row.add_child(left_col)
	var sk_idx: int = Global.active_skill_index(id)
	var info_preview := HeroSkillPreview.new()
	info_preview.custom_minimum_size = Vector2(138, 82)
	info_preview.setup(id, Global.weapon_rank(id), sk_idx, cur_skin_mod)
	left_col.add_child(info_preview)
	var sk_pv_row := HBoxContainer.new()
	sk_pv_row.add_theme_constant_override("separation", 4)
	left_col.add_child(sk_pv_row)
	var pv_c1 := UI.button("C1", func():
		Global.set_skill_index(id, 1)
		open_hero(id, "info", preview_rank), 11, 34.0)
	pv_c1.disabled = (sk_idx == 1)
	sk_pv_row.add_child(pv_c1)
	var pv_c2 := UI.button("C2", func():
		Global.set_skill_index(id, 2)
		open_hero(id, "info", preview_rank), 11, 34.0)
	pv_c2.disabled = (sk_idx == 2)
	sk_pv_row.add_child(pv_c2)
	sk_pv_row.add_child(UI.button("▶ Xem", info_preview.replay, 11, 62.0))
	left_col.add_child(UI.button("5 bậc vũ khí", open_hero.bind(id, "showcase", Global.weapon_rank(id)), 12, 138.0))

	var skin_col: Color = cur_skin.get("aura_color", Color(1.0, 0.88, 0.42)) as Color
	var skin_lbl := UI.label("Trang phục: %s" % str(cur_skin.get("name", "Mặc định")), 10, skin_col, true)
	skin_lbl.custom_minimum_size = Vector2(138, 0)
	left_col.add_child(skin_lbl)
	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 4)
	left_col.add_child(skin_row)
	var b_next_skin := UI.button("Đổi áo (%d)" % skins_list.size(), func():
		var nxt_sid: String = HeroSkins.next_skin_id(id, cur_skin_id)
		_preview_skin_hero = id
		_preview_skin_id = nxt_sid
		if unlocked and _is_skin_unlocked(id, nxt_sid) and Global.has_method("select_skin"):
			Global.call("select_skin", id, nxt_sid)
			if Net != null and Net.is_online() and Net.has_method("request_set_skin"):
				Net.call("request_set_skin", nxt_sid)
			if lobby != null and lobby.has_method("refresh_hero_appearance"):
				lobby.refresh_hero_appearance(id)
		open_hero(id, "info", preview_rank), 10, 68.0)
	skin_row.add_child(b_next_skin)
	var skin_act_txt: String = "Đang mặc" if cur_skin_active else ("Chọn" if cur_skin_unlocked else "Mở %dx" % cur_skin_cost)
	var b_skin_act := UI.button(skin_act_txt, func():
		var target_sid: String = str(cur_skin.get("id", HeroSkins.DEFAULT_SKIN))
		if not unlocked:
			return
		var ok := false
		if cur_skin_unlocked:
			if Global.has_method("select_skin"):
				Global.call("select_skin", id, target_sid)
				ok = true
		elif Global.has_method("unlock_and_select_skin"):
			ok = bool(Global.call("unlock_and_select_skin", id, target_sid))
		if ok:
			if Sfx != null:
				Sfx.play("buy" if not cur_skin_unlocked else "pickup_weapon")
			if Net != null and Net.is_online() and Net.has_method("request_set_skin"):
				Net.call("request_set_skin", target_sid)
			if lobby != null and lobby.has_method("refresh_hero_appearance"):
				lobby.refresh_hero_appearance(id)
			open_hero(id, "info", preview_rank), 10, 66.0)
	b_skin_act.disabled = (not unlocked) or cur_skin_active or (not cur_skin_unlocked and Global.coins < cur_skin_cost)
	if not cur_skin_unlocked and unlocked:
		b_skin_act.modulate = Color(1.0, 0.88, 0.42)
	skin_row.add_child(b_skin_act)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(360, 0)
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var w := WeaponData.get_data(h.weapon)
	var fam: String = SynergyData.family(h.weapon)
	var sig: String = SynergyData.signature_for(id)
	var hd: Dictionary = SynergyData.HERO_DESC.get(id, {})
	var hlv2: int = Global.hero_level(id)
	var wr2: int = Global.weapon_rank(id)
	var hb2: Dictionary = ProgressionData.hero_bonuses(hlv2)
	var passive: Dictionary = HeroData.passive_info(id)
	var sk1: Dictionary = HeroData.skill_info(id, 1)
	var sk2: Dictionary = HeroData.skill_info(id, 2)
	var cur_sk: Dictionary = sk2 if sk_idx == 2 else sk1
	var lines: Array = [
		UI.label(h.era, 13, Color(0.85, 0.8, 0.75)),
		UI.label("Khởi đầu: %s Bậc %d [%s]" % [w.name, wr2, SynergyData.family_name(fam)], 13, Color(0.9, 0.9, 0.95)),
	]
	if sig != "" and WeaponData.DATA.has(sig):
		lines.append(UI.label("Định mệnh (★★): %s" % WeaponData.DATA[sig].name, 12, Color(1.0, 0.85, 0.35)))
	if not passive.is_empty():
		lines.append(UI.label("Nội tại (%s): %s" % [str(passive.get("name", "")), str(passive.get("desc", ""))], 11, Color(0.58, 0.96, 0.78), true))
	for l in lines:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(l)
	var sk_toggle_row := HBoxContainer.new()
	sk_toggle_row.add_theme_constant_override("separation", 6)
	info.add_child(sk_toggle_row)
	var btn_sk1 := UI.button("Chiêu 1: %s%s" % [str(sk1.get("skill_name", h.skill_name)), " ✓" if sk_idx == 1 else ""], func():
		Global.set_skill_index(id, 1)
		open_hero(id, "info", preview_rank), 11, 174.0)
	btn_sk1.custom_minimum_size = Vector2(174, 24)
	btn_sk1.disabled = (sk_idx == 1)
	btn_sk1.modulate = Color(1.0, 0.92, 0.45) if sk_idx == 1 else Color(0.82, 0.84, 0.9)
	sk_toggle_row.add_child(btn_sk1)
	var btn_sk2 := UI.button("Chiêu 2: %s%s" % [str(sk2.get("skill_name", "Chiêu 2")), " ✓" if sk_idx == 2 else ""], func():
		Global.set_skill_index(id, 2)
		open_hero(id, "info", preview_rank), 11, 174.0)
	btn_sk2.custom_minimum_size = Vector2(174, 24)
	btn_sk2.disabled = (sk_idx == 2)
	btn_sk2.modulate = Color(1.0, 0.92, 0.45) if sk_idx == 2 else Color(0.82, 0.84, 0.9)
	sk_toggle_row.add_child(btn_sk2)
	var lines2: Array = [
		UI.label("Chiêu %d: %s (Hồi %.0fs)" % [sk_idx, str(cur_sk.get("skill_name", h.skill_name)), float(cur_sk.get("skill_cd", h.skill_cd))], 13, Color(0.6, 0.88, 1.0)),
		UI.label(str(cur_sk.get("skill_desc", h.skill_desc)), 11, Color(0.9, 0.88, 0.85), true),
	]
	if not hd.is_empty():
		lines2.append(UI.label("★ Cùng hệ: %s" % str(hd.get("lv1", "")), 11, Color(0.84, 0.88, 0.96), true))
		lines2.append(UI.label("★★ Tâm đắc: %s" % str(hd.get("lv2", "")), 11, Color(1.0, 0.88, 0.38), true))
	lines2.append(UI.label("Cấp %d  |  Máu %d   Giáp %d   Năng lượng %d" % [hlv2, int(h.hp) + int(hb2.hp), int(h.armor) + int(hb2.armor), int(h.energy) + int(hb2.energy)], 12, Color(0.95, 0.8, 0.65)))
	if not unlocked:
		lines2.append(UI.label("Cần mở khóa tướng để tu luyện.", 11, Color(0.85, 0.7, 0.65)))
	for l2 in lines2:
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(l2)
	var msg := UI.label("", 12, Color(1, 0.6, 0.5))
	box.add_child(msg)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	box.add_child(btns)
	if unlocked:
		btns.add_child(UI.button("Xác nhận tướng", func():
			lobby.confirm_hero(id)
			close(), 18, 180.0))
	elif Net != null and Net.is_online() and not Net.is_host():
		var b_lk2 := UI.button("Chủ phòng chưa mở", func(): pass, 16, 190.0)
		b_lk2.disabled = true
		btns.add_child(b_lk2)
	else:
		btns.add_child(UI.button("Mở khóa: %d xu" % h.cost, func():
			if Global.try_unlock(id):
				lobby.confirm_hero(id)
				close()
			else:
				msg.text = "Chưa đủ xu. Hãy xuất trận để kiếm thêm!", 18, 180.0))
	btns.add_child(UI.button("Đóng", close, 18, 120.0))


# ------------------------------------------------------------------ Lò rèn

func _mat_icon(mid: String, px: float = 12.0) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = Art.tex(MaterialData.DATA[mid].icon)
	icon.custom_minimum_size = Vector2(px, px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _preview_weapon_sfx(wid: String, w: Dictionary) -> void:
	if Sfx != null and Sfx.has_method("play_weapon"):
		Sfx.play_weapon(wid, w)
	elif Sfx != null:
		Sfx.play("ui_click")


func _do_craft(wid: String, tier_filter: int = 0) -> void:
	if Global.try_craft(wid):
		Sfx.play("forge")
		if lobby != null:
			lobby.on_forged()
		open_forge("craft", tier_filter)


func open_forge(tab: String = "upgrade", tier_filter: int = 0) -> void:
	var title := "Lò rèn - Nâng cấp vĩnh viễn" if tab == "upgrade" else "Lò rèn - Rèn binh khí"
	var box := _begin(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	var b_up := UI.button("Nâng cấp", open_forge.bind("upgrade", 0), 14, 120.0)
	b_up.disabled = (tab == "upgrade")
	var b_cr := UI.button("Rèn binh khí", open_forge.bind("craft", tier_filter), 14, 130.0)
	b_cr.disabled = (tab == "craft")
	tabs.add_child(b_up)
	tabs.add_child(b_cr)
	if tab == "upgrade":
		box.add_child(UI.label("Xu hiện có: %d" % Global.coins, 16, Color(1, 0.88, 0.45)))
		for id in Global.UPGRADES:
			var u: Dictionary = Global.UPGRADES[id]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			box.add_child(row)
			var lv := Global.upgrade(id)
			var name_l := UI.label("%s  (%d/%d)" % [u.name, lv, int(u.max)], 17, Color(1, 0.9, 0.6))
			name_l.custom_minimum_size = Vector2(180, 0)
			name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(name_l)
			var d := UI.label(u.desc, 14, Color(0.9, 0.88, 0.85))
			d.custom_minimum_size = Vector2(220, 0)
			d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(d)
			if lv >= int(u.max):
				row.add_child(UI.label("Đã tối đa", 15, Color(0.6, 0.9, 0.6)))
			else:
				row.add_child(UI.button("%d xu" % Global.upgrade_cost(id), func():
					if Global.try_upgrade(id):
						open_forge("upgrade", 0), 15, 100.0))
	else:
		var inv := HBoxContainer.new()
		inv.alignment = BoxContainer.ALIGNMENT_CENTER
		inv.add_theme_constant_override("separation", 8)
		box.add_child(inv)
		inv.add_child(UI.label("Xu: %d" % Global.coins, 13, Color(1, 0.88, 0.45)))
		for mid in MaterialData.ORDER:
			var md: Dictionary = MaterialData.DATA[mid]
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 3)
			cell.add_child(_mat_icon(str(mid), 13.0))
			var cnt: int = Global.material_count(str(mid))
			var col: Color = md.color if cnt > 0 else Color(0.55, 0.55, 0.55)
			cell.add_child(UI.label(str(cnt), 13, col))
			inv.add_child(cell)
		var fbar := HBoxContainer.new()
		fbar.alignment = BoxContainer.ALIGNMENT_CENTER
		fbar.add_theme_constant_override("separation", 5)
		box.add_child(fbar)
		var fb_all := UI.button("Tất cả", open_forge.bind("craft", 0), 11, 64.0)
		fb_all.disabled = (tier_filter == 0)
		fbar.add_child(fb_all)
		for t_i in range(1, 6):
			var fb := UI.button("Cấp %d" % t_i, open_forge.bind("craft", t_i), 11, 56.0)
			fb.disabled = (tier_filter == t_i)
			fb.modulate = WeaponData.TIER_COLORS[t_i] if tier_filter == t_i else Color(0.86, 0.86, 0.9)
			fbar.add_child(fb)
		if Global.forged != "" and WeaponData.DATA.has(Global.forged):
			var pend := HBoxContainer.new()
			pend.alignment = BoxContainer.ALIGNMENT_CENTER
			pend.add_theme_constant_override("separation", 6)
			var pw := TextureRect.new()
			pw.texture = Art.tex("weapons/%s.png" % Global.forged)
			pw.custom_minimum_size = Vector2(24, 14)
			pw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pend.add_child(UI.label("Chờ ra trận:", 13, Color(0.65, 0.95, 0.65)))
			pend.add_child(pw)
			pend.add_child(UI.label(WeaponData.DATA[Global.forged].name, 13, WeaponData.tier_color(Global.forged)))
			box.add_child(pend)
		var wids: Array = Global.forgeable_weapons().duplicate()
		for tier_key in ["basic", "advanced"]:
			var bp_arr: Array = AchievementData.BLUEPRINT_TIERS.get(tier_key, [])
			for bp_v in bp_arr:
				var bp_wid: String = str(bp_v)
				if WeaponData.DATA.has(bp_wid) and MaterialData.can_forge_weapon(bp_wid) and not wids.has(bp_wid):
					wids.append(bp_wid)
		var filtered_wids: Array = []
		for wid_v in wids:
			var wid_s: String = str(wid_v)
			if tier_filter > 0 and int(WeaponData.DATA.get(wid_s, {}).get("tier", 1)) != tier_filter:
				continue
			filtered_wids.append(wid_s)
		if filtered_wids.is_empty():
			var empty_msg := "Chưa có bản vẽ. Hãy ghép bản vẽ ở Bàn Bản Vẽ hoặc mở trong hầm ngục!" if wids.is_empty() else "Không có công thức Cấp %d đã mở." % tier_filter
			box.add_child(UI.label(empty_msg, 13, Color(0.85, 0.82, 0.78)))
		else:
			var scroll := ScrollContainer.new()
			scroll.custom_minimum_size = Vector2(582, 146)
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			box.add_child(scroll)
			var list := VBoxContainer.new()
			list.add_theme_constant_override("separation", 4)
			scroll.add_child(list)
			for wid in filtered_wids:
				var wid_s: String = str(wid)
				var w: Dictionary = WeaponData.DATA[wid_s]
				var rec: Dictionary = MaterialData.recipe_for(wid_s)
				var req_bp: bool = MaterialData.is_achievement_blueprint(wid_s)
				var has_bp: bool = Global.owns_blueprint(wid_s)
				var can_asm: bool = Global.can_assemble_blueprint(wid_s)
				var need_frags: int = Global.fragments_needed(wid_s)
				var have_frags: int = Global.fragment_count(wid_s)
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 4)
				list.add_child(row)
				var wicon := TextureRect.new()
				wicon.texture = Art.tex("weapons/%s.png" % wid_s)
				wicon.custom_minimum_size = Vector2(24, 16)
				wicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				wicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				if not has_bp:
					wicon.modulate = Color(0.65, 0.65, 0.72, 0.9) if can_asm else Color(0.55, 0.55, 0.62, 0.85)
				row.add_child(wicon)
				var name_col := VBoxContainer.new()
				name_col.custom_minimum_size = Vector2(118, 0)
				name_col.add_theme_constant_override("separation", 0)
				row.add_child(name_col)
				var nl := UI.label(str(w.name), 12, WeaponData.tier_color(wid_s) if has_bp else (Color(0.95, 0.92, 0.72) if can_asm else Color(0.66, 0.66, 0.72)))
				nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				name_col.add_child(nl)
				var wtier: int = int(w.get("tier", 1))
				if req_bp:
					var bpl := UI.label("📜 Bản vẽ · Cấp %d" % wtier, 10, Color(0.52, 0.92, 1.0) if has_bp else Color(1.0, 0.72, 0.35))
					bpl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
					name_col.add_child(bpl)
				elif not has_bp:
					var fgl := UI.label("🧩 Mảnh bản vẽ: %d / %d" % [have_frags, need_frags], 10, Color(0.55, 1.0, 0.78) if can_asm else Color(1.0, 0.78, 0.40))
					fgl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
					name_col.add_child(fgl)
				else:
					var tl := UI.label("Cấp %d · %s" % [wtier, MaterialData.blueprint_tier_label(wid_s)], 10, WeaponData.tier_color(wid_s))
					tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
					name_col.add_child(tl)
				var sfx_btn := UI.button("🔊", _preview_weapon_sfx.bind(wid_s, w), 11, 28.0)
				row.add_child(sfx_btn)
				var reqs := HBoxContainer.new()
				reqs.add_theme_constant_override("separation", 3)
				reqs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(reqs)
				var mats: Dictionary = rec.get("mats", {})
				for mid in MaterialData.ORDER:
					if not mats.has(mid):
						continue
					var need: int = int(mats[mid])
					var have: int = Global.material_count(str(mid))
					var ok: bool = have >= need
					var mc := HBoxContainer.new()
					mc.add_theme_constant_override("separation", 2)
					mc.add_child(_mat_icon(str(mid), 11.0))
					var ml := UI.label("%d/%d" % [have, need], 10, Color(0.88, 0.92, 0.88) if ok else Color(1, 0.35, 0.35))
					mc.add_child(ml)
					reqs.add_child(mc)
				var need_c: int = int(rec.get("coins", 0))
				var ok_c: bool = Global.coins >= need_c
				reqs.add_child(UI.label("%dx" % need_c, 10, Color(1, 0.88, 0.45) if ok_c else Color(1, 0.35, 0.35)))
				if req_bp and not has_bp:
					var lk := UI.button("Cần mở khóa bản vẽ ở Tầng Hầm", func(): pass, 10, 166.0)
					lk.disabled = true
					row.add_child(lk)
				elif not has_bp:
					if can_asm:
						var ab := UI.button("Ghép Bản Vẽ", func():
							if Global.assemble_blueprint(wid_s):
								if Sfx != null:
									Sfx.play("forge")
								if lobby != null and lobby.has_method("on_station_fx"):
									lobby.on_station_fx(Vector2(1032, 345), "Ghép bản vẽ %s!" % str(w.name), WeaponData.tier_color(wid_s))
								open_forge("craft", tier_filter), 11, 144.0)
						ab.modulate = Color(0.65, 1.0, 0.80)
						row.add_child(ab)
					else:
						var fb_lk := UI.button("Cần ghép bản vẽ (%d/%d)" % [have_frags, need_frags], func(): pass, 10, 144.0)
						fb_lk.disabled = true
						row.add_child(fb_lk)
				elif Global.forged != "":
					var wb := UI.button("Đã có binh khí chờ ra trận", func(): pass, 11, 144.0)
					wb.disabled = true
					row.add_child(wb)
				else:
					var cb := UI.button("Rèn", _do_craft.bind(wid_s, tier_filter), 13, 60.0)
					cb.disabled = not Global.can_craft(wid_s)
					row.add_child(cb)
	_end(box)


# ------------------------------------------------------------------ Kho vũ khí

func open_rack() -> void:
	var box := _begin("Giá binh khí - Đã sưu tầm %d / %d" % [Global.discovered.size(), WeaponData.DATA.size()])
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var gridc := GridContainer.new()
	gridc.columns = 7
	gridc.add_theme_constant_override("h_separation", 4)
	gridc.add_theme_constant_override("v_separation", 4)
	scroll.add_child(gridc)
	var ids: Array = WeaponData.DATA.keys()
	ids.sort_custom(func(a, b): return int(WeaponData.DATA[a].tier) < int(WeaponData.DATA[b].tier))
	for wid in ids:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(76, 46)
		var icon := TextureRect.new()
		icon.texture = Art.tex("weapons/%s.png" % wid)
		icon.custom_minimum_size = Vector2(76, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var known: bool = Global.discovered.has(wid)
		icon.modulate = Color.WHITE if known else Color(0, 0, 0, 0.75)
		cell.add_child(icon)
		var nm := UI.label(WeaponData.DATA[wid].name if known else "???", 11, WeaponData.tier_color(wid) if known else Color(0.5, 0.5, 0.5), true)
		cell.add_child(nm)
		gridc.add_child(cell)
	var rack_btns := HBoxContainer.new()
	rack_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	rack_btns.add_theme_constant_override("separation", 10)
	box.add_child(rack_btns)
	var b_test := UI.button("⚔️ Thử vũ khí", open_weapon_test_rack.bind(0), 15, 165.0)
	b_test.modulate = Color(1.0, 0.90, 0.45)
	rack_btns.add_child(b_test)
	rack_btns.add_child(UI.button("Đóng", close, 16, 130.0))


# ------------------------------------------------------------------ Thử Binh Khí (Võ Đường)

func _collect_test_weapons(tier_filter: int) -> Array:
	var starter_ids: Dictionary = {}
	for hid_v in HeroData.DATA.keys():
		var hinfo: Dictionary = HeroData.DATA[hid_v]
		var swid: String = str(hinfo.get("weapon", ""))
		if swid != "":
			starter_ids[swid] = true
	var out: Array = []
	for wid_v in WeaponData.DATA.keys():
		var wid: String = str(wid_v)
		var wd: Dictionary = WeaponData.DATA[wid]
		var is_starter: bool = bool(wd.get("basic", false)) or starter_ids.has(wid)
		var eligible: bool = is_starter or Global.discovered.has(wid) or Global.owns_blueprint(wid)
		if not eligible:
			continue
		var wtier: int = int(wd.get("tier", 1))
		if tier_filter == 1 or tier_filter == 2 or tier_filter == 12:
			if wtier > 2:
				continue
		elif tier_filter > 0 and wtier != tier_filter:
			continue
		out.append(wid)
	out.sort_custom(func(a: String, b: String) -> bool:
		var wa: Dictionary = WeaponData.DATA[a]
		var wb: Dictionary = WeaponData.DATA[b]
		var ta: int = int(wa.get("tier", 1))
		var tb: int = int(wb.get("tier", 1))
		if ta != tb:
			return ta < tb
		var ba: int = 1 if bool(wa.get("boss_motif", false)) else 0
		var bb: int = 1 if bool(wb.get("boss_motif", false)) else 0
		if ba != bb:
			return ba > bb
		return str(wa.get("name", a)) < str(wb.get("name", b)))
	return out


func _spawn_test_pickup_near_player(wid: String) -> bool:
	if lobby == null or not is_instance_valid(lobby):
		return false
	var p = lobby.get("player")
	if p == null or not is_instance_valid(p):
		return false
	var parent_node: Node = lobby.get("world")
	if parent_node == null or not is_instance_valid(parent_node):
		parent_node = p.get_parent()
	if parent_node == null:
		return false
	var pk := Pickup.new()
	pk.kind = "weapon"
	pk.weapon_id = wid
	var angle: float = randf_range(-0.6, 0.6)
	var dist: float = randf_range(22.0, 34.0)
	var spawn_pos: Vector2 = p.global_position + Vector2(cos(angle) * dist, sin(angle) * dist + 14.0)
	pk.position = spawn_pos
	parent_node.add_child(pk)
	if Sfx != null:
		Sfx.play("pickup")
	var wname: String = str(WeaponData.get_data(wid).get("name", wid))
	Fx.float_text(parent_node, spawn_pos + Vector2(0, -18), "Đặt: %s" % wname, WeaponData.tier_color(wid), 12)
	return true


func open_weapon_test_rack(tier_filter: int = 0, last_msg: String = "") -> void:
	var box := _begin("Thử Binh Khí — Võ Đường")
	box.add_theme_constant_override("separation", 4)

	var note := UI.label("Vũ khí thử nghiệm chỉ dùng trong Võ Đường — tự khôi phục khi xuất trận", 12, Color(1.0, 0.88, 0.45), true)
	note.custom_minimum_size = Vector2(560, 0)
	box.add_child(note)

	var act_row := HBoxContainer.new()
	act_row.alignment = BoxContainer.ALIGNMENT_CENTER
	act_row.add_theme_constant_override("separation", 8)
	box.add_child(act_row)

	var b_restore := UI.button("Trả vũ khí gốc", func():
		if lobby != null and is_instance_valid(lobby):
			var p = lobby.get("player")
			if p != null and is_instance_valid(p) and p.has_method("restore_test_weapons"):
				p.restore_test_weapons()
				if Sfx != null:
					Sfx.play("pickup")
		open_weapon_test_rack(tier_filter, "Đã trả về vũ khí gốc của tướng!"), 12, 148.0)
	b_restore.modulate = Color(0.75, 0.94, 1.0)
	act_row.add_child(b_restore)

	var b_reset_dps := UI.button("Đặt lại DPS hình nhân", func():
		var cnt: int = 0
		if get_tree() != null:
			for n in get_tree().get_nodes_in_group("enemies"):
				if n != null and is_instance_valid(n) and n.has_method("reset_dps"):
					n.reset_dps()
					cnt += 1
		open_weapon_test_rack(tier_filter, "Đã đặt lại DPS cho %d hình nhân!" % cnt if cnt > 0 else "Đã đặt lại bộ đếm DPS!"), 12, 176.0)
	b_reset_dps.modulate = Color(1.0, 0.86, 0.52)
	act_row.add_child(b_reset_dps)

	var fbar := HBoxContainer.new()
	fbar.alignment = BoxContainer.ALIGNMENT_CENTER
	fbar.add_theme_constant_override("separation", 5)
	box.add_child(fbar)
	var filter_specs := [
		[0, "Tất cả", 72.0],
		[1, "Cấp 1-2", 80.0],
		[3, "Cấp 3", 68.0],
		[4, "Cấp 4", 68.0],
		[5, "Cấp 5", 68.0],
	]
	for spec in filter_specs:
		var fv: int = int(spec[0])
		var active: bool = (tier_filter == fv) or (fv == 1 and (tier_filter == 2 or tier_filter == 12))
		var fb := UI.button(str(spec[1]), open_weapon_test_rack.bind(fv, ""), 12, float(spec[2]))
		fb.disabled = active
		if active:
			fb.modulate = WeaponData.TIER_COLORS[fv] if (fv >= 3 and fv <= 5) else Color(1.0, 0.90, 0.45)
		fbar.add_child(fb)

	if last_msg != "":
		box.add_child(UI.label(last_msg, 12, Color(0.55, 0.98, 0.72)))

	var items: Array = _collect_test_weapons(tier_filter)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, 134.0 if last_msg != "" else 152.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	if items.is_empty():
		list.add_child(UI.label("Chưa có vũ khí đã mở khóa ở bậc này. Hãy khám phá hầm ngục hoặc ghép bản vẽ!", 12, Color(0.85, 0.82, 0.78)))
	else:
		for wid_v in items:
			var wid: String = str(wid_v)
			var wd: Dictionary = WeaponData.DATA.get(wid, {})
			var wname: String = str(wd.get("name", wid))
			var wtier: int = int(wd.get("tier", 1))
			var wdmg: int = int(wd.get("damage", 0))
			var wen: int = int(wd.get("energy", 0))
			var is_boss_m: bool = bool(wd.get("boss_motif", false))
			var is_basic: bool = bool(wd.get("basic", false))
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if (wtier >= 5 or is_boss_m) else "ui/panel.png"))
			list.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			card.add_child(row)

			var icon := TextureRect.new()
			icon.texture = Art.tex("weapons/%s.png" % wid)
			icon.custom_minimum_size = Vector2(30, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)

			var info := VBoxContainer.new()
			info.custom_minimum_size = Vector2(330, 0)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_constant_override("separation", 0)
			row.add_child(info)
			var tag: String = " ★Thần binh" if is_boss_m else (" (Cơ bản)" if is_basic else "")
			var nl := UI.label("%s%s" % [wname, tag], 13, WeaponData.tier_color(wid))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info.add_child(nl)
			var meta := UI.label("Cấp %d (%s) · ST %d · NL %d" % [wtier, WeaponData.tier_name(wid), wdmg, wen], 11, Color(0.86, 0.86, 0.84))
			meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info.add_child(meta)

			var b_equip := UI.button("Cầm thử", func():
				if lobby != null and is_instance_valid(lobby):
					var p = lobby.get("player")
					if p != null and is_instance_valid(p) and p.has_method("equip_test_weapon"):
						p.equip_test_weapon(wid)
						if Sfx != null:
							Sfx.play("pickup")
				close(), 12, 82.0)
			b_equip.modulate = Color(0.62, 1.0, 0.78)
			row.add_child(b_equip)

			var b_drop := UI.button("Đặt xuống sàn", func():
				if _spawn_test_pickup_near_player(wid):
					open_weapon_test_rack(tier_filter, "Đã đặt %s xuống sàn cạnh bạn — thử [R] Hợp Nhất!" % wname), 12, 112.0)
			b_drop.modulate = Color(0.75, 0.92, 1.0)
			row.add_child(b_drop)

	_end(box)


# ------------------------------------------------------------------ Bia ghi công & Hồn Sử Đại Việt

func open_stele() -> void:
	var box := _begin("Bia ghi công")
	var lines := [
		"Số lượt xuất trận: %d" % int(Global.stats.get("runs", 0)),
		"Giặc đã hạ: %d" % int(Global.stats.get("kills", 0)),
		"Trùm đã đánh bại: %d" % int(Global.stats.get("bosses", 0)),
		"Màn cao nhất: %d" % Global.best_level,
		"Tướng đã mở: %d / %d" % [Global.unlocked.size(), HeroData.ORDER.size()],
		"Vũ khí đã sưu tầm: %d / %d" % [Global.discovered.size(), WeaponData.DATA.size()],
	]
	for t in lines:
		box.add_child(UI.label(t, 18, Color(0.95, 0.9, 0.82)))
	var stele_btns := HBoxContainer.new()
	stele_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	stele_btns.add_theme_constant_override("separation", 10)
	box.add_child(stele_btns)
	var b_chr := UI.button("📖 Hồn Sử Đại Việt", open_chronicles.bind("all"), 15, 195.0)
	b_chr.modulate = Color(1.0, 0.88, 0.42)
	stele_btns.add_child(b_chr)
	stele_btns.add_child(UI.button("Đóng", close, 16, 125.0))


func _chronicle_badge_meta(cat: String) -> Dictionary:
	match cat:
		"mythic":
			return {"label": "TAM YÊU", "color": Color(0.84, 0.56, 1.0)}
		"relic":
			return {"label": "KỶ VẬT", "color": Color(0.45, 0.94, 1.0)}
		_:
			return {"label": "TRÙM LỊCH SỬ", "color": Color(1.0, 0.72, 0.34)}


func _chronicle_lock_hint(entry: Dictionary) -> String:
	var custom_hint: String = str(entry.get("hint", entry.get("unlock_hint", "")))
	if custom_hint != "":
		return "🔒 Điều kiện bí ẩn: %s" % custom_hint
	var cid: String = str(entry.get("id", ""))
	var cat: String = str(entry.get("category", "boss"))
	var era: String = str(entry.get("era", ""))
	match cid:
		"relic_boss_motif":
			return "🔒 Điều kiện bí ẩn: Ghép hoàn chỉnh một Bản Vẽ Thần Binh Trùm."
		"relic_merged_mythic":
			return "🔒 Điều kiện bí ẩn: Hợp Nhất ([R]) hoặc ghép thành công Thần Binh Thần Thoại."
		"coop_dong_tam":
			return "🔒 Điều kiện bí ẩn: Cùng đồng đội LAN kích hoạt Hợp Chiêu Đại Việt."
	if cat == "mythic":
		return "🔒 Điều kiện bí ẩn: Đánh bại Yêu Vương ẩn mình tại %s." % (era if era != "" else "Cõi Thần Thoại")
	return "🔒 Điều kiện bí ẩn: Đánh bại Trùm Lịch Sử tại %s." % (era if era != "" else "Chiến trường Đại Việt")


func open_chronicles(filter_cat: String = "all") -> void:
	var c_sc := _chronicle_data()
	var order_arr: Array = c_sc.get("ORDER") if (c_sc != null and c_sc.get("ORDER") is Array) else []
	var data_dict: Dictionary = c_sc.get("DATA") if (c_sc != null and c_sc.get("DATA") is Dictionary) else {}
	var total_cnt: int = int(c_sc.total_count()) if (c_sc != null and c_sc.has_method("total_count")) else order_arr.size()
	var raw_unlocked: Variant = Global.get("unlocked_chronicles")
	var unlocked_arr: Array = raw_unlocked as Array if raw_unlocked is Array else []
	var unlocked_cnt: int = 0
	if Global.has_method("unlocked_chronicle_count"):
		unlocked_cnt = int(Global.unlocked_chronicle_count())
	else:
		for cid_v in order_arr:
			if unlocked_arr.has(str(cid_v)):
				unlocked_cnt += 1

	var box := _begin("HỒN SỬ ĐẠI VIỆT (%d / %d)" % [unlocked_cnt, total_cnt])
	box.add_theme_constant_override("separation", 4)

	var sub := UI.label("Đánh bại Trùm, ghép Thần Binh và Hợp Chiêu LAN để khai mở trang sử & treo Kỷ Vật tại Đại Sảnh!", 12, Color(0.95, 0.90, 0.76), true)
	sub.custom_minimum_size = Vector2(566, 0)
	box.add_child(sub)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	box.add_child(tabs)
	var tab_specs := [
		["all", "Tất cả", 84.0],
		["boss", "Trùm Lịch Sử", 122.0],
		["mythic", "Tam Yêu", 98.0],
		["relic", "Kỷ Vật", 92.0],
	]
	for spec in tab_specs:
		var ck: String = str(spec[0])
		var active: bool = (filter_cat == ck)
		var tb := UI.button(str(spec[1]), open_chronicles.bind(ck), 12, float(spec[2]))
		tb.disabled = active
		if active:
			tb.modulate = Color(1.0, 0.88, 0.42)
		tabs.add_child(tb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, 174)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	var shown_any: bool = false
	for cid_v in order_arr:
		var cid: String = str(cid_v)
		var entry: Dictionary = data_dict.get(cid, {})
		if entry.is_empty():
			continue
		var cat: String = str(entry.get("category", "boss"))
		if filter_cat != "all" and cat != filter_cat:
			continue
		shown_any = true
		var is_unlocked: bool = Global.has_chronicle(cid) if Global.has_method("has_chronicle") else unlocked_arr.has(cid)
		var entry_col: Color = entry.get("color", Color(1.0, 0.85, 0.35)) as Color
		var bmeta: Dictionary = _chronicle_badge_meta(cat)
		var bcol: Color = bmeta.get("color", Color(1.0, 0.78, 0.36)) as Color

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if is_unlocked else "ui/panel.png"))
		card.custom_minimum_size = Vector2(568, 0)
		list.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 3)
		card.add_child(cv)

		var hdr := HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 6)
		cv.add_child(hdr)

		var badge_panel := PanelContainer.new()
		var bst := StyleBoxFlat.new()
		var badge_c: Color = bcol if is_unlocked else Color(0.55, 0.55, 0.62)
		bst.bg_color = Color(badge_c.r * 0.25, badge_c.g * 0.25, badge_c.b * 0.25, 0.92)
		bst.border_color = Color(badge_c.r, badge_c.g, badge_c.b, 0.96 if is_unlocked else 0.55)
		bst.set_border_width_all(1)
		bst.set_corner_radius_all(3)
		bst.content_margin_left = 5
		bst.content_margin_right = 5
		bst.content_margin_top = 1
		bst.content_margin_bottom = 1
		badge_panel.add_theme_stylebox_override("panel", bst)
		badge_panel.add_child(UI.label(str(bmeta.get("label", cat.to_upper())), 10, badge_c))
		hdr.add_child(badge_panel)

		var title_str: String = str(entry.get("title", cid)) if is_unlocked else "Trang sử chưa khai mở"
		var tl := UI.label(title_str, 14, entry_col if is_unlocked else Color(0.70, 0.70, 0.76))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hdr.add_child(tl)

		var era_str: String = str(entry.get("era", "")) if is_unlocked else "???"
		var el := UI.label(era_str, 11, Color(0.92, 0.85, 0.64) if is_unlocked else Color(0.56, 0.56, 0.62))
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hdr.add_child(el)

		if is_unlocked:
			var story_txt: String = str(entry.get("story", ""))
			if story_txt != "":
				var sl := UI.label(story_txt, 11, Color(0.92, 0.90, 0.86), true)
				sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				sl.custom_minimum_size = Vector2(546, 0)
				cv.add_child(sl)
			var quote_txt: String = str(entry.get("quote", ""))
			if quote_txt != "":
				var qr := RichTextLabel.new()
				qr.bbcode_enabled = true
				qr.fit_content = true
				qr.scroll_active = false
				qr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				qr.custom_minimum_size = Vector2(546, 0)
				qr.add_theme_font_override("normal_font", Art.font())
				qr.add_theme_font_override("italics_font", Art.font())
				qr.add_theme_font_size_override("normal_font_size", 11)
				qr.add_theme_font_size_override("italics_font_size", 11)
				qr.add_theme_color_override("default_color", Color(1.0, 0.88, 0.54))
				qr.text = "[i]“%s”[/i]" % quote_txt
				cv.add_child(qr)
			var ftr := HBoxContainer.new()
			ftr.add_theme_constant_override("separation", 8)
			cv.add_child(ftr)
			var hang_lbl := UI.label("✓ Đã treo kỷ vật tại Đại Sảnh", 11, Color(0.55, 0.98, 0.68))
			hang_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			hang_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ftr.add_child(hang_lbl)
			var plaque: String = str(entry.get("plaque_label", ""))
			if plaque != "":
				ftr.add_child(UI.label("[%s]" % plaque, 10, Color(0.94, 0.84, 0.52)))
		else:
			var lock_l := UI.label(_chronicle_lock_hint(entry), 11, Color(0.78, 0.78, 0.84), true)
			lock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lock_l.custom_minimum_size = Vector2(546, 0)
			cv.add_child(lock_l)

	if not shown_any:
		list.add_child(UI.label("Chưa có trang Hồn Sử nào trong mục này.", 12, Color(0.85, 0.82, 0.78)))

	_end(box)


# ------------------------------------------------------------------ Giếng Ước

func _do_wish() -> void:
	if lobby == null or int(lobby.well_uses) <= 0 or Global.coins < 10:
		return
	Global.coins -= 10
	lobby.well_uses = int(lobby.well_uses) - 1
	var roll: float = randf()
	var msg := ""
	var col := Color(0.5, 0.95, 1.0)
	if roll < 0.40:
		var mid: String = str(MaterialData.ORDER[randi() % MaterialData.ORDER.size()])
		var qty: int = 2 if randf() < 0.35 else 1
		Global.materials[mid] = Global.material_count(mid) + qty
		msg = "Giếng ban tặng +%d %s!" % [qty, str(MaterialData.DATA[mid].name)]
		col = Color(0.65, 1.0, 0.68)
		Sfx.play("forge")
	elif roll < 0.72:
		var bonus: int = 22 if randf() < 0.4 else 16
		Global.coins += bonus
		msg = "Lộc giếng cổ: nhận +%d xu!" % bonus
		col = Color(1.0, 0.88, 0.38)
		Sfx.play("coin")
	else:
		msg = "Mặt nước gợn sóng lấp lánh... thử lại lần sau!"
		col = Color(0.72, 0.86, 0.98)
		Sfx.play("pickup")
	Global.save_game()
	if lobby.has_method("on_well_result"):
		lobby.on_well_result(msg, col)
	open_well(msg)


func open_well(last_msg: String = "") -> void:
	var box := _begin("Giếng Ước Cổ")
	var left: int = int(lobby.well_uses) if lobby != null else 0
	var info := UI.label("Thả 10 xu xuống giếng để nhận nguyên liệu rèn hoặc lộc may mắn trước khi xuất trận.", 13, Color(0.88, 0.92, 0.96), true)
	info.custom_minimum_size = Vector2(440, 0)
	box.add_child(info)
	box.add_child(UI.label("Xu hiện có: %d   |   Lượt còn lại: %d / 3" % [Global.coins, left], 15, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 15, Color(0.55, 0.98, 0.75)))
	var btn := UI.button("Thả 10 xu cầu may" if left > 0 else "Hết lượt cầu hôm nay", _do_wish, 16, 220.0)
	btn.disabled = left <= 0 or Global.coins < 10
	box.add_child(UI.center(btn))
	_end(box)


# ------------------------------------------------------------------ Bảng Khiêu Chiến

func open_challenge() -> void:
	var box := _begin("Bảng Khiêu Chiến")
	var cur_diff: String = str(Global.settings.get("difficulty", "thuong"))
	var diff_names := {"de": "Dễ (máu địch ×0,7)", "thuong": "Thường (cân bằng chuẩn)", "kho": "Khó (máu địch ×1,4 - Thử thách!)"}
	box.add_child(UI.label("Chế độ hiện tại: %s" % str(diff_names.get(cur_diff, cur_diff)), 15, Color(1.0, 0.88, 0.45)))
	var drow := HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation", 8)
	box.add_child(drow)
	for spec in [["de", "Dễ"], ["thuong", "Thường"], ["kho", "Khó"]]:
		var did: String = str(spec[0])
		var dname: String = str(spec[1])
		var b := UI.button(dname, func():
			Global.set_setting("difficulty", did)
			Global.save_game()
			open_challenge(), 14, 96.0)
		b.modulate = Color(1.0, 0.9, 0.42) if did == cur_diff else Color(0.75, 0.75, 0.78)
		drow.add_child(b)
	var b_badass := UI.button("Ác Mộng: BẬT" if Global.badass_mode else "Ác Mộng: TẮT", func():
		Global.badass_mode = not Global.badass_mode
		Global.save_game()
		open_challenge(), 14, 136.0)
	b_badass.modulate = Color(1.0, 0.38, 0.42) if Global.badass_mode else Color(0.76, 0.76, 0.82)
	drow.add_child(b_badass)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 130)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var trials := [
		["Chinh phục Màn 6", "Đạt màn 6 trở lên để mở khóa Thánh Gióng.", Global.best_level >= 6],
		["Kho Tàng Binh Khí", "Sưu tầm từ 12 vũ khí để mở nhiều công thức rèn cấp cao.", Global.discovered.size() >= 12],
		["Chiến Tích Đánh Trùm", "Hạ ít nhất 3 Trùm lịch sử qua các chương.", int(Global.stats.get("bosses", 0)) >= 3],
	]
	for t in trials:
		var done: bool = bool(t[2])
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		row.add_child(vb)
		var hdr := UI.label("%s  [%s]" % [str(t[0]), "Hoàn thành" if done else "Đang thử thách"], 14, Color(0.55, 0.96, 0.62) if done else Color(1.0, 0.85, 0.42))
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(hdr)
		var dsc := UI.label(str(t[1]), 12, Color(0.88, 0.86, 0.82), true)
		dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(dsc)
		list.add_child(row)
	_end(box)


# ------------------------------------------------------------------ Bách Khoa Toàn Thư

func open_codex(tab: String = "buffs") -> void:
	var box := _begin("Bách Khoa Toàn Thư")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var b_buff := UI.button("Phúc lành (%d)" % BuffData.DATA.size(), open_codex.bind("buffs"), 13, 142.0)
	b_buff.disabled = (tab == "buffs")
	var b_relic := UI.button("Cổ Vật (%d)" % RelicData.ORDER.size(), open_codex.bind("relics"), 13, 128.0)
	b_relic.disabled = (tab == "relics")
	var total_bosses: int = EnemyData.CHAPTERS.size() + EnemyData.MYTHIC_CHAPTERS.size() + EnemyData.SECRET_BOSSES.size()
	var b_boss := UI.button("Trùm & Bí Cảnh (%d)" % total_bosses, open_codex.bind("bosses"), 13, 168.0)
	b_boss.disabled = (tab == "bosses")
	tabs.add_child(b_buff)
	tabs.add_child(b_relic)
	tabs.add_child(b_boss)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	if tab == "buffs":
		for bid in BuffData.DATA:
			var bd: Dictionary = BuffData.DATA[bid]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := UI.label("%s (%s)" % [str(bd.name), BuffData.category_name(str(bid))], 13, BuffData.tier_color(str(bid)))
			nm.custom_minimum_size = Vector2(215, 0)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(nm)
			var dsc := UI.label(str(bd.desc), 12, Color(0.88, 0.88, 0.85), true)
			dsc.custom_minimum_size = Vector2(315, 0)
			dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(dsc)
			list.add_child(row)
	elif tab == "relics":
		for rid_v in RelicData.ORDER:
			var rid: String = str(rid_v)
			var rd: Dictionary = RelicData.get_relic(rid)
			var rar: String = str(rd.get("rarity", "rare"))
			var rcol: Color = rd.get("color", RelicData.rarity_color(rar)) as Color
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := UI.label("%s [%s]" % [str(rd.get("name", rid)), RelicData.rarity_name(rar)], 12, rcol)
			nm.custom_minimum_size = Vector2(215, 0)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(nm)
			var dsc := UI.label(str(rd.get("desc", "")), 11, Color(0.90, 0.88, 0.85), true)
			dsc.custom_minimum_size = Vector2(320, 0)
			dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(dsc)
			list.add_child(row)
	else:
		for ch in EnemyData.CHAPTERS:
			var bid2: String = str(ch.get("boss", ""))
			var binfo: Dictionary = EnemyData.BOSSES.get(bid2, {})
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := UI.label("%s — %s" % [str(ch.get("name", "")), str(binfo.get("name", bid2))], 12, Color(1.0, 0.78, 0.45))
			nm.custom_minimum_size = Vector2(225, 0)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(nm)
			var dsc := UI.label("%s: %s (%s)" % [str(ch.get("year", "")), str(binfo.get("title", "")), str(binfo.get("form2", ""))], 11, Color(0.88, 0.86, 0.84), true)
			dsc.custom_minimum_size = Vector2(310, 0)
			dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(dsc)
			list.add_child(row)
		for mch in EnemyData.MYTHIC_CHAPTERS:
			var mbid: String = str(mch.get("boss", ""))
			var mbinfo: Dictionary = EnemyData.MYTHIC_BOSSES.get(mbid, {})
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := UI.label("%s — %s" % [str(mch.get("name", "")), str(mbinfo.get("name", mbid))], 12, Color(0.84, 0.62, 1.0))
			nm.custom_minimum_size = Vector2(225, 0)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(nm)
			var dsc := UI.label("%s: %s (%s)" % [str(mch.get("year", "")), str(mbinfo.get("title", "")), str(mbinfo.get("form2", ""))], 11, Color(0.90, 0.86, 0.96), true)
			dsc.custom_minimum_size = Vector2(310, 0)
			dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(dsc)
			list.add_child(row)
		var secret_specs := [
			["thuy_cung", "thuy_tinh", Color(0.42, 0.88, 1.0)],
			["dinh_tan_vien", "thien_loi", Color(0.76, 0.82, 1.0)],
		]
		for spec in secret_specs:
			var sc: Dictionary = EnemyData.SECRET_CHAPTERS.get(str(spec[0]), {})
			var sb: Dictionary = EnemyData.SECRET_BOSSES.get(str(spec[1]), {})
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := UI.label("%s — %s" % [str(sc.get("name", "")), str(sb.get("name", ""))], 12, spec[2] as Color)
			nm.custom_minimum_size = Vector2(225, 0)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(nm)
			var dsc := UI.label("%s: %s (%s)" % [str(sc.get("year", "")), str(sb.get("title", "")), str(sb.get("form2", ""))], 11, Color(0.88, 0.94, 1.0), true)
			dsc.custom_minimum_size = Vector2(310, 0)
			dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(dsc)
			list.add_child(row)
		var tc: Dictionary = EnemyData.TRUE_ENDING_CHAPTER.get("cuu_trung", {})
		var tb: Dictionary = EnemyData.SECRET_BOSSES.get("hon_mang_yeu_de", {})
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 8)
		var tnm := UI.label("%s — %s" % [str(tc.get("name", "Đỉnh Hồng Lĩnh — Cửu Trùng")), str(tb.get("name", "Hỗn Mang Yêu Đế"))], 12, Color(1.0, 0.72, 0.98))
		tnm.custom_minimum_size = Vector2(225, 0)
		tnm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		trow.add_child(tnm)
		var tdsc := UI.label("%s: %s (%s)" % [str(tc.get("year", "")), str(tb.get("title", "")), str(tb.get("form2", ""))], 11, Color(1.0, 0.88, 0.98), true)
		tdsc.custom_minimum_size = Vector2(310, 0)
		tdsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		trow.add_child(tdsc)
		list.add_child(trow)
	_end(box)


# ------------------------------------------------------------------ Quán Trà Đại Sảnh

func _roll_village_fortune() -> String:
	var outcomes: Array[Dictionary] = [
		{"name": "Quẻ Đại Cát — Long Mạch", "coins": 30, "buff": "banh_chung", "msg": "Quẻ Đại Cát: +30 xu & phúc lành Bánh chưng lượt tới!"},
		{"name": "Quẻ Thượng Cát — Tài Lộc", "coins": 45, "buff": "", "mat": "ngoc_than", "msg": "Quẻ Thượng Cát: +45 xu & +1 Ngọc thần!"},
		{"name": "Quẻ Trung Cát — Thần Cơ", "coins": 20, "buff": "mat_than", "msg": "Quẻ Trung Cát: +20 xu & phúc lành Mắt thần lượt tới!"},
		{"name": "Quẻ Bình An — Hộ Mệnh", "coins": 25, "buff": "khien_doc", "msg": "Quẻ Bình An: +25 xu & phúc lành Khiên độc lượt tới!"},
	]
	var pick: Dictionary = outcomes[randi() % outcomes.size()]
	Global.coins += int(pick.get("coins", 0))
	var b: String = str(pick.get("buff", ""))
	if b != "" and not Global.lobby_garden_buffs.has(b):
		Global.lobby_garden_buffs.append(b)
	var m: String = str(pick.get("mat", ""))
	if m != "" and MaterialData.DATA.has(m):
		Global.materials[m] = Global.material_count(m) + 1
	Global.save_game()
	return str(pick.get("msg", "Gieo quẻ thành công!"))


func open_tea(last_msg: String = "") -> void:
	var box := _begin("Quán Trà Đại Sảnh")
	box.add_child(UI.label("Thưởng thức trà & đặc sản trước khi ra trận (giữ hiệu lực suốt lượt kế tiếp).", 13, Color(0.88, 0.92, 0.86), true))
	var cur_name: String = str(Global.LOBBY_DRINKS[Global.lobby_drink].name) if Global.lobby_drink != "" and Global.LOBBY_DRINKS.has(Global.lobby_drink) else "Chưa chọn"
	box.add_child(UI.label("Xu: %d   |   Đang dùng: %s" % [Global.coins, cur_name], 14, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 13, Color(0.55, 0.98, 0.72)))
	for did in ["tra_sen", "ruou_can", "ca_phe", "tra_gung"]:
		var dd: Dictionary = Global.LOBBY_DRINKS[did]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var nm := UI.label(str(dd.name), 15, Color(1.0, 0.88, 0.5))
		nm.custom_minimum_size = Vector2(165, 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(nm)
		var ds := UI.label(str(dd.desc), 13, Color(0.9, 0.88, 0.85))
		ds.custom_minimum_size = Vector2(230, 0)
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(ds)
		var active: bool = Global.lobby_drink == did
		var cost: int = int(dd.cost)
		var b := UI.button("Đang dùng" if active else "Uống (%d xu)" % cost, func():
			if Global.coins < cost or Global.lobby_drink == did:
				return
			Global.coins -= cost
			Global.lobby_drink = did
			Global.save_game()
			Sfx.play("buy")
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(558, 594), "Đã thưởng thức %s!" % str(dd.name), Color(0.65, 0.98, 0.7))
			open_tea("Đã chọn %s cho lượt xuất trận tới!" % str(dd.name)), 13, 128.0)
		b.disabled = active or Global.coins < cost
		row.add_child(b)
	if _is_npc_rescued("quan_su_co_loa"):
		var rolled: bool = lobby != null and bool(lobby.get("fortune_rolled"))
		var f_row := HBoxContainer.new()
		f_row.alignment = BoxContainer.ALIGNMENT_CENTER
		f_row.add_theme_constant_override("separation", 8)
		box.add_child(f_row)
		f_row.add_child(UI.label("Quân Sư Cổ Loa:", 12, Color(0.45, 0.88, 1.0)))
		var b_fortune := UI.button("Đã gieo quẻ lần này ✓" if rolled else "🔮 Gieo Quẻ Đầu Làng (Miễn phí)", func():
			if lobby == null or bool(lobby.get("fortune_rolled")):
				return
			lobby.set("fortune_rolled", true)
			var fmsg: String = _roll_village_fortune()
			Sfx.play("level_clear")
			if lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(558, 594), fmsg, Color(0.52, 0.96, 1.0))
			open_tea(fmsg), 12, 240.0)
		b_fortune.disabled = rolled
		b_fortune.modulate = Color(0.55, 0.96, 1.0) if not rolled else Color(0.7, 0.72, 0.76)
		f_row.add_child(b_fortune)
	_end(box)


# ------------------------------------------------------------------ Sa Bàn Quân Sự

func open_war_table(tab: String = "seed", last_msg: String = "") -> void:
	var box := _begin("Sa Bàn Quân Sự")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	var b_seed := UI.button("Mã Thử Thách", open_war_table.bind("seed"), 14, 150.0)
	b_seed.disabled = (tab == "seed")
	var b_lb := UI.button("Bảng Vinh Danh (%d)" % Global.leaderboard.size(), open_war_table.bind("board"), 14, 170.0)
	b_lb.disabled = (tab == "board")
	tabs.add_child(b_seed)
	tabs.add_child(b_lb)

	if last_msg != "":
		box.add_child(UI.label(last_msg, 13, Color(0.55, 0.98, 0.72)))

	if tab == "seed":
		var cur_code: String = Global.pending_challenge_code
		var best_cl: int = int(Global.stats.get("best_co_loa_wave", 0))
		box.add_child(UI.label("Mã cổng hiện đặt: %s  |  Thủ Thành Cổ Loa: Đợt %d" % [cur_code if cur_code != "" else "Ngẫu nhiên tự do", best_cl], 13, Color(1.0, 0.88, 0.45)))
		var edit := LineEdit.new()
		edit.text = cur_code
		edit.placeholder_text = "Nhập mã chiến dịch (vd: MELINH40)"
		edit.custom_minimum_size = Vector2(260, 26)
		box.add_child(UI.center(edit))

		var presets := HBoxContainer.new()
		presets.alignment = BoxContainer.ALIGNMENT_CENTER
		presets.add_theme_constant_override("separation", 8)
		box.add_child(presets)
		for pcode in ["MELINH40", "BACHDANG", "DIENBIEN"]:
			presets.add_child(UI.button(pcode, func():
				edit.text = pcode, 13, 108.0))

		var acts := HBoxContainer.new()
		acts.alignment = BoxContainer.ALIGNMENT_CENTER
		acts.add_theme_constant_override("separation", 8)
		box.add_child(acts)
		acts.add_child(UI.button("Đặt mã cho cổng", func():
			var norm: String = edit.text.strip_edges().to_upper()
			Global.pending_challenge_code = norm
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(808, 608), "Đặt mã: %s" % (norm if norm != "" else "Tự do"), Color(0.65, 0.92, 1.0))
			open_war_table("seed", "Cổng xuất trận sẽ dùng mã: %s" % (norm if norm != "" else "Ngẫu nhiên")), 13, 146.0))
		acts.add_child(UI.button("Xuất trận ngay", func():
			var norm2: String = edit.text.strip_edges().to_upper()
			if lobby != null and lobby.has_method("start_run_with_code"):
				close()
				lobby.start_run_with_code(norm2), 13, 132.0))
		var b_coloa := UI.button("⚔️ Chế độ Thủ Thành Cổ Loa", func():
			Global.pending_run_mode = "co_loa"
			Global.pending_challenge_code = ""
			if lobby != null and lobby.has_method("start_run_with_code"):
				close()
				lobby.start_run_with_code(""), 13, 210.0)
		b_coloa.modulate = Color(1.0, 0.88, 0.42)
		acts.add_child(b_coloa)
	else:
		if Global.leaderboard.is_empty():
			box.add_child(UI.label("Chưa có chiến tích nào. Hãy hoàn thành một lượt xuất trận!", 13, Color(0.86, 0.84, 0.8)))
		else:
			var scroll := ScrollContainer.new()
			scroll.custom_minimum_size = Vector2(520, 165)
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			box.add_child(scroll)
			var list := VBoxContainer.new()
			list.add_theme_constant_override("separation", 4)
			scroll.add_child(list)
			var cap: int = mini(10, Global.leaderboard.size())
			for i in cap:
				var e: Dictionary = Global.leaderboard[i]
				var hid: String = str(e.get("hero", ""))
				var hname: String = str(HeroData.DATA[hid].name) if HeroData.DATA.has(hid) else hid
				var ctag: String = (" [%s]" % str(e.get("code", ""))) if str(e.get("code", "")) != "" else ""
				var line := "#%d  %s%s  -  Màn %d  -  %d điểm (%s)" % [i + 1, hname, ctag, int(e.get("level", 1)), int(e.get("score", 0)), Global.format_time(float(e.get("time", 0.0)))]
				var lb := UI.label(line, 13, Color(1.0, 0.88, 0.42) if i == 0 else Color(0.9, 0.88, 0.84))
				lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				list.add_child(lb)
	_end(box)


# ------------------------------------------------------------------ Vườn Thảo Dược

func open_garden(last_msg: String = "") -> void:
	Global.ensure_garden_plots()
	var has_tue_tinh: bool = _is_npc_rescued("than_y_tue_tinh")
	var box := _begin("Vườn Thảo Dược Linh Sen (%d ô)" % Global.garden_plots.size())
	var can_water: bool = lobby != null and not bool(lobby.garden_watered)
	box.add_child(UI.label("Trồng thảo dược chín sau mỗi lượt chiến đấu, hoặc tưới nước 1 lần mỗi lần ghé sảnh.  |  Xu: %d" % Global.coins, 12, Color(0.85, 0.94, 0.84), true))
	if has_tue_tinh:
		box.add_child(UI.label("Danh Y Tuệ Tĩnh: Mở rộng 6 luống & giống thần thoại Linh Chi Vàng / Hoa Ưu Đàm!", 11, Color(0.45, 0.96, 0.64)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 13, Color(0.55, 0.98, 0.72)))

	var plant_keys: Array[String] = ["tre_nga", "huyet_sam", "sen_tuyet"]
	if has_tue_tinh:
		for extra_k in ["linh_chi_vang", "hoa_uu_dam"]:
			if Global.GARDEN_PLANTS.has(extra_k):
				plant_keys.append(extra_k)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, 176)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	for i in Global.garden_plots.size():
		var slot_data: Dictionary = Global.garden_plots[i]
		var pid: String = str(slot_data.get("plant", ""))
		var stg: int = int(slot_data.get("stage", 0))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
		card.custom_minimum_size = Vector2(566, 0)
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		if pid == "":
			var lb := UI.label("Ô %d: Đất trống" % (i + 1), 12, Color(0.82, 0.8, 0.76))
			lb.custom_minimum_size = Vector2(118, 0)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(lb)
			var btns_wrap := VBoxContainer.new()
			btns_wrap.add_theme_constant_override("separation", 3)
			row.add_child(btns_wrap)
			var r1 := HBoxContainer.new()
			r1.add_theme_constant_override("separation", 5)
			btns_wrap.add_child(r1)
			var r2: HBoxContainer = null
			if plant_keys.size() > 3:
				r2 = HBoxContainer.new()
				r2.add_theme_constant_override("separation", 5)
				btns_wrap.add_child(r2)
			for p_idx in plant_keys.size():
				var pkey: String = plant_keys[p_idx]
				var pd: Dictionary = Global.GARDEN_PLANTS[pkey]
				var cost: int = int(pd.cost)
				var b := UI.button("%s (%dx)" % [str(pd.name), cost], func():
					if Global.plant_garden(i, pkey):
						Sfx.play("pickup")
						if lobby != null:
							if lobby.has_method("refresh_garden_display"):
								lobby.refresh_garden_display()
							if lobby.has_method("on_station_fx"):
								lobby.on_station_fx(Vector2(154, 430), "Đã gieo %s!" % str(pd.name), Color(0.65, 0.98, 0.6))
						open_garden("Đã trồng %s vào Ô %d!" % [str(pd.name), i + 1]), 11, 134.0)
				b.disabled = Global.coins < cost
				if pkey == "linh_chi_vang" or pkey == "hoa_uu_dam":
					b.modulate = Color(1.0, 0.90, 0.45)
				if p_idx < 3 or r2 == null:
					r1.add_child(b)
				else:
					r2.add_child(b)
		else:
			var pd2: Dictionary = Global.GARDEN_PLANTS.get(pid, {})
			var st_txt: String = "Đã chín!" if stg >= 2 else "Đang lớn"
			var st_col: Color = Color(0.55, 0.98, 0.6) if stg >= 2 else Color(1.0, 0.85, 0.45)
			var info_box := VBoxContainer.new()
			info_box.custom_minimum_size = Vector2(360, 0)
			info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_box.add_theme_constant_override("separation", 1)
			row.add_child(info_box)
			var h_lb := UI.label("Ô %d: %s  [%s]" % [i + 1, str(pd2.get("name", pid)), st_txt], 13, st_col)
			h_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info_box.add_child(h_lb)
			var d_lb := UI.label(str(pd2.get("desc", "")), 11, Color(0.86, 0.86, 0.82), true)
			d_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info_box.add_child(d_lb)
			if stg >= 2:
				row.add_child(UI.button("Thu hoạch", func():
					var res_msg: String = Global.harvest_garden(i)
					if res_msg != "":
						Sfx.play("coin")
						if lobby != null:
							if lobby.has_method("refresh_garden_display"):
								lobby.refresh_garden_display()
							if lobby.has_method("on_station_fx"):
								lobby.on_station_fx(Vector2(154, 430), res_msg, Color(0.65, 1.0, 0.68))
						open_garden(res_msg), 13, 130.0))
			else:
				var wb := UI.button("Tưới nước" if can_water else "Đã tưới lượt này", func():
					if lobby != null and not bool(lobby.garden_watered) and Global.water_garden_plot(i):
						lobby.garden_watered = true
						Sfx.play("pickup")
						if lobby.has_method("refresh_garden_display"):
							lobby.refresh_garden_display()
						if lobby.has_method("on_station_fx"):
							lobby.on_station_fx(Vector2(154, 430), "%s đã chín!" % str(pd2.get("name", pid)), Color(0.55, 0.96, 1.0))
						open_garden("Đã tưới nước — %s chín sẵn sàng thu hoạch!" % str(pd2.get("name", pid))), 12, 138.0)
				wb.disabled = not can_water
				row.add_child(wb)
	_end(box)


# ------------------------------------------------------------------ Đài Thiên Phú (Cây Thiên Phú Đại Việt)

func open_skill_tree(branch_filter: String = "all", last_msg: String = "") -> void:
	var tree_dict: Dictionary = _skill_tree_dict()
	var bonuses: Dictionary = SkillTreeData.compute_bonuses(tree_dict)
	var box := _begin("Cây Thiên Phú Đại Việt")
	box.add_theme_constant_override("separation", 3)

	var inv := HBoxContainer.new()
	inv.alignment = BoxContainer.ALIGNMENT_CENTER
	inv.add_theme_constant_override("separation", 8)
	box.add_child(inv)
	inv.add_child(UI.label("Xu: %d" % Global.coins, 12, Color(1.0, 0.88, 0.45)))
	for mid in MaterialData.ORDER:
		var md: Dictionary = MaterialData.DATA[mid]
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_mat_icon(str(mid), 11.0))
		var cnt: int = Global.material_count(str(mid))
		cell.add_child(UI.label(str(cnt), 12, md.color if cnt > 0 else Color(0.55, 0.55, 0.55)))
		inv.add_child(cell)

	var sum_parts: Array[String] = []
	if int(bonuses.get("dmg_pct", 0)) > 0:
		sum_parts.append("+%d%% ST" % int(bonuses.dmg_pct))
	if int(bonuses.get("atk_speed_pct", 0)) > 0:
		sum_parts.append("+%d%% Tốc đánh" % int(bonuses.atk_speed_pct))
	if int(bonuses.get("hp_add", 0)) > 0:
		sum_parts.append("+%d Máu" % int(bonuses.hp_add))
	if int(bonuses.get("armor_add", 0)) > 0:
		sum_parts.append("+%d Giáp" % int(bonuses.armor_add))
	if int(bonuses.get("energy_add", 0)) > 0:
		sum_parts.append("+%d NL" % int(bonuses.energy_add))
	if int(bonuses.get("skill_cd_pct", 0)) > 0:
		sum_parts.append("-%d%% Hồi chiêu" % int(bonuses.skill_cd_pct))
	if int(bonuses.get("coin_pct", 0)) > 0:
		sum_parts.append("+%d%% Xu" % int(bonuses.coin_pct))
	var sum_txt: String = "Tổng cộng: " + (" · ".join(sum_parts) if not sum_parts.is_empty() else "Chưa nâng bậc thiên phú nào")
	box.add_child(UI.label(sum_txt, 11, Color(0.62, 0.96, 0.78), true))

	if last_msg != "":
		box.add_child(UI.label(last_msg, 12, Color(0.55, 0.98, 0.72)))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 5)
	box.add_child(tabs)
	var b_all := UI.button("Tất cả (16)", open_skill_tree.bind("all", ""), 11, 96.0)
	b_all.disabled = (branch_filter == "all")
	tabs.add_child(b_all)
	for bid_v in SkillTreeData.BRANCH_ORDER:
		var bid: String = str(bid_v)
		var br: Dictionary = SkillTreeData.BRANCHES[bid]
		var tb := UI.button(str(br.name), open_skill_tree.bind(bid, ""), 11, 92.0)
		tb.disabled = (branch_filter == bid)
		tb.modulate = (br.color as Color) if branch_filter == bid else Color(0.86, 0.88, 0.92)
		tabs.add_child(tb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, 166.0 if last_msg == "" else 150.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var branches_to_show: Array = SkillTreeData.BRANCH_ORDER if branch_filter == "all" else [branch_filter]
	for bid_v in branches_to_show:
		var bid: String = str(bid_v)
		if not SkillTreeData.BRANCHES.has(bid):
			continue
		var br: Dictionary = SkillTreeData.BRANCHES[bid]
		var bcol: Color = br.get("color", Color.WHITE) as Color
		var bhdr := UI.label("◆ %s — %s" % [str(br.name), str(br.desc)], 12, bcol)
		bhdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(bhdr)
		for nid_v in br.get("nodes", []):
			var nid: String = str(nid_v)
			var nd: Dictionary = SkillTreeData.NODES.get(nid, {})
			if nd.is_empty():
				continue
			var cur_r: int = SkillTreeData.node_rank(tree_dict, nid)
			var max_r: int = int(nd.get("max_rank", 1))
			var maxed: bool = cur_r >= max_r

			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if maxed else "ui/panel.png"))
			card.custom_minimum_size = Vector2(566, 0)
			list.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			card.add_child(row)

			var info_col := VBoxContainer.new()
			info_col.custom_minimum_size = Vector2(412, 0)
			info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_col.add_theme_constant_override("separation", 1)
			row.add_child(info_col)

			var nl := UI.label("%s  (%d / %d)" % [str(nd.name), cur_r, max_r], 13, Color(0.55, 0.98, 0.65) if maxed else bcol.lerp(Color.WHITE, 0.35))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info_col.add_child(nl)
			var dl := UI.label(str(nd.desc), 11, Color(0.90, 0.88, 0.85), true)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info_col.add_child(dl)

			if not maxed:
				var cost: Dictionary = SkillTreeData.upgrade_cost(nid, cur_r + 1)
				_add_cost_row(info_col, int(cost.get("coins", 0)), cost.get("mats", {}))
				var can_up: bool = SkillTreeData.can_upgrade_node(tree_dict, nid, Global.coins, Global.materials)
				var b_up := UI.button("Nâng cấp", func():
					if Global.has_method("upgrade_skill_tree_node") and bool(Global.call("upgrade_skill_tree_node", nid)):
						Sfx.play("forge")
						if lobby != null and lobby.has_method("on_station_fx"):
							lobby.on_station_fx(Vector2(680, 326), "%s Bậc %d!" % [str(nd.name), cur_r + 1], bcol)
						open_skill_tree(branch_filter, "Đã nâng %s lên Bậc %d!" % [str(nd.name), cur_r + 1]), 12, 118.0)
				b_up.disabled = not can_up
				row.add_child(b_up)
			else:
				var b_max := UI.button("Tối đa ✓", func(): pass, 12, 118.0)
				b_max.disabled = true
				row.add_child(b_max)
	_end(box)


# ------------------------------------------------------------------ Đài Thức Tỉnh Thần Thú

func open_pet_shrine(last_msg: String = "") -> void:
	var box := _begin("Đài Thức Tỉnh Thần Thú")
	box.add_theme_constant_override("separation", 4)
	var has_nghe_nhan: bool = _is_npc_rescued("nghe_nhan_phu_lang")
	var sub_txt: String = "Thức tỉnh linh thú lên hình thái Thần Thú tối thượng!"
	if has_nghe_nhan:
		sub_txt += "  (Nghệ Nhân Phù Lãng: -20% nguyên liệu!)"
	box.add_child(UI.label(sub_txt, 12, Color(0.55, 0.96, 0.88) if has_nghe_nhan else Color(0.88, 0.92, 0.96), true))
	box.add_child(UI.label("Xu: %d  |  Yêu hồn: %d  |  Ngọc thần: %d" % [Global.coins, Global.material_count("yeu_hon"), Global.material_count("ngoc_than")], 12, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 13, Color(0.55, 0.98, 0.72)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, 174.0 if last_msg == "" else 156.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	for pid in ["dog", "cat", "rooster", "crane"]:
		var evo: Dictionary = CampNpcs.get_awakened_pet(pid)
		if evo.is_empty():
			continue
		var awakened: bool = _is_pet_awakened(pid)
		var evo_col: Color = evo.get("color", Color(1.0, 0.84, 0.34)) as Color
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if awakened else "ui/panel.png"))
		card.custom_minimum_size = Vector2(566, 0)
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var at := AtlasTexture.new()
		at.atlas = Art.tex(str(evo.get("sprite", "")))
		at.region = Rect2(0, 0, int(evo.get("fw", 28)), int(evo.get("fh", 24)))
		var pic := TextureRect.new()
		pic.texture = at
		pic.custom_minimum_size = Vector2(40, 36)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(pic)

		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(360, 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 1)
		row.add_child(info)
		var nl := UI.label("%s → %s" % [str(evo.get("base_name", pid)), str(evo.get("name", pid))], 13, evo_col)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(nl)
		var dl := UI.label(str(evo.get("desc", "")), 11, Color(0.90, 0.88, 0.85), true)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(dl)
		if not awakened:
			var raw_mats: Dictionary = evo.get("mats", {})
			var adj_mats: Dictionary = {}
			for m_k in raw_mats:
				var qty: int = int(raw_mats[m_k])
				if has_nghe_nhan:
					qty = maxi(1, int(floor(float(qty) * 0.8)))
				adj_mats[m_k] = qty
			_add_cost_row(info, int(evo.get("coins", 300)), adj_mats)

		if awakened:
			var b_done := UI.button("Đã Thức Tỉnh ★", func():
				Global.select_pet(pid)
				if Net != null and Net.is_online():
					Net.request_set_pet(pid)
				if lobby != null and lobby.has_method("refresh_pet_stations"):
					lobby.refresh_pet_stations()
				open_pet_shrine("Đã chọn %s đồng hành ra trận!" % str(evo.get("name", pid))), 12, 128.0)
			b_done.modulate = Color(0.65, 1.0, 0.78)
			row.add_child(b_done)
		else:
			var can_aw: bool = _can_awaken_pet(pid)
			var b_aw := UI.button("Thức Tỉnh", func():
				if Global.has_method("awaken_pet") and bool(Global.call("awaken_pet", pid)):
					Sfx.play("level_clear")
					if lobby != null:
						if lobby.has_method("refresh_pet_stations"):
							lobby.refresh_pet_stations()
						if lobby.has_method("on_station_fx"):
							lobby.on_station_fx(Vector2(356, 446), "Thức tỉnh %s!" % str(evo.get("name", pid)), evo_col)
					open_pet_shrine("%s đã thức tỉnh thành công!" % str(evo.get("name", pid))), 13, 128.0)
			b_aw.disabled = not can_aw
			b_aw.modulate = Color(1.0, 0.88, 0.42) if can_aw else Color(0.75, 0.75, 0.8)
			row.add_child(b_aw)
	_end(box)


# ------------------------------------------------------------------ Võ Đài Tỷ Thí

func open_sparring() -> void:
	var box := _begin("Võ Đài Tỷ Thí")
	var arena_nd: Node2D = lobby.get("_sparring_arena") as Node2D if lobby != null else null
	var is_on: bool = arena_nd != null and is_instance_valid(arena_nd) and bool(arena_nd.get("active"))
	var has_vosu: bool = _is_npc_rescued("vo_su_thien_nam")
	box.add_child(UI.label("Võ Đài Tỷ Thí không gây tử vong (máu dừng ở 1, tự hồi đầy khi phân thắng bại).", 13, Color(0.92, 0.90, 0.86), true))
	if has_vosu:
		box.add_child(UI.label("Võ Sư Thiên Nam: \"Lên đài tỷ thí một phen, rèn gân cốt trước giờ xuất quân!\"", 12, Color(1.0, 0.78, 0.42), true))
	var mode_txt: String = "Đang diễn ra (Bước vào vòng đỏ Võ Đường Đông để giao đấu!)" if is_on else "Đang nghỉ — Bật tỷ thí để đấu với Võ Sư Thiên Nam (Solo) hoặc đồng đội (LAN)."
	box.add_child(UI.label(mode_txt, 12, Color(0.55, 0.98, 0.72) if is_on else Color(0.84, 0.86, 0.92), true))
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	box.add_child(btns)
	var b_tog := UI.button("Kết thúc Tỷ Thí" if is_on else "⚔️ Bắt đầu Tỷ Thí", func():
		if lobby != null and lobby.has_method("toggle_sparring"):
			lobby.toggle_sparring()
		close(), 15, 190.0)
	b_tog.modulate = Color(1.0, 0.56, 0.48) if is_on else Color(1.0, 0.88, 0.38)
	btns.add_child(b_tog)
	btns.add_child(UI.button("Đóng", close, 15, 110.0))


# ------------------------------------------------------------------ Bàn Phù Phép Binh Khí

func open_enchant(last_msg: String = "") -> void:
	var box := _begin("Bàn Phù Phép Binh Khí")
	var hid: String = Global.selected_hero
	var wid: String = str(HeroData.DATA[hid].weapon) if HeroData.DATA.has(hid) else ""
	var wname: String = str(WeaponData.get_data(wid).name) if wid != "" else "Vũ khí"
	var cur_mod: String = Global.lobby_weapon_mod
	box.add_child(UI.label("Gắn bùa cho binh khí khởi đầu (%s) — Thử ngay trên Hình nhân hoặc mang vào trận!" % wname, 13, Color(0.82, 0.94, 0.98), true))
	var cur_txt: String = WeaponMods.mod_name(cur_mod) if cur_mod != "" else "Chưa gắn"
	box.add_child(UI.label("Xu: %d   |   Bùa hiện gắn: %s" % [Global.coins, cur_txt], 14, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 14, Color(0.55, 0.98, 0.72)))
	for mid in WeaponMods.ORDER:
		var md: Dictionary = WeaponMods.DATA[mid]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var nm := UI.label(str(md.name), 15, WeaponMods.mod_color(str(mid)))
		nm.custom_minimum_size = Vector2(150, 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(nm)
		var ds := UI.label(str(md.desc), 13, Color(0.9, 0.88, 0.85))
		ds.custom_minimum_size = Vector2(235, 0)
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(ds)
		var active: bool = cur_mod == str(mid)
		var cost: int = 40
		var b := UI.button("Đang gắn" if active else "Phù phép (%dx)" % cost, func():
			if Global.coins < cost or Global.lobby_weapon_mod == str(mid):
				return
			Global.coins -= cost
			Global.lobby_weapon_mod = str(mid)
			if wid != "":
				Global.set_weapon_mod(wid, str(mid))
			Global.save_game()
			Sfx.play("forge")
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(1032, 430), "Gắn bùa %s!" % str(md.name), WeaponMods.mod_color(str(mid)))
			open_enchant("Đã gắn bùa %s lên %s!" % [str(md.name), wname]), 13, 132.0)
		b.disabled = active or Global.coins < cost
		row.add_child(b)
	_end(box)


# ------------------------------------------------------------------ Tượng Thần Hộ Mệnh

func open_shrine(last_msg: String = "") -> void:
	var box := _begin("Tượng Thần Hộ Mệnh")
	box.add_child(UI.label("Dâng lễ vật cầu thần phúc bảo hộ tướng sĩ trong lượt xuất trận sắp tới.", 13, Color(0.92, 0.9, 0.84), true))
	var cur_bid: String = Global.lobby_shrine_buff
	var cur_name: String = str(Global.SHRINE_BLESSINGS[cur_bid].name) if cur_bid != "" and Global.SHRINE_BLESSINGS.has(cur_bid) else "Chưa cầu"
	box.add_child(UI.label("Xu: %d   |   Thần phúc: %s" % [Global.coins, cur_name], 14, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 14, Color(0.55, 0.98, 0.72)))
	for bid in ["ruou_thuoc", "giap_dong", "linh_khi"]:
		var sd: Dictionary = Global.SHRINE_BLESSINGS[bid]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var nm := UI.label(str(sd.name), 15, Color(1.0, 0.86, 0.4))
		nm.custom_minimum_size = Vector2(160, 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(nm)
		var ds := UI.label(str(sd.desc), 13, Color(0.9, 0.88, 0.85))
		ds.custom_minimum_size = Vector2(235, 0)
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(ds)
		var active: bool = cur_bid == bid
		var cost: int = int(sd.cost)
		var b := UI.button("Đã phù hộ" if active else "Cầu phúc (%dx)" % cost, func():
			if Global.coins < cost or Global.lobby_shrine_buff == bid:
				return
			Global.coins -= cost
			Global.lobby_shrine_buff = bid
			Global.save_game()
			Sfx.play("level_clear")
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(546, 114), "%s ứng linh!" % str(sd.name), Color(1.0, 0.9, 0.35))
			open_shrine("Nhận %s cho lượt xuất trận tới!" % str(sd.name)), 13, 130.0)
		b.disabled = active or Global.coins < cost
		row.add_child(b)
	_end(box)


# ------------------------------------------------------------------ Rương Quân Nhu

func open_supply(last_msg: String = "") -> void:
	var box := _begin("Rương Quân Nhu Tiền Tiêu")
	var can_claim: bool = lobby != null and not bool(lobby.supply_claimed)
	box.add_child(UI.label("Nhận khẩu phần tiếp tế miễn phí mỗi lần ghé sảnh hoặc mua nhanh nguyên liệu rèn.", 13, Color(0.9, 0.88, 0.84), true))
	box.add_child(UI.label("Xu hiện có: %d" % Global.coins, 14, Color(1.0, 0.88, 0.45)))
	if last_msg != "":
		box.add_child(UI.label(last_msg, 14, Color(0.55, 0.98, 0.72)))
	var b_claim := UI.button("Nhận tiếp tế miễn phí (+25 xu & +1 nguyên liệu)" if can_claim else "Đã nhận tiếp tế lần này", func():
		if lobby == null or bool(lobby.supply_claimed):
			return
		lobby.supply_claimed = true
		Global.coins += 25
		var mid: String = str(MaterialData.ORDER[randi() % MaterialData.ORDER.size()])
		Global.materials[mid] = Global.material_count(mid) + 1
		Global.save_game()
		Sfx.play("chest_open")
		var msg := "Tiếp tế: +25 xu & +1 %s!" % str(MaterialData.DATA[mid].name)
		if lobby.has_method("on_station_fx"):
			lobby.on_station_fx(Vector2(814, 114), msg, Color(1.0, 0.88, 0.38))
		open_supply(msg), 14, 340.0)
	b_claim.disabled = not can_claim
	box.add_child(UI.center(b_claim))

	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 8)
	box.add_child(grid)
	for mid in MaterialData.ORDER:
		var md: Dictionary = MaterialData.DATA[mid]
		var col_box := VBoxContainer.new()
		col_box.add_theme_constant_override("separation", 3)
		var hdr := HBoxContainer.new()
		hdr.alignment = BoxContainer.ALIGNMENT_CENTER
		hdr.add_theme_constant_override("separation", 3)
		hdr.add_child(_mat_icon(str(mid), 13.0))
		hdr.add_child(UI.label("%s (%d)" % [str(md.name), Global.material_count(str(mid))], 12, md.color))
		col_box.add_child(hdr)
		var buy_b := UI.button("+2 (25 xu)", func():
			if Global.coins < 25:
				return
			Global.coins -= 25
			Global.materials[str(mid)] = Global.material_count(str(mid)) + 2
			Global.save_game()
			Sfx.play("buy")
			open_supply("Đã đổi +2 %s!" % str(md.name)), 12, 110.0)
		buy_b.disabled = Global.coins < 25
		col_box.add_child(buy_b)
		grid.add_child(col_box)
	_end(box)


# ------------------------------------------------------------------ Linh Thú & Hồ Cá Koi

func open_pet(pet_id: String, last_msg: String = "") -> void:
	if not Global.PETS.has(pet_id):
		return
	var pinfo: Dictionary = Global.PETS[pet_id]
	var box := _begin(str(pinfo.name))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var at := AtlasTexture.new()
	at.atlas = Art.tex(str(pinfo.sprite))
	at.region = Rect2(0, 0, int(pinfo.fw), int(pinfo.fh))
	var pic := TextureRect.new()
	pic.texture = at
	pic.custom_minimum_size = Vector2(72, 64)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(pic)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(340, 0)
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)
	var sub := UI.label(str(pinfo.title), 14, pinfo.color)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(sub)
	var role_l := UI.label("Ra trận: %s" % str(pinfo.role), 13, Color(0.95, 0.92, 0.86), true)
	role_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(role_l)
	var gift_l := UI.label("Tại sảnh: %s" % str(pinfo.gift), 12, Color(0.68, 0.94, 0.78), true)
	gift_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(gift_l)

	if last_msg != "":
		box.add_child(UI.label(last_msg, 14, Color(0.55, 0.98, 0.72)))

	var gifted: bool = lobby != null and lobby.pet_gifts.has(pet_id)
	var is_active: bool = (Global.selected_pet == pet_id)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	box.add_child(btns)

	var b_pet := UI.button("Đã vuốt ve lần này" if gifted else "Vuốt ve & Nhận quà", func():
		if lobby == null or lobby.pet_gifts.has(pet_id):
			return
		lobby.pet_gifts[pet_id] = true
		var msg := ""
		match pet_id:
			"dog":
				Global.coins += 15
				msg = "Cún Vàng vẫy đuôi đào được +15 xu!"
			"cat":
				Global.coins += 10
				msg = "Mèo Tam Thể mang lại +10 xu may mắn!"
			"rooster":
				var pool: Array[String] = ["dong", "sat", "go_lim", "hoa_duoc"]
				var mid: String = pool[randi() % pool.size()]
				Global.materials[mid] = Global.material_count(mid) + 1
				msg = "Gà Trống tặng +1 %s!" % str(MaterialData.DATA[mid].name)
			"crane":
				Global.materials["hoa_duoc"] = Global.material_count("hoa_duoc") + 1
				msg = "Chim Hạc nhả tặng +1 Hoa dược!"
		Global.save_game()
		Sfx.play("coin")
		if lobby.has_method("on_pet_interacted"):
			lobby.on_pet_interacted(pet_id, msg, pinfo.color)
		elif lobby.has_method("on_station_fx") and lobby.player != null and is_instance_valid(lobby.player):
			lobby.on_station_fx(lobby.player.global_position, msg, pinfo.color)
		open_pet(pet_id, msg), 14, 170.0)
	b_pet.disabled = gifted
	btns.add_child(b_pet)

	var b_follow := UI.button("Để ở lại sảnh" if is_active else "Đồng hành ra trận", func():
		var next_id: String = "" if Global.selected_pet == pet_id else pet_id
		Global.select_pet(next_id)
		if Net != null and Net.is_online():
			Net.request_set_pet(next_id)
		if lobby != null and lobby.has_method("refresh_pet_stations"):
			lobby.refresh_pet_stations()
		Sfx.play("pickup_weapon")
		var msg := ("%s đã nghỉ tại sảnh." % str(pinfo.name)) if next_id == "" else ("%s sẽ theo bạn ra trận!" % str(pinfo.name))
		open_pet(pet_id, msg), 14, 175.0)
	btns.add_child(b_follow)
	btns.add_child(UI.button("Đóng", close, 14, 100.0))


func open_pond(last_msg: String = "") -> void:
	var box := _begin("Hồ Cá Koi Vườn Sen")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var at := AtlasTexture.new()
	at.atlas = Art.tex("world/animal_koi_gold.png")
	at.region = Rect2(0, 0, 22, 12)
	var pic := TextureRect.new()
	pic.texture = at
	pic.custom_minimum_size = Vector2(66, 40)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(pic)

	var desc := UI.label("Rắc thính cho đàn cá Koi ăn (1 lần mỗi ghé sảnh): ngắm đàn cá tụ lại ăn mồi, nhận ngay +10 xu và phúc lành Linh Khí (+60 năng lượng lượt tới).", 13, Color(0.92, 0.94, 0.96), true)
	desc.custom_minimum_size = Vector2(330, 0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(desc)

	if last_msg != "":
		box.add_child(UI.label(last_msg, 14, Color(0.55, 0.98, 0.72)))

	var fed: bool = lobby != null and bool(lobby.koi_fed)
	var b_feed := UI.button("Đã cho cá ăn lần này" if fed else "Rắc thính cho cá ăn (Miễn phí)", func():
		if lobby == null or bool(lobby.koi_fed):
			return
		lobby.koi_fed = true
		Global.coins += 10
		if not Global.lobby_garden_buffs.has("linh_khi"):
			Global.lobby_garden_buffs.append("linh_khi")
		Global.save_game()
		Sfx.play("coin")
		if lobby.has_method("on_koi_fed"):
			lobby.on_koi_fed()
		open_pond("Đàn cá Koi tụ lại ăn mồi! +10 xu & +1 phúc lành Linh Khí."), 14, 260.0)
	b_feed.disabled = fed
	box.add_child(UI.center(b_feed))
	_end(box)


# ------------------------------------------------------------------ Thương Nhân Nguyên Liệu

const MAT_SHOP_PRICES: Dictionary = {
	"dong": {"buy1": 10, "buy5": 42, "sell1": 5},
	"sat": {"buy1": 12, "buy5": 50, "sell1": 6},
	"go_lim": {"buy1": 12, "buy5": 50, "sell1": 6},
	"hoa_duoc": {"buy1": 15, "buy5": 65, "sell1": 8},
	"yeu_hon": {"buy1": 28, "buy5": 120, "sell1": 14},
	"ngoc_than": {"buy1": 55, "buy5": 240, "sell1": 28},
}


func _mat_buy_price(mid: String, qty: int) -> int:
	var pdict: Dictionary = MAT_SHOP_PRICES.get(mid, {})
	var base: int = int(pdict.get("buy5" if qty >= 5 else "buy1", 10))
	if lobby != null and str(lobby.merchant_deal) == mid:
		return maxi(1, int(ceil(float(base) * 0.7)))
	return base


func open_mat_merchant(tab: String = "buy", last_msg: String = "") -> void:
	var box := _begin("Thương Nhân Nguyên Liệu")
	box.add_theme_constant_override("separation", 2 if tab == "trade" else 3)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var b_buy := UI.button("Mua nguyên liệu", open_mat_merchant.bind("buy", ""), 13, 150.0)
	b_buy.disabled = (tab == "buy")
	var b_trade := UI.button("Bán & Gói ưu đãi", open_mat_merchant.bind("trade", ""), 13, 155.0)
	b_trade.disabled = (tab == "trade")
	tabs.add_child(b_buy)
	tabs.add_child(b_trade)

	# Thanh kho xu + 6 nguyên liệu
	var inv := HBoxContainer.new()
	inv.alignment = BoxContainer.ALIGNMENT_CENTER
	inv.add_theme_constant_override("separation", 8)
	box.add_child(inv)
	inv.add_child(UI.label("Xu: %d" % Global.coins, 12, Color(1.0, 0.88, 0.45)))
	for mid in MaterialData.ORDER:
		var md: Dictionary = MaterialData.DATA[mid]
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_mat_icon(str(mid), 11.0))
		var cnt: int = Global.material_count(str(mid))
		cell.add_child(UI.label(str(cnt), 12, md.color if cnt > 0 else Color(0.55, 0.55, 0.55)))
		inv.add_child(cell)

	var deal_id: String = str(lobby.merchant_deal) if lobby != null else ""
	var banner_txt: String = last_msg
	var banner_col := Color(0.55, 0.98, 0.72)
	if banner_txt == "" and tab == "buy":
		if deal_id != "" and MaterialData.DATA.has(deal_id):
			banner_txt = "Ưu đãi ghé sảnh hôm nay: %s giảm 30%%!" % str(MaterialData.DATA[deal_id].name)
			banner_col = Color(1.0, 0.88, 0.38)
		else:
			banner_txt = "Chọn nguyên liệu cần mua cho Lò rèn hoặc bán bớt đồ dư."
			banner_col = Color(0.86, 0.9, 0.94)
	if banner_txt != "":
		box.add_child(UI.label(banner_txt, 11, banner_col))

	if tab == "trade":
		# Gói Thợ Rèn 1 lần/ghé sảnh
		var bundle_bought: bool = lobby != null and bool(lobby.merchant_bundle_bought)
		var bpanel := PanelContainer.new()
		bpanel.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if not bundle_bought else "ui/panel.png"))
		box.add_child(bpanel)
		var brow := HBoxContainer.new()
		brow.add_theme_constant_override("separation", 8)
		bpanel.add_child(brow)
		var bdesc := UI.label("Gói Thợ Rèn (60 xu): +3 Đồng, +3 Sắt, +2 Gỗ lim, +1 Yêu hồn", 12, Color(1.0, 0.9, 0.45))
		bdesc.custom_minimum_size = Vector2(315, 0)
		bdesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		brow.add_child(bdesc)
		var b_pack := UI.button("Đã mua lần này" if bundle_bought else "Mua gói (60x)", func():
			if lobby == null or bool(lobby.merchant_bundle_bought) or Global.coins < 60:
				return
			Global.coins -= 60
			lobby.merchant_bundle_bought = true
			Global.materials["dong"] = Global.material_count("dong") + 3
			Global.materials["sat"] = Global.material_count("sat") + 3
			Global.materials["go_lim"] = Global.material_count("go_lim") + 2
			Global.materials["yeu_hon"] = Global.material_count("yeu_hon") + 1
			Global.save_game()
			Sfx.play("chest_open")
			lobby.on_station_fx(lobby._mat_shop_pos, "Mua Gói Thợ Rèn!", Color(1.0, 0.88, 0.35))
			open_mat_merchant("trade", "Đã nhận Gói Thợ Rèn: +3 Đồng, +3 Sắt, +2 Gỗ lim, +1 Yêu hồn!"), 12, 128.0)
		b_pack.disabled = bundle_bought or Global.coins < 60
		brow.add_child(b_pack)

	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", UI.panel_box("ui/panel.png"))
	box.add_child(list_panel)

	if tab == "buy":
		var list_box := VBoxContainer.new()
		list_box.add_theme_constant_override("separation", 2)
		list_panel.add_child(list_box)
		for mid_v in MaterialData.ORDER:
			var mid: String = str(mid_v)
			var md: Dictionary = MaterialData.DATA[mid]
			var have: int = Global.material_count(mid)
			var is_deal: bool = (mid == deal_id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			list_box.add_child(row)

			var icon_wrap := HBoxContainer.new()
			icon_wrap.custom_minimum_size = Vector2(180, 0)
			icon_wrap.add_theme_constant_override("separation", 5)
			icon_wrap.add_child(_mat_icon(mid, 12.0))
			var nm_txt: String = str(md.name) + (" (-30% ★)" if is_deal else "")
			var nm := UI.label(nm_txt, 12, Color(1.0, 0.9, 0.4) if is_deal else md.color)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			icon_wrap.add_child(nm)
			row.add_child(icon_wrap)

			var own_l := UI.label("Có: %d" % have, 11, Color(0.84, 0.88, 0.9))
			own_l.custom_minimum_size = Vector2(56, 0)
			own_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.add_child(own_l)

			var p1: int = _mat_buy_price(mid, 1)
			var p5: int = _mat_buy_price(mid, 5)
			var b1 := UI.button("Mua x1 (%dx)" % p1, func():
				if Global.coins < p1:
					return
				Global.coins -= p1
				Global.materials[mid] = Global.material_count(mid) + 1
				Global.save_game()
				Sfx.play("buy")
				if lobby != null and lobby.has_method("on_station_fx"):
					lobby.on_station_fx(lobby._mat_shop_pos, "+1 %s" % str(md.name), md.color)
				open_mat_merchant("buy", "Đã mua +1 %s (%d xu)!" % [str(md.name), p1]), 11, 100.0)
			b1.disabled = Global.coins < p1
			row.add_child(b1)

			var b5 := UI.button("Mua x5 (%dx)" % p5, func():
				if Global.coins < p5:
					return
				Global.coins -= p5
				Global.materials[mid] = Global.material_count(mid) + 5
				Global.save_game()
				Sfx.play("buy")
				if lobby != null and lobby.has_method("on_station_fx"):
					lobby.on_station_fx(lobby._mat_shop_pos, "+5 %s" % str(md.name), md.color)
				open_mat_merchant("buy", "Đã mua +5 %s (%d xu)!" % [str(md.name), p5]), 11, 108.0)
			b5.disabled = Global.coins < p5
			row.add_child(b5)
	else:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 4)
		list_panel.add_child(grid)
		for mid_v in MaterialData.ORDER:
			var mid: String = str(mid_v)
			var md: Dictionary = MaterialData.DATA[mid]
			var have: int = Global.material_count(mid)
			var s1: int = int(MAT_SHOP_PRICES[mid].sell1)
			var s5: int = s1 * 5
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 4)
			grid.add_child(cell)

			var icon_wrap := HBoxContainer.new()
			icon_wrap.custom_minimum_size = Vector2(96, 0)
			icon_wrap.add_theme_constant_override("separation", 4)
			icon_wrap.add_child(_mat_icon(mid, 11.0))
			var nm := UI.label("%s (%d)" % [str(md.name), have], 11, md.color)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			icon_wrap.add_child(nm)
			cell.add_child(icon_wrap)

			var bs1 := UI.button("Bán 1 (+%dx)" % s1, func():
				if Global.material_count(mid) < 1:
					return
				Global.materials[mid] = Global.material_count(mid) - 1
				if int(Global.materials[mid]) <= 0:
					Global.materials.erase(mid)
				Global.coins += s1
				Global.save_game()
				Sfx.play("coin")
				open_mat_merchant("trade", "Đã bán 1 %s (+%d xu)!" % [str(md.name), s1]), 10, 74.0)
			bs1.disabled = have < 1
			cell.add_child(bs1)

			var bs5 := UI.button("Bán 5 (+%dx)" % s5, func():
				if Global.material_count(mid) < 5:
					return
				Global.materials[mid] = Global.material_count(mid) - 5
				if int(Global.materials[mid]) <= 0:
					Global.materials.erase(mid)
				Global.coins += s5
				Global.save_game()
				Sfx.play("coin")
				open_mat_merchant("trade", "Đã bán 5 %s (+%d xu)!" % [str(md.name), s5]), 10, 82.0)
			bs5.disabled = have < 5
			cell.add_child(bs5)

	box.add_child(UI.center(UI.button("Đóng", close, 14, 120.0)))


# ------------------------------------------------------------------ Tầng Hầm: Thành Tựu, Bản Vẽ, Bảo Tàng

func open_achievements(cat: String = "all", last_msg: String = "") -> void:
	var hs := _hotpatch_sync()
	if hs != null:
		hs.ensure_autoloads_synced(get_tree())
	var box := _begin("Bia Thành Tựu Chiến Tích")
	box.add_theme_constant_override("separation", 4)

	var total_ach: int = AchievementData.ORDER.size()
	var done_count: int = 0
	for aid_v in AchievementData.ORDER:
		if AchievementData.is_completed(str(aid_v), Global):
			done_count += 1
	var unclaimed: int = Global.unclaimed_achievement_count()

	var hdr := HBoxContainer.new()
	hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr.add_theme_constant_override("separation", 12)
	box.add_child(hdr)
	hdr.add_child(UI.label("Tiến độ: %d / %d   |   Chờ nhận: %d" % [done_count, total_ach, unclaimed], 13, Color(1.0, 0.88, 0.45)))
	var b_all := UI.button("Nhận tất cả (%d)" % unclaimed if unclaimed > 0 else "Nhận tất cả", func():
		var claimed: Array = Global.claim_all_achievements()
		if not claimed.is_empty():
			Sfx.play("chest_open")
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(430, 1150), "Nhận %d thành tựu!" % claimed.size(), Color(1.0, 0.88, 0.35))
			open_achievements(cat, "Đã nhận thưởng %d mốc thành tựu!" % claimed.size()), 12, 138.0)
	b_all.disabled = unclaimed <= 0
	hdr.add_child(b_all)

	if last_msg != "":
		box.add_child(UI.label(last_msg, 12, Color(0.55, 0.98, 0.72)))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	var b_all_tab := UI.button("Tất cả", open_achievements.bind("all", ""), 11, 74.0)
	b_all_tab.disabled = (cat == "all")
	tabs.add_child(b_all_tab)
	for cid_v in AchievementData.CATEGORY_ORDER:
		var cid: String = str(cid_v)
		var cinfo: Dictionary = AchievementData.CATEGORIES[cid]
		var cb := UI.button(str(cinfo.name), open_achievements.bind(cid, ""), 11, 88.0)
		cb.disabled = (cat == cid)
		cb.modulate = cinfo.color if cat == cid else Color(0.88, 0.88, 0.92)
		tabs.add_child(cb)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(576, 178)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for aid_v in AchievementData.ORDER:
		var aid: String = str(aid_v)
		var info: Dictionary = AchievementData.DATA[aid]
		if cat != "all" and str(info.get("cat", "")) != cat:
			continue
		var cur: int = Global.achievement_progress(aid)
		var target: int = maxi(1, int(info.get("target", 1)))
		var is_claimed: bool = Global.is_achievement_claimed(aid)
		var can_claim: bool = Global.can_claim_achievement(aid)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if can_claim else "ui/panel.png"))
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var left := VBoxContainer.new()
		left.custom_minimum_size = Vector2(416, 0)
		left.add_theme_constant_override("separation", 1)
		row.add_child(left)

		var top_line := HBoxContainer.new()
		top_line.add_theme_constant_override("separation", 8)
		left.add_child(top_line)
		var title_col := Color(1.0, 0.88, 0.36) if can_claim else (Color(0.58, 0.96, 0.65) if is_claimed else Color(0.95, 0.92, 0.86))
		var nm := UI.label(str(info.get("name", aid)), 13, title_col)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_line.add_child(nm)
		var prog_l := UI.label("%d / %d" % [mini(cur, target), target], 12, Color(0.62, 0.96, 0.72) if cur >= target else Color(0.84, 0.84, 0.88))
		top_line.add_child(prog_l)

		var dsc := UI.label(str(info.get("desc", "")), 11, Color(0.84, 0.82, 0.78), true)
		dsc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.add_child(dsc)

		var rew_row := HBoxContainer.new()
		rew_row.add_theme_constant_override("separation", 7)
		left.add_child(rew_row)
		var rew_c: int = int(info.get("coins", 0))
		if rew_c > 0:
			rew_row.add_child(UI.label("+%d xu" % rew_c, 11, Color(1.0, 0.88, 0.45)))
		var mats: Dictionary = info.get("mats", {})
		for mid_v in MaterialData.ORDER:
			var mid: String = str(mid_v)
			if not mats.has(mid):
				continue
			var mc := HBoxContainer.new()
			mc.add_theme_constant_override("separation", 2)
			mc.add_child(_mat_icon(mid, 10.0))
			mc.add_child(UI.label("+%d" % int(mats[mid]), 11, MaterialData.DATA[mid].color))
			rew_row.add_child(mc)
		var bp_wid: String = str(info.get("blueprint", ""))
		if bp_wid != "":
			var wname: String = str(WeaponData.DATA.get(bp_wid, {}).get("name", bp_wid))
			var bgrade: String = MaterialData.blueprint_grade(bp_wid)
			rew_row.add_child(UI.label("📜 Bản vẽ (%s): %s" % [bgrade, wname], 11, Color(0.55, 0.92, 1.0)))

		var btn_txt: String = "Đã nhận ✓" if is_claimed else ("Nhận thưởng" if can_claim else "Chưa đạt")
		var b_claim := UI.button(btn_txt, func():
			if not Global.can_claim_achievement(aid):
				return
			Global.claim_achievement(aid)
			Sfx.play("chest_open")
			if lobby != null and lobby.has_method("on_station_fx"):
				lobby.on_station_fx(Vector2(430, 1150), "Nhận: %s!" % str(info.get("name", aid)), Color(1.0, 0.88, 0.35))
			open_achievements(cat, "Đã nhận thưởng mốc '%s'!" % str(info.get("name", aid))), 12, 112.0)
		b_claim.disabled = not can_claim
		row.add_child(b_claim)

	_end(box)


func _blueprint_progress_bar(have: int, need: int, ready: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(maxi(1, need))
	bar.value = float(clampi(have, 0, maxi(1, need)))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(118, 9)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.06, 0.12, 0.92)
	bg.border_color = Color(0.45, 0.35, 0.24, 0.8)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.42, 0.96, 0.66) if ready else Color(0.45, 0.82, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func open_blueprints(filter_key: String = "all", last_msg: String = "") -> void:
	var hs := _hotpatch_sync()
	if hs != null:
		hs.ensure_autoloads_synced(get_tree())
	var box := _begin("Bàn Bản Vẽ Binh Khí")
	box.add_theme_constant_override("separation", 3)

	var all_bps: Array = MaterialData.all_blueprint_weapons()
	var total_bp: int = all_bps.size()
	var owned_bp: int = Global.owned_blueprint_count()
	var ready_cnt: int = Global.assemblable_blueprint_count()

	var hdr_txt := "Bản vẽ đã mở: %d / %d   |   Xu: %d" % [owned_bp, total_bp, Global.coins]
	if ready_cnt > 0:
		hdr_txt += "   |   ✨ Đủ mảnh ghép: %d" % ready_cnt
	box.add_child(UI.label(hdr_txt, 13, Color(1.0, 0.88, 0.45)))

	var sub_lbl := UI.label("Cần có Bản vẽ để rèn vũ khí. Vũ khí xịn Cấp 3–5 cần nhặt Mảnh Bản Vẽ từ Rương ải & Trùm để ghép!", 10, Color(0.84, 0.90, 0.96), true)
	sub_lbl.custom_minimum_size = Vector2(560, 0)
	box.add_child(sub_lbl)

	if ready_cnt > 0:
		var b_asm_all := UI.button("✨ Ghép tất cả bản vẽ đủ mảnh (%d)" % ready_cnt, func():
			var assembled_names: PackedStringArray = []
			for wv in MaterialData.all_blueprint_weapons():
				var wid_a: String = str(wv)
				if Global.can_assemble_blueprint(wid_a) and Global.assemble_blueprint(wid_a):
					assembled_names.append(str(WeaponData.DATA.get(wid_a, {}).get("name", wid_a)))
			if not assembled_names.is_empty():
				if Sfx != null:
					Sfx.play("forge")
				if lobby != null and lobby.has_method("on_station_fx"):
					lobby.on_station_fx(Vector2(680, 1255), "Ghép %d bản vẽ!" % assembled_names.size(), Color(0.55, 0.98, 0.72))
				open_blueprints(filter_key, "Đã ghép %d bản vẽ: %s!" % [assembled_names.size(), ", ".join(assembled_names)])
			else:
				open_blueprints(filter_key, ""), 11, 290.0)
		b_asm_all.custom_minimum_size = Vector2(290.0, 24.0)
		b_asm_all.modulate = Color(0.75, 1.0, 0.85)
		box.add_child(UI.center(b_asm_all))

	if last_msg != "":
		box.add_child(UI.label(last_msg, 11, Color(0.55, 0.98, 0.72)))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 2)
	box.add_child(tabs)
	var tab_specs: Array = [
		["all", "Tất cả (%d)" % total_bp, 78.0],
		["owned", "Đã sở hữu", 70.0],
		["fragments", "🧩 Mảnh ghép", 84.0],
		["basic", "Cơ bản (1-2)", 76.0],
		["mid", "Trung cấp (3)", 80.0],
		["advanced", "Nâng cao (4)", 76.0],
		["legendary", "★ Huyền Thoại (5)", 104.0],
	]
	for spec in tab_specs:
		var gk: String = str(spec[0])
		var tb := UI.button(str(spec[1]), open_blueprints.bind(gk, ""), 11, float(spec[2]))
		tb.disabled = (filter_key == gk)
		if gk == "legendary":
			tb.modulate = WeaponData.TIER_COLORS[5] if filter_key == gk else Color(1.0, 0.84, 0.55)
		elif gk == "fragments" and ready_cnt > 0:
			tb.modulate = Color(0.55, 1.0, 0.78)
		tabs.add_child(tb)

	var scroll_h: float = 162.0 - (26.0 if ready_cnt > 0 else 0.0) - (16.0 if last_msg != "" else 0.0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(586, scroll_h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var items: Array = []
	for wv in all_bps:
		var wid_s: String = str(wv)
		var tier: int = int(WeaponData.DATA.get(wid_s, {}).get("tier", 1))
		match filter_key:
			"owned":
				if not Global.owns_blueprint(wid_s):
					continue
			"fragments":
				if Global.owns_blueprint(wid_s) or Global.fragment_count(wid_s) <= 0:
					continue
			"basic":
				if tier > 2:
					continue
			"mid":
				if tier != 3:
					continue
			"advanced":
				if tier != 4:
					continue
			"legendary":
				if tier != 5:
					continue
		items.append(wid_s)

	if filter_key == "fragments":
		items.sort_custom(func(a: String, b: String) -> bool:
			var ra: int = 0 if Global.can_assemble_blueprint(a) else 1
			var rb: int = 0 if Global.can_assemble_blueprint(b) else 1
			if ra != rb:
				return ra < rb
			var ta: int = int(WeaponData.DATA.get(a, {}).get("tier", 1))
			var tb: int = int(WeaponData.DATA.get(b, {}).get("tier", 1))
			if ta != tb:
				return ta > tb
			return str(WeaponData.DATA.get(a, {}).get("name", a)) < str(WeaponData.DATA.get(b, {}).get("name", b)))

	if items.is_empty():
		var empty_bp_msg := "Chưa có mảnh bản vẽ nào đang ghép. Mở Rương ải & hạ Trùm để nhặt Mảnh Bản Vẽ!" if filter_key == "fragments" else "Chưa sở hữu bản vẽ nào trong mục này. Mở Rương, hạ Trùm hoặc nhận thưởng Thành tựu để mở!"
		list.add_child(UI.label(empty_bp_msg, 12, Color(0.85, 0.82, 0.78)))

	for wid_v in items:
		var wid: String = str(wid_v)
		var w: Dictionary = WeaponData.DATA.get(wid, {})
		var wname: String = str(w.get("name", wid))
		var wtier: int = int(w.get("tier", 1))
		var tier_lbl: String = MaterialData.blueprint_tier_label(wid)
		var unlocked_bp: bool = Global.owns_blueprint(wid)
		var is_ach_bp: bool = MaterialData.is_achievement_blueprint(wid)
		var uses_frags: bool = MaterialData.uses_fragments(wid)
		var need_frags: int = Global.fragments_needed(wid)
		var have_frags: int = need_frags if unlocked_bp else Global.fragment_count(wid)
		var can_asm: bool = Global.can_assemble_blueprint(wid)
		var rec: Dictionary = MaterialData.recipe_for(wid)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.panel_box("ui/panel_gold.png" if (unlocked_bp or can_asm) else "ui/panel.png"))
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		card.add_child(row)

		var wicon := TextureRect.new()
		wicon.texture = Art.tex("weapons/%s.png" % wid)
		wicon.custom_minimum_size = Vector2(34, 22)
		wicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked_bp and not can_asm:
			wicon.modulate = Color(0.42, 0.42, 0.48, 0.85)
		row.add_child(wicon)

		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(332, 0)
		info.add_theme_constant_override("separation", 1)
		row.add_child(info)

		var top_l := HBoxContainer.new()
		top_l.add_theme_constant_override("separation", 5)
		info.add_child(top_l)
		var name_col_ui: Color = WeaponData.tier_color(wid) if unlocked_bp else (Color(0.96, 0.94, 0.72) if can_asm else Color(0.72, 0.72, 0.78))
		var nl := UI.label("%s [Cấp %d · %s]" % [wname, wtier, tier_lbl], 12, name_col_ui)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_l.add_child(nl)
		var st_txt := "✓ Đã mở bản vẽ" if unlocked_bp else ("✨ Đủ mảnh ghép!" if can_asm else "🔒 Chưa mở")
		var st_col := Color(0.55, 0.96, 0.65) if unlocked_bp else (Color(0.55, 1.0, 0.78) if can_asm else Color(1.0, 0.72, 0.38))
		var stl := UI.label(st_txt, 11, st_col)
		top_l.add_child(stl)

		if unlocked_bp:
			var owned_src := "✓ Sẵn sàng rèn tại Lò Rèn"
			if is_ach_bp:
				var src_aid: String = AchievementData.blueprint_source(wid)
				var src_name: String = str(AchievementData.DATA.get(src_aid, {}).get("name", "Thành tựu Tầng Hầm"))
				owned_src = "Thành tựu: %s" % src_name
			var srcl := UI.label(owned_src, 10, Color(0.78, 0.88, 0.84))
			srcl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info.add_child(srcl)
		elif is_ach_bp:
			var src_aid2: String = AchievementData.blueprint_source(wid)
			var src_name2: String = str(AchievementData.DATA.get(src_aid2, {}).get("name", "Thành tựu Tầng Hầm"))
			var achl := UI.label("🏆 Mở khóa tại Bảng Thành Tựu (%s)" % src_name2, 10, Color(1.0, 0.84, 0.45))
			achl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info.add_child(achl)
		elif uses_frags:
			var frow := HBoxContainer.new()
			frow.add_theme_constant_override("separation", 5)
			info.add_child(frow)
			var ficon := TextureRect.new()
			ficon.texture = Art.tex("items/blueprint_frag.png")
			ficon.custom_minimum_size = Vector2(12, 12)
			ficon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ficon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			frow.add_child(ficon)
			frow.add_child(_blueprint_progress_bar(have_frags, need_frags, can_asm))
			var flbl := UI.label("🧩 Mảnh: %d / %d" % [have_frags, need_frags], 10, Color(0.55, 1.0, 0.78) if can_asm else Color(0.84, 0.90, 0.98))
			flbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			frow.add_child(flbl)
			if not can_asm:
				var fsrc := UI.label("Nhặt mảnh từ Rương ải & Trùm (%d/%d)" % [have_frags, need_frags], 10, Color(0.76, 0.82, 0.90))
				fsrc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				info.add_child(fsrc)
		else:
			var srow := HBoxContainer.new()
			srow.add_theme_constant_override("separation", 4)
			info.add_child(srow)
			var sicon := TextureRect.new()
			sicon.texture = Art.tex("items/blueprint_scroll.png")
			sicon.custom_minimum_size = Vector2(12, 12)
			sicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			srow.add_child(sicon)
			var ssrc := UI.label("📜 Nhặt bản vẽ từ Rương ải & Tinh nhuệ", 10, Color(0.78, 0.84, 0.92))
			ssrc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			srow.add_child(ssrc)

		if not rec.is_empty():
			_add_cost_row(info, int(rec.get("coins", 0)), rec.get("mats", {}))

		var b_sfx := UI.button("🔊", _preview_weapon_sfx.bind(wid, w), 12, 32.0)
		row.add_child(b_sfx)

		if unlocked_bp:
			var b_forge := UI.button("Tới Lò Rèn", open_forge.bind("craft"), 11, 108.0)
			b_forge.modulate = Color(0.82, 0.96, 1.0)
			row.add_child(b_forge)
		elif can_asm:
			var b_asm := UI.button("Ghép Bản Vẽ", func():
				if Global.assemble_blueprint(wid):
					if Sfx != null:
						Sfx.play("forge")
					if lobby != null and lobby.has_method("on_station_fx"):
						lobby.on_station_fx(Vector2(680, 1255), "Ghép bản vẽ %s!" % wname, WeaponData.tier_color(wid))
					open_blueprints(filter_key, "Đã ghép bản vẽ %s! Có thể rèn tại Lò Rèn." % wname), 11, 108.0)
			b_asm.modulate = Color(0.65, 1.0, 0.80)
			row.add_child(b_asm)
		else:
			var b_lk := UI.button("Chưa mở khóa", func(): pass, 11, 108.0)
			b_lk.disabled = true
			row.add_child(b_lk)

	_end(box)


func open_weapon_gallery(tier_filter: int = 0, bp_only: bool = false) -> void:
	var total_w: int = WeaponData.DATA.size()
	var box := _begin("Bảo Tàng Binh Khí — %d / %d" % [Global.discovered.size(), total_w])
	box.add_theme_constant_override("separation", 4)

	var st_runs: int = int(Global.stats.get("runs", 0))
	var st_kills: int = int(Global.stats.get("kills", 0))
	var st_bosses: int = int(Global.stats.get("bosses", 0))
	var st_mythic: int = int(Global.stats.get("mythic_bosses", 0))
	var st_crafted: int = int(Global.stats.get("crafted", 0))
	var stat_txt := "Lượt: %d  |  Giặc: %d  |  Trùm: %d  |  Thần thoại: %d  |  Rèn: %d  |  Màn cao nhất: %d" % [
		st_runs, st_kills, st_bosses, st_mythic, st_crafted, Global.best_level]
	box.add_child(UI.label(stat_txt, 11, Color(0.88, 0.9, 0.94)))

	var fbar := HBoxContainer.new()
	fbar.alignment = BoxContainer.ALIGNMENT_CENTER
	fbar.add_theme_constant_override("separation", 5)
	box.add_child(fbar)
	var b_all := UI.button("Tất cả", open_weapon_gallery.bind(0, false), 11, 66.0)
	b_all.disabled = (tier_filter == 0 and not bp_only)
	fbar.add_child(b_all)
	for t_i in range(1, 6):
		var bt := UI.button("Cấp %d" % t_i, open_weapon_gallery.bind(t_i, bp_only), 11, 58.0)
		bt.disabled = (tier_filter == t_i)
		bt.modulate = WeaponData.TIER_COLORS[t_i] if tier_filter == t_i else Color(0.86, 0.86, 0.9)
		fbar.add_child(bt)
	var b_bp := UI.button("📜 Bản vẽ", open_weapon_gallery.bind(tier_filter, not bp_only), 11, 88.0)
	b_bp.modulate = Color(0.55, 0.94, 1.0) if bp_only else Color(0.82, 0.82, 0.88)
	fbar.add_child(b_bp)

	var ids: Array = []
	for wid_v in WeaponData.DATA.keys():
		var wid: String = str(wid_v)
		var wd: Dictionary = WeaponData.DATA[wid]
		if tier_filter > 0 and int(wd.get("tier", 1)) != tier_filter:
			continue
		if bp_only and not MaterialData.requires_blueprint(wid):
			continue
		ids.append(wid)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ta: int = int(WeaponData.DATA[a].get("tier", 1))
		var tb: int = int(WeaponData.DATA[b].get("tier", 1))
		if ta != tb:
			return ta < tb
		return str(WeaponData.DATA[a].get("name", a)) < str(WeaponData.DATA[b].get("name", b)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(576, 178)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var gridc := GridContainer.new()
	gridc.columns = 7
	gridc.add_theme_constant_override("h_separation", 4)
	gridc.add_theme_constant_override("v_separation", 4)
	scroll.add_child(gridc)
	for wid_v in ids:
		var wid: String = str(wid_v)
		var known: bool = Global.discovered.has(wid)
		var is_bp: bool = MaterialData.requires_blueprint(wid)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(76, 46)
		var icon := TextureRect.new()
		icon.texture = Art.tex("weapons/%s.png" % wid)
		icon.custom_minimum_size = Vector2(76, 26)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.WHITE if known else Color(0, 0, 0, 0.75)
		cell.add_child(icon)
		var lbl_txt: String = str(WeaponData.DATA[wid].get("name", wid)) if known else ("📜 ???" if is_bp else "???")
		var lbl_col: Color = WeaponData.tier_color(wid) if known else (Color(0.52, 0.72, 0.85) if is_bp else Color(0.5, 0.5, 0.5))
		var nm := UI.label(lbl_txt, 10, lbl_col, true)
		cell.add_child(nm)
		gridc.add_child(cell)

	_end(box)
