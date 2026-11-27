extends Node2D
## Hiệu ứng thi triển chiêu thức riêng cho toàn bộ 28 kỹ năng anh hùng (v3.0.0).
## Dùng được cả trong trận (`spawn`) lẫn khung xem trước trong Sảnh (`draw_preview_fx`).

const Art = preload("res://scripts/art/art.gd")
const Fx = preload("res://scripts/effects/fx.gd")

const SKILL_META: Dictionary = {
	"song_trung": {"c1": Color(0.95, 0.28, 0.48), "c2": Color(1.0, 0.82, 0.34), "dur": 0.72, "range": 86.0},
	"co_lenh_me_linh": {"c1": Color(0.92, 0.20, 0.36), "c2": Color(1.0, 0.84, 0.30), "dur": 0.78, "range": 92.0},
	"voi_chien": {"c1": Color(0.98, 0.74, 0.22), "c2": Color(0.90, 0.28, 0.20), "dur": 0.68, "range": 96.0},
	"chieng_nui_nua": {"c1": Color(1.0, 0.80, 0.24), "c2": Color(1.0, 0.94, 0.62), "dur": 0.76, "range": 88.0},
	"coc_bach_dang": {"c1": Color(0.28, 0.76, 0.98), "c2": Color(0.86, 0.72, 0.40), "dur": 0.80, "range": 84.0},
	"thuy_trieu_dang": {"c1": Color(0.22, 0.68, 0.98), "c2": Color(0.75, 0.96, 1.0), "dur": 0.76, "range": 96.0},
	"nam_quoc_son_ha": {"c1": Color(1.0, 0.84, 0.32), "c2": Color(0.55, 0.92, 1.0), "dur": 0.82, "range": 82.0},
	"tuong_nhu_nguyet": {"c1": Color(0.52, 0.88, 0.72), "c2": Color(0.85, 0.96, 1.0), "dur": 0.78, "range": 92.0},
	"hich_tuong_si": {"c1": Color(0.90, 0.24, 0.22), "c2": Color(1.0, 0.82, 0.30), "dur": 0.82, "range": 84.0},
	"hoa_cong_bach_dang": {"c1": Color(1.0, 0.44, 0.14), "c2": Color(1.0, 0.84, 0.28), "dur": 0.78, "range": 98.0},
	"thuan_thien_kiem": {"c1": Color(0.36, 0.94, 0.64), "c2": Color(1.0, 0.88, 0.36), "dur": 0.80, "range": 84.0},
	"kim_quy_ho_gia": {"c1": Color(1.0, 0.86, 0.28), "c2": Color(0.55, 0.96, 0.78), "dur": 0.80, "range": 84.0},
	"than_toc": {"c1": Color(1.0, 0.28, 0.22), "c2": Color(1.0, 0.86, 0.32), "dur": 0.64, "range": 98.0},
	"hoa_ho_dai_phao": {"c1": Color(1.0, 0.42, 0.16), "c2": Color(1.0, 0.88, 0.34), "dur": 0.76, "range": 100.0},
	"hoa_hong": {"c1": Color(1.0, 0.48, 0.16), "c2": Color(1.0, 0.86, 0.30), "dur": 0.78, "range": 90.0},
	"nhat_tao_xung_kich": {"c1": Color(1.0, 0.44, 0.18), "c2": Color(1.0, 0.90, 0.42), "dur": 0.70, "range": 98.0},
	"hum_thieng": {"c1": Color(0.96, 0.58, 0.18), "c2": Color(1.0, 0.86, 0.36), "dur": 0.76, "range": 94.0},
	"phuc_kich_yen_the": {"c1": Color(0.34, 0.88, 0.52), "c2": Color(0.76, 1.0, 0.84), "dur": 0.72, "range": 94.0},
	"keo_phao": {"c1": Color(0.54, 0.76, 0.36), "c2": Color(1.0, 0.78, 0.28), "dur": 0.80, "range": 96.0},
	"boc_pha_nghin_can": {"c1": Color(1.0, 0.54, 0.18), "c2": Color(1.0, 0.90, 0.42), "dur": 0.82, "range": 94.0},
	"ngua_sat": {"c1": Color(1.0, 0.38, 0.18), "c2": Color(1.0, 0.86, 0.32), "dur": 0.74, "range": 98.0},
	"nho_tre_danh_giac": {"c1": Color(0.42, 0.96, 0.46), "c2": Color(1.0, 0.90, 0.36), "dur": 0.78, "range": 92.0},
	"mua_ten_co_loa": {"c1": Color(0.96, 0.78, 0.28), "c2": Color(0.42, 0.96, 0.90), "dur": 0.78, "range": 100.0},
	"loa_thanh_tran": {"c1": Color(0.92, 0.72, 0.24), "c2": Color(0.46, 0.94, 0.88), "dur": 0.80, "range": 96.0},
	"thuy_long_trieu": {"c1": Color(0.24, 0.72, 0.98), "c2": Color(1.0, 0.88, 0.36), "dur": 0.82, "range": 92.0},
	"tram_trung_hao_quang": {"c1": Color(0.32, 0.82, 1.0), "c2": Color(1.0, 0.86, 0.44), "dur": 0.82, "range": 94.0},
	"doi_non_lap_be": {"c1": Color(0.54, 0.78, 0.36), "c2": Color(0.96, 0.74, 0.34), "dur": 0.80, "range": 98.0},
	"thach_giap_tan_vien": {"c1": Color(0.76, 0.58, 0.32), "c2": Color(0.56, 0.92, 0.44), "dur": 0.82, "range": 90.0},
}

var skill_id: String = ""
var dir: Vector2 = Vector2.RIGHT
var color_override: Color = Color(0, 0, 0, 0)
var syn: int = 0
var dur: float = 0.75
var _t: float = 0.0
var _mid_burst_done: bool = false
var _glow_layer: Node2D = null
var _pulse_light: PointLight2D = null


static func spawn(parent: Node, pos: Vector2, aim_dir: Vector2, p_skill_id: String, p_color_override: Color = Color(0, 0, 0, 0), p_syn: int = 0) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var fx := new()
	fx.position = pos
	fx.dir = aim_dir.normalized() if aim_dir.length_squared() > 0.0001 else Vector2.RIGHT
	fx.skill_id = p_skill_id
	fx.color_override = p_color_override
	fx.syn = clampi(p_syn, 0, 2)
	var meta: Dictionary = SKILL_META.get(p_skill_id, {})
	fx.dur = float(meta.get("dur", 0.74))
	parent.add_child(fx)
	return fx


static func draw_preview_fx(ci: CanvasItem, p_skill_id: String, center: Vector2, target: Vector2, p: float, t: float, p_color_override: Color = Color(0, 0, 0, 0)) -> void:
	if ci == null:
		return
	var cp: float = clampf(p, 0.0, 1.0)
	if cp <= 0.001:
		return
	_draw_skill_layers(ci, p_skill_id, center, target, cp, t, 2, p_color_override, false)
	_draw_skill_layers(ci, p_skill_id, center, target, cp, t, 2, p_color_override, true)


func _ready() -> void:
	z_index = 5
	_glow_layer = _GlowLayer.new()
	_glow_layer.owner_fx = self
	_glow_layer.z_index = 1
	_glow_layer.material = Art.additive()
	add_child(_glow_layer)

	var cols: Array = _resolve_colors(skill_id, color_override)
	var c1: Color = cols[0]
	var c2: Color = cols[1]
	_pulse_light = Art.light(c1.lerp(c2, 0.35), 2.1, 0.95)
	add_child(_pulse_light)

	if is_inside_tree() and get_parent() != null:
		var p_cnt: int = 12 + syn * 4
		var p_dir: Vector2 = dir if _is_directional(skill_id) else Vector2.UP
		var p_spread: float = 55.0 if _is_directional(skill_id) else 180.0
		Fx.particles(get_parent(), global_position, c1, p_cnt, 105.0, 0.42, -25.0, 1.9, p_spread, p_dir, c2)


