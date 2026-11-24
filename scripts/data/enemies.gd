extends RefCounted
## Kẻ địch và 10 chương lịch sử (năm 40 đến năm 1954).
## Dựa trên các cuộc kháng chiến có thật, thêm hư cấu cho kịch tính:
## pháp sư của giặc dùng tà thuật gọi yêu quái dân gian ra trợ chiến.

# Loại lính (hình: enemies/<quân>_<loại>.png)
const ARCHETYPES := {
	# thời phong kiến
	"bo_binh": {"name": "Bộ binh", "hp": 8, "speed": 66.0, "radius": 7.0, "ai": "chase", "coins": 1},
	"cung_thu": {"name": "Cung thủ", "hp": 6, "speed": 56.0, "radius": 7.0, "ai": "shoot", "shoot_cd": 1.7, "coins": 1},
	"khien_binh": {"name": "Khiên binh", "hp": 18, "speed": 36.0, "radius": 8.0, "ai": "tank", "coins": 2},
	"phap_su": {"name": "Pháp sư", "hp": 10, "speed": 44.0, "radius": 7.0, "ai": "caster", "shoot_cd": 2.8, "coins": 2},
	"ky_binh": {"name": "Kỵ binh", "hp": 14, "speed": 70.0, "radius": 10.0, "ai": "charge", "coins": 2,
		"sheet": "enemies/nguyen_mong_ky_binh.png", "size": Vector2i(34, 30)},
	# thời cận đại
	"linh_sung": {"name": "Lính súng trường", "hp": 8, "speed": 54.0, "radius": 7.0, "ai": "rifle", "shoot_cd": 1.5, "coins": 1},
	"xa_thu": {"name": "Xạ thủ súng máy", "hp": 12, "speed": 40.0, "radius": 7.0, "ai": "mg", "shoot_cd": 2.6, "coins": 2},
	"phao_binh": {"name": "Pháo cối", "hp": 9, "speed": 38.0, "radius": 7.0, "ai": "mortar", "shoot_cd": 3.2, "coins": 2},
	"xe_tang": {"name": "Xe tăng", "hp": 70, "speed": 26.0, "radius": 14.0, "ai": "tank_elite", "shoot_cd": 2.4, "coins": 6,
		"sheet": "enemies/xe_tang.png", "size": Vector2i(40, 30)},
}

# Yêu quái do tà thuật gọi ra
const FOLK := {
	"tieu_yeu": {"name": "Tiểu yêu", "hp": 6, "speed": 74.0, "radius": 7.0, "ai": "chase", "coins": 1,
		"sheet": "enemies/tieu_yeu.png", "size": Vector2i(16, 17)},
	"ho_tinh": {"name": "Hồ tinh", "hp": 6, "speed": 60.0, "radius": 7.0, "ai": "shoot", "shoot_cd": 1.6, "coins": 1,
		"sheet": "enemies/ho_tinh.png", "size": Vector2i(22, 16), "proj": "orb_pink"},
	"moc_tinh": {"name": "Mộc tinh", "hp": 18, "speed": 26.0, "radius": 10.0, "ai": "ring", "shoot_cd": 2.8, "coins": 2,
		"sheet": "enemies/moc_tinh.png", "size": Vector2i(26, 28)},
	"chan_tinh": {"name": "Chằn tinh", "hp": 34, "speed": 34.0, "radius": 11.0, "ai": "slam", "shoot_cd": 3.5, "coins": 3,
		"sheet": "enemies/chan_tinh.png", "size": Vector2i(30, 32)},
	"dai_bang": {"name": "Đại bàng tinh", "hp": 10, "speed": 80.0, "radius": 9.0, "ai": "charge", "coins": 2,
		"sheet": "enemies/dai_bang.png", "size": Vector2i(36, 26)},
	"ma_troi": {"name": "Ma trơi", "hp": 3, "speed": 62.0, "radius": 6.0, "ai": "kamikaze", "coins": 1,
		"sheet": "enemies/ma_troi.png", "size": Vector2i(14, 18)},
	"ngu_tinh": {"name": "Thủy quái Ngư Tinh", "hp": 120, "speed": 45.0, "radius": 18.0, "ai": "ngu", "coins": 6,
		"sheet": "enemies/ngu_tinh.png", "size": Vector2i(60, 46), "frames": 6},
}

