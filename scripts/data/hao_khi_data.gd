extends RefCounted
## Dữ liệu 10 bậc độ khó Hào Khí Đại Việt (0 = Bình Thường, 1..10 = Hào Khí Bậc 1..10).

const MAX_LEVEL: int = 10

const LEVELS: Dictionary = {
	0: {
		"level": 0,
		"name": "Bình Thường",
		"hp_mult": 1.0,
		"dmg_mult": 1.0,
		"speed_mult": 1.0,
		"elite_shield_chance": 0.0,
		"extra_traps": 0,
		"shop_price_mult": 1.0,
		"phase3_enabled": false,
		"coin_mult": 1.0,
		"fragment_bonus": 0.0,
		"relic_bonus": 0.0,
	},
	1: {
		"level": 1,
		"name": "Hào Khí Bậc 1",
		"hp_mult": 1.16,
		"dmg_mult": 1.09,
		"speed_mult": 1.028,
		"elite_shield_chance": 0.0,
		"extra_traps": 0,
		"shop_price_mult": 1.06,
		"phase3_enabled": false,
		"coin_mult": 1.15,
		"fragment_bonus": 0.06,
		"relic_bonus": 0.04,
	},
	2: {
		"level": 2,
		"name": "Hào Khí Bậc 2",
		"hp_mult": 1.32,
		"dmg_mult": 1.18,
		"speed_mult": 1.056,
		"elite_shield_chance": 0.32,
		"extra_traps": 0,
		"shop_price_mult": 1.12,
		"phase3_enabled": false,
		"coin_mult": 1.30,
		"fragment_bonus": 0.12,
		"relic_bonus": 0.08,
	},
	3: {
		"level": 3,
		"name": "Hào Khí Bậc 3",
		"hp_mult": 1.48,
		"dmg_mult": 1.27,
		"speed_mult": 1.084,
		"elite_shield_chance": 0.38,
		"extra_traps": 1,
		"shop_price_mult": 1.18,
		"phase3_enabled": false,
		"coin_mult": 1.45,
		"fragment_bonus": 0.18,
		"relic_bonus": 0.12,
	},
	4: {
		"level": 4,
		"name": "Hào Khí Bậc 4",
		"hp_mult": 1.64,
		"dmg_mult": 1.36,
		"speed_mult": 1.112,
		"elite_shield_chance": 0.44,
		"extra_traps": 1,
		"shop_price_mult": 1.24,
		"phase3_enabled": true,
		"coin_mult": 1.60,
		"fragment_bonus": 0.24,
		"relic_bonus": 0.16,
	},
	5: {
		"level": 5,
		"name": "Hào Khí Bậc 5",
		"hp_mult": 1.80,
		"dmg_mult": 1.45,
		"speed_mult": 1.14,
		"elite_shield_chance": 0.50,
		"extra_traps": 1,
		"shop_price_mult": 1.30,
		"phase3_enabled": true,
		"coin_mult": 1.75,
		"fragment_bonus": 0.30,
		"relic_bonus": 0.20,
	},
	6: {
		"level": 6,
		"name": "Hào Khí Bậc 6",
		"hp_mult": 1.96,
		"dmg_mult": 1.54,
		"speed_mult": 1.168,
		"elite_shield_chance": 0.56,
		"extra_traps": 1,
		"shop_price_mult": 1.36,
		"phase3_enabled": true,
		"coin_mult": 1.90,
		"fragment_bonus": 0.36,
		"relic_bonus": 0.24,
	},
	7: {
		"level": 7,
		"name": "Hào Khí Bậc 7",
		"hp_mult": 2.12,
		"dmg_mult": 1.63,
		"speed_mult": 1.196,
		"elite_shield_chance": 0.62,
		"extra_traps": 2,
		"shop_price_mult": 1.42,
		"phase3_enabled": true,
		"coin_mult": 2.05,
		"fragment_bonus": 0.42,
		"relic_bonus": 0.28,
	},
	8: {
		"level": 8,
		"name": "Hào Khí Bậc 8",
		"hp_mult": 2.28,
		"dmg_mult": 1.72,
		"speed_mult": 1.224,
		"elite_shield_chance": 0.68,
		"extra_traps": 2,
		"shop_price_mult": 1.48,
		"phase3_enabled": true,
		"coin_mult": 2.20,
		"fragment_bonus": 0.48,
		"relic_bonus": 0.32,
	},
	9: {
		"level": 9,
		"name": "Hào Khí Bậc 9",
		"hp_mult": 2.44,
		"dmg_mult": 1.81,
		"speed_mult": 1.252,
		"elite_shield_chance": 0.74,
		"extra_traps": 2,
		"shop_price_mult": 1.54,
		"phase3_enabled": true,
		"coin_mult": 2.35,
		"fragment_bonus": 0.54,
		"relic_bonus": 0.36,
	},
	10: {
		"level": 10,
		"name": "Hào Khí Bậc 10 — Hào Khí Ngàn Năm",
		"hp_mult": 2.60,
		"dmg_mult": 1.90,
		"speed_mult": 1.28,
		"elite_shield_chance": 0.80,
		"extra_traps": 2,
		"shop_price_mult": 1.60,
		"phase3_enabled": true,
		"coin_mult": 2.50,
		"fragment_bonus": 0.60,
		"relic_bonus": 0.40,
	},
}


static func level_info(lv: int) -> Dictionary:
	var clamped: int = clampi(lv, 0, MAX_LEVEL)
	return LEVELS.get(clamped, LEVELS[0])


static func level_name(lv: int) -> String:
	var info: Dictionary = level_info(lv)
	return str(info.get("name", "Bình Thường"))


static func summary_line(lv: int) -> String:
	var clamped: int = clampi(lv, 0, MAX_LEVEL)
	var info: Dictionary = level_info(clamped)
	if clamped == 0:
		return "Bình Thường: Độ khó chuẩn · Phần thưởng chuẩn"
	var parts: Array[String] = [
		"Máu x%.2f" % float(info.get("hp_mult", 1.0)),
		"ST x%.2f" % float(info.get("dmg_mult", 1.0)),
		"Tốc x%.2f" % float(info.get("speed_mult", 1.0)),
		"Xu x%.2f" % float(info.get("coin_mult", 1.0)),
		"+%d%% Mảnh" % int(round(float(info.get("fragment_bonus", 0.0)) * 100.0)),
		"+%d%% Cổ Vật" % int(round(float(info.get("relic_bonus", 0.0)) * 100.0)),
	]
	if float(info.get("elite_shield_chance", 0.0)) > 0.0:
		parts.append("Khiên Tinh Anh %d%%" % int(round(float(info.get("elite_shield_chance", 0.0)) * 100.0)))
	if int(info.get("extra_traps", 0)) > 0:
		parts.append("+%d Bẫy" % int(info.get("extra_traps", 0)))
	if bool(info.get("phase3_enabled", false)):
		parts.append("Trùm Giai Đoạn 3")
	return " · ".join(parts)
