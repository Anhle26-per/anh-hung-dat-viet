"""133 vũ khí mới (phép thuật, ảo ma, nguyên tố, viễn tưởng) + 10 dải hình đạn mới.

Được gọi từ art_weapons.py để tạo đủ 200 vũ khí trong assets/sprites/weapons/ và grips.json,
cùng 10 dải đạn trong assets/sprites/fx/.
"""
import math
from px import hexc, outline, sheet, save, canvas, auto_shade, Image, ImageDraw

WHITE = (255, 255, 255, 255)

PAL = {
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
    "ice": ("78d4ff", "e4faff", "2a7ec0"),
    "purple": ("a050e0", "e4b0ff", "5a2a90"),
    "void": ("4a2470", "9860d0", "1c0e32"),
    "poison": ("68cc3a", "b8ff78", "2e7020"),
    "soul": ("3adcb0", "b8ffe8", "187464"),
    "pink": ("e85aa8", "ffb8e4", "902868"),
    "skin": ("f5c7a1", "ffe4cc", "d4957a"),
    "white": ("e8e4f0", "ffffff", "a8a4b8"),
    "fire": ("ff8a2a", "fff0a0", "e8402a"),
    "rope": ("d8c08a", "f4e4b8", "9a8250"),
    "paper": ("f4dca0", "fff4d0", "b89650"),
}
C = {k: tuple(hexc(c) for c in v) for k, v in PAL.items()}


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
        if 0 <= x < self.img.width and 0 <= y < self.img.height:
            self.after.append((int(x), int(y), C[m][k]))

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
                x, y, col = a
                if 0 <= x < self.img.width and 0 <= y < self.img.height:
                    self.img.putpixel((x, y), col)
        if hand:
            gx, gy = grip
            sk = C["skin"]
            self.d.rectangle([gx - 1, gy - 1, gx + 1, gy + 1], fill=sk[0])
            self.d.line([gx - 1, gy - 1, gx + 1, gy - 1], fill=sk[1])
            self.d.line([gx - 1, gy + 1, gx + 1, gy + 1], fill=sk[2])
        return self.img, grip

    def _polish(self):
        px = self.img.load()
        w, h = self.img.size
        shiny = {C[m][1] for m in ("steel", "iron", "gold", "jade", "cyan", "ice", "bronze", "white", "purple", "soul")}
        woods = {C[m][0]: C[m][2] for m in ("wood", "dwood", "bamboo", "leather")}
        glints = 0
        for x in range(w):
            for y in range(h):
                c = px[x, y]
                if c in shiny and glints < 3 and (x + y) % 7 == 0:
                    px[x, y] = WHITE
                    glints += 1
                elif c in woods and (x * 3 + y * 5) % 9 == 0:
                    px[x, y] = woods[c]


# ---------------------------------------------------------------- Mẫu vũ khí phép thuật & kỳ dị
def magic_wand(length, shaft_m, gem_m, tip_shape="orb", ring=None, sparks=None):
    W = length + 10
    p = Pen(W, 13)
    cy = 6
    p.rect(1, cy, length, cy + 1, shaft_m)
    p.rect(0, cy - 1, 2, cy + 2, "gold" if shaft_m != "gold" else "purple")
    gx = length
    if ring:
        p.rect(gx - 2, cy - 2, gx, cy + 3, ring)
    if tip_shape == "orb":
        p.ell([gx, cy - 3, gx + 6, cy + 3], gem_m)
        p.dot(gx + 2, cy - 1, "white", 1)
    elif tip_shape == "crystal":
        p.poly([(gx, cy), (gx + 4, cy - 4), (gx + 8, cy), (gx + 4, cy + 4)], gem_m)
        p.dot(gx + 3, cy - 1, "white", 1)
    elif tip_shape == "crescent":
        p.ell([gx, cy - 4, gx + 7, cy + 4], gem_m)
        p.ell([gx + 3, cy - 2, gx + 8, cy + 2], "black")
        p.dot(gx + 2, cy - 2, "white", 1)
    elif tip_shape == "star":
        p.rect(gx + 2, cy - 4, gx + 4, cy + 4, gem_m)
        p.rect(gx, cy - 1, gx + 6, cy + 1, gem_m)
        p.dot(gx + 3, cy, "white", 1)
    elif tip_shape == "brush":
        p.rect(gx - 1, cy - 1, gx + 1, cy + 2, "gold")
        p.poly([(gx + 1, cy - 2), (gx + 7, cy), (gx + 1, cy + 3)], gem_m)
        p.dot(gx + 6, cy, "white", 1)
    elif tip_shape == "trident_tip":
        p.rect(gx, cy - 3, gx + 1, cy + 4, "gold")
        p.line([(gx + 1, cy - 3), (gx + 6, cy - 3)], gem_m)
        p.line([(gx + 1, cy), (gx + 7, cy)], gem_m)
        p.line([(gx + 1, cy + 3), (gx + 6, cy + 3)], gem_m)
        p.dot(gx + 4, cy, "white", 1)
    if sparks:
        p.dot(gx + 7, cy - 4, sparks, 1)
        p.dot(gx + 8, cy + 3, sparks, 0)
    return p.finish((5, cy))


