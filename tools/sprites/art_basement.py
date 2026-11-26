"""Vẽ đồ họa pixel art cho Tầng Hầm Chiến Tích (phong cách ấm áp cổ điển đồng bộ với Sảnh Chính):
  - world/basement_bg.png             (880x560): Hầm đá chiến tích với vòm gạch, sàn đá phiến, thảm đỏ-vàng, bệ trưng bày & ánh đuốc ấm
  - world/lobby_stairs_down.png       (48x44):  Lối cầu thang đá đi xuống Tầng Hầm đặt ở Đại Sảnh
  - world/basement_stairs_up.png      (56x54):  Cầu thang đá & gỗ sơn son đi lên Đại Sảnh
  - world/basement_trophy_stele.png   (48x56):  Bia Thành Tựu rùa đá vàng rực & lư hương
  - world/basement_blueprint_desk.png (56x44):  Bàn Bản Vẽ gỗ gụ trải cuộn bản vẽ phát sáng & đèn đồng
  - world/basement_armory_shelf.png   (56x48):  Tủ Bảo Tàng Binh Khí 3 tầng mái đình trưng bày thần binh
"""
import math
import random
from px import hexc, shade, outline, auto_shade, save, canvas, Image, ImageDraw


def _c(h, a=255):
    return hexc(h, a)


def _lerp(c1, c2, k):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * k) for i in range(3)) + (255,)


def _with_shadow(outlined_img, sx0, sy0, sx1, sy1, alpha=95):
    w, h = outlined_img.size
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(base)
    sd.ellipse([sx0, sy0, sx1, sy1], fill=(16, 10, 22, alpha))
    base.alpha_composite(outlined_img)
    return base


def _draw_tiled_floor(d, rng, x0, y0, x1, y1, col, col_l, col_d, grout, tile=18, crack_rate=0.07):
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
            b = col if r < 0.70 else (_lerp(col, col_d, 0.24) if r < 0.87 else _lerp(col, col_l, 0.22))
            d.rectangle([tx0, ty0, tx1, ty1], fill=b)
            d.line([(tx0, ty0), (tx1, ty0)], fill=_lerp(b, col_l, 0.50))
            d.line([(tx0, ty0), (tx0, ty1)], fill=_lerp(b, col_l, 0.28))
            d.line([(tx0, ty1), (tx1, ty1)], fill=_lerp(b, col_d, 0.58))
            if rng.random() < crack_rate and tx1 - tx0 > 6 and ty1 - ty0 > 6:
                cx = rng.randint(tx0 + 2, tx1 - 3)
                cy = rng.randint(ty0 + 2, ty1 - 3)
                d.line([(cx, cy), (cx + 3, cy + 2)], fill=_lerp(b, col_d, 0.72))


def _draw_wood_platform(d, x0, y0, x1, y1, plank_h=6):
    wood, w_l, w_d = _c("865630"), _c("aa7442"), _c("54321a")
    d.rectangle([x0, y0, x1, y1], fill=w_d)
    for i, y in enumerate(range(y0 + 1, y1 - 2, plank_h)):
        py1 = min(y1 - 2, y + plank_h - 2)
        b = wood if i % 2 == 0 else _lerp(wood, w_d, 0.16)
        d.rectangle([x0 + 1, y, x1 - 1, py1], fill=b)
        d.line([(x0 + 1, y), (x1 - 1, y)], fill=_lerp(b, w_l, 0.48))
        for x in range(x0 + 12 + (i * 27) % 40, x1 - 4, 40):
            d.line([(x, y), (x, py1)], fill=w_d)
    d.rectangle([x0, y0, x1, y1], outline=_c("3c2010"))
    d.rectangle([x0 + 1, y1 + 1, x1 - 1, y1 + 5], fill=_c("442616"))
    d.line([(x0 + 1, y1 + 1), (x1 - 1, y1 + 1)], fill=_c("b8844c"))