# Trùm: mỗi chương một kẻ cầm đầu từng bị đánh bại
const BOSSES := {
	"to_dinh": {"name": "Tô Định", "title": "Thái thú Giao Chỉ", "hp": 260, "speed": 50.0,
		"patterns": ["sweep", "ring", "charge", "summon"], "summon": "bo_binh", "special": "tron_chay", "patterns2": ["ring", "charge", "spiral", "summon"], "form2": "Quỷ Tham Tàn"},
	"luc_dan": {"name": "Lục Dận", "title": "Tướng nhà Đông Ngô", "hp": 300, "speed": 50.0,
		"patterns": ["sweep", "charge", "ring", "summon"], "summon": "bo_binh", "special": "tran_khien", "patterns2": ["sweep", "fan", "charge", "ring"], "form2": "Quỷ Gai Đông Ngô"},
	"hoang_thao": {"name": "Hoằng Tháo", "title": "Thái tử Nam Hán", "hp": 340, "speed": 48.0,
		"patterns": ["spiral", "volley", "ring", "summon"], "summon": "cung_thu", "special": "thuy_quai", "patterns2": ["spiral", "fan", "ring", "volley"], "form2": "Thủy Quỷ Nam Hán"},
	"quach_quy": {"name": "Quách Quỳ", "title": "Tướng nhà Tống", "hp": 360, "speed": 48.0,
		"patterns": ["volley", "sweep", "ring", "summon"], "summon": "khien_binh", "special": "mua_ten", "patterns2": ["volley", "spiral", "sweep", "fan"], "form2": "Ưng Quỷ Tống Triều"},
	"thoat_hoan": {"name": "Thoát Hoan", "title": "Trấn Nam Vương nhà Nguyên", "hp": 380, "speed": 52.0,
		"patterns": ["volley", "charge", "sweep", "summon"], "summon": "ky_binh", "special": "ong_dong", "patterns2": ["charge", "volley", "ring", "charge"], "form2": "Lang Quỷ Thảo Nguyên"},
	"lieu_thang": {"name": "Liễu Thăng", "title": "Tổng binh nhà Minh", "hp": 400, "speed": 54.0,
		"patterns": ["charge", "sweep", "volley", "summon"], "summon": "bo_binh", "special": "sa_lay", "patterns2": ["charge", "fan", "spiral", "sweep"], "form2": "Quỷ Rừng Sa Lầy"},
	"ton_si_nghi": {"name": "Tôn Sĩ Nghị", "title": "Tổng đốc Lưỡng Quảng", "hp": 420, "speed": 46.0,
		"patterns": ["cannon", "fan", "ring", "summon"], "summon": "phap_su", "special": "bo_chay", "patterns2": ["cannon", "spiral", "fan", "ring"], "form2": "Ngưu Quỷ Lưỡng Quảng"},
	"tau_hy_vong": {"name": "Tàu chiến Hy Vọng", "title": "Chiến thuyền thủy quân Pháp", "hp": 460, "speed": 30.0,
		"patterns": ["broadside", "cannon", "ring", "summon"], "summon": "linh_sung", "special": "boc_chay", "patterns2": ["broadside", "spiral", "cannon", "ring"], "form2": "Tàu Ma Lửa Xanh",
		"sheet": "enemies/boss_tau_hy_vong.png", "size": Vector2i(64, 44), "frames": 7, "radius": 20.0},
	"don_truong": {"name": "Đồn trưởng Nhã Nam", "title": "Chỉ huy quân viễn chinh", "hp": 480, "speed": 50.0,
		"patterns": ["burst", "mortar", "sweep", "summon"], "summon": "xa_thu", "special": "phao_kich", "patterns2": ["burst", "mortar", "spiral", "fan"], "form2": "Quỷ Gai Đồn Bốt"},
	"do_cat": {"name": "Đờ Cát", "title": "Chỉ huy tập đoàn cứ điểm Điện Biên Phủ", "hp": 520, "speed": 46.0,
		"patterns": ["burst", "mortar", "cannon", "summon"], "summon": "xe_tang", "special": "ham_chi_huy", "patterns2": ["burst", "mortar", "spiral", "cannon"], "form2": "Ngưu Quỷ Hầm Ngầm"},
}


