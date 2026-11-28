"""Gạch nền và tường đa sắc độ (14 cột): 8 bối cảnh, tường cao 2 ô, lối đi lát đá/gỗ,
viền cỏ/đá, thảm lễ nghi, bóng đổ mềm và chi tiết rải sàn.

world/tiles.png   : mỗi hàng 1 bối cảnh, 14 cột:
                    0-3 sàn chính, 4-5 tường tầng trên, 6-7 tường tầng dưới, 8 nóc tường,
                    9 lối đi (walkway), 10 sân giữa (center), 11 viền rìa (trim),
                    12 thảm nghi lễ (ceremony), 13 gạch điểm xuyết (accent)
world/shadows.png : 3 ô bóng đổ mềm (trên, trái, góc)
world/details.png : 8 chi tiết rải sàn (sỏi, cỏ, lá, hoa, vết nứt, xương, vũng nước, rơm)
"""
import math
import random
from px import hexc, save, Image, ImageDraw

T = 16


def C(h, a=255):
    return hexc(h, a)


def mix(c1, c2, k):
    return tuple(int(c1[i] * (1 - k) + c2[i] * k) for i in range(3)) + (255,)


def lighten(c, k):
    # Hue-shift ánh sáng vàng nắng ấm
    return mix(c, (255, 240, 202), k)


def darken(c, k):
    # Hue-shift bóng đổ tím lam lạnh tạo chiều sâu khối
    return mix(c, (26, 18, 44), k)


# Bảng màu đa sắc cho 8 bối cảnh (sàn, tường, mái, lối đi, viền cỏ/đá, nghi lễ)
THEMES = [
    # 0 rừng núi Nưa (rêu xanh mát, tường đá xám xanh, lối đá cuội vàng nhạt)
    {"floor": "5d7452", "wall": "6d7866", "roof": "3e5638", "path": "9c8c6c", "trim": "4d7c3e", "cer": "8e3838", "fk": "slab", "wk": "stone", "accent": "72b84a"},
    # 1 sông Bạch Đằng (sàn gỗ ấm, cọc lim, lối cầu ván sáng, viền sóng lam)
    {"floor": "8a623c", "wall": "5d6878", "roof": "3a4a60", "path": "b48858", "trim": "4a6e7c", "cer": "9a3438", "fk": "plank", "wk": "palisade", "accent": "62a8d8"},
    # 2 Thành Thăng Long (gạch Bát Tràng đỏ cam, tường son vàng, lối đá xám vàng)
    {"floor": "a85c42", "wall": "923e36", "roof": "582426", "path": "c2aa84", "trim": "7c4632", "cer": "b62e34", "fk": "terracotta", "wk": "brick", "accent": "f0b84e"},
    # 3 Gò Đống Đa (sân đá lam xám, tường vôi kem mái ngói đỏ, lối đá sáng, hoa đào hồng)
    {"floor": "828090", "wall": "c0b6a6", "roof": "8e3830", "path": "b2aa9c", "trim": "6a7866", "cer": "a4323a", "fk": "slab", "wk": "plaster", "accent": "f4a0c0"},
    # 4 Làng quê Mê Linh (đất phù sa ấm, hàng rào tre lục, lối lát gạch vàng, cỏ xanh)
    {"floor": "94724a", "wall": "8ca04a", "roof": "546e30", "path": "b89262", "trim": "5c8c3a", "cer": "9e3834", "fk": "dirt", "wk": "bamboo", "accent": "74b844"},
    # 5 Đồn Pháp (nền đá xi măng ấm nhẹ, tường đá xám vàng, lối gạch đan, rêu viền)
    {"floor": "848882", "wall": "9c927e", "roof": "5c564a", "path": "aca694", "trim": "5e7252", "cer": "8a3834", "fk": "concrete", "wk": "concrete", "accent": "7c9460"},
    # 6 Chiến hào Điện Biên (đất nâu đỏ, ụ bao cát vàng, ván gỗ lót hào, cỏ sẫm)
    {"floor": "745c3e", "wall": "b49464", "roof": "645438", "path": "9c744c", "trim": "4e6638", "cer": "9c3630", "fk": "mud", "wk": "sandbag", "accent": "e0a850"},
    # 7 Doanh trại (gạch cung đình kem vàng, tường sơn son thếp vàng)
    {"floor": "c2aa84", "wall": "a83430", "roof": "5e2022", "path": "d4be98", "trim": "8c7654", "cer": "a62c32", "fk": "palace", "wk": "lacquer", "accent": "f0b84e"},
]


