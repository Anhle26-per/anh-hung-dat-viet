extends RefCounted
## Bùa cường hóa vũ khí (12 bùa gắn tại Thợ rèn lưu động) & 8 Thuộc tính ngẫu nhiên vũ khí (Affixes).

const DATA: Dictionary = {
	"da_mai": {"name": "Đá mài", "desc": "+2 sát thương", "color": Color(1.0, 0.78, 0.35)},
	"ngoc_tiet_kiem": {"name": "Ngọc tiết kiệm", "desc": "-1 năng lượng (tối thiểu 0)", "color": Color(0.45, 0.85, 1.0)},
	"long_chim": {"name": "Lông chim", "desc": "+20% tốc độ đánh/bắn", "color": Color(0.65, 1.0, 0.65)},
	"hoa_thach": {"name": "Hỏa thạch", "desc": "Đòn đánh/đạn gây cháy", "color": Color(1.0, 0.45, 0.25)},
	"ngoc_phan_than": {"name": "Ngọc phân thân", "desc": "+1 đạn/nhát", "color": Color(0.78, 0.56, 1.0)},
	"da_nay_tuong": {"name": "Đá nảy tường", "desc": "+1 nảy tường", "color": Color(0.55, 0.92, 0.96)},
	"bua_sam_set": {"name": "Bùa sấm sét", "desc": "+1 sét lan", "color": Color(0.42, 0.86, 1.0)},
	"bang_tinh": {"name": "Băng tinh", "desc": "Đòn gây làm chậm", "color": Color(0.62, 0.92, 1.0)},
	"ong_ngam_than": {"name": "Ống ngắm thần", "desc": "+12% chí mạng", "color": Color(1.0, 0.90, 0.38)},
	"huyet_ngoc": {"name": "Huyết ngọc", "desc": "+3 sát thương & hút 1 khí", "color": Color(0.98, 0.34, 0.42)},
	"coi_no_lien": {"name": "Cối nổ liền", "desc": "Tầm nổ/với +22%", "color": Color(1.0, 0.62, 0.28)},
	"da_xuyen_pha": {"name": "Đá xuyên phá", "desc": "+1 xuyên mục tiêu", "color": Color(0.86, 0.88, 0.96)},
}

const ORDER: Array = [
	"da_mai",
	"ngoc_tiet_kiem",
	"long_chim",
	"hoa_thach",
	"ngoc_phan_than",
	"da_nay_tuong",
	"bua_sam_set",
	"bang_tinh",
	"ong_ngam_than",
	"huyet_ngoc",
	"coi_no_lien",
	"da_xuyen_pha",
]

const AFFIX_ORDER: Array = [
	"toc_xa",
	"bao_kich",
	"loi_dien",
	"khong_lo",
	"tiet_khi",
	"cuong_sat",
	"xuyen_thau",
	"bang_hoa",
]

const AFFIXES: Dictionary = {
	"toc_xa": {"name": "Tốc Xạ", "desc": "Tốc độ đánh/bắn +18%, đạn bay nhanh +15%", "color": Color(0.55, 0.98, 0.68)},
	"bao_kich": {"name": "Bạo Kích", "desc": "+15% tỉ lệ chí mạng, +1 sát thương", "color": Color(1.0, 0.86, 0.32)},
	"loi_dien": {"name": "Lôi Điện", "desc": "+1 sét lan & gây choáng 0,35s", "color": Color(0.45, 0.88, 1.0)},
	"khong_lo": {"name": "Khổng Lồ", "desc": "+25% sát thương, +25% tầm với/nổ", "color": Color(1.0, 0.64, 0.30)},
	"tiet_khi": {"name": "Tiết Khí", "desc": "-1 năng lượng tiêu hao & +8% tốc đánh", "color": Color(0.42, 0.94, 0.86)},
	"cuong_sat": {"name": "Cuồng Sát", "desc": "+3 sát thương & tăng lực đẩy lùi", "color": Color(0.98, 0.36, 0.38)},
	"xuyen_thau": {"name": "Xuyên Thấu", "desc": "+2 xuyên mục tiêu", "color": Color(0.84, 0.86, 1.0)},
	"bang_hoa": {"name": "Băng Hỏa", "desc": "Đòn đánh vừa đốt cháy vừa làm chậm", "color": Color(0.88, 0.56, 1.0)},
}


