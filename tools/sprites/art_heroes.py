"""Tướng: vẽ tay từng pixel, khung 32x32, nhìn sang phải (game tự lật khi quay trái).

Mỗi hàng viết dạng R(x, "mẫu"): mẫu bắt đầu ở cột x. Dấu "." là trong suốt.
Bảng ký tự:
  s/S/z  da sáng / bóng / bóng sâu     b  má hồng    o  miệng
  e/w/i  mắt (đen / điểm sáng / tròng) h/H/j  tóc (gốc / sáng / tối)
  1/2/3/7 màu áo chính (gốc/tối/sáng/rất tối)    4/5/6  màu phụ (gốc/tối/sáng)
  g/G/y  vàng đồng (gốc/tối/sáng)      m/M/n  thép (gốc/tối/sáng)
  c/C/x  áo choàng (gốc/tối/rất tối)   r/R  tua đỏ    k/K  râu bạc
  p/P    quần      q/Q  ủng
Xuất ra 1 dải 9 khung: thở(4) + đi(4) + trúng đòn(1).
"""
from px import hexc, outline, polish, sheet, save, Image

W = 32
COMMON = {
    "s": "f7caa4", "S": "dc9a7e", "z": "b8746a", "b": "f39a90", "o": "b8505a",
    "e": "241a2e", "w": "ffffff", "i": "4a6ab0",
    "h": "2e2436", "H": "4e3e5e", "j": "1a1422",
    "g": "f0b848", "G": "b0702a", "y": "fff2a8",
    "m": "c8cede", "M": "868ea8", "n": "ffffff",
    "r": "e84a4a", "R": "a02838",
    "k": "e4e0ec", "K": "a8a0b8",
    "q": "7a4e30", "Q": "4a2c1a",
}


def pal(**kw):
    d = dict(COMMON)
    d.update(kw)
    return {k: hexc(v) for k, v in d.items()}


def R(x, pattern):
    return (x, pattern)


def draw_rows(img, rows, p, y0=0, dx=0):
    for y, row in enumerate(rows):
        if row is None:
            continue
        segs = row if isinstance(row, list) else [row]
        for x0, pat in segs:
            _seg(img, x0, pat, p, y0 + y, dx)


def _seg(img, x0, pat, p, yy0, dx):
    if True:
        for i, ch in enumerate(pat):
            if ch in ". ":
                continue
            if ch not in p:
                raise KeyError(f"Ký tự {ch!r} chưa có màu: {pat!r}")
            x, yy = x0 + i + dx, yy0
            if 0 <= x < W and 0 <= yy < W:
                img.putpixel((x, yy), p[ch])


# ---------------------------------------------------------------- Khuôn mặt dùng chung (hàng 10-17)
def face(x_flap, flap="G", hair="hh"):
    """Mặt nhìn sang phải: mắt to 2x3 có điểm sáng, má hồng, miệng nhỏ."""
    f = flap
    return [
        R(x_flap, f + hair + "sssssssssssS"),
        R(x_flap, f + hair + "sssssssssssS"),
        R(x_flap, f + hair + "sssswesswesS"),
        R(x_flap, f + hair + "sssseesseesS"),
        R(x_flap, f + hair + "ssssiessiesS"),
        R(x_flap, f + hair + "sbbsssosbbsS"),
        R(x_flap + 1, hair[-1] + "SsssssssssS"),
        R(x_flap + 2, "zSSssssssSz"),
    ]


