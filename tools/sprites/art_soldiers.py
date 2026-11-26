"""Lính giặc siêu mượt (khung 24x26 x 16 khung = 384x26):
  0..7:   đi bộ (walk) 8 nhịp uyển chuyển — chân, tay, vũ khí, áo choàng, chỏm lông nhịp nhàng
  8..9:   lấy đà (windup) — co thế -> căng cung/giương đao tối đa kèm tia chớp báo hiệu
  10..13: tấn công (attack) — lao chém/bắn -> vung hết tầm/lửa lớn -> vệt dư ảnh -> thu chiêu/nhả khói
  14..15: trúng đòn (hurt) — giật lùi lóe đỏ -> lảo đảo hồi phục
"""
from px import hexc, polish, sheet, save, Image
from art_enemies import ARMIES

W, H = 24, 26
FRAMES = 16

BASE = {
    "s": "f6c8a4", "S": "cf9276", "z": "9c645a", "E": "24162b", "w": "ffffff", "u": "7a2832",
    "h": "2b2230", "H": "4b3d58", "d": "181220",
    "m": "d0d8ea", "M": "808aa8", "n": "ffffff",
    "g": "f0b848", "G": "a86826", "y": "fff4a4",
    "o": "9c6436", "O": "5a361e", "k": "f2eefc", "r": "e23c3e", "R": "8c2232",
    "v": "b46cff", "V": "56268c", "c": "f2d6ff", "K": "66e4ff",
    "b": "7c4c30", "B": "482a18", "q": "4a3428", "Q": "2b1c18",
    "f": "ff9028", "F": "e44424", "Y": "fff688",
}


def R(x, pat):
    return (x, pat)


def _draw_rows(img, rows, pal, y0=0, dx=0, dy=0):
    px = img.load()
    for y, row in enumerate(rows):
        if row is None:
            continue
        segs = row if isinstance(row, list) else [row]
        for x0, pat in segs:
            for i, ch in enumerate(pat):
                if ch in ". ":
                    continue
                xx, yy = x0 + i + dx, y0 + y + dy
                if 0 <= xx < W and 0 <= yy < H:
                    px[xx, yy] = pal[ch]


HATS = {
    "dong_han": (
        {"a": "2d2436", "A": "181220", "x": "584a68"},
        [None, R(9, "xaaaa"), R(8, "xxaaaAA"), R(8, "aaagaaA"), R(7, "xaaaaaaaaA"), R(6, "AAggggggAAAA"), None],
        [(0, 9, "gg"), (0, 10, "r")],
    ),
    "dong_ngo": (
        {"a": "c88442", "A": "7c4620", "x": "f6c280"},
        [None, R(10, "xx"), R(9, "xaaA"), R(8, "xxaaaaA"), R(7, "xaaaaaaaaA"), R(6, "AAAggggAAAA"), [R(6, "A"), R(16, "A")]],
        [(0, 10, "rr"), (1, 10, "rR")],
    ),
    "nam_han": (
        {"a": "1e5268", "A": "0e2c3a", "x": "3c8ea0"},
        [None, None, R(8, "xaaaaa"), R(7, "xaxaxaaA"), R(7, "aaaaaaAA"), R(6, "gggggnggggg"), None],
        [(1, 10, "y"), (2, 9, "g")],
    ),
    "tong": (
        {"a": "aeb6cc", "A": "666e8e", "x": "eef4ff"},
        [None, R(9, "xax"), R(9, "xaaA"), R(8, "xaaaaAA"), R(7, "xaaaaaaaA"), R(6, "AAAmnmnMAAA"), [R(6, "A"), R(16, "A")]],
        [(0, 10, "r"), (1, 9, "rRr")],
    ),
    "nguyen_mong": (
        {"a": "74503c", "A": "402a1e", "x": "b49472"},
        [None, R(9, "rRr"), R(8, "rRrrr"), R(7, "xaxaxaxaA"), R(6, "axaxaxaxaxA"), R(6, "AAAAAAAAAAA"), None],
        [(0, 10, "g")],
    ),
    "minh": (
        {"a": "423a54", "A": "1e1a2a", "x": "6c6482"},
        [None, R(9, "xax"), R(8, "xaaaaA"), R(8, "xaaaaaaA"), R(7, "ggggngggG"), R(6, "AAAAAAAAAAA"), None],
        [(0, 10, "rr"), (1, 9, "rR")],
    ),
    "thanh": (
        {"a": "2c2434", "A": "181220", "x": "524464"},
        [None, R(9, "gGg"), R(8, "xaaaA"), R(7, "axaaaaaA"), R(5, "xaaaaaaaaaaaA"), R(4, "AAAggggggggAAAA"), None],
        [(0, 10, "r"), (1, 9, "rRr")],
    ),
    "phap_thuy": (
        {"a": "f0eef6", "A": "b2aec6", "x": "ffffff"},
        [None, R(10, "rr"), R(9, "rRr"), R(7, "xaaaaaaA"), R(6, "aaaaaaaaaA"), R(7, "333g3333"), None],
        [],
    ),
    "phap_vien_chinh": (
        {"a": "eeeadd", "A": "ada996", "x": "ffffff"},
        [None, R(8, "xaaaa"), R(7, "xaaaaaA"), R(6, "xaaaaaaaA"), R(6, "abbbgbbbbA"), R(4, "AAAAAAAAAAAAAA"), None],
        [],
    ),
    "phap_1954": (
        {"a": "626240", "A": "3a3a24", "x": "88885c"},
        [None, None, R(8, "xaaaa"), R(7, "xaAaAaA"), R(6, "aAaAgaAaAa"), R(5, "AAAAAAAAAAAAA"), None],
        [],
    ),
}

