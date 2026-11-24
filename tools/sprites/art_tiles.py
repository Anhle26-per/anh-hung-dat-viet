"""Gạch nền và tường (vẽ lại cho đẹp): 8 bối cảnh, tường cao 2 ô, bóng đổ, chi tiết rải sàn.

world/tiles.png   : mỗi hàng 1 bối cảnh, 10 cột:
                    0-3 sàn, 4-5 tường tầng trên, 6-7 tường tầng dưới, 8 nóc tường, 9 sàn đặc biệt
world/shadows.png : 3 ô bóng đổ (trên, trái, góc)
world/details.png : 8 chi tiết rải sàn (sỏi, cỏ, lá, hoa, vết nứt, xương, vũng nước, rơm)
"""
import random
from px import hexc, save, Image, ImageDraw

T = 16


def C(h, a=255):
    return hexc(h, a)


def mix(c1, c2, k):
    return tuple(int(c1[i] * (1 - k) + c2[i] * k) for i in range(3)) + (255,)


def lighten(c, k):
    return mix(c, (255, 246, 220), k)


def darken(c, k):
    return mix(c, (26, 16, 34), k)


# Bảng màu từng bối cảnh: sàn, tường, kiểu sàn, kiểu tường
THEMES = [
    {"floor": "6b7558", "wall": "7a8462", "fk": "slab", "wk": "stone", "accent": "5e9a3a"},        # 0 rừng núi
    {"floor": "8a6038", "wall": "6e5236", "fk": "plank", "wk": "palisade", "accent": "4a8ab0"},    # 1 sông nước
    {"floor": "a65a3e", "wall": "8e3a30", "fk": "terracotta", "wk": "brick", "accent": "e8b04a"}, # 2 Thăng Long
    {"floor": "8c8890", "wall": "b8aea0", "fk": "slab", "wk": "plaster", "accent": "f4a0c0"},      # 3 Đống Đa
    {"floor": "8e7048", "wall": "9aa04c", "fk": "dirt", "wk": "bamboo", "accent": "6aa83a"},       # 4 làng quê
    {"floor": "8a8a80", "wall": "9a9282", "fk": "concrete", "wk": "concrete", "accent": "6a6a60"}, # 5 đồn Pháp
    {"floor": "6e5a3c", "wall": "b09264", "fk": "mud", "wk": "sandbag", "accent": "4a6a8a"},       # 6 chiến hào
    {"floor": "c0a882", "wall": "a8322e", "fk": "palace", "wk": "lacquer", "accent": "e8b04a"},    # 7 doanh trại
]


def _img(c=(0, 0, 0, 0)):
    return Image.new("RGBA", (T, T), c)


