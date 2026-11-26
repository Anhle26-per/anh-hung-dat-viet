extends RefCounted
## Dữ liệu mở rộng tướng v2.0.0: Nội tại (11 tướng), Kỹ năng 2 (11 tướng) và 5 Tượng Thần Việt.

const PASSIVES := {
	"hai_ba_trung": {
		"name": "Uy danh Mê Linh",
		"desc": "Đòn kiếm tạo dư ảnh gây thêm sát thương, đồng đội/phân thân đánh nhanh +15%.",
	},
	"ba_trieu": {
		"name": "Thiết giáp cự tượng",
		"desc": "Miễn nhiễm đẩy lùi; khi giáp đầy nhận -1 sát thương (tối thiểu 1).",
	},
	"ngo_quyen": {
		"name": "Thủy triều Bạch Đằng",
		"desc": "Di chuyển qua vùng nước không bị chậm; cọc và bẫy phe ta bền +40%.",
	},
	"ly_thuong_kiet": {
		"name": "Thơ thần hộ quốc",
		"desc": "Hạ 6 giặc hồi 1 giáp; đạn phản xạ tăng +25% tốc độ và sát thương.",
	},
	"tran_hung_dao": {
		"name": "Hào khí Đông A",
		"desc": "Gây sát thương gần đồng minh hoặc cờ hiệu tăng +15% tỉ lệ chí mạng.",
	},
	"le_loi": {
		"name": "Ánh gươm Thuận Thiên",
		"desc": "Đòn cận chiến tầm xa hơn +18% và có 20% phóng sóng kiếm nhỏ.",
	},
	"quang_trung": {
		"name": "Hành quân thần tốc",
		"desc": "+10% tốc chạy cơ bản; sau khi lướt né, phát bắn kế +30% sát thương.",
	},
	"nguyen_trung_truc": {
		"name": "Lửa thiêu Nhật Tảo",
		"desc": "Miễn nhiễm cháy nổ bản thân; đòn đánh lên giặc đang cháy gây +25% sát thương.",
	},
	"hoang_hoa_tham": {
		"name": "Bóng rừng Yên Thế",
		"desc": "Đứng trong bụi rậm tăng +25% chí mạng và +15% né đòn.",
	},
	"chien_si_dien_bien": {
		"name": "Quyết chiến Điện Biên",
		"desc": "Giảm 15% sát thương nổ nhận vào; vũ khí thuốc nổ/hỏa lực mạnh hơn +20%.",
	},
	"thanh_giong": {
		"name": "Sức mạnh Phù Đổng",
		"desc": "Mỗi 10 giặc hạ được tăng vĩnh viễn +1 máu tối đa trong lượt (tối đa +3).",
	},
}

