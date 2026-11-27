extends RefCounted
## Dữ liệu Trang phục Anh Hùng (Hero Skins) cho toàn bộ 14 vị tướng v3.0.0.
## Mỗi tướng có trang phục "default" (miễn phí) và 2 trang phục mở khóa bằng xu.

const Heroes = preload("res://scripts/data/heroes.gd")

const DEFAULT_SKIN := "default"

const SKINS_BY_HERO: Dictionary = {
	"hai_ba_trung": [
		{
			"id": "default", "name": "Mê Linh Chu Sa",
			"desc": "Chiến bào hồng sen nguyên bản của Trưng Trắc – Trưng Nhị.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.72, 0.19, 0.35), "fx_color": Color(0.94, 0.72, 0.28),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Chiến Thần",
			"desc": "Giáp vàng ròng rực rỡ uy nghi ngày hội quân Mê Linh.",
			"cost": 300, "modulate": Color(1.12, 0.98, 0.72),
			"aura_color": Color(1.0, 0.84, 0.32), "fx_color": Color(1.0, 0.88, 0.38),
		},
		{
			"id": "huyet_hoa", "name": "Huyết Hỏa Phượng Hoàng",
			"desc": "Áo choàng đỏ thẫm rực lửa như cánh phượng tung bay.",
			"cost": 380, "modulate": Color(1.16, 0.80, 0.84),
			"aura_color": Color(1.0, 0.34, 0.42), "fx_color": Color(1.0, 0.48, 0.52),
		},
	],
	"ba_trieu": [
		{
			"id": "default", "name": "Hoàng Bào Núi Nưa",
			"desc": "Chiến bào vàng rực cưỡi voi trắng xông pha trận mạc.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.90, 0.72, 0.18), "fx_color": Color(0.75, 0.15, 0.15),
		},
		{
			"id": "bach_tuong", "name": "Bạch Tượng Thánh Giáp",
			"desc": "Giáp ngà voi trắng bạc tỏa ánh sáng thanh khiết.",
			"cost": 280, "modulate": Color(0.96, 1.02, 1.14),
			"aura_color": Color(0.86, 0.94, 1.0), "fx_color": Color(0.88, 0.96, 1.0),
		},
		{
			"id": "huyet_hoa", "name": "Huyết Hỏa Chiến Giáp",
			"desc": "Chiến giáp rực hồng lửa thiêu đốt mọi đội hình địch.",
			"cost": 360, "modulate": Color(1.14, 0.78, 0.74),
			"aura_color": Color(0.98, 0.32, 0.24), "fx_color": Color(1.0, 0.44, 0.26),
		},
	],
	"ngo_quyen": [
		{
			"id": "default", "name": "Thanh Long Bạch Đằng",
			"desc": "Chiến bào xanh biển sâu của vị anh hùng phá quân Nam Hán.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.20, 0.42, 0.72), "fx_color": Color(0.88, 0.72, 0.28),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Chiến Thần",
			"desc": "Long bào vương triều Ngô rực ánh hoàng kim Bạch Đằng.",
			"cost": 320, "modulate": Color(1.10, 0.98, 0.74),
			"aura_color": Color(0.98, 0.82, 0.30), "fx_color": Color(1.0, 0.86, 0.34),
		},
		{
			"id": "ngoc_bich", "name": "Ngọc Bích Thủy Triều",
			"desc": "Áo giáp lam ngọc lấp lánh ánh sóng thủy triều dâng.",
			"cost": 380, "modulate": Color(0.76, 1.08, 1.04),
			"aura_color": Color(0.26, 0.92, 0.86), "fx_color": Color(0.36, 0.96, 0.90),
		},
	],
	"ly_thuong_kiet": [
		{
			"id": "default", "name": "Phòng Tuyến Như Nguyệt",
			"desc": "Giáp bạc thanh tao của Thái úy viết bài thơ thần bất hủ.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.23, 0.42, 0.66), "fx_color": Color(0.85, 0.87, 0.93),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Thái Úy",
			"desc": "Giáp vàng khảm chữ thần tỏa hào quang Nam Quốc Sơn Hà.",
			"cost": 300, "modulate": Color(1.12, 0.96, 0.74),
			"aura_color": Color(1.0, 0.84, 0.34), "fx_color": Color(1.0, 0.86, 0.40),
		},
		{
			"id": "huyen_vu", "name": "Huyền Vũ Bạch Y",
			"desc": "Áo giáp tím huyền sương đêm bên bờ sông Như Nguyệt.",
			"cost": 380, "modulate": Color(0.86, 0.88, 1.16),
			"aura_color": Color(0.56, 0.66, 1.0), "fx_color": Color(0.64, 0.78, 1.0),
		},
	],
	"tran_hung_dao": [
		{
			"id": "default", "name": "Hào Khí Đông A",
			"desc": "Triều phục đỏ thẫm oai phong ba lần đánh tan quân Nguyên.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.70, 0.16, 0.16), "fx_color": Color(0.15, 0.12, 0.12),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Quốc Công",
			"desc": "Chiến bào vàng ròng khắc hai chữ Sát Thát rực rỡ.",
			"cost": 340, "modulate": Color(1.14, 0.96, 0.72),
			"aura_color": Color(1.0, 0.80, 0.28), "fx_color": Color(1.0, 0.84, 0.34),
		},
		{
			"id": "huyen_vu", "name": "Huyền Vũ Vạn Kiếp",
			"desc": "Áo giáp đen tím uy nghiêm trấn giữ ải Vạn Kiếp.",
			"cost": 400, "modulate": Color(0.84, 0.82, 1.12),
			"aura_color": Color(0.72, 0.42, 0.96), "fx_color": Color(0.82, 0.54, 1.0),
		},
	],
	"le_loi": [
		{
			"id": "default", "name": "Áo Vải Lam Sơn",
			"desc": "Chiến bào xanh rừng Lam Sơn mang gươm thần Thuận Thiên.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.23, 0.48, 0.29), "fx_color": Color(0.94, 0.72, 0.28),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Thái Tổ",
			"desc": "Hoàng bào đăng quang Thăng Long rực ánh gươm vàng.",
			"cost": 320, "modulate": Color(1.12, 0.98, 0.72),
			"aura_color": Color(1.0, 0.84, 0.30), "fx_color": Color(1.0, 0.88, 0.36),
		},
		{
			"id": "ngoc_bich", "name": "Ngọc Bích Hoàn Kiếm",
			"desc": "Sắc ngọc lục bảo huyền ảo của hồ Lục Thủy trả gươm.",
			"cost": 380, "modulate": Color(0.76, 1.12, 0.94),
			"aura_color": Color(0.28, 0.94, 0.68), "fx_color": Color(0.38, 0.98, 0.74),
		},
	],
	"quang_trung": [
		{
			"id": "default", "name": "Áo Vải Cờ Đào",
			"desc": "Chiến bào xanh thẫm cờ đào Tây Sơn hành quân thần tốc.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.16, 0.20, 0.36), "fx_color": Color(0.85, 0.15, 0.12),
		},
		{
			"id": "huyet_hoa", "name": "Huyết Hỏa Ngọc Hồi",
			"desc": "Chiến bào đỏ rực ánh lửa đại phá đồn Ngọc Hồi – Đống Đa.",
			"cost": 340, "modulate": Color(1.16, 0.80, 0.76),
			"aura_color": Color(1.0, 0.36, 0.20), "fx_color": Color(1.0, 0.44, 0.24),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Bắc Bình",
			"desc": "Long bào vàng ròng uy phong của vị hoàng đế bách thắng.",
			"cost": 400, "modulate": Color(1.14, 0.98, 0.74),
			"aura_color": Color(1.0, 0.82, 0.28), "fx_color": Color(1.0, 0.86, 0.36),
		},
	],
	"nguyen_trung_truc": [
		{
			"id": "default", "name": "Anh Hùng Nhật Tảo",
			"desc": "Bà ba trắng khăn rằn đỏ hiên ngang đốt cháy tàu Esperance.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.91, 0.89, 0.94), "fx_color": Color(0.85, 0.24, 0.24),
		},
		{
			"id": "huyet_hoa", "name": "Huyết Hỏa Hỏa Công",
			"desc": "Áo choàng đỏ rực lửa cháy sáng rực vàm Nhật Tảo.",
			"cost": 300, "modulate": Color(1.16, 0.80, 0.74),
			"aura_color": Color(1.0, 0.42, 0.18), "fx_color": Color(1.0, 0.48, 0.22),
		},
		{
			"id": "huyen_vu", "name": "Huyền Vũ Rạch Giá",
			"desc": "Áo đen khăn thẫm hành động bí mật trong đêm sương.",
			"cost": 360, "modulate": Color(0.82, 0.88, 1.12),
			"aura_color": Color(0.36, 0.76, 0.96), "fx_color": Color(0.46, 0.84, 1.0),
		},
	],
	"hoang_hoa_tham": [
		{
			"id": "default", "name": "Hùm Thiêng Yên Thế",
			"desc": "Áo nâu sờn núi rừng Yên Thế uy dũng bất khuất.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.54, 0.35, 0.23), "fx_color": Color(0.91, 0.69, 0.29),
		},
		{
			"id": "ngoc_bich", "name": "Ngọc Bích Đại Ngàn",
			"desc": "Trang phục ngụy trang xanh thẫm hòa cùng rừng già Yên Thế.",
			"cost": 280, "modulate": Color(0.80, 1.08, 0.86),
			"aura_color": Color(0.34, 0.88, 0.50), "fx_color": Color(0.42, 0.94, 0.58),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Mãnh Hổ",
			"desc": "Chiến phục vàng hổ phách tỏa uy mãnh hổ gầm vang.",
			"cost": 380, "modulate": Color(1.14, 0.96, 0.72),
			"aura_color": Color(1.0, 0.74, 0.24), "fx_color": Color(1.0, 0.80, 0.30),
		},
	],
	"chien_si_dien_bien": [
		{
			"id": "default", "name": "Mũ Nan Điện Biên",
			"desc": "Quân phục xanh lá truyền thống với mũ nan lưới ngụy trang.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.35, 0.48, 0.23), "fx_color": Color(0.55, 0.42, 0.24),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Quyết Thắng",
			"desc": "Quân phục rực ánh cờ đỏ sao vàng tung bay trên nóc hầm.",
			"cost": 300, "modulate": Color(1.12, 0.98, 0.74),
			"aura_color": Color(1.0, 0.82, 0.26), "fx_color": Color(1.0, 0.84, 0.32),
		},
		{
			"id": "huyen_vu", "name": "Huyền Vũ Đêm Mường Thanh",
			"desc": "Trang phục hành quân đêm khói lửa chiến dịch Mường Thanh.",
			"cost": 360, "modulate": Color(0.84, 0.92, 1.12),
			"aura_color": Color(0.96, 0.54, 0.26), "fx_color": Color(1.0, 0.62, 0.32),
		},
	],
	"thanh_giong": [
		{
			"id": "default", "name": "Thiết Giáp Phù Đổng",
			"desc": "Giáp sắt Phù Đổng cưỡi ngựa sắt phun lửa thiêu giặc Ân.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.76, 0.24, 0.20), "fx_color": Color(1.0, 0.78, 0.28),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Thiên Vương",
			"desc": "Thần giáp vàng ròng rực sáng đỉnh Sóc Sơn bay về trời.",
			"cost": 350, "modulate": Color(1.15, 0.98, 0.70),
			"aura_color": Color(1.0, 0.86, 0.32), "fx_color": Color(1.0, 0.90, 0.38),
		},
		{
			"id": "huyet_hoa", "name": "Huyết Hỏa Thần Mã",
			"desc": "Ngọn lửa hồng rực cháy từ thiết giáp bất khả chiến bại.",
			"cost": 450, "modulate": Color(1.16, 0.78, 0.72),
			"aura_color": Color(1.0, 0.36, 0.20), "fx_color": Color(1.0, 0.44, 0.22),
		},
	],
	"an_duong_vuong": [
		{
			"id": "default", "name": "Vương Bào Cổ Loa",
			"desc": "Hoàng bào đồng vàng Cổ Loa cùng Nỏ Thần Kim Quy linh thiêng.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.86, 0.62, 0.22), "fx_color": Color(0.35, 0.90, 0.85),
		},
		{
			"id": "ngoc_bich", "name": "Ngọc Bích Kim Quy",
			"desc": "Áo giáp ánh ngọc bích tỏa hào quang thần Kim Quy.",
			"cost": 340, "modulate": Color(0.78, 1.12, 1.06),
			"aura_color": Color(0.32, 0.96, 0.88), "fx_color": Color(0.42, 1.0, 0.94),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Loa Thành",
			"desc": "Chiến bào vàng ròng vương triều Âu Lạc tối thượng.",
			"cost": 420, "modulate": Color(1.15, 0.98, 0.72),
			"aura_color": Color(1.0, 0.84, 0.30), "fx_color": Color(1.0, 0.88, 0.36),
		},
	],
	"lac_long_quan": [
		{
			"id": "default", "name": "Thủy Tổ Biển Đông",
			"desc": "Long bào lam hải uy nghiêm của Quốc Tổ Bách Việt.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.20, 0.65, 0.92), "fx_color": Color(0.98, 0.84, 0.36),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Long Vương",
			"desc": "Kim long bảo giáp rực sáng vầng hào quang Lạc Hồng.",
			"cost": 350, "modulate": Color(1.14, 0.98, 0.74),
			"aura_color": Color(1.0, 0.86, 0.32), "fx_color": Color(1.0, 0.90, 0.40),
		},
		{
			"id": "ngoc_bich", "name": "Ngọc Bích Thủy Cung",
			"desc": "Vảy rồng ngọc lục bảo óng ánh dưới đáy Biển Đông.",
			"cost": 450, "modulate": Color(0.76, 1.12, 1.08),
			"aura_color": Color(0.26, 0.94, 0.86), "fx_color": Color(0.38, 0.98, 0.94),
		},
	],
	"son_tinh": [
		{
			"id": "default", "name": "Tản Viên Sơn Thánh",
			"desc": "Thạch giáp rêu xanh vững chãi như ngọn Tản Viên sừng sững.",
			"cost": 0, "modulate": Color.WHITE,
			"aura_color": Color(0.45, 0.68, 0.34), "fx_color": Color(0.90, 0.66, 0.32),
		},
		{
			"id": "hoang_kim", "name": "Hoàng Kim Sơn Thần",
			"desc": "Chiến giáp hổ phách hoàng kim tỏa ánh mặt trời trên đỉnh núi.",
			"cost": 340, "modulate": Color(1.14, 0.96, 0.72),
			"aura_color": Color(1.0, 0.80, 0.30), "fx_color": Color(1.0, 0.84, 0.36),
		},
		{
			"id": "huyen_vu", "name": "Huyền Vũ Bàn Thạch",
			"desc": "Giáp đá đen tím kiên cố bất động trước muôn đợt sóng dữ.",
			"cost": 420, "modulate": Color(0.84, 0.88, 1.12),
			"aura_color": Color(0.62, 0.56, 0.96), "fx_color": Color(0.74, 0.68, 1.0),
		},
	],
}


