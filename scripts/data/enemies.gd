extends RefCounted
## Kẻ địch và 10 chương lịch sử (năm 40 đến năm 1954).
## Dựa trên các cuộc kháng chiến có thật, thêm hư cấu cho kịch tính:
## pháp sư của giặc dùng tà thuật gọi yêu quái dân gian ra trợ chiến.

# Loại lính (hình: enemies/<quân>_<loại>.png)
const ARCHETYPES := {
	# thời phong kiến
	"bo_binh": {"name": "Bộ binh", "hp": 15, "speed": 74.0, "radius": 7.0, "ai": "chase", "coins": 1},
	"cung_thu": {"name": "Cung thủ", "hp": 12, "speed": 62.0, "radius": 7.0, "ai": "shoot", "shoot_cd": 1.35, "coins": 1},
	"khien_binh": {"name": "Khiên binh", "hp": 30, "speed": 42.0, "radius": 8.0, "ai": "tank", "coins": 2},
	"phap_su": {"name": "Pháp sư", "hp": 19, "speed": 50.0, "radius": 7.0, "ai": "caster", "shoot_cd": 2.2, "coins": 2},
	"ky_binh": {"name": "Kỵ binh", "hp": 24, "speed": 78.0, "radius": 10.0, "ai": "charge", "coins": 2,
		"sheet": "enemies/nguyen_mong_ky_binh.png", "size": Vector2i(34, 30), "frames": 8},
	# thời cận đại
	"linh_sung": {"name": "Lính súng trường", "hp": 16, "speed": 60.0, "radius": 7.0, "ai": "rifle", "shoot_cd": 1.2, "coins": 1},
	"xa_thu": {"name": "Xạ thủ súng máy", "hp": 22, "speed": 46.0, "radius": 7.0, "ai": "mg", "shoot_cd": 2.1, "coins": 2},
	"phao_binh": {"name": "Pháo cối", "hp": 17, "speed": 44.0, "radius": 7.0, "ai": "mortar", "shoot_cd": 2.5, "coins": 2},
	"xe_tang": {"name": "Xe tăng", "hp": 95, "speed": 30.0, "radius": 14.0, "ai": "tank_elite", "shoot_cd": 2.0, "coins": 6,
		"sheet": "enemies/xe_tang.png", "size": Vector2i(40, 30), "frames": 8},
}

# Yêu quái do tà thuật gọi ra
const FOLK := {
	"tieu_yeu": {"name": "Tiểu yêu", "hp": 12, "speed": 82.0, "radius": 7.0, "ai": "chase", "coins": 1,
		"sheet": "enemies/tieu_yeu.png", "size": Vector2i(16, 17), "frames": 8},
	"ho_tinh": {"name": "Hồ tinh", "hp": 13, "speed": 66.0, "radius": 7.0, "ai": "shoot", "shoot_cd": 1.3, "coins": 1,
		"sheet": "enemies/ho_tinh.png", "size": Vector2i(22, 16), "proj": "orb_pink", "frames": 8},
	"moc_tinh": {"name": "Mộc tinh", "hp": 30, "speed": 32.0, "radius": 10.0, "ai": "ring", "shoot_cd": 2.2, "coins": 2,
		"sheet": "enemies/moc_tinh.png", "size": Vector2i(26, 28), "frames": 8},
	"chan_tinh": {"name": "Chằn tinh", "hp": 52, "speed": 40.0, "radius": 11.0, "ai": "slam", "shoot_cd": 2.7, "coins": 3,
		"sheet": "enemies/chan_tinh.png", "size": Vector2i(30, 32), "frames": 8},
	"dai_bang": {"name": "Đại bàng tinh", "hp": 18, "speed": 88.0, "radius": 9.0, "ai": "charge", "coins": 2,
		"sheet": "enemies/dai_bang.png", "size": Vector2i(36, 26), "frames": 8},
	"ma_troi": {"name": "Ma trơi", "hp": 7, "speed": 74.0, "radius": 6.0, "ai": "kamikaze", "coins": 1,
		"sheet": "enemies/ma_troi.png", "size": Vector2i(14, 18), "frames": 8},
	"ngu_tinh": {"name": "Thủy quái Ngư Tinh", "hp": 150, "speed": 50.0, "radius": 18.0, "ai": "ngu", "coins": 6,
		"sheet": "enemies/ngu_tinh.png", "size": Vector2i(60, 46), "frames": 8},
}

