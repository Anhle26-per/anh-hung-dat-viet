"""Vũ khí, binh sĩ, voi chiến, quái và trùm."""
import math
import random
from px import hexc, grid, outline, polish, sheet, save, canvas, auto_shade, shade, Image, ImageDraw

W = {
    "o": hexc("9a6234"), "O": hexc("5e3a20"),            # gỗ
    "m": hexc("d8dce8"), "M": hexc("8a92ac"), "n": hexc("ffffff"),   # kim loại
    "g": hexc("e8b04a"), "G": hexc("a86a2a"), "y": hexc("fff0a0"),   # vàng
    "r": hexc("e04848"), "R": hexc("8e2632"),            # đỏ
    "s": hexc("f5c7a1"), "S": hexc("d4957a"),            # tay
    "j": hexc("9db04c"), "J": hexc("62702e"),            # tre
    "z": hexc("c4803e"), "Z": hexc("7a4622"), "x": hexc("f2b878"),   # đồng
    "k": hexc("ece8f4"), "v": hexc("4ad6a0"), "V": hexc("1f8a6a"),   # dây, ngọc
    "e": hexc("2a1d2e"),
}

# Mỗi vũ khí: lưới (chĩa sang phải) và điểm cầm (x, y) — xoay quanh điểm này.
WEAPONS = {
    "giao": ((7, 3), [
        "",
        ".......................mn",
        ".....sss..........gg..mmnm",
        "ooooosssooooooooooGgrmmmmmmn",
        "OOOOOsSSOOOOOOOOOOGGr.MMMM",
        "...................rR",
        "...................R",
    ]),
    "kiem": ((2, 3), [
        "",
        "....yg",
        "RsssgGnnnnnnnnnnnnm",
        "gsssgGmmmmmmmmmmmmmm",
        "RsSSgGMMMMMMMMMMMM",
        "....yG",
        "",
    ]),
    "dao": ((7, 6), [
        "",
        ".........................nm",
        "......................nmmmM",
        "....................nmmmmmM",
        "..................gnmmmmmmM",
        "......sss.......gGmmmmmmMM",
        "oooooosssooooooogGmmmmMM",
        "OOOOOOsSSOOOOOOOGG",
        "...............rR",
        "...............R",
        "",
    ]),
    "cung": ((9, 9), [
        "...kkkgo",
        "..k....oO",
        "..k.....oO",
        "..k.....oO",
        "..k......oO",
        "..k......oO",
        "..k......oO",
        "..k......rR",
        "..k.....sss",
        "..k.....sSS",
        "..k.....sSS",
        "..k......rR",
        "..k......oO",
        "..k......oO",
        "..k......oO",
        "..k.....oO",
        "..k.....oO",
        "..k....oO",
        "...kkkgo",
    ]),
    "no": ((5, 5), [
        "............oO",
        "...........k.oO",
        "..........k..oO",
        ".....sss.k...oO",
        "......mmmmmmmmmmmn",
        "oooosssoooooooogGoo",
        "OOOOsSSOOOOOOOGGO",
        ".....O...k...oO",
        "..........k..oO",
        "...........k.oO",
        "............oO",
    ]),
    "no_lien_chau": ((5, 7), [
        "..............gy",
        ".......GggggG.k.gy",
        ".......gvVyvgk..gy",
        ".......gyyyyGk...gy",
        "......kGGGGGG....gy",
        ".....sss.........gy",
        "......mmmmmmmmmmmmmn",
        "gggggsssggggggggyGgg",
        "GGGGGsSSGGGGGGGGGGG",
        ".....G.......k...gy",
        ".............k..gy",
        "..............kgy",
        "..............gy",
    ]),
    "hoa_ho": ((4, 3), [
        "",
        "...sss",
        "...sssgyjjjgjjjjgjzz",
        "ooosssgjjjjgjjjjgjzZ",
        "OOOsSSGjjjjGjjjjGjZZ",
        "...SSSGJJJJGJJJJGJZ",
        "",
    ]),
    "than_co_sang": ((4, 4), [
        ".........r",
        "........xz...........zx",
        ".......zxxxzxxxxxzxxxzxx",
        "...sss.zzzzZzzzzzZzzzzzz",
        "ooosss.zzzzZzzzzzZzzzzzz",
        "OOOsSS.ZZZZZZZZZZZZZZZZZ",
        ".......ZZZZZZZZZZZZZZZZ",
        "........Z............ZZ",
    ]),
    "hoa_tien": ((4, 4), [
        "..................mn",
        "......oooooooooooo...",
        "...sssrRooRRooooRRmmmn",
        "...sssoooooooooooo",
        "oooSSSrRooRRooooRRmmmn",
        "......OOOOOOOOOOOO",
        "......rRooRRooooRRmmmn",
        "......OOOOOOOOOOOO..mn",
    ]),
}


