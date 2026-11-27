extends RefCounted
## Cây kỹ năng vĩnh viễn 4 nhánh (16 nút) mở khóa bằng xu & nguyên liệu tại Doanh Trại.

const BRANCH_ORDER: Array = ["vo_dao", "ho_quoc", "linh_khi", "phu_quy"]

const BRANCHES: Dictionary = {
	"vo_dao": {
		"id": "vo_dao",
		"name": "Võ Đạo",
		"desc": "Cường hóa sức mạnh tấn công và đòn chí mạng.",
		"color": Color(0.96, 0.42, 0.30),
		"nodes": ["vd_luc_dao", "vd_toc_danh", "vd_chi_mang", "vd_tuyet_ky"],
	},
	"ho_quoc": {
		"id": "ho_quoc",
		"name": "Hộ Quốc",
		"desc": "Bồi bổ thể phách, giáp trụ và khả năng sinh tồn.",
		"color": Color(0.38, 0.78, 1.0),
		"nodes": ["hq_the_phach", "hq_thiet_giap", "hq_khang_don", "hq_bat_khuat"],
	},
	"linh_khi": {
		"id": "linh_khi",
		"name": "Linh Khí",
		"desc": "Tăng năng lượng tối đa, hồi chiêu và uy lực kỹ năng.",
		"color": Color(0.68, 0.48, 1.0),
		"nodes": ["lk_tinh_hoan", "lk_ngung_tu", "lk_chinh_khi", "lk_lien_chieu"],
	},
	"phu_quy": {
		"id": "phu_quy",
		"name": "Phú Quý",
		"desc": "Gia tăng tài lộc, ưu đãi thương nhân và vận may rơi đồ.",
		"color": Color(1.0, 0.80, 0.28),
		"nodes": ["pq_chieu_tai", "pq_hanh_trang", "pq_tho_ren", "pq_duyen_bau"],
	},
}

const NODE_ORDER: Array = [
	"vd_luc_dao", "vd_toc_danh", "vd_chi_mang", "vd_tuyet_ky",
	"hq_the_phach", "hq_thiet_giap", "hq_khang_don", "hq_bat_khuat",
	"lk_tinh_hoan", "lk_ngung_tu", "lk_chinh_khi", "lk_lien_chieu",
	"pq_chieu_tai", "pq_hanh_trang", "pq_tho_ren", "pq_duyen_bau",
]

const NODES: Dictionary = {
	# --- Võ Đạo ---
	"vd_luc_dao": {
		"id": "vd_luc_dao", "branch": "vo_dao", "tier": 0, "name": "Lực Đạo",
		"max_rank": 5, "per_rank": 6, "stat": "dmg_pct",
		"desc": "+6% sát thương đòn đánh mỗi bậc (tối đa +30%).",
	},
	"vd_toc_danh": {
		"id": "vd_toc_danh", "branch": "vo_dao", "tier": 1, "name": "Tốc Đánh",
		"max_rank": 5, "per_rank": 5, "stat": "atk_speed_pct",
		"desc": "+5% tốc độ đánh/bắn mỗi bậc (tối đa +25%).",
	},
	"vd_chi_mang": {
		"id": "vd_chi_mang", "branch": "vo_dao", "tier": 2, "name": "Chí Mạng",
		"max_rank": 4, "per_rank": 4, "stat": "crit_pct",
		"desc": "+4% tỉ lệ chí mạng mỗi bậc (tối đa +16%).",
	},
	"vd_tuyet_ky": {
		"id": "vd_tuyet_ky", "branch": "vo_dao", "tier": 3, "name": "Tuyệt Kỹ",
		"max_rank": 3, "per_rank": 12, "stat": "crit_dmg_pct",
		"desc": "+12% sát thương chí mạng & đòn kết liễu mỗi bậc.",
	},

	# --- Hộ Quốc ---
	"hq_the_phach": {
		"id": "hq_the_phach", "branch": "ho_quoc", "tier": 0, "name": "Thể Phách",
		"max_rank": 3, "per_rank": 1, "stat": "hp_add",
		"desc": "+1 Máu tối đa mỗi bậc (tối đa +3).",
	},
	"hq_thiet_giap": {
		"id": "hq_thiet_giap", "branch": "ho_quoc", "tier": 1, "name": "Thiết Giáp",
		"max_rank": 3, "per_rank": 1, "stat": "armor_add",
		"desc": "+1 Giáp tối đa mỗi bậc (tối đa +3).",
	},
	"hq_khang_don": {
		"id": "hq_khang_don", "branch": "ho_quoc", "tier": 2, "name": "Kháng Đòn",
		"max_rank": 4, "per_rank": 5, "stat": "dmg_taken_pct",
		"desc": "Giảm 5% sát thương nhận vào mỗi bậc (tối đa -20%).",
	},
	"hq_bat_khuat": {
		"id": "hq_bat_khuat", "branch": "ho_quoc", "tier": 3, "name": "Bất Khuất",
		"max_rank": 3, "per_rank": 0.05, "stat": "iframe_add",
		"desc": "+0,05s bất tử sau trúng đòn & hồi giáp nhanh hơn mỗi bậc.",
	},

	# --- Linh Khí ---
	"lk_tinh_hoan": {
		"id": "lk_tinh_hoan", "branch": "linh_khi", "tier": 0, "name": "Tinh Hoàn",
		"max_rank": 4, "per_rank": 25, "stat": "energy_add",
		"desc": "+25 Năng lượng tối đa mỗi bậc (tối đa +100).",
	},
	"lk_ngung_tu": {
		"id": "lk_ngung_tu", "branch": "linh_khi", "tier": 1, "name": "Ngưng Tụ",
		"max_rank": 4, "per_rank": 5, "stat": "skill_cd_pct",
		"desc": "-5% thời gian hồi kỹ năng mỗi bậc (tối đa -20%).",
	},
	"lk_chinh_khi": {
		"id": "lk_chinh_khi", "branch": "linh_khi", "tier": 2, "name": "Chính Khí",
		"max_rank": 4, "per_rank": 10, "stat": "skill_dmg_pct",
		"desc": "+10% sát thương kỹ năng mỗi bậc (tối đa +40%).",
	},
	"lk_lien_chieu": {
		"id": "lk_lien_chieu", "branch": "linh_khi", "tier": 3, "name": "Liên Chiêu",
		"max_rank": 3, "per_rank": 8, "stat": "skill_energy_refund",
		"desc": "Tung kỹ năng hoàn lại +8 năng lượng mỗi bậc (tối đa +24).",
	},

	# --- Phú Quý ---
	"pq_chieu_tai": {
		"id": "pq_chieu_tai", "branch": "phu_quy", "tier": 0, "name": "Chiêu Tài",
		"max_rank": 5, "per_rank": 10, "stat": "coin_pct",
		"desc": "+10% xu nhận được mỗi bậc (tối đa +50%).",
	},
	"pq_hanh_trang": {
		"id": "pq_hanh_trang", "branch": "phu_quy", "tier": 1, "name": "Hành Trang",
		"max_rank": 4, "per_rank": 15, "stat": "start_coins",
		"desc": "+15 xu khởi đầu mỗi lượt chơi mỗi bậc (tối đa +60).",
	},
	"pq_tho_ren": {
		"id": "pq_tho_ren", "branch": "phu_quy", "tier": 2, "name": "Thợ Rèn",
		"max_rank": 4, "per_rank": 6, "stat": "shop_discount_pct",
		"desc": "-6% giá xu ở Thương Nhân & Lò Rèn mỗi bậc (tối đa -24%).",
	},
	"pq_duyen_bau": {
		"id": "pq_duyen_bau", "branch": "phu_quy", "tier": 3, "name": "Duyên Báu",
		"max_rank": 4, "per_rank": 5, "stat": "luck_pct",
		"desc": "+5% vận may rơi Cổ Vật & Mảnh bản vẽ mỗi bậc (tối đa +20%).",
	},
}


