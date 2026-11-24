extends RefCounted
## Phúc lành: qua mỗi màn được chọn 1 trong 3, cộng dồn suốt lượt chơi.
## Hình biểu tượng: assets/sprites/ui/buff_<mã>.png
##   max : số lần chồng tối đa

const DATA := {
	"banh_chung": {"name": "Bánh chưng", "desc": "+2 máu tối đa, hồi đầy máu.", "max": 5},
	"giap_dong": {"name": "Giáp đồng", "desc": "+2 giáp tối đa.", "max": 5},
	"ruou_thuoc": {"name": "Rượu thuốc", "desc": "+20% sát thương.", "max": 5},
	"ngua_o": {"name": "Ngựa ô", "desc": "+12% tốc độ chạy.", "max": 3},
	"bua_ho_menh": {"name": "Bùa hộ mệnh", "desc": "12% né mọi đòn đánh.", "max": 3},
	"da_mai": {"name": "Đá mài gươm", "desc": "Vũ khí cận chiến: +20% tầm với, +15% sát thương.", "max": 3},
	"hoa_duoc": {"name": "Hỏa dược", "desc": "Vụ nổ to hơn 35%.", "max": 3},
	"tra_tim_sen": {"name": "Trà tim sen", "desc": "Hồi chiêu nhanh hơn 20%.", "max": 3},
	"mat_than": {"name": "Mắt thần", "desc": "+12% tỉ lệ chí mạng (gấp đôi sát thương).", "max": 4},
	"linh_khi": {"name": "Linh khí", "desc": "+60 năng lượng tối đa, nạp đầy.", "max": 4},
	"huyet_sam": {"name": "Huyết sâm", "desc": "Hạ giặc có 8% hồi 1 máu.", "max": 3},
	"boi_thu": {"name": "Bội thu", "desc": "Nhặt xu được thêm 50%.", "max": 3},
	"giay_co": {"name": "Giày cỏ", "desc": "Tấn công nhanh hơn 15%.", "max": 3},
	"ten_doi": {"name": "Mũi tên đôi", "desc": "Vũ khí bắn xa: +1 viên mỗi phát.", "max": 2},
	"khien_chan": {"name": "Khiên chấn động", "desc": "Khi bị đánh: tỏa sóng chấn động đẩy lùi giặc.", "max": 1},
	"ngoc_bich": {"name": "Ngọc bích", "desc": "Hồi 2 năng lượng mỗi giây.", "max": 3},
}


## Chọn ngẫu nhiên n phúc lành chưa đạt tối đa
static func offer(owned: Dictionary, n := 3) -> Array:
	var pool: Array = []
	for id in DATA:
		if int(owned.get(id, 0)) < int(DATA[id].max):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, n)
