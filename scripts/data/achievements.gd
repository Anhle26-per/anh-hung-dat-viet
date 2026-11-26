extends RefCounted
## Dữ liệu 24 mốc Thành Tựu tại Tầng Hầm Chiến Tích và phần thưởng Xu / Nguyên liệu / 14 Bản Vẽ binh khí.

const CATEGORY_ORDER: Array = ["chien_cong", "tram_tuong", "chinh_phuc", "binh_khi", "che_tao"]

const CATEGORIES: Dictionary = {
	"chien_cong": {
		"name": "Chiến Công",
		"desc": "Tiêu diệt giặc xâm lăng và yêu ma trong các trận đánh.",
		"color": Color(0.95, 0.42, 0.36),
	},
	"tram_tuong": {
		"name": "Trảm Tướng",
		"desc": "Đánh bại các Trùm lịch sử, Tam Yêu và Trùm Thần Thoại.",
		"color": Color(1.0, 0.68, 0.28),
	},
	"chinh_phuc": {
		"name": "Chinh Phục",
		"desc": "Vượt ải thử thách và tích lũy số lượt xuất trận.",
		"color": Color(0.45, 0.86, 1.0),
	},
	"binh_khi": {
		"name": "Binh Khí",
		"desc": "Sưu tầm đầy đủ kho 200 binh khí cổ kim kỳ dị.",
		"color": Color(0.76, 0.54, 1.0),
	},
	"che_tao": {
		"name": "Chế Tạo",
		"desc": "Rèn đúc binh khí, tích lũy tài phú và mở rương báu.",
		"color": Color(0.48, 0.92, 0.56),
	},
}

const BLUEPRINT_TIERS: Dictionary = {
	"basic": [
		"truong_hoa_cau",
		"dua_bang_suong",
		"bua_tran_yeu",
		"sung_bong_bong",
		"luan_hoi_ban",
		"bai_tu_sac",
		"long_den_ma_troi",
	],
	"advanced": [
		"guong_bat_quai",
		"sach_sao_bang",
		"sung_tesla",
		"truong_ho_den",
		"kiem_thoi_khong",
		"luoi_hai_tu_than",
		"dai_bac_long_vuong",
	],
}

const ORDER: Array = [
	# Chiến Công (5)
	"kills_25",
	"kills_100",
	"kills_350",
	"kills_800",
	"kills_2000",
	# Trảm Tướng (5)
	"bosses_1",
	"bosses_5",
	"bosses_15",
	"mythic_1",
	"mythic_5",
	# Chinh Phục (5)
	"runs_3",
	"runs_12",
	"level_5",
	"level_15",
	"level_25",
	# Binh Khí (5)
	"weapons_15",
	"weapons_40",
	"weapons_80",
	"weapons_130",
	"weapons_180",
	# Chế Tạo & Tài Phú (4)
	"crafted_1",
	"crafted_5",
	"coins_500",
	"chests_10",
]

