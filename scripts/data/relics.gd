extends RefCounted
## Dữ liệu 15 Cổ Vật Sử Việt (Relics) nhặt được trong lượt chơi (từ rương báu, sự kiện, Cổ Loa).
## Mỗi cổ vật cộng chỉ số hoặc hiệu ứng thụ động cho cả lượt chơi.

const ORDER: Array = [
	"trong_dong_ngoc_lu",
	"mong_rua_kim_quy",
	"an_den_tran",
	"thuan_thien_kiem_an",
	"chuong_quy_dien",
	"vac_pho_minh",
	"cuu_dinh_hue",
	"non_la_bai_tho",
	"chieu_doi_do",
	"gom_chu_dau",
	"ngoc_ty_dai_viet",
	"long_ngong_mi_chau",
	"dan_da_tay_nguyen",
	"sung_te_vang",
	"hat_lua_than",
]

const RARITY_NAMES: Dictionary = {
	"rare": "Hiếm",
	"epic": "Sử thi",
	"mythic": "Huyền thoại",
}

const RARITY_COLORS: Dictionary = {
	"rare": Color(0.35, 0.72, 1.0),
	"epic": Color(0.76, 0.45, 1.0),
	"mythic": Color(1.0, 0.72, 0.24),
}

const DATA: Dictionary = {
	"trong_dong_ngoc_lu": {
		"id": "trong_dong_ngoc_lu",
		"name": "Trống Đồng Ngọc Lũ",
		"rarity": "mythic",
		"color": Color(1.0, 0.82, 0.28),
		"desc": "Quốc bảo Đông Sơn: +2 Máu tối đa, +1 Giáp tối đa, +10% Tỉ lệ chí mạng.",
		"stats": {"hp_add": 2, "armor_add": 1, "crit_pct": 10},
	},
	"mong_rua_kim_quy": {
		"id": "mong_rua_kim_quy",
		"name": "Móng Rùa Kim Quy",
		"rarity": "epic",
		"color": Color(0.42, 0.92, 0.82),
		"desc": "Thần vật Cổ Loa: +2 Giáp tối đa, +12% Tỉ lệ chí mạng.",
		"stats": {"armor_add": 2, "crit_pct": 12},
	},
	"an_den_tran": {
		"id": "an_den_tran",
		"name": "Ấn Đền Trần",
		"rarity": "mythic",
		"color": Color(0.96, 0.42, 0.32),
		"desc": "Uy linh Đông A: +25% Sát thương lên Trùm, +8% Tỉ lệ chí mạng.",
		"stats": {"boss_dmg_pct": 25, "crit_pct": 8},
	},
	"thuan_thien_kiem_an": {
		"id": "thuan_thien_kiem_an",
		"name": "Thuận Thiên Kiếm Ấn",
		"rarity": "mythic",
		"color": Color(0.35, 0.92, 0.62),
		"desc": "Khí phách Lam Sơn: +20% Sát thương cận chiến, +12% Sát thương lên Trùm.",
		"stats": {"melee_dmg_pct": 20, "boss_dmg_pct": 12},
	},
	"chuong_quy_dien": {
		"id": "chuong_quy_dien",
		"name": "Chuông Quy Điền",
		"rarity": "epic",
		"color": Color(0.88, 0.68, 0.34),
		"desc": "Tứ đại khí An Nam: -12% Hồi kỹ năng, +40 Năng lượng tối đa.",
		"stats": {"skill_cd_pct": 12, "energy_add": 40},
	},
	"vac_pho_minh": {
		"id": "vac_pho_minh",
		"name": "Vạc Phổ Minh",
		"rarity": "epic",
		"color": Color(0.42, 0.86, 0.56),
		"desc": "Đỉnh đồng Thiên Trường: +2 Máu tối đa, +20% Sát thương hiệu ứng.",
		"stats": {"hp_add": 2, "status_dmg_pct": 20},
	},
	"cuu_dinh_hue": {
		"id": "cuu_dinh_hue",
		"name": "Cửu Đỉnh Huế",
		"rarity": "mythic",
		"color": Color(1.0, 0.72, 0.24),
		"desc": "Chín đỉnh đế đô: +1 Máu, +1 Giáp, +30 Năng lượng, +15% Sát thương lên Trùm.",
		"stats": {"hp_add": 1, "armor_add": 1, "energy_add": 30, "boss_dmg_pct": 15},
	},
	"non_la_bai_tho": {
		"id": "non_la_bai_tho",
		"name": "Nón Lá Bài Thơ",
		"rarity": "rare",
		"color": Color(0.74, 0.92, 0.72),
		"desc": "Nét duyên cố đô: +10% Tốc độ di chuyển, -8% Thời gian hồi kỹ năng.",
		"stats": {"speed_pct": 10, "skill_cd_pct": 8},
	},
	"chieu_doi_do": {
		"id": "chieu_doi_do",
		"name": "Chiếu Dời Đô",
		"rarity": "epic",
		"color": Color(0.98, 0.86, 0.48),
		"desc": "Thiên đô Thăng Long: +25% Xu nhận được, +10% Tốc độ di chuyển.",
		"stats": {"coin_pct": 25, "speed_pct": 10},
	},
	"gom_chu_dau": {
		"id": "gom_chu_dau",
		"name": "Gốm Chu Đậu",
		"rarity": "rare",
		"color": Color(0.46, 0.78, 1.0),
		"desc": "Men lam cổ truyền: +35 Năng lượng tối đa, +18% Xu nhận được.",
		"stats": {"energy_add": 35, "coin_pct": 18},
	},
	"ngoc_ty_dai_viet": {
		"id": "ngoc_ty_dai_viet",
		"name": "Ngọc Tỷ Đại Việt",
		"rarity": "epic",
		"color": Color(0.32, 0.96, 0.74),
		"desc": "Ấn tín quốc gia: +1 Giáp tối đa, -10% Hồi kỹ năng, +15% Xu.",
		"stats": {"armor_add": 1, "skill_cd_pct": 10, "coin_pct": 15},
	},
	"long_ngong_mi_chau": {
		"id": "long_ngong_mi_chau",
		"name": "Lông Ngỗng Mị Châu",
		"rarity": "rare",
		"color": Color(0.92, 0.94, 1.0),
		"desc": "Dấu xưa Cổ Loa: +14% Tốc độ di chuyển, +8% Tỉ lệ chí mạng.",
		"stats": {"speed_pct": 14, "crit_pct": 8},
	},
	"dan_da_tay_nguyen": {
		"id": "dan_da_tay_nguyen",
		"name": "Đàn Đá Tây Nguyên",
		"rarity": "rare",
		"color": Color(0.84, 0.62, 0.36),
		"desc": "Âm vang đại ngàn: +15% Sát thương cận chiến, +15% Sát thương hiệu ứng.",
		"stats": {"melee_dmg_pct": 15, "status_dmg_pct": 15},
	},
	"sung_te_vang": {
		"id": "sung_te_vang",
		"name": "Sừng Tê Vàng",
		"rarity": "epic",
		"color": Color(0.96, 0.78, 0.30),
		"desc": "Giải độc bách bệnh: Miễn nhiễm độc tố, +1 Máu tối đa, +15% Sát thương hiệu ứng.",
		"stats": {"poison_immune": 1, "hp_add": 1, "status_dmg_pct": 15},
	},
	"hat_lua_than": {
		"id": "hat_lua_than",
		"name": "Hạt Lúa Thần",
		"rarity": "rare",
		"color": Color(0.98, 0.88, 0.40),
		"desc": "Báu vật ruộng đồng: +2 Máu tối đa, +15% Xu nhận được.",
		"stats": {"hp_add": 2, "coin_pct": 15},
	},
}


