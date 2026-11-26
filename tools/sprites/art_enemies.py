"""Quân xâm lược, quái tinh nhuệ 8 khung và 10 trùm lịch sử thiết kế chi tiết cao.

- Mọi lính & quái: 8 khung (0-3 đi, 4 lấy đà, 5 tấn công, 6 thu chiêu, 7 trúng đòn).
- Trùm (48x48, tàu 64x44): 7 khung (0-3 đi uy nghi, 4 vung chiêu cực đại, 5 nổi giận bùng khí, 6 đặc biệt).
"""
import math
from px import hexc, grid, polish, sheet, save, canvas, auto_shade, hue_ramp, mix, shade, Image, ImageDraw

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

FACE = [
    "....hsssssS",
    "....hsKssKS",
    "....hsseseS",
    "....hSssssS",
    ".....SSSSS",
]
BODY = [
    ".....3111112",
    ".....3141412",
    ".....4444444",
    ".....2111112",
    ".....2212212",
]


def army_pal(a):
    p = dict(BASE)
    for k in "12345fFpP":
        p[k] = hexc(a[k])
    p["K"] = hexc("24162b")
    p["k"] = hexc(a.get("k", "f0ecf8"))
    return p


def cavalry_frames():
    """Kỵ binh Nguyên Mông (34x30 x 8 khung): 0-3 phi ngựa, 4 giương giáo, 5 đâm giáo, 6 ghìm cương, 7 trúng đòn."""
    a = ARMIES["nguyen_mong"]
    p = army_pal(a)
    hd, h_dark, horse, hl, hs = hue_ramp("845234")
    frames = []
    rider = grid(a["hat"], p, 20)
    face = grid(FACE, p, 20)
    body = grid(BODY[:3], p, 20)
    for f in range(8):
        img, d = canvas(34, 30)
        lift = [0, 1, 0, 1, 1, 0, 1, -1][f]
        legs = [(0, 3), (2, 1), (3, 0), (1, 2), (0, 2), (3, 0), (1, 2), (2, 2)][f]
        dx = -1 if f in (4, 7) else (2 if f == 5 else 0)
        for x, k in ((7, 0), (11, 1), (21, 0), (25, 1)):
            off = legs[k]
            d.line([x + dx, 19 - lift, x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=h_dark if k else horse, width=2)
            d.point([x + dx + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=hd)
        d.ellipse([4 + dx, 12 - lift, 28 + dx, 22 - lift], fill=horse)
        d.polygon([(24 + dx, 14 - lift), (29 + dx, 5 - lift), (33 + dx, 7 - lift), (31 + dx, 10 - lift), (28 + dx, 17 - lift)], fill=horse)
        auto_shade(img, horse, hl, h_dark)
        d.line([(27 + dx, 6 - lift), (23 + dx, 13 - lift)], fill=hexc("2b2230"), width=2)
        d.line([(5 + dx, 14 - lift), (max(0, 1 + dx), 20 - lift)], fill=hexc("2b2230"), width=2)
        d.point([min(33, 31 + dx), 7 - lift], fill=hexc("ffe060") if f in (4, 5) else hexc("1a1222"))
        d.rectangle([12 + dx, 11 - lift, 20 + dx, 13 - lift], fill=hexc("ca3e3e"))
        d.line([(13 + dx, 12 - lift), (19 + dx, 12 - lift)], fill=hexc("f0b848"))
        img.alpha_composite(rider, (max(0, 6 + dx), max(0, 0 - lift)))
        img.alpha_composite(face, (max(0, 6 + dx), max(0, 5 - lift)))
        img.alpha_composite(body, (max(0, 6 + dx), max(0, 10 - lift)))
        # Giáo kỵ binh hành động rõ theo khung
        if f == 4:
            d.line([(13, 8), (22, 6)], fill=hexc("9c6436"), width=2)
            d.polygon([(22, 5), (26, 5), (22, 7)], fill=hexc("ffffff"))
        elif f == 5:
            d.line([(15, 11), (32, 10)], fill=hexc("9c6436"), width=2)
            d.polygon([(30, 8), (33, 10), (30, 12)], fill=hexc("ffffff"))
            d.line([(26, 7), (33, 10)], fill=hexc("9eeeff"))
        elif f == 6:
            d.line([(18, 12), (28, 14)], fill=hexc("9c6436"), width=1)
            d.point([29, 14], fill=hexc("dce2f0"))
        else:
            d.line([(19 + dx, 2 - lift), (19 + dx, 14 - lift)], fill=hexc("9c6436"))
            d.line([(19 + dx, 0 - lift), (19 + dx, 2 - lift)], fill=hexc("ffffff"))
        if f == 7:
            d.ellipse([21, 5, 25, 9], fill=hexc("ff6060"))
        frames.append(polish(img))
    return frames


def tank_frames():
    """Xe tăng Pháp 1954 (40x30 x 8 khung): 0-3 lăn bánh, 4 khóa nòng, 5 khai hỏa chớp lớn, 6 nhả khói, 7 tóe tia đạn."""
    bd_deep, bd, body, bl, bspec = hue_ramp("6a6c3c")
    fr = []
    for f in range(8):
        img, d = canvas(40, 30)
        recoil = -2 if f == 5 else (-1 if f in (6, 7) else 0)
        d.rectangle([3, 18, 37, 26], fill=hexc("28291d"))
        for x in range(5, 37, 5):
            cx = x + ((f % 2) if f < 4 else 0)
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
        if f == 4:
            d.point([37, 8], fill=hexc("ffe86a"))
        elif f == 5:
            d.polygon([(35, 4), (39, 8), (35, 12), (33, 8)], fill=hexc("ff6820"))
            d.polygon([(35, 6), (39, 8), (35, 10)], fill=hexc("fff68a"))
            d.point([38, 8], fill=hexc("ffffff"))
        elif f == 6:
            d.ellipse([34, 4, 38, 8], fill=hexc("c8ccd4", 200))
            d.ellipse([31, 2, 35, 5], fill=hexc("e8ecf0", 170))
        elif f == 7:
            d.line([(16, 6), (22, 11)], fill=hexc("ffaa30"))
            d.point([18, 8], fill=hexc("ffffff"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/xe_tang.png")


def chan_tinh_frames():
    """Chằn tinh dữ tợn (30x32 x 8 khung): 0-3 bước nặng, 4 giơ chùy 2 tay, 5 nện đất sấm sét, 6 thu thế, 7 choáng."""
    s_deep, sd, sk, sl, sspec = hue_ramp("6a8f58")
    fr = []
    for f in range(8):
        img, d = canvas(30, 32)
        bob = [0, -1, 0, -1, -1, 2, 1, -1][f]
        lo = [(0, 2), (1, 1), (2, 0), (1, 1), (0, 0), (2, 2), (1, 1), (1, 0)][f]
        dx = -1 if f in (4, 7) else (1 if f == 5 else 0)
        d.rectangle([9 + dx, 24, 13 + dx, 30 - lo[0]], fill=sd)
        d.rectangle([17 + dx, 24, 21 + dx, 30 - lo[1]], fill=sk)
        d.ellipse([5 + dx, 10 + bob, 25 + dx, 27 + bob], fill=sk)
        d.ellipse([8 + dx, 2 + bob, 22 + dx, 15 + bob], fill=sk)
        auto_shade(img, sk, sl, sd)
        # Đai da nạm đồng + đầu lâu
        d.rectangle([7 + dx, 20 + bob, 23 + dx, 24 + bob], fill=hexc("7a482c"))
        d.rectangle([13 + dx, 20 + bob, 17 + dx, 24 + bob], fill=hexc("e8dcc0"))
        d.point([14 + dx, 22 + bob], fill=hexc("241410"))
        d.point([16 + dx, 22 + bob], fill=hexc("241410"))
        # Cặp sừng & răng nanh
        d.polygon([(9 + dx, 4 + bob), (6 + dx, max(0, 0 + bob)), (12 + dx, 3 + bob)], fill=hexc("efe4cc"))
        d.polygon([(21 + dx, 4 + bob), (24 + dx, max(0, 0 + bob)), (18 + dx, 3 + bob)], fill=hexc("efe4cc"))
        eye_c = hexc("fff060") if f in (4, 5) else hexc("ff3828")
        d.rectangle([11 + dx, 7 + bob, 12 + dx, 8 + bob], fill=eye_c)
        d.rectangle([17 + dx, 7 + bob, 18 + dx, 8 + bob], fill=eye_c)
        mh = 3 if f in (4, 5) else 1
        d.rectangle([12 + dx, 12 + bob, 18 + dx, 12 + bob + mh], fill=hexc("2a1414"))
        d.point([12 + dx, 12 + bob], fill=hexc("ffffff"))
        d.point([17 + dx, 12 + bob], fill=hexc("ffffff"))
        # Chùy gỗ bọc gai sắt theo hành động
        if f == 4:
            d.line([(20, 12), (24, 3)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([21, 0, 27, 6], fill=hexc("5a3a22"))
            d.point([24, 2], fill=hexc("dce2f0"))
        elif f == 5:
            d.line([(22, 17), (28, 25)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, 22, 29, 27], fill=hexc("5a3a22"))
            d.arc([16, 12, 29, 27], -45, 45, fill=hexc("fff088"), width=2)
        elif f == 6:
            d.line([(24, 19), (28, 17)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, 14, 29, 19], fill=hexc("5a3a22"))
        elif f == 7:
            d.line([(6, 15), (3, 21)], fill=hexc("7a4a2e"), width=2)
            d.point([10, 3], fill=hexc("ffffff"))
        else:
            wy = 10 + bob - f % 2
            d.line([(24, 16 + bob), (28, wy)], fill=hexc("7a4a2e"), width=3)
            d.ellipse([25, wy - 5, 29, wy], fill=hexc("5a3a22"))
            d.point([27, wy - 3], fill=hexc("dce2f0"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/chan_tinh.png")


def dai_bang_frames():
    """Đại bàng tinh (36x26 x 8 khung): 0-3 sải cánh, 4 khép cánh bổ nhào, 5 quắp lao vút, 6 hãm phanh, 7 xù lông."""
    b_deep, bd, br, bl, bspec = hue_ramp("825432")
    fr = []
    for f in range(8):
        img, d = canvas(36, 26)
        wing = [-8, -3, 4, -3, -6, 6, -4, 2][f]
        dx = -2 if f == 4 else (2 if f == 5 else (-1 if f == 7 else 0))
        d.polygon([(16 + dx, 12), (2 + dx, 12 + wing), (8 + dx, 15), (16 + dx, 16)], fill=br)
        d.polygon([(20 + dx, 12), (34 + dx, 12 + wing), (28 + dx, 15), (20 + dx, 16)], fill=br)
        d.line([(4 + dx, 12 + wing), (14 + dx, 13)], fill=hexc("f0b848"))
        d.line([(32 + dx, 12 + wing), (22 + dx, 13)], fill=hexc("f0b848"))
        d.ellipse([12 + dx, 9, 24 + dx, 21], fill=br)
        auto_shade(img, br, bl, bd)
        d.ellipse([20 + dx, 5, 28 + dx, 13], fill=hexc("cc9a54"))
        d.line([(21 + dx, 7), (25 + dx, 6)], fill=hexc("ffe496"))
        d.polygon([(27 + dx, 8), (33 + dx, 10), (27 + dx, 11)], fill=hexc("f4b632"))
        d.point([24 + dx, 8], fill=hexc("ff3030") if f in (4, 5) else hexc("1a1222"))
        # Móng vuốt vươn về trước khi lao tới (f==5)
        tx = 4 if f == 5 else 0
        d.line([(15 + dx, 21), (14 + dx + tx, 24)], fill=hexc("f4b632"))
        d.line([(20 + dx, 21), (21 + dx + tx, 24)], fill=hexc("f4b632"))
        if f == 5:
            d.line([(2, 8), (11, 8)], fill=hexc("e0f8ff"))
            d.line([(1, 16), (10, 16)], fill=hexc("ffffff"))
        elif f == 7:
            d.point([18, 4], fill=hexc("ffffff"))
            d.point([16, 6], fill=hexc("ff5050"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/dai_bang.png")


def ma_troi_frames():
    """Ma trơi (14x18 x 8 khung): ngọn lửa ma nhiều lớp có hồn ma & tàn lửa."""
    fr = []
    for f in range(8):
        img, d = canvas(14, 18)
        h = [0, 1, 2, 1, 0, -1, 2, 1][f]
        outer = hexc("b84aff", 210) if f == 7 else hexc("4aa8ff", 210)
        mid = hexc("78d8ff", 230) if f != 7 else hexc("e088ff", 220)
        core = hexc("ffffff") if f == 5 else hexc("d6f8ff")
        d.polygon([(2, 12), (7, max(0, 1 + h)), (12, 12)], fill=outer)
        d.ellipse([2, 7, 12, 16], fill=outer)
        d.ellipse([3, 8, 11, 15], fill=mid)
        d.ellipse([5, 10, 9, 14], fill=core)
        d.point([5, 11], fill=hexc("1a2248"))
        d.point([8, 11], fill=hexc("1a2248"))
        if f in (4, 5):
            d.point([3, 4], fill=hexc("a8f0ff"))
            d.point([11, 5], fill=hexc("ffffff"))
        fr.append(img)
    save(sheet(fr), "enemies/ma_troi.png")


# ---------------------------------------------------------------- 10 Trùm lịch sử thiết kế chi tiết cao (48x48 x 7)
BOSSES = {
    "to_dinh": {
        "name": "Tô Định", "army": "dong_han", "body": "9e2842", "trim": "f4be48", "cape": "2c1b36",
        "hat": "han_official", "weapon": "saber", "beard": "goatee", "eye": "ffcf54", "trait": "seal",
    },
    "quach_quy": {
        "name": "Quách Quỳ", "army": "tong", "body": "c44e3a", "trim": "a6b2d2", "cape": "4d2662",
        "hat": "steel_helmet", "weapon": "halberd", "beard": "full", "eye": "ffe484", "trait": "banner",
    },
    "lieu_thang": {
        "name": "Liễu Thăng", "army": "minh", "body": "ba3826", "trim": "f2be4a", "cape": "3b324e",
        "hat": "ming_helmet", "weapon": "saber", "beard": "jagged", "eye": "ff8a48", "trait": "spiked",
    },
    "don_truong": {
        "name": "Đồn trưởng Nhã Nam", "army": "phap_vien_chinh", "body": "dedacc", "trim": "eab448", "cape": "283e76",
        "hat": "pith", "weapon": "pistol", "beard": "stache", "eye": "26182c", "trait": "modern_belt",
    },
    "do_cat": {
        "name": "Đờ Cát", "army": "phap_1954", "body": "888c56", "trim": "eab448", "cape": "484a2a",
        "hat": "kepi", "weapon": "cane", "beard": "none", "eye": "26182c", "trait": "modern_belt",
    },
    "luc_dan": {
        "name": "Lục Dận", "army": "dong_ngo", "body": "3c8650", "trim": "dc9044", "cape": "214c31",
        "hat": "helmet", "weapon": "halberd", "beard": "full", "eye": "ffe060", "trait": "spiked",
    },
    "hoang_thao": {
        "name": "Hoằng Tháo", "army": "nam_han", "body": "28849c", "trim": "f4c24e", "cape": "7e246a",
        "hat": "crown", "weapon": "trident", "beard": "none", "eye": "8ef6ff", "trait": "scale_collar",
    },
    "thoat_hoan": {
        "name": "Thoát Hoan", "army": "nguyen_mong", "body": "925d3c", "trim": "dc3e40", "cape": "4e382e",
        "hat": "fur", "weapon": "saber", "beard": "braid", "eye": "ffd848", "trait": "fur_collar",
    },
    "ton_si_nghi": {
        "name": "Tôn Sĩ Nghị", "army": "thanh", "body": "385ec0", "trim": "f4d250", "cape": "861e30",
        "hat": "official", "weapon": "fan", "beard": "mandarin", "eye": "ffe87a", "trait": "mandarin",
    },
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

    frames = []
    for f in range(7):  # 0-3 đi, 4 vung vũ khí, 5 nổi giận, 6 đặc biệt
        img, d = canvas(48, 48)
        t = f % 4
        if f < 4:
            bob = [0, -2, 0, -2][t]
            lean = [0, 1, 0, -1][t]
            cape_sway = [0, -3, -1, 2][t]
            cape_flare = 0
            leg_l = [(0, 0), (4, -3), (0, 0), (-4, -1)][t]
            leg_r = [(0, 0), (-4, -1), (0, 0), (4, -3)][t]
            arm_l = [(0, 0), (-3, -1), (0, 0), (3, 1)][t]
            arm_r = [(0, 0), (3, -2), (0, 0), (-3, 1)][t]
        elif f == 4:
            bob = 1
            lean = 3
            cape_sway = -6
            cape_flare = 3
            leg_l = (-5, 0)
            leg_r = (5, -1)
            arm_l = (-5, -2)
            arm_r = (5, -3)
        elif f == 5:
            bob = -1
            lean = 0
            cape_sway = 0
            cape_flare = 4
            leg_l = (-2, 0)
            leg_r = (2, 0)
            arm_l = (-5, -5)
            arm_r = (4, -4)
        else:
            bob = 0
            lean = 0
            cape_sway = -1
            cape_flare = 2
            leg_l = (0, 0)
            leg_r = (0, 0)
            arm_l = (-2, -2)
            arm_r = (2, -2)

        # 1. Cờ lệnh sau lưng (Quách Quỳ) + Áo choàng hai tầng viền kim tuyến
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

        # 2. Chân bọc giáp & ủng chiến tướng
        for bx, (ldx, ldy) in ((16, leg_l), (26, leg_r)):
            hip_x, hip_y = bx + lean, 34 + bob
            knee_x = bx + ldx // 2
            fx, fy = bx + ldx, 43 + ldy
            d.line([(hip_x + 2, hip_y), (knee_x + 2, fy - 3)], fill=c_deep, width=5)
            d.rectangle([knee_x, fy - 7, knee_x + 4, fy - 4], fill=trim_d)
            d.rectangle([fx, fy - 4, fx + 5, fy - 2], fill=trim_l)
            d.rectangle([fx - 1, fy - 2, fx + 6, fy + 1], fill=hexc("23171b"))
            d.point([fx + 1, fy - 2], fill=gold_s)

        # 3. Tay trái & giáp cổ tay
        lx0, ly0 = 12 + lean, 23 + bob
        lhx = max(2, min(45, 9 + lean + arm_l[0]))
        lhy = max(6, min(44, 30 + bob + arm_l[1]))
        d.line([(lx0, ly0), (lhx, lhy)], fill=body_d, width=4)
        d.ellipse([lhx - 2, lhy - 2, lhx + 2, lhy + 2], fill=trim)
        d.ellipse([lhx - 1, lhy, lhx + 2, lhy + 3], fill=skin)

        # 4. Thân giáp chiến tướng tạo khối + vạt giáp hông + chi tiết đặc trưng từng trùm
        bx0, bx1 = 13 + lean, 33 + lean
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
            # Bổ tử vuông thêu kim tuyến & tràng hạt quan Thanh
            d.rectangle([19 + lean, 24 + bob, 27 + lean, 29 + bob], fill=gold_d)
            d.rectangle([20 + lean, 25 + bob, 26 + lean, 28 + bob], fill=gold_l)
            d.arc([16 + lean, 19 + bob, 30 + lean, 28 + bob], 15, 165, fill=hexc("54e0b8"))
        elif trait == "modern_belt":
            # Dây đeo chéo da nâu + huân chương
            d.line([(bx0 + 2, 21 + bob), (bx1 - 2, 31 + bob)], fill=hexc("5e3820"), width=2)
            d.rectangle([bx0 + 2, 24 + bob, bx0 + 4, 26 + bob], fill=gold_s)
            d.rectangle([bx0 + 5, 24 + bob, bx0 + 6, 26 + bob], fill=hexc("e23c3e"))
        elif trait == "fur_collar":
            # Cổ áo lông thú Nguyên Mông dày rậm
            d.ellipse([12 + lean, 19 + bob, 34 + lean, 25 + bob], fill=hexc("ece4d8"))
            d.ellipse([19 + lean, 24 + bob, 27 + lean, 29 + bob], fill=trim_l)
        elif trait == "scale_collar":
            # Cổ ngọc thủy tộc & hộ tâm lam ngọc (Hoằng Tháo)
            d.polygon([(14 + lean, 21 + bob), (23 + lean, 27 + bob), (32 + lean, 21 + bob)], fill=hexc("5ef0ff"))
            d.ellipse([20 + lean, 24 + bob, 26 + lean, 29 + bob], fill=gold)
            d.point([23 + lean, 26 + bob], fill=hexc("44e4ff"))
        else:
            d.ellipse([19 + lean, 23 + bob, 27 + lean, 29 + bob], fill=gold_d)
            d.ellipse([20 + lean, 24 + bob, 26 + lean, 28 + bob], fill=trim_l)
            d.point([22 + lean, 25 + bob], fill=gold_s)
            if trait == "seal":
                d.rectangle([14 + lean, 33 + bob, 18 + lean, 36 + bob], fill=gold_l)  # ấn tín Tô Định

        # Vai giáp điêu khắc (có gai nhọn cho tướng võ Liễu Thăng / Lục Dận)
        for px0, px1, sgn in ((8 + lean, 16 + lean, -1), (30 + lean, 38 + lean, 1)):
            d.ellipse([px0, 19 + bob, px1, 26 + bob], fill=trim)
            d.arc([px0, 19 + bob, px1, 26 + bob], 190 if sgn < 0 else 270, 330 if sgn < 0 else 360, fill=trim_s)
            d.line([(px0 + 2, 24 + bob), (px1 - 2, 24 + bob)], fill=t_deep)
            if trait == "spiked":
                sx_tip = px0 - 2 if sgn < 0 else px1 + 2
                d.polygon([(px0 + 3, 20 + bob), (sx_tip, 16 + bob), (px1 - 2, 21 + bob)], fill=steel_s)

        # 5. Đầu & gương mặt sắc nét
        d.polygon([
            (15 + lean, 9 + bob), (31 + lean, 9 + bob),
            (31 + lean, 18 + bob), (26 + lean, 23 + bob),
            (20 + lean, 23 + bob), (15 + lean, 18 + bob),
        ], fill=skin)
        d.line([(16 + lean, 10 + bob), (24 + lean, 9 + bob)], fill=skin_l)
        d.line([(15 + lean, 17 + bob), (20 + lean, 22 + bob)], fill=skin_d)
        d.line([(31 + lean, 12 + bob), (31 + lean, 18 + bob)], fill=skin_d)
        ex = 25 + lean
        eye = hexc("ff2838") if f == 5 else eye_norm
        d.rectangle([ex - 5, 14 + bob, ex - 2, 16 + bob], fill=hexc("ffffff"))
        d.rectangle([ex + 1, 14 + bob, ex + 4, 16 + bob], fill=hexc("ffffff"))
        d.rectangle([ex - 4, 14 + bob, ex - 3, 16 + bob], fill=eye)
        d.rectangle([ex + 2, 14 + bob, ex + 3, 16 + bob], fill=eye)
        d.line([ex - 6, 12 + bob, ex - 2, 13 + bob], fill=dark, width=1)
        d.line([ex + 5, 12 + bob, ex + 1, 13 + bob], fill=dark, width=1)
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

        # 6. Mũ / Vương miện thiết kế riêng tỉ mỉ
        hat = cfg["hat"]
        if hat == "helmet":
            d.chord([14 + lean, 3 + bob, 32 + lean, 18 + bob], 180, 360, fill=hexc("ca8440"))
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=gold_d)
            d.polygon([(21 + lean, max(0, 1 + bob)), (25 + lean, max(0, 1 + bob)), (23 + lean, 6 + bob)], fill=gold_l)
            d.line([23 + lean, max(0, 0 + bob), 18 + lean + cape_sway // 2, 3 + bob], fill=hexc("e23c3e"), width=2)
        elif hat == "crown":
            d.rectangle([15 + lean, 6 + bob, 31 + lean, 10 + bob], fill=gold)
            for idx_p, x in enumerate((15, 19, 23, 27, 31)):
                pk_y = 0 if idx_p == 2 else 2
                d.polygon([(x - 2 + lean, 6 + bob), (x + lean, max(0, pk_y + bob)), (x + 2 + lean, 6 + bob)], fill=gold_l if idx_p == 2 else gold)
            d.point([23 + lean, 8 + bob], fill=hexc("4ee8a8"))
            d.point([19 + lean, 8 + bob], fill=hexc("e83848"))
            d.point([27 + lean, 8 + bob], fill=hexc("e83848"))
        elif hat == "fur":
            d.ellipse([12 + lean, 4 + bob, 34 + lean, 14 + bob], fill=hexc("6e4c3c"))
            d.chord([15 + lean, max(0, 0 + bob), 31 + lean, 12 + bob], 180, 360, fill=hexc("ca3e3e"))
            d.ellipse([21 + lean, max(0, 0 + bob), 25 + lean, 3 + bob], fill=gold_s)
            for x in range(13, 34, 2):
                d.point([x + lean, 11 + bob], fill=hexc("b89674"))
        elif hat == "han_official":
            d.rectangle([16 + lean, 1 + bob, 30 + lean, 11 + bob], fill=hexc("2c2334"))
            d.rectangle([11 + lean, 7 + bob, 16 + lean, 9 + bob], fill=hexc("1a1322"))
            d.rectangle([30 + lean, 7 + bob, 35 + lean, 9 + bob], fill=hexc("1a1322"))
            d.rectangle([14 + lean, 9 + bob, 32 + lean, 11 + bob], fill=hexc("181220"))
            d.line([18 + lean, 3 + bob, 28 + lean, 3 + bob], fill=hexc("564668"))
            d.rectangle([21 + lean, 4 + bob, 25 + lean, 7 + bob], fill=gold_s)
        elif hat == "steel_helmet":
            d.chord([14 + lean, 3 + bob, 32 + lean, 17 + bob], 180, 360, fill=steel)
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=steel_d)
            d.line([23 + lean, 3 + bob, 21 + lean + cape_sway // 2, max(0, 0 + bob)], fill=hexc("e23c3e"), width=2)
            d.line([(16 + lean, 6 + bob), (21 + lean, 5 + bob)], fill=steel_s)
        elif hat == "ming_helmet":
            d.chord([14 + lean, 2 + bob, 32 + lean, 18 + bob], 180, 360, fill=hexc("3e374e"))
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=gold_d)
            d.ellipse([21 + lean, max(0, 0 + bob), 25 + lean, 4 + bob], fill=hexc("e23c3e"))
            d.line([16 + lean, 7 + bob, 30 + lean, 7 + bob], fill=gold_l)
        elif hat == "pith":
            d.chord([13 + lean, 2 + bob, 33 + lean, 20 + bob], 180, 360, fill=hexc("f2eee2"))
            d.rectangle([11 + lean, 10 + bob, 35 + lean, 12 + bob], fill=hexc("c8c4b4"))
            d.line([15 + lean, 9 + bob, 31 + lean, 9 + bob], fill=hexc("72442a"))
            d.rectangle([21 + lean, 5 + bob, 24 + lean, 8 + bob], fill=gold)
        elif hat == "kepi":
            d.rectangle([16 + lean, 3 + bob, 30 + lean, 10 + bob], fill=hexc("d03b32"))
            d.rectangle([15 + lean, 10 + bob, 31 + lean, 12 + bob], fill=hexc("2c2334"))
            d.line([17 + lean, 5 + bob, 29 + lean, 5 + bob], fill=gold_l)
            d.rectangle([28 + lean, 12 + bob, 34 + lean, 13 + bob], fill=hexc("181220"))
        elif hat == "official":
            d.chord([14 + lean, 3 + bob, 32 + lean, 15 + bob], 180, 360, fill=hexc("2c2334"))
            d.rectangle([12 + lean, 9 + bob, 34 + lean, 10 + bob], fill=hexc("2c2334"))
            d.ellipse([21 + lean, max(0, 0 + bob), 25 + lean, 4 + bob], fill=hexc("e83848"))
            d.line([(14 + lean, 6 + bob), (6 + lean + cape_sway // 2, 12 + bob)], fill=hexc("389862"), width=2)
            d.point([6 + lean + cape_sway // 2, 12 + bob], fill=hexc("4ae2ff"))

        # 7. Tay phải & vũ khí đặc trưng (chỉ 1 đoạn, đầy nét sáng & tua)
        swing = f == 4
        w = cfg["weapon"]
        rx0, ry0 = 33 + lean, 23 + bob
        hx = 40 if swing else 35 + lean + arm_r[0]
        hy = 27 + bob if swing else 30 + bob + arm_r[1]
        d.line([(rx0, ry0), (hx, hy)], fill=body, width=4)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=trim_l)
        if w == "halberd":
            top = (47, 25) if swing else (min(46, hx + 7), max(1, hy - 26))
            d.line([(hx - 4, hy + 10), top], fill=hexc("6a4028"), width=2)
            d.polygon([(top[0] - 4, top[1]), (top[0] + 1, top[1] - 2), (top[0] + 1, top[1] + 6), (top[0] - 5, top[1] + 4)], fill=steel)
            d.line([(top[0], top[1] - 1), (top[0], top[1] + 5)], fill=steel_s)
            d.point([top[0] - 1, top[1] + 7], fill=hexc("e23c3e"))
            if swing:
                d.arc([32, 7, 47, 36], -70, 40, fill=hexc("ffffff"), width=2)
        elif w == "trident":
            top = (47, 22) if swing else (min(46, hx + 4), max(1, hy - 28))
            d.line([(hx - 2, hy + 8), top], fill=gold_d, width=2)
            for dx_t in (-3, 0, 3):
                d.line([(min(47, top[0] + dx_t), top[1] + 5), (min(47, top[0] + dx_t), top[1])], fill=gold_s if dx_t == 0 else gold)
            d.line([(top[0] - 3, top[1] + 5), (min(47, top[0] + 3), top[1] + 5)], fill=gold_l)
            if swing:
                d.line([(hx + 2, hy - 4), (47, hy - 8)], fill=hexc("a8f4ff"), width=2)
        elif w == "saber":
            if swing:
                d.line([(hx, hy), (47, hy - 4)], fill=steel_s, width=2)
                d.arc([30, hy - 16, 47, hy + 10], -80, 30, fill=hexc("ffffff"), width=2)
            else:
                tip_x = min(46, hx + 8 + arm_r[0])
                tip_y = max(2, hy - 14)
                d.line([(hx, hy), (tip_x, tip_y)], fill=steel, width=2)
                d.point([tip_x, tip_y - 1], fill=steel_s)
            d.line([(hx - 2, hy + 1), (hx + 2, hy - 1)], fill=gold_l)
        elif w == "pistol":
            d.rectangle([hx, hy - 3, min(47, hx + (7 if swing else 6)), hy - 1], fill=hexc("3e374e"))
            d.rectangle([hx, hy - 1, hx + 2, hy + 2], fill=hexc("72442a"))
            if swing:
                d.polygon([(45, hy - 5), (47, hy - 2), (45, hy + 1), (43, hy - 2)], fill=hexc("fff06a"))
        elif w == "cane":
            d.line([(hx, hy), (min(47, hx + 7), hy - 5)] if swing else [(hx, hy), (min(46, hx + 3), min(46, hy + 13))], fill=hexc("6e4228"), width=2)
            d.point([hx, hy - 1], fill=gold_s)
            if swing:
                d.arc([hx - 2, hy - 12, 47, hy + 6], -55, 35, fill=hexc("ffe88a"), width=2)
        elif w == "fan":
            d.pieslice([hx - 8, hy - 12, min(47, hx + 8), hy + 6], -100 if not swing else -40, -20 if not swing else 40, fill=hexc("f0ecf8"))
            d.line([(hx, hy - 3), (min(47, hx + 7), hy - 9)], fill=gold_l)
            if swing:
                d.arc([hx - 4, hy - 14, 47, hy + 8], -55, 35, fill=hexc("d8f4ff"), width=2)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=skin)

        # Khung 5: bùng hào quang nổi giận quanh thân
        if f == 5:
            for ang_i in range(6):
                aa = ang_i * math.tau / 6.0
                px_f = int(24 + math.cos(aa) * 20)
                py_f = int(24 + math.sin(aa) * 18)
                if 0 <= px_f < 47 and 0 <= py_f < 47:
                    d.point([px_f, py_f], fill=hexc("ff7040"))

        # Khung 6 đặc biệt theo sự tích từng trùm
        if f == 6 and cfg["hat"] == "kepi":
            img, d = canvas(48, 48)
            for row, y in enumerate((34, 28, 22)):
                for x in range(6 + row * 3, 42 - row * 3, 8):
                    d.ellipse([x, y, x + 9, y + 7], fill=hexc("b0905e"))
            auto_shade(img, hexc("b0905e"), hexc("dcba86"), hexc("6c5636"))
            d.rectangle([16, 14, 32, 22], fill=hexc("2c261a"))
            d.rectangle([18, 16, 30, 20], fill=hexc("120e0a"))
            d.rectangle([22, 17, 26, 19], fill=hexc("d43b34"))
            d.line([(30, 18), (41, 16)], fill=hexc("3e374e"), width=2)
            d.rectangle([14, 12, 34, 14], fill=hexc("5e5e3c"))
        elif f == 6 and cfg["hat"] == "fur":
            img, d = canvas(48, 48)
            d.ellipse([6, 18, 42, 44], fill=hexc("ca8440"))
            d.rectangle([10, 18, 38, 44], fill=hexc("ca8440"))
            auto_shade(img, hexc("ca8440"), hexc("f8c280"), hexc("7a4620"))
            d.ellipse([8, 12, 40, 26], fill=hexc("7a4620"))
            d.ellipse([12, 15, 36, 24], fill=hexc("2a1414"))
            d.rectangle([20, 14, 21, 17], fill=hexc("ffffff"))
            d.rectangle([26, 14, 27, 17], fill=hexc("ffffff"))
            d.point([21, 16], fill=dark)
            d.point([27, 16], fill=dark)
            for y in (28, 36):
                d.line([10, y, 38, y], fill=gold_l, width=2)
        elif f == 6:
            # Khung chiêu đặc biệt rực sáng vương khí quanh tướng
            for spx, spy in ((8, 16), (40, 16), (6, 28), (42, 28)):
                d.point([spx, spy], fill=gold_s)
                d.point([spx, spy - 1], fill=trim_l)

        frames.append(polish(img))
    return frames


def ship_frames():
    """Tàu chiến Hy Vọng (64x44 x 7): ván gỗ nổi khối, lỗ pháo đồng, buồm tam sắc, sóng rẽ nước và lửa cháy rực."""
    h_deep, hd, hull, hl, hs = hue_ramp("623e24")
    fr = []
    for f in range(7):
        img, d = canvas(64, 44)
        w = f % 4
        bob = [0, 1, 0, -1][w] if f < 4 else (1 if f == 4 else 0)
        sail_bulge = [0, 3, 1, -1][w] if f < 4 else 4
        wake = [0, 2, 4, 1][w]
        d.ellipse([0, 34 + bob, 63, 43 + bob], fill=hexc("286cb0", 165))
        d.arc([2 + wake, 35 + bob, 61, 42 + bob], 10, 170, fill=hexc("a8e6ff"), width=1)
        if f == 4:
            d.line([(55, 33 + bob), (63, 29 + bob)], fill=hexc("ffffff"), width=2)
            d.line([(54, 37 + bob), (63, 36 + bob)], fill=hexc("bce8ff"), width=1)
        d.polygon([(2, 26 + bob), (62, 26 + bob), (56, 38 + bob), (8, 38 + bob)], fill=hull)
        auto_shade(img, hull, hl, hd)
        d.line([(5, 29 + bob), (59, 29 + bob)], fill=h_deep)
        d.line([(4, 27 + bob), (60, 27 + bob)], fill=hexc("f0ecf8"))
        # Mũi tàu mạ vàng
        d.polygon([(59, 25 + bob), (63, 22 + bob), (60, 28 + bob)], fill=hexc("f0b848"))
        for x in (14, 26, 38, 50):
            d.rectangle([x, 30 + bob, x + 3, 32 + bob], fill=hexc("1a1210"))
            d.point([x + 1, 31 + bob], fill=hexc("a86826"))
            if f == 4:
                d.ellipse([x - 2, 33 + bob, x + 6, 39 + bob], fill=hexc("ff8c24"))
                d.ellipse([x - 1, 34 + bob, x + 4, 38 + bob], fill=hexc("fff688"))
        d.line([(24, 26 + bob), (24, 2 + bob)], fill=hexc("3a2214"), width=2)
        d.line([(24, 3 + bob), (42 + sail_bulge, 24 + bob)], fill=hexc("b8a890"))  # dây buồm
        d.polygon([(25, 4 + bob), (40 + sail_bulge, 8 + bob), (40 + sail_bulge, 22 + bob), (25, 24 + bob)], fill=hexc("f2eee2"))
        d.line([(25, 14 + bob), (40 + sail_bulge, 15 + bob)], fill=hexc("c8c4b4"))
        d.rectangle([44, 14 + bob, 48, 26 + bob], fill=hexc("2c2622"))
        d.line([(44, 15 + bob), (48, 15 + bob)], fill=hexc("d48c44"))
        sx = 42 - (w * 2 if f < 4 else 4)
        d.ellipse([sx, 8 + bob - (f % 2), sx + 8, 14 + bob - (f % 2)], fill=hexc("726878", 185))
        d.rectangle([22, 2 + bob, 30, 6 + bob], fill=hexc("2a3a8a"))
        d.rectangle([24, 2 + bob, 26, 6 + bob], fill=hexc("ffffff"))
        d.rectangle([28, 2 + bob, 30, 6 + bob], fill=hexc("c83a32"))
        if f >= 5:
            for x in range(8, 58, 7):
                d.polygon([(x, 27 + bob), (x + 3, 15 + bob - (x % 5)), (x + 6, 27 + bob)], fill=hexc("ff7020"))
                d.polygon([(x + 2, 27 + bob), (x + 3, 20 + bob), (x + 4, 27 + bob)], fill=hexc("fff06a"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/boss_tau_hy_vong.png")


def build():
    for army in ARMIES:
        kinds = ("bo_binh", "linh_sung", "xa_thu", "phao_binh") if army.startswith("phap") else ("bo_binh", "cung_thu", "khien_binh", "phap_su")
        for kind in kinds:
            save(sheet(cavalry_frames() if kind == "ky_binh" else []), f"enemies/{army}_{kind}.png") if False else None
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