static func node_rank(tree: Dictionary, nid: String) -> int:
	if not NODES.has(nid):
		return 0
	var max_r: int = int(NODES[nid].get("max_rank", 1))
	return clampi(int(tree.get(nid, 0)), 0, max_r)


static func upgrade_cost(nid: String, next_rank: int) -> Dictionary:
	if not NODES.has(nid):
		return {}
	var nd: Dictionary = NODES[nid]
	var max_r: int = int(nd.get("max_rank", 1))
	if next_rank < 1 or next_rank > max_r:
		return {}
	var tier: int = int(nd.get("tier", 0))
	var coins: int = (80 + tier * 55) * next_rank
	var mats: Dictionary = {}
	match tier:
		0:
			if next_rank >= 2:
				mats["dong"] = next_rank
			if next_rank >= 4:
				mats["sat"] = next_rank - 2
		1:
			if next_rank >= 1:
				mats["dong"] = next_rank + 1
			if next_rank >= 3:
				mats["sat"] = next_rank - 1
		2:
			mats["sat"] = next_rank * 2
			mats["yeu_hon"] = maxi(1, next_rank - 1)
			if next_rank >= 3:
				mats["ngoc_than"] = 1
		3:
			mats["sat"] = next_rank * 2 + 1
			mats["yeu_hon"] = next_rank * 2
			mats["ngoc_than"] = next_rank
	return {"coins": coins, "mats": mats}


static func can_upgrade_node(tree: Dictionary, nid: String, coins: int, mats: Dictionary) -> bool:
	if not NODES.has(nid):
		return false
	var cur: int = node_rank(tree, nid)
	var max_r: int = int(NODES[nid].get("max_rank", 1))
	if cur >= max_r:
		return false
	var cost: Dictionary = upgrade_cost(nid, cur + 1)
	if cost.is_empty():
		return false
	if coins < int(cost.get("coins", 0)):
		return false
	var req_mats: Dictionary = cost.get("mats", {})
	for m_v in req_mats.keys():
		var m: String = str(m_v)
		if int(mats.get(m, 0)) < int(req_mats[m_v]):
			return false
	return true


static func compute_bonuses(tree: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"dmg_pct": 0,
		"atk_speed_pct": 0,
		"crit_pct": 0,
		"crit_dmg_pct": 0,
		"finisher_pct": 0,
		"hp_add": 0,
		"armor_add": 0,
		"dmg_taken_pct": 0,
		"iframe_add": 0.0,
		"armor_regen_pct": 0,
		"energy_add": 0,
		"skill_cd_pct": 0,
		"skill_dmg_pct": 0,
		"skill_energy_refund": 0,
		"coin_pct": 0,
		"start_coins": 0,
		"shop_discount_pct": 0,
		"luck_pct": 0,
	}
	for nid_v in NODE_ORDER:
		var nid: String = str(nid_v)
		var r: int = node_rank(tree, nid)
		if r <= 0:
			continue
		var nd: Dictionary = NODES[nid]
		var stat: String = str(nd.get("stat", ""))
		var per: Variant = nd.get("per_rank", 0)
		if typeof(per) == TYPE_FLOAT:
			out[stat] = float(out.get(stat, 0.0)) + float(per) * float(r)
		else:
			out[stat] = int(out.get(stat, 0)) + int(per) * r
		if nid == "vd_tuyet_ky":
			out["finisher_pct"] = 8 * r
		elif nid == "hq_bat_khuat":
			out["armor_regen_pct"] = 10 * r
	return out
