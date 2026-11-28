"""Nghệ thuật pixel art chuyên sâu cho chiến trường Thủ Thành Cổ Loa (v3.0.0 Polish):
  - world/coloa_bg.png         (1152x832, tâm 576,416): Thành Ốc 3 vòng, hào nước hoa sen,
                               4 cầu gỗ rút, 4 đại lộ lát đá, quảng trường Mặt Trống Đồng & 8 bệ đá
  - world/coloa_gate_arch.png  (84x58): Cổng Thành mái ngói cong đầu đao
  - world/coloa_core.png       (256x64 = 4 khung 64x64): Đền Nỏ Thần Kim Quy bay lơ lửng phát sáng
  - 5 loại Tháp x 3 cấp (mỗi cấp 2 khung 44x44 -> 88x44) + 5 biểu tượng tower_*.png (44x44)
"""
import math
import random
from px import hexc, shade, outline, auto_shade, sheet, save, canvas, Image, ImageDraw

C = hexc


def _c(h, a=255):
    return hexc(h, a)


def _with_shadow(outlined_img, sx0, sy0, sx1, sy1, alpha=95):
    w, h = outlined_img.size
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(base)
    sd.ellipse([sx0, sy0, sx1, sy1], fill=(14, 10, 20, alpha))
    base.alpha_composite(outlined_img)
    return base


def _lerp(c1, c2, k):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * k) for i in range(3)) + (255,)