# Trùm: mỗi chương một kẻ cầm đầu từng bị đánh bại
const BOSSES := {
	"to_dinh": {"name": "Tô Định", "title": "Thái thú Giao Chỉ", "hp": 260, "speed": 50.0,
		"intro": "Thái thú tàn bạo — vung đao lao tới, cùng đường sẽ giả trang bỏ chạy!",
		"patterns": ["sweep", "ring", "charge", "summon"], "summon": "bo_binh", "special": "tron_chay", "patterns2": ["ring", "charge", "spiral", "summon"], "form2": "Quỷ Tham Tàn"},
	"luc_dan": {"name": "Lục Dận", "title": "Tướng nhà Đông Ngô", "hp": 300, "speed": 50.0,
		"intro": "Danh tướng Đông Ngô — múa kích càn lướt, dựng trận khiên cố thủ!",
		"patterns": ["sweep", "charge", "ring", "summon"], "summon": "bo_binh", "special": "tran_khien", "patterns2": ["sweep", "fan", "charge", "ring"], "form2": "Quỷ Gai Đông Ngô"},
	"hoang_thao": {"name": "Hoằng Tháo", "title": "Thái tử Nam Hán", "hp": 340, "speed": 48.0,
		"intro": "Thái tử Nam Hán — đâm đinh ba xé sóng, gọi Thủy Quái trợ chiến!",
		"patterns": ["spiral", "charge", "ring", "summon"], "summon": "cung_thu", "special": "thuy_quai", "patterns2": ["spiral", "charge", "fan", "volley"], "form2": "Thủy Quỷ Nam Hán"},
	"quach_quy": {"name": "Quách Quỳ", "title": "Tướng nhà Tống", "hp": 360, "speed": 48.0,
		"intro": "Thống soái quân Tống — bắn mưa tên phủ kín trận địa và xung phong!",
		"patterns": ["volley", "charge", "sweep", "summon"], "summon": "khien_binh", "special": "mua_ten", "patterns2": ["volley", "charge", "spiral", "fan"], "form2": "Ưng Quỷ Tống Triều"},
	"thoat_hoan": {"name": "Thoát Hoan", "title": "Trấn Nam Vương nhà Nguyên", "hp": 380, "speed": 52.0,
		"intro": "Trấn Nam Vương — gọi kỵ binh càn quét, nguy cấp chui ống đồng lăn tới!",
		"patterns": ["volley", "charge", "sweep", "summon"], "summon": "ky_binh", "special": "ong_dong", "patterns2": ["charge", "volley", "ring", "charge"], "form2": "Lang Quỷ Thảo Nguyên"},
	"lieu_thang": {"name": "Liễu Thăng", "title": "Tổng binh nhà Minh", "hp": 400, "speed": 54.0,
		"intro": "Tổng binh nhà Minh — vung đao lao chém dữ dội, biến hình nhảy đập đất!",
		"patterns": ["charge", "sweep", "volley", "summon"], "summon": "bo_binh", "special": "sa_lay", "patterns2": ["leap_slam", "charge", "spiral", "sweep"], "form2": "Quỷ Rừng Sa Lầy"},
	"ton_si_nghi": {"name": "Tôn Sĩ Nghị", "title": "Tổng đốc Lưỡng Quảng", "hp": 420, "speed": 46.0,
		"intro": "Tổng đốc Lưỡng Quảng — nã đại bác liên hồi, quạt gió đẩy lùi đối thủ!",
		"patterns": ["cannon", "charge", "ring", "summon"], "summon": "phap_su", "special": "bo_chay", "patterns2": ["cannon", "charge", "spiral", "fan"], "form2": "Ngưu Quỷ Lưỡng Quảng"},
	"tau_hy_vong": {"name": "Tàu chiến Hy Vọng", "title": "Chiến thuyền thủy quân Pháp", "hp": 460, "speed": 30.0,
		"intro": "Chiến hạm Pháp — giương buồm húc thẳng, nã loạt đại bác mạn tàu!",
		"patterns": ["broadside", "charge", "ring", "summon"], "summon": "linh_sung", "special": "boc_chay", "patterns2": ["broadside", "charge", "cannon", "ring"], "form2": "Tàu Ma Lửa Xanh",
		"sheet": "enemies/boss_tau_hy_vong.png", "size": Vector2i(64, 44), "frames": 7, "radius": 20.0},
	"don_truong": {"name": "Đồn trưởng Nhã Nam", "title": "Chỉ huy quân viễn chinh", "hp": 480, "speed": 50.0,
		"intro": "Chỉ huy đồn bốt — xả súng liên thanh kết hợp gọi pháo kích diện rộng!",
		"patterns": ["burst", "charge", "mortar", "summon"], "summon": "xa_thu", "special": "phao_kich", "patterns2": ["burst", "charge", "mortar", "spiral"], "form2": "Quỷ Gai Đồn Bốt"},
	"do_cat": {"name": "Đờ Cát", "title": "Chỉ huy tập đoàn cứ điểm Điện Biên Phủ", "hp": 520, "speed": 46.0,
		"intro": "Chỉ huy Điện Biên Phủ — gọi xe tăng và pháo cối, cố thủ hầm chỉ huy!",
		"patterns": ["burst", "mortar", "charge", "summon"], "summon": "xe_tang", "special": "ham_chi_huy", "patterns2": ["burst", "leap_slam", "mortar", "cannon"], "form2": "Ngưu Quỷ Hầm Ngầm"},
}


