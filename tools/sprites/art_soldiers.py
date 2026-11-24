"""Lính giặc chi tiết (khung 24x26): đi 4 khung + tấn công 1 khung.

Ghép theo lớp: đồ sau lưng -> chân -> thân -> mặt -> mũ -> vũ khí phía trước.
Mỗi đạo quân có màu áo và kiểu mũ riêng; mỗi loại lính có dáng và vũ khí riêng.
"""
from px import hexc, outline, polish, sheet, save, Image
from art_heroes import R, draw_rows
from art_enemies import ARMIES

W, H = 24, 26

BASE = {
    "s": "f0c4a0", "S": "c88e74", "z": "a06a5a", "E": "2a1d2e", "w": "ffffff", "u": "6a2a2a",
    "h": "2b2230", "H": "4b3d58", "d": "1a1420",
    "m": "c8cede", "M": "868ea8", "n": "ffffff",
    "g": "e8b04a", "G": "a86a2a", "y": "fff0a0",
    "o": "9a6234", "O": "5e3a20", "k": "ece8f4", "r": "d83a3a", "R": "8e2632",
    "v": "b06aff", "V": "5a2a90", "c": "f0d0ff",
    "b": "7a4a2e", "B": "4a2a18", "q": "4a3428", "Q": "2e1e18",
}

# Mũ từng đạo quân (a/A/x = màu mũ chính / tối / sáng)
HATS = {
    "dong_han": ({"a": "2b2230", "A": "1a1420", "x": "4b3d58"}, [
        None, R(9, "aaaaa"), R(8, "axaaaaA"), R(8, "aaagaaA"), R(7, "AAAAAAAAAA"), R(6, "AAAAAAAAAAAA"), None]),
    "dong_ngo": ({"a": "c4803e", "A": "7a4622", "x": "f2b878"}, [
        R(10, "rr"), R(9, "rRr"), R(10, "xA"), R(8, "xaaaaA"), R(7, "xxaaaaaaA"), R(6, "AAAAAAAAAAA"), [R(6, "A"), R(16, "A")]]),
    "nam_han": ({"a": "1a4a5e", "A": "0e2a36", "x": "2a7a8a"}, [
        None, None, R(8, "aaaaaa"), R(7, "axaxaxaA"), R(7, "aaaaaaaA"), R(6, "ggggggggggg"), None]),
    "tong": ({"a": "a8b0c4", "A": "6a7290", "x": "e0e6f0"}, [
        R(10, "r"), R(9, "rRr"), R(9, "xaA"), R(8, "xaaaaA"), R(7, "xaaaaaaaA"), R(6, "AAAAAAAAAAA"), [R(6, "A"), R(16, "A")]]),
    "nguyen_mong": ({"a": "6a4a3a", "A": "3e2a20", "x": "a88a6a"}, [
        R(10, "g"), R(9, "rrr"), R(8, "rRrrr"), R(7, "xaxaxaxaA"), R(6, "axaxaxaxaxA"), R(6, "AAAAAAAAAAA"), None]),
    "minh": ({"a": "3a3448", "A": "1e1a28", "x": "5e5870"}, [
        R(10, "rr"), R(9, "rrRr"), R(8, "xaaaaA"), R(7, "xaaaaaaA"), R(7, "ggggggggG"), R(6, "AAAAAAAAAAA"), None]),
    "thanh": ({"a": "2b2230", "A": "1a1420", "x": "4b3d58"}, [
        R(10, "r"), R(9, "rrr"), R(8, "rRrrR"), R(7, "axaaaaaA"), R(5, "aaaaaaaaaaaaA"), R(4, "AAAAAAAAAAAAAAA"), None]),
    "phap_thuy": ({"a": "f0eef4", "A": "b8b4c8", "x": "ffffff"}, [
        None, R(10, "rr"), R(10, "Rr"), R(7, "xaaaaaaA"), R(6, "aaaaaaaaaA"), R(7, "33333333"), None]),
    "phap_vien_chinh": ({"a": "ece8dc", "A": "b0ac9a", "x": "ffffff"}, [
        None, R(8, "xaaaa"), R(7, "xaaaaaA"), R(6, "xaaaaaaaA"), R(6, "abbbbbbbbA"), R(4, "AAAAAAAAAAAAAA"), None]),
    "phap_1954": ({"a": "5a5a3a", "A": "3a3a24", "x": "7a7a52"}, [
        None, None, R(8, "xaaaa"), R(7, "xaAaAaA"), R(6, "aAaAaAaAaA"), R(5, "AAAAAAAAAAAAA"), None]),
}