def _bevel(px, x0, y0, x1, y1, base, lk=0.18, dk=0.22):
    """Phiến có gờ: cạnh trên/trái sáng, cạnh dưới/phải tối."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = base
    lt, dk_ = lighten(base, lk), darken(base, dk)
    for x in range(x0, x1 + 1):
        px[x, y0] = lt
        px[x, y1] = dk_
    for y in range(y0, y1 + 1):
        px[x0, y] = lt if y < y1 else dk_
        px[x1, y] = dk_


def _speckle(px, rng, x0, y0, x1, y1, base, n, k=0.08):
    """Vân đá: các cụm 2 điểm sáng/tối nhẹ (không nhiễu lấm tấm)."""
    for _ in range(n):
        x, y = rng.randint(x0, x1 - 1), rng.randint(y0, y1)
        c = lighten(base, k) if rng.random() < 0.5 else darken(base, k)
        if px[x, y] == base:
            px[x, y] = c
        if px[x + 1, y] == base:
            px[x + 1, y] = c


# ---------------------------------------------------------------- Sàn
def floor(th, v, rng):
    base = C(th["floor"])
    grout = darken(base, 0.45)
    acc = C(th["accent"])
    img = _img(grout)
    px = img.load()
    d = ImageDraw.Draw(img)
    k = th["fk"]
    if k in ("slab", "palace"):
        if v == 3:   # hai phiến nhỏ
            _bevel(px, 0, 0, 14, 6, base)
            _bevel(px, 0, 8, 14, 14, lighten(base, 0.04))
        else:
            _bevel(px, 0, 0, 14, 14, base if v != 1 else darken(base, 0.04))
            _speckle(px, rng, 2, 2, 12, 12, base, 6)
        if v == 1:
            d.line([(4, 3), (7, 7), (6, 11)], fill=darken(base, 0.35))
            d.point([8, 7], fill=lighten(base, 0.2))
        if v == 2 and k != "palace":
            for _ in range(5):
                x, y = rng.randint(2, 11), rng.randint(2, 11)
                d.rectangle([x, y, x + 1, y], fill=acc)
                d.point([x, y + 1], fill=darken(acc, 0.3))
        if k == "palace" and v == 2:
            d.rectangle([4, 4, 10, 10], outline=lighten(base, 0.15))
            d.rectangle([6, 6, 8, 8], fill=darken(base, 0.08))
            d.point([7, 7], fill=C("e8b04a"))
    elif k == "terracotta":
        for (x0, y0) in ((0, 0), (8, 0), (0, 8), (8, 8)):
            b = base if (x0 + y0) % 16 == 0 else darken(base, 0.06)
            _bevel(px, x0, y0, x0 + 6, y0 + 6, b, 0.2, 0.25)
        if v == 1:
            d.line([(9, 9), (12, 12)], fill=darken(base, 0.4))
        if v == 2:
            d.rectangle([3, 3, 4, 4], fill=acc)
            d.rectangle([11, 11, 12, 12], fill=acc)
    elif k == "plank":
        for i, y0 in enumerate((0, 4, 8, 12)):
            b = base if i % 2 == 0 else darken(base, 0.08)
            for y in range(y0, y0 + 3):
                for x in range(T):
                    px[x, y] = b
            for x in range(T):
                px[x, y0] = lighten(b, 0.12)
            end = (5 + i * 7) % 16
            for y in range(y0, y0 + 3):
                px[end, y] = grout
            gx = rng.randint(1, 12)
            d.line([(gx, y0 + 1), (gx + 3, y0 + 1)], fill=darken(b, 0.12))
            px[(end + 1) % 16, y0 + 1] = darken(b, 0.35)
        if v == 2:
            d.ellipse([4, 5, 11, 10], fill=darken(base, 0.18))
    elif k == "dirt":
        img = _img(base)
        px = img.load()
        d = ImageDraw.Draw(img)
        for _ in range(10):
            x, y = rng.randint(0, 14), rng.randint(0, 14)
            c = lighten(base, 0.07) if rng.random() < 0.5 else darken(base, 0.08)
            d.rectangle([x, y, x + 1, y], fill=c)
        if v in (1, 3):
            for _ in range(2):
                x, y = rng.randint(2, 12), rng.randint(2, 12)
                d.rectangle([x, y, x + 1, y], fill=C("a8a090"))
                d.point([x, y + 1], fill=C("6a6458"))
        if v == 2:
            for dx in (0, 2, 4):
                d.line([(5 + dx, 10), (6 + dx, 6 + dx % 3)], fill=acc)
    elif k == "concrete":
        img = _img(base)
        px = img.load()
        d = ImageDraw.Draw(img)
        d.line([(0, 15), (15, 15)], fill=darken(base, 0.25))
        d.line([(15, 0), (15, 15)], fill=darken(base, 0.25))
        d.line([(0, 0), (14, 0)], fill=lighten(base, 0.1))
        _speckle(px, rng, 1, 1, 13, 13, base, 8, 0.06)
        if v == 1:
            d.line([(3, 12), (7, 8), (12, 7)], fill=darken(base, 0.35))
        if v == 2:
            d.ellipse([4, 4, 11, 9], fill=darken(base, 0.1))
    elif k == "mud":
        img = _img(base)
        px = img.load()
        d = ImageDraw.Draw(img)
        for _ in range(12):
            x, y = rng.randint(0, 14), rng.randint(0, 14)
            d.rectangle([x, y, x + 1, y], fill=darken(base, 0.1) if rng.random() < 0.6 else lighten(base, 0.06))
        if v == 2:
            for x, y in ((4, 6), (10, 10)):
                d.rectangle([x, y, x + 1, y], fill=C("8a8478"))
                d.point([x, y + 1], fill=C("4a4640"))
        if v == 1:
            d.line([(2, 4), (5, 4)], fill=darken(base, 0.3))
            d.line([(9, 11), (13, 11)], fill=darken(base, 0.3))
    return img


# ---------------------------------------------------------------- Tường: 2 tầng (upper, lower) + nóc
def wall_pair(th, v, rng):
    base = C(th["wall"])
    lt, dk, mortar = lighten(base, 0.2), darken(base, 0.3), darken(base, 0.5)
    up, lo = _img(base), _img(base)
    pu, pl = up.load(), lo.load()
    du, dl = ImageDraw.Draw(up), ImageDraw.Draw(lo)
    k = th["wk"]

    def blocks(d, px, y0, rows, bw, bh, off_alt=True):
        for r in range(rows):
            y = y0 + r * bh
            off = (bw // 2) if (r % 2 and off_alt) else 0
            for x in range(-off, T, bw):
                b = base if rng.random() < 0.7 else (lighten(base, 0.05) if rng.random() < 0.5 else darken(base, 0.06))
                d.rectangle([x, y, x + bw - 2, y + bh - 2], fill=b)
                d.line([(x, y), (x + bw - 2, y)], fill=lighten(b, 0.18))
                d.line([(x, y + bh - 2), (x + bw - 2, y + bh - 2)], fill=darken(b, 0.18))

    if k in ("stone", "brick", "concrete", "sandbag"):
        for img, d in ((up, du), (lo, dl)):
            d.rectangle([0, 0, 15, 15], fill=mortar)
        if k == "stone":
            blocks(du, pu, 3, 3, 8, 5)
            blocks(dl, pl, 0, 3, 8, 5)
        elif k == "brick":
            blocks(du, pu, 3, 4, 6, 3)
            blocks(dl, pl, 1, 5, 6, 3)
        elif k == "concrete":
            du.rectangle([0, 0, 15, 15], fill=base)
            dl.rectangle([0, 0, 15, 15], fill=base)
            du.line([(0, 9), (15, 9)], fill=dk)
            dl.line([(7, 0), (7, 15)], fill=darken(base, 0.15))
            if v == 1:
                dl.line([(10, 3), (10, 12)], fill=C("6a5a3a"))
                dl.line([(11, 3), (11, 9)], fill=C("7a6a4a"))
        elif k == "sandbag":
            for d, y0 in ((du, 3), (dl, 0)):
                for r in range(3):
                    y = y0 + r * 5
                    off = 4 if r % 2 else 0
                    for x in range(-off, T, 8):
                        d.rounded_rectangle([x, y, x + 7, y + 4], 2, fill=base)
                        d.line([(x + 1, y + 1), (x + 5, y + 1)], fill=lt)
                        d.line([(x + 1, y + 4), (x + 6, y + 4)], fill=dk)
    elif k == "palisade":
        for d in (du, dl):
            d.rectangle([0, 0, 15, 15], fill=darken(base, 0.55))
        for x in range(0, T, 4):
            b = base if (x // 4) % 2 == 0 else darken(base, 0.08)
            du.rectangle([x, 2, x + 3, 15], fill=b)
            du.polygon([(x, 2), (x + 1.5, 0), (x + 3, 2)], fill=b)
            dl.rectangle([x, 0, x + 3, 15], fill=b)
            for d in (du, dl):
                d.line([(x, 0), (x, 15)], fill=lighten(b, 0.15))
                d.line([(x + 3, 0), (x + 3, 15)], fill=darken(b, 0.25))
        du.line([(0, 8), (15, 8)], fill=C("c8a870"))
        dl.line([(0, 9), (15, 9)], fill=C("c8a870"))
    elif k == "bamboo":
        for d in (du, dl):
            d.rectangle([0, 0, 15, 15], fill=darken(base, 0.6))
        for x in range(0, T, 4):
            b = base if (x // 4) % 2 == 0 else darken(base, 0.1)
            for d, y0 in ((du, 1), (dl, 0)):
                d.rectangle([x, y0, x + 2, 15], fill=b)
                d.line([(x, y0), (x, 15)], fill=lighten(b, 0.25))
            for y in (5, 12):
                du.line([(x, y), (x + 2, y)], fill=darken(b, 0.35))
            dl.line([(x, 7), (x + 2, 7)], fill=darken(b, 0.35))
        du.line([(0, 9), (15, 9)], fill=C("8a6a3a"))
    elif k == "plaster":
        du.rectangle([0, 0, 15, 15], fill=base)
        dl.rectangle([0, 0, 15, 15], fill=base)
        for x in range(0, T, 4):                     # mái ngói nhỏ trên đầu tường
            du.rectangle([x, 0, x + 3, 3], fill=C("8e3a30"))
            du.line([(x, 0), (x + 3, 0)], fill=C("c05a48"))
            du.point([x + 3, 3], fill=C("5e2620"))
        du.line([(0, 4), (15, 4)], fill=darken(base, 0.35))
        dl.rectangle([0, 9, 15, 15], fill=darken(base, 0.2))      # chân tường
        dl.line([(0, 9), (15, 9)], fill=C("8e3a30"))
        if v == 1:
            du.rectangle([5, 7, 10, 12], fill=darken(base, 0.4))   # ô cửa sổ song
            for x in (6, 8):
                du.line([(x, 7), (x, 12)], fill=C("6a4028"))
    elif k == "lacquer":
        gold, gold_d = C("e8b04a"), C("a86a2a")
        du.rectangle([0, 0, 15, 15], fill=base)
        dl.rectangle([0, 0, 15, 15], fill=base)
        du.rectangle([0, 0, 15, 2], fill=C("5e3a20"))
        du.line([(0, 2), (15, 2)], fill=gold)
        du.rectangle([2, 5, 13, 15], outline=gold_d)
        dl.rectangle([2, 0, 13, 9], outline=gold_d)
        dl.rectangle([0, 11, 15, 15], fill=C("5e3a20"))
        dl.line([(0, 11), (15, 11)], fill=gold)
        if v == 1:
            du.rectangle([6, 8, 9, 11], fill=gold)
            du.point([7, 9], fill=C("fff0a0"))
        for img in (up, lo):
            p = img.load()
            for y in range(T):
                p[0, y] = lighten(p[0, y], 0.12)
    # gờ mái trên cùng của tầng trên + chân tường tối ở tầng dưới
    du.line([(0, 0), (15, 0)], fill=lighten(base, 0.35))
    du.line([(0, 1), (15, 1)], fill=darken(base, 0.45)) if k not in ("plaster", "lacquer", "palisade") else None
    dl.line([(0, 15), (15, 15)], fill=darken(base, 0.55))
    return up, lo


def wall_top(th):
    base = darken(C(th["wall"]), 0.55)
    img = _img(base)
    d = ImageDraw.Draw(img)
    d.rectangle([1, 1, 14, 14], fill=lighten(base, 0.08))
    d.line([(1, 1), (14, 1)], fill=lighten(base, 0.18))
    d.rectangle([0, 0, 15, 15], outline=darken(base, 0.3))
    return img


def shadows():
    img = Image.new("RGBA", (T * 3, T), (0, 0, 0, 0))
    px = img.load()
    for y in range(T):
        for x in range(T):
            top = max(0, 1 - y / 6.0)
            left = max(0, 1 - x / 4.0)
            if top > 0:
                px[x, y] = (12, 6, 18, int(120 * top))
            if left > 0:
                px[T + x, y] = (12, 6, 18, int(90 * left))
            c = max(top, left)
            if c > 0:
                px[T * 2 + x, y] = (12, 6, 18, int(120 * c))
    save(img, "world/shadows.png")


def details():
    img = Image.new("RGBA", (T * 8, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = 0   # sỏi
    for x, y in ((5, 9), (8, 11), (11, 8)):
        d.ellipse([o + x, y, o + x + 2, y + 1], fill=C("a8a090"))
        d.point([o + x + 1, y + 2], fill=C("5a5650"))
    o = T   # cỏ
    for x, h in ((5, 4), (7, 6), (9, 5), (11, 3)):
        d.line([(o + x, 12), (o + x + (1 if x % 2 else -1), 12 - h)], fill=C("6aa83a"))
    d.line([(o + 7, 12), (o + 7, 7)], fill=C("8ad05a"))
    o = T * 2   # lá rụng
    for x, y, c in ((4, 6, "c8843a"), (9, 10, "a8602a"), (11, 5, "d8a040")):
        d.ellipse([o + x, y, o + x + 3, y + 1], fill=C(c))
    o = T * 3   # hoa dại
    for x, y in ((5, 7), (10, 10)):
        d.point([o + x, y], fill=C("f4e060"))
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            d.point([o + x + dx, y + dy], fill=C("ffffff"))
    o = T * 4   # vết nứt
    d.line([(o + 3, 4), (o + 7, 8), (o + 6, 12), (o + 10, 14)], fill=(30, 20, 30, 140))
    o = T * 5   # mảnh xương
    d.line([(o + 4, 9), (o + 11, 7)], fill=C("e8e0cc"), width=2)
    d.point([o + 3, 9], fill=C("e8e0cc"))
    d.point([o + 12, 7], fill=C("e8e0cc"))
    o = T * 6   # vũng nước
    d.ellipse([o + 2, 6, o + 13, 11], fill=(70, 100, 140, 150))
    d.line([(o + 5, 8), (o + 8, 8)], fill=(200, 230, 255, 180))
    o = T * 7   # rơm
    for i in range(5):
        d.line([(o + 3 + i * 2, 11), (o + 6 + i * 2, 8 - i % 2)], fill=C("e0c470"))
    save(img, "world/details.png")


def build():
    rng = random.Random(21)
    atlas = Image.new("RGBA", (T * 10, T * len(THEMES)), (0, 0, 0, 0))
    for r, th in enumerate(THEMES):
        cells = [floor(th, v, rng) for v in range(4)]
        u0, l0 = wall_pair(th, 0, rng)
        u1, l1 = wall_pair(th, 1, rng)
        cells += [u0, u1, l0, l1, wall_top(th), floor(th, 0, rng)]
        for c, img in enumerate(cells):
            atlas.alpha_composite(img, (c * T, r * T))
    save(atlas, "world/tiles.png")
    shadows()
    details()


if __name__ == "__main__":
    build()