## Tam Yêu trong truyền thuyết Lạc Long Quân: trùm giữa chương (màn 2 của chương, ngẫu nhiên).
## Mỗi yêu có hình thường và hình "hiện nguyên hình" khi còn nửa máu.
const LEGENDS := {
	"ho_tinh_vuong": {"name": "Hồ Tinh", "title": "Cáo chín đuôi đầm Xác Cáo", "speed": 72.0, "radius": 15.0,
		"intro": "Yêu cáo nghìn năm — phi nước đại tung lửa hồ ly và phân thân ảo ảnh!",
		"patterns": ["tails", "clone", "sweep", "charge"], "patterns2": ["tails", "clone", "spiral", "charge"],
		"summon": "ho_tinh", "special": "cuu_vi", "form2": "Cửu Vĩ Hồ Ly",
		"size": Vector2i(84, 60), "size2": Vector2i(84, 60)},
	"moc_tinh_vuong": {"name": "Mộc Tinh", "title": "Cây chiên đàn nghìn năm", "speed": 24.0, "radius": 18.0,
		"intro": "Cổ thụ thành tinh — nhảy đập rung chuyển mặt đất, trồi rễ cây vây hãm!",
		"patterns": ["roots", "leap_slam", "ring", "summon"], "patterns2": ["roots", "leap_slam", "spiral", "roots"],
		"summon": "moc_tinh", "special": "rung_gia", "form2": "Mộc Tinh Lửa Đỏ",
		"size": Vector2i(72, 72), "size2": Vector2i(72, 72)},
	"ngu_tinh_vuong": {"name": "Ngư Tinh", "title": "Thủy quái Biển Đông", "speed": 46.0, "radius": 18.0,
		"intro": "Thủy quái Biển Đông — lặn ngầm tập kích dưới chân, dâng sóng thần!",
		"patterns": ["dive", "spiral", "fan", "summon"], "patterns2": ["dive", "charge", "tidal", "spiral"],
		"summon": "tieu_yeu", "special": "song_than", "form2": "Ngư Tinh Hắc Hải",
		"size": Vector2i(84, 60), "size2": Vector2i(84, 60)},
}
const LEGEND_BASE_HP := 260