def _img(c=(0, 0, 0, 0)):
    return Image.new("RGBA", (T, T), c)


def _soft_bevel(px, x0, y0, x1, y1, base, lk=0.10, dk=0.12):
    """Phiến đá/gạch chuyển sắc êm, không viền gắt."""
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


def _soft_mottle(px, rng, x0, y0, x1, y1, base, n, k=0.05):
    """Mảng màu loang mượt 2-3 điểm, tránh lấm tấm pixel."""
    for _ in range(n):
        x, y = rng.randint(x0, max(x0, x1 - 2)), rng.randint(y0, max(y0, y1 - 1))
        c = lighten(base, k) if rng.random() < 0.5 else darken(base, k)
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            if px[x + dx, y + dy] == base:
                px[x + dx, y + dy] = c


# ---------------------------------------------------------------- Sàn chính (cột 0-3)
def floor(th, v, rng):
    base = C(th["floor"])
    grout = darken(base, 0.24)
    acc = C(th["accent"])
    img = _img(grout)
    px = img.load()
    d = ImageDraw.Draw(img)
    k = th["fk"]
    if k in ("slab", "palace"):
        tone = base if v == 0 else (darken(base, 0.03) if v == 1 else lighten(base, 0.03))
        if v == 3:
            _soft_bevel(px, 0, 0, 15, 7, tone, 0.09, 0.11)
            _soft_bevel(px, 0, 8, 15, 15, lighten(tone, 0.03), 0.09, 0.11)
        else:
            _soft_bevel(px, 0, 0, 15, 15, tone, 0.09, 0.11)
            _soft_mottle(px, rng, 2, 2, 13, 13, tone, 5, 0.04)
        if v == 1:
            d.line([(4, 4), (7, 7), (6, 11)], fill=darken(tone, 0.18))
            d.point([8, 7], fill=lighten(tone, 0.1))
        if v == 2 and k != "palace":
            for _ in range(3):
                x, y = rng.randint(3, 11), rng.randint(3, 11)
                d.ellipse([x, y, x + 2, y + 1], fill=acc)
        if k == "palace" and v == 2:
            d.rectangle([4, 4, 11, 11], outline=lighten(tone, 0.10))
            d.point([7, 7], fill=C("e8b04a"))
    elif k == "terracotta":
        for (x0, y0) in ((0, 0), (8, 0), (0, 8), (8, 8)):
            b = base if (x0 + y0) % 16 == 0 else darken(base, 0.04)
            _soft_bevel(px, x0, y0, x0 + 7, y0 + 7, b, 0.11, 0.14)
        if v == 1:
            d.line([(9, 9), (12, 12)], fill=darken(base, 0.22))
        if v == 2:
            d.ellipse([3, 3, 4, 4], fill=acc)
            d.ellipse([11, 11, 12, 12], fill=acc)
    elif k == "plank":
        for i, y0 in enumerate((0, 4, 8, 12)):
            b = base if i % 2 == 0 else darken(base, 0.05)
            d.rectangle([0, y0, 15, y0 + 2], fill=b)
            d.line([(0, y0), (15, y0)], fill=lighten(b, 0.08))
            d.line([(0, y0 + 3), (15, y0 + 3)], fill=darken(b, 0.16))
            end = (5 + i * 7) % 16
            d.line([(end, y0), (end, y0 + 2)], fill=grout)
            gx = rng.randint(1, 12)
            d.line([(gx, y0 + 1), (gx + 3, y0 + 1)], fill=darken(b, 0.08))
        if v == 2:
            d.ellipse([4, 5, 11, 10], fill=darken(base, 0.12))
    elif k == "dirt":
        tone = base if v != 1 else darken(base, 0.03)
        img = _img(tone)
        px = img.load()
        d = ImageDraw.Draw(img)
        _soft_mottle(px, rng, 0, 0, 15, 15, tone, 8, 0.05)
        if v == 2:
            for dx in (0, 3):
                d.line([(5 + dx, 10), (6 + dx, 7)], fill=acc)
        if v == 3:
            d.ellipse([5, 6, 8, 8], fill=lighten(tone, 0.08))
    elif k == "concrete":
        img = _img(base)
        px = img.load()
        d = ImageDraw.Draw(img)
        d.line([(0, 15), (15, 15)], fill=darken(base, 0.12))
        d.line([(15, 0), (15, 15)], fill=darken(base, 0.12))
        d.line([(0, 0), (14, 0)], fill=lighten(base, 0.06))
        _soft_mottle(px, rng, 1, 1, 13, 13, base, 6, 0.04)
        if v == 1:
            d.line([(3, 12), (7, 8), (12, 7)], fill=darken(base, 0.20))
        if v == 2:
            d.ellipse([4, 4, 11, 9], fill=darken(base, 0.07))
    elif k == "mud":
        img = _img(base)
        px = img.load()
        d = ImageDraw.Draw(img)
        _soft_mottle(px, rng, 0, 0, 15, 15, base, 8, 0.06)
        if v == 2:
            d.ellipse([4, 6, 7, 8], fill=C("5a7898"))
        if v == 1:
            d.line([(3, 4), (7, 4)], fill=darken(base, 0.16))
            d.line([(9, 11), (13, 11)], fill=darken(base, 0.16))
    return img


