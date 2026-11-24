"""Gạch nền 4 chương, đồ trang trí, giao diện (khung, nút, biểu tượng)."""
import math
import random
from px import hexc, grid, outline, sheet, save, canvas, auto_shade, Image, ImageDraw

T = 16

# Mỗi chương: sàn (gốc, sáng, tối), tường (gốc, sáng, tối), kiểu sàn
THEMES = [
    {"floor": ("4e5a44", "66745a", "343e2e"), "wall": ("5e6a48", "86945e", "3a4230"), "kind": "moss"},     # rừng núi Nưa
    {"floor": ("7a5434", "9a7048", "52361e"), "wall": ("5a6470", "7e8a96", "3a4048"), "kind": "plank"},    # sông Bạch Đằng
    {"floor": ("8a3e32", "aa5444", "5e2620"), "wall": ("7a2a2a", "a84038", "4a1818"), "kind": "brick"},    # thành Thăng Long
    {"floor": ("6e6a72", "8e8a92", "4a4650"), "wall": ("6a5a6a", "8e7a8a", "443a48"), "kind": "slab"},     # gò Đống Đa
    {"floor": ("8a6a46", "a8865a", "5e4630"), "wall": ("9a8a6a", "c0b08a", "64583e"), "kind": "earth"},    # làng quê Mê Linh
    {"floor": ("7a7a72", "9a9a90", "52524c"), "wall": ("8a8270", "aaa08a", "5a5446"), "kind": "concrete"}, # đồn Pháp
    {"floor": ("6a5a3e", "86744e", "463a28"), "wall": ("a88a5a", "d0b080", "6a5434"), "kind": "trench"},   # chiến hào
]


def _c(h):
    return hexc(h)


def floor_tile(th, variant, rng):
    f, fl, fd = (_c(x) for x in th["floor"])
    img = Image.new("RGBA", (T, T), f)
    px = img.load()
    kind = th["kind"]
    for y in range(T):
        for x in range(T):
            n = rng.random()
            c = f
            if kind == "plank":
                if y % 5 == 4:
                    c = fd
                elif y % 5 == 0:
                    c = fl
                elif (x + (y // 5) * 7) % 16 == 0:
                    c = fd
                elif n < 0.08:
                    c = fd
            elif kind == "brick":
                row = y // 4
                off = 4 if row % 2 else 0
                if y % 4 == 3 or (x + off) % 8 == 7:
                    c = fd
                elif y % 4 == 0:
                    c = fl
            elif kind in ("earth", "trench"):
                if n < 0.12:
                    c = fd
                elif n > 0.9:
                    c = fl
                if kind == "trench" and (y % 8 == 7) and n < 0.5:
                    c = fd
            elif kind == "concrete":
                if x % 8 == 0 or y % 8 == 0:
                    c = fd
                elif n < 0.05:
                    c = fd
                elif n > 0.93:
                    c = fl
            else:
                if x == 0 or y == 0:
                    c = fd
                elif x == 1 or y == 1:
                    c = fl if n < 0.7 else f
                elif n < 0.06:
                    c = fd
                elif n > 0.95:
                    c = fl
            px[x, y] = c
    d = ImageDraw.Draw(img)
    if variant == 1:   # vết nứt
        d.line([(4, 5), (7, 8), (7, 11)], fill=fd)
    elif variant == 2:
        if kind in ("moss", "slab"):
            moss = _c("5e8a3a") if kind == "moss" else _c("e890b0")   # rêu / cánh hoa đào
            for _ in range(7):
                x, y = rng.randint(2, 13), rng.randint(2, 13)
                d.point([x, y], fill=moss)
                d.point([x + 1, y], fill=moss)
        else:
            d.line([(10, 3), (12, 6)], fill=fd)
    elif variant == 3:  # hoa văn khắc chìm
        d.rectangle([5, 5, 10, 10], outline=fd)
        d.point([7, 7], fill=fl)
        d.point([8, 8], fill=fl)
    return img


def wall_face(th, variant, rng):
    w, wl, wd = (_c(x) for x in th["wall"])
    if th["kind"] == "trench":
        img = Image.new("RGBA", (T, T), wd)
        d = ImageDraw.Draw(img)
        for row, y in enumerate((0, 5, 10)):
            for x in range(-4 + (row % 2) * 4, T, 8):
                d.rounded_rectangle([x, y, x + 7, y + 5], 2, fill=w)
                d.line([(x + 1, y + 1), (x + 5, y + 1)], fill=wl)
        return img
    img = Image.new("RGBA", (T, T), w)
    px = img.load()
    for y in range(T):
        for x in range(T):
            row = y // 4
            off = 4 if row % 2 else 0
            c = w
            if y % 4 == 3 or (x + off) % 8 == 7:
                c = wd
            elif y % 4 == 0:
                c = wl if rng.random() < 0.8 else w
            if y < 2:
                c = wl
            px[x, y] = c
    if variant == 1:
        d = ImageDraw.Draw(img)
        d.rectangle([5, 6, 10, 10], fill=wd)      # hốc tường
        d.point([6, 7], fill=_c("2a1d2e"))
    return img


def wall_top(th):
    w, wl, wd = (_c(x) for x in th["wall"])
    dark = tuple(int(c * 0.45) for c in w[:3]) + (255,)
    img = Image.new("RGBA", (T, T), dark)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, T - 1, T - 1], outline=tuple(int(c * 0.3) for c in w[:3]) + (255,))
    d.line([(1, 1), (T - 2, 1)], fill=tuple(int(c * 0.6) for c in w[:3]) + (255,))
    return img