const CHAPTERS := [
	{"name": "Mê Linh", "year": "Năm 40", "army": "dong_han", "army_name": "Quân Đông Hán", "boss": "to_dinh",
		"theme": 4, "decor": ["bamboo", "banner", "pot"], "folk": ["tieu_yeu", "ma_troi"], "dark": Color(0.82, 0.78, 0.72),
		"intro": "Thái thú Tô Định tàn bạo. Hai Bà Trưng phất cờ khởi nghĩa ở Mê Linh!"},
	{"name": "Núi Nưa", "year": "Năm 248", "army": "dong_ngo", "army_name": "Quân Đông Ngô", "boss": "luc_dan",
		"theme": 0, "decor": ["bamboo", "banner", "pot"], "folk": ["tieu_yeu", "chan_tinh"], "dark": Color(0.78, 0.82, 0.76),
		"intro": "Quân Đông Ngô tràn xuống Cửu Chân. Bà Triệu cưỡi voi ra trận!"},
	{"name": "Sông Bạch Đằng", "year": "Năm 938", "army": "nam_han", "army_name": "Quân Nam Hán", "boss": "hoang_thao",
		"theme": 1, "decor": ["lantern", "pot", "banner"], "folk": ["ho_tinh"], "dark": Color(0.71, 0.76, 0.88),
		"intro": "Thuyền giặc Nam Hán theo thủy triều vào sông. Bãi cọc đã cắm sẵn!"},
	{"name": "Sông Như Nguyệt", "year": "Năm 1077", "army": "tong", "army_name": "Quân Tống", "boss": "quach_quy",
		"theme": 1, "decor": ["banner", "lantern", "pot"], "folk": ["dai_bang", "ho_tinh"], "dark": Color(0.74, 0.78, 0.86),
		"intro": "Quân Tống áp sát phòng tuyến. Bài thơ Nam quốc sơn hà vang lên giữa đêm!"},
	{"name": "Thành Thăng Long", "year": "Năm 1285", "army": "nguyen_mong", "army_name": "Quân Nguyên Mông", "boss": "thoat_hoan",
		"theme": 2, "decor": ["banner", "lantern", "pot"], "folk": ["moc_tinh", "tieu_yeu"], "dark": Color(0.84, 0.71, 0.71),
		"intro": "Vó ngựa Nguyên Mông vào Thăng Long. Hịch tướng sĩ vang lên!"},
	{"name": "Ải Chi Lăng", "year": "Năm 1427", "army": "minh", "army_name": "Quân Minh", "boss": "lieu_thang",
		"theme": 0, "decor": ["bamboo", "banner", "pot"], "folk": ["chan_tinh", "dai_bang"], "dark": Color(0.72, 0.78, 0.72),
		"intro": "Mười vạn quân Minh kéo sang. Nghĩa quân Lam Sơn mai phục ở ải Chi Lăng!"},
	{"name": "Gò Đống Đa", "year": "Tết Kỷ Dậu 1789", "army": "thanh", "army_name": "Quân Thanh", "boss": "ton_si_nghi",
		"theme": 3, "decor": ["peach", "lantern", "banner"], "folk": ["ho_tinh", "moc_tinh"], "dark": Color(0.78, 0.74, 0.84),
		"intro": "Mùng 5 Tết, đại quân Tây Sơn thần tốc tiến về Thăng Long!"},
	{"name": "Vàm Nhật Tảo", "year": "Năm 1861", "army": "phap_thuy", "army_name": "Thủy quân Pháp", "boss": "tau_hy_vong",
		"theme": 1, "decor": ["crate", "lantern", "pot"], "folk": ["ma_troi"], "dark": Color(0.68, 0.72, 0.84), "modern": true,
		"intro": "Tàu chiến Hy Vọng neo trên vàm Nhật Tảo. Đêm nay nó sẽ bốc cháy!"},
	{"name": "Rừng Yên Thế", "year": "Năm 1890", "army": "phap_vien_chinh", "army_name": "Quân viễn chinh Pháp", "boss": "don_truong",
		"theme": 5, "decor": ["crate", "sandbag", "bamboo"], "folk": ["chan_tinh", "ma_troi"], "dark": Color(0.76, 0.78, 0.70), "modern": true,
		"intro": "Hùm thiêng Yên Thế vẫn đứng vững giữa núi rừng. Đồn giặc sắp vỡ!"},
	{"name": "Điện Biên Phủ", "year": "Năm 1954", "army": "phap_1954", "army_name": "Tập đoàn cứ điểm", "boss": "do_cat",
		"theme": 6, "decor": ["sandbag", "crate", "sandbag"], "folk": ["ma_troi"], "dark": Color(0.74, 0.72, 0.66), "modern": true,
		"intro": "Năm mươi sáu ngày đêm khoét núi, ngủ hầm. Lừng lẫy năm châu, chấn động địa cầu!"},
]