FACE_NORM = [
    R(7, "hssssssssS"), R(7, "hsssEsssES"), R(7, "hsssEEsEES"),
    R(7, "hsssEwsEwS"), R(7, "hSsssuussS"), R(8, "zSSSSSSz"),
]
FACE_WINDUP = [
    R(7, "hssssssssS"), R(7, "hssEEssEES"), R(7, "hsssEEsEES"),
    R(7, "hsssEsssES"), R(7, "hSsssuussS"), R(8, "zSSSSSSz"),
]
FACE_ATTACK = [
    R(7, "hssssssssS"), R(7, "hssEssssES"), R(7, "hssEwsEEwS"),
    R(7, "hsssEEsEES"), R(7, "hSssuuuuuS"), R(8, "zSSSSSSz"),
]
FACE_HURT = [
    R(7, "hssssssssS"), R(7, "hssEssssES"), R(7, "hsssEssEsS"),
    R(7, "hssEssssES"), R(7, "hSssuuuusS"), R(8, "zSSSSSSz"),
]

BODY_OLD = [
    R(7, "3144g44412"),
    [R(6, "2"), R(7, "3131113112"), R(17, "2")],
    [R(5, "S2"), R(7, "3141141112"), R(17, "2s")],
    R(7, "5444yg4445"),
    R(7, "2113113112"),
    R(7, "2214214122"),
    R(8, "22122122"),
]
BODY_NEW = [
    R(7, "3111g11112"),
    [R(6, "2"), R(7, "3133113312"), R(17, "2")],
    [R(5, "S2"), R(7, "311b1yb112"), R(17, "2s")],
    R(7, "bbbbyybbbb"),
    R(7, "211y11y112"),
    R(7, "2211111122"),
    R(8, "22111122"),
]
ROBE = [
    R(7, "3vvvvgvvv2"),
    [R(6, "2"), R(7, "31c1111c12"), R(17, "2")],
    [R(5, "S2"), R(7, "311K11K112"), R(17, "2s")],
    R(7, "5444gy4445"),
    R(6, "211c11111c12"),
    R(6, "21111cc11112"),
    R(5, "21111111111122"),
    R(5, "22221222122222"),
]

