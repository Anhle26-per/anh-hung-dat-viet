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
import math
import random
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

    # 3. Đèn đá chạm trổ mái cong nhiều tầng 3 khung động (32x48 mỗi khung)
    dl_frames = []
    for f in range(3):
        img, d = canvas(32, 48)
        # Chân bệ đá chạm cánh sen & rêu xanh chân đế
        d.rectangle([7, 40, 24, 44], fill=sd)
        d.rectangle([9, 36, 22, 41], fill=st)
        d.polygon([(8, 36), (11, 34), (20, 34), (23, 36)], fill=sl)
        # Trụ bát giác thuôn dần lên trên + dây leo xanh bám trụ
        d.polygon([(12, 34), (19, 34), (18, 22), (13, 22)], fill=st)
        auto_shade(img, st, sl, sd)
        d.line([(15, 23), (15, 34)], fill=sl)
        d.line([(12, 33), (15, 29), (18, 25)], fill=_c("4a8a3a"))
        for vx, vy in ((13, 30), (17, 26), (9, 41), (22, 42)):
            d.point([vx, vy], fill=_c("6ec04c"))
        # Đài đỡ lồng đèn + buồng đèn lưới gỗ phát sáng 3 khung
        d.rectangle([9, 20, 22, 23], fill=sd)
        d.rectangle([10, 12, 21, 20], fill=st)
        glow_col = _c("ffb43a") if f == 0 else (_c("ffd866") if f == 1 else _c("ff9c2c"))
        d.rectangle([12, 13, 19, 19], fill=glow_col)
        d.ellipse([14, 14, 17, 18], fill=_c("fff6b8"))
        # Nan chấn song trước mặt đèn
        d.line([(15, 13), (15, 19)], fill=_c("462e1e"))
        d.line([(12, 16), (19, 16)], fill=_c("462e1e"))
        # Mái ngói đá cong đầu đao & chóp búp sen
        d.polygon([(4, 13), (27, 13), (29, 9), (23, 10), (16, 4), (8, 10), (2, 9)], fill=st, outline=sd)
        d.line([(9, 10), (16, 4), (22, 10)], fill=sl)
        d.ellipse([14, 1, 17, 4], fill=sl)
        d.point([15, 1], fill=_c("e8e2d2"))
        dl_frames.append(_with_shadow(outline(img), 5, 39, 26, 46, 95))
    save(sheet(dl_frames), "world/prop_stone_lantern.png")

    # 3b. Cột Đèn Lồng Gỗ Sơn Son Tay Treo Đầu Rồng 3 khung (30x52 mỗi khung)
    wl_frames = []
    red, r_l, r_d = _c("b82a30"), _c("e4524a"), _c("6e161c")
    for f in range(3):
        img, d = canvas(30, 52)
        sw = [-1, 0, 1][f]
        # Chân tảng đá & cột gỗ sơn son đai đồng vàng
        d.rectangle([5, 44, 13, 48], fill=sd)
        d.rectangle([6, 42, 12, 45], fill=sl)
        d.rectangle([7, 7, 10, 42], fill=red)
        auto_shade(img, red, r_l, r_d)
        for ry in (15, 29, 39):
            d.rectangle([7, ry, 10, ry + 1], fill=gold)
        # Tay xà gỗ vươn ra treo đèn lồng chạm hoa văn đồng
        d.rectangle([6, 5, 22, 8], fill=wood)
        d.line([(6, 5), (22, 5)], fill=w_l)
        d.polygon([(11, 8), (15, 8), (11, 13)], fill=gold)
        d.rectangle([4, 4, 7, 7], fill=gold)
        # Dây treo + lồng đèn lụa đỏ lục giác phát sáng & tua vàng lắc nhẹ
        lx = 20 + sw
        d.line([(20, 8), (lx, 12)], fill=gold)
        d.rectangle([lx - 2, 12, lx + 2, 13], fill=gold)
        d.ellipse([lx - 5, 13, lx + 5, 25], fill=red)
        d.ellipse([lx - 3, 15, lx + 3, 23], fill=_c("ff7a2e"))
        d.ellipse([lx - 1, 16, lx + 1, 21], fill=_c("fff0a0"))
        d.line([(lx, 13), (lx, 25)], fill=r_d)
        d.rectangle([lx - 2, 24, lx + 2, 25], fill=gold)
        d.line([(lx, 26), (lx + sw, 31)], fill=gold_l)
        wl_frames.append(_with_shadow(outline(img), 3, 43, 17, 50, 90))
    save(sheet(wl_frames), "world/prop_wood_lamp.png")

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


def _blossom_tree(w, h, seed, bark_cols, petal_cols, fallen_col):
    """Vẽ cây cổ thụ thân uốn sần sùi, rễ bạnh & tán hoa nhiều tầng ánh sáng."""
    rng = random.Random(seed)
    img, d = canvas(w, h)
    bk, bk_l, bk_d = [_c(c) for c in bark_cols]
    p_sh, p_mid, p_hi, p_tip, stamen = [_c(c) for c in petal_cols]
    cx = w // 2
    by = h - 7

    # Rễ bạnh & gốc cây cổ thụ thuôn dần + nhánh uốn lượn
    d.polygon([(cx - 8, by), (cx - 4, by - 14), (cx + 4, by - 14), (cx + 8, by)], fill=bk_d)
    d.polygon([(cx - 5, by), (cx - 3, by - 22), (cx + 3, by - 22), (cx + 5, by)], fill=bk)
    branches = [
        [(cx - 1, by - 18), (cx - 12, by - 31), (cx - 19, by - 37)],
        [(cx + 1, by - 19), (cx + 11, by - 30), (cx + 19, by - 35)],
        [(cx, by - 22), (cx - 5, by - 35), (cx - 9, by - 44)],
        [(cx, by - 21), (cx + 6, by - 36), (cx + 10, by - 43)],
    ]
    for br in branches:
        d.line(br, fill=bk_d, width=3)
        d.line([(br[0][0], br[0][1] - 1), (br[1][0], br[1][1] - 1)], fill=bk_l, width=1)
    # Vân vỏ cây & rêu gốc
    for y in range(by - 20, by - 1, 3):
        d.line([(cx - 1, y), (cx - 1, y + 1)], fill=bk_l)
        d.line([(cx + 2, y + 1), (cx + 2, y + 2)], fill=bk_d)
    for mx, my in ((cx - 6, by - 1), (cx - 4, by - 2), (cx + 5, by - 1)):
        d.point([mx, my], fill=_c("4e8836"))

    # Tán hoa 4 tầng khối tròn chồng lớp (bóng đậm -> giữa -> sáng -> chồi non -> nhị)
    clusters = [
        (cx - 16, by - 35, 10), (cx + 15, by - 33, 10), (cx - 7, by - 42, 11),
        (cx + 8, by - 40, 11), (cx, by - 33, 10), (cx, by - 46, 9),
    ]
    for rx, ry, r in clusters:
        d.ellipse([rx - r, ry - int(r * 0.78), rx + r, ry + int(r * 0.85)], fill=p_sh)
    for rx, ry, r in clusters:
        d.ellipse([rx - r + 1, ry - int(r * 0.78), rx + r - 1, ry + int(r * 0.62)], fill=p_mid)
    for rx, ry, r in clusters:
        d.ellipse([rx - r + 2, ry - int(r * 0.76), rx + int(r * 0.45), ry + int(r * 0.2)], fill=p_hi)
    # Điểm xuyết từng cụm hoa 4 cánh, lá non và nhị vàng
    for _ in range(52):
        rx, ry, r = rng.choice(clusters)
        fx = rx + rng.randint(-r + 2, r - 2)
        fy = ry + rng.randint(-int(r * 0.65), int(r * 0.55))
        if 2 <= fx < w - 2 and 2 <= fy < h - 8:
            d.point([fx, fy], fill=p_tip)
            d.point([fx + 1, fy], fill=p_tip)
            if rng.random() < 0.35:
                d.point([fx, fy + 1], fill=stamen)
    for _ in range(14):
        rx, ry, r = rng.choice(clusters)
        lx = rx + rng.randint(-r + 3, r - 3)
        ly = ry + rng.randint(-int(r * 0.6), int(r * 0.4))
        d.rectangle([lx, ly, lx + 1, ly + 1], fill=_c("56a642"))

    out = _with_shadow(outline(img), 9, h - 10, w - 10, h - 2, 95)
    od = ImageDraw.Draw(out)
    for px, py in ((cx - 14, h - 4), (cx - 8, h - 3), (cx + 9, h - 4), (cx + 15, h - 5), (cx + 2, h - 3)):
        od.point([px, py], fill=_c(fallen_col, 220))
    return out