def tiles():
    rng = random.Random(11)
    atlas = Image.new("RGBA", (T * 8, T * len(THEMES)), (0, 0, 0, 0))
    for r, th in enumerate(THEMES):
        row = [floor_tile(th, v, rng) for v in range(4)] + [wall_face(th, 0, rng), wall_face(th, 1, rng), wall_top(th), wall_top(th)]
        for c, img in enumerate(row):
            atlas.alpha_composite(img, (c * T, r * T))
    save(atlas, "world/tiles.png")


def decor():
    # đuốc treo tường 4 khung
    fr = []
    for f in range(4):
        img, d = canvas(10, 18)
        d.rectangle([4, 9, 5, 16], fill=_c("5e3a20"))
        d.rectangle([2, 8, 7, 9], fill=_c("c4803e"))
        h = [0, 1, 0, -1][f]
        d.polygon([(2, 8), (7, 8), (5 + (f % 2), 1 + h), (4, 3)], fill=_c("ff8a2a"))
        d.polygon([(3, 8), (6, 8), (5, 4 + h)], fill=_c("ffd84a"))
        d.point([4, 7], fill=_c("fff8d0"))
        fr.append(outline(img))
    save(sheet(fr), "world/torch.png")
    # cờ đỏ có mặt trống đồng (treo tường)
    fr = []
    for f in range(2):
        img, d = canvas(14, 24)
        d.line([(1, 1), (12, 1)], fill=_c("5e3a20"), width=2)
        sw = f
        d.polygon([(2, 2), (11, 2), (11 + sw, 19), (6, 22), (2 - sw, 19)], fill=_c("b8323a"))
        auto_shade(img, _c("b8323a"), _c("e05a50"), _c("7a1e2c"))
        d.ellipse([4, 7, 9, 12], outline=_c("e8b04a"))
        d.point([6, 9], fill=_c("fff0a0"))
        d.point([7, 10], fill=_c("fff0a0"))
        d.line([(3, 16), (10, 16)], fill=_c("e8b04a"))
        fr.append(outline(img))
    save(sheet(fr), "world/banner.png")
    # chum gốm Bát Tràng men lam
    img, d = canvas(14, 15)
    d.ellipse([1, 3, 12, 14], fill=_c("e8e4f0"))
    d.rectangle([4, 1, 9, 4], fill=_c("e8e4f0"))
    auto_shade(img, _c("e8e4f0"), _c("ffffff"), _c("a8a4c0"))
    d.line([(2, 8), (11, 8)], fill=_c("2a5ab0"))
    d.arc([3, 6, 7, 11], 180, 360, fill=_c("2a5ab0"))
    d.arc([7, 6, 11, 11], 0, 180, fill=_c("2a5ab0"))
    d.line([(4, 1), (9, 1)], fill=_c("2a5ab0"))
    save(outline(img), "world/pot.png")
    # đèn lồng đỏ 2 khung
    fr = []
    for f in range(2):
        img, d = canvas(10, 16)
        d.line([(5, 0), (5, 2)], fill=_c("5e3a20"))
        d.ellipse([1, 3, 8, 12], fill=_c("d83a3a"))
        auto_shade(img, _c("d83a3a"), _c("ff8a6a") if f else _c("f06a5a"), _c("8e2632"))
        d.rectangle([3, 2, 6, 3], fill=_c("e8b04a"))
        d.rectangle([3, 12, 6, 13], fill=_c("e8b04a"))
        d.line([(4, 14), (4, 15)], fill=_c("e8b04a"))
        d.line([(1, 7), (8, 7)], fill=_c("8e2632"))
        fr.append(outline(img))
    save(sheet(fr), "world/lantern.png")
    # cây đào ngày Tết (chương 4)
    img, d = canvas(26, 30)
    d.line([(13, 29), (13, 16)], fill=_c("4a2e1e"), width=3)
    d.line([(13, 18), (7, 11)], fill=_c("4a2e1e"), width=2)
    d.line([(13, 17), (20, 10)], fill=_c("4a2e1e"), width=2)
    rng = random.Random(4)
    for _ in range(40):
        x, y = rng.randint(2, 23), rng.randint(2, 18)
        d.point([x, y], fill=_c("f4a0c0") if rng.random() < 0.7 else _c("ffe0ec"))
    save(outline(img), "world/peach.png")
    # khóm tre (chương 1)
    img, d = canvas(20, 30)
    for x, h in ((4, 26), (9, 29), (14, 24)):
        d.line([(x, 29), (x, 29 - h)], fill=_c("8aa048"), width=2)
        for y in range(29 - h + 4, 29, 6):
            d.point([x, y], fill=_c("4e5e24"))
            d.point([x + 1, y], fill=_c("4e5e24"))
        d.polygon([(x, 29 - h + 2), (x + 6, 29 - h), (x + 1, 29 - h + 4)], fill=_c("5e9a3a"))
        d.polygon([(x, 29 - h + 8), (x - 6, 29 - h + 6), (x - 1, 29 - h + 10)], fill=_c("5e9a3a"))
    save(outline(img), "world/bamboo.png")