def _draw_carpet(d, x0, y0, x1, y1, main="8a2228", border="e6b44c", trim="52141a"):
    d.rectangle([x0, y0, x1, y1], fill=_c(trim))
    d.rectangle([x0 + 2, y0 + 2, x1 - 2, y1 - 2], fill=_c(main))
    d.rectangle([x0 + 4, y0 + 4, x1 - 4, y1 - 4], outline=_c(border))
    d.rectangle([x0 + 7, y0 + 7, x1 - 7, y1 - 7], outline=_c("c48230"))


def _draw_glow(img, px, cx, cy, r=48, warm=(255, 200, 115), strength=0.18):
    w, h = img.size
    for y in range(max(0, cy - r), min(h, cy + r + 1)):
        for x in range(max(0, cx - r), min(w, cx + r + 1)):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                k = (1.0 - math.sqrt(d2) / r) * strength
                cr, cg, cb, ca = px[x, y]
                nr = min(255, int(cr + (warm[0] - cr) * k))
                ng = min(255, int(cg + (warm[1] - cg) * k))
                nb = min(255, int(cb + (warm[2] - cb) * k))
                px[x, y] = (nr, ng, nb, ca)


def build_basement_bg():
    """Nền Tầng Hầm Chiến Tích 880x560.
    Tâm bản đồ (440, 280) tương ứng world (680, 1180) khi đặt tại BASEMENT_ORIGIN=(240, 900).
      - Cầu thang lên: (440, 72)
      - Bia Thành Tựu: (190, 270)
      - Bàn Bản Vẽ: (440, 375)
      - Bảo Tàng Binh Khí: (690, 270)
    """
    W, H = 880, 560
    rng = random.Random(2027)
    img = Image.new("RGBA", (W, H), _c("18121c"))
    d = ImageDraw.Draw(img)

    # Sàn đá hầm ấm áp (tông đá nâu-xám cổ kính, sáng ấm hơn ngục tối)
    _draw_tiled_floor(d, rng, 18, 52, W - 18, H - 18, _c("6e625c"), _c("908278"), _c("4c4240"), _c("342c2e"), tile=20, crack_rate=0.07)

    # Tường đá bao quanh & vòm hầm phía Bắc
    wall_dark = _c("2c222a")
    wall_mid = _c("4a3c42")
    wall_top = _c("6e6264")
    wall_hi = _c("9a8c88")
    # Tường Bắc dày (0..52) với hàng gạch vòm hầm & xà gỗ lim
    d.rectangle([0, 0, W, 52], fill=wall_mid)
    for row, wy in enumerate(range(12, 48, 12)):
        off = 14 if row % 2 else 0
        for wx in range(-off, W, 28):
            d.rectangle([wx + 1, wy + 1, wx + 26, wy + 10], fill=_c("54464c") if (wx + wy) % 3 != 0 else _c("463a40"))
            d.line([(wx + 1, wy + 1), (wx + 26, wy + 1)], fill=wall_top)
    d.rectangle([0, 0, W, 10], fill=wall_dark)
    d.rectangle([0, 10, W, 14], fill=wall_top)
    d.line([(0, 10), (W, 10)], fill=wall_hi)
    # Gờ đá chân tường Bắc & các vòm cuốn trang trí
    d.rectangle([16, 48, W - 16, 54], fill=_c("3c3036"))
    d.line([(16, 48), (W - 16, 48)], fill=_c("847672"))
    for ax in range(90, W - 70, 140):
        if abs(ax - 440) < 70:
            continue
        d.pieslice([ax - 24, 16, ax + 24, 52], 180, 360, fill=_c("281e24"), outline=_c("7a6c68"))
        d.rectangle([ax - 22, 34, ax + 22, 48], fill=_c("281e24"))
        # Cờ chiến tích / khiên trang trí treo trong hốc vòm
        d.polygon([(ax - 10, 24), (ax + 10, 24), (ax + 8, 40), (ax, 44), (ax - 8, 40)], fill=_c("8c2228"), outline=_c("e2b046"))
        d.ellipse([ax - 4, 29, ax + 4, 37], fill=_c("e2b046"))

    # Tường Tây, Đông, Nam
    for rx0, ry0, rx1, ry1 in ((0, 0, 18, H), (W - 18, 0, W, H), (0, H - 18, W, H)):
        d.rectangle([rx0, ry0, rx1, ry1], fill=wall_mid)
        d.rectangle([rx0, ry0, rx1, ry0 + 5], fill=wall_top)
        d.line([(rx0, ry0), (rx1, ry0)], fill=wall_hi)
    d.rectangle([18, 52, W - 18, H - 18], outline=_c("261c22"))

    # Cột gỗ lim & chân tảng đá dọc tường
    for px0 in (24, 240, 360, 520, 640, 840):
        d.rectangle([px0 - 4, 14, px0 + 4, 54], fill=_c("784224"), outline=_c("3c1e10"))
        d.line([(px0 - 3, 15), (px0 - 3, 52)], fill=_c("a8683a"))
        d.rectangle([px0 - 6, 48, px0 + 6, 54], fill=_c("8e867c"))

    # Thảm đỏ-vàng chữ thập nối cầu thang <-> tâm hầm <-> 3 khu trưng bày
    _draw_carpet(d, 406, 68, 474, 412)
    _draw_carpet(d, 150, 238, 730, 302)
    # Tua vàng dọc mép thảm
    for ty in range(74, 406, 16):
        d.rectangle([404, ty, 406, ty + 6], fill=_c("e0ad42"))
        d.rectangle([474, ty, 476, ty + 6], fill=_c("e0ad42"))
    for tx in range(158, 724, 18):
        d.rectangle([tx, 236, tx + 6, 238], fill=_c("e0ad42"))
        d.rectangle([tx, 302, tx + 6, 304], fill=_c("e0ad42"))

    # Sân nền Cầu Thang (440, 72)
    _draw_tiled_floor(d, rng, 384, 52, 496, 118, _c("8c8478"), _c("b2a99a"), _c("5c544c"), _c("3c3632"), tile=14)
    d.rectangle([383, 52, 497, 119], outline=_c("e0ad42"))

    # Huy hiệu Trống Đồng khảm đá giữa Tầng Hầm (440, 270)
    cx, cy = 440, 270
    for rad, col in ((48, _c("4a2a14")), (43, _c("d4a442")), (34, _c("7e5222")), (24, _c("e4bc52")), (13, _c("742026")), (6, _c("ffe280"))):
        d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=col)
    for i in range(12):
        a = i / 12.0 * math.tau
        d.line([(cx + math.cos(a) * 14, cy + math.sin(a) * 14),
                (cx + math.cos(a) * 33, cy + math.sin(a) * 33)], fill=_c("ffe280"))

    # 1. Bệ Tây (190, 270): Bia Thành Tựu
    _draw_tiled_floor(d, rng, 118, 206, 262, 336, _c("867e74"), _c("aba296"), _c("5c554e"), _c("3c3632"), tile=16)
    d.rectangle([117, 205, 263, 337], outline=_c("d4a23e"))
    _draw_carpet(d, 146, 234, 234, 314, main="7e1e26", border="ecc054", trim="4c1218")

    # 2. Bệ Nam (440, 375): Bàn Bản Vẽ
    _draw_wood_platform(d, 352, 332, 528, 434, plank_h=6)
    _draw_carpet(d, 378, 348, 502, 418, main="1e4458", border="e8b84e", trim="122a38")

    # 3. Bệ Đông (690, 270): Bảo Tàng Binh Khí
    _draw_wood_platform(d, 616, 206, 764, 336, plank_h=6)
    _draw_carpet(d, 642, 234, 738, 314, main="6c2026", border="ecc054", trim="421216")

    # Các góc trang trí: thùng gỗ, chậu đồng, giá cờ nhỏ (không cản đường đi)
    for bx, by in ((46, 82), (834, 82), (46, 514), (834, 514)):
        d.ellipse([bx - 12, by - 8, bx + 12, by + 8], fill=_c("5e381e"), outline=_c("2c180c"))
        d.ellipse([bx - 9, by - 6, bx + 9, by + 4], fill=_c("8c5830"))
        d.ellipse([bx - 5, by - 4, bx + 5, by + 2], fill=_c("c48e48"))

    # Giá đuốc gắn tường (10 điểm quanh hầm)
    torch_spots = [
        (300, 46), (580, 46), (120, 46), (760, 46),
        (24, 170), (24, 390), (856, 170), (856, 390),
        (260, 536), (620, 536),
    ]
    for tx, ty in torch_spots:
        d.rectangle([tx - 3, ty - 4, tx + 3, ty + 4], fill=_c("4e484a"), outline=_c("201a1e"))
        d.ellipse([tx - 3, ty - 8, tx + 3, ty - 2], fill=_c("ff8e2c"))
        d.point([tx, ty - 6], fill=_c("fff4a8"))

    px = img.load()
    # Bóng đổ dọc tường Bắc & Tây
    for dy in range(7):
        k = 0.28 * (1.0 - dy / 7.0)
        y = 52 + dy
        for x in range(18, W - 18):
            cr, cg, cb, ca = px[x, y]
            px[x, y] = (int(cr * (1.0 - k)), int(cg * (1.0 - k)), int(cb * (1.0 - k)), ca)
    for dx in range(6):
        k = 0.20 * (1.0 - dx / 6.0)
        x = 18 + dx
        for y in range(52, H - 18):
            cr, cg, cb, ca = px[x, y]
            px[x, y] = (int(cr * (1.0 - k)), int(cg * (1.0 - k)), int(cb * (1.0 - k)), ca)

    # Ánh sáng ấm tại các khu trung tâm, 3 bệ và các ngọn đuốc
    for (lx, ly, rad, col, st_k) in [
        (440, 72, 68, (255, 224, 150), 0.20),
        (440, 270, 82, (255, 210, 125), 0.18),
        (190, 270, 68, (255, 218, 130), 0.20),
        (440, 375, 68, (140, 220, 255), 0.16),
        (690, 270, 68, (255, 185, 110), 0.20),
    ]:
        _draw_glow(img, px, lx, ly, rad, col, st_k)
    for tx, ty in torch_spots:
        _draw_glow(img, px, tx, ty, 44, (255, 175, 85), 0.16)

    save(img, "world/basement_bg.png")


