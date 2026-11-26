"""Quân xâm lược qua các thời kỳ (có hư cấu cho kịch tính) + 4 trùm.

Mỗi đạo quân có 4 loại lính dùng chung khung: bộ binh, cung thủ, khiên binh, pháp sư.
Quân Nguyên Mông có thêm kỵ binh. Mỗi loại 4 khung đi bộ, 18x21.
"""
import math
from px import hexc, grid, outline, polish, sheet, save, canvas, auto_shade, Image, ImageDraw

BASE = {
    "s": hexc("f0c4a0"), "S": hexc("c88e74"), "e": hexc("2a1d2e"), "w": hexc("ffffff"),
    "h": hexc("2b2230"), "H": hexc("4b3d58"),
    "o": hexc("9a6234"), "O": hexc("5e3a20"), "m": hexc("d8dce8"), "M": hexc("8a92ac"),
    "g": hexc("e8b04a"), "G": hexc("a86a2a"), "y": hexc("fff0a0"),
    "r": hexc("d83a3a"), "R": hexc("8e2632"), "k": hexc("ece8f4"),
    "q": hexc("4a3428"), "Q": hexc("2e1e18"),
    "v": hexc("b06aff"), "V": hexc("5a2a90"), "u": hexc("f0d0ff"),
}

ARMIES = {
    "dong_han": {"name": "Quân Đông Hán", "1": "8a2a3a", "2": "5a1626", "3": "c04a5a", "4": "2b2230", "5": "1a1420",
                 "f": "2b2230", "F": "4b3d58", "p": "2a2a3e", "P": "1a1a28",
                 "hat": [
                     "",
                     "......hhhhhh",
                     ".....hHhhhhh",
                     ".....hhhhhhh",
                     "....5444444445",
                 ]},
    "tong": {"name": "Quân Tống", "1": "b04a3a", "2": "742a22", "3": "e07a5a", "4": "8a92ac", "5": "565c74",
             "f": "8a92ac", "F": "d8dce8", "p": "3a3040", "P": "241e2a",
             "hat": [
                 "........r",
                 ".......mrm",
                 "......mMmmm",
                 ".....mmmmmmM",
                 "....MMMMMMMMMM",
             ]},
    "minh": {"name": "Quân Minh", "1": "a83a2a", "2": "6a2018", "3": "d86a4a", "4": "3a3448", "5": "1e1a28",
             "f": "3a3448", "F": "5e5870", "p": "2a2a3e", "P": "1a1a28",
             "hat": [
                 "........r",
                 ".......rrr",
                 "......h4444h",
                 ".....h444444h",
                 "....hhhhhhhhhh",
             ]},
    "phap_thuy": {"name": "Thủy quân Pháp", "1": "2a3a6a", "2": "1a2444", "3": "4a64a8", "4": "e8e4f0", "5": "a8a4c0",
                  "f": "e8e4f0", "F": "ffffff", "p": "2a3a6a", "P": "1a2444",
                  "hat": [
                      "",
                      "........r",
                      "......kkrkkk",
                      ".....kkkkkkkk",
                      "......3333333",
                  ]},
    "phap_vien_chinh": {"name": "Quân viễn chinh Pháp", "k": "f0ece0", "1": "d8d4c4", "2": "a8a490", "3": "f4f0e4", "4": "6a4028", "5": "3e2416",
                        "f": "e8e4d8", "F": "ffffff", "p": "a8a490", "P": "787462",
                        "hat": [
                            "",
                            "......kkkkk",
                            ".....kkkkkkk",
                            "....kkkkkkkkk",
                            "...KKKKKKKKKKK",
                        ]},
    "phap_1954": {"name": "Lính Pháp 1954", "1": "7a7a4a", "2": "4e4e2e", "3": "a8a86a", "4": "5a4024", "5": "3a2a18",
                  "f": "5a5a3a", "F": "7a7a52", "p": "5e5e3a", "P": "3e3e26",
                  "hat": [
                      "",
                      "......FFFFF",
                      ".....FfffffF",
                      "....ffffffffF",
                      "...ffffffffffF",
                  ]},
    "dong_ngo": {"name": "Quân Đông Ngô", "1": "3e7a4a", "2": "264e32", "3": "6eb070", "4": "c4803e", "5": "7a4622",
                 "f": "c4803e", "F": "f2b878", "p": "3a3a2e", "P": "24241c",
                 "hat": [
                     "........r",
                     ".......rRr",
                     "......GgggG",
                     ".....gyggggG",
                     "....GGGGGGGGGG",
                 ]},
    "nam_han": {"name": "Quân Nam Hán", "1": "2a7a8a", "2": "1a4a5e", "3": "5ab8c0", "4": "e8b04a", "5": "a86a2a",
                "f": "1a4a5e", "F": "2a7a8a", "p": "2a2a3e", "P": "1a1a28",
                "hat": [
                    "",
                    "",
                    "......hhhhhh",
                    ".....hHhhhhhh",
                    "....5444444445",
                ]},
    "nguyen_mong": {"name": "Quân Nguyên Mông", "1": "8a5a3a", "2": "5a3622", "3": "b8845a", "4": "c43c3c", "5": "7a1e2c",
                    "f": "6a4a3a", "F": "a88a6a", "p": "4a3a30", "P": "2e241e",
                    "hat": [
                        "........r",
                        ".......4r4",
                        "......444445",
                        ".....FfFfFfFf",
                        "....fFfFfFfFfF",
                    ]},
    "thanh": {"name": "Quân Thanh", "1": "3a5aa8", "2": "243a74", "3": "6a8ad8", "4": "e8c84a", "5": "a88a2a",
              "f": "2b2230", "F": "4b3d58", "p": "2a2a3e", "P": "1a1a28",
              "hat": [
                  "........r",
                  ".......rrr",
                  "......hhhhhh",
                  "....hhhhhhhhhh",
                  "...HHHHHHHHHHHH",
              ]},
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
ROBE = [
    ".....3111112",
    ".....3141412",
    ".....4444444",
    ".....2111112",
    "....211111112",
    "....222122222",
]
LEGS = [
    [".....ppppPP", "......pP.pP", "......qQ.qQ", ".....qqQ.qqQ"],
    [".....ppppPP", ".....pP...pP", "....qQ.....qQ", "....qQ.....qqQ"],
    [".....ppppPP", "......ppPP", "......qQqQ", "........qqQ"],
    [".....PPppppp", ".....PP...pP", "....QQ.....qQ", "....qQ.....qqQ"],
]
WEAPON = {
    "bo_binh": [   # đao
        "", "", "", "", "",
        "...............m",
        "..............mM",
        ".............mM",
        "............mM",
        "...........sG",
        "...........s",
    ],
    "cung_thu": [
        "", "",
        "..............o",
        "...............o",
        "...............oO",
        "............k..oO",
        "............k..oO",
        "...........ssk.oO",
        "............k..oO",
        "............k..oO",
        "...............oO",
        "...............o",
        "..............o",
    ],
    "khien_binh": [
        "", "", "", "", "", "", "",
        ".........5555",
        "........544445",
        "........54gg45",
        "........54gy45",
        "........544445",
        "........544445",
        ".........5445",
        "..........55",
    ],
    "phap_su": [
        "..............u",
        ".............uvu",
        "..............V",
        "..............o",
        "..............o",
        "..............o",
        "..............o",
        ".............so",
        "..............o",
        "..............o",
        "..............o",
        "..............O",
        "..............O",
        "..............O",
        "..............O",
    ],
}


WEAPON.update({
    "bo_binh_modern": [   # súng trường có lưỡi lê, cầm chéo
        "", "", "",
        "................m",
        "...............m",
        "..............O",
        ".............O",
        "............o",
        "...........so",
        "..........so",
    ],
    "linh_sung": [
        "", "", "", "", "", "", "", "",
        "..........sOOMMMMMMm",
        "..........ss.",
    ],
    "xa_thu": [
        "", "", "", "", "", "", "",
        "..........MMMMMMMMMm",
        "..........sMMMMG",
        "..........s.MM.G",
        "............M..G",
    ],
    "phao_binh": [
        "", "",
        "..............MM",
        ".............MMM",
        "............MMM",
        "...........MMM",
        "..........sMM",
        "..........sM",
        "...........M.M",
    ],
})


def army_pal(a):
    p = dict(BASE)
    for k in "12345fFpP":
        p[k] = hexc(a[k])
    p["K"] = hexc("2a1d2e")
    p["k"] = hexc(a.get("k", "ece8f4"))
    p["K2"] = p["K"]
    return p


def soldier_frames(army_id, kind):
    a = ARMIES[army_id]
    p = army_pal(a)
    if kind == "phap_su":
        p["1"], p["2"], p["3"] = hexc("4a2a6a"), hexc("2a1840"), hexc("7a50a0")
        p["e"] = hexc("e030ff")
    frames = []
    for i, legs in enumerate(LEGS):
        img = Image.new("RGBA", (20, 22), (0, 0, 0, 0))
        bob = -1 if i % 2 == 1 else 0
        body = ROBE if kind == "phap_su" else BODY
        leg_y = 16 if kind != "phap_su" else 17
        img.alpha_composite(grid(legs, p, 20), (0, leg_y))
        if bob:
            img.alpha_composite(grid([legs[0]], p, 20), (0, leg_y - 1))
        up = Image.new("RGBA", (20, 22), (0, 0, 0, 0))
        up.alpha_composite(grid(a["hat"], p, 20), (0, 1))
        up.alpha_composite(grid(FACE, p, 20), (0, 6))
        up.alpha_composite(grid(body, p, 20), (0, 11))
        img.alpha_composite(up, (0, bob))
        wkey = kind
        if kind == "bo_binh" and army_id.startswith("phap"):
            wkey = "bo_binh_modern"
        img.alpha_composite(grid(WEAPON[wkey], p, 20), (0, bob))
        frames.append(polish(img))
    return frames


def cavalry_frames():
    """Kỵ binh Nguyên Mông: ngựa nâu + lính cung cưỡi trên lưng."""
    a = ARMIES["nguyen_mong"]
    p = army_pal(a)
    horse, horse_l, horse_d = hexc("7a4a2e"), hexc("a8744a"), hexc("4a2a18")
    frames = []
    rider = grid(a["hat"], p, 20)
    face = grid(FACE, p, 20)
    body = grid(BODY[:3], p, 20)
    for f in range(4):
        img, d = canvas(34, 30)
        lift = [0, 1, 0, 1][f]
        legs = [(0, 3), (2, 1), (3, 0), (1, 2)][f]
        for x, k in ((7, 0), (11, 1), (21, 0), (25, 1)):
            off = legs[k]
            d.line([x, 19 - lift, x + (2 if k else -1) * (off - 1), 27 - (off > 1)], fill=horse_d if k else horse, width=2)
        d.ellipse([4, 12 - lift, 28, 22 - lift], fill=horse)
        d.polygon([(24, 14 - lift), (29, 5 - lift), (33, 7 - lift), (31, 10 - lift), (28, 17 - lift)], fill=horse)
        auto_shade(img, horse, horse_l, horse_d)
        d.line([(27, 6 - lift), (23, 13 - lift)], fill=hexc("2b2230"), width=2)   # bờm
        d.line([(5, 14 - lift), (1, 20 - lift)], fill=hexc("2b2230"), width=2)    # đuôi
        d.point([31, 7 - lift], fill=hexc("1a1222"))
        d.rectangle([12, 11 - lift, 20, 13 - lift], fill=hexc("c43c3c"))           # yên ngựa
        img.alpha_composite(rider, (6, 0 - lift))
        img.alpha_composite(face, (6, 5 - lift))
        img.alpha_composite(body, (6, 10 - lift))
        d.line([(19, 2 - lift), (19, 14 - lift)], fill=hexc("9a6234"))             # giáo
        d.line([(19, 0 - lift), (19, 1 - lift)], fill=hexc("d8dce8"))
        frames.append(polish(img))
    return frames


# ---------------------------------------------------------------- Trùm (vẽ thủ tục, 44x46)
BOSSES = {
    "to_dinh": {"name": "Tô Định", "army": "dong_han", "body": "8a2a3a", "trim": "e8b04a", "cape": "2b2230",
                "hat": "han_official", "weapon": "saber", "beard": True},
    "quach_quy": {"name": "Quách Quỳ", "army": "tong", "body": "b04a3a", "trim": "8a92ac", "cape": "4a2a5a",
                  "hat": "steel_helmet", "weapon": "halberd", "beard": True},
    "lieu_thang": {"name": "Liễu Thăng", "army": "minh", "body": "a83a2a", "trim": "e8b04a", "cape": "3a3448",
                   "hat": "ming_helmet", "weapon": "saber", "beard": True},
    "don_truong": {"name": "Đồn trưởng Nhã Nam", "army": "phap_vien_chinh", "body": "d8d4c4", "trim": "e8b04a", "cape": "2a3a6a",
                   "hat": "pith", "weapon": "pistol", "beard": False},
    "do_cat": {"name": "Đờ Cát", "army": "phap_1954", "body": "8a8a5a", "trim": "e8b04a", "cape": "4e4e2e",
               "hat": "kepi", "weapon": "cane", "beard": False},
    "luc_dan": {"name": "Lục Dận", "army": "dong_ngo", "body": "3e7a4a", "trim": "c4803e", "cape": "264e32",
                "hat": "helmet", "weapon": "halberd", "beard": True},
    "hoang_thao": {"name": "Hoằng Tháo", "army": "nam_han", "body": "2a7a8a", "trim": "e8b04a", "cape": "7a2a6a",
                   "hat": "crown", "weapon": "trident", "beard": False},
    "thoat_hoan": {"name": "Thoát Hoan", "army": "nguyen_mong", "body": "8a5a3a", "trim": "c43c3c", "cape": "4a3a30",
                   "hat": "fur", "weapon": "saber", "beard": True},
    "ton_si_nghi": {"name": "Tôn Sĩ Nghị", "army": "thanh", "body": "3a5aa8", "trim": "e8c84a", "cape": "7a1e2c",
                    "hat": "official", "weapon": "fan", "beard": True},
}


def boss_frames(cfg):
    body = hexc(cfg["body"])
    body_l, body_d = tuple(min(255, int(c * 1.35)) for c in body[:3]) + (255,), tuple(int(c * 0.6) for c in body[:3]) + (255,)
    trim = hexc(cfg["trim"])
    cape = hexc(cfg["cape"])
    cape_l, cape_d = tuple(min(255, int(c * 1.4)) for c in cape[:3]) + (255,), tuple(int(c * 0.6) for c in cape[:3]) + (255,)
    skin, skin_d = hexc("f0c4a0"), hexc("c88e74")
    dark = hexc("2a1d2e")
    steel, steel_d = hexc("d8dce8"), hexc("8a92ac")
    gold, gold_d = hexc("e8b04a"), hexc("a86a2a")
    frames = []
    for f in range(7):   # đi(4) + vung vũ khí(1) + nổi giận(1) + đặc biệt(1)
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
            cape_flare = 2
            leg_l = (-5, 0)
            leg_r = (5, -1)
            arm_l = (-5, -2)
            arm_r = (4, -3)
        elif f == 5:
            bob = -1
            lean = 0
            cape_sway = 0
            cape_flare = 3
            leg_l = (-2, 0)
            leg_r = (2, 0)
            arm_l = (-4, -4)
            arm_r = (2, -3)
        else:
            bob = 0
            lean = 0
            cape_sway = 0
            cape_flare = 0
            leg_l = (0, 0)
            leg_r = (0, 0)
            arm_l = (0, 0)
            arm_r = (0, 0)

        # áo choàng phía sau (bay theo bước chạy & lao tới)
        c_top_l = 12 + lean
        c_top_r = 30 + lean
        c_bot_l = max(1, 7 + cape_sway - cape_flare)
        c_bot_r = min(46, 35 + cape_sway + cape_flare)
        d.polygon([(c_top_l, 20 + bob), (c_top_r, 20 + bob), (c_bot_r, 41 + bob // 2), (c_bot_l, 42 + bob // 2)], fill=cape)
        auto_shade(img, cape, cape_l, cape_d)

        # chân + ủng chuyển động xen kẽ
        for bx, (ldx, ldy) in ((16, leg_l), (25, leg_r)):
            hip_x = bx + lean
            hip_y = 35 + bob
            knee_x = bx + ldx // 2
            foot_x = bx + ldx
            foot_y = 43 + ldy
            d.line([(hip_x + 2, hip_y), (knee_x + 2, foot_y - 3)], fill=hexc("3a3040"), width=5)
            d.rectangle([foot_x, foot_y - 4, foot_x + 5, foot_y - 3], fill=trim)
            d.rectangle([foot_x - 1, foot_y - 2, foot_x + 6, foot_y + 1], fill=hexc("2a1e18"))

        # tay trái (vung ngược chiều tay vũ khí)
        lx0, ly0 = 12 + lean, 23 + bob
        lhx = clamp_x = max(2, min(45, 9 + lean + arm_l[0]))
        lhy = max(6, min(44, 30 + bob + arm_l[1]))
        d.line([(lx0, ly0), (lhx, lhy)], fill=body_d, width=4)
        d.ellipse([lhx - 2, lhy - 2, lhx + 2, lhy + 2], fill=trim)
        d.ellipse([lhx - 1, lhy, lhx + 2, lhy + 3], fill=skin)

        # thân giáp
        bx0 = 13 + lean
        bx1 = 33 + lean
        d.rectangle([bx0, 22 + bob, bx1, 37 + bob], fill=body)
        auto_shade(img, body, body_l, body_d)
        for y in range(25 + bob, 36 + bob, 3):
            for x in range(bx0 + 2, bx1 - 1, 4):
                d.line([x, y, x + 2, y], fill=body_d)
        d.rectangle([bx0, 31 + bob, bx1, 33 + bob], fill=trim)              # đai lưng
        d.rectangle([21 + lean, 31 + bob, 25 + lean, 33 + bob], fill=gold)
        d.ellipse([20 + lean, 24 + bob, 26 + lean, 29 + bob], fill=trim)    # hộ tâm kính
        d.point([22 + lean, 25 + bob], fill=hexc("ffffff"))
        # vai giáp
        d.ellipse([9 + lean, 20 + bob, 17 + lean, 26 + bob], fill=trim)
        d.ellipse([29 + lean, 20 + bob, 37 + lean, 26 + bob], fill=trim)
        # đầu
        d.ellipse([15 + lean, 7 + bob, 31 + lean, 23 + bob], fill=skin)
        d.chord([15 + lean, 7 + bob, 31 + lean, 23 + bob], 90, 180, fill=skin_d)
        ex = 25 + lean
        eye = hexc("e8202a") if f == 5 else dark
        d.rectangle([ex - 4, 14 + bob, ex - 3, 16 + bob], fill=eye)
        d.rectangle([ex + 1, 14 + bob, ex + 2, 16 + bob], fill=eye)
        d.line([ex - 6, 12 + bob, ex - 2, 13 + bob], fill=dark)        # lông mày giận
        d.line([ex + 4, 12 + bob, ex, 13 + bob], fill=dark)
        if cfg["beard"]:
            d.polygon([(19 + lean, 19 + bob), (29 + lean, 19 + bob), (27 + lean, 26 + bob), (24 + lean, 28 + bob), (21 + lean, 26 + bob)], fill=dark)
            d.line([ex - 4, 19 + bob, ex + 3, 19 + bob], fill=hexc("4b3d58"))
        else:
            d.line([ex - 3, 20 + bob, ex + 1, 20 + bob], fill=skin_d)
        # mũ
        hat = cfg["hat"]
        if hat == "helmet":
            d.chord([14 + lean, 4 + bob, 32 + lean, 18 + bob], 180, 360, fill=hexc("c4803e"))
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=gold_d)
            d.polygon([(22 + lean, 0 + bob), (24 + lean, 0 + bob), (23 + lean, 5 + bob)], fill=gold)
            d.line([23 + lean, -1 + bob, 20 + lean + cape_sway // 2, -4 + bob], fill=hexc("d83a3a"), width=2)
        elif hat == "crown":
            d.rectangle([15 + lean, 6 + bob, 31 + lean, 10 + bob], fill=gold)
            for x in (15, 19, 23, 27, 31):
                d.polygon([(x - 2 + lean, 6 + bob), (x + lean, 1 + bob), (x + 2 + lean, 6 + bob)], fill=gold)
            d.point([23 + lean, 8 + bob], fill=hexc("4ad6a0"))
            d.point([19 + lean, 8 + bob], fill=hexc("d83a3a"))
            d.point([27 + lean, 8 + bob], fill=hexc("d83a3a"))
        elif hat == "fur":
            d.ellipse([12 + lean, 4 + bob, 34 + lean, 14 + bob], fill=hexc("6a4a3a"))
            d.chord([15 + lean, 0 + bob, 31 + lean, 12 + bob], 180, 360, fill=hexc("c43c3c"))
            d.ellipse([21 + lean, -2 + bob, 25 + lean, 2 + bob], fill=gold)
            for x in range(13, 34, 2):
                d.point([x + lean, 11 + bob], fill=hexc("a88a6a"))
        elif hat == "han_official":
            d.rectangle([16 + lean, 1 + bob, 30 + lean, 11 + bob], fill=hexc("2b2230"))
            d.rectangle([14 + lean, 9 + bob, 32 + lean, 11 + bob], fill=hexc("1a1420"))
            d.line([18 + lean, 3 + bob, 28 + lean, 3 + bob], fill=hexc("4b3d58"))
            d.rectangle([22 + lean, 5 + bob, 24 + lean, 7 + bob], fill=gold)
        elif hat == "steel_helmet":
            d.chord([14 + lean, 3 + bob, 32 + lean, 17 + bob], 180, 360, fill=hexc("8a92ac"))
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=hexc("565c74"))
            d.line([23 + lean, 3 + bob, 23 + lean + cape_sway // 2, -2 + bob], fill=hexc("d83a3a"), width=2)
            d.point([19 + lean, 6 + bob], fill=hexc("ffffff"))
        elif hat == "ming_helmet":
            d.chord([14 + lean, 2 + bob, 32 + lean, 18 + bob], 180, 360, fill=hexc("3a3448"))
            d.rectangle([13 + lean, 10 + bob, 33 + lean, 12 + bob], fill=gold_d)
            d.ellipse([21 + lean, -1 + bob, 25 + lean, 3 + bob], fill=hexc("d83a3a"))
            d.line([16 + lean, 7 + bob, 30 + lean, 7 + bob], fill=gold)
        elif hat == "pith":
            d.chord([13 + lean, 2 + bob, 33 + lean, 20 + bob], 180, 360, fill=hexc("f0ece0"))
            d.rectangle([11 + lean, 10 + bob, 35 + lean, 12 + bob], fill=hexc("c8c4b4"))
            d.line([15 + lean, 9 + bob, 31 + lean, 9 + bob], fill=hexc("6a4028"))
            d.point([18 + lean, 5 + bob], fill=hexc("ffffff"))
        elif hat == "kepi":
            d.rectangle([16 + lean, 3 + bob, 30 + lean, 10 + bob], fill=hexc("c83a32"))
            d.rectangle([15 + lean, 10 + bob, 31 + lean, 12 + bob], fill=hexc("2b2230"))
            d.line([17 + lean, 5 + bob, 29 + lean, 5 + bob], fill=gold)
            d.rectangle([28 + lean, 12 + bob, 33 + lean, 13 + bob], fill=hexc("1a1420"))
        elif hat == "official":
            d.chord([14 + lean, 3 + bob, 32 + lean, 15 + bob], 180, 360, fill=hexc("2b2230"))
            d.rectangle([12 + lean, 9 + bob, 34 + lean, 10 + bob], fill=hexc("2b2230"))
            d.ellipse([21 + lean, 0 + bob, 25 + lean, 4 + bob], fill=hexc("d83a3a"))
            d.line([(14 + lean, 6 + bob), (6 + lean + cape_sway // 2, 12 + bob)], fill=hexc("3a8a5a"), width=2)  # lông công
            d.point([6 + lean + cape_sway // 2, 12 + bob], fill=hexc("4ad6ff"))

        # tay vũ khí & cánh tay nối từ vai
        swing = f == 4
        w = cfg["weapon"]
        rx0, ry0 = 33 + lean, 23 + bob
        hx = 40 if swing else 35 + lean + arm_r[0]
        hy = 27 + bob if swing else 30 + bob + arm_r[1]
        d.line([(rx0, ry0), (hx, hy)], fill=body, width=4)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=trim)
        if w == "halberd":
            top = (47, 26) if swing else (min(46, hx + 8), max(1, hy - 26))
            d.line([(hx - 4, hy + 10), top], fill=hexc("6a4028"), width=2)
            d.polygon([(top[0] - 3, top[1]), (top[0] + 1, top[1] - 1), (top[0] + 1, top[1] + 6), (top[0] - 4, top[1] + 4)], fill=steel)
            if swing:
                d.arc([34, 8, 47, 36], -65, 35, fill=hexc("ffffff"), width=1)
        elif w == "trident":
            top = (47, 22) if swing else (min(46, hx + 4), max(1, hy - 28))
            d.line([(hx - 2, hy + 8), top], fill=gold_d, width=2)
            for dx in (-3, 0, 3):
                d.line([(min(47, top[0] + dx), top[1] + 4), (min(47, top[0] + dx), top[1])], fill=gold)
            d.line([(top[0] - 3, top[1] + 4), (min(47, top[0] + 3), top[1] + 4)], fill=gold)
            if swing:
                d.line([(hx + 2, hy - 4), (47, hy - 7)], fill=hexc("a8f0ff"))
        elif w == "saber":
            if swing:
                d.line([(hx, hy), (47, hy - 3)], fill=steel, width=2)
                d.arc([32, hy - 14, 47, hy + 8], -75, 25, fill=hexc("ffffff"), width=1)
            else:
                tip_x = min(46, hx + 8 + arm_r[0])
                tip_y = max(2, hy - 14)
                d.line([(hx, hy), (tip_x, tip_y)], fill=steel, width=2)
                d.point([tip_x, tip_y - 1], fill=steel)
            d.line([(hx - 2, hy + 1), (hx + 2, hy - 1)], fill=gold)
        elif w == "pistol":
            d.rectangle([hx, hy - 3, min(47, hx + (7 if swing else 6)), hy - 1], fill=hexc("3a3448"))
            d.rectangle([hx, hy - 1, hx + 2, hy + 2], fill=hexc("6a4028"))
            if swing:
                d.polygon([(46, hy - 4), (47, hy - 2), (46, hy), (44, hy - 2)], fill=hexc("ffe86a"))
        elif w == "cane":
            d.line([(hx, hy), (min(47, hx + 7), hy - 5)] if swing else [(hx, hy), (min(46, hx + 3), min(46, hy + 13))], fill=hexc("6a4028"), width=2)
            d.point([hx, hy - 1], fill=gold)
            if swing:
                d.arc([hx - 2, hy - 12, 47, hy + 6], -50, 30, fill=hexc("ffe88a"), width=1)
        elif w == "fan":
            d.pieslice([hx - 8, hy - 12, min(47, hx + 8), hy + 6], -100 if not swing else -40, -20 if not swing else 40, fill=hexc("ece8f4"))
            d.line([(hx, hy - 3), (min(47, hx + 7), hy - 9)], fill=gold)
            if swing:
                d.arc([hx - 4, hy - 14, 47, hy + 8], -55, 35, fill=hexc("d8f0ff"), width=1)
        d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=skin)
        if f == 6 and cfg["hat"] == "kepi":
            img, d = canvas(48, 48)
            for row, y in enumerate((34, 28, 22)):
                for x in range(6 + row * 3, 42 - row * 3, 8):
                    d.ellipse([x, y, x + 9, y + 7], fill=hexc("a88a5a"))
            auto_shade(img, hexc("a88a5a"), hexc("d0b080"), hexc("6a5434"))
            d.rectangle([16, 14, 32, 22], fill=hexc("2a2418"))
            d.rectangle([18, 16, 30, 20], fill=hexc("120e0a"))
            d.rectangle([22, 17, 26, 19], fill=hexc("c83a32"))
            d.line([(30, 18), (40, 16)], fill=hexc("3a3448"), width=2)
            d.rectangle([14, 12, 34, 14], fill=hexc("5a5a3a"))
        if f == 6 and cfg["hat"] == "fur":
            # Thoát Hoan chui vào ống đồng!
            img, d = canvas(48, 48)
            d.ellipse([6, 18, 42, 44], fill=hexc("c4803e"))
            d.rectangle([10, 18, 38, 44], fill=hexc("c4803e"))
            auto_shade(img, hexc("c4803e"), hexc("f2b878"), hexc("7a4622"))
            d.ellipse([8, 12, 40, 26], fill=hexc("7a4622"))
            d.ellipse([12, 15, 36, 24], fill=hexc("2a1414"))
            d.rectangle([20, 14, 21, 17], fill=hexc("ffffff"))   # đôi mắt ló ra
            d.rectangle([26, 14, 27, 17], fill=hexc("ffffff"))
            d.point([21, 16], fill=dark)
            d.point([27, 16], fill=dark)
            for y in (28, 36):
                d.line([10, y, 38, y], fill=hexc("7a4622"), width=2)
        frames.append(polish(img))
    return frames


def tank_frames():
    body, bl, bd = hexc("6a6a3a"), hexc("9a9a5a"), hexc("3e3e22")
    fr = []
    for f in range(4):
        img, d = canvas(40, 30)
        d.rectangle([3, 18, 37, 26], fill=hexc("2e2e20"))
        for x in range(5, 37, 5):
            d.ellipse([x - 2 + (f % 2), 20, x + 2 + (f % 2), 25], fill=hexc("5a5a4a"))
        d.polygon([(4, 18), (8, 11), (34, 11), (37, 18)], fill=body)
        auto_shade(img, body, bl, bd)
        d.ellipse([12, 4, 28, 14], fill=body)
        d.rectangle([26, 7, 39 - (2 if f == 3 else 0), 9], fill=bd)
        d.rectangle([16, 6, 19, 8], fill=bl)
        d.point([20, 4], fill=hexc("2e2e20"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/xe_tang.png")


def chan_tinh_frames():
    sk, sl, sd = hexc("6a8a5a"), hexc("9ab886"), hexc("3e5a36")
    fr = []
    for f in range(4):
        img, d = canvas(30, 32)
        bob = [0, -1, 0, -1][f]
        lo = [(0, 2), (1, 1), (2, 0), (1, 1)][f]
        d.rectangle([9, 24, 13, 30 - lo[0]], fill=sd)
        d.rectangle([17, 24, 21, 30 - lo[1]], fill=sk)
        d.ellipse([5, 10 + bob, 25, 27 + bob], fill=sk)
        d.ellipse([8, 2 + bob, 22, 15 + bob], fill=sk)
        auto_shade(img, sk, sl, sd)
        d.rectangle([7, 20 + bob, 23, 24 + bob], fill=hexc("7a4a2e"))
        d.polygon([(9, 4 + bob), (7, -1 + bob), (12, 3 + bob)], fill=hexc("e8dcc0"))
        d.polygon([(21, 4 + bob), (23, -1 + bob), (18, 3 + bob)], fill=hexc("e8dcc0"))
        d.rectangle([11, 7 + bob, 12, 8 + bob], fill=hexc("ff3a2a"))
        d.rectangle([17, 7 + bob, 18, 8 + bob], fill=hexc("ff3a2a"))
        d.line([12, 12 + bob, 18, 12 + bob], fill=hexc("2a1414"))
        d.point([12, 13 + bob], fill=hexc("ffffff"))
        d.point([17, 13 + bob], fill=hexc("ffffff"))
        d.line([(25, 16 + bob), (29, 10 + bob - f % 2)], fill=hexc("7a4a2e"), width=3)
        d.ellipse([26, 5 + bob - f % 2, 30, 10 + bob - f % 2], fill=hexc("5a3a22"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/chan_tinh.png")


def dai_bang_frames():
    br, bl, bd = hexc("7a5030"), hexc("a8784a"), hexc("4a2e18")
    fr = []
    for f in range(4):
        img, d = canvas(36, 26)
        wing = [-8, -3, 4, -3][f]
        d.polygon([(16, 12), (2, 12 + wing), (8, 15), (16, 16)], fill=br)
        d.polygon([(20, 12), (34, 12 + wing), (28, 15), (20, 16)], fill=br)
        d.ellipse([12, 9, 24, 21], fill=br)
        auto_shade(img, br, bl, bd)
        d.ellipse([20, 5, 28, 13], fill=hexc("b8884a"))
        d.line([(21, 7), (25, 6)], fill=hexc("e0b870"))
        d.polygon([(27, 8), (32, 10), (27, 11)], fill=hexc("f0b030"))
        d.point([24, 8], fill=hexc("1a1222"))
        d.line([(15, 21), (14, 24)], fill=hexc("f0b030"))
        d.line([(20, 21), (21, 24)], fill=hexc("f0b030"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/dai_bang.png")


def ma_troi_frames():
    fr = []
    for f in range(4):
        img, d = canvas(14, 18)
        h = [0, 1, 2, 1][f]
        d.polygon([(2, 12), (7, 1 + h), (12, 12)], fill=hexc("4aa8ff", 200))
        d.ellipse([2, 7, 12, 16], fill=hexc("4aa8ff", 210))
        d.ellipse([4, 9, 10, 15], fill=hexc("bff0ff"))
        d.point([5, 11], fill=hexc("1a2a4a"))
        d.point([8, 11], fill=hexc("1a2a4a"))
        fr.append(img)
    save(sheet(fr), "enemies/ma_troi.png")


def ship_frames():
    """Tàu chiến Hy Vọng: thân gỗ, buồm phồng, sóng rẽ nước, ống khói, đại bác. 7 khung."""
    hull, hl, hd = hexc("5a3a22"), hexc("8a5a34"), hexc("3a2214")
    fr = []
    for f in range(7):
        img, d = canvas(64, 44)
        w = f % 4
        bob = [0, 1, 0, -1][w] if f < 4 else (1 if f == 4 else 0)
        sail_bulge = [0, 3, 1, -1][w] if f < 4 else 4
        wake = [0, 2, 4, 1][w]
        d.ellipse([0, 34 + bob, 63, 43 + bob], fill=hexc("2a6aa8", 160))
        d.arc([2 + wake, 35 + bob, 61, 42 + bob], 10, 170, fill=hexc("9ee0ff"), width=1)
        if f == 4:
            # Sóng rẽ mũi tàu khi húc tới
            d.line([(56, 33 + bob), (63, 30 + bob)], fill=hexc("ffffff"), width=2)
            d.line([(54, 37 + bob), (63, 36 + bob)], fill=hexc("bce8ff"), width=1)
        d.polygon([(2, 26 + bob), (62, 26 + bob), (56, 38 + bob), (8, 38 + bob)], fill=hull)
        auto_shade(img, hull, hl, hd)
        d.line([(4, 27 + bob), (60, 27 + bob)], fill=hexc("e8e4f0"))
        for x in (14, 26, 38, 50):
            d.rectangle([x, 30 + bob, x + 3, 32 + bob], fill=hexc("1a1210"))
            if f == 4:
                d.ellipse([x - 2, 33 + bob, x + 6, 39 + bob], fill=hexc("ffd84a"))
        d.line([(24, 26 + bob), (24, 2 + bob)], fill=hexc("3a2214"), width=2)
        d.polygon([(25, 4 + bob), (40 + sail_bulge, 8 + bob), (40 + sail_bulge, 22 + bob), (25, 24 + bob)], fill=hexc("e8e4d8"))
        d.line([(25, 14 + bob), (40 + sail_bulge, 15 + bob)], fill=hexc("c8c4b4"))
        d.rectangle([44, 14 + bob, 48, 26 + bob], fill=hexc("2a2420"))
        sx = 42 - (w * 2 if f < 4 else 4)
        d.ellipse([sx, 8 + bob - (f % 2), sx + 8, 14 + bob - (f % 2)], fill=hexc("6a6070", 180))
        d.rectangle([22, 2 + bob, 30, 6 + bob], fill=hexc("2a3a8a"))
        d.rectangle([24, 2 + bob, 26, 6 + bob], fill=hexc("ffffff"))
        d.rectangle([28, 2 + bob, 30, 6 + bob], fill=hexc("c83a32"))
        if f >= 5:   # bốc cháy
            for x in range(8, 58, 7):
                d.polygon([(x, 27 + bob), (x + 3, 16 + bob - (x % 5)), (x + 6, 27 + bob)], fill=hexc("ff8a2a"))
                d.polygon([(x + 2, 27 + bob), (x + 3, 21 + bob), (x + 4, 27 + bob)], fill=hexc("ffe060"))
        fr.append(polish(img))
    save(sheet(fr), "enemies/boss_tau_hy_vong.png")


def build():
    for army in ARMIES:
        kinds = ("bo_binh", "linh_sung", "xa_thu", "phao_binh") if army.startswith("phap") else ("bo_binh", "cung_thu", "khien_binh", "phap_su")
        for kind in kinds:
            save(sheet(soldier_frames(army, kind)), f"enemies/{army}_{kind}.png")
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