const MYTHIC_CHAPTERS := [
	{
		"name": "Đầm Xác Cáo",
		"year": "Thần Thoại · Lĩnh Nam",
		"intro": "Cửu Vĩ Hồ Tinh khuấy động chướng khí đầm Xác Cáo!",
		"army": "dong_han",
		"army_name": "Yêu Quân Đầm Cáo",
		"boss": "cuu_vi_ho",
		"theme": 3,
		"decor": ["lantern", "pot", "bamboo"],
		"folk": ["ho_tinh", "tieu_yeu", "ma_troi"],
		"dark": Color(0.76, 0.68, 0.88),
		"mythic": true,
	},
	{
		"name": "Rừng Chiên Đàn",
		"year": "Thần Thoại · Lĩnh Nam",
		"intro": "Xương Cuồng Mộc Tinh nghìn năm vươn rễ nuốt chửng đại ngàn!",
		"army": "minh",
		"army_name": "Yêu Binh Rừng Già",
		"boss": "xuong_cuong",
		"theme": 0,
		"decor": ["bamboo", "pot", "banner"],
		"folk": ["moc_tinh", "chan_tinh", "dai_bang"],
		"dark": Color(0.68, 0.80, 0.72),
		"mythic": true,
	},
	{
		"name": "Biển Đông Hắc Hải",
		"year": "Thần Thoại · Lĩnh Nam",
		"intro": "Hắc Hải Ngư Tinh Vương dâng sóng thần thử lửa anh hùng!",
		"army": "nam_han",
		"army_name": "Thủy Yêu Biển Đông",
		"boss": "hac_hai_ngu",
		"theme": 1,
		"decor": ["lantern", "pot", "banner"],
		"folk": ["ngu_tinh", "dai_bang", "ho_tinh"],
		"dark": Color(0.66, 0.74, 0.90),
		"mythic": true,
	},
]

const MYTHIC_BOSSES := {
	"cuu_vi_ho": {
		"name": "Cửu Vĩ Hồ Vương",
		"title": "Yêu Cáo Chín Đuôi Đầm Xác Cáo",
		"intro": "Cửu Vĩ Yêu Vương — chín đuôi xoay lửa hồ ly ngập trời, phi thân siêu tốc!",
		"hp": 920,
		"speed": 74.0,
		"radius": 16.0,
		"radius2": 16.0,
		"patterns": ["tails", "clone", "sweep", "charge"],
		"patterns2": ["tails", "clone", "spiral", "charge"],
		"summon": "ho_tinh",
		"special": "cuu_vi",
		"form2": "Cửu Vĩ Yêu Vương",
		"sheet": "enemies/boss_ho_tinh_vuong.png",
		"sheet2": "enemies/boss_ho_tinh_vuong_2.png",
		"size": Vector2i(84, 60),
		"size2": Vector2i(84, 60),
		"frames": 7,
		"mythic": true,
	},
	"xuong_cuong": {
		"name": "Xương Cuồng Mộc Tinh",
		"title": "Thần Mộc Nghìn Năm Rừng Chiên Đàn",
		"intro": "Thần Mộc Ma Thụ — rễ cổ thụ trồi hàng loạt, tung cú nhảy chấn địa!",
		"hp": 1180,
		"speed": 30.0,
		"radius": 18.0,
		"radius2": 18.0,
		"patterns": ["roots", "leap_slam", "ring", "summon"],
		"patterns2": ["roots", "leap_slam", "spiral", "roots"],
		"summon": "moc_tinh",
		"special": "rung_gia",
		"form2": "Xương Cuồng Ma Thụ",
		"sheet": "enemies/boss_moc_tinh_vuong.png",
		"sheet2": "enemies/boss_moc_tinh_vuong_2.png",
		"size": Vector2i(72, 72),
		"size2": Vector2i(72, 72),
		"frames": 7,
		"mythic": true,
	},
	"hac_hai_ngu": {
		"name": "Hắc Hải Ngư Tinh Vương",
		"title": "Thủy Quái Hung Tàn Biển Đông",
		"intro": "Bá Chủ Biển Đen — lặn sóng ngầm lao húc, cuốn sóng thần càn quét!",
		"hp": 1450,
		"speed": 52.0,
		"radius": 18.0,
		"radius2": 18.0,
		"patterns": ["dive", "spiral", "fan", "summon"],
		"patterns2": ["dive", "charge", "tidal", "spiral"],
		"summon": "ngu_tinh",
		"special": "song_than",
		"form2": "Bá Chủ Biển Đen",
		"sheet": "enemies/boss_ngu_tinh_vuong.png",
		"sheet2": "enemies/boss_ngu_tinh_vuong_2.png",
		"size": Vector2i(84, 60),
		"size2": Vector2i(84, 60),
		"frames": 7,
		"mythic": true,
	},
}


static func is_victory_hall(level: int) -> bool:
	return level == 16 or level >= 32


static func is_mythic_level(level: int) -> bool:
	return level >= 17 and level <= 31


static func is_boss_level(level: int) -> bool:
	if level >= 1 and level <= 15:
		return level % 5 == 0
	if level >= 17 and level <= 31:
		return (level - 16) % 5 == 0
	return false