def build_lobby_stairs_down():
    """Lối cầu thang đá đi xuống Tầng Hầm đặt ở Đại Sảnh (48x44)."""
    img, d = canvas(48, 44)
    st, sl, sd = _c("868078"), _c("b6afa4"), _c("4a4440")
    red, r_l, r_d = _c("a8282e"), _c("d84c48"), _c("5e1418")
    gold, gold_l = _c("e4b242"), _c("fff0a0")

    # Khung viền đá hình chữ U mở xuống dưới
    d.rectangle([7, 5, 40, 38], fill=_c("1a121c"))
    d.rectangle([5, 3, 42, 9], fill=st)
    auto_shade(img, st, sl, sd)
    d.rectangle([5, 9, 10, 39], fill=st, outline=sd)
    d.rectangle([37, 9, 42, 39], fill=st, outline=sd)
    d.line([(6, 9), (6, 38)], fill=sl)
    d.line([(38, 9), (38, 38)], fill=sl)

    # 5 bậc đá đi xuống tối dần + ánh đèn hắt từ tầng hầm
    step_cols = ["a29a8e", "867e74", "6a625a", "504844", "383032"]
    for i, sc in enumerate(step_cols):
        y0 = 10 + i * 5
        d.rectangle([11, y0, 36, y0 + 4], fill=_c(sc))
        d.line([(11, y0), (36, y0)], fill=shade(_c(sc), 0.22))
        d.line([(11, y0 + 4), (36, y0 + 4)], fill=shade(_c(sc), -0.35))
    # Ánh sáng vàng ấm hắt lên từ dưới hầm
    d.rectangle([13, 31, 34, 37], fill=_c("7a4a1e"))
    d.rectangle([16, 33, 31, 37], fill=_c("d88a2e"))
    d.rectangle([19, 35, 28, 37], fill=_c("ffd868"))

    # Trụ sơn son & chóp đồng vàng 2 bên cầu thang
    for px0 in (4, 37):
        d.rectangle([px0, 2, px0 + 6, 12], fill=red, outline=r_d)
        d.line([(px0 + 1, 3), (px0 + 1, 11)], fill=r_l)
        d.rectangle([px0 + 1, 0, px0 + 5, 3], fill=gold)
        d.point([px0 + 2, 1], fill=gold_l)
        d.rectangle([px0, 34, px0 + 6, 40], fill=red, outline=r_d)
        d.rectangle([px0 + 1, 32, px0 + 5, 34], fill=gold)

    # Mũi tên đá vàng khắc trên thanh đá trên cùng chỉ xuống
    d.polygon([(20, 5), (27, 5), (23, 8)], fill=gold_l)

    save(_with_shadow(outline(img), 4, 36, 43, 42, 95), "world/lobby_stairs_down.png")


