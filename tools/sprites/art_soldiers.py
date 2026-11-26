"""Lính giặc chi tiết cao (khung 24x26 x 8 khung = 192x26):
  0..3: đi bộ (walk) — chân, thân, tay, mũ, chỏm lông đều chuyển động theo nhịp bước
  4:    lấy đà (windup) — ngả người, nheo mắt, giương/kê vũ khí kèm tia sáng báo hiệu
  5:    tấn công (attack) — lao tới, tia chém / tên bay / đạn tóe lửa / bùng phép
  6:    thu chiêu (recover) — hồi thế, khói súng / dư ảnh dịu xuống
  7:    trúng đòn (hurt) — giật lùi, nhắm mắt nhăn mặt, mũ lệch nhẹ

Ghép lớp chặt chẽ: đồ sau lưng -> chân -> thân giáp -> đầu & biểu cảm -> mũ & chỏm -> tay & vũ khí.
"""
from px import hexc, polish, sheet, save, Image, ImageDraw
from art_enemies import ARMIES

W, H = 24, 26
FRAMES = 8

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

HATS = {
    "dong_han": ({"a": "2c2334", "A": "181322", "x": "544564"}, [
        None, R := lambda x, p: (x, p),
    ]),
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


# Mũ chi tiết từng đạo quân (7 hàng: y=0..6), hỗ trợ chỏm lông lay động riêng theo dx
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

# Mặt theo trạng thái (normal / windup / attack / hurt)
FACE_NORM = [
    R(7, "hssssssssS"),
    R(7, "hsssEsssES"),
    R(7, "hsssEEsEES"),
    R(7, "hsssEwsEwS"),
    R(7, "hSsssuussS"),
    R(8, "zSSSSSSz"),
]
FACE_WINDUP = [
    R(7, "hssssssssS"),
    R(7, "hssEEssEES"),
    R(7, "hsssEEsEES"),
    R(7, "hsssEsssES"),
    R(7, "hSsssuussS"),
    R(8, "zSSSSSSz"),
]
FACE_ATTACK = [
    R(7, "hssssssssS"),
    R(7, "hssEssssES"),
    R(7, "hssEwsEEwS"),
    R(7, "hsssEEsEES"),
    R(7, "hSssuuuuuS"),
    R(8, "zSSSSSSz"),
]
FACE_HURT = [
    R(7, "hssssssssS"),
    R(7, "hssEssssES"),
    R(7, "hsssEssEsS"),
    R(7, "hssEssssES"),
    R(7, "hSssuuuusS"),
    R(8, "zSSSSSSz"),
]

# Thân áo giáp chi tiết hơn: nẹp vai, họa tiết giáp vảy / khuy vàng, thắt lưng nổi khối
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

# 4 dáng chân đi + windup trụ + attack lao tới + recover + hurt giật lùi
LEGS_WALK = [
    [R(8, "ppppPPPP"), R(8, "ppP..pPP"), R(8, "ppP..pPP"), R(8, "qqQ..qqQ"), R(7, "qqqQ.qqqqQ")],
    [R(8, "ppppPPPP"), R(7, "ppP....pPP"), R(6, "ppP......pPP"), R(6, "qqQ......qqQ"), R(5, "qqQ........qqqQ")],
    [R(8, "ppppPPPP"), R(9, "ppPPP"), R(9, "ppPPP"), R(9, "qqQqQ"), R(10, "qqqqQ")],
    [R(8, "PPPPpppp"), R(7, "PPp....ppP"), R(6, "PPp......ppP"), R(6, "QqQ......qqQ"), R(5, "qqQ........qqqQ")],
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
    """Vẽ vũ khí theo từng khung f (0..3 walk, 4 windup, 5 attack, 6 recover, 7 hurt) gọn trong 24x26."""
    w = {}

    def put(y, x, p):
        if 0 <= y < H:
            w.setdefault(y, []).append((x, p))

    # Nhịp tay lắc nhẹ khi đi (f 0..3)
    walk_dx = [0, 1, 0, -1][f] if f < 4 else 0
    walk_dy = [0, -1, 0, 1][f] if f < 4 else 0

    if kind == "bo_binh" and not modern:  # đao cong sắc nét
        if f == 4:  # giương đao ra sau lưng chuẩn bị bổ
            for i, (x, y) in enumerate(((15, 11), (14, 10), (13, 9), (12, 8), (11, 7))):
                put(y, x, "nm" if i < 4 else "n")
            put(12, 16, "gG")
            put(8, 10, "y")
        elif f == 5:  # chém vồng sáng về trước
            put(13, 18, "Gnnnnn")
            put(14, 17, "gmmmmmn")
            put(11, 19, "nnn")
            put(12, 21, "nK")
            put(15, 21, "Kn")
        elif f == 6:  # hạ đao thu chiêu
            put(15, 18, "Ggmmm")
            put(16, 20, "mmmn")
        elif f == 7:  # giơ tay đỡ khi bị đánh
            for i, (x, y) in enumerate(((16, 13), (16, 12), (17, 11), (17, 10))):
                put(y, x, "nm")
            put(14, 15, "gG")
        else:
            ox, oy = walk_dx, walk_dy
            for i, (x, y) in enumerate(((18 + ox, 13 + oy), (19 + ox, 12 + oy), (20 + ox, 11 + oy), (21 + ox, 10 + oy))):
                put(y, x, "nm")
            put(9 + oy, 22 + ox, "n")
            put(13 + oy, 17 + ox, "g")
            put(14 + oy, 17 + ox, "Gg")

    elif kind == "cung_thu":  # cung cong + dây + tên nỏ
        arc = {7: 19, 8: 20, 9: 20, 10: 21, 11: 21, 12: 21, 13: 21, 14: 21, 15: 21, 16: 21, 17: 21, 18: 20, 19: 20, 20: 19}
        dx_b = -1 if f == 7 else (1 if f == 5 else walk_dx)
        dy_b = walk_dy if f < 4 else 0
        for y, x in arc.items():
            put(y + dy_b, min(22, x + dx_b), "oO")
        sx = 15 if f == 4 else (20 if f == 5 else 18)
        for y in range(8, 20):
            dx = int(round((sx - 18) * (1 - abs(y - 14) / 6.5)))
            put(y + dy_b, min(22, 18 + dx + dx_b), "k")
        if f == 4:
            put(14, 14, "ooooooon")
            put(14, 21, "y")
        elif f == 5:
            put(14, 19, "nnKnn")
            put(13, 21, "K")
            put(15, 21, "K")
        elif f == 6:
            put(14, 18, "k")

    elif kind == "khien_binh":  # đại thuẫn có hoa văn đồng & chốt sáng
        ox = -1 if f == 4 else (3 if f == 5 else (1 if f == 6 else (-2 if f == 7 else walk_dx)))
        oy = 1 if f == 4 else (walk_dy if f < 4 else 0)
        rows = [
            "..444444..",
            ".41133114.",
            "4133gg3314",
            "413gyyg314",
            "411gyyg114",
            "4111gg1114",
            "4111111114",
            ".41111114.",
            "..411114..",
            "...4444...",
        ]
        for i, r in enumerate(rows):
            for j, ch in enumerate(r):
                if ch != ".":
                    xx = 10 + ox + j
                    if 0 <= xx < W:
                        put(11 + oy + i, xx, ch)
        if f == 5:
            put(13, 22, "yY")
            put(14, 22, "Yn")
            put(15, 22, "y")
        elif f == 4:
            put(12, 13, "n")

    elif kind == "phap_su":  # trượng ngọc pháp sư có ấn xoay
        top = 0 if f in (4, 5) else (2 + walk_dy if f < 4 else 3)
        sx = 17 if f == 4 else (20 if f == 5 else (18 + walk_dx))
        for y in range(top + 4, 23):
            put(y, sx, "o" if y % 3 else "O")
        if f == 4:
            put(top + 1, sx - 1, "Kcv")
            put(top + 2, sx - 2, "cvKvc")
            put(top + 3, sx - 1, "VvV")
            put(top, sx, "n")
        elif f == 5:
            put(top + 1, sx - 1, "nKn")
            put(top + 2, sx - 2, "KncnK")
            put(top + 3, sx - 1, "VvV")
            put(11, 22, "Kn")
            put(13, 21, "cK")
            put(9, 21, "K")
        elif f == 6:
            put(top + 2, sx - 1, "vcK")
            put(top + 3, sx - 1, "VvV")
        else:
            put(top + 1, sx, "v")
            put(top + 2, sx - 1, "vcv")
            put(top + 3, sx - 1, "VvV")

    elif kind == "bo_binh" and modern:  # súng trường gắn lưỡi lê
        if f == 4:
            put(14, 10, "OOOooMMMMMMn")
        elif f == 5:
            put(14, 12, "OOooMMMMMMnnK")
            put(13, 22, "n")
            put(15, 22, "K")
        elif f == 6:
            put(14, 11, "OOOooMMMMMMn")
        else:
            ox, oy = (-1, -1) if f == 7 else (walk_dx, walk_dy)
            for i, (x, y) in enumerate(((15, 17), (16, 16), (17, 15), (18, 14), (19, 13), (20, 12), (21, 11))):
                put(y + oy, min(23, x + ox), "O" if i < 3 else "M")
            put(10 + oy, min(23, 22 + ox), "nn")

    elif kind == "linh_sung":  # súng trường cổ điển
        ox = -1 if f == 5 else (walk_dx if f < 4 else 0)
        oy = 1 if f == 4 else (walk_dy if f < 4 else 0)
        put(14 + oy, 11 + ox, "OOOoMMMMMMMn")
        put(15 + oy, 12 + ox, "O")
        if f == 4:
            put(13 + oy, 22, "g")
        elif f == 5:
            put(13, 21, "FYn")
            put(14, 21, "fYYn")
            put(15, 21, "FY")
        elif f == 6:
            put(12, 22, "kk")
            put(11, 21, "M")

    elif kind == "xa_thu":  # súng máy dây đạn đồng
        ox = -1 if f == 5 else (walk_dx if f < 4 else 0)
        put(13, 11 + ox, "dddddddMMMMn")
        put(14, 11 + ox, "dMMdddd")
        put(15, 13 + ox, "d")
        put(15, 15 + ox, "d")
        for i in range(5):
            put(15 + i // 2, 10 - i + ox, "g")
        if f == 5:
            put(12, 21, "FYYn")
            put(13, 21, "YYnn")
            put(14, 21, "FfY")
        elif f == 6:
            put(11, 21, "kk")
            put(12, 22, "M")

    elif kind == "phao_binh":  # đạn cối trên tay & chớp nòng sau lưng
        if f == 4:
            put(11, 17, "MMn")
            put(12, 17, "MM")
        elif f == 5:
            put(12, 18, "Mn")
            put(6, 7, "FYn")
            put(7, 7, "fYY")
            put(8, 8, "F")
        elif f == 6:
            put(6, 6, "kk")
            put(5, 7, "M")
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
    # Áo choàng nhẹ / tua sau cho bộ binh phong kiến
    if not modern and kind in ("bo_binh", "khien_binh"):
        sway = [0, -1, 0, 1, -1, 1, 0, -1][f]
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


def _hurt_tint(img):
    """Ánh đỏ nhẹ quanh mép trên để khung trúng đòn (frame 7) nổi rõ."""
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a > 200:
                px[x, y] = (min(255, int(r * 0.8 + 70)), int(g * 0.72), int(b * 0.72), a)
    return img


def soldier_frames(army_id, kind):
    p = make_pal(army_id, kind)
    modern = army_id.startswith("phap")
    hat_rows, plume = HATS[army_id][1], HATS[army_id][2]
    body = ROBE if kind == "phap_su" else (BODY_NEW if modern else BODY_OLD)
    frames = []
    for f in range(FRAMES):
        if f < 4:
            legs = LEGS_WALK[f]
            bob = [0, -1, 0, -1][f]
            lean = 0
            face = FACE_NORM
            plume_dx = [0, -1, 0, 1][f]
        elif f == 4:
            legs = LEGS_WINDUP
            bob = 1
            lean = -1
            face = FACE_WINDUP
            plume_dx = -1
        elif f == 5:
            legs = LEGS_ATTACK
            bob = 0
            lean = 1
            face = FACE_ATTACK
            plume_dx = -2
        elif f == 6:
            legs = LEGS_ATTACK
            bob = 1
            lean = 1
            face = FACE_NORM
            plume_dx = 1
        else:
            legs = LEGS_HURT
            bob = -1
            lean = -2
            face = FACE_HURT
            plume_dx = 2

        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(back, back_rows(kind, modern, f), p, 0, dx=lean)
        img.alpha_composite(back, (0, max(-1, min(1, bob))))

        if kind == "phap_su":
            _draw_rows(img, legs[3:], p, 23, dx=lean if f >= 4 else 0)
        else:
            _draw_rows(img, legs, p, 19, dx=lean if f >= 4 else 0)
            if bob < 0:
                _draw_rows(img, [legs[0]], p, 18, dx=lean if f >= 4 else 0)

        up = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(up, body, p, 12, dx=lean, dy=bob)
        _draw_rows(up, face, p, 6, dx=lean, dy=bob)
        _draw_rows(up, hat_rows, p, 0, dx=lean + (1 if f == 7 else 0), dy=bob)
        if plume:
            for py, px0, pat in plume:
                _draw_rows(up, [R(px0, pat)], p, py, dx=lean + plume_dx, dy=bob)
        img.alpha_composite(up)

        wpn = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        _draw_rows(wpn, weapon_rows(kind, modern, f), p, 0, dx=0, dy=max(0, bob))
        img.alpha_composite(wpn)

        if f == 7:
            _hurt_tint(img)
        frames.append(polish(img))
    return frames


def build():
    for army in ARMIES:
        kinds = ("bo_binh", "linh_sung", "xa_thu", "phao_binh") if army.startswith("phap") else ("bo_binh", "cung_thu", "khien_binh", "phap_su")
        for kind in kinds:
            save(sheet(soldier_frames(army, kind)), f"enemies/{army}_{kind}.png")


if __name__ == "__main__":
    build()
