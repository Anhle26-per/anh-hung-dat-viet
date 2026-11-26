extends RefCounted
## Dữ liệu 6 nguyên liệu rơi từ giặc/rương và bảng công thức rèn binh khí tại Lò rèn.

const WeaponData = preload("res://scripts/data/weapons.gd")

const ORDER: Array = ["dong", "sat", "go_lim", "hoa_duoc", "yeu_hon", "ngoc_than"]

const DATA: Dictionary = {
	"dong": {"name": "Đồng", "color": Color(0.92, 0.62, 0.28), "icon": "items/mat_dong.png"},
	"sat": {"name": "Sắt", "color": Color(0.72, 0.78, 0.88), "icon": "items/mat_sat.png"},
	"go_lim": {"name": "Gỗ lim", "color": Color(0.76, 0.48, 0.28), "icon": "items/mat_go_lim.png"},
	"hoa_duoc": {"name": "Hỏa dược", "color": Color(0.96, 0.42, 0.22), "icon": "items/mat_hoa_duoc.png"},
	"yeu_hon": {"name": "Yêu hồn", "color": Color(0.78, 0.45, 1.0), "icon": "items/mat_yeu_hon.png"},
	"ngoc_than": {"name": "Ngọc thần", "color": Color(0.32, 0.96, 0.75), "icon": "items/mat_ngoc_than.png"},
}

# Tỉ lệ rơi (tách thành hằng số để thẻ G11 dễ cân bằng sau này)
const DROP_NORMAL: float = 0.08
const DROP_ELITE: float = 0.40
const DROP_FOLK: float = 0.15
const DROP_BOSS_NGOC: float = 0.50
const DROP_CHEST: float = 0.20

const ANCIENT_POOL: Array = ["dong", "sat", "go_lim"]
const MODERN_POOL: Array = ["sat", "hoa_duoc"]
const FIREARM_PROJS: Array = ["bullet", "pellet", "rocket", "grenade", "cannonball", "plasma"]

const RECIPES: Dictionary = {
	1: {"coins": 25, "mats": {"dong": 2}},
	2: {"coins": 55, "mats": {"dong": 3, "sat": 2}},
	3: {"coins": 130, "mats": {"sat": 4, "yeu_hon": 1}},
	4: {"coins": 320, "mats": {"sat": 6, "dong": 5, "yeu_hon": 3, "ngoc_than": 2}},
	5: {"coins": 850, "mats": {"sat": 12, "dong": 10, "yeu_hon": 8, "ngoc_than": 6}},
}


static func can_forge_weapon(wid: String) -> bool:
	if not WeaponData.DATA.has(wid):
		return false
	var w: Dictionary = WeaponData.DATA[wid]
	if bool(w.get("basic", false)):
		return false
	var tier: int = int(w.get("tier", 1))
	return tier >= 1 and RECIPES.has(tier)


static func all_blueprint_weapons() -> Array:
	var out: Array = []
	for wid_v in WeaponData.DATA.keys():
		var wid: String = str(wid_v)
		if can_forge_weapon(wid):
			out.append(wid)
	out.sort_custom(func(a: String, b: String) -> bool:
		var ta: int = int(WeaponData.DATA[a].get("tier", 1))
		var tb: int = int(WeaponData.DATA[b].get("tier", 1))
		if ta != tb:
			return ta < tb
		return str(WeaponData.DATA[a].get("name", a)) < str(WeaponData.DATA[b].get("name", b)))
	return out


static func fragments_needed(wid: String) -> int:
	if not can_forge_weapon(wid):
		return 0
	var w: Dictionary = WeaponData.DATA.get(wid, {})
	var tier: int = int(w.get("tier", 1))
	if tier <= 2:
		return 1
	if tier == 3:
		return 2
	if tier == 4:
		return 3
	return 5 if (bool(w.get("boss_motif", false)) or bool(w.get("merged", false))) else 4


static func uses_fragments(wid: String) -> bool:
	return fragments_needed(wid) > 1


