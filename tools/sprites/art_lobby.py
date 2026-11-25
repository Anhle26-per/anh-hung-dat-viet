"""Tranh nền Doanh Trại Anh Hùng 4 phòng kiểu Soul Knight (1360 x 760):
  - center (Đại Sảnh Anh Hùng):  x 460..900, y 250..690
  - west   (Vườn Sen & Chiến Tích): x 40..420,  y 250..690
  - east   (Xưởng Rèn & Võ Đường): x 940..1320, y 250..690
  - north  (Đại Cổng Xuất Trận): x 460..900, y 20..210
  - 3 hành lang rộng 90px nối thông 4 phòng:
      Tây: 420..460 x 425..515
      Đông: 900..940 x 425..515
      Bắc: 635..725 x 210..250
"""
import math
import random
from px import hexc, save, Image, ImageDraw

W, H = 1360, 760

CENTER = (460, 250, 900, 690)
WEST = (40, 250, 420, 690)
EAST = (940, 250, 1320, 690)
NORTH = (460, 20, 900, 210)

CORR_WEST = (420, 425, 460, 515)
CORR_EAST = (900, 425, 940, 515)
CORR_NORTH = (635, 210, 725, 250)


def C(h, a=255):
    return hexc(h, a)


def lerp(c1, c2, k):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * k) for i in range(3)) + (255,)


