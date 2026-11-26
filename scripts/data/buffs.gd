extends RefCounted
## Phúc lành: qua mỗi màn được chọn 1 trong 3, cộng dồn suốt lượt chơi.
## Hình biểu tượng: assets/sprites/ui/buff_<mã>.png
##   max  : số lần chồng tối đa
##   cat  : cong / thu / chien_thuat / nguyen_to / dac_biet
##   tier : 1 (Thường), 2 (Hiếm), 3 (Đặc biệt / Tuyệt kỹ)

const CATEGORIES := {
	"cong": {"name": "Công kích", "color": Color(1.0, 0.58, 0.38)},
	"thu": {"name": "Phòng thủ", "color": Color(0.55, 0.85, 1.0)},
	"chien_thuat": {"name": "Chiến thuật", "color": Color(0.58, 0.94, 0.62)},
	"nguyen_to": {"name": "Nguyên tố", "color": Color(0.76, 0.65, 1.0)},
	"dac_biet": {"name": "Tuyệt kỹ", "color": Color(1.0, 0.85, 0.32)},
}

const TIER_NAMES := {
	1: "Thường",
	2: "Hiếm",
	3: "★ Đặc biệt",
}

const TIER_COLORS := {
	1: Color(0.84, 0.72, 0.52),
	2: Color(0.42, 0.82, 1.0),
	3: Color(1.0, 0.86, 0.3),
}

