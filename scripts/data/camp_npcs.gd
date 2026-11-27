extends RefCounted
## Dữ liệu 4 NPC Doanh Trại được giải cứu trong hầm ngục & thông số Thần Thú Thức Tỉnh (v3.0.0).

const NPC_ORDER: Array = [
	"than_y_tue_tinh",
	"nghe_nhan_phu_lang",
	"quan_su_co_loa",
	"vo_su_thien_nam",
]

const NPCS: Dictionary = {
	"than_y_tue_tinh": {
		"id": "than_y_tue_tinh",
		"name": "Danh Y Tuệ Tĩnh",
		"title": "Thánh Thuốc Nam Dược",
		"role": "Mở khóa Vườn Thảo Dược 6 luống & 2 giống thần thoại (Linh Chi Vàng, Hoa Ưu Đàm).",
		"unlocks": "Vườn Thảo Dược 6 luống + Linh Chi Vàng + Hoa Ưu Đàm",
		"herbs": ["Linh Chi Vàng", "Hoa Ưu Đàm"],
		"quote": "Nam dược trị Nam nhân — vườn thuốc đã mở rộng 6 luống!",
		"color": Color(0.42, 0.94, 0.58),
		"sprite": "world/garden_linh_chi.png",
	},
	"nghe_nhan_phu_lang": {
		"id": "nghe_nhan_phu_lang",
		"name": "Nghệ Nhân Phù Lãng",
		"title": "Bậc Thầy Gốm & Đúc Đồng",
		"role": "Mở khóa Đài Thức Tỉnh Thần Thú & giảm 20% nguyên liệu rèn/thức tỉnh.",
		"unlocks": "Đài Thức Tỉnh Thần Thú + Giảm 20% nguyên liệu rèn/thức tỉnh",
		"craft_discount": 0.20,
		"quote": "Đất Phù Lãng nung lửa đỏ, rèn nên linh thú hộ quốc!",
		"color": Color(0.96, 0.72, 0.34),
		"sprite": "world/lobby_pet_shrine.png",
	},
	"quan_su_co_loa": {
		"id": "quan_su_co_loa",
		"name": "Quân Sư Cổ Loa",
		"title": "Mưu Sĩ Thành Ốc",
		"role": "Mở khóa Gieo Quẻ Đầu Làng tại Quán Trà & chỉ dẫn Chiến Trường Cổ Loa.",
		"unlocks": "Gieo Quẻ Đầu Làng tại Quán Trà + Chỉ dẫn Chiến Trường Cổ Loa",
		"quote": "Nỏ thần đã giương, quẻ lành đã định — thành Cổ Loa bất khả xâm phạm!",
		"color": Color(0.45, 0.86, 1.0),
		"sprite": "world/coloa_core.png",
	},
	"vo_su_thien_nam": {
		"id": "vo_su_thien_nam",
		"name": "Võ Sư Thiên Nam",
		"title": "Chưởng Môn Võ Đài",
		"role": "Mở khóa Võ Đài Tỷ Thí & Thử Lửa Hào Khí.",
		"unlocks": "Võ Đài Tỷ Thí + Thử Lửa Hào Khí",
		"quote": "Lên đài tỷ thí một phen, rèn gân cốt trước giờ xuất quân!",
		"color": Color(1.0, 0.44, 0.38),
		"sprite": "world/lobby_sparring_banner.png",
	},
}

const AWAKENED_PETS: Dictionary = {
	"dog": {
		"id": "dog",
		"name": "Nghê Thần Lửa",
		"base_name": "Cún Vàng",
		"coins": 300,
		"mats": {"yeu_hon": 2, "ngoc_than": 1},
		"sprite": "world/animal_dog_evo.png",
		"fw": 28,
		"fh": 24,
		"dmg": 8,
		"atk_cd": 0.72,
		"stun": 0.45,
		"pickup_range": 185.0,
		"move_speed": 188.0,
		"color": Color(1.0, 0.56, 0.20),
		"desc": "Phóng lửa Nghê Thần (8 ST, choáng nhẹ) & hút chiến lợi phẩm bán kính 185px.",
	},
	"cat": {
		"id": "cat",
		"name": "Linh Miêu Chiêu Bảo",
		"base_name": "Mèo Tam Thể",
		"coins": 300,
		"mats": {"yeu_hon": 2, "ngoc_than": 1},
		"sprite": "world/animal_cat_evo.png",
		"fw": 26,
		"fh": 22,
		"dmg": 10,
		"atk_cd": 0.82,
		"coin_bonus": 0.35,
		"crit_bonus": 0.10,
		"color": Color(1.0, 0.82, 0.34),
		"desc": "Song trảo Linh Miêu (10 ST), +35% xu & hào quang +10% chí mạng.",
	},
	"rooster": {
		"id": "rooster",
		"name": "Kim Kê Mặt Trời",
		"base_name": "Gà Trống Chọi",
		"coins": 300,
		"mats": {"yeu_hon": 2, "ngoc_than": 1},
		"sprite": "world/animal_rooster_evo.png",
		"fw": 26,
		"fh": 26,
		"dmg": 8,
		"atk_cd": 0.42,
		"support_cd": 10.0,
		"energy_gain": 30,
		"haste_dur": 3.0,
		"color": Color(1.0, 0.72, 0.22),
		"desc": "Mổ liên hoàn 8 ST & mỗi 10s gáy hồi +30 khí + tăng tốc đánh 3s!",
	},
	"crane": {
		"id": "crane",
		"name": "Lạc Điểu Hồng Bàng",
		"base_name": "Chim Hạc Trắng",
		"coins": 350,
		"mats": {"yeu_hon": 2, "ngoc_than": 2},
		"sprite": "world/animal_crane_evo.png",
		"fw": 28,
		"fh": 36,
		"dmg": 0,
		"support_cd": 12.0,
		"armor_gain": 2,
		"clear_radius": 95.0,
		"next_level_heal": 2,
		"color": Color(0.55, 0.92, 1.0),
		"desc": "Mỗi 12s xóa đạn quanh chủ & hồi +2 Giáp; sang màn hồi +2 Máu.",
	},
}


static func get_npc(id: String) -> Dictionary:
	return NPCS.get(id, {})


static func npc_name(id: String) -> String:
	var d: Dictionary = NPCS.get(id, {})
	return str(d.get("name", id))


static func get_awakened_pet(pet_id: String) -> Dictionary:
	return AWAKENED_PETS.get(pet_id, {})
