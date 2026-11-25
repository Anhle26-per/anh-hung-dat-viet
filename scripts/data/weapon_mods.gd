extends RefCounted
## Bùa cường hóa vũ khí trong lượt chơi (gắn tại Thợ rèn lưu động).

const DATA: Dictionary = {
	"da_mai": {"name": "Đá mài", "desc": "+2 sát thương", "color": Color(1.0, 0.78, 0.35)},
	"ngoc_tiet_kiem": {"name": "Ngọc tiết kiệm", "desc": "-1 năng lượng (tối thiểu 0)", "color": Color(0.45, 0.85, 1.0)},
	"long_chim": {"name": "Lông chim", "desc": "+20% tốc độ đánh/bắn", "color": Color(0.65, 1.0, 0.65)},
	"hoa_thach": {"name": "Hỏa thạch", "desc": "Đòn đánh/đạn gây cháy", "color": Color(1.0, 0.45, 0.25)},
}

const ORDER: Array = ["da_mai", "ngoc_tiet_kiem", "long_chim", "hoa_thach"]


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
