extends RefCounted
## Chế độ chơi mở rộng v2.0.0: Boss Rush (13 màn) & 8 Biến số Thử thách (Mutators) + Thử thách Hằng ngày.

const BOSS_RUSH_CLEAR_LEVEL := 13

const MUTATOR_ORDER: Array = [
	"big_bullets",
	"double_boss",
	"weapon_roulette",
	"hyper_speed",
	"elite_swarm",
	"glass_cannon",
	"infinite_energy",
	"melee_master",
]

const MUTATORS := {
	"big_bullets": {
		"name": "Đạn Khổng Lồ",
		"desc": "Đạn cả ta và giặc to gấp rưỡi (×1,5 kích thước), dễ trúng mục tiêu hơn.",
		"color": Color(1.0, 0.62, 0.28),
		"modifiers": {"bullet_scale": 1.5, "enemy_bullet_scale": 1.45},
	},
	"double_boss": {
		"name": "Song Trùm Xuất Trận",
		"desc": "Mỗi phòng Trùm xuất hiện thêm 1 Đại Tướng phụ chiến đấu cùng lúc!",
		"color": Color(0.95, 0.28, 0.36),
		"modifiers": {"extra_boss": 1},
	},
	"weapon_roulette": {
		"name": "Xúc Xắc Binh Khí",
		"desc": "Mỗi khi bước sang màn mới, vũ khí đang cầm tự động đổi ngẫu nhiên.",
		"color": Color(0.76, 0.52, 1.0),
		"modifiers": {"swap_weapon_stage": true},
	},
	"hyper_speed": {
		"name": "Nhịp Độ Siêu Thanh",
		"desc": "Tốc độ chạy & tốc độ đạn toàn chiến trường tăng +35%.",
		"color": Color(0.32, 0.88, 1.0),
		"modifiers": {"speed_mult": 1.35, "bullet_speed_mult": 1.35},
	},
	"elite_swarm": {
		"name": "Bầy Tinh Anh",
		"desc": "Tỉ lệ giặc Tinh Anh tăng mạnh (45%), nhưng rớt thêm +35% xu.",
		"color": Color(1.0, 0.84, 0.32),
		"modifiers": {"elite_chance": 0.45, "coin_mult": 1.35},
	},
	"glass_cannon": {
		"name": "Pháo Thủy Tinh",
		"desc": "Sát thương gây ra ×2, nhưng máu tối đa giảm một nửa (tối thiểu 2).",
		"color": Color(0.96, 0.42, 0.64),
		"modifiers": {"dmg_mult": 2.0, "hp_mult": 0.5},
	},
	"infinite_energy": {
		"name": "Linh Khí Vô Tận",
		"desc": "Mọi vũ khí bắn không tốn năng lượng, thỏa sức xả đạn!",
		"color": Color(0.36, 0.72, 1.0),
		"modifiers": {"free_energy": true},
	},
	"melee_master": {
		"name": "Bậc Thầy Cận Chiến",
		"desc": "Cận chiến +60% sát thương & +30% tốc đánh; bắn xa -30% sát thương.",
		"color": Color(0.45, 0.94, 0.56),
		"modifiers": {"melee_dmg_mult": 1.6, "melee_rate_mult": 1.3, "ranged_dmg_mult": 0.7},
	},
}


static func mutator_info(mid: String) -> Dictionary:
	var d: Variant = MUTATORS.get(mid, {})
	return (d as Dictionary).duplicate() if d is Dictionary else {}


static func mutator_name(mid: String) -> String:
	var d: Dictionary = MUTATORS.get(mid, {})
	return str(d.get("name", mid))


static func mutator_color(mid: String) -> Color:
	var d: Dictionary = MUTATORS.get(mid, {})
	var c: Variant = d.get("color", Color.WHITE)
	return c as Color if c is Color else Color.WHITE


static func daily_seed_code() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "NGAY-%04d%02d%02d" % [int(d.get("year", 2026)), int(d.get("month", 1)), int(d.get("day", 1))]


static func daily_mutators() -> Array:
	var d: Dictionary = Time.get_date_dict_from_system()
	var y: int = int(d.get("year", 2026))
	var m: int = int(d.get("month", 1))
	var day: int = int(d.get("day", 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = (y * 10000 + m * 100 + day) * 2654435761 + 17
	var pool: Array = MUTATOR_ORDER.duplicate()
	var count: int = 2 + (rng.randi() % 2)  # 2 hoặc 3 biến số mỗi ngày
	var picked: Array = []
	for _i in count:
		if pool.is_empty():
			break
		var idx: int = rng.randi() % pool.size()
		picked.append(str(pool[idx]))
		pool.remove_at(idx)
	return picked