# Mặt: lông mày xếch hình chữ V, mắt có điểm sáng, miệng mím
FACE = [
    R(7, "hssssssssS"),
    R(7, "hsssEsssES"),
    R(7, "hsssEEsEES"),
    R(7, "hsssEwsEwS"),
    R(7, "hSsssuussS"),
    R(8, "zSSSSSSz"),
]
# Thân có hai tay: tay sau (trái) và tay trước (phải) cầm vũ khí ở (18, 14)
BODY_OLD = [
    R(7, "3144444412"),
    [R(6, "2"), R(7, "3111111112"), R(17, "2")],
    [R(5, "S2"), R(7, "3121121112"), R(17, "2s")],
    R(7, "5444y44445"),
    R(7, "2113113112"),
    R(7, "2211211122"),
    R(8, "22122122"),
]
BODY_NEW = [
    R(7, "3111111112"),
    [R(6, "2"), R(7, "3133113312"), R(17, "2")],
    [R(5, "S2"), R(7, "31111y1112"), R(17, "2s")],
    R(7, "bbbbybbbbb"),
    R(7, "211y111112"),
    R(7, "2211111122"),
    R(8, "22111122"),
]
ROBE = [
    R(7, "3vvvvvvvv2"),
    [R(6, "2"), R(7, "31c1111c12"), R(17, "2")],
    [R(5, "S2"), R(7, "3111111112"), R(17, "2s")],
    R(7, "5444y44445"),
    R(6, "211c11111c12"),
    R(6, "211111111112"),
    R(5, "21111111111122"),
    R(5, "22221222122222"),
]
LEGS = [
    [R(8, "ppppPPPP"), R(8, "ppP..pPP"), R(8, "ppP..pPP"), R(8, "qqQ..qqQ"), R(7, "qqqQ.qqqqQ")],
    [R(8, "ppppPPPP"), R(7, "ppP....pPP"), R(6, "ppP......pPP"), R(6, "qqQ......qqQ"), R(5, "qqQ........qqqQ")],
    [R(8, "ppppPPPP"), R(9, "ppPPP"), R(9, "ppPPP"), R(9, "qqQqQ"), R(10, "qqqqQ")],
    [R(8, "PPPPpppp"), R(7, "PPp....ppP"), R(6, "PPp......ppP"), R(6, "QqQ......qqQ"), R(5, "qqQ........qqqQ")],
]
BOB = [0, -1, 0, -1]


def _at(rows_by_y):
    """{y: [(x, mẫu), ...]} -> danh sách hàng 0..H-1 cho draw_rows"""
    out = [None] * H
    for y, segs in rows_by_y.items():
        if 0 <= y < H:
            out[y] = [R(x, p) for x, p in segs]
    return out