const SKILLS_2 := {
	"hai_ba_trung": {
		"skill": "co_lenh_me_linh",
		"skill_name": "Cờ lệnh Mê Linh",
		"skill_desc": "Phất cờ khởi nghĩa gọi 2 kỵ binh nữ tướng cùng hào quang tăng +35% tốc đánh trong 7 giây.",
		"skill_cd": 13.0,
		"synergy_desc": "★ Hào quang +45% tốc đánh  |  ★★ Gọi 3 kỵ binh + sóng cờ xuyên phá",
	},
	"ba_trieu": {
		"skill": "chieng_nui_nua",
		"skill_name": "Chiêng núi Nưa",
		"skill_desc": "Đánh chiêng đồng chấn động 360°, làm choáng giặc xung quanh 1,8 giây và xóa đạn địch.",
		"skill_cd": 11.0,
		"synergy_desc": "★ Bán kính +30%, hồi 1 giáp  |  ★★ Dư chấn 2 nhịp + phản ngược đạn địch",
	},
	"ngo_quyen": {
		"skill": "thuy_trieu_dang",
		"skill_name": "Thủy triều dâng",
		"skill_desc": "Gọi 3 đợt sóng lớn Bạch Đằng quét về phía trước, đẩy lùi và làm chậm giặc 45% trong 3 giây.",
		"skill_cd": 12.0,
		"synergy_desc": "★ Sóng rộng +25%  |  ★★ Kèm cọc ngầm dưới sóng gây sát thương kép",
	},
	"ly_thuong_kiet": {
		"skill": "tuong_nhu_nguyet",
		"skill_name": "Tường Như Nguyệt",
		"skill_desc": "Dựng 3 chiến lũy tre chắn đạn địch phía trước và phóng tên phản công suốt 6 giây.",
		"skill_cd": 13.0,
		"synergy_desc": "★ 4 chiến lũy bền +40%  |  ★★ Chiến lũy tự bắn tên thần mỗi 0,8 giây",
	},
	"tran_hung_dao": {
		"skill": "hoa_cong_bach_dang",
		"skill_name": "Hỏa công Bạch Đằng",
		"skill_desc": "Phóng 5 bè hỏa thuyền lao tới phát nổ tạo biển lửa thiêu rụi đội hình giặc.",
		"skill_cd": 13.5,
		"synergy_desc": "★ 7 bè lửa  |  ★★ Vùng cháy kéo dài +50%, gây cháy lan",
	},
	"le_loi": {
		"skill": "kim_quy_ho_gia",
		"skill_name": "Kim Quy hộ giá",
		"skill_desc": "Triệu hồi mai rùa vàng bất tử trong 3,5 giây và hất văng đạn giặc thành tia vàng.",
		"skill_cd": 14.0,
		"synergy_desc": "★ Hộ giá 4,5 giây  |  ★★ Hết giờ nổ sóng vàng + hồi 2 giáp",
	},
	"quang_trung": {
		"skill": "hoa_ho_dai_phao",
		"skill_name": "Hỏa hổ đại pháo",
		"skill_desc": "Khai hỏa liên hoàn 3 phát Hỏa Hổ khổng lồ xuyên phá và để lại vệt lửa rực cháy.",
		"skill_cd": 12.5,
		"synergy_desc": "★ 4 phát đại pháo  |  ★★ Đạn tách 3 mảnh lửa khi va chạm",
	},
	"nguyen_trung_truc": {
		"skill": "nhat_tao_xung_kich",
		"skill_name": "Nhật Tảo xung kích",
		"skill_desc": "Lướt xuyên hàng giặc mang theo ngọn lửa anh hùng, để lại vệt cháy nổ liên hoàn.",
		"skill_cd": 10.0,
		"synergy_desc": "★ Hồi 20 năng lượng mỗi giặc trúng  |  ★★ Nổ lớn cuối đường lướt ×2 sát thương",
	},
	"hoang_hoa_tham": {
		"skill": "phuc_kich_yen_the",
		"skill_name": "Phục kích Yên Thế",
		"skill_desc": "Tàng hình 3 giây (+50% tốc chạy), phát đánh đầu tiên phá ẩn thân chắc chắn CHÍ MẠNG ×2,5.",
		"skill_cd": 12.0,
		"synergy_desc": "★ Tàng hình 4s, gọi bẫy chông  |  ★★ Phá ẩn thân phóng loạt 5 phát đạn xuyên",
	},
	"chien_si_dien_bien": {
		"skill": "boc_pha_nghin_can",
		"skill_name": "Bộc phá nghìn cân",
		"skill_desc": "Đặt khối thuốc nổ hẹn giờ cực mạnh gây chấn động hủy diệt hầm hào sau 1,2 giây.",
		"skill_cd": 14.0,
		"synergy_desc": "★ Bán kính nổ +35%  |  ★★ Dư chấn làm choáng 2s + để lại hố lửa",
	},
	"thanh_giong": {
		"skill": "nho_tre_danh_giac",
		"skill_name": "Nhổ tre đánh giặc",
		"skill_desc": "Nhổ bụi tre ngà khổng lồ quét 360° cực mạnh, đánh văng giặc và thổi bay mọi đạn địch.",
		"skill_cd": 11.0,
		"synergy_desc": "★ Quét 2 vòng liên tiếp  |  ★★ Gọi thiên lôi giáng xuống mỗi giặc trúng đòn",
	},
}

const STATUE_ORDER: Array = ["lac_long", "au_co", "son_tinh", "chu_dong_tu", "phu_dong"]

const STATUES := {
	"lac_long": {
		"name": "Tượng Lạc Long Quân",
		"desc": "Khi tung chiêu: phóng 6 làn sóng thủy long tỏa tròn gây sát thương và đẩy lùi giặc.",
		"cost": 25,
		"cd": 8.0,
		"color": Color(0.24, 0.72, 0.96),
	},
	"au_co": {
		"name": "Tượng Âu Cơ",
		"desc": "Khi tung chiêu: tỏa lông tiên hồi 1 giáp, +20 năng lượng và xóa đạn gần thân.",
		"cost": 28,
		"cd": 10.0,
		"color": Color(1.0, 0.56, 0.72),
	},
	"son_tinh": {
		"name": "Tượng Sơn Tinh",
		"desc": "Khi tung chiêu: gọi chấn địa trụ đá húc tung và làm choáng giặc xung quanh.",
		"cost": 26,
		"cd": 8.5,
		"color": Color(0.72, 0.56, 0.34),
	},
	"chu_dong_tu": {
		"name": "Tượng Chử Đồng Tử",
		"desc": "Khi tung chiêu: ban hào quang vàng +25% tốc chạy, +15% chí mạng trong 4s và rớt xu.",
		"cost": 24,
		"cd": 7.5,
		"color": Color(0.98, 0.82, 0.30),
	},
	"phu_dong": {
		"name": "Tượng Phù Đổng",
		"desc": "Khi tung chiêu: giáng lôi hỏa Phù Đổng lên giặc gần nhất và tăng +25% tốc đánh 3,5s.",
		"cost": 30,
		"cd": 9.0,
		"color": Color(0.96, 0.36, 0.24),
	},
}


static func get_passive(hid: String) -> Dictionary:
	var d: Variant = PASSIVES.get(hid, {})
	return (d as Dictionary).duplicate() if d is Dictionary else {}


static func get_skill2(hid: String) -> Dictionary:
	var d: Variant = SKILLS_2.get(hid, {})
	return (d as Dictionary).duplicate() if d is Dictionary else {}


static func get_statue(sid: String) -> Dictionary:
	var d: Variant = STATUES.get(sid, {})
	return (d as Dictionary).duplicate() if d is Dictionary else {}
