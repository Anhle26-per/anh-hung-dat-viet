"""Quân xâm lược, quái tinh nhuệ 16 khung và 10 trùm lịch sử 36 khung siêu mượt.

- Mọi lính & quái nhỏ: 16 khung (0-7 đi bộ 8 nhịp, 8-9 lấy đà, 10-13 tấn công 4 nhịp, 14-15 trúng đòn).
- Trùm (48x48, tàu 64x44): 36 khung (0-3 idle, 4-11 walk, 12-15 windup, 16-19 melee_sweep,
  20-23 ranged_shot, 24-27 cast_summon, 28-29 dash, 30-32 leap, 33 rage, 34-35 special).
"""
import math
from px import hexc, grid, polish, sheet, save, canvas, auto_shade, hue_ramp

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
    """Kỵ binh Nguyên Mông (34x30 x 16 khung): 0-7 phi nước đại, 8-9 giương giáo, 10-13 đâm chớp giáo, 14-15 trúng đòn."""
    a = ARMIES["nguyen_mong"]
    p = army_pal(a)
    hd, h_dark, horse, hl, _ = hue_ramp("845234")
    frames = []
    rider = grid(a["hat"], p, 20)
    face = grid(FACE, p, 20)
    body = grid(BODY[:3], p, 20)
    for f in range(16):
        img, d = canvas(34, 30)
        t = f % 8
        lift = [0, 1, 2, 1, 0, 1, 2, 1][t] if f < 8 else (1 if f in (8, 9, 12, 13) else (0 if f in (10, 11) else -1))
        legs = [
            (0, 3), (1, 2), (2, 1), (3, 1),
            (3, 0), (2, 0), (1, 1), (0, 2),
        ][t] if f < 8 else ((0, 2) if f in (8, 9) else ((3, 0) if f in (10, 11) else (1, 2)))
        dx = -1 if f in (8, 9, 14) else (2 if f in (10, 11) else 0)
        for x, k in ((7, 0), (11, 1), (21, 0), (25, 1)):
            off = legs[k]
            d.line([x + dx, 19 - lift, x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=h_dark if k else horse, width=2)
            d.point([x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=hd)
        d.ellipse([4 + dx, 12 - lift, 28 + dx, 22 - lift], fill=horse)
        d.polygon([(24 + dx, 14 - lift), (29 + dx, 5 - lift), (33 + dx, 7 - lift), (31 + dx, 10 - lift), (28 + dx, 17 - lift)], fill=horse)
        auto_shade(img, horse, hl, h_dark)
        d.line([(27 + dx, 6 - lift), (23 + dx, 13 - lift)], fill=hexc("2b2230"), width=2)
        d.line([(5 + dx, 14 - lift), (max(0, 1 + dx), 20 - lift + (f % 2))], fill=hexc("2b2230"), width=2)
        d.point([min(33, 31 + dx), 7 - lift], fill=hexc("ffe060") if f in (8, 9, 10, 11) else hexc("1a1222"))
        d.rectangle([12 + dx, 11 - lift, 20 + dx, 13 - lift], fill=hexc("ca3e3e"))
        d.line([(13 + dx, 12 - lift), (19 + dx, 12 - lift)], fill=hexc("f0b848"))
        img.alpha_composite(rider, (max(0, 6 + dx), max(0, 0 - lift)))
        img.alpha_composite(face, (max(0, 6 + dx), max(0, 5 - lift)))
        img.alpha_composite(body, (max(0, 6 + dx), max(0, 10 - lift)))
        if f in (8, 9):
            ox = -1 if f == 9 else 0
            d.line([(13 + ox, 8), (22 + ox, 6)], fill=hexc("9c6436"), width=2)
            d.polygon([(22 + ox, 5), (26 + ox, 5), (22 + ox, 7)], fill=hexc("ffffff"))
        elif f in (10, 11):
            d.line([(15, 11), (32, 10)], fill=hexc("9c6436"), width=2)
            d.polygon([(30, 8), (33, 10), (30, 12)], fill=hexc("ffffff"))
            if f == 11:
                d.line([(25, 7), (33, 10)], fill=hexc("9eeeff"))
        elif f in (12, 13):
            d.line([(18, 12), (28, 14 if f == 12 else 15)], fill=hexc("9c6436"), width=1)
            d.point([29, 14 if f == 12 else 15], fill=hexc("dce2f0"))
        else:
            d.line([(19 + dx, 2 - lift), (19 + dx, 14 - lift)], fill=hexc("9c6436"))
            d.line([(19 + dx, 0 - lift), (19 + dx, 2 - lift)], fill=hexc("ffffff"))
        if f in (14, 15):
            d.ellipse([21, 5, 25, 9], fill=hexc("ff6060") if f == 14 else hexc("ffaa60"))
        frames.append(polish(img))
    return frames


def tank_frames():
    """Xe tăng Pháp 1954 (40x30 x 16 khung): 0-7 lăn xích mượt, 8-9 khóa nòng, 10-13 giật bắn & nhả khói, 14-15 trúng đòn."""
    bd_deep, bd, body, bl, bspec = hue_ramp("6a6c3c")
    fr = []
    for f in range(16):
        img, d = canvas(40, 30)
        recoil = -3 if f == 11 else (-2 if f == 10 else (-1 if f in (12, 14) else 0))
        d.rectangle([3, 18, 37, 26], fill=hexc("28291d"))
        for x in range(5, 37, 5):
            cx = x + ((f % 3) if f < 8 else 0)
            if cx <= 36:
                d.ellipse([cx - 2, 20, cx + 2, 25], fill=hexc("5e604c"))
                d.point([cx, 22], fill=hexc("8c8e72"))
        d.polygon([(4, 18), (8, 11), (34, 11), (37, 18)], fill=body)
        auto_shade(img, body, bl, bd)
        d.line([(9, 12), (33, 12)], fill=bspec)
        for rx in (10, 16, 22, 28, 33):
            d.point([rx, 16], fill=bd_deep)
        d.ellipse([12 + recoil, 4, 28 + recoil, 14], fill=body)
        d.rectangle([15 + recoil, 3, 21 + recoil, 5], fill=bl)
        d.rectangle([26 + recoil, 7, 36 + recoil, 9], fill=bd)
        d.rectangle([35 + recoil, 6, 37 + recoil, 10], fill=bd_deep)
        d.rectangle([16 + recoil, 6, 19 + recoil, 8], fill=bspec)
        if f in (8, 9):
            d.point([37, 8], fill=hexc("ffe86a") if f == 9 else hexc("ffaa30"))
        elif f in (10, 11):
            d.polygon([(35, 4 if f == 11 else 5), (39, 8), (35, 12 if f == 11 else 11), (33, 8)], fill=hexc("ff6820"))
            d.polygon([(35, 6), (39, 8), (35, 10)], fill=hexc("fff68a"))
            if f == 11:
                d.point([38, 8], fill=hexc("ffffff"))
        elif f in (12, 13):
            ox = 34 if f == 12 else 31
            oy = 4 if f == 12 else 2
            d.ellipse([ox, oy, ox + 4, oy + 4], fill=hexc("c8ccd4", 200))
            d.ellipse([ox - 3, max(0, oy - 2), ox + 1, oy + 1], fill=hexc("e8ecf0", 160))
        elif f in (14, 15):
            d.line([(16, 6), (22, 11)], fill=hexc("ffaa30") if f == 14 else hexc("ffd880"))
            if f == 14:
                d.point([18, 8], fill=hexc("ffffff"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/xe_tang.png")


def chan_tinh_frames():
    """Chằn tinh (30x32 x 16 khung): 0-7 bước nện nặng, 8-9 vung chùy, 10-13 đập đất rung chấn, 14-15 choáng."""
    _, sd, sk, sl, _ = hue_ramp("6a8f58")
    fr = []
    for f in range(16):
        img, d = canvas(30, 32)
        bob = [0, 0, -1, -1, 0, 0, -1, 0, -1, -2, 1, 2, 1, 0, -1, 0][f]
        lo = [(0, 2), (1, 2), (1, 1), (2, 1), (2, 0), (1, 0), (1, 1), (0, 1)][f] if f < 8 else ((0, 0) if f in (8, 9, 13) else (2, 2))
        dx = -1 if f in (8, 9, 14) else (1 if f in (10, 11) else 0)
        d.rectangle([9 + dx, 24, 13 + dx, 30 - lo[0]], fill=sd)
        d.rectangle([17 + dx, 24, 21 + dx, 30 - lo[1]], fill=sk)
        d.ellipse([5 + dx, 10 + bob, 25 + dx, 27 + bob], fill=sk)
        d.ellipse([8 + dx, 2 + bob, 22 + dx, 15 + bob], fill=sk)
        auto_shade(img, sk, sl, sd)
        d.rectangle([7 + dx, 20 + bob, 23 + dx, 24 + bob], fill=hexc("7a482c"))
        d.rectangle([13 + dx, 20 + bob, 17 + dx, 24 + bob], fill=hexc("e8dcc0"))
        d.point([14 + dx, 22 + bob], fill=hexc("241410"))
        d.point([16 + dx, 22 + bob], fill=hexc("241410"))
        d.polygon([(9 + dx, 4 + bob), (6 + dx, max(0, 0 + bob)), (12 + dx, 3 + bob)], fill=hexc("efe4cc"))
        d.polygon([(21 + dx, 4 + bob), (24 + dx, max(0, 0 + bob)), (18 + dx, 3 + bob)], fill=hexc("efe4cc"))
        eye_c = hexc("fff060") if f in (8, 9, 10, 11) else hexc("ff3828")
        d.rectangle([11 + dx, 7 + bob, 12 + dx, 8 + bob], fill=eye_c)
        d.rectangle([17 + dx, 7 + bob, 18 + dx, 8 + bob], fill=eye_c)
        mh = 3 if f in (8, 9, 10, 11) else 1
        d.rectangle([12 + dx, 12 + bob, 18 + dx, 12 + bob + mh], fill=hexc("2a1414"))
        d.point([12 + dx, 12 + bob], fill=hexc("ffffff"))
        d.point([17 + dx, 12 + bob], fill=hexc("ffffff"))
        if f in (8, 9):
            cy_c = 5 if f == 8 else 2
            d.line([(20, 12), (24, cy_c)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([21, max(0, cy_c - 2), 27, cy_c + 4], fill=hexc("5a3a22"))
            if f == 9:
                d.point([24, cy_c], fill=hexc("dce2f0"))
        elif f in (10, 11):
            d.line([(22, 17), (28, 25 if f == 11 else 21)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, 22 if f == 11 else 18, 29, 27 if f == 11 else 23], fill=hexc("5a3a22"))
            if f == 11:
                d.arc([16, 12, 29, 27], -45, 45, fill=hexc("fff088"), width=2)
        elif f in (12, 13):
            wy = 19 if f == 12 else 15
            d.line([(24, 19), (28, wy)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, wy - 3, 29, wy + 2], fill=hexc("5a3a22"))
        elif f >= 14:
            d.line([(6, 15), (3, 21)], fill=hexc("7a4a2e"), width=2)
            if f == 14:
                d.point([10, 3], fill=hexc("ffffff"))
        else:
            wy = [11, 10, 9, 10, 11, 12, 11, 10][f]
            d.line([(24, 16 + bob), (28, wy + bob)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, wy - 5 + bob, 29, wy + bob], fill=hexc("5a3a22"))
            d.point([27, wy - 3 + bob], fill=hexc("dce2f0"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/chan_tinh.png")


def dai_bang_frames():
    """Đại bàng tinh (36x26 x 16 khung): 0-7 vỗ cánh 8 nhịp, 8-9 xếp cánh, 10-13 lao vút, 14-15 xù lông."""
    _, bd, br, bl, _ = hue_ramp("825432")
    fr = []
    for f in range(16):
        img, d = canvas(36, 26)
        wing = [-8, -6, -3, 1, 5, 2, -2, -6][f] if f < 8 else ([-5, -7, 4, 7, 1, -4, 3, 1][f - 8])
        dx = -2 if f in (8, 9) else (2 if f in (10, 11) else (-1 if f >= 14 else 0))
        d.polygon([(16 + dx, 12), (2 + dx, 12 + wing), (8 + dx, 15), (16 + dx, 16)], fill=br)
        d.polygon([(20 + dx, 12), (34 + dx, 12 + wing), (28 + dx, 15), (20 + dx, 16)], fill=br)
        d.line([(4 + dx, 12 + wing), (14 + dx, 13)], fill=hexc("f0b848"))
        d.line([(32 + dx, 12 + wing), (22 + dx, 13)], fill=hexc("f0b848"))
        d.ellipse([12 + dx, 9, 24 + dx, 21], fill=br)
        auto_shade(img, br, bl, bd)
        d.ellipse([20 + dx, 5, 28 + dx, 13], fill=hexc("cc9a54"))
        d.line([(21 + dx, 7), (25 + dx, 6)], fill=hexc("ffe496"))
        d.polygon([(27 + dx, 8), (33 + dx, 10), (27 + dx, 11)], fill=hexc("f4b632"))
        d.point([24 + dx, 8], fill=hexc("ff3030") if f in (8, 9, 10, 11) else hexc("1a1222"))
        tx = 4 if f in (10, 11) else 0
        d.line([(15 + dx, 21), (14 + dx + tx, 24)], fill=hexc("f4b632"))
        d.line([(20 + dx, 21), (21 + dx + tx, 24)], fill=hexc("f4b632"))
        if f in (10, 11):
            d.line([(2, 8), (11, 8)], fill=hexc("e0f8ff"))
            if f == 11:
                d.line([(1, 16), (10, 16)], fill=hexc("ffffff"))
        elif f >= 14:
            d.point([18, 4], fill=hexc("ffffff"))
            if f == 14:
                d.point([16, 6], fill=hexc("ff5050"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/dai_bang.png")


def ma_troi_frames():
    """Ma trơi (14x18 x 16 khung): ngọn lửa ma uốn lượn liên tục."""
    fr = []
    for f in range(16):
        img, d = canvas(14, 18)
        h = [0, 0, 1, 2, 2, 1, 0, 0, 0, -1, -1, 0, 1, 2, 1, 2][f]
        tip_dx = [0, 1, 1, 0, 0, -1, -1, 0, 0, 0, 1, -1, 0, 1, -1, 1][f]
        outer = hexc("b84aff", 210) if f >= 14 else hexc("4aa8ff", 210)
        mid = hexc("78d8ff", 230) if f < 14 else hexc("e088ff", 220)
        core = hexc("ffffff") if f in (10, 11) else hexc("d6f8ff")
        d.polygon([(2, 12), (7 + tip_dx, max(0, 1 + h)), (12, 12)], fill=outer)
        d.ellipse([2, 7, 12, 16], fill=outer)
        d.ellipse([3, 8, 11, 15], fill=mid)
        d.ellipse([5, 10, 9, 14], fill=core)
        d.point([5, 11], fill=hexc("1a2248"))
        d.point([8, 11], fill=hexc("1a2248"))
        if f in (9, 10, 11):
            d.point([3, 4], fill=hexc("a8f0ff"))
            if f == 11:
                d.point([11, 5], fill=hexc("ffffff"))
        fr.append(img)
    save(sheet(fr), "enemies/ma_troi.png")


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
    for f in range(36):
        img, d = canvas(48, 48)
        if f < 4:  # 0..3 idle: nhịp thở, áo choàng bay, ánh kim vũ khí
            k = f
            bob = [0, -1, -1, 0][k]
            lean = [0, 0, 1, 0][k]
            cape_sway = [0, 1, 2, 1][k]
            cape_flare = [0, 0, 1, 0][k]
            leg_l = [(-2, 0), (-2, 0), (-1, 0), (-2, 0)][k]
            leg_r = [(2, 0), (2, 0), (3, 0), (2, 0)][k]
            arm_l = [(-1, 0), (-1, -1), (-2, -1), (-1, 0)][k]
            arm_r = [(1, 0), (1, -1), (2, -1), (1, 0)][k]
        elif f < 12:  # 4..11 walk: 8 nhịp sải bước
            t = f - 4
            bob = [0, -1, -2, -1, 0, -1, -2, -1][t]
            lean = [0, 1, 1, 0, 0, -1, -1, 0][t]
            cape_sway = [1, 2, 3, 2, -1, -2, -3, -2][t]
            cape_flare = [0, 0, 1, 0, 0, 0, 1, 0][t]
            leg_l = [(1, 0), (3, -1), (4, -3), (2, -1), (-1, -1), (-3, 0), (-4, -1), (-2, 0)][t]
            leg_r = [(-1, -1), (-3, 0), (-4, -1), (-2, 0), (1, 0), (3, -1), (4, -3), (2, -1)][t]
            arm_l = [(-1, 0), (-2, -1), (-3, -1), (-2, 0), (1, 0), (2, 1), (3, 1), (2, 0)][t]
            arm_r = [(1, 0), (2, -1), (3, -2), (1, -1), (-1, 0), (-2, 0), (-3, 1), (-1, 1)][t]
        elif f < 16:  # 12..15 windup: khom người, giơ cao vũ khí, mắt lóe sáng
            k = f - 12
            bob = [0, 1, 2, 1][k]
            lean = [-1, -2, -3, -2][k]
            cape_sway = [1, 2, 3, 4][k]
            cape_flare = [1, 2, 2, 3][k]
            leg_l, leg_r = (-3, 0), (3, -1)
            arm_l = [(-1, -1), (-3, -2), (-4, -3), (-5, -4)][k]
            arm_r = [(-2, -1), (-4, -3), (-5, -5), (-4, -6)][k]
        elif f < 20:  # 16..19 melee_sweep: chém quét rộng
            k = f - 16
            bob = [0, 1, 1, 0][k]
            lean = [2, 3, 3, 1][k]
            cape_sway = [-4, -6, -5, -2][k]
            cape_flare = [2, 3, 3, 1][k]
            leg_l, leg_r = (-5, 0), (5, -1)
            arm_l = [(-4, -2), (-5, -2), (-4, -1), (-2, 0)][k]
            arm_r = [(3, -3), (5, -2), (4, 1), (2, 2)][k]
        elif f < 24:  # 20..23 ranged_shot: ngắm bắn / phóng chiêu + giật nảy
            k = f - 20
            bob = [0, 0, 1, 0][k]
            lean = [1, 2, -1, 0][k]
            cape_sway = [-1, -2, 2, 1][k]
            cape_flare = [1, 2, 2, 1][k]
            leg_l, leg_r = (-3, 0), (4, 0)
            arm_l = [(2, -2), (3, -2), (1, -3), (0, -1)][k]
            arm_r = [(4, -2), (5, -2), (2, -3), (3, -1)][k]
        elif f < 28:  # 24..27 cast_summon: giơ ấn / trượng triệu hồi & vòng phép
            k = f - 24
            bob = [0, -1, -2, -1][k]
            lean = [0, -1, 0, 0][k]
            cape_sway = [-2, 2, -3, 3][k]
            cape_flare = [2, 3, 4, 3][k]
            leg_l, leg_r = (-2, 0), (2, 0)
            arm_l = [(-3, -4), (-4, -6), (-5, -7), (-3, -5)][k]
            arm_r = [(2, -3), (3, -5), (4, -6), (2, -4)][k]
        elif f < 30:  # 28..29 dash: lao húc tốc độ cao
            k = f - 28
            bob = [1, 0][k]
            lean = 4
            cape_sway = [-7, -6][k]
            cape_flare = [4, 3][k]
            leg_l = (-5, -1) if k == 0 else (-2, -2)
            leg_r = (5, -2) if k == 0 else (2, 0)
            arm_l, arm_r = (-5, -1), (6, -1)
        elif f < 33:  # 30..32 leap: khom -> bật nhảy cao -> đập đất
            k = f - 30
            bob = [2, -4, 2][k]
            lean = [0, 1, 2][k]
            cape_sway = [1, -3, -4][k]
            cape_flare = [2, 4, 4][k]
            leg_l = (-3, 0) if k == 0 else ((-3, -3) if k == 1 else (-4, 0))
            leg_r = (3, 0) if k == 0 else ((3, -3) if k == 1 else (4, 0))
            arm_l = [(-3, -1), (-5, -6), (-4, 2)][k]
            arm_r = [(2, -1), (4, -6), (5, 3)][k]
        elif f == 33:  # 33 rage: gầm rú bùng nổ
            bob = -2
            lean = 0
            cape_sway = 0
            cape_flare = 4
            leg_l, leg_r = (-2, 0), (2, 0)
            arm_l, arm_r = (-6, -6), (5, -5)
        else:  # 34..35 special: thế chiêu đặc biệt riêng từng trùm
            k = f - 34
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

        is_idle = f < 4
        is_wind = 12 <= f < 16
        is_atk = 16 <= f < 20
        is_rng = 20 <= f < 24
        is_cast = 24 <= f < 28
        is_dash = f in (28, 29)
        is_leap_air = f == 31
        is_leap_slam = f == 32
        is_rage = f == 33
        is_spec = f >= 34

        if is_cast:
            rc = gold_l if f % 2 == 0 else hexc("5ef0ff")
            d.arc([4, 37, 44, 46], 0, 360, fill=rc, width=1)
            for rx_p, ry_p in ((8, 39), (39, 39), (14, 44), (34, 44)):
                d.point([rx_p, ry_p - (f - 24)], fill=gold_s)

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
            seal_c = hexc("64f4ff") if f in (25, 27) else gold_s
            d.ellipse([lhx - 3, max(1, lhy - 4), lhx + 3, lhy + 2], fill=seal_c)
            d.point([lhx, max(1, lhy - 2)], fill=hexc("ffffff"))

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
            eye = hexc("ff2838")
        elif is_wind:
            eye = hexc("fff890") if f == 15 else hexc("ffaa38")
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
            hat_dx = -4 if f == 34 else -7
            hat_dy = -1 if f == 34 else 3
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

        # Vũ khí theo từng pha hành động (0-3 idle, 4-11 walk, 12-15 windup, 16-19 melee, 20-23 ranged, 24-27 cast, 28-29 dash, 30-32 leap, 33 rage, 34-35 special)
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
                atk_y = [10, 22, 34, 38][f - 16]
                top = (47, atk_y)
            else:
                top = (min(46, hx + (1 if is_wind else 6)), max(1, hy - (28 if is_wind else 25)))
            d.line([(max(2, hx - 4), min(46, hy + 10)), top], fill=hexc("6a4028"), width=2)
            d.polygon([(max(1, top[0] - 4), top[1]), (min(47, top[0] + 1), max(0, top[1] - 2)), (min(47, top[0] + 1), min(47, top[1] + 6)), (max(0, top[0] - 5), min(47, top[1] + 4))], fill=steel)
            d.line([(top[0], max(0, top[1] - 1)), (top[0], min(47, top[1] + 5))], fill=steel_s)
            if f in (16, 17, 18):
                d.arc([30, 5, 47, 38], -80, 55 if f >= 17 else 5, fill=hexc("ffffff"), width=2)
            elif is_rng and f in (21, 22):
                d.polygon([(43, hy - 3), (47, hy), (43, hy + 3), (39, hy)], fill=hexc("fff078"))
            elif is_idle and f in (1, 2):
                d.point([min(47, top[0]), max(0, top[1] + (f - 1) * 2)], fill=hexc("ffffff"))
        elif w == "trident":
            if is_dash or is_rng:
                top = (47, hy)
            elif is_leap_air or is_cast:
                top = (hx, 1)
            elif is_leap_slam:
                top = (47, 40)
            elif is_atk:
                top = (47, [12, 22, 32, 36][f - 16])
            else:
                top = (min(46, hx + (2 if is_wind else 4)), max(1, hy - 28))
            d.line([(max(2, hx - 2), min(46, hy + 8)), top], fill=gold_d, width=2)
            for dx_t in (-3, 0, 3):
                d.line([(min(47, max(0, top[0] + dx_t)), min(47, top[1] + 5)), (min(47, max(0, top[0] + dx_t)), top[1])], fill=gold_s if dx_t == 0 else gold)
            d.line([(max(0, top[0] - 3), min(47, top[1] + 5)), (min(47, top[0] + 3), min(47, top[1] + 5))], fill=gold_l)
            if f in (16, 17, 18):
                d.line([(hx + 2, hy - 4), (47, hy - 8)], fill=hexc("a8f4ff"), width=2)
            elif is_rng and f in (21, 22):
                d.ellipse([42, hy - 3, 47, hy + 3], fill=hexc("7ef6ff"))
            elif is_idle and f in (1, 2):
                d.point([min(47, top[0]), max(0, top[1] + f)], fill=hexc("ffffff"))
        elif w == "saber":
            if is_dash or is_rng:
                d.line([(hx, hy), (47, hy - (1 if is_rng else 0))], fill=steel_s, width=2)
                if is_rng and f in (21, 22):
                    d.arc([39, max(0, hy - 6), 47, min(47, hy + 6)], -70, 70, fill=hexc("ffaa44"), width=2)
            elif is_leap_air or is_cast:
                d.line([(hx, hy), (hx - 2, max(1, hy - 16))], fill=steel_s, width=2)
            elif is_leap_slam:
                d.line([(hx, hy), (47, 41)], fill=steel_s, width=2)
            elif is_atk:
                ang_dy = [10, 4, -6, -9][f - 16]
                d.line([(hx, hy), (47, max(1, min(46, hy - ang_dy)))], fill=steel_s, width=2)
                if f in (16, 17, 18):
                    d.arc([28, max(1, hy - 16), 47, min(47, hy + 12)], -80, 45 if f >= 17 else 0, fill=hexc("ffffff"), width=2)
            else:
                tip_x = min(46, max(4, hx + (2 if is_wind else 7) + arm_r[0]))
                tip_y = max(2, hy - (16 if is_wind else 14))
                d.line([(hx, hy), (tip_x, tip_y)], fill=steel, width=2)
                d.point([tip_x, tip_y - 1], fill=steel_s)
                if is_idle and f in (1, 2):
                    d.point([(hx + tip_x) // 2, (hy + tip_y) // 2], fill=hexc("ffffff"))
            d.line([(hx - 2, hy + 1), (hx + 2, hy - 1)], fill=gold_l)
        elif w == "pistol":
            if is_atk:
                d.line([(hx, hy), (47, hy - (6 if f == 16 else (0 if f == 17 else -6)))], fill=hexc("3e374e"), width=2)
                if f in (16, 17, 18):
                    d.arc([31, max(1, hy - 12), 47, min(47, hy + 10)], -75, 45, fill=hexc("ffd88a"), width=2)
            else:
                d.rectangle([hx, hy - 3, min(47, hx + (8 if is_rng or is_dash else 6)), hy - 1], fill=hexc("3e374e"))
                d.rectangle([hx, hy - 1, hx + 2, hy + 2], fill=hexc("72442a"))
                if is_rng and f in (21, 22):
                    d.polygon([(44, hy - 5), (47, hy - 2), (44, hy + 1), (41, hy - 2)], fill=hexc("fff06a"))
                elif is_rng and f == 23:
                    d.ellipse([42, max(0, hy - 7), 47, max(2, hy - 2)], fill=hexc("d8dce4", 190))
        elif w == "cane":
            if is_atk:
                d.line([(hx, hy), (47, max(1, min(46, hy - [8, 2, -6, -8][f - 16])))], fill=hexc("6e4228"), width=2)
                if f in (16, 17, 18):
                    d.arc([hx - 2, max(0, hy - 12), 47, min(47, hy + 8)], -65, 45, fill=hexc("ffe88a"), width=2)
            elif is_rng:
                d.line([(hx, hy), (min(47, hx + 9), hy - 2)], fill=hexc("6e4228"), width=2)
                if f in (21, 22):
                    d.ellipse([43, hy - 5, 47, hy - 1], fill=hexc("fff06a"))
                elif f == 23:
                    d.ellipse([42, max(0, hy - 8), 46, max(2, hy - 4)], fill=hexc("d8dce4", 185))
            else:
                d.line([(hx, hy), (min(47, hx + 7), hy - 5)] if is_dash else [(hx, hy), (min(46, hx + 3), min(46, hy + 13))], fill=hexc("6e4228"), width=2)
                d.point([hx, hy - 1], fill=gold_s)
        elif w == "fan":
            spread = is_atk or is_dash or is_rng
            d.pieslice([hx - 8, max(0, hy - 12), min(47, hx + 8), min(47, hy + 6)], -40 if spread else -100, 40 if spread else -20, fill=hexc("f0ecf8"))
            d.line([(hx, hy - 3), (min(47, hx + 7), hy - 9)], fill=gold_l)
            if f in (16, 17, 18):
                d.arc([hx - 4, max(0, hy - 14), 47, min(47, hy + 8)], -60, 40, fill=hexc("d8f4ff"), width=2)
            elif is_rng and f in (21, 22):
                d.arc([38, max(0, hy - 8), 47, min(47, hy + 8)], -70, 70, fill=hexc("a8f6ff"), width=2)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=skin)

        if f in (14, 15):  # tia sáng lóe ở windup
            gx, gy = min(46, hx + 2), max(1, hy - 6)
            d.point([gx, gy], fill=hexc("fff8a8"))
            if f == 15:
                d.line([(gx - 2, gy), (min(47, gx + 2), gy)], fill=hexc("ffffff"))
                d.line([(gx, max(0, gy - 2)), (gx, min(47, gy + 2))], fill=hexc("ffffff"))
        elif is_dash:
            for sy in (14, 24, 34):
                d.line([(1 + (f % 2) * 2, sy), (8 + (f % 2) * 2, sy)], fill=hexc("e8f4ff"))
        elif is_leap_slam:
            d.arc([4, 34, 44, 47], 190, 350, fill=hexc("ffe87a"), width=2)
        elif is_rage:
            for ang_i in range(8):
                aa = ang_i * math.tau / 8.0 + 0.25
                px_f = int(24 + math.cos(aa) * 21)
                py_f = int(24 + math.sin(aa) * 19)
                if 0 <= px_f < 47 and 0 <= py_f < 47:
                    d.point([px_f, py_f], fill=hexc("ff5838") if ang_i % 2 == 0 else hexc("ffe868"))

        # 34..35 chiêu đặc biệt riêng từng trùm
        if is_spec:
            k = f - 34
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
    """Tàu chiến Hy Vọng (64x44 x 36 khung): 0-3 idle, 4-11 rẽ sóng, 12-15 nạp pháo, 16-19 húc quét,
    20-23 đại bác mạn tàu, 24-27 đèn hiệu triệu hồi, 28-29 lao húc, 30-32 vượt sóng đập xuống, 33 quá tải, 34-35 bốc cháy."""
    h_deep, hd, hull, hl, _ = hue_ramp("623e24")
    fr = []
    for f in range(36):
        img, d = canvas(64, 44)
        is_idle = f < 4
        is_walk = 4 <= f < 12
        is_wind = 12 <= f < 16
        is_melee = 16 <= f < 20
        is_rng = 20 <= f < 24
        is_cast = 24 <= f < 28
        is_dash = f in (28, 29)
        is_leap = 30 <= f < 33
        is_rage = f == 33
        is_spec = f >= 34

        w = (f % 4) if is_idle else ((f - 4) % 8 if is_walk else 0)
        if is_idle:
            bob = [0, 0, -1, 0][f]
            sail_bulge = [0, 1, 2, 1][f]
            wake = [0, 1, 1, 0][f]
        elif is_walk:
            bob = [0, 1, 1, 0, -1, -1, 0, 0][w]
            sail_bulge = [0, 2, 3, 2, 1, -1, -1, 0][w]
            wake = [0, 1, 3, 4, 3, 2, 1, 0][w]
        elif is_wind:
            k = f - 12
            bob = [0, 1, 1, 0][k]
            sail_bulge = [1, 2, 3, 4][k]
            wake = 1 + k
        elif is_melee:
            k = f - 16
            bob = [0, 1, 1, 0][k]
            sail_bulge = [4, 5, 4, 2][k]
            wake = [2, 4, 5, 2][k]
        elif is_rng:
            k = f - 20
            bob = [0, 1, 2, 0][k]
            sail_bulge = [2, 4, 5, 3][k]
            wake = 2
        elif is_cast:
            k = f - 24
            bob = [-1, 0, -1, 0][k]
            sail_bulge = [2, 3, 2, 3][k]
            wake = 1 + k
        elif is_dash:
            bob = 1 if f == 28 else 0
            sail_bulge = 6
            wake = 5
        elif is_leap:
            k = f - 30
            bob = [2, -5, 2][k]
            sail_bulge = [1, 5, 3][k]
            wake = [1, 0, 5][k]
        elif is_rage:
            bob = -1
            sail_bulge = 5
            wake = 4
        else:
            bob = 0 if f == 34 else 1
            sail_bulge = 3
            wake = 2

        water_y = 34 + max(-2, min(2, bob))
        d.ellipse([0, water_y, 63, min(43, water_y + 9)], fill=hexc("286cb0", 165))
        d.arc([2 + wake, water_y + 1, 61, min(43, water_y + 8)], 10, 170, fill=hexc("a8e6ff"), width=1)
        if is_cast:
            d.arc([4, 32, 60, 42], 0, 360, fill=hexc("5ef0ff") if f % 2 == 0 else hexc("fff088"), width=1)
        if is_melee or is_dash or f == 32:
            d.line([(55, 33 + bob), (63, 29 + bob)], fill=hexc("ffffff"), width=2)
            d.line([(54, 37 + bob), (63, 36 + bob)], fill=hexc("bce8ff"), width=1)
        if is_melee and f in (17, 18):
            d.arc([46, 18 + bob, 63, 36 + bob], -75, 65, fill=hexc("ffffff"), width=2)
        if f == 32:
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
            if is_wind and f == 15:
                d.point([x + 2, 31 + bob], fill=hexc("fff688"))
            if is_rng and f in (20, 21, 22):
                if f == 20:
                    d.point([x + 1, 33 + bob], fill=hexc("ffaa30"))
                else:
                    r_f = 5 if f == 22 else 3
                    d.ellipse([x - 1, 32 + bob, x + r_f, 32 + bob + r_f], fill=hexc("ff8c24"))
                    d.ellipse([x, 33 + bob, x + r_f - 1, 32 + bob + r_f - 1], fill=hexc("fff688"))
            elif is_rng and f == 23:
                d.ellipse([x - 1, 31 + bob, x + 4, 36 + bob], fill=hexc("d0d4dc", 190))

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
                d.point([rx_b, ry_b], fill=hexc("ff6830"))
                d.point([rx_b, ry_b + 1], fill=hexc("fff06a"))
        if is_spec:
            for idx_x, x in enumerate(range(8, 58, 7)):
                fh = 15 + ((idx_x + f) % 3) * 4
                d.polygon([(x, 27 + bob), (x + 3, max(1, 27 + bob - fh + 3)), (x + 6, 27 + bob)], fill=hexc("ff7020"))
                d.polygon([(x + 2, 27 + bob), (x + 3, max(2, 27 + bob - fh // 2)), (x + 4, 27 + bob)], fill=hexc("fff06a"))
            d.polygon([(26, 16 + bob), (31, 7 + bob + (f % 2) * 2), (36, 16 + bob)], fill=hexc("ff8428"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/boss_tau_hy_vong.png")


def build():
    tank_frames()
    chan_tinh_frames()
    dai_bang_frames()
    ma_troi_frames()
    ship_frames()
    save(sheet(cavalry_frames()), "enemies/nguyen_mong_ky_binh.png")
    for bid, cfg in BOSSES.items():
        save(sheet(boss_frames(cfg)), f"enemies/boss_{bid}.png")


if __name__ == "__main__":
    build()