def weapon_rows(kind, modern, attack):
    w = {}
    def put(y, x, p):
        w.setdefault(y, []).append((x, p))
    if kind == "bo_binh" and not modern:            # đao
        if attack:
            put(13, 19, "mmmmn")
            put(14, 18, "Gnnnnm")
        else:
            for i, (x, y) in enumerate(((19, 13), (20, 12), (21, 11), (22, 10))):
                put(y, x, "nm")
            put(9, 23, "n")
            put(13, 18, "g")
            put(14, 18, "Gg")
    elif kind == "cung_thu":                         # cung
        arc = {6: 20, 7: 21, 8: 21, 9: 22, 10: 22, 11: 22, 12: 22, 13: 22, 14: 22, 15: 22, 16: 22, 17: 22, 18: 22, 19: 21, 20: 21, 21: 20}
        for y, x in arc.items():
            put(y, x, "oO")
        sx = 16 if attack else 19
        for y in range(7, 21):
            dx = int(round((sx - 19) * (1 - abs(y - 14) / 7.0)))
            put(y, 19 + dx, "k")
        if attack:
            put(14, 16, "ooooooon")
    elif kind == "khien_binh":                       # khiên lớn
        ox = 2 if attack else 0
        rows = ["..444444..", ".41111114.", "4133111114", "4131gg1114", "411gyyg114", "411gyyg114",
                "4111gg1114", "4111111114", ".41111114.", "..411114..", "...4444..."]
        for i, r in enumerate(rows):
            for j, ch in enumerate(r):
                if ch != ".":
                    put(11 + i, 10 + ox + j, ch)
    elif kind == "phap_su":                          # gậy phép
        top = 2 if not attack else 0
        for y in range(top + 4, 23):
            put(y, 19, "o" if y % 3 else "O")
        put(top + 1, 18, "vcv" if attack else ".v.")
        put(top + 2, 18, "vcv")
        put(top + 3, 18, "VvV")
        if attack:
            put(top, 19, "c")
            put(top + 2, 16, "c")
            put(top + 2, 22, "c")
    elif kind == "bo_binh" and modern:               # súng trường lưỡi lê
        if attack:
            put(14, 12, "OOOooMMMMMMn")
        else:
            for i, (x, y) in enumerate(((15, 17), (16, 16), (17, 15), (18, 14), (19, 13), (20, 12), (21, 11))):
                put(y, x, "O" if i < 3 else "M")
            put(10, 22, "n")
            put(9, 23, "n")
    elif kind == "linh_sung":                        # súng trường ngang
        put(14, 12, "OOOoMMMMMMMn")
        put(15, 13, "O")
        if attack:
            put(13, 23, "y")
            put(14, 23, "y")
    elif kind == "xa_thu":                           # súng máy + dây đạn
        put(13, 12, "dddddddMMMMn")
        put(14, 12, "dMMdddd")
        put(15, 14, "d")
        put(15, 16, "d")
        for i in range(5):
            put(15 + i // 2, 10 - i, "g")
        if attack:
            put(12, 23, "y")
            put(13, 23, "y")
            put(14, 23, "g")
    elif kind == "phao_binh":                        # đạn cối trên tay
        put(13, 18, "MM")
        put(14, 18, "Mn")
    return _at(w)


def back_rows(kind, modern):
    w = {}
    def put(y, x, p):
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
    if kind == "phao_binh":
        for i in range(10):
            put(19 - i, 3 + i // 2, "MM")
        put(9, 8, "nM")
    return _at(w)


def make_pal(army_id, kind):
    a = ARMIES[army_id]
    p = dict(BASE)
    for k in "12345pP":
        p[k] = a[k]
    p.update(HATS[army_id][0])
    if kind == "phap_su":
        p["1"], p["2"], p["3"] = "4a2a6a", "2a1840", "7a50a0"
        p["E"] = "e030ff"
    return {k: hexc(v) for k, v in p.items()}


def C(p, k):
    return p[k]


def soldier_frames(army_id, kind):
    p = make_pal(army_id, kind)
    modern = army_id.startswith("phap")
    hat = HATS[army_id][1]
    body = ROBE if kind == "phap_su" else (BODY_NEW if modern else BODY_OLD)
    frames = []
    for f in range(5):
        attack = f == 4
        legs = LEGS[0] if attack else LEGS[f]
        bob = 0 if attack else BOB[f]
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw_rows(back, back_rows(kind, modern), p, 0)
        img.alpha_composite(back, (0, bob))
        if kind == "phap_su":
            draw_rows(img, legs[3:], p, 23)
        else:
            draw_rows(img, legs, p, 19)
            if bob < 0:
                draw_rows(img, [legs[0]], p, 18)
        up = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw_rows(up, body, p, 12)
        draw_rows(up, FACE, p, 6)
        draw_rows(up, hat, p, 0)
        img.alpha_composite(up, (0, bob))
        wpn = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw_rows(wpn, weapon_rows(kind, modern, attack), p, 0)
        img.alpha_composite(wpn, (0, bob))
        frames.append(polish(img))
    return frames


def build():
    for army in ARMIES:
        kinds = ("bo_binh", "linh_sung", "xa_thu", "phao_binh") if army.startswith("phap") else ("bo_binh", "cung_thu", "khien_binh", "phap_su")
        for kind in kinds:
            save(sheet(soldier_frames(army, kind)), f"enemies/{army}_{kind}.png")


if __name__ == "__main__":
    build()
