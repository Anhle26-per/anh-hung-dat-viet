"""Biểu tượng phúc lành 32x32 (pixel art chi tiết, chiều sâu phân lớp, ánh sáng & viền tối)."""
import math
from px import hexc, shade, outline, save, DARK_LINE, Image
import art_v20_world

S = 32

C = {k: hexc(v) for k, v in {
    "leaf_d": "26541c", "leaf": "4a8e32", "leaf_l": "7ed052", "leaf_hi": "b8f288",
    "lat_d": "a87224", "lat": "e8b84c", "lat_l": "f5d472", "lat_hi": "fff2a8",
    "red_d": "681422", "red": "c82c38", "red_l": "f25c54", "red_hi": "ffa898",
    "gold_d": "7c4612", "gold": "d48c28", "gold_l": "ffcf54", "gold_hi": "fff6b8",
    "bronze_d": "582e14", "bronze": "9e5c26", "bronze_l": "d68e42", "bronze_hi": "f6c878",
    "steel_d": "3e4860", "steel": "7686a8", "steel_l": "b8cae8", "steel_hi": "f0f6ff",
    "wood_d": "462816", "wood": "7c4c2a", "wood_l": "b47846", "wood_hi": "dca46c",
    "stone_d": "2e2a3c", "stone": "544e6a", "stone_l": "847ea0", "stone_hi": "b4aec8",
    "blue_d": "143e8e", "blue": "2a7ee8", "blue_l": "5ec8ff", "blue_hi": "c8f8ff",
    "jade_d": "125240", "jade": "269e74", "jade_l": "5ae4ac", "jade_hi": "c0ffe4",
    "pois_d": "18441e", "pois": "348c38", "pois_l": "6ce04e", "pois_hi": "c8ff8c",
    "purp_d": "3a1c64", "purp": "763cc4", "purp_l": "b478ff", "purp_hi": "ebd0ff",
    "ink_d": "1a1624", "ink": "322c44", "ink_l": "584e72", "ink_hi": "96a8cc",
    "fire_d": "9a1e18", "fire": "e84c24", "fire_l": "ff9e2c", "fire_hi": "fff088",
    "pink_d": "a8486c", "pink": "ea84a4", "pink_hi": "ffd4e4",
    "white": "ffffff", "cream": "fff5dc",
}.items()}


def _blank():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def _pp(img, x, y, col):
    ix, iy = int(round(x)), int(round(y))
    if 1 <= ix < S - 1 and 1 <= iy < S - 1:
        img.putpixel((ix, iy), col)


def _blend(img, x, y, col):
    ix, iy = int(round(x)), int(round(y))
    if 1 <= ix < S - 1 and 1 <= iy < S - 1:
        bg = img.getpixel((ix, iy))
        a = col[3] / 255.0
        if bg[3] == 0:
            img.putpixel((ix, iy), col)
        else:
            nr = int(bg[0] * (1 - a) + col[0] * a)
            ng = int(bg[1] * (1 - a) + col[1] * a)
            nb = int(bg[2] * (1 - a) + col[2] * a)
            na = min(255, max(bg[3], col[3]))
            img.putpixel((ix, iy), (nr, ng, nb, na))


def _rect(img, x0, y0, x1, y1, col):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            _pp(img, x, y, col)


def _disc(img, cx, cy, r, col):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                _pp(img, x, y, col)


def _ring(img, cx, cy, r_in, r_out, col):
    for y in range(int(math.floor(cy - r_out)), int(math.ceil(cy + r_out)) + 1):
        for x in range(int(math.floor(cx - r_out)), int(math.ceil(cx + r_out)) + 1):
            d = math.hypot(x - cx, y - cy)
            if r_in <= d <= r_out:
                _pp(img, x, y, col)


def _line(img, x0, y0, x1, y1, col, thick=1):
    steps = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) * 2))
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        if thick <= 1:
            _pp(img, x, y, col)
        else:
            _disc(img, x, y, thick * 0.5, col)


def _spark(img, cx, cy, col, core=None, size=2):
    _pp(img, cx, cy, core or C["white"])
    for d in range(1, size + 1):
        c = col if d == 1 else (col[0], col[1], col[2], 190)
        _pp(img, cx - d, cy, c)
        _pp(img, cx + d, cy, c)
        _pp(img, cx, cy - d, c)
        _pp(img, cx, cy + d, c)


def _shield_base(img, cx, top, w_half, h, c_d, c_m, c_l, c_hi, rim_d, rim_l):
    """Vẽ khiên cổ điển có viền kim loại, độ khối 3D và ánh sáng góc trên-trái."""
    for dy in range(h):
        y = top + dy
        t = dy / max(1, h - 1)
        if t < 0.45:
            hw = w_half
        else:
            k = (t - 0.45) / 0.55
            hw = max(1, int(round(w_half * (1.0 - k ** 1.35))))
        for dx in range(-hw, hw + 1):
            x = cx + dx
            is_rim = abs(dx) >= hw - 1 or dy <= 1 or dy >= h - 2
            if is_rim:
                col = rim_l if (dx < 0 or dy < 3) and not (dx > hw - 2 and dy > 4) else rim_d
            else:
                nx = dx / max(1, hw)
                ny = (dy - h * 0.35) / max(1, h)
                lit = -nx * 0.55 - ny * 0.45
                if lit > 0.35:
                    col = c_hi
                elif lit > 0.05:
                    col = c_l
                elif lit > -0.28:
                    col = c_m
                else:
                    col = c_d
            _pp(img, x, y, col)


