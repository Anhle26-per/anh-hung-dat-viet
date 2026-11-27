extends RefCounted
## Hợp Chiêu Đại Việt (LAN Co-op Synergy Ultimates):
## Hai người chơi tung kỹ năng gần nhau trong thời gian ngắn sẽ kích hoạt Hợp Chiêu.

const COMBOS: Dictionary = {
	"bach_dang_hoa_coc": {
		"id": "bach_dang_hoa_coc",
		"name": "Bạch Đằng Hỏa Cọc",
		"subtitle": "Thủy triều bãi cọc hợp kích hỏa công đại phá thủy trại!",
		"color": Color(0.36, 0.82, 1.0),
		"radius": 175.0,
		"damage": 36,
		"armor_bonus": 3,
		"energy_bonus": 45,
		"buff_dur": 4.5,
		"stun_dur": 1.4,
	},
	"nu_kiet_linh_nam": {
		"id": "nu_kiet_linh_nam",
		"name": "Nữ Kiệt Lĩnh Nam",
		"subtitle": "Song Trưng xung trận cùng Voi Chiến Núi Nưa quét sạch giặc!",
		"color": Color(0.98, 0.38, 0.56),
		"radius": 170.0,
		"damage": 34,
		"armor_bonus": 3,
		"energy_bonus": 45,
		"buff_dur": 4.5,
		"stun_dur": 1.3,
	},
	"nam_quoc_thuan_thien": {
		"id": "nam_quoc_thuan_thien",
		"name": "Nam Quốc Thuận Thiên",
		"subtitle": "Thần thi hộ quốc hội tụ Kiếm Thần Thuận Thiên trấn áp yêu tà!",
		"color": Color(0.45, 0.96, 0.74),
		"radius": 175.0,
		"damage": 35,
		"armor_bonus": 4,
		"energy_bonus": 50,
		"buff_dur": 5.0,
		"stun_dur": 1.4,
	},
	"hoa_toc_than_binh": {
		"id": "hoa_toc_than_binh",
		"name": "Hỏa Tốc Thần Binh",
		"subtitle": "Tây Sơn thần tốc hợp lửa Nhật Tảo thiêu rụi trận địa!",
		"color": Color(1.0, 0.45, 0.20),
		"radius": 170.0,
		"damage": 38,
		"armor_bonus": 2,
		"energy_bonus": 55,
		"buff_dur": 4.5,
		"stun_dur": 1.2,
	},
	"phao_kich_yen_the": {
		"id": "phao_kich_yen_the",
		"name": "Pháo Kích Yên Thế",
		"subtitle": "Hùm thiêng Yên Thế mở đường cho đại pháo Điện Biên dội sấm!",
		"color": Color(0.96, 0.74, 0.28),
		"radius": 180.0,
		"damage": 36,
		"armor_bonus": 3,
		"energy_bonus": 45,
		"buff_dur": 4.5,
		"stun_dur": 1.5,
	},
	"phu_dong_thien_vuong": {
		"id": "phu_dong_thien_vuong",
		"name": "Phù Đổng Thiên Vương",
		"subtitle": "Ngựa sắt tung vó phun lửa trời tiếp sức đồng đội xung thiên!",
		"color": Color(1.0, 0.78, 0.24),
		"radius": 185.0,
		"damage": 40,
		"armor_bonus": 3,
		"energy_bonus": 50,
		"buff_dur": 5.0,
		"stun_dur": 1.5,
	},
	"song_hung_dong_tam": {
		"id": "song_hung_dong_tam",
		"name": "Song Hùng Đồng Tâm",
		"subtitle": "Hai tướng chung một chí hướng, cộng hưởng uy lực gấp bội!",
		"color": Color(0.98, 0.86, 0.36),
		"radius": 165.0,
		"damage": 32,
		"armor_bonus": 3,
		"energy_bonus": 45,
		"buff_dur": 4.0,
		"stun_dur": 1.2,
	},
	"hop_chieu_dai_viet": {
		"id": "hop_chieu_dai_viet",
		"name": "Hợp Chiêu Đại Việt",
		"subtitle": "Hào khí Đông A hội tụ, đồng lòng phá trận!",
		"color": Color(1.0, 0.84, 0.34),
		"radius": 160.0,
		"damage": 30,
		"armor_bonus": 2,
		"energy_bonus": 40,
		"buff_dur": 4.0,
		"stun_dur": 1.2,
	},
	"son_hai_chan_thien": {
		"id": "son_hai_chan_thien",
		"name": "Sơn Hải Chấn Thiên",
		"subtitle": "Thủy triều Long Quân hợp dãy núi Tản Viên rung chuyển trời đất!",
		"color": Color(0.32, 0.88, 0.72),
		"radius": 190.0,
		"damage": 42,
		"armor_bonus": 4,
		"energy_bonus": 50,
		"buff_dur": 5.0,
		"stun_dur": 1.8,
	},
	"loa_giang_van_tien": {
		"id": "loa_giang_van_tien",
		"name": "Loa Giang Vạn Tiễn",
		"subtitle": "Nỏ Thần Cổ Loa hòa sóng cọc Bạch Đằng trút mưa tên hủy diệt!",
		"color": Color(0.40, 0.92, 0.90),
		"radius": 180.0,
		"damage": 38,
		"armor_bonus": 3,
		"energy_bonus": 50,
		"buff_dur": 4.5,
		"stun_dur": 1.4,
	},
	"thanh_son_phu_dong": {
		"id": "thanh_son_phu_dong",
		"name": "Thánh Sơn Phù Đổng",
		"subtitle": "Lửa Thánh Gióng cùng Thạch Thần Tản Viên giáng thế phá vòng vây!",
		"color": Color(0.98, 0.68, 0.24),
		"radius": 190.0,
		"damage": 44,
		"armor_bonus": 4,
		"energy_bonus": 50,
		"buff_dur": 5.0,
		"stun_dur": 1.8,
	},
	"kim_quy_than_no": {
		"id": "kim_quy_than_no",
		"name": "Kim Quy Thần Nỏ",
		"subtitle": "Kiếm Thuận Thiên cộng hưởng Nỏ Thần Kim Quy tỏa hào quang bất diệt!",
		"color": Color(0.96, 0.82, 0.34),
		"radius": 180.0,
		"damage": 39,
		"armor_bonus": 4,
		"energy_bonus": 55,
		"buff_dur": 5.0,
		"stun_dur": 1.5,
	},
}

