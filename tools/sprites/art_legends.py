"""Tam Yêu & Trùm Thần Thoại thiết kế chi tiết sắc nét (24 khung mượt mà):
Hồ Tinh Cửu Vĩ, Mộc Tinh, Ngư Tinh Vương.
Mỗi trùm có 2 hình (Pha 1 thường + Pha 2 hiện nguyên hình), mỗi tờ 24 khung:
0-7 đi tuần/chạy 8 nhịp, 8-10 gồng lấy đà, 11-14 đòn đánh liên hoàn,
15-16 lướt tốc, 17-19 dậm nhảy, 20-21 cuồng nộ, 22-23 tung tuyệt chiêu.
"""
import math
import random
from PIL import Image, ImageDraw
from px import save, polish, shade, hexc, hue_ramp

C = hexc


def _sheet(frames, rel):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.alpha_composite(f, (i * w, 0))
    save(s, rel)


class _Shift:
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


# ------------------------------------------------------------------ Hồ Tinh Cửu Vĩ (84x60 x 24)
def fox_frame(f, phase):
    W, H = 84, 60
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = _Shift(ImageDraw.Draw(img), 10)
    _, fur_d, fur, fur_l, _ = hue_ramp("f4e8d8" if phase == 1 else "efe6f8")
    gold_d, _, gold, gold_l, gold_s = hue_ramp("f0b848")
    red = C("e2384c") if phase == 1 else C("9a38f8")
    tip = C("ffae38") if phase == 1 else C("64e4ff")
    tip_s = C("fff298") if phase == 1 else C("e4ffff")

    t = (f / 8.0) * math.tau
    is_atk = f in (11, 12, 13, 15, 16, 18)
    is_wind = f in (8, 9, 10, 17)
    is_rage = f in (20, 21)
    is_spec = f in (22, 23)
    if f < 8:
        sway = round(math.sin(t) * 3)
        bob = round(-1.5 + math.cos(t * 2) * 1.5)
        hind_dx, hind_dy = round(-math.sin(t) * 5), round(-abs(math.cos(t)) * 3)
        front_dx, front_dy = round(math.sin(t) * 5), round(-abs(math.sin(t)) * 3)
        lunge = 0
    elif f in (8, 9, 10):
        k = f - 7  # 1,2,3
        sway, bob, lunge = -k * 2, k, -k
        hind_dx, hind_dy, front_dx, front_dy = -4 - k, -1, 2, -2
    elif f in (11, 12, 13, 14):
        prog = [3, 6, 4, 1][f - 11]
        sway, bob, lunge = prog, -1 if f in (11, 12) else 1, prog
        hind_dx, hind_dy, front_dx, front_dy = -prog, -2, prog + 1, -3 if f <= 12 else 0
    elif f in (15, 16):
        sway, bob, lunge = 7, 2, 6
        hind_dx, hind_dy, front_dx, front_dy = -8, -3, 8, -4
    elif f in (17, 18, 19):
        if f == 17:
            sway, bob, lunge = -2, 3, -1
            hind_dx, hind_dy, front_dx, front_dy = -4, 0, 3, 0
        elif f == 18:
            sway, bob, lunge = 5, -6, 4
            hind_dx, hind_dy, front_dx, front_dy = -7, -5, 7, -5
        else:
            sway, bob, lunge = 2, 2, 2
            hind_dx, hind_dy, front_dx, front_dy = -2, 0, 4, 1
    else:
        sway = 2 if f in (20, 22) else -2
        bob = -2 if f in (20, 23) else 0
        lunge = 0
        hind_dx, hind_dy, front_dx, front_dy = -2, 0, 2, 0

    # Đuôi xòe phân tầng rực rỡ (3 đuôi pha 1, 9 đuôi pha 2)
    n = 3 if phase == 1 else 9
    base = (26 + lunge // 2, 34 + bob)
    for i in range(n):
        a = math.radians(205) + (i - (n - 1) / 2) * (0.31 if n == 9 else 0.45) + math.radians(sway * 2.2)
        L = 26 if n == 3 else 25 + (i % 2) * 3
        pts = []
        for k in range(9):
            tt = k / 8
            r = L * tt
            wob = math.sin(tt * 3.2 + i + f * 0.78) * (3.2 if not is_atk else 1.8)
            x = base[0] + math.cos(a) * r + math.cos(a + 1.57) * wob - (4 * tt if is_atk else 0)
            y = base[1] + math.sin(a) * r * 0.85 + math.sin(a + 1.57) * wob - tt * tt * (6 if is_atk else 10)
            pts.append((x, y))
        for k, (x, y) in enumerate(pts):
            rr = 2.6 + 3.6 * math.sin(k / 8 * 3.0)
            col = fur if k < 5 else (red if (phase == 2 and k == 5) else tip)
            _ell(d, x, y, rr, rr, shade(col, -0.14 if i % 2 else 0.04))
        x, y = pts[-1]
        _ell(d, x, y, 2.2, 2.2, tip_s)

    for i, x in enumerate((26, 32, 43, 49)):
        is_front = i >= 2
        dx = (front_dx if is_front else hind_dx) + (1 if i % 2 else -1)
        dy = front_dy if is_front else hind_dy
        hy_hip = 41 + bob
        px = min(68, max(8, x + dx + lunge // 2))
        py = min(54, max(38, 51 + dy + (bob // 2)))
        d.line([(x + lunge // 2, hy_hip), (px + 1, py - 2)], fill=fur_d if i % 2 else fur, width=4)
        d.rectangle([px - 1, py - 2, px + 3, py], fill=fur)
        d.rectangle([px - 1, py, px + 3, py + 2], fill=C("3a2834"))

    _ell(d, 36 + lunge // 2, 38 + bob, 16 if is_atk else 15, 9 if is_atk else 10, fur)
    _ell(d, 36 + lunge // 2, 42 + bob, 13, 6, fur_d)
    d.line([(26 + lunge // 2, 31 + bob), (44 + lunge // 2, 30 + bob)], fill=fur_l)
    _ell(d, 50 + lunge // 2, 30 + bob, 8, 9, fur)
    hx, hy = 56 + lunge, 22 + bob + (2 if is_atk else 0)
    _ell(d, hx, hy, 9, 7, fur)
    d.polygon([(hx + 5, hy - 1), (hx + 15, hy + 2), (hx + 5, hy + 5)], fill=fur)
    _ell(d, hx + 14, hy + 2, 1.5, 1.5, C("2a1d2e"))
    ear_tilt = -4 if is_atk else (-2 if is_wind else 0)
    for ex in (-5, 3):
        d.polygon([(hx + ex - 3, hy - 4), (hx + ex + ear_tilt, hy - 13), (hx + ex + 4, hy - 4)], fill=fur)
        d.polygon([(hx + ex - 1, hy - 5), (hx + ex + ear_tilt, hy - 10), (hx + ex + 2, hy - 5)], fill=red)
        d.point([hx + ex + ear_tilt, hy - 12], fill=C("2c1c2e"))
    d.line([(hx + 1, hy - 1), (hx + 7, hy)], fill=red)
    d.line([(hx - 4, hy + 2), (hx - 1, hy + 4)], fill=red)
    if phase == 2:
        d.arc([hx - 2, hy - 6, hx + 3, hy - 2], 200, 360, fill=gold_s)
    eye = C("ffe448") if phase == 1 else C("ff2c68")
    d.rectangle([hx + 3, hy - 1, hx + 5, hy], fill=eye)
    d.point([hx + 5, hy - 1], fill=C("24162c"))
    if is_atk or is_spec or is_rage:
        d.polygon([(hx + 6, hy + 4), (hx + 15, hy + 3), (hx + 8, hy + 7)], fill=C("8e2632"))
        d.point([hx + 8, hy + 4], fill=fur_l)
    d.arc([42 + lunge // 2, 26 + bob, 56 + lunge // 2, 40 + bob], 20, 160, fill=gold, width=2)
    d.line([(43 + lunge // 2, 35 + bob), (37 + lunge // 2, 39 + bob + (sway // 2))], fill=red, width=2)
    _ell(d, 49 + lunge // 2, 38 + bob, 2, 2, C("e04038") if phase == 1 else C("64e4ff"))
    if f in (15, 16):
        for k in range(3):
            y_s = 20 + k * 10 + (f % 2) * 3
            d.line([(-4, y_s), (14, y_s)], fill=tip_s)
    if f == 19:
        d.arc([16, 48, 68, 58], 0, 180, fill=gold_s)
    if phase == 2 or is_spec or is_rage:
        for k in range(6):
            a = k / 6 * math.tau + f * 0.65
            _ell(d, 36 + math.cos(a) * 26, 30 + math.sin(a) * 12, 2.2, 2.2, C("84e8ff") if not is_rage else tip)
    if is_rage:
        d.line([(hx + 3, hy - 3), (hx + 6, hy - 2)], fill=C("2a1d2e"))
    return polish(img, texture=False)


# ------------------------------------------------------------------ Mộc Tinh (72x72 x 24)
def tree_frame(f, phase):
    W, H = 72, 72
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bark_deep, bark_d, bark, bark_l, _ = hue_ramp("6c4a32" if phase == 1 else "543228")
    leaf_deep, leaf_d, leaf, leaf_l, leaf_s = hue_ramp("3e823a" if phase == 1 else "c24428")
    eye = C("a8ff74") if phase == 1 else C("ff5028")
    rune = C("7cf8a0") if phase == 1 else C("ffae38")
    t = (f / 8.0) * math.tau
    rng = random.Random(33 + phase * 7)

    if f < 8:
        sway = round(math.sin(t) * 2)
        bob = round(-1 + math.cos(t * 2))
        dx_shift = 0
    elif f in (8, 9, 10):
        sway, bob, dx_shift = 0, -(f - 7), 0
    elif f in (11, 12, 13, 14):
        sway, bob, dx_shift = 0, [0, 3, 2, 0][f - 11], [1, 2, 1, 0][f - 11]
    elif f in (15, 16):
        sway, bob, dx_shift = 2, 1, 4
    elif f in (17, 18, 19):
        sway, bob, dx_shift = 0, [3, -6, 3][f - 17], 0
    else:
        sway = 1 if f % 2 == 0 else -1
        bob = -2 if f in (20, 22) else 0
        dx_shift = 0

    for i, x in enumerate((24, 34, 44, 52)):
        phase_leg = t + i * (math.pi / 2)
        up = max(0, round(math.sin(phase_leg) * 5)) if f < 8 else (6 if f == 18 else (2 if f in (8, 9, 10) else 0))
        sx = round(math.cos(phase_leg) * 3) if f < 8 else (-3 if i < 2 else 3)
        d.line([(x + sway // 2 + dx_shift, 54 + bob), (x - 6 + i * 3 + sx + dx_shift, 66 - up)], fill=bark_d, width=5)
        d.line([(x - 6 + i * 3 + sx + dx_shift, 66 - up), (x - 10 + i * 4 + sx + dx_shift, 68 - up)], fill=bark_deep, width=3)

    d.polygon([(22 + sway // 2 + dx_shift, 58 + bob), (26 + sway + dx_shift, 26 + bob), (48 + sway + dx_shift, 26 + bob), (54 + sway // 2 + dx_shift, 58 + bob)], fill=bark)
    for x in (28, 34, 41, 47):
        d.line([(x + sway + dx_shift, 30 + bob), (x + (1 if x > 38 else -1) + sway // 2 + dx_shift, 56 + bob)], fill=bark_d)
    d.line([(27 + sway + dx_shift, 28 + bob), (25 + sway // 2 + dx_shift, 56 + bob)], fill=bark_l)
    d.polygon([(36 + sway // 2 + dx_shift, 50 + bob), (39 + sway // 2 + dx_shift, 53 + bob), (36 + sway // 2 + dx_shift, 56 + bob), (33 + sway // 2 + dx_shift, 53 + bob)], fill=rune)

    for sgn, ax in ((-1, 26), (1, 48)):
        if f in (8, 9, 10, 17, 22, 23):
            k = 10 if f in (8, 17) else 15
            adx, ady = sgn * 16, -k
        elif f in (11, 12, 13, 14, 19):
            ady = [-4, 10, 8, 2, 12][min(4, f - 11 if f <= 14 else 4)]
            adx = sgn * (19 if f in (12, 13, 19) else 17)
        elif f in (15, 16):
            adx, ady = sgn * 18 - 4, -2
        elif f in (20, 21):
            adx, ady = sgn * 20, -6 if f == 20 else -3
        else:
            ang = t + (0 if sgn < 0 else math.pi)
            ady = round(math.sin(ang) * 4)
            adx = sgn * 17 + round(math.cos(ang) * 3)
        sx0, sy0 = ax + sway + dx_shift, 36 + bob
        ex, ey = max(3, min(68, sx0 + adx)), max(4, min(68, 38 + bob + ady))
        d.line([(sx0, sy0), (ex, ey)], fill=bark, width=5)
        d.line([(ex, ey), (ex + sgn * 5, ey - 5)], fill=bark, width=3)
        d.line([(ex, ey), (ex + sgn * 6, ey + 3)], fill=bark_d, width=2)
        d.line([(ex - sgn * 4, ey - 1), (ex - sgn * 2, ey - 7)], fill=bark, width=2)
        _ell(d, ex + sgn * 5, ey - 6, 4, 3, leaf_l)

    for cx, cy, r in ((36, 16, 16), (22, 20, 11), (50, 20, 11), (30, 8, 9), (44, 8, 9)):
        _ell(d, cx + sway + dx_shift, cy + bob, r, r * 0.8, leaf_d)
    for cx, cy, r in ((36, 14, 14), (22, 18, 9), (50, 18, 9), (30, 7, 7), (44, 7, 7)):
        _ell(d, cx + sway + dx_shift, cy + bob, r, r * 0.75, leaf)
    for cx, cy, r in ((32, 10, 6), (42, 11, 5), (22, 15, 4), (48, 15, 4)):
        _ell(d, cx + sway + dx_shift, cy + bob, r, r * 0.7, leaf_l)
    for _ in range(28):
        lx = rng.randint(15, 57) + sway + dx_shift
        ly = rng.randint(3, 24) + bob
        if 0 <= lx < W and 0 <= ly < H:
            d.point([lx, ly], fill=leaf_s if rng.random() < 0.4 else leaf_deep)
    if phase == 2 or f in (20, 21):
        for k in range(5):
            x = 18 + k * 9 + sway + dx_shift
            d.polygon([(x - 2, 26 + bob), (x, 17 + bob - (k + f) % 3 * 2), (x + 2, 26 + bob)], fill=C("ffbe40"))

    d.ellipse([28 + sway + dx_shift, 32 + bob, 34 + sway + dx_shift, 38 + bob], fill=C("1a0e10"))
    d.ellipse([40 + sway + dx_shift, 32 + bob, 46 + sway + dx_shift, 38 + bob], fill=C("1a0e10"))
    d.rectangle([30 + sway + dx_shift, 34 + bob, 32 + sway + dx_shift, 36 + bob], fill=eye)
    d.rectangle([42 + sway + dx_shift, 34 + bob, 44 + sway + dx_shift, 36 + bob], fill=eye)
    d.point([31 + sway + dx_shift, 34 + bob], fill=C("ffffff"))
    d.point([43 + sway + dx_shift, 34 + bob], fill=C("ffffff"))
    if f in (20, 21) or phase == 2:
        d.line([(28 + sway + dx_shift, 30 + bob), (34 + sway + dx_shift, 32 + bob)], fill=bark_deep, width=2)
        d.line([(46 + sway + dx_shift, 30 + bob), (40 + sway + dx_shift, 32 + bob)], fill=bark_deep, width=2)
    mouth_h = 6 if f in (9, 10, 12, 18, 22, 23) else 3
    d.ellipse([31 + sway + dx_shift, 42 + bob, 43 + sway + dx_shift, 42 + bob + mouth_h + 2], fill=C("1a0e10"))
    for x in (33, 36, 39):
        d.point([x + sway + dx_shift, 43 + bob], fill=C("f0e4cc"))
    _ell(d, 24 + sway // 2 + dx_shift, 50 + bob, 3, 2, leaf_l)
    _ell(d, 51 + sway // 2 + dx_shift, 46 + bob, 2, 2, C("ea4848"))
    d.point([51 + sway // 2 + dx_shift, 45 + bob], fill=C("ffffff"))
    if f in (12, 19):
        d.line([(10, 68), (62, 68)], fill=rune, width=2)
    elif f in (22, 23):
        for k in range(4):
            a = k * 1.57 + f * 0.7
            _ell(d, 36 + math.cos(a) * 28, 36 + math.sin(a) * 18, 2.5, 2.5, rune)
    return polish(img)


# ------------------------------------------------------------------ Ngư Tinh Vương (84x60 x 24)
def fish_frame(f, phase):
    W, H = 84, 60
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    _, sc_d, sc, sc_l, sc_s = hue_ramp("3292b2" if phase == 1 else "663694")
    belly_d, _, belly, belly_l, _ = hue_ramp("ece0b2")
    _, fin_d, fin, fin_l, _ = hue_ramp("e45246" if phase == 1 else "f8346e")
    eye = C("fff49c") if phase == 1 else C("ff3842")
    t = (f / 8.0) * math.tau
    if f < 8:
        bob = round(-1.5 + math.cos(t) * 1.5)
        tail = round(math.sin(t) * 7)
        lunge_x = 0
    elif f in (8, 9, 10):
        bob, tail, lunge_x = 0, -4 - (f - 8), -(f - 7)
    elif f in (11, 12, 13, 14):
        prog = [2, 5, 3, 1][f - 11]
        bob, tail, lunge_x = -1 if f == 12 else 0, 4 if f <= 12 else 1, prog
    elif f in (15, 16):
        bob, tail, lunge_x = 0, 6 if f == 15 else -6, 6
    elif f in (17, 18, 19):
        bob = [2, -6, 2][f - 17]
        tail = [-4, 0, 4][f - 17]
        lunge_x = 2 if f == 18 else 0
    else:
        bob = -2 if f % 2 == 0 else 0
        tail = 3 if f % 2 == 0 else -3
        lunge_x = 0

    d.ellipse([10, 50, 74, 58], fill=C("286cb0", 155))
    d.ellipse([16 + (f % 4) * 2, 52, 68 - (f % 4), 57], fill=C("4ea2e0", 165))
    d.arc([12, 49, 72, 57], (f * 25) % 180, (f * 25 + 110) % 360, fill=C("c8f0ff"), width=1)
    y0 = 26 + bob
    d.polygon([(14 + lunge_x, y0), (max(0, 1 + lunge_x // 2), y0 - 13 + tail), (6, y0 + tail // 3), (max(0, 1 + lunge_x // 2), y0 + 13 + tail)], fill=fin)
    d.line([(14 + lunge_x, y0), (3, y0 - 10 + tail)], fill=fin_d)
    d.line([(14 + lunge_x, y0), (3, y0 + 10 + tail)], fill=fin_d)
    _ell(d, 40 + lunge_x, y0, 28, 16, sc)
    _ell(d, 42 + lunge_x, y0 + 7, 24, 8, belly)
    for row in range(3):
        for col in range(7):
            x = 22 + lunge_x + col * 6 + (row % 2) * 3
            y = y0 - 10 + row * 5
            d.arc([x - 3, y - 2, x + 3, y + 3], 0, 180, fill=sc_d)
            d.point([x, y - 1], fill=sc_s if row == 0 else sc_l)
    for i in range(6):
        x = 24 + lunge_x + i * 6
        hgt = 10 + (i % 2) * 4 + (4 if phase == 2 else 0)
        d.polygon([(x - 3, y0 - 13), (x - (2 if f in (11, 12, 15, 16) else 0), y0 - 13 - hgt), (x + 3, y0 - 13)], fill=fin)
        d.line([(x, y0 - 13), (x - (1 if f in (11, 12) else 0), y0 - 11 - hgt)], fill=fin_l)
    pw = round(math.sin(t) * 5) if f < 8 else (-6 if f in (8, 9, 10) else 4)
    py = round(math.cos(t) * 2) if f < 8 else (-3 if f in (8, 9, 10) else 1)
    d.polygon([(40 + lunge_x, y0 + 10), (33 + pw, y0 + 24 + py), (46 + pw, y0 + 22 + py)], fill=fin)
    d.polygon([(54 + lunge_x, y0 + 10), (50 - pw, y0 + 24 - py), (62 - pw, y0 + 20 - py)], fill=fin)
    jaw = 7 if f in (10, 11, 12, 22, 23) else 2
    hx = min(65, 60 + lunge_x)
    d.polygon([(hx, y0 - 10), (hx + 18, y0 - 2), (hx + 18, y0 + 1), (hx, y0 + 2)], fill=sc)
    d.polygon([(hx + 2, y0 + 2), (hx + 18, y0 + 1 + jaw), (hx + 2, y0 + 9)], fill=sc_d)
    d.polygon([(hx + 4, y0 + 1), (hx + 17, y0 + 1), (hx + 17, y0 + jaw)], fill=C("5a1a2a"))
    for x in range(hx + 5, hx + 17, 3):
        d.polygon([(x, y0), (x + 1, y0 + 2), (x + 2, y0)], fill=C("ffffff"))
    d.ellipse([hx + 4, y0 - 8, hx + 10, y0 - 3], fill=C("ffffff"))
    d.rectangle([hx + 7, y0 - 7, hx + 9, y0 - 4], fill=eye)
    d.point([hx + 8, y0 - 6], fill=C("1a0e10"))
    for k in range(2):
        pts = [(hx + 16, y0 + k * 2)] + [(min(83, hx + 18 + j * 2), y0 + k * 2 + int(math.sin(j + f * 0.6 + k) * 2) + j) for j in range(4)]
        d.line(pts, fill=C("f2be4c"))
    if f in (20, 21) or phase == 2:
        d.line([(hx + 3, y0 - 10), (hx + 10, y0 - 8)], fill=sc_d, width=2)
    if f in (22, 23):
        for k in range(5):
            off = 2 if f == 23 else 0
            d.ellipse([68 + k * 2, y0 - 14 - k * 3 - off, 71 + k * 2, y0 - 11 - k * 3 - off], fill=C("a8ecff"))
    return polish(img, texture=False)


def build():
    for fn, rel in ((fox_frame, "ho_tinh_vuong"), (tree_frame, "moc_tinh_vuong"), (fish_frame, "ngu_tinh_vuong")):
        for phase in (1, 2):
            frames = [fn(i, phase) for i in range(24)]
            _sheet(frames, "enemies/boss_%s%s.png" % (rel, "" if phase == 1 else "_2"))


if __name__ == "__main__":
    build()