def build_basement_stairs_up():
    """Cầu thang đi lên Đại Sảnh từ Tầng Hầm (56x54)."""
    img, d = canvas(56, 54)
    st, sl, sd = _c("88827a"), _c("b8b2a6"), _c("4a4540")
    red, r_l, r_d = _c("a8282e"), _c("d84c48"), _c("5e1418")
    gold, gold_l = _c("e4b242"), _c("fff2a8")

    # Cổng vòm đá phía trên tỏa ánh sáng vàng ấm từ Đại Sảnh
    d.pieslice([10, 2, 45, 30], 180, 360, fill=st, outline=sd)
    d.rectangle([10, 16, 45, 48], fill=st, outline=sd)
    d.pieslice([14, 6, 41, 28], 180, 360, fill=_c("ffe28a"))
    d.rectangle([14, 17, 41, 28], fill=_c("ffd068"))
    d.ellipse([20, 10, 35, 22], fill=_c("fff8d0"))

    # 6 bậc thang đi lên sáng dần về phía vòm cổng
    steps = ["645c56", "7c746c", "948c82", "aba296", "c4baa8", "dfd4be"]
    for i, sc in enumerate(steps):
        y0 = 44 - i * 4
        d.rectangle([14, y0, 41, y0 + 3], fill=_c(sc))
        d.line([(14, y0), (41, y0)], fill=shade(_c(sc), 0.25))
        d.line([(14, y0 + 3), (41, y0 + 3)], fill=shade(_c(sc), -0.30))

    # Lan can gỗ sơn son hai bên + chóp sen vàng
    for bx in (7, 42):
        d.rectangle([bx, 18, bx + 6, 48], fill=red, outline=r_d)
        d.line([(bx + 1, 19), (bx + 1, 47)], fill=r_l)
        d.rectangle([bx + 1, 15, bx + 5, 18], fill=gold)
        d.point([bx + 2, 16], fill=gold_l)
        d.rectangle([bx - 1, 46, bx + 7, 50], fill=sd)

    # Biển hoành phi nhỏ trên vòm cổng
    d.rectangle([19, 3, 36, 9], fill=_c("341414"), outline=gold)
    d.line([(22, 6), (33, 6)], fill=gold_l)

    save(_with_shadow(outline(img), 6, 45, 49, 52, 105), "world/basement_stairs_up.png")


