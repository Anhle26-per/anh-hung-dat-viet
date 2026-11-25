"""Vẽ lại toàn bộ công trình và đồ trang trí chi tiết cho Sảnh Chính 4 phòng:
  - world/lobby_stele.png      (48x56): Bia đá Rùa Văn Miếu, trán bia rồng vàng, chữ khắc, bát hương
  - world/lobby_well.png       (3 khung 54x56 -> 162x56): Giếng Ước mái đình cong, tời gỗ, nước ngọc phát sáng
  - world/lobby_challenge.png  (52x52): Bảng Khiêu Chiến mái ngói, kích đồng tua đỏ, 3 tờ sớ niêm phong
  - world/lobby_forge.png      (3 khung 56x48 -> 168x48): Lò Rèn vòm gạch ống khói, bễ thổi, lửa bùng, đe + phôi thép đỏ
  - world/lobby_rack.png       (52x46): Giá Binh Khí 2 tầng sơn son phông lụa, kiếm/đao/kích/nỏ/khiên/ống tên
  - world/lobby_codex.png      (54x50): Tàng Kinh Các 3 tầng cuộn sách + bục đọc mở sách vàng & đèn dầu đồng
  - Đồ trang trí phòng: prop_tea_table, prop_war_map, prop_stone_lantern, prop_bench,
    prop_weapon_barrel, prop_coal_pile, prop_brazier (3 khung), prop_flag_stand
"""
from px import hexc, shade, outline, auto_shade, sheet, save, canvas, Image, ImageDraw


def _c(h, a=255):
    return hexc(h, a)


def _with_shadow(outlined_img, sx0, sy0, sx1, sy1, alpha=95):
    """Đặt bóng đổ tiếp đất êm bên dưới lớp viền ngoài của công trình."""
    w, h = outlined_img.size
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(base)
    sd.ellipse([sx0, sy0, sx1, sy1], fill=(16, 10, 22, alpha))
    base.alpha_composite(outlined_img)
    return base


def build_stele():
    """Bia Ghi Công kiểu Văn Miếu: rùa đá nâng bia trán rồng vàng, 48x56."""
    img, d = canvas(48, 56)
    st, sl, sd = _c("807d78"), _c("aea9a0"), _c("4f4c48")
    dark_st, dark_l, dark_d = _c("585552"), _c("7e7a74"), _c("363331")
    gold, gold_l, gold_d = _c("e0ac3c"), _c("ffe888"), _c("9c6a1e")

    # Đế rùa đá
    d.rectangle([10, 48, 37, 52], fill=dark_d)
    d.ellipse([11, 41, 36, 51], fill=dark_st)          # mai rùa
    auto_shade(img, dark_st, dark_l, dark_d)
    # Hoa văn lục giác trên mai rùa
    for hx in (17, 23, 29):
        d.line([(hx, 43), (hx + 2, 46), (hx, 49)], fill=dark_d)
    # Đầu rùa nhô về phía dưới-phải + 4 chân rùa
    d.ellipse([20, 47, 27, 53], fill=st)
    auto_shade(img, st, sl, sd)
    d.point([22, 50], fill=_c("18101e"))
    d.point([25, 50], fill=_c("18101e"))
    for lx in (13, 31):
        d.rectangle([lx, 48, lx + 3, 52], fill=st)

    # Thân bia đá dựng đứng & trán bia vòm cong
    d.rectangle([14, 11, 33, 42], fill=st)
    d.pieslice([14, 3, 33, 21], 180, 360, fill=st)
    auto_shade(img, st, sl, sd)

    # Viền khung khắc mặt bia + trán bia chạm vàng
    d.rectangle([16, 14, 31, 40], fill=_c("64615c"), outline=sd)
    d.rectangle([17, 15, 30, 39], outline=sl)
    d.pieslice([17, 6, 30, 17], 180, 360, fill=gold_d)
    d.ellipse([21, 7, 26, 12], fill=gold)
    d.point([23, 9], fill=gold_l)
    d.point([19, 11], fill=gold_l)
    d.point([28, 11], fill=gold_l)

    # Các dòng chữ khắc cổ (dạng cột dọc & tiêu đề vàng)
    d.rectangle([20, 16, 27, 18], fill=gold)
    for colx in (19, 22, 25, 28):
        for y in range(21, 37, 3):
            if (colx + y) % 5 != 0:
                d.rectangle([colx, y, colx + 1, y + 1], fill=sl if colx == 22 else _c("b8b2a2"))

    # Rêu xanh nhẹ ở chân bia & 2 bát hương đồng hai bên
    for mx, my in ((14, 39), (15, 40), (31, 41), (13, 44), (34, 45)):
        d.point([mx, my], fill=_c("55863e"))
    br, br_l, br_d = _c("b67438"), _c("e4a862"), _c("6e3e1c")
    for ix in (7, 37):
        d.rectangle([ix, 46, ix + 4, 50], fill=br)
        auto_shade(img, br, br_l, br_d)
        d.line([(ix + 2, 43), (ix + 2, 45)], fill=_c("d83e36"))
        d.point([ix + 2, 42], fill=_c("ffba48"))

    return _with_shadow(outline(img), 8, 49, 39, 55, 105)