# 8 pha bước chân chuyển tiếp mượt (walk 0..7)
LEGS_WALK = [
    [R(8, "ppppPPPP"), R(8, "ppP..pPP"), R(8, "ppP..pPP"), R(8, "qqQ..qqQ"), R(7, "qqqQ.qqqqQ")],
    [R(8, "ppppPPPP"), R(7, "ppP...pPP"), R(7, "ppP...pPP"), R(7, "qqQ....qqQ"), R(6, "qqqQ...qqqqQ")],
    [R(8, "ppppPPPP"), R(7, "ppP....pPP"), R(6, "ppP......pPP"), R(6, "qqQ......qqQ"), R(5, "qqQ........qqqQ")],
    [R(8, "ppppPPPP"), R(8, "ppP...pPP"), R(8, "ppP..pPP"), R(8, "qqQ..qqQ"), R(8, "qqqQ.qqqQ")],
    [R(8, "ppppPPPP"), R(9, "ppPPP"), R(9, "ppPPP"), R(9, "qqQqQ"), R(10, "qqqqQ")],
    [R(8, "PPPPpppp"), R(8, "PPp..ppP"), R(7, "PPp...ppP"), R(7, "QqQ....qqQ"), R(6, "qqQ.....qqqQ")],
    [R(8, "PPPPpppp"), R(7, "PPp....ppP"), R(6, "PPp......ppP"), R(6, "QqQ......qqQ"), R(5, "qqQ........qqqQ")],
    [R(8, "PPPPpppp"), R(8, "PPp..ppP"), R(8, "PPp..pPP"), R(8, "qqQ..qqQ"), R(7, "qqqQ.qqqQ")],
]
LEGS_WINDUP = [R(8, "ppppPPPP"), R(7, "ppP...pPP"), R(6, "ppP....pPP"), R(6, "qqQ....qqQ"), R(5, "qqqQ...qqqqQ")]
LEGS_ATTACK = [R(8, "ppppPPPP"), R(7, "ppP.....pPP"), R(6, "ppP......pPP"), R(6, "qqQ.......qqQ"), R(5, "qqqQ......qqqqQ")]
LEGS_HURT = [R(8, "ppppPPPP"), R(8, "ppP...pPP"), R(9, "ppP...pPP"), R(9, "qqQ...qqQ"), R(8, "qqqQ..qqqQ")]


def _at(rows_by_y):
    out = [None] * H
    for y, segs in rows_by_y.items():
        if 0 <= y < H:
            out[y] = [R(x, p) for x, p in segs]
    return out