# ---------------------------------------------------------------- Sàn phụ đa sắc (cột 9-13)
def walkway_tile(th, rng):
    """Cột 9: lối đi lát đá / cầu ván sáng nổi bật dẫn giữa các cửa."""
    p = C(th["path"])
    grout = darken(p, 0.28)
    img = _img(grout)
    px = img.load()
    d = ImageDraw.Draw(img)
    k = th["fk"]
    if k in ("plank", "mud"):
        # ván gỗ bắc cầu / ván lót chiến hào
        for y0 in (0, 8):
            _soft_bevel(px, 0, y0, 15, y0 + 6, p if y0 == 0 else darken(p, 0.05), 0.12, 0.16)
            d.line([(2, y0 + 3), (13, y0 + 3)], fill=darken(p, 0.08))
        d.rectangle([2, 0, 4, 15], fill=darken(p, 0.20))
        d.rectangle([11, 0, 13, 15], fill=darken(p, 0.20))
    else:
        # đá phiến lát so le 2 hàng
        _soft_bevel(px, 0, 0, 7, 7, p, 0.13, 0.15)
        _soft_bevel(px, 8, 0, 15, 7, darken(p, 0.04), 0.13, 0.15)
        _soft_bevel(px, 0, 8, 4, 15, darken(p, 0.03), 0.13, 0.15)
        _soft_bevel(px, 5, 8, 12, 15, lighten(p, 0.03), 0.13, 0.15)
        _soft_bevel(px, 13, 8, 15, 15, darken(p, 0.04), 0.13, 0.15)
        _soft_mottle(px, rng, 1, 1, 14, 14, p, 4, 0.05)
    return img


def center_tile(th):
    """Cột 10: ô gạch sân giữa trang trí hình thoi/viền vàng nhẹ."""
    p = lighten(C(th["path"]), 0.08)
    acc = C(th["accent"])
    img = _img(p)
    px = img.load()
    d = ImageDraw.Draw(img)
    _soft_bevel(px, 0, 0, 15, 15, p, 0.12, 0.15)
    d.rectangle([2, 2, 13, 13], outline=mix(p, acc, 0.45))
    d.polygon([(7, 4), (11, 7), (7, 11), (4, 7)], fill=mix(p, acc, 0.25), outline=mix(p, acc, 0.65))
    d.point([7, 7], fill=lighten(acc, 0.25))
    return img


def trim_tile(th, rng):
    """Cột 11: ô rìa tiếp giáp tường (rêu/cỏ/viền đá chuyển tiếp mềm)."""
    base = C(th["floor"])
    tr = C(th["trim"])
    blend = mix(base, tr, 0.55)
    img = _img(blend)
    px = img.load()
    d = ImageDraw.Draw(img)
    _soft_mottle(px, rng, 0, 0, 15, 15, blend, 10, 0.08)
    for _ in range(4):
        x, y = rng.randint(2, 13), rng.randint(2, 13)
        d.line([(x, y), (x + 1, y - 2)], fill=lighten(tr, 0.20))
    return img


