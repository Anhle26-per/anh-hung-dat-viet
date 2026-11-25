extends RefCounted
## 67 vũ khí: 10 vũ khí cơ bản của từng tướng + 57 vũ khí nhặt trong trận, chia 5 cấp.
## Hình vẽ: assets/sprites/weapons/<mã>.png (vẽ bằng tools/sprites/art_weapons.py).
##
## Trường chung: name, tier (1-5), type, damage, cooldown (giây), energy, desc
## type "melee"  : reach, arc (độ), style ("swing" vung / "thrust" đâm / "spin" xoay),
##                 hits (số nhát), wave (bắn kèm sóng kiếm), fire (để lại lửa)
## type "ranged" : proj (hình đạn), speed, life, count, spread, inaccuracy, pierce,
##                 explode (bán kính nổ), knock, homing, recoil, muzzle, shake
## type "beam"   : length, width, color (tia laze / điện từ xuyên mọi thứ)
## type "wave"   : radius, stun (sóng lan ra từ trống đồng / đàn thần)
## type "spikes" : count, spacing (gai đá trồi lên thành hàng)
## Đặc biệt: boomerang (bay về), chain (sét lan), homing (đuổi mục tiêu)

const TIER_NAMES := ["", "Thường", "Tốt", "Hiếm", "Sử thi", "Huyền thoại"]
const TIER_COLORS := [Color.WHITE, Color("c8c8d0"), Color("6ad06a"), Color("4aa8ff"), Color("c070ff"), Color("ffb030")]