# ---------------------------------------------------------------- Chân (hàng 25-30)
LEGS_IDLE = [
    R(11, "pppppPPPP"),
    R(11, "pppP.ppPP"),
    R(11, "ppPP.ppPP"),
    R(11, "qqqQ.qqqQ"),
    R(11, "qqqQ.qqqQ"),
    R(11, "qqqqQqqqqQ"),
]
LEGS_WALK = [
    [R(11, "pppppPPPP"), R(10, "pppP...ppPP"), R(9, "ppPP.....ppPP"), R(8, "qqqQ.......qqqQ"),
     R(8, "qqQ.........qqqQ"), R(7, "qqQ..........qqqqQ")],
    [R(11, "pppppPPPP"), R(12, "pppPPP"), R(12, "ppPPPP"), R(12, "qqQqqQ"), R(14, "qqqQ"), R(14, "qqqqQ")],
    [R(11, "PPPPppppp"), R(10, "PPPp...pppP"), R(9, "PPPp.....ppPP"), R(8, "QqqQ.......qqqQ"),
     R(8, "qqQ.........qqqQ"), R(7, "qqQ..........qqqqQ")],
    [R(11, "pppppPPPP"), R(12, "PPPppP"), R(12, "PPpppP"), R(12, "QqQqqQ"), R(11, "qqqQ"), R(11, "qqqqQ")],
]
BOB = [0, -1, 0, -1]

# ================================================================ Ngô Quyền: mũ trụ vàng, tua đỏ, giáp vảy xanh, áo choàng đỏ
NGO_QUYEN = pal(**{"1": "4a7fd0", "2": "2f4f99", "3": "8fbcff", "7": "1f2f66",
                   "4": "f0b848", "5": "b0702a", "6": "fff2a8",
                   "c": "c83c3c", "C": "8a2438", "x": "5a1830", "p": "3a3550", "P": "262236"})
NGO_QUYEN_UP = [
    R(15, "rr"),
    R(14, "rRrr"),
    R(14, "rrRr"),
    R(15, "Rr"),
    R(15, "yG"),
    R(13, "ygggG"),
    R(11, "yyggggggG"),
    R(10, "yyggggggggG"),
    R(9, "ygyggggggggGG"),
    R(8, "GGGGGGGrGGGGGGG"),
] + face(8) + [
    [R(7, "ccc"), R(10, "31gggggg1"), R(19, "gyyg")],
    [R(6, "cCcc"), R(10, "311211211"), R(19, "GggG")],
    [R(5, "cCxcc"), R(10, "321121121"), R(19, "12")],
    [R(5, "cCxCc"), R(10, "54446444455")],
    [R(4, "cCCxCc"), R(10, "21131131132")],
    [R(4, "cCxxCx"), R(10, "22212221222")],
    [R(4, "CxxCx")],
]

# ================================================================ Bà Triệu: tóc búi cao cài trâm, giáp vàng viền đỏ, khăn đỏ bay
BA_TRIEU = pal(**{"1": "f0c040", "2": "b8802a", "3": "fff4a8", "7": "8a5a1e",
                  "4": "d83c3c", "5": "8a2434", "6": "f58070",
                  "c": "d83c3c", "C": "8a2434", "x": "5a1828", "p": "7a2c34", "P": "4e1a26"})
BA_TRIEU_UP = [
    None,
    R(13, "hHHh"),
    R(12, "hHHhhh"),
    R(12, "hhhhjh"),
    R(11, "gyRrrRg"),
    R(13, "hhhh"),
    R(10, "hhHHhhhhhh"),
    R(9, "hHHhhhhhhhhh"),
    R(8, "hHhhhhhhhhhhhj"),
    R(8, "hhhhhhhhjhhhhhh"),
] + [
    R(8, "hhhhhhsssssssh"),
    R(8, "hhhhsssssssssS"),
    R(8, "hhhsssswesswesS"),
    R(8, "hhhsssseesseesS"),
    R(8, "hhhsssiessiesS"),
    R(8, "hhhsbbsssosbbS"),
    R(7, "hhhhhSsssssssS"),
    R(7, "hhhhhzSSsssSz"),
] + [
    [R(6, "hhhh"), R(10, "3144441"), R(18, "6446")],
    [R(5, "hHhhj"), R(10, "3113113"), R(18, "4554")],
    [R(5, "hHhjr"), R(10, "3131131"), R(18, "12")],
    [R(5, "hhhjR"), R(10, "544y4445")],
    [R(5, "hhjj"), R(10, "21131131")],
    [R(5, "hjjr"), R(10, "22131222")],
    [R(6, "jjR")],
]

