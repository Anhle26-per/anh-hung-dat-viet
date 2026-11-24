"""Tranh nền doanh trại (416 x 240), vẽ nguyên bức theo bố cục:
  trên: mặt tiền đình làng (mái ngói cong, cột son, cửa bức bàn, hoành phi)
  sân khấu gỗ cho các tướng, sân gạch Bát Tràng, võ đường sàn gỗ bên trái,
  khu cổng bên phải, vườn cỏ + lan can đá phía dưới, tường thấp hai bên.
"""
import math
import random
from px import hexc, save, Image, ImageDraw

W, H = 416, 240


def C(h, a=255):
    return hexc(h, a)


def lerp(c1, c2, k):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * k) for i in range(3)) + (255,)


def build():
    rng = random.Random(5)
    img = Image.new("RGBA", (W, H), C("2a1a1a"))
    d = ImageDraw.Draw(img)
    px = img.load()

    # ---------------- sân gạch Bát Tràng (gạch 12x12 có gờ, so le từng hàng)
    brick, b_l, b_d, grout = C("b06a48"), C("cc8662"), C("8a4e36"), C("6e3c2a")
    d.rectangle([0, 96, W, H], fill=grout)
    for row, y in enumerate(range(96, H, 12)):
        off = 6 if row % 2 else 0
        for x in range(-off, W, 12):
            b = brick if rng.random() < 0.75 else lerp(brick, b_d, 0.25) if rng.random() < 0.5 else lerp(brick, b_l, 0.25)
            d.rectangle([x, y, x + 10, y + 10], fill=b)
            d.line([(x, y), (x + 10, y)], fill=lerp(b, b_l, 0.6))
            d.line([(x, y), (x, y + 10)], fill=lerp(b, b_l, 0.35))
            d.line([(x, y + 10), (x + 10, y + 10)], fill=lerp(b, b_d, 0.6))
            if rng.random() < 0.05:
                d.line([(x + 3, y + 3), (x + 6, y + 7)], fill=lerp(b, b_d, 0.7))

    # ---------------- võ đường sàn gỗ (trái)
    wood, w_l, w_d = C("9a6a3c"), C("b8844e"), C("6a4426")
    d.rectangle([8, 110, 140, 196], fill=w_d)
    for i, y in enumerate(range(111, 196, 5)):
        b = wood if i % 2 == 0 else lerp(wood, w_d, 0.2)
        d.rectangle([9, y, 139, y + 3], fill=b)
        d.line([(9, y), (139, y)], fill=lerp(b, w_l, 0.5))
        for x in range(9 + (i * 23) % 40, 139, 40):
            d.line([(x, y), (x, y + 3)], fill=w_d)
    d.rectangle([7, 109, 141, 197], outline=C("4a2a18"))
    d.line([(8, 197), (140, 197)], fill=C("3a2014"))

    # ---------------- vòng đá quanh cổng (phải)
    cx, cy = 370, 160
    for r, col in ((30, C("6e6a62")), (27, C("9a958a")), (22, C("b4ae9e")), (20, C("8a8478"))):
        d.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=col)
    for i in range(12):
        a = i / 12 * math.tau
        d.line([(cx + math.cos(a) * 21, cy + math.sin(a) * 12.6), (cx + math.cos(a) * 26, cy + math.sin(a) * 15.6)], fill=C("6e6a62"))

    # ---------------- vườn cỏ phía dưới
    grass, g_l, g_d = C("5a8a3a"), C("7aaa4a"), C("3e6a2a")
    d.rectangle([0, 206, W, H], fill=grass)
    for _ in range(420):
        x, y = rng.randint(0, W - 1), rng.randint(206, H - 1)
        d.point([x, y], fill=g_l if rng.random() < 0.5 else g_d)
    for _ in range(40):
        x, y = rng.randint(4, W - 4), rng.randint(208, H - 6)
        d.line([(x, y + 3), (x - 1, y)], fill=g_l)
        d.line([(x + 1, y + 3), (x + 2, y)], fill=g_l)
    for _ in range(18):   # hoa dại
        x, y = rng.randint(6, W - 6), rng.randint(210, H - 4)
        c = rng.choice([C("f4e060"), C("f4a0c0"), C("ffffff")])
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            d.point([x + dx, y + dy], fill=c)
        d.point([x, y], fill=C("e8a040"))
    d.rectangle([0, 204, W, 206], fill=C("8a8478"))   # bờ đá
    d.line([(0, 204), (W, 204)], fill=C("b4ae9e"))

    # ---------------- lan can đá cuối vườn
    for x in range(0, W, 16):
        d.rectangle([x + 2, 226, x + 5, 238], fill=C("a8a296"))
        d.line([(x + 2, 226), (x + 5, 226)], fill=C("d0cabc"))
    d.rectangle([0, 224, W, 227], fill=C("b4ae9e"))
    d.line([(0, 224), (W, 224)], fill=C("e0dacc"))
    d.rectangle([0, 237, W, 240], fill=C("6e6a62"))

    # ---------------- tường thấp hai bên, có ô cửa sổ hoa
    for x0 in (0, W - 10):
        d.rectangle([x0, 64, x0 + 9, 224], fill=C("c8bca8"))
        d.line([(x0 + (9 if x0 == 0 else 0), 64), (x0 + (9 if x0 == 0 else 0), 224)], fill=C("8a8070"))
        d.rectangle([x0, 64, x0 + 9, 67], fill=C("8e3a30"))
        for y in range(84, 210, 34):
            d.rectangle([x0 + 2, y, x0 + 7, y + 12], fill=C("5a3a24"))
            d.line([(x0 + 2, y + 6), (x0 + 7, y + 6)], fill=C("c8a060"))
            d.line([(x0 + 4, y), (x0 + 4, y + 12)], fill=C("c8a060"))

    # ---------------- sân khấu gỗ cho các tướng
    sy0, sy1 = 66, 100
    d.rectangle([24, sy0, W - 24, sy1], fill=C("8a5a34"))
    for i, y in enumerate(range(sy0, sy1, 4)):
        d.line([(24, y), (W - 24, y)], fill=C("a8744a") if i % 2 == 0 else C("7a4e2c"))
    d.rectangle([24, sy1, W - 24, sy1 + 4], fill=C("5e3a20"))     # mặt trước sân khấu
    d.line([(24, sy1), (W - 24, sy1)], fill=C("c08a56"))
    for x in range(40, W - 24, 32):                                  # chân sân khấu chạm hoa văn
        d.rectangle([x, sy1 + 1, x + 1, sy1 + 3], fill=C("e8b04a"))
    for x in (196, 208):                                             # bậc thềm giữa
        pass
    d.rectangle([188, sy1 + 4, 228, sy1 + 8], fill=C("9a958a"))
    d.line([(188, sy1 + 4), (228, sy1 + 4)], fill=C("c8c2b4"))

    # ---------------- mặt tiền đình: cột son, cửa bức bàn, hoành phi
    d.rectangle([0, 28, W, 66], fill=C("6a3a24"))
    for x in range(14, W - 10, 44):                                   # cửa bức bàn
        d.rectangle([x, 36, x + 30, 64], fill=C("8a4a2c"))
        d.rectangle([x + 2, 38, x + 28, 50], fill=C("5a2e1a"))
        for gx in range(x + 4, x + 28, 4):
            d.line([(gx, 38), (gx, 50)], fill=C("c08a56"))
        d.line([(x + 2, 44), (x + 28, 44)], fill=C("c08a56"))
        d.rectangle([x + 2, 52, x + 28, 62], outline=C("c08a56"))
    for x in range(4, W, 44):                                         # cột son
        d.rectangle([x, 30, x + 6, 66], fill=C("b8323a"))
        d.line([(x, 30), (x, 66)], fill=C("e05a50"))
        d.line([(x + 6, 30), (x + 6, 66)], fill=C("7a1e2c"))
        d.rectangle([x - 1, 63, x + 7, 66], fill=C("8a8478"))
    d.rectangle([168, 32, 248, 44], fill=C("2a1414"))                  # hoành phi
    d.rectangle([169, 33, 247, 43], outline=C("e8b04a"))
    for i, x in enumerate(range(176, 244, 9)):
        d.rectangle([x, 36, x + 5, 40], fill=C("e8b04a"))
        d.point([x + 2, 38], fill=C("2a1414"))

    # ---------------- mái ngói cong, đầu đao vút lên
    roof, r_l, r_d = C("7a2a24"), C("a84038"), C("4a1818")
    pts = [(0, 30), (W, 30), (W, 14), (W - 30, 18), (30, 18), (0, 14)]
    d.polygon(pts, fill=roof)
    for x in range(0, W, 6):                                           # hàng ngói ống
        top = 18 if 30 <= x <= W - 30 else 18 - int((30 - min(x, W - x)) * 4 / 30)
        d.line([(x, top), (x, 30)], fill=r_d)
        d.line([(x + 1, top), (x + 1, 30)], fill=r_l)
    d.rectangle([0, 28, W, 31], fill=C("3a1410"))                      # diềm mái
    d.line([(0, 28), (W, 28)], fill=C("c05a48"))
    d.rectangle([20, 8, W - 20, 13], fill=C("5a1c18"))                 # bờ nóc
    d.line([(20, 8), (W - 20, 8)], fill=C("c05a48"))
    for xs, sgn in ((20, -1), (W - 20, 1)):                            # đầu đao
        d.polygon([(xs, 8), (xs + 12 * sgn, 2), (xs + 16 * sgn, 0), (xs + 10 * sgn, 8), (xs, 13)], fill=C("5a1c18"))
        d.point([xs + 16 * sgn, 0], fill=C("e8b04a"))
    d.ellipse([200, 2, 216, 10], fill=C("e8b04a"))                     # lưỡng long chầu nguyệt (mặt trăng)
    d.ellipse([203, 4, 213, 8], fill=C("fff0a0"))
    for xs, sgn in ((186, 1), (230, -1)):
        d.line([(xs, 8), (xs + 8 * sgn, 4), (xs + 12 * sgn, 6)], fill=C("3a8a6a"), width=2)
    d.rectangle([0, 0, W, 1], fill=C("1a0e10"))

    # bóng đổ của mái và sân khấu xuống sân
    for y in range(66, 72):
        a = int(70 * (1 - (y - 66) / 6))
        for x in range(0, W):
            r, g, b, _ = px[x, y]
            px[x, y] = (int(r * (1 - a / 255)), int(g * (1 - a / 255)), int(b * (1 - a / 255)), 255)
    for y in range(105, 112):
        a = int(80 * (1 - (y - 105) / 7))
        for x in range(24, W - 24):
            r, g, b, _ = px[x, y]
            px[x, y] = (int(r * (1 - a / 255)), int(g * (1 - a / 255)), int(b * (1 - a / 255)), 255)
    save(img, "world/lobby_bg.png")


if __name__ == "__main__":
    build()
