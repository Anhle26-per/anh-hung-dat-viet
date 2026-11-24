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


# ---------------------------------------------------------------- Quái
E = {
    "a": hexc("6cc44a"), "A": hexc("3a7a3a"), "B": hexc("a8e870"),
    "i": hexc("f4ecd8"), "I": hexc("b8a888"),
    "w": hexc("ffffff"), "r": hexc("e8303a"), "K": hexc("3a1428"),
    "f": hexc("ec8a3a"), "F": hexc("a8482a"), "L": hexc("ffbe7a"), "W": hexc("d8c8c0"),
    "e": hexc("2a1d2e"), "n": hexc("2a1d2e"), "u": hexc("7ad8ff"), "U": hexc("2a8ae0"),
}

TIEU_YEU = [
    "",
    "...i........i",
    "...iI......Ii",
    "....iBaaaaaI",
    "...aBBaaaaaaa",
    "..aBaaaaaaaaaA",
    "..aBwraaawraaA",
    "..aawraaawraaA",
    "..aaaaaaaaaaaA",
    "..aaKwKwKwKaaA",
    "..AaaKKKKKaaAA",
    "...AaaaaaaaAA",
    "..a.AAAAAAAA.a",
]
TIEU_YEU_LEGS = [
    ["....aA....aA", "....AA....AA"],
    ["...aA......aA", "...AA......AA"],
    ["....aA....aA", "....AA....AA"],
    [".....aA..aA", ".....AA..AA"],
]

HO_TINH = [
    "",
    "..w..........F..F",
    ".wLw........fF.fF",
    ".wLfw.......ffffff",
    "..fLf......fLffffff",
    "..fFf.....fLfeefffff",
    "..ffF....fffffffwwwn",
    ".fffF...ffffffwwwww",
    ".ffFF.fLffffffwww",
    "..fFFfLffffffffw",
    "...FFffffffffffF",
    ".....FffffffffF",
]
HO_TINH_LEGS = [
    [".....fF.fF..fF.fF", ".....ww.ww..ww.ww"],
    ["....fF...fF.fF..fF", "....ww...ww.ww..ww"],
    [".....fF.fF..fF.fF", ".....ww.ww..ww.ww"],
    ["......fFfF...fFfF", "......wwww...wwww"],
]


def _enemy_frames(up, legs_list, pal, size, up_y, leg_y, bobs):
    frames = []
    for i, legs in enumerate(legs_list):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        img.alpha_composite(grid(legs, pal, size[0]), (0, leg_y))
        img.alpha_composite(grid(up, pal, size[0]), (0, up_y + bobs[i]))
        frames.append(polish(img))
    return frames


def build_enemies():
    save(sheet(_enemy_frames(TIEU_YEU, TIEU_YEU_LEGS, E, (16, 17), 0, 13, [0, -1, 0, 1])), "enemies/tieu_yeu.png")
    fox = _enemy_frames(HO_TINH, HO_TINH_LEGS, E, (22, 16), 0, 12, [0, -1, 0, -1])
    # đốm ma trơi xanh bay quanh hồ tinh
    for i, f in enumerate(fox):
        d = ImageDraw.Draw(f)
        y = 2 + [0, 1, 2, 1][i]
        d.point([20, y], fill=E["u"])
        d.point([20, y + 1], fill=E["U"])
        d.point([19, y + 1], fill=E["u"])
    save(sheet(fox), "enemies/ho_tinh.png")
    save(sheet(_moc_tinh()), "enemies/moc_tinh.png")
    save(sheet(_ngu_tinh()), "enemies/ngu_tinh.png")


def _moc_tinh():
    bark, bark_l, bark_d = hexc("7a4e2e"), hexc("a8744a"), hexc("4a2e1e")
    leaf, leaf_l, leaf_d = hexc("4a9a3a"), hexc("86d05a"), hexc("2a5a2e")
    rng = random.Random(7)
    frames = []
    for f in range(4):
        img, d = canvas(26, 28)
        sway = [0, 1, 0, -1][f]
        # rễ chân
        lo = [(0, 2), (1, 1), (2, 0), (1, 1)][f]
        d.line([9, 22, 6 - lo[0], 26], fill=bark_d, width=2)
        d.line([16, 22, 19 + lo[1], 26], fill=bark_d, width=2)
        # thân
        d.rectangle([8, 11, 17, 23], fill=bark)
        auto_shade(img, bark, bark_l, bark_d)
        for y in range(13, 23, 3):
            d.line([10, y, 11, y + 1], fill=bark_d)
            d.point([15, y + 1], fill=bark_d)
        # cành tay
        d.line([8, 15, 3, 12 + sway], fill=bark, width=2)
        d.line([17, 15, 22, 12 - sway], fill=bark, width=2)
        d.point([2, 11 + sway], fill=leaf)
        d.point([23, 11 - sway], fill=leaf)
        # tán lá
        for cx, cy, r in ((8, 7, 6), (17, 7, 6), (12 + sway, 4, 6), (12, 9, 5)):
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf)
        auto_shade(img, leaf, leaf_l, leaf_d)
        px = img.load()
        for _ in range(16):
            x, y = rng.randint(3, 22), rng.randint(0, 12)
            if px[x, y] == leaf:
                px[x, y] = leaf_d if rng.random() < 0.5 else leaf_l
        # mặt: hốc mắt tối với mắt vàng rực, lông mày giận, miệng răng cưa
        dark = hexc("24140e")
        d.rectangle([9, 13, 11, 15], fill=dark)
        d.rectangle([14, 13, 16, 15], fill=dark)
        d.rectangle([10, 14, 11, 15], fill=hexc("ffd84a"))
        d.rectangle([14, 14, 15, 15], fill=hexc("ffd84a"))
        d.point([10, 14], fill=hexc("fff8c0"))
        d.point([14, 14], fill=hexc("fff8c0"))
        d.line([8, 11, 11, 12], fill=dark)
        d.line([14, 12, 17, 11], fill=dark)
        d.rectangle([10, 17, 15, 19], fill=dark)
        for x in (10, 12, 14):
            d.point([x, 17], fill=hexc("e8dcc0"))
        for x in (11, 13, 15):
            d.point([x, 19], fill=hexc("e8dcc0"))
        frames.append(polish(img))
    return frames