def build_weapons():
    grips = {}
    for wid, (grip, rows) in WEAPONS.items():
        w = max(len(r) for r in rows) + 2
        img = grid([""] + ["." + r for r in rows] + [""], W, w)
        img = outline(img)
        save(img, f"weapons/{wid}.png")
        grips[wid] = (grip[0] + 1, grip[1] + 1)
    return grips


# ---------------------------------------------------------------- Binh sĩ (Hịch tướng sĩ)
ALLY_PAL = dict(W)
ALLY_PAL.update({"1": hexc("c43c3c"), "2": hexc("862434"), "3": hexc("f07a62"),
                 "4": hexc("e8b04a"), "h": hexc("2b2230"), "p": hexc("3a3550"), "P": hexc("262236"),
                 "q": hexc("6b4630"), "Q": hexc("3e2619"), "b": hexc("ee8d8a")})
ALLY_UP = [
    "........y......mn",
    ".......gyg.....mn",
    "......gyggG....rR",
    ".....gyggggG...o",
    "...GGGGGGGGGGG.o",
    "....hhsssssS...o",
    "....hssesesS...o",
    "....hsssbssS...o",
    ".....SssssS....o",
    ".....13111112..o",
    ".....31111112..o",
    ".....4444g444sso",
    ".....2111111ssO",
    ".....2212212...O",
]
ALLY_LEGS = [
    [".....ppppPP", "......pP.pP", "......qQ.qQ", ".....qqQ.qqQ"],
    [".....ppppPP", ".....pP...pP", "....qQ.....qQ", "....qQ.....qqQ"],
    [".....ppppPP", "......ppPP", "......qQqQ", "........qqQ"],
    [".....PPppppp", ".....PP...pP", "....QQ.....qQ", "....qQ.....qqQ"],
]


def build_ally():
    frames = []
    for i, legs in enumerate(ALLY_LEGS):
        img = Image.new("RGBA", (18, 20), (0, 0, 0, 0))
        bob = -1 if i % 2 == 1 else 0
        img.alpha_composite(grid(legs, ALLY_PAL, 18), (0, 15))
        if bob:
            img.alpha_composite(grid([legs[0]], ALLY_PAL, 18), (0, 14))
        img.alpha_composite(grid(ALLY_UP, ALLY_PAL, 18), (0, 1 + bob))
        frames.append(polish(img))
    save(sheet(frames), "fx/ally.png")