const NAMED_PAIRS: Array = [
	["ngo_quyen", "tran_hung_dao", "bach_dang_hoa_coc"],
	["hai_ba_trung", "ba_trieu", "nu_kiet_linh_nam"],
	["ly_thuong_kiet", "le_loi", "nam_quoc_thuan_thien"],
	["quang_trung", "nguyen_trung_truc", "hoa_toc_than_binh"],
	["hoang_hoa_tham", "chien_si_dien_bien", "phao_kich_yen_the"],
	["lac_long_quan", "son_tinh", "son_hai_chan_thien"],
	["an_duong_vuong", "ngo_quyen", "loa_giang_van_tien"],
	["thanh_giong", "son_tinh", "thanh_son_phu_dong"],
	["an_duong_vuong", "le_loi", "kim_quy_than_no"],
]


static func resolve(hero_a: String, hero_b: String) -> Dictionary:
	var a: String = hero_a.strip_edges()
	var b: String = hero_b.strip_edges()
	if a != "" and a == b:
		return (COMBOS["song_hung_dong_tam"] as Dictionary).duplicate(true)
	for pair in NAMED_PAIRS:
		var p0: String = str(pair[0])
		var p1: String = str(pair[1])
		if (a == p0 and b == p1) or (a == p1 and b == p0):
			var cid: String = str(pair[2])
			return (COMBOS[cid] as Dictionary).duplicate(true)
	if (a == "thanh_giong" or b == "thanh_giong") and a != "" and b != "":
		return (COMBOS["phu_dong_thien_vuong"] as Dictionary).duplicate(true)
	return (COMBOS["hop_chieu_dai_viet"] as Dictionary).duplicate(true)
