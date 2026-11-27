"""50 vũ khí từ thời xưa đến hiện đại. Mỗi vũ khí chĩa sang phải, có điểm cầm (grip).

Vẽ theo "họ" vũ khí (kiếm, giáo, rìu, cung, súng...) với vật liệu khác nhau,
rồi tự đổ bóng + thêm viền. 9 vũ khí đầu tiên giữ bản vẽ tay trong art_chars.py.
Kết quả: assets/sprites/weapons/<id>.png và assets/sprites/weapons/grips.json
"""
import json
import os
from px import hexc, grid, outline, save, auto_shade, OUT, Image, ImageDraw
import art_chars
import art_weapons_ext

M = {
    "wood": ("9a6234", "c08850", "5e3a20"),
    "dwood": ("6a4028", "8a5a38", "3e2416"),
    "bamboo": ("9db04c", "c8d878", "62702e"),
    "iron": ("8a92ac", "d8dce8", "565c74"),
    "steel": ("b8c0d4", "f4f6fc", "7a84a0"),
    "bronze": ("c4803e", "f2b878", "7a4622"),
    "gold": ("e8b04a", "fff0a0", "a86a2a"),
    "red": ("c43c3c", "f07a62", "7a1e2c"),
    "black": ("3a3448", "5e5870", "1e1a28"),
    "gun": ("4a5060", "7a8294", "2a2e3a"),
    "olive": ("6a7a3a", "8e9e56", "434e24"),
    "jade": ("4ad6a0", "a0ffd8", "1f8a6a"),
    "stone": ("8a8478", "b4ae9e", "5a5650"),
    "leather": ("7a4a2e", "a06a44", "4a2a18"),
    "cyan": ("4ae0ff", "d0faff", "1a8ac0"),
    "purple": ("a050e0", "e4b0ff", "5a2a90"),
    "skin": ("f5c7a1", "ffe4cc", "d4957a"),
    "white": ("e8e4f0", "ffffff", "a8a4b8"),
    "fire": ("ff8a2a", "fff0a0", "e8402a"),
    "rope": ("d8c08a", "f4e4b8", "9a8250"),
}
C = {k: tuple(hexc(c) for c in v) for k, v in M.items()}


class Pen:
    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.used = []
        self.after = []

    def _u(self, m):
        if m not in self.used:
            self.used.append(m)
        return C[m][0]

    def rect(self, x0, y0, x1, y1, m):
        self.d.rectangle([x0, y0, x1, y1], fill=self._u(m))

    def poly(self, pts, m):
        self.d.polygon(pts, fill=self._u(m))

    def line(self, pts, m, w=1):
        self.d.line(pts, fill=self._u(m), width=w)

    def ell(self, box, m):
        self.d.ellipse(box, fill=self._u(m))

    def dot(self, x, y, m, k=0):
        """Chi tiết vẽ sau khi đổ bóng (k: 0 gốc, 1 sáng, 2 tối)."""
        self.after.append((x, y, C[m][k]))

    def dline(self, pts, m, k=0):
        self.after.append(("line", pts, C[m][k]))

    def finish(self, grip, hand=True):
        for m in self.used:
            auto_shade(self.img, *C[m])
        self._polish()
        for a in self.after:
            if a[0] == "line":
                self.d.line(a[1], fill=a[2])
            else:
                self.img.putpixel((a[0], a[1]), a[2])
        if hand:
            gx, gy = grip
            sk = C["skin"]
            self.d.rectangle([gx - 1, gy - 1, gx + 1, gy + 1], fill=sk[0])
            self.d.line([gx - 1, gy - 1, gx + 1, gy - 1], fill=sk[1])
            self.d.line([gx - 1, gy + 1, gx + 1, gy + 1], fill=sk[2])
        return self.img, grip

    def _polish(self):
        """Chi tiết sắc nét: điểm lóe trên kim loại, vân gỗ."""
        px = self.img.load()
        w, h = self.img.size
        shiny = {C[m][1] for m in ("steel", "iron", "gold", "jade", "cyan", "bronze", "white", "purple")}
        woods = {C[m][0]: C[m][2] for m in ("wood", "dwood", "bamboo", "leather")}
        glints = 0
        for x in range(w):
            for y in range(h):
                c = px[x, y]
                if c in shiny and glints < 3 and (x + y) % 7 == 0:
                    px[x, y] = (255, 255, 255, 255)
                    glints += 1
                elif c in woods and (x * 3 + y * 5) % 9 == 0:
                    px[x, y] = woods[c]