def _coin_at(img, cx, cy, r=5):
    """Đồng tiền cổ lỗ vuông Việt Nam."""
    _disc(img, cx, cy, r, C["gold_d"])
    _disc(img, cx, cy, r - 1, C["gold"])
    for y in range(int(cy - r + 1), int(cy + r)):
        for x in range(int(cx - r + 1), int(cx + r)):
            if math.hypot(x - cx, y - cy) <= r - 1.1:
                if (x - cx) + (y - cy) < -1.5:
                    _pp(img, x, y, C["gold_hi"])
                elif (x - cx) + (y - cy) < 0.8:
                    _pp(img, x, y, C["gold_l"])
    hole = max(1, r // 3)
    for y in range(int(cy - hole), int(cy + hole + 1)):
        for x in range(int(cx - hole), int(cx + hole + 1)):
            if 1 <= x < S - 1 and 1 <= y < S - 1:
                img.putpixel((x, y), (0, 0, 0, 0))
    # viền trong lỗ vuông
    for y in range(int(cy - hole), int(cy + hole + 1)):
        _pp(img, cx - hole - 1, y, C["gold_d"])
        _pp(img, cx + hole + 1, y, C["gold_d"])
    for x in range(int(cx - hole), int(cx + hole + 1)):
        _pp(img, x, cy - hole - 1, C["gold_d"])
        _pp(img, x, cy + hole + 1, C["gold_d"])


# ==================================================================== 31 Icons
def draw_banh_chung():
    img = _blank()
    # Bánh chưng đặt nghiêng có độ dày 3D (mặt trên + thành bên dưới-phải)
    for y in range(7, 25):
        for x in range(6, 26):
            # cạnh dưới tạo khối dày
            if y >= 22:
                _pp(img, x, y, C["leaf_d"])
            elif x >= 24:
                _pp(img, x, y, C["leaf_d"])
            else:
                # gân lá dong chéo
                d = (x - 6) + (y - 7)
                if d < 10:
                    col = C["leaf_hi"] if (x + y) % 4 == 0 else C["leaf_l"]
                elif d < 22:
                    col = C["leaf_l"] if (x - y) % 5 == 0 else C["leaf"]
                else:
                    col = C["leaf"] if (x + y) % 4 == 0 else C["leaf_d"]
                _pp(img, x, y, col)
    # nếp gấp lá ở 4 góc
    for k in range(3):
        _pp(img, 7 + k, 8, C["leaf_hi"])
        _pp(img, 7, 8 + k, C["leaf_hi"])
        _pp(img, 23 - k, 21, C["leaf_d"])
    # dây lạt ngang dọc (mỗi chiều 2 sợi đan chữ thập)
    for bx in (12, 19):
        for y in range(6, 25):
            col = C["lat_hi"] if y < 12 else (C["lat"] if y < 21 else C["lat_d"])
            _pp(img, bx, y, col)
            _pp(img, bx + 1, y, C["lat_d"] if y >= 20 else C["lat"])
    for by in (12, 18):
        for x in range(6, 26):
            col = C["lat_hi"] if x < 12 else (C["lat"] if x < 22 else C["lat_d"])
            _pp(img, x, by, col)
            _pp(img, x, by + 1, C["lat_d"] if x >= 22 else C["lat"])
    # nút thắt dây lạt đỏ may mắn ở tâm
    _disc(img, 16, 15, 2.3, C["red"])
    _pp(img, 15, 14, C["red_hi"])
    _pp(img, 16, 15, C["gold_hi"])
    _line(img, 16, 15, 19, 17, C["red_l"])
    _line(img, 16, 15, 13, 18, C["red_d"])
    _spark(img, 8, 8, C["leaf_hi"], C["white"], 1)
    return img


def draw_giap_dong():
    img = _blank()
    # Thân giáp đồng Đông Sơn + vai giáp + họa tiết mặt trời trống đồng
    # Vai trái/phải
    _disc(img, 8, 10, 4.2, C["bronze_l"])
    _disc(img, 8, 10, 3.0, C["bronze_hi"])
    _disc(img, 23, 10, 4.2, C["bronze_d"])
    _disc(img, 23, 10, 2.8, C["bronze"])
    # Thân giáp
    for y in range(8, 26):
        hw = 7 if y < 18 else (8 if y < 22 else 6)
        for dx in range(-hw, hw + 1):
            x = 16 + dx
            if y <= 9 and abs(dx) <= 3:
                continue  # cổ áo V
            lit = -dx * 0.08 - (y - 14) * 0.05
            if dx == -hw or dx == hw or y >= 24:
                col = C["bronze_d"]
            elif lit > 0.35:
                col = C["bronze_hi"]
            elif lit > 0.0:
                col = C["bronze_l"]
            elif lit > -0.35:
                col = C["bronze"]
            else:
                col = C["bronze_d"]
            _pp(img, x, y, col)
    # Viền thắt lưng đỏ-vàng
    _rect(img, 9, 20, 22, 21, C["red_d"])
    _rect(img, 10, 20, 21, 20, C["gold_l"])
    # Họa tiết mặt trời Đông Sơn ở giữa ngực
    _ring(img, 16, 14, 2.7, 3.8, C["gold_d"])
    _disc(img, 16, 14, 2.2, C["gold_l"])
    _pp(img, 15, 13, C["gold_hi"])
    for a_i in range(8):
        ang = a_i * math.pi / 4
        _pp(img, 16 + math.cos(ang) * 4.5, 14 + math.sin(ang) * 4.5, C["gold_hi"])
    # Đinh tán vai
    _pp(img, 7, 9, C["white"])
    _pp(img, 23, 9, C["gold_l"])
    return img


def draw_ruou_thuoc():
    img = _blank()
    # Bình hồ lô gốm men đỏ đựng rượu thuốc + dây đỏ + bùa chữ vàng
    # Bóng nền nhẹ
    _disc(img, 16, 25, 6, C["red_d"])
    # Thân dưới hồ lô
    _disc(img, 16, 20, 7.2, C["red_d"])
    _disc(img, 16, 20, 6.2, C["red"])
    _disc(img, 14, 18, 4.2, C["red_l"])
    # Thân trên hồ lô
    _disc(img, 16, 11, 4.5, C["red_d"])
    _disc(img, 16, 11, 3.6, C["red"])
    _disc(img, 14.5, 10, 2.0, C["red_l"])
    # Cổ bình & nút bần
    _rect(img, 14, 5, 17, 7, C["wood_l"])
    _pp(img, 14, 5, C["wood_hi"])
    _rect(img, 13, 7, 18, 8, C["gold_l"])
    # Dây lụa đỏ thắt eo hồ lô
    _rect(img, 12, 14, 19, 15, C["gold"])
    _line(img, 19, 14, 23, 18, C["red_l"])
    _line(img, 19, 15, 22, 20, C["red_d"])
    # Nhãn bùa hình thoi trên bụng bình
    for dy in range(-3, 4):
        hw = 3 - abs(dy)
        for dx in range(-hw, hw + 1):
            _pp(img, 16 + dx, 20 + dy, C["cream"] if abs(dx) < hw and abs(dy) < 3 else C["gold_l"])
    _line(img, 16, 18, 16, 22, C["red"])
    _line(img, 15, 20, 17, 20, C["red"])
    # Điểm lóe men gốm sáng
    _pp(img, 12, 17, C["white"])
    _pp(img, 12, 18, C["red_hi"])
    _pp(img, 13, 9, C["white"])
    # Khí rượu bốc lên
    _pp(img, 21, 7, C["fire_l"])
    _pp(img, 22, 5, C["fire_hi"])
    _pp(img, 10, 6, C["fire_l"])
    return img


def draw_ngua_o():
    img = _blank()
    # Đầu & cổ chiến mã ô dũng mãnh + bờm bay trong gió + dây cương đỏ-vàng
    # Vệt tốc độ xanh-trắng phía sau
    _line(img, 4, 10, 11, 10, C["blue_l"])
    _line(img, 3, 14, 10, 14, C["blue_hi"])
    _line(img, 5, 18, 11, 18, C["blue"])
    # Bờm ngựa bay về bên trái
    for k in range(5):
        _line(img, 14 - k, 7 + k * 2, 7 - k // 2, 9 + k * 2, C["ink_l"] if k % 2 == 0 else C["ink"])
        _pp(img, 11 - k, 8 + k * 2, C["ink_hi"])
    # Cổ & đầu ngựa
    for y in range(11, 27):
        x0 = 11 if y < 20 else 10
        x1 = 19 if y < 19 else 20
        for x in range(x0, x1 + 1):
            _pp(img, x, y, C["ink_hi"] if x < 14 else (C["ink_l"] if x < 17 else C["ink"]))
    # Mõm ngựa vươn sang phải
    for y in range(8, 17):
        x_end = 26 - max(0, (y - 12)) // 2
        for x in range(15, x_end + 1):
            if y == 8 and x > 20:
                continue
            col = C["ink_hi"] if (y < 11 and x < 23) else (C["ink_l"] if y < 14 else C["ink"])
            _pp(img, x, y, col)
    # Tai nhọn
    _line(img, 16, 8, 15, 4, C["ink_l"])
    _line(img, 17, 8, 17, 5, C["ink_hi"])
    _line(img, 19, 8, 19, 5, C["ink"])
    # Mắt rực sáng
    _pp(img, 20, 10, C["white"])
    _pp(img, 21, 10, C["gold_hi"])
    _pp(img, 24, 13, C["ink_hi"])  # lỗ mũi
    # Dây cương đỏ & khóa vàng
    _line(img, 16, 15, 24, 14, C["red_l"])
    _line(img, 16, 15, 12, 23, C["red"])
    _disc(img, 16, 15, 1.3, C["gold_hi"])
    return img


def draw_bua_ho_menh():
    img = _blank()
    # Lá bùa hộ mệnh Việt cổ: dây treo vàng, thân đỏ viền vàng, chữ triện & tua lụa
    _ring(img, 16, 5, 1.5, 2.8, C["gold_l"])
    _pp(img, 15, 3, C["gold_hi"])
    # Thân bùa
    _rect(img, 9, 7, 22, 22, C["gold_d"])
    _rect(img, 10, 8, 21, 21, C["red"])
    _rect(img, 11, 9, 20, 20, C["red_l"])
    # Lõi giấy vàng bên trong
    _rect(img, 12, 10, 19, 19, C["gold_hi"])
    _rect(img, 13, 11, 18, 18, C["cream"])
    # Nét triện chu sa
    _line(img, 13, 12, 18, 12, C["red"])
    _line(img, 16, 11, 16, 18, C["red"])
    _line(img, 13, 15, 18, 15, C["red"])
    _pp(img, 14, 17, C["red_d"])
    _pp(img, 18, 17, C["red_d"])
    # Tua lụa đỏ phía dưới
    _rect(img, 14, 22, 17, 23, C["gold_l"])
    for tx in (13, 15, 17, 19):
        _line(img, tx, 24, tx + (1 if tx > 16 else -1), 28, C["red_l"] if tx in (13, 15) else C["red"])
    # Sao bảo hộ
    _spark(img, 7, 11, C["blue_l"], C["white"], 1)
    _spark(img, 25, 17, C["gold_l"], C["white"], 1)
    return img


def draw_da_mai():
    img = _blank()
    # Khối đá mài nghiêng 3D + lưỡi kiếm thép mài tóe tia lửa vàng
    # Khối đá mài ở dưới
    for y in range(18, 27):
        for x in range(5, 25):
            if y < 21:
                col = C["stone_hi"] if x < 16 else C["stone_l"]
            elif y < 24:
                col = C["stone_l"] if x < 18 else C["stone"]
            else:
                col = C["stone_d"]
            _pp(img, x, y, col)
    # Vệt nước bóng trên mặt đá
    _line(img, 8, 19, 19, 19, C["blue_hi"])
    # Lưỡi gươm chéo đang mài
    for i in range(17):
        bx = 10 + i
        by = 20 - i
        _pp(img, bx, by, C["steel_hi"])
        _pp(img, bx + 1, by, C["steel_l"])
        _pp(img, bx + 2, by, C["steel_d"])
        _pp(img, bx, by - 1, C["white"])
    # Chuôi gươm ở góc dưới-trái
    _line(img, 7, 19, 12, 23, C["gold_l"], 2)
    _line(img, 6, 24, 9, 21, C["wood_l"], 2)
    _pp(img, 5, 25, C["gold_hi"])
    # Tia lửa mài bắn tung tóe
    _spark(img, 12, 18, C["fire_hi"], C["white"], 2)
    _pp(img, 8, 14, C["fire_l"])
    _pp(img, 10, 12, C["fire_hi"])
    _pp(img, 15, 13, C["fire_l"])
    _pp(img, 7, 17, C["fire"])
    return img


def draw_hoa_duoc():
    img = _blank()
    # Trái phá hỏa dược: cầu sắt đen bọc đai đồng đỏ, ngòi nổ cháy rực
    _disc(img, 15, 19, 8.5, C["ink_d"])
    _disc(img, 15, 19, 7.5, C["ink"])
    _disc(img, 13, 17, 4.5, C["ink_l"])
    # Đai sơn đỏ & đinh đồng
    for x in range(8, 23):
        if math.hypot(x - 15, 19 - 19) <= 7.6:
            _pp(img, x, 19, C["red"] if x > 14 else C["red_l"])
            _pp(img, x, 20, C["red_d"])
    for dx in (-4, 0, 4):
        _pp(img, 15 + dx, 19, C["gold_hi"])
    # Cổ trái phá & điểm sáng bóng
    _rect(img, 13, 10, 17, 12, C["steel"])
    _pp(img, 14, 10, C["steel_hi"])
    _pp(img, 11, 14, C["white"])
    _pp(img, 12, 14, C["ink_hi"])
    _pp(img, 11, 15, C["ink_hi"])
    # Ngòi cháy cong + chùm lửa nổ
    _line(img, 15, 10, 18, 7, C["lat"])
    _line(img, 18, 7, 22, 7, C["lat_l"])
    _disc(img, 24, 7, 3.0, C["fire"])
    _disc(img, 24, 7, 1.8, C["fire_hi"])
    _spark(img, 24, 7, C["fire_l"], C["white"], 3)
    _pp(img, 21, 3, C["fire_hi"])
    _pp(img, 27, 4, C["fire_l"])
    _pp(img, 27, 10, C["fire"])
    return img


def draw_tra_tim_sen():
    img = _blank()
    # Chén trà ngọc men lam trên đĩa gỗ + cánh sen hồng + tim sen xanh + khói hương
    # Đĩa lót gỗ
    for dx in range(-10, 11):
        _pp(img, 16 + dx, 25, C["wood_hi"] if dx < 0 else C["wood"])
        if abs(dx) <= 8:
            _pp(img, 16 + dx, 26, C["wood_d"])
    # Thân chén ngọc
    for y in range(15, 25):
        hw = 9 - max(0, y - 18) // 2 - (1 if y >= 23 else 0)
        for dx in range(-hw, hw + 1):
            if y == 15:
                col = C["jade_hi"] if dx < 2 else C["jade_l"]
            elif dx < -hw + 3:
                col = C["jade_hi"]
            elif dx < 2:
                col = C["jade_l"]
            elif dx < hw - 1:
                col = C["jade"]
            else:
                col = C["jade_d"]
            _pp(img, 16 + dx, y, col)
    # Mặt nước trà xanh ngọc & tim sen
    for dx in range(-7, 8):
        _pp(img, 16 + dx, 16, C["jade_d"])
        if abs(dx) <= 6:
            _pp(img, 16 + dx, 15, C["jade_l"])
    # Tim sen & cánh sen hồng nổi trên mặt trà
    _pp(img, 15, 15, C["leaf_hi"])
    _pp(img, 16, 14, C["leaf_hi"])
    _pp(img, 17, 15, C["leaf_l"])
    _pp(img, 13, 15, C["pink"])
    _pp(img, 12, 14, C["pink_hi"])
    _pp(img, 19, 15, C["pink_d"])
    # Làn khói thơm uốn lượn
    for i in range(8):
        _pp(img, 13 + int(round(math.sin(i * 0.9))), 12 - i, C["jade_hi"] if i < 4 else C["white"])
        _pp(img, 19 - int(round(math.sin(i * 0.9))), 11 - i, C["jade_l"] if i < 4 else C["jade_hi"])
    _pp(img, 10, 19, C["white"])
    return img


def draw_mat_than():
    img = _blank()
    # Mắt thần cánh vàng: khung mắt chạm cánh vàng + đồng tử lam phát quang
    # Cánh vàng hai bên
    for k in range(3):
        _line(img, 5 + k, 12 + k * 2, 10, 14 + k, C["gold_l"] if k == 0 else C["gold"])
        _line(img, 26 - k, 12 + k * 2, 21, 14 + k, C["gold_l"] if k == 0 else C["gold_d"])
    # Khung mắt hình hạnh nhân
    for x in range(7, 26):
        dx = abs(x - 16) / 9.0
        half_h = max(0.0, 5.5 * (1.0 - dx * dx))
        for y in range(int(16 - half_h - 1), int(16 + half_h + 2)):
            dist = abs(y - 16)
            if dist >= half_h - 0.6:
                _pp(img, x, y, C["gold_hi"] if y < 16 else C["gold_d"])
            else:
                _pp(img, x, y, C["white"] if y < 16 else C["steel_l"])
    # Mống mắt lam + con ngươi chí mạng đỏ-trắng
    _disc(img, 16, 16, 4.0, C["blue_d"])
    _disc(img, 16, 16, 3.0, C["blue"])
    _disc(img, 15, 15, 1.8, C["blue_l"])
    _line(img, 16, 13, 16, 19, C["ink_d"])
    _pp(img, 14, 14, C["white"])
    _pp(img, 16, 16, C["red_l"])
    # Tia sáng trên-dưới mắt
    _spark(img, 16, 7, C["gold_l"], C["white"], 2)
    _spark(img, 16, 24, C["blue_l"], C["white"], 1)
    return img


def draw_linh_khi():
    img = _blank()
    # Hai xoáy linh khí lam ngọc cuộn quanh tinh cầu năng lượng ở tâm
    for a_i in range(44):
        t = a_i / 43.0
        ang = t * math.pi * 2.4
        r = 11.5 * (1.0 - 0.72 * t)
        for arm, c1, c2 in [(0.0, C["blue"], C["blue_hi"]), (math.pi, C["blue_d"], C["blue_l"])]:
            px = 16 + math.cos(ang + arm) * r
            py = 16 + math.sin(ang + arm) * r
            _disc(img, px, py, 1.5 if t < 0.7 else 1.1, c2 if t > 0.45 else c1)
    # Tinh cầu lõi sáng
    _disc(img, 16, 16, 4.0, C["blue_l"])
    _disc(img, 16, 16, 2.5, C["blue_hi"])
    _disc(img, 15, 15, 1.3, C["white"])
    _spark(img, 7, 8, C["blue_l"], C["white"], 1)
    _spark(img, 24, 23, C["blue_hi"], C["white"], 1)
    return img


def draw_huyet_sam():
    img = _blank()
    # Củ huyết sâm nghìn năm: rễ đỏ-vàng sần sùi + lá xanh + chùm quả đỏ mọng
    # Lá sâm 3 nhánh
    for lx, ly in [(11, 10), (16, 8), (21, 10)]:
        _line(img, 16, 13, lx, ly, C["leaf_d"])
        _disc(img, lx, ly, 2.3, C["leaf"])
        _pp(img, lx - 1, ly - 1, C["leaf_hi"])
    # Chùm quả sâm đỏ tươi ở đỉnh
    for qx, qy in [(15, 7), (17, 7), (16, 5)]:
        _disc(img, qx, qy, 1.4, C["red"])
        _pp(img, qx - 1, qy - 1, C["white"])
    # Thân củ sâm
    for y in range(13, 23):
        hw = 3 if y < 20 else 2
        for dx in range(-hw, hw + 1):
            col = C["gold_hi"] if dx < -1 else (C["bronze_l"] if dx <= 1 else C["bronze_d"])
            _pp(img, 16 + dx, y, col)
    # Các rễ nhánh vươn xuống
    _line(img, 14, 21, 10, 26, C["bronze"], 2)
    _line(img, 10, 26, 8, 28, C["bronze_d"])
    _line(img, 16, 22, 16, 28, C["bronze_l"], 2)
    _line(img, 18, 21, 22, 26, C["bronze_d"], 2)
    _line(img, 22, 26, 24, 28, C["bronze_d"])
    # Vằn ngang củ sâm & tia hồi máu
    for ry in (15, 18, 20):
        _line(img, 14, ry, 18, ry, C["red_d"])
    _spark(img, 7, 17, C["red_l"], C["white"], 1)
    _spark(img, 25, 15, C["red_l"], C["white"], 1)
    return img


def draw_boi_thu():
    img = _blank()
    # Chồng đồng tiền cổ lỗ vuông lấp lánh + dải lụa đỏ chúc phúc
    _coin_at(img, 20, 12, 5)
    _coin_at(img, 11, 14, 5)
    _coin_at(img, 16, 21, 6)
    # Dải ruy băng đỏ vắt chéo
    _line(img, 8, 23, 14, 27, C["red_l"])
    _line(img, 24, 22, 18, 27, C["red"])
    _spark(img, 25, 7, C["gold_l"], C["white"], 2)
    _spark(img, 6, 9, C["gold_l"], C["white"], 1)
    _spark(img, 25, 25, C["gold_hi"], C["white"], 1)
    return img


def draw_giay_co():
    img = _blank()
    # Đôi giày cỏ bện rơm vàng gắn cánh gió thần tốc
    # Cánh trắng-vàng gắn ở gót
    for k in range(5):
        _line(img, 9, 13 + k, 4 + k, 7 + k * 2, C["white"] if k < 2 else C["gold_hi"])
        _line(img, 11, 15 + k, 6 + k, 10 + k * 2, C["gold_l"])
    # Đế giày bện rơm
    for x in range(7, 26):
        _pp(img, x, 24, C["wood_d"])
        _pp(img, x, 23, C["lat_d"] if x % 2 == 0 else C["wood"])
        _pp(img, x, 22, C["lat"] if x % 2 == 0 else C["lat_l"])
    # Thân giày & dây quai rơm đan
    for y in range(16, 22):
        x0 = 9 if y < 20 else 8
        x1 = 18 if y < 19 else 24
        for x in range(x0, x1 + 1):
            col = C["lat_hi"] if (x + y) % 3 == 0 else (C["lat"] if x < 19 else C["lat_d"])
            _pp(img, x, y, col)
    # Dây quai chéo
    _line(img, 15, 16, 21, 21, C["wood"])
    _line(img, 17, 17, 13, 21, C["wood_l"])
    # Vệt gió lướt
    _line(img, 20, 12, 27, 12, C["blue_hi"])
    _line(img, 22, 15, 28, 15, C["blue_l"])
    return img


def draw_ten_doi():
    img = _blank()
    # Hai mũi tên chiến song song bay chéo lên góc trên-phải
    for ox, oy in [(-4, -3), (4, 4)]:
        x0, y0 = 9 + ox, 22 + oy
        x1, y1 = 22 + ox, 9 + oy
        # Vệt khí động
        _line(img, x0 - 2, y0 + 2, x0 + 2, y0 - 2, C["blue_hi"])
        # Thân tên tre
        _line(img, x0, y0, x1, y1, C["wood_l"], 2)
        _line(img, x0, y0, x1, y1, C["lat_hi"], 1)
        # Lông vũ đuôi đỏ-vàng
        _line(img, x0, y0, x0 - 3, y0 - 1, C["red_l"])
        _line(img, x0, y0, x0 + 1, y0 + 3, C["red"])
        _line(img, x0 + 2, y0 - 2, x0 - 1, y0 - 3, C["gold_l"])
        _line(img, x0 + 2, y0 - 2, x0 + 3, y0 + 1, C["gold"])
        # Đầu mũi tên thép nhọn
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2 and (dx - dy >= -1):
                    _pp(img, x1 + dx + 1, y1 + dy - 1, C["white"] if dx + dy < 0 else C["steel_l"])
        _pp(img, x1 + 3, y1 - 3, C["white"])
    return img


def draw_khien_chan():
    img = _blank()
    # Khiên sắt tâm vàng phát sóng xung kích lam tỏa tròn
    # Vòng sóng chấn động ngoài
    _ring(img, 16, 16, 11.2, 12.6, C["blue"])
    _ring(img, 16, 16, 9.8, 10.6, C["blue_hi"])
    _shield_base(img, 16, 8, 7, 17, C["steel_d"], C["steel"], C["steel_l"], C["steel_hi"], C["steel_d"], C["steel_hi"])
    # Tâm chấn động vàng
    _disc(img, 16, 15, 3.0, C["gold_l"])
    _disc(img, 16, 15, 1.8, C["white"])
    for ang_i in range(4):
        ang = ang_i * math.pi / 2 + math.pi / 4
        _line(img, 16 + math.cos(ang) * 9, 15 + math.sin(ang) * 9,
              16 + math.cos(ang) * 13, 15 + math.sin(ang) * 13, C["blue_hi"])
    return img


def draw_ngoc_bich():
    img = _blank()
    # Ngọc bích bội hình bát giác vát cạnh + khung vàng + tua đỏ
    _ring(img, 16, 6, 1.2, 2.5, C["gold_l"])
    for y in range(8, 23):
        for x in range(9, 24):
            dx, dy = abs(x - 16), abs(y - 15)
            if dx + dy <= 10 and dx <= 6 and dy <= 7:
                if dx >= 5 or dy >= 6 or dx + dy >= 9:
                    col = C["jade_d"]
                elif (x - 16) + (y - 15) < -2:
                    col = C["jade_hi"]
                elif (x - 16) + (y - 15) < 2:
                    col = C["jade_l"]
                else:
                    col = C["jade"]
                _pp(img, x, y, col)
    # Lỗ tròn giữa ngọc bích viền vàng
    _ring(img, 16, 15, 1.8, 2.8, C["gold_l"])
    for y in range(14, 17):
        for x in range(15, 18):
            img.putpixel((x, y), (0, 0, 0, 0))
    # Điểm lóe ngọc & tua lụa đỏ dưới
    _pp(img, 12, 11, C["white"])
    _pp(img, 13, 11, C["jade_hi"])
    _rect(img, 15, 22, 17, 23, C["gold"])
    _line(img, 15, 24, 14, 28, C["red_l"])
    _line(img, 16, 24, 16, 29, C["red"])
    _line(img, 17, 24, 18, 28, C["red_d"])
    return img


def draw_ho_tam_kinh():
    img = _blank()
    # Hộ tâm kính: gương đồng bát giác trước ngực, tâm gương vàng ngà soi sáng, 4 đinh tán & dây đỏ
    # Dây lụa đỏ buộc hai bên
    _line(img, 5, 12, 8, 13, C["red_l"])
    _line(img, 5, 14, 8, 14, C["red"])
    _line(img, 26, 12, 23, 13, C["red_l"])
    _line(img, 26, 14, 23, 14, C["red"])
    # Khung đồng bát giác
    for y in range(6, 27):
        for x in range(6, 27):
            dx, dy = abs(x - 16), abs(y - 16)
            if dx <= 9 and dy <= 9 and dx + dy <= 14:
                is_outer = dx >= 7 or dy >= 7 or dx + dy >= 12
                if is_outer:
                    col = C["bronze_hi"] if (x - 16) + (y - 16) < -3 else (C["bronze_l"] if (x - 16) + (y - 16) < 4 else C["bronze_d"])
                else:
                    # Mặt gương đánh bóng phản chiếu chéo
                    diag = (x - 16) - (y - 16)
                    if -2 <= diag <= 1 and (x - 16) + (y - 16) < 4:
                        col = C["white"]
                    elif (x - 16) + (y - 16) < 1:
                        col = C["gold_hi"]
                    else:
                        col = C["gold_l"]
                _pp(img, x, y, col)
    # Vòng chạm khắc quanh mặt gương + 4 đinh đồng
    _ring(img, 16, 16, 5.5, 6.4, C["gold_d"])
    for rx, ry in [(10, 10), (22, 10), (10, 22), (22, 22)]:
        _pp(img, rx, ry, C["gold_hi"])
    _spark(img, 16, 16, C["gold_hi"], C["white"], 2)
    return img


def draw_dan_nay():
    img = _blank()
    # Tường đá bên trái + tia đạn vàng-cam lao tới dội bật sắc nét
    # Khối tường gạch đá
    for y in range(5, 27):
        for x in range(4, 11):
            mortar = (y % 6 == 0) or (x == 10)
            if mortar:
                col = C["stone_d"]
            elif x <= 6:
                col = C["stone_hi"] if y < 16 else C["stone_l"]
            else:
                col = C["stone_l"] if y < 18 else C["stone"]
            _pp(img, x, y, col)
    # Đường đạn lao vào (từ dưới-phải -> tường)
    _line(img, 24, 24, 11, 16, C["fire"], 2)
    _line(img, 24, 24, 11, 16, C["fire_l"], 1)
    # Đường đạn bật nảy (từ tường -> trên-phải)
    _line(img, 11, 16, 25, 8, C["fire_l"], 2)
    _line(img, 11, 16, 25, 8, C["fire_hi"], 1)
    # Đầu đạn rực sáng ở mũi bật
    _disc(img, 25, 8, 2.3, C["fire_hi"])
    _disc(img, 25, 8, 1.2, C["white"])
    # Tia va chạm tại tường
    _spark(img, 11, 16, C["fire_hi"], C["white"], 2)
    return img


def draw_xuyen_tam():
    img = _blank()
    # Mũi tên chí mạng đỏ-vàng xuyên thẳng qua vòng tâm mục tiêu
    # Vòng bia mục tiêu ở giữa
    _ring(img, 16, 16, 6.5, 8.2, C["steel_d"])
    _ring(img, 16, 16, 5.2, 6.5, C["steel_l"])
    _ring(img, 16, 16, 3.0, 4.5, C["red"])
    # Đuôi tên bên trái
    _line(img, 4, 16, 12, 16, C["gold_l"], 2)
    _line(img, 4, 14, 7, 16, C["red_l"])
    _line(img, 4, 18, 7, 16, C["red"])
    # Tia xuyên thủng + mũi tên chọc ra bên phải
    _line(img, 12, 16, 26, 16, C["fire_hi"], 2)
    _line(img, 15, 16, 27, 16, C["white"], 1)
    for dy in range(-3, 4):
        for dx in range(3 - abs(dy)):
            _pp(img, 24 + dx, 16 + dy, C["red_hi"] if dy <= 0 else C["red"])
    _pp(img, 27, 16, C["white"])
    _spark(img, 16, 16, C["red_l"], C["white"], 2)
    return img


def draw_khien_lua():
    img = _blank()
    # Khiên hỏa diệm viền vàng rực ngọn lửa bùng quanh
    # Ngọn lửa nền phía sau
    for fx, fy, r in [(9, 10, 3.2), (23, 10, 3.2), (16, 6, 3.4), (7, 17, 2.5), (25, 17, 2.5)]:
        _disc(img, fx, fy, r, C["fire"])
        _disc(img, fx, fy - 1, r * 0.55, C["fire_l"])
    _shield_base(img, 16, 9, 7, 17, C["red_d"], C["red"], C["fire"], C["fire_l"], C["gold_d"], C["gold_hi"])
    # Ấn ngọn lửa giữa mặt khiên
    _disc(img, 16, 17, 3.0, C["fire_l"])
    _line(img, 16, 12, 16, 18, C["fire_hi"], 2)
    _pp(img, 16, 11, C["white"])
    _pp(img, 14, 15, C["fire_hi"])
    _pp(img, 18, 16, C["fire_l"])
    return img


def draw_khien_doc():
    img = _blank()
    # Khiên độc ngọc lục bảo + khí độc tỏa & giọt nọc độc nhỏ xuống
    # Khí độc mờ quanh viền
    for px, py, r in [(8, 11, 2.6), (24, 12, 2.6), (10, 23, 2.2), (22, 23, 2.2)]:
        _disc(img, px, py, r, C["pois"])
    _shield_base(img, 16, 8, 7, 17, C["pois_d"], C["pois"], C["pois_l"], C["pois_hi"], C["ink"], C["pois_l"])
    # Ấn giọt độc sáng ở giữa
    _disc(img, 16, 17, 2.7, C["pois_hi"])
    _line(img, 16, 12, 16, 17, C["pois_hi"], 2)
    _pp(img, 15, 15, C["white"])
    # Giọt độc nhỏ xuống đáy
    _line(img, 16, 25, 16, 28, C["pois_l"])
    _pp(img, 16, 28, C["pois_hi"])
    return img


def draw_thuong_khach():
    img = _blank()
    # Kim bài Khách Quý: thẻ ngọc viền vàng khắc chữ, treo dải lụa đỏ
    _ring(img, 16, 6, 1.4, 2.6, C["gold_l"])
    # Dải lụa đỏ phía sau
    _line(img, 8, 10, 12, 14, C["red_l"], 2)
    _line(img, 24, 10, 20, 14, C["red"], 2)
    # Thẻ kim bài bát giác dài
    for y in range(8, 25):
        hw = 5 if (y == 8 or y == 24) else 7
        for dx in range(-hw, hw + 1):
            is_rim = abs(dx) >= hw - 1 or y <= 9 or y >= 23
            if is_rim:
                col = C["gold_hi"] if dx < 0 and y < 16 else (C["gold_l"] if y < 20 else C["gold_d"])
            else:
                col = C["red_l"] if dx + y < 26 else C["red"]
            _pp(img, 16 + dx, y, col)
    # Biểu tượng đồng tiền / vương miện vàng ở giữa thẻ
    _disc(img, 16, 16, 3.3, C["gold_l"])
    _pp(img, 15, 15, C["gold_hi"])
    _pp(img, 16, 16, C["red_d"])
    _spark(img, 24, 7, C["gold_l"], C["white"], 1)
    _spark(img, 7, 21, C["gold_hi"], C["white"], 1)
    return img


def draw_hut_nang_luong():
    img = _blank()
    # Hấp tinh đại pháp: hố hút năng lượng tím-lam xoáy tụ vào nhân sáng rực
    _disc(img, 16, 16, 10.5, C["purp_d"])
    _ring(img, 16, 16, 7.5, 9.5, C["blue_d"])
    for k in range(6):
        ang = k * math.pi / 3
        for s in range(7):
            t = s / 6.0
            a = ang + t * 1.3
            r = 12.0 - t * 8.5
            _pp(img, 16 + math.cos(a) * r, 16 + math.sin(a) * r, C["blue_hi"] if t > 0.5 else C["blue_l"])
    _disc(img, 16, 16, 3.6, C["blue_l"])
    _disc(img, 16, 16, 2.0, C["white"])
    _spark(img, 7, 7, C["purp_l"], C["white"], 1)
    _spark(img, 25, 24, C["blue_hi"], C["white"], 1)
    return img


def draw_kiem_phan_dan():
    img = _blank()
    # Thanh kiếm vung chéo tạo vòng kiếm khí lam chém hất ngược đạn địch đỏ
    # Vòng kiếm khí bán nguyệt
    for i in range(28):
        ang = -0.9 + (i / 27.0) * 2.2
        r = 10.5
        px = 13 + math.cos(ang) * r
        py = 16 + math.sin(ang) * r
        _disc(img, px, py, 1.4, C["blue_hi"] if i % 2 == 0 else C["blue_l"])
    # Thanh kiếm chéo
    for i in range(15):
        _pp(img, 8 + i, 22 - i, C["steel_hi"])
        _pp(img, 9 + i, 22 - i, C["steel_l"])
        _pp(img, 8 + i, 21 - i, C["white"])
    _line(img, 7, 19, 12, 24, C["gold_l"], 2)
    _line(img, 6, 24, 9, 21, C["wood_l"], 2)
    # Viên đạn địch đỏ đang bị đánh bật ngược sang phải
    _line(img, 22, 13, 27, 9, C["fire_hi"])
    _disc(img, 25, 11, 2.3, C["red_l"])
    _pp(img, 24, 10, C["white"])
    _spark(img, 20, 14, C["blue_hi"], C["white"], 2)
    return img


def draw_tich_luc():
    img = _blank()
    # Xung kích thế năng: nắm đấm / luồng sét tím-vàng cuộn tụ bùng nổ
    _ring(img, 16, 16, 10.0, 11.4, C["purp_l"])
    _disc(img, 16, 16, 8.2, C["purp_d"])
    _disc(img, 16, 16, 5.8, C["purp"])
    # Tia sét năng lượng vàng-trắng ở giữa
    pts = [(19, 6), (13, 14), (17, 14), (11, 25), (20, 16), (16, 16), (19, 6)]
    for i in range(len(pts) - 1):
        _line(img, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], C["gold_l"], 2)
    _line(img, 18, 8, 14, 14, C["white"])
    _line(img, 16, 15, 13, 22, C["white"])
    _spark(img, 8, 9, C["gold_hi"], C["white"], 1)
    _spark(img, 24, 22, C["purp_hi"], C["white"], 1)
    return img


def draw_noi_cong():
    img = _blank()
    # Nội công tâm pháp: ấn chưởng phát chưởng kình lam-trắng nhiều tầng sóng
    # 3 vòng chưởng kình đồng tâm
    _ring(img, 16, 16, 10.5, 12.2, C["blue"])
    _ring(img, 16, 16, 7.2, 8.8, C["blue_l"])
    _disc(img, 16, 16, 5.2, C["blue_hi"])
    # Bàn tay ấn chưởng ở tâm
    _rect(img, 14, 15, 18, 20, C["white"])
    for fx in (13, 15, 17, 19):
        _line(img, fx, 15, fx, 11, C["white"])
    _line(img, 18, 18, 21, 15, C["gold_hi"])
    # Hạt khí xoay quanh
    for k in range(4):
        ang = k * math.pi / 2 + 0.4
        _spark(img, 16 + math.cos(ang) * 11, 16 + math.sin(ang) * 11, C["gold_l"], C["white"], 1)
    return img


def draw_kim_giap():
    img = _blank()
    # Kim giáp tài lộc: khiên hoàng kim nạm ngọc đỏ & đồng tiền cổ
    _shield_base(img, 16, 7, 8, 19, C["gold_d"], C["gold"], C["gold_l"], C["gold_hi"], C["bronze_d"], C["gold_hi"])
    # Đồng tiền lỗ vuông khắc giữa mặt khiên
    _coin_at(img, 16, 15, 4)
    # Viên ngọc đỏ đỉnh khiên
    _disc(img, 16, 9, 1.5, C["red_l"])
    _pp(img, 15, 8, C["white"])
    _spark(img, 7, 10, C["gold_l"], C["white"], 1)
    _spark(img, 25, 11, C["gold_l"], C["white"], 1)
    _spark(img, 16, 27, C["gold_hi"], C["white"], 1)
    return img


def draw_loi_dinh():
    img = _blank()
    # Lôi đình thiên phạt: mây giông tím đen + 3 tia Thiên Lôi giáng xuống
    # Đám mây giông phía trên
    for cx, cy, r in [(11, 9, 3.6), (16, 8, 4.4), (21, 10, 3.4)]:
        _disc(img, cx, cy, r, C["ink"])
        _disc(img, cx - 1, cy - 1, r * 0.65, C["purp"])
    _pp(img, 14, 6, C["ink_hi"])
    # Tia sét chính giữa + 2 tia nhảy chuyền trái/phải
    _line(img, 16, 11, 13, 17, C["gold_l"], 2)
    _line(img, 13, 17, 17, 17, C["white"], 2)
    _line(img, 17, 17, 14, 26, C["gold_hi"], 2)
    _line(img, 16, 12, 14, 17, C["white"], 1)
    # Tia nhánh trái & phải
    _line(img, 13, 17, 8, 24, C["blue_l"])
    _pp(img, 8, 25, C["white"])
    _line(img, 17, 17, 23, 24, C["blue_l"])
    _pp(img, 23, 25, C["white"])
    _spark(img, 14, 26, C["gold_l"], C["white"], 2)
    return img


def draw_phi_kiem():
    img = _blank()
    # Ngự kiếm phi hành: thanh phi kiếm ngọc bích bay lơ lửng + vòng kiếm khí quỹ đạo
    # Vòng quỹ đạo kiếm bay
    for i in range(28):
        ang = (i / 28.0) * math.pi * 2
        px = 16 + math.cos(ang) * 10.5
        py = 17 + math.sin(ang) * 4.2
        _pp(img, px, py, C["jade_hi"] if math.sin(ang) > 0 else C["jade"])
    # Lưỡi phi kiếm thẳng đứng ở giữa
    for y in range(6, 21):
        _pp(img, 15, y, C["white"] if y < 14 else C["jade_hi"])
        _pp(img, 16, y, C["steel_hi"])
        _pp(img, 17, y, C["jade_l"])
    _pp(img, 16, 4, C["white"])
    _pp(img, 16, 5, C["jade_hi"])
    # Chắn tay vàng hình cánh tiên & chuôi ngọc + tua đỏ
    _line(img, 11, 20, 21, 20, C["gold_l"], 2)
    _pp(img, 10, 19, C["gold_hi"])
    _pp(img, 22, 19, C["gold_hi"])
    _line(img, 16, 21, 16, 25, C["jade_d"], 2)
    _pp(img, 16, 26, C["gold_hi"])
    _line(img, 16, 27, 15, 29, C["red_l"])
    _spark(img, 8, 9, C["jade_hi"], C["white"], 1)
    _spark(img, 24, 11, C["jade_hi"], C["white"], 1)
    return img


def draw_ngu_hanh():
    img = _blank()
    # Ngũ hành tương sinh: vòng trận vàng liên kết 3 viên ngọc Hỏa (đỏ) - Độc (lục) - Lôi (lam)
    pts = [(16, 8), (9, 22), (23, 22)]
    _ring(img, 16, 17, 7.6, 8.6, C["gold"])
    for i in range(3):
        p0, p1 = pts[i], pts[(i + 1) % 3]
        _line(img, p0[0], p0[1], p1[0], p1[1], C["gold_l"])
    # Tâm thái cực sáng
    _disc(img, 16, 17, 2.5, C["gold_hi"])
    _pp(img, 16, 17, C["white"])
    # 3 viên ngọc nguyên tố
    gems = [
        (16, 8, C["fire_d"], C["fire"], C["fire_hi"]),
        (9, 22, C["pois_d"], C["pois"], C["pois_hi"]),
        (23, 22, C["blue_d"], C["blue"], C["blue_hi"]),
    ]
    for gx, gy, cd, cm, chi in gems:
        _disc(img, gx, gy, 3.6, cd)
        _disc(img, gx, gy, 2.7, cm)
        _disc(img, gx - 0.8, gy - 0.8, 1.3, chi)
        _pp(img, gx - 1, gy - 1, C["white"])
    return img


def draw_huyet_nguyet():
    img = _blank()
    # Huyết nguyệt cuồng chiến: vầng trăng khuyết đỏ rực + lưỡi đao chiến cắt ngang
    # Hào quang trăng máu
    _disc(img, 14, 16, 9.6, C["red_d"])
    for y in range(6, 27):
        for x in range(5, 26):
            d1 = math.hypot(x - 14, y - 16)
            d2 = math.hypot(x - 19, y - 15)
            if d1 <= 9.2 and d2 >= 6.8:
                if d1 > 7.5 or x < 8:
                    col = C["red_hi"] if y < 14 else C["red_l"]
                else:
                    col = C["red_l"] if y < 17 else C["red"]
                _pp(img, x, y, col)
    # Lưỡi kiếm/đao cuồng chiến cắt chéo trước mặt trăng
    for i in range(15):
        _pp(img, 13 + i, 23 - i, C["steel_hi"])
        _pp(img, 14 + i, 23 - i, C["white"])
        _pp(img, 13 + i, 24 - i, C["red_l"])
    _line(img, 11, 21, 15, 25, C["gold_l"], 2)
    _line(img, 9, 26, 12, 23, C["ink_l"], 2)
    _spark(img, 24, 9, C["red_hi"], C["white"], 1)
    _spark(img, 7, 10, C["red_l"], C["white"], 1)
    return img


def draw_phan_tach():
    img = _blank()
    # Đạn phân tách: mũi đạn cam-vàng bắn vào lăng kính giữa rồi tách thành 2 tia sáng rực
    _line(img, 4, 16, 14, 16, C["fire"], 2)
    _line(img, 6, 16, 14, 16, C["fire_hi"], 1)
    # Tinh thể phân tách giữa
    for dy in range(-4, 5):
        hw = 4 - abs(dy)
        for dx in range(-hw, hw + 1):
            col = C["white"] if abs(dx) + abs(dy) <= 1 else (C["blue_hi"] if dx < 0 else C["blue_l"])
            _pp(img, 15 + dx, 16 + dy, col)
    # Hai mảnh đạn tách góc trên/dưới phải
    _line(img, 17, 15, 26, 8, C["fire_l"], 2)
    _line(img, 17, 15, 26, 8, C["fire_hi"], 1)
    _disc(img, 26, 8, 2.1, C["fire_hi"])
    _pp(img, 26, 8, C["white"])
    _line(img, 17, 17, 26, 24, C["fire_l"], 2)
    _line(img, 17, 17, 26, 24, C["fire_hi"], 1)
    _disc(img, 26, 24, 2.1, C["fire_hi"])
    _pp(img, 26, 24, C["white"])
    _spark(img, 15, 16, C["gold_hi"], C["white"], 2)
    return img


def draw_khuc_xa():
    img = _blank()
    # Khúc xạ liên hoàn: tia sáng lam-vàng bật dội giữa 2 mặt gương đá trên/dưới
    _rect(img, 5, 5, 26, 8, C["stone"])
    _rect(img, 6, 6, 25, 7, C["stone_hi"])
    _rect(img, 5, 23, 26, 26, C["stone_d"])
    _rect(img, 6, 24, 25, 25, C["stone_l"])
    # Đường đạn zig-zag 3 đoạn
    pts = [(5, 19), (12, 9), (20, 22), (27, 12)]
    for i in range(len(pts) - 1):
        _line(img, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], C["blue"], 2)
        _line(img, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], C["blue_hi"], 1)
    _spark(img, 12, 9, C["gold_hi"], C["white"], 2)
    _spark(img, 20, 22, C["gold_hi"], C["white"], 2)
    _disc(img, 27, 12, 2.0, C["white"])
    return img