static func is_legend_mid_level(level: int) -> bool:
	return stage_in_chapter(level) == 3 and not is_victory_hall(level)


static func stage_chapter_num(level: int) -> int:
	if level <= 15:
		return int((maxi(level, 1) - 1) / 5) + 1
	if level == 16:
		return 3
	if level <= 31:
		return 4 + int((level - 17) / 5)
	return 6


static func stage_in_chapter(level: int) -> int:
	if level == 16 or level >= 32:
		return 6
	if level <= 15:
		return (maxi(level, 1) - 1) % 5 + 1
	return (level - 17) % 5 + 1


static func chapter_index(level: int) -> int:
	if is_mythic_level(level):
		return int((level - 17) / 5) % MYTHIC_CHAPTERS.size()
	if level >= 32:
		return MYTHIC_CHAPTERS.size() - 1
	var eff_lv: int = mini(maxi(level, 1), 15)
	var ch_seq: int = int((eff_lv - 1) / 5)
	if Global != null and Global.has_method("chapter_at"):
		return Global.chapter_at(ch_seq) % CHAPTERS.size()
	return ch_seq % CHAPTERS.size()


static func chapter(level: int) -> Dictionary:
	if is_mythic_level(level) or level >= 32:
		return MYTHIC_CHAPTERS[chapter_index(level)]
	return CHAPTERS[chapter_index(level)]


## Độ khó theo tiến trình màn (tăng dần từ 1-1 -> 3-5, sang 4-1 -> 6-5 nâng cấp rõ rệt)
static func loop_mult(level: int) -> float:
	if level <= 16:
		return 1.0
	return 1.45


## Trùm thứ mấy của lượt chơi (0..2 ở 3 chương lịch sử, 3..5 ở Chuyến Du Hành Thần Thoại)
static func boss_index(level: int) -> int:
	if level <= 15:
		return int((maxi(level, 1) - 1) / 5)
	if level == 16:
		return 2
	if level <= 31:
		return 3 + int((level - 17) / 5)
	return 5


## Mã trùm ở màn này
static func boss_id(level: int) -> String:
	if is_mythic_level(level) or level >= 32:
		var mch: Dictionary = MYTHIC_CHAPTERS[chapter_index(level)]
		return str(mch.boss)
	return Global.boss_at(boss_index(level))


## Chương gốc (đạo quân) của 1 trùm, để trùm gọi đúng lính của mình
static func home_chapter(boss: String) -> Dictionary:
	for ch in CHAPTERS:
		if ch.boss == boss:
			return ch
	for mch in MYTHIC_CHAPTERS:
		if mch.boss == boss:
			return mch
	return CHAPTERS[0]


static func army_name(army: String) -> String:
	for ch in CHAPTERS:
		if ch.army == army:
			return ch.army_name
	for mch in MYTHIC_CHAPTERS:
		if mch.army == army:
			return mch.army_name
	return ""


## Máu trùm tăng rõ rệt qua từng chương (trùm 1: 300, trùm 2: 480, trùm 3: 660;
## trùm Thần Thoại dùng mức máu riêng: 920 -> 1180 -> 1450)
const BOSS_BASE_HP := 300
const BOSS_HP_STEP := 0.60


