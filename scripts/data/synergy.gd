extends RefCounted
## Đồng điệu binh khí (cấp 0/1/2 theo tướng) và Ấn hệ (6 hệ vũ khí) - thẻ G18.

const HeroData = preload("res://scripts/data/heroes.gd")
const WeaponData = preload("res://scripts/data/weapons.gd")

const FAMILY_ORDER: Array = ["kiem", "truong", "cung_no", "hoa_khi", "sung", "than_khi"]

const FAMILIES: Dictionary = {
	"kiem": {
		"name": "Đao kiếm",
		"color": Color(0.96, 0.52, 0.36),
		"weapons": [
			"kiem_dong", "doan_dao", "guom_lenh", "dao_rua", "dao_gam", "liem",
			"kiem", "ma_tau", "dao", "song_kiem", "quat_thep", "kiem_rong_tien",
			"thuan_thien", "kiem_tia_sang",
		],
	},
	"truong": {
		"name": "Côn thương",
		"color": Color(0.92, 0.78, 0.32),
		"weapons": [
			"giao_tre", "con_lam_son", "gay_tre", "giao", "mac", "kich",
			"truong_thuong", "chuy_dong", "con_nhi_khuc", "riu_da", "riu_chien",
			"roi_sat_giong", "dinh_ba_thuy_tinh", "bua_thien_loi", "tre_tram_dot",
		],
	},
	"cung_no": {
		"name": "Cung nỏ",
		"color": Color(0.48, 0.90, 0.56),
		"weapons": [
			"no_tay", "na", "cung", "no", "phi_tieu", "cung_dai", "cung_rong",
			"no_lien_chau", "cung_vang", "riu_thach_sanh",
		],
	},
	"hoa_khi": {
		"name": "Hỏa khí",
		"color": Color(1.0, 0.58, 0.22),
		"weapons": [
			"ong_lua", "hoa_ho", "hoa_tien", "than_co_sang", "phao_dong",
			"dai_bac_than_cong", "sung_phun_lua", "sung_phong_luu", "sung_phong_ten_lua",
		],
	},
	"sung": {
		"name": "Súng",
		"color": Color(0.48, 0.82, 1.0),
		"weapons": [
			"hoa_mai_yen_the", "hoa_mai", "sung_kip", "sung_ngan", "sung_luc",
			"sung_san", "sung_truong", "sung_truong_bo_binh", "sung_hai_nong",
			"tieu_lien", "sung_truong_tan_cong", "sung_ban_tia", "sung_may",
			"sung_plasma", "sung_laze", "sung_dien_tu",
		],
	},
	"than_khi": {
		"name": "Thần khí",
		"color": Color(0.84, 0.56, 1.0),
		"weapons": ["trong_dong", "dan_than", "gay_son_tinh"],
	},
}

const SIGNATURE: Dictionary = {
	"ly_thuong_kiet": "no_lien_chau",
	"le_loi": "thuan_thien",
	"quang_trung": "hoa_ho",
	"hoang_hoa_tham": "hoa_mai",
}

const IMPRINTS: Dictionary = {
	"kiem": {"name": "Kiếm khí", "waves": 6, "min_dmg": 4, "desc": "Phóng 6 sóng kiếm tỏa 360° quanh mình"},
	"truong": {"name": "Trấn địa", "radius": 60.0, "damage": 4, "knock": 260.0, "stun": 0.6, "desc": "Sóng xung kích bán kính 60, choáng 0,6s"},
	"cung_no": {"name": "Mưa tên", "count": 12, "duration": 1.5, "radius": 90.0, "damage": 3, "desc": "12 mũi tên rơi trong 1,5s quanh mình"},
	"hoa_khi": {"name": "Hỏa ấn", "count": 3, "radius": 14.0, "life": 2.0, "dist": 26.0, "desc": "Đặt 3 vùng lửa tam giác tồn tại 2s"},
	"sung": {"name": "Nạp đạn thần tốc", "duration": 4.0, "fire_rate_mult": 1.3, "pierce": 1, "desc": "Trong 4s bắn nhanh +30%, đạn xuyên thêm 1"},
	"than_khi": {"name": "Linh khí", "energy": 40, "cd_mult": 0.7, "desc": "Hồi 40 năng lượng, hồi chiêu ngắn hơn 30%"},
}