const DATA := {
	# ============================================================ VŨ KHÍ CƠ BẢN CỦA TỪNG TƯỚNG (không tốn năng lượng, không rơi ngẫu nhiên)
	"kiem_dong": {"name": "Kiếm đồng Mê Linh", "tier": 1, "basic": true, "type": "melee", "damage": 4, "cooldown": 0.3, "reach": 32.0, "arc": 120.0,
		"desc": "Kiếm đồng thời Hùng Vương - An Dương Vương."},
	"doan_dao": {"name": "Đoản đao", "tier": 1, "basic": true, "type": "melee", "damage": 5, "cooldown": 0.38, "reach": 34.0, "arc": 140.0,
		"desc": "Đao ngắn, chém rộng."},
	"giao_tre": {"name": "Giáo tre", "tier": 1, "basic": true, "type": "melee", "style": "thrust", "damage": 4, "cooldown": 0.38, "reach": 46.0, "arc": 30.0,
		"desc": "Giáo vót từ tre đực, đâm xa."},
	"no_tay": {"name": "Nỏ tay", "tier": 1, "basic": true, "type": "ranged", "proj": "arrow", "damage": 3, "cooldown": 0.3, "energy": 0, "speed": 440.0, "life": 0.75,
		"desc": "Nỏ nhỏ cầm một tay, không tốn năng lượng."},
	"guom_lenh": {"name": "Gươm lệnh", "tier": 1, "basic": true, "type": "melee", "damage": 4, "cooldown": 0.27, "reach": 33.0, "arc": 120.0,
		"desc": "Gươm chỉ huy của chủ tướng."},
	"con_lam_son": {"name": "Côn Lam Sơn", "tier": 1, "basic": true, "type": "melee", "damage": 4, "cooldown": 0.34, "reach": 38.0, "arc": 160.0, "knock": 200.0,
		"desc": "Côn gỗ của nghĩa quân Lam Sơn, quét rộng."},
	"ong_lua": {"name": "Ống lửa", "tier": 1, "basic": true, "type": "ranged", "proj": "fireball", "damage": 1, "cooldown": 0.13, "energy": 0, "speed": 220.0, "life": 0.3, "inaccuracy": 12.0, "muzzle": "fire",
		"desc": "Ống tre phun lửa tầm ngắn."},
	"dao_rua": {"name": "Dao rựa", "tier": 1, "basic": true, "type": "melee", "damage": 5, "cooldown": 0.32, "reach": 32.0, "arc": 130.0,
		"desc": "Con dao phát rừng của nông dân Nam Bộ."},
	"hoa_mai_yen_the": {"name": "Súng hỏa mai Yên Thế", "tier": 1, "basic": true, "type": "ranged", "proj": "cannonball", "damage": 6, "cooldown": 0.62, "energy": 0, "speed": 440.0, "life": 0.8, "recoil": 3.0, "muzzle": "smoke",
		"desc": "Súng tự chế của nghĩa quân Yên Thế."},
	"sung_truong_bo_binh": {"name": "Súng trường bộ binh", "tier": 1, "basic": true, "type": "ranged", "proj": "bullet", "damage": 5, "cooldown": 0.45, "energy": 0, "speed": 600.0, "life": 0.8, "recoil": 3.0, "muzzle": "flash",
		"desc": "Khẩu súng trường theo người chiến sĩ."},

	# ============================================================ CẬN CHIẾN
	"gay_tre": {"name": "Gậy tre", "tier": 1, "type": "melee", "damage": 4, "cooldown": 0.38, "reach": 40.0, "arc": 140.0, "knock": 220.0,
		"desc": "Như Thánh Gióng nhổ tre đánh giặc. Đẩy lùi mạnh."},
	"dao_gam": {"name": "Dao găm", "tier": 1, "type": "melee", "damage": 4, "cooldown": 0.18, "reach": 24.0, "arc": 90.0,
		"desc": "Ngắn nhưng đâm rất nhanh."},
	"riu_da": {"name": "Rìu đá", "tier": 1, "type": "melee", "damage": 7, "cooldown": 0.6, "reach": 30.0, "arc": 120.0,
		"desc": "Vũ khí thời Đông Sơn. Chậm, nặng tay."},
	"liem": {"name": "Lưỡi liềm", "tier": 1, "type": "melee", "damage": 4, "cooldown": 0.26, "reach": 28.0, "arc": 150.0,
		"desc": "Nông cụ thành vũ khí khởi nghĩa."},
	"giao": {"name": "Giáo", "tier": 1, "type": "melee", "style": "thrust", "damage": 5, "cooldown": 0.42, "reach": 50.0, "arc": 30.0,
		"desc": "Đâm xa, thẳng hàng."},
	"kiem": {"name": "Gươm", "tier": 2, "type": "melee", "damage": 5, "cooldown": 0.28, "reach": 34.0, "arc": 120.0,
		"desc": "Chém nhanh, vung rộng."},
	"ma_tau": {"name": "Mã tấu", "tier": 2, "type": "melee", "damage": 6, "cooldown": 0.32, "reach": 34.0, "arc": 130.0,
		"desc": "Lưỡi to bản, chém ngọt."},
	"mac": {"name": "Mác", "tier": 2, "type": "melee", "style": "thrust", "damage": 7, "cooldown": 0.45, "reach": 52.0, "arc": 40.0,
		"desc": "Cán dài, lưỡi rộng của quân Đại Việt."},
	"chuy_dong": {"name": "Chùy đồng", "tier": 2, "type": "melee", "damage": 9, "cooldown": 0.62, "reach": 32.0, "arc": 140.0, "knock": 260.0,
		"desc": "Nện mạnh, quái văng xa."},
	"con_nhi_khuc": {"name": "Côn nhị khúc", "tier": 2, "type": "melee", "style": "spin", "damage": 3, "cooldown": 0.2, "reach": 30.0, "arc": 360.0,
		"desc": "Xoay tròn đánh quanh người."},
	"dao": {"name": "Đại đao", "tier": 3, "type": "melee", "damage": 9, "cooldown": 0.5, "reach": 42.0, "arc": 160.0,
		"desc": "Chém mạnh, tầm rộng."},
	"kich": {"name": "Kích", "tier": 3, "type": "melee", "style": "thrust", "damage": 9, "cooldown": 0.42, "reach": 54.0, "arc": 50.0,
		"desc": "Vừa đâm vừa móc."},
	"truong_thuong": {"name": "Trường thương", "tier": 3, "type": "melee", "style": "thrust", "damage": 8, "cooldown": 0.36, "reach": 64.0, "arc": 24.0,
		"desc": "Tầm với xa nhất."},
	"riu_chien": {"name": "Rìu chiến", "tier": 3, "type": "melee", "damage": 13, "cooldown": 0.7, "reach": 36.0, "arc": 170.0, "knock": 240.0,
		"desc": "Rìu hai lưỡi, chém như bổ củi."},
	"song_kiem": {"name": "Song kiếm", "tier": 3, "type": "melee", "damage": 5, "cooldown": 0.3, "reach": 34.0, "arc": 130.0, "hits": 2,
		"desc": "Hai lưỡi, mỗi lần chém trúng 2 nhát."},
	"quat_thep": {"name": "Quạt thép", "tier": 4, "type": "melee", "damage": 8, "cooldown": 0.34, "reach": 36.0, "arc": 200.0, "wave": "sword_wave",
		"desc": "Phẩy quạt chém tan đạn, tung lưỡi gió."},
	"kiem_rong_tien": {"name": "Kiếm Rồng Tiên", "tier": 4, "type": "melee", "damage": 10, "cooldown": 0.34, "reach": 38.0, "arc": 140.0, "wave": "sword_wave",
		"desc": "Kiếm ngọc dòng dõi Rồng Tiên, mỗi nhát bắn sóng kiếm."},
	"thuan_thien": {"name": "Gươm Thuận Thiên", "tier": 5, "type": "melee", "damage": 10, "cooldown": 0.42, "reach": 42.0, "arc": 160.0, "wave": "sword_wave", "hits": 2,
		"desc": "Gươm thần của Lê Lợi. Sóng kiếm xuyên giáp."},
	"roi_sat_giong": {"name": "Roi sắt Thánh Gióng", "tier": 5, "type": "melee", "damage": 13, "cooldown": 0.55, "reach": 50.0, "arc": 220.0, "fire": true, "knock": 320.0,
		"desc": "Roi sắt rực lửa, quét bay cả đám giặc."},
	"kiem_tia_sang": {"name": "Kiếm tia sáng", "tier": 5, "type": "melee", "damage": 9, "cooldown": 0.30, "reach": 40.0, "arc": 150.0,
		"desc": "Lưỡi kiếm năng lượng của tương lai."},

	# ============================================================ BẮN XA CỔ
	"na": {"name": "Ná", "tier": 1, "type": "ranged", "proj": "stone", "damage": 3, "cooldown": 0.3, "energy": 0, "speed": 360.0, "life": 0.7,
		"desc": "Bắn đá, không tốn năng lượng."},
	"cung": {"name": "Cung tên", "tier": 1, "type": "ranged", "proj": "arrow", "damage": 4, "cooldown": 0.42, "energy": 1, "speed": 440.0, "life": 0.9, "pierce": 1,
		"desc": "Mũi tên xuyên 2 địch."},
	"no": {"name": "Nỏ", "tier": 1, "type": "ranged", "proj": "arrow", "damage": 3, "cooldown": 0.24, "energy": 1, "speed": 480.0, "life": 0.8,
		"desc": "Bắn nhanh, chính xác."},
	"phi_tieu": {"name": "Phi tiêu", "tier": 2, "type": "ranged", "proj": "dart", "damage": 3, "cooldown": 0.3, "energy": 1, "speed": 420.0, "life": 0.6, "count": 3, "spread": 20.0,
		"desc": "Phóng 3 phi tiêu một lúc."},
	"cung_dai": {"name": "Cung dài", "tier": 2, "type": "ranged", "proj": "arrow", "damage": 6, "cooldown": 0.5, "energy": 1, "speed": 560.0, "life": 1.0, "pierce": 2,
		"desc": "Tên bay xa, xuyên 3 địch."},
	"hoa_ho": {"name": "Hỏa hổ", "tier": 3, "type": "ranged", "proj": "fireball", "damage": 2, "cooldown": 0.09, "energy": 1, "speed": 240.0, "life": 0.42, "count": 2, "spread": 26.0, "inaccuracy": 10.0, "knock": 20.0, "muzzle": "fire",
		"desc": "Ống phun lửa của quân Tây Sơn."},
	"hoa_tien": {"name": "Hỏa tiễn", "tier": 3, "type": "ranged", "proj": "rocket", "damage": 7, "cooldown": 0.8, "energy": 3, "speed": 280.0, "life": 1.2, "explode": 40.0, "recoil": 3.0, "muzzle": "smoke",
		"desc": "Tên lửa thời Trần, nổ lan."},
	"than_co_sang": {"name": "Súng thần cơ", "tier": 3, "type": "ranged", "proj": "cannonball", "damage": 11, "cooldown": 0.7, "energy": 3, "speed": 380.0, "life": 1.0, "knock": 240.0, "recoil": 4.0, "muzzle": "flash", "shake": 2.0,
		"desc": "Súng của Hồ Nguyên Trừng. Đạn nặng."},
	"phao_dong": {"name": "Pháo đồng", "tier": 4, "type": "ranged", "proj": "cannonball", "damage": 14, "cooldown": 0.9, "energy": 4, "speed": 320.0, "life": 1.1, "explode": 46.0, "recoil": 5.0, "muzzle": "flash", "shake": 3.0,
		"desc": "Đạn pháo nổ tung."},
	"cung_rong": {"name": "Cung Lạc Long", "tier": 4, "type": "ranged", "proj": "fireball", "damage": 8, "cooldown": 0.45, "energy": 2, "speed": 330.0, "life": 1.4, "count": 2, "spread": 14.0, "homing": 4.0, "pierce": 1,
		"desc": "Tên lửa rồng tự đuổi theo giặc."},
	"no_lien_chau": {"name": "Nỏ thần Liên Châu", "tier": 5, "type": "ranged", "proj": "arrow", "damage": 4, "cooldown": 0.42, "energy": 3, "speed": 500.0, "life": 0.9, "count": 4, "spread": 32.0, "pierce": 1,
		"desc": "Nỏ thần An Dương Vương: 4 mũi tên một phát."},
	"dai_bac_than_cong": {"name": "Đại bác thần công", "tier": 5, "type": "ranged", "proj": "cannonball", "damage": 18, "cooldown": 1.30, "energy": 6, "speed": 300.0, "life": 1.2, "explode": 56.0, "recoil": 7.0, "muzzle": "flash", "shake": 5.0,
		"desc": "Đạn thần công nổ lớn."},
	"trong_dong": {"name": "Trống đồng thần", "tier": 5, "type": "wave", "damage": 9, "cooldown": 0.85, "energy": 3, "radius": 110.0,
		"desc": "Tiếng trống Đông Sơn lan ra, đánh mọi kẻ xung quanh và xóa đạn."},
	"hoa_mai": {"name": "Súng hỏa mai", "tier": 2, "type": "ranged", "proj": "cannonball", "damage": 9, "cooldown": 0.8, "energy": 2, "speed": 460.0, "life": 0.9, "recoil": 4.0, "muzzle": "smoke",
		"desc": "Súng châm ngòi, chậm mà mạnh."},

	# ============================================================ CẬN ĐẠI & HIỆN ĐẠI
	"sung_kip": {"name": "Súng kíp", "tier": 1, "type": "ranged", "proj": "bullet", "damage": 5, "cooldown": 0.5, "energy": 1, "speed": 480.0, "life": 0.7, "recoil": 3.0, "muzzle": "smoke",
		"desc": "Súng ngắn đá lửa."},
	"sung_ngan": {"name": "Súng ngắn", "tier": 1, "type": "ranged", "proj": "bullet", "damage": 3, "cooldown": 0.22, "energy": 1, "speed": 520.0, "life": 0.7, "recoil": 2.0, "muzzle": "flash",
		"desc": "Gọn nhẹ, bắn đều tay."},
	"sung_luc": {"name": "Súng lục ổ quay", "tier": 2, "type": "ranged", "proj": "bullet", "damage": 6, "cooldown": 0.34, "energy": 1, "speed": 540.0, "life": 0.7, "recoil": 3.0, "muzzle": "flash", "pierce": 1,
		"desc": "Đạn xuyên 2 địch."},
	"sung_san": {"name": "Súng săn", "tier": 2, "type": "ranged", "proj": "pellet", "damage": 2, "cooldown": 0.6, "energy": 2, "speed": 420.0, "life": 0.4, "count": 6, "spread": 34.0, "inaccuracy": 6.0, "recoil": 4.0, "muzzle": "flash", "shake": 2.0,
		"desc": "Bắn chùm đạn tầm gần."},
	"sung_truong": {"name": "Súng trường", "tier": 2, "type": "ranged", "proj": "bullet", "damage": 9, "cooldown": 0.62, "energy": 1, "speed": 640.0, "life": 0.9, "pierce": 1, "recoil": 4.0, "muzzle": "flash",
		"desc": "Bắn phát một, chính xác."},
	"sung_hai_nong": {"name": "Súng hai nòng", "tier": 3, "type": "ranged", "proj": "pellet", "damage": 2, "cooldown": 0.80, "energy": 3, "speed": 440.0, "life": 0.42, "count": 7, "spread": 38.0, "inaccuracy": 6.0, "recoil": 6.0, "muzzle": "flash", "shake": 3.0,
		"desc": "Hai nòng cùng nổ, chùm đạn dày."},
	"tieu_lien": {"name": "Tiểu liên", "tier": 3, "type": "ranged", "proj": "bullet", "damage": 2, "cooldown": 0.10, "energy": 1, "speed": 560.0, "life": 0.6, "inaccuracy": 8.0, "recoil": 1.5, "muzzle": "flash",
		"desc": "Bắn liên thanh cực nhanh."},
	"sung_truong_tan_cong": {"name": "Súng trường tấn công", "tier": 3, "type": "ranged", "proj": "bullet", "damage": 3, "cooldown": 0.14, "energy": 1, "speed": 600.0, "life": 0.8, "inaccuracy": 4.0, "recoil": 2.0, "muzzle": "flash",
		"desc": "Cân bằng giữa tốc độ và sức mạnh."},
	"sung_ban_tia": {"name": "Súng bắn tỉa", "tier": 4, "type": "ranged", "proj": "bullet", "damage": 18, "cooldown": 1.10, "energy": 3, "speed": 900.0, "life": 1.0, "pierce": 99, "recoil": 6.0, "muzzle": "flash", "shake": 2.0,
		"desc": "Một phát xuyên thủng cả hàng giặc."},
	"sung_may": {"name": "Súng máy", "tier": 4, "type": "ranged", "proj": "bullet", "damage": 3, "cooldown": 0.10, "energy": 1, "speed": 600.0, "life": 0.8, "inaccuracy": 10.0, "recoil": 2.0, "muzzle": "flash", "shake": 0.6,
		"desc": "Mưa đạn không ngớt."},
	"sung_phong_luu": {"name": "Súng phóng lựu", "tier": 4, "type": "ranged", "proj": "grenade", "damage": 10, "cooldown": 0.85, "energy": 3, "speed": 260.0, "life": 0.7, "explode": 46.0, "recoil": 4.0, "muzzle": "smoke",
		"desc": "Lựu đạn nổ khi chạm hoặc hết đà."},
	"sung_phong_ten_lua": {"name": "Súng phóng tên lửa", "tier": 4, "type": "ranged", "proj": "rocket", "damage": 15, "cooldown": 1.15, "energy": 5, "speed": 340.0, "life": 1.4, "explode": 52.0, "recoil": 6.0, "muzzle": "smoke", "shake": 3.0,
		"desc": "Tên lửa nổ mạnh."},
	"sung_phun_lua": {"name": "Súng phun lửa", "tier": 4, "type": "ranged", "proj": "fireball", "damage": 2, "cooldown": 0.09, "energy": 1, "speed": 250.0, "life": 0.45, "count": 1, "spread": 16.0, "inaccuracy": 12.0, "pierce": 1, "muzzle": "fire",
		"desc": "Lửa xuyên qua kẻ địch."},
	"sung_plasma": {"name": "Súng plasma", "tier": 4, "type": "ranged", "proj": "plasma", "damage": 7, "cooldown": 0.32, "energy": 2, "speed": 380.0, "life": 1.0, "explode": 22.0, "muzzle": "flash",
		"desc": "Cầu plasma nổ nhỏ."},
	# ============================================================ TRUYỀN KỲ VIỆT NAM
	"riu_thach_sanh": {"name": "Rìu Thạch Sanh", "tier": 5, "type": "ranged", "proj": "axe", "boomerang": true, "damage": 10, "cooldown": 0.65, "energy": 1, "speed": 320.0, "life": 0.9, "pierce": 99, "knock": 160.0,
		"desc": "Rìu chém chằn tinh. Ném ra rồi bay vòng về tay."},
	"dan_than": {"name": "Đàn thần Thạch Sanh", "tier": 5, "type": "wave", "damage": 4, "cooldown": 1.0, "energy": 3, "radius": 130.0, "stun": 2.0, "color": Color("ffe08a"),
		"desc": "Tiếng đàn làm giặc bủn rủn tay chân, đứng im."},
	"cung_vang": {"name": "Cung vàng Thạch Sanh", "tier": 4, "type": "ranged", "proj": "arrow", "damage": 7, "cooldown": 0.45, "energy": 1, "speed": 520.0, "life": 1.2, "pierce": 2, "homing": 5.0, "color": Color("ffd84a"),
		"desc": "Mũi tên vàng bắn hạ đại bàng, tự đuổi mục tiêu."},
	"gay_son_tinh": {"name": "Gậy thần Sơn Tinh", "tier": 5, "type": "spikes", "damage": 9, "cooldown": 0.90, "energy": 4, "count": 7, "spacing": 18.0, "shake": 3.0,
		"desc": "Vẫy gậy dâng núi: gai đá trồi lên thành hàng."},
	"dinh_ba_thuy_tinh": {"name": "Đinh ba Thủy Tinh", "tier": 5, "type": "melee", "style": "thrust", "damage": 9, "cooldown": 0.48, "reach": 56.0, "arc": 40.0, "wave": "water_wave", "knock": 260.0,
		"desc": "Đâm kèm sóng nước cuốn phăng giặc."},
	"bua_thien_loi": {"name": "Búa Thiên Lôi", "tier": 5, "type": "melee", "damage": 10, "cooldown": 0.65, "reach": 38.0, "arc": 160.0, "chain": 4, "knock": 200.0, "shake": 2.0,
		"desc": "Thiên Lôi chỉ đâu đánh đấy: sét lan qua 4 kẻ địch."},
	"tre_tram_dot": {"name": "Cây tre trăm đốt", "tier": 4, "type": "melee", "style": "thrust", "damage": 8, "cooldown": 0.38, "reach": 86.0, "arc": 22.0,
		"desc": "Khắc nhập, khắc xuất! Roi tre dài vươn xa."},

	"sung_laze": {"name": "Súng laze", "tier": 5, "type": "beam", "damage": 6, "cooldown": 0.26, "energy": 2, "length": 320.0, "width": 3.0, "color": Color("4ae0ff"),
		"desc": "Tia laze tức thì, xuyên mọi quái."},
	"sung_dien_tu": {"name": "Súng điện từ", "tier": 5, "type": "beam", "damage": 22, "cooldown": 1.15, "energy": 5, "length": 420.0, "width": 6.0, "color": Color("c8f8ff"), "shake": 4.0,
		"desc": "Bắn tia điện từ khổng lồ."},
}


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, {})