const DATA := {
	"banh_chung": {"name": "Bánh chưng", "desc": "+2 máu tối đa, hồi đầy máu.", "max": 5, "cat": "thu", "tier": 1},
	"giap_dong": {"name": "Giáp đồng", "desc": "+2 giáp tối đa.", "max": 5, "cat": "thu", "tier": 1},
	"ruou_thuoc": {"name": "Rượu thuốc", "desc": "+20% sát thương.", "max": 5, "cat": "cong", "tier": 1},
	"ngua_o": {"name": "Ngựa ô", "desc": "+12% tốc độ chạy.", "max": 3, "cat": "chien_thuat", "tier": 1},
	"bua_ho_menh": {"name": "Bùa hộ mệnh", "desc": "12% né mọi đòn đánh.", "max": 3, "cat": "thu", "tier": 1},
	"da_mai": {"name": "Đá mài gươm", "desc": "Vũ khí cận chiến: +20% tầm với, +15% sát thương.", "max": 3, "cat": "cong", "tier": 1},
	"hoa_duoc": {"name": "Hỏa dược", "desc": "Vụ nổ to hơn 35%.", "max": 3, "cat": "nguyen_to", "tier": 1},
	"tra_tim_sen": {"name": "Trà tim sen", "desc": "Hồi chiêu nhanh hơn 20%.", "max": 3, "cat": "chien_thuat", "tier": 2},
	"mat_than": {"name": "Mắt thần", "desc": "+12% tỉ lệ chí mạng (gấp đôi sát thương).", "max": 4, "cat": "cong", "tier": 1},
	"linh_khi": {"name": "Linh khí", "desc": "+60 năng lượng tối đa, nạp đầy.", "max": 4, "cat": "chien_thuat", "tier": 1},
	"huyet_sam": {"name": "Huyết sâm", "desc": "Hạ giặc có 8% hồi 1 máu.", "max": 3, "cat": "thu", "tier": 2},
	"boi_thu": {"name": "Bội thu", "desc": "Nhặt xu được thêm 50%.", "max": 3, "cat": "chien_thuat", "tier": 1},
	"giay_co": {"name": "Giày cỏ", "desc": "Tấn công nhanh hơn 15%.", "max": 3, "cat": "cong", "tier": 1},
	"ten_doi": {"name": "Mũi tên đôi", "desc": "Vũ khí bắn xa: +1 viên mỗi phát.", "max": 2, "cat": "cong", "tier": 2},
	"khien_chan": {"name": "Khiên chấn động", "desc": "Khi bị đánh: tỏa sóng chấn động đẩy lùi giặc.", "max": 1, "cat": "thu", "tier": 2},
	"ngoc_bich": {"name": "Ngọc bích", "desc": "Hồi 2 năng lượng mỗi giây.", "max": 3, "cat": "chien_thuat", "tier": 1},
	"ho_tam_kinh": {"name": "Hộ tâm kính", "desc": "Khi giáp vỡ, chặn trọn đòn đầu tiên tràn vào máu (hồi 8 giây).", "max": 1, "cat": "thu", "tier": 3},
	# --- Nâng cấp Hiếm (Tier 2) lấy cảm hứng Soul Knight ---
	"dan_nay": {"name": "Đạn nảy tường", "desc": "Đạn bắn bật nảy tường thêm 1 lần.", "max": 1, "cat": "cong", "tier": 2},
	"xuyen_tam": {"name": "Xuyên tâm tiễn", "desc": "+8% tỉ lệ chí mạng; đạn chí mạng xuyên qua giặc.", "max": 1, "cat": "cong", "tier": 2},
	"khien_lua": {"name": "Khiên lửa", "desc": "Miễn nhiễm cháy, giảm 50% sát thương nổ; đòn lửa mạnh hơn +50%.", "max": 1, "cat": "nguyen_to", "tier": 2},
	"khien_doc": {"name": "Khiên độc", "desc": "Miễn nhiễm độc chướng khí; đòn đánh có 20% gây trúng độc.", "max": 1, "cat": "nguyen_to", "tier": 2},
	"thuong_khach": {"name": "Khách quý", "desc": "Giảm 30% giá tại Thương Nhân và tặng 1 lần Đổi hàng miễn phí.", "max": 1, "cat": "chien_thuat", "tier": 2},
	"hut_nang_luong": {"name": "Hấp tinh đại pháp", "desc": "Hạ giặc hồi 10 năng lượng; dọn sạch phòng hồi 2 giáp.", "max": 2, "cat": "chien_thuat", "tier": 2},
	"kiem_phan_dan": {"name": "Kiếm khí phản đạn", "desc": "Đánh cận chiến hất ngược đạn địch bay trả lại gây sát thương.", "max": 1, "cat": "cong", "tier": 2},
	# --- Tuyệt kỹ Đặc biệt (Tier 3) ---
	"tich_luc": {"name": "Xung kích thế năng", "desc": "Di chuyển tích 100% Xung kích: đòn kế chắc chắn CHÍ MẠNG +8 ST, choáng và nổ sóng.", "max": 1, "cat": "dac_biet", "tier": 3},
	"noi_cong": {"name": "Nội công tâm pháp", "desc": "Đánh cận chiến (hoặc phát thứ 4 bắn xa) phóng Chưởng Kình xuyên phá và xóa đạn địch.", "max": 1, "cat": "dac_biet", "tier": 3},
	"kim_giap": {"name": "Kim giáp tài lộc", "desc": "Mỗi 60 xu đang có tăng +1 giáp tối đa (tối đa +4); nhặt mỗi 15 xu hồi 1 giáp.", "max": 1, "cat": "dac_biet", "tier": 3},
	"loi_dinh": {"name": "Lôi đình thiên phạt", "desc": "Đòn chí mạng hoặc hạ giặc giáng Thiên Lôi nhảy chuyền 3 mục tiêu (hồi 0,6 giây).", "max": 1, "cat": "dac_biet", "tier": 3},
	"phi_kiem": {"name": "Ngự kiếm phi hành", "desc": "Triệu hồi Phi Kiếm bay quanh thân, tự phóng đâm giặc gần nhất mỗi 1,1 giây.", "max": 1, "cat": "dac_biet", "tier": 3},
	"ngu_hanh": {"name": "Ngũ hành tương sinh", "desc": "Đòn đánh luân phiên truyền Hỏa / Độc / Lôi; +30% sát thương lên giặc dính hiệu ứng.", "max": 1, "cat": "dac_biet", "tier": 3},
	"huyet_nguyet": {"name": "Huyết nguyệt cuồng chiến", "desc": "Hạ giặc kích Cuồng chiến 3,5s: +25% tốc đánh, +15% tốc chạy, +15% chí mạng.", "max": 1, "cat": "dac_biet", "tier": 3},
	# --- Mở rộng v2.0.0 (8 Phúc lành Hiếm & Tuyệt kỹ) ---
	"phan_tach": {"name": "Đạn phân tách", "desc": "Đạn trúng giặc hoặc hết tầm tách ra 2 mảnh đạn phụ gây 50% sát thương.", "max": 1, "cat": "cong", "tier": 2},
	"khuc_xa": {"name": "Khúc xạ liên hoàn", "desc": "Đạn nảy tường thêm 2 lần và tăng +15% sát thương sau mỗi lần bật.", "max": 1, "cat": "cong", "tier": 2},
	"bang_tam": {"name": "Băng tâm hàn khí", "desc": "Đòn đánh có 25% đóng băng làm chậm giặc 45% trong 2,5s; miễn nhiễm đóng băng.", "max": 1, "cat": "nguyen_to", "tier": 2},
	"cuong_no_trum": {"name": "Cuồng nộ diệt trùm", "desc": "+35% sát thương lên Trùm và giặc Tinh Anh.", "max": 1, "cat": "cong", "tier": 2},
	"song_kiem_hop": {"name": "Tam binh hợp bích", "desc": "Mở thêm ô vũ khí thứ 3; đổi vũ khí tăng +20% tốc đánh trong 2 giây.", "max": 1, "cat": "dac_biet", "tier": 3},
	"tuong_thach": {"name": "Tường thạch hộ thân", "desc": "Giảm 1 sát thương nhận vào (tối thiểu 1); khi trúng đòn gọi vòng đá chắn đạn 2s.", "max": 1, "cat": "thu", "tier": 2},
	"chien_xa_ben": {"name": "Chiến xa bất khuất", "desc": "Thú cưỡi và chiến xa +50% máu tối đa, +25% sát thương húc.", "max": 1, "cat": "chien_thuat", "tier": 2},
	"lien_kich_ba": {"name": "Liên kích tam đoạn", "desc": "Đòn cận chiến thứ 3 phóng sóng khí 360° gây +65% sát thương và xóa đạn địch.", "max": 1, "cat": "dac_biet", "tier": 3},
}