static func apply(w: Dictionary, mod_id: String) -> Dictionary:
	var out: Dictionary = w.duplicate(true)
	if mod_id == "" or not DATA.has(mod_id):
		return out
	match mod_id:
		"da_mai":
			out["damage"] = int(out.get("damage", 1)) + 2
		"ngoc_tiet_kiem":
			out["energy"] = maxi(0, int(out.get("energy", 0)) - 1)
		"long_chim":
			out["cooldown"] = float(out.get("cooldown", 0.3)) * 0.83
		"hoa_thach":
			out["mod_fire"] = true
		"ngoc_phan_than":
			if str(out.get("type", "")) == "melee":
				out["hits"] = int(out.get("hits", 1)) + 1
			else:
				out["count"] = int(out.get("count", 1)) + 1
				if float(out.get("spread", 0.0)) < 10.0:
					out["spread"] = 10.0
		"da_nay_tuong":
			out["bounce"] = int(out.get("bounce", out.get("bounces", 0))) + 1
		"bua_sam_set":
			out["chain"] = int(out.get("chain", 0)) + 1
		"bang_tinh":
			out["mod_ice"] = true
			out["slow"] = maxf(float(out.get("slow", 0.0)), 2.0)
			if str(out.get("status", "")) == "":
				out["status"] = "slow"
		"ong_ngam_than":
			out["mod_crit"] = float(out.get("mod_crit", 0.0)) + 0.12
			out["crit_bonus"] = float(out.get("crit_bonus", 0.0)) + 0.12
		"huyet_ngoc":
			out["damage"] = int(out.get("damage", 1)) + 3
			out["mod_leech_energy"] = int(out.get("mod_leech_energy", 0)) + 1
		"coi_no_lien":
			if out.has("reach"):
				out["reach"] = float(out.get("reach", 32.0)) * 1.22
			if out.has("radius"):
				out["radius"] = float(out.get("radius", 80.0)) * 1.22
			if out.has("explode"):
				out["explode"] = float(out.get("explode", 0.0)) * 1.22
			if out.has("length"):
				out["length"] = float(out.get("length", 260.0)) * 1.22
		"da_xuyen_pha":
			out["pierce"] = int(out.get("pierce", 0)) + 1
	return out


static func mod_name(mod_id: String) -> String:
	if not DATA.has(mod_id):
		return ""
	var d: Dictionary = DATA[mod_id]
	return str(d.get("name", ""))


static func mod_color(mod_id: String) -> Color:
	if not DATA.has(mod_id):
		return Color.WHITE
	var d: Dictionary = DATA[mod_id]
	return d.get("color", Color.WHITE) as Color


static func roll_affix(tier: int = 1) -> String:
	if AFFIX_ORDER.is_empty():
		return ""
	if tier >= 4 and randf() < 0.45:
		var high_pool: Array = ["bao_kich", "loi_dien", "khong_lo", "cuong_sat", "bang_hoa"]
		return str(high_pool.pick_random())
	return str(AFFIX_ORDER.pick_random())


static func apply_affix(w: Dictionary, affix_id: String) -> Dictionary:
	var out: Dictionary = w.duplicate(true)
	if affix_id == "" or not AFFIXES.has(affix_id):
		return out
	out["affix"] = affix_id
	out["affix_name"] = affix_name(affix_id)
	match affix_id:
		"toc_xa":
			out["cooldown"] = float(out.get("cooldown", 0.35)) * 0.85
			if out.has("speed"):
				out["speed"] = float(out.get("speed", 400.0)) * 1.15
		"bao_kich":
			out["crit_bonus"] = float(out.get("crit_bonus", 0.0)) + 0.15
			out["damage"] = int(out.get("damage", 1)) + 1
		"loi_dien":
			out["chain"] = int(out.get("chain", 0)) + 1
			out["stun"] = maxf(float(out.get("stun", 0.0)), 0.35)
		"khong_lo":
			out["damage"] = maxi(1, int(round(float(out.get("damage", 1)) * 1.25)))
			if out.has("reach"):
				out["reach"] = float(out.get("reach", 32.0)) * 1.25
			if out.has("radius"):
				out["radius"] = float(out.get("radius", 80.0)) * 1.25
			if out.has("explode"):
				out["explode"] = float(out.get("explode", 0.0)) * 1.25
			out["evolved_scale"] = float(out.get("evolved_scale", 1.0)) * 1.15
		"tiet_khi":
			out["energy"] = maxi(0, int(out.get("energy", 0)) - 1)
			out["cooldown"] = float(out.get("cooldown", 0.35)) * 0.92
		"cuong_sat":
			out["damage"] = int(out.get("damage", 1)) + 3
			out["knock"] = float(out.get("knock", 120.0)) + 40.0
		"xuyen_thau":
			out["pierce"] = int(out.get("pierce", 0)) + 2
		"bang_hoa":
			out["mod_fire"] = true
			out["slow"] = maxf(float(out.get("slow", 0.0)), 1.8)
	return out


static func affix_name(aid: String) -> String:
	if not AFFIXES.has(aid):
		return ""
	return str((AFFIXES[aid] as Dictionary).get("name", ""))


static func affix_color(aid: String) -> Color:
	if not AFFIXES.has(aid):
		return Color.WHITE
	var c: Variant = (AFFIXES[aid] as Dictionary).get("color", Color.WHITE)
	return c as Color if c is Color else Color.WHITE