## Tam Yêu trong truyền thuyết Lạc Long Quân: trùm giữa chương (màn 2 của chương, ngẫu nhiên).
## Mỗi yêu có hình thường và hình "hiện nguyên hình" khi còn nửa máu.
const LEGENDS := {
	"ho_tinh_vuong": {"name": "Hồ Tinh", "title": "Cáo chín đuôi đầm Xác Cáo", "speed": 72.0, "radius": 15.0,
		"patterns": ["tails", "clone", "sweep", "charge"], "patterns2": ["tails", "clone", "spiral", "charge"],
		"summon": "ho_tinh", "special": "cuu_vi", "form2": "Cửu Vĩ Hồ Ly",
		"size": Vector2i(84, 60), "size2": Vector2i(84, 60)},
	"moc_tinh_vuong": {"name": "Mộc Tinh", "title": "Cây chiên đàn nghìn năm", "speed": 24.0, "radius": 18.0,
		"patterns": ["roots", "ring", "summon", "fan"], "patterns2": ["roots", "ring", "spiral", "roots"],
		"summon": "moc_tinh", "special": "rung_gia", "form2": "Mộc Tinh Lửa Đỏ",
		"size": Vector2i(72, 72), "size2": Vector2i(72, 72)},
	"ngu_tinh_vuong": {"name": "Ngư Tinh", "title": "Thủy quái Biển Đông", "speed": 46.0, "radius": 18.0,
		"patterns": ["dive", "spiral", "fan", "summon"], "patterns2": ["dive", "tidal", "spiral", "fan"],
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


static func chapter_index(level: int) -> int:
	return int((level - 1) / 3) % CHAPTERS.size()


static func chapter(level: int) -> Dictionary:
	return CHAPTERS[chapter_index(level)]


## Vòng lặp: sau chương cuối quay lại chương 1 nhưng giặc mạnh hơn
static func loop_mult(level: int) -> float:
	return 1.0 + float(int((level - 1) / (3 * CHAPTERS.size()))) * 0.6


## Trùm thứ mấy của lượt chơi (0, 1, 2...): mỗi 3 màn gặp 1 trùm
static func boss_index(level: int) -> int:
	return int((level - 1) / 3)


## Mã trùm ở màn này: ngẫu nhiên theo lượt chơi (xem Global.boss_at)
static func boss_id(level: int) -> String:
	return Global.boss_at(boss_index(level))


## Chương gốc (đạo quân) của 1 trùm, để trùm gọi đúng lính của mình
static func home_chapter(boss: String) -> Dictionary:
	for ch in CHAPTERS:
		if ch.boss == boss:
			return ch
	return CHAPTERS[0]


static func army_name(army: String) -> String:
	for ch in CHAPTERS:
		if ch.army == army:
			return ch.army_name
	return ""


## Máu trùm chỉ phụ thuộc thứ tự gặp, không phụ thuộc trùm nào:
## trùm thứ 1: 300, thứ 2: 426, ... thứ 10: 1434 (đi vòng 2 tiếp tục tăng).
const BOSS_BASE_HP := 300
const BOSS_HP_STEP := 0.42


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
		var b: Dictionary = BOSSES[bid]
		var home := home_chapter(bid)
		var power := boss_index(level)
		d = b.duplicate()
		d["id"] = bid
		d["boss"] = true
		d["ai"] = "boss"
		d["radius"] = b.get("radius", 14.0)
		d["coins"] = 30
		d["sheet"] = b.get("sheet", "enemies/boss_%s.png" % bid)
		d["size"] = b.get("size", Vector2i(48, 48))
		d["frames"] = b.get("frames", 7)
		d["army"] = home.army
		d["summon"] = "%s@%s" % [b.summon, home.army]
		d["power"] = power
		var boss_hp: int = int(round(BOSS_BASE_HP * (1.0 + BOSS_HP_STEP * power)))
		var hp_mult: float = Global.difficulty_hp_mult()
		d["hp"] = boss_hp if is_equal_approx(hp_mult, 1.0) else maxi(1, int(round(float(boss_hp) * hp_mult)))
		# hình ma tướng: phóng to gấp đôi + chừa chỗ cho sừng và hào quang
		var sz: Vector2i = d.size
		d["sheet2"] = "enemies/boss_%s_2.png" % bid
		d["size2"] = Vector2i(sz.x * 2 + 16, sz.y * 2 + 18)
		d["radius2"] = d.radius * 1.6
		return d
	if id.begins_with("legend:"):
		var lid := id.substr(7)
		d = LEGENDS[lid].duplicate()
		var lp := boss_index(level)
		d["id"] = lid
		d["boss"] = true
		d["legend"] = true
		d["ai"] = "boss"
		d["coins"] = 30
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
			d["frames"] = 5
		d["name"] = "%s (%s)" % [d.name, army_name(army)]
	# chỉ số tăng theo chương (độ khó) và theo màn
	var depth := float((level - 1) % (3 * CHAPTERS.size()))
	var unit_hp: int = int(float(d.hp) * (1.0 + 0.12 * depth) * loop_mult(level))
	var hp_mult_u: float = Global.difficulty_hp_mult()
	d["hp"] = unit_hp if is_equal_approx(hp_mult_u, 1.0) else maxi(1, int(round(float(unit_hp) * hp_mult_u)))
	return d


static func pool(level: int) -> Array:
	var ch := chapter(level)
	var p: Array
	if ch.get("modern", false):
		p = ["bo_binh", "bo_binh", "linh_sung", "linh_sung", "linh_sung", "phao_binh"]
		if ch.army != "phap_thuy":
			p += ["xa_thu", "xa_thu"]
		if ch.army == "phap_1954" and level % 3 != 1:
			p.append("xe_tang")
	else:
		p = ["bo_binh", "bo_binh", "bo_binh", "cung_thu", "cung_thu"]
		if level % 3 != 1:
			p += ["khien_binh", "phap_su"]
		if ch.army == "nguyen_mong":
			p += ["ky_binh", "ky_binh"]
	# yêu quái do tà thuật (hư cấu)
	p.append(ch.folk.pick_random())
	if level % 3 == 2:
		p.append(ch.folk.pick_random())
	return p