static func skins_for(hero_id: String) -> Array:
	var list: Variant = SKINS_BY_HERO.get(hero_id, [])
	if list is Array and not (list as Array).is_empty():
		var out: Array = []
		for item in (list as Array):
			if item is Dictionary:
				out.append((item as Dictionary).duplicate(true))
		return out
	var h: Dictionary = Heroes.DATA.get(hero_id, {})
	var c1: Color = h.get("color", Color.WHITE)
	var c2: Color = h.get("accent", Color(1.0, 0.84, 0.34))
	return [{
		"id": DEFAULT_SKIN, "name": "Mặc Định",
		"desc": "Trang phục nguyên bản của anh hùng.",
		"cost": 0, "modulate": Color.WHITE,
		"aura_color": c1, "fx_color": c2,
	}]


static func get_skin(hero_id: String, skin_id: String) -> Dictionary:
	var list: Array = skins_for(hero_id)
	for s in list:
		if str((s as Dictionary).get("id", "")) == skin_id:
			return (s as Dictionary).duplicate(true)
	return (list[0] as Dictionary).duplicate(true)


static func next_skin_id(hero_id: String, current_skin_id: String) -> String:
	var list: Array = skins_for(hero_id)
	if list.is_empty():
		return DEFAULT_SKIN
	for i in list.size():
		if str((list[i] as Dictionary).get("id", "")) == current_skin_id:
			var nxt: Dictionary = list[(i + 1) % list.size()]
			return str(nxt.get("id", DEFAULT_SKIN))
	return str((list[0] as Dictionary).get("id", DEFAULT_SKIN))