def build_well():
    """Giếng Ước Cổ mái ngói cong, 3 khung nước lấp lánh (54x56 mỗi khung)."""
    frames = []
    roof, r_l, r_d = _c("8e2c26"), _c("bd463c"), _c("521818")
    wood, w_l, w_d = _c("8c5430"), _c("b67a48"), _c("58321c")
    st, sl, sd = _c("86827a"), _c("b4afa4"), _c("524e48")
    gold, gold_l = _c("e4b042"), _c("fff0a0")

    for f in range(3):
        img, d = canvas(54, 56)
        # Vành đá bát giác & thân giếng rêu phong
        d.ellipse([10, 33, 43, 52], fill=sd)
        d.ellipse([10, 29, 43, 48], fill=st)
        auto_shade(img, st, sl, sd)
        # Gạch đá xếp quanh thành giếng
        for x in (14, 21, 28, 35):
            d.line([(x, 42), (x, 49)], fill=sd)
        for mx, my in ((13, 43), (14, 44), (38, 44), (24, 49), (25, 49)):
            d.point([mx, my], fill=_c("54863c"))

        # Lòng nước phát sáng ngọc lam động 3 khung
        d.ellipse([14, 31, 39, 43], fill=_c("143c4a"))
        w1 = _c("24788c") if f != 1 else _c("2b899c")
        w2 = _c("44b8cc") if f == 0 else (_c("58d2e2") if f == 1 else _c("3aa6bc"))
        d.ellipse([15, 32, 38, 42], fill=w1)
        d.ellipse([18 + f - 1, 34, 34 + f - 1, 40], fill=w2)
        d.ellipse([22, 35, 29, 38], fill=_c("9af4ff"))
        # Đốm sáng phép thuật nhấp nháy
        sp_pts = [((19, 36), (34, 38), (27, 28)),
                  ((21, 35), (32, 37), (24, 25)),
                  ((18, 38), (35, 35), (29, 26))][f]
        for sx, sy in sp_pts:
            d.point([sx, sy], fill=_c("e8ffff"))
            d.point([sx + 1, sy], fill=gold_l)

        # Cột son hai bên nâng mái + xà tời gỗ + gàu múc
        for cx in (11, 39):
            d.rectangle([cx, 15, cx + 3, 40], fill=_c("b6323a"))
            d.line([(cx, 15), (cx, 40)], fill=_c("e26054"))
            d.rectangle([cx - 1, 38, cx + 4, 41], fill=sl)
        d.rectangle([11, 21, 42, 23], fill=wood)
        d.rectangle([23, 19, 30, 24], fill=w_l)
        d.line([(26, 24), (26, 30)], fill=_c("c29e6c"))
        d.rectangle([24, 29, 28, 33], fill=wood, outline=w_d)

        # Mái ngói cong có đầu đao & hoành phi vàng ở giữa
        pts = [(6, 17), (47, 17), (51, 9), (40, 11), (27, 3), (13, 11), (2, 9)]
        d.polygon(pts, fill=roof)
        for rx in range(6, 48, 4):
            d.line([(rx, 10), (rx, 17)], fill=r_d)
            d.line([(rx + 1, 10), (rx + 1, 17)], fill=r_l)
        d.polygon([(27, 2), (12, 11), (41, 11)], fill=r_l)
        d.line([(5, 17), (48, 17)], fill=_c("3a1210"))
        d.line([(12, 11), (27, 2), (41, 11)], fill=gold)
        d.ellipse([25, 1, 29, 5], fill=gold)
        d.point([27, 2], fill=gold_l)
        d.point([2, 8], fill=gold)
        d.point([51, 8], fill=gold)

        frames.append(_with_shadow(outline(img), 8, 43, 45, 53, 95))
    return sheet(frames)