def build_flora():
    """Cây Đào, Cây Mai, Khóm Tre, Chậu Bonsai, Khóm Hoa, Lá & Hoa Sen chi tiết."""
    save(_blossom_tree(56, 62, 11, ("5e3824", "865438", "3a2014"),
                       ("a6365e", "dc6892", "f6a6c4", "ffeef6", "ffda60"), "f49ec0"), "world/lobby_peach.png")
    save(_blossom_tree(54, 60, 29, ("4c3222", "724e36", "2c1b12"),
                       ("aa6c16", "e0a624", "f8d84e", "fff6b4", "c85a1c"), "f6d24c"), "world/lobby_apricot.png")

    # Khóm Tre Làng Việt: 5 thân đốt tre, măng non & tán lá lông chim (44x58)
    img, d = canvas(44, 58)
    culms = [(11, 40, "6f8e38", "9cc050", "445a1e"),
             (17, 50, "7ea240", "aed25c", "4c6622"),
             (22, 54, "688a34", "94bc4c", "3e561c"),
             (28, 46, "84a844", "b4d862", "506824"),
             (33, 36, "688836", "94ba4a", "40561e")]
    for bx, bh, c_m, c_l, c_d in culms:
        top = 53 - bh
        lean = -2 if bx < 20 else (2 if bx > 24 else 0)
        d.line([(bx, 53), (bx + lean, top)], fill=_c(c_m), width=2)
        d.line([(bx, 53), (bx + lean, top)], fill=_c(c_l), width=1)
        for ny in range(top + 6, 52, 7):
            nx = bx + int(lean * (53 - ny) / max(1, bh))
            d.line([(nx - 1, ny), (nx + 1, ny)], fill=_c(c_d))
            d.point([nx, ny - 1], fill=_c("d6e29c"))
        # Cành lá lông chim nhiều tầng
        for ly in range(top + 2, top + 20, 6):
            lx = bx + int(lean * (53 - ly) / max(1, bh))
            for sgn in (-1, 1):
                d.polygon([(lx, ly), (lx + 9 * sgn, ly - 3), (lx + 6 * sgn, ly + 1)], fill=_c("4b8a32"))
                d.polygon([(lx + 2 * sgn, ly + 1), (lx + 11 * sgn, ly + 1), (lx + 5 * sgn, ly + 4)], fill=_c("6eb648"))
                d.point([lx + 9 * sgn, ly - 3], fill=_c("9ee066"))
    # Măng non nhú ở chân khóm tre
    d.polygon([(7, 53), (9, 46), (11, 53)], fill=_c("84a840"))
    d.polygon([(35, 53), (37, 47), (39, 53)], fill=_c("84a840"))
    save(_with_shadow(outline(img), 5, 48, 39, 56, 95), "world/lobby_bamboo.png")

    # Chậu Tùng Bonsai Bát Tràng lục giác (32x36)
    img, d = canvas(32, 36)
    d.polygon([(8, 25), (23, 25), (21, 32), (10, 32)], fill=_c("2858a8"), outline=_c("18346e"))
    d.rectangle([7, 23, 24, 25], fill=_c("e4e8f4"), outline=_c("2858a8"))
    d.line([(10, 28), (21, 28)], fill=_c("88b8f0"))
    d.rectangle([10, 32, 12, 33], fill=_c("18346e"))
    d.rectangle([19, 32, 21, 33], fill=_c("18346e"))
    d.ellipse([9, 21, 22, 24], fill=_c("4a7c32"))
    # Thân uốn S cổ thụ
    d.line([(16, 22), (13, 17), (18, 12), (14, 7)], fill=_c("62381e"), width=2)
    d.line([(15, 22), (12, 17), (17, 12)], fill=_c("8a5432"), width=1)
    # 4 tán lá tùng xếp tầng mây
    for px, py, rx, ry in ((9, 16, 6, 3), (22, 13, 6, 3), (14, 8, 7, 4), (17, 5, 5, 3)):
        d.ellipse([px - rx, py - ry, px + rx, py + ry], fill=_c("2a642a"))
        d.ellipse([px - rx + 1, py - ry, px + rx - 1, py + ry - 1], fill=_c("46963c"))
        d.ellipse([px - rx + 2, py - ry, px + 1, py], fill=_c("7cd056"))
    save(_with_shadow(outline(img), 6, 29, 25, 35, 85), "world/lobby_bonsai.png")

    # 2 Khóm Hoa Sân Vườn (Cúc Vàng & Mẫu Đơn Đỏ, 34x26)
    for variant, fname, fl_cols in (
        ("gold", "world/lobby_bush_gold.png", ("d88c1e", "f6cc44", "fff2a4")),
        ("red", "world/lobby_bush_red.png", ("a21c26", "e4444a", "ffb4bc")),
    ):
        img, d = canvas(34, 26)
        for bx, by, rx, ry in ((11, 15, 8, 6), (22, 15, 8, 6), (17, 11, 10, 7)):
            d.ellipse([bx - rx, by - ry, bx + rx, by + ry], fill=_c("285c24"))
            d.ellipse([bx - rx + 1, by - ry, bx + rx - 1, by + ry - 2], fill=_c("408632"))
            d.ellipse([bx - rx + 2, by - ry, bx + 2, by], fill=_c("66b848"))
        fc_d, fc_m, fc_l = [_c(c) for c in fl_cols]
        for fx, fy in ((9, 13), (15, 8), (21, 10), (25, 14), (14, 15), (19, 16)):
            d.ellipse([fx - 2, fy - 2, fx + 2, fy + 2], fill=fc_d)
            d.ellipse([fx - 1, fy - 2, fx + 1, fy + 1], fill=fc_m)
            d.point([fx, fy - 1], fill=fc_l)
        save(_with_shadow(outline(img), 3, 18, 30, 25, 85), fname)

    # Lá sen gân nổi + giọt sương (24x16) & Hoa sen hồng nở rộ (18x16)
    img, d = canvas(24, 16)
    d.ellipse([1, 2, 22, 14], fill=_c("347434"))
    d.ellipse([2, 2, 21, 12], fill=_c("4c9a42"))
    d.polygon([(12, 8), (23, 5), (23, 10)], fill=(0, 0, 0, 0))
    for vx, vy in ((4, 6), (5, 11), (11, 13), (17, 12), (10, 3)):
        d.line([(11, 8), (vx, vy)], fill=_c("255825"))
    d.ellipse([7, 5, 9, 7], fill=_c("baf8ff"))
    d.point([7, 5], fill=_c("ffffff"))
    save(outline(img), "world/lotus_leaf.png")

    img, d = canvas(18, 16)
    for pts in (((3, 12), (1, 6), (6, 8)), ((14, 12), (16, 6), (11, 8)),
                ((5, 13), (4, 3), (9, 8)), ((12, 13), (13, 3), (8, 8))):
        d.polygon(pts, fill=_c("e46e9a"))
    d.polygon([(9, 1), (12, 9), (6, 9)], fill=_c("ffa4c6"))
    d.polygon([(9, 2), (10, 8), (8, 8)], fill=_c("ffe8f2"))
    d.ellipse([6, 9, 11, 12], fill=_c("f4ca44"))
    save(outline(img), "world/lotus.png")