# ---------------------------------------------------------------- Voi chiến (Bà Triệu)
def build_elephant():
    G = hexc("8e8ea8")
    GL = hexc("b8b8cc")
    GD = hexc("5e5e7a")
    EAR = hexc("7a7a96")
    frames = []
    for f in range(4):
        img, d = canvas(40, 30)
        lift = [0, 1, 0, 1][f]
        leg_off = [(0, 2), (1, 1), (2, 0), (1, 1)][f]
        # chân (sau trước)
        for x, ph in ((8, 0), (14, 1), (22, 0), (28, 1)):
            off = leg_off[ph]
            d.rectangle([x, 19 - lift, x + 4, 26 - off], fill=GD if ph else G)
            d.rectangle([x, 26 - off, x + 4, 27 - off], fill=hexc("d8d0c0"))
        # thân
        d.ellipse([4, 6 - lift, 32, 23 - lift], fill=G)
        # đuôi
        d.line([5, 11 - lift, 2, 17 - lift], fill=GD, width=1)
        d.point([2, 18 - lift], fill=hexc("3a3048"))
        # đầu
        d.ellipse([25, 3 - lift, 37, 16 - lift], fill=G)
        # vòi cong
        d.line([35, 12 - lift, 37, 18 - lift], fill=G, width=3)
        d.line([37, 18 - lift, 36, 22 - lift], fill=G, width=2)
        d.point([35, 23 - lift], fill=G)
        auto_shade(img, G, GL, GD)
        # tai
        d.polygon([(25, 5 - lift), (30, 6 - lift), (31, 13 - lift), (27, 17 - lift), (23, 14 - lift)], fill=EAR)
        d.line([(26, 7 - lift), (27, 14 - lift)], fill=GD)
        # ngà
        d.line([33, 14 - lift, 38, 13 - lift], fill=hexc("f4ecd8"), width=1)
        d.point([33, 15 - lift], fill=hexc("c8bca0"))
        # mắt
        d.point([33, 8 - lift], fill=hexc("1a1222"))
        d.point([34, 8 - lift], fill=hexc("ffffff"))
        # vải phủ lưng đỏ, viền vàng, hoa văn
        d.polygon([(10, 5 - lift), (24, 5 - lift), (25, 14 - lift), (9, 14 - lift)], fill=hexc("c43c3c"))
        d.line([(9, 14 - lift), (25, 14 - lift)], fill=hexc("e8b04a"))
        for x in range(10, 25, 2):
            d.point([x, 15 - lift], fill=hexc("e8b04a"))
        d.line([(11, 6 - lift), (23, 6 - lift)], fill=hexc("f07a62"))
        d.rectangle([15, 8 - lift, 18, 11 - lift], fill=hexc("e8b04a"))
        d.point([16, 9 - lift], fill=hexc("c43c3c"))
        d.point([17, 10 - lift], fill=hexc("c43c3c"))
        frames.append(polish(img))
    save(sheet(frames), "fx/elephant.png")


