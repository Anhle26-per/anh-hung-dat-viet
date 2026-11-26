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
	2: {"coins": 50, "mats": {"dong": 3, "sat": 2}},
	3: {"coins": 120, "mats": {"sat": 4, "yeu_hon": 1}},
	4: {"coins": 250, "mats": {"sat": 5, "dong": 4, "yeu_hon": 2, "ngoc_than": 1}},
	5: {"coins": 400, "mats": {"sat": 6, "yeu_hon": 3, "ngoc_than": 3}},
}


static func can_forge_weapon(wid: String) -> bool:
	if not WeaponData.DATA.has(wid):
		return false
	var w: Dictionary = WeaponData.DATA[wid]
	if bool(w.get("basic", false)):
		return false
	var tier: int = int(w.get("tier", 1))
	return tier >= 2 and RECIPES.has(tier)


static func requires_blueprint(wid: String) -> bool:
	return bool(WeaponData.DATA.get(wid, {}).get("blueprint", false))


static func blueprint_grade(wid: String) -> String:
	var tier: int = int(WeaponData.DATA.get(wid, {}).get("tier", 1))
	return "Nâng cao" if tier >= 4 else "Cơ bản"


static func recipe_for(wid: String) -> Dictionary:
	if not can_forge_weapon(wid):
		return {}
	var w: Dictionary = WeaponData.DATA[wid]
	var tier: int = int(w.get("tier", 1))
	var base: Dictionary = RECIPES[tier]
	var mats: Dictionary = (base.mats as Dictionary).duplicate()
	if tier == 3:
		var proj: String = str(w.get("proj", ""))
		if proj in FIREARM_PROJS:
			mats["hoa_duoc"] = 3
		else:
			mats["go_lim"] = 3
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