# ================================================================ Trần Hưng Đạo: mũ quan cánh chuồn, áo bào đỏ thêu vàng, râu bạc
TRAN_HUNG_DAO = pal(**{"1": "c03a3a", "2": "7e2232", "3": "f07060", "7": "4e1424",
                       "4": "f0b848", "5": "b0702a", "6": "fff2a8",
                       "h": "26222e", "H": "4a4458", "j": "16121c",
                       "c": "7e2232", "C": "4e1424", "x": "2e0a16",
                       "p": "7e2232", "P": "4e1424", "q": "26222e", "Q": "16121c"})
TRAN_HUNG_DAO_UP = [
    None,
    None,
    R(12, "hhhhhh"),
    R(11, "hHHhhhhj"),
    R(10, "hHhhhhhhhj"),
    R(10, "hhhhhhhhhj"),
    R(10, "hhhhhhhhhj"),
    [R(2, "HHHh"), R(9, "5444y44445"), R(24, "hHHH")],
    [R(2, "hhhhhh"), R(10, "hhhhhhhh"), R(22, "hhhhhh")],
    R(8, "hhhhhhhhhhhhhh"),
] + [
    R(8, "hhhsssssssssssS"),
    R(8, "hhhsssssssssssS"),
    R(8, "hhhsssswesswesS"),
    R(8, "hhhsssseesseesS"),
    R(8, "hhhsssiessiesS"),
    R(8, "hhhsbbskkkkkbS"),
    R(9, "hSsskkKkkkkS"),
    R(10, "zSSkkkkkKSz"),
] + [
    [R(9, "31441kkkkK1"), R(20, "1gg")],
    [R(9, "311441kkKK1"), R(20, "12G")],
    [R(9, "3114461kK112")],
    [R(9, "544446444445")],
    [R(8, "2113111311112")],
    [R(8, "21131113111312")],
    [R(8, "22221222122222")],
]

# ================================================================ Quang Trung: khăn đỏ buộc đầu, giáp xanh than, hộ tâm kính vàng, áo choàng đỏ
QUANG_TRUNG = pal(**{"1": "3a4c86", "2": "232e5a", "3": "6a86cc", "7": "141a38",
                     "4": "dc3c32", "5": "922230", "6": "ff7e66",
                     "c": "c83a32", "C": "882230", "x": "561626", "p": "2a2440", "P": "1a1628"})
QUANG_TRUNG_UP = [
    R(14, "hh"),
    R(13, "hHHh"),
    R(13, "hhhj"),
    R(14, "hh"),
    R(10, "hhhhhhhhhh"),
    R(9, "hHHhhhhhhhhj"),
    R(8, "hHhhhhhhhhhhhj"),
    R(8, "hhhhhhhhhhhhhj"),
    R(5, "4464444444444444"),
    R(4, "45.55555555555555"),
] + [
    R(3, "45.hhhssssssssssS"),
    R(2, "45..hhsssssssssssS"),
    R(2, "5...hhsssssssssssS"),
    R(6, "hhsssswesswesS"),
    R(6, "hhsssseesseesS"),
    R(6, "hhsssiessiessS"),
    R(7, "hSbbsssossbbS"),
    R(8, "zSsssssssSz"),
] + [
    [R(7, "ccc"), R(10, "3111gg111"), R(19, "gyyg")],
    [R(6, "cCcc"), R(10, "311gyyg11"), R(19, "GggG")],
    [R(5, "cCxcc"), R(10, "311gGGg11"), R(19, "12")],
    [R(5, "cCxCc"), R(10, "GggggyggggG")],
    [R(4, "cCCxCc"), R(10, "21131131132")],
    [R(4, "cCxxCx"), R(10, "22212221222")],
    [R(4, "CxxCx")],
]