# ---------------------------------------------------------------- Ngựa sắt phun lửa (Thánh Gióng)
def build_iron_horse():
    """Ngựa sắt chiến mã của Thánh Gióng: 4 khung phi nước đại, kích thước khớp voi chiến (40x30)."""
    M = hexc("7888a4")
    ML = hexc("b8c8e2")
    MD = hexc("46526c")
    MN = hexc("e8f0ff")
    HOOF = hexc("2c3448")
    GOLD = hexc("f4be44")
    GOLD_L = hexc("fff098")
    GOLD_D = hexc("a86a22")
    RED = hexc("cc3428")
    F_RED = hexc("e84020")
    F_ORG = hexc("ff8c24")
    F_YEL = hexc("ffe858")
    frames = []
    for f in range(4):
        img, d = canvas(40, 30)
        lift = [0, 1, 0, 1][f]
        # 4 chân phi nước đại (chân sau xa, chân trước xa, chân sau gần, chân trước gần)
        rear_a = [(-3, 1), (-1, 0), (2, -1), (0, 0)][f]
        rear_b = [(2, -1), (0, 0), (-3, 1), (-1, 0)][f]
        front_a = [(3, -1), (1, 0), (-2, 1), (0, 0)][f]
        front_b = [(-2, 1), (0, 0), (3, -1), (2, -1)][f]

        # Chân xa (màu tối hơn)
        d.line([(10, 17 - lift), (8 + rear_b[0], 22 - lift), (7 + rear_b[0], 27 + rear_b[1])], fill=MD, width=3)
        d.rectangle([6 + rear_b[0], 26 + rear_b[1], 9 + rear_b[0], 28 + rear_b[1]], fill=HOOF)
        d.line([(24, 17 - lift), (26 + front_b[0], 22 - lift), (27 + front_b[0], 27 + front_b[1])], fill=MD, width=3)
        d.rectangle([26 + front_b[0], 26 + front_b[1], 29 + front_b[0], 28 + front_b[1]], fill=HOOF)

        # Đuôi lửa bùng cháy phía sau
        tw = [0, -1, 1, 0][f]
        d.polygon([(8, 12 - lift), (2, 10 - lift + tw), (1, 14 - lift + tw), (3, 17 - lift), (8, 15 - lift)], fill=F_RED)
        d.polygon([(8, 13 - lift), (3, 12 - lift + tw), (3, 15 - lift + tw), (7, 15 - lift)], fill=F_ORG)
        d.line([(7, 13 - lift), (4, 13 - lift + tw)], fill=F_YEL, width=1)

        # Thân ngựa sắt cơ bắp bọc giáp
        d.ellipse([7, 10 - lift, 28, 21 - lift], fill=M)
        # Cổ ngựa vươn cao oai vệ
        d.polygon([(22, 12 - lift), (27, 5 - lift), (32, 7 - lift), (28, 17 - lift)], fill=M)
        # Đầu ngựa sắt góc cạnh chiến mã
        d.polygon([(26, 4 - lift), (33, 4 - lift), (37, 10 - lift), (35, 13 - lift), (29, 11 - lift)], fill=M)
        # Tai sắt nhọn
        d.polygon([(27, 4 - lift), (28, 2 - lift), (30, 4 - lift)], fill=ML)
        d.polygon([(30, 4 - lift), (31, 2 - lift), (32, 4 - lift)], fill=M)

        # Chân gần (sáng hơn)
        d.line([(12, 17 - lift), (10 + rear_a[0], 22 - lift), (9 + rear_a[0], 27 + rear_a[1])], fill=M, width=3)
        d.rectangle([8 + rear_a[0], 26 + rear_a[1], 11 + rear_a[0], 28 + rear_a[1]], fill=HOOF)
        d.point([9 + rear_a[0], 27 + rear_a[1]], fill=GOLD)
        d.line([(25, 17 - lift), (28 + front_a[0], 22 - lift), (29 + front_a[0], 27 + front_a[1])], fill=M, width=3)
        d.rectangle([28 + front_a[0], 26 + front_a[1], 31 + front_a[0], 28 + front_a[1]], fill=HOOF)
        d.point([29 + front_a[0], 27 + front_a[1]], fill=GOLD)

        # Đổ bóng kim loại cho thân, cổ, đầu, chân
        auto_shade(img, M, ML, MD)

        # Đường giáp sắt & đinh tán sáng trên vai / hông
        d.line([(13, 12 - lift), (13, 19 - lift)], fill=MD)
        d.line([(23, 11 - lift), (23, 19 - lift)], fill=MD)
        d.point([11, 13 - lift], fill=MN)
        d.point([24, 13 - lift], fill=MN)
        d.point([26, 11 - lift], fill=MN)

        # Giáp ngực & giáp mặt viền vàng
        d.line([(27, 12 - lift), (29, 16 - lift)], fill=GOLD, width=2)
        d.point([28, 13 - lift], fill=GOLD_L)
        d.line([(31, 5 - lift), (36, 9 - lift)], fill=GOLD, width=1)
        d.point([33, 6 - lift], fill=GOLD_L)

        # Yên ngựa đỏ viền vàng rực rỡ
        d.polygon([(13, 9 - lift), (22, 9 - lift), (23, 16 - lift), (12, 16 - lift)], fill=RED)
        d.line([(12, 16 - lift), (23, 16 - lift)], fill=GOLD)
        for x in range(13, 23, 2):
            d.point([x, 17 - lift], fill=GOLD)
        d.line([(14, 10 - lift), (21, 10 - lift)], fill=GOLD_L)
        d.rectangle([16, 12 - lift, 19, 14 - lift], fill=GOLD)
        d.point([17, 13 - lift], fill=GOLD_D)

        # Bờm lửa vàng-cam rực cháy dọc cổ
        mw = [0, 1, 0, -1][f]
        d.polygon([(26, 4 - lift), (21, 4 - lift + mw), (19, 8 - lift), (22, 11 - lift), (26, 8 - lift)], fill=F_RED)
        d.polygon([(26, 5 - lift), (22, 6 - lift + mw), (21, 9 - lift), (25, 9 - lift)], fill=F_ORG)
        d.point([24, 6 - lift + mw], fill=F_YEL)
        d.point([23, 8 - lift], fill=F_YEL)

        # Mắt rực lửa
        d.point([31, 7 - lift], fill=hexc("1a1222"))
        d.point([32, 7 - lift], fill=F_YEL)
        d.point([33, 7 - lift], fill=MN)

        framed = polish(img)
        # Tia lửa phun ra từ mũi ngựa sắt (vẽ sau polish để sáng rực)
        fd = ImageDraw.Draw(framed)
        fl = [2, 3, 2, 1][f]
        nx, ny = 36, 11 - lift
        fd.point([nx, ny], fill=F_YEL)
        fd.point([min(39, nx + 1), ny], fill=F_ORG)
        fd.point([min(39, nx + 1), min(29, ny + 1)], fill=F_RED)
        if fl >= 2:
            fd.point([min(39, nx + 2), max(0, ny - 1)], fill=F_YEL)
            fd.point([min(39, nx + 2), ny + 1], fill=F_ORG)
        if fl >= 3:
            fd.point([39, ny], fill=F_YEL)
            fd.point([39, min(29, ny + 2)], fill=F_RED)
        frames.append(framed)
    save(sheet(frames), "fx/iron_horse.png")