def draw_tiled_floor(d, rng, x0, y0, x1, y1, col, col_l, col_d, grout, tile=16, crack_rate=0.05):
    d.rectangle([x0, y0, x1, y1], fill=grout)
    for row, y in enumerate(range(y0, y1, tile)):
        off = (tile // 2) if row % 2 else 0
        for x in range(x0 - off, x1, tile):
            tx0 = max(x0, x)
            ty0 = max(y0, y)
            tx1 = min(x1 - 1, x + tile - 2)
            ty1 = min(y1 - 1, y + tile - 2)
            if tx1 <= tx0 or ty1 <= ty0:
                continue
            r = rng.random()
            b = col if r < 0.72 else (lerp(col, col_d, 0.22) if r < 0.88 else lerp(col, col_l, 0.22))
            d.rectangle([tx0, ty0, tx1, ty1], fill=b)
            d.line([(tx0, ty0), (tx1, ty0)], fill=lerp(b, col_l, 0.52))
            d.line([(tx0, ty0), (tx0, ty1)], fill=lerp(b, col_l, 0.30))
            d.line([(tx0, ty1), (tx1, ty1)], fill=lerp(b, col_d, 0.58))
            if rng.random() < crack_rate and tx1 - tx0 > 6 and ty1 - ty0 > 6:
                cx = rng.randint(tx0 + 2, tx1 - 3)
                cy = rng.randint(ty0 + 2, ty1 - 3)
                d.line([(cx, cy), (cx + 3, cy + 3)], fill=lerp(b, col_d, 0.72))


def draw_wood_platform(d, x0, y0, x1, y1, plank_h=6):
    wood, w_l, w_d = C("946238"), C("b8824c"), C("633e22")
    d.rectangle([x0, y0, x1, y1], fill=w_d)
    for i, y in enumerate(range(y0 + 1, y1 - 2, plank_h)):
        py1 = min(y1 - 2, y + plank_h - 2)
        b = wood if i % 2 == 0 else lerp(wood, w_d, 0.16)
        d.rectangle([x0 + 1, y, x1 - 1, py1], fill=b)
        d.line([(x0 + 1, y), (x1 - 1, y)], fill=lerp(b, w_l, 0.5))
        for x in range(x0 + 12 + (i * 29) % 44, x1 - 4, 44):
            d.line([(x, y), (x, py1)], fill=w_d)
    d.rectangle([x0, y0, x1, y1], outline=C("442414"))
    d.rectangle([x0 + 1, y1 + 1, x1 - 1, y1 + 5], fill=C("4e2e1a"))
    d.line([(x0 + 1, y1 + 1), (x1 - 1, y1 + 1)], fill=C("c28e58"))


def draw_carpet(d, x0, y0, x1, y1, main="96282e", border="e8b64c", trim="5c161c"):
    d.rectangle([x0, y0, x1, y1], fill=C(trim))
    d.rectangle([x0 + 2, y0 + 2, x1 - 2, y1 - 2], fill=C(main))
    d.rectangle([x0 + 4, y0 + 4, x1 - 4, y1 - 4], outline=C(border))
    d.rectangle([x0 + 7, y0 + 7, x1 - 7, y1 - 7], outline=C("c88432"))


def draw_dinh_roof(d, x0, y0, x1, y1, badge_text=True):
    """Mặt tiền đình + mái ngói cong dọc theo cạnh trên một căn phòng."""
    w = x1 - x0
    roof, r_l, r_d = C("7c2822"), C("ae4238"), C("4a1616")
    # tường gỗ + cửa bức bàn bên dưới mái
    wy0 = y0 + 20
    d.rectangle([x0, wy0, x1, y1], fill=C("643622"))
    for x in range(x0 + 14, x1 - 28, 46):
        d.rectangle([x, wy0 + 4, x + 32, y1 - 2], fill=C("86482a"))
        d.rectangle([x + 2, wy0 + 6, x + 30, wy0 + 16], fill=C("542a18"))
        for gx in range(x + 4, x + 30, 4):
            d.line([(gx, wy0 + 6), (gx, wy0 + 16)], fill=C("c28c56"))
        d.rectangle([x + 2, wy0 + 18, x + 30, y1 - 4], outline=C("c28c56"))
    # cột son
    for x in range(x0 + 4, x1 - 8, 46):
        d.rectangle([x, wy0, x + 7, y1], fill=C("b8323a"))
        d.line([(x, wy0), (x, y1)], fill=C("e25e52"))
        d.line([(x + 7, wy0), (x + 7, y1)], fill=C("741c28"))
        d.rectangle([x - 1, y1 - 3, x + 8, y1], fill=C("8e887c"))
    # mái ngói cong
    pts = [(x0 - 4, wy0 + 2), (x1 + 4, wy0 + 2), (x1 + 6, y0 + 6), (x1 - 22, y0 + 10), (x0 + 22, y0 + 10), (x0 - 6, y0 + 6)]
    d.polygon(pts, fill=roof)
    for x in range(x0 - 2, x1 + 3, 7):
        dist = min(x - (x0 - 2), (x1 + 2) - x)
        top = y0 + 10 if dist >= 22 else y0 + 10 - int((22 - max(0, dist)) * 4 / 22)
        d.line([(x, top), (x, wy0 + 1)], fill=r_d)
        d.line([(x + 2, top), (x + 2, wy0 + 1)], fill=r_l)
    d.rectangle([x0 - 4, wy0, x1 + 4, wy0 + 3], fill=C("3a1410"))
    d.line([(x0 - 4, wy0), (x1 + 4, wy0)], fill=C("c45a46"))
    d.rectangle([x0 + 16, y0 + 2, x1 - 16, y0 + 6], fill=C("5a1c18"))
    d.line([(x0 + 16, y0 + 2), (x1 - 16, y0 + 2)], fill=C("c45a46"))
    # đầu đao hai bên
    for xs, sgn in ((x0 + 16, -1), (x1 - 16, 1)):
        d.polygon([(xs, y0 + 2), (xs + 12 * sgn, y0 - 3), (xs + 16 * sgn, y0 - 5), (xs + 10 * sgn, y0 + 3), (xs, y0 + 7)], fill=C("5a1c18"))
        d.point([xs + 16 * sgn, y0 - 5], fill=C("eac050"))
    if badge_text and w >= 240:
        cx = (x0 + x1) // 2
        d.ellipse([cx - 8, y0 - 3, cx + 8, y0 + 5], fill=C("e8b04a"))
        d.ellipse([cx - 5, y0 - 1, cx + 5, y0 + 3], fill=C("fff2a8"))
        d.rectangle([cx - 46, wy0 + 2, cx + 46, wy0 + 15], fill=C("281212"))
        d.rectangle([cx - 45, wy0 + 3, cx + 45, wy0 + 14], outline=C("e8b04a"))
        for gx in range(cx - 34, cx + 36, 11):
            d.rectangle([gx, wy0 + 6, gx + 6, wy0 + 11], fill=C("e8b04a"))
            d.point([gx + 3, wy0 + 8], fill=C("281212"))


def draw_perimeter_walls(d):
    """Vẽ khung tường đá + viền gỗ quanh 4 phòng, chừa trống đúng 3 cửa thông."""
    wall_body = C("4c4248")
    wall_top = C("7a7276")
    wall_hi = C("a8a09e")
    wall_sh = C("261e24")

    def wall_rect(x0, y0, x1, y1):
        d.rectangle([x0, y0, x1, y1], fill=wall_body)
        d.rectangle([x0, y0, x1, y0 + 5], fill=wall_top)
        d.line([(x0, y0), (x1, y0)], fill=wall_hi)
        d.line([(x0, y1), (x1, y1)], fill=wall_sh)

    # Tường bao từng phòng (dày 14px bên ngoài vùng đi bộ)
    # Center: x 460..900, y 250..690
    wall_rect(446, 236, 634, 250)   # Bắc trái (chừa 635..725)
    wall_rect(726, 236, 914, 250)   # Bắc phải
    wall_rect(446, 690, 914, 706)   # Nam
    wall_rect(446, 250, 460, 424)   # Tây trên (chừa 425..515)
    wall_rect(446, 516, 460, 690)   # Tây dưới
    wall_rect(900, 250, 914, 424)   # Đông trên (chừa 425..515)
    wall_rect(900, 516, 914, 690)   # Đông dưới

    # West: x 40..420, y 250..690
    wall_rect(26, 236, 434, 250)    # Bắc
    wall_rect(26, 690, 434, 706)    # Nam
    wall_rect(26, 250, 40, 690)     # Tây
    wall_rect(420, 250, 434, 424)   # Đông trên
    wall_rect(420, 516, 434, 690)   # Đông dưới

    # East: x 940..1320, y 250..690
    wall_rect(926, 236, 1334, 250)  # Bắc
    wall_rect(926, 690, 1334, 706)  # Nam
    wall_rect(1320, 250, 1334, 690) # Đông
    wall_rect(926, 250, 940, 424)   # Tây trên
    wall_rect(926, 516, 940, 690)   # Tây dưới

    # North: x 460..900, y 20..210
    wall_rect(446, 6, 914, 20)      # Bắc
    wall_rect(446, 20, 460, 210)    # Tây
    wall_rect(900, 20, 914, 210)    # Đông
    wall_rect(446, 210, 634, 224)   # Nam trái
    wall_rect(726, 210, 914, 224)   # Nam phải

    # Viền hai bên 3 hành lang
    wall_rect(420, 412, 460, 424)
    wall_rect(420, 516, 460, 528)
    wall_rect(900, 412, 940, 424)
    wall_rect(900, 516, 940, 528)
    wall_rect(622, 210, 634, 250)
    wall_rect(726, 210, 738, 250)

    # Trụ cổng đỏ tại 3 cửa nối phòng
    for px, py in ((422, 422), (452, 422), (422, 512), (452, 512),
                   (902, 422), (932, 422), (902, 512), (932, 512),
                   (632, 212), (722, 212), (632, 242), (722, 242)):
        d.rectangle([px, py, px + 8, py + 8], fill=C("b8323a"), outline=C("e8b04a"))


def draw_lantern_glow(img, px, cx, cy, r=36, warm=(255, 205, 110)):
    for y in range(max(0, cy - r), min(H, cy + r + 1)):
        for x in range(max(0, cx - r), min(W, cx + r + 1)):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                k = (1.0 - math.sqrt(d2) / r) * 0.16
                cr, cg, cb, ca = px[x, y]
                nr = min(255, int(cr + (warm[0] - cr) * k))
                ng = min(255, int(cg + (warm[1] - cg) * k))
                nb = min(255, int(cb + (warm[2] - cb) * k))
                px[x, y] = (nr, ng, nb, ca)


def build():
    rng = random.Random(2026)
    img = Image.new("RGBA", (W, H), C("120e16"))
    d = ImageDraw.Draw(img)

    # Nền ngoài nhẹ quanh viền bản đồ (lá cây tối & ngói xa)
    for _ in range(900):
        x, y = rng.randint(0, W - 1), rng.randint(0, H - 1)
        d.point([x, y], fill=rng.choice([C("1a1520"), C("221c28"), C("17201a")]))

    # =========================================================================
    # 1. ĐẠI SẢNH ANH HÙNG (CENTER: 460..900, 250..690)
    # =========================================================================
    draw_tiled_floor(d, rng, *CENTER, C("b06c4a"), C("cc8864"), C("8a4f38"), C("6b3b29"), tile=16)

    # Thảm đỏ hoa văn lớn dọc trục Bắc-Nam và Tây-Đông của Đại Sảnh
    draw_carpet(d, 646, 252, 714, 668)
    draw_carpet(d, 462, 444, 898, 496)
    # Huy hiệu Trống Đồng ở tâm Đại Sảnh (680, 470)
    cx, cy = 680, 470
    for rad, col in ((46, C("5a3418")), (42, C("d4a442")), (34, C("8c5c26")), (24, C("e0b84e")), (13, C("742228")), (6, C("fce078"))):
        d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=col)
    for i in range(12):
        a = i / 12.0 * math.tau
        d.line([(cx + math.cos(a) * 14, cy + math.sin(a) * 14),
                (cx + math.cos(a) * 32, cy + math.sin(a) * 32)], fill=C("fce078"))

    # Hai bục gỗ sân khấu hai cánh trái/phải phía trên Đại Sảnh cho 11 vị tướng đứng
    draw_wood_platform(d, 476, 294, 628, 424, plank_h=6)
    draw_wood_platform(d, 732, 294, 884, 424, plank_h=6)
    # Hai bục gỗ nhỏ phía nam cho tướng bổ sung / khu uống trà
    draw_wood_platform(d, 478, 536, 626, 648, plank_h=6)
    draw_wood_platform(d, 734, 536, 882, 648, plank_h=6)

    # Bàn trà gỗ giữa khu nghỉ phía nam
    d.rectangle([534, 582, 570, 604], fill=C("5a341c"), outline=C("c28e58"))
    d.ellipse([544, 588, 550, 594], fill=C("e8dec8"))
    d.ellipse([554, 590, 560, 596], fill=C("e8dec8"))

    # Mặt đình bên trên Đại Sảnh (tách 2 cánh trái/phải để chừa hành lang Bắc 635..725)
    draw_dinh_roof(d, 464, 248, 630, 292, badge_text=False)
    draw_dinh_roof(d, 730, 248, 896, 292, badge_text=False)

    # =========================================================================
    # 2. VƯỜN SEN & CHIẾN TÍCH (WEST: 40..420, 250..690)
    # =========================================================================
    # Nền cỏ vườn mượt + đốm sáng tối + hoa dại
    grass, g_l, g_d = C("4f8034"), C("6da044"), C("375e24")
    d.rectangle([40, 250, 420, 690], fill=grass)
    for _ in range(3600):
        x, y = rng.randint(42, 418), rng.randint(252, 688)
        d.point([x, y], fill=g_l if rng.random() < 0.45 else g_d)
    for _ in range(180):
        x, y = rng.randint(46, 414), rng.randint(256, 682)
        d.line([(x, y + 3), (x - 1, y)], fill=g_l)
        d.line([(x + 1, y + 3), (x + 2, y)], fill=g_l)
    for _ in range(75):
        x, y = rng.randint(48, 412), rng.randint(260, 678)
        c = rng.choice([C("f6e464"), C("f49ac0"), C("fff4ee")])
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            d.point([x + dx, y + dy], fill=c)
        d.point([x, y], fill=C("e89a38"))

    # Lối đá dạo sân vườn nối từ cửa Đông (420, 470) lên khu 3 công trình phía trên & vòng xuống hồ
    stone, st_l, st_d = C("8f8a7e"), C("b8b2a4"), C("5e5a50")
    for (sx, sy) in [
        (398, 470), (370, 470), (342, 466), (314, 450), (294, 424),
        (264, 410), (226, 405), (186, 405), (146, 405), (345, 415), (345, 385),
    ]:
        d.ellipse([sx - 15, sy - 11, sx + 15, sy + 11], fill=st_d)
        d.ellipse([sx - 13, sy - 9, sx + 13, sy + 9], fill=stone, outline=st_l)

    # Sân đá đặt Bia Chiến Tích (135, 345), Giếng Ước (245, 345), Bảng Khiêu Chiến (345, 345)
    draw_tiled_floor(d, rng, 82, 286, 392, 392, C("9c9688"), C("bcb6a8"), C("6e685e"), C("524e46"), tile=18, crack_rate=0.06)
    d.rectangle([80, 284, 394, 394], outline=C("444038"))

    # Hồ Sen thanh tịnh ở nửa dưới Vườn (tâm 215, 585)
    hx, hy = 215, 585
    for rx, ry, col in ((84, 56, C("5c5850")), (79, 52, C("9e988a")), (73, 47, C("225b6e")), (65, 41, C("2e7588")), (52, 32, C("3a8ea0"))):
        d.ellipse([hx - rx, hy - ry, hx + rx, hy + ry], fill=col)
    # Lá sen và hoa sen hồng
    for lx, ly, lr in ((175, 575, 11), (206, 562, 10), (242, 572, 12), (190, 604, 11), (235, 608, 10), (266, 590, 9)):
        d.ellipse([lx - lr, ly - lr + 2, lx + lr, ly + lr - 2], fill=C("3a7c38"), outline=C("5ca84e"))
        d.line([(lx, ly), (lx + lr - 2, ly - 2)], fill=C("245224"))
    for fx, fy in ((178, 572), (244, 569), (233, 605)):
        d.ellipse([fx - 5, fy - 4, fx + 5, fy + 4], fill=C("f68cb4"))
        d.ellipse([fx - 3, fy - 3, fx + 3, fy + 3], fill=C("ffc2da"))
        d.point([fx, fy], fill=C("fae060"))

    # Bụi tre / trúc trang trí các góc vườn
    for bx, by in ((66, 278), (392, 278), (68, 654), (392, 654)):
        d.ellipse([bx - 16, by - 10, bx + 16, by + 10], fill=C("2a4e20"))
        d.ellipse([bx - 12, by - 14, bx + 12, by + 6], fill=C("468032"))
        d.ellipse([bx - 6, by - 16, bx + 8, by - 2], fill=C("66a644"))

    # =========================================================================
    # 3. XƯỞNG RÈN & VÕ ĐƯỜNG (EAST: 940..1320, 250..690)
    # =========================================================================
    # Nửa trên: nền đá Xưởng Rèn + viền quanh sàn Võ Đường
    draw_tiled_floor(d, rng, 940, 250, 1320, 690, C("7a7672"), C("9e9892"), C("524e4c"), C("3e3a38"), tile=18, crack_rate=0.08)

    # Sân lò rèn ấm rực bên góc trên trái (968..1094, 286..396)
    draw_tiled_floor(d, rng, 968, 286, 1094, 396, C("584a48"), C("76625e"), C("3e3230"), C("2c2220"), tile=14)
    d.rectangle([967, 285, 1095, 397], outline=C("281a18"))
    # Góc Thư viện gỗ bên trên phải (1200..1304, 284..398) cho Bách Khoa Toàn Thư
    draw_wood_platform(d, 1200, 284, 1304, 398, plank_h=6)
    draw_carpet(d, 1218, 314, 1286, 384, main="244a5e", border="e8b64c", trim="162c3a")

    # Nửa dưới: Võ Đường sàn gỗ rộng rãi (960..1302, 482..674) - chứa 3 Hình Nhân (1040,580 / 1140,560 / 1220,610)
    draw_wood_platform(d, 960, 482, 1302, 674, plank_h=7)
    d.rectangle([982, 504, 1280, 654], outline=C("c28e58"))
    # Vòng tròn tập võ dưới sàn gỗ
    d.ellipse([1096, 540, 1184, 628], outline=C("b8824c"))

    # =========================================================================
    # 4. ĐẠI CỔNG XUẤT TRẬN (NORTH: 460..900, 20..210)
    # =========================================================================
    draw_tiled_floor(d, rng, *NORTH, C("6a6872"), C("8e8c98"), C("46444c"), C("302e36"), tile=16, crack_rate=0.05)
    # Thảm danh dự dẫn vào Cổng Thời Gian (680, 115)
    draw_carpet(d, 646, 126, 714, 210)
    # Bệ đá tròn trung tâm Cổng Thời Gian
    gx, gy = 680, 115
    for rx, ry, col in ((56, 38, C("3a3642")), (50, 34, C("645e70")), (42, 28, C("9c94a8")), (32, 22, C("423c52"))):
        d.ellipse([gx - rx, gy - ry, gx + rx, gy + ry], fill=col)
    for i in range(16):
        a = i / 16.0 * math.tau
        d.line([(gx + math.cos(a) * 34, gy + math.sin(a) * 23),
                (gx + math.cos(a) * 46, gy + math.sin(a) * 31)], fill=C("e8c468"))
    # Mặt đình hoành tráng phía Bắc phòng Bắc
    draw_dinh_roof(d, 464, 22, 896, 70, badge_text=True)

    # =========================================================================
    # 5. 3 HÀNH LANG NỐI PHÒNG RỘNG 90px
    # =========================================================================
    # Tây: 420..460, 425..515
    draw_tiled_floor(d, rng, *CORR_WEST, C("a47e60"), C("c69c78"), C("7c5a42"), C("543b2a"), tile=15)
    draw_carpet(d, 420, 444, 460, 496)
    # Đông: 900..940, 425..515
    draw_tiled_floor(d, rng, *CORR_EAST, C("a47e60"), C("c69c78"), C("7c5a42"), C("543b2a"), tile=15)
    draw_carpet(d, 900, 444, 940, 496)
    # Bắc: 635..725, 210..250
    draw_tiled_floor(d, rng, *CORR_NORTH, C("928c90"), C("b8b2b6"), C("6c686e"), C("4a464c"), tile=15)
    draw_carpet(d, 646, 210, 714, 250)

    # Bậc đá nhẹ hai bên cửa nối
    for x in (420, 456, 900, 936):
        d.line([(x, 425), (x, 515)], fill=C("e0d4c0"))
    for y in (210, 248):
        d.line([(635, y), (725, y)], fill=C("e0d4c0"))

    # =========================================================================
    # 6. TƯỜNG BAO & ÁNH SÁNG ĐÈN LỒNG ẤM
    # =========================================================================
    draw_perimeter_walls(d)

    px = img.load()
    # Ánh sáng ấm quanh các ngã ba, cổng xuất trận, lò rèn và đài sen
    for (lx, ly, rad, col) in [
        (680, 470, 82, (255, 215, 130)),
        (552, 355, 58, (255, 200, 110)),
        (808, 355, 58, (255, 200, 110)),
        (680, 115, 76, (150, 225, 255)),
        (1032, 345, 62, (255, 145, 75)),
        (1252, 345, 52, (255, 225, 150)),
        (215, 585, 64, (130, 225, 210)),
        (135, 345, 46, (255, 220, 140)),
        (245, 345, 46, (150, 235, 255)),
        (345, 345, 46, (255, 195, 120)),
    ]:
        draw_lantern_glow(img, px, lx, ly, rad, col)

    save(img, "world/lobby_bg.png")


if __name__ == "__main__":
    build()
