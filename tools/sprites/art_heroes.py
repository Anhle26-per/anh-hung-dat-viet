"""Tướng: vẽ tay từng pixel phong cách chibi đầu to (~55% chiều cao), khung 32x32, nhìn sang phải.

Mỗi hàng viết dạng R(x, "mẫu"): mẫu bắt đầu ở cột x. Dấu "." là trong suốt.
Bảng ký tự:
  s/S/z  da sáng / bóng / bóng sâu     b  má hồng    o  miệng
  e/w/i  mắt (đen / điểm sáng / tròng) h/H/j  tóc (gốc / sáng / tối)
  1/2/3/7 màu áo chính (gốc/tối/sáng/rất tối)    4/5/6  màu phụ (gốc/tối/sáng)
  g/G/y  vàng đồng (gốc/tối/sáng)      m/M/n  thép (gốc/tối/sáng)
  c/C/x  áo choàng (gốc/tối/rất tối)   r/R  tua đỏ    k/K  râu/lông bạc
  p/P    quần      q/Q  ủng
Xuất ra 1 dải 16 khung (512x32):
  0..3:  thở (idle, 4 khung)
  4..7:  đi (walk, 4 khung)
  8:     trúng đòn (hurt, 1 khung)
  9..10: tấn công (attack, 2 khung)
  11..12: tung kỹ năng (skill, 2 khung)
  13..15: gục ngã (down, 3 khung: loạng choạng -> khuỵu gối -> ngã nằm)
"""
from px import hexc, outline, polish, sheet, save, Image