def decor2():
    # thùng gỗ
    img, d = canvas(14, 13)
    d.rectangle([1, 2, 12, 12], fill=_c("8a5a32"))
    auto_shade(img, _c("8a5a32"), _c("b8844e"), _c("5a3a1e"))
    d.line([(1, 2), (12, 12)], fill=_c("5a3a1e"))
    d.line([(12, 2), (1, 12)], fill=_c("5a3a1e"))
    d.rectangle([1, 2, 12, 12], outline=_c("6a4426"))
    save(outline(img), "world/crate.png")
    # bao cát xếp
    img, d = canvas(22, 13)
    for row, y in enumerate((6, 1)):
        for x in range(1 + row * 4, 21 - row * 4, 8):
            d.rounded_rectangle([x, y, x + 8, y + 5], 2, fill=_c("a88a5a"))
    auto_shade(img, _c("a88a5a"), _c("d0b080"), _c("6a5434"))
    save(outline(img), "world/sandbag.png")


def lobby_art():
    # lò rèn: lò gạch có lửa + đe
    fr = []
    for f in range(3):
        img, d = canvas(32, 28)
        d.rectangle([2, 6, 18, 26], fill=_c("8a3e32"))
        auto_shade(img, _c("8a3e32"), _c("b05444"), _c("5e2620"))
        for y in range(8, 26, 4):
            d.line([(2, y), (18, y)], fill=_c("5e2620"))
        d.rectangle([6, 14, 14, 22], fill=_c("2a1414"))
        fl = [0, 1, -1][f]
        d.polygon([(7, 22), (10, 15 + fl), (13, 22)], fill=_c("ff8a2a"))
        d.polygon([(9, 22), (10, 18 + fl), (11, 22)], fill=_c("ffe060"))
        d.rectangle([4, 2, 9, 6], fill=_c("5e2620"))
        d.rectangle([21, 18, 30, 21], fill=_c("4a4458"))
        d.rectangle([24, 21, 27, 26], fill=_c("3a3448"))
        d.line([(21, 18), (30, 18)], fill=_c("8a84a0"))
        d.line([(26, 12), (29, 17)], fill=_c("6a4028"), width=2)
        d.rectangle([24, 10, 28, 12], fill=_c("8a92ac"))
        fr.append(outline(img))
    save(sheet(fr), "world/forge.png")
    # giá binh khí: giá gỗ cắm giáo, kiếm, kích
    img, d = canvas(34, 28)
    d.rectangle([2, 22, 31, 25], fill=_c("6a4028"))
    d.rectangle([3, 8, 5, 25], fill=_c("8a5a32"))
    d.rectangle([28, 8, 30, 25], fill=_c("8a5a32"))
    d.rectangle([2, 10, 31, 12], fill=_c("8a5a32"))
    auto_shade(img, _c("8a5a32"), _c("b8844e"), _c("5a3a1e"))
    for x, top, col in ((8, 1, "d8dce8"), (13, 3, "e8b04a"), (18, 0, "d8dce8"), (23, 2, "c4803e")):
        d.line([(x, top + 4), (x, 23)], fill=_c("5e3a20"), width=1)
        d.polygon([(x - 1, top + 4), (x, top), (x + 1, top + 4)], fill=_c(col))
        d.point([x, top + 5], fill=_c("d83a3a"))
    save(outline(img), "world/weapon_rack.png")
    # bia đá ghi công
    img, d = canvas(20, 28)
    d.rectangle([2, 23, 17, 26], fill=_c("5a5650"))
    d.rounded_rectangle([4, 2, 15, 23], 3, fill=_c("8a8478"))
    auto_shade(img, _c("8a8478"), _c("b4ae9e"), _c("5a5650"))
    for y in range(7, 21, 3):
        d.line([(6, y), (13, y)], fill=_c("5a5650"))
    d.rectangle([7, 3, 12, 5], fill=_c("e8b04a"))
    save(outline(img), "world/stele.png")
    # hình nhân rơm: thường / trúng đòn
    fr = []
    for f in range(2):
        img, d = canvas(20, 28)
        tilt = 1 if f else 0
        d.line([(10, 14), (10, 27)], fill=_c("6a4028"), width=2)
        d.line([(3 + tilt, 12), (17 + tilt, 12)], fill=_c("6a4028"), width=2)
        d.ellipse([5 + tilt, 9, 15 + tilt, 22], fill=_c("d8b860"))
        d.ellipse([6 + tilt, 1, 14 + tilt, 10], fill=_c("e0c470"))
        auto_shade(img, _c("d8b860"), _c("f0d888"), _c("a88a3a"))
        d.line([(6 + tilt, 15), (14 + tilt, 15)], fill=_c("8a5a32"))
        d.line([(6 + tilt, 18), (14 + tilt, 18)], fill=_c("8a5a32"))
        d.point([8 + tilt, 5], fill=_c("2a1d2e"))
        d.point([12 + tilt, 5], fill=_c("2a1d2e"))
        d.ellipse([8 + tilt, 12, 12 + tilt, 16], outline=_c("d83a3a"))
        fr.append(outline(img))
    save(sheet(fr), "world/dummy.png")