# ------------------------------------------------------------------ 1. Bản đồ Thành Cổ Loa (1152x832)
def build_coloa_bg():
    W, H = 1152, 832
    CX, CY = W // 2, H // 2  # (576, 416) = world (0, 0)
    rng = random.Random(300938)

    img = Image.new("RGBA", (W, H), C("2d5228"))
    d = ImageDraw.Draw(img)

    # 1) Đồng cỏ ngoại vi nhiều sắc độ & cỏ hoa dại
    grass, grass_l, grass_d = C("36622c"), C("548c3c"), C("22441e")
    d.rectangle([0, 0, W, H], fill=grass)
    for y in range(0, H, 16):
        for x in range(0, W, 16):
            r = rng.random()
            col = grass if r < 0.65 else (_lerp(grass, grass_d, 0.35) if r < 0.85 else _lerp(grass, grass_l, 0.25))
            d.rectangle([x, y, x + 15, y + 15], fill=col)
            if rng.random() < 0.35:
                gx, gy = x + rng.randint(2, 12), y + rng.randint(2, 12)
                d.line([(gx, gy), (gx - 1, gy - 2)], fill=grass_l)
                d.line([(gx + 2, gy), (gx + 3, gy - 2)], fill=grass_l)
            if rng.random() < 0.08:
                fx, fy = x + rng.randint(3, 12), y + rng.randint(3, 12)
                d.point([fx, fy], fill=C("f8e468") if rng.random() < 0.6 else C("fff4f8"))

    # Đường đất hành quân ngoài 4 cổng dẫn vào cầu
    dirt, dirt_l, dirt_d = C("7c5c3a"), C("9e7a4e"), C("543b24")
    for box in (
        (CX - 34, 0, CX + 34, CY - 220),
        (CX - 34, CY + 220, CX + 34, H),
        (0, CY - 32, CX - 320, CY + 32),
        (CX + 320, CY - 32, W, CY + 32),
    ):
        d.rectangle(box, fill=dirt)
        d.rectangle([box[0] + 4, box[1] + 4, box[2] - 4, box[3] - 4], fill=_lerp(dirt, dirt_l, 0.28))

    # 2) Bờ thành đất đắp ngoại vi + Tường Thành Ốc ngoài (ellipse outer ring)
    rammed_d, rammed, rammed_l = C("5e4830"), C("8a6a44"), C("b08c5c")
    stone_d, stone, stone_l = C("4c4944"), C("7c7870"), C("aca69a")
    d.ellipse([CX - 404, CY - 294, CX + 404, CY + 294], fill=rammed_d, outline=C("382818"), width=3)
    d.ellipse([CX - 392, CY - 284, CX + 392, CY + 284], fill=rammed)

    # 3) Hào Nước Cổ Loa (Spiral Moat ellipse)
    moat_edge = C("3a3834")
    water_d, water, water_l, foam = C("184664"), C("246c8c"), C("3aa4bc"), C("a8f0ff")
    d.ellipse([CX - 376, CY - 270, CX + 376, CY + 270], fill=stone_d, outline=moat_edge, width=2)
    d.ellipse([CX - 370, CY - 264, CX + 370, CY + 264], fill=water_d)
    d.ellipse([CX - 362, CY - 256, CX + 362, CY + 256], fill=water)
    d.ellipse([CX - 352, CY - 246, CX + 352, CY + 246], fill=water_d)

    # Sóng gợn, lá sen & hoa sen trên hào nước
    for i in range(64):
        ang = (i / 64.0) * math.tau
        wx = CX + math.cos(ang) * rng.uniform(326, 360)
        wy = CY + math.sin(ang) * rng.uniform(226, 254)
        # chừa chỗ cho 4 cây cầu
        if abs(wx - CX) < 42 or abs(wy - CY) < 40:
            continue
        d.arc([wx - 8, wy - 2, wx + 8, wy + 3], 10, 170, fill=water_l if i % 2 == 0 else foam, width=1)
        if i % 4 == 0:
            d.ellipse([wx - 4, wy - 3, wx + 4, wy + 2], fill=C("328444"))
            if i % 8 == 0:
                d.ellipse([wx - 2, wy - 3, wx + 2, wy], fill=C("ffa4c8"))

    # Bờ kè đá nội thành + Tường Thành Nội (4 cung lũy đá có lỗ châu mai)
    d.ellipse([CX - 318, CY - 218, CX + 318, CY + 218], fill=stone_d, outline=moat_edge, width=2)
    d.ellipse([CX - 310, CY - 212, CX + 310, CY + 212], fill=stone)

    # Sân gạch nội thành Cổ Loa
    tile_base, tile_l, tile_d, grout = C("786854"), C("9a886e"), C("564a3c"), C("42382e")
    d.ellipse([CX - 294, CY - 198, CX + 294, CY + 198], fill=grout)
    # Vẽ gạch lát cắt clip trong ellipse nội thành
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([CX - 292, CY - 196, CX + 292, CY + 196], fill=255)
    courtyard = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(courtyard)
    cd.rectangle([CX - 296, CY - 200, CX + 296, CY + 200], fill=grout)
    for row, y in enumerate(range(CY - 200, CY + 200, 16)):
        off = 8 if row % 2 else 0
        for x in range(CX - 304 + off, CX + 300, 16):
            r = rng.random()
            b = tile_base if r < 0.68 else (_lerp(tile_base, tile_d, 0.28) if r < 0.88 else _lerp(tile_base, tile_l, 0.28))
            cd.rectangle([x + 1, y + 1, x + 14, y + 14], fill=b)
            cd.line([(x + 1, y + 1), (x + 14, y + 1)], fill=_lerp(b, tile_l, 0.4))
            cd.line([(x + 1, y + 14), (x + 14, y + 14)], fill=_lerp(b, tile_d, 0.5))
    img.paste(courtyard, (0, 0), mask)

    # Tường thành gạch ốc có lỗ châu mai dọc theo vành trong (bỏ trống 4 cổng)
    for deg in range(0, 360, 4):
        rad = math.radians(deg)
        wx = CX + math.cos(rad) * 298
        wy = CY + math.sin(rad) * 202
        if abs(wx - CX) < 42 or abs(wy - CY) < 40:
            continue
        cd_col = stone_l if (deg // 4) % 2 == 0 else stone_d
        d.rectangle([wx - 6, wy - 6, wx + 6, wy + 5], fill=stone, outline=C("2c2824"))
        d.rectangle([wx - 4, wy - 5, wx + 4, wy - 2], fill=cd_col)

    # 4 Pháo đài góc bát giác bằng đá trên tường thành
    for qx, qy in ((CX - 220, CY - 146), (CX + 220, CY - 146), (CX - 220, CY + 146), (CX + 220, CY + 146)):
        d.ellipse([qx - 26, qy - 20, qx + 26, qy + 20], fill=stone_d, outline=C("2c2824"), width=2)
        d.ellipse([qx - 21, qy - 16, qx + 21, qy + 16], fill=stone)
        d.ellipse([qx - 14, qy - 10, qx + 14, qy + 10], fill=tile_l)

    # 4) 4 Cầu gỗ bắc qua Hào Nước & Đại lộ đá dẫn vào trung tâm
    wood_d, wood, wood_l = C("4e2e18"), C("885830"), C("b47e4c")
    gold_d, gold, gold_l = C("8a581c"), C("d89e36"), C("ffe484")
    # Cầu Bắc & Cầu Nam
    for y0, y1 in ((CY - 274, CY - 204), (CY + 204, CY + 274)):
        d.rectangle([CX - 34, y0, CX + 34, y1], fill=wood_d, outline=C("28180c"), width=2)
        d.rectangle([CX - 28, y0 + 2, CX + 28, y1 - 2], fill=wood)
        for py in range(y0 + 4, y1 - 2, 7):
            d.line([(CX - 28, py), (CX + 28, py)], fill=wood_d)
            d.line([(CX - 28, py + 1), (CX + 28, py + 1)], fill=wood_l)
        # Lan can gỗ 2 bên cầu
        d.rectangle([CX - 34, y0, CX - 28, y1], fill=wood_l, outline=wood_d)
        d.rectangle([CX + 28, y0, CX + 34, y1], fill=wood_l, outline=wood_d)
    # Cầu Tây & Cầu Đông
    for x0, x1 in ((CX - 380, CX - 302), (CX + 302, CX + 380)):
        d.rectangle([x0, CY - 32, x1, CY + 32], fill=wood_d, outline=C("28180c"), width=2)
        d.rectangle([x0 + 2, CY - 26, x1 - 2, CY + 26], fill=wood)
        for px in range(x0 + 4, x1 - 2, 7):
            d.line([(px, CY - 26), (px, CY + 26)], fill=wood_d)
            d.line([(px + 1, CY - 26), (px + 1, CY + 26)], fill=wood_l)
        d.rectangle([x0, CY - 32, x1, CY - 26], fill=wood_l, outline=wood_d)
        d.rectangle([x0, CY + 26, x1, CY + 32], fill=wood_l, outline=wood_d)

    # Đại lộ lát đá sạch + Thảm Hoàng Gia viền vàng dọc 4 hướng vào trung tâm
    carpet, carpet_l, carpet_d = C("8c242c"), C("b4343c"), C("541418")
    # Thẳng đứng (Bắc - Nam)
    d.rectangle([CX - 26, CY - 204, CX + 26, CY + 204], fill=stone_l, outline=stone_d)
    d.rectangle([CX - 16, CY - 200, CX + 16, CY + 200], fill=carpet_d)
    d.rectangle([CX - 14, CY - 198, CX + 14, CY + 198], fill=carpet)
    d.rectangle([CX - 12, CY - 196, CX + 12, CY + 196], outline=gold)
    # Ngang (Tây - Đông)
    d.rectangle([CX - 302, CY - 24, CX + 302, CY + 24], fill=stone_l, outline=stone_d)
    d.rectangle([CX - 298, CY - 15, CX + 298, CY + 15], fill=carpet_d)
    d.rectangle([CX - 296, CY - 13, CX + 296, CY + 13], fill=carpet)
    d.rectangle([CX - 294, CY - 11, CX + 294, CY + 11], outline=gold)

    # 5) Quảng Trường Trống Đồng Đông Sơn ở tâm (CX, CY)
    d.ellipse([CX - 146, CY - 112, CX + 146, CY + 112], fill=stone_d, outline=C("2e2824"), width=2)
    d.ellipse([CX - 138, CY - 104, CX + 138, CY + 104], fill=C("8a765c"))
    d.ellipse([CX - 102, CY - 78, CX + 102, CY + 78], fill=C("5a3820"), outline=gold, width=2)
    d.ellipse([CX - 84, CY - 64, CX + 84, CY + 64], fill=C("784c24"), outline=gold_l, width=1)
    d.ellipse([CX - 56, CY - 44, CX + 56, CY + 44], fill=C("9e6b2a"), outline=gold, width=2)
    # 12 tia mặt trời Trống Đồng tỏa quanh Lõi Cổ Loa
    for ray in range(12):
        ra = ray * (math.tau / 12.0)
        p1 = (CX + math.cos(ra) * 20, CY + math.sin(ra) * 16)
        p2 = (CX + math.cos(ra) * 54, CY + math.sin(ra) * 42)
        d.line([p1, p2], fill=gold_l, width=2)
    for k in range(24):
        ra2 = k * (math.tau / 24.0)
        rx = CX + math.cos(ra2) * 70
        ry = CY + math.sin(ra2) * 54
        d.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=C("38c8a8") if k % 2 == 0 else gold_l)
    d.ellipse([CX - 26, CY - 20, CX + 26, CY + 20], fill=gold_d, outline=gold_l, width=2)

    # 6) 8 Bệ Đá Xây Tháp chạm viền đồng đúng 8 tọa độ PAD_POSITIONS
    pads = [
        (0, -120), (120, 0), (0, 120), (-120, 0),
        (-175, -175), (175, -175), (175, 175), (-175, 175),
    ]
    for px_off, py_off in pads:
        px, py = CX + px_off, CY + py_off
        pts = []
        for s in range(8):
            a = s * (math.tau / 8.0) + math.pi / 8.0
            pts.append((px + math.cos(a) * 24, py + math.sin(a) * 20))
        d.polygon(pts, fill=stone_d, outline=C("28221e"))
        inner = [(px + math.cos(s * (math.tau / 8.0) + math.pi / 8.0) * 18, py + math.sin(s * (math.tau / 8.0) + math.pi / 8.0) * 14) for s in range(8)]
        d.polygon(inner, fill=stone, outline=gold_d)
        d.ellipse([px - 10, py - 8, px + 10, py + 8], fill=C("544a42"), outline=gold)

    # Viền tối nhẹ góc bản đồ tạo chiều sâu
    d.rectangle([0, 0, W - 1, H - 1], outline=C("1a2e16"), width=4)
    save(img, "world/coloa_bg.png")