def draw_bang_tam():
    img = _blank()
    # Băng tâm hàn khí: tinh thể băng lục giác sắc cạnh với lõi trắng sáng & bông tuyết
    for y in range(6, 27):
        for x in range(6, 27):
            dx, dy = abs(x - 16), abs(y - 16)
            if dx <= 8 and dy <= 9 and dx + dy <= 12:
                if dx >= 6 or dy >= 7 or dx + dy >= 10:
                    col = C["blue_d"]
                elif (x - 16) + (y - 16) < -2:
                    col = C["white"]
                elif (x - 16) + (y - 16) < 3:
                    col = C["blue_hi"]
                else:
                    col = C["blue_l"]
                _pp(img, x, y, col)
    # Gân tuyết 6 hướng
    for ang_i in range(6):
        ang = ang_i * math.pi / 3
        _line(img, 16, 16, 16 + math.cos(ang) * 10.5, 16 + math.sin(ang) * 10.5, C["white"])
    _disc(img, 16, 16, 2.6, C["blue_hi"])
    _pp(img, 16, 16, C["white"])
    _spark(img, 7, 9, C["blue_hi"], C["white"], 1)
    _spark(img, 25, 22, C["blue_hi"], C["white"], 1)
    return img


def draw_cuong_no_trum():
    img = _blank()
    # Cuồng nộ diệt trùm: vương miện/đầu sừng trùm đỏ sẫm bị thanh kiếm vàng chém xuyên
    # Sừng trùm hai bên
    _line(img, 9, 13, 5, 6, C["gold_l"], 2)
    _line(img, 23, 13, 27, 6, C["gold"], 2)
    # Đầu lâu/giáp trùm đỏ
    _disc(img, 16, 17, 7.2, C["red_d"])
    _disc(img, 16, 16, 6.0, C["red"])
    _pp(img, 13, 15, C["fire_hi"])
    _pp(img, 19, 15, C["fire_hi"])
    _rect(img, 13, 20, 19, 23, C["cream"])
    _pp(img, 15, 20, C["ink_d"])
    _pp(img, 17, 20, C["ink_d"])
    # Thanh kiếm vàng chém chéo xuyên qua
    for i in range(18):
        _pp(img, 7 + i, 24 - i, C["gold_hi"])
        _pp(img, 8 + i, 24 - i, C["white"])
        _pp(img, 7 + i, 25 - i, C["gold"])
    _line(img, 6, 21, 10, 25, C["bronze_l"], 2)
    _spark(img, 16, 16, C["fire_l"], C["white"], 2)
    return img