static func is_achievement_blueprint(wid: String) -> bool:
	return bool(WeaponData.DATA.get(wid, {}).get("blueprint", false))


static func requires_blueprint(wid: String) -> bool:
	return is_achievement_blueprint(wid)


static func blueprint_grade(wid: String) -> String:
	var tier: int = int(WeaponData.DATA.get(wid, {}).get("tier", 1))
	return "Nâng cao" if tier >= 4 else "Cơ bản"


static func blueprint_tier_label(wid: String) -> String:
	var tier: int = int(WeaponData.DATA.get(wid, {}).get("tier", 1))
	if tier >= 5:
		return "★ Huyền thoại"
	if tier == 4:
		return "Nâng cao"
	if tier == 3:
		return "Trung cấp"
	return "Cơ bản"


static func _is_fire_or_gun(w: Dictionary) -> bool:
	var proj: String = str(w.get("proj", ""))
	return (proj in FIREARM_PROJS) or bool(w.get("fire", false)) or str(w.get("status", "")) == "burn"


static func _is_arcane_or_spirit(w: Dictionary) -> bool:
	var t: String = str(w.get("type", ""))
	var proj: String = str(w.get("proj", ""))
	return (t in ["wave", "beam", "spikes"]) or proj.begins_with("orb_") or (proj in ["soul_bolt", "talisman", "card", "bubble"]) or int(w.get("chain", 0)) > 0


static func recipe_for(wid: String) -> Dictionary:
	if not can_forge_weapon(wid):
		return {}
	var w: Dictionary = WeaponData.DATA[wid]
	var tier: int = int(w.get("tier", 1))
	var base: Dictionary = RECIPES[tier]
	var mats: Dictionary = (base.mats as Dictionary).duplicate()
	var is_fire_gun: bool = _is_fire_or_gun(w)
	var is_arcane: bool = _is_arcane_or_spirit(w)
	match tier:
		1:
			if is_fire_gun:
				mats["hoa_duoc"] = 1
			elif is_arcane:
				mats["sat"] = 1
			else:
				mats["go_lim"] = 1
		2:
			if is_fire_gun:
				mats["hoa_duoc"] = 2
			elif is_arcane:
				mats["yeu_hon"] = 1
			else:
				mats["go_lim"] = 2
		3:
			if is_fire_gun:
				mats["hoa_duoc"] = 3
			elif is_arcane:
				mats["yeu_hon"] = 3
				mats["go_lim"] = 2
			else:
				mats["go_lim"] = 3
		4:
			if is_fire_gun:
				mats["hoa_duoc"] = 4
			elif is_arcane:
				mats["yeu_hon"] = 5
				mats["ngoc_than"] = 3
			else:
				mats["go_lim"] = 4
		5:
			if is_fire_gun:
				mats["hoa_duoc"] = 8
			elif is_arcane:
				mats["yeu_hon"] = 10
				mats["ngoc_than"] = 7
			else:
				mats["go_lim"] = 8
	return {"coins": int(base.coins), "mats": mats}


static func roll_enemy_drops(is_boss: bool, is_legend: bool, is_folk: bool, elite: bool, modern: bool, mythic: bool = false) -> Array:
	var out: Array = []
	var pool: Array = MODERN_POOL if modern else ANCIENT_POOL
	if is_legend:
		out.append("ngoc_than")
		out.append("yeu_hon")
		out.append("yeu_hon")
		if mythic:
			out.append("ngoc_than")
			out.append("yeu_hon")
		return out
	if is_boss:
		if mythic:
			out.append("ngoc_than")
			out.append("yeu_hon")
			out.append("yeu_hon")
			out.append(str(pool.pick_random()))
			if randf() < 0.65:
				out.append("ngoc_than")
			return out
		var count: int = randi_range(2, 3)
		for i in count:
			out.append(str(pool.pick_random()))
		if randf() < DROP_BOSS_NGOC:
			out.append("ngoc_than")
		return out
	if elite:
		if mythic:
			if randf() < 0.72:
				out.append("ngoc_than" if randf() < 0.25 else "yeu_hon")
			return out
		if randf() < DROP_ELITE:
			out.append("yeu_hon" if is_folk else str(pool.pick_random()))
		return out
	if is_folk:
		if randf() < (0.46 if mythic else DROP_FOLK):
			out.append("yeu_hon")
		return out
	if mythic:
		if randf() < 0.30:
			out.append("yeu_hon" if randf() < 0.55 else str(pool.pick_random()))
		return out
	if randf() < DROP_NORMAL:
		out.append(str(pool.pick_random()))
	return out