const IMPRINT_INTRO := "Ấn hệ kích hoạt theo hệ vũ khí đang cầm mỗi khi tung chiêu, luôn cộng thêm vào chiêu gốc."

const HERO_DESC: Dictionary = {
	"hai_ba_trung": {
		"lv1": "Song Trưng kéo dài 10 giây.",
		"lv2": "Song Trưng 11s; mỗi nhát chém cả hai phóng sóng kiếm 50% sát thương.",
	},
	"ba_trieu": {
		"lv1": "Voi húc +3 sát thương mỗi giặc.",
		"lv2": "Voi húc +6 sát thương; mỗi giặc bị húc hồi 1 giáp (tối đa 3).",
	},
	"ngo_quyen": {
		"lv1": "Cọc làm giặc choáng 0,5 giây.",
		"lv2": "Thêm vòng cọc ngoài, tồn tại lâu +50%, choáng 1 giây.",
	},
	"ly_thuong_kiet": {
		"lv1": "Đạn bật ngược gây sát thương ×1,5.",
		"lv2": "Đạn bật ngược ×2 và xuyên 1; khi còn vòng chữ bắn thêm 2 mũi ±12°.",
	},
	"tran_hung_dao": {
		"lv1": "Gọi 4 binh sĩ ra trận.",
		"lv2": "4 binh sĩ, +50% sát thương, dồn vào mục tiêu chủ tướng vừa đánh.",
	},
	"le_loi": {
		"lv1": "4 thanh gươm bay vòng quanh.",
		"lv2": "5 gươm; đánh cận chiến trúng giặc phóng thêm 1 gươm (0,5s/lần).",
	},
	"quang_trung": {
		"lv1": "Thần tốc tăng tầm hỏa khí ×1,5.",
		"lv2": "Tầm hỏa khí ×2; khi chạy để lại đốm lửa 1,5s gây cháy.",
	},
	"nguyen_trung_truc": {
		"lv1": "Ném 10 bầu lửa quanh mình.",
		"lv2": "12 bầu lửa; trong 4s đánh trúng giặc đang cháy gây ×2 sát thương.",
	},
	"hoang_hoa_tham": {
		"lv1": "2 phát kế tiếp không tốn nạp / năng lượng.",
		"lv2": "3 phát không cần nạp và gây choáng 0,8 giây.",
	},
	"chien_si_dien_bien": {
		"lv1": "Pháo bắn nhanh hơn 20%.",
		"lv2": "Pháo nhanh +40%; giặc trúng đạn bị đánh dấu 3s, pháo ưu tiên & +50% dmg.",
	},
}


static func family(wid: String) -> String:
	for fam in FAMILY_ORDER:
		var arr: Array = FAMILIES[fam].weapons
		if arr.has(wid):
			return str(fam)
	var w: Dictionary = WeaponData.get_data(wid)
	if w.is_empty():
		return "kiem"
	var t: String = str(w.get("type", "melee"))
	if t == "beam":
		return "sung"
	if t == "wave" or t == "spikes":
		return "than_khi"
	if t == "melee":
		return "kiem"
	var proj: String = str(w.get("proj", "bullet"))
	if proj in ["fireball", "rocket", "grenade", "cannonball"]:
		return "hoa_khi"
	if proj in ["bullet", "pellet"]:
		return "sung"
	return "cung_no"


static func family_name(fam: String) -> String:
	if FAMILIES.has(fam):
		return str(FAMILIES[fam].name)
	return "Đao kiếm"


static func family_color(fam: String) -> Color:
	if FAMILIES.has(fam):
		return FAMILIES[fam].color
	return Color.WHITE


static func imprint_data(wid: String) -> Dictionary:
	return IMPRINTS.get(family(wid), IMPRINTS["kiem"])


static func imprint_name(wid: String) -> String:
	return str(imprint_data(wid).get("name", ""))


static func signature_for(hero_id: String) -> String:
	return str(SIGNATURE.get(hero_id, ""))


static func level(hero_id: String, weapon_id: String) -> int:
	if weapon_id == "" or not HeroData.DATA.has(hero_id):
		return 0
	var base_w: String = str(HeroData.DATA[hero_id].weapon)
	if weapon_id == base_w or signature_for(hero_id) == weapon_id:
		return 2
	var fam: String = family(weapon_id)
	if fam == "than_khi" or fam == family(base_w):
		return 1
	return 0
