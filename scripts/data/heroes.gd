extends RefCounted
## Danh sách tướng theo dòng lịch sử. Muốn thêm tướng: thêm 1 mục vào DATA và tên vào ORDER,
## vẽ hình trong tools/sprites/art_heroes.py, viết kỹ năng trong player.gd (_use_skill).
##   weapon : vũ khí cơ bản khởi đầu (cấp Thường, không tốn năng lượng)
##   skill  : mã kỹ năng
##   cost   : số xu để mở khóa (0 = có sẵn)

const ORDER := ["hai_ba_trung", "ba_trieu", "ngo_quyen", "ly_thuong_kiet", "tran_hung_dao",
	"le_loi", "quang_trung", "nguyen_trung_truc", "hoang_hoa_tham", "chien_si_dien_bien"]

const DATA := {
	"hai_ba_trung": {
		"name": "Hai Bà Trưng", "era": "Năm 40 - Khởi nghĩa Mê Linh",
		"weapon": "kiem_dong", "skill": "song_trung", "skill_name": "Song Trưng",
		"skill_desc": "Trưng Nhị xuất hiện sát cánh, đánh theo mọi đòn của Trưng Trắc trong 8 giây.",
		"skill_cd": 14.0, "hp": 6, "armor": 5, "energy": 180, "speed": 96.0,
		"color": Color(0.72, 0.19, 0.35), "accent": Color(0.94, 0.72, 0.28), "cost": 0,
	},
	"ba_trieu": {
		"name": "Bà Triệu", "era": "Năm 248 - Khởi nghĩa núi Nưa",
		"weapon": "doan_dao", "skill": "voi_chien", "skill_name": "Voi chiến",
		"skill_desc": "Cưỡi voi lao thẳng về phía trước, húc văng giặc và không mất máu.",
		"skill_cd": 7.0, "hp": 7, "armor": 4, "energy": 160, "speed": 100.0,
		"color": Color(0.90, 0.72, 0.18), "accent": Color(0.75, 0.15, 0.15), "cost": 0,
	},
	"ngo_quyen": {
		"name": "Ngô Quyền", "era": "Năm 938 - Chiến thắng Bạch Đằng",
		"weapon": "giao_tre", "skill": "coc_bach_dang", "skill_name": "Cọc Bạch Đằng",
		"skill_desc": "Nước dâng, cọc nhọn trồi lên quanh mình: đâm giặc và chặn đạn.",
		"skill_cd": 12.0, "hp": 6, "armor": 5, "energy": 180, "speed": 95.0,
		"color": Color(0.20, 0.42, 0.72), "accent": Color(0.88, 0.72, 0.28), "cost": 0,
	},
	"ly_thuong_kiet": {
		"name": "Lý Thường Kiệt", "era": "Năm 1077 - Phòng tuyến Như Nguyệt",
		"weapon": "no_tay", "skill": "nam_quoc_son_ha", "skill_name": "Nam quốc sơn hà",
		"skill_desc": "Vòng chữ thần quanh mình trong 5 giây: đạn giặc chạm vào bị bật ngược lại.",
		"skill_cd": 13.0, "hp": 6, "armor": 6, "energy": 190, "speed": 94.0,
		"color": Color(0.23, 0.42, 0.66), "accent": Color(0.85, 0.87, 0.93), "cost": 200,
	},
	"tran_hung_dao": {
		"name": "Trần Hưng Đạo", "era": "Năm 1285 - Ba lần thắng quân Nguyên",
		"weapon": "guom_lenh", "skill": "hich_tuong_si", "skill_name": "Hịch tướng sĩ",
		"skill_desc": "Hồi trống đồng vang lên, 3 binh sĩ ra trận chiến đấu cùng 10 giây.",
		"skill_cd": 14.0, "hp": 6, "armor": 6, "energy": 200, "speed": 92.0,
		"color": Color(0.70, 0.16, 0.16), "accent": Color(0.15, 0.12, 0.12), "cost": 300,
	},
	"le_loi": {
		"name": "Lê Lợi", "era": "Năm 1427 - Ải Chi Lăng",
		"weapon": "con_lam_son", "skill": "thuan_thien_kiem", "skill_name": "Gươm Thuận Thiên",
		"skill_desc": "Ba thanh gươm thần bay vòng quanh, chém mọi kẻ đến gần trong 6 giây.",
		"skill_cd": 13.0, "hp": 7, "armor": 5, "energy": 190, "speed": 94.0,
		"color": Color(0.23, 0.48, 0.29), "accent": Color(0.94, 0.72, 0.28), "cost": 400,
	},
	"quang_trung": {
		"name": "Quang Trung", "era": "Năm 1789 - Đại phá quân Thanh",
		"weapon": "ong_lua", "skill": "than_toc", "skill_name": "Thần tốc",
		"skill_desc": "Trong 5 giây: chạy nhanh, đánh nhanh gấp đôi và không tốn năng lượng.",
		"skill_cd": 13.0, "hp": 5, "armor": 5, "energy": 220, "speed": 100.0,
		"color": Color(0.16, 0.20, 0.36), "accent": Color(0.85, 0.15, 0.12), "cost": 500,
	},
	"nguyen_trung_truc": {
		"name": "Nguyễn Trung Trực", "era": "Năm 1861 - Hỏa hồng Nhật Tảo",
		"weapon": "dao_rua", "skill": "hoa_hong", "skill_name": "Hỏa hồng Nhật Tảo",
		"skill_desc": "Ném 8 bầu lửa quanh mình, biển lửa thiêu giặc trong 4 giây.",
		"skill_cd": 12.0, "hp": 6, "armor": 5, "energy": 200, "speed": 98.0,
		"color": Color(0.91, 0.89, 0.94), "accent": Color(0.85, 0.24, 0.24), "cost": 600,
	},
	"hoang_hoa_tham": {
		"name": "Hoàng Hoa Thám", "era": "Năm 1890 - Hùm thiêng Yên Thế",
		"weapon": "hoa_mai_yen_the", "skill": "hum_thieng", "skill_name": "Hùm thiêng Yên Thế",
		"skill_desc": "Tiếng hổ gầm làm giặc choáng, hổ thần lao ra vồ mọi kẻ trên đường.",
		"skill_cd": 13.0, "hp": 6, "armor": 5, "energy": 210, "speed": 96.0,
		"color": Color(0.54, 0.35, 0.23), "accent": Color(0.91, 0.69, 0.29), "cost": 700,
	},
	"chien_si_dien_bien": {
		"name": "Chiến sĩ Điện Biên", "era": "Năm 1954 - Chiến dịch Điện Biên Phủ",
		"weapon": "sung_truong_bo_binh", "skill": "keo_phao", "skill_name": "Kéo pháo vào trận",
		"skill_desc": "Đặt khẩu pháo tự động nã đạn vào giặc trong 9 giây.",
		"skill_cd": 15.0, "hp": 6, "armor": 6, "energy": 220, "speed": 96.0,
		"color": Color(0.35, 0.48, 0.23), "accent": Color(0.55, 0.42, 0.24), "cost": 800,
	},
}