# ---------------------------------------------------------------- Quái (8 khung chi tiết)
E = {
    "a": hexc("64cc4c"), "A": hexc("2d7236"), "B": hexc("b2f27a"), "C": hexc("1d4a26"),
    "i": hexc("f6eedc"), "I": hexc("b8a686"),
    "w": hexc("ffffff"), "r": hexc("ec363c"), "K": hexc("3a1428"),
    "f": hexc("f28d38"), "F": hexc("aa4626"), "L": hexc("ffd082"), "W": hexc("f6ece6"),
    "e": hexc("26182c"), "n": hexc("26182c"), "u": hexc("7ee6ff"), "U": hexc("288ee4"),
    "g": hexc("f0ba4a"), "G": hexc("a46824"), "c": hexc("d8f8ff"), "p": hexc("c850ff"),
}

TIEU_YEU = [
    "",
    "...i........i",
    "...iI......Ii",
    "....iBaaaaaI",
    "...aBBaaaaaaa",
    "..aBaaaaaaaaaA",
    "..aBwrraawrraA",
    "..aawrgaawrgaA",
    "..aaaaCCaaaaaA",
    "..aaKwKwKwKaaA",
    "..gGaaKKKKKaaA",
    "...AaaaaaaaAA",
    "..a.AAAAgAAA.a",
]
TIEU_YEU_HURT = [
    "",
    "...i........i",
    "...iI......Ii",
    "....iBaaaaaI",
    "...aBBaaaaaaa",
    "..aBaaaaaaaaaA",
    "..aBraaaawraaA",
    "..aaaraaaaraaA",
    "..aaaaCCaaaaaA",
    "..aaKKKKKKKaaA",
    "..gGaaKwwKaaAA",
    "...AaaaaaaaAA",
    "..a.AAAAgAAA.a",
]
TIEU_YEU_LEGS = [
    ["....aA....aA", "....AA....AA"],
    ["...aA......aA", "...AA......AA"],
    ["....aA....aA", "....AA....AA"],
    [".....aA..aA", ".....AA..AA"],
]