def weapon_rows(kind, modern, f):
    w = {}

    def put(y, x, p):
        if 0 <= y < H:
            w.setdefault(y, []).append((x, p))

    walk_dx = [0, 1, 1, 0, 0, -1, -1, 0][f] if f < 8 else 0
    walk_dy = [0, 0, -1, -1, 0, 0, 1, 0][f] if f < 8 else 0

    if kind == "bo_binh" and not modern:  # đao cong
        if f in (8, 9):  # lấy đà 2 nhịp: vung nhẹ -> giương hết cỡ + lóe sáng
            off = 0 if f == 8 else -1
            for i, (x, y) in enumerate(((16 + off, 12), (15 + off, 11), (14 + off, 10), (13 + off, 9), (12 + off, 8))):
                put(y, x, "nm" if i < 4 else "n")
            put(13, 17 + off, "gG")
            if f == 9:
                put(7, 11, "y")
        elif f == 10:  # bắt đầu chém xuống
            put(11, 19, "Gnnm")
            put(12, 18, "gmmn")
            put(10, 21, "nK")
        elif f == 11:  # chém hết tầm + vồng sáng rộng
            put(13, 18, "Gnnnnn")
            put(14, 17, "gmmmmmn")
            put(10, 19, "nnnK")
            put(12, 21, "nnK")
            put(15, 20, "Knn")
        elif f == 12:  # dư ảnh theo đà
            put(14, 18, "Gmmmn")
            put(15, 20, "Kmm")
            put(16, 21, "K")
        elif f == 13:  # thu chiêu
            put(15, 18, "Ggmm")
            put(14, 19, "mn")
        elif f in (14, 15):  # trúng đòn 2 nhịp
            ox = 0 if f == 14 else 1
            for i, (x, y) in enumerate(((15 + ox, 13), (15 + ox, 12), (16 + ox, 11), (16 + ox, 10))):
                put(y, x, "nm")
            put(14, 14 + ox, "gG")
        else:
            ox, oy = walk_dx, walk_dy
            for i, (x, y) in enumerate(((18 + ox, 13 + oy), (19 + ox, 12 + oy), (20 + ox, 11 + oy), (21 + ox, 10 + oy))):
                put(y, x, "nm")
            put(9 + oy, 22 + ox, "n")
            put(13 + oy, 17 + ox, "g")
            put(14 + oy, 17 + ox, "Gg")

    elif kind == "cung_thu":  # cung + dây kéo mượt + tên lao
        arc = {7: 19, 8: 20, 9: 20, 10: 21, 11: 21, 12: 21, 13: 21, 14: 21, 15: 21, 16: 21, 17: 21, 18: 20, 19: 20, 20: 19}
        dx_b = -1 if f >= 14 else (1 if f in (10, 11) else walk_dx)
        dy_b = walk_dy if f < 8 else 0
        for y, x in arc.items():
            put(y + dy_b, min(22, x + dx_b), "oO")
        sx = 16 if f == 8 else (14 if f == 9 else (21 if f in (10, 11) else (19 if f == 12 else 18)))
        for y in range(8, 20):
            dx = int(round((sx - 18) * (1 - abs(y - 14) / 6.5)))
            put(y + dy_b, min(22, 18 + dx + dx_b), "k")
        if f in (8, 9):
            put(14, sx, "ooooooon")
            if f == 9:
                put(14, 22, "y")
        elif f in (10, 11):
            put(14, 18, "nnKnn")
            if f == 11:
                put(13, 21, "K")
                put(15, 21, "K")
        elif f == 12:
            put(14, 20, "Kk")

    elif kind == "khien_binh":
        ox = -1 if f == 8 else (-2 if f == 9 else (2 if f == 10 else (3 if f == 11 else (1 if f in (12, 13) else (-2 if f >= 14 else walk_dx)))))
        oy = 1 if f in (8, 9) else (walk_dy if f < 8 else 0)
        rows = [
            "..444444..", ".41133114.", "4133gg3314", "413gyyg314", "411gyyg114",
            "4111gg1114", "4111111114", ".41111114.", "..411114..", "...4444...",
        ]
        for i, r in enumerate(rows):
            for j, ch in enumerate(r):
                if ch != ".":
                    xx = 10 + ox + j
                    if 0 <= xx < W:
                        put(11 + oy + i, xx, ch)
        if f == 9:
            put(12, 12, "n")
        elif f in (10, 11):
            put(13, 22, "yY")
            put(14, 22, "Yn")
            if f == 11:
                put(15, 22, "y")
                put(12, 22, "n")

    elif kind == "phap_su":
        top = 1 if f == 8 else (0 if f in (9, 10, 11) else (1 if f == 12 else (2 + walk_dy if f < 8 else 3)))
        sx = 17 if f in (8, 9) else (20 if f in (10, 11) else (19 if f == 12 else (18 + walk_dx)))
        for y in range(top + 4, 23):
            put(y, sx, "o" if y % 3 else "O")
        if f in (8, 9):
            put(top + 1, sx - 1, "Kcv" if f == 9 else "vcv")
            put(top + 2, sx - 2, "cvKvc")
            put(top + 3, sx - 1, "VvV")
            if f == 9:
                put(top, sx, "n")
        elif f in (10, 11, 12):
            put(top + 1, sx - 1, "nKn")
            put(top + 2, sx - 2, "KncnK")
            put(top + 3, sx - 1, "VvV")
            if f in (10, 11):
                put(11, 22, "Kn")
                put(13, 21, "cK")
            if f == 11:
                put(9, 21, "K")
                put(14, 22, "n")
        else:
            put(top + 1, sx, "v")
            put(top + 2, sx - 1, "vcv")
            put(top + 3, sx - 1, "VvV")

    elif kind == "bo_binh" and modern:
        if f in (8, 9):
            ox = 10 if f == 8 else 9
            put(14, ox, "OOOooMMMMMMn")
        elif f in (10, 11):
            put(14, 12, "OOooMMMMMMnnK")
            if f == 11:
                put(13, 22, "n")
                put(15, 22, "K")
        elif f in (12, 13):
            put(14, 11, "OOOooMMMMMMn")
        else:
            ox, oy = (-1, -1) if f >= 14 else (walk_dx, walk_dy)
            for i, (x, y) in enumerate(((15, 17), (16, 16), (17, 15), (18, 14), (19, 13), (20, 12), (21, 11))):
                put(y + oy, min(23, x + ox), "O" if i < 3 else "M")
            put(10 + oy, min(23, 22 + ox), "nn")

    elif kind == "linh_sung":
        ox = -1 if f in (10, 11) else (walk_dx if f < 8 else 0)
        oy = 1 if f in (8, 9) else (walk_dy if f < 8 else 0)
        put(14 + oy, 11 + ox, "OOOoMMMMMMMn")
        put(15 + oy, 12 + ox, "O")
        if f == 9:
            put(13 + oy, 22, "g")
        elif f == 10:
            put(13, 21, "FYn")
            put(14, 21, "fYYn")
        elif f == 11:
            put(13, 21, "fYYn")
            put(14, 20, "FYnn")
            put(15, 21, "FY")
        elif f in (12, 13):
            put(12 if f == 12 else 11, 22, "kk")
            put(11 if f == 12 else 10, 21, "M")

    elif kind == "xa_thu":
        ox = -1 if f in (10, 11) else (walk_dx if f < 8 else 0)
        put(13, 11 + ox, "dddddddMMMMn")
        put(14, 11 + ox, "dMMdddd")
        put(15, 13 + ox, "d")
        put(15, 15 + ox, "d")
        for i in range(5):
            put(15 + i // 2, 10 - i + ox, "g")
        if f in (10, 11):
            put(12, 21, "FYYn")
            put(13, 21, "YYnn")
            if f == 11:
                put(14, 21, "FfY")
        elif f in (12, 13):
            put(11 if f == 12 else 10, 21, "kk")
            put(12 if f == 12 else 11, 22, "M")

    elif kind == "phao_binh":
        if f in (8, 9):
            put(11 if f == 9 else 12, 17, "MMn")
            put(12 if f == 9 else 13, 17, "MM")
        elif f in (10, 11):
            put(12, 18, "Mn")
            put(6, 7, "FYn")
            put(7, 7, "fYY")
            if f == 11:
                put(5, 7, "Y")
                put(8, 8, "F")
        elif f in (12, 13):
            put(6 if f == 12 else 5, 6, "kk")
            put(5 if f == 12 else 4, 7, "M")
        else:
            ox, oy = walk_dx, walk_dy
            put(13 + oy, 17 + ox, "MM")
            put(14 + oy, 17 + ox, "Mn")

    return _at(w)


def back_rows(kind, modern, f):
    w = {}

    def put(y, x, p):
        if 0 <= y < H:
            w.setdefault(y, []).append((x, p))

    if kind == "cung_thu":
        for y in range(9, 19):
            put(y, 4, "bbB")
        put(7, 4, "r.r")
        put(8, 4, "kkk")
    if modern and kind in ("linh_sung", "bo_binh", "xa_thu"):
        for y in range(12, 19):
            put(y, 3, "bbbB")
        put(12, 3, "BBBB")
        put(13, 4, "g")
    if kind == "phao_binh":
        for i in range(10):
            put(19 - i, 3 + i // 2, "MM")
        put(9, 8, "nM")
    if not modern and kind in ("bo_binh", "khien_binh"):
        sway = [0, -1, -1, 0, 1, 1, 0, -1, -1, -2, 1, 2, 1, 0, -1, 0][f]
        for y in range(13, 21):
            put(y, max(1, 5 + sway - (y - 13) // 4), "22")
    return _at(w)


def make_pal(army_id, kind):
    a = ARMIES[army_id]
    p = dict(BASE)
    for k in "12345pP":
        p[k] = a[k]
    p.update(HATS[army_id][0])
    if kind == "phap_su":
        p["1"], p["2"], p["3"] = "4e2c72", "2b1846", "8454b2"
        p["E"] = "ea38ff"
    return {k: hexc(v) for k, v in p.items()}


def _hurt_tint(img, strong=True):
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a > 200:
                if strong:
                    px[x, y] = (min(255, int(r * 0.78 + 75)), int(g * 0.7), int(b * 0.7), a)
                else:
                    px[x, y] = (min(255, int(r * 0.88 + 38)), int(g * 0.85), int(b * 0.85), a)
    return img


def soldier_frames(army_id, kind):
    p = make_pal(army_id, kind)
    modern = army_id.startswith("phap")
    hat_rows, plume = HATS[army_id][1], HATS[army_id][2]
    body = ROBE if kind == "phap_su" else (BODY_NEW if modern else BODY_OLD)
    frames = []
    for f in range(FRAMES):
        if f < 8:
            legs = LEGS_WALK[f]
            bob = [0, 0, -1, -1, 0, 0, -1, -1][f]
            lean = 0
            face = FACE_NORM
            plume_dx = [0, -1, -1, 0, 1, 1, 0, -1][f]
        elif f in (8, 9):
            legs = LEGS_WINDUP
            bob = 1
            lean = -1 if f == 8 else -2
            face = FACE_WINDUP
            plume_dx = -1 if f == 8 else -2
        elif f in (10, 11, 12, 13):
            legs = LEGS_ATTACK
            bob = 0 if f in (10, 11) else 1
            lean = 1 if f != 11 else 2
            face = FACE_ATTACK if f in (10, 11) else FACE_NORM
            plume_dx = -2 if f <= 11 else 1
        else:
            legs = LEGS_HURT
            bob = -1 if f == 14 else 0
            lean = -2 if f == 14 else -1
            face = FACE_HURT
            plume_dx = 2 if f == 14 else 1

        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(back, back_rows(kind, modern, f), p, 0, dx=lean)
        img.alpha_composite(back, (0, max(-1, min(1, bob))))

        if kind == "phap_su":
            _draw_rows(img, legs[3:], p, 23, dx=lean if f >= 8 else 0)
        else:
            _draw_rows(img, legs, p, 19, dx=lean if f >= 8 else 0)
            if bob < 0:
                _draw_rows(img, [legs[0]], p, 18, dx=lean if f >= 8 else 0)

        up = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(up, body, p, 12, dx=lean, dy=bob)
        _draw_rows(up, face, p, 6, dx=lean, dy=bob)
        _draw_rows(up, hat_rows, p, 0, dx=lean + (1 if f == 14 else 0), dy=bob)
        if plume:
            for py, px0, pat in plume:
                _draw_rows(up, [R(px0, pat)], p, py, dx=lean + plume_dx, dy=bob)
        img.alpha_composite(up)

        wpn = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(wpn, weapon_rows(kind, modern, f), p, 0, dx=0, dy=max(0, bob))
        img.alpha_composite(wpn)

        if f in (14, 15):
            _hurt_tint(img, f == 14)
        frames.append(polish(img))
    return frames


def build():
    for army in ARMIES:
        kinds = ("bo_binh", "linh_sung", "xa_thu", "phao_binh") if army.startswith("phap") else ("bo_binh", "cung_thu", "khien_binh", "phap_su")
        for kind in kinds:
            save(sheet(soldier_frames(army, kind)), f"enemies/{army}_{kind}.png")


if __name__ == "__main__":
    build()