def _draw_koi_sheet(variant):
    """Cá Koi 4 khung uốn lượn mượt mà (22x12 mỗi khung)."""
    frames = []
    for f in range(4):
        img, d = canvas(22, 12)
        dy = [0, 1, 0, -1][f]
        ty = [0, -2, 0, 2][f]
        if variant == "red":
            body, patch, rim = _c("f6f4ee"), _c("e4422a"), _c("1a4a5a")
        elif variant == "calico":
            body, patch, rim = _c("f6f2e8"), _c("e45a2a"), _c("1a4a5a")
        else:
            body, patch, rim = _c("f4be36"), _c("ffe678"), _c("244a58")
        # Đuôi quạt bán trong suốt + thân thuôn uốn chữ S
        d.polygon([(6, 6), (1, 3 + ty), (3, 6 + ty // 2), (1, 9 + ty)], fill=shade(body, 0.25))
        d.polygon([(7, 4), (12, 3 + dy), (18, 4), (20, 6), (18, 8), (12, 8 + dy), (7, 7)], fill=body)
        # Vây ngực hai bên
        d.polygon([(14, 4), (11, 1), (15, 3)], fill=shade(body, 0.3))
        d.polygon([(14, 8), (11, 11), (15, 9)], fill=shade(body, 0.3))
        # Mảng hoa văn Kohaku / Sanke / Yamabuki + mắt & râu cá
        d.ellipse([12, 4 + dy // 2, 16, 7 + dy // 2], fill=patch)
        d.ellipse([8, 5, 11, 7], fill=patch)
        if variant == "calico":
            d.rectangle([10, 5, 11, 6], fill=_c("222028"))
            d.rectangle([14, 6, 15, 7], fill=_c("222028"))
        d.point([18, 5], fill=_c("18141c"))
        d.line([(20, 5), (21, 4)], fill=patch)
        d.line([(20, 7), (21, 8)], fill=patch)
        frames.append(outline(img, color=rim))
    return sheet(frames)


def build_animals():
    """Các loài động vật chi tiết trong doanh trại."""
    save(_draw_koi_sheet("red"), "world/animal_koi_red.png")
    save(_draw_koi_sheet("calico"), "world/animal_koi_calico.png")
    save(_draw_koi_sheet("gold"), "world/animal_koi_gold.png")

    # Chuồn chuồn nước 2 khung đập cánh (14x12)
    df_frames = []
    for f in range(2):
        img, d = canvas(14, 12)
        d.line([(2, 6), (10, 6)], fill=_c("22b8dc"))
        d.ellipse([9, 5, 12, 7], fill=_c("44ecff"))
        d.point([11, 5], fill=_c("142430"))
        if f == 0:
            d.polygon([(7, 5), (3, 1), (9, 2)], fill=_c("d8f8ff", 210))
            d.polygon([(7, 7), (4, 10), (9, 9)], fill=_c("b8eeff", 210))
        else:
            d.polygon([(7, 5), (5, 3), (10, 4)], fill=_c("d8f8ff", 210))
            d.polygon([(7, 7), (5, 9), (10, 8)], fill=_c("b8eeff", 210))
        df_frames.append(img)
    save(sheet(df_frames), "world/animal_dragonfly.png")

    # Gà trống chọi Việt Nam 4 khung (24x24): bước 1, bước 2, vươn cổ gáy, mổ thóc
    r_frames = []
    for f in range(4):
        img, d = canvas(24, 24)
        lean_y = 2 if f == 3 else (-1 if f == 2 else 0)
        lean_x = 1 if f == 3 else 0
        # Chân vàng chắc khỏe bước luân phiên
        l1x, l2x = [(10, 14), (13, 10), (11, 13), (11, 13)][f]
        d.line([(l1x, 17), (l1x, 21)], fill=_c("f2a22a"))
        d.line([(l2x, 17), (l2x, 21)], fill=_c("c67a18"))
        # Đuôi cong lông ngũ sắc xanh lục ánh biếc
        d.arc([1, 4, 11, 16], 110, 270, fill=_c("165c4a"), width=2)
        d.arc([2, 5, 10, 15], 120, 250, fill=_c("2ea880"), width=1)
        d.arc([3, 7, 10, 15], 130, 240, fill=_c("e4a836"), width=1)
        # Thân nâu gụ, cánh xếp lớp & cổ lông kim cam
        d.ellipse([6, 10 + lean_y // 2, 16, 18 + lean_y // 2], fill=_c("7c321c"))
        d.ellipse([8, 11 + lean_y // 2, 14, 16 + lean_y // 2], fill=_c("a64a24"))
        d.polygon([(12, 11), (15, 6 + lean_y), (18 + lean_x, 8 + lean_y), (16, 14)], fill=_c("e8922c"))
        d.ellipse([14 + lean_x, 5 + lean_y, 19 + lean_x, 10 + lean_y], fill=_c("f6b43c"))
        # Mào đỏ răng cưa, tích đỏ, mắt & mỏ nhọn
        d.polygon([(15 + lean_x, 5 + lean_y), (16 + lean_x, 2 + lean_y), (18 + lean_x, 4 + lean_y), (19 + lean_x, 2 + lean_y), (19 + lean_x, 6 + lean_y)], fill=_c("dc2828"))
        d.ellipse([16 + lean_x, 9 + lean_y, 18 + lean_x, 12 + lean_y], fill=_c("dc2828"))
        d.polygon([(19 + lean_x, 7 + lean_y), (22 + lean_x, 8 + lean_y), (19 + lean_x, 9 + lean_y)], fill=_c("f6bc38"))
        d.point([18 + lean_x, 7 + lean_y], fill=_c("1a101c"))
        r_frames.append(_with_shadow(outline(img), 6, 19, 19, 23, 80))
    save(sheet(r_frames), "world/animal_rooster.png")

    # Gà con lông xù 4 khung (16x15)
    ch_frames = []
    for f in range(4):
        img, d = canvas(16, 15)
        hop = -2 if f == 2 else 0
        peck = 2 if f == 3 else 0
        d.ellipse([3, 6 + hop, 11, 12 + hop], fill=_c("f4cc50"))
        d.ellipse([4, 6 + hop, 9, 10 + hop], fill=_c("fff0a4"))
        d.ellipse([8, 2 + hop + peck, 13, 7 + hop + peck], fill=_c("f8dc68"))
        d.point([11, 4 + hop + peck], fill=_c("18101c"))
        d.point([10, 5 + hop + peck], fill=_c("f48888"))   # má hồng
        d.polygon([(13, 4 + hop + peck), (15, 5 + hop + peck), (13, 6 + hop + peck)], fill=_c("f28228"))
        lx = 6 if f != 1 else 8
        d.line([(lx, 12 + hop), (lx, 13)], fill=_c("f28228"))
        d.line([(lx + 2, 12 + hop), (lx + 2, 13)], fill=_c("f28228"))
        ch_frames.append(_with_shadow(outline(img), 3, 11, 12, 14, 70))
    save(sheet(ch_frames), "world/animal_chick.png")

    # Cún Vàng (Chó Cỏ đuôi xoăn) 4 khung (26x22)
    d_frames = []
    tan, tan_l, tan_d = _c("dc9442"), _c("f6bc6a"), _c("9e6022")
    cream = _c("f8f2e4")
    for f in range(4):
        img, d = canvas(26, 22)
        tail_dx = 1 if f in (1, 3) else 0
        sit_dy = 2 if f in (2, 3) else 0
        # Đuôi xoăn vểnh lên vui vẻ
        d.arc([2, 5 + sit_dy, 9, 13 + sit_dy], 90, 320, fill=tan, width=2)
        d.point([5 + tail_dx, 6 + sit_dy], fill=tan_l)
        # Thân lông vàng mật & ức trắng
        d.ellipse([6, 10 + sit_dy, 17, 17 + sit_dy // 2], fill=tan)
        auto_shade(img, tan, tan_l, tan_d)
        d.ellipse([13, 12 + sit_dy // 2, 17, 17], fill=cream)
        # Chân chạy luân phiên + bàn chân trắng
        for lx, ly in ([(8, 17), (14, 17)], [(7, 16), (15, 16)], [(9, 17), (15, 17)], [(9, 17), (15, 17)])[f]:
            d.line([(lx, 15), (lx, ly + 2)], fill=tan_d, width=2)
            d.point([lx, ly + 2], fill=cream)
        # Đầu tròn, mõm trắng, tai cụp dễ thương & vòng cổ đỏ gắn chuông vàng
        d.rectangle([14, 11, 17, 13], fill=_c("d82c2c"))
        d.point([16, 13], fill=_c("ffe258"))
        d.ellipse([13, 3, 22, 12], fill=tan)
        d.ellipse([17, 7, 23, 11], fill=cream)
        d.point([22, 8], fill=_c("1c141c"))   # mũi đen
        d.point([19, 6], fill=_c("1c141c"))   # mắt tròn
        d.point([19, 5], fill=_c("ffffff"))
        d.polygon([(14, 4), (12, 8), (15, 8)], fill=tan_d)   # tai cụp
        if f in (2, 3):
            d.point([20, 10], fill=_c("f67488"))  # thè lưỡi cười
        d_frames.append(_with_shadow(outline(img), 5, 17, 20, 21, 85))
    save(sheet(d_frames), "world/animal_dog.png")

    # Mèo Tam Thể 4 khung (24x20): ngồi, nháy mắt, vẫy đuôi, cuộn tròn ngủ
    c_frames = []
    cr = _c("f6efe2")
    for f in range(4):
        img, d = canvas(24, 20)
        if f == 3:
            # Cuộn tròn ngủ ngon
            d.ellipse([5, 9, 19, 17], fill=cr)
            d.ellipse([7, 10, 12, 14], fill=_c("e07e34"))
            d.ellipse([13, 12, 17, 15], fill=_c("38343c"))
            d.ellipse([12, 7, 19, 14], fill=cr)
            d.polygon([(13, 8), (14, 5), (15, 8)], fill=_c("e07e34"))
            d.polygon([(17, 8), (18, 5), (19, 8)], fill=_c("38343c"))
            d.line([(14, 11), (15, 11)], fill=_c("342828"))
            d.line([(17, 11), (18, 11)], fill=_c("342828"))
        else:
            tx = 1 if f == 2 else 0
            d.arc([3 + tx, 7, 10 + tx, 16], 110, 270, fill=_c("e07e34"), width=2)
            d.ellipse([7, 9, 16, 17], fill=cr)
            d.ellipse([8, 11, 12, 15], fill=_c("38343c"))
            d.ellipse([9, 3, 18, 11], fill=cr)
            d.polygon([(9, 5), (10, 1), (12, 4)], fill=_c("e07e34"))
            d.polygon([(15, 4), (17, 1), (18, 5)], fill=_c("38343c"))
            d.point([11, 3], fill=_c("f49eb0"))
            d.point([16, 3], fill=_c("f49eb0"))
            eye_col = _c("46c874") if f != 1 else _c("382c28")
            d.point([12, 7], fill=eye_col)
            d.point([16, 7], fill=eye_col)
            d.point([14, 8], fill=_c("f48ca4"))
        c_frames.append(_with_shadow(outline(img), 4, 15, 20, 19, 80))
    save(sheet(c_frames), "world/animal_cat.png")

    # Chim Hạc Trắng Hồ Sen 4 khung (26x34): đứng khoan thai, ngoái đầu, cúi mỏ, xòe nhẹ cánh
    cr_frames = []
    wh, wh_s = _c("f6f8fa"), _c("c6d0de")
    for f in range(4):
        img, d = canvas(26, 34)
        # Đôi chân cao thanh mảnh đứng bên mép nước
        d.line([(11, 20), (11, 31)], fill=_c("44424a"))
        d.line([(14, 20), (14, 31)], fill=_c("44424a"))
        d.line([(10, 31), (13, 31)], fill=_c("44424a"))
        # Thân & cánh lông trắng viền xám nhạt
        d.ellipse([6, 13, 18, 22], fill=wh)
        if f == 3:
            d.polygon([(7, 13), (3, 9), (12, 15)], fill=wh_s)
        d.polygon([(6, 16), (3, 21), (9, 20)], fill=_c("383c48"))   # đuôi lông đen thanh lịch
        d.arc([7, 14, 16, 20], 10, 160, fill=wh_s)
        # Cổ cong chữ S, chỏm lông đỏ & mỏ dài vàng nhọn
        if f == 2:
            d.line([(15, 15), (19, 17), (18, 22)], fill=wh, width=2)
            d.ellipse([16, 21, 20, 25], fill=wh)
            d.point([17, 21], fill=_c("e03030"))
            d.line([(19, 24), (23, 29)], fill=_c("e8aa34"))
        else:
            hx = 13 if f == 1 else 16
            d.line([(15, 15), (17, 10), (hx, 6)], fill=wh, width=2)
            d.ellipse([hx - 2, 3, hx + 2, 7], fill=wh)
            d.point([hx, 3], fill=_c("e03030"))
            d.point([hx + (1 if f != 1 else -1), 5], fill=_c("18141c"))
            beak_x = hx - 5 if f == 1 else hx + 6
            d.line([(hx + (1 if f != 1 else -1), 5), (beak_x, 6)], fill=_c("e8aa34"))
        cr_frames.append(_with_shadow(outline(img), 6, 28, 19, 33, 75))
    save(sheet(cr_frames), "world/animal_crane.png")


def _draw_raised_bed(d, img):
    """Vẽ luống đất đá chạm khắc viền rêu kích thước chuẩn 48x54 (phần bồn y=26..48)."""
    st, sl, sd = _c("847e74"), _c("b2aba0"), _c("4a453e")
    wood, w_l, w_d = _c("7e4c28"), _c("a87042"), _c("4a2812")
    # Viền đá & thanh gỗ góc bồn
    d.rectangle([5, 30, 42, 47], fill=sd)
    d.rectangle([6, 26, 41, 44], fill=st)
    auto_shade(img, st, sl, sd)
    d.rectangle([8, 28, 39, 41], fill=_c("4b3120"), outline=_c("2f1c12"))
    for ry in (31, 35, 39):
        d.line([(10, ry), (37, ry)], fill=_c("352014"))
    for cx in (6, 39):
        d.rectangle([cx, 25, cx + 2, 45], fill=wood)
        d.line([(cx, 25), (cx, 45)], fill=w_l)
    # Rêu xanh nhỏ ở chân bồn
    for mx, my in ((9, 44), (10, 45), (35, 44), (22, 46)):
        d.point([mx, my], fill=_c("548c3c"))


def build_garden_plots():
    """6 họa tiết luống cây Vườn Thảo Dược (48x54 mỗi luống) + thùng nước tưới cây (24x28)."""
    # 1. Ô đất trống (48x54)
    img, d = canvas(48, 54)
    _draw_raised_bed(d, img)
    d.line([(33, 25), (33, 33)], fill=_c("9e6e42"), width=2)
    d.rectangle([30, 23, 36, 26], fill=_c("d8b884"), outline=_c("6a4424"))
    save(_with_shadow(outline(img), 4, 41, 43, 51, 95), "world/garden_plot_empty.png")

    # 2. Ô cây đang nảy mầm (48x54)
    img, d = canvas(48, 54)
    _draw_raised_bed(d, img)
    d.ellipse([15, 29, 32, 39], fill=_c("382214"))
    d.line([(23, 34), (23, 20)], fill=_c("58aa44"), width=2)
    d.polygon([(23, 27), (15, 23), (18, 29)], fill=_c("4e9a3c"))
    d.polygon([(24, 25), (32, 21), (29, 27)], fill=_c("68be4c"))
    d.ellipse([21, 16, 25, 21], fill=_c("8ee064"))
    for wx, wy in ((18, 25), (29, 23)):
        d.point([wx, wy], fill=_c("a8f6ff"))
    save(_with_shadow(outline(img), 4, 41, 43, 51, 95), "world/garden_plot_sprout.png")

    # 3. Tre Ngà Phù Đổng chín (48x54): 3 thân vàng ngà đốt vàng óng, lá ngọc bích & măng non
    img, d = canvas(48, 54)
    _draw_raised_bed(d, img)
    stalks = [(14, 10, -1), (23, 4, 0), (31, 9, 1)]
    for bx, top, lean in stalks:
        d.line([(bx, 36), (bx + lean, top)], fill=_c("e4ca6c"), width=3)
        d.line([(bx, 36), (bx + lean, top)], fill=_c("fff4b2"), width=1)
        for ny in range(top + 6, 35, 7):
            nx = bx + int(lean * (36 - ny) / max(1, 36 - top))
            d.line([(nx - 1, ny), (nx + 2, ny)], fill=_c("9c7c28"))
            d.point([nx, ny - 1], fill=_c("ffe87a"))
        for ly in range(top + 3, top + 18, 6):
            lx = bx + int(lean * (36 - ly) / max(1, 36 - top))
            for sgn in (-1, 1):
                d.polygon([(lx, ly), (lx + 9 * sgn, ly - 3), (lx + 6 * sgn, ly + 1)], fill=_c("3c863a"))
                d.polygon([(lx + 2 * sgn, ly + 1), (lx + 10 * sgn, ly + 1), (lx + 4 * sgn, ly + 4)], fill=_c("64be52"))
                d.point([lx + 9 * sgn, ly - 3], fill=_c("a6ef76"))
    d.polygon([(17, 36), (19, 27), (21, 36)], fill=_c("f0da80"))
    d.point([23, 2], fill=_c("fff6a8"))
    save(_with_shadow(outline(img), 4, 41, 43, 51, 95), "world/garden_tre_nga.png")

    # 4. Huyết Sâm Cổ Nghìn Năm chín (48x54): tán lá xanh thẫm 3 tầng & chùm quả đỏ rực phát sáng
    img, d = canvas(48, 54)
    _draw_raised_bed(d, img)
    d.line([(23, 36), (23, 14)], fill=_c("8e2e2a"), width=2)
    # Tán lá xòe 3 lớp xanh ngọc
    for cx, cy, sgn in ((13, 25, -1), (33, 25, 1), (15, 19, -1), (31, 19, 1)):
        d.polygon([(23, cy + 2), (cx, cy - 3), (cx + 3 * sgn, cy + 3)], fill=_c("2c7432"))
        d.polygon([(23, cy + 1), (cx + 1 * sgn, cy - 2), (cx + 4 * sgn, cy + 1)], fill=_c("54b24c"))
        d.line([(23, cy + 1), (cx + 2 * sgn, cy - 1)], fill=_c("86de6e"))
    # Chùm quả huyết sâm đỏ tươi ở ngọn + đốm khí vàng
    for bx, by in ((20, 12), (24, 10), (26, 13), (22, 14), (24, 15), (19, 15)):
        d.ellipse([bx - 2, by - 2, bx + 2, by + 2], fill=_c("c41e26"))
        d.ellipse([bx - 1, by - 2, bx + 1, by], fill=_c("ff4a46"))
        d.point([bx, by - 2], fill=_c("ffc4bc"))
    for gx, gy in ((16, 10), (30, 12), (24, 6)):
        d.point([gx, gy], fill=_c("ffe878"))
    save(_with_shadow(outline(img), 4, 41, 43, 51, 95), "world/garden_huyet_sam.png")

    # 5. Sen Tuyết Linh chín (48x54): mặt nước lam băng trong bồn, lá ngọc & đài sen trắng tuyết
    img, d = canvas(48, 54)
    _draw_raised_bed(d, img)
    d.ellipse([9, 28, 38, 40], fill=_c("1c5e74"))
    d.ellipse([11, 29, 36, 39], fill=_c("2f8aa4"))
    # Lá sen xanh biếc hai bên
    for lx in (15, 31):
        d.ellipse([lx - 6, 30, lx + 6, 37], fill=_c("2e7e5e"), outline=_c("5ec89e"))
    # Đài Sen Tuyết trắng muốt viền lam nhạt & nhị vàng băng
    for pts in (((15, 32), (10, 21), (20, 25)), ((32, 32), (37, 21), (27, 25)),
                ((18, 32), (14, 15), (24, 24)), ((29, 32), (33, 15), (23, 24))):
        d.polygon(pts, fill=_c("bcecf8"))
    d.polygon([(23, 10), (29, 27), (17, 27)], fill=_c("eefaff"))
    d.polygon([(23, 12), (26, 26), (20, 26)], fill=_c("ffffff"))
    d.ellipse([20, 25, 26, 29], fill=_c("ffe876"))
    for fx, fy in ((15, 11), (31, 12), (23, 7)):
        d.point([fx, fy], fill=_c("d6ffff"))
    save(_with_shadow(outline(img), 4, 41, 43, 51, 95), "world/garden_sen_tuyet.png")

    # 6. Thùng nước gỗ hứng mưa & bình tưới đồng bên cạnh (24x28)
    img, d = canvas(24, 28)
    wood, w_l, w_d = _c("7e4c28"), _c("aa7040"), _c("4a2812")
    d.ellipse([2, 8, 17, 24], fill=wood)
    auto_shade(img, wood, w_l, w_d)
    d.rectangle([2, 13, 17, 14], fill=_c("545260"))
    d.rectangle([2, 19, 17, 20], fill=_c("545260"))
    d.ellipse([3, 7, 16, 11], fill=_c("2c7894"))
    d.ellipse([6, 8, 12, 10], fill=_c("7ae4ff"))
    # Bình tưới đồng dựng sát bên
    d.rectangle([14, 17, 21, 24], fill=_c("c8883c"), outline=_c("6e4018"))
    d.line([(20, 19), (23, 15)], fill=_c("c8883c"), width=2)
    save(_with_shadow(outline(img), 2, 20, 22, 26, 85), "world/garden_barrel.png")


def build_material_shop():
    """Gian hàng Thương Nhân Nguyên Liệu (5 bộ sprite chi tiết):
      - world/lobby_mat_shop.png  (4 khung 84x68 -> 336x68): quầy gỗ mái lụa, lồng đèn, ông thương nhân, 6 nguyên liệu & cân bàn tính
      - world/shop_mat_carpet.png (104x38): thảm thổ cẩm trải trước quầy
      - world/shop_ore_crates.png (36x32): rương quặng & sọt gỗ lim / túi hỏa dược
      - world/shop_gem_rack.png   (3 khung 32x44 -> 96x44): kệ sơn mài bày ngọc thần, lọ yêu hồn & đèn dầu
      - world/shop_banner.png     (3 khung 24x48 -> 72x48): cờ phướn Thương Hội bay phấp phới
    """
    wood, w_l, w_d = _c("6e3f22"), _c("9c6038"), _c("3e2010")
    red, r_l, r_d = _c("9e2628"), _c("d4423c"), _c("5c1216")
    gold, gold_l, gold_d = _c("ebbc42"), _c("fff29c"), _c("946418")
    jade, jade_l, jade_d = _c("246c62"), _c("3da092"), _c("14423c")
    skin, skin_d = _c("f2c094"), _c("c68e62")
    cream = _c("f2dfb4")

    # 1. Quầy hàng chính 4 khung (84x68)
    frames = []
    for f in range(4):
        img, d = canvas(84, 68)
        # Vách gỗ hậu & kệ sổ sách mờ sau lưng thương nhân
        d.rectangle([13, 22, 70, 44], fill=_c("3c2418"))
        d.rectangle([15, 25, 28, 27], fill=w_d)
        d.rectangle([55, 25, 68, 27], fill=w_d)
        d.rectangle([17, 21, 22, 25], fill=cream, outline=gold_d)   # cuộn sổ
        d.rectangle([58, 20, 65, 25], fill=_c("a8683a"), outline=w_d) # túi hàng trên kệ

        # Hai cột gỗ lim đứng + đế đá tảng
        for cx in (12, 69):
            d.rectangle([cx, 18, cx + 2, 60], fill=wood)
            d.line([(cx, 18), (cx, 60)], fill=w_l)
            d.rectangle([cx - 1, 58, cx + 3, 61], fill=_c("7c7874"), outline=_c("44403e"))

        # Ông Thương Nhân (ở giữa phía sau quầy)
        # Thân áo dài gấm xanh ngọc thêu viền vàng
        d.polygon([(35, 42), (37, 29), (46, 29), (48, 42)], fill=jade)
        auto_shade(img, jade, jade_l, jade_d)
        d.line([(41, 30), (41, 41)], fill=gold)
        d.rectangle([37, 36, 46, 37], fill=red)  # đai lụa đỏ
        # Đầu, khăn đóng & chòm râu bạc hiền hậu
        d.ellipse([38, 22, 45, 29], fill=skin)
        d.rectangle([37, 20, 46, 23], fill=_c("222028"))  # khăn đóng
        d.rectangle([38, 22, 45, 22], fill=gold)
        if f == 2:
            d.line([(39, 25), (40, 25)], fill=_c("20161e"))
            d.line([(43, 25), (44, 25)], fill=_c("20161e"))
        else:
            d.point([40, 25], fill=_c("20161e"))
            d.point([43, 25], fill=_c("20161e"))
        d.point([41, 27], fill=_c("985440"))  # miệng cười
        d.polygon([(40, 28), (43, 28), (42, 31)], fill=_c("e8eaee"))  # chòm râu bạc
        # Tay cầm quạt giấy phe phẩy nhẹ theo khung f
        fan_dy = (0, -1, -2, -1)[f]
        d.line([(37, 34), (33, 33 + fan_dy)], fill=skin)
        d.pieslice([28, 28 + fan_dy, 36, 36 + fan_dy], 200, 350, fill=cream, outline=gold_d)
        d.line([(46, 34), (49, 36)], fill=skin)

        # Thân quầy gỗ lim mặt rộng phía trước + yếm gấm đỏ
        d.rectangle([10, 42, 73, 60], fill=wood)
        auto_shade(img, wood, w_l, w_d)
        d.rectangle([9, 39, 74, 43], fill=w_l, outline=w_d)  # mặt quầy nhô
        d.line([(10, 40), (73, 40)], fill=_c("bd7f4c"))
        # Yếm vải gấm đỏ & đồng tiền vàng giữa yếm
        d.rectangle([28, 45, 55, 57], fill=red, outline=gold_d)
        d.rectangle([30, 46, 53, 55], outline=gold)
        d.ellipse([39, 48, 44, 53], fill=gold)
        d.rectangle([41, 50, 42, 51], fill=red)

        # Bày 6 nguyên liệu + bàn tính + cân đồng trên mặt quầy (y=33..41)
        # Bàn tính & cân tiểu ly bên trái
        d.rectangle([12, 37, 18, 41], fill=w_d, outline=gold_d)
        for bx in (13, 15, 17):
            d.point([bx + (f % 2 if bx == 15 else 0), 38], fill=gold_l)
            d.point([bx, 40], fill=gold)
        d.line([(23, 32), (23, 39)], fill=gold)         # trụ cân đồng
        d.line([(19, 33), (27, 33)], fill=gold_l)       # đòn cân
        d.rectangle([19, 36, 21, 37], fill=gold)
        d.rectangle([25, 36, 27, 37], fill=gold)

        # (1) Thỏi Đồng
        d.rectangle([29, 37, 33, 40], fill=_c("d67c2c"), outline=_c("7c3a12"))
        d.rectangle([30, 35, 33, 37], fill=_c("f4a64c"), outline=_c("7c3a12"))
        # (2) Thỏi Sắt
        d.rectangle([35, 37, 40, 40], fill=_c("8b96ab"), outline=_c("444b5e"))
        d.line([(36, 37), (39, 37)], fill=_c("d2ddf0"))
        # (3) Bó Gỗ lim
        for gy in (36, 38):
            d.rectangle([42, gy, 47, gy + 1], fill=_c("84502c"), outline=_c("4a2812"))
        d.line([(44, 36), (44, 40)], fill=_c("d8b878"))  # dây thừng buộc
        # (4) Bầu Hỏa dược
        d.ellipse([49, 35, 53, 40], fill=_c("d63e22"), outline=_c("6c1810"))
        d.point([51, 34], fill=_c("ffa838") if f % 2 == 0 else _c("fff098"))
        # (5) Bình Yêu hồn (lấp lánh tím)
        d.rectangle([55, 35, 59, 40], fill=_c("9e4be8"), outline=_c("4a1e78"))
        d.point([57, 34], fill=_c("e4b8ff"))
        d.point([56 + (f % 2), 37], fill=_c("ffffff") if f in (0, 2) else _c("e4b8ff"))
        # (6) Viên Ngọc thần trên gối nhung (lấp lánh xanh ngọc)
        d.rectangle([62, 38, 70, 40], fill=red)
        d.polygon([(66, 33), (69, 36), (66, 39), (63, 36)], fill=_c("2ce8b4"), outline=_c("127a60"))
        d.point([66, 35], fill=_c("d8fff4") if f % 2 == 0 else _c("74ffda"))
        if f in (1, 3):
            d.point([69, 32], fill=_c("d8fff4"))

        # Mái hiên lụa kẻ sọc đỏ son - vàng kem + xà đầu rồng + biển hiệu
        d.rectangle([6, 17, 77, 20], fill=w_d)
        for sx in range(8, 75, 4):
            col = red if ((sx // 4) % 2 == 0) else cream
            col_hi = r_l if ((sx // 4) % 2 == 0) else _c("fff4d4")
            d.polygon([(sx, 17), (sx + 3, 17), (sx + 2, 7), (sx - 1 if sx > 8 else sx, 7)], fill=col)
            d.point([sx + 1, 9], fill=col_hi)
            # Diềm múi vải lượn sóng
            d.pieslice([sx - 1, 16, sx + 3, 21], 0, 180, fill=col)
            d.point([sx + 1, 21], fill=gold if (sx // 4) % 2 == 0 else gold_l)
        d.rectangle([9, 5, 74, 7], fill=wood, outline=w_d)  # nóc gỗ
        # Đầu rồng chạm vàng hai đầu nóc
        d.polygon([(5, 8), (9, 5), (9, 9)], fill=gold)
        d.polygon([(78, 8), (74, 5), (74, 9)], fill=gold)
        # Biển hiệu gỗ sơn son treo giữa mái
        d.rectangle([28, 10, 55, 18], fill=r_d, outline=gold)
        d.rectangle([30, 12, 53, 16], fill=red)
        for ch_x in (33, 37, 41, 45, 49):
            d.rectangle([ch_x, 13, ch_x + 2, 15], fill=gold_l)

        # Hai lồng đèn đỏ treo hai bên đung đưa nhẹ theo khung
        sway = (0, 1, 0, -1)[f]
        for lx in (7, 76):
            d.line([(lx, 18), (lx + sway, 22)], fill=gold_d)
            d.ellipse([lx - 3 + sway, 22, lx + 3 + sway, 29], fill=red, outline=gold_d)
            d.rectangle([lx - 1 + sway, 24, lx + 1 + sway, 27], fill=_c("ffe47c") if f % 2 == 0 else _c("ffb848"))
            d.line([(lx + sway, 30), (lx + sway, 32)], fill=gold)

        frames.append(_with_shadow(outline(img), 6, 56, 77, 65, 95))
    save(sheet(frames), "world/lobby_mat_shop.png")

    # 2. Thảm dệt thổ cẩm trải trước quầy (104x38)
    img, d = canvas(104, 38)
    d.rectangle([4, 3, 99, 34], fill=_c("6a1a1d"), outline=_c("3c0c10"))
    d.rectangle([7, 6, 96, 31], fill=_c("8e2629"), outline=gold)
    d.rectangle([10, 9, 93, 28], outline=_c("c89432"))
    # Hoa văn hình thoi vàng chạy dọc thảm
    for cx in range(20, 92, 16):
        d.polygon([(cx, 13), (cx + 5, 18), (cx, 23), (cx - 5, 18)], fill=gold_d, outline=gold)
        d.ellipse([cx - 2, 16, cx + 2, 20], fill=gold_l)
    # Tua rua vàng hai bên mép thảm
    for y in range(5, 34, 3):
        d.line([(1, y), (3, y)], fill=gold_d)
        d.line([(100, y), (102, y)], fill=gold_d)
    save(img, "world/shop_mat_carpet.png")

    # 3. Rương quặng mở nắp & sọt gỗ lim / túi hỏa dược (36x32)
    img, d = canvas(36, 32)
    # Rương gỗ sau-trái
    d.rectangle([3, 7, 20, 15], fill=w_d, outline=_c("2c160c"))  # nắp mở
    d.rectangle([2, 13, 21, 25], fill=wood, outline=w_d)
    for cx, cy in ((5, 12), (9, 11), (13, 12), (7, 14)):
        d.rectangle([cx, cy, cx + 3, cy + 2], fill=_c("ea8e38"), outline=_c("8a4214"))
    for ix, iy in ((14, 11), (16, 13)):
        d.rectangle([ix, iy, ix + 3, iy + 2], fill=_c("92a0b8"), outline=_c("444e60"))
    d.rectangle([6, 13, 7, 25], fill=_c("545260"))
    d.rectangle([16, 13, 17, 25], fill=_c("545260"))
    # Sọt tre đựng gỗ lim & túi hỏa dược bên phải
    d.polygon([(20, 17), (33, 17), (31, 27), (22, 27)], fill=_c("b88846"), outline=_c("6c4a20"))
    d.line([(21, 21), (32, 21)], fill=_c("885e2a"))
    d.rectangle([22, 11, 26, 17], fill=_c("764422"), outline=_c("422210"))
    d.ellipse([27, 13, 32, 18], fill=red, outline=r_d)
    d.point([29, 12], fill=gold)
    save(_with_shadow(outline(img), 2, 22, 33, 30, 85), "world/shop_ore_crates.png")

    # 4. Kệ sơn mài 3 tầng bày Ngọc thần, Yêu hồn & Đèn dầu (3 khung 32x44)
    rack_frames = []
    for f in range(3):
        img, d = canvas(32, 44)
        # Khung kệ gỗ sơn son thiếp vàng
        d.rectangle([5, 6, 26, 39], fill=_c("3c1816"), outline=w_d)
        for cx in (5, 25):
            d.rectangle([cx, 4, cx + 1, 40], fill=red)
            d.point([cx, 3], fill=gold)
        for sy in (14, 24, 34):
            d.rectangle([4, sy, 27, sy + 2], fill=wood, outline=w_d)
            d.line([(5, sy), (26, sy)], fill=gold_d)
        # Tầng 1: cụm Ngọc thần sáng + đèn dầu đồng cháy lập lòe
        d.polygon([(10, 14), (12, 8), (14, 14)], fill=_c("32e8b4"), outline=_c("127a60"))
        d.polygon([(13, 14), (15, 10), (17, 14)], fill=_c("74ffda"))
        d.rectangle([19, 11, 24, 14], fill=gold_d)
        d.point([21, 9 - (f % 2)], fill=_c("fff098") if f != 1 else _c("ff9832"))
        # Tầng 2: 2 bình Yêu hồn phát sáng tím
        for ux, col_g in ((9, "a854f0"), (18, "7e3ec8")):
            d.rectangle([ux, 18, ux + 5, 24], fill=_c(col_g), outline=_c("42186e"))
            d.point([ux + 2, 17], fill=gold)
            d.point([ux + 2, 20], fill=_c("f4d8ff") if f == 0 else _c("d2a4ff"))
        # Tầng 3: 2 hũ xu vàng
        for jx in (8, 18):
            d.ellipse([jx, 27, jx + 6, 34], fill=_c("8e582a"), outline=_c("4c2c12"))
            d.ellipse([jx + 1, 26, jx + 5, 29], fill=gold_l if f != 2 else gold)
        rack_frames.append(_with_shadow(outline(img), 4, 36, 27, 42, 90))
    save(sheet(rack_frames), "world/shop_gem_rack.png")

    # 5. Cờ phướn Thương Hội bay phấp phới (3 khung 24x48)
    ban_frames = []
    for f in range(3):
        img, d = canvas(24, 48)
        # Trụ đá & cán gỗ
        d.rectangle([8, 40, 15, 44], fill=_c("7c7874"), outline=_c("44403e"))
        d.rectangle([11, 5, 12, 42], fill=wood)
        d.line([(6, 8), (18, 8)], fill=gold)
        d.point([11, 3], fill=gold_l)
        # Lá phướn đỏ viền vàng uốn sóng theo khung
        ox = (0, 1, -1)[f]
        d.polygon([(7, 9), (16, 9), (16 + ox, 30), (12 + ox, 35), (7 + ox, 30)], fill=red, outline=gold)
        d.ellipse([9, 13, 14, 18], fill=gold)         # đồng tiền cổ
        d.rectangle([11, 15, 12, 16], fill=red)
        d.rectangle([10 + ox, 21, 13 + ox, 26], fill=gold_l)
        d.line([(12 + ox, 35), (12 + ox * 2, 39)], fill=gold)
        ban_frames.append(_with_shadow(outline(img), 7, 40, 16, 46, 85))
    save(sheet(ban_frames), "world/shop_banner.png")


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
    build_garden_plots()
    build_flora()
    build_animals()
    build_props()
    build_material_shop()


if __name__ == "__main__":
    build()