def magic_staff(length, shaft_m, head_m, style="cage", accent="gold"):
    W = length + 14
    p = Pen(W, 17)
    cy = 8
    p.rect(1, cy, length, cy + 1, shaft_m)
    p.rect(length - 2, cy - 2, length, cy + 3, accent)
    x = length
    if style == "cage":
        p.ell([x, cy - 5, x + 10, cy + 5], accent)
        p.ell([x + 2, cy - 3, x + 8, cy + 3], head_m)
        p.dot(x + 4, cy - 1, "white", 1)
    elif style == "blackhole":
        p.ell([x + 1, cy - 6, x + 12, cy + 6], head_m)
        p.ell([x + 4, cy - 3, x + 9, cy + 3], "black")
        p.dot(x + 2, cy - 4, "cyan", 1)
        p.dot(x + 10, cy + 4, "pink", 1)
    elif style == "flame_halo":
        p.poly([(x, cy - 2), (x + 5, cy - 6), (x + 11, cy), (x + 5, cy + 6), (x, cy + 2)], accent)
        p.ell([x + 2, cy - 3, x + 8, cy + 3], head_m)
        p.dot(x + 4, cy - 1, "white", 1)
    elif style == "crown":
        p.poly([(x, cy - 3), (x + 5, cy - 6), (x + 10, cy - 2), (x + 10, cy + 2), (x + 5, cy + 6), (x, cy + 3)], accent)
        p.ell([x + 3, cy - 3, x + 8, cy + 3], head_m)
        p.dot(x + 9, cy - 4, "cyan", 1)
        p.dot(x + 9, cy + 4, "cyan", 1)
    elif style == "yin_yang":
        p.ell([x + 1, cy - 5, x + 11, cy + 5], "white")
        p.d.pieslice([x + 1, cy - 5, x + 11, cy + 5], 90, 270, fill=C["black"][0])
        p.dot(x + 6, cy - 2, "black", 0)
        p.dot(x + 6, cy + 2, "white", 1)
    elif style == "rock":
        p.poly([(x, cy - 3), (x + 4, cy - 6), (x + 9, cy - 3), (x + 11, cy + 1), (x + 6, cy + 6), (x, cy + 3)], "stone")
        p.ell([x + 3, cy - 2, x + 7, cy + 2], head_m)
        p.dot(x + 4, cy - 1, "white", 1)
    elif style == "bolt":
        p.poly([(x, cy - 4), (x + 7, cy - 4), (x + 4, cy), (x + 11, cy), (x + 2, cy + 6), (x + 5, cy + 1), (x, cy + 1)], head_m)
        p.dot(x + 9, cy, "white", 1)
    return p.finish((7, cy))


def grimoire(cover_m, trim_m, emblem_m, page_m="paper"):
    p = Pen(17, 17)
    p.rect(2, 2, 13, 14, cover_m)
    p.rect(12, 3, 14, 13, page_m)
    p.rect(2, 2, 4, 14, trim_m)
    p.rect(2, 2, 13, 3, trim_m)
    p.rect(2, 13, 13, 14, trim_m)
    p.ell([6, 6, 10, 10], emblem_m)
    p.dot(8, 8, "white", 1)
    return p.finish((4, 8))


def talisman_stack(body_m="paper", ink_m="red", aura_m=None):
    p = Pen(18, 13)
    p.rect(2, 2, 13, 10, body_m)
    p.rect(4, 3, 15, 9, body_m)
    p.dline([(7, 4), (13, 4)], ink_m, 0)
    p.dline([(10, 4), (10, 8)], ink_m, 0)
    p.dline([(8, 6), (12, 6)], ink_m, 0)
    p.dline([(8, 8), (12, 8)], ink_m, 0)
    if aura_m:
        p.dot(16, 4, aura_m, 1)
        p.dot(16, 8, aura_m, 1)
    return p.finish((4, 6))


def chakram_ring(ring_m, edge_m, gem_m=None, teeth=True):
    p = Pen(18, 18)
    p.ell([2, 2, 15, 15], ring_m)
    p.ell([5, 5, 12, 12], "black")
    p.d.ellipse([6, 6, 11, 11], fill=(0, 0, 0, 0))
    if teeth:
        for dx, dy in ((8, 0), (8, 17), (0, 8), (17, 8), (2, 2), (15, 2), (2, 15), (15, 15)):
            p.dot(dx, dy, edge_m, 1)
    if gem_m:
        p.dot(8, 3, gem_m, 1)
        p.dot(8, 14, gem_m, 1)
        p.dot(14, 8, gem_m, 1)
    return p.finish((3, 9))


def card_fan(accent_m="red"):
    p = Pen(18, 16)
    p.poly([(3, 11), (8, 2), (13, 4), (8, 13)], "white")
    p.rect(7, 3, 15, 12, "paper")
    p.dline([(9, 5), (13, 5)], accent_m, 0)
    p.dline([(9, 7), (13, 7)], "jade", 0)
    p.dline([(9, 9), (13, 9)], "gold", 0)
    p.dot(11, 6, "red", 0)
    return p.finish((5, 9))


def lantern(body_m="soul", frame_m="gold"):
    p = Pen(18, 18)
    p.rect(1, 5, 8, 6, "dwood")
    p.line([(8, 5), (12, 2)], "gold")
    p.rect(10, 2, 14, 3, frame_m)
    p.ell([8, 4, 16, 13], body_m)
    p.rect(10, 13, 14, 14, frame_m)
    p.dline([(12, 5), (12, 12)], "white", 1)
    p.dot(12, 15, "red", 0)
    p.dot(12, 16, "red", 2)
    return p.finish((4, 5))