def _ngu_tinh():
    """Trùm Ngư Tinh: cá yêu khổng lồ. 6 khung: bơi(4) + há miệng(1) + gồng(1)."""
    body, body_l, body_d = hexc("2e8a9a"), hexc("5ec8c8"), hexc("1a4e6a")
    belly, belly_l, belly_d = hexc("e8d8a8"), hexc("fff4d0"), hexc("b8a078")
    fin, fin_l, fin_d = hexc("c84a5a"), hexc("f07a7a"), hexc("7a2a44")
    frames = []
    for f in range(6):
        img, d = canvas(60, 46)
        t = f % 4
        sway = [0, 2, 0, -2][t] if f < 4 else 0
        mouth_open = f == 4
        rage = f == 5
        cy = 24
        # đuôi
        d.polygon([(14, cy), (2, cy - 12 + sway), (6, cy + sway // 2), (2, cy + 12 + sway)], fill=fin)
        auto_shade(img, fin, fin_l, fin_d)
        # vây lưng (gai)
        for i, x in enumerate(range(20, 42, 5)):
            h = 10 - abs(i - 2) * 2
            d.polygon([(x, cy - 11), (x + 3, cy - 11 - h + (sway if i % 2 else 0) // 2), (x + 6, cy - 11)], fill=fin)
        # thân
        d.ellipse([10, cy - 14, 52, cy + 14], fill=body)
        auto_shade(img, body, body_l, body_d)
        # bụng
        d.chord([14, cy - 2, 50, cy + 14], 0, 180, fill=belly)
        auto_shade(img, belly, belly_l, belly_d)
        # vảy
        px = img.load()
        for row, y in enumerate(range(cy - 10, cy, 4)):
            for x in range(18 + (row % 2) * 3, 46, 6):
                for dx in range(4):
                    if px[x + dx, y + (1 if dx in (0, 3) else 2)] == body:
                        px[x + dx, y + (1 if dx in (0, 3) else 2)] = body_d
        # vây ngực
        fy = [0, 2, 3, 1][t]
        d.polygon([(27, cy + 10), (35, cy + 10), (31, cy + 19 + fy), (24, cy + 16 + fy)], fill=fin)
        d.line([(28, cy + 12), (27, cy + 16 + fy)], fill=fin_d)
        d.line([(31, cy + 12), (30, cy + 17 + fy)], fill=fin_d)
        # râu dài
        d.line([(50, cy + 2), (56, cy + 6), (58, cy + 12 + sway // 2)], fill=fin_d)
        d.line([(48, cy - 6), (54, cy - 12), (58, cy - 13 - sway // 2)], fill=fin_d)
        # mắt
        ex, ey = 43, cy - 5
        d.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], fill=hexc("fff4c0"))
        pupil = hexc("e8202a") if rage else hexc("1a1222")
        d.rectangle([ex, ey - 2, ex + 1, ey + 2], fill=pupil)
        d.line([(ex - 4, ey - 5), (ex + 3, ey - 3)], fill=body_d, width=2)
        # miệng + răng
        if mouth_open:
            d.polygon([(52, cy - 1), (44, cy + 3), (52, cy + 10)], fill=hexc("3a0e22"))
            for y in range(cy, cy + 10, 3):
                d.point([50, y], fill=hexc("ffffff"))
        else:
            d.line([(52, cy + 2), (45, cy + 4)], fill=hexc("3a0e22"))
            d.point([49, cy + 3], fill=hexc("ffffff"))
            d.point([47, cy + 4], fill=hexc("ffffff"))
        if rage:
            for y in range(46):
                for x in range(60):
                    c = px[x, y]
                    if c[3] and c not in (hexc("fff4c0"),):
                        px[x, y] = (min(255, c[0] + 40), c[1], c[2], 255)
        frames.append(polish(img))
    return frames


def build():
    grips = build_weapons()
    build_ally()
    build_elephant()
    build_enemies()
    return grips


if __name__ == "__main__":
    print(build())