def build_challenge():
    """Bảng Khiêu Chiến mái ngói nhỏ, kích đồng & 3 sớ mật, 52x52."""
    img, d = canvas(52, 52)
    wood, w_l, w_d = _c("86502d"), _c("b27848"), _c("522e18")
    roof, r_l, r_d = _c("8e2c26"), _c("bd463c"), _c("521818")
    gold, gold_l = _c("e4b042"), _c("fff0a0")

    # Hai trụ cột gỗ + thanh chắn ngang + mái che nhỏ
    for cx in (11, 38):
        d.rectangle([cx, 12, cx + 3, 47], fill=wood)
        auto_shade(img, wood, w_l, w_d)
        d.rectangle([cx - 1, 45, cx + 4, 48], fill=_c("7a766e"))
    d.rectangle([10, 14, 41, 38], fill=_c("5e201e"))
    d.rectangle([12, 16, 39, 36], fill=_c("3a1d14"), outline=gold)

    # Mái ngói cong trên đầu bảng
    d.polygon([(5, 15), (46, 15), (49, 9), (41, 10), (26, 6), (10, 10), (2, 9)], fill=roof)
    for rx in range(7, 45, 4):
        d.line([(rx, 10), (rx, 15)], fill=r_d)
        d.line([(rx + 1, 10), (rx + 1, 15)], fill=r_l)
    d.rectangle([19, 12, 32, 15], fill=gold)
    d.point([3, 8], fill=gold_l)
    d.point([48, 8], fill=gold_l)

    # 3 tờ sớ thử thách dán trên bảng (trái, giữa, phải)
    scrolls = [
        (13, 18, 20, 32, "f2e4c2", "d43632"),
        (22, 17, 29, 34, "f7ecd0", "e4a428"),
        (31, 19, 38, 32, "e8dcc0", "2e8a5c"),
    ]
    for sx0, sy0, sx1, sy1, paper, seal in scrolls:
        d.rectangle([sx0, sy0, sx1, sy1], fill=_c(paper), outline=_c("9c7c52"))
        d.rectangle([sx0 + 2, sy0 + 1, sx0 + 4, sy0 + 2], fill=_c(seal))
        for ly in range(sy0 + 4, sy1 - 2, 3):
            d.line([(sx0 + 2, ly), (sx1 - 2, ly)], fill=_c("6a4c32"))

    # Cây kích đồng dựng chéo bên cạnh + tua đỏ
    d.line([(44, 7), (44, 47)], fill=w_d, width=2)
    d.polygon([(44, 2), (42, 8), (47, 7)], fill=_c("d8dce8"))
    d.line([(44, 8), (48, 12)], fill=_c("d83a34"), width=2)
    d.line([(43, 10), (43, 16)], fill=_c("d83a34"))

    return _with_shadow(outline(img), 8, 44, 46, 50, 95)