W = 32
COMMON = {
    "s": "f8cca8", "S": "de9c7e", "z": "b47066", "b": "f69492", "o": "c2505c",
    "e": "22182c", "w": "ffffff", "i": "4a6cb8",
    "h": "2e2438", "H": "544468", "j": "181220",
    "g": "f2bc46", "G": "b07028", "y": "fff4a8",
    "m": "ccd4e4", "M": "848ea8", "n": "ffffff",
    "r": "ea4646", "R": "a22638",
    "k": "eae6f2", "K": "a8a0bc",
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
            for i, ch in enumerate(pat):
                if ch in ". ":
                    continue
                if ch not in p:
                    raise KeyError(f"Ký tự {ch!r} chưa có màu: {pat!r}")
                x, yy = x0 + i + dx, y0 + y
                if 0 <= x < W and 0 <= yy < W:
                    img.putpixel((x, yy), p[ch])


def _put(img, x, y, c):
    if 0 <= x < W and 0 <= y < W:
        px = img.load()
        bg = px[x, y]
        if bg[3] == 0 or c[3] == 255:
            px[x, y] = c
        else:
            a = c[3] / 255.0
            ba = bg[3] / 255.0
            oa = a + ba * (1.0 - a)
            if oa > 0:
                r = int((c[0] * a + bg[0] * ba * (1.0 - a)) / oa)
                g = int((c[1] * a + bg[1] * ba * (1.0 - a)) / oa)
                b = int((c[2] * a + bg[2] * ba * (1.0 - a)) / oa)
                px[x, y] = (r, g, b, int(oa * 255))


# ---------------------------------------------------------------- Khuôn mặt chibi to cân đối (hàng 9-18, x=7..23)
def chibi_face(expr="normal", flap="h", side="hh", brow=None, lashes=False,
               beard=None, mustache=None, mouth="smile"):
    """Khuôn mặt chibi tròn trịa: bề rộng 17px (x=7..23), mắt to 3x4 long lanh, cằm bo tròn cân đối.
    Trả về 10 hàng (y=9..18).
    """
    f = flap
    sd = side
    # Tọa độ cột chuẩn trên mặt (17 cột từ x=7 đến x=23):
    #   x=7: flap (1) | x=8..9: side hair (2) | x=10..23: da mặt (14 cột)
    #   Bên trong 14 cột da mặt (chỉ số 0..13 tương ứng x=10..23):
    #     0: s  | 1: l_ext | 2..4: mắt trái (x=12..14) | 5..7: sống mũi (x=15..17)
    #     8..10: mắt phải (x=18..20) | 11: r_ext | 12: s | 13: S  => tổng 14 cột!
    if expr == "normal":
        e1 = "wee"
        e2 = "eee"
        e3 = "iie"
        e4 = "iwi" if lashes else "iie"
        l_ext = "e" if lashes else "s"
        r_ext = "e" if lashes else "s"
    elif expr == "fierce":
        e1 = "eee"
        e2 = "wee"
        e3 = "iie"
        e4 = "sss"
        l_ext = "s"
        r_ext = "s"
    elif expr == "skill":
        e1 = "wyw"
        e2 = "ywy"
        e3 = "yyy"
        e4 = "iwi"
        l_ext = "s"
        r_ext = "s"
    else:
        e1 = e2 = e3 = e4 = "sss"
        l_ext = r_ext = "s"

    def eye_row(left_e, right_e, le="s", re="s"):
        return "s" + le + left_e + "sss" + right_e + re + "sS"

    if expr == "hurt":
        r11 = f + sd + eye_row("ess", "sse")
        r12 = f + sd + eye_row("ses", "ses")
        r13 = f + sd + eye_row("ess", "sse")
        r14 = f + sd + "sbsssssssssbS"
    elif expr == "down":
        r11 = f + sd + eye_row("ese", "ese")
        r12 = f + sd + eye_row("ses", "ses")
        r13 = f + sd + eye_row("ese", "ese")
        r14 = f + sd + "sssssssssssssS"
    else:
        r11 = f + sd + eye_row(e1, e1, l_ext, r_ext)
        r12 = f + sd + eye_row(e2, e2)
        r13 = f + sd + eye_row(e3, e3)
        r14 = f + sd + eye_row(e4, e4)

    # Hàng trán / lông mày (y=10, 14 cột da mặt)
    if brow == "fierce" or expr == "fierce":
        r10 = f + sd + "sshhhssshhhssS"
    elif brow == "thick":
        r10 = f + sd + "ssHHHsssHHHssS"
    elif brow == "silver":
        r10 = f + sd + "ssKKKsssKKKssS"
    else:
        r10 = f + sd + "sssssssssssssS"

    # Hàng má hồng + miệng / ria (y=15, 14 cột da mặt, tâm miệng ở chỉ số 6 = x=16)
    if expr in ("hurt", "skill", "fierce"):
        mouth_seg = "sbbsssoosssbbS"
    elif expr == "down":
        mouth_seg = "ssssssossssssS"
    elif mustache == "silver":
        mouth_seg = "sbbsskkkkkkbbS"
    elif mustache == "neat":
        mouth_seg = "sbbssHhhhhHbbS"
    elif mustache == "bushy":
        mouth_seg = "sbbsHhhhhhHbbS"
    elif mustache == "goatee":
        mouth_seg = "sbbssHhhhhHbbS"
    elif mouth == "grin":
        mouth_seg = "sbbsssoosssbbS"
    else:
        mouth_seg = "sbbsssossbsbbS".replace("bsbb", "ssbb")

    r15 = f + sd + mouth_seg

    # Cằm bo tròn cân đối (r16: x=8..22 rộng 15; r17: x=9..21 rộng 13; r18: x=11..19 rộng 9)
    if beard == "silver":
        r16 = R(8, sd[-1] + "SsssskkkKssssS")
        r17 = R(9, "zSsskkkkkKsSz")
        r18 = R(11, "zKkkkkkKz")
    elif beard == "goatee":
        r16 = R(8, sd[-1] + "SsssssHhhssssS")
        r17 = R(9, "zSSssHhhhHsSz")
        r18 = R(11, "zSShhhSSz")
    elif beard == "bushy":
        r16 = R(8, sd[-1] + "SsssHhhhhHsssS")
        r17 = R(9, "zSSsHhhhhHsSz")
        r18 = R(11, "zSHhhhHSz")
    else:
        r16 = R(8, sd[-1] + "SssssssssssssS")
        r17 = R(9, "zSSssssssssSz")
        r18 = R(11, "zSSssssSz")

    return [
        R(8, sd + "ssssssssssssS"),    # y=9 (x=8..22)
        R(7, r10),                      # y=10 (x=7..23)
        R(7, r11),                      # y=11
        R(7, r12),                      # y=12
        R(7, r13),                      # y=13
        R(7, r14),                      # y=14
        R(7, r15),                      # y=15
        r16,                            # y=16 (x=8..22)
        r17,                            # y=17 (x=9..21)
        r18,                            # y=18 (x=11..19)
    ]


# ---------------------------------------------------------------- Chân chibi ngắn mũm mĩm (hàng 26-29, 4px)
LEGS_IDLE = [
    R(11, "pppppPPPP"),
    R(11, "ppPP.ppPP"),
    R(11, "qqqQ.qqqQ"),
    R(10, "qqqqQqqqqQ"),
]
LEGS_WALK = [
    [R(11, "pppppPPPP"), R(10, "ppPP...ppPP"), R(9, "qqqQ.....qqqQ"), R(8, "qqqQ......qqqqQ")],
    [R(11, "pppppPPPP"), R(12, "ppPPPP"), R(12, "qqQqqQ"), R(13, "qqqqQ")],
    [R(11, "PPPPppppp"), R(10, "PPPp...pppP"), R(9, "QqqQ.....qqqQ"), R(8, "qqqQ......qqqqQ")],
    [R(11, "pppppPPPP"), R(12, "PPpppP"), R(12, "QqQqqQ"), R(11, "qqqqQ")],
]
LEGS_ATTACK_1 = [
    R(11, "pppppPPPP"),
    R(10, "ppPP..ppPP"),
    R(9, "qqqQ...qqqQ"),
    R(8, "qqqqQ...qqqqQ"),
]
LEGS_ATTACK_2 = [
    R(10, "pppppPPPPP"),
    R(9, "ppPP....ppPP"),
    R(8, "qqqQ.....qqqQ"),
    R(7, "qqqqQ.....qqqqQ"),
]
LEGS_SKILL = [
    R(10, "pppppPPPPP"),
    R(10, "ppPP...ppPP"),
    R(9, "qqqQ....qqqQ"),
    R(9, "qqqqQ...qqqqQ"),
]
LEGS_STAGGER = [
    R(10, "pppppPPPP"),
    R(9, "ppPP...ppP"),
    R(8, "qqqQ....qqQ"),
    R(7, "qqqQ....qqqQ"),
]
LEGS_KNEEL = [
    None,
    R(10, "ppppppppPP"),
    R(9, "qqqQppPPqqQ"),
    R(9, "qqqqQQQqqqqQ"),
]
BOB = [0, -1, 0, -1]
LEG_Y = 26


# ---------------------------------------------------------------- Tay chibi theo tư thế (y=19..24)
def arms_rows(pose="idle", sleeve="1", cuff="3", hand="s", shoulder=None):
    """Đôi tay chibi gọn: xuôi theo thân khi đứng, vung mạnh ra trước khi đánh, giơ cao khi tung chiêu."""
    sh = shoulder or cuff
    if pose == "idle":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(9, sleeve), R(21, sleeve)],
            [R(9, hand), R(21, hand)],
            None, None,
        ]
    if pose == "walk_a":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(8, sleeve), R(22, sleeve)],
            [R(8, hand), R(22, hand)],
            None, None,
        ]
    if pose == "walk_b":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(10, sleeve), R(20, sleeve)],
            [R(10, hand), R(20, hand)],
            None, None,
        ]
    if pose == "hurt":
        return [
            [R(8, hand), R(22, hand)],
            [R(9, sleeve), R(21, sleeve)],
            None, None, None, None,
        ]
    if pose == "attack_1":
        return [
            [R(8, sleeve), R(21, sh + sleeve)],
            [R(7, hand), R(21, sleeve + cuff + hand)],
            [R(23, hand + hand)],
            None, None, None,
        ]
    if pose == "attack_2":
        return [
            [R(8, sleeve), R(21, sh + sleeve + cuff)],
            [R(7, hand), R(21, sleeve + cuff + hand + hand)],
            [R(24, hand)],
            None, None, None,
        ]
    if pose == "skill_1":
        return [
            [R(7, hand), R(23, hand)],
            [R(8, cuff + sleeve), R(21, sleeve + cuff)],
            [R(9, sh), R(20, sh)],
            None, None, None,
        ]
    if pose == "skill_2":
        return [
            [R(6, hand + cuff), R(23, cuff + hand)],
            [R(7, cuff + sleeve), R(22, sleeve + cuff)],
            [R(9, sh), R(20, sh)],
            None, None, None,
        ]
    if pose == "stagger":
        return [
            [R(6, hand), R(22, hand)],
            [R(7, sleeve + sh), R(21, sh + sleeve)],
            None, None, None, None,
        ]
    # kneel
    return [
        None,
        [R(9, sh), R(20, sh)],
        [R(9, sleeve), R(21, sleeve)],
        [R(10, hand), R(21, hand)],
        None, None,
    ]