def build_trophy_stele():
    """Bia Thành Tựu bằng đá cẩm thạch & rồng vàng + 2 đỉnh hương lửa thiêng (48x56)."""
    img, d = canvas(48, 56)
    st, sl, sd = _c("6c6874"), _c("9c96a4"), _c("3e3a44")
    gold, gold_l, gold_d = _c("e4b23c"), _c("fff29c"), _c("94621a")
    jade = _c("56d8b4")

    # Đế rùa đá chạm vàng
    d.rectangle([9, 47, 38, 52], fill=sd)
    d.ellipse([10, 40, 37, 50], fill=st)
    auto_shade(img, st, sl, sd)
    d.ellipse([19, 46, 28, 53], fill=sl)
    d.point([21, 49], fill=gold_l)
    d.point([26, 49], fill=gold_l)

    # Thân bia đá cao & trán bia rồng vàng
    d.rectangle([13, 11, 34, 42], fill=st)
    d.pieslice([13, 3, 34, 21], 180, 360, fill=st)
    auto_shade(img, st, sl, sd)

    # Viền khung vàng & ngọc bích trên đỉnh bia
    d.rectangle([15, 14, 32, 40], fill=_c("423e4a"), outline=gold_d)
    d.rectangle([16, 15, 31, 39], outline=gold)
    d.pieslice([16, 5, 31, 17], 180, 360, fill=gold_d)
    d.ellipse([21, 6, 26, 11], fill=gold)
    d.ellipse([22, 7, 25, 10], fill=jade)

    # Huy chương vàng & 3 hàng chữ vàng khắc trên mặt bia
    d.ellipse([21, 16, 26, 21], fill=gold, outline=gold_l)
    for y in range(24, 37, 4):
        d.line([(19, y), (28, y)], fill=gold_l if y == 24 else _c("e6cf88"))
        d.point([18, y], fill=gold)
        d.point([29, y], fill=gold)

    # 2 đỉnh đồng cháy lửa vàng rực hai bên chân bia
    for lx in (6, 36):
        d.rectangle([lx, 44, lx + 5, 49], fill=_c("b87636"), outline=_c("5e3416"))
        d.rectangle([lx + 1, 42, lx + 4, 44], fill=gold)
        d.ellipse([lx + 1, 37, lx + 4, 42], fill=_c("ff942c"))
        d.point([lx + 2, 39], fill=_c("fff8b0"))

    save(_with_shadow(outline(img), 6, 48, 41, 55, 105), "world/basement_trophy_stele.png")