def build_forge():
    """Lò Rèn Đại Việt vòm gạch, bễ thổi, lửa bùng & đe rèn kiếm nóng, 3 khung 56x48."""
    frames = []
    brick, b_l, b_d = _c("8c3e32"), _c("b65848"), _c("58221e")
    iron, i_l, i_d = _c("4c4a58"), _c("7e7c90"), _c("2a2834")
    wood, w_l, w_d = _c("86502d"), _c("b27848"), _c("522e18")

    for f in range(3):
        img, d = canvas(56, 48)
        # Thùng nước tôi thép (phải trên) & bễ da (trái)
        d.rectangle([3, 27, 10, 40], fill=wood)
        auto_shade(img, wood, w_l, w_d)
        d.polygon([(3, 28), (11, 24 + (f % 2)), (11, 33)], fill=_c("764628"))
        d.line([(10, 32), (14, 34)], fill=iron)

        # Khối lò gạch lớn + ống khói cao
        d.rectangle([13, 3, 21, 14], fill=brick)
        d.rectangle([12, 2, 22, 4], fill=b_d)
        d.rectangle([10, 14, 30, 41], fill=brick)
        auto_shade(img, brick, b_l, b_d)
        for ry in range(16, 40, 4):
            d.line([(10, ry), (30, ry)], fill=b_d)
            for rx in range(12 + (ry % 8) // 2, 29, 6):
                d.line([(rx, ry), (rx, ry + 3)], fill=b_d)

        # Miệng lò vòm đá + lửa hồng bùng cháy 3 khung
        d.pieslice([14, 21, 26, 35], 180, 360, fill=_c("4e4a4c"))
        d.rectangle([14, 28, 26, 40], fill=_c("221012"))
        d.rectangle([13, 39, 27, 42], fill=_c("5e5a5c"))
        peak = [23, 21, 24][f]
        d.polygon([(15, 39), (18, peak + 2), (20, peak), (23, peak + 3), (25, 39)], fill=_c("ff6c22"))
        d.polygon([(17, 39), (20, peak + 5), (23, 39)], fill=_c("ffbe38"))
        d.polygon([(19, 39), (20, peak + 8), (21, 39)], fill=_c("fff6a8"))
        # Tàn lửa bay ra cửa lò & ống khói
        d.point([16 + f, 1], fill=_c("ffe270"))
        d.point([18 - f, 0], fill=_c("ff8e30"))
        d.point([28 + f, 30 - f * 2], fill=_c("ffe066"))

        # Khúc gỗ kê đe + Đe sừng rèn kiếm nóng (bên phải)
        d.rectangle([37, 34, 45, 42], fill=wood)
        d.rectangle([38, 31, 44, 34], fill=iron)
        d.polygon([(32, 27), (47, 27), (49, 29), (44, 31), (36, 31)], fill=iron)
        d.line([(32, 27), (47, 27)], fill=i_l)
        # Thanh kiếm đang nung đỏ trên mặt đe + búa tạ dựng bên cạnh
        d.rectangle([35, 25, 45, 26], fill=_c("ff6224") if f % 2 == 0 else _c("ff9e36"))
        d.point([40, 25], fill=_c("fff4a0"))
        d.line([(47, 19), (51, 33)], fill=w_d, width=2)
        d.rectangle([45, 17, 50, 20], fill=i_l, outline=i_d)

        # Kìm kẹp & thùng nước bên góc phải
        d.ellipse([48, 34, 54, 42], fill=wood)
        d.ellipse([49, 34, 53, 36], fill=_c("3c829e"))

        frames.append(_with_shadow(outline(img), 4, 38, 53, 45, 95))
    return sheet(frames)


def build_rack():
    """Giá Binh Khí 2 tầng sơn son phông lụa đỏ trưng kiếm, đao, nỏ, khiên, 52x46."""
    img, d = canvas(52, 46)
    wood, w_l, w_d = _c("88502c"), _c("b47a46"), _c("522c16")
    gold, gold_l = _c("e4b042"), _c("fff0a0")
    steel, st_l, st_d = _c("d4dae8"), _c("ffffff"), _c("747e96")

    # Phông lụa đỏ thêu rồng phía sau giá
    d.rectangle([8, 9, 43, 39], fill=_c("6c1822"), outline=gold)
    d.rectangle([10, 11, 41, 37], outline=_c("9e2c34"))

    # Khung gỗ lớn 2 tầng chạm đầu vàng
    d.rectangle([5, 39, 46, 42], fill=w_d)
    for px in (6, 42):
        d.rectangle([px, 5, px + 3, 41], fill=wood)
        auto_shade(img, wood, w_l, w_d)
        d.rectangle([px, 3, px + 3, 5], fill=gold)
    for py in (8, 22, 36):
        d.rectangle([5, py, 46, py + 2], fill=wood)
        d.line([(5, py), (46, py)], fill=w_l)
    d.rectangle([22, 6, 29, 10], fill=gold)

    # Hàng vũ khí đứng: kích, kiếm đồng, đại đao, giáo dài
    for wx, top, tip in ((13, 3, steel), (19, 6, gold), (32, 4, steel), (38, 2, st_l)):
        d.line([(wx, top + 6), (wx, 38)], fill=w_d, width=1)
        d.polygon([(wx - 2, top + 6), (wx, top), (wx + 2, top + 6)], fill=tip)
        d.line([(wx - 1, top + 6), (wx, top)], fill=st_l)
        d.point([wx, top + 7], fill=_c("d83a34"))

    # Cung nỏ nằm ngang tầng giữa & Khiên đồng tròn + ống tên
    d.line([(21, 19), (30, 19)], fill=w_l, width=2)
    d.arc([20, 13, 31, 25], 200, 340, fill=gold)
    d.ellipse([21, 25, 31, 35], fill=_c("c4843c"), outline=gold_l)
    d.ellipse([24, 28, 28, 32], fill=_c("922828"))
    d.rectangle([42, 26, 47, 39], fill=_c("6c4424"), outline=w_l)
    for ax in (43, 45, 46):
        d.point([ax, 24], fill=_c("e84840"))

    return _with_shadow(outline(img), 4, 38, 48, 44, 95)


def build_codex():
    """Tàng Kinh Các: giá sách cổ 3 tầng + bục đọc mở sách vàng & đèn đồng, 54x50."""
    img, d = canvas(54, 50)
    wood, w_l, w_d = _c("764424"), _c("a26a3c"), _c("442414")
    gold, gold_l = _c("e4b042"), _c("fff2a8")

    # Tủ sách cao 3 tầng
    d.rectangle([7, 5, 46, 38], fill=w_d)
    d.rectangle([9, 7, 44, 36], fill=_c("301c12"))
    for sy in (6, 16, 26, 35):
        d.rectangle([7, sy, 46, sy + 2], fill=wood)
        d.line([(7, sy), (46, sy)], fill=w_l)
    d.polygon([(6, 6), (27, 2), (47, 6)], fill=_c("5e201e"), outline=gold)

    # Sách & cuộn tre nhiều màu xếp trên 3 tầng kệ
    colors = ["b83834", "346a9c", "3c844a", "c89432", "7e428c", "d4c49a"]
    for shelf_y in (9, 19, 29):
        for i, bx in enumerate(range(11, 41, 4)):
            col = _c(colors[(i + shelf_y) % len(colors)])
            bh = 5 if i % 2 == 0 else 6
            d.rectangle([bx, shelf_y + (6 - bh), bx + 2, shelf_y + 5], fill=col)
            d.point([bx + 1, shelf_y + (6 - bh) + 1], fill=gold_l if i % 3 == 0 else shade(col, 0.3))

    # Bục đọc phía trước tủ: đặt sách vàng mở trang + đèn dầu + nghiên mực
    d.rectangle([15, 32, 38, 45], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([14, 30, 39, 33], fill=w_l)
    # Quyển Bách Khoa mở hai trang trắng viền vàng
    d.polygon([(17, 26), (26, 28), (36, 26), (36, 32), (26, 34), (17, 32)], fill=_c("f4ebd2"), outline=gold)
    d.line([(26, 28), (26, 34)], fill=w_d)
    for ly in (28, 30):
        d.line([(19, ly), (24, ly + 1)], fill=_c("7c6244"))
        d.line([(28, ly + 1), (34, ly)], fill=_c("7c6244"))
    # Đèn dầu đồng phát sáng bên trái bục
    d.rectangle([9, 34, 13, 39], fill=_c("c88838"))
    d.point([11, 32], fill=_c("fff088"))
    d.point([11, 31], fill=_c("ffd048"))

    return _with_shadow(outline(img), 6, 40, 48, 47, 95)


def build_props():
    """Các đạo cụ nội thất làm đầy 4 phòng Sảnh Chính."""
    wood, w_l, w_d = _c("86502d"), _c("b27848"), _c("522e18")
    gold, gold_l = _c("e4b042"), _c("fff2a8")
    st, sl, sd = _c("848078"), _c("b4afa4"), _c("4e4a46")

    # 1. Bộ bàn trà gỗ gụ + 4 đôn + ấm chén sứ (44x32)
    img, d = canvas(44, 32)
    for sx, sy in ((4, 12), (35, 12), (6, 22), (33, 22)):
        d.ellipse([sx, sy, sx + 6, sy + 5], fill=wood, outline=w_d)
        d.line([(sx + 1, sy + 1), (sx + 5, sy + 1)], fill=w_l)
    d.ellipse([11, 8, 32, 23], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.ellipse([13, 9, 30, 20], fill=_c("9e6238"))
    d.ellipse([19, 11, 24, 16], fill=_c("e8e2d2"), outline=_c("5e7c94"))  # ấm trà
    for cx, cy in ((16, 14), (26, 14), (21, 17)):
        d.ellipse([cx, cy, cx + 2, cy + 2], fill=_c("f4efe4"))
    save(_with_shadow(outline(img), 3, 20, 40, 29, 85), "world/prop_tea_table.png")

    # 2. Bàn Sa Bàn chiến lược Đại Việt (50x36)
    img, d = canvas(50, 36)
    d.rectangle([7, 10, 42, 29], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([9, 11, 40, 25], fill=_c("3c6844"))     # địa hình núi sông
    d.polygon([(12, 16), (20, 12), (28, 18), (38, 15), (39, 23), (11, 23)], fill=_c("5e8c52"))
    d.line([(12, 20), (24, 17), (37, 21)], fill=_c("448cb8"), width=2)  # dòng sông
    for fx, fy, fc in ((17, 15, "e4423c"), (29, 15, "f2c244"), (34, 20, "e4423c")):
        d.line([(fx, fy), (fx, fy - 4)], fill=w_d)
        d.rectangle([fx + 1, fy - 4, fx + 3, fy - 2], fill=_c(fc))
    d.rectangle([8, 25, 11, 31], fill=w_d)
    d.rectangle([38, 25, 41, 31], fill=w_d)
    save(_with_shadow(outline(img), 5, 25, 44, 33, 95), "world/prop_war_map.png")

    # 3. Đèn đá sân vườn có rêu & ánh đèn ấm (22x34)
    img, d = canvas(22, 34)
    d.rectangle([6, 26, 15, 30], fill=sd)
    d.rectangle([9, 17, 12, 26], fill=st)
    d.rectangle([6, 10, 15, 17], fill=st)
    auto_shade(img, st, sl, sd)
    d.rectangle([8, 12, 13, 15], fill=_c("ffd866"))
    d.polygon([(3, 11), (11, 4), (18, 11)], fill=st, outline=sd)
    d.ellipse([9, 2, 12, 5], fill=sl)
    d.point([7, 27], fill=_c("54863c"))
    save(_with_shadow(outline(img), 4, 27, 17, 32, 85), "world/prop_stone_lantern.png")

    # 4. Ghế đá / gỗ dài nghỉ chân sân vườn (40x20)
    img, d = canvas(40, 20)
    d.rectangle([6, 12, 9, 17], fill=sd)
    d.rectangle([30, 12, 33, 17], fill=sd)
    d.rectangle([4, 7, 35, 13], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.line([(5, 9), (34, 9)], fill=w_l)
    d.rectangle([4, 4, 35, 6], fill=w_l, outline=w_d)
    save(_with_shadow(outline(img), 3, 13, 36, 18, 80), "world/prop_bench.png")

    # 5. Thùng gỗ đựng giáo kiếm tập võ (24x26)
    img, d = canvas(24, 26)
    d.ellipse([4, 10, 19, 23], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([4, 14, 19, 15], fill=_c("4e4c58"))
    d.rectangle([4, 19, 19, 20], fill=_c("4e4c58"))
    d.ellipse([5, 9, 18, 13], fill=_c("3a2012"))
    for wx, top in ((8, 3), (12, 2), (15, 5)):
        d.line([(wx, top + 3), (wx, 11)], fill=w_l)
        d.polygon([(wx - 1, top + 3), (wx, top), (wx + 1, top + 3)], fill=_c("d6dce8"))
    save(_with_shadow(outline(img), 3, 19, 20, 24, 85), "world/prop_weapon_barrel.png")

    # 6. Khay than hồng & thỏi sắt rèn (30x22)
    img, d = canvas(30, 22)
    d.rectangle([3, 11, 26, 19], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.polygon([(5, 12), (10, 6), (17, 5), (24, 12)], fill=_c("28242a"))
    for ex, ey in ((9, 9), (13, 8), (18, 10), (15, 11)):
        d.point([ex, ey], fill=_c("ff7c28"))
    d.rectangle([18, 10, 25, 13], fill=_c("7c8296"), outline=_c("3c4050"))
    d.rectangle([20, 8, 26, 10], fill=_c("9ca4b8"), outline=_c("3c4050"))
    save(_with_shadow(outline(img), 2, 16, 27, 20, 85), "world/prop_coal_pile.png")

    # 7. Đỉnh đồng đốt lửa 3 khung động (26x32)
    b_frames = []
    br, br_l, br_d = _c("b87638"), _c("e4ac64"), _c("6e3e1c")
    for f in range(3):
        img, d = canvas(26, 32)
        d.rectangle([7, 24, 10, 28], fill=br_d)
        d.rectangle([15, 24, 18, 28], fill=br_d)
        d.ellipse([5, 14, 20, 25], fill=br)
        d.rectangle([4, 13, 21, 16], fill=br_l)
        auto_shade(img, br, br_l, br_d)
        peak = 4 + (f % 2) * 2
        d.polygon([(7, 13), (10, peak + 2), (13, peak - 1), (16, peak + 3), (18, 13)], fill=_c("ff7024"))
        d.polygon([(10, 13), (13, peak + 4), (16, 13)], fill=_c("ffe468"))
        b_frames.append(_with_shadow(outline(img), 4, 24, 21, 30, 85))
    save(sheet(b_frames), "world/prop_brazier.png")

    # 8. Cờ Rồng Đại Việt đứng trang trí cổng (26x42)
    img, d = canvas(26, 42)
    d.rectangle([6, 35, 16, 39], fill=wood)
    d.line([(11, 3), (11, 37)], fill=w_l, width=2)
    d.polygon([(11, 1), (10, 4), (12, 4)], fill=gold_l)
    d.polygon([(12, 6), (23, 8), (20, 17), (22, 25), (12, 27)], fill=_c("b8222a"))
    d.polygon([(12, 6), (23, 8), (22, 10), (12, 8)], fill=gold)
    d.ellipse([15, 13, 19, 17], fill=gold)
    d.point([17, 15], fill=gold_l)
    save(_with_shadow(outline(img), 5, 35, 18, 40, 85), "world/prop_flag_stand.png")


def build_tea():
    """Quán Trà Đại Sảnh: bàn gỗ gụ, bếp than hồng, ấm chén Bát Tràng & 2 đôn, 50x40."""
    img, d = canvas(50, 40)
    wood, w_l, w_d = _c("7e4826"), _c("aa6e3e"), _c("4a2412")
    gold = _c("e4b042")
    # 2 đôn gỗ hai bên
    for sx in (4, 39):
        d.ellipse([sx, 22, sx + 7, 29], fill=wood, outline=w_d)
        d.ellipse([sx + 1, 22, sx + 6, 25], fill=w_l)
        d.rectangle([sx + 2, 28, sx + 5, 34], fill=w_d)
    # Bàn trà chữ nhật chính giữa & chân bàn
    for lx in (13, 33):
        d.rectangle([lx, 26, lx + 3, 35], fill=w_d)
    d.rectangle([11, 13, 38, 27], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([12, 14, 37, 23], fill=_c("9a5d34"))
    d.rectangle([11, 23, 38, 26], fill=w_d)
    # Bếp than hồng nhỏ bên trái mặt bàn & ấm trà xanh trắng bên phải
    d.ellipse([14, 15, 22, 22], fill=_c("624638"), outline=_c("3c2820"))
    d.ellipse([16, 17, 20, 20], fill=_c("ff7a28"))
    d.point([18, 18], fill=_c("ffe468"))
    d.ellipse([24, 13, 32, 20], fill=_c("ece8dc"), outline=_c("4a7496"))  # ấm gốm Bát Tràng
    d.line([(28, 12), (28, 13)], fill=gold)
    d.line([(32, 16), (34, 14)], fill=_c("ece8dc"))
    # 3 chén trà nóng trên khay tre
    d.rectangle([20, 20, 35, 23], fill=_c("b88c4a"))
    for cx in (22, 26, 30):
        d.ellipse([cx, 19, cx + 2, 22], fill=_c("f6f2e8"))
        d.point([cx + 1, 17], fill=_c("e8f4f8", 180))
    return _with_shadow(outline(img), 3, 29, 46, 38, 95)


def build_war_table():
    """Bàn Sa Bàn Quân Sự: bản đồ địa hình Đại Việt đắp nổi & cờ chiến thuật, 54x42."""
    img, d = canvas(54, 42)
    wood, w_l, w_d = _c("744222"), _c("9c6438"), _c("422212")
    gold = _c("e4b042")
    # Bàn gỗ nặng có chân & khung đồng
    for lx in (8, 42):
        d.rectangle([lx, 28, lx + 4, 37], fill=w_d)
    d.rectangle([6, 10, 47, 30], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    for cx, cy in ((6, 10), (45, 10), (6, 28), (45, 28)):
        d.rectangle([cx, cy, cx + 2, cy + 2], fill=gold)
    # Mặt bản đồ địa hình núi sông Đại Việt
    d.rectangle([9, 12, 44, 26], fill=_c("356440"), outline=w_d)
    d.polygon([(11, 18), (19, 13), (27, 16), (33, 13), (42, 18), (43, 25), (10, 25)], fill=_c("5b8c52"))
    d.polygon([(14, 15), (18, 13), (22, 16)], fill=_c("847e6c"))  # dãy núi
    d.polygon([(30, 14), (34, 13), (38, 16)], fill=_c("847e6c"))
    d.line([(10, 21), (22, 19), (32, 22), (43, 20)], fill=_c("3c8ec0"), width=2)  # sông
    # Thành trì mini & 3 cờ đánh dấu chiến thuật
    d.rectangle([23, 18, 27, 21], fill=_c("c2b8a4"), outline=_c("5e5446"))
    for fx, fy, fc in ((16, 16, "e43a34"), (25, 16, "f4c444"), (37, 19, "e43a34")):
        d.line([(fx, fy + 2), (fx, fy - 5)], fill=w_d)
        d.polygon([(fx + 1, fy - 5), (fx + 5, fy - 4), (fx + 1, fy - 2)], fill=_c(fc))
    # Cuộn sớ mật & la bàn bên góc bàn
    d.rectangle([38, 22, 44, 25], fill=_c("f0e2be"), outline=_c("8a6a40"))
    d.ellipse([11, 21, 15, 25], fill=gold, outline=w_d)
    return _with_shadow(outline(img), 4, 30, 49, 40, 95)


def build_garden():
    """Vườn Thảo Dược 3 ô đất: sen vàng, huyết sâm đỏ & măng tre ngà + bình tưới, 64x46."""
    img, d = canvas(64, 46)
    st, sl, sd = _c("807c74"), _c("aea89c"), _c("4e4a44")
    # Khung đá 3 ô trồng cây xếp ngang
    d.rectangle([6, 18, 53, 40], fill=st)
    auto_shade(img, st, sl, sd)
    for i, ox in enumerate((9, 24, 39)):
        d.rectangle([ox, 21, ox + 11, 35], fill=_c("4b3120"), outline=sd)
        for rx in range(ox + 2, ox + 10, 3):
            d.line([(rx, 24), (rx, 33)], fill=_c("352014"))
        if i == 0:
            # Ô 1: Sen Vàng & lá xanh
            d.ellipse([ox + 1, 25, ox + 10, 32], fill=_c("3e843c"))
            d.polygon([(ox + 2, 23), (ox + 5, 15), (ox + 9, 23)], fill=_c("f4cc48"))
            d.polygon([(ox + 4, 23), (ox + 5, 13), (ox + 7, 23)], fill=_c("fff096"))
        elif i == 1:
            # Ô 2: Huyết Sâm lá xanh thắm + quả đỏ rực
            d.line([(ox + 5, 29), (ox + 5, 17)], fill=_c("4ca044"), width=2)
            for lx, ly in ((ox + 1, 21), (ox + 8, 21), (ox + 2, 25), (ox + 8, 25)):
                d.ellipse([lx, ly, lx + 3, ly + 2], fill=_c("54b24c"))
            for bx, by in ((ox + 4, 15), (ox + 6, 14), (ox + 5, 17)):
                d.ellipse([bx, by, bx + 2, by + 2], fill=_c("e83a38"))
        else:
            # Ô 3: Tre Ngà xanh mướt với đốt vàng
            for tx, top in ((ox + 3, 12), (ox + 7, 9)):
                d.line([(tx, 29), (tx, top)], fill=_c("6ca83c"), width=2)
                d.point([tx, top + 6], fill=_c("d8ba4e"))
                d.polygon([(tx + 1, top + 3), (tx + 5, top + 1), (tx + 2, top + 5)], fill=_c("52b246"))
    # Bình tưới đồng bên góc phải
    d.rectangle([52, 28, 59, 36], fill=_c("c2843c"), outline=_c("6a401c"))
    d.line([(59, 31), (62, 27)], fill=_c("c2843c"), width=2)
    d.arc([50, 26, 55, 34], 90, 270, fill=_c("e4b042"))
    return _with_shadow(outline(img), 4, 34, 60, 44, 95)


def build_enchant():
    """Bàn Phù Phép Binh Khí: bệ đá khắc cổ ngữ + tinh thể ngọc lơ lửng 3 khung (52x46)."""
    frames = []
    st, sl, sd = _c("54505e"), _c("868296"), _c("2c2834")
    gold, gold_l = _c("e4b042"), _c("fff2a0")
    for f in range(3):
        img, d = canvas(52, 46)
        # Chân bệ & mặt bàn đá phù văn
        d.rectangle([10, 35, 41, 41], fill=sd)
        d.rectangle([13, 21, 38, 36], fill=st)
        d.rectangle([8, 17, 43, 23], fill=sl, outline=sd)
        auto_shade(img, st, sl, sd)
        # Khăn đỏ thêu phù chú buông trước bàn & ký tự cổ ngữ phát sáng
        d.polygon([(18, 22), (33, 22), (31, 36), (25, 39), (20, 36)], fill=_c("7c1a24"), outline=gold)
        d.ellipse([23, 26, 28, 31], outline=gold_l)
        # Tinh thể ngọc linh khí lơ lửng phía trên bàn
        bob = [0, -2, -1][f]
        cy = 10 + bob
        d.ellipse([19, 17, 32, 21], fill=_c("22b4c8", 120))
        d.polygon([(26, cy - 8), (33, cy), (26, cy + 8), (19, cy)], fill=_c("34d4e0"))
        d.polygon([(26, cy - 8), (26, cy + 8), (19, cy)], fill=_c("7af6ff"))
        d.polygon([(26, cy - 4), (29, cy), (26, cy + 4)], fill=_c("e2ffff"))
        # Hạt linh khí xoay quanh tinh thể
        pts = [((14, cy - 2), (37, cy + 3)), ((16, cy - 5), (36, cy - 1)), ((15, cy + 2), (38, cy - 4))][f]
        for sx, sy in pts:
            d.point([sx, sy], fill=_c("a8ffff"))
            d.point([sx + 1, sy], fill=gold_l)
        frames.append(_with_shadow(outline(img), 7, 36, 44, 44, 95))
    return sheet(frames)


def build_shrine():
    """Tượng Thần Hộ Mệnh: bệ thờ 2 tầng, tượng đồng hào quang, quả cầu ngọc & lư hương, 48x54."""
    img, d = canvas(48, 54)
    st, sl, sd = _c("7c7872"), _c("aba69c"), _c("484540")
    gold, gold_l, gold_d = _c("dea636"), _c("fff09a"), _c("8e5e1c")
    # Bệ thờ 2 tầng + vải đỏ
    d.rectangle([8, 41, 39, 48], fill=sd)
    d.rectangle([10, 34, 37, 42], fill=st)
    auto_shade(img, st, sl, sd)
    d.rectangle([17, 35, 30, 44], fill=_c("921c26"), outline=gold)
    # Vòng hào quang sau tượng & tượng đồng cổ
    d.ellipse([13, 4, 34, 25], outline=gold)
    d.ellipse([15, 6, 32, 23], outline=gold_l)
    d.polygon([(16, 34), (19, 18), (28, 18), (31, 34)], fill=gold)
    auto_shade(img, gold, gold_l, gold_d)
    d.ellipse([20, 9, 27, 17], fill=gold)         # đầu tượng
    d.polygon([(21, 9), (23, 4), (26, 9)], fill=gold_l)  # mũ
    # Ngọc lục bảo & bát hương nhỏ trên bệ
    d.ellipse([21, 21, 26, 26], fill=_c("44e4c4"), outline=_c("c8fff4"))
    d.rectangle([12, 31, 16, 34], fill=gold_d)
    d.point([14, 29], fill=_c("ffb848"))
    d.rectangle([31, 31, 35, 34], fill=gold_d)
    d.point([33, 29], fill=_c("ffb848"))
    return _with_shadow(outline(img), 6, 43, 41, 51, 100)


def build_supply():
    """Rương Quân Nhu: rương gỗ sơn son viền sắt hé mở chứa vàng xu, túi lương & sớ mật, 46x42."""
    img, d = canvas(46, 42)
    red, r_l, r_d = _c("8e2426"), _c("bc3c3c"), _c("521216")
    iron, i_l = _c("4a4856"), _c("828096")
    gold, gold_l = _c("f0bc42"), _c("fff29c")
    # Nắp rương hé mở phía sau
    d.rectangle([9, 8, 36, 19], fill=r_d, outline=iron)
    d.rectangle([11, 10, 34, 17], fill=red)
    for bx in (13, 22, 31):
        d.line([(bx, 8), (bx, 19)], fill=iron, width=2)
    # Bên trong rương lộ vàng xu, cuộn sớ, bó thảo mộc & túi quân lương
    d.rectangle([10, 17, 35, 24], fill=_c("2c1414"))
    for cx, cy in ((13, 19), (16, 18), (19, 19), (22, 18), (15, 21), (18, 21)):
        d.ellipse([cx, cy, cx + 3, cy + 3], fill=gold)
        d.point([cx + 1, cy + 1], fill=gold_l)
    d.ellipse([24, 17, 30, 23], fill=_c("b89658"), outline=_c("6e522c"))  # túi lương
    d.rectangle([29, 16, 34, 22], fill=_c("f2e4c2"), outline=_c("d43632"))  # cuộn sớ
    # Thân rương sơn son đai sắt & khóa vàng
    d.rectangle([8, 22, 37, 36], fill=red)
    auto_shade(img, red, r_l, r_d)
    for bx in (12, 32):
        d.rectangle([bx, 22, bx + 2, 36], fill=iron)
        d.line([(bx, 22), (bx, 36)], fill=i_l)
    d.rectangle([20, 21, 25, 27], fill=gold, outline=_c("7c5418"))
    d.point([22, 24], fill=_c("2c1814"))
    return _with_shadow(outline(img), 5, 32, 40, 39, 95)


def build():
    save(build_stele(), "world/lobby_stele.png")
    save(build_well(), "world/lobby_well.png")
    save(build_challenge(), "world/lobby_challenge.png")
    save(build_forge(), "world/lobby_forge.png")
    save(build_rack(), "world/lobby_rack.png")
    save(build_codex(), "world/lobby_codex.png")
    save(build_tea(), "world/lobby_tea.png")
    save(build_war_table(), "world/lobby_war_table.png")
    save(build_garden(), "world/lobby_garden.png")
    save(build_enchant(), "world/lobby_enchant.png")
    save(build_shrine(), "world/lobby_shrine.png")
    save(build_supply(), "world/lobby_supply.png")
    build_props()


if __name__ == "__main__":
    build()
