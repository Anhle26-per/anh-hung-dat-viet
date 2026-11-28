"""Đồ họa vật thể & cây cối hầm ngục thường phủ nhiều lớp bóng đổ (4-tone hue-shifted pixel art):
- Cây đào Tết 4 khung rung gió + hoa nổi khối sáng/tối: world/peach.png (36x40 -> 144x40)
- Khóm tre ngà 4 khung đung đưa + lá rậm 4 sắc độ: world/bamboo.png (28x36 -> 112x36)
- Vật cản & đạo cụ phủ bóng khối: pot (18x20), crate (20x20), sandbag (26x16), stele (24x34),
  pillar (22x32), cover_wall_h (48x24), cover_wall_v (20x44), barrel_boom 4f (18x22 -> 72x22)
- Trang trí phòng: torch 4f (12x22 -> 48x22), banner 4f (16x28 -> 64x28), lantern 4f (14x20 -> 56x20), drum_floor (44x44)
"""
import math
import random
from px import hexc, outline, save, sheet, canvas, DARK_LINE

C = {k: hexc(v) for k, v in {
    "bark_hi": "8e6244", "bark_l": "6e482e", "bark": "4c3020", "bark_d": "2e1c16",
    "pink_hi": "fff0f6", "pink_l": "ffc2da", "pink": "ea78a4", "pink_d": "a83c6c",
    "bam_hi": "c8e068", "bam_l": "98be46", "bam": "6c9032", "bam_d": "425e1e",
    "leaf_hi": "bce86c", "leaf_l": "84c448", "leaf": "4c8c30", "leaf_d": "28561e",
    "wood_hi": "e4b274", "wood_l": "bc7e48", "wood": "86502a", "wood_d": "4e2c1a",
    "stone_hi": "c8c2dc", "stone_l": "948eb0", "stone": "605a78", "stone_d": "363048",
    "ceramic_hi": "ffffff", "ceramic_l": "ece8f8", "ceramic": "c8c2de", "ceramic_d": "8c86aa",
    "cobalt_l": "4e86e4", "cobalt": "2a58b4", "cobalt_d": "1a3474",
    "sand_hi": "f4deb0", "sand_l": "d6b67c", "sand": "a68452", "sand_d": "684e30",
    "red_hi": "ff9e8e", "red_l": "eb4c46", "red": "b82430", "red_d": "681422",
    "gold_hi": "fff6b0", "gold_l": "ffd452", "gold": "d48824", "gold_d": "784414",
    "steel_hi": "f0f6ff", "steel_l": "b4c4e0", "steel": "7282a2", "steel_d": "3a445e",
    "fire_hi": "fff69c", "fire_l": "ffaa34", "fire": "e85224", "fire_d": "9a1e18",
    "ink_d": "1a1424", "white": "ffffff",
}.items()}


def _pp(img, x, y, col):
    w, h = img.size
    ix, iy = int(round(x)), int(round(y))
    if 1 <= ix < w - 1 and 1 <= iy < h - 1:
        img.putpixel((ix, iy), col)


def _rect(img, x0, y0, x1, y1, col):
    for y in range(int(round(y0)), int(round(y1)) + 1):
        for x in range(int(round(x0)), int(round(x1)) + 1):
            _pp(img, x, y, col)


def _disc(img, cx, cy, r, col):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                _pp(img, x, y, col)


def _shaded_disc(img, cx, cy, r, c_hi, c_l, c_m, c_d):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r2:
                lum = (-dx * 0.55 - dy * 0.82) / max(1.0, r)
                col = c_hi if lum > 0.50 else (c_l if lum > 0.12 else (c_m if lum > -0.35 else c_d))
                _pp(img, x, y, col)


def _line(img, x0, y0, x1, y1, col, thick=1):
    steps = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) * 2.5))
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        if thick <= 1:
            _pp(img, x, y, col)
        else:
            _disc(img, x, y, thick * 0.5, col)