func _process(delta: float) -> void:
	_t += delta
	var p: float = clampf(_t / maxf(dur, 0.01), 0.0, 1.0)
	if not _mid_burst_done and p >= 0.36:
		_mid_burst_done = true
		if is_inside_tree() and get_parent() != null:
			var cols: Array = _resolve_colors(skill_id, color_override)
			var burst_pos: Vector2 = global_position + dir * 22.0 if _is_directional(skill_id) else global_position
			Fx.particles(get_parent(), burst_pos, cols[1], 8 + syn * 3, 85.0, 0.34, -15.0, 1.6, 150.0, dir, cols[0])
	if _pulse_light != null:
		var env: float = sin(p * PI)
		_pulse_light.energy = env * (1.15 + 0.15 * float(syn))
		_pulse_light.texture_scale = 1.8 + env * 1.4
	if _t >= dur:
		queue_free()
		return
	queue_redraw()
	if _glow_layer != null:
		_glow_layer.queue_redraw()


func _draw() -> void:
	var p: float = clampf(_t / maxf(dur, 0.01), 0.0, 1.0)
	var meta: Dictionary = SKILL_META.get(skill_id, {})
	var reach: float = float(meta.get("range", 88.0)) * (1.0 + 0.08 * float(syn))
	_draw_skill_layers(self, skill_id, Vector2.ZERO, dir * reach, p, _t, syn, color_override, false)


func _draw_glow(ci: CanvasItem) -> void:
	var p: float = clampf(_t / maxf(dur, 0.01), 0.0, 1.0)
	var meta: Dictionary = SKILL_META.get(skill_id, {})
	var reach: float = float(meta.get("range", 88.0)) * (1.0 + 0.08 * float(syn))
	_draw_skill_layers(ci, skill_id, Vector2.ZERO, dir * reach, p, _t, syn, color_override, true)


class _GlowLayer extends Node2D:
	var owner_fx = null
	func _draw() -> void:
		if owner_fx != null and is_instance_valid(owner_fx):
			owner_fx._draw_glow(self)


# ------------------------------------------------------------------ Helpers

static func _is_directional(sid: String) -> bool:
	return sid in [
		"voi_chien", "thuy_trieu_dang", "tuong_nhu_nguyet", "hoa_cong_bach_dang",
		"than_toc", "hoa_ho_dai_phao", "nhat_tao_xung_kich", "hum_thieng",
		"phuc_kich_yen_the", "keo_phao", "boc_pha_nghin_can", "ngua_sat", "nho_tre_danh_giac",
		"mua_ten_co_loa", "doi_non_lap_be",
	]


static func _resolve_colors(sid: String, ov: Color) -> Array:
	var meta: Dictionary = SKILL_META.get(sid, {})
	var c1: Color = meta.get("c1", Color(1.0, 0.84, 0.34))
	var c2: Color = meta.get("c2", Color(1.0, 0.96, 0.72))
	if ov.a > 0.01:
		c1 = ov
		c2 = ov.lightened(0.38)
	return [c1, c2]


static func _ease_out_cubic(x: float) -> float:
	var t := 1.0 - clampf(x, 0.0, 1.0)
	return 1.0 - t * t * t


static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var t := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + c3 * t * t * t + c1 * t * t


static func _fade_env(p: float, hold_end: float = 0.68) -> float:
	if p < 0.14:
		return clampf(p / 0.14, 0.0, 1.0)
	if p > hold_end:
		return clampf(1.0 - (p - hold_end) / maxf(1.0 - hold_end, 0.01), 0.0, 1.0)
	return 1.0