def draw_song_kiem_hop():
    img = _blank()
    # Tam binh hợp bích: 3 thanh binh khí (ngọc, đỏ, vàng) đan chéo quanh ấn sao vàng
    # Kiếm 1 (trái dưới -> phải trên)
    _line(img, 7, 24, 24, 7, C["steel_hi"], 2)
    _line(img, 6, 20, 10, 24, C["jade_l"], 2)
    # Kiếm 2 (phải dưới -> trái trên)
    _line(img, 24, 24, 7, 7, C["steel_l"], 2)
    _line(img, 21, 24, 25, 20, C["red_l"], 2)
    # Thanh thứ 3 dựng thẳng giữa (vàng rực)
    _line(img, 16, 26, 16, 5, C["gold_hi"], 2)
    _line(img, 12, 22, 20, 22, C["gold"], 2)
    _pp(img, 16, 4, C["white"])
    # Ấn sao vàng ở giao điểm
    _disc(img, 16, 15, 3.2, C["gold_d"])
    _disc(img, 16, 15, 2.2, C["gold_hi"])
    _spark(img, 16, 15, C["white"], C["white"], 2)
    return img


def draw_tuong_thach():
    img = _blank()
    # Tường thạch hộ thân: khiên đá chạm cổ ngữ + 2 phiến đá hộ vệ bay hai bên
    _shield_base(img, 16, 7, 7, 18, C["stone_d"], C["stone"], C["stone_l"], C["stone_hi"], C["bronze_d"], C["gold_l"])
    # Cổ ngữ vàng ở giữa khiên đá
    _ring(img, 16, 15, 2.0, 3.2, C["gold_l"])
    _pp(img, 16, 15, C["gold_hi"])
    # 2 phiến đá lơ lửng trái/phải
    _rect(img, 4, 11, 7, 20, C["stone_l"])
    _rect(img, 5, 12, 6, 18, C["stone_hi"])
    _rect(img, 24, 11, 27, 20, C["stone"])
    _rect(img, 25, 12, 26, 18, C["stone_l"])
    _spark(img, 6, 9, C["gold_l"], C["white"], 1)
    _spark(img, 26, 9, C["gold_l"], C["white"], 1)
    return img