def ceremony_tile(th):
    """Cột 12: thảm son vàng khu vực lễ nghi (phòng Trùm / Tam Yêu / Kho báu / Chợ)."""
    cer = C(th["cer"])
    gold = C("e8b04a")
    img = _img(cer)
    px = img.load()
    d = ImageDraw.Draw(img)
    _soft_bevel(px, 0, 0, 15, 15, cer, 0.12, 0.18)
    d.rectangle([1, 1, 14, 14], outline=darken(cer, 0.25))
    d.rectangle([2, 2, 13, 13], outline=mix(cer, gold, 0.55))
    d.polygon([(7, 5), (10, 7), (7, 10), (5, 7)], fill=mix(cer, gold, 0.35))
    return img


def accent_tile(th, rng):
    """Cột 13: gạch điểm xuyết phá vỡ sự lặp lại đơn điệu."""
    base = mix(C(th["floor"]), C(th["path"]), 0.32)
    acc = C(th["accent"])
    img = _img(base)
    px = img.load()
    d = ImageDraw.Draw(img)
    _soft_bevel(px, 0, 0, 15, 15, base, 0.10, 0.12)
    d.rectangle([4, 4, 11, 11], outline=mix(base, acc, 0.38))
    _soft_mottle(px, rng, 1, 1, 14, 14, base, 4, 0.05)
    return img