# ------------------------------------------------------------------ 2. Cổng Thành Cổ Loa (84x58)
def build_gate_arch():
    img, d = canvas(84, 58)
    stone_d, stone, stone_l = C("4a4844"), C("7c7870"), C("b0aaa0")
    red_d, red, red_l = C("6e1c1e"), C("a82e2e"), C("dc5848")
    gold_d, gold, gold_l = C("8c581c"), C("e0a638"), C("fff0a0")
    wood_d, wood = C("462614"), C("7a4824")

    # Hai trụ cổng đá lớn chừa lối đi ở giữa (x 24..60 trống để lính và người đi qua)
    for tx in (6, 62):
        d.rectangle([tx, 24, tx + 16, 54], fill=stone_d, outline=C("242020"))
        d.rectangle([tx + 2, 26, tx + 14, 52], fill=stone)
        d.rectangle([tx + 3, 27, tx + 13, 30], fill=stone_l)
        # Cột son đỏ tựa tường
        d.rectangle([tx + 12 if tx < 40 else tx + 1, 22, tx + 15 if tx < 40 else tx + 4, 52], fill=red)
    # Thanh xà gỗ & bảng hiệu cổ
    d.rectangle([10, 18, 73, 25], fill=wood, outline=wood_d)
    d.rectangle([28, 17, 55, 25], fill=C("281212"), outline=gold)
    d.line([(33, 21), (50, 21)], fill=gold_l, width=2)

    # Mái ngói cong đình Việt (2 tầng mái)
    roof_pts = [(4, 20), (79, 20), (82, 12), (66, 13), (17, 13), (1, 12)]
    d.polygon(roof_pts, fill=red_d)
    for rx in range(6, 78, 6):
        d.line([(rx, 13), (rx, 19)], fill=red)
        d.line([(rx + 2, 13), (rx + 2, 19)], fill=red_l)
    # Tầng mái nóc trên + lưỡng long triều nhật
    d.polygon([(14, 13), (69, 13), (72, 7), (58, 8), (25, 8), (11, 7)], fill=red)
    d.rectangle([22, 4, 61, 8], fill=red_d, outline=red_l)
    for sgn, bx in ((-1, 22), (1, 61)):
        d.polygon([(bx, 5), (bx + 9 * sgn, 1), (bx + 12 * sgn, 0), (bx + 7 * sgn, 7)], fill=red_d)
        d.point([bx + 12 * sgn, 0], fill=gold_l)
    d.ellipse([36, 1, 47, 7], fill=gold)
    d.ellipse([39, 2, 44, 5], fill=gold_l)

    save(_with_shadow(outline(img), 4, 48, 79, 57, 85), "world/coloa_gate_arch.png")