const DATA: Dictionary = {
	# --- Chiến Công (kills) ---
	"kills_25": {
		"name": "Tân Binh Lập Công",
		"desc": "Tiêu diệt 25 kẻ địch trên chiến trường.",
		"cat": "chien_cong",
		"stat": "kills",
		"target": 25,
		"coins": 30,
		"mats": {"dong": 2},
		"blueprint": "",
	},
	"kills_100": {
		"name": "Dũng Sĩ Diệt Giặc",
		"desc": "Tiêu diệt 100 kẻ địch.",
		"cat": "chien_cong",
		"stat": "kills",
		"target": 100,
		"coins": 60,
		"mats": {"dong": 3, "sat": 2},
		"blueprint": "truong_hoa_cau",
	},
	"kills_350": {
		"name": "Mãnh Tướng Sa Trường",
		"desc": "Tiêu diệt 350 kẻ địch.",
		"cat": "chien_cong",
		"stat": "kills",
		"target": 350,
		"coins": 120,
		"mats": {"sat": 4, "go_lim": 2},
		"blueprint": "bua_tran_yeu",
	},
	"kills_800": {
		"name": "Thiên Quân Vạn Mã",
		"desc": "Tiêu diệt 800 kẻ địch.",
		"cat": "chien_cong",
		"stat": "kills",
		"target": 800,
		"coins": 220,
		"mats": {"sat": 5, "yeu_hon": 2},
		"blueprint": "guong_bat_quai",
	},
	"kills_2000": {
		"name": "Bất Bại Chiến Thần",
		"desc": "Tiêu diệt 2.000 kẻ địch.",
		"cat": "chien_cong",
		"stat": "kills",
		"target": 2000,
		"coins": 400,
		"mats": {"yeu_hon": 3, "ngoc_than": 2},
		"blueprint": "luoi_hai_tu_than",
	},

	# --- Trảm Tướng (bosses & mythic_bosses) ---
	"bosses_1": {
		"name": "Phá Trận Thủ Lĩnh",
		"desc": "Đánh bại 1 Trùm giữ ải.",
		"cat": "tram_tuong",
		"stat": "bosses",
		"target": 1,
		"coins": 50,
		"mats": {"dong": 2, "yeu_hon": 1},
		"blueprint": "dua_bang_suong",
	},
	"bosses_5": {
		"name": "Khắc Tinh Hung Tướng",
		"desc": "Đánh bại 5 Trùm giữ ải.",
		"cat": "tram_tuong",
		"stat": "bosses",
		"target": 5,
		"coins": 120,
		"mats": {"sat": 4, "yeu_hon": 2},
		"blueprint": "luan_hoi_ban",
	},
	"bosses_15": {
		"name": "Bình Định Giang Sơn",
		"desc": "Đánh bại 15 Trùm giữ ải.",
		"cat": "tram_tuong",
		"stat": "bosses",
		"target": 15,
		"coins": 240,
		"mats": {"yeu_hon": 3, "ngoc_than": 1},
		"blueprint": "sach_sao_bang",
	},
	"mythic_1": {
		"name": "Bước Vào Thần Thoại",
		"desc": "Đánh bại 1 Trùm ở chuyến du hành Thần Thoại (màn 17+).",
		"cat": "tram_tuong",
		"stat": "mythic_bosses",
		"target": 1,
		"coins": 260,
		"mats": {"yeu_hon": 3, "ngoc_than": 2},
		"blueprint": "truong_ho_den",
	},
	"mythic_5": {
		"name": "Chúa Tể Truyền Thuyết",
		"desc": "Đánh bại 5 Trùm ở chế độ Thần Thoại.",
		"cat": "tram_tuong",
		"stat": "mythic_bosses",
		"target": 5,
		"coins": 500,
		"mats": {"yeu_hon": 5, "ngoc_than": 4},
		"blueprint": "dai_bac_long_vuong",
	},

	# --- Chinh Phục (best_level & runs) ---
	"runs_3": {
		"name": "Chí Lớn Lên Đường",
		"desc": "Xuất trận 3 lượt hành trình.",
		"cat": "chinh_phuc",
		"stat": "runs",
		"target": 3,
		"coins": 35,
		"mats": {"dong": 2, "go_lim": 2},
		"blueprint": "",
	},
	"runs_12": {
		"name": "Kiên Cường Bất Khuất",
		"desc": "Xuất trận 12 lượt hành trình.",
		"cat": "chinh_phuc",
		"stat": "runs",
		"target": 12,
		"coins": 90,
		"mats": {"sat": 3, "hoa_duoc": 2},
		"blueprint": "long_den_ma_troi",
	},
	"level_5": {
		"name": "Vượt Ải Đầu Tiên",
		"desc": "Đạt tới màn 5 trong một lượt chơi.",
		"cat": "chinh_phuc",
		"stat": "best_level",
		"target": 5,
		"coins": 70,
		"mats": {"dong": 3, "sat": 2},
		"blueprint": "",
	},
	"level_15": {
		"name": "Khải Hoàn Điện Biên",
		"desc": "Chinh phục tới màn 15.",
		"cat": "chinh_phuc",
		"stat": "best_level",
		"target": 15,
		"coins": 250,
		"mats": {"sat": 5, "ngoc_than": 2},
		"blueprint": "sung_tesla",
	},
	"level_25": {
		"name": "Xuyên Không Thần Thoại",
		"desc": "Vươn tới màn 25 ở vùng Thần Thoại.",
		"cat": "chinh_phuc",
		"stat": "best_level",
		"target": 25,
		"coins": 450,
		"mats": {"yeu_hon": 4, "ngoc_than": 3},
		"blueprint": "kiem_thoi_khong",
	},

	# --- Binh Khí (discovered out of 200) ---
	"weapons_15": {
		"name": "Tập Sự Binh Gia",
		"desc": "Sưu tầm 15 / 200 loại binh khí.",
		"cat": "binh_khi",
		"stat": "discovered",
		"target": 15,
		"coins": 40,
		"mats": {"dong": 3},
		"blueprint": "",
	},
	"weapons_40": {
		"name": "Kho Tàng Cổ Kim",
		"desc": "Sưu tầm 40 / 200 loại binh khí.",
		"cat": "binh_khi",
		"stat": "discovered",
		"target": 40,
		"coins": 100,
		"mats": {"sat": 3, "go_lim": 3},
		"blueprint": "sung_bong_bong",
	},
	"weapons_80": {
		"name": "Bách Binh Giám Định",
		"desc": "Sưu tầm 80 / 200 loại binh khí.",
		"cat": "binh_khi",
		"stat": "discovered",
		"target": 80,
		"coins": 180,
		"mats": {"hoa_duoc": 3, "yeu_hon": 2},
		"blueprint": "bai_tu_sac",
	},
	"weapons_130": {
		"name": "Đại Sư Tàng Bảo",
		"desc": "Sưu tầm 130 / 200 loại binh khí.",
		"cat": "binh_khi",
		"stat": "discovered",
		"target": 130,
		"coins": 300,
		"mats": {"yeu_hon": 4, "ngoc_than": 2},
		"blueprint": "",
	},
	"weapons_180": {
		"name": "Thiên Hạ Vô Song",
		"desc": "Sưu tầm 180 / 200 loại binh khí.",
		"cat": "binh_khi",
		"stat": "discovered",
		"target": 180,
		"coins": 600,
		"mats": {"yeu_hon": 6, "ngoc_than": 5},
		"blueprint": "",
	},

	# --- Chế Tạo & Tài Phú (crafted, coins, chests) ---
	"crafted_1": {
		"name": "Khởi Lửa Lò Rèn",
		"desc": "Rèn thành công 1 binh khí tại Lò rèn.",
		"cat": "che_tao",
		"stat": "crafted",
		"target": 1,
		"coins": 45,
		"mats": {"dong": 2, "sat": 2},
		"blueprint": "",
	},
	"crafted_5": {
		"name": "Thợ Rèn Lão Luyện",
		"desc": "Rèn thành công 5 binh khí tại Lò rèn.",
		"cat": "che_tao",
		"stat": "crafted",
		"target": 5,
		"coins": 140,
		"mats": {"sat": 4, "hoa_duoc": 2, "yeu_hon": 1},
		"blueprint": "",
	},
	"coins_500": {
		"name": "Tích Lương Thảo",
		"desc": "Tích trữ đạt 500 xu trong kho.",
		"cat": "che_tao",
		"stat": "coins",
		"target": 500,
		"coins": 100,
		"mats": {"dong": 4, "go_lim": 3},
		"blueprint": "",
	},
	"chests_10": {
		"name": "Thợ Săn Kho Báu",
		"desc": "Mở tổng cộng 10 rương chiến lợi phẩm.",
		"cat": "che_tao",
		"stat": "chests",
		"target": 10,
		"coins": 120,
		"mats": {"sat": 3, "yeu_hon": 2},
		"blueprint": "",
	},
}