static func tier(id: String) -> int:
	if not DATA.has(id):
		return 1
	var d: Dictionary = DATA[id]
	return int(d.get("tier", 1))


static func tier_name(id: String) -> String:
	return str(TIER_NAMES.get(tier(id), "Thường"))


static func tier_color(id: String) -> Color:
	var c: Variant = TIER_COLORS.get(tier(id), TIER_COLORS[1])
	return c as Color if c is Color else Color(0.84, 0.72, 0.52)


static func category_id(id: String) -> String:
	if not DATA.has(id):
		return "cong"
	var d: Dictionary = DATA[id]
	return str(d.get("cat", "cong"))


static func category_name(id: String) -> String:
	var cid: String = category_id(id)
	var cinfo: Dictionary = CATEGORIES.get(cid, {})
	return str(cinfo.get("name", "Công kích"))


static func category_color(id: String) -> Color:
	var cid: String = category_id(id)
	var cinfo: Dictionary = CATEGORIES.get(cid, {})
	var c: Variant = cinfo.get("color", Color.WHITE)
	return c as Color if c is Color else Color.WHITE


static func _pick_from(cands: Array, used_cats: Dictionary) -> String:
	if cands.is_empty():
		return ""
	var fresh: Array = []
	for id_v in cands:
		var bid: String = str(id_v)
		if not used_cats.has(category_id(bid)):
			fresh.append(bid)
	var pick_pool: Array = fresh if not fresh.is_empty() else cands
	pick_pool.shuffle()
	return str(pick_pool[0])


## Chọn ngẫu nhiên n phúc lành chưa đạt tối đa (ưu tiên đa dạng hệ & có thể đảm bảo Tuyệt kỹ khi hạ trùm)
static func offer(owned: Dictionary, n := 3, boss_bonus := false, exclude: Array = []) -> Array:
	var pool: Array = []
	for id_v in DATA:
		var bid: String = str(id_v)
		if int(owned.get(bid, 0)) < int(DATA[bid].max):
			pool.append(bid)
	if pool.is_empty():
		return []
	var filtered: Array = []
	for bid_v in pool:
		var bid: String = str(bid_v)
		if not exclude.has(bid):
			filtered.append(bid)
	if filtered.size() >= mini(n, pool.size()):
		pool = filtered

	var t3: Array = []
	var t2: Array = []
	var t1: Array = []
	for bid_v in pool:
		var bid: String = str(bid_v)
		var tr: int = tier(bid)
		if tr >= 3:
			t3.append(bid)
		elif tr == 2:
			t2.append(bid)
		else:
			t1.append(bid)

	var out: Array = []
	var used_cats: Dictionary = {}

	# Ô 1: Đảm bảo Tuyệt kỹ (Tier 3) nếu vừa hạ trùm hoặc ~40% tỉ lệ ở màn thường
	if not t3.is_empty() and (boss_bonus or randf() < 0.4):
		var pick3: String = _pick_from(t3, used_cats)
		if pick3 != "":
			out.append(pick3)
			used_cats[category_id(pick3)] = true
			pool.erase(pick3)
			t3.erase(pick3)

	# Ô 2: Đảm bảo ít nhất 1 nâng cấp Hiếm trở lên (Tier 2+)
	if out.size() < n:
		var rare_pool: Array = t2 + t3
		var pick2: String = _pick_from(rare_pool, used_cats)
		if pick2 != "":
			out.append(pick2)
			used_cats[category_id(pick2)] = true
			pool.erase(pick2)
			t2.erase(pick2)
			t3.erase(pick2)

	# Các ô còn lại: chọn cân bằng từ phần còn lại, ưu tiên khác hệ
	while out.size() < n and not pool.is_empty():
		var weighted: Array = []
		for bid_v in pool:
			var bid: String = str(bid_v)
			var tr: int = tier(bid)
			var copies: int = 2 if tr == 2 else (1 if tr >= 3 else 3)
			for _c in copies:
				weighted.append(bid)
		var next_pick: String = _pick_from(weighted, used_cats)
		if next_pick == "":
			break
		out.append(next_pick)
		used_cats[category_id(next_pick)] = true
		pool.erase(next_pick)
	return out