def bell_weapon(bell_m="gold", glow_m=None):
    p = Pen(18, 16)
    p.rect(1, 7, 7, 8, "dwood")
    p.poly([(7, 4), (13, 3), (16, 12), (7, 11)], bell_m)
    p.rect(15, 3, 16, 12, "bronze" if bell_m == "gold" else "gold")
    p.dot(16, 7, "red", 0)
    if glow_m:
        p.dot(17, 4, glow_m, 1)
        p.dot(17, 11, glow_m, 1)
    return p.finish((4, 7))


def flute_weapon(body_m="bamboo", aura_m="jade"):
    p = Pen(24, 11)
    p.rect(1, 4, 22, 6, body_m)
    for x in (6, 9, 12, 15, 18):
        p.dot(x, 5, "black", 2)
    p.dot(21, 7, "red", 0)
    p.dot(22, 8, "red", 2)
    p.dot(22, 2, aura_m, 1)
    return p.finish((5, 5))


def mirror_weapon():
    p = Pen(18, 18)
    p.rect(1, 8, 6, 9, "dwood")
    p.poly([(7, 3), (12, 1), (16, 5), (16, 12), (12, 16), (7, 14), (5, 9)], "gold")
    p.ell([7, 4, 14, 13], "cyan")
    p.ell([9, 6, 12, 11], "white")
    p.dot(10, 8, "gold", 1)
    return p.finish((4, 8))


def kaleidoscope_weapon():
    p = Pen(22, 12)
    p.rect(1, 4, 18, 7, "purple")
    p.rect(6, 4, 8, 7, "gold")
    p.rect(16, 3, 19, 8, "cyan")
    p.dot(20, 4, "pink", 1)
    p.dot(20, 7, "gold", 1)
    return p.finish((5, 6))


def dice_weapon(m="white", spot_m="red"):
    p = Pen(16, 15)
    p.rect(4, 3, 12, 11, m)
    p.dot(6, 5, spot_m, 0)
    p.dot(10, 5, spot_m, 0)
    p.dot(8, 7, spot_m, 0)
    p.dot(6, 9, spot_m, 0)
    p.dot(10, 9, spot_m, 0)
    p.dot(13, 2, "fire", 1)
    return p.finish((5, 7))


def gourd_weapon():
    p = Pen(16, 16)
    p.ell([5, 2, 11, 7], "wood")
    p.ell([4, 6, 13, 14], "wood")
    p.rect(7, 1, 9, 2, "red")
    p.dot(10, 9, "poison", 1)
    p.dot(11, 10, "poison", 0)
    return p.finish((5, 9))


def clog_weapon():
    p = Pen(16, 12)
    p.poly([(2, 5), (13, 4), (14, 8), (2, 8)], "wood")
    p.rect(4, 8, 6, 10, "dwood")
    p.rect(10, 8, 12, 10, "dwood")
    p.poly([(6, 3), (11, 3), (12, 5), (6, 5)], "red")
    return p.finish((4, 6))


def straw_hat():
    p = Pen(18, 12)
    p.poly([(1, 8), (9, 2), (16, 8)], "paper")
    p.dline([(3, 8), (14, 8)], "wood", 2)
    p.dot(9, 2, "red", 0)
    return p.finish((4, 7))


def palm_fan():
    p = Pen(20, 16)
    p.rect(1, 7, 7, 8, "bamboo")
    p.ell([6, 2, 18, 13], "paper")
    p.dline([(7, 7), (16, 5)], "wood", 0)
    p.dline([(7, 8), (16, 10)], "wood", 0)
    return p.finish((4, 7))


def bamboo_rotor():
    p = Pen(20, 14)
    p.rect(1, 6, 10, 7, "bamboo")
    p.rect(9, 2, 11, 11, "gold")
    p.poly([(11, 3), (18, 1), (18, 4), (11, 5)], "bamboo")
    p.poly([(11, 8), (18, 9), (18, 12), (11, 10)], "bamboo")
    return p.finish((5, 6))


def firework_cannon(m="red", trim="gold", tubes=1):
    W = 24
    p = Pen(W, 15)
    p.rect(1, 6, 7, 8, "dwood")
    if tubes == 1:
        p.rect(7, 4, 21, 10, m)
        p.rect(11, 4, 12, 10, trim)
        p.rect(19, 3, 22, 11, trim)
        p.dot(22, 7, "fire", 1)
    else:
        for y in (3, 7, 11):
            p.rect(7, y - 1, 21, y + 1, m)
            p.dot(22, y, "fire", 1)
        p.rect(10, 2, 12, 12, trim)
    return p.finish((5, 7))


def scythe(shaft, blade_m, shaft_m="dwood", glow_m=None):
    W = shaft + 12
    p = Pen(W, 20)
    cy = 10
    p.rect(1, cy, shaft, cy + 1, shaft_m)
    p.rect(shaft - 1, cy - 2, shaft + 1, cy + 2, "gold")
    p.poly([(shaft, cy - 2), (shaft + 8, cy - 8), (shaft + 10, cy - 5), (shaft + 4, cy + 2), (shaft + 2, cy + 8), (shaft - 1, cy + 7), (shaft, cy + 2)], blade_m)
    p.dline([(shaft + 7, cy - 7), (shaft + 2, cy + 7)], blade_m, 1)
    if glow_m:
        p.dot(shaft + 6, cy - 4, glow_m, 1)
        p.dot(shaft + 2, cy + 5, glow_m, 1)
    return p.finish((7, cy))