def _spark(img, cx, cy, col, core=None, sz=1):
    _pp(img, cx, cy, core or C["white"])
    for d in range(1, sz + 1):
        _pp(img, cx - d, cy, col)
        _pp(img, cx + d, cy, col)
        _pp(img, cx, cy - d, col)
        _pp(img, cx, cy + d, col)


# ==================================================================== Cây cối 4 khung (độ sâu khối & đổ bóng tán)
def build_trees():
    # 1. peach.png (36x40, 4f) - Cây đào Tết với gốc xù xì 4 tầng & tán hoa khối cầu có bóng dưới tán
    fr = []
    clusters = [
        (18, 12, 8.2), (10, 15, 6.2), (26, 15, 6.0),
        (14, 9, 5.4), (23, 9, 5.2), (18, 17, 5.8),
    ]
    petals_seed = [(8, 22), (27, 21), (15, 25), (22, 26), (11, 19)]
    for f in range(4):
        img, _ = canvas(36, 40)
        sw = [0, 1, 0, -1][f]
        # Rễ & thân cây 3 lớp vỏ cây sáng/tối
        _line(img, 14, 37, 17, 34, C["bark_d"], 2)
        _line(img, 22, 37, 19, 34, C["bark_d"], 2)
        _line(img, 18, 37, 18, 20, C["bark"], 4)
        _line(img, 17, 36, 17, 20, C["bark_l"], 2)
        _line(img, 19, 36, 19, 21, C["bark_d"], 2)
        _pp(img, 16, 29, C["bark_hi"])
        _pp(img, 17, 24, C["bark_hi"])
        # Cành vươn
        _line(img, 18, 23, 10 + sw * 0.5, 16, C["bark"], 2)
        _line(img, 18, 22, 26 + sw * 0.5, 16, C["bark"], 2)
        _line(img, 18, 20, 18 + sw * 0.4, 11, C["bark_l"], 2)
        # Bóng đổ tối phía dưới tán cây
        for cx, cy, rad in clusters:
            _disc(img, cx + sw + 1, cy + 2, rad, C["pink_d"])
        for cx, cy, rad in clusters:
            _shaded_disc(img, cx + sw, cy, rad, C["pink_hi"], C["pink_l"], C["pink"], C["pink_d"])
        # Nhụy hoa vàng & chấm sáng lấp lánh
        for cx, cy, rad in clusters[:4]:
            _pp(img, cx + sw - 1, cy - 1, C["gold_hi"])
            _pp(img, cx + sw + 2, cy, C["pink_hi"])
        # Cánh hoa rơi lất phất
        for idx, (px0, py0) in enumerate(petals_seed):
            if (idx + f) % 2 == 0:
                _pp(img, px0 + sw, py0 + (f * 2) % 6, C["pink_l"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/peach.png")

    # 2. bamboo.png (28x36, 4f) - Khóm tre 5 thân có đốt + tán lá 4 sắc độ xanh rậm rạp
    fr = []
    culms = [(7, 28, -1), (11, 33, 0), (15, 34, 0), (19, 30, 1), (22, 25, 1)]
    for f in range(4):
        img, _ = canvas(28, 36)
        sw = [0, 1, 0, -1][f]
        for bx, bh, lean in culms:
            top_x = bx + sw + lean
            top_y = 34 - bh
            _line(img, bx, 34, top_x, top_y, C["bam"], 2)
            _line(img, bx - 0.5, 33, top_x - 0.5, top_y, C["bam_l"], 1)
            for ny in range(top_y + 4, 33, 5):
                t = (ny - top_y) / max(1.0, float(bh))
                nx = top_x * (1.0 - t) + bx * t
                _line(img, nx - 1, ny, nx + 1, ny, C["bam_d"], 1)
                _pp(img, nx, ny - 1, C["bam_hi"])
        # Chùm lá tre có lớp tối làm nền & lớp sáng phía trên
        foliage = [(9, 10, 4.5), (15, 8, 5.0), (20, 11, 4.2), (12, 14, 4.0), (18, 15, 3.8)]
        for cx, cy, r in foliage:
            _disc(img, cx + sw + 1, cy + 1, r, C["leaf_d"])
        for cx, cy, r in foliage:
            _shaded_disc(img, cx + sw, cy, r, C["leaf_hi"], C["leaf_l"], C["leaf"], C["leaf_d"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/bamboo.png")


# ==================================================================== Vật cản & Đạo cụ phủ bóng khối
def build_covers_and_decor():
    # 1. pot.png (18x20) - Chum gốm Bát Tràng men lam rạn bóng
    img, _ = canvas(18, 20)
    _shaded_disc(img, 9, 12, 6.2, C["ceramic_hi"], C["ceramic_l"], C["ceramic"], C["ceramic_d"])
    _rect(img, 6, 4, 11, 6, C["ceramic_l"])
    _rect(img, 5, 3, 12, 4, C["ceramic_hi"])
    _line(img, 6, 3, 11, 3, C["cobalt_l"], 1)
    # Hoa văn rồng/sóng men lam quanh thân
    _line(img, 4, 11, 13, 11, C["cobalt"], 1)
    for hx in (5, 9, 12):
        _pp(img, hx, 10, C["cobalt_l"])
        _pp(img, hx + 1, 12, C["cobalt_d"])
    _rect(img, 6, 17, 11, 18, C["ceramic_d"])
    save(outline(img, DARK_LINE), "world/pot.png")

    # 2. crate.png (20x20) - Thùng gỗ lim đóng đinh đồng có vát góc khối
    img, _ = canvas(20, 20)
    _rect(img, 3, 3, 16, 17, C["wood_d"])
    _rect(img, 4, 4, 15, 7, C["wood_l"])
    _rect(img, 4, 4, 14, 5, C["wood_hi"])
    _rect(img, 4, 8, 15, 16, C["wood"])
    _rect(img, 5, 9, 10, 15, C["wood_l"])
    # Khung giằng & thanh chéo có ánh sáng cạnh trên
    _line(img, 4, 8, 15, 16, C["wood_d"], 1)
    _line(img, 15, 8, 4, 16, C["wood_d"], 1)
    _line(img, 5, 8, 14, 15, C["wood_hi"], 1)
    _rect(img, 3, 3, 16, 4, C["steel"])
    _rect(img, 3, 15, 16, 16, C["steel_d"])
    for rx, ry in ((4, 4), (15, 4), (4, 16), (15, 16)):
        _pp(img, rx, ry, C["gold_l"])
    save(outline(img, DARK_LINE), "world/crate.png")

    # 3. sandbag.png (26x16) - Ụ bao cát 2 tầng may chỉ khâu có bóng gấp nếp
    img, _ = canvas(26, 16)
    bags = [(2, 9, 9, 14), (10, 9, 17, 14), (17, 9, 24, 14), (5, 4, 13, 9), (13, 4, 21, 9)]
    for x0, y0, x1, y1 in bags:
        _rect(img, x0, y0, x1, y1, C["sand_d"])
        _rect(img, x0 + 1, y0, x1 - 1, y1 - 1, C["sand"])
        _rect(img, x0 + 1, y0, x1 - 2, y0 + 1, C["sand_hi"])
        _line(img, x0 + 2, y0 + 2, x1 - 3, y0 + 2, C["sand_l"], 1)
        _pp(img, x0 + 1, y0 + 2, C["wood_d"])
        _pp(img, x1 - 1, y0 + 2, C["wood_d"])
    save(outline(img, DARK_LINE), "world/sandbag.png")

    # 4. stele.png (24x34) - Bia đá rêu phong chạm chữ vàng trên lưng rùa đá
    img, _ = canvas(24, 34)
    # Đế rùa đá
    _rect(img, 4, 26, 19, 31, C["stone_d"])
    _rect(img, 5, 25, 18, 28, C["stone"])
    _rect(img, 6, 25, 15, 26, C["stone_hi"])
    # Thân bia
    _rect(img, 6, 6, 17, 25, C["stone_d"])
    _rect(img, 7, 7, 16, 24, C["stone"])
    _rect(img, 7, 7, 12, 22, C["stone_l"])
    _rect(img, 8, 5, 15, 7, C["stone_hi"])
    # Hoa văn vàng khắc giữa bia & rêu xanh góc
    for ky in range(10, 21, 3):
        _line(img, 9, ky, 14, ky, C["gold_l"] if ky == 10 else C["gold"], 1)
    _disc(img, 7, 23, 2.0, C["leaf"])
    _pp(img, 6, 22, C["leaf_l"])
    _disc(img, 16, 9, 1.5, C["leaf"])
    save(outline(img, DARK_LINE), "world/stele.png")

    # 5. pillar.png (22x32) - Cột đá đình chạm rồng đồng vàng
    img, _ = canvas(22, 32)
    _rect(img, 4, 26, 17, 30, C["stone_d"])
    _rect(img, 5, 25, 16, 27, C["stone_l"])
    _rect(img, 6, 7, 15, 25, C["stone_d"])
    _rect(img, 7, 7, 14, 24, C["stone"])
    _rect(img, 7, 7, 10, 23, C["stone_hi"])
    # Đai đồng vàng & đầu cột chạm khắc
    _rect(img, 4, 3, 17, 7, C["stone_l"])
    _rect(img, 5, 3, 15, 4, C["stone_hi"])
    _rect(img, 6, 11, 15, 13, C["gold"])
    _rect(img, 7, 11, 12, 12, C["gold_hi"])
    _rect(img, 6, 19, 15, 21, C["gold_d"])
    _pp(img, 9, 19, C["gold_l"])
    save(outline(img, DARK_LINE), "world/pillar.png")

    # 6. cover_wall_h.png (48x24) - Đoạn tường chắn ngang chạm đá & rêu
    img, _ = canvas(48, 24)
    _rect(img, 2, 3, 45, 21, C["stone_d"])
    # Mái đá đỉnh tường
    _rect(img, 2, 3, 45, 7, C["stone_l"])
    _rect(img, 3, 3, 44, 4, C["stone_hi"])
    # Hàng gạch so le 2 lớp
    for r, y0 in enumerate((8, 14)):
        off = 5 if r else 0
        for bx in range(3 - off, 44, 10):
            x0 = max(3, bx)
            x1 = min(44, bx + 8)
            _rect(img, x0, y0, x1, y0 + 4, C["stone"] if r == 0 else C["stone_d"])
            _line(img, x0, y0, x1, y0, C["stone_l"], 1)
    # Rêu mọc trên khe đá
    _disc(img, 11, 15, 2.2, C["leaf"])
    _pp(img, 10, 14, C["leaf_l"])
    _disc(img, 34, 9, 2.0, C["leaf"])
    _pp(img, 33, 8, C["leaf_hi"])
    save(outline(img, DARK_LINE), "world/cover_wall_h.png")

    # 7. cover_wall_v.png (20x44) - Đoạn tường chắn dọc
    img, _ = canvas(20, 44)
    _rect(img, 3, 2, 16, 41, C["stone_d"])
    _rect(img, 3, 2, 16, 6, C["stone_hi"])
    for r, y0 in enumerate(range(7, 39, 6)):
        _rect(img, 4, y0, 15, min(39, y0 + 4), C["stone"] if r % 2 == 0 else C["stone_l"])
        _rect(img, 4, y0, 8, min(39, y0 + 3), C["stone_hi"])
    _rect(img, 3, 38, 16, 41, C["ink_d"])
    _disc(img, 13, 22, 2.0, C["leaf"])
    _pp(img, 12, 21, C["leaf_l"])
    save(outline(img, DARK_LINE), "world/cover_wall_v.png")

    # 8. barrel_boom.png (18x22, 4f) - Thùng thuốc nổ đỏ cam có đai thép & ngòi lửa cháy
    fr = []
    for f in range(4):
        img, _ = canvas(18, 22)
        _rect(img, 4, 6, 13, 19, C["red_d"])
        _rect(img, 4, 6, 11, 18, C["red"])
        _rect(img, 5, 7, 8, 17, C["red_l"])
        _line(img, 6, 7, 6, 17, C["red_hi"], 1)
        _rect(img, 4, 8, 13, 9, C["steel"])
        _rect(img, 4, 15, 13, 16, C["steel_d"])
        _rect(img, 5, 5, 12, 6, C["wood_hi"])
        # Biểu tượng lửa vàng giữa thùng
        _spark(img, 9, 12, C["fire_l"], C["fire_hi"], 1)
        # Ngòi dây & tia lửa
        _line(img, 9, 5, 11, 2, C["sand_l"], 1)
        sp_c = C["fire_hi"] if f % 2 == 0 else C["fire_l"]
        _spark(img, 11 + (f % 2), 2 - (f // 3), C["fire"], sp_c, 1)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/barrel_boom.png")

    # 9. torch.png (12x22, 4f) - Đuốc sắt gắn tường có ngọn lửa nhiều tầng
    fr = []
    for f in range(4):
        img, _ = canvas(12, 22)
        _rect(img, 5, 12, 6, 20, C["wood_d"])
        _line(img, 5, 12, 5, 19, C["wood_l"], 1)
        _rect(img, 3, 10, 8, 12, C["gold"])
        _pp(img, 4, 10, C["gold_hi"])
        h_fl = [0, -1, 0, 1][f]
        _disc(img, 6, 7 + h_fl * 0.4, 3.0, C["fire"])
        _disc(img, 6, 7 + h_fl * 0.5, 2.0, C["fire_l"])
        _pp(img, 6 + (f % 2), 3 + h_fl, C["fire_l"])
        _pp(img, 5, 8, C["fire_hi"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/torch.png")

    # 10. banner.png (16x28, 4f) - Cờ lệnh thêu mặt trống đồng vẫy 4 khung mượt
    fr = []
    for f in range(4):
        img, _ = canvas(16, 28)
        _line(img, 2, 2, 13, 2, C["wood_l"], 2)
        _pp(img, 1, 2, C["gold_hi"])
        _pp(img, 14, 2, C["gold_hi"])
        sw = [0, 1, 0, -1][f]
        for y in range(4, 24):
            w_half = 5 if y < 19 else max(1, 5 - (y - 19))
            ox = sw if y > 13 else 0
            for dx in range(-w_half, w_half + 1):
                col = C["red_hi"] if dx < -2 else (C["red_l"] if dx < 1 else (C["red"] if dx < 4 else C["red_d"]))
                _pp(img, 8 + dx + ox, y, col)
        # Viền vàng & mặt trống đồng
        _line(img, 4 + (sw if 16 > 13 else 0), 17, 12 + (sw if 16 > 13 else 0), 17, C["gold_l"], 1)
        _disc(img, 8, 11, 2.6, C["gold"])
        _pp(img, 7, 10, C["gold_hi"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/banner.png")

    # 11. lantern.png (14x20, 4f) - Đèn lồng đỏ phát sáng lung linh 4 khung
    fr = []
    for f in range(4):
        img, _ = canvas(14, 20)
        _line(img, 7, 1, 7, 3, C["wood_l"], 1)
        _rect(img, 5, 3, 9, 4, C["gold_hi"])
        _shaded_disc(img, 7, 9, 4.5, C["fire_hi"] if f in (1, 2) else C["red_hi"], C["red_l"], C["red"], C["red_d"])
        _rect(img, 5, 13, 9, 14, C["gold"])
        _line(img, 7 + (1 if f == 1 else (-1 if f == 3 else 0)), 15, 7, 18, C["gold_l"], 1)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/lantern.png")


def build():
    build_trees()
    build_covers_and_decor()
    print("Da ve xong cay coi, vat can va dao cu ham nguc phu bong!")


if __name__ == "__main__":
    build()