# ---------------------------------------------------------------- Mặt có ria / râu
def face_hair(x, hair="hhh", mouth_row="sbbsssosbbsS", chin=None):
    """Mặt cho tướng đội khăn / đầu tóc ở bên trái."""
    return [
        R(x, hair + "sssssssssssS"),
        R(x, hair + "sssssssssssS"),
        R(x, hair + "sssswesswesS"),
        R(x, hair + "sssseesseesS"),
        R(x, hair + "sssiessiessS"),
        R(x, hair + mouth_row),
        chin or R(x + 1, "hSsssssssssS"),
        R(x + 2, "zSSssssssSz"),
    ]


# ================================================================ Hai Bà Trưng: mũ Trưng Vương vàng 3 chóp, áo đỏ thẫm thêu vàng, tóc dài
HAI_BA_TRUNG = pal(**{"1": "b8305a", "2": "7a1a3e", "3": "f0709a", "7": "4a0e26",
                      "4": "f0b848", "5": "b0702a", "6": "fff2a8", "p": "5a1a30", "P": "3a0e20"})
HAI_BA_TRUNG_UP = [
    [R(11, "y"), R(15, "y"), R(19, "y")],
    [R(10, "ygG"), R(14, "ygG"), R(18, "ygG")],
    R(10, "gggrgggrgggG"),
    R(10, "GGGGGGGGGGGG"),
    R(9, "hHHhhhhhhhhhj"),
    R(8, "hHhhhhhhhhhhhj"),
    R(8, "hhhhhhhhhhhhhhj"),
    R(8, "hhhhhhhhhhhhhhh"),
    R(8, "hhhhhhhhhhhhhhh"),
    R(8, "hhhhhhhssssshhh"),
] + [
    R(8, "hhhhhsssssssssS"),
    R(8, "hhhhsssssssssS"),
    R(8, "hhhsssswesswesS"),
    R(8, "hhhsssseesseesS"),
    R(8, "hhhsssiessiesS"),
    R(8, "hhhsbbssrsbbS"),
    R(7, "hhhhhSsssssssS"),
    R(7, "hhhhhzSSsssSz"),
] + [
    [R(6, "hhhh"), R(10, "31g4g4g1"), R(18, "3113")],
    [R(5, "hHhhj"), R(10, "311g4g11"), R(18, "1112")],
    [R(5, "hHhjh"), R(10, "3111g111"), R(18, "2222")],
    [R(5, "hhhjh"), R(10, "5444y4445")],
    [R(4, "hhhjj"), R(9, "2113111312")],
    [R(4, "hjjj"), R(8, "221131113122")],
    R(8, "22221222122"),
]

# ================================================================ Lý Thường Kiệt: mũ trụ thép lông trắng, giáp vảy thép viền xanh, áo choàng xanh
LY_THUONG_KIET = pal(**{"1": "3a6aa8", "2": "24467a", "3": "7aa8e8", "7": "142a50",
                        "4": "f0b848", "5": "b0702a", "6": "fff2a8",
                        "c": "2a4a8a", "C": "1a2e5a", "x": "101a38", "p": "3a3550", "P": "262236"})
LY_THUONG_KIET_UP = [
    R(9, "kkk"),
    R(8, "kKkkk"),
    R(10, "KKkk"),
    R(12, "KkknM"),
    R(13, "mnmM"),
    R(12, "nmmmmM"),
    R(11, "nnmmmmmmM"),
    R(10, "nnmmmmmmmmM"),
    R(9, "nmnmmmmmmmmMM"),
    R(8, "MMMMMMM1MMMMMMM"),
] + face(8, flap="M") + [
    [R(7, "ccc"), R(10, "3nmmmmmm1"), R(19, "nmmM")],
    [R(6, "cCcc"), R(10, "3mMmMmMm1"), R(19, "MmmM")],
    [R(5, "cCxcc"), R(10, "3MmMmMmM1"), R(19, "12")],
    [R(5, "cCxCc"), R(10, "54446444455")],
    [R(4, "cCCxCc"), R(10, "2mMmMmMmMm2")],
    [R(4, "cCxxCx"), R(10, "22212221222")],
    [R(4, "CxxCx")],
]