HO_TINH = [
    "",
    "..W..........F..F",
    ".WLW........fF.fF",
    ".WLfW.......ffffff",
    "..fLf......fLffffff",
    "..fFf.....fLfeefffff",
    "..ffF....fffffffWWWn",
    ".fffF...ffffffWWWWW",
    ".ffFF.fLffffffWWW",
    "..fFFfLffffffffW",
    "...FFfffffffffgF",
    ".....FffffffffF",
]
HO_TINH_LEGS = [
    [".....fF.fF..fF.fF", ".....WW.WW..WW.WW"],
    ["....fF...fF.fF..fF", "....WW...WW.WW..WW"],
    [".....fF.fF..fF.fF", ".....WW.WW..WW.WW"],
    ["......fFfF...fFfF", "......WWWW...WWWW"],
]


def _tieu_yeu():
    frames = []
    size = (16, 17)
    bobs = [0, -1, 0, -1, 1, -1, 1, -1]
    for f in range(8):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if f < 4:
            legs = TIEU_YEU_LEGS[f]
            dx = 0
            up = TIEU_YEU
        elif f == 4:
            legs = ["...aA......aA", "...AA......AA"]
            dx = -1
            up = TIEU_YEU
        elif f == 5:
            legs = ["..aA........aA", "..AA........AA"]
            dx = 1
            up = TIEU_YEU
        elif f == 6:
            legs = ["....aA....aA", "....AA....AA"]
            dx = 0
            up = TIEU_YEU
        else:
            legs = ["...aA......aA", "...AA......AA"]
            dx = -1
            up = TIEU_YEU_HURT
        img.alpha_composite(grid(legs, E, size[0]), (dx, 13))
        img.alpha_composite(grid(up, E, size[0]), (dx, max(0, bobs[f])))
        if f == 4:
            d.point([13, 10], fill=E["w"])
            d.point([12, 11], fill=E["B"])
        elif f == 5:
            d.line([(12, 7), (15, 5)], fill=E["w"])
            d.line([(12, 10), (15, 8)], fill=E["c"])
            d.line([(13, 12), (15, 11)], fill=E["u"])
        elif f == 6:
            d.point([14, 12], fill=E["B"])
        elif f == 7:
            d.point([2, 3], fill=E["r"])
            d.point([1, 5], fill=E["w"])
        frames.append(polish(img))
    return frames


def _ho_tinh():
    frames = []
    size = (22, 16)
    bobs = [0, -1, 0, -1, 1, -1, 0, 0]
    for f in range(8):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        legs = HO_TINH_LEGS[f % 4] if f < 4 else (HO_TINH_LEGS[1] if f in (4, 5) else HO_TINH_LEGS[0])
        dx = -1 if f in (4, 7) else (1 if f == 5 else 0)
        img.alpha_composite(grid(legs, E, size[0]), (max(-1, dx), 12))
        img.alpha_composite(grid(HO_TINH, E, size[0]), (max(-1, dx), max(0, bobs[f])))
        if f == 4:
            d.ellipse([18, 2, 21, 5], fill=E["u"])
            d.point([19, 3], fill=E["w"])
        elif f == 5:
            d.line([(18, 5), (21, 3)], fill=E["u"], width=2)
            d.point([21, 2], fill=E["w"])
            d.point([20, 6], fill=E["c"])
        elif f == 6:
            d.point([20, 4], fill=E["U"])
        elif f == 7:
            d.point([14, 5], fill=E["r"])
            d.point([15, 5], fill=E["r"])
            d.point([3, 3], fill=E["w"])
        else:
            y = 2 + [0, 1, 2, 1][f]
            d.point([20, y], fill=E["u"])
            d.point([20, y + 1], fill=E["U"])
            d.point([19, y + 1], fill=E["c"])
        frames.append(polish(img))
    return frames