def sword(handle, length, h, mb, mh, guard="gold", curve=0, glow=None, twin=False, double_fx=None):
    W = handle + length + 4
    p = Pen(W, h + 10)
    cy = (h + 10) // 2
    p.rect(1, cy - 1, handle, cy, mh)
    p.rect(0, cy - 1, 1, cy, guard)
    gx = handle + 1
    p.rect(gx, cy - 3, gx + 1, cy + 2, guard)
    x0 = gx + 2
    top = cy - h // 2 - 1
    bot = cy + (h - h // 2) - 1
    pts = [(x0, top), (x0 + length - 3, top - curve), (x0 + length, (top + bot) // 2 - curve), (x0 + length - 3, bot - curve // 2), (x0, bot)]
    p.poly(pts, mb)
    p.dline([(x0 + 1, top + 1), (x0 + length - 4, top - curve + 1)], mb, 1)
    if glow:
        for x in range(x0 + 2, x0 + length - 2, 3):
            p.dot(x, cy - 1, glow, 1)
    if twin:
        img1, g1 = p.finish((handle // 2 + 1, cy))
        p2 = Pen(W, h + 10)
        p2.rect(1, cy - 1, handle, cy, mh)
        p2.rect(gx, cy - 3, gx + 1, cy + 2, guard)
        p2.poly(pts, double_fx or mb)
        img2, _ = p2.finish((handle // 2 + 1, cy))
        out = Image.new("RGBA", (img1.width + 2, img1.height + 4), (0, 0, 0, 0))
        out.alpha_composite(img2, (2, 0))
        out.alpha_composite(img1, (0, 4))
        return out, (g1[0], g1[1] + 4)
    return p.finish((handle // 2 + 1, cy))


def spear(shaft, mh, mm, glow=None, wings=False):
    W = shaft + 16
    p = Pen(W, 15)
    cy = 7
    p.rect(1, cy, shaft, cy + 1, mh)
    x = shaft
    p.rect(x - 1, cy - 2, x, cy + 3, "gold")
    p.poly([(x, cy - 2), (x + 14, cy), (x + 14, cy + 1), (x, cy + 3)], mm)
    if wings:
        p.poly([(x + 1, cy - 2), (x + 5, cy - 6), (x + 7, cy - 2)], mm)
        p.poly([(x + 1, cy + 3), (x + 5, cy + 7), (x + 7, cy + 3)], mm)
    if glow:
        p.dot(x + 7, cy, glow, 1)
        p.dot(x + 11, cy, "white", 1)
    return p.finish((7, cy))


def hammer(shaft, size, mh="dwood", mm="iron", trim="gold", glow=None):
    p = Pen(shaft + size * 2 + 5, size * 2 + 8)
    cy = size + 4
    p.rect(1, cy, shaft, cy + 1, mh)
    p.rect(shaft, cy - size, shaft + size + 2, cy + size + 1, mm)
    p.rect(shaft - 1, cy - size - 1, shaft + size + 3, cy - size, trim)
    p.rect(shaft - 1, cy + size + 1, shaft + size + 3, cy + size + 2, trim)
    if glow:
        p.dot(shaft + size // 2 + 1, cy, glow, 1)
        p.dot(shaft + size + 3, cy - size - 2, glow, 1)
    return p.finish((5, cy))


def chainsaw():
    p = Pen(26, 13)
    p.rect(1, 5, 9, 8, "red")
    p.rect(2, 3, 6, 4, "black")
    p.rect(9, 4, 24, 8, "steel")
    for x in range(10, 24, 2):
        p.dot(x, 3, "iron", 2)
        p.dot(x, 9, "iron", 2)
    return p.finish((4, 6))


def mag_fan(body_m="jade", rib_m="gold", glow_m=None):
    p = Pen(20, 20)
    for i in range(7):
        a = math.radians(-60 + i * 20)
        p.line([(3, 10), (3 + math.cos(a) * 12, 10 + math.sin(a) * 12)], rib_m)
    p.d.pieslice([-9, -2, 15, 22], -60, 60, fill=C[body_m][0])
    p._u(body_m)
    if glow_m:
        p.dot(14, 7, glow_m, 1)
        p.dot(14, 13, glow_m, 1)
    return p.finish((3, 10))


def bow(h, m, deco=None, glow=None, mech=False):
    p = Pen(16, h + 4)
    cy = (h + 4) // 2
    if mech:
        p.rect(1, cy, 12, cy + 1, "gun")
        p.line([(10, cy - h // 2 + 1), (12, cy), (10, cy + h // 2 - 1)], m, 2)
        p.line([(10, cy - h // 2 + 1), (6, cy)], "cyan", 1)
        p.line([(10, cy + h // 2 - 1), (6, cy + 1)], "cyan", 1)
        if glow:
            p.dot(14, cy, glow, 1)
        return p.finish((5, cy))
    p.d.arc([-h // 2 + 4, 1, 12, h + 1], -80, 80, fill=C[m][0], width=2)
    p._u(m)
    p.line([(5, 2), (5, h)], "white")
    p.rect(10, cy - 1, 12, cy + 1, "leather")
    if deco:
        p.dot(10, 3, deco, 1)
        p.dot(10, h - 1, deco, 1)
    if glow:
        p.dot(13, cy, glow, 1)
        p.dot(11, 5, glow, 1)
        p.dot(11, h - 3, glow, 1)
    return p.finish((10, cy))


def scifi_gun(barrel=11, body=9, mb="gun", ms="black", glow="cyan", muzzle="brake", coil=False, tank=False, saw=False, bubble=False):
    W = 6 + body + barrel + 5
    p = Pen(W, 16)
    cy = 6
    x = 2
    p.poly([(x, cy + 3), (x + 1, cy), (x + 6, cy), (x + 6, cy + 2)], ms)
    x += 6
    p.rect(x, cy - 1, x + body, cy + 2, mb)
    p.poly([(x + 1, cy + 2), (x + 4, cy + 2), (x + 3, cy + 6), (x, cy + 6)], ms)
    gx, gy = x + 2, cy + 4
    bx = x + body
    p.rect(bx, cy - 1, bx + barrel, cy + 1, mb)
    if coil:
        for cx in range(bx + 1, bx + barrel, 3):
            p.rect(cx, cy - 2, cx + 1, cy + 2, glow)
    mc = glow or mb
    if muzzle == "brake":
        p.rect(bx + barrel - 1, cy - 2, bx + barrel + 1, cy + 2, mc)
    elif muzzle == "bell":
        p.poly([(bx + barrel, cy - 2), (bx + barrel + 3, cy - 3), (bx + barrel + 3, cy + 3), (bx + barrel, cy + 2)], mc)
    elif muzzle == "prism":
        p.poly([(bx + barrel, cy - 3), (bx + barrel + 4, cy), (bx + barrel, cy + 3)], mc)
    if tank:
        p.ell([x + 1, cy - 5, x + 7, cy - 1], glow)
    if bubble:
        p.ell([x + 1, cy - 5, x + 7, cy - 1], "cyan")
        p.dot(x + 3, cy - 4, "white", 1)
    if saw:
        p.ell([bx + barrel - 2, cy - 4, bx + barrel + 5, cy + 3], "steel")
        p.dot(bx + barrel + 2, cy - 1, "red", 0)
    if glow:
        p.dot(x + 3, cy, glow, 1)
        p.dot(bx + barrel - 1, cy, "white", 1)
    return p.finish((gx, gy))


def dragon_cannon():
    p = Pen(28, 17)
    cy = 8
    p.rect(1, cy + 1, 7, cy + 2, "dwood")
    p.rect(6, cy - 4, 21, cy + 4, "jade")
    p.rect(10, cy - 5, 12, cy + 5, "gold")
    p.poly([(20, cy - 5), (26, cy - 3), (26, cy + 3), (20, cy + 5)], "gold")
    p.dot(23, cy - 2, "red", 0)
    p.dot(26, cy, "cyan", 1)
    return p.finish((5, cy))


# ---------------------------------------------------------------- Danh sách 133 vũ khí mới
PROC_EXT = {
    # --- Pháp trượng, đũa phép & sách phép (32)
    "dua_tia_lua": lambda: magic_wand(13, "wood", "fire", "orb", sparks="fire"),
    "dua_giot_nuoc": lambda: magic_wand(13, "bamboo", "cyan", "orb", sparks="cyan"),
    "gay_suong_mu": lambda: magic_wand(16, "white", "ice", "crystal", ring="ice"),
    "sach_la_doc": lambda: grimoire("olive", "wood", "poison"),
    "truong_hoa_cau": lambda: magic_staff(19, "dwood", "fire", "flame_halo", "gold"),
    "dua_bang_suong": lambda: magic_wand(15, "ice", "ice", "crystal", ring="white", sparks="cyan"),
    "truong_sam_set": lambda: magic_staff(19, "iron", "cyan", "bolt", "gold"),
    "sach_ma_phap_co": lambda: grimoire("purple", "gold", "pink"),
    "dua_but_long": lambda: magic_wand(15, "bamboo", "void", "brush", ring="gold"),
    "truong_doc_to": lambda: magic_staff(19, "dwood", "poison", "cage", "olive"),
    "sach_gio_loc": lambda: grimoire("jade", "white", "cyan"),
    "truong_anh_sang": lambda: magic_staff(21, "white", "gold", "crown", "gold"),
    "sach_thien_thach": lambda: grimoire("red", "gold", "fire"),
    "truong_bang_gia": lambda: magic_staff(20, "steel", "ice", "crown", "ice"),
    "sach_loi_than": lambda: grimoire("gun", "cyan", "cyan"),
    "dua_linh_hon": lambda: magic_wand(16, "black", "soul", "crescent", sparks="soul"),
    "truong_trong_luc": lambda: magic_staff(20, "black", "purple", "cage", "purple"),
    "sach_doc_vuong": lambda: grimoire("black", "poison", "poison"),
    "truong_hoa_nguc": lambda: magic_staff(22, "black", "fire", "flame_halo", "red"),
    "sach_sao_bang": lambda: grimoire("void", "gold", "cyan"),
    "truong_bao_tuyet": lambda: magic_staff(22, "white", "ice", "cage", "cyan"),
    "sach_hu_khong": lambda: grimoire("void", "purple", "void"),
    "truong_cuu_thien": lambda: magic_staff(22, "gold", "cyan", "bolt", "cyan"),
    "quyen_truong_phu_thuy": lambda: magic_staff(21, "purple", "pink", "crown", "gold"),
    "sach_ngan_ha": lambda: grimoire("cyan", "white", "gold"),
    "truong_ho_den": lambda: magic_staff(23, "black", "purple", "blackhole", "purple"),
    "sach_thien_khai": lambda: grimoire("gold", "white", "cyan"),
    "truong_ngu_hanh": lambda: magic_staff(22, "gold", "jade", "crown", "red"),
    "truong_dia_chan": lambda: magic_staff(22, "dwood", "jade", "rock", "bronze"),
    "sach_tinh_tu": lambda: grimoire("purple", "gold", "white"),
    "dua_ngoc_hoang": lambda: magic_wand(17, "gold", "cyan", "trident_tip", ring="jade", sparks="gold"),
    "truong_thai_cuc": lambda: magic_staff(22, "dwood", "white", "yin_yang", "gold"),

    # --- Vũ khí ảo ma & kỳ dị dân gian (35)
    "quat_mo": palm_fan,
    "guoc_moc": clog_weapon,
    "non_la_bay": straw_hat,
    "bua_giay_vang": lambda: talisman_stack("paper", "red"),
    "sao_truc": lambda: flute_weapon("bamboo", "white"),
    "bua_tran_yeu": lambda: talisman_stack("paper", "red", "gold"),
    "sung_bong_bong": lambda: scifi_gun(barrel=8, body=7, mb="pink", ms="white", glow="cyan", muzzle="bell", bubble=True),
    "xuc_xac_no": lambda: dice_weapon("white", "red"),
    "chong_chong_tre": bamboo_rotor,
    "sung_tien_xu": lambda: scifi_gun(barrel=7, body=8, mb="gold", ms="wood", glow="gold", muzzle="brake"),
    "chuong_dong": lambda: bell_weapon("bronze"),
    "den_ong_sao": lambda: magic_wand(15, "bamboo", "gold", "star", sparks="red"),
    "but_long_than": lambda: magic_wand(17, "dwood", "black", "brush", ring="jade"),
    "luan_hoi_ban": lambda: chakram_ring("gold", "steel", "cyan"),
    "bai_tu_sac": lambda: card_fan("red"),
    "long_den_ma_troi": lambda: lantern("soul", "gold"),
    "sao_truc_bao_to": lambda: flute_weapon("jade", "cyan"),
    "chuong_chieu_hon": lambda: bell_weapon("jade", "soul"),
    "phao_hoa_tet": lambda: firework_cannon("red", "gold", 1),
    "vong_sen_luan": lambda: chakram_ring("pink", "gold", "jade"),
    "bua_tru_ta": lambda: talisman_stack("gold", "red", "fire"),
    "muoi_duc_anh_trang": lambda: scythe(15, "white", "dwood", "cyan"),
    "binh_ho_lo_ruou": gourd_weapon,
    "guong_bat_quai": mirror_weapon,
    "bo_bai_than": lambda: card_fan("purple"),
    "xuc_xac_van_menh": lambda: dice_weapon("gold", "purple"),
    "bua_thien_su": lambda: talisman_stack("white", "purple", "cyan"),
    "kinh_van_hoa": kaleidoscope_weapon,
    "trong_com_set": lambda: firework_cannon("bronze", "cyan", 1),
    "phao_thang_thien": lambda: firework_cannon("red", "gold", 3),
    "sung_bong_bong_tien": lambda: scifi_gun(barrel=10, body=8, mb="cyan", ms="pink", glow="white", muzzle="bell", bubble=True),
    "luoi_hai_tu_than": lambda: scythe(20, "black", "void", "soul"),
    "dai_bac_long_vuong": dragon_cannon,
    "banh_xe_phong_hoa": lambda: chakram_ring("fire", "gold", "red"),
    "chuong_phat_to": lambda: bell_weapon("gold", "white"),

    # --- Cận chiến nguyên tố & thương kích hiện đại (30)
    "dao_gam_doc": lambda: sword(4, 9, 2, "poison", "black", "iron"),
    "gay_sat": lambda: spear(20, "iron", "steel"),
    "thuong_dong": lambda: spear(18, "wood", "bronze"),
    "kiem_lua": lambda: sword(5, 14, 3, "fire", "red", "gold", glow="fire"),
    "kiem_bang": lambda: sword(5, 14, 3, "ice", "white", "steel", glow="white"),
    "kiem_set": lambda: sword(5, 14, 3, "cyan", "black", "gold", glow="white"),
    "thuong_bang": lambda: spear(20, "white", "ice", "white"),
    "bua_sat": lambda: hammer(14, 4, "dwood", "iron", "steel"),
    "kiem_nhat_nguyet": lambda: sword(4, 13, 2, "gold", "black", "gold", twin=True, double_fx="steel"),
    "dao_gam_ao_anh": lambda: sword(4, 9, 2, "purple", "black", "cyan", twin=True, double_fx="cyan"),
    "kiem_doc_xa": lambda: sword(5, 15, 3, "poison", "black", "jade", curve=1, glow="poison"),
    "thuong_hoa_long": lambda: spear(21, "red", "fire", "gold", wings=True),
    "bua_bang_ha": lambda: hammer(16, 5, "steel", "ice", "cyan", "white"),
    "luoi_hai_bac": lambda: scythe(17, "steel", "dwood"),
    "song_dao_phong_ba": lambda: sword(4, 14, 3, "cyan", "wood", "gold", curve=1, twin=True, double_fx="steel"),
    "quat_ngoc_luan": lambda: mag_fan("jade", "gold", "cyan"),
    "cua_may_cam_tay": chainsaw,
    "kiem_plasma": lambda: sword(5, 16, 3, "purple", "gun", "cyan", glow="pink"),
    "kich_thien_loi": lambda: spear(22, "dwood", "cyan", "gold", wings=True),
    "dai_dao_huyen_vu": lambda: sword(8, 17, 4, "ice", "black", "bronze", curve=1, glow="cyan"),
    "song_kiem_bang_hoa": lambda: sword(5, 15, 2, "fire", "black", "gold", twin=True, double_fx="ice"),
    "bua_chan_thien": lambda: hammer(17, 5, "dwood", "bronze", "gold", "fire"),
    "luoi_hai_huyet_nguyet": lambda: scythe(19, "red", "black", "pink"),
    "kiem_thoi_khong": lambda: sword(6, 18, 3, "void", "gold", "cyan", glow="pink"),
    "thuong_bach_long": lambda: spear(24, "white", "steel", "ice", wings=True),
    "kiem_phuong_hoang": lambda: sword(6, 17, 3, "fire", "gold", "red", glow="fire"),
    "bua_cuu_le": lambda: hammer(18, 6, "black", "bronze", "gold", "cyan"),
    "quat_ba_tieu": lambda: mag_fan("fire", "gold", "red"),
    "kiem_luong_tu": lambda: sword(5, 16, 3, "cyan", "gun", "white", glow="cyan"),
    "dai_dao_thanh_long": lambda: sword(9, 18, 4, "jade", "red", "gold", curve=1, glow="cyan"),

    # --- Cung nỏ phép thuật & phi vũ khí (16)
    "cung_tre": lambda: bow(18, "bamboo"),
    "phi_tieu_doc": lambda: chakram_ring("poison", "steel", "black", teeth=False),
    "cung_bang": lambda: bow(20, "ice", deco="white", glow="cyan"),
    "no_doc": lambda: bow(14, "olive", glow="poison", mech=True),
    "cung_set": lambda: bow(21, "cyan", deco="gold", glow="white"),
    "no_bang_suong": lambda: bow(14, "ice", glow="white", mech=True),
    "phi_dao_luan_hoi": lambda: chakram_ring("steel", "cyan", "gold"),
    "cung_tinh_van": lambda: bow(22, "purple", deco="gold", glow="cyan"),
    "no_bao_lua": lambda: bow(16, "red", glow="fire", mech=True),
    "cung_nguyet_anh": lambda: bow(22, "void", deco="white", glow="pink"),
    "no_thien_co": lambda: bow(16, "gold", glow="cyan", mech=True),
    "cung_thai_duong": lambda: bow(24, "gold", deco="red", glow="fire"),
    "no_cuu_long": lambda: bow(16, "jade", glow="gold", mech=True),
    "cung_phan_than": lambda: bow(22, "jade", deco="cyan", glow="white"),
    "phi_tieu_sao_bang": lambda: chakram_ring("gold", "white", "cyan"),
    "no_huyet_anh": lambda: bow(16, "red", glow="soul", mech=True),

    # --- Súng hiện đại & khoa học viễn tưởng (20)
    "sung_ban_da": lambda: scifi_gun(barrel=7, body=7, mb="wood", ms="dwood", glow=None, muzzle="bell"),
    "sung_ban_dinh": lambda: scifi_gun(barrel=8, body=7, mb="iron", ms="red", glow=None, muzzle="brake"),
    "sung_bang": lambda: scifi_gun(barrel=10, body=8, mb="white", ms="ice", glow="ice", tank=True),
    "sung_axit": lambda: scifi_gun(barrel=9, body=8, mb="olive", ms="black", glow="poison", tank=True),
    "sung_ban_cua": lambda: scifi_gun(barrel=10, body=8, mb="iron", ms="red", glow="steel", saw=True),
    "sung_dien_giat": lambda: scifi_gun(barrel=11, body=8, mb="gun", ms="black", glow="cyan", coil=True),
    "sung_tia_nuoc": lambda: scifi_gun(barrel=10, body=8, mb="cyan", ms="white", glow="cyan", tank=True, muzzle="bell"),
    "sung_dan_nay": lambda: scifi_gun(barrel=9, body=8, mb="steel", ms="gold", glow="gold", muzzle="brake"),
    "sung_tesla": lambda: scifi_gun(barrel=13, body=9, mb="bronze", ms="gun", glow="cyan", coil=True, muzzle="bell"),
    "sung_lang_kinh": lambda: scifi_gun(barrel=12, body=9, mb="white", ms="purple", glow="pink", muzzle="prism"),
    "sung_luong_tu": lambda: scifi_gun(barrel=11, body=9, mb="purple", ms="black", glow="cyan", coil=True),
    "sung_tuyet_son": lambda: scifi_gun(barrel=12, body=9, mb="ice", ms="steel", glow="white", tank=True, muzzle="bell"),
    "sung_cua_xoay": lambda: scifi_gun(barrel=12, body=9, mb="black", ms="red", glow="gold", saw=True),
    "sung_doc_duoc": lambda: scifi_gun(barrel=12, body=9, mb="black", ms="olive", glow="poison", tank=True, muzzle="bell"),
    "sung_trong_luc": lambda: scifi_gun(barrel=12, body=10, mb="void", ms="black", glow="purple", coil=True, muzzle="bell"),
    "sung_railgun": lambda: scifi_gun(barrel=17, body=10, mb="gun", ms="steel", glow="cyan", coil=True, muzzle="brake"),
    "sung_tieu_huy": lambda: scifi_gun(barrel=12, body=10, mb="black", ms="purple", glow="pink", coil=True, muzzle="prism"),
    "sung_hoa_ti_lien": lambda: scifi_gun(barrel=14, body=10, mb="olive", ms="red", glow="fire", muzzle="bell"),
    "sung_phan_vat_chat": lambda: scifi_gun(barrel=13, body=10, mb="black", ms="void", glow="purple", tank=True, muzzle="prism"),
    "sung_quang_tu": lambda: scifi_gun(barrel=15, body=10, mb="gold", ms="white", glow="cyan", coil=True, muzzle="prism"),
}


# ---------------------------------------------------------------- 10 loại đạn mới trong assets/sprites/fx/
def build_projectiles_ext():
    # 1. orb_ice (11x11 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(11, 11)
        r = 4 if f == 0 else 5
        d.ellipse([5 - r, 5 - r, 5 + r, 5 + r], fill=hexc("4ad0ff", 140))
        d.polygon([(5, 1), (9, 5), (5, 9), (1, 5)], fill=hexc("78e4ff"))
        d.polygon([(5, 3), (7, 5), (5, 7), (3, 5)], fill=WHITE)
        fr.append(img)
    save(sheet(fr), "fx/orb_ice.png")

    # 2. orb_void (13x13 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(13, 13)
        r = 5 if f == 0 else 6
        d.ellipse([6 - r, 6 - r, 6 + r, 6 + r], fill=hexc("a040ff", 150))
        d.ellipse([3, 3, 9, 9], fill=hexc("341450"))
        d.ellipse([4, 4, 8, 8], fill=hexc("120820"))
        d.point([4 + f, 3], fill=hexc("f0a0ff"))
        d.point([8 - f, 9], fill=hexc("c070ff"))
        fr.append(img)
    save(sheet(fr), "fx/orb_void.png")

    # 3. orb_star (13x13 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(13, 13)
        col = hexc("ffd84a") if f == 0 else hexc("ffe878")
        d.ellipse([3, 3, 9, 9], fill=hexc("ffaa20", 140))
        d.line([6, 1, 6, 11], fill=col, width=1)
        d.line([1, 6, 11, 6], fill=col, width=1)
        if f == 1:
            d.line([3, 3, 9, 9], fill=col, width=1)
            d.line([3, 9, 9, 3], fill=col, width=1)
        d.rectangle([5, 5, 7, 7], fill=WHITE)
        fr.append(img)
    save(sheet(fr), "fx/orb_star.png")

    # 4. orb_lightning (11x11 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(11, 11)
        d.ellipse([2, 2, 8, 8], fill=hexc("30c8ff", 160))
        d.ellipse([3, 3, 7, 7], fill=hexc("90f4ff"))
        if f == 0:
            d.line([(1, 5), (4, 3), (6, 7), (9, 5)], fill=WHITE)
        else:
            d.line([(5, 1), (3, 4), (7, 6), (5, 9)], fill=WHITE)
        fr.append(img)
    save(sheet(fr), "fx/orb_lightning.png")

    # 5. talisman (14x9 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(14, 9)
        yoff = 0 if f == 0 else 1
        d.rectangle([2, 1 + yoff, 11, 6 + yoff], fill=hexc("f4d880"))
        d.line([4, 3 + yoff, 9, 3 + yoff], fill=hexc("d83030"))
        d.line([7, 2 + yoff, 7, 5 + yoff], fill=hexc("d83030"))
        d.point([12, 3 + yoff], fill=hexc("ff9030"))
        fr.append(outline(img))
    save(sheet(fr), "fx/talisman.png")

    # 6. chakram (13x13 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(13, 13)
        d.ellipse([2, 2, 10, 10], fill=hexc("e8b04a"))
        d.ellipse([4, 4, 8, 8], fill=(0, 0, 0, 0))
        pts = ((6, 1), (6, 11), (1, 6), (11, 6)) if f == 0 else ((2, 2), (10, 2), (2, 10), (10, 10))
        for px, py in pts:
            d.point([px, py], fill=WHITE)
        fr.append(outline(img))
    save(sheet(fr), "fx/chakram.png")

    # 7. card (11x9 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(11, 9)
        d.rectangle([2, 2, 8, 6], fill=hexc("f8f4e8"))
        d.point([5, 4], fill=hexc("d83030") if f == 0 else hexc("289a60"))
        d.point([3, 3], fill=hexc("e8b04a"))
        d.point([7, 5], fill=hexc("e8b04a"))
        fr.append(outline(img))
    save(sheet(fr), "fx/card.png")

    # 8. bubble (11x11 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(11, 11)
        r = 4 if f == 0 else 5
        d.ellipse([5 - r, 5 - r, 5 + r, 5 + r], fill=hexc("80e8ff", 110), outline=hexc("c0f8ff", 220))
        d.point([3, 3], fill=WHITE)
        d.point([4, 3], fill=hexc("ffc0f0"))
        fr.append(img)
    save(sheet(fr), "fx/bubble.png")

    # 9. soul_bolt (13x9 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(13, 9)
        wob = 0 if f == 0 else 1
        d.polygon([(1, 4 + wob), (7, 2), (11, 4), (7, 6)], fill=hexc("28c89a", 210))
        d.ellipse([6, 2, 10, 6], fill=hexc("78ffe0"))
        d.point([8, 4], fill=WHITE)
        fr.append(img)
    save(sheet(fr), "fx/soul_bolt.png")

    # 10. sawblade (13x13 x 2 frames)
    fr = []
    for f in range(2):
        img, d = canvas(13, 13)
        d.ellipse([2, 2, 10, 10], fill=hexc("b8c0d4"))
        d.ellipse([5, 5, 7, 7], fill=hexc("c43c3c"))
        teeth = ((6, 1), (6, 11), (1, 6), (11, 6)) if f == 0 else ((3, 2), (10, 3), (2, 9), (9, 10))
        for tx, ty in teeth:
            d.point([tx, ty], fill=WHITE)
        fr.append(outline(img))
    save(sheet(fr), "fx/sawblade.png")