def build_blueprint_desk():
    """Bàn Bản Vẽ gỗ lim với cuộn giấy xanh phát sáng, compa & đèn dầu đồng (56x44)."""
    img, d = canvas(56, 44)
    wood, w_l, w_d = _c("864e2a"), _c("b47442"), _c("4a2814")
    gold, gold_l = _c("e4b242"), _c("fff2a8")
    bp, bp_l, bp_d = _c("246494"), _c("48a4d8"), _c("163a5a")

    # Chân bàn & thanh ngang dưới
    for lx in (8, 43):
        d.rectangle([lx, 24, lx + 4, 39], fill=w_d)
        d.line([(lx + 1, 24), (lx + 1, 38)], fill=wood)
    d.rectangle([10, 32, 45, 35], fill=w_d)

    # Mặt bàn gỗ lớn viền nẹp đồng
    d.rectangle([5, 14, 50, 28], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([5, 14, 50, 18], fill=w_l)
    d.rectangle([5, 25, 50, 29], fill=w_d)
    for cx, cy in ((6, 15), (47, 15), (6, 25), (47, 25)):
        d.rectangle([cx, cy, cx + 2, cy + 2], fill=gold)

    # Tờ bản vẽ kiến trúc xanh lam mở rộng trên bàn + hình vẽ kiếm phát sáng trắng-vàng
    d.polygon([(14, 12), (40, 11), (42, 23), (12, 24)], fill=bp, outline=_c("d6ecff"))
    d.rectangle([15, 14, 39, 21], fill=bp_d)
    # Đường nét bản vẽ vũ khí phát sáng trên giấy xanh
    d.line([(18, 19), (33, 15)], fill=_c("9ae8ff"), width=1)
    d.line([(20, 16), (22, 20)], fill=gold_l)
    d.point([34, 15], fill=_c("ffffff"))
    d.ellipse([27, 16, 31, 20], outline=bp_l)
    # Cục chặn giấy bằng đồng 4 góc
    for px0, py0 in ((13, 12), (39, 11), (12, 22), (40, 21)):
        d.point([px0, py0], fill=gold_l)

    # Cuộn bản vẽ phụ bên trái & đèn dầu đồng bên phải
    d.rectangle([7, 16, 11, 22], fill=_c("e8dcbe"), outline=w_d)
    d.rectangle([8, 17, 10, 21], fill=_c("3c82b4"))
    d.rectangle([43, 16, 48, 22], fill=_c("c48436"), outline=w_d)
    d.ellipse([44, 11, 47, 16], fill=_c("ffaa38"))
    d.point([45, 13], fill=_c("fff8b8"))

    # Giá ống đựng cuộn bản vẽ đặt cạnh chân bàn bên phải
    d.rectangle([48, 27, 53, 38], fill=_c("5e361c"), outline=w_d)
    for rx, col in ((49, "68b4e4"), (51, "f2d282")):
        d.line([(rx, 24), (rx, 29)], fill=_c(col))

    save(_with_shadow(outline(img), 4, 34, 52, 42, 95), "world/basement_blueprint_desk.png")


def build_armory_shelf():
    """Tủ Bảo Tàng Binh Khí 3 tầng mái đình sơn son trưng bày thần binh (56x48)."""
    img, d = canvas(56, 48)
    wood, w_l, w_d = _c("743822"), _c("a45a36"), _c("441e12")
    red, r_l, r_d = _c("9c242a"), _c("d44844"), _c("581418")
    gold, gold_l = _c("e6b442"), _c("fff2a8")

    # Mái đình cong trang trí trên nóc tủ
    d.polygon([(4, 10), (51, 10), (53, 6), (44, 7), (28, 2), (12, 7), (2, 6)], fill=red, outline=r_d)
    d.line([(12, 7), (28, 2), (44, 7)], fill=r_l)
    d.rectangle([23, 5, 32, 9], fill=gold)

    # Khung tủ gỗ sơn son 3 tầng nền nhung đỏ sẫm
    d.rectangle([7, 10, 48, 43], fill=wood, outline=w_d)
    d.rectangle([9, 12, 46, 41], fill=_c("2e1418"))
    for sy in (11, 21, 31, 41):
        d.rectangle([7, sy, 48, sy + 2], fill=wood)
        d.line([(7, sy), (48, sy)], fill=w_l)
    # 2 cột son hai bên tủ
    for cx in (7, 46):
        d.rectangle([cx, 10, cx + 2, 43], fill=red)
        d.line([(cx, 10), (cx, 43)], fill=r_l)

    # Tầng 1: Kiếm thần vàng + Búa sét + Trượng ngọc
    d.line([(12, 19), (21, 14)], fill=_c("eaf2ff"), width=1)
    d.line([(11, 18), (13, 20)], fill=gold)
    d.rectangle([26, 14, 30, 17], fill=_c("70c8ff"), outline=_c("ffffff"))
    d.line([(28, 17), (28, 20)], fill=w_l)
    d.line([(36, 14), (43, 19)], fill=gold_l)
    d.ellipse([35, 13, 38, 16], fill=_c("56f0c0"))

    # Tầng 2: Khiên đồng + Cung vàng + Quả cầu tinh tú
    d.ellipse([12, 24, 19, 30], fill=gold, outline=gold_l)
    d.point([15, 27], fill=red)
    d.arc([23, 23, 32, 31], 210, 340, fill=gold_l)
    d.line([(24, 27), (31, 27)], fill=_c("d6e6f8"))
    d.ellipse([36, 24, 42, 30], fill=_c("8652e8"), outline=_c("d8b4ff"))
    d.point([38, 25], fill=_c("ffffff"))

    # Tầng 3: Súng thần cơ + Hộp ngọc + Lư hương nhỏ
    d.rectangle([12, 35, 22, 37], fill=_c("8492a8"), outline=_c("444e60"))
    d.rectangle([12, 37, 15, 39], fill=w_l)
    d.rectangle([26, 35, 32, 39], fill=gold, outline=w_d)
    d.point([29, 36], fill=_c("58f4c8"))
    d.rectangle([37, 36, 43, 40], fill=_c("c48436"), outline=w_d)
    d.point([40, 34], fill=_c("ffaa38"))

    # Chân đế tủ
    d.rectangle([9, 43, 14, 45], fill=w_d)
    d.rectangle([41, 43, 46, 45], fill=w_d)

    save(_with_shadow(outline(img), 5, 39, 50, 46, 100), "world/basement_armory_shelf.png")


def build():
    build_basement_bg()
    build_lobby_stairs_down()
    build_basement_stairs_up()
    build_trophy_stele()
    build_blueprint_desk()
    build_armory_shelf()


if __name__ == "__main__":
    build()