static func roll_chest_drops(modern: bool, mythic: bool = false) -> Array:
	var out: Array = []
	if not mythic and randf() >= DROP_CHEST:
		return out
	var pool: Array = MODERN_POOL if modern else ANCIENT_POOL
	if mythic:
		out.append("yeu_hon" if randf() < 0.65 else str(pool.pick_random()))
		if randf() < 0.55:
			out.append("yeu_hon")
		if randf() < 0.28:
			out.append("ngoc_than")
		return out
	var count: int = randi_range(1, 2)
	for i in count:
		out.append(str(pool.pick_random()))
	return out


## Phân tách vũ khí tại Bệ Phân Tách thành xu và nguyên liệu theo cấp / Thần binh Trùm.
static func decompose_yield(wid: String) -> Dictionary:
	if wid == "" or not WeaponData.DATA.has(wid):
		return {"coins": 0, "mats": {}}
	var w: Dictionary = WeaponData.DATA[wid]
	var tier: int = clampi(int(w.get("tier", 1)), 1, 5)
	var is_boss: bool = bool(w.get("boss_motif", false))
	var is_merged: bool = bool(w.get("merged", false))
	var is_fire_gun: bool = _is_fire_or_gun(w)
	var is_arcane: bool = _is_arcane_or_spirit(w)
	var coins: int = 15
	var mats: Dictionary = {}
	match tier:
		1:
			coins = 15
			mats["dong"] = 1
			if is_fire_gun:
				mats["hoa_duoc"] = 1
			elif is_arcane:
				mats["sat"] = 1
			else:
				mats["go_lim"] = 1
		2:
			coins = 30
			mats["dong"] = 2
			mats["sat"] = 1
			if is_fire_gun:
				mats["hoa_duoc"] = 1
			elif is_arcane:
				mats["yeu_hon"] = 1
			else:
				mats["go_lim"] = 1
		3:
			coins = 65
			mats["sat"] = 2
			mats["yeu_hon"] = 1
			if is_fire_gun:
				mats["hoa_duoc"] = 2
			elif is_arcane:
				mats["yeu_hon"] = 2
			else:
				mats["go_lim"] = 2
		4:
			coins = 150
			mats["sat"] = 3
			mats["dong"] = 2
			mats["yeu_hon"] = 2
			mats["ngoc_than"] = 1
			if is_fire_gun:
				mats["hoa_duoc"] = 2
			elif is_arcane:
				mats["yeu_hon"] = 3
				mats["ngoc_than"] = 2
			else:
				mats["go_lim"] = 2
		5:
			coins = 360
			mats["sat"] = 5
			mats["dong"] = 4
			mats["yeu_hon"] = 4
			mats["ngoc_than"] = 3
			if is_fire_gun:
				mats["hoa_duoc"] = 4
			elif is_arcane:
				mats["yeu_hon"] = 5
				mats["ngoc_than"] = 4
			else:
				mats["go_lim"] = 4
	if is_boss:
		coins += 160
		mats["yeu_hon"] = int(mats.get("yeu_hon", 0)) + 2
		mats["ngoc_than"] = int(mats.get("ngoc_than", 0)) + 2
	elif is_merged:
		coins += 120
		mats["yeu_hon"] = int(mats.get("yeu_hon", 0)) + 2
		mats["ngoc_than"] = int(mats.get("ngoc_than", 0)) + 1
	return {"coins": coins, "mats": mats}