static func progress_for(aid: String, g: Node) -> int:
	if g == null or not DATA.has(aid):
		return 0
	var info: Dictionary = DATA[aid]
	var stat_key: String = str(info.get("stat", ""))
	match stat_key:
		"kills", "bosses", "mythic_bosses", "runs", "crafted", "chests":
			var st: Variant = g.get("stats")
			if typeof(st) == TYPE_DICTIONARY:
				return maxi(0, int((st as Dictionary).get(stat_key, 0)))
			return 0
		"best_level":
			return maxi(0, int(g.get("best_level")))
		"discovered":
			var disc: Variant = g.get("discovered")
			if typeof(disc) == TYPE_ARRAY:
				return (disc as Array).size()
			return 0
		"coins":
			return maxi(0, int(g.get("coins")))
	return 0


static func is_completed(aid: String, g: Node) -> bool:
	if not DATA.has(aid):
		return false
	var target: int = int(DATA[aid].get("target", 1))
	return progress_for(aid, g) >= target


static func is_blueprint_id(wid: String) -> bool:
	var basic: Array = BLUEPRINT_TIERS.get("basic", [])
	var adv: Array = BLUEPRINT_TIERS.get("advanced", [])
	return basic.has(wid) or adv.has(wid)


static func blueprint_source(wid: String) -> String:
	for aid in ORDER:
		var k: String = str(aid)
		if str(DATA[k].get("blueprint", "")) == wid:
			return k
	return ""