# ---------------------------------------------------------------- Cận chiến
def staff(length, m, bands=(), tip=None, fire=False):
    p = Pen(length + 4, 9)
    p.rect(1, 3, length, 4, m)
    for b in bands:
        p.rect(b, 3, b, 4, "rope")
    for b in range(4, length, 5):
        p.dot(b, 3, m, 2)   # mấu tre
    if tip:
        p.rect(length - 3, 2, length + 1, 5, tip)
    if fire:
        for i, (dx, dy) in enumerate(((2, -2), (0, -3), (-2, -2), (1, -4))):
            p.dot(length + dx, 2 + dy, "fire", i % 2)
        p.dot(length + 2, 3, "fire", 1)
    return p.finish((7, 3))


def blade(handle, length, h, mb, mh, guard="gold", curve=0, tip_up=False, glow=None, edge=True, pommel=None):
    W = handle + length + 4
    p = Pen(W, h + 8)
    cy = (h + 8) // 2
    p.rect(1, cy - 1, handle, cy, mh)
    if pommel:
        p.rect(0, cy - 1, 1, cy, pommel)
    gx = handle + 1
    if guard:
        p.rect(gx, cy - 3, gx + 1, cy + 2, guard)
    x0 = gx + 2
    top = cy - h // 2 - 1
    bot = cy + (h - h // 2) - 1
    pts = [(x0, top), (x0 + length - 3, top - curve), (x0 + length, (top + bot) // 2 - curve), (x0 + length - 3, bot - curve // 2), (x0, bot)]
    if tip_up:
        pts = [(x0, top), (x0 + length - 1, top - curve - 1), (x0 + length - 4, bot - curve), (x0, bot)]
    p.poly(pts, mb)
    if edge:
        p.dline([(x0 + 1, top + (1 if h > 2 else 0)), (x0 + length - 4, top - curve + (1 if h > 2 else 0))], mb, 1)
    if glow:
        for x in range(x0 + 2, x0 + length - 3, 3):
            p.dot(x, cy - 1 - curve * (x - x0) // max(length, 1), glow, 1)
    return p.finish((handle // 2 + 1, cy))


def polearm(shaft, head, mh="wood", mm="steel", tassel=True):
    W = shaft + 16
    p = Pen(W, 15)
    cy = 7
    p.rect(1, cy, shaft, cy + 1, mh)
    x = shaft
    if head == "mac":     # mác: lưỡi to, sống thẳng, mũi nhọn
        p.poly([(x, cy - 2), (x + 10, cy - 1), (x + 14, cy + 1), (x + 9, cy + 3), (x, cy + 3)], mm)
    elif head == "kich":  # kích: mũi giáo + lưỡi cong 1 bên
        p.poly([(x + 2, cy - 1), (x + 13, cy), (x + 2, cy + 2)], mm)
        p.poly([(x + 3, cy - 1), (x + 6, cy - 6), (x + 8, cy - 5), (x + 6, cy - 1)], mm)
        p.poly([(x + 3, cy + 2), (x + 5, cy + 5), (x + 7, cy + 2)], mm)
    elif head == "lance":
        p.poly([(x, cy - 2), (x + 15, cy), (x + 15, cy + 1), (x, cy + 3)], mm)
    p.rect(x - 1, cy - 1, x, cy + 2, "gold")
    if tassel:
        p.rect(x - 3, cy + 2, x - 2, cy + 5, "red")
        p.dot(x - 3, cy + 6, "red", 2)
    return p.finish((8, cy))


def axe(shaft, size, mh="wood", mm="iron", stone=False, double=False):
    p = Pen(shaft + 6, size * 2 + 8)
    cy = size + 3
    p.rect(1, cy, shaft, cy + 1, mh)
    x = shaft - 4
    if stone:
        p.ell([x - 1, cy - size, x + 6, cy + size], "stone")
        p.line([(x - 2, cy - 1), (x + 2, cy + 2)], "rope")
        p.line([(x - 2, cy + 2), (x + 2, cy - 1)], "rope")
    else:
        p.poly([(x, cy - 1), (x + 3, cy - size), (x + 6, cy - size - 1), (x + 5, cy + size + 2), (x + 3, cy + size + 1), (x, cy + 2)], mm)
        if double:
            p.poly([(x, cy - 1), (x - 3, cy - size + 1), (x - 4, cy + size + 1), (x, cy + 2)], mm)
        p.dline([(x + 6, cy - size), (x + 5, cy + size + 1)], mm, 1)
    return p.finish((6, cy))


def mace(shaft, r, mh="wood", mm="bronze", spikes=True):
    p = Pen(shaft + r * 2 + 6, r * 2 + 8)
    cy = r + 4
    p.rect(1, cy, shaft, cy + 1, mh)
    cx = shaft + r
    if spikes:
        for dx, dy in ((0, -r - 2), (0, r + 2), (r + 2, 0), (r, -r), (r, r)):
            p.line([(cx, cy), (cx + dx, cy + dy)], "iron")
    p.ell([cx - r, cy - r, cx + r, cy + r], mm)
    p.rect(shaft - 1, cy - 1, shaft, cy + 2, "gold")
    return p.finish((6, cy))


def sickle():
    p = Pen(20, 16)
    p.rect(1, 9, 8, 10, "wood")
    p.d.arc([6, 1, 19, 14], 180, 360, fill=C["iron"][0], width=2)
    p._u("iron")
    p.d.arc([6, 1, 19, 14], 0, 40, fill=C["iron"][0], width=2)
    p.dline([(9, 4), (13, 2)], "iron", 1)
    return p.finish((4, 9))


def nunchaku():
    p = Pen(22, 12)
    p.rect(1, 5, 8, 6, "black")
    p.line([(9, 5), (11, 4), (13, 4)], "iron")
    p.rect(13, 3, 20, 4, "black")
    for x in (2, 7, 14, 19):
        p.dot(x, 5 if x < 10 else 3, "gold", 0)
    return p.finish((4, 5))


def fan():
    p = Pen(20, 20)
    for i in range(7):
        import math
        a = math.radians(-60 + i * 20)
        x1, y1 = 3 + math.cos(a) * 12, 10 + math.sin(a) * 12
        p.line([(3, 10), (x1, y1)], "iron")
    p.d.pieslice([-9, -2, 15, 22], -60, 60, fill=C["red"][0])
    p._u("red")
    for i in range(7):
        import math
        a = math.radians(-60 + i * 20)
        p.dline([(4 + math.cos(a) * 5, 10 + math.sin(a) * 5), (3 + math.cos(a) * 11, 10 + math.sin(a) * 11)], "gold", 0)
    p.dot(9, 10, "gold", 1)
    return p.finish((3, 10))


def twin_swords():
    a, ga = blade(4, 13, 2, "steel", "red")
    b, gb = blade(4, 13, 2, "steel", "red")
    img = Image.new("RGBA", (a.width + 2, a.height + 4), (0, 0, 0, 0))
    img.alpha_composite(b, (2, 0))
    img.alpha_composite(a, (0, 4))
    return img, (ga[0], ga[1] + 4)


def energy_sword():
    p = Pen(30, 9)
    p.rect(1, 3, 7, 5, "gun")
    p.rect(8, 2, 8, 6, "gold")
    p.rect(9, 3, 27, 5, "cyan")
    p.dot(28, 4, "cyan", 1)
    for x in range(10, 27):
        p.dot(x, 4, "white", 1)
    return p.finish((4, 4))


# ---------------------------------------------------------------- Bắn xa cổ
def slingshot():
    p = Pen(14, 16)
    p.rect(1, 7, 6, 8, "wood")
    p.line([(6, 7), (10, 2)], "wood", 2)
    p.line([(6, 8), (10, 13)], "wood", 2)
    p.dline([(10, 2), (8, 7)], "leather", 0)
    p.dline([(10, 13), (8, 8)], "leather", 0)
    p.dot(8, 7, "stone", 1)
    return p.finish((3, 7))


def long_bow(h, m, deco=None, glow=None):
    p = Pen(13, h + 4)
    cy = (h + 4) // 2
    p.d.arc([-h // 2 + 3, 1, 10, h + 1], -80, 80, fill=C[m][0], width=2)
    p._u(m)
    p.line([(4, 2), (4, h)], "white")
    p.rect(8, cy - 1, 10, cy + 1, "leather")
    if deco:
        p.dot(9, 3, deco, 1)
        p.dot(9, h - 1, deco, 1)
    if glow:
        for y in range(4, h, 4):
            p.dot(11, y, glow, 1)
    return p.finish((9, cy))


def darts():
    p = Pen(16, 12)
    for i, y in enumerate((3, 6, 9)):
        x = 3 + (i % 2) * 2
        p.line([(x, y), (x + 8, y)], "steel")
        p.dot(x + 9, y, "white", 1)
        p.dot(x, y - 1, "red", 0)
        p.dot(x, y + 1, "red", 2)
    return p.finish((4, 6))


def cannon(length, th, m="bronze", rings=2, wheels=False, mouth=True):
    p = Pen(length + 6, th + 10)
    cy = (th + 10) // 2
    p.rect(1, cy, 6, cy + 1, "wood")
    p.ell([5, cy - th // 2 - 1, 11, cy + th // 2 + 1], m)
    p.rect(8, cy - th // 2, length, cy + th // 2, m)
    if mouth:
        p.rect(length, cy - th // 2 - 1, length + 2, cy + th // 2 + 1, m)
    for i in range(rings):
        x = 12 + i * (length - 14) // max(1, rings)
        p.dline([(x, cy - th // 2), (x, cy + th // 2)], m, 2)
        p.dline([(x + 1, cy - th // 2), (x + 1, cy + th // 2)], m, 1)
    p.dot(9, cy - th // 2 - 1, "fire", 1)
    if wheels:
        p.ell([10, cy + th // 2 - 1, 16, cy + th // 2 + 5], "dwood")
    return p.finish((4, cy))


def drum_weapon():
    p = Pen(20, 18)
    p.ell([3, 1, 19, 7], "bronze")
    p.rect(3, 4, 19, 13, "bronze")
    p.ell([3, 10, 19, 16], "bronze")
    p.ell([3, 1, 19, 7], "gold")
    for x in range(5, 19, 3):
        p.dline([(x, 8), (x, 13)], "bronze", 2)
    p.dot(11, 4, "gold", 1)
    p.dline([(7, 4), (15, 4)], "gold", 2)
    return p.finish((2, 9), hand=False)


# ---------------------------------------------------------------- Súng (bộ phận ghép lại)
def gun(barrel=12, body=8, stock="none", mag="none", grip=True, scope=False, mb="gun", ms="wood",
        muzzle=None, bipod=False, pump=False, double=False, under=None, glow=None, tank=False, th=2):
    W = 4 + (8 if stock != "none" else 0) + body + barrel + 3
    p = Pen(W, 16)
    cy = 6
    x = 1
    gx = 6
    if stock == "rifle":
        p.poly([(x, cy + 3), (x + 1, cy), (x + 9, cy), (x + 9, cy + 2), (x + 3, cy + 4)], ms)
        x += 9
    elif stock == "pistol":
        x += 2
    elif stock == "wire":
        p.line([(x, cy + 3), (x + 8, cy + 1)], mb)
        p.line([(x, cy), (x, cy + 3)], mb)
        p.line([(x, cy), (x + 8, cy)], mb)
        x += 8
    elif stock == "musket":
        p.poly([(x, cy + 4), (x, cy), (x + 9, cy), (x + 9, cy + 2)], ms)
        x += 9
    # thân súng
    p.rect(x, cy - 1, x + body, cy + 2, mb)
    gx = x + 2
    if grip:
        p.poly([(x + 1, cy + 2), (x + 4, cy + 2), (x + 3, cy + 6), (x, cy + 6)], ms if stock in ("pistol", "none") and ms != "wood" or stock == "pistol" else mb)
        gx, gy = x + 2, cy + 4
    else:
        gy = cy + 1
    # nòng
    bx = x + body
    p.rect(bx, cy - 1 + (1 if th == 1 else 0), bx + barrel, cy, mb if not glow else mb)
    if double:
        p.rect(bx, cy + 1, bx + barrel, cy + 1, mb)
    if muzzle == "brake":
        p.rect(bx + barrel - 1, cy - 2, bx + barrel + 1, cy + 1, mb)
    elif muzzle == "bell":
        p.rect(bx + barrel, cy - 2, bx + barrel + 1, cy + 1, mb)
    elif muzzle == "tube":
        p.rect(bx - 6, cy - 2, bx + barrel - 4, cy + 1, mb)
        p.poly([(bx + barrel - 4, cy - 3), (bx + barrel, cy - 1), (bx + barrel + 2, cy - 1),
                (bx + barrel + 2, cy), (bx + barrel, cy), (bx + barrel - 4, cy + 2)], "iron")
        p.dot(bx + barrel + 2, cy - 1, "red", 0)
    # băng đạn
    if mag == "box":
        p.rect(x + body - 4, cy + 3, x + body - 2, cy + 7, mb)
    elif mag == "curve":
        p.poly([(x + body - 4, cy + 3), (x + body - 1, cy + 3), (x + body + 1, cy + 8), (x + body - 2, cy + 9)], mb)
    elif mag == "drum":
        p.ell([x + body - 6, cy + 2, x + body, cy + 8], mb)
    elif mag == "cylinder":
        p.rect(x + body - 4, cy - 2, x + body - 1, cy + 2, mb)
        p.dot(x + body - 3, cy, "black", 2)
    elif mag == "belt":
        for i in range(4):
            p.rect(x + body - 6 + i * 2, cy + 3 + i, x + body - 5 + i * 2, cy + 4 + i, "gold")
    if pump:
        p.rect(bx + 2, cy + 1, bx + 6, cy + 2, ms)
    if under == "wood":
        p.rect(bx, cy + 1, bx + barrel - 3, cy + 1, ms)
    if scope:
        p.rect(x + 1, cy - 4, x + body + 1, cy - 3, "black")
        p.dot(x + body + 1, cy - 4, "cyan", 1)
    if bipod:
        p.line([(bx + barrel - 3, cy + 1), (bx + barrel - 5, cy + 5)], mb)
        p.line([(bx + barrel - 3, cy + 1), (bx + barrel - 1, cy + 5)], mb)
    if tank:
        p.ell([x - 2, cy + 2, x + 5, cy + 9], "red")
        p.dot(x + 1, cy + 3, "white", 1)
    if glow:
        for i in range(bx, bx + barrel, 3):
            p.dot(i, cy - 1, glow, 1)
        p.dot(x + 3, cy, glow, 1)
        p.dot(x + 4, cy, glow, 0)
    return p.finish((gx, gy))


# ---------------------------------------------------------------- Vũ khí truyền kỳ Việt Nam
def axe_thach_sanh():
    p = Pen(26, 18)
    cy = 9
    p.rect(1, cy, 18, cy + 1, "dwood")
    for x in (4, 8, 12):
        p.dot(x, cy, "gold", 0)
    p.poly([(15, cy - 1), (18, cy - 7), (22, cy - 8), (24, cy - 4), (24, cy + 6), (22, cy + 9), (18, cy + 8), (15, cy + 3)], "steel")
    p.poly([(15, cy - 1), (12, cy - 4), (11, cy + 5), (15, cy + 3)], "gold")
    p.dline([(23, cy - 6), (23, cy + 7)], "steel", 1)
    p.dot(19, cy, "jade", 1)
    p.dot(20, cy, "jade", 0)
    p.dot(19, cy + 1, "jade", 2)
    return p.finish((5, cy))


def lute():
    """Đàn thần: đàn bầu/đàn tì bà gỗ, dây vàng, nốt nhạc."""
    p = Pen(24, 16)
    cy = 8
    p.ell([10, cy - 6, 22, cy + 6], "wood")
    p.rect(1, cy - 1, 12, cy, "dwood")
    p.rect(0, cy - 2, 2, cy + 1, "gold")
    p.ell([14, cy - 2, 18, cy + 2], "dwood")
    for i, y in enumerate((cy - 1, cy)):
        p.dline([(2, y), (20, y)], "gold", 1)
    p.dot(21, cy - 5, "red", 0)
    p.dot(20, cy + 5, "red", 0)
    return p.finish((6, cy))


def golden_bow():
    p = Pen(14, 26)
    cy = 13
    p.d.arc([-10, 1, 11, 25], -80, 80, fill=C["gold"][0], width=2)
    p._u("gold")
    p.line([(4, 2), (4, 24)], "white")
    p.rect(9, cy - 2, 11, cy + 2, "red")
    for y in (4, 22):
        p.dot(9, y, "jade", 1)
    p.dot(11, cy, "jade", 0)
    return p.finish((10, cy))


def son_tinh_staff():
    p = Pen(30, 14)
    cy = 7
    p.rect(1, cy, 22, cy + 1, "dwood")
    p.line([(21, cy), (24, cy - 4)], "dwood", 2)
    p.line([(21, cy + 1), (25, cy + 4)], "dwood", 2)
    p.ell([22, cy - 4, 29, cy + 4], "jade")
    p.dot(24, cy - 2, "white", 1)
    p.dot(25, cy - 2, "jade", 1)
    for x in (6, 12, 18):
        p.dot(x, cy + 1, "stone", 1)
        p.dot(x, cy, "stone", 0)
    p.dot(4, cy + 2, "bamboo", 0)
    p.dot(5, cy + 3, "bamboo", 1)
    return p.finish((7, cy))


def trident():
    p = Pen(32, 14)
    cy = 7
    p.rect(1, cy, 22, cy + 1, "cyan")
    p.rect(21, cy - 4, 22, cy + 5, "gold")
    for dy in (-4, 0, 4):
        p.rect(22, cy + dy, 27, cy + dy + 1 if dy == 0 else cy + dy, "steel")
        p.poly([(27, cy + dy - 1), (31, cy + dy), (27, cy + dy + (2 if dy == 0 else 1))], "steel")
    for x in range(3, 20, 4):
        p.dot(x, cy, "white", 1)
    return p.finish((7, cy))


def thunder_hammer():
    p = Pen(24, 20)
    cy = 10
    p.rect(1, cy, 13, cy + 1, "dwood")
    p.rect(13, cy - 6, 21, cy + 7, "bronze")
    p.rect(12, cy - 7, 22, cy - 6, "gold")
    p.rect(12, cy + 7, 22, cy + 8, "gold")
    p.dline([(17, cy - 4), (15, cy), (18, cy), (16, cy + 5)], "cyan", 1)
    p.dot(15, cy - 5, "white", 1)
    p.dot(22, cy - 9, "cyan", 1)
    p.dot(23, cy - 7, "cyan", 0)
    return p.finish((5, cy))


def hundred_bamboo():
    p = Pen(34, 9)
    cy = 4
    p.rect(1, cy, 32, cy + 1, "bamboo")
    for x in range(4, 32, 3):
        p.dline([(x, cy), (x, cy + 1)], "bamboo", 2)
    p.poly([(31, cy - 2), (33, cy), (31, cy + 3)], "bamboo")
    p.dot(6, cy - 1, "jade", 1)
    return p.finish((5, cy))


def hand_crossbow():
    p = Pen(16, 13)
    cy = 6
    p.rect(1, cy, 10, cy + 1, "wood")
    p.line([(9, cy - 4), (11, cy), (9, cy + 5)], "dwood", 2)
    p.dline([(9, cy - 4), (6, cy)], "white", 1)
    p.dline([(9, cy + 5), (6, cy + 1)], "white", 1)
    p.dline([(5, cy - 1), (14, cy - 1)], "iron", 0)
    p.dot(14, cy - 1, "white", 1)
    return p.finish((4, cy))


def co_loa_crossbow():
    """Nỏ Cổ Loa: thân đồng, cánh cung vàng, rùa thần & mũi tên đồng."""
    p = Pen(19, 15)
    cy = 7
    p.rect(1, cy, 13, cy + 1, "bronze")
    p.rect(4, cy - 1, 7, cy + 2, "gold")
    p.line([(10, cy - 5), (13, cy), (10, cy + 6)], "gold", 2)
    p.dline([(10, cy - 5), (7, cy)], "white", 1)
    p.dline([(10, cy + 6), (7, cy + 1)], "white", 1)
    p.dline([(6, cy - 1), (17, cy - 1)], "cyan", 1)
    p.dot(17, cy - 1, "white", 1)
    p.dot(6, cy, "jade", 1)
    return p.finish((5, cy))


def tan_vien_hammer():
    """Búa Tản Viên: cán gỗ lim, đầu búa đá núi vàng viền ngọc."""
    p = Pen(23, 17)
    cy = 8
    p.rect(1, cy, 13, cy + 1, "dwood")
    p.rect(12, cy - 5, 19, cy + 6, "stone")
    p.rect(12, cy - 6, 19, cy - 5, "bronze")
    p.rect(12, cy + 6, 19, cy + 7, "bronze")
    p.dot(15, cy, "gold", 1)
    p.dot(16, cy, "jade", 1)
    p.dot(19, cy - 4, "stone", 1)
    return p.finish((5, cy))


# ---------------------------------------------------------------- Danh sách
PROC = {
    # vũ khí cơ bản của từng tướng
    "kiem_dong": lambda: blade(4, 11, 2, "bronze", "dwood", guard="bronze"),
    "doan_dao": lambda: blade(4, 12, 3, "iron", "wood", guard="iron", curve=1),
    "giao_tre": lambda: polearm(16, "lance", mh="bamboo", mm="bamboo", tassel=False),
    "no_tay": hand_crossbow,
    "guom_lenh": lambda: blade(4, 13, 2, "steel", "red", guard="gold", pommel="gold"),
    "con_lam_son": lambda: staff(22, "wood", bands=(5, 17)),
    "ong_lua": lambda: gun(barrel=9, body=4, stock="none", mb="bamboo", ms="wood", muzzle="bell", grip=False),
    "dao_rua": lambda: blade(4, 11, 4, "iron", "wood", guard=None, tip_up=True),
    "hoa_mai_yen_the": lambda: gun(barrel=14, body=5, stock="musket", ms="dwood", mb="iron", grip=False, th=1),
    "sung_truong_bo_binh": lambda: gun(barrel=13, body=7, stock="rifle", under="wood", mb="gun", th=1, grip=False),
    "no_co_loa": co_loa_crossbow,
    "long_uyen_kiem": lambda: blade(5, 15, 3, "cyan", "gold", guard="gold", glow="white", pommel="jade"),
    "bua_tan_vien": tan_vien_hammer,
    # cận chiến
    "gay_tre": lambda: staff(24, "bamboo", bands=(6, 18)),
    "dao_gam": lambda: blade(4, 8, 2, "iron", "leather", guard="iron"),
    "riu_da": lambda: axe(16, 4, stone=True),
    "liem": sickle,
    "ma_tau": lambda: blade(5, 14, 3, "iron", "wood", guard=None, curve=1),
    "mac": lambda: polearm(18, "mac"),
    "chuy_dong": lambda: mace(14, 4),
    "con_nhi_khuc": nunchaku,
    "kich": lambda: polearm(18, "kich"),
    "truong_thuong": lambda: polearm(24, "lance", mh="dwood"),
    "riu_chien": lambda: axe(18, 5, mh="dwood", mm="steel", double=True),
    "song_kiem": twin_swords,
    "quat_thep": fan,
    "kiem_rong_tien": lambda: blade(5, 17, 3, "jade", "red", guard="gold", glow="white", pommel="gold"),
    "thuan_thien": lambda: blade(6, 19, 3, "steel", "gold", guard="jade", glow="gold", pommel="jade"),
    "roi_sat_giong": lambda: staff(26, "black", bands=(7,), tip="iron", fire=True),
    "kiem_tia_sang": energy_sword,
    # bắn xa cổ
    "na": slingshot,
    "phi_tieu": darts,
    "cung_dai": lambda: long_bow(22, "dwood"),
    "cung_rong": lambda: long_bow(22, "red", deco="gold", glow="fire"),
    "phao_dong": lambda: cannon(18, 5, "bronze", rings=3),
    "dai_bac_than_cong": lambda: cannon(24, 7, "black", rings=3, wheels=True),
    "trong_dong": drum_weapon,
    "hoa_mai": lambda: gun(barrel=16, body=6, stock="musket", ms="wood", mb="iron", grip=False, th=1),
    # cận đại & hiện đại
    "sung_kip": lambda: gun(barrel=7, body=5, stock="pistol", ms="wood", mb="bronze", muzzle="bell", th=1),
    "sung_ngan": lambda: gun(barrel=4, body=7, stock="pistol", ms="black", mb="gun"),
    "sung_luc": lambda: gun(barrel=6, body=7, stock="pistol", ms="wood", mb="iron", mag="cylinder", th=1),
    "sung_san": lambda: gun(barrel=12, body=6, stock="rifle", pump=True, mb="gun"),
    "sung_hai_nong": lambda: gun(barrel=12, body=5, stock="rifle", double=True, mb="iron", grip=False),
    "sung_truong": lambda: gun(barrel=14, body=7, stock="rifle", under="wood", mb="gun", th=1, grip=False),
    "tieu_lien": lambda: gun(barrel=6, body=9, stock="wire", mag="box", mb="black"),
    "sung_truong_tan_cong": lambda: gun(barrel=9, body=9, stock="rifle", mag="curve", mb="gun", ms="wood", muzzle="brake"),
    "sung_ban_tia": lambda: gun(barrel=16, body=8, stock="rifle", scope=True, bipod=True, mb="olive", ms="olive", muzzle="brake", th=1),
    "sung_may": lambda: gun(barrel=13, body=11, stock="rifle", mag="belt", bipod=True, mb="black", ms="black", muzzle="brake"),
    "sung_phong_luu": lambda: gun(barrel=7, body=8, stock="rifle", mag="drum", mb="olive", ms="olive", th=3, muzzle="bell"),
    "sung_phong_ten_lua": lambda: gun(barrel=14, body=6, stock="none", muzzle="tube", mb="olive", ms="dwood"),
    "sung_phun_lua": lambda: gun(barrel=10, body=8, stock="none", tank=True, mb="gun", muzzle="bell"),
    "sung_plasma": lambda: gun(barrel=8, body=10, stock="pistol", mb="purple", ms="black", glow="purple", muzzle="brake"),
    "sung_laze": lambda: gun(barrel=12, body=10, stock="rifle", mb="white", ms="gun", glow="cyan", scope=True),
    "riu_thach_sanh": axe_thach_sanh,
    "dan_than": lute,
    "cung_vang": golden_bow,
    "gay_son_tinh": son_tinh_staff,
    "dinh_ba_thuy_tinh": trident,
    "bua_thien_loi": thunder_hammer,
    "tre_tram_dot": hundred_bamboo,
    "sung_dien_tu": lambda: gun(barrel=16, body=10, stock="rifle", mb="gun", ms="gun", glow="cyan", double=True, muzzle="brake"),
}


def tiers():
    import re
    src = open(os.path.join(os.path.dirname(__file__), "..", "..", "scripts", "data", "weapons.gd"), encoding="utf-8").read()
    return {m[0]: int(m[1]) for m in re.findall(r'"([a-z_]+)": \{"name": "[^"]+", "tier": (\d)', src)}


def boss_motifs():
    import re
    src = open(os.path.join(os.path.dirname(__file__), "..", "..", "scripts", "data", "weapons.gd"), encoding="utf-8").read()
    return set(re.findall(r'"([a-z_]+)": \{[^\n]*"boss_motif": true', src))


TIER_EDGE = {4: hexc("4a1a6a"), 5: hexc("7a3a00"), "red": hexc("7a101c")}
TIER_GLOW = {4: hexc("c070ff", 110), 5: hexc("ffc040", 140), "red": hexc("ff384c", 165)}
BASIC_WEAPONS = (
    "kiem_dong", "doan_dao", "giao_tre", "no_tay", "guom_lenh",
    "con_lam_son", "ong_lua", "dao_rua", "hoa_mai_yen_the", "sung_truong_bo_binh",
    "gay_tre", "no_co_loa", "long_uyen_kiem", "bua_tan_vien",
)


def finalize(img, tier, is_boss=False):
    """Viền đen cho cấp 1-3; cấp 4 viền tím, cấp 5 viền vàng phát sáng; Thần binh Trùm viền đỏ rực."""
    pad = Image.new("RGBA", (img.width + 4, img.height + 4), (0, 0, 0, 0))
    pad.alpha_composite(img, (2, 2))
    if is_boss:
        out = outline(pad, TIER_EDGE["red"])
        return outline(out, TIER_GLOW["red"]), 2
    if tier >= 4:
        out = outline(pad, TIER_EDGE[tier])
        return outline(out, TIER_GLOW[tier]), 2
    return outline(pad), 2


def finalize_rank(img, rank):
    """Biến thể vũ khí khởi đầu: bậc 3 viền xanh lam, bậc 5 viền vàng lấp lánh (giữ cùng kích thước và grip)."""
    pad = Image.new("RGBA", (img.width + 4, img.height + 4), (0, 0, 0, 0))
    pad.alpha_composite(img, (2, 2))
    if rank == 3:
        out = outline(pad, hexc("1b4b8c"))
        return outline(out, hexc("4aa8ff", 150))
    out = outline(pad, hexc("7a3a00"))
    res = outline(out, hexc("ffe055", 175))
    px = res.load()
    pts = []
    for x in range(1, res.width - 1):
        for y in range(1, res.height - 1):
            if px[x, y][3] >= 220 and (x * 5 + y * 3) % 13 == 0:
                pts.append((x, y))
    for i, (sx, sy) in enumerate(pts[:4]):
        px[sx, sy] = (255, 255, 225, 255)
        if i < 2 and sx + 1 < res.width and px[sx + 1, sy][3] == 0:
            px[sx + 1, sy] = (255, 240, 140, 220)
    return res


def build():
    tier = tiers()
    boss_set = boss_motifs()
    grips = {}
    raw_imgs = {}
    for wid, (grip, rows) in art_chars.WEAPONS.items():
        w = max(len(r) for r in rows)
        raw = grid(rows, art_chars.W, w)
        raw_imgs[wid] = raw
        img, off = finalize(raw, tier.get(wid, 1), wid in boss_set)
        save(img, f"weapons/{wid}.png")
        grips[wid] = (grip[0] + off, grip[1] + off)
    for wid, fn in PROC.items():
        res = fn()
        raw, g = res
        raw_imgs[wid] = raw
        img, off = finalize(raw, tier.get(wid, 1), wid in boss_set)
        save(img, f"weapons/{wid}.png")
        grips[wid] = (g[0] + off, g[1] + off)
    for wid, fn in art_weapons_ext.PROC_EXT.items():
        res = fn()
        raw, g = res
        raw_imgs[wid] = raw
        img, off = finalize(raw, tier.get(wid, 1), wid in boss_set)
        save(img, f"weapons/{wid}.png")
        grips[wid] = (g[0] + off, g[1] + off)
    art_weapons_ext.build_projectiles_ext()
    for wid in BASIC_WEAPONS:
        if wid in raw_imgs:
            save(finalize_rank(raw_imgs[wid], 3), f"weapons/{wid}_b3.png")
            save(finalize_rank(raw_imgs[wid], 5), f"weapons/{wid}_b5.png")
    path = os.path.join(OUT, "weapons", "grips.json")
    with open(path, "w") as f:
        json.dump({k: list(v) for k, v in sorted(grips.items())}, f, indent=1)
    return grips


if __name__ == "__main__":
    g = build()
    print(len(g), "vũ khí")
