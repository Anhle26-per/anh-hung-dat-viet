"""Quân xâm lược, quái tinh nhuệ 24 khung và 10 trùm lịch sử 48 khung (lưới 12x4) siêu mượt.

- Mọi lính & quái nhỏ: 24 khung:
  0..7 walk, 8/16/9/17 windup, 10/11/18/12/19/13 attack, 14..15 hurt, 20..23 idle.
- Trùm (48x48, tàu 64x44): 48 khung lưới 12x4:
  0..5 idle, 6..13 walk, 14..19 windup, 20..25 melee_sweep, 26..31 ranged_shot,
  32..35 cast_summon, 36..39 dash, 40..43 leap, 44..45 rage, 46..47 special.
"""
import math
import random
from PIL import Image, ImageDraw
from px import hexc, grid, polish, sheet, sheet_grid, save, canvas, auto_shade, hue_ramp

BASE = {
    "s": hexc("f6c8a4"), "S": hexc("cf9276"), "e": hexc("24162b"), "w": hexc("ffffff"),
    "h": hexc("2b2230"), "H": hexc("524262"),
    "o": hexc("9c6436"), "O": hexc("5a361e"), "m": hexc("dce2f0"), "M": hexc("828cad"),
    "g": hexc("f0b848"), "G": hexc("a86826"), "y": hexc("fff4a4"),
    "r": hexc("e23c3e"), "R": hexc("8c2232"), "k": hexc("f0ecf8"),
    "q": hexc("4a3428"), "Q": hexc("2b1c18"),
    "v": hexc("b46cff"), "V": hexc("56268c"), "u": hexc("f2d6ff"),
}

ARMIES = {
    "dong_han": {"name": "Quân Đông Hán", "1": "962b3d", "2": "5a1628", "3": "ce5262", "4": "302538", "5": "1a1322",
                 "f": "2d2434", "F": "544464", "p": "2b2a42", "P": "191828",
                 "hat": ["", "......hhhhhh", ".....hHhhhhh", ".....hhhhhhh", "....5444444445"]},
    "tong": {"name": "Quân Tống", "1": "be4e3c", "2": "782a24", "3": "ec8462", "4": "8e98b4", "5": "525a76",
             "f": "8e98b4", "F": "e4eaf8", "p": "3c3044", "P": "241d2c",
             "hat": ["........r", ".......mrm", "......mMmmm", ".....mmmmmmM", "....MMMMMMMMMM"]},
    "minh": {"name": "Quân Minh", "1": "b63d2b", "2": "6d201a", "3": "e8704e", "4": "3e374e", "5": "1e192a",
             "f": "3e374e", "F": "665d7c", "p": "2b2a42", "P": "191828",
             "hat": ["........r", ".......rrr", "......h4444h", ".....h444444h", "....hhhhhhhhhh"]},
    "phap_thuy": {"name": "Thủy quân Pháp", "1": "2d4276", "2": "1a2648", "3": "5472ba", "4": "ece8f4", "5": "a6a2c2",
                  "f": "ece8f4", "F": "ffffff", "p": "2d4276", "P": "1a2648",
                  "hat": ["", "........r", "......kkrkkk", ".....kkkkkkkk", "......3333333"]},
    "phap_vien_chinh": {"name": "Quân viễn chinh Pháp", "k": "f2eee2", "1": "dedac8", "2": "a8a48e", "3": "faf6ea", "4": "72442a", "5": "402416",
                        "f": "eae6da", "F": "ffffff", "p": "a8a48e", "P": "767260",
                        "hat": ["", "......kkkkk", ".....kkkkkkk", "....kkkkkkkkk", "...KKKKKKKKKKK"]},
    "phap_1954": {"name": "Lính Pháp 1954", "1": "7f804d", "2": "4c4e2d", "3": "b0b26e", "4": "604226", "5": "3c2a18",
                  "f": "5e5e3c", "F": "828456", "p": "5e603a", "P": "3c3e24",
                  "hat": ["", "......FFFFF", ".....FfffffF", "....ffffffffF", "...ffffffffffF"]},
    "dong_ngo": {"name": "Quân Đông Ngô", "1": "42844e", "2": "265032", "3": "76bc76", "4": "ca8440", "5": "7a4620",
                 "f": "ca8440", "F": "f6c07e", "p": "3c3c2e", "P": "24241b",
                 "hat": ["........r", ".......rRr", "......GgggG", ".....gyggggG", "....GGGGGGGGGG"]},
    "nam_han": {"name": "Quân Nam Hán", "1": "2c8294", "2": "194c62", "3": "62c4cc", "4": "eeb44c", "5": "a86a28",
                "f": "194c62", "F": "2c8294", "p": "2b2a42", "P": "191828",
                "hat": ["", "", "......hhhhhh", ".....hHhhhhhh", "....5444444445"]},
    "nguyen_mong": {"name": "Quân Nguyên Mông", "1": "905d3d", "2": "5a3622", "3": "c28c60", "4": "ca3e3e", "5": "7c1d2d",
                    "f": "6e4c3c", "F": "b09070", "p": "4c3b30", "P": "2e241d",
                    "hat": ["........r", ".......4r4", "......444445", ".....FfFfFfFf", "....fFfFfFfFfF"]},
    "thanh": {"name": "Quân Thanh", "1": "3d62b6", "2": "243c7a", "3": "7094e4", "4": "eecc4e", "5": "a88a28",
              "f": "2c2334", "F": "4e405c", "p": "2b2a42", "P": "191828",
              "hat": ["........r", ".......rrr", "......hhhhhh", "....hhhhhhhhhh", "...HHHHHHHHHHHH"]},
}

FACE = ["....hsssssS", "....hsKssKS", "....hsseseS", "....hSssssS", ".....SSSSS"]
BODY = [".....3111112", ".....3141412", ".....4444444", ".....2111112", ".....2212212"]


def army_pal(a):
    p = dict(BASE)
    for k in "12345fFpP":
        p[k] = hexc(a[k])
    p["K"] = hexc("24162b")
    p["k"] = hexc(a.get("k", "f0ecf8"))
    return p