def lobby_decor():
    # cột đình sơn son, đầu cột và chân tảng đá
    img, d = canvas(14, 44)
    d.rectangle([3, 6, 10, 38], fill=_c("b8323a"))
    auto_shade(img, _c("b8323a"), _c("e05a50"), _c("7a1e2c"))
    d.rectangle([1, 2, 12, 6], fill=_c("e8b04a"))
    d.line([(1, 2), (12, 2)], fill=_c("fff0a0"))
    d.rectangle([1, 38, 12, 43], fill=_c("8a8478"))
    d.line([(1, 38), (12, 38)], fill=_c("b4ae9e"))
    for y in (12, 30):
        d.line([(3, y), (10, y)], fill=_c("e8b04a"))
    d.line([(5, 14), (5, 28)], fill=_c("e05a50"))
    save(outline(img), "world/pillar.png")
    # nghê đá
    img, d = canvas(22, 22)
    st, sl, sd = _c("8a8a80"), _c("b8b8aa"), _c("5a5a52")
    d.rectangle([2, 16, 19, 21], fill=sd)
    d.ellipse([4, 7, 16, 18], fill=st)
    d.ellipse([10, 1, 20, 11], fill=st)
    auto_shade(img, st, sl, sd)
    for x, y in ((11, 2), (14, 1), (17, 2)):
        d.point([x, y], fill=sd)
    d.point([17, 5], fill=_c("2a1d2e"))
    d.line([(16, 8), (19, 8)], fill=sd)
    d.line([(4, 10), (1, 6)], fill=st, width=2)
    d.ellipse([12, 13, 16, 17], fill=sl)
    save(outline(img), "world/nghe.png")
    # lư hương đồng
    img, d = canvas(18, 18)
    br, bl, bd = _c("c4803e"), _c("f2b878"), _c("7a4622")
    d.ellipse([2, 5, 15, 15], fill=br)
    d.rectangle([1, 4, 16, 6], fill=br)
    auto_shade(img, br, bl, bd)
    d.line([(4, 15), (3, 17)], fill=bd)
    d.line([(13, 15), (14, 17)], fill=bd)
    d.line([(8, 15), (8, 17)], fill=bd)
    for x in (6, 8, 10):
        d.line([(x, 1), (x, 4)], fill=_c("d83a3a"))
        d.point([x, 0], fill=_c("ffb040"))
    d.rectangle([5, 9, 11, 11], outline=bd)
    save(outline(img), "world/incense.png")
    # trống đồng trên giá
    img, d = canvas(28, 28)
    d.line([(3, 26), (8, 12)], fill=_c("6a4028"), width=2)
    d.line([(24, 26), (19, 12)], fill=_c("6a4028"), width=2)
    d.ellipse([4, 6, 23, 14], fill=br)
    d.rectangle([4, 10, 23, 20], fill=br)
    d.ellipse([4, 16, 23, 24], fill=br)
    auto_shade(img, br, bl, bd)
    d.ellipse([4, 6, 23, 14], fill=_c("e8b04a"))
    d.ellipse([10, 8, 17, 12], outline=_c("a86a2a"))
    d.point([13, 10], fill=_c("fff0a0"))
    for x in range(6, 23, 3):
        d.line([(x, 14), (x, 21)], fill=bd)
    save(outline(img), "world/drum_stand.png")
    # bonsai trong chậu
    img, d = canvas(18, 20)
    d.rectangle([3, 14, 14, 19], fill=_c("2a5ab0"))
    d.line([(3, 14), (14, 14)], fill=_c("6a9ae0"))
    d.line([(8, 14), (7, 9), (10, 6)], fill=_c("5e3a20"), width=2)
    for cx, cy, r in ((5, 7, 3), (11, 5, 4), (13, 9, 3)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=_c("4a9a3a"))
    auto_shade(img, _c("4a9a3a"), _c("86d05a"), _c("2a5a2e"))
    save(outline(img), "world/bonsai.png")
    # lá sen + hoa sen
    img, d = canvas(14, 10)
    d.ellipse([0, 2, 13, 9], fill=_c("4a9a3a"))
    d.polygon([(6, 5), (13, 4), (13, 7)], fill=(0, 0, 0, 0))
    d.line([(2, 5), (6, 5)], fill=_c("2a5a2e"))
    save(outline(img), "world/lotus_leaf.png")
    img, d = canvas(10, 9)
    for pts in (((5, 0), (7, 5), (3, 5)), ((1, 3), (5, 6), (2, 7)), ((9, 3), (5, 6), (8, 7))):
        d.polygon(pts, fill=_c("f4a0c0"))
    d.point([5, 2], fill=_c("ffe0ec"))
    d.rectangle([4, 5, 6, 6], fill=_c("ffd84a"))
    save(outline(img), "world/lotus.png")
    # cá koi 2 khung
    fr = []
    for f in range(2):
        img, d = canvas(12, 6)
        tail = 1 if f else -1
        d.ellipse([3, 1, 10, 5], fill=_c("f08a3a"))
        d.polygon([(3, 3), (0, 1 + tail), (0, 5 + tail)], fill=_c("f08a3a"))
        d.point([6, 2], fill=_c("ffffff"))
        d.point([8, 3], fill=_c("ffffff"))
        d.point([9, 2], fill=_c("1a1222"))
        fr.append(img)
    save(sheet(fr), "world/koi.png")
    # gà con 2 khung (đi / mổ thóc)
    fr = []
    for f in range(2):
        img, d = canvas(12, 11)
        dy = 2 if f else 0
        d.ellipse([1, 3, 9, 10], fill=_c("e8c060"))
        d.ellipse([6, 0 + dy, 11, 5 + dy], fill=_c("e8c060"))
        auto_shade(img, _c("e8c060"), _c("fff0a0"), _c("a88a3a"))
        d.point([9, 2 + dy], fill=_c("1a1222"))
        d.point([11, 3 + dy], fill=_c("f08a2a"))
        d.point([8, 0 + dy], fill=_c("d83a3a"))
        d.line([(4, 10), (4, 11)], fill=_c("f08a2a"))
        d.line([(6, 10), (6, 11)], fill=_c("f08a2a"))
        fr.append(outline(img))
    save(sheet(fr), "world/chicken.png")