# ================================================================ Lê Lợi: khăn xếp đen, râu đen, áo bào xanh Lam Sơn viền vàng
LE_LOI = pal(**{"1": "3a7a4a", "2": "24503a", "3": "6ab070", "7": "143022",
                "4": "f0b848", "5": "b0702a", "6": "fff2a8",
                "h": "26222e", "H": "4a4458", "j": "16121c",
                "p": "24503a", "P": "143022", "q": "26222e", "Q": "16121c"})
LE_LOI_UP = [
    None, None, None,
    R(11, "hhhhhhhh"),
    R(10, "hHHHHHHHHh"),
    R(9, "hhhhhhhhhhhj"),
    R(9, "HHHHHHHHHHHH"),
    R(8, "hhhhhhhhhhhhhj"),
    R(8, "HHHHHHHHHHHHHH"),
    R(8, "hhhhhhhhhhhhhhh"),
] + face_hair(8, mouth_row="sbbsjjjjsbbS", chin=R(9, "hSsjjjjjjsS")) + [
    [R(9, "3144jjjjj1"), R(19, "1gg")],
    [R(9, "31144jjj11"), R(19, "12G")],
    R(9, "3114461j1112"),
    R(9, "544446444445"),
    R(8, "2113111311112"),
    R(8, "21131113111312"),
    R(8, "22221222122222"),
]

# ================================================================ Nguyễn Trung Trực: khăn đóng đen, áo trắng, khăn đỏ thắt lưng, ria mép
NGUYEN_TRUNG_TRUC = pal(**{"1": "e8e4f0", "2": "a8a4c0", "3": "ffffff", "7": "6a6688",
                           "4": "d83c3c", "5": "8e2230", "6": "ff7a66",
                           "p": "2e2a3a", "P": "1a1824"})
NGUYEN_TRUNG_TRUC_UP = [
    None, None, None, None,
    R(10, "hhhhhhhhhh"),
    R(9, "hHhHhHhHhHhj"),
    R(8, "hhhhhhhhhhhhhj"),
    R(8, "hHhHhHhHhHhHhj"),
    R(8, "hhhhhhhhhhhhhh"),
    R(8, "hhhhhhhhhhhhhhh"),
] + face_hair(8, mouth_row="sbbsHhhHsbbS") + [
    [R(10, "3111111111"), R(20, "31")],
    [R(10, "3111111111"), R(20, "12")],
    R(10, "311111111112"),
    R(9, "54444y444445"),
    [R(9, "21111111112"), R(20, "45")],
    R(9, "222212221222"),
    None,
]

# ================================================================ Hoàng Hoa Thám: khăn đen, ria rậm, áo nâu, dây đạn chéo
HOANG_HOA_THAM = pal(**{"1": "8a5a3a", "2": "5a3622", "3": "b8845a", "7": "3a2014",
                        "4": "6a4028", "5": "3e2416", "6": "a06a44",
                        "p": "3a3040", "P": "241e2a"})
HOANG_HOA_THAM_UP = [
    None, None, None, None,
    R(10, "hhhhhhhhhh"),
    R(9, "hjhjhjhjhjhj"),
    R(8, "hhhhhhhhhhhhhj"),
    R(8, "hjhjhjhjhjhjhj"),
    R(8, "hhhhhhhhhhhhhh"),
    R(8, "hhhhhhhhhhhhhhh"),
] + face_hair(8, mouth_row="sbbHhhhhHbbS", chin=R(9, "hSssHhhHssS")) + [
    [R(10, "3g11111111"), R(20, "31")],
    [R(10, "31g1111111"), R(20, "12")],
    R(10, "311g11111112"),
    R(9, "5444g4444445"),
    R(9, "211111g11112"),
    R(9, "2222122g1222"),
    None,
]