def draw_chien_xa_ben():
    img = _blank()
    # Chiến xa bất khuất: đầu giáp chiến xa đồng đỏ + ngà sắt húc + cờ đỏ
    # Bánh/đế thép
    _rect(img, 6, 22, 25, 26, C["ink"])
    for wx in (9, 16, 23):
        _disc(img, wx, 24, 2.0, C["steel_l"])
    # Thân giáp đỏ-đồng
    _rect(img, 7, 12, 24, 22, C["bronze"])
    _rect(img, 8, 13, 23, 18, C["red"])
    _rect(img, 9, 13, 22, 14, C["gold_hi"])
    # Đôi ngà thép húc phía trước
    _line(img, 22, 19, 28, 15, C["steel_hi"], 2)
    _line(img, 21, 21, 27, 19, C["steel_l"], 2)
    _pp(img, 28, 14, C["white"])
    # Cờ hiệu đỏ sau lưng
    _line(img, 10, 5, 10, 12, C["gold_l"])
    _rect(img, 10, 5, 16, 9, C["red_l"])
    _pp(img, 13, 7, C["gold_hi"])
    return img


def draw_lien_kich_ba():
    img = _blank()
    # Liên kích tam đoạn: 3 vòng trảm khí tầng lớp (đồng -> lửa vàng -> trăng lam trắng 360°)
    _ring(img, 16, 16, 10.2, 12.2, C["blue_hi"])
    for i in range(22):
        ang = -0.6 + (i / 21.0) * 2.5
        _disc(img, 15 + math.cos(ang) * 8.0, 16 + math.sin(ang) * 8.0, 1.3, C["fire_hi"] if i % 2 == 0 else C["fire_l"])
    for i in range(16):
        ang = 1.4 + (i / 15.0) * 2.2
        _disc(img, 16 + math.cos(ang) * 5.2, 16 + math.sin(ang) * 5.2, 1.1, C["gold_hi"])
    # Lõi thanh kiếm chém ngang
    _line(img, 8, 22, 23, 9, C["white"], 2)
    _line(img, 7, 19, 11, 23, C["gold_l"], 2)
    _spark(img, 23, 9, C["blue_hi"], C["white"], 2)
    return img


