"""Tam Yêu trong truyền thuyết Lạc Long Quân: Ngư Tinh, Hồ Tinh, Mộc Tinh.
Mỗi yêu có 2 hình: hình thường (boss_<mã>.png) và hình "hiện nguyên hình" (boss_<mã>_2.png).
Mỗi tờ 7 khung: đi 0-3, tấn công 4, nổi giận 5, tung chiêu 6.
"""
import math
from PIL import Image, ImageDraw
from px import save, polish, shade, hexc

C = hexc


def _sheet(frames, rel):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.alpha_composite(f, (i * w, 0))
    save(s, rel)


class _Shift:
    """Bọc ImageDraw: dịch mọi tọa độ sang phải dx (để đuôi cáo không bị cắt mép)."""
    def __init__(self, d, dx):
        self.d, self.dx = d, dx

    def _p(self, pts):
        if isinstance(pts[0], (tuple, list)):
            return [(x + self.dx, y) for x, y in pts]
        out = list(pts)
        for i in range(0, len(out), 2):
            out[i] += self.dx
        return out

    def __getattr__(self, name):
        f = getattr(self.d, name)
        return lambda xy, *a, **k: f(self._p(xy), *a, **k)


def _ell(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)


# ------------------------------------------------------------------ Hồ Tinh Cửu Vĩ
def fox_frame(f, phase):
    W, H = 84, 60
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = _Shift(ImageDraw.Draw(img), 10)
    fur, fur_d, fur_l = C("f4ece0"), C("c8b8a8"), C("ffffff")
    gold = C("e8b04a")
    red = C("d83a4a") if phase == 1 else C("8a2ae8")
    tip = C("ffb040") if phase == 1 else C("60d8ff")
    walk = f % 4 if f < 4 else 0
    if f < 4:
        sway = [0, 3, 0, -3][walk]
        bob = [0, -3, -1, -2][walk]
        hind_dx = [0, -5, -1, 4][walk]
        hind_dy = [0, -4, -1, 0][walk]
        front_dx = [0, 5, 1, -4][walk]
        front_dy = [0, -4, -1, 0][walk]
    elif f == 4:
        sway = 6
        bob = 2
        hind_dx, hind_dy = -6, -2
        front_dx, front_dy = 7, -3
    else:
        sway = 2 if f == 5 else 0
        bob = -1 if f == 5 else 0
        hind_dx, hind_dy = -2, 0
        front_dx, front_dy = 2, 0
    # đuôi xòe sau lưng
    n = 3 if phase == 1 else 9
    base = (26, 34 + bob)
    for i in range(n):
        a = math.radians(205) + (i - (n - 1) / 2) * (0.30 if n == 9 else 0.45) + math.radians(sway * 2.2)
        L = 26 if n == 3 else 24 + (i % 2) * 3
        pts = []
        for k in range(9):
            t = k / 8
            r = L * t
            wob = math.sin(t * 3.2 + i + f * 1.15) * (3.2 if f != 4 else 1.8)
            x = base[0] + math.cos(a) * r + math.cos(a + 1.57) * wob - (4 * t if f == 4 else 0)
            y = base[1] + math.sin(a) * r * 0.85 + math.sin(a + 1.57) * wob - t * t * (6 if f == 4 else 10)
            pts.append((x, y))
        for k, (x, y) in enumerate(pts):
            rr = 2.5 + 3.5 * math.sin(k / 8 * 3.0)
            col = fur if k < 6 else tip
            _ell(d, x, y, rr, rr, shade(col, -0.12 if i % 2 else 0))
        x, y = pts[-1]
        _ell(d, x, y, 2, 2, shade(tip, 0.35))
    # chân sau & chân trước phi nước đại
    for i, x in enumerate((26, 32, 43, 49)):
        is_front = i >= 2
        dx = (front_dx if is_front else hind_dx) + (1 if i % 2 else -1)
        dy = front_dy if is_front else hind_dy
        hy_hip = 41 + bob
        px = min(68, max(8, x + dx))
        py = min(53, 51 + dy + (bob // 2))
        d.line([(x, hy_hip), (px + 1, py - 2)], fill=fur_d if i % 2 else fur, width=4)
        d.rectangle([px - 1, py - 2, px + 3, py], fill=fur)
        d.rectangle([px - 1, py, px + 3, py + 2], fill=C("3a2a30"))
    # thân
    _ell(d, 36 + (2 if f == 4 else 0), 38 + bob, 16 if f == 4 else 15, 9 if f == 4 else 10, fur)
    _ell(d, 36 + (2 if f == 4 else 0), 42 + bob, 13, 6, fur_d)
    d.line([(26, 31 + bob), (44, 30 + bob)], fill=fur_l)
    # cổ + đầu
    _ell(d, 50 + (2 if f == 4 else 0), 30 + bob, 8, 9, fur)
    hx, hy = 56, 22 + bob
    if f == 4:
        hx += 5
        hy += 2
    _ell(d, hx, hy, 9, 7, fur)
    d.polygon([(hx + 5, hy - 1), (hx + 15, hy + 2), (hx + 5, hy + 5)], fill=fur)      # mõm
    _ell(d, hx + 14, hy + 2, 1.5, 1.5, C("2a1d2e"))                                      # mũi
    ear_tilt = -4 if f == 4 else 0
    for ex in (-5, 3):                                                                   # tai
        d.polygon([(hx + ex - 3, hy - 4), (hx + ex + ear_tilt, hy - 13), (hx + ex + 4, hy - 4)], fill=fur)
        d.polygon([(hx + ex - 1, hy - 5), (hx + ex + ear_tilt, hy - 10), (hx + ex + 2, hy - 5)], fill=red)
    d.line([(hx + 1, hy - 1), (hx + 7, hy)], fill=red)                                  # vằn mặt
    d.line([(hx - 4, hy + 2), (hx - 1, hy + 4)], fill=red)
    eye = C("ffe040") if phase == 1 else C("ff3060")
    d.rectangle([hx + 3, hy - 1, hx + 5, hy], fill=eye)
    d.point([hx + 5, hy - 1], fill=C("2a1d2e"))
    if f in (4, 6):
        d.polygon([(hx + 6, hy + 4), (hx + 15, hy + 3), (hx + 8, hy + 7)], fill=C("8e2632"))
        d.point([hx + 8, hy + 4], fill=fur_l)
    # vòng cổ chuông vàng + hạt châu
    d.arc([42, 26 + bob, 56, 40 + bob], 20, 160, fill=gold, width=2)
    _ell(d, 49, 38 + bob, 2, 2, C("c8443a") if phase == 1 else C("60d8ff"))
    if phase == 2 or f == 6:
        for k in range(6):
            a = k / 6 * math.tau + f
            _ell(d, 36 + math.cos(a) * 26, 30 + math.sin(a) * 12, 2, 2, C("80e0ff"))
    if f == 5:
        d.line([(hx + 3, hy - 3), (hx + 6, hy - 2)], fill=C("2a1d2e"))
    return polish(img, texture=False)


# ------------------------------------------------------------------ Mộc Tinh (cây chiên đàn nghìn năm)
def tree_frame(f, phase):
    W, H = 72, 72
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bark, bark_d, bark_l = C("6a4a32"), C("4a3020"), C("8a6a48")
    leaf = C("3e7a3a") if phase == 1 else C("b8402a")
    leaf_l = C("6aaa4a") if phase == 1 else C("f08a3a")
    leaf_d = C("2a5a2a") if phase == 1 else C("7a2a20")
    eye = C("a0ff70") if phase == 1 else C("ff4a2a")
    walk = f % 4 if f < 4 else 0
    sway = [0, 2, 0, -2][walk] if f < 4 else 0
    bob = [0, -2, 0, -2][walk] if f < 4 else (2 if f == 4 else 0)
    # rễ làm chân (nâng cao khi bước nặng nề)
    lifts = ((24, [0, 6, 1, 0], [0, 3, 0, -2]), (34, [0, 0, 1, 6], [0, -2, 0, 3]), (44, [6, 0, 0, 1], [3, 0, -2, 0]), (52, [0, 1, 6, 0], [-2, 0, 3, 0]))
    for i, (x, lift, hstep) in enumerate(lifts):
        up = lift[walk] if f < 4 else (4 if f == 4 else 0)
        sx = hstep[walk] if f < 4 else (-3 if i < 2 else 3)
        d.line([(x + sway // 2, 54 + bob), (x - 6 + i * 3 + sx, 66 - up)], fill=bark_d, width=5)
        d.line([(x - 6 + i * 3 + sx, 66 - up), (x - 10 + i * 4 + sx, 68 - up)], fill=bark_d, width=3)
    # thân cây
    d.polygon([(22 + sway // 2, 58 + bob), (26 + sway, 26 + bob), (48 + sway, 26 + bob), (54 + sway // 2, 58 + bob)], fill=bark)
    for x in (28, 34, 41, 47):
        d.line([(x + sway, 30 + bob), (x + (1 if x > 38 else -1) + sway // 2, 56 + bob)], fill=bark_d)
    d.line([(27 + sway, 28 + bob), (25 + sway // 2, 56 + bob)], fill=bark_l)
    # cánh tay cành (vung ngược chiều khi đi, giơ cao khi đập/nhảy)
    for sgn, ax in ((-1, 26), (1, 48)):
        if f == 4:
            adx, ady = sgn * 16, -12
        elif f == 6:
            adx, ady = sgn * 18, -14
        elif f == 5:
            adx, ady = sgn * 20, -4
        else:
            l_dy = [-3, 3, -1, -4][walk]
            r_dy = [3, -4, 1, 3][walk]
            l_dx = [-2, 3, 0, -3][walk]
            r_dx = [2, -3, 0, 3][walk]
            ady = l_dy if sgn < 0 else r_dy
            adx = sgn * 17 + (l_dx if sgn < 0 else r_dx)
        sx0 = ax + sway
        sy0 = 36 + bob
        ex = sx0 + adx
        ey = 38 + bob + ady
        d.line([(sx0, sy0), (ex, ey)], fill=bark, width=5)
        d.line([(ex, ey), (ex + sgn * 6, ey - 6)], fill=bark, width=3)
        d.line([(ex, ey), (ex + sgn * 7, ey + 3)], fill=bark, width=2)
        d.line([(ex - sgn * 4, ey - 1), (ex - sgn * 2, ey - 7)], fill=bark, width=2)
        _ell(d, ex + sgn * 6, ey - 7, 4, 3, leaf)
    # tán lá
    for cx, cy, r in ((36, 16, 16), (22, 20, 11), (50, 20, 11), (30, 8, 9), (44, 8, 9)):
        _ell(d, cx + sway, cy + bob, r, r * 0.8, leaf_d)
    for cx, cy, r in ((36, 14, 14), (22, 18, 9), (50, 18, 9), (30, 7, 7), (44, 7, 7)):
        _ell(d, cx + sway, cy + bob, r, r * 0.75, leaf)
    for k in range(18):
        x = 16 + (k * 37) % 42 + sway
        y = 4 + (k * 23) % 22 + bob
        d.point([x, y], fill=leaf_l)
        d.point([x + 1, y], fill=leaf_l)
    if phase == 2:
        for k in range(5):
            x = 18 + k * 9 + sway
            d.polygon([(x - 2, 26 + bob), (x, 18 + bob - (k + f) % 3 * 2), (x + 2, 26 + bob)], fill=C("ffb040"))
    # khuôn mặt hốc cây
    d.ellipse([28 + sway, 32 + bob, 34 + sway, 38 + bob], fill=C("1a0e10"))
    d.ellipse([40 + sway, 32 + bob, 46 + sway, 38 + bob], fill=C("1a0e10"))
    d.rectangle([30 + sway, 34 + bob, 32 + sway, 36 + bob], fill=eye)
    d.rectangle([42 + sway, 34 + bob, 44 + sway, 36 + bob], fill=eye)
    if f == 5 or phase == 2:
        d.line([(28 + sway, 30 + bob), (34 + sway, 32 + bob)], fill=bark_d, width=2)
        d.line([(46 + sway, 30 + bob), (40 + sway, 32 + bob)], fill=bark_d, width=2)
    mouth_h = 6 if f in (4, 6) else 3
    d.ellipse([31 + sway, 42 + bob, 43 + sway, 42 + bob + mouth_h + 2], fill=C("1a0e10"))
    for x in (33, 36, 39):
        d.point([x + sway, 43 + bob], fill=C("e8dcc0"))
    # rêu và nấm
    _ell(d, 24 + sway // 2, 50 + bob, 3, 2, C("6aaa4a"))
    _ell(d, 51 + sway // 2, 46 + bob, 2, 2, C("e04848"))
    d.point([51 + sway // 2, 45 + bob], fill=C("ffffff"))
    return polish(img)


# ------------------------------------------------------------------ Ngư Tinh (thủy quái Biển Đông)
def fish_frame(f, phase):
    W, H = 84, 60
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    sc, sc_d, sc_l = (C("3a8aa8"), C("1e5a78"), C("7ad0e0")) if phase == 1 else (C("6a3a8a"), C("3a1e5a"), C("b07ad8"))
    belly = C("e8dcb0")
    fin = C("e05a4a") if phase == 1 else C("ff3a6a")
    eye = C("fff0a0") if phase == 1 else C("ff4040")
    walk = f % 4 if f < 4 else 0
    bob = [0, -2, -3, -1][walk] if f < 4 else (1 if f == 4 else -1)
    tail = [0, 7, 1, -7][walk] if f < 4 else (-5 if f == 4 else 2)
    lunge_x = 3 if f == 4 else 0
    # vũng nước & bọt sóng dưới bụng
    d.ellipse([10, 50, 74, 58], fill=C("2a6aa8", 150))
    d.ellipse([16 + walk * 2, 52, 68 - walk, 57], fill=C("4a9ad8", 160))
    d.arc([12, 49, 72, 57], (walk * 30) % 180, (walk * 30 + 110) % 360, fill=C("bce8ff"), width=1)
    y0 = 26 + bob
    # đuôi quẫy mạnh
    d.polygon([(14 + lunge_x, y0), (1, y0 - 13 + tail), (6, y0 + tail // 3), (1, y0 + 13 + tail)], fill=fin)
    d.line([(14 + lunge_x, y0), (3, y0 - 10 + tail)], fill=shade(fin, -0.3))
    d.line([(14 + lunge_x, y0), (3, y0 + 10 + tail)], fill=shade(fin, -0.3))
    # thân
    _ell(d, 40 + lunge_x, y0, 28, 16, sc)
    _ell(d, 42 + lunge_x, y0 + 7, 24, 8, belly)
    # vảy
    for row in range(3):
        for col in range(7):
            x = 22 + lunge_x + col * 6 + (row % 2) * 3
            y = y0 - 10 + row * 5
            d.arc([x - 3, y - 2, x + 3, y + 3], 0, 180, fill=sc_d)
            d.point([x, y - 1], fill=sc_l)
    # vây lưng như vương miện
    for i in range(6):
        x = 24 + lunge_x + i * 6
        hgt = 10 + (i % 2) * 4 + (4 if phase == 2 else 0)
        d.polygon([(x - 3, y0 - 13), (x - (2 if f == 4 else 0), y0 - 13 - hgt), (x + 3, y0 - 13)], fill=fin)
        d.line([(x, y0 - 13), (x - (1 if f == 4 else 0), y0 - 11 - hgt)], fill=shade(fin, 0.3))
    # vây ngực / chân vây quạt rộng
    pw = [0, 5, 1, -5][walk] if f < 4 else -6
    py = [0, -3, 0, 2][walk] if f < 4 else -3
    d.polygon([(40 + lunge_x, y0 + 10), (33 + pw, y0 + 24 + py), (46 + pw, y0 + 22 + py)], fill=fin)
    d.polygon([(54 + lunge_x, y0 + 10), (50 - pw, y0 + 24 - py), (62 - pw, y0 + 20 - py)], fill=fin)
    # đầu, miệng, râu
    jaw = 7 if f in (4, 6) else 2
    hx = 60 + lunge_x
    d.polygon([(hx, y0 - 10), (hx + 18, y0 - 2), (hx + 18, y0 + 1), (hx, y0 + 2)], fill=sc)
    d.polygon([(hx + 2, y0 + 2), (hx + 18, y0 + 1 + jaw), (hx + 2, y0 + 9)], fill=sc_d)
    d.polygon([(hx + 4, y0 + 1), (hx + 17, y0 + 1), (hx + 17, y0 + jaw)], fill=C("5a1a2a"))
    for x in range(hx + 5, hx + 17, 3):
        d.polygon([(x, y0), (x + 1, y0 + 2), (x + 2, y0)], fill=C("ffffff"))
    d.ellipse([hx + 4, y0 - 8, hx + 10, y0 - 3], fill=C("ffffff"))
    d.rectangle([hx + 7, y0 - 7, hx + 9, y0 - 4], fill=eye)
    d.point([hx + 8, y0 - 6], fill=C("1a0e10"))
    for k in range(2):
        pts = [(hx + 16, y0 + k * 2)] + [(min(83, hx + 18 + j * 2), y0 + k * 2 + int(math.sin(j + f + k) * 2) + j) for j in range(4)]
        d.line(pts, fill=C("e8b04a"))
    if f == 5 or phase == 2:
        d.line([(hx + 3, y0 - 10), (hx + 10, y0 - 8)], fill=sc_d, width=2)
    if f == 6:
        for k in range(5):
            d.ellipse([70 + k * 2, y0 - 16 - k * 3, 73 + k * 2, y0 - 13 - k * 3], fill=C("a8e8ff"))
    return polish(img, texture=False)


def build():
    for fn, rel in ((fox_frame, "ho_tinh_vuong"), (tree_frame, "moc_tinh_vuong"), (fish_frame, "ngu_tinh_vuong")):
        for phase in (1, 2):
            frames = [fn(i, phase) for i in range(7)]
            _sheet(frames, "enemies/boss_%s%s.png" % (rel, "" if phase == 1 else "_2"))


if __name__ == "__main__":
    build()