static func tier_color(id: String) -> Color:
	return TIER_COLORS[int(DATA.get(id, {}).get("tier", 1))]


static var _grips := {}


## Điểm cầm của hình vũ khí (đọc từ grips.json do công cụ vẽ tạo ra)
static func grip(id: String) -> Vector2:
	if _grips.is_empty():
		var f := FileAccess.open("res://assets/sprites/weapons/grips.json", FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				_grips = d
	var g = _grips.get(id, [4, 4])
	return Vector2(g[0], g[1])


## Chọn ngẫu nhiên 1 vũ khí theo tỉ lệ chuẩn (Huyền thoại Cấp 5 rất hiếm).
static func roll(level: int, bonus := 0) -> String:
	var t_idx: float = float(mini(maxi(level - 1, 0), 12))
	var b: float = float(maxi(bonus, 0))
	var weights: Array[float] = [
		0.0,
		maxf(54.0 - t_idx * 2.5 - b * 9.0, 12.0),
		maxf(30.0 - t_idx * 0.6 - b * 2.0, 16.0),
		12.0 + t_idx * 1.6 + b * 6.0,
		3.5 + t_idx * 0.9 + b * 3.2,
		0.5 + t_idx * 0.25 + (b * b) * 0.55,
	]
	var total := 0.0
	for t in range(1, 6):
		total += weights[t]
	var r := randf() * total
	var tier := 1
	for t in range(1, 6):
		r -= weights[t]
		if r <= 0.0:
			tier = t
			break
	var pool: Array = []
	for id in DATA:
		if int(DATA[id].tier) == tier and not DATA[id].get("basic", false):
			pool.append(id)
	return pool.pick_random()