## Trả về thông tin đầy đủ của 1 loại địch. id ví dụ: "bo_binh", "tieu_yeu", "boss".
## Có thể ghi "linh_sung@phap_1954" để lấy lính của 1 đạo quân cụ thể (trùm gọi quân nhà).
static func info(id: String, level: int) -> Dictionary:
	var ch := chapter(level)
	var d: Dictionary
	var army: String = ch.army
	if "@" in id:
		var parts := id.split("@")
		id = parts[0]
		army = parts[1]
	if id == "boss":
		var bid := boss_id(level)
		var is_mythic_boss: bool = MYTHIC_BOSSES.has(bid)
		var b: Dictionary = MYTHIC_BOSSES[bid] if is_mythic_boss else BOSSES[bid]
		var home := home_chapter(bid)
		var power := boss_index(level)
		d = b.duplicate()
		d["id"] = bid
		d["boss"] = true
		d["ai"] = "boss"
		d["radius"] = b.get("radius", 14.0)
		d["coins"] = 28 if is_mythic_boss else 16
		d["sheet"] = b.get("sheet", "enemies/boss_%s.png" % bid)
		d["size"] = b.get("size", Vector2i(48, 48))
		d["frames"] = b.get("frames", 7)
		d["army"] = home.army
		d["summon"] = "%s@%s" % [b.summon, home.army]
		d["power"] = power
		var boss_hp: int = int(b["hp"]) if is_mythic_boss else int(round(BOSS_BASE_HP * (1.0 + BOSS_HP_STEP * power)))
		var hp_mult: float = Global.difficulty_hp_mult()
		d["hp"] = boss_hp if is_equal_approx(hp_mult, 1.0) else maxi(1, int(round(float(boss_hp) * hp_mult)))
		var sz: Vector2i = d.size
		d["sheet2"] = b.get("sheet2", "enemies/boss_%s_2.png" % bid)
		d["size2"] = b.get("size2", Vector2i(sz.x * 2 + 16, sz.y * 2 + 18))
		d["radius2"] = b.get("radius2", d.radius * 1.6)
		return d
	if id.begins_with("legend:"):
		var lid := id.substr(7)
		d = LEGENDS[lid].duplicate()
		var lp := boss_index(level)
		d["id"] = lid
		d["boss"] = true
		d["legend"] = true
		d["ai"] = "boss"
		d["coins"] = 18
		d["frames"] = 7
		d["sheet"] = "enemies/boss_%s.png" % lid
		d["sheet2"] = "enemies/boss_%s_2.png" % lid
		d["radius2"] = d.radius
		d["power"] = lp
		var leg_hp: int = int(round(LEGEND_BASE_HP * (1.0 + BOSS_HP_STEP * lp)))
		var hp_mult_l: float = Global.difficulty_hp_mult()
		d["hp"] = leg_hp if is_equal_approx(hp_mult_l, 1.0) else maxi(1, int(round(float(leg_hp) * hp_mult_l)))
		return d
	elif FOLK.has(id):
		d = FOLK[id].duplicate()
		d["id"] = id
	else:
		d = ARCHETYPES[id].duplicate()
		d["id"] = id
		d["army"] = army
		if not d.has("sheet"):
			d["sheet"] = "enemies/%s_%s.png" % [army, id]
			d["size"] = Vector2i(24, 26)
			d["frames"] = 8
		d["name"] = "%s (%s)" % [d.name, army_name(army)]
	# Chỉ số tăng đều theo từng màn & nhảy bậc rõ khi vào Chuyến Du Hành Thần Thoại (4-1+)
	var depth: float = float(maxi(level - 1, 0)) if level <= 15 else float(14 + maxi(level - 17, 0))
	var unit_hp: int = int(round(float(d.hp) * (1.0 + 0.16 * depth) * loop_mult(level)))
	var hp_mult_u: float = Global.difficulty_hp_mult()
	d["hp"] = unit_hp if is_equal_approx(hp_mult_u, 1.0) else maxi(1, int(round(float(unit_hp) * hp_mult_u)))
	return d


static func pool(level: int) -> Array:
	var ch := chapter(level)
	var stg := stage_in_chapter(level)
	var p: Array
	if is_mythic_level(level):
		if stage_chapter_num(level) == 6:
			p = ["bo_binh", "cung_thu", "khien_binh", "phap_su", "ky_binh", "xe_tang"]
		else:
			p = ["bo_binh", "cung_thu", "cung_thu", "khien_binh", "phap_su", "ky_binh"]
		# Yêu quái dày đặc hơn ở vùng Thần Thoại
		p.append(ch.folk.pick_random())
		p.append(ch.folk.pick_random())
		if stg >= 3:
			p.append(ch.folk.pick_random())
		return p
	if ch.get("modern", false):
		p = ["bo_binh", "bo_binh", "linh_sung", "linh_sung", "linh_sung", "phao_binh"]
		if ch.army != "phap_thuy":
			p += ["xa_thu", "xa_thu"]
		if ch.army == "phap_1954" and stg >= 3:
			p.append("xe_tang")
	else:
		p = ["bo_binh", "bo_binh", "bo_binh", "cung_thu", "cung_thu"]
		if stg >= 2:
			p += ["khien_binh", "phap_su"]
		if ch.army == "nguyen_mong":
			p += ["ky_binh", "ky_binh"]
	# yêu quái do tà thuật (hư cấu)
	p.append(ch.folk.pick_random())
	if stg >= 3:
		p.append(ch.folk.pick_random())
	return p