static func _draw_diamond(ci: CanvasItem, pos: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	if rx <= 0.2 or ry <= 0.2:
		return
	var f := Vector2.from_angle(rot)
	var s := Vector2(-f.y, f.x)
	var pts := PackedVector2Array([
		pos + f * rx,
		pos + s * ry,
		pos - f * rx,
		pos - s * ry,
	])
	ci.draw_colored_polygon(pts, col)


static func _draw_star(ci: CanvasItem, pos: Vector2, r_outer: float, r_inner: float, spikes: int, rot: float, col: Color) -> void:
	if r_outer <= 0.4 or spikes < 3:
		return
	var pts := PackedVector2Array()
	var n := spikes * 2
	for i in n:
		var ang := rot + TAU * float(i) / float(n)
		var rr := r_outer if i % 2 == 0 else r_inner
		pts.append(pos + Vector2.from_angle(ang) * rr)
	ci.draw_colored_polygon(pts, col)


static func _draw_crescent(ci: CanvasItem, pos: Vector2, radius: float, ang_mid: float, half_arc: float, thick: float, col: Color, segs: int = 12) -> void:
	if radius <= 1.0 or thick <= 0.3 or segs < 3:
		return
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(segs + 1):
		var frac := float(i) / float(segs)
		var a := ang_mid + lerpf(-half_arc, half_arc, frac)
		var taper := sin(frac * PI)
		var d := Vector2.from_angle(a)
		outer.append(pos + d * (radius + thick * 0.5 * taper))
		inner.append(pos + d * maxf(1.0, radius - thick * 0.5 * taper))
	var poly := PackedVector2Array()
	for pt in outer:
		poly.append(pt)
	for j in range(inner.size() - 2, 0, -1):
		poly.append(inner[j])
	ci.draw_colored_polygon(poly, col)


static func _draw_sword_icon(ci: CanvasItem, pos: Vector2, ang: float, length: float, col: Color, hilt_col: Color) -> void:
	var f := Vector2.from_angle(ang)
	var s := Vector2(-f.y, f.x)
	var tip := pos + f * (length * 0.65)
	var base := pos - f * (length * 0.35)
	var blade := PackedVector2Array([
		tip,
		pos + f * (length * 0.15) + s * (length * 0.11),
		base + s * (length * 0.08),
		base - s * (length * 0.08),
		pos + f * (length * 0.15) - s * (length * 0.11),
	])
	ci.draw_colored_polygon(blade, col)
	ci.draw_line(base + s * (length * 0.24), base - s * (length * 0.24), hilt_col, 2.0)
	ci.draw_line(base, base - f * (length * 0.22), hilt_col, 1.8)


static func _draw_flame_tongue(ci: CanvasItem, pos: Vector2, r: float, t: float, seed_off: float, c_out: Color, c_in: Color) -> void:
	var sway := sin(t * 14.0 + seed_off) * r * 0.24
	var h := r * (1.35 + 0.25 * sin(t * 18.0 + seed_off * 1.7))
	var outer := PackedVector2Array([
		pos + Vector2(-r * 0.65, r * 0.2),
		pos + Vector2(-r * 0.35 + sway * 0.4, -h * 0.45),
		pos + Vector2(sway, -h),
		pos + Vector2(r * 0.35 + sway * 0.4, -h * 0.45),
		pos + Vector2(r * 0.65, r * 0.2),
		pos + Vector2(0.0, r * 0.42),
	])
	ci.draw_colored_polygon(outer, c_out)
	var inner := PackedVector2Array([
		pos + Vector2(-r * 0.32, r * 0.15),
		pos + Vector2(sway * 0.6, -h * 0.62),
		pos + Vector2(r * 0.32, r * 0.15),
		pos + Vector2(0.0, r * 0.26),
	])
	ci.draw_colored_polygon(inner, c_in)


static func _draw_bolt(ci: CanvasItem, a: Vector2, b: Vector2, segs: int, jitter: float, seed_v: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array([a])
	var ab := b - a
	var perp := Vector2(-ab.y, ab.x).normalized() if ab.length_squared() > 0.01 else Vector2.UP
	for i in range(1, segs):
		var frac := float(i) / float(segs)
		var off := sin(seed_v * 9.3 + float(i) * 2.7) * jitter * sin(frac * PI)
		pts.append(a.lerp(b, frac) + perp * off)
	pts.append(b)
	ci.draw_polyline(pts, col, w)


# ------------------------------------------------------------------ 28 Bespoke Skill Renderers

static func _draw_skill_layers(ci: CanvasItem, sid: String, center: Vector2, target: Vector2, p: float, t: float, syn: int, ov: Color, glow: bool) -> void:
	var cols: Array = _resolve_colors(sid, ov)
	var c1: Color = cols[0]
	var c2: Color = cols[1]
	var env: float = _fade_env(p)
	var delta_v: Vector2 = target - center
	var dist: float = maxf(delta_v.length(), 28.0)
	var d: Vector2 = delta_v.normalized() if delta_v.length_squared() > 0.001 else Vector2.RIGHT
	var perp := Vector2(-d.y, d.x)
	var ang := d.angle()
	var sc := clampf(dist / 88.0, 0.55, 1.35)

	match sid:
		"song_trung":
			var eo := _ease_out_cubic(p)
			var twin_off := perp * (16.0 * sc)
			if not glow:
				ci.draw_arc(center, (12.0 + eo * 26.0) * sc, 0.0, TAU, 28, Color(c1, 0.45 * env), 1.6)
				for k_s in 2:
					var sgn: float = -1.0 if k_s == 0 else 1.0
					var sp: Vector2 = center + twin_off * sgn
					ci.draw_circle(sp, 7.5 * sc * _ease_out_back(minf(p * 2.5, 1.0)), Color(c1, 0.28 * env))
					ci.draw_arc(sp, 9.5 * sc, 0.0, TAU, 16, Color(c2, 0.65 * env), 1.3)
					var wp: Vector2 = sp.lerp(target + twin_off * sgn * 0.25, _ease_out_cubic(clampf(p * 1.35, 0.0, 1.0)))
					_draw_crescent(ci, wp, 16.0 * sc, ang, 0.95, 5.5 * sc, Color(c1, 0.85 * env), 10)
			else:
				for k_s in 2:
					var sgn: float = -1.0 if k_s == 0 else 1.0
					var wp: Vector2 = (center + twin_off * sgn).lerp(target + twin_off * sgn * 0.25, _ease_out_cubic(clampf(p * 1.35, 0.0, 1.0)))
					_draw_crescent(ci, wp, 16.0 * sc, ang, 0.85, 3.0 * sc, Color(c2, 0.72 * env), 10)
					ci.draw_circle(center + twin_off * sgn, 11.0 * sc, Color(c1, 0.28 * env))
				_draw_star(ci, center.lerp(target, minf(p * 1.2, 1.0)), 11.0 * sc * env, 4.0 * sc, 4, t * 4.0, Color(c2, 0.55 * env))

		"co_lenh_me_linh":
			var rise := _ease_out_back(minf(p * 2.2, 1.0))
			var pole_base := center - perp * (11.0 * sc) + Vector2(0, 8.0 * sc)
			var pole_top := pole_base + Vector2(0, -30.0 * sc * rise)
			var wave := sin(t * 14.0) * 3.0 * sc
			if not glow:
				ci.draw_arc(center, (10.0 + _ease_out_cubic(p) * 38.0) * sc, 0.0, TAU, 32, Color(c1, 0.75 * env), 2.2)
				ci.draw_line(pole_base, pole_top, Color(0.88, 0.72, 0.30, env), 2.2)
				var flag := PackedVector2Array([
					pole_top,
					pole_top + d * (18.0 * sc) + Vector2(0, 4.0 * sc + wave),
					pole_top + d * (9.0 * sc) + Vector2(0, 11.0 * sc + wave * 0.5),
					pole_top + Vector2(0, 14.0 * sc),
				])
				ci.draw_colored_polygon(flag, Color(c1, 0.92 * env))
				ci.draw_polyline(flag, Color(c2, 0.9 * env), 1.2)
				for k in 2:
					var sgn := -1.0 if k == 0 else 1.0
					var lp := (center + perp * (12.0 * sc * sgn)).lerp(target + perp * (6.0 * sc * sgn), _ease_out_cubic(clampf(p * 1.4 - 0.1 * k, 0.0, 1.0)))
					_draw_diamond(ci, lp, 9.0 * sc, 3.2 * sc, ang, Color(c2, 0.85 * env))
			else:
				ci.draw_circle(pole_top, 12.0 * sc, Color(c2, 0.35 * env))
				for r in 6:
					var ra := ang + lerpf(-0.9, 0.9, float(r) / 5.0)
					ci.draw_line(center, center + Vector2.from_angle(ra) * (34.0 * sc * _ease_out_cubic(p)), Color(c2, 0.42 * env), 1.6)

		"voi_chien":
			var charge_p := _ease_out_cubic(minf(p * 1.25, 1.0))
			var head := center.lerp(target, charge_p)
			if not glow:
				for i in 3:
					var fp := center.lerp(head, float(i + 1) / 3.5)
					ci.draw_circle(fp + Vector2(0, 6.0 * sc), (7.5 - float(i) * 1.5) * sc, Color(0.75, 0.62, 0.42, 0.35 * env))
				var cone := PackedVector2Array([
					head + d * (14.0 * sc),
					head - d * (10.0 * sc) + perp * (16.0 * sc),
					head - d * (4.0 * sc),
					head - d * (10.0 * sc) - perp * (16.0 * sc),
				])
				ci.draw_colored_polygon(cone, Color(c1, 0.32 * env))
				for k_s in 2:
					var sgn: float = -1.0 if k_s == 0 else 1.0
					_draw_crescent(ci, head + perp * (5.0 * sc * sgn), 13.0 * sc, ang + 0.18 * sgn, 0.65, 3.8 * sc, Color(1.0, 0.96, 0.82, 0.92 * env), 8)
				ci.draw_arc(head, 16.0 * sc, ang - 0.85, ang + 0.85, 16, Color(c2, 0.85 * env), 2.4)
			else:
				ci.draw_circle(head + d * (6.0 * sc), 16.0 * sc, Color(c1, 0.38 * env))
				_draw_crescent(ci, head + d * (4.0 * sc), 18.0 * sc, ang, 0.9, 4.5 * sc, Color(c1, 0.55 * env), 10)

		"chieng_nui_nua":
			var eo := _ease_out_cubic(p)
			if not glow:
				ci.draw_circle(center, 11.0 * sc * (1.0 + 0.14 * sin(t * 28.0)), Color(0.76, 0.54, 0.18, 0.48 * env))
				ci.draw_arc(center, 11.0 * sc, 0.0, TAU, 24, Color(c1, 0.95 * env), 2.2)
				for ring_i in 3:
					var rp := clampf(p * 1.35 - float(ring_i) * 0.18, 0.0, 1.0)
					if rp <= 0.0:
						continue
					var rr := (10.0 + _ease_out_cubic(rp) * 44.0) * sc
					var ra := (1.0 - rp) * 0.95
					ci.draw_arc(center, rr, 0.0, TAU, 36, Color(c1, ra), 2.6 - float(ring_i) * 0.5)
					for tk in 12:
						var ta := TAU * float(tk) / 12.0 + t * 2.2 * (1.0 if ring_i % 2 == 0 else -1.0)
						var tp := center + Vector2.from_angle(ta) * rr
						ci.draw_line(tp * 0.96 + center * 0.04, tp + Vector2.from_angle(ta) * (4.0 * sc), Color(c2, ra), 1.6)
			else:
				ci.draw_circle(center, (16.0 + eo * 26.0) * sc, Color(c1, 0.22 * env))
				_draw_star(ci, center, 16.0 * sc * (1.0 - p * 0.4), 6.0 * sc, 8, t * 2.5, Color(c2, 0.55 * env))

		"coc_bach_dang":
			var eo := _ease_out_cubic(p)
			if not glow:
				for wi in 2:
					var wr := (14.0 + eo * 32.0 + float(wi) * 10.0) * sc
					ci.draw_arc(center, wr, 0.0, TAU, 32, Color(c1, (0.72 - 0.25 * float(wi)) * env), 1.8)
				var cnt := 7 + syn * 2
				for si in cnt:
					var frac := float(si) / float(cnt)
					var sa := ang + lerpf(-1.6, 1.6, frac) if cnt > 5 else TAU * frac
					var dist_s := (24.0 + float(si % 2) * 14.0) * sc
					var sp := center + Vector2(cos(sa) * dist_s, sin(sa) * dist_s * 0.72)
					var delay := float(si) * 0.035
					var sp_p := clampf((p - delay) / 0.24, 0.0, 1.0)
					if sp_p <= 0.0:
						continue
					var sh := 16.0 * sc * _ease_out_back(sp_p) * clampf((1.0 - p) * 3.5, 0.0, 1.0)
					var stake := PackedVector2Array([
						sp + Vector2(-3.2 * sc, 2.0 * sc),
						sp + Vector2(0.0, -sh),
						sp + Vector2(3.2 * sc, 2.0 * sc),
					])
					ci.draw_colored_polygon(stake, Color(0.56, 0.40, 0.24, env))
					ci.draw_line(sp + Vector2(0.0, -sh), sp + Vector2(1.0 * sc, 1.0 * sc), Color(c2, 0.85 * env), 1.1)
			else:
				ci.draw_circle(center, (18.0 + eo * 20.0) * sc, Color(c1, 0.25 * env))
				for di in 6:
					var da := TAU * float(di) / 6.0 + t * 1.5
					ci.draw_circle(center + Vector2.from_angle(da) * (24.0 * sc * eo), 3.0 * sc, Color(c2, 0.65 * env))

		"thuy_trieu_dang":
			if not glow:
				for wi in 3:
					var wp := clampf(p * 1.3 - float(wi) * 0.16, 0.0, 1.0)
					if wp <= 0.0:
						continue
					var wpos := center.lerp(target, _ease_out_cubic(wp))
					var w_alpha := (1.0 - wp * 0.55) * env
					var wave_r := (18.0 + float(wi) * 5.0) * sc
					_draw_crescent(ci, wpos - d * (8.0 * sc), wave_r, ang, 1.05, 7.5 * sc, Color(c1, 0.72 * w_alpha), 12)
					ci.draw_arc(wpos - d * (6.0 * sc), wave_r + 2.0 * sc, ang - 0.95, ang + 0.95, 14, Color(c2, 0.9 * w_alpha), 2.0)
				for sk in 3:
					var skp := center.lerp(target, 0.35 + float(sk) * 0.25)
					ci.draw_colored_polygon(PackedVector2Array([
						skp + Vector2(-2.5 * sc, 4.0 * sc),
						skp + Vector2(0.0, -9.0 * sc * env),
						skp + Vector2(2.5 * sc, 4.0 * sc),
					]), Color(0.75, 0.62, 0.38, 0.75 * env))
			else:
				var gp := center.lerp(target, _ease_out_cubic(p))
				_draw_crescent(ci, gp - d * (6.0 * sc), 22.0 * sc, ang, 0.9, 5.0 * sc, Color(c2, 0.55 * env), 12)

		"nam_quoc_son_ha":
			var rr := (25.0 + sin(p * PI) * 8.0) * sc
			if not glow:
				ci.draw_circle(center, rr, Color(c1, 0.14 * env))
				ci.draw_arc(center, rr, 0.0, TAU, 36, Color(c1, 0.92 * env), 2.2)
				ci.draw_arc(center, rr - 4.5 * sc, t * 2.5, t * 2.5 + PI * 1.5, 24, Color(c2, 0.72 * env), 1.4)
				for gi in 10:
					var ga := t * 2.2 + TAU * float(gi) / 10.0
					var gp := center + Vector2.from_angle(ga) * (rr + 4.5 * sc)
					var gt := Vector2.from_angle(ga + PI * 0.5)
					ci.draw_line(gp - gt * (2.6 * sc), gp + gt * (2.6 * sc), Color(c1, 0.92 * env), 2.0)
					ci.draw_line(gp - Vector2.from_angle(ga) * (1.8 * sc), gp + Vector2.from_angle(ga) * (1.8 * sc), Color(c2, 0.85 * env), 1.4)
			else:
				ci.draw_circle(center, rr * 1.08, Color(c1, 0.22 * env))
				var ref_p := (center + d * rr).lerp(target, _ease_out_cubic(fmod(p * 2.0, 1.0)))
				_draw_diamond(ci, ref_p, 7.0 * sc, 2.8 * sc, ang, Color(c2, 0.85 * env))

		"tuong_nhu_nguyet":
			var wall_ctr := center + d * (24.0 * sc)
			var rise := _ease_out_back(minf(p * 2.1, 1.0))
			if not glow:
				ci.draw_arc(center, 25.0 * sc, ang - 1.1, ang + 1.1, 18, Color(c1, 0.65 * env), 2.0)
				for bi in 5:
					var ba := ang + lerpf(-0.9, 0.9, float(bi) / 4.0)
					var bp := center + Vector2.from_angle(ba) * (25.0 * sc)
					var bh := 15.0 * sc * rise
					ci.draw_line(bp + Vector2(0, 4.0 * sc), bp + Vector2(0, 4.0 * sc - bh), Color(0.45, 0.82, 0.45, env), 3.0)
					ci.draw_line(bp + Vector2(-1.0, 4.0 * sc - bh), bp + Vector2(2.0, 4.0 * sc - bh + 3.0 * sc), Color(c2, env), 1.2)
				for ai in 5:
					var ap_frac := clampf(p * 1.45 - 0.18 - float(ai) * 0.05, 0.0, 1.0)
					if ap_frac <= 0.0:
						continue
					var a_ang := ang + lerpf(-0.38, 0.38, float(ai) / 4.0)
					var a_dir := Vector2.from_angle(a_ang)
					var ap := wall_ctr.lerp(target + perp * lerpf(-12.0, 12.0, float(ai) / 4.0) * sc, _ease_out_cubic(ap_frac))
					ci.draw_line(ap - a_dir * (10.0 * sc), ap + a_dir * (4.0 * sc), Color(c2, 0.92 * env), 1.8)
					_draw_diamond(ci, ap + a_dir * (4.0 * sc), 3.8 * sc, 1.8 * sc, a_ang, Color(1, 1, 1, env))
			else:
				ci.draw_circle(wall_ctr, 18.0 * sc, Color(c1, 0.28 * env))

		"hich_tuong_si":
			var eo := _ease_out_cubic(p)
			if not glow:
				ci.draw_arc(center, 15.0 * sc, 0.0, TAU, 24, Color(c2, 0.85 * env), 1.8)
				_draw_star(ci, center, 13.0 * sc, 5.5 * sc, 8, t * 1.5, Color(c1, 0.45 * env))
				for k in 2:
					var rp := fmod(p * 2.2 + float(k) * 0.5, 1.0)
					ci.draw_arc(center, (14.0 + rp * 34.0) * sc, 0.0, TAU, 28, Color(c2, (1.0 - rp) * 0.8 * env), 2.0)
				for si in 3:
					var sa := ang + lerpf(-0.9, 0.9, float(si) / 2.0)
					var sp := center + Vector2.from_angle(sa) * (22.0 * sc)
					var ph := 20.0 * sc * clampf(p * 2.5 - float(si) * 0.15, 0.0, 1.0) * env
					ci.draw_rect(Rect2(sp + Vector2(-2.5 * sc, -ph), Vector2(5.0 * sc, ph)), Color(c2, 0.42 * env))
					_draw_diamond(ci, sp + Vector2(0, -ph), 4.0 * sc, 5.0 * sc, 0.0, Color(c1, 0.85 * env))
			else:
				ci.draw_circle(center, (16.0 + eo * 18.0) * sc, Color(c2, 0.28 * env))

		"hoa_cong_bach_dang":
			if not glow:
				for bi in 5:
					var fan := lerpf(-0.42, 0.42, float(bi) / 4.0)
					var b_ang := ang + fan
					var b_dir := Vector2.from_angle(b_ang)
					var bp_t := _ease_out_cubic(clampf(p * 1.28 - float(absi(bi - 2)) * 0.06, 0.0, 1.0))
					var bp := center.lerp(center + b_dir * dist, bp_t)
					var b_perp := Vector2(-b_dir.y, b_dir.x)
					var hull := PackedVector2Array([
						bp + b_dir * (8.0 * sc),
						bp - b_dir * (5.0 * sc) + b_perp * (3.8 * sc),
						bp - b_dir * (7.0 * sc),
						bp - b_dir * (5.0 * sc) - b_perp * (3.8 * sc),
					])
					ci.draw_colored_polygon(hull, Color(0.45, 0.24, 0.12, env))
					_draw_flame_tongue(ci, bp - b_dir * (2.0 * sc), 5.5 * sc, t, float(bi) * 1.9, Color(c1, 0.9 * env), Color(c2, 0.95 * env))
			else:
				for bi in 5:
					var b_dir := Vector2.from_angle(ang + lerpf(-0.42, 0.42, float(bi) / 4.0))
					var bp := center.lerp(center + b_dir * dist, _ease_out_cubic(clampf(p * 1.28, 0.0, 1.0)))
					ci.draw_circle(bp, 8.5 * sc * env, Color(c1, 0.42 * env))

		"thuan_thien_kiem":
			var orb_r := 26.0 * sc
			var cnt := 3 + syn
			if not glow:
				ci.draw_arc(center, orb_r, 0.0, TAU, 28, Color(c1, 0.48 * env), 1.5)
				for bi in cnt:
					var ba := t * 7.0 + TAU * float(bi) / float(cnt)
					var bp := center + Vector2(cos(ba) * orb_r, sin(ba) * orb_r * 0.72)
					_draw_crescent(ci, center, orb_r, ba - 0.35, 0.5, 4.0 * sc, Color(c1, 0.45 * env), 8)
					_draw_sword_icon(ci, bp, ba + PI * 0.5, 16.0 * sc, Color(c1, 0.95 * env), Color(c2, 0.95 * env))
			else:
				ci.draw_circle(center, 18.0 * sc, Color(c1, 0.25 * env))
				_draw_star(ci, center, 16.0 * sc * env, 4.5 * sc, 4, t * 3.0, Color(c2, 0.55 * env))
				for bi in cnt:
					var ba := t * 7.0 + TAU * float(bi) / float(cnt)
					var bp := center + Vector2(cos(ba) * orb_r, sin(ba) * orb_r * 0.72)
					ci.draw_circle(bp, 6.5 * sc, Color(c2, 0.52 * env))

		"kim_quy_ho_gia":
			var sh_r := (24.0 + sin(p * PI) * 6.0) * sc
			if not glow:
				ci.draw_circle(center, sh_r, Color(c1, 0.18 * env))
				var hex := PackedVector2Array()
				for hi in 6:
					var ha := t * 1.4 + TAU * float(hi) / 6.0
					hex.append(center + Vector2.from_angle(ha) * sh_r)
				hex.append(hex[0])
				ci.draw_polyline(hex, Color(c1, 0.92 * env), 2.4)
				for hi in 6:
					ci.draw_line(center + (hex[hi] - center) * 0.42, hex[hi], Color(c2, 0.65 * env), 1.3)
				ci.draw_arc(center, sh_r * 0.44, 0.0, TAU, 12, Color(c2, 0.85 * env), 1.6)
			else:
				ci.draw_circle(center, sh_r * 1.15, Color(c1, 0.26 * env))
				for ri in 6:
					var ra := ang + lerpf(-0.9, 0.9, float(ri) / 5.0)
					var r0 := center + Vector2.from_angle(ra) * sh_r
					var r1 := r0 + Vector2.from_angle(ra) * (16.0 * sc * _ease_out_cubic(p))
					ci.draw_line(r0, r1, Color(c2, 0.72 * env), 2.0)

		"than_toc":
			var dash_p := _ease_out_cubic(minf(p * 1.3, 1.0))
			if not glow:
				for gi in 4:
					var gp := center.lerp(target, clampf(dash_p - float(gi) * 0.14, 0.0, 1.0))
					var ga := (1.0 - float(gi) * 0.22) * env
					_draw_diamond(ci, gp, 12.0 * sc, 7.0 * sc, ang, Color(c1, 0.45 * ga))
				for li in 5:
					var loff := perp * lerpf(-14.0, 14.0, float(li) / 4.0) * sc
					var lp0 := center.lerp(target, maxf(0.0, dash_p - 0.35)) + loff
					var lp1 := center.lerp(target, dash_p) + loff
					ci.draw_line(lp0, lp1, Color(c2, 0.85 * env), 1.8)
			else:
				var head := center.lerp(target, dash_p)
				ci.draw_circle(head, 15.0 * sc, Color(c2, 0.45 * env))
				_draw_crescent(ci, head, 16.0 * sc, ang, 0.85, 5.0 * sc, Color(c1, 0.65 * env), 10)

		"hoa_ho_dai_phao":
			if not glow:
				ci.draw_arc(center + d * (10.0 * sc), (8.0 + p * 16.0) * sc, ang - 1.0, ang + 1.0, 12, Color(c2, 0.85 * env), 2.2)
				for ci_i in 3:
					var ca := ang + lerpf(-0.28, 0.28, float(ci_i) / 2.0)
					var cd := Vector2.from_angle(ca)
					var cp_t := clampf(p * 1.4 - float(ci_i) * 0.12, 0.0, 1.0)
					var cp_pos := center.lerp(center + cd * dist, _ease_out_cubic(cp_t))
					ci.draw_line(cp_pos - cd * (16.0 * sc), cp_pos, Color(c1, 0.82 * env), 3.6 * sc)
					ci.draw_circle(cp_pos, 4.5 * sc, Color(0.22, 0.16, 0.14, env))
					ci.draw_circle(cp_pos, 3.0 * sc, Color(c2, env))
					if cp_t > 0.78:
						var ep := (cp_t - 0.78) / 0.22
						_draw_star(ci, cp_pos, (10.0 + ep * 14.0) * sc, 4.5 * sc, 7, float(ci_i) + t * 4.0, Color(c1, (1.0 - ep * 0.5) * env))
			else:
				for ci_i in 3:
					var cd := Vector2.from_angle(ang + lerpf(-0.28, 0.28, float(ci_i) / 2.0))
					var cp_t := clampf(p * 1.4 - float(ci_i) * 0.12, 0.0, 1.0)
					var cp_pos := center.lerp(center + cd * dist, _ease_out_cubic(cp_t))
					ci.draw_circle(cp_pos, 9.5 * sc * env, Color(c1, 0.48 * env))

		"hoa_hong":
			var pots := 6 + syn * 2
			if not glow:
				for hi in pots:
					var ha := TAU * float(hi) / float(pots) + 0.3
					var hdest := target.lerp(center, 0.25) + Vector2(cos(ha) * 26.0, sin(ha) * 18.0) * sc
					var arc_p := clampf(p * 2.2, 0.0, 1.0)
					var hpos := center.lerp(hdest, arc_p) + Vector2(0, -sin(arc_p * PI) * 16.0 * sc)
					if p < 0.42:
						ci.draw_circle(hpos, 3.2 * sc, Color(0.58, 0.24, 0.12, env))
						ci.draw_circle(hpos + Vector2(0, -2.0 * sc), 2.0 * sc, Color(c2, env))
					else:
						ci.draw_circle(hdest + Vector2(0, 3.0 * sc), 9.0 * sc, Color(c1, 0.30 * env))
						_draw_flame_tongue(ci, hdest, 6.2 * sc, t, float(hi) * 1.7, Color(c1, 0.88 * env), Color(c2, 0.95 * env))
			else:
				if p >= 0.38:
					var fctr := target.lerp(center, 0.25)
					ci.draw_circle(fctr, 26.0 * sc, Color(c1, 0.28 * env))
					ci.draw_circle(fctr, 14.0 * sc, Color(c2, 0.35 * env))

		"nhat_tao_xung_kich":
			var dp := _ease_out_cubic(minf(p * 1.25, 1.0))
			var prow := center.lerp(target, dp)
			if not glow:
				for pi in 4:
					var thr := 0.18 * float(pi)
					if p > thr:
						var fp := center.lerp(target, float(pi + 1) / 4.2)
						ci.draw_circle(fp + Vector2(0, 5.0 * sc), 8.0 * sc, Color(c1, 0.32 * env))
						_draw_flame_tongue(ci, fp, 7.0 * sc, t, float(pi) * 2.1, Color(c1, 0.9 * env), Color(c2, 0.95 * env))
				var wake := PackedVector2Array([
					prow + d * (12.0 * sc),
					prow - d * (14.0 * sc) + perp * (14.0 * sc),
					prow - d * (8.0 * sc),
					prow - d * (14.0 * sc) - perp * (14.0 * sc),
				])
				ci.draw_colored_polygon(wake, Color(c2, 0.65 * env))
			else:
				ci.draw_circle(prow, 15.0 * sc, Color(c1, 0.45 * env))
				ci.draw_line(center, prow, Color(c2, 0.48 * env), 4.0 * sc)

		"hum_thieng":
			var rp := _ease_out_cubic(minf(p * 1.35, 1.0))
			var tp := center.lerp(target, rp)
			if not glow:
				for wi in 2:
					ci.draw_arc(center, (12.0 + rp * 34.0 + float(wi) * 8.0) * sc, ang - 1.15, ang + 1.15, 16, Color(c1, (0.85 - 0.3 * float(wi)) * env), 2.2)
				var aura_p := PackedVector2Array([
					tp + d * (14.0 * sc),
					tp + perp * (9.0 * sc),
					tp - d * (12.0 * sc) + perp * (5.0 * sc),
					tp - d * (12.0 * sc) - perp * (5.0 * sc),
					tp - perp * (9.0 * sc),
				])
				ci.draw_colored_polygon(aura_p, Color(c1, 0.55 * env))
				if p > 0.32:
					var cp := clampf((p - 0.32) / 0.35, 0.0, 1.0)
					for ci_i in 3:
						var off := Vector2(-4.0 + float(ci_i) * 4.0, -7.0 + float(ci_i) * 4.5) * sc
						_draw_crescent(ci, target + off, 12.0 * sc * cp, -0.55, 0.85, 2.8 * sc, Color(c2, 0.95 * env), 8)
			else:
				ci.draw_circle(tp, 14.0 * sc, Color(c2, 0.45 * env))
				if p > 0.32:
					ci.draw_circle(target, 16.0 * sc, Color(c1, 0.42 * env))

		"phuc_kich_yen_the":
			if not glow:
				for si in 3:
					var sr := (12.0 + float(si) * 6.0 + sin(t * 8.0 + float(si)) * 2.0) * sc
					ci.draw_arc(center, sr, t * 2.0 + float(si), t * 2.0 + float(si) + PI * 1.3, 16, Color(c1, 0.55 * env), 2.2)
				for li in 6:
					var la := t * 3.5 + TAU * float(li) / 6.0
					var lp := center + Vector2.from_angle(la) * ((14.0 + p * 20.0) * sc)
					_draw_diamond(ci, lp, 4.2 * sc, 1.8 * sc, la + 0.7, Color(c1, 0.85 * env))
				for di in 5:
					var dp_t := clampf(p * 1.5 - 0.15 - float(di) * 0.04, 0.0, 1.0)
					if dp_t <= 0.0:
						continue
					var da := ang + lerpf(-0.34, 0.34, float(di) / 4.0)
					var ddir := Vector2.from_angle(da)
					var dp := center.lerp(center + ddir * dist, _ease_out_cubic(dp_t))
					ci.draw_line(dp - ddir * (14.0 * sc), dp, Color(c2, 0.92 * env), 1.8)
					_draw_diamond(ci, dp, 3.5 * sc, 1.5 * sc, da, Color(1, 1, 1, env))
			else:
				ci.draw_circle(center, 18.0 * sc, Color(c1, 0.28 * env))
				_draw_star(ci, center + Vector2(0, -6.0 * sc), 9.0 * sc * env, 2.5 * sc, 4, 0.0, Color(c2, 0.75 * env))

		"keo_phao":
			var gun_p := center + d * (24.0 * sc)
			var sh_p := fmod(p * 1.8, 1.0)
			var sh_pos := gun_p.lerp(target, sh_p) + Vector2(0, -sin(sh_p * PI) * 20.0 * sc)
			if not glow:
				ci.draw_circle(gun_p + Vector2(0, 4.0 * sc), 9.0 * sc, Color(0.45, 0.38, 0.25, 0.45 * env))
				ci.draw_rect(Rect2(gun_p + Vector2(-7.0, -2.0) * sc, Vector2(14.0, 6.0) * sc), Color(c1, env))
				ci.draw_line(gun_p, gun_p + d * (12.0 * sc) + Vector2(0, -4.0 * sc), Color(0.28, 0.34, 0.24, env), 3.0)
				ci.draw_arc(target, 12.0 * sc, 0.0, TAU, 20, Color(c2, 0.78 * env), 1.4)
				ci.draw_line(target - Vector2(14.0, 0) * sc, target + Vector2(14.0, 0) * sc, Color(c2, 0.78 * env), 1.2)
				ci.draw_line(target - Vector2(0, 14.0) * sc, target + Vector2(0, 14.0) * sc, Color(c2, 0.78 * env), 1.2)
				ci.draw_circle(sh_pos, 3.4 * sc, Color(c2, env))
			else:
				if sh_p > 0.78:
					var bp := (sh_p - 0.78) / 0.22
					_draw_star(ci, target, (10.0 + bp * 14.0) * sc, 5.0 * sc, 8, t * 3.0, Color(c2, (1.0 - bp * 0.4) * env))
					ci.draw_circle(target, 16.0 * sc, Color(1.0, 0.45, 0.15, 0.45 * env))

		"boc_pha_nghin_can":
			var bpos := center.lerp(target, 0.78)
			if not glow:
				if p < 0.38:
					var pulse := 0.5 + 0.5 * sin(t * 28.0)
					ci.draw_rect(Rect2(bpos - Vector2(6.0, 5.0) * sc, Vector2(12.0, 10.0) * sc), Color(0.42, 0.36, 0.24, env))
					ci.draw_arc(bpos, (14.0 + pulse * 6.0) * sc, 0.0, TAU, 24, Color(1.0, 0.28, 0.20, 0.85), 1.6)
					_draw_star(ci, bpos + Vector2(0, -7.0 * sc), 6.0 * sc, 2.2 * sc, 4, t * 8.0, Color(c2, 1.0))
				else:
					var ep := clampf((p - 0.38) / 0.62, 0.0, 1.0)
					var er := _ease_out_cubic(ep) * 38.0 * sc
					ci.draw_circle(bpos, er * 0.82, Color(0.22, 0.14, 0.10, (1.0 - ep) * 0.55))
					ci.draw_arc(bpos, er, 0.0, TAU, 32, Color(c1, (1.0 - ep) * 0.95), 3.0)
					_draw_star(ci, bpos, er * 0.85, er * 0.32, 10, 0.2, Color(c1, (1.0 - ep) * 0.88))
					_draw_star(ci, bpos, er * 0.52, er * 0.2, 8, 0.5, Color(c2, (1.0 - ep) * 0.95))
			else:
				if p >= 0.38:
					var ep := clampf((p - 0.38) / 0.62, 0.0, 1.0)
					ci.draw_circle(bpos, (14.0 + _ease_out_cubic(ep) * 26.0) * sc, Color(c1, (1.0 - ep) * 0.55))

		"ngua_sat":
			var hp := _ease_out_cubic(minf(p * 1.25, 1.0))
			var hpos := center.lerp(target, hp * 0.72)
			if not glow:
				for hi in 3:
					var fp := center.lerp(hpos, float(hi) / 3.0)
					ci.draw_arc(fp + Vector2(0, 6.0 * sc), 8.0 * sc, 0.0, TAU, 16, Color(c2, 0.55 * env), 1.4)
				for fi in 6:
					var fa := ang + lerpf(-0.42, 0.42, float(fi) / 5.0)
					var fdir := Vector2.from_angle(fa)
					var f_t := clampf(p * 1.4 - float(fi) * 0.05, 0.0, 1.0)
					var fpos := (hpos + d * (8.0 * sc)).lerp(target + fdir * (10.0 * sc), f_t)
					ci.draw_circle(fpos, (5.5 - float(fi % 2) * 1.2) * sc, Color(c1, 0.85 * env))
					ci.draw_circle(fpos, 2.5 * sc, Color(c2, 0.95 * env))
			else:
				var cone := PackedVector2Array([
					hpos + d * (6.0 * sc),
					target + perp * (18.0 * sc),
					target - perp * (18.0 * sc),
				])
				ci.draw_colored_polygon(cone, Color(c1, 0.32 * env))
				ci.draw_circle(hpos, 14.0 * sc, Color(c2, 0.45 * env))

		"nho_tre_danh_giac":
			var sweep_p := _ease_out_cubic(minf(p * 1.35, 1.0))
			if not glow:
				for ki in 6:
					var ka := ang + lerpf(-1.1, 1.1, float(ki) / 5.0)
					ci.draw_line(center, center + Vector2.from_angle(ka) * (20.0 * sc * sweep_p), Color(0.52, 0.42, 0.24, 0.8 * env), 1.5)
				_draw_crescent(ci, center + d * (8.0 * sc), 32.0 * sc, ang - 0.8 + sweep_p * 1.6, 1.15, 7.0 * sc, Color(c1, 0.88 * env), 14)
				for li in 5:
					var la := ang + lerpf(-1.2, 1.2, float(li) / 4.0) + sweep_p * 0.6
					var lp := center + Vector2.from_angle(la) * (26.0 * sc + sin(t * 10.0 + float(li)) * 4.0 * sc)
					_draw_diamond(ci, lp, 4.5 * sc, 1.6 * sc, la + 0.5, Color(c1, 0.9 * env))
				if p > 0.28:
					_draw_bolt(ci, target + Vector2(0, -42.0 * sc), target, 6, 7.0 * sc, t * 2.0, Color(c2, 0.95 * env), 2.2)
			else:
				_draw_crescent(ci, center + d * (8.0 * sc), 32.0 * sc, ang - 0.8 + sweep_p * 1.6, 1.0, 4.0 * sc, Color(c2, 0.6 * env), 12)
				if p > 0.28:
					_draw_bolt(ci, target + Vector2(0, -42.0 * sc), target, 6, 7.0 * sc, t * 2.0, Color(1, 1, 1, 0.85 * env), 1.4)
					ci.draw_circle(target, 14.0 * sc, Color(c1, 0.45 * env))

		"mua_ten_co_loa":
			var fan_cnt := 7 + syn * 2
			var eo := _ease_out_cubic(minf(p * 1.35, 1.0))
			if not glow:
				# Nỏ Thần Kim Quy golden bow arc + hexagonal turtle halo
				ci.draw_arc(center, 22.0 * sc, ang - 1.35, ang + 1.35, 22, Color(c1, 0.92 * env), 2.4)
				ci.draw_line(center + Vector2.from_angle(ang - 1.35) * (22.0 * sc), center + Vector2.from_angle(ang + 1.35) * (22.0 * sc), Color(c2, 0.72 * env), 1.3)
				var hex := PackedVector2Array()
				for hi in 6:
					var ha := t * 1.8 + TAU * float(hi) / 6.0
					hex.append(center + Vector2.from_angle(ha) * (16.0 * sc))
				hex.append(hex[0])
				ci.draw_polyline(hex, Color(c1, 0.55 * env), 1.4)
				# Fanning 180-deg volley of Kim Quy arrows
				for ai in fan_cnt:
					var frac := float(ai) / float(maxi(fan_cnt - 1, 1))
					var aa := ang + lerpf(-1.25, 1.25, frac)
					var adir := Vector2.from_angle(aa)
					var ap_t := _ease_out_cubic(clampf(p * 1.5 - absf(frac - 0.5) * 0.25, 0.0, 1.0))
					var apos := (center + adir * (14.0 * sc)).lerp(center + adir * (dist * 1.02), ap_t)
					ci.draw_line(apos - adir * (15.0 * sc), apos, Color(c1, 0.9 * env), 1.8)
					_draw_diamond(ci, apos + adir * (3.0 * sc), 4.2 * sc, 1.8 * sc, aa, Color(c2, 0.95 * env))
			else:
				_draw_crescent(ci, center + d * (6.0 * sc), 24.0 * sc, ang, 1.3, 4.5 * sc, Color(c1, 0.45 * env), 14)
				for ai in fan_cnt:
					var frac := float(ai) / float(maxi(fan_cnt - 1, 1))
					var aa := ang + lerpf(-1.25, 1.25, frac)
					var adir := Vector2.from_angle(aa)
					var ap_t := _ease_out_cubic(clampf(p * 1.5 - absf(frac - 0.5) * 0.25, 0.0, 1.0))
					var apos := (center + adir * (14.0 * sc)).lerp(center + adir * (dist * 1.02), ap_t)
					ci.draw_circle(apos, 4.2 * sc * env, Color(c2, 0.6 * env))
				ci.draw_circle(center, 15.0 * sc * (1.0 - eo * 0.3), Color(c2, 0.24 * env))

		"loa_thanh_tran":
			var eo := _ease_out_cubic(p)
			var rise := _ease_out_back(minf(p * 2.1, 1.0))
			if not glow:
				# Triple concentric spiral rings of Thành Cổ Loa
				for ri in 3:
					var rr := (16.0 + float(ri) * 10.0) * sc
					var rot_a := t * (2.6 - float(ri) * 0.6) * (1.0 if ri % 2 == 0 else -1.0)
					ci.draw_arc(center, rr, rot_a, rot_a + PI * 1.55, 24, Color(c1, (0.85 - float(ri) * 0.18) * env), 1.8)
				# Central Nỏ Liên Châu turret frame
				var tpos := center + d * (18.0 * sc)
				ci.draw_circle(tpos, 7.5 * sc * rise, Color(0.54, 0.36, 0.14, env))
				ci.draw_arc(tpos, 10.5 * sc * rise, ang - 1.0, ang + 1.0, 14, Color(c1, env), 2.2)
				for bi in 4:
					var bt := fmod(p * 2.4 + float(bi) * 0.25, 1.0)
					var ba := ang + sin(float(bi) * 2.1) * 0.24
					var bdir := Vector2.from_angle(ba)
					var bpos := (tpos + bdir * (8.0 * sc)).lerp(target + bdir * (10.0 * sc), _ease_out_cubic(bt))
					ci.draw_line(bpos - bdir * (12.0 * sc), bpos, Color(c2, 0.92 * env), 1.8)
					_draw_diamond(ci, bpos, 3.6 * sc, 1.6 * sc, ba, Color(1, 1, 1, env))
			else:
				ci.draw_circle(center, (20.0 + eo * 18.0) * sc, Color(c1, 0.24 * env))
				_draw_star(ci, center + d * (18.0 * sc), 12.0 * sc * env, 4.0 * sc, 6, t * 3.5, Color(c2, 0.62 * env))

		"thuy_long_trieu":
			var orbit_r := (26.0 + sin(p * PI) * 8.0) * sc
			if not glow:
				ci.draw_arc(center, orbit_r, 0.0, TAU, 32, Color(c1, 0.52 * env), 2.0)
				ci.draw_arc(center, orbit_r * 0.68, t * 3.0, t * 3.0 + PI * 1.4, 20, Color(c2, 0.55 * env), 1.5)
				# Song Long Biển Đông: 2 counter-rotating dragon bodies
				for di in 2:
					var base_a := t * 5.2 + float(di) * PI
					var prev_pt := Vector2.ZERO
					for si in 6:
						var sa := base_a - float(si) * 0.34
						var sr := orbit_r + sin(t * 9.0 + float(si) * 1.1) * 3.2 * sc
						var sp := center + Vector2(cos(sa) * sr, sin(sa) * sr * 0.78)
						var rad := (5.4 - float(si) * 0.62) * sc
						var scol := c1 if di == 0 else c1.lerp(c2, 0.35)
						ci.draw_circle(sp, rad, Color(scol, 0.88 * env))
						if si == 0:
							_draw_diamond(ci, sp, 7.0 * sc, 3.8 * sc, sa + PI * 0.5, Color(c2, 0.95 * env))
						if si > 0:
							ci.draw_line(prev_pt, sp, Color(c2, 0.72 * env), 1.6)
						prev_pt = sp
			else:
				ci.draw_circle(center, orbit_r * 1.05, Color(c1, 0.24 * env))
				for di in 2:
					var ha := t * 5.2 + float(di) * PI
					var hp := center + Vector2(cos(ha) * orbit_r, sin(ha) * orbit_r * 0.78)
					ci.draw_circle(hp, 10.5 * sc, Color(c2, 0.52 * env))
					_draw_crescent(ci, center, orbit_r, ha - 0.4, 0.7, 5.0 * sc, Color(c1, 0.45 * env), 10)

		"tram_trung_hao_quang":
			var eo := _ease_out_cubic(p)
			var halo_r := (16.0 + eo * 26.0) * sc
			if not glow:
				ci.draw_circle(center, halo_r, Color(c1, 0.16 * env))
				ci.draw_arc(center, halo_r, 0.0, TAU, 36, Color(c2, 0.88 * env), 2.2)
				ci.draw_arc(center, halo_r * 0.72, 0.0, TAU, 28, Color(c1, 0.65 * env), 1.5)
				# Ring of glowing Trăm Trứng orbs + homing dragon rays
				var eggs := 6 + syn * 2
				for ei in eggs:
					var ea := t * 2.8 + TAU * float(ei) / float(eggs)
					var epos := center + Vector2(cos(ea) * halo_r * 0.82, sin(ea) * halo_r * 0.68 - sin(p * PI) * 4.0 * sc)
					_draw_diamond(ci, epos, 3.6 * sc, 4.6 * sc, 0.0, Color(c2, 0.95 * env))
					ci.draw_circle(epos, 2.2 * sc, Color(1, 1, 1, 0.85 * env))
					if p > 0.25:
						var ray_t := _ease_out_cubic(clampf((p - 0.25) / 0.75, 0.0, 1.0))
						var rdir := Vector2.from_angle(ea)
						var rpos := epos.lerp(center + rdir * (dist * 0.92), ray_t)
						ci.draw_line(epos, rpos, Color(c1, 0.55 * env), 1.6)
						_draw_diamond(ci, rpos, 5.0 * sc, 2.2 * sc, ea, Color(c2, 0.9 * env))
			else:
				ci.draw_circle(center, halo_r * 1.1, Color(c2, 0.28 * env))
				_draw_star(ci, center, 16.0 * sc * env, 5.5 * sc, 6, t * 2.2, Color(c1, 0.55 * env))

		"doi_non_lap_be":
			if not glow:
				# Seismic ground fissure line + 3 erupting Tản Viên granite peaks
				ci.draw_line(center, target, Color(c2, 0.75 * env), 3.0 * sc)
				var peaks := 3 + syn
				for mi in peaks:
					var frac := float(mi + 1) / float(peaks + 1)
					var delay := float(mi) * 0.11
					var mp := clampf((p - delay) / 0.34, 0.0, 1.0)
					if mp <= 0.0:
						continue
					var mpos := center.lerp(target, frac)
					var rise := _ease_out_back(mp) * clampf((1.0 - p) * 3.8, 0.0, 1.0)
					var mw := (11.0 + float(mi % 2) * 3.0) * sc
					var mh := (22.0 + float(mi % 2) * 6.0) * sc * rise
					var peak := PackedVector2Array([
						mpos + Vector2(-mw, 4.0 * sc),
						mpos + Vector2(-mw * 0.45, -mh * 0.65),
						mpos + Vector2(0.0, -mh),
						mpos + Vector2(mw * 0.45, -mh * 0.55),
						mpos + Vector2(mw, 4.0 * sc),
					])
					ci.draw_colored_polygon(peak, Color(0.42, 0.36, 0.28, 0.92 * env))
					ci.draw_polyline(peak, Color(c1, 0.9 * env), 1.6)
					ci.draw_arc(mpos + Vector2(0, 3.0 * sc), mw * 1.25 * mp, 0.0, TAU, 18, Color(c2, (1.0 - mp * 0.5) * env), 1.6)
			else:
				for mi in 3 + syn:
					var frac := float(mi + 1) / float(4 + syn)
					var mpos := center.lerp(target, frac)
					ci.draw_circle(mpos, 14.0 * sc * env, Color(c2, 0.35 * env))
					_draw_star(ci, mpos + Vector2(0, -10.0 * sc), 9.0 * sc * env, 3.2 * sc, 4, float(mi), Color(c1, 0.58 * env))

		"thach_giap_tan_vien":
			var eo := _ease_out_cubic(p)
			var sh_r := (22.0 + sin(p * PI) * 5.0) * sc
			if not glow:
				# Octagonal Tản Viên stone shield barrier + 3 seismic pulse rings
				var oct := PackedVector2Array()
				for oi in 8:
					var oa := t * 1.2 + TAU * float(oi) / 8.0
					oct.append(center + Vector2.from_angle(oa) * sh_r)
				ci.draw_colored_polygon(oct, Color(c1, 0.22 * env))
				oct.append(oct[0])
				ci.draw_polyline(oct, Color(c1, 0.92 * env), 2.6)
				for ri in 3:
					var rp := clampf(p * 1.4 - float(ri) * 0.2, 0.0, 1.0)
					if rp <= 0.0:
						continue
					var rr := (12.0 + _ease_out_cubic(rp) * 40.0) * sc
					ci.draw_arc(center, rr, 0.0, TAU, 28, Color(c2, (1.0 - rp) * 0.88), 2.2)
				# Giant hammer sweep
				var h_ang := ang - 1.0 + _ease_out_cubic(minf(p * 1.4, 1.0)) * 2.0
				var hpos := center + Vector2.from_angle(h_ang) * (24.0 * sc)
				ci.draw_line(center, hpos, Color(0.58, 0.38, 0.20, env), 2.8)
				_draw_diamond(ci, hpos, 8.5 * sc, 5.5 * sc, h_ang + PI * 0.5, Color(c1, env))
			else:
				ci.draw_circle(center, (sh_r + eo * 12.0) * 1.05, Color(c2, 0.28 * env))
				_draw_star(ci, center, 16.0 * sc * env, 5.0 * sc, 8, t * 2.4, Color(c1, 0.55 * env))

		_:
			var eo := _ease_out_cubic(p)
			ci.draw_arc(center, (10.0 + eo * 32.0) * sc, 0.0, TAU, 24, Color(c1, env), 2.0)
			if glow:
				ci.draw_circle(center, 16.0 * sc, Color(c2, 0.4 * env))