# ================================================================ Định nghĩa 10 vị tướng chibi
# head: lớp mũ/tóc/vương miện/cánh chuồn gắn chặt vào đầu (y=0..10)
# head_back: lớp áo choàng / tóc dài / ba lô phía sau thân (y=0..25), di chuyển theo thân & phất nhẹ
HERO_SPECS = {
    # ------------------------------------------------------------ 1. Hai Bà Trưng
    "hai_ba_trung": {
        "pal": pal(**{
            "1": "c43060", "2": "801a40", "3": "f4729e", "7": "4e0e28",
            "4": "f4be48", "5": "b4742a", "6": "fff4a8",
            "i": "a83e88", "p": "5c1832", "P": "3a0e20",
        }),
        "head_back": [
            None, None, None, None, None, None,
            R(6, "hhh"), R(5, "hHhh"), R(5, "hHhh"), R(5, "hhhh"),
            R(5, "hhhh"), R(5, "hhhh"), R(5, "hhhh"), R(5, "hHhh"),
            R(5, "hhhh"), R(5, "hhhjh"), R(5, "hhhjh"), R(5, "hhhjh"),
            R(5, "hhhjh"), R(4, "hHhhj"), R(4, "hHhhj"), R(4, "hhhjj"),
            R(4, "hhhjj"), R(4, "hhjjj"), R(5, "hjjj"), R(5, "jjj"),
        ],
        "head": [
            None,
            [R(10, "y"), R(15, "y"), R(20, "y")],
            [R(9, "ygG"), R(14, "ygy"), R(19, "ygG")],
            R(9, "ggrgggggrggG"),
            R(9, "GGGGGGGGGGGG"),
            R(8, "hHHhhhhhhhhhhj"),
            R(7, "hHhhhhhhhhhhhhhj"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhhhsshhsshhhhhh"),
        ],
        "face": dict(flap="h", side="hh", lashes=True, mouth="smile"),
        "torso": [
            R(10, "31g4444g13"),
            R(10, "311g46g112"),
            R(10, "3111gg1112"),
            R(10, "5444yy4445"),
            R(9, "211314413112"),
            R(9, "211311113112"),
            R(9, "222122221222"),
        ],
        "arm": dict(sleeve="1", cuff="g", hand="s", shoulder="3"),
        "attack_fx": ("slash", "ff78a8", "fff4b8"),
        "skill_fx": ("twin", "ff66a4", "fff2a0"),
    },

    # ------------------------------------------------------------ 2. Bà Triệu
    "ba_trieu": {
        "pal": pal(**{
            "1": "f2c23c", "2": "b67e24", "3": "fff4a8", "7": "845418",
            "4": "de3a3a", "5": "8e2234", "6": "ff8272",
            "c": "de3a3a", "C": "8e2234", "x": "5a1628",
            "i": "b86424", "p": "7c2a34", "P": "4e1824",
        }),
        "head_back": [
            None, None, None, None,
            R(5, "rrRrr"), R(4, "rrRrR"), R(3, "rRR"),
            R(5, "hh"), R(5, "hHhh"), R(5, "hhhh"),
            R(5, "hhhh"), R(5, "hhhh"), R(5, "hhhh"), R(5, "hHhh"),
            R(5, "hhhh"), R(5, "hhhjh"), R(5, "hhhjh"), R(5, "hhhjh"),
            R(5, "hhhjh"), R(5, "hHhhj"), R(4, "hHhjr"), R(4, "hhhjR"),
            R(4, "hhjjr"), R(4, "hjjR"), R(5, "jjR"), None,
        ],
        "head": [
            None,
            R(13, "hHHhh"),
            R(12, "hHHhhhh"),
            R(12, "hhhhhjh"),
            R(9, "rRygRrrRgyy"),
            R(12, "hhhhhh"),
            R(8, "hhHHhhhhhhhhhh"),
            R(7, "hHHhhhhhhhhhhhhj"),
            R(7, "hHhhhhhhhhhhhhhhj"),
            R(7, "hhhhhhssshhhsshhh"),
        ],
        "face": dict(flap="h", side="hh", brow="fierce", lashes=True, mouth="grin"),
        "torso": [
            R(10, "3144444413"),
            R(10, "3113113112"),
            R(10, "3131111312"),
            R(10, "5444yy4445"),
            R(9, "211314413112"),
            R(9, "211311113112"),
            R(9, "222122221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="6"),
        "attack_fx": ("slash", "ffaa30", "fff6b8"),
        "skill_fx": ("roar", "ff6a28", "fff08a"),
    },

    # ------------------------------------------------------------ 3. Ngô Quyền
    "ngo_quyen": {
        "pal": pal(**{
            "1": "3e7ad4", "2": "264c98", "3": "88beff", "7": "182c64",
            "4": "f2bc46", "5": "b07028", "6": "fff4a8",
            "c": "cc3838", "C": "8a2236", "x": "58162e",
            "i": "3a68c4", "p": "383450", "P": "242038",
        }),
        "head_back": [None] * 19 + [
            R(6, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(3, "cCCxCc"), R(3, "cCxxCx"), R(4, "CxxCx"),
        ],
        "head": [
            None,
            R(14, "rRr"),
            R(13, "rrRrr"),
            R(14, "rRry"),
            R(13, "ygggG"),
            R(11, "yyggggggG"),
            R(9, "yyggggggggggG"),
            R(8, "ygygggggggggggGG"),
            R(7, "ygggggggggggggggG"),
            R(7, "GGGGGGGGrrGGGGGGGG"),
        ],
        "face": dict(flap="G", side="hh", brow="fierce", mouth="smile"),
        "torso": [
            R(10, "31gggggg13"),
            R(10, "3112112112"),
            R(10, "3211211212"),
            R(10, "5444yy4445"),
            R(10, "2113113112"),
            R(10, "2112112112"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="1", cuff="g", hand="s", shoulder="y"),
        "attack_fx": ("thrust", "5cc4ff", "fff4b0"),
        "skill_fx": ("wave", "3ec8ff", "ffe878"),
    },

    # ------------------------------------------------------------ 4. Lý Thường Kiệt
    "ly_thuong_kiet": {
        "pal": pal(**{
            "1": "386cb0", "2": "22447a", "3": "7cb0f0", "7": "142a52",
            "4": "f2bc46", "5": "b07028", "6": "fff4a8",
            "c": "264a8e", "C": "182e5c", "x": "101a3a",
            "i": "4274b8", "p": "383450", "P": "242038",
        }),
        "head_back": [None] * 19 + [
            R(6, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(3, "cCCxCc"), R(3, "cCxxCx"), R(4, "CxxCx"),
        ],
        "head": [
            None,
            R(7, "kkkk"),
            R(6, "kKkkkk"),
            [R(8, "KKkkk"), R(13, "nmmM")],
            R(11, "KkknmmmM"),
            R(10, "nnmmmmmmMM"),
            R(9, "nnmmmmmmmmmM"),
            R(8, "nmnmmmmmmmmmmMM"),
            R(7, "nmmmmmmmmmmmmmmmM"),
            R(7, "MMMMMMMM11MMMMMMMM"),
        ],
        "face": dict(flap="M", side="hh", mouth="smile"),
        "torso": [
            R(10, "3nmmmmmm13"),
            R(10, "3mMmMmMm12"),
            R(10, "3MmMmMmM12"),
            R(10, "5444yy4445"),
            R(10, "2mMmMmMmM2"),
            R(10, "2113113112"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="m", cuff="1", hand="s", shoulder="n"),
        "attack_fx": ("shot", "94dcff", "ffffff"),
        "skill_fx": ("poem", "70c8ff", "fff090"),
    },

    # ------------------------------------------------------------ 5. Trần Hưng Đạo
    # Mũ quan cánh chuồn gắn thẳng vào head để cánh mũ luôn đi cùng đầu trong mọi khung
    "tran_hung_dao": {
        "pal": pal(**{
            "1": "c43838", "2": "7e2030", "3": "f27262", "7": "4e1222",
            "4": "f2bc46", "5": "b07028", "6": "fff4a8",
            "h": "262230", "H": "4e465e", "j": "16121e",
            "c": "7e2030", "C": "4e1222", "x": "2e0a16",
            "i": "3c5478", "p": "7e2030", "P": "4e1222", "q": "262230", "Q": "16121e",
        }),
        "head_back": [None] * 19 + [
            R(7, "ccc"), R(6, "cCcc"), R(6, "cCxcc"), R(6, "cCxCc"),
            R(6, "cCCxC"), R(6, "CxxC"), None,
        ],
        "head": [
            None, None,
            R(12, "hhhhhhh"),
            R(10, "hHHhhhhhhj"),
            R(9, "hHhhhhhhhhhj"),
            R(9, "hhhhhhhhhhhj"),
            [R(2, "HHHh"), R(8, "h5444yy4445h"), R(25, "hHHH")],
            [R(2, "hhhhh"), R(7, "hhhhhhhhhhhhhhhhj"), R(24, "hhhhh")],
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="silver", mustache="silver", beard="silver"),
        "torso": [
            R(10, "3144kkkK41"),
            R(10, "31146kkK12"),
            R(10, "3114464412"),
            R(10, "54444yy445"),
            R(9, "211314413112"),
            R(9, "211311113112"),
            R(9, "222122221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="3"),
        "attack_fx": ("slash", "ffd24a", "ffffff"),
        "skill_fx": ("drum", "ffbe38", "fff4a8"),
    },

    # ------------------------------------------------------------ 6. Lê Lợi
    "le_loi": {
        "pal": pal(**{
            "1": "34804c", "2": "205238", "3": "6cb876", "7": "123222",
            "4": "f2bc46", "5": "b07028", "6": "fff4a8",
            "h": "24202e", "H": "4c465c", "j": "14101c",
            "i": "386048", "p": "205238", "P": "123222", "q": "26222e", "Q": "16121c",
        }),
        "head_back": [None] * 26,
        "head": [
            None, None,
            R(11, "hhhhhhhhh"),
            R(10, "hHHHHHHHHhh"),
            R(9, "hhhhhhgyhhhhj"),
            R(8, "hHHHHHHHHHHHHh"),
            R(8, "hhhhhhgyhhhhhhj"),
            R(7, "hHHHHHHHHHHHHHHh"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="thick", mustache="goatee", beard="goatee"),
        "torso": [
            R(10, "3144hHhH41"),
            R(10, "31144hh412"),
            R(10, "3114464112"),
            R(10, "54444yy445"),
            R(9, "211311113112"),
            R(9, "211311113112"),
            R(9, "222122221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="3"),
        "attack_fx": ("thrust", "58e07c", "fff4a8"),
        "skill_fx": ("sword", "48e880", "fff6a0"),
    },

    # ------------------------------------------------------------ 7. Quang Trung
    "quang_trung": {
        "pal": pal(**{
            "1": "344a8c", "2": "202e5e", "3": "6c88d4", "7": "12183a",
            "4": "e03c32", "5": "942030", "6": "ff826a",
            "c": "cc3830", "C": "8a2030", "x": "561426",
            "i": "c85a2a", "p": "2a2442", "P": "181428",
        }),
        "head_back": [
            None, None, None, None, None, None, None,
            R(4, "4464"), R(3, "454"), R(2, "45"),
            R(2, "54"), R(1, "5"), None, None, None, None, None, None, None,
            R(6, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(3, "cCCxCc"), R(3, "cCxxCx"), R(4, "CxxCx"),
        ],
        "head": [
            None,
            R(14, "hHHh"),
            R(13, "hHHhhj"),
            R(14, "hhhh"),
            R(9, "hHHhhhhhhhhhh"),
            R(8, "hHhhhhhhhhhhhhj"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(6, "446444444444444444"),
            R(6, "555555555555555555"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="fierce", mouth="grin"),
        "torso": [
            R(10, "3111gg1113"),
            R(10, "311gyyg112"),
            R(10, "311gGGg112"),
            R(10, "GgggyygggG"),
            R(10, "2113113112"),
            R(10, "2112112112"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="y"),
        "attack_fx": ("thrust", "ff5a30", "fff69c"),
        "skill_fx": ("lightning", "ffe840", "ffffff"),
    },

    # ------------------------------------------------------------ 8. Nguyễn Trung Trực
    "nguyen_trung_truc": {
        "pal": pal(**{
            "1": "eeeaf6", "2": "aaa6c4", "3": "ffffff", "7": "6c688a",
            "4": "de3a3a", "5": "902030", "6": "ff7c68",
            "i": "424c78", "p": "2e2a3c", "P": "1a1826",
        }),
        "head_back": [None] * 22 + [R(8, "44"), R(7, "45"), R(7, "5"), None],
        "head": [
            None, None, None,
            R(10, "hhhhhhhhhhh"),
            R(9, "hHhHhHhHhHhhj"),
            R(8, "hhhhhhhhhhhhhhj"),
            R(7, "hHhHhHhHhHhHhHhhj"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="fierce", mustache="neat"),
        "torso": [
            R(10, "3111111113"),
            R(10, "3111111112"),
            R(10, "3111111112"),
            R(9, "544446444445"),
            R(9, "211111111145"),
            R(10, "2111111112"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="1", cuff="2", hand="s", shoulder="3"),
        "attack_fx": ("slash", "ff6438", "fff4a8"),
        "skill_fx": ("fire", "ff4824", "ffdc52"),
    },

    # ------------------------------------------------------------ 9. Hoàng Hoa Thám
    "hoang_hoa_tham": {
        "pal": pal(**{
            "1": "905e3c", "2": "5c3822", "3": "be885e", "7": "3a2014",
            "4": "6e4228", "5": "402416", "6": "a46c46",
            "i": "5c3c28", "p": "3a3042", "P": "241e2c",
        }),
        "head_back": [None] * 26,
        "head": [
            None, None, None,
            R(10, "hhhhhhhhhhh"),
            R(9, "hjhjhjhjhjhjj"),
            [R(5, "hh"), R(8, "hhhhhhhhhhhhhhj")],
            R(4, "hHhhhhhhhhhhhhhhhhj"),
            R(4, "hhjhhhhhhhhhhhhhhhj"),
            [R(5, "hj"), R(7, "hhhhhhhhhhhhhhhhj")],
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="thick", mustache="bushy", beard="bushy"),
        "torso": [
            R(10, "3yg1111113"),
            R(10, "31yg111112"),
            R(10, "311yg11112"),
            R(9, "54444yg44445"),
            R(10, "211111yg12"),
            R(10, "2111111g12"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="3"),
        "attack_fx": ("shot", "ff9c38", "fff4a8"),
        "skill_fx": ("tiger", "ff8820", "ffe866"),
    },

    # ------------------------------------------------------------ 10. Chiến sĩ Điện Biên
    "chien_si_dien_bien": {
        "pal": pal(**{
            "1": "587e38", "2": "385426", "3": "8cb05c", "7": "203418",
            "4": "92703e", "5": "5e4424", "6": "bc9458",
            "m": "8c8e4a", "M": "5a5c2e", "n": "c0c072",
            "v": "48962c", "V": "28601a",
            "i": "3c4e2e", "p": "385426", "P": "203418", "q": "3c2c1e", "Q": "1e140e",
        }),
        "head_back": [None] * 19 + [
            R(5, "4644"), R(4, "46445"), R(4, "44445"), R(4, "54445"),
            R(5, "5555"), None, None,
        ],
        "head": [
            None,
            [R(11, "vV"), R(17, "v")],
            [R(10, "vVn"), R(16, "Vv")],
            R(9, "vVnnmmvmmV"),
            R(8, "nnmmVmmmmvmmM"),
            R(7, "nmmvmmmmmmVmmM"),
            R(6, "nmmmmmVmmmmmmmmmM"),
            R(5, "MMMMMMMMMMMMMMMMMMMMM"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", mouth="smile"),
        "torso": [
            R(10, "3111111113"),
            R(10, "3111yy1112"),
            R(10, "3111111112"),
            R(10, "5555yy5555"),
            R(10, "2113113112"),
            R(10, "2112112112"),
            R(10, "2221221222"),
        ],
        "arm": dict(sleeve="1", cuff="2", hand="s", shoulder="3"),
        "attack_fx": ("shot", "ffd84a", "ffffff"),
        "skill_fx": ("rally", "8ce848", "fff268"),
    },

    # ------------------------------------------------------------ 11. Thánh Gióng (Tướng ẩn - Phù Đổng Thiên Vương)
    "thanh_giong": {
        "pal": pal(**{
            "1": "c4cee0", "2": "7e8aa6", "3": "f2f6ff", "7": "48526c",
            "4": "f6c43c", "5": "b8721e", "6": "fff8b0",
            "c": "e84628", "C": "a82422", "x": "66141a",
            "f": "ff9a2e", "F": "ffe45c",
            "i": "c84824", "p": "5c2228", "P": "34121a", "q": "6e7894", "Q": "3c4258",
        }),
        "head_back": [None] * 17 + [
            R(7, "fc"), R(6, "fcc"),
            R(6, "fccc"), R(5, "fcCcc"), R(4, "fcCxcc"), R(4, "fcCxCc"),
            R(3, "fcCCxC"), R(4, "cCxxC"), R(5, "CxxC"),
        ],
        "head": [
            None,
            R(14, "frr"),
            R(13, "frrRr"),
            R(13, "ygggG"),
            R(11, "nn11g1122"),
            R(9, "nn1111g11112M"),
            R(8, "n31111y1111122M"),
            R(7, "n311111y11111122M"),
            R(7, "y444446r644444445"),
            R(7, "M555555rr5555555M"),
        ],
        "face": dict(flap="M", side="hh", brow="fierce", mouth="grin"),
        "torso": [
            R(10, "3411yy1143"),
            R(10, "3141661412"),
            R(10, "3114444112"),
            R(10, "544c6yc445"),
            R(9, "241131131142"),
            R(9, "211c1221c112"),
            R(9, "222522225222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="6"),
        "attack_fx": ("slash", "ff8820", "fff6a0"),
        "skill_fx": ("fire", "ff5818", "ffea58"),
    },
}


# ---------------------------------------------------------------- Hiệu ứng tấn công & kỹ năng (sau polish)
def _draw_attack_fx(img, spec, stage):
    kind, c_main_h, c_hi_h = spec["attack_fx"]
    cm = hexc(c_main_h, 215)
    ch = hexc(c_hi_h, 245)
    cg = hexc(c_main_h, 110)
    if kind == "slash":
        if stage == 1:
            for x, y in ((25, 13), (26, 14), (27, 15)):
                _put(img, x, y, cm)
            _put(img, 26, 13, ch)
        else:
            arc = [(26, 12), (28, 14), (29, 17), (29, 20), (28, 23), (26, 25)]
            for x, y in arc:
                _put(img, x, y, ch)
                _put(img, x - 1, y, cm)
                _put(img, x - 2, y, cg)
            for x, y in ((27, 13), (28, 16), (28, 19), (27, 22)):
                _put(img, x, y, ch)
    elif kind == "thrust":
        if stage == 1:
            for x in (25, 26, 27):
                _put(img, x, 20, cm)
            _put(img, 27, 20, ch)
        else:
            for x in range(24, 31):
                _put(img, x, 20, ch)
                _put(img, x, 19, cm)
                _put(img, x, 21, cm)
            for x in (23, 25, 28):
                _put(img, x, 18, cg)
                _put(img, x, 22, cg)
            _put(img, 30, 20, (255, 255, 255, 255))
    else:  # shot
        if stage == 1:
            for x, y in ((26, 20), (27, 19), (27, 21)):
                _put(img, x, y, cm)
            _put(img, 27, 20, ch)
        else:
            for x, y in ((26, 20), (27, 20), (28, 20), (29, 20), (30, 20),
                         (28, 18), (28, 19), (28, 21), (28, 22),
                         (27, 19), (29, 19), (27, 21), (29, 21)):
                _put(img, x, y, cm)
            for x, y in ((27, 20), (28, 20), (29, 20), (28, 19), (28, 21)):
                _put(img, x, y, ch)
            _put(img, 28, 20, (255, 255, 255, 255))


def _draw_skill_fx(img, spec, stage):
    kind, c_main_h, c_hi_h = spec["skill_fx"]
    cm = hexc(c_main_h, 210)
    ch = hexc(c_hi_h, 245)
    cg = hexc(c_main_h, 115)

    ring_y = 29 if stage == 1 else 28
    span = range(6, 26) if stage == 1 else range(4, 28)
    for x in span:
        if (x + stage) % 2 == 0:
            _put(img, x, ring_y, cm)
        else:
            _put(img, x, ring_y, cg)
    if stage == 2:
        for x in (6, 11, 20, 25):
            _put(img, x, ring_y, ch)

    if kind == "lightning":
        bolts = (
            [(4, 10), (5, 11), (4, 12), (5, 13), (27, 11), (26, 12), (27, 13)]
            if stage == 1 else
            [(3, 7), (4, 8), (3, 9), (4, 10), (3, 11), (28, 7), (27, 8), (28, 9), (27, 10), (28, 11),
             (5, 22), (4, 23), (27, 21), (28, 22)]
        )
        for x, y in bolts:
            _put(img, x, y, ch)
            _put(img, x + 1, y, cg)
    elif kind == "wave":
        pts = [(4, 24), (5, 22), (6, 20), (26, 24), (25, 22), (24, 20)] if stage == 1 else \
              [(3, 25), (4, 22), (5, 19), (4, 16), (28, 25), (27, 22), (26, 19), (27, 16)]
        for x, y in pts:
            _put(img, x, y, cm)
            _put(img, x, y - 1, ch)
    elif kind == "fire":
        flames = [(4, 23), (5, 21), (5, 19), (26, 23), (25, 21), (25, 19)] if stage == 1 else \
                 [(3, 24), (4, 21), (4, 18), (5, 15), (28, 24), (27, 21), (27, 18), (26, 15), (15, 1)]
        for x, y in flames:
            _put(img, x, y, cm)
            _put(img, x, y - 1, ch)
            _put(img, x, y + 1, cg)
    elif kind == "drum":
        rays = [(4, 14), (27, 14), (6, 8), (25, 8), (6, 22), (25, 22)] if stage == 1 else \
               [(2, 14), (3, 14), (28, 14), (29, 14), (5, 5), (26, 5), (5, 23), (26, 23), (15, 1), (16, 1)]
        for x, y in rays:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)
    elif kind == "sword":
        cols = [(5, 19), (5, 16), (26, 19), (26, 16)] if stage == 1 else \
               [(4, 22), (4, 18), (4, 14), (4, 10), (27, 22), (27, 18), (27, 14), (27, 10), (15, 1), (16, 1)]
        for x, y in cols:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)
            _put(img, x, y + 2, cg)
    elif kind in ("twin", "poem"):
        stars = [(5, 12), (26, 14), (6, 22), (25, 20)] if stage == 1 else \
                [(4, 9), (27, 10), (3, 18), (28, 18), (6, 24), (25, 24), (15, 1)]
        for x, y in stars:
            _put(img, x, y, ch)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                _put(img, x + dx, y + dy, cg)
    else:  # roar, tiger, rally
        sparks = [(5, 16), (6, 12), (26, 16), (25, 12)] if stage == 1 else \
                 [(3, 15), (4, 11), (6, 7), (28, 15), (27, 11), (25, 7), (4, 22), (27, 22)]
        for x, y in sparks:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)


# ---------------------------------------------------------------- Ghép 1 khung hình đứng/động
def _render_raw(spec, legs, bob=0, breathe=0, dx=0, expr="normal",
                arm_pose="idle", back_dx=0, head_dy=0, head_dx=0, torso_dy=0,
                with_legs=True):
    p = spec["pal"]
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    # 1. Lớp sau (tóc dài, áo choàng, ba lô, dải khăn) di chuyển đồng bộ với thân
    if spec.get("head_back"):
        back = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        draw_rows(back, spec["head_back"], p, y0=torso_dy, dx=dx + back_dx)
        img.alpha_composite(back, (0, bob))

    # 2. Chân
    if with_legs and legs:
        draw_rows(img, legs, p, y0=LEG_Y, dx=dx)
        if bob < 0:
            draw_rows(img, [legs[0]], p, y0=LEG_Y - 1, dx=dx)

    # 3. Thân chibi (y=19..25)
    body = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw_rows(body, spec["torso"], p, y0=19 + torso_dy, dx=dx)
    a = spec["arm"]
    draw_rows(body, arms_rows(arm_pose, a["sleeve"], a["cuff"], a["hand"], a["shoulder"]),
              p, y0=19 + torso_dy, dx=dx)
    img.alpha_composite(body, (0, bob))

    # 4. Đầu chibi (mặt + mũ/tóc đè lên trán)
    head = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    frows = chibi_face(expr=expr, **spec["face"])
    draw_rows(head, frows, p, y0=9, dx=dx + head_dx)
    draw_rows(head, spec["head"], p, y0=0, dx=dx + head_dx)
    img.alpha_composite(head, (0, bob + breathe + head_dy))
    return img


def compose_frame(spec, legs, **kw):
    raw = _render_raw(spec, legs, **kw)
    return polish(raw)


def compose_fallen(spec):
    """Khung 15 (gục ngã nằm bệt): xoay nhân vật chibi (mắt x x) nằm ngang sát mặt đất rồi polish()."""
    raw = _render_raw(spec, LEGS_IDLE, expr="down", arm_pose="kneel", bob=0, breathe=0)
    rot = raw.transpose(Image.ROTATE_90)
    bbox = rot.getbbox()
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    if bbox:
        cropped = rot.crop(bbox)
        cw, ch = cropped.size
        if ch > 28:
            cropped = cropped.crop((0, (ch - 28) // 2, cw, (ch - 28) // 2 + 28))
            cw, ch = cropped.size
        if cw > 28:
            cropped = cropped.crop(((cw - 28) // 2, 0, (cw - 28) // 2 + 28, ch))
            cw, ch = cropped.size
        ox = max(2, (W - cw) // 2)
        oy = max(1, 29 - ch)
        out.alpha_composite(cropped, (ox, oy))
    return polish(out)


def build_hero_frames(spec):
    frames = []
    # 0..3: idle (4 khung — thở nhẹ + phất áo choàng/tóc)
    frames.append(compose_frame(spec, LEGS_IDLE, breathe=0, back_dx=0))
    frames.append(compose_frame(spec, LEGS_IDLE, breathe=0, back_dx=-1))
    frames.append(compose_frame(spec, LEGS_IDLE, breathe=1, back_dx=0))
    frames.append(compose_frame(spec, LEGS_IDLE, breathe=1, back_dx=-1))

    # 4..7: walk (4 khung — chạy chibi nảy người)
    walk_arms = ["walk_a", "idle", "walk_b", "idle"]
    walk_back = [-1, 0, -1, 0]
    for i in range(4):
        frames.append(compose_frame(spec, LEGS_WALK[i], bob=BOB[i],
                                    arm_pose=walk_arms[i], back_dx=walk_back[i]))

    # 8: hurt (1 khung — giật lùi, mắt > <)
    frames.append(compose_frame(spec, LEGS_IDLE, dx=-1, expr="hurt",
                                arm_pose="hurt", back_dx=-1))

    # 9..10: attack (2 khung — lao tới vung đòn + tia sáng đặc trưng từng tướng)
    f9 = compose_frame(spec, LEGS_ATTACK_1, dx=1, expr="fierce",
                       arm_pose="attack_1", back_dx=-1)
    _draw_attack_fx(f9, spec, 1)
    frames.append(f9)

    f10 = compose_frame(spec, LEGS_ATTACK_2, dx=1, bob=0, head_dy=1, head_dx=1,
                        expr="fierce", arm_pose="attack_2", back_dx=-2)
    _draw_attack_fx(f10, spec, 2)
    frames.append(f10)

    # 11..12: skill (2 khung — giơ tay tụ lực / tung chiêu + hào quang riêng từng tướng)
    f11 = compose_frame(spec, LEGS_SKILL, dx=0, bob=0, expr="skill",
                        arm_pose="skill_1", back_dx=-1)
    _draw_skill_fx(f11, spec, 1)
    frames.append(f11)

    f12 = compose_frame(spec, LEGS_SKILL, dx=0, bob=-1, expr="skill",
                        arm_pose="skill_2", back_dx=-2)
    _draw_skill_fx(f12, spec, 2)
    frames.append(f12)

    # 13..15: down (3 khung — loạng choạng -> khuỵu gối -> ngã nằm ngang)
    frames.append(compose_frame(spec, LEGS_STAGGER, dx=-2, head_dy=-1,
                                expr="hurt", arm_pose="stagger", back_dx=-1))
    frames.append(compose_frame(spec, LEGS_KNEEL, dx=0, bob=0, head_dy=3, head_dx=1,
                                torso_dy=2, expr="down", arm_pose="kneel", back_dx=0))
    frames.append(compose_fallen(spec))
    return frames


HEROES = {hid: spec for hid, spec in HERO_SPECS.items()}


def build():
    out = {}
    for hid, spec in HERO_SPECS.items():
        frames = build_hero_frames(spec)
        save(sheet(frames), f"heroes/{hid}.png")
        out[hid] = frames
    return out


if __name__ == "__main__":
    build()