def cavalry_frames():
    """Kỵ binh Nguyên Mông (34x30 x 24 khung): 0-7 phi nước đại, 8/16/9/17 giương giáo, 10/11/18/12/19/13 đâm giáo, 14-15 trúng đòn, 20-23 đứng chờ."""
    a = ARMIES["nguyen_mong"]
    p = army_pal(a)
    hd, h_dark, horse, hl, _ = hue_ramp("845234")
    frames = []
    rider = grid(a["hat"], p, 20)
    face = grid(FACE, p, 20)
    body = grid(BODY[:3], p, 20)
    for f in range(24):
        img, d = canvas(34, 30)
        is_idle = f >= 20
        is_wind = f in (8, 16, 9, 17)
        is_atk = f in (10, 11, 18, 12, 19, 13)
        is_hurt = f in (14, 15)
        if f < 8:
            t = f
            lift = [0, 1, 2, 1, 0, 1, 2, 1][t]
            legs = [(0, 3), (1, 2), (2, 1), (3, 1), (3, 0), (2, 0), (1, 1), (0, 2)][t]
            dx = 0
        elif is_wind:
            lift = 1 if f in (8, 16) else 2
            legs = (0, 2) if f in (8, 16) else (-1, 3)
            dx = -1 if f in (8, 16) else -2
        elif is_atk:
            lift = 0 if f in (10, 11, 18) else 1
            legs = (3, 0) if f in (10, 11, 18) else (1, 2)
            dx = 3 if f == 18 else (2 if f in (10, 11) else (1 if f in (12, 19) else 0))
        elif is_hurt:
            lift = -1
            legs = (1, 2)
            dx = -1 if f == 14 else 0
        else:  # 20..23 idle
            k = f - 20
            lift = [0, 1, 1, 0][k]
            legs = [(0, 1), (0, 1), (1, 1), (0, 1)][k]
            dx = [0, 0, 1, 0][k]
        for x, k in ((7, 0), (11, 1), (21, 0), (25, 1)):
            off = legs[k]
            d.line([x + dx, 19 - lift, x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=h_dark if k else horse, width=2)
            d.point([x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=hd)
        if f in (2, 6):
            d.point([4 + dx, 27], fill=hexc("dcd4c0"))
            d.point([18 + dx, 27], fill=hexc("b8ae98"))
        d.ellipse([4 + dx, 12 - lift, 28 + dx, 22 - lift], fill=horse)
        d.polygon([(24 + dx, 14 - lift), (29 + dx, 5 - lift), (33 + dx, 7 - lift), (31 + dx, 10 - lift), (28 + dx, 17 - lift)], fill=horse)
        auto_shade(img, horse, hl, h_dark)
        d.line([(27 + dx, 6 - lift), (23 + dx, 13 - lift)], fill=hexc("2b2230"), width=2)
        tail_w = (f - 20) % 2 if is_idle else (f % 2)
        d.line([(5 + dx, 14 - lift), (max(0, 1 + dx), 20 - lift + tail_w)], fill=hexc("2b2230"), width=2)
        eye_h = hexc("ffffff") if f == 17 else (hexc("ffe060") if (is_wind or f in (10, 11, 18)) else hexc("1a1222"))
        d.point([min(33, 31 + dx), 7 - lift], fill=eye_h)
        d.rectangle([12 + dx, 11 - lift, 20 + dx, 13 - lift], fill=hexc("ca3e3e"))
        d.line([(13 + dx, 12 - lift), (19 + dx, 12 - lift)], fill=hexc("f0b848"))
        img.alpha_composite(rider, (max(0, 6 + dx), max(0, 0 - lift)))
        img.alpha_composite(face, (max(0, 6 + dx), max(0, 5 - lift)))
        img.alpha_composite(body, (max(0, 6 + dx), max(0, 10 - lift)))
        if is_wind:
            ox = 0 if f == 8 else (-1 if f in (16, 9) else -2)
            oy = -1 if f in (9, 17) else 0
            d.line([(13 + ox, 8 + oy), (22 + ox, 6 + oy)], fill=hexc("9c6436"), width=2)
            d.polygon([(22 + ox, 5 + oy), (26 + ox, 5 + oy), (22 + ox, 7 + oy)], fill=hexc("ffffff"))
            if f in (9, 17):
                d.point([26 + ox, 5 + oy], fill=hexc("fff68a") if f == 9 else hexc("ffffff"))
                if f == 17:
                    d.point([25 + ox, 4 + oy], fill=hexc("fff68a"))
        elif f in (10, 11, 18):
            d.line([(15, 11), (32, 10)], fill=hexc("9c6436"), width=2)
            d.polygon([(30, 8), (33, 10), (30, 12)], fill=hexc("ffffff"))
            if f in (11, 18):
                d.line([(25, 7), (33, 10)], fill=hexc("9eeeff"))
                if f == 18:
                    d.line([(22, 13), (33, 10)], fill=hexc("ffffff"))
                    d.line([(2, 14), (9, 14)], fill=hexc("d8f4ff"))
        elif f in (12, 19, 13):
            y_l = 14 if f == 12 else (13 if f == 19 else 15)
            d.line([(18, 12), (28, y_l)], fill=hexc("9c6436"), width=1)
            d.point([29, y_l], fill=hexc("dce2f0"))
            if f == 19:
                d.line([(24, 11), (30, 13)], fill=hexc("9eeeff"))
        else:
            d.line([(19 + dx, 2 - lift), (19 + dx, 14 - lift)], fill=hexc("9c6436"))
            d.line([(19 + dx, 0 - lift), (19 + dx, 2 - lift)], fill=hexc("ffffff"))
            if f == 22:
                d.point([20 + dx, max(0, 0 - lift)], fill=hexc("fff6a8"))
        if is_hurt:
            d.ellipse([21, 5, 25, 9], fill=hexc("ff6060") if f == 14 else hexc("ffaa60"))
        frames.append(polish(img))
    return frames


def tank_frames():
    """Xe tăng Pháp 1954 (40x30 x 24 khung): 0-7 lăn xích, 8/16/9/17 khóa nòng, 10/11/18/12/19/13 bắn & khói, 14-15 trúng đòn, 20-23 nổ máy chờ."""
    bd_deep, bd, body, bl, bspec = hue_ramp("6a6c3c")
    fr = []
    for f in range(24):
        img, d = canvas(40, 30)
        is_idle = f >= 20
        recoil = -3 if f in (11, 18) else (-2 if f == 10 else (-1 if f in (12, 19, 14) else 0))
        vib_y = -1 if f in (21, 22) else 0
        d.rectangle([3, 18, 37, 26], fill=hexc("28291d"))
        for x in range(5, 37, 5):
            cx = x + ((f % 3) if f < 8 else 0)
            if cx <= 36:
                d.ellipse([cx - 2, 20, cx + 2, 25], fill=hexc("5e604c"))
                d.point([cx, 22], fill=hexc("8c8e72"))
        if f in (2, 6):
            d.point([4, 26], fill=hexc("c8c0a8"))
            d.point([2, 25], fill=hexc("9a927c"))
        d.polygon([(4, 18), (8, 11 + vib_y), (34, 11 + vib_y), (37, 18)], fill=body)
        auto_shade(img, body, bl, bd)
        d.line([(9, 12 + vib_y), (33, 12 + vib_y)], fill=bspec)
        for rx in (10, 16, 22, 28, 33):
            d.point([rx, 16], fill=bd_deep)
        d.ellipse([12 + recoil, 4 + vib_y, 28 + recoil, 14 + vib_y], fill=body)
        d.rectangle([15 + recoil, 3 + vib_y, 21 + recoil, 5 + vib_y], fill=bl)
        d.rectangle([26 + recoil, 7 + vib_y, 36 + recoil, 9 + vib_y], fill=bd)
        d.rectangle([35 + recoil, 6 + vib_y, 37 + recoil, 10 + vib_y], fill=bd_deep)
        d.rectangle([16 + recoil, 6 + vib_y, 19 + recoil, 8 + vib_y], fill=bspec)
        if f in (8, 16, 9, 17):
            c_gl = hexc("ffaa30") if f == 8 else (hexc("ffd048") if f == 16 else (hexc("ffe86a") if f == 9 else hexc("ffffff")))
            d.point([37, 8], fill=c_gl)
            if f in (9, 17):
                d.point([38, 8], fill=hexc("fff8a8"))
                if f == 17:
                    d.point([37, 7], fill=hexc("ffe86a"))
                    d.point([37, 9], fill=hexc("ffe86a"))
        elif f in (10, 11, 18):
            d.polygon([(35, 4 if f in (11, 18) else 5), (39, 8), (35, 12 if f in (11, 18) else 11), (33, 8)], fill=hexc("ff6820"))
            d.polygon([(35, 6), (39, 8), (35, 10)], fill=hexc("fff68a"))
            if f in (11, 18):
                d.point([38, 8], fill=hexc("ffffff"))
                if f == 18:
                    d.arc([31, 2, 39, 14], -70, 70, fill=hexc("fff8b8"), width=1)
        elif f in (12, 19, 13):
            ox = 34 if f == 12 else (32 if f == 19 else 30)
            oy = 4 if f == 12 else (3 if f == 19 else 1)
            d.ellipse([ox, oy, ox + 4, oy + 4], fill=hexc("c8ccd4", 200))
            d.ellipse([ox - 3, max(0, oy - 2), ox + 1, oy + 1], fill=hexc("e8ecf0", 160))
        elif f in (14, 15):
            d.line([(16, 6), (22, 11)], fill=hexc("ffaa30") if f == 14 else hexc("ffd880"))
            if f == 14:
                d.point([18, 8], fill=hexc("ffffff"))
        elif is_idle:
            k = f - 20
            d.ellipse([5 - (k % 2), 8 - k, 8 - (k % 2), 11 - k], fill=hexc("c8ccd4", 165))
            if k == 2:
                d.point([17, 7], fill=hexc("ffffff"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/xe_tang.png")


def chan_tinh_frames():
    """Chằn tinh (30x32 x 24 khung): 0-7 bước nặng, 8/16/9/17 vung chùy, 10/11/18/12/19/13 đập đất, 14-15 choáng, 20-23 thở cảnh giới."""
    _, sd, sk, sl, _ = hue_ramp("6a8f58")
    fr = []
    for f in range(24):
        img, d = canvas(30, 32)
        is_idle = f >= 20
        is_wind = f in (8, 16, 9, 17)
        is_atk = f in (10, 11, 18, 12, 19, 13)
        if f < 8:
            bob = [0, 0, -1, -1, 0, 0, -1, 0][f]
            lo = [(0, 2), (1, 2), (1, 1), (2, 1), (2, 0), (1, 0), (1, 1), (0, 1)][f]
            dx = 0
        elif is_wind:
            bob = -1 if f in (8, 16) else -2
            lo = (0, 0)
            dx = -1 if f in (8, 16) else -2
        elif is_atk:
            bob = {10: 1, 11: 2, 18: 2, 12: 1, 19: 1, 13: 0}[f]
            lo = (0, 0) if f == 13 else (2, 2)
            dx = 2 if f == 18 else (1 if f in (10, 11, 12) else 0)
        elif f in (14, 15):
            bob = -1 if f == 14 else 0
            lo = (2, 2)
            dx = -1 if f == 14 else 0
        else:
            k = f - 20
            bob = [0, -1, -1, 0][k]
            lo = (0, 0)
            dx = [0, 0, 1, 0][k]
        d.rectangle([9 + dx, 24, 13 + dx, 30 - lo[0]], fill=sd)
        d.rectangle([17 + dx, 24, 21 + dx, 30 - lo[1]], fill=sk)
        if f in (2, 6):
            d.point([7 + dx, 30], fill=hexc("cfc4ad"))
            d.point([22 + dx, 30], fill=hexc("cfc4ad"))
        d.ellipse([5 + dx, 10 + bob, 25 + dx, 27 + bob], fill=sk)
        d.ellipse([8 + dx, 2 + bob, 22 + dx, 15 + bob], fill=sk)
        auto_shade(img, sk, sl, sd)
        d.rectangle([7 + dx, 20 + bob, 23 + dx, 24 + bob], fill=hexc("7a482c"))
        d.rectangle([13 + dx, 20 + bob, 17 + dx, 24 + bob], fill=hexc("e8dcc0"))
        d.point([14 + dx, 22 + bob], fill=hexc("241410"))
        d.point([16 + dx, 22 + bob], fill=hexc("241410"))
        d.polygon([(9 + dx, 4 + bob), (6 + dx, max(0, 0 + bob)), (12 + dx, 3 + bob)], fill=hexc("efe4cc"))
        d.polygon([(21 + dx, 4 + bob), (24 + dx, max(0, 0 + bob)), (18 + dx, 3 + bob)], fill=hexc("efe4cc"))
        eye_c = hexc("ffffff") if f == 17 else (hexc("fff060") if (is_wind or f in (10, 11, 18)) else hexc("ff3828"))
        d.rectangle([11 + dx, 7 + bob, 12 + dx, 8 + bob], fill=eye_c)
        d.rectangle([17 + dx, 7 + bob, 18 + dx, 8 + bob], fill=eye_c)
        mh = 3 if (is_wind or f in (10, 11, 18)) else 1
        d.rectangle([12 + dx, 12 + bob, 18 + dx, 12 + bob + mh], fill=hexc("2a1414"))
        d.point([12 + dx, 12 + bob], fill=hexc("ffffff"))
        d.point([17 + dx, 12 + bob], fill=hexc("ffffff"))
        if is_wind:
            cy_c = 5 if f == 8 else (4 if f == 16 else (2 if f == 9 else 1))
            d.line([(20, 12), (24, cy_c)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([21, max(0, cy_c - 2), 27, cy_c + 4], fill=hexc("5a3a22"))
            if f in (9, 17):
                d.point([24, max(0, cy_c)], fill=hexc("ffffff") if f == 17 else hexc("dce2f0"))
        elif f in (10, 11, 18):
            d.line([(22, 17), (28, 25 if f in (11, 18) else 21)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, 22 if f in (11, 18) else 18, 29, 27 if f in (11, 18) else 23], fill=hexc("5a3a22"))
            if f in (11, 18):
                d.arc([16, 12, 29, 27], -45, 45, fill=hexc("ffffff") if f == 18 else hexc("fff088"), width=2)
                if f == 18:
                    d.line([(20, 29), (29, 29)], fill=hexc("fff088"))
        elif f in (12, 19, 13):
            wy = 19 if f == 12 else (17 if f == 19 else 15)
            d.line([(24, 19), (28, wy)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, wy - 3, 29, wy + 2], fill=hexc("5a3a22"))
        elif f in (14, 15):
            d.line([(6, 15), (3, 21)], fill=hexc("7a4a2e"), width=2)
            if f == 14:
                d.point([10, 3], fill=hexc("ffffff"))
        else:
            wy = [11, 10, 9, 10, 11, 12, 11, 10][f] if f < 8 else [12, 11, 10, 11][f - 20]
            d.line([(24 + dx, 16 + bob), (28, wy + bob)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, wy - 5 + bob, 29, wy + bob], fill=hexc("5a3a22"))
            d.point([27, wy - 3 + bob], fill=hexc("dce2f0"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/chan_tinh.png")


def dai_bang_frames():
    """Đại bàng tinh (36x26 x 24 khung): 0-7 vỗ cánh, 8/16/9/17 xếp cánh, 10/11/18/12/19/13 lao vút, 14-15 xù lông, 20-23 lượn chờ."""
    _, bd, br, bl, _ = hue_ramp("825432")
    fr = []
    for f in range(24):
        img, d = canvas(36, 26)
        if f < 8:
            wing = [-8, -6, -3, 1, 5, 2, -2, -6][f]
            dx = 0
        elif f in (8, 16, 9, 17):
            wing = {8: -5, 16: -6, 9: -7, 17: -8}[f]
            dx = -2
        elif f in (10, 11, 18, 12, 19, 13):
            wing = {10: 4, 11: 7, 18: 8, 12: 2, 19: -1, 13: -4}[f]
            dx = 2 if f in (10, 11, 18) else 1
        elif f in (14, 15):
            wing = 3 if f == 14 else 1
            dx = -1
        else:  # 20..23 idle hover
            wing = [-2, -3, -1, 0][f - 20]
            dx = [0, 0, 1, 0][f - 20]
        dy_idle = -1 if f in (21, 22) else 0
        d.polygon([(16 + dx, 12 + dy_idle), (2 + dx, 12 + wing + dy_idle), (8 + dx, 15 + dy_idle), (16 + dx, 16 + dy_idle)], fill=br)
        d.polygon([(20 + dx, 12 + dy_idle), (34 + dx, 12 + wing + dy_idle), (28 + dx, 15 + dy_idle), (20 + dx, 16 + dy_idle)], fill=br)
        d.line([(4 + dx, 12 + wing + dy_idle), (14 + dx, 13 + dy_idle)], fill=hexc("f0b848"))
        d.line([(32 + dx, 12 + wing + dy_idle), (22 + dx, 13 + dy_idle)], fill=hexc("f0b848"))
        d.ellipse([12 + dx, 9 + dy_idle, 24 + dx, 21 + dy_idle], fill=br)
        auto_shade(img, br, bl, bd)
        d.ellipse([20 + dx, 5 + dy_idle, 28 + dx, 13 + dy_idle], fill=hexc("cc9a54"))
        d.line([(21 + dx, 7 + dy_idle), (25 + dx, 6 + dy_idle)], fill=hexc("ffe496"))
        d.polygon([(27 + dx, 8 + dy_idle), (33 + dx, 10 + dy_idle), (27 + dx, 11 + dy_idle)], fill=hexc("f4b632"))
        eye_e = hexc("ffffff") if f == 17 else (hexc("ff3030") if (f in (8, 16, 9, 10, 11, 18)) else hexc("1a1222"))
        d.point([24 + dx, 8 + dy_idle], fill=eye_e)
        tx = 4 if f in (10, 11, 18) else 0
        d.line([(15 + dx, 21 + dy_idle), (14 + dx + tx, 24 + dy_idle)], fill=hexc("f4b632"))
        d.line([(20 + dx, 21 + dy_idle), (21 + dx + tx, 24 + dy_idle)], fill=hexc("f4b632"))
        if f in (10, 11, 18):
            d.line([(2, 8), (11, 8)], fill=hexc("e0f8ff"))
            if f in (11, 18):
                d.line([(1, 16), (10, 16)], fill=hexc("ffffff"))
                if f == 18:
                    d.line([(3, 12), (12, 12)], fill=hexc("a8f0ff"))
        elif f in (14, 15):
            d.point([18, 4], fill=hexc("ffffff"))
            if f == 14:
                d.point([16, 6], fill=hexc("ff5050"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/dai_bang.png")


def ma_troi_frames():
    """Ma trơi (14x18 x 24 khung): ngọn lửa ma uốn lượn + tụ nổ + đứng lơ lửng."""
    fr = []
    for f in range(24):
        img, d = canvas(14, 18)
        h = [0, 0, 1, 2, 2, 1, 0, 0, 0, -1, -1, 0, 1, 2, 1, 2, -1, -2, 0, 1, 0, -1, -1, 0][f]
        tip_dx = [0, 1, 1, 0, 0, -1, -1, 0, 0, 0, 1, -1, 0, 1, -1, 1, -1, 0, 1, -1, 0, 1, 0, -1][f]
        is_hurt = f in (14, 15)
        outer = hexc("b84aff", 210) if is_hurt else hexc("4aa8ff", 210)
        mid = hexc("78d8ff", 230) if not is_hurt else hexc("e088ff", 220)
        core = hexc("ffffff") if f in (10, 11, 17, 18) else hexc("d6f8ff")
        d.polygon([(2, 12), (7 + tip_dx, max(0, 1 + h)), (12, 12)], fill=outer)
        d.ellipse([2, 7, 12, 16], fill=outer)
        d.ellipse([3, 8, 11, 15], fill=mid)
        d.ellipse([5, 10, 9, 14], fill=core)
        d.point([5, 11], fill=hexc("1a2248"))
        d.point([8, 11], fill=hexc("1a2248"))
        if f in (9, 17, 10, 11, 18):
            d.point([3, 4], fill=hexc("a8f0ff"))
            if f in (11, 17, 18):
                d.point([11, 5], fill=hexc("ffffff"))
                if f == 18:
                    d.point([7, 2], fill=hexc("ffffff"))
                    d.point([2, 8], fill=hexc("a8f0ff"))
        fr.append(img)
    save(sheet(fr), "enemies/ma_troi.png")


_FOLK_E = {
    "a": hexc("525d6b"), "A": hexc("2c3442"), "B": hexc("8b9bb0"), "i": hexc("634332"), "I": hexc("3b271e"),
    "r": hexc("e83a3a"), "w": hexc("ffffff"), "C": hexc("3b1822"), "K": hexc("4a2832"),
    "f": hexc("f48c44"), "F": hexc("c45428"), "L": hexc("ffd494"), "W": hexc("fff0dc"),
    "e": hexc("26182c"), "n": hexc("26182c"), "u": hexc("7ee6ff"), "U": hexc("288ee4"),
    "g": hexc("f0ba4a"), "G": hexc("a46824"), "c": hexc("d8f8ff"), "p": hexc("c850ff"),
}

_TIEU_YEU = [
    "", "...i........i", "...iI......Ii", "....iBaaaaaI", "...aBBaaaaaaa", "..aBaaaaaaaaaA",
    "..aBwrraawrraA", "..aawrgaawrgaA", "..aaaaCCaaaaaA", "..aaKwKwKwKaaA", "..gGaaKKKKKaaA",
    "...AaaaaaaaAA", "..a.AAAAgAAA.a",
]
_TIEU_YEU_HURT = [
    "", "...i........i", "...iI......Ii", "....iBaaaaaI", "...aBBaaaaaaa", "..aBaaaaaaaaaA",
    "..aBraaaawraaA", "..aaaraaaaraaA", "..aaaaCCaaaaaA", "..aaKKKKKKKaaA", "..gGaaKwwKaaAA",
    "...AaaaaaaaAA", "..a.AAAAgAAA.a",
]
_TIEU_YEU_LEGS = [
    ["....aA....aA", "....AA....AA"], ["...aA......aA", "...AA......AA"],
    ["....aA....aA", "....AA....AA"], [".....aA..aA", ".....AA..AA"],
]

_HO_TINH = [
    "", "..W..........F..F", ".WLW........fF.fF", ".WLfW.......ffffff", "..fLf......fLffffff",
    "..fFf.....fLfeefffff", "..ffF....fffffffWWWn", ".fffF...ffffffWWWWW", ".ffFF.fLffffffWWW",
    "..fFFfLffffffffW", "...FFfffffffffgF", ".....FffffffffF",
]
_HO_TINH_LEGS = [
    [".....fF.fF..fF.fF", ".....WW.WW..WW.WW"], ["....fF...fF.fF..fF", "....WW...WW.WW..WW"],
    [".....fF.fF..fF.fF", ".....WW.WW..WW.WW"], ["......fFfF...fFfF", "......WWWW...WWWW"],
]


def tieu_yeu_frames():
    """Tiểu yêu (16x17 x 24 khung): 0-7 chạy, 8/16/9/17 lấy đà, 10/11/18/12/19/13 vồ cào, 14-15 trúng đòn, 20-23 thở chờ."""
    frames = []
    size = (16, 17)
    walk_legs = [
        _TIEU_YEU_LEGS[0], ["....aA....aA", "...AA.....AA"], _TIEU_YEU_LEGS[1], ["...aA......aA", "....AA....AA"],
        _TIEU_YEU_LEGS[2], [".....aA..aA", "....AA....AA"], _TIEU_YEU_LEGS[3], ["....aA...aA", ".....AA..AA"],
    ]
    walk_bobs = [0, 0, -1, -1, 0, -1, 0, 1]
    for f in range(24):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if f < 8:
            legs = walk_legs[f]
            dx = 1 if f == 2 else 0
            bob = walk_bobs[f]
            up = _TIEU_YEU
        elif f in (8, 16, 9, 17):
            legs = _TIEU_YEU_LEGS[3] if f in (8, 16) else ["...aA......aA", "...AA......AA"]
            dx = -1
            bob = 1 if f in (8, 16) else 0
            up = _TIEU_YEU
        elif f in (10, 11, 18):
            legs = ["..aA........aA", "..AA........AA"]
            dx = 0 if f == 10 else (1 if f == 11 else 2)
            bob = -1
            up = _TIEU_YEU
        elif f in (12, 19, 13):
            legs = ["...aA......aA", "...AA......AA"] if f in (12, 19) else ["....aA....aA", "....AA....AA"]
            dx = 1 if f in (12, 19) else 0
            bob = 0 if f in (12, 19) else 1
            up = _TIEU_YEU
        elif f in (14, 15):
            legs = ["...aA......aA", "...AA......AA"] if f == 14 else ["....aA....aA", "....AA....AA"]
            dx = -1 if f == 14 else 0
            bob = 0 if f == 14 else 1
            up = _TIEU_YEU_HURT
        else:  # 20..23 idle
            k = f - 20
            legs = _TIEU_YEU_LEGS[0]
            dx = [0, 0, 1, 0][k]
            bob = [0, -1, -1, 0][k]
            up = _TIEU_YEU
        img.alpha_composite(grid(legs, _FOLK_E, size[0]), (dx, 13))
        img.alpha_composite(grid(up, _FOLK_E, size[0]), (dx, max(0, bob)))
        if f in (2, 6):
            d.point([2, 15], fill=_FOLK_E["B"])
        if f == 8:
            d.point([12, 10], fill=_FOLK_E["B"])
        elif f in (16, 9, 17):
            d.point([13, 9], fill=_FOLK_E["w"] if f in (9, 17) else _FOLK_E["u"])
            d.point([12, 10], fill=_FOLK_E["B"])
            if f == 17:
                d.point([14, 8], fill=_FOLK_E["w"])
        elif f == 10:
            d.line([(12, 8), (14, 6)], fill=_FOLK_E["w"])
            d.line([(12, 11), (14, 9)], fill=_FOLK_E["c"])
        elif f in (11, 18):
            d.line([(12, 7), (15, 5)], fill=_FOLK_E["w"])
            d.line([(12, 10), (15, 8)], fill=_FOLK_E["c"])
            d.line([(13, 12), (15, 11)], fill=_FOLK_E["u"])
            if f == 18:
                d.line([(11, 6), (15, 4)], fill=_FOLK_E["w"])
        elif f in (12, 19):
            d.line([(13, 9), (15, 11)], fill=_FOLK_E["c"])
            d.point([14, 12], fill=_FOLK_E["u"] if f == 12 else _FOLK_E["B"])
        elif f == 13:
            d.point([14, 12], fill=_FOLK_E["B"])
        elif f == 14:
            d.point([2, 3], fill=_FOLK_E["r"])
            d.point([1, 5], fill=_FOLK_E["w"])
            d.point([3, 2], fill=_FOLK_E["w"])
        elif f == 15:
            d.point([3, 4], fill=_FOLK_E["r"])
        elif f == 22:
            d.point([13, 7], fill=_FOLK_E["w"])
        frames.append(polish(img))
    save(sheet(frames), "enemies/tieu_yeu.png")


def ho_tinh_frames():
    """Hồ tinh tiểu quái (22x16 x 24 khung): 0-7 chạy, 8/16/9/17 tụ cầu, 10/11/18/12/19/13 phóng cầu, 14-15 trúng đòn, 20-23 chờ."""
    frames = []
    size = (22, 16)
    walk_bobs = [0, 0, -1, -1, 0, -1, 0, 1]
    for f in range(24):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if f < 8:
            legs = _HO_TINH_LEGS[(f // 2) % 4]
            dx, bob = 0, walk_bobs[f]
        elif f in (8, 16, 9, 17):
            legs = _HO_TINH_LEGS[1]
            dx = -1
            bob = 0 if f in (8, 16) else 1
        elif f in (10, 11, 18):
            legs = _HO_TINH_LEGS[2]
            dx, bob = (1 if f in (11, 18) else 0), -1
        elif f in (12, 19, 13):
            legs = _HO_TINH_LEGS[0]
            dx, bob = 0, (0 if f in (12, 19) else 1)
        elif f in (14, 15):
            legs = _HO_TINH_LEGS[1 if f == 14 else 0]
            dx, bob = (-1 if f == 14 else 0), 0
        else:  # 20..23 idle
            k = f - 20
            legs = _HO_TINH_LEGS[0]
            dx = [0, 0, 1, 0][k]
            bob = [0, -1, -1, 0][k]
        img.alpha_composite(grid(legs, _FOLK_E, size[0]), (max(-1, dx), 12))
        img.alpha_composite(grid(_HO_TINH, _FOLK_E, size[0]), (max(-1, dx), max(0, bob)))
        if f in (2, 6):
            d.point([5, 14], fill=_FOLK_E["L"])
        if f in (8, 16):
            d.ellipse([17, 3, 19, 5], fill=_FOLK_E["U"] if f == 8 else _FOLK_E["u"])
        elif f in (9, 17):
            d.ellipse([18, 2, 21, 5], fill=_FOLK_E["u"])
            d.point([19, 3], fill=_FOLK_E["w"])
            if f == 17:
                d.point([21, 2], fill=_FOLK_E["w"])
        elif f == 10:
            d.line([(17, 4), (20, 3)], fill=_FOLK_E["u"], width=2)
            d.point([20, 3], fill=_FOLK_E["w"])
        elif f in (11, 18):
            d.line([(18, 5), (21, 3)], fill=_FOLK_E["u"], width=2)
            d.point([21, 2], fill=_FOLK_E["w"])
            d.point([20, 6], fill=_FOLK_E["c"])
            if f == 18:
                d.point([19, 1], fill=_FOLK_E["w"])
        elif f in (12, 19):
            d.point([20, 4], fill=_FOLK_E["U"])
            d.point([21, 5], fill=_FOLK_E["c"] if f == 12 else _FOLK_E["u"])
        elif f == 13:
            d.point([19, 5], fill=_FOLK_E["U"])
        elif f == 14:
            d.point([14, 5], fill=_FOLK_E["r"])
            d.point([15, 5], fill=_FOLK_E["r"])
            d.point([3, 3], fill=_FOLK_E["w"])
        elif f == 15:
            d.point([14, 5], fill=_FOLK_E["r"])
            d.point([4, 4], fill=_FOLK_E["w"])
        else:
            y = 2 + ([0, 1, 2, 2, 1, 0, 1, 2][f] if f < 8 else [1, 0, 0, 1][f - 20])
            d.point([20, y], fill=_FOLK_E["u"])
            d.point([20, y + 1], fill=_FOLK_E["U"])
            d.point([19, y + 1], fill=_FOLK_E["c"])
        frames.append(polish(img))
    save(sheet(frames), "enemies/ho_tinh.png")


def moc_tinh_frames():
    """Mộc tinh tiểu quái (26x28 x 24 khung): 0-7 bước nặng, 8/16/9/17 vươn cành, 10/11/18/12/19/13 đập chấn, 14-15 trúng đòn, 20-23 đứng chờ."""
    bark, bark_l, bark_d = hexc("7e5030"), hexc("b27b4e"), hexc("46291c")
    leaf, leaf_l, leaf_d = hexc("4ea23e"), hexc("90dc62"), hexc("285c2c")
    frames = []
    for f in range(24):
        img, d = canvas(26, 28)
        rng = random.Random(7)
        if f < 8:
            ang = f / 8.0 * math.tau
            sway = round(math.sin(ang))
            bob = -1 if abs(math.sin(ang)) > 0.6 else 0
            lo = (max(0, round(math.sin(ang) * 2)), max(0, round(-math.sin(ang) * 2)))
        elif f in (8, 16, 9, 17):
            sway = 0
            bob = -1 if f in (9, 17) else 0
            lo = (0, 0)
        elif f in (10, 11, 18, 12, 19, 13):
            sway = 0
            bob = {10: 0, 11: 1, 18: 2, 12: 1, 19: 1, 13: 0}[f]
            lo = (2, 2) if f in (11, 18, 12) else (1, 1)
        elif f in (14, 15):
            sway = -1 if f == 14 else 0
            bob = 0 if f == 14 else 1
            lo = (2, 2)
        else:  # 20..23 idle
            k = f - 20
            sway = [0, 1, 0, -1][k]
            bob = [0, -1, -1, 0][k]
            lo = (0, 0)
        d.line([9, 22 + bob, 6 - lo[0], 26], fill=bark_d, width=2)
        d.line([16, 22 + bob, 19 + lo[1], 26], fill=bark_d, width=2)
        if f in (2, 6):
            d.point([5, 26], fill=hexc("c8c0a8"))
            d.point([20, 26], fill=hexc("c8c0a8"))
        d.rectangle([8, 11 + bob, 17, 23 + bob], fill=bark)
        auto_shade(img, bark, bark_l, bark_d)
        for y in range(13 + bob, 23 + bob, 3):
            d.line([10, y, 11, y + 1], fill=bark_d)
            d.point([15, y + 1], fill=bark_d)
        rune_c = hexc("ffffff") if f in (17, 18) else (hexc("ffe86a") if f in (8, 16, 9, 10, 11, 12) else hexc("7af488"))
        d.rectangle([12, 20 + bob, 13, 21 + bob], fill=rune_c)
        if f in (8, 16):
            yy = 9 if f == 16 else 10
            d.line([8, 15 + bob, 4, yy], fill=bark, width=2)
            d.line([17, 15 + bob, 21, yy], fill=bark, width=2)
        elif f in (9, 17):
            d.line([8, 15 + bob, 3, 7], fill=bark, width=2)
            d.line([17, 15 + bob, 22, 7], fill=bark, width=2)
            d.point([2, 6], fill=hexc("ffffff") if f == 17 else leaf_l)
            d.point([23, 6], fill=hexc("ffffff") if f == 17 else leaf_l)
        elif f == 10:
            d.line([8, 15 + bob, 2, 15], fill=bark, width=2)
            d.line([17, 15 + bob, 23, 15], fill=bark, width=2)
        elif f in (11, 18, 12):
            d.line([8, 15 + bob, 2, 22], fill=bark, width=2)
            d.line([17, 15 + bob, 23, 22], fill=bark, width=2)
            d.ellipse([1, 21, 5, 25], fill=leaf_l)
            d.ellipse([20, 21, 24, 25], fill=leaf_l)
        elif f in (19, 13, 14, 15):
            dy = 17 if f in (19, 13) else 18
            d.line([8, 15 + bob, 4, dy], fill=bark, width=2)
            d.line([17, 15 + bob, 21, dy], fill=bark, width=2)
        else:
            d.line([8, 15 + bob, 3, 12 + sway], fill=bark, width=2)
            d.line([17, 15 + bob, 22, 12 - sway], fill=bark, width=2)
            d.point([2, 11 + sway], fill=leaf)
            d.point([23, 11 - sway], fill=leaf)
        for cx, cy, r in ((8, 7 + bob, 6), (17, 7 + bob, 6), (12 + sway, 4 + bob, 6), (12, 9 + bob, 5)):
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf)
        auto_shade(img, leaf, leaf_l, leaf_d)
        px = img.load()
        for _ in range(18):
            x, y = rng.randint(3, 22), rng.randint(max(0, bob), 12)
            if px[x, y] == leaf:
                px[x, y] = leaf_d if rng.random() < 0.45 else leaf_l
        dark = hexc("24140e")
        d.rectangle([9, 13 + bob, 11, 15 + bob], fill=dark)
        d.rectangle([14, 13 + bob, 16, 15 + bob], fill=dark)
        eye_c = hexc("ff4838") if f in (14, 15) else (hexc("ffffff") if f == 17 else (hexc("fff8a8") if f in (16, 9, 10, 11, 18, 12) else hexc("ffd84a")))
        d.rectangle([10, 14 + bob, 11, 15 + bob], fill=eye_c)
        d.rectangle([14, 14 + bob, 15, 15 + bob], fill=eye_c)
        d.line([8, 11 + bob, 11, 12 + bob], fill=dark)
        d.line([14, 12 + bob, 17, 11 + bob], fill=dark)
        mouth_h = 3 if f in (9, 17, 10, 11, 18, 12) else 2
        d.rectangle([10, 17 + bob, 15, 17 + bob + mouth_h], fill=dark)
        for x in (10, 12, 14):
            d.point([x, 17 + bob], fill=hexc("e8dcc0"))
        for x in (11, 13, 15):
            d.point([x, 17 + bob + mouth_h], fill=hexc("e8dcc0"))
        if f in (11, 18, 12):
            d.line([(2 if f in (11, 18) else 4, 26), (23 if f in (11, 18) else 21, 26)], fill=hexc("ffffff") if f == 18 else hexc("a8f080"))
        elif f in (14, 15):
            d.point([6, 12], fill=hexc("d8a060"))
            d.point([19, 12], fill=hexc("d8a060"))
        frames.append(polish(img))
    save(sheet(frames), "enemies/moc_tinh.png")


def ngu_tinh_frames():
    """Thủy quái Ngư Tinh (60x46 x 24 khung): 0-7 bơi, 8/16/9/17 há miệng, 10/11/18/12/19/13 phun nước, 14-15 trúng đòn, 20-23 lượn chờ."""
    body, body_l, body_d = hexc("2b92a8"), hexc("70e4dc"), hexc("154868")
    belly, belly_l, belly_d = hexc("f2e4b8"), hexc("fff8dc"), hexc("b89e74")
    fin, fin_l, fin_d = hexc("df4b58"), hexc("ff8a8a"), hexc("7e223c")
    frames = []
    for f in range(24):
        img, d = canvas(60, 46)
        ang = f / 8.0 * math.tau
        if f < 8:
            sway = round(math.sin(ang) * 3)
            dx = 0
            cy = 24 + round(math.cos(ang))
        elif f in (8, 16, 9, 17):
            sway = -2 if f in (8, 16) else -4
            dx = -1 if f in (8, 16) else -2
            cy = 24
        elif f in (10, 11, 18, 12, 19, 13):
            sway = {10: 1, 11: 4, 18: 5, 12: 2, 19: 1, 13: 0}[f]
            dx = {10: 1, 11: 3, 18: 4, 12: 2, 19: 1, 13: 0}[f]
            cy = 24 if f != 13 else 23
        elif f in (14, 15):
            sway = -2 if f == 14 else 0
            dx = -2 if f == 14 else -1
            cy = 24
        else:  # 20..23 idle
            k = f - 20
            sway = [0, 2, 0, -2][k]
            dx = [0, 0, 1, 0][k]
            cy = 24 + [0, -1, -1, 0][k]
        mouth_open = f in (9, 17, 10, 11, 18, 12)
        d.polygon([(14 + dx, cy), (2 + dx, cy - 12 + sway), (6 + dx, cy + sway // 2), (2 + dx, cy + 12 + sway)], fill=fin)
        auto_shade(img, fin, fin_l, fin_d)
        for i, x in enumerate(range(20, 42, 5)):
            h = 11 - abs(i - 2) * 2
            d.polygon([(x + dx, cy - 11), (x + 3 + dx, cy - 11 - h + (sway if i % 2 else 0) // 2), (x + 6 + dx, cy - 11)], fill=fin)
        d.ellipse([10 + dx, cy - 14, 52 + dx, cy + 14], fill=body)
        auto_shade(img, body, body_l, body_d)
        d.chord([14 + dx, cy - 2, 50 + dx, cy + 14], 0, 180, fill=belly)
        auto_shade(img, belly, belly_l, belly_d)
        px = img.load()
        for row, y in enumerate(range(cy - 10, cy, 4)):
            for x in range(18 + (row % 2) * 3, 46, 6):
                for ddx in range(4):
                    xx, yy = x + ddx + dx, y + (1 if ddx in (0, 3) else 2)
                    if 0 <= xx < 60 and 0 <= yy < 46 and px[xx, yy] == body:
                        px[xx, yy] = body_d
        fy = round(math.sin(ang) * 2) if f < 8 else (-2 if f in (8, 16, 9, 17) else (0 if f >= 20 else 3))
        d.polygon([(27 + dx, cy + 10), (35 + dx, cy + 10), (31 + dx, cy + 19 + fy), (24 + dx, cy + 16 + fy)], fill=fin)
        d.line([(28 + dx, cy + 12), (27 + dx, cy + 16 + fy)], fill=fin_d)
        d.line([(31 + dx, cy + 12), (30 + dx, cy + 17 + fy)], fill=fin_d)
        d.line([(50 + dx, cy + 2), (55 + dx, cy + 6), (min(59, 58 + dx), cy + 12 + sway // 2)], fill=hexc("f0b848"))
        d.line([(48 + dx, cy - 6), (54 + dx, cy - 12), (min(59, 58 + dx), cy - 13 - sway // 2)], fill=hexc("f0b848"))
        ex, ey = 43 + dx, cy - 5
        d.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=hexc("fff6c4"))
        pupil = hexc("e8202a") if f in (14, 15, 17) else hexc("1a1222")
        d.rectangle([ex, ey - 2, ex + 1, ey + 2], fill=pupil)
        d.line([(ex - 4, ey - 5), (ex + 3, ey - 3)], fill=body_d, width=2)
        if mouth_open:
            d.polygon([(min(59, 52 + dx), cy - 1), (44 + dx, cy + 3), (min(59, 52 + dx), cy + 10)], fill=hexc("3a0e22"))
            for y in range(cy, cy + 10, 3):
                d.point([min(59, 50 + dx), y], fill=hexc("ffffff"))
            if f == 10:
                d.line([(min(59, 53 + dx), cy + 3), (57, cy + 3)], fill=hexc("9ee8ff"), width=2)
            elif f in (11, 18, 12):
                d.line([(min(59, 53 + dx), cy + 3), (59, cy + 2)], fill=hexc("9ee8ff"), width=2)
                d.line([(min(59, 53 + dx), cy + 6), (59, cy + 7)], fill=hexc("ffffff"))
        else:
            d.line([(min(59, 52 + dx), cy + 2), (45 + dx, cy + 4)], fill=hexc("3a0e22"))
            d.point([49 + dx, cy + 3], fill=hexc("ffffff"))
            d.point([47 + dx, cy + 4], fill=hexc("ffffff"))
        if f in (14, 15):
            d.ellipse([36, 12, 40, 15], fill=hexc("ffffff"))
        elif f in (2, 6):
            d.point([10, 34], fill=hexc("9ee8ff"))
        frames.append(polish(img))
    save(sheet(frames), "enemies/ngu_tinh.png")


# ---------------------------------------------------------------- 10 Trùm lịch sử 36 khung chi tiết (48x48 x 36 = 1728x48)
BOSSES = {
    "to_dinh": {"name": "Tô Định", "army": "dong_han", "body": "9e2842", "trim": "f4be48", "cape": "2c1b36",
                "hat": "han_official", "weapon": "saber", "beard": "goatee", "eye": "ffcf54", "trait": "seal", "special": "tron_chay"},
    "quach_quy": {"name": "Quách Quỳ", "army": "tong", "body": "c44e3a", "trim": "a6b2d2", "cape": "4d2662",
                  "hat": "steel_helmet", "weapon": "halberd", "beard": "full", "eye": "ffe484", "trait": "banner", "special": "mua_ten"},
    "lieu_thang": {"name": "Liễu Thăng", "army": "minh", "body": "ba3826", "trim": "f2be4a", "cape": "3b324e",
                   "hat": "ming_helmet", "weapon": "saber", "beard": "jagged", "eye": "ff8a48", "trait": "spiked", "special": "sa_lay"},
    "don_truong": {"name": "Đồn trưởng Nhã Nam", "army": "phap_vien_chinh", "body": "dedacc", "trim": "eab448", "cape": "283e76",
                   "hat": "pith", "weapon": "pistol", "beard": "stache", "eye": "26182c", "trait": "modern_belt", "special": "phao_kich"},
    "do_cat": {"name": "Đờ Cát", "army": "phap_1954", "body": "888c56", "trim": "eab448", "cape": "484a2a",
               "hat": "kepi", "weapon": "cane", "beard": "none", "eye": "26182c", "trait": "modern_belt", "special": "ham_chi_huy"},
    "luc_dan": {"name": "Lục Dận", "army": "dong_ngo", "body": "3c8650", "trim": "dc9044", "cape": "214c31",
                "hat": "helmet", "weapon": "halberd", "beard": "full", "eye": "ffe060", "trait": "spiked", "special": "tran_khien"},
    "hoang_thao": {"name": "Hoằng Tháo", "army": "nam_han", "body": "28849c", "trim": "f4c24e", "cape": "7e246a",
                   "hat": "crown", "weapon": "trident", "beard": "none", "eye": "8ef6ff", "trait": "scale_collar", "special": "thuy_quai"},
    "thoat_hoan": {"name": "Thoát Hoan", "army": "nguyen_mong", "body": "925d3c", "trim": "dc3e40", "cape": "4e382e",
                   "hat": "fur", "weapon": "saber", "beard": "braid", "eye": "ffd848", "trait": "fur_collar", "special": "ong_dong"},
    "ton_si_nghi": {"name": "Tôn Sĩ Nghị", "army": "thanh", "body": "385ec0", "trim": "f4d250", "cape": "861e30",
                    "hat": "official", "weapon": "fan", "beard": "mandarin", "eye": "ffe87a", "trait": "mandarin", "special": "bo_chay"},
}


def boss_frames(cfg):
    b_deep, body_d, body, body_l, body_s = hue_ramp(cfg["body"])
    t_deep, trim_d, trim, trim_l, trim_s = hue_ramp(cfg["trim"])
    c_deep, cape_d, cape, cape_l, _ = hue_ramp(cfg["cape"])
    _, skin_d, skin, skin_l, _ = hue_ramp("f4c4a0")
    _, steel_d, steel, steel_l, steel_s = hue_ramp("ced6ea")
    _, gold_d, gold, gold_l, gold_s = hue_ramp("f0b848")
    dark = hexc("1e1326")
    eye_norm = hexc(cfg.get("eye", "26182c"))
    spec = cfg.get("special", "")

    frames = []
    for f in range(48):
        img, d = canvas(48, 48)
        is_idle = f < 6
        is_walk = 6 <= f < 14
        is_wind = 14 <= f < 20
        is_atk = 20 <= f < 26
        is_rng = 26 <= f < 32
        is_cast = 32 <= f < 36
        is_dash = 36 <= f < 40
        is_leap = 40 <= f < 44
        is_leap_air = f in (41, 42)
        is_leap_slam = f == 43
        is_rage = f in (44, 45)
        is_spec = f >= 46

        if is_idle:  # 0..5 idle: nhịp thở uy nghi, áo choàng bay, ánh kim vũ khí & hào quang
            k = f
            bob = [0, -1, -1, -2, -1, 0][k]
            lean = [0, 0, 1, 1, 0, 0][k]
            cape_sway = [0, 1, 2, 2, 1, -1][k]
            cape_flare = [0, 0, 1, 1, 0, 0][k]
            leg_l = [(-2, 0), (-2, 0), (-1, 0), (-1, 0), (-2, 0), (-2, 0)][k]
            leg_r = [(2, 0), (2, 0), (3, 0), (3, 0), (2, 0), (2, 0)][k]
            arm_l = [(-1, 0), (-1, -1), (-2, -1), (-2, -2), (-1, -1), (-1, 0)][k]
            arm_r = [(1, 0), (1, -1), (2, -1), (2, -2), (1, -1), (1, 0)][k]
        elif is_walk:  # 6..13 walk: 8 nhịp sải bước nặng
            t = f - 6
            bob = [0, -1, -2, -1, 0, -1, -2, -1][t]
            lean = [0, 1, 1, 0, 0, -1, -1, 0][t]
            cape_sway = [1, 2, 3, 2, -1, -2, -3, -2][t]
            cape_flare = [0, 0, 1, 0, 0, 0, 1, 0][t]
            leg_l = [(1, 0), (3, -1), (4, -3), (2, -1), (-1, -1), (-3, 0), (-4, -1), (-2, 0)][t]
            leg_r = [(-1, -1), (-3, 0), (-4, -1), (-2, 0), (1, 0), (3, -1), (4, -3), (2, -1)][t]
            arm_l = [(-1, 0), (-2, -1), (-3, -1), (-2, 0), (1, 0), (2, 1), (3, 1), (2, 0)][t]
            arm_r = [(1, 0), (2, -1), (3, -2), (1, -1), (-1, 0), (-2, 0), (-3, 1), (-1, 1)][t]
        elif is_wind:  # 14..19 windup: 6 nhịp thu thế, ấn sáng dâng lên, mắt lóe rực
            k = f - 14
            bob = [0, 1, 1, 2, 2, 1][k]
            lean = [-1, -1, -2, -3, -3, -2][k]
            cape_sway = [1, 2, 2, 3, 4, 4][k]
            cape_flare = [1, 1, 2, 2, 3, 3][k]
            leg_l, leg_r = (-3, 0), (3, -1)
            arm_l = [(-1, -1), (-2, -2), (-3, -2), (-4, -3), (-5, -4), (-5, -5)][k]
            arm_r = [(-2, -1), (-3, -2), (-4, -3), (-5, -5), (-5, -6), (-4, -6)][k]
        elif is_atk:  # 20..25 melee_sweep: 6 nhịp chém quét rộng + dư ảnh
            k = f - 20
            bob = [0, 0, 1, 1, 0, 0][k]
            lean = [1, 2, 3, 3, 2, 1][k]
            cape_sway = [-2, -4, -6, -5, -3, -1][k]
            cape_flare = [1, 2, 3, 3, 2, 1][k]
            leg_l, leg_r = (-5, 0), (5, -1)
            arm_l = [(-3, -2), (-4, -2), (-5, -2), (-4, -1), (-3, 0), (-2, 0)][k]
            arm_r = [(2, -3), (4, -3), (5, -2), (5, 0), (3, 2), (2, 2)][k]
        elif is_rng:  # 26..31 ranged_shot: 6 nhịp ngắm -> bắn liên hoàn -> nhả khói
            k = f - 26
            bob = [0, 0, 0, 1, 0, 0][k]
            lean = [1, 2, 2, -1, -1, 0][k]
            cape_sway = [-1, -1, -2, 2, 2, 1][k]
            cape_flare = [1, 1, 2, 2, 2, 1][k]
            leg_l, leg_r = (-3, 0), (4, 0)
            arm_l = [(2, -2), (3, -2), (3, -2), (1, -3), (1, -2), (0, -1)][k]
            arm_r = [(4, -2), (5, -2), (5, -2), (2, -3), (2, -2), (3, -1)][k]
        elif is_cast:  # 32..35 cast_summon: 4 nhịp giơ ấn triệu hồi
            k = f - 32
            bob = [0, -1, -2, -1][k]
            lean = [0, -1, 0, 0][k]
            cape_sway = [-2, 2, -3, 3][k]
            cape_flare = [2, 3, 4, 3][k]
            leg_l, leg_r = (-2, 0), (2, 0)
            arm_l = [(-3, -4), (-4, -6), (-5, -7), (-3, -5)][k]
            arm_r = [(2, -3), (3, -5), (4, -6), (2, -4)][k]
        elif is_dash:  # 36..39 dash: 4 nhịp lao húc tốc độ cao
            k = f - 36
            bob = [1, 0, 0, 1][k]
            lean = [3, 4, 4, 2][k]
            cape_sway = [-5, -7, -7, -4][k]
            cape_flare = [3, 4, 4, 2][k]
            leg_l = [(-4, 0), (-5, -1), (-2, -2), (-3, 0)][k]
            leg_r = [(4, -1), (5, -2), (2, 0), (3, 0)][k]
            arm_l = [(-4, -1), (-5, -1), (-5, -2), (-3, -1)][k]
            arm_r = [(5, -1), (6, -1), (6, -2), (4, -1)][k]
        elif is_leap:  # 40..43 leap: khom -> phóng lên -> đỉnh -> đập đất
            k = f - 40
            bob = [2, -3, -5, 2][k]
            lean = [0, 1, 2, 2][k]
            cape_sway = [1, -2, -4, -5][k]
            cape_flare = [2, 3, 4, 4][k]
            leg_l = [(-3, 0), (-3, -2), (-3, -4), (-4, 0)][k]
            leg_r = [(3, 0), (3, -2), (3, -4), (4, 0)][k]
            arm_l = [(-3, -1), (-4, -4), (-5, -6), (-4, 2)][k]
            arm_r = [(2, -1), (3, -4), (4, -6), (5, 3)][k]
        elif is_rage:  # 44..45 rage: 2 nhịp gầm rú bùng nổ vòng chấn động đỏ/vàng
            k = f - 44
            bob = -2 if k == 0 else -1
            lean = 0 if k == 0 else -1
            cape_sway = 0 if k == 0 else 2
            cape_flare = 4
            leg_l, leg_r = (-2, 0), (2, 0)
            arm_l = (-6, -6) if k == 0 else (-7, -5)
            arm_r = (5, -5) if k == 0 else (6, -6)
        else:  # 46..47 special: thế chiêu đặc biệt riêng từng trùm
            k = f - 46
            if spec in ("tron_chay", "bo_chay"):
                bob = -1 if k == 0 else 1
                lean = -3 if spec == "tron_chay" else -4
                cape_sway = 5 if k == 0 else 7
                cape_flare = 4
                leg_l = (-4, -2) if k == 0 else (3, 0)
                leg_r = (4, 0) if k == 0 else (-3, -2)
                arm_l = (-4, -3) if k == 0 else (-5, -5)
                arm_r = (2, -3) if k == 0 else (4, -4)
            elif spec == "tran_khien":
                bob = 1 if k == 0 else 0
                lean = 1
                cape_sway = -2 if k == 0 else -1
                cape_flare = 2
                leg_l, leg_r = (-4, 0), (4, 0)
                arm_l, arm_r = (4, -2), (3, -2)
            elif spec == "sa_lay":
                bob = 5 if k == 0 else 6
                lean = -1 if k == 0 else 2
                cape_sway = -3 if k == 0 else 3
                cape_flare = 3
                leg_l, leg_r = (-2, 2), (2, 2)
                arm_l = (-5, -4) if k == 0 else (-3, -6)
                arm_r = (4, -4) if k == 0 else (5, -6)
            elif spec == "mua_ten":
                bob = 0 if k == 0 else -1
                lean = -1
                cape_sway = 2 if k == 0 else 3
                cape_flare = 2
                leg_l, leg_r = (-3, 0), (3, 0)
                arm_l, arm_r = (3, -5), (1, -6)
            elif spec == "phao_kich":
                bob = 0 if k == 0 else -1
                lean = 0
                cape_sway = -2 if k == 0 else -3
                cape_flare = 3
                leg_l, leg_r = (-2, 0), (2, 0)
                arm_l, arm_r = (-3, -1), (3, -6)
            else:
                bob = 0 if k == 0 else -1
                lean = 0
                cape_sway = -1 if k == 0 else 1
                cape_flare = 2 if k == 0 else 3
                leg_l, leg_r = (-2, 0), (2, 0)
                arm_l, arm_r = (-3, -3), (3, -3)

        if is_cast:
            rc = gold_l if f % 2 == 0 else hexc("5ef0ff")
            d.arc([4, 37, 44, 46], 0, 360, fill=rc, width=1)
            for rx_p, ry_p in ((8, 39), (39, 39), (14, 44), (34, 44)):
                d.point([rx_p, ry_p - (f - 32)], fill=gold_s)
        elif is_idle and f in (2, 3, 4):
            d.point([8 + f * 3, 14 + (f % 2) * 4], fill=gold_s)
            d.point([40 - f * 2, 18 + (f % 2) * 3], fill=gold_l)
        elif is_wind and f >= 16:
            d.arc([8, 39, 40, 46], 0, 360, fill=hexc("ff9838") if f < 18 else gold_s, width=1)

        trait = cfg.get("trait", "")
        if trait == "banner":
            bx_flg = max(2, 10 + lean + cape_sway // 2)
            d.line([(16 + lean, 22 + bob), (bx_flg, 3 + bob)], fill=hexc("7a4a2e"), width=2)
            d.polygon([(bx_flg, 3 + bob), (max(1, bx_flg - 7), 6 + bob), (bx_flg, 11 + bob)], fill=hexc("e23c3e"))
            d.point([max(1, bx_flg - 3), 7 + bob], fill=gold_s)
        c_tl, c_tr = 11 + lean, 31 + lean
        c_bl = max(1, 6 + cape_sway - cape_flare)
        c_br = min(46, 37 + cape_sway + cape_flare)
        d.polygon([(c_tl, 20 + bob), (c_tr, 20 + bob), (c_br, 42 + bob // 2), (23 + lean + cape_sway // 2, 39 + bob // 2), (c_bl, 43 + bob // 2)], fill=cape)
        d.line([(c_tl, 20 + bob), (c_bl, 43 + bob // 2)], fill=trim_d)
        d.line([(c_tr, 20 + bob), (c_br, 42 + bob // 2)], fill=trim_l)
        d.line([(c_bl + 2, 41 + bob // 2), (c_br - 2, 40 + bob // 2)], fill=gold)
        auto_shade(img, cape, cape_l, cape_d)

        for bx, (ldx, ldy) in ((16, leg_l), (26, leg_r)):
            hip_x, hip_y = bx + lean, 34 + bob
            knee_x = bx + ldx // 2
            fx, fy = max(1, min(40, bx + ldx)), max(25, min(46, 43 + ldy))
            d.line([(hip_x + 2, hip_y), (knee_x + 2, fy - 3)], fill=c_deep, width=5)
            d.rectangle([knee_x, fy - 7, knee_x + 4, fy - 4], fill=trim_d)
            d.rectangle([fx, fy - 4, fx + 5, fy - 2], fill=trim_l)
            d.rectangle([fx - 1, fy - 2, fx + 6, fy + 1], fill=hexc("23171b"))
            d.point([fx + 1, fy - 2], fill=gold_s)

        lx0, ly0 = 12 + lean, 23 + bob
        lhx = max(2, min(45, 9 + lean + arm_l[0]))
        lhy = max(6, min(44, 30 + bob + arm_l[1]))
        d.line([(lx0, ly0), (lhx, lhy)], fill=body_d, width=4)
        d.ellipse([lhx - 2, lhy - 2, lhx + 2, lhy + 2], fill=trim)
        d.ellipse([lhx - 1, lhy, lhx + 2, lhy + 3], fill=skin)
        if is_cast:
            seal_c = hexc("64f4ff") if f in (33, 35) else gold_s
            d.ellipse([lhx - 3, max(1, lhy - 4), lhx + 3, lhy + 2], fill=seal_c)
            d.point([lhx, max(1, lhy - 2)], fill=hexc("ffffff"))
        if is_walk and f in (8, 12):
            d.point([12, 45], fill=hexc("d8d0be"))
            d.point([33, 45], fill=hexc("d8d0be"))

        bx0, bx1 = max(2, 13 + lean), min(45, 33 + lean)
        d.polygon([(bx0 - 1, 21 + bob), (bx1 + 1, 21 + bob), (bx1 - 1, 32 + bob), (bx0 + 1, 32 + bob)], fill=body)
        d.polygon([(bx0, 32 + bob), (bx1, 32 + bob), (bx1 + 1, 38 + bob), (bx0 - 1, 38 + bob)], fill=body_d)
        auto_shade(img, body, body_l, b_deep)
        for row_i, y in enumerate(range(23 + bob, 31 + bob, 3)):
            for x in range(bx0 + 2 + (row_i % 2) * 2, bx1 - 1, 4):
                d.line([x, y, x + 2, y], fill=body_s)
                d.point([x + 1, y + 1], fill=b_deep)
        d.line([(bx0, 21 + bob), (23 + lean, 24 + bob), (bx1, 21 + bob)], fill=trim_l)
        d.rectangle([bx0, 31 + bob, bx1, 33 + bob], fill=trim_d)
        d.line([(bx0 + 1, 31 + bob), (bx1 - 1, 31 + bob)], fill=trim_l)
        d.rectangle([20 + lean, 30 + bob, 26 + lean, 34 + bob], fill=gold)
        d.rectangle([22 + lean, 31 + bob, 24 + lean, 33 + bob], fill=hexc("e83848"))
        d.line([(23 + lean, 34 + bob), (23 + lean, 38 + bob)], fill=gold, width=2)
        if trait == "mandarin":
            d.rectangle([19 + lean, 24 + bob, 27 + lean, 29 + bob], fill=gold_d)
            d.rectangle([20 + lean, 25 + bob, 26 + lean, 28 + bob], fill=gold_l)
            d.arc([16 + lean, 19 + bob, 30 + lean, 28 + bob], 15, 165, fill=hexc("54e0b8"))
        elif trait == "modern_belt":
            d.line([(bx0 + 2, 21 + bob), (bx1 - 2, 31 + bob)], fill=hexc("5e3820"), width=2)
            d.rectangle([bx0 + 2, 24 + bob, bx0 + 4, 26 + bob], fill=gold_s)
            d.rectangle([bx0 + 5, 24 + bob, bx0 + 6, 26 + bob], fill=hexc("e23c3e"))
        elif trait == "fur_collar":
            d.ellipse([12 + lean, 19 + bob, 34 + lean, 25 + bob], fill=hexc("ece4d8"))
            d.ellipse([19 + lean, 24 + bob, 27 + lean, 29 + bob], fill=trim_l)
        elif trait == "scale_collar":
            d.polygon([(14 + lean, 21 + bob), (23 + lean, 27 + bob), (32 + lean, 21 + bob)], fill=hexc("5ef0ff"))
            d.ellipse([20 + lean, 24 + bob, 26 + lean, 29 + bob], fill=gold)
            d.point([23 + lean, 26 + bob], fill=hexc("44e4ff"))
        else:
            d.ellipse([19 + lean, 23 + bob, 27 + lean, 29 + bob], fill=gold_d)
            d.ellipse([20 + lean, 24 + bob, 26 + lean, 28 + bob], fill=trim_l)
            d.point([22 + lean, 25 + bob], fill=gold_s)
            if trait == "seal":
                d.rectangle([14 + lean, 33 + bob, 18 + lean, 36 + bob], fill=gold_l)

        for px0, px1, sgn in ((8 + lean, 16 + lean, -1), (30 + lean, 38 + lean, 1)):
            d.ellipse([max(1, px0), 19 + bob, min(46, px1), 26 + bob], fill=trim)
            d.arc([max(1, px0), 19 + bob, min(46, px1), 26 + bob], 190 if sgn < 0 else 270, 330 if sgn < 0 else 360, fill=trim_s)
            d.line([(max(1, px0 + 2), 24 + bob), (min(46, px1 - 2), 24 + bob)], fill=t_deep)
            if trait == "spiked":
                sx_tip = max(0, px0 - 2) if sgn < 0 else min(47, px1 + 2)
                d.polygon([(px0 + 3, 20 + bob), (sx_tip, max(0, 16 + bob)), (px1 - 2, 21 + bob)], fill=steel_s)

        d.polygon([
            (15 + lean, 9 + bob), (31 + lean, 9 + bob),
            (31 + lean, 18 + bob), (26 + lean, 23 + bob),
            (20 + lean, 23 + bob), (15 + lean, 18 + bob),
        ], fill=skin)
        d.line([(16 + lean, 10 + bob), (24 + lean, 9 + bob)], fill=skin_l)
        d.line([(15 + lean, 17 + bob), (20 + lean, 22 + bob)], fill=skin_d)
        d.line([(31 + lean, 12 + bob), (31 + lean, 18 + bob)], fill=skin_d)
        ex = 25 + lean
        if is_rage:
            eye = hexc("ff2838") if f == 44 else hexc("fff06a")
        elif is_wind:
            eye = hexc("ffffff") if f == 19 else (hexc("fff890") if f >= 17 else hexc("ffaa38"))
        else:
            eye = eye_norm
        d.rectangle([ex - 5, 14 + bob, ex - 2, 16 + bob], fill=hexc("ffffff"))
        d.rectangle([ex + 1, 14 + bob, ex + 4, 16 + bob], fill=hexc("ffffff"))
        d.rectangle([ex - 4, 14 + bob, ex - 3, 16 + bob], fill=eye)
        d.rectangle([ex + 2, 14 + bob, ex + 3, 16 + bob], fill=eye)
        d.line([ex - 6, 12 + bob, ex - 2, 13 + bob], fill=dark, width=1)
        d.line([ex + 5, 12 + bob, ex + 1, 13 + bob], fill=dark, width=1)
        if is_rage:
            d.rectangle([ex - 3, 19 + bob, ex + 2, 22 + bob], fill=hexc("4a1018"))
            d.point([ex - 2, 19 + bob], fill=hexc("ffffff"))
            d.point([ex + 1, 19 + bob], fill=hexc("ffffff"))
        brd = cfg["beard"]
        if brd == "full":
            d.polygon([(18 + lean, 19 + bob), (30 + lean, 19 + bob), (28 + lean, 26 + bob), (24 + lean, 29 + bob), (20 + lean, 26 + bob)], fill=dark)
            d.line([ex - 4, 19 + bob, ex + 3, 19 + bob], fill=hexc("544464"))
        elif brd == "goatee":
            d.line([(ex - 5, 18 + bob), (ex - 1, 19 + bob), (ex + 3, 18 + bob)], fill=dark)
            d.polygon([(22 + lean, 21 + bob), (26 + lean, 21 + bob), (24 + lean, 27 + bob)], fill=dark)
        elif brd == "jagged":
            d.polygon([(19 + lean, 19 + bob), (29 + lean, 19 + bob), (27 + lean, 26 + bob), (24 + lean, 24 + bob), (21 + lean, 26 + bob)], fill=dark)
        elif brd == "braid":
            d.polygon([(19 + lean, 19 + bob), (29 + lean, 19 + bob), (26 + lean, 26 + bob), (22 + lean, 26 + bob)], fill=dark)
            d.line([(19 + lean, 22 + bob), (17 + lean, 27 + bob)], fill=dark, width=2)
            d.line([(29 + lean, 22 + bob), (31 + lean, 27 + bob)], fill=dark, width=2)
        elif brd == "mandarin":
            d.line([(ex - 5, 19 + bob), (ex - 7, 25 + bob)], fill=dark)
            d.line([(ex + 4, 19 + bob), (ex + 6, 25 + bob)], fill=dark)
            d.line([(24 + lean, 21 + bob), (24 + lean, 27 + bob)], fill=dark)
        elif brd == "stache":
            d.line([(ex - 4, 19 + bob), (ex + 2, 19 + bob)], fill=hexc("4a3228"), width=2)
        else:
            d.line([ex - 3, 20 + bob, ex + 1, 20 + bob], fill=skin_d)

        hat = cfg["hat"]
        if is_spec and spec == "bo_chay":
            hat_dx = -4 if f == 46 else -7
            hat_dy = -1 if f == 46 else 3
        else:
            hat_dx, hat_dy = 0, 0
        hx_off = lean + hat_dx
        hy_off = bob + hat_dy
        if hat == "helmet":
            d.chord([14 + hx_off, max(0, 3 + hy_off), 32 + hx_off, 18 + hy_off], 180, 360, fill=hexc("ca8440"))
            d.rectangle([13 + hx_off, 10 + hy_off, 33 + hx_off, 12 + hy_off], fill=gold_d)
            d.polygon([(21 + hx_off, max(0, 1 + hy_off)), (25 + hx_off, max(0, 1 + hy_off)), (23 + hx_off, 6 + hy_off)], fill=gold_l)
            d.line([23 + hx_off, max(0, 0 + hy_off), max(1, 18 + hx_off + cape_sway // 2), max(0, 3 + hy_off)], fill=hexc("e23c3e"), width=2)
        elif hat == "crown":
            d.rectangle([15 + hx_off, 6 + hy_off, 31 + hx_off, 10 + hy_off], fill=gold)
            for idx_p, x in enumerate((15, 19, 23, 27, 31)):
                pk_y = 0 if idx_p == 2 else 2
                d.polygon([(x - 2 + hx_off, 6 + hy_off), (x + hx_off, max(0, pk_y + hy_off)), (x + 2 + hx_off, 6 + hy_off)], fill=gold_l if idx_p == 2 else gold)
            d.point([23 + hx_off, 8 + hy_off], fill=hexc("4ee8a8"))
            d.point([19 + hx_off, 8 + hy_off], fill=hexc("e83848"))
            d.point([27 + hx_off, 8 + hy_off], fill=hexc("e83848"))
        elif hat == "fur":
            d.ellipse([12 + hx_off, 4 + hy_off, 34 + hx_off, 14 + hy_off], fill=hexc("6e4c3c"))
            d.chord([15 + hx_off, max(0, 0 + hy_off), 31 + hx_off, 12 + hy_off], 180, 360, fill=hexc("ca3e3e"))
            d.ellipse([21 + hx_off, max(0, 0 + hy_off), 25 + hx_off, max(1, 3 + hy_off)], fill=gold_s)
            for x in range(13, 34, 2):
                d.point([x + hx_off, 11 + hy_off], fill=hexc("b89674"))
        elif hat == "han_official":
            d.rectangle([16 + hx_off, max(0, 1 + hy_off), 30 + hx_off, 11 + hy_off], fill=hexc("2c2334"))
            d.rectangle([11 + hx_off, 7 + hy_off, 16 + hx_off, 9 + hy_off], fill=hexc("1a1322"))
            d.rectangle([30 + hx_off, 7 + hy_off, 35 + hx_off, 9 + hy_off], fill=hexc("1a1322"))
            d.rectangle([14 + hx_off, 9 + hy_off, 32 + hx_off, 11 + hy_off], fill=hexc("181220"))
            d.line([18 + hx_off, max(1, 3 + hy_off), 28 + hx_off, max(1, 3 + hy_off)], fill=hexc("564668"))
            d.rectangle([21 + hx_off, 4 + hy_off, 25 + hx_off, 7 + hy_off], fill=gold_s)
        elif hat == "steel_helmet":
            d.chord([14 + hx_off, max(0, 3 + hy_off), 32 + hx_off, 17 + hy_off], 180, 360, fill=steel)
            d.rectangle([13 + hx_off, 10 + hy_off, 33 + hx_off, 12 + hy_off], fill=steel_d)
            d.line([23 + hx_off, max(0, 3 + hy_off), max(1, 21 + hx_off + cape_sway // 2), max(0, 0 + hy_off)], fill=hexc("e23c3e"), width=2)
            d.line([(16 + hx_off, max(1, 6 + hy_off)), (21 + hx_off, max(1, 5 + hy_off))], fill=steel_s)
        elif hat == "ming_helmet":
            d.chord([14 + hx_off, max(0, 2 + hy_off), 32 + hx_off, 18 + hy_off], 180, 360, fill=hexc("3e374e"))
            d.rectangle([13 + hx_off, 10 + hy_off, 33 + hx_off, 12 + hy_off], fill=gold_d)
            d.ellipse([21 + hx_off, max(0, 0 + hy_off), 25 + hx_off, max(1, 4 + hy_off)], fill=hexc("e23c3e"))
            d.line([16 + hx_off, 7 + hy_off, 30 + hx_off, 7 + hy_off], fill=gold_l)
        elif hat == "pith":
            d.chord([13 + hx_off, max(0, 2 + hy_off), 33 + hx_off, 20 + hy_off], 180, 360, fill=hexc("f2eee2"))
            d.rectangle([11 + hx_off, 10 + hy_off, 35 + hx_off, 12 + hy_off], fill=hexc("c8c4b4"))
            d.line([15 + hx_off, 9 + hy_off, 31 + hx_off, 9 + hy_off], fill=hexc("72442a"))
            d.rectangle([21 + hx_off, 5 + hy_off, 24 + hx_off, 8 + hy_off], fill=gold)
        elif hat == "kepi":
            d.rectangle([16 + hx_off, max(0, 3 + hy_off), 30 + hx_off, 10 + hy_off], fill=hexc("d03b32"))
            d.rectangle([15 + hx_off, 10 + hy_off, 31 + hx_off, 12 + hy_off], fill=hexc("2c2334"))
            d.line([17 + hx_off, 5 + hy_off, 29 + hx_off, 5 + hy_off], fill=gold_l)
            d.rectangle([28 + hx_off, 12 + hy_off, 34 + hx_off, 13 + hy_off], fill=hexc("181220"))
        elif hat == "official":
            d.chord([14 + hx_off, max(0, 3 + hy_off), 32 + hx_off, 15 + hy_off], 180, 360, fill=hexc("2c2334"))
            d.rectangle([12 + hx_off, 9 + hy_off, 34 + hx_off, 10 + hy_off], fill=hexc("2c2334"))
            d.ellipse([21 + hx_off, max(0, 0 + hy_off), 25 + hx_off, max(1, 4 + hy_off)], fill=hexc("e83848"))
            d.line([(14 + hx_off, 6 + hy_off), (max(1, 6 + hx_off + cape_sway // 2), 12 + hy_off)], fill=hexc("389862"), width=2)
            d.point([max(1, 6 + hx_off + cape_sway // 2), 12 + hy_off], fill=hexc("4ae2ff"))

        # Vũ khí theo từng pha hành động (0-5 idle, 6-13 walk, 14-19 windup, 20-25 melee, 26-31 ranged, 32-35 cast, 36-39 dash, 40-43 leap, 44-45 rage, 46-47 special)
        w = cfg["weapon"]
        rx0, ry0 = 33 + lean, 23 + bob
        hx = min(44, max(6, 35 + lean + arm_r[0]))
        hy = min(43, max(4, 30 + bob + arm_r[1]))
        d.line([(rx0, ry0), (hx, hy)], fill=body, width=4)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=trim_l)

        if w == "halberd":
            if is_dash or is_rng:
                top = (47, hy - (2 if is_dash else 0))
            elif is_leap_air or is_cast:
                top = (hx + 2, 1)
            elif is_leap_slam:
                top = (47, 42)
            elif is_atk:
                atk_y = [8, 14, 22, 32, 37, 39][f - 20]
                top = (47, atk_y)
            else:
                top = (min(46, hx + (1 if is_wind else 6)), max(1, hy - (28 if is_wind else 25)))
            d.line([(max(2, hx - 4), min(46, hy + 10)), top], fill=hexc("6a4028"), width=2)
            d.polygon([(max(1, top[0] - 4), top[1]), (min(47, top[0] + 1), max(0, top[1] - 2)), (min(47, top[0] + 1), min(47, top[1] + 6)), (max(0, top[0] - 5), min(47, top[1] + 4))], fill=steel)
            d.line([(top[0], max(0, top[1] - 1)), (top[0], min(47, top[1] + 5))], fill=steel_s)
            if f in (21, 22, 23, 24):
                d.arc([30, 5, 47, 38], -80, 55 if f >= 22 else 15, fill=hexc("ffffff"), width=2)
            elif is_rng and f in (27, 28, 29):
                d.polygon([(43, hy - 3), (47, hy), (43, hy + 3), (39, hy)], fill=hexc("fff078") if f < 29 else hexc("ffffff"))
            elif is_idle and f in (1, 2, 3):
                d.point([min(47, top[0]), max(0, top[1] + (f - 1) * 2)], fill=hexc("ffffff"))
        elif w == "trident":
            if is_dash or is_rng:
                top = (47, hy)
            elif is_leap_air or is_cast:
                top = (hx, 1)
            elif is_leap_slam:
                top = (47, 40)
            elif is_atk:
                top = (47, [9, 15, 22, 30, 35, 37][f - 20])
            else:
                top = (min(46, hx + (2 if is_wind else 4)), max(1, hy - 28))
            d.line([(max(2, hx - 2), min(46, hy + 8)), top], fill=gold_d, width=2)
            for dx_t in (-3, 0, 3):
                d.line([(min(47, max(0, top[0] + dx_t)), min(47, top[1] + 5)), (min(47, max(0, top[0] + dx_t)), top[1])], fill=gold_s if dx_t == 0 else gold)
            d.line([(max(0, top[0] - 3), min(47, top[1] + 5)), (min(47, top[0] + 3), min(47, top[1] + 5))], fill=gold_l)
            if f in (21, 22, 23, 24):
                d.line([(hx + 2, hy - 4), (47, hy - 8)], fill=hexc("a8f4ff") if f != 22 else hexc("ffffff"), width=2)
            elif is_rng and f in (27, 28, 29):
                d.ellipse([42, hy - 3, 47, hy + 3], fill=hexc("7ef6ff") if f < 29 else hexc("ffffff"))
            elif is_idle and f in (1, 2, 3):
                d.point([min(47, top[0]), max(0, top[1] + f - 1)], fill=hexc("ffffff"))
        elif w == "saber":
            if is_dash or is_rng:
                d.line([(hx, hy), (47, hy - (1 if is_rng else 0))], fill=steel_s, width=2)
                if is_rng and f in (27, 28, 29):
                    d.arc([39, max(0, hy - 6), 47, min(47, hy + 6)], -70, 70, fill=hexc("ffaa44") if f < 29 else hexc("fff088"), width=2)
            elif is_leap_air or is_cast:
                d.line([(hx, hy), (hx - 2, max(1, hy - 16))], fill=steel_s, width=2)
            elif is_leap_slam:
                d.line([(hx, hy), (47, 41)], fill=steel_s, width=2)
            elif is_atk:
                ang_dy = [12, 8, 2, -4, -8, -10][f - 20]
                d.line([(hx, hy), (47, max(1, min(46, hy - ang_dy)))], fill=steel_s, width=2)
                if f in (21, 22, 23, 24):
                    d.arc([28, max(1, hy - 16), 47, min(47, hy + 12)], -80, 45 if f >= 22 else 10, fill=hexc("ffffff"), width=2)
            else:
                tip_x = min(46, max(4, hx + (2 if is_wind else 7) + arm_r[0]))
                tip_y = max(2, hy - (16 if is_wind else 14))
                d.line([(hx, hy), (tip_x, tip_y)], fill=steel, width=2)
                d.point([tip_x, tip_y - 1], fill=steel_s)
                if is_idle and f in (1, 2, 3):
                    d.point([(hx + tip_x) // 2, (hy + tip_y) // 2], fill=hexc("ffffff"))
            d.line([(hx - 2, hy + 1), (hx + 2, hy - 1)], fill=gold_l)
        elif w == "pistol":
            if is_atk:
                d.line([(hx, hy), (47, hy - (6 if f in (20, 21) else (0 if f in (22, 23) else -6)))], fill=hexc("3e374e"), width=2)
                if f in (21, 22, 23, 24):
                    d.arc([31, max(1, hy - 12), 47, min(47, hy + 10)], -75, 45, fill=hexc("ffd88a"), width=2)
            else:
                d.rectangle([hx, hy - 3, min(47, hx + (8 if is_rng or is_dash else 6)), hy - 1], fill=hexc("3e374e"))
                d.rectangle([hx, hy - 1, hx + 2, hy + 2], fill=hexc("72442a"))
                if is_rng and f in (27, 28, 29):
                    d.polygon([(44, hy - 5), (47, hy - 2), (44, hy + 1), (41, hy - 2)], fill=hexc("fff06a") if f != 28 else hexc("ffffff"))
                elif is_rng and f in (30, 31):
                    d.ellipse([42, max(0, hy - 7 - (f - 30)), 47, max(2, hy - 2 - (f - 30))], fill=hexc("d8dce4", 190))
        elif w == "cane":
            if is_atk:
                d.line([(hx, hy), (47, max(1, min(46, hy - [10, 6, 0, -5, -7, -8][f - 20])))], fill=hexc("6e4228"), width=2)
                if f in (21, 22, 23, 24):
                    d.arc([hx - 2, max(0, hy - 12), 47, min(47, hy + 8)], -65, 45, fill=hexc("ffe88a"), width=2)
            elif is_rng:
                d.line([(hx, hy), (min(47, hx + 9), hy - 2)], fill=hexc("6e4228"), width=2)
                if f in (27, 28, 29):
                    d.ellipse([43, hy - 5, 47, hy - 1], fill=hexc("fff06a") if f != 28 else hexc("ffffff"))
                elif f in (30, 31):
                    d.ellipse([42, max(0, hy - 8 - (f - 30)), 46, max(2, hy - 4 - (f - 30))], fill=hexc("d8dce4", 185))
            else:
                d.line([(hx, hy), (min(47, hx + 7), hy - 5)] if is_dash else [(hx, hy), (min(46, hx + 3), min(46, hy + 13))], fill=hexc("6e4228"), width=2)
                d.point([hx, hy - 1], fill=gold_s)
        elif w == "fan":
            spread = is_atk or is_dash or is_rng
            d.pieslice([hx - 8, max(0, hy - 12), min(47, hx + 8), min(47, hy + 6)], -40 if spread else -100, 40 if spread else -20, fill=hexc("f0ecf8"))
            d.line([(hx, hy - 3), (min(47, hx + 7), hy - 9)], fill=gold_l)
            if f in (21, 22, 23, 24):
                d.arc([hx - 4, max(0, hy - 14), 47, min(47, hy + 8)], -60, 40, fill=hexc("d8f4ff"), width=2)
            elif is_rng and f in (27, 28, 29):
                d.arc([38, max(0, hy - 8), 47, min(47, hy + 8)], -70, 70, fill=hexc("a8f6ff") if f != 28 else hexc("ffffff"), width=2)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=skin)

        if f in (17, 18, 19):  # tia sáng lóe ở windup (14..19)
            gx, gy = min(46, hx + 2), max(1, hy - 6)
            d.point([gx, gy], fill=hexc("fff8a8"))
            if f in (18, 19):
                d.line([(gx - 2, gy), (min(47, gx + 2), gy)], fill=hexc("ffffff"))
                d.line([(gx, max(0, gy - 2)), (gx, min(47, gy + 2))], fill=hexc("ffffff"))
        elif is_dash:
            for sy in (14, 24, 34):
                d.line([(1 + (f % 2) * 2, sy), (8 + (f % 2) * 3, sy)], fill=hexc("e8f4ff"))
        elif is_leap_slam:
            d.arc([4, 34, 44, 47], 190, 350, fill=hexc("ffe87a"), width=2)
        elif is_rage:
            k_r = f - 44
            d.arc([2 + k_r, 34, 46 - k_r, 47], 0, 360, fill=hexc("ff3838") if k_r == 0 else hexc("ffe868"), width=2)
            for ang_i in range(8):
                aa = ang_i * math.tau / 8.0 + 0.25 + k_r * 0.4
                px_f = int(24 + math.cos(aa) * 21)
                py_f = int(24 + math.sin(aa) * 19)
                if 0 <= px_f < 47 and 0 <= py_f < 47:
                    d.point([px_f, py_f], fill=hexc("ff5838") if ang_i % 2 == 0 else hexc("ffe868"))

        # 46..47 chiêu đặc biệt riêng từng trùm
        if is_spec:
            k = f - 46
            if spec == "ham_chi_huy":  # Đờ Cát: hầm chỉ huy bao cát + súng máy
                img, d = canvas(48, 48)
                for row, y in enumerate((34, 28, 22)):
                    for x in range(6 + row * 3, 42 - row * 3, 8):
                        d.ellipse([x, y, x + 9, y + 7], fill=hexc("b0905e"))
                auto_shade(img, hexc("b0905e"), hexc("dcba86"), hexc("6c5636"))
                d.rectangle([16, 14, 32, 22], fill=hexc("2c261a"))
                d.rectangle([18, 16, 30, 20], fill=hexc("120e0a"))
                d.rectangle([22, 17, 26, 19], fill=hexc("d43b34"))
                d.line([(30, 18), (41, 16)], fill=hexc("3e374e"), width=2)
                if k == 0:
                    d.ellipse([41, 14, 46, 19], fill=hexc("fff06a"))
                else:
                    d.ellipse([40, 13, 44, 17], fill=hexc("d0d4dc", 200))
                d.rectangle([14, 12, 34, 14], fill=hexc("5e5e3c"))
            elif spec == "ong_dong":  # Thoát Hoan: chui ống đồng lăn tới
                img, d = canvas(48, 48)
                wob = 0 if k == 0 else 2
                d.ellipse([6 + wob, 18, 42 + wob, 44], fill=hexc("ca8440"))
                d.rectangle([10 + wob, 18, 38 + wob, 44], fill=hexc("ca8440"))
                auto_shade(img, hexc("ca8440"), hexc("f8c280"), hexc("7a4620"))
                d.ellipse([8 + wob, 12, 40 + wob, 26], fill=hexc("7a4620"))
                d.ellipse([12 + wob, 15, 36 + wob, 24], fill=hexc("2a1414"))
                ex_o = 0 if k == 0 else 1
                d.rectangle([20 + wob + ex_o, 14, 21 + wob + ex_o, 17], fill=hexc("ffffff"))
                d.rectangle([26 + wob + ex_o, 14, 27 + wob + ex_o, 17], fill=hexc("ffffff"))
                d.point([21 + wob + ex_o, 16], fill=dark)
                d.point([27 + wob + ex_o, 16], fill=dark)
                for y in (28, 36):
                    d.line([10 + wob, y, 38 + wob, y], fill=gold_l, width=2)
            elif spec == "tran_khien":  # Lục Dận: dựng trận khiên Đông Ngô
                sx = 29 + k
                d.polygon([(sx, 14), (sx + 13, 18), (sx + 13, 38), (sx, 43), (sx - 2, 28)], fill=gold_d)
                d.polygon([(sx + 2, 16), (sx + 11, 19), (sx + 11, 37), (sx + 2, 40)], fill=hexc("3c8650"))
                d.ellipse([sx + 3, 25, sx + 9, 31], fill=gold_l)
                d.arc([sx - 3, 12, 47, 45], -60, 60, fill=hexc("fff088") if k == 0 else hexc("7cf8a0"), width=2)
            elif spec == "thuy_quai":  # Hoằng Tháo: sóng thủy quái dâng cuộn
                d.ellipse([3, 35 - k * 2, 45, 46], fill=hexc("1f6ca8", 210))
                d.arc([4, 28 - k * 3, 22, 44], 180, 350, fill=hexc("8ef6ff"), width=2)
                d.arc([26, 26 - (1 - k) * 3, 44, 44], 190, 360, fill=hexc("8ef6ff"), width=2)
            elif spec == "mua_ten":  # Quách Quỳ: giương cung bắn mưa tên lên trời
                d.arc([23, 8, 37, 28], -80, 80, fill=gold_l, width=2)
                for ax_off in (0, 6, 12):
                    y_arr = 14 - k * 5 - (ax_off % 5)
                    if y_arr > 2:
                        d.line([(29 + ax_off, y_arr), (32 + ax_off, max(0, y_arr - 7))], fill=steel_s, width=1)
                        d.point([32 + ax_off, max(0, y_arr - 7)], fill=hexc("fff06a"))
            elif spec == "sa_lay":  # Liễu Thăng: sa lầy bùn đất Ải Chi Lăng
                d.ellipse([4, 34, 44, 46], fill=hexc("523a24"))
                d.ellipse([7, 36, 41, 44], fill=hexc("3a2618"))
                for mx in (9, 17, 31, 39):
                    d.point([mx, 32 - k * 3], fill=hexc("8a643c"))
                    d.point([mx + 1, 30 - k * 2], fill=hexc("c29c6a"))
            elif spec == "tron_chay":  # Tô Định: tung áo choàng & dấu vết trốn chạy
                for dx_s in (4, 8, 12):
                    d.ellipse([dx_s + k * 2, 36, dx_s + 5 + k * 2, 42], fill=hexc("d8d0c4", 180))
                d.ellipse([34, 33 + k, 38, 37 + k], fill=gold_s)
            elif spec == "bo_chay":  # Tôn Sĩ Nghị: rơi ấn & khói chạy trối chết
                d.rectangle([34, 37 + k, 39, 41 + k], fill=gold_l)
                d.ellipse([36 + k * 2, 30, 42 + k * 2, 36], fill=hexc("e8e0d4", 170))
            elif spec == "phao_kich":  # Đồn trưởng: bắn pháo hiệu gọi pháo kích
                fy_fl = 8 - k * 4
                d.ellipse([35, max(0, fy_fl), 41, max(4, fy_fl + 5)], fill=hexc("ff3838"))
                d.point([38, max(1, fy_fl + 2)], fill=hexc("fff688"))
                d.arc([8, 36, 40, 46], 0, 360, fill=hexc("ff7040"), width=1)

        frames.append(polish(img))
    return frames


def ship_frames():
    """Tàu chiến Hy Vọng (64x44 x 48 khung lưới 12x4): 0-5 idle, 6-13 rẽ sóng, 14-19 nạp pháo, 20-25 húc quét,
    26-31 đại bác mạn tàu, 32-35 đèn hiệu triệu hồi, 36-39 lao húc, 40-43 vượt sóng đập xuống, 44-45 quá tải, 46-47 bốc cháy."""
    h_deep, hd, hull, hl, _ = hue_ramp("623e24")
    fr = []
    for f in range(48):
        img, d = canvas(64, 44)
        is_idle = f < 6
        is_walk = 6 <= f < 14
        is_wind = 14 <= f < 20
        is_melee = 20 <= f < 26
        is_rng = 26 <= f < 32
        is_cast = 32 <= f < 36
        is_dash = 36 <= f < 40
        is_leap = 40 <= f < 44
        is_rage = f in (44, 45)
        is_spec = f >= 46

        w = (f % 6) if is_idle else ((f - 6) % 8 if is_walk else 0)
        if is_idle:
            bob = [0, 0, -1, -1, 0, 0][f]
            sail_bulge = [0, 1, 2, 2, 1, 0][f]
            wake = [0, 1, 1, 2, 1, 0][f]
        elif is_walk:
            bob = [0, 1, 1, 0, -1, -1, 0, 0][w]
            sail_bulge = [0, 2, 3, 2, 1, -1, -1, 0][w]
            wake = [0, 1, 3, 4, 3, 2, 1, 0][w]
        elif is_wind:
            k = f - 14
            bob = [0, 1, 1, 1, 0, 0][k]
            sail_bulge = [1, 2, 2, 3, 4, 4][k]
            wake = 1 + k // 2
        elif is_melee:
            k = f - 20
            bob = [0, 0, 1, 1, 0, 0][k]
            sail_bulge = [3, 4, 5, 5, 3, 2][k]
            wake = [2, 3, 4, 5, 3, 2][k]
        elif is_rng:
            k = f - 26
            bob = [0, 1, 1, 2, 1, 0][k]
            sail_bulge = [2, 3, 4, 5, 4, 3][k]
            wake = 2
        elif is_cast:
            k = f - 32
            bob = [-1, 0, -1, 0][k]
            sail_bulge = [2, 3, 2, 3][k]
            wake = 1 + k
        elif is_dash:
            k = f - 36
            bob = [1, 0, 0, 1][k]
            sail_bulge = [5, 6, 6, 4][k]
            wake = 5
        elif is_leap:
            k = f - 40
            bob = [2, -3, -5, 2][k]
            sail_bulge = [1, 4, 5, 3][k]
            wake = [1, 0, 0, 5][k]
        elif is_rage:
            bob = -1 if f == 44 else 0
            sail_bulge = 5
            wake = 4
        else:
            bob = 0 if f == 46 else 1
            sail_bulge = 3
            wake = 2

        water_y = 34 + max(-2, min(2, bob))
        d.ellipse([0, water_y, 63, min(43, water_y + 9)], fill=hexc("286cb0", 165))
        d.arc([2 + wake, water_y + 1, 61, min(43, water_y + 8)], 10, 170, fill=hexc("a8e6ff"), width=1)
        if is_cast:
            d.arc([4, 32, 60, 42], 0, 360, fill=hexc("5ef0ff") if f % 2 == 0 else hexc("fff088"), width=1)
        if is_melee or is_dash or f == 43:
            d.line([(55, 33 + bob), (63, 29 + bob)], fill=hexc("ffffff"), width=2)
            d.line([(54, 37 + bob), (63, 36 + bob)], fill=hexc("bce8ff"), width=1)
        if is_melee and f in (21, 22, 23, 24):
            d.arc([46, 18 + bob, 63, 36 + bob], -75, 65, fill=hexc("ffffff"), width=2)
        if f == 43:
            d.arc([2, 32, 22, 43], 180, 330, fill=hexc("d8f8ff"), width=2)
            d.arc([42, 32, 62, 43], 210, 360, fill=hexc("d8f8ff"), width=2)

        d.polygon([(2, 26 + bob), (62, 26 + bob), (56, 38 + bob), (8, 38 + bob)], fill=hull)
        auto_shade(img, hull, hl, hd)
        d.line([(5, 29 + bob), (59, 29 + bob)], fill=h_deep)
        d.line([(4, 27 + bob), (60, 27 + bob)], fill=hexc("f0ecf8"))
        d.polygon([(59, 25 + bob), (63, 22 + bob), (60, 28 + bob)], fill=hexc("f0b848"))
        for x in (14, 26, 38, 50):
            d.rectangle([x, 30 + bob, x + 3, 32 + bob], fill=hexc("1a1210"))
            port_c = hexc("ff5828") if (is_wind or is_rage) else hexc("a86826")
            d.point([x + 1, 31 + bob], fill=port_c)
            if is_wind and f in (18, 19):
                d.point([x + 2, 31 + bob], fill=hexc("fff688") if f == 18 else hexc("ffffff"))
            if is_rng and f in (26, 27, 28, 29):
                if f in (26, 27):
                    d.point([x + 1, 33 + bob], fill=hexc("ffaa30") if f == 26 else hexc("fff06a"))
                else:
                    r_f = 5 if f == 29 else 3
                    d.ellipse([x - 1, 32 + bob, x + r_f, 32 + bob + r_f], fill=hexc("ff8c24"))
                    d.ellipse([x, 33 + bob, x + r_f - 1, 32 + bob + r_f - 1], fill=hexc("fff688"))
            elif is_rng and f in (30, 31):
                off_s = f - 30
                d.ellipse([x - 1, 31 + bob - off_s, x + 4, 36 + bob - off_s], fill=hexc("d0d4dc", 190))

        mast_top = max(1, 2 + bob)
        d.line([(24, 26 + bob), (24, mast_top)], fill=hexc("3a2214"), width=2)
        d.line([(24, mast_top + 1), (42 + sail_bulge, 24 + bob)], fill=hexc("b8a890"))
        d.polygon([(25, mast_top + 2), (40 + sail_bulge, mast_top + 6), (40 + sail_bulge, 22 + bob), (25, 24 + bob)], fill=hexc("f2eee2"))
        d.line([(25, 14 + bob), (40 + sail_bulge, 15 + bob)], fill=hexc("c8c4b4"))
        d.rectangle([44, 14 + bob, 48, 26 + bob], fill=hexc("2c2622"))
        d.line([(44, 15 + bob), (48, 15 + bob)], fill=hexc("ff6430") if is_rage else hexc("d48c44"))
        sx = 42 - (w if is_walk else (6 if is_dash else 4))
        d.ellipse([sx, 8 + bob - (f % 2), sx + 8, 14 + bob - (f % 2)], fill=hexc("ff8c38" if is_rage else "726878", 195))
        if is_dash:
            for sy in (14, 20, 30):
                d.line([(1 + (f % 2) * 3, sy), (9 + (f % 2) * 3, sy)], fill=hexc("e8f4ff"))
        flag_y = mast_top
        d.rectangle([22, flag_y, 30, flag_y + 4], fill=hexc("2a3a8a"))
        d.rectangle([24, flag_y, 26, flag_y + 4], fill=hexc("ffffff"))
        d.rectangle([28, flag_y, 30, flag_y + 4], fill=hexc("c83a32"))
        if is_cast:
            d.ellipse([21, max(0, flag_y - 4), 27, flag_y + 2], fill=hexc("64f4ff") if f % 2 == 0 else hexc("fff06a"))
        if is_rage:
            for rx_b, ry_b in ((10, 12), (54, 14), (16, 6), (48, 8)):
                d.point([rx_b, ry_b], fill=hexc("ff6830") if f == 44 else hexc("ff2828"))
                d.point([rx_b, ry_b + 1], fill=hexc("fff06a"))
        if is_spec:
            for idx_x, x in enumerate(range(8, 58, 7)):
                fh = 15 + ((idx_x + f) % 3) * 4
                d.polygon([(x, 27 + bob), (x + 3, max(1, 27 + bob - fh + 3)), (x + 6, 27 + bob)], fill=hexc("ff7020"))
                d.polygon([(x + 2, 27 + bob), (x + 3, max(2, 27 + bob - fh // 2)), (x + 4, 27 + bob)], fill=hexc("fff06a"))
            d.polygon([(26, 16 + bob), (31, 7 + bob + (f % 2) * 2), (36, 16 + bob)], fill=hexc("ff8428"))
        fr.append(polish(img))
    save(sheet_grid(fr, cols=12), "enemies/boss_tau_hy_vong.png")


def build():
    tank_frames()
    chan_tinh_frames()
    dai_bang_frames()
    ma_troi_frames()
    tieu_yeu_frames()
    ho_tinh_frames()
    moc_tinh_frames()
    ngu_tinh_frames()
    ship_frames()
    save(sheet(cavalry_frames()), "enemies/nguyen_mong_ky_binh.png")
    for bid, cfg in BOSSES.items():
        save(sheet_grid(boss_frames(cfg), cols=12), f"enemies/boss_{bid}.png")


if __name__ == "__main__":
    build()