# ------------------------------------------------------------------ 3. Nỏ Thần Cổ Loa (256x64 = 4 khung 64x64)
def build_coloa_core():
    stone_d, stone, stone_l = C("464440"), C("7c7872"), C("b4aea2")
    gold_d, gold, gold_l, gold_s = C("7c4a18"), C("cf8e2c"), C("f6c852"), C("fff6b0")
    jade_d, jade, jade_l = C("1c7c6c"), C("34e0b8"), C("bcfff6")
    fire_d, fire, fire_l = C("ea4820"), C("ff9428"), C("fff088")

    frames = []
    for f in range(4):
        img, d = canvas(64, 64)
        bob = [0, -2, -3, -1][f]
        # Đế lục giác đá và vành đồng Đông Sơn 2 tầng
        d.ellipse([6, 36, 57, 58], fill=stone_d, outline=C("221c18"))
        d.ellipse([8, 32, 55, 52], fill=stone)
        auto_shade(img, stone, stone_l, stone_d)
        d.ellipse([13, 32, 50, 48], fill=gold_d, outline=gold)
        d.ellipse([16, 30, 47, 44], fill=gold)
        d.ellipse([21, 32, 42, 41], outline=gold_l)
        # 4 ngọn lửa linh ở 4 góc bệ thờ
        fl_h = [4, 6, 5, 3][f]
        for fx, fy in ((12, 40), (51, 40), (16, 49), (47, 49)):
            d.rectangle([fx - 2, fy - 1, fx + 2, fy + 2], fill=gold_d)
            d.polygon([(fx - 2, fy), (fx, fy - fl_h), (fx + 2, fy)], fill=fire)
            d.point([fx, fy - fl_h + 1], fill=fire_l)
        # Trụ ngọc & hào quang Kim Quy
        d.rectangle([28, 22, 35, 38], fill=gold_d, outline=gold_l)
        d.ellipse([20, 12 + bob, 43, 33 + bob], fill=C("228e7c", 110 if f % 2 == 0 else 155), outline=jade_l)
        # Thân Nỏ Thần Kim Quy bay lơ lửng
        cy_c = 21 + bob
        d.arc([12, cy_c - 10, 51, cy_c + 10], 195, 345, fill=gold_d, width=4)
        d.arc([12, cy_c - 10, 51, cy_c + 10], 195, 345, fill=gold_s, width=2)
        d.line([(14, cy_c - 1), (31, cy_c + 5), (49, cy_c - 1)], fill=jade_l, width=1)
        d.rectangle([29, cy_c - 12, 34, cy_c + 8], fill=gold_l, outline=gold_d)
        # Mũi tên ngọc Kim Quy phát sáng ở mũi nỏ
        d.polygon([(31, cy_c - 18), (36, cy_c - 10), (31, cy_c - 5), (26, cy_c - 10)], fill=jade)
        d.polygon([(31, cy_c - 16), (34, cy_c - 10), (31, cy_c - 7), (28, cy_c - 10)], fill=jade_l)
        d.point([31, cy_c - 12], fill=gold_s)
        frames.append(_with_shadow(outline(img), 8, 44, 55, 60, 100))

    save(sheet(frames), "world/coloa_core.png")