# ---------------------------------------------------------------- Tường 2 tầng + mái/nóc (cột 4-8)
def wall_pair(th, v, rng):
    base = C(th["wall"])
    roof = C(th["roof"])
    acc = C(th["accent"])
    lt, dk, mortar = lighten(base, 0.16), darken(base, 0.24), darken(base, 0.40)
    up, lo = _img(base), _img(base)
    pu, pl = up.load(), lo.load()
    du, dl = ImageDraw.Draw(up), ImageDraw.Draw(lo)
    k = th["wk"]

    def blocks(d, y0, rows, bw, bh, off_alt=True):
        for r in range(rows):
            y = y0 + r * bh
            off = (bw // 2) if (r % 2 and off_alt) else 0
            for x in range(-off, T, bw):
                b = base if rng.random() < 0.7 else (lighten(base, 0.06) if rng.random() < 0.5 else darken(base, 0.06))
                d.rectangle([x, y, x + bw - 2, y + bh - 2], fill=b)
                d.line([(x, y), (x + bw - 2, y)], fill=lighten(b, 0.14))
                d.line([(x, y + bh - 2), (x + bw - 2, y + bh - 2)], fill=darken(b, 0.14))

    if k in ("stone", "brick", "concrete", "sandbag"):
        for d in (du, dl):
            d.rectangle([0, 0, 15, 15], fill=mortar)
        if k == "stone":
            blocks(du, 4, 3, 8, 4)
            blocks(dl, 0, 3, 8, 4)
            if v == 1:
                du.ellipse([3, 7, 6, 9], fill=acc)
        elif k == "brick":
            blocks(du, 4, 4, 6, 3)
            blocks(dl, 0, 4, 6, 3)
        elif k == "concrete":
            du.rectangle([0, 0, 15, 15], fill=base)
            dl.rectangle([0, 0, 15, 15], fill=base)
            du.line([(0, 10), (15, 10)], fill=dk)
            dl.line([(7, 0), (7, 15)], fill=darken(base, 0.14))
            if v == 1:
                du.rectangle([5, 6, 10, 9], fill=darken(base, 0.45))
        elif k == "sandbag":
            for d, y0 in ((du, 4), (dl, 0)):
                for r in range(3):
                    y = y0 + r * 4
                    off = 4 if r % 2 else 0
                    for x in range(-off, T, 8):
                        d.rounded_rectangle([x, y, x + 7, y + 3], 1, fill=base)
                        d.line([(x + 1, y), (x + 5, y)], fill=lt)
    elif k == "palisade":
        for d in (du, dl):
            d.rectangle([0, 0, 15, 15], fill=darken(base, 0.50))
        for x in range(0, T, 4):
            b = base if (x // 4) % 2 == 0 else darken(base, 0.08)
            du.rectangle([x, 3, x + 3, 15], fill=b)
            du.polygon([(x, 3), (x + 1, 0), (x + 3, 3)], fill=roof)
            dl.rectangle([x, 0, x + 3, 15], fill=b)
            for d in (du, dl):
                d.line([(x, 3 if d is du else 0), (x, 15)], fill=lighten(b, 0.14))
        du.line([(0, 9), (15, 9)], fill=C("d8b878"))
        dl.line([(0, 8), (15, 8)], fill=C("d8b878"))
    elif k == "bamboo":
        for d in (du, dl):
            d.rectangle([0, 0, 15, 15], fill=darken(base, 0.52))
        for x in range(0, T, 4):
            b = base if (x // 4) % 2 == 0 else darken(base, 0.09)
            for d, y0 in ((du, 2), (dl, 0)):
                d.rectangle([x, y0, x + 2, 15], fill=b)
                d.line([(x, y0), (x, 15)], fill=lighten(b, 0.22))
            du.line([(x, 7), (x + 2, 7)], fill=darken(b, 0.30))
            dl.line([(x, 7), (x + 2, 7)], fill=darken(b, 0.30))
        du.line([(0, 10), (15, 10)], fill=C("a8804a"))
    elif k == "plaster":
        du.rectangle([0, 0, 15, 15], fill=base)
        dl.rectangle([0, 0, 15, 15], fill=base)
        if v == 1:
            du.rectangle([5, 7, 10, 12], fill=darken(base, 0.40))
            for x in (6, 8):
                du.line([(x, 7), (x, 12)], fill=C("6a4028"))
    elif k == "lacquer":
        gold = C("e8b04a")
        du.rectangle([0, 0, 15, 15], fill=base)
        dl.rectangle([0, 0, 15, 15], fill=base)
        du.rectangle([2, 5, 13, 14], outline=C("a86a2a"))
        dl.rectangle([2, 1, 13, 10], outline=C("a86a2a"))
        if v == 1:
            du.rectangle([6, 8, 9, 11], fill=gold)

    # Mái / viền nóc tường trên có bóng đổ mái hiên phía dưới tạo chiều sâu 3D
    du.rectangle([0, 0, 15, 3], fill=roof)
    du.line([(0, 0), (15, 0)], fill=lighten(roof, 0.28))
    du.line([(0, 3), (15, 3)], fill=darken(roof, 0.34))
    du.line([(0, 4), (15, 4)], fill=darken(base, 0.42))
    du.line([(0, 5), (15, 5)], fill=darken(base, 0.22))
    if k in ("brick", "plaster", "lacquer"):
        for x in range(0, T, 4):
            du.line([(x + 1, 0), (x + 1, 2)], fill=lighten(roof, 0.18))
            du.point([(x + 3) % T, 2], fill=darken(roof, 0.22))
    elif k in ("stone", "bamboo"):
        if v == 1:
            # Dây leo rêu rủ từ mái xuống tường
            du.line([(2, 3), (3, 9)], fill=darken(acc, 0.20))
            du.line([(3, 4), (4, 7)], fill=acc)
    # Chân tường đậm tiếp giáp sàn (plinth AO rõ nét)
    plinth = darken(base, 0.44)
    dl.rectangle([0, 11, 15, 15], fill=plinth)
    dl.line([(0, 11), (15, 11)], fill=darken(base, 0.26))
    dl.line([(0, 14), (15, 14)], fill=darken(plinth, 0.38))
    dl.line([(0, 15), (15, 15)], fill=darken(plinth, 0.52))
    return up, lo


def wall_top(th, rng):
    """Cột 8: nóc tường / mái vây hài hòa với nền bối cảnh, không kẻ ô vuông gắt."""
    roof = C(th["roof"])
    base = darken(roof, 0.30)
    img = _img(base)
    px = img.load()
    d = ImageDraw.Draw(img)
    _soft_mottle(px, rng, 0, 0, 15, 15, base, 6, 0.08)
    d.rectangle([1, 1, 14, 14], fill=mix(base, roof, 0.38))
    d.line([(2, 2), (13, 2)], fill=lighten(roof, 0.14))
    d.line([(2, 13), (13, 13)], fill=darken(roof, 0.36))
    return img


def shadows():
    img = Image.new("RGBA", (T * 3, T), (0, 0, 0, 0))
    px = img.load()
    for y in range(T):
        for x in range(T):
            top = max(0.0, 1.0 - y / 13.0)
            left = max(0.0, 1.0 - x / 8.0)
            if top > 0.0:
                px[x, y] = (16, 10, 28, int(155 * top * top))
            if left > 0.0:
                px[T + x, y] = (16, 10, 28, int(112 * left * left))
            c = max(top, left)
            if c > 0.0:
                px[T * 2 + x, y] = (16, 10, 28, int(155 * c * c))
    save(img, "world/shadows.png")


def details():
    img = Image.new("RGBA", (T * 8, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = 0   # sỏi nhiều cỡ có bóng đổ & ánh sáng
    for x, y in ((4, 9), (8, 11), (11, 7)):
        d.ellipse([o + x, y + 1, o + x + 3, y + 3], fill=(22, 16, 30, 120))
        d.ellipse([o + x, y, o + x + 3, y + 2], fill=C("b8b09e"))
        d.point([o + x + 1, y], fill=C("e6dec8"))
        d.point([o + x + 2, y + 2], fill=C("6a6458"))
    o = T   # bụi cỏ xanh tươi 3 tầng
    for x, h in ((4, 5), (7, 7), (9, 6), (11, 4)):
        d.line([(o + x, 13), (o + x + (1 if x % 2 else -1), 13 - h)], fill=C("386824"))
    d.line([(o + 7, 13), (o + 7, 6)], fill=C("62aa42"))
    d.point([o + 7, 6], fill=C("a8e878"))
    o = T * 2   # lá rụng thu nhiều sắc độ
    for x, y, c, ch in ((4, 6, "c8762c", "f0a648"), (9, 10, "9e4e20", "d47a38"), (11, 5, "d89632", "f8ce66")):
        d.ellipse([o + x, y + 1, o + x + 3, y + 3], fill=(24, 16, 28, 95))
        d.ellipse([o + x, y, o + x + 3, y + 2], fill=C(c))
        d.point([o + x + 1, y], fill=C(ch))
    o = T * 3   # hoa dại có lá nền & cánh nổi
    for x, y, pet in ((5, 7, "fff6ec"), (10, 10, "ffbfd4")):
        d.ellipse([o + x - 1, y + 1, o + x + 1, y + 2], fill=C("3e722a"))
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            d.point([o + x + dx, y + dy], fill=C(pet))
        d.point([o + x, y], fill=C("ffd048"))
    o = T * 4   # vết nứt có viền sáng cạnh vỡ
    d.line([(o + 4, 4), (o + 8, 8), (o + 7, 12), (o + 11, 14)], fill=(255, 240, 210, 50))
    d.line([(o + 3, 4), (o + 7, 8), (o + 6, 12), (o + 10, 14)], fill=(28, 18, 34, 135))
    o = T * 5   # mảnh xương có khối
    d.line([(o + 4, 10), (o + 11, 8)], fill=(24, 16, 30, 105), width=2)
    d.line([(o + 4, 9), (o + 11, 7)], fill=C("d8ceb8"), width=2)
    d.line([(o + 5, 8), (o + 10, 7)], fill=C("fff8ec"), width=1)
    d.point([o + 3, 9], fill=C("ede4d0"))
    d.point([o + 12, 7], fill=C("ede4d0"))
    o = T * 6   # vũng nước lấp lánh đa sắc
    d.ellipse([o + 2, 6, o + 13, 11], fill=(48, 88, 138, 155))
    d.ellipse([o + 3, 7, o + 11, 10], fill=(78, 136, 192, 165))
    d.line([(o + 4, 8), (o + 9, 8)], fill=(224, 246, 255, 210))
    o = T * 7   # rơm vàng 2 lớp
    for i in range(5):
        d.line([(o + 3 + i * 2, 12), (o + 6 + i * 2, 9 - i % 2)], fill=C("b08c3e"))
        d.line([(o + 3 + i * 2, 11), (o + 6 + i * 2, 8 - i % 2)], fill=C("f0d478"))
    save(img, "world/details.png")


def build():
    rng = random.Random(21)
    atlas = Image.new("RGBA", (T * 14, T * len(THEMES)), (0, 0, 0, 0))
    for r, th in enumerate(THEMES):
        cells = [floor(th, v, rng) for v in range(4)]
        u0, l0 = wall_pair(th, 0, rng)
        u1, l1 = wall_pair(th, 1, rng)
        cells += [
            u0, u1, l0, l1,
            wall_top(th, rng),
            walkway_tile(th, rng),
            center_tile(th),
            trim_tile(th, rng),
            ceremony_tile(th),
            accent_tile(th, rng),
        ]
        for c, img in enumerate(cells):
            atlas.alpha_composite(img, (c * T, r * T))
    save(atlas, "world/tiles.png")
    shadows()
    details()


if __name__ == "__main__":
    build()