def build_enemies():
    save(sheet(_tieu_yeu()), "enemies/tieu_yeu.png")
    save(sheet(_ho_tinh()), "enemies/ho_tinh.png")
    save(sheet(_moc_tinh()), "enemies/moc_tinh.png")
    save(sheet(_ngu_tinh()), "enemies/ngu_tinh.png")


def _moc_tinh():
    bark, bark_l, bark_d = hexc("7e5030"), hexc("b27b4e"), hexc("46291c")
    leaf, leaf_l, leaf_d = hexc("4ea23e"), hexc("90dc62"), hexc("285c2c")
    rng = random.Random(7)
    frames = []
    for f in range(8):
        img, d = canvas(26, 28)
        sway = [0, 1, 0, -1][f] if f < 4 else (-1 if f == 7 else 0)
        bob = [0, -1, 0, -1][f] if f < 4 else (1 if f == 5 else (-1 if f == 4 else 0))
        lo = [(0, 2), (1, 1), (2, 0), (1, 1)][f] if f < 4 else ((0, 0) if f in (4, 6) else (2, 2))
        d.line([9, 22 + bob, 6 - lo[0], 26], fill=bark_d, width=2)
        d.line([16, 22 + bob, 19 + lo[1], 26], fill=bark_d, width=2)
        d.rectangle([8, 11 + bob, 17, 23 + bob], fill=bark)
        auto_shade(img, bark, bark_l, bark_d)
        for y in range(13 + bob, 23 + bob, 3):
            d.line([10, y, 11, y + 1], fill=bark_d)
            d.point([15, y + 1], fill=bark_d)
        # Ấn cổ mộc phát sáng trước ngực
        rune_c = hexc("ffe86a") if f in (4, 5) else hexc("7af488")
        d.rectangle([12, 20 + bob, 13, 21 + bob], fill=rune_c)
        # Cành tay theo từng hoạt động
        if f == 4:
            d.line([8, 15 + bob, 3, 7], fill=bark, width=2)
            d.line([17, 15 + bob, 22, 7], fill=bark, width=2)
            d.point([2, 6], fill=leaf_l)
            d.point([23, 6], fill=leaf_l)
        elif f == 5:
            d.line([8, 15 + bob, 2, 22], fill=bark, width=2)
            d.line([17, 15 + bob, 23, 22], fill=bark, width=2)
            d.ellipse([1, 21, 5, 25], fill=leaf_l)
            d.ellipse([20, 21, 24, 25], fill=leaf_l)
        elif f == 7:
            d.line([8, 15 + bob, 4, 18], fill=bark, width=2)
            d.line([17, 15 + bob, 21, 18], fill=bark, width=2)
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
        eye_c = hexc("ff4838") if f == 7 else (hexc("fff8a8") if f in (4, 5) else hexc("ffd84a"))
        d.rectangle([10, 14 + bob, 11, 15 + bob], fill=eye_c)
        d.rectangle([14, 14 + bob, 15, 15 + bob], fill=eye_c)
        d.line([8, 11 + bob, 11, 12 + bob], fill=dark)
        d.line([14, 12 + bob, 17, 11 + bob], fill=dark)
        mouth_h = 3 if f in (4, 5) else 2
        d.rectangle([10, 17 + bob, 15, 17 + bob + mouth_h], fill=dark)
        for x in (10, 12, 14):
            d.point([x, 17 + bob], fill=hexc("e8dcc0"))
        for x in (11, 13, 15):
            d.point([x, 17 + bob + mouth_h], fill=hexc("e8dcc0"))
        if f == 5:
            d.line([(3, 26), (22, 26)], fill=hexc("a8f080"))
        elif f == 7:
            d.point([6, 12], fill=hexc("d8a060"))
            d.point([19, 12], fill=hexc("d8a060"))
        frames.append(polish(img))
    return frames