# ------------------------------------------------------------------ 4. 5 Tháp x 3 Cấp (2 khung 44x44 -> 88x44)
def _tower_base_stone(d, stone_d, stone, stone_l, trim):
    d.ellipse([5, 29, 38, 41], fill=stone_d, outline=C("241c18"))
    d.ellipse([6, 26, 37, 37], fill=stone)
    d.arc([8, 27, 35, 36], 0, 360, fill=trim, width=1)


def _draw_luy_tre(f, tier):
    img, d = canvas(44, 44)
    stone_d, stone, stone_l = C("4c4842"), C("7c786e"), C("aca69a")
    wood_d, wood, wood_l = C("482a14"), C("7a4a24"), C("aa7040")
    gold, gold_l = C("d89e36"), C("fff0a0")
    bam = C("56842c") if tier < 3 else C("b89828")
    bam_l = C("8ec848") if tier < 3 else C("ffe868")
    _tower_base_stone(d, stone_d, stone, stone_l, gold if tier >= 2 else stone_l)

    # Hàng cọc tre nhọn thành tầng
    for bx in range(8, 35, 4):
        top = (15 if tier == 1 else (11 if tier == 2 else 8)) + ((bx // 4) % 2) * 2
        d.rectangle([bx, top, bx + 3, 33], fill=bam, outline=C("2a3a18"))
        d.line([(bx + 1, top), (bx + 1, 33)], fill=bam_l)
        tip_col = C("cbd4e0") if tier >= 2 else bam_l
        d.polygon([(bx, top), (bx + 1, top - 4), (bx + 3, top)], fill=tip_col)
    # Thanh ngang buộc dây + khiên đỏ ở Cấp 2 & cờ Cổ Loa ở Cấp 3
    d.rectangle([7, 23, 36, 27], fill=wood, outline=wood_d)
    if tier >= 2:
        for sx in (13, 27):
            d.ellipse([sx - 4, 19, sx + 4, 28], fill=C("b4282c"), outline=gold)
            d.point([sx, 23], fill=gold_l)
    if tier >= 3:
        # Cờ vàng bay phấp phới & gai ngọc phát sáng
        fx = 22
        d.line([(fx, 3), (fx, 24)], fill=gold, width=2)
        wave = 1 if f == 1 else 0
        d.polygon([(fx + 1, 4), (fx + 11, 7 + wave), (fx + 1, 11)], fill=C("dc2c32"))
        d.point([fx + 5, 7 + wave], fill=gold_l)
        for gx in (10, 22, 33):
            d.point([gx, 6 if f == 0 else 5], fill=C("88fff0"))
    return _with_shadow(outline(img), 6, 33, 37, 42, 90)


def _draw_no_than(f, tier):
    img, d = canvas(44, 44)
    stone_d, stone, stone_l = C("4c4842"), C("7c786e"), C("aca69a")
    wood_d, wood, wood_l = C("482a14"), C("7a4a24"), C("aa7040")
    gold_d, gold, gold_l = C("8a581c"), C("dc9e36"), C("fff0a0")
    jade_l = C("98fff0")
    _tower_base_stone(d, stone_d, stone, stone_l, gold if tier >= 2 else wood_l)

    if tier == 1:
        # Tháp gỗ 1 tầng
        d.polygon([(11, 33), (15, 16), (28, 16), (32, 33)], fill=wood, outline=wood_d)
        d.rectangle([12, 14, 31, 18], fill=gold_d, outline=gold)
    elif tier == 2:
        # Tháp đá 2 tầng + viền vàng
        d.polygon([(10, 33), (13, 18), (30, 18), (33, 33)], fill=stone, outline=stone_d)
        d.rectangle([11, 14, 32, 19], fill=gold_d, outline=gold)
        d.rectangle([14, 11, 29, 14], fill=C("8e2628"), outline=gold)
    else:
        # Lầu gác Hoàng Gia mái ngói cong + nỏ thần 3 nòng
        d.polygon([(9, 34), (12, 17), (31, 17), (34, 34)], fill=C("7c2424"), outline=gold_d)
        d.rectangle([10, 15, 33, 19], fill=gold, outline=gold_l)
        d.polygon([(7, 15), (36, 15), (33, 10), (10, 10)], fill=C("b42c2c"), outline=gold)

    # Cụm Nỏ trên đỉnh (rung nhẹ khung f==1)
    by = 8 + (1 if f == 1 else 0)
    d.arc([11, by - 3, 32, by + 9], 190, 350, fill=gold_l if tier >= 2 else wood_l, width=2)
    d.line([(22, by - 5), (22, by + 7)], fill=gold_l, width=2)
    d.point([22, by - 5], fill=jade_l)
    if tier >= 3:
        d.point([16, by - 3], fill=jade_l)
        d.point([28, by - 3], fill=jade_l)
    return _with_shadow(outline(img), 6, 33, 37, 42, 95)


def _draw_bai_coc(f, tier):
    img, d = canvas(44, 44)
    w_d, w, w_l = C("164a6c"), C("22749c"), C("68d8f8")
    wood_d, wood, steel = C("462814"), C("7a4a24"), C("dce6f4")
    gold_l = C("fff098")

    # Hồ xoáy nước Bạch Đằng
    d.ellipse([4, 21, 39, 39], fill=w_d, outline=C("284052"))
    d.ellipse([6, 23, 37, 37], fill=w)
    ang_off = 35 if f == 1 else 0
    d.arc([9, 25, 34, 35], 10 + ang_off, 190 + ang_off, fill=w_l, width=2 if tier >= 2 else 1)

    stakes = [(12, 13, 2), (22, 8, 0), (31, 13, -2), (17, 19, 1), (27, 19, -1)]
    if tier >= 2:
        stakes += [(8, 22, 2), (35, 22, -2)]
    for sx, sy, lean in stakes:
        d.line([(sx, 32), (sx + lean, sy)], fill=wood_d, width=3)
        d.line([(sx, 32), (sx + lean, sy)], fill=wood, width=1)
        if tier >= 2:
            d.polygon([(sx + lean - 1, sy + 2), (sx + lean, sy - 3), (sx + lean + 2, sy + 2)], fill=steel)
    if tier >= 3:
        # Bùa vàng & xoáy thủy long quanh cọc chính
        d.point([22, 6 - (1 if f == 1 else 0)], fill=C("98ffff"))
        d.arc([13, 18, 30, 28], 180 + ang_off, 360 + ang_off, fill=gold_l, width=1)
    return _with_shadow(outline(img), 4, 29, 39, 41, 80)


def _draw_phao_dai(f, tier):
    img, d = canvas(44, 44)
    stone_d, stone, stone_l = C("464648"), C("747478"), C("a4a4aa")
    gun_d, gun, gun_l = C("242832"), C("4a5264"), C("828ca2")
    sand, sand_d = C("b89862"), C("6e5634")
    gold_l = C("ffe464")
    _tower_base_stone(d, stone_d, stone, stone_l, C("8e94a0"))

    if tier == 1:
        # Ụ bao cát + 1 nòng pháo
        for bx in (8, 16, 24, 30):
            d.rounded_rectangle([bx, 24, bx + 7, 30], 2, fill=sand, outline=sand_d)
        d.line([(20, 24), (31, 10)], fill=gun_d, width=6)
        d.line([(20, 24), (31, 10)], fill=gun_l, width=2)
    elif tier == 2:
        # Lô cốt bê tông + pháo nòng dài
        d.rounded_rectangle([9, 19, 34, 33], 3, fill=stone, outline=stone_d)
        d.rectangle([13, 23, 30, 26], fill=C("1a181c"))
        d.line([(21, 21), (34, 7)], fill=gun_d, width=7)
        d.line([(21, 21), (34, 7)], fill=gun_l, width=3)
    else:
        # Pháo Đài Sao Vàng Điện Biên + 2 nòng pháo + đạn dự trữ
        d.rounded_rectangle([7, 17, 36, 33], 3, fill=C("5a6246"), outline=C("2c3222"))
        d.rectangle([14, 23, 29, 29], fill=C("c82828"), outline=gold_l)
        d.point([22, 26], fill=gold_l)
        d.line([(16, 18), (27, 6)], fill=gun_d, width=6)
        d.line([(16, 18), (27, 6)], fill=gun_l, width=2)
        d.line([(25, 18), (36, 6)], fill=gun_d, width=6)
        d.line([(25, 18), (36, 6)], fill=gun_l, width=2)
    if f == 1:
        d.ellipse([30 if tier < 3 else 34, 4, 34 if tier < 3 else 39, 9], fill=C("ffaa38", 180))
    return _with_shadow(outline(img), 5, 32, 38, 42, 95)


def _draw_lo_ren(f, tier):
    img, d = canvas(44, 44)
    brick_d, brick, brick_l = C("56221c"), C("944438"), C("c26252")
    fire_d, fire, fire_l = C("ea4820"), C("ff8828"), C("fff078")
    iron_d, iron, iron_l = C("383c48"), C("6c7488"), C("bac4dc")
    gold, gold_l = C("d89e36"), C("fff2a0")
    _tower_base_stone(d, C("484440"), C("78726a"), C("a49c92"), gold if tier >= 2 else C("8a6a44"))

    # Thân lò rèn
    d.rectangle([7, 13, 25, 33], fill=brick, outline=brick_d)
    d.line([(8, 14), (24, 14)], fill=brick_l)
    d.rectangle([9, 5, 16, 13], fill=brick_d)
    if tier >= 2:
        d.rectangle([18, 7, 23, 13], fill=brick_d)
    # Cửa lò rực lửa nhấp nháy giữa f=0 / f=1
    d.rectangle([11, 21, 21, 31], fill=C("221010"))
    fh = 22 if f == 0 else 20
    d.polygon([(12, 31), (16, fh), (20, 31)], fill=fire)
    d.polygon([(14, 31), (16, fh + 3), (18, 31)], fill=fire_l)
    # Khói/tia lửa từ ống khói
    d.ellipse([10 + f * 2, 2, 14 + f * 2, 5], fill=C("ffe278" if tier >= 3 else "d8d0dc", 170))
    # Đe rèn bên phải
    d.rectangle([26, 25, 37, 29], fill=iron, outline=iron_d)
    d.line([(27, 25), (36, 25)], fill=iron_l)
    d.rectangle([29, 29, 34, 33], fill=iron_d)
    if tier >= 3:
        # Búa thần lơ lửng phát sáng vàng
        hy = 13 + (1 if f == 1 else -1)
        d.line([(32, hy + 3), (32, hy + 10)], fill=gold, width=2)
        d.rectangle([28, hy, 36, hy + 4], fill=gold_l, outline=gold)
    return _with_shadow(outline(img), 5, 32, 38, 42, 95)


def build_coloa_towers():
    drawers = {
        "luy_tre": _draw_luy_tre,
        "no_than": _draw_no_than,
        "bai_coc": _draw_bai_coc,
        "phao_dai": _draw_phao_dai,
        "lo_ren": _draw_lo_ren,
    }
    for short, fn in drawers.items():
        for tier in (1, 2, 3):
            frames = [fn(0, tier), fn(1, tier)]
            save(sheet(frames), f"world/tower_{short}_t{tier}.png")
        # Biểu tượng đơn (frame 0 của cấp 2) dùng cho thanh xây dựng / preview
        save(fn(0, 2), f"world/tower_{short}.png")


def build():
    build_coloa_bg()
    build_gate_arch()
    build_coloa_core()
    build_coloa_towers()


if __name__ == "__main__":
    build()
    print("Đã vẽ xong bộ pixel art Thành Cổ Loa!")