# ================================================================ Chiến sĩ Điện Biên: mũ cối ngụy trang lá, quân phục xanh, ba lô
CHIEN_SI = pal(**{"1": "5a7a3a", "2": "3a5228", "3": "8aaa5a", "7": "22321a",
                  "4": "8a6a3a", "5": "5a4024", "6": "b08a52",
                  "m": "8a8a4a", "M": "5a5a2e", "n": "b8b870", "v": "4a8a2a", "V": "2a5a1a",
                  "p": "3a5228", "P": "22321a", "q": "3a2a1e", "Q": "1e140e"})
CHIEN_SI_UP = [
    None, None,
    [R(12, "v"), R(17, "V")],
    R(11, "vVnmmvM"),
    R(10, "nnmmVmmmvM"),
    R(9, "nmmvmmmmmVmM"),
    R(8, "nmmmmmVmmmmmmM"),
    R(7, "MMMMMMMMMMMMMMMM"),
    R(8, "hhhhhhhhhhhhhh"),
    R(8, "hhhhhhhhhhhhhhh"),
] + face(8, flap="h") + [
    [R(6, "444"), R(9, "3111111111"), R(19, "31")],
    [R(5, "4645"), R(9, "3111111111"), R(19, "12")],
    [R(5, "4445"), R(9, "31111y1111"), R(19, "22")],
    [R(5, "5445"), R(9, "5555555555")],
    [R(5, "555"), R(9, "2113111311")],
    R(9, "2221222122"),
    None,
]

HEROES = {
    "hai_ba_trung": (HAI_BA_TRUNG_UP, HAI_BA_TRUNG),
    "ly_thuong_kiet": (LY_THUONG_KIET_UP, LY_THUONG_KIET),
    "le_loi": (LE_LOI_UP, LE_LOI),
    "nguyen_trung_truc": (NGUYEN_TRUNG_TRUC_UP, NGUYEN_TRUNG_TRUC),
    "hoang_hoa_tham": (HOANG_HOA_THAM_UP, HOANG_HOA_THAM),
    "chien_si_dien_bien": (CHIEN_SI_UP, CHIEN_SI),
    "ngo_quyen": (NGO_QUYEN_UP, NGO_QUYEN),
    "ba_trieu": (BA_TRIEU_UP, BA_TRIEU),
    "tran_hung_dao": (TRAN_HUNG_DAO_UP, TRAN_HUNG_DAO),
    "quang_trung": (QUANG_TRUNG_UP, QUANG_TRUNG),
}

LEG_Y = 25


def compose(up, p, legs, bob=0, breathe=0, hurt=False):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw_rows(img, legs, p, LEG_Y)
    if bob < 0:
        draw_rows(img, [legs[0]], p, LEG_Y - 1)
    body = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw_rows(body, up, p, 0)
    if breathe:
        head = body.crop((0, 0, W, 18))
        rest = body.crop((0, 18, W, W))
        body = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        body.alpha_composite(rest, (0, 18))
        body.alpha_composite(head, (0, breathe))
    if hurt:
        px = body.load()
        e, w, i, s = p["e"], p["w"], p["i"], p["s"]
        for y in range(10, 16):
            for x in range(W):
                if px[x, y] in (e, w, i):
                    px[x, y] = s
        # mắt nhắm chặt >  <
        for (x, y) in ((14, 12), (15, 13), (14, 14), (19, 12), (18, 13), (19, 14)):
            if px[x, y][3]:
                px[x, y] = e
    img.alpha_composite(body, (0, bob))
    return polish(img)


def build():
    out = {}
    for hid, (up, p) in HEROES.items():
        frames = [compose(up, p, LEGS_IDLE), compose(up, p, LEGS_IDLE),
                  compose(up, p, LEGS_IDLE, breathe=1), compose(up, p, LEGS_IDLE, breathe=1)]
        for i in range(4):
            frames.append(compose(up, p, LEGS_WALK[i], bob=BOB[i]))
        frames.append(compose(up, p, LEGS_IDLE, hurt=True))
        save(sheet(frames), f"heroes/{hid}.png")
        out[hid] = frames
    return out


if __name__ == "__main__":
    build()
