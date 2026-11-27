extends RefCounted
## Dữ liệu chiến trường Thủ Thành Cổ Loa & thông số 5 loại Tháp Phòng Thủ (v3.0.0).

const TOWER_ORDER: Array = [
	"luy_tre_nga",
	"thap_no_than",
	"bai_coc_bach_dang",
	"phao_dai_dien_bien",
	"lo_ren_da_chien",
]

const TOWERS: Dictionary = {
	"luy_tre_nga": {
		"name": "Lũy Tre Ngà",
		"desc": "Thành tre kiên cố chắn đường, phản gai & làm chậm giặc áp sát.",
		"color": Color(0.45, 0.85, 0.42),
		"max_tier": 3,
		"costs": [20, 35, 55],
		"sprite": "world/tower_luy_tre.png",
		"hp": 120,
		"cd": 0.75,
		"range": 45.0,
		"dmg": 4,
	},
	"thap_no_than": {
		"name": "Tháp Nỏ Thần",
		"desc": "Phóng loạt tên Kim Quy xuyên thấu nhiều mục tiêu tầm trung.",
		"color": Color(0.96, 0.78, 0.30),
		"max_tier": 3,
		"costs": [25, 40, 65],
		"sprite": "world/tower_no_than.png",
		"hp": 80,
		"cd": 0.95,
		"range": 260.0,
		"dmg": 6,
	},
	"bai_coc_bach_dang": {
		"name": "Bãi Cọc Bạch Đằng",
		"desc": "Trồi cọc nhọn diện rộng, sát thương & làm chậm đội hình địch.",
		"color": Color(0.38, 0.82, 0.96),
		"max_tier": 3,
		"costs": [25, 40, 65],
		"sprite": "world/tower_bai_coc.png",
		"hp": 95,
		"cd": 1.35,
		"range": 92.0,
		"dmg": 8,
	},
	"phao_dai_dien_bien": {
		"name": "Pháo Đài Điện Biên",
		"desc": "Nã đạn pháo tầm xa nổ lan dữ dội vào cụm giặc ở xa.",
		"color": Color(0.98, 0.46, 0.30),
		"max_tier": 3,
		"costs": [35, 55, 85],
		"sprite": "world/tower_phao_dai.png",
		"hp": 90,
		"cd": 2.1,
		"range": 340.0,
		"dmg": 14,
	},
	"lo_ren_da_chien": {
		"name": "Lò Rèn Dã Chiến",
		"desc": "Hồi Giáp & Linh Khí cho đồng đội, đồng thời tu sửa Nỏ Thần Cổ Loa.",
		"color": Color(1.0, 0.65, 0.28),
		"max_tier": 3,
		"costs": [30, 50, 75],
		"sprite": "world/tower_lo_ren.png",
		"hp": 100,
		"cd": 4.5,
		"range": 160.0,
		"dmg": 0,
	},
}

const ARENA_RECT := Rect2(-560.0, -400.0, 1120.0, 800.0)
const CORE_POS := Vector2.ZERO

const PAD_POSITIONS: Array[Vector2] = [
	Vector2(0.0, -120.0),
	Vector2(120.0, 0.0),
	Vector2(0.0, 120.0),
	Vector2(-120.0, 0.0),
	Vector2(-175.0, -175.0),
	Vector2(175.0, -175.0),
	Vector2(175.0, 175.0),
	Vector2(-175.0, 175.0),
]

const SPAWN_LANES: Array[Vector2] = [
	Vector2(0.0, -340.0),
	Vector2(0.0, 340.0),
	Vector2(-490.0, 0.0),
	Vector2(490.0, 0.0),
]


static func tower_info(tid: String) -> Dictionary:
	var raw: Variant = TOWERS.get(tid, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


static func tower_upgrade_cost(tid: String, next_tier: int) -> int:
	if not TOWERS.has(tid):
		return 0
	var info: Dictionary = TOWERS[tid]
	var costs: Array = info.get("costs", [25, 40, 65])
	if next_tier < 1 or next_tier > costs.size():
		return 0
	return int(costs[next_tier - 1])


static func wave_config(wave_num: int) -> Dictionary:
	var w: int = maxi(1, wave_num)
	var is_boss: bool = (w % 5 == 0)
	var reward_coins: int = 25 + w * 6
	var pool: Array[String] = ["bo_binh", "cung_thu", "tieu_yeu"]
	if w >= 2:
		pool.append("ho_tinh")
	if w >= 3:
		pool.append_array(["khien_binh", "phap_su", "ma_troi"])
	if w >= 5:
		pool.append_array(["ky_binh", "moc_tinh", "dai_bang"])
	if w >= 7:
		pool.append_array(["linh_sung", "xa_thu", "chan_tinh"])
	if w >= 9:
		pool.append_array(["phao_binh", "xe_tang"])

	var spawns: Array[String] = []
	if is_boss:
		spawns.append("boss")
		var escort_count: int = clampi(4 + int(w / 2), 4, 16)
		for i in escort_count:
			spawns.append(pool[(w * 3 + i) % pool.size()])
	else:
		var mob_count: int = clampi(6 + w * 2, 8, 36)
		for i in mob_count:
			spawns.append(pool[(w * 5 + i) % pool.size()])

	return {
		"wave": w,
		"is_boss": is_boss,
		"reward_coins": reward_coins,
		"spawns": spawns,
		"elite_chance": clampf(0.05 + 0.03 * float(w), 0.05, 0.55),
		"spawn_interval": clampf(0.95 - 0.03 * float(w), 0.28, 0.95),
	}