def ambient_art():
    # chiếc lá rơi (trắng xám, game tô màu vàng/cam/xanh)
    img, d = canvas(7, 5)
    d.polygon([(0, 2), (3, 0), (6, 2), (3, 4)], fill=_c("ffffff"))
    d.line([(1, 2), (5, 2)], fill=_c("c8c8c8"))
    save(img, "fx/leaf.png")
    # cánh hoa đào
    img, d = canvas(4, 3)
    d.ellipse([0, 0, 3, 2], fill=_c("ffd0e0"))
    d.point([1, 1], fill=_c("ffffff"))
    save(img, "fx/petal.png")


def loot_art():
    # hòm sơn mài chiến lợi phẩm: 4 khung mở nắp
    fr = []
    for f in range(4):
        img, d = canvas(22, 20)
        d.rectangle([2, 9, 19, 18], fill=_c("8e2632"))
        d.rectangle([2, 9, 19, 10], fill=_c("b8323a"))
        d.line([(2, 18), (19, 18)], fill=_c("5e1a22"))
        d.rectangle([2, 12, 19, 13], fill=_c("e8b04a"))
        d.rectangle([9, 11, 12, 15], fill=_c("e8b04a"))
        d.point([10, 13], fill=_c("5e1a22"))
        lid = [0, 3, 6, 8][f]
        d.polygon([(2, 9 - lid), (19, 9 - lid), (19, 5 - lid * 1.2), (2, 5 - lid * 1.2)], fill=_c("a8323a"))
        d.line([(2, 5 - lid * 1.2), (19, 5 - lid * 1.2)], fill=_c("e05a50"))
        d.line([(2, 9 - lid), (19, 9 - lid)], fill=_c("e8b04a"))
        if f >= 2:
            d.rectangle([4, 9, 17, 10], fill=_c("2a1414"))
            for x in (6, 10, 14):
                d.point([x, 8], fill=_c("fff0a0"))
        fr.append(outline(img))
    save(sheet(fr), "items/loot_chest.png")
    # hồ lô linh khí (xanh lam) và hồ lô lớn (đỏ)
    def gourd(fill, dark, lite, rel, big=False):
        s = 2 if big else 0
        img, d = canvas(12 + s, 14 + s)
        d.rectangle([5, 0, 6 + s, 2], fill=_c("9a6234"))
        d.ellipse([3, 2, 8 + s, 6], fill=_c(fill))
        d.ellipse([1, 5, 10 + s, 13 + s], fill=_c(fill))
        d.ellipse([3, 7, 5, 9], fill=_c(lite))
        d.arc([1, 5, 10 + s, 13 + s], 20, 160, fill=_c(dark))
        d.line([(3, 6), (8 + s, 6)], fill=_c("e8b04a"))
        save(outline(img), rel)
    gourd("3a8ae8", "1a4ea8", "a8d8ff", "items/potion_energy.png")
    gourd("e04848", "8e2632", "ffb0b0", "items/potion_big.png", True)
    # gánh hàng rong: người bán đội nón lá + đòn gánh 2 thúng
    fr = []
    for f in range(2):
        img, d = canvas(30, 30)
        bob = f
        d.polygon([(9, 7 + bob), (15, 1 + bob), (21, 7 + bob)], fill=_c("e8d8a0"))
        d.line([(9, 7 + bob), (21, 7 + bob)], fill=_c("b8a060"))
        d.ellipse([11, 6 + bob, 19, 14 + bob], fill=_c("f5c7a1"))
        d.point([13, 10 + bob], fill=_c("2a1d2e"))
        d.point([17, 10 + bob], fill=_c("2a1d2e"))
        d.line([(14, 12 + bob), (16, 12 + bob)], fill=_c("b8505a"))
        d.rectangle([11, 14 + bob, 19, 23], fill=_c("4a6a8a"))
        d.rectangle([11, 14 + bob, 19, 15 + bob], fill=_c("6a8aaa"))
        d.rectangle([12, 23, 14, 28], fill=_c("2e2a3a"))
        d.rectangle([16, 23, 18, 28], fill=_c("2e2a3a"))
        d.line([(1, 15 + bob), (29, 15 + bob)], fill=_c("8a5a32"), width=2)
        for x in (1, 23):
            d.line([(x + 3, 16 + bob), (x + 1, 22)], fill=_c("c8a060"))
            d.line([(x + 3, 16 + bob), (x + 5, 22)], fill=_c("c8a060"))
            d.ellipse([x, 21, x + 6, 27], fill=_c("b8904a"))
            d.line([(x, 23), (x + 6, 23)], fill=_c("8a6a32"))
            d.point([x + 2, 21], fill=_c("e04848"))
            d.point([x + 4, 21], fill=_c("6aa83a"))
        fr.append(outline(img))
    save(sheet(fr), "world/merchant.png")
    # kệ hàng tre
    img, d = canvas(22, 14)
    d.rectangle([1, 6, 20, 8], fill=_c("9db04c"))
    d.line([(1, 6), (20, 6)], fill=_c("c8d878"))
    d.line([(3, 8), (3, 13)], fill=_c("62702e"), width=2)
    d.line([(18, 8), (18, 13)], fill=_c("62702e"), width=2)
    d.rectangle([2, 4, 19, 6], fill=_c("c8443a"))
    save(outline(img), "world/stand.png")
    # biểu tượng trạng thái: cháy, độc
    img, d = canvas(8, 9)
    d.polygon([(1, 8), (4, 0), (7, 8)], fill=_c("ff8a2a"))
    d.polygon([(3, 8), (4, 4), (5, 8)], fill=_c("ffe060"))
    save(outline(img), "ui/status_burn.png")
    img, d = canvas(8, 8)
    d.ellipse([1, 1, 6, 6], fill=_c("7ad83a"))
    d.point([3, 3], fill=_c("2a5a1a"))
    d.point([4, 4], fill=_c("2a5a1a"))
    d.point([2, 2], fill=_c("d0ffa0"))
    save(outline(img), "ui/status_poison.png")
    # xác giặc: bóng mờ nằm (dùng chung, tô màu theo áo)