static func get_relic(rid: String) -> Dictionary:
	return (DATA.get(rid, {}) as Dictionary)


static func rarity_name(rarity: String) -> String:
	return str(RARITY_NAMES.get(rarity, "Hiếm"))


static func rarity_color(rarity: String) -> Color:
	var c: Variant = RARITY_COLORS.get(rarity, Color(0.35, 0.72, 1.0))
	return c as Color if c is Color else Color(0.35, 0.72, 1.0)


static func roll_relic(owned: Array, rng = null) -> String:
	var owned_set: Dictionary = {}
	for o in owned:
		owned_set[str(o)] = true
	var unowned: Array = []
	for rid_v in ORDER:
		var rid: String = str(rid_v)
		if not owned_set.has(rid):
			unowned.append(rid)
	var pool: Array = unowned if not unowned.is_empty() else ORDER.duplicate()
	if pool.is_empty():
		return ""
	var weights: Array[float] = []
	var total: float = 0.0
	for rid_v in pool:
		var r: String = str(DATA.get(str(rid_v), {}).get("rarity", "rare"))
		var w: float = 50.0 if r == "rare" else (32.0 if r == "epic" else 18.0)
		weights.append(w)
		total += w
	var roll_val: float = (rng.randf() if rng != null and rng.has_method("randf") else randf()) * total
	for i in pool.size():
		roll_val -= weights[i]
		if roll_val <= 0.0:
			return str(pool[i])
	return str(pool[pool.size() - 1])


static func aggregate_stats(relic_ids: Array) -> Dictionary:
	var total: Dictionary = {}
	for rid_v in relic_ids:
		var rid: String = str(rid_v)
		var rdata: Dictionary = DATA.get(rid, {})
		if rdata.is_empty():
			continue
		var st: Dictionary = rdata.get("stats", {})
		for k_v in st.keys():
			var k: String = str(k_v)
			var val: Variant = st[k_v]
			if k == "poison_immune":
				total[k] = maxi(int(total.get(k, 0)), int(val))
			elif typeof(val) == TYPE_FLOAT:
				total[k] = float(total.get(k, 0.0)) + float(val)
			else:
				total[k] = int(total.get(k, 0)) + int(val)
	return total
