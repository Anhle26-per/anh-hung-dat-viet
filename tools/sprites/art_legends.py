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
    sway = [0, 2, 0, -2][walk]
    bob = [0, -1, 0, -1][walk]
    if f == 4:
        sway = 4
    # đuôi xòe sau lưng
    n = 3 if phase == 1 else 9
    base = (26, 34 + bob)
    for i in range(n):
        a = math.radians(-160 + (i - (n - 1) / 2) * (100 / max(n - 1, 1)) * (0.6 if n == 3 else 1.0) + sway * 3)
        a = math.radians(205) + (i - (n - 1) / 2) * (0.30 if n == 9 else 0.45) + math.radians(sway * 2)
        L = 26 if n == 3 else 24 + (i % 2) * 3
        pts = []
        for k in range(9):
            t = k / 8
            r = L * t
            wob = math.sin(t * 3 + i + f * 0.8) * 2.5
            x = base[0] + math.cos(a) * r + math.cos(a + 1.57) * wob
            y = base[1] + math.sin(a) * r * 0.85 + math.sin(a + 1.57) * wob - t * t * 10
            pts.append((x, y))
        for k, (x, y) in enumerate(pts):
            rr = 2.5 + 3.5 * math.sin(k / 8 * 3.0)
            col = fur if k < 6 else tip
            _ell(d, x, y, rr, rr, shade(col, -0.12 if i % 2 else 0))
        x, y = pts[-1]
        _ell(d, x, y, 2, 2, shade(tip, 0.35))
    # thân
    _ell(d, 36, 38 + bob, 15, 10, fur)
    _ell(d, 36, 42 + bob, 13, 6, fur_d)
    d.line([(26, 31 + bob), (44, 30 + bob)], fill=fur_l)
    # chân
    lp = [(0, 0), (2, -2), (0, 0), (-2, -2)][walk]
    for i, x in enumerate((28, 34, 42, 47)):
        dx = lp[0] if i % 2 == 0 else -lp[0]
        dy = lp[1] if i % 2 == 0 else 0
        d.rectangle([x + dx, 44 + bob + dy, x + dx + 3, 52 + dy], fill=fur)
        d.rectangle([x + dx, 51 + dy, x + dx + 3, 53 + dy], fill=C("3a2a30"))
    # cổ + đầu
    _ell(d, 50, 30 + bob, 8, 9, fur)
    hx, hy = 56, 22 + bob
    if f == 4:
        hx += 2
    _ell(d, hx, hy, 9, 7, fur)
    d.polygon([(hx + 5, hy - 1), (hx + 15, hy + 2), (hx + 5, hy + 5)], fill=fur)      # mõm
    _ell(d, hx + 14, hy + 2, 1.5, 1.5, C("2a1d2e"))                                      # mũi
    for ex in (-5, 3):                                                                   # tai
        d.polygon([(hx + ex - 3, hy - 4), (hx + ex, hy - 14), (hx + ex + 4, hy - 4)], fill=fur)
        d.polygon([(hx + ex - 1, hy - 5), (hx + ex, hy - 11), (hx + ex + 2, hy - 5)], fill=red)
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
    sway = [0, 1, 0, -1][walk]
    # rễ làm chân
    for i, (x, lift) in enumerate(((24, [0, 2, 0, 0]), (34, [0, 0, 0, 2]), (44, [2, 0, 0, 0]), (52, [0, 0, 2, 0]))):
        up = lift[walk]
        d.line([(x, 54), (x - 6 + i * 3, 66 - up)], fill=bark_d, width=4)
        d.line([(x - 6 + i * 3, 66 - up), (x - 10 + i * 4, 68 - up)], fill=bark_d, width=3)
    # thân cây
    d.polygon([(22, 58), (26, 26), (48, 26), (54, 58)], fill=bark)
    for x in (28, 34, 41, 47):
        d.line([(x, 30), (x + (1 if x > 38 else -1), 56)], fill=bark_d)
    d.line([(27, 28), (25, 56)], fill=bark_l)
    # cánh tay cành
    arm_up = 6 if f == 4 else (10 if f == 6 else 0)
    for sgn, ax in ((-1, 26), (1, 48)):
        ex = ax + sgn * 18
        ey = 38 - arm_up + sway * sgn
        d.line([(ax, 36), (ex, ey)], fill=bark, width=5)
        d.line([(ex, ey), (ex + sgn * 6, ey - 6)], fill=bark, width=3)
        d.line([(ex, ey), (ex + sgn * 7, ey + 3)], fill=bark, width=2)
        d.line([(ex - sgn * 4, ey - 1), (ex - sgn * 2, ey - 7)], fill=bark, width=2)
        _ell(d, ex + sgn * 6, ey - 7, 4, 3, leaf)
    # tán lá
    for cx, cy, r in ((36, 16, 16), (22, 20, 11), (50, 20, 11), (30, 8, 9), (44, 8, 9)):
        _ell(d, cx + sway, cy, r, r * 0.8, leaf_d)
    for cx, cy, r in ((36, 14, 14), (22, 18, 9), (50, 18, 9), (30, 7, 7), (44, 7, 7)):
        _ell(d, cx + sway, cy, r, r * 0.75, leaf)
    for k in range(18):
        x = 16 + (k * 37) % 42 + sway
        y = 4 + (k * 23) % 22
        d.point([x, y], fill=leaf_l)
        d.point([x + 1, y], fill=leaf_l)
    if phase == 2:
        for k in range(5):
            x = 18 + k * 9 + sway
            d.polygon([(x - 2, 26), (x, 18 - (k + f) % 3 * 2), (x + 2, 26)], fill=C("ffb040"))
    # khuôn mặt hốc cây
    d.ellipse([28, 32, 34, 38], fill=C("1a0e10"))
    d.ellipse([40, 32, 46, 38], fill=C("1a0e10"))
    d.rectangle([30, 34, 32, 36], fill=eye)
    d.rectangle([42, 34, 44, 36], fill=eye)
    if f == 5 or phase == 2:
        d.line([(28, 30), (34, 32)], fill=bark_d, width=2)
        d.line([(46, 30), (40, 32)], fill=bark_d, width=2)
    mouth_h = 6 if f in (4, 6) else 3
    d.ellipse([31, 42, 43, 42 + mouth_h + 2], fill=C("1a0e10"))
    for x in (33, 36, 39):
        d.point([x, 43], fill=C("e8dcc0"))
    # rêu và nấm
    _ell(d, 24, 50, 3, 2, C("6aaa4a"))
    _ell(d, 51, 46, 2, 2, C("e04848"))
    d.point([51, 45], fill=C("ffffff"))
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
    bob = [0, -1, -2, -1][walk]
    tail = [0, 3, 0, -3][walk]
    # vũng nước dưới chân
    d.ellipse([10, 50, 74, 58], fill=C("2a6aa8", 150))
    d.ellipse([16, 52, 68, 57], fill=C("4a9ad8", 150))
    y0 = 26 + bob
    # đuôi
    d.polygon([(14, y0), (2, y0 - 12 + tail), (6, y0), (2, y0 + 12 + tail)], fill=fin)
    d.line([(14, y0), (4, y0 - 9 + tail)], fill=shade(fin, -0.3))
    d.line([(14, y0), (4, y0 + 9 + tail)], fill=shade(fin, -0.3))
    # thân
    _ell(d, 40, y0, 28, 16, sc)
    _ell(d, 42, y0 + 7, 24, 8, belly)
    # vảy
    for row in range(3):
        for col in range(7):
            x = 22 + col * 6 + (row % 2) * 3
            y = y0 - 10 + row * 5
            d.arc([x - 3, y - 2, x + 3, y + 3], 0, 180, fill=sc_d)
            d.point([x, y - 1], fill=sc_l)
    # vây lưng như vương miện
    for i in range(6):
        x = 24 + i * 6
        hgt = 10 + (i % 2) * 4 + (4 if phase == 2 else 0)
        d.polygon([(x - 3, y0 - 13), (x, y0 - 13 - hgt), (x + 3, y0 - 13)], fill=fin)
        d.line([(x, y0 - 13), (x, y0 - 11 - hgt)], fill=shade(fin, 0.3))
    # vây ngực / chân vây
    pw = [0, 2, 0, -2][walk]
    d.polygon([(40, y0 + 10), (34 + pw, y0 + 24), (46 + pw, y0 + 22)], fill=fin)
    d.polygon([(54, y0 + 10), (52 - pw, y0 + 24), (62 - pw, y0 + 20)], fill=fin)
    # đầu, miệng, râu
    jaw = 5 if f in (4, 6) else 2
    d.polygon([(60, y0 - 10), (78, y0 - 2), (78, y0 + 1), (60, y0 + 2)], fill=sc)
    d.polygon([(62, y0 + 2), (78, y0 + 1 + jaw), (62, y0 + 9)], fill=sc_d)
    d.polygon([(64, y0 + 1), (77, y0 + 1), (77, y0 + jaw)], fill=C("5a1a2a"))
    for x in range(65, 77, 3):
        d.polygon([(x, y0), (x + 1, y0 + 2), (x + 2, y0)], fill=C("ffffff"))
    d.ellipse([64, y0 - 8, 70, y0 - 3], fill=C("ffffff"))
    d.rectangle([67, y0 - 7, 69, y0 - 4], fill=eye)
    d.point([68, y0 - 6], fill=C("1a0e10"))
    for k in range(2):
        pts = [(76, y0 + k * 2)] + [(78 + j * 2, y0 + k * 2 + int(math.sin(j + f + k) * 2) + j) for j in range(4)]
        d.line(pts, fill=C("e8b04a"))
    if f == 5 or phase == 2:
        d.line([(63, y0 - 10), (70, y0 - 8)], fill=sc_d, width=2)
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