def ui():
    gold, gold_l, gold_d = _c("e8b04a"), _c("fff0a0"), _c("a86a2a")
    # khung sơn mài 24x24 (9-slice, lề 6)
    def panel(bg, border, rel):
        img, d = canvas(24, 24)
        d.rectangle([1, 1, 22, 22], fill=bg)
        d.rectangle([0, 1, 23, 22], outline=_c("1a1222"))
        d.rectangle([1, 0, 22, 23], outline=_c("1a1222"))
        d.rectangle([1, 1, 22, 22], outline=border)
        d.line([(2, 2), (21, 2)], fill=tuple(min(255, int(c * 1.3)) for c in border[:3]) + (255,))
        for x, y in ((2, 2), (21, 2), (2, 21), (21, 21)):
            d.point([x, y], fill=gold_l)
        d.rectangle([3, 3, 20, 20], outline=tuple(int(c * 0.75) for c in bg[:3]) + (255,))
        save(img, rel)
    panel(_c("2a1a22"), gold_d, "ui/panel.png")
    panel(_c("6a1e24"), gold, "ui/panel_red.png")
    panel(_c("3a2a1e"), gold, "ui/panel_gold.png")
    # nút: thường / rê chuột / bấm
    for name, bg, br in (("button", _c("8e2632"), gold_d), ("button_hover", _c("b8323a"), gold), ("button_pressed", _c("5e1a22"), gold_d)):
        img, d = canvas(24, 16)
        d.rectangle([1, 1, 22, 14], fill=bg)
        d.rectangle([0, 1, 23, 14], outline=_c("1a1222"))
        d.rectangle([1, 0, 22, 15], outline=_c("1a1222"))
        d.rectangle([1, 1, 22, 14], outline=br)
        d.line([(2, 2), (21, 2)], fill=tuple(min(255, int(c * 1.35)) for c in bg[:3]) + (255,))
        d.line([(2, 13), (21, 13)], fill=tuple(int(c * 0.7) for c in bg[:3]) + (255,))
        save(img, f"ui/{name}.png")
    # biểu tượng 9x9
    icons = {
        "heart": ([".rr.rr..", "rwrrrRr.", "rrrrrRR.", "rrrrRRR.", ".rrRRR..", "..rRR...", "...R...."],
                  {"r": _c("e04848"), "R": _c("8e2632"), "w": _c("ffb0b0")}),
        "shield": (["mmmmmmm", "mwmmmMm", "mmmmmMm", "mmmmMMm", ".mmMMm.", "..mMm..", "...m..."],
                   {"m": _c("a8b0c8"), "M": _c("6a7290"), "w": _c("ffffff")}),
        "energy": (["...cc", "..cc.", ".cccc", "...cc", "..cc.", ".cc..", "cc..."],
                   {"c": _c("62c8ff")}),
        "skull": ([".wwwww.", "wwwwwww", "wkwwkww", "wkwwkww", "wwwkwww", ".wwwww.", ".w.w.w."],
                  {"w": _c("ece8f4"), "k": _c("2a1d2e")}),
    }
    for k, (rows, pal) in icons.items():
        save(outline(grid(rows, pal)), f"ui/icon_{k}.png")
    # đá quý cấp bậc vũ khí 7x7 (5 cấp)
    for i, col in enumerate(("c8c8d0", "6ad06a", "4aa8ff", "c070ff", "ffb030")):
        c = _c(col)
        img = grid([".ccc.", "cwccc", "ccccd", "cccdd", ".cdd."],
                   {"c": c, "w": _c("ffffff"), "d": tuple(int(v * 0.6) for v in c[:3]) + (255,)})
        save(outline(img), f"ui/tier_{i + 1}.png")


def build():
    tiles()
    decor()
    decor2()
    lobby_art()
    lobby_decor()
    ambient_art()
    loot_art()
    ui()


if __name__ == "__main__":
    build()
