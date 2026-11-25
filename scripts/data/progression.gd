extends RefCounted
## Dữ liệu Tu luyện tướng (cấp 1–5) và Rèn binh khí khởi đầu (bậc 1–5) - thẻ G19.

const HERO_LEVELS: Dictionary = {
	1: {"hp": 0, "armor": 0, "energy": 0, "cd_mult": 1.0, "coins": 0, "mats": {}, "desc": "Khởi đầu"},
	2: {"hp": 1, "armor": 0, "energy": 0, "cd_mult": 1.0, "coins": 150, "mats": {}, "desc": "+1 máu tối đa"},
	3: {"hp": 0, "armor": 1, "energy": 0, "cd_mult": 1.0, "coins": 300, "mats": {}, "desc": "+1 giáp tối đa"},
	4: {"hp": 0, "armor": 0, "energy": 30, "cd_mult": 1.0, "coins": 500, "mats": {"yeu_hon": 2}, "desc": "+30 năng lượng tối đa"},
	5: {"hp": 0, "armor": 0, "energy": 0, "cd_mult": 0.85, "coins": 800, "mats": {"ngoc_than": 1}, "desc": "Hồi kỹ năng ×0,85"},
}

const WEAPON_RANKS: Dictionary = {
	1: {"name": "Bậc 1", "dmg_mult": 1.0, "cd_mult": 1.0, "coins": 0, "mats": {}, "trait": 0, "desc": "Chỉ số gốc"},
	2: {"name": "Bậc 2", "dmg_mult": 1.25, "cd_mult": 1.0, "coins": 100, "mats": {"dong": 3}, "trait": 0, "desc": "Sát thương ×1,25"},
	3: {"name": "Bậc 3", "dmg_mult": 1.5, "cd_mult": 0.92, "coins": 220, "mats": {"sat": 5, "dong": 2}, "trait": 1, "desc": "Sát thương ×1,5, hồi đòn ×0,92, mở Đặc tính 1"},
	4: {"name": "Bậc 4", "dmg_mult": 1.8, "cd_mult": 0.88, "coins": 400, "mats": {"sat": 6, "yeu_hon": 2}, "trait": 1, "desc": "Sát thương ×1,8, hồi đòn ×0,88"},
	5: {"name": "Thức tỉnh", "dmg_mult": 2.2, "cd_mult": 0.85, "coins": 700, "mats": {"sat": 8, "yeu_hon": 3, "ngoc_than": 2}, "trait": 2, "desc": "Thức tỉnh: Sát thương ×2,2, hồi đòn ×0,85, mở Đặc tính 2"},
}

const TRAITS: Dictionary = {
	"kiem_dong": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"doan_dao": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"giao_tre": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"guom_lenh": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"con_lam_son": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"dao_rua": {"kind": "melee", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng kiếm 60% sát thương"},
	"no_tay": {"kind": "bow", "d1": "Tên xuyên 1 giặc", "d2": "Mỗi phát bắn 2 mũi lệch ±6°"},
	"ong_lua": {"kind": "flame", "d1": "Thời gian cháy gây ra ×2", "d2": "Tầm phun ×1,5"},
	"hoa_mai_yen_the": {"kind": "gun", "d1": "Đạn xuyên 1 giặc", "d2": "Phát thứ 4 liên tiếp nổ nhỏ bán kính 24"},
	"sung_truong_bo_binh": {"kind": "gun", "d1": "Đạn xuyên 1 giặc", "d2": "Phát thứ 4 liên tiếp nổ nhỏ bán kính 24"},
	"gay_tre": {"kind": "melee_fire", "d1": "Tầm với +15%", "d2": "Mỗi nhát thứ 3 phóng sóng lửa gây cháy (60%)"},
}


static func hero_bonuses(lv: int) -> Dictionary:
	var c: int = clampi(lv, 1, 5)
	var hp: int = 0
	var armor: int = 0
	var energy: int = 0
	var cd_mult: float = 1.0
	for k in range(2, c + 1):
		var info: Dictionary = HERO_LEVELS[k]
		hp += int(info.hp)
		armor += int(info.armor)
		energy += int(info.energy)
		cd_mult = minf(cd_mult, float(info.cd_mult))
	return {"hp": hp, "armor": armor, "energy": energy, "cd_mult": cd_mult}


static func apply_weapon_rank(wid: String, base_data: Dictionary, rank: int) -> Dictionary:
	if base_data.is_empty():
		return base_data
	var r: int = clampi(rank, 1, 5)
	var out: Dictionary = base_data.duplicate()
	var info: Dictionary = WEAPON_RANKS[r]
	out["damage"] = int(ceil(float(base_data.get("damage", 1)) * float(info.dmg_mult)))
	out["cooldown"] = float(base_data.get("cooldown", 0.3)) * float(info.cd_mult)
	var tr: Dictionary = TRAITS.get(wid, {})
	if not tr.is_empty() and r >= 3:
		match str(tr.kind):
			"melee", "melee_fire":
				out["reach"] = float(base_data.get("reach", 32.0)) * 1.15
			"bow", "gun":
				out["pierce"] = int(base_data.get("pierce", 0)) + 1
			"flame":
				out["burn_mult"] = 2.0
	if not tr.is_empty() and r >= 5:
		match str(tr.kind):
			"melee":
				out["trait_wave3"] = true
			"melee_fire":
				out["trait_wave3"] = true
				out["trait_fire_wave"] = true
			"bow":
				out["count"] = int(base_data.get("count", 1)) + 1
				out["spread"] = 12.0
			"flame":
				out["life"] = float(base_data.get("life", 0.3)) * 1.5
			"gun":
				out["trait_explode4"] = true
	return out


static func weapon_texture_path(wid: String, rank: int) -> String:
	if TRAITS.has(wid):
		if rank >= 5:
			return "weapons/%s_b5.png" % wid
		if rank >= 3:
			return "weapons/%s_b3.png" % wid
	return "weapons/%s.png" % wid