DRAWERS = {
    "banh_chung": draw_banh_chung,
    "giap_dong": draw_giap_dong,
    "ruou_thuoc": draw_ruou_thuoc,
    "ngua_o": draw_ngua_o,
    "bua_ho_menh": draw_bua_ho_menh,
    "da_mai": draw_da_mai,
    "hoa_duoc": draw_hoa_duoc,
    "tra_tim_sen": draw_tra_tim_sen,
    "mat_than": draw_mat_than,
    "linh_khi": draw_linh_khi,
    "huyet_sam": draw_huyet_sam,
    "boi_thu": draw_boi_thu,
    "giay_co": draw_giay_co,
    "ten_doi": draw_ten_doi,
    "khien_chan": draw_khien_chan,
    "ngoc_bich": draw_ngoc_bich,
    "ho_tam_kinh": draw_ho_tam_kinh,
    "dan_nay": draw_dan_nay,
    "xuyen_tam": draw_xuyen_tam,
    "khien_lua": draw_khien_lua,
    "khien_doc": draw_khien_doc,
    "thuong_khach": draw_thuong_khach,
    "hut_nang_luong": draw_hut_nang_luong,
    "kiem_phan_dan": draw_kiem_phan_dan,
    "tich_luc": draw_tich_luc,
    "noi_cong": draw_noi_cong,
    "kim_giap": draw_kim_giap,
    "loi_dinh": draw_loi_dinh,
    "phi_kiem": draw_phi_kiem,
    "ngu_hanh": draw_ngu_hanh,
    "huyet_nguyet": draw_huyet_nguyet,
    "phan_tach": draw_phan_tach,
    "khuc_xa": draw_khuc_xa,
    "bang_tam": draw_bang_tam,
    "cuong_no_trum": draw_cuong_no_trum,
    "song_kiem_hop": draw_song_kiem_hop,
    "tuong_thach": draw_tuong_thach,
    "chien_xa_ben": draw_chien_xa_ben,
    "lien_kich_ba": draw_lien_kich_ba,
}


def build():
    for k, fn in DRAWERS.items():
        img = fn()
        save(outline(img, DARK_LINE), f"ui/buff_{k}.png")
    art_v20_world.build()


if __name__ == "__main__":
    build()