def _ngu_tinh():
    """Thủy quái Ngư Tinh (60x46 x 8 khung): 0-3 bơi, 4 lấy đà, 5 táp phun nước, 6 cuồng nộ, 7 trúng đòn."""
    body, body_l, body_d = hexc("2b92a8"), hexc("70e4dc"), hexc("154868")
    belly, belly_l, belly_d = hexc("f2e4b8"), hexc("fff8dc"), hexc("b89e74")
    fin, fin_l, fin_d = hexc("df4b58"), hexc("ff8a8a"), hexc("7e223c")
    frames = []
    for f in range(8):
        img, d = canvas(60, 46)
        t = f % 4
        sway = [0, 3, 0, -3][t] if f < 4 else (-4 if f == 4 else (4 if f == 5 else 0))
        dx = -2 if f in (4, 7) else (3 if f == 5 else 0)
        mouth_open = f in (4, 5)
        rage = f == 6
        cy = 24 + ([0, -1, 0, 1][t] if f < 4 else 0)
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
        fy = [0, 2, 3, 1][t] if f < 4 else (-2 if f == 4 else 3)
        d.polygon([(27 + dx, cy + 10), (35 + dx, cy + 10), (31 + dx, cy + 19 + fy), (24 + dx, cy + 16 + fy)], fill=fin)
        d.line([(28 + dx, cy + 12), (27 + dx, cy + 16 + fy)], fill=fin_d)
        d.line([(31 + dx, cy + 12), (30 + dx, cy + 17 + fy)], fill=fin_d)
        d.line([(50 + dx, cy + 2), (55 + dx, cy + 6), (min(59, 58 + dx), cy + 12 + sway // 2)], fill=hexc("f0b848"))
        d.line([(48 + dx, cy - 6), (54 + dx, cy - 12), (min(59, 58 + dx), cy - 13 - sway // 2)], fill=hexc("f0b848"))
        ex, ey = 43 + dx, cy - 5
        d.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=hexc("fff6c4"))
        pupil = hexc("e8202a") if rage or f == 7 else hexc("1a1222")
        d.rectangle([ex, ey - 2, ex + 1, ey + 2], fill=pupil)
        d.line([(ex - 4, ey - 5), (ex + 3, ey - 3)], fill=body_d, width=2)
        if mouth_open:
            d.polygon([(min(59, 52 + dx), cy - 1), (44 + dx, cy + 3), (min(59, 52 + dx), cy + 10)], fill=hexc("3a0e22"))
            for y in range(cy, cy + 10, 3):
                d.point([min(59, 50 + dx), y], fill=hexc("ffffff"))
            if f == 5:
                d.line([(min(59, 53 + dx), cy + 3), (59, cy + 2)], fill=hexc("9ee8ff"), width=2)
                d.line([(min(59, 53 + dx), cy + 6), (59, cy + 7)], fill=hexc("ffffff"))
        else:
            d.line([(min(59, 52 + dx), cy + 2), (45 + dx, cy + 4)], fill=hexc("3a0e22"))
            d.point([49 + dx, cy + 3], fill=hexc("ffffff"))
            d.point([47 + dx, cy + 4], fill=hexc("ffffff"))
        if rage:
            for y in range(46):
                for x in range(60):
                    c = px[x, y]
                    if c[3] and c not in (hexc("fff6c4"),):
                        px[x, y] = (min(255, c[0] + 45), int(c[1] * 0.9), int(c[2] * 0.9), 255)
        elif f == 7:
            d.ellipse([36, 12, 40, 15], fill=hexc("ffffff"))
        frames.append(polish(img))
    return frames


def build():
    grips = build_weapons()
    build_ally()
    build_elephant()
    build_iron_horse()
    build_enemies()
    return grips


if __name__ == "__main__":
    print(build())
