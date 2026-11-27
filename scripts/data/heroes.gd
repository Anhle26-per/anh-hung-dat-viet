extends RefCounted
## Danh sách tướng theo dòng lịch sử. Muốn thêm tướng: thêm 1 mục vào DATA và tên vào ORDER,
## vẽ hình trong tools/sprites/art_heroes.py, viết kỹ năng trong player.gd (_use_skill).
##   weapon : vũ khí cơ bản khởi đầu (cấp Thường, không tốn năng lượng)
##   skill  : mã kỹ năng
##   cost   : số xu để mở khóa (0 = có sẵn)

const HeroSkillsExt = preload("res://scripts/data/hero_skills_ext.gd")

const ORDER := ["hai_ba_trung", "ba_trieu", "ngo_quyen", "ly_thuong_kiet", "tran_hung_dao",
	"le_loi", "quang_trung", "nguyen_trung_truc", "hoang_hoa_tham", "chien_si_dien_bien", "thanh_giong",
	"an_duong_vuong", "lac_long_quan", "son_tinh"]

const DATA := {
	"hai_ba_trung": {
		"name": "Hai Bà Trưng", "era": "Năm 40 - Khởi nghĩa Mê Linh",
		"weapon": "kiem_dong", "skill": "song_trung", "skill_name": "Song Trưng",
		"skill_desc": "Trưng Nhị xuất hiện sát cánh, đánh theo mọi đòn của Trưng Trắc trong 8 giây.",
		"synergy_desc": "★ 10s  |  ★★ 11s + phóng sóng kiếm 50%",
		"skill_cd": 14.0, "hp": 6, "armor": 5, "energy": 180, "speed": 96.0,
		"color": Color(0.72, 0.19, 0.35), "accent": Color(0.94, 0.72, 0.28), "cost": 0,
	},
	"ba_trieu": {
		"name": "Bà Triệu", "era": "Năm 248 - Khởi nghĩa núi Nưa",
		"weapon": "doan_dao", "skill": "voi_chien", "skill_name": "Voi chiến",
		"skill_desc": "Cưỡi voi lao thẳng về phía trước, húc văng giặc và không mất máu.",
		"synergy_desc": "★ +3 sát thương  |  ★★ +6 sát thương, húc hồi giáp (tối đa 3)",
		"skill_cd": 7.0, "hp": 7, "armor": 4, "energy": 160, "speed": 100.0,
		"color": Color(0.90, 0.72, 0.18), "accent": Color(0.75, 0.15, 0.15), "cost": 0,
	},
	"ngo_quyen": {
		"name": "Ngô Quyền", "era": "Năm 938 - Chiến thắng Bạch Đằng",
		"weapon": "giao_tre", "skill": "coc_bach_dang", "skill_name": "Cọc Bạch Đằng",
		"skill_desc": "Nước dâng, cọc nhọn trồi lên quanh mình: đâm giặc và chặn đạn.",
		"synergy_desc": "★ Choáng 0,5s  |  ★★ Thêm vòng cọc ngoài, bền +50%, choáng 1s",
		"skill_cd": 12.0, "hp": 6, "armor": 5, "energy": 180, "speed": 95.0,
		"color": Color(0.20, 0.42, 0.72), "accent": Color(0.88, 0.72, 0.28), "cost": 0,
	},
	"ly_thuong_kiet": {
		"name": "Lý Thường Kiệt", "era": "Năm 1077 - Phòng tuyến Như Nguyệt",
		"weapon": "no_tay", "skill": "nam_quoc_son_ha", "skill_name": "Nam quốc sơn hà",
		"skill_desc": "Vòng chữ thần quanh mình trong 5 giây: đạn giặc chạm vào bị bật ngược lại.",
		"synergy_desc": "★ Bật đạn ×1,5  |  ★★ Bật ×2 xuyên 1, bắn thêm 2 mũi ±12°",
		"skill_cd": 13.0, "hp": 6, "armor": 6, "energy": 190, "speed": 94.0,
		"color": Color(0.23, 0.42, 0.66), "accent": Color(0.85, 0.87, 0.93), "cost": 200,
	},
	"tran_hung_dao": {
		"name": "Trần Hưng Đạo", "era": "Năm 1285 - Ba lần thắng quân Nguyên",
		"weapon": "guom_lenh", "skill": "hich_tuong_si", "skill_name": "Hịch tướng sĩ",
		"skill_desc": "Hồi trống đồng vang lên, 3 binh sĩ ra trận chiến đấu cùng 10 giây.",
		"synergy_desc": "★ 4 binh sĩ  |  ★★ 4 binh sĩ +50% dmg, dồn mục tiêu vừa đánh",
		"skill_cd": 14.0, "hp": 6, "armor": 6, "energy": 200, "speed": 92.0,
		"color": Color(0.70, 0.16, 0.16), "accent": Color(0.15, 0.12, 0.12), "cost": 300,
	},
	"le_loi": {
		"name": "Lê Lợi", "era": "Năm 1427 - Ải Chi Lăng",
		"weapon": "con_lam_son", "skill": "thuan_thien_kiem", "skill_name": "Gươm Thuận Thiên",
		"skill_desc": "Ba thanh gươm thần bay vòng quanh, chém mọi kẻ đến gần trong 6 giây.",
		"synergy_desc": "★ 4 gươm  |  ★★ 5 gươm, đánh cận chiến phóng gươm đâm",
		"skill_cd": 13.0, "hp": 7, "armor": 5, "energy": 190, "speed": 94.0,
		"color": Color(0.23, 0.48, 0.29), "accent": Color(0.94, 0.72, 0.28), "cost": 400,
	},
	"quang_trung": {
		"name": "Quang Trung", "era": "Năm 1789 - Đại phá quân Thanh",
		"weapon": "ong_lua", "skill": "than_toc", "skill_name": "Thần tốc",
		"skill_desc": "Trong 5 giây: chạy nhanh, đánh nhanh gấp đôi và không tốn năng lượng.",
		"synergy_desc": "★ Tầm hỏa khí ×1,5  |  ★★ Tầm ×2, chạy rải lửa gây cháy",
		"skill_cd": 13.0, "hp": 5, "armor": 5, "energy": 220, "speed": 100.0,
		"color": Color(0.16, 0.20, 0.36), "accent": Color(0.85, 0.15, 0.12), "cost": 500,
	},
	"nguyen_trung_truc": {
		"name": "Nguyễn Trung Trực", "era": "Năm 1861 - Hỏa hồng Nhật Tảo",
		"weapon": "dao_rua", "skill": "hoa_hong", "skill_name": "Hỏa hồng Nhật Tảo",
		"skill_desc": "Ném 8 bầu lửa quanh mình, biển lửa thiêu giặc trong 4 giây.",
		"synergy_desc": "★ 10 bầu lửa  |  ★★ 12 bầu lửa, trong 4s đánh giặc cháy ×2",
		"skill_cd": 12.0, "hp": 6, "armor": 5, "energy": 200, "speed": 98.0,
		"color": Color(0.91, 0.89, 0.94), "accent": Color(0.85, 0.24, 0.24), "cost": 600,
	},
	"hoang_hoa_tham": {
		"name": "Hoàng Hoa Thám", "era": "Năm 1890 - Hùm thiêng Yên Thế",
		"weapon": "hoa_mai_yen_the", "skill": "hum_thieng", "skill_name": "Hùm thiêng Yên Thế",
		"skill_desc": "Tiếng hổ gầm làm giặc choáng, hổ thần lao ra vồ mọi kẻ trên đường.",
		"synergy_desc": "★ 2 phát không nạp  |  ★★ 3 phát không nạp + choáng 0,8s",
		"skill_cd": 13.0, "hp": 6, "armor": 5, "energy": 210, "speed": 96.0,
		"color": Color(0.54, 0.35, 0.23), "accent": Color(0.91, 0.69, 0.29), "cost": 700,
	},
	"chien_si_dien_bien": {
		"name": "Chiến sĩ Điện Biên", "era": "Năm 1954 - Chiến dịch Điện Biên Phủ",
		"weapon": "sung_truong_bo_binh", "skill": "keo_phao", "skill_name": "Kéo pháo vào trận",
		"skill_desc": "Đặt khẩu pháo tự động nã đạn vào giặc trong 9 giây.",
		"synergy_desc": "★ Pháo nhanh +20%  |  ★★ Pháo +40%, đánh dấu giặc +50% dmg",
		"skill_cd": 15.0, "hp": 6, "armor": 6, "energy": 220, "speed": 96.0,
		"color": Color(0.35, 0.48, 0.23), "accent": Color(0.55, 0.42, 0.24), "cost": 800,
	},
	"thanh_giong": {
		"name": "Thánh Gióng", "era": "Truyền thuyết - Phù Đổng Thiên Vương",
		"weapon": "gay_tre", "skill": "ngua_sat", "skill_name": "Ngựa sắt phun lửa",
		"skill_desc": "Cưỡi ngựa sắt lao vút, phun luồng lửa thiêu giặc phía trước và không mất máu.",
		"synergy_desc": "★ +3 dmg húc, phun 5 cầu lửa  |  ★★ +6 dmg húc, phun 8 cầu lửa + rải lửa",
		"skill_cd": 10.0, "hp": 7, "armor": 6, "energy": 180, "speed": 100.0,
		"color": Color(0.76, 0.24, 0.20), "accent": Color(1.0, 0.78, 0.28), "cost": 1200, "secret": true, "unlock_level": 6,
	},
	"an_duong_vuong": {
		"name": "An Dương Vương", "era": "Âu Lạc - Thành Cổ Loa",
		"weapon": "no_co_loa", "skill": "mua_ten_co_loa", "skill_name": "Mưa tên Cổ Loa",
		"skill_desc": "Khai hỏa Nỏ Thần Kim Quy phóng loạt tên xuyên thấu 180° trong 4 giây.",
		"synergy_desc": "★ +3 mũi tên xuyên  |  ★★ Tạo vòng hào quang Kim Quy chặn đạn & bắn liên hoàn",
		"skill_cd": 12.0, "hp": 6, "armor": 6, "energy": 210, "speed": 96.0,
		"color": Color(0.86, 0.62, 0.22), "accent": Color(0.35, 0.90, 0.85), "cost": 900,
	},
	"lac_long_quan": {
		"name": "Lạc Long Quân", "era": "Hồng Bàng - Quốc Tổ Bách Việt",
		"weapon": "long_uyen_kiem", "skill": "thuy_long_trieu", "skill_name": "Thủy long triều",
		"skill_desc": "Triệu hồi Song Long Biển Đông xoay quanh người công kích và xóa đạn giặc trong 6 giây.",
		"synergy_desc": "★ Thủy Long to & gây choáng  |  ★★ Hồi 2 Giáp + phóng 6 sóng Rồng tỏa tròn",
		"skill_cd": 13.5, "hp": 7, "armor": 6, "energy": 210, "speed": 98.0,
		"color": Color(0.20, 0.65, 0.92), "accent": Color(0.98, 0.84, 0.36), "cost": 1100,
	},
	"son_tinh": {
		"name": "Sơn Tinh", "era": "Truyền thuyết - Tản Viên Sơn Thánh",
		"weapon": "bua_tan_vien", "skill": "doi_non_lap_be", "skill_name": "Dời non lấp bể",
		"skill_desc": "Gọi 3 dãy núi đá Tản Viên trồi lên nghiền nát, hất tung và làm choáng giặc.",
		"synergy_desc": "★ +2 dãy trụ đá & giáp +2  |  ★★ Chấn động toàn màn gây choáng 1,8s",
		"skill_cd": 12.5, "hp": 8, "armor": 6, "energy": 190, "speed": 92.0,
		"color": Color(0.45, 0.68, 0.34), "accent": Color(0.90, 0.66, 0.32), "cost": 1000,
	},
}


static func passive_info(hid: String) -> Dictionary:
	return HeroSkillsExt.get_passive(hid)


static func skill_info(hid: String, idx: int = 1) -> Dictionary:
	if not DATA.has(hid):
		return {}
	var out: Dictionary = (DATA[hid] as Dictionary).duplicate()
	if idx == 2 and HeroSkillsExt.SKILLS_2.has(hid):
		var s2: Dictionary = HeroSkillsExt.SKILLS_2[hid]
		for k in s2:
			out[k] = s2[k]
	return out
