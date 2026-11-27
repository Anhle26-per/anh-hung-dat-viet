"""Tướng: vẽ tay từng pixel phong cách chibi đầu to (~55% chiều cao), khung 32x32, nhìn sang phải.

Mỗi hàng viết dạng R(x, "mẫu"): mẫu bắt đầu ở cột x. Dấu "." là trong suốt.
Bảng ký tự:
  s/S/z  da sáng / bóng / bóng sâu     b  má hồng    o  miệng
  e/w/i  mắt (đen / điểm sáng / tròng) h/H/j  tóc (gốc / sáng / tối)
  1/2/3/7 màu áo chính (gốc/tối/sáng/rất tối)    4/5/6  màu phụ (gốc/tối/sáng)
  g/G/y  vàng đồng (gốc/tối/sáng)      m/M/n  thép (gốc/tối/sáng)
  c/C/x  áo choàng (gốc/tối/rất tối)   r/R  tua đỏ    k/K  râu/lông bạc
  p/P    quần      q/Q  ủng
Xuất ra 1 dải 28 khung (896x32):
  0..3:   thở (idle, 4 khung gốc)
  4..7:   đi (walk, 4 khung gốc)
  8:      trúng đòn (hurt, 1 khung)
  9..10:  tấn công (attack 1-2)
  11..12: tung kỹ năng (skill 1-2)
  13..15: gục ngã (down, 3 khung: loạng choạng -> khuỵu gối -> ngã nằm)
  16..17: chuyển tiếp thở (idle 6 khung: [0, 1, 16, 2, 17, 3])
  18..21: bước trung gian (walk 8 khung: [4, 18, 5, 19, 6, 20, 7, 21])
  22..23: vung tiếp & thu thế (attack 4 khung: [9, 10, 22, 23])
  24..25: tụ lực & bùng nổ hào quang (skill 4 khung: [24, 11, 12, 25])
  26..27: lướt né (dash 2 khung: [26, 27])
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
    elif expr == "shimmer":
        e1 = "wwe"
        e2 = "eye"
        e3 = "iwe"
        e4 = "iwi" if lashes else "iwe"
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
    elif expr == "skill_climax":
        e1 = "wyw"
        e2 = "ywy"
        e3 = "ywy"
        e4 = "wiy"
        l_ext = "s"
        r_ext = "s"
    elif expr == "blink":
        e1 = "sss"
        e2 = "sss"
        e3 = "eee"
        e4 = "sss"
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
    if expr in ("hurt", "skill", "skill_climax", "fierce"):
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
LEGS_WALK_MID = [
    [R(11, "pppppPPPP"), R(11, "ppPP..ppPP"), R(10, "qqqQ..qqqQ"), R(10, "qqqqQ.qqqQ")],
    [R(11, "pppppPPPP"), R(11, "PPpp..ppPP"), R(10, "QqqQ...qqqQ"), R(9, "qqqQ....qqqqQ")],
    [R(11, "PPPPppppp"), R(11, "PPpp..ppPP"), R(11, "QqqQ..qqqQ"), R(11, "qqqQ..qqqqQ")],
    [R(11, "pppppPPPP"), R(10, "ppPP..ppPP"), R(10, "qqqQ...qqqQ"), R(9, "qqqqQ...qqqqQ")],
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
LEGS_ATTACK_3 = [
    R(10, "pppppPPPPP"),
    R(9, "ppPP.....ppPP"),
    R(8, "qqqQ......qqqQ"),
    R(7, "qqqqQ......qqqqQ"),
]
LEGS_ATTACK_4 = [
    R(11, "pppppPPPP"),
    R(10, "ppPP.ppPP"),
    R(10, "qqqQ.qqqQ"),
    R(9, "qqqqQqqqqQ"),
]
LEGS_SKILL = [
    R(10, "pppppPPPPP"),
    R(10, "ppPP...ppPP"),
    R(9, "qqqQ....qqqQ"),
    R(9, "qqqqQ...qqqqQ"),
]
LEGS_SKILL_WINDUP = [
    R(11, "pppppPPPP"),
    R(10, "ppPP.ppPP"),
    R(10, "qqqQ.qqqQ"),
    R(10, "qqqqQqqqqQ"),
]
LEGS_DASH_1 = [
    R(10, "pppppPPPP"),
    R(9, "ppPP..ppPP"),
    R(7, "qqqQ....qqqQ"),
    R(6, "qqqqQ....qqqqQ"),
]
LEGS_DASH_2 = [
    R(10, "pppppPPPP"),
    R(8, "ppPP...ppPP"),
    R(6, "qqqQ.....qqqQ"),
    R(5, "qqqqQ.....qqqqQ"),
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
    if pose == "idle_b":
        return [
            [R(9, sh), R(21, sh)],
            [R(9, sleeve), R(21, sleeve)],
            [R(9, hand), R(21, hand)],
            None, None, None,
        ]
    if pose == "walk_a":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(8, sleeve), R(22, sleeve)],
            [R(8, hand), R(22, hand)],
            None, None,
        ]
    if pose == "walk_mid_a":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(8, sleeve), R(21, sleeve)],
            [R(9, hand), R(21, hand)],
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
    if pose == "walk_mid_b":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(10, sleeve), R(21, sleeve)],
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
    if pose == "attack_3":
        return [
            [R(8, sleeve), R(21, sh + sleeve)],
            [R(7, hand), R(21, sleeve + cuff)],
            [R(22, hand + hand)],
            None, None, None,
        ]
    if pose == "attack_4":
        return [
            None,
            [R(9, sh), R(21, sh + sleeve)],
            [R(9, sleeve), R(21, cuff + hand)],
            [R(9, hand)],
            None, None,
        ]
    if pose == "skill_windup":
        return [
            None,
            [R(9, sh), R(21, sh)],
            [R(10, sleeve + cuff), R(20, cuff + sleeve)],
            [R(11, hand), R(19, hand)],
            None, None,
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
    if pose == "skill_climax":
        return [
            [R(5, hand + cuff), R(24, cuff + hand)],
            [R(7, cuff + sleeve), R(22, sleeve + cuff)],
            [R(9, sh), R(20, sh)],
            None, None, None,
        ]
    if pose == "dash_1":
        return [
            None,
            [R(8, sh + sleeve), R(21, sh)],
            [R(7, hand + sleeve), R(20, sleeve)],
            [R(6, hand), R(19, hand)],
            None, None,
        ]
    if pose == "dash_2":
        return [
            [R(7, hand + sleeve), R(20, sh)],
            [R(6, hand), R(19, sleeve + hand)],
            None, None, None, None,
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

    # ------------------------------------------------------------ 12. An Dương Vương
    "an_duong_vuong": {
        "pal": pal(**{
            "1": "d49a34", "2": "8c5c18", "3": "ffe074", "7": "54340c",
            "4": "38d8c8", "5": "1e8a82", "6": "b8fff8",
            "c": "246e78", "C": "164652", "x": "0d2b36",
            "i": "2ca8a0", "p": "5c3618", "P": "3a200e",
        }),
        "head_back": [
            None, None, None, None, None, None, None,
            R(5, "gG"), R(4, "ygG"), R(4, "gG"),
            R(5, "46"), R(5, "46"), R(5, "g4"), R(5, "g4"),
            R(4, "ygG"), R(5, "gG"), None, None, None,
            R(6, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(3, "cCCxCc"), R(3, "cCxxCx"), R(4, "CxxCx"),
        ],
        "head": [
            None,
            R(14, "y4y"),
            R(13, "y646y"),
            R(11, "g3g545g3g"),
            [R(4, "y3g"), R(9, "g311464113g"), R(23, "g3y")],
            [R(5, "3g"), R(8, "g31116461113g"), R(23, "g3")],
            R(8, "g11111y111111gG"),
            R(7, "y3111146411113gG"),
            R(7, "gGGGGGGGGGGGGGGGg"),
            R(7, "hhhhhsshhsshhhhhh"),
        ],
        "face": dict(flap="h", side="hh", brow="fierce", mustache="neat"),
        "torso": [
            R(10, "31g464g113"),
            R(10, "311g46g112"),
            R(10, "3111441112"),
            R(10, "5444yy4445"),
            R(9, "211314413112"),
            R(9, "211311113112"),
            R(9, "222122221222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="3"),
        "attack_fx": ("shot", "42f0de", "ffffff"),
        "skill_fx": ("poem", "f6c43c", "88fff4"),
    },

    # ------------------------------------------------------------ 13. Lạc Long Quân
    "lac_long_quan": {
        "pal": pal(**{
            "1": "2c8ae0", "2": "1a5496", "3": "7cc8ff", "7": "103260",
            "4": "f6c438", "5": "b07420", "6": "fff6a8",
            "c": "1e96a8", "C": "125c70", "x": "0a3646",
            "i": "38b4f0", "p": "1a4a84", "P": "102e58", "q": "264878", "Q": "162848",
        }),
        "head_back": [
            None, None, None, None, None, None,
            R(5, "hHhh"), R(5, "hhhh"), R(5, "hhhh"), R(5, "hhhh"),
            R(5, "hhhh"), R(5, "hhhh"), R(5, "hHhh"), R(5, "hhhh"),
            R(5, "hhhjh"), R(5, "hhhjh"), R(5, "hhhjh"), R(5, "hhhjh"),
            R(4, "hHhhj"),
            R(5, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(3, "cCCxCc"), R(3, "cCxxCx"), R(4, "CxxCx"),
        ],
        "head": [
            None,
            [R(9, "y"), R(21, "y")],
            [R(9, "yg"), R(14, "6y6"), R(20, "gy")],
            [R(10, "gG"), R(13, "46y64"), R(19, "Gg")],
            R(10, "g311464113g"),
            R(9, "g31114y41113g"),
            R(8, "y3111114111113g"),
            R(7, "y31111111111113g"),
            R(7, "g44444636444444g"),
            R(7, "G55555533555555G"),
        ],
        "face": dict(flap="h", side="hh", brow="thick", mustache="neat", beard="goatee"),
        "torso": [
            R(10, "3411yy1143"),
            R(10, "3141661412"),
            R(10, "3114444112"),
            R(10, "5444yy4445"),
            R(9, "241131131142"),
            R(9, "211112211112"),
            R(9, "222522225222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="6"),
        "attack_fx": ("slash", "3ec8ff", "fff6a8"),
        "skill_fx": ("wave", "34b8ff", "ffe878"),
    },

    # ------------------------------------------------------------ 14. Sơn Tinh
    "son_tinh": {
        "pal": pal(**{
            "1": "5c8c42", "2": "3a5c28", "3": "92c468", "7": "223816",
            "4": "d88e3a", "5": "8c5420", "6": "ffd078",
            "c": "785a3c", "C": "4e3824", "x": "302014",
            "i": "5c8c42", "p": "4a3826", "P": "2e2218",
        }),
        "head_back": [
            None, None, None, None, None,
            R(2, "mMM"), R(1, "nmmMM"), R(1, "mmMMM"), R(2, "MMM"),
            R(4, "45"), R(4, "45"), R(5, "45"), R(5, "45"), R(6, "45"), R(6, "45"),
            None, None, None, None,
            R(6, "cccc"), R(5, "cCccc"), R(4, "cCxccc"), R(4, "cCxCcc"),
            R(4, "cCCxCc"), R(4, "cCxxCx"), R(5, "CxxC"),
        ],
        "head": [
            None,
            [R(11, "h"), R(15, "H"), R(19, "h")],
            [R(10, "hH"), R(13, "hHhhH"), R(19, "Hh")],
            R(9, "hHhhhhhhhhhhj"),
            R(8, "hHhhhhhhhhhhhhj"),
            R(8, "hhhhhhhhhhhhhhj"),
            R(7, "464111464111464h"),
            R(7, "545313545313545h"),
            R(7, "hhhhhhhhhhhhhhhhj"),
            R(7, "hhhsssssssssssshh"),
        ],
        "face": dict(flap="h", side="hh", brow="thick", mustache="bushy", beard="bushy", mouth="grin"),
        "torso": [
            R(10, "3411661143"),
            R(10, "3141441412"),
            R(10, "3111441112"),
            R(9, "54444yy44445"),
            R(9, "241131131142"),
            R(9, "211112211112"),
            R(9, "222522225222"),
        ],
        "arm": dict(sleeve="1", cuff="4", hand="s", shoulder="6"),
        "attack_fx": ("slash", "e6a444", "fff2a8"),
        "skill_fx": ("drum", "8cd452", "ffd868"),
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
        elif stage == 2:
            arc = [(26, 12), (28, 14), (29, 17), (29, 20), (28, 23), (26, 25)]
            for x, y in arc:
                _put(img, x, y, ch)
                _put(img, x - 1, y, cm)
                _put(img, x - 2, y, cg)
            for x, y in ((27, 13), (28, 16), (28, 19), (27, 22)):
                _put(img, x, y, ch)
        elif stage == 3:
            smear = [(24, 9), (27, 11), (29, 14), (30, 18), (30, 22), (28, 25), (25, 27)]
            for x, y in smear:
                _put(img, x, y, ch)
                _put(img, x - 1, y, cm)
                _put(img, x - 2, y, cg)
                _put(img, x - 3, y, cg)
            for x, y in ((28, 13), (30, 16), (31, 19), (29, 23), (26, 26)):
                _put(img, x, y, (255, 255, 255, 245))
        else:
            for x, y in ((26, 24), (24, 26), (22, 27)):
                _put(img, x, y, cg)
            for x, y in ((25, 25), (23, 21)):
                _put(img, x, y, ch)
    elif kind == "thrust":
        if stage == 1:
            for x in (25, 26, 27):
                _put(img, x, 20, cm)
            _put(img, 27, 20, ch)
        elif stage == 2:
            for x in range(24, 31):
                _put(img, x, 20, ch)
                _put(img, x, 19, cm)
                _put(img, x, 21, cm)
            for x in (23, 25, 28):
                _put(img, x, 18, cg)
                _put(img, x, 22, cg)
            _put(img, 30, 20, (255, 255, 255, 255))
        elif stage == 3:
            for x in range(23, 32):
                _put(img, x, 20, ch)
                _put(img, x, 19, cm)
                _put(img, x, 21, cm)
            for x in (24, 26, 28):
                _put(img, x, 18, cm)
                _put(img, x, 22, cm)
            for x, y in ((25, 17), (26, 17), (25, 23), (26, 23)):
                _put(img, x, y, cg)
            _put(img, 31, 20, (255, 255, 255, 255))
            _put(img, 30, 20, (255, 255, 255, 240))
        else:
            for x, y in ((27, 19), (27, 21), (29, 20)):
                _put(img, x, y, cg)
            _put(img, 28, 20, ch)
    else:  # shot
        if stage == 1:
            for x, y in ((26, 20), (27, 19), (27, 21)):
                _put(img, x, y, cm)
            _put(img, 27, 20, ch)
        elif stage == 2:
            for x, y in ((26, 20), (27, 20), (28, 20), (29, 20), (30, 20),
                         (28, 18), (28, 19), (28, 21), (28, 22),
                         (27, 19), (29, 19), (27, 21), (29, 21)):
                _put(img, x, y, cm)
            for x, y in ((27, 20), (28, 20), (29, 20), (28, 19), (28, 21)):
                _put(img, x, y, ch)
            _put(img, 28, 20, (255, 255, 255, 255))
        elif stage == 3:
            for x in range(25, 32):
                _put(img, x, 20, ch if x >= 28 else cm)
            for x, y in ((26, 18), (27, 17), (26, 22), (27, 23), (29, 18), (29, 22), (30, 19), (30, 21)):
                _put(img, x, y, cg if x < 28 else cm)
            _put(img, 31, 20, (255, 255, 255, 255))
        else:
            for x, y in ((27, 18), (29, 19), (28, 21)):
                _put(img, x, y, cg)
            _put(img, 26, 20, cm)


def _draw_skill_fx(img, spec, stage):
    kind, c_main_h, c_hi_h = spec["skill_fx"]
    cm = hexc(c_main_h, 210)
    ch = hexc(c_hi_h, 245)
    cg = hexc(c_main_h, 115)

    if stage == 0:
        for x in range(8, 24):
            _put(img, x, 29, cm if x % 3 == 0 else cg)
        for x in (9, 15, 16, 22):
            _put(img, x, 28, ch)
        for x, y in ((8, 23), (23, 23), (10, 20), (21, 20)):
            _put(img, x, y, cm)
            _put(img, x, y - 1, ch)
        return

    ring_y = 29 if stage == 1 else 28
    span = range(6, 26) if stage == 1 else (range(4, 28) if stage == 2 else range(3, 29))
    for x in span:
        if (x + stage) % 2 == 0:
            _put(img, x, ring_y, cm)
        else:
            _put(img, x, ring_y, cg)
    if stage >= 2:
        for x in (6, 11, 20, 25):
            _put(img, x, ring_y, ch)
    if stage == 3:
        for x in range(5, 27, 2):
            _put(img, x, 30, cm)
        for x in (3, 9, 15, 16, 22, 28):
            _put(img, x, 27, ch)
            _put(img, x, 28, (255, 255, 255, 235))
        for x in (13, 15, 16, 18):
            _put(img, x, 1, ch)
        _put(img, 15, 0, (255, 255, 255, 240))

    if kind == "lightning":
        if stage == 1:
            bolts = [(4, 10), (5, 11), (4, 12), (5, 13), (27, 11), (26, 12), (27, 13)]
        elif stage == 2:
            bolts = [(3, 7), (4, 8), (3, 9), (4, 10), (3, 11), (28, 7), (27, 8), (28, 9), (27, 10), (28, 11),
                     (5, 22), (4, 23), (27, 21), (28, 22)]
        else:
            bolts = [(2, 5), (3, 6), (2, 7), (3, 8), (2, 9), (4, 15), (3, 16), (4, 17),
                     (29, 5), (28, 6), (29, 7), (28, 8), (29, 9), (27, 15), (28, 16), (27, 17),
                     (6, 24), (25, 24)]
        for x, y in bolts:
            _put(img, x, y, ch)
            _put(img, x + 1, y, cg)
    elif kind == "wave":
        if stage == 1:
            pts = [(4, 24), (5, 22), (6, 20), (26, 24), (25, 22), (24, 20)]
        elif stage == 2:
            pts = [(3, 25), (4, 22), (5, 19), (4, 16), (28, 25), (27, 22), (26, 19), (27, 16)]
        else:
            pts = [(2, 26), (3, 23), (4, 20), (5, 17), (3, 14), (29, 26), (28, 23), (27, 20), (26, 17), (28, 14)]
        for x, y in pts:
            _put(img, x, y, cm)
            _put(img, x, y - 1, ch)
    elif kind == "fire":
        if stage == 1:
            flames = [(4, 23), (5, 21), (5, 19), (26, 23), (25, 21), (25, 19)]
        elif stage == 2:
            flames = [(3, 24), (4, 21), (4, 18), (5, 15), (28, 24), (27, 21), (27, 18), (26, 15), (15, 1)]
        else:
            flames = [(2, 25), (3, 22), (3, 19), (4, 16), (5, 12), (29, 25), (28, 22), (28, 19), (27, 16), (26, 12), (14, 2), (17, 2)]
        for x, y in flames:
            _put(img, x, y, cm)
            _put(img, x, y - 1, ch)
            _put(img, x, y + 1, cg)
    elif kind == "drum":
        if stage == 1:
            rays = [(4, 14), (27, 14), (6, 8), (25, 8), (6, 22), (25, 22)]
        elif stage == 2:
            rays = [(2, 14), (3, 14), (28, 14), (29, 14), (5, 5), (26, 5), (5, 23), (26, 23), (15, 1), (16, 1)]
        else:
            rays = [(1, 14), (2, 14), (29, 14), (30, 14), (4, 5), (5, 6), (27, 5), (26, 6),
                    (4, 23), (27, 23), (9, 2), (22, 2)]
        for x, y in rays:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)
    elif kind == "sword":
        if stage == 1:
            cols = [(5, 19), (5, 16), (26, 19), (26, 16)]
        elif stage == 2:
            cols = [(4, 22), (4, 18), (4, 14), (4, 10), (27, 22), (27, 18), (27, 14), (27, 10), (15, 1), (16, 1)]
        else:
            cols = [(3, 23), (3, 19), (3, 15), (3, 11), (3, 7), (28, 23), (28, 19), (28, 15), (28, 11), (28, 7), (15, 2), (16, 2)]
        for x, y in cols:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)
            _put(img, x, y + 2, cg)
    elif kind in ("twin", "poem"):
        if stage == 1:
            stars = [(5, 12), (26, 14), (6, 22), (25, 20)]
        elif stage == 2:
            stars = [(4, 9), (27, 10), (3, 18), (28, 18), (6, 24), (25, 24), (15, 1)]
        else:
            stars = [(3, 7), (28, 7), (2, 16), (29, 16), (5, 24), (26, 24), (11, 2), (20, 2)]
        for x, y in stars:
            _put(img, x, y, ch)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                _put(img, x + dx, y + dy, cg)
    else:  # roar, tiger, rally
        if stage == 1:
            sparks = [(5, 16), (6, 12), (26, 16), (25, 12)]
        elif stage == 2:
            sparks = [(3, 15), (4, 11), (6, 7), (28, 15), (27, 11), (25, 7), (4, 22), (27, 22)]
        else:
            sparks = [(2, 15), (3, 10), (5, 5), (29, 15), (28, 10), (26, 5), (3, 22), (28, 22), (10, 2), (21, 2)]
        for x, y in sparks:
            _put(img, x, y, ch)
            _put(img, x, y + 1, cm)


# ---------------------------------------------------------------- Ghép 1 khung hình đứng/động
def _render_raw(spec, legs, bob=0, breathe=0, dx=0, expr="normal",
                arm_pose="idle", back_dx=0, back_dy=0, back_ripple=0,
                head_dy=0, head_dx=0, torso_dy=0, with_legs=True):
    p = spec["pal"]
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    # 1. Lớp sau (tóc dài, áo choàng, ba lô, dải khăn) di chuyển đồng bộ với thân
    hb = spec.get("head_back")
    if hb:
        back = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        if back_ripple and len(hb) >= 24 and any(hb[23:]):
            draw_rows(back, hb[:20], p, y0=torso_dy + back_dy, dx=dx + back_dx)
            draw_rows(back, hb[20:], p, y0=20 + torso_dy + back_dy, dx=dx + back_dx + back_ripple)
        else:
            draw_rows(back, hb, p, y0=torso_dy + back_dy, dx=dx + back_dx)
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


def _draw_idle_glint(img, spec, stage):
    _, c_main_h, c_hi_h = spec["attack_fx"]
    cm = hexc(c_main_h, 175)
    ch = hexc(c_hi_h, 230)
    if stage == 1:
        _put(img, 22, 19, ch)
        _put(img, 23, 19, cm)
        _put(img, 22, 18, cm)
    elif stage == 3:
        _put(img, 10, 6, ch)
        _put(img, 11, 6, cm)
        _put(img, 23, 21, ch)


def _draw_armor_highlight(img, spec, stage):
    _, c_main_h, c_hi_h = spec["attack_fx"]
    hi = hexc(c_hi_h, 210)
    sh = (255, 255, 255, 185)
    px = img.load()
    spots = {
        0: [(14, 19), (15, 19), (12, 6)],
        1: [(15, 20), (16, 20), (10, 20), (20, 20)],
        2: [(16, 21), (17, 21), (14, 5), (15, 5)],
        3: [(13, 20), (14, 21), (15, 22), (16, 6)],
    }
    for x, y in spots.get(stage % 4, []):
        if 0 <= x < W and 0 <= y < W and px[x, y][3] > 200 and px[x, y][:3] != (16, 10, 20):
            _put(img, x, y, sh if (x + y) % 2 == 0 else hi)


def _draw_walk_dust(img, idx):
    dust_a = (225, 215, 195, 165)
    dust_b = (205, 192, 172, 110)
    pts = [(7, 29), (8, 29), (6, 28)] if idx % 2 == 0 else [(8, 29), (9, 28)]
    for x, y in pts:
        _put(img, x, y, dust_a if x > 7 else dust_b)


def _draw_hurt_fx(img):
    sp = (255, 240, 180, 235)
    sp2 = (255, 110, 90, 195)
    for x, y in ((24, 11), (25, 12), (24, 13)):
        _put(img, x, y, sp)
    for x, y in ((25, 10), (26, 12), (6, 15)):
        _put(img, x, y, sp2)


def _draw_dash_fx(img, spec, stage):
    _, c_main_h, c_hi_h = spec["attack_fx"]
    cm = hexc(c_main_h, 195)
    ch = hexc(c_hi_h, 235)
    cg = hexc(c_main_h, 105)
    wind_hi = (235, 248, 255, 225)
    if stage == 1:
        streaks = [(10, (2, 7)), (15, (1, 6)), (20, (0, 6)), (25, (2, 7))]
        for y, (x0, x1) in streaks:
            for x in range(x0, x1 + 1):
                _put(img, x, y, wind_hi if x >= x1 - 1 else (ch if x >= x1 - 3 else cg))
        for x, y in ((4, 29), (5, 29), (6, 28), (7, 29)):
            _put(img, x, y, cm)
    else:
        streaks = [(8, (1, 8)), (12, (0, 7)), (17, (0, 8)), (22, (1, 8)), (27, (2, 9))]
        for y, (x0, x1) in streaks:
            for x in range(x0, x1 + 1):
                _put(img, x, y, wind_hi if x >= x1 - 1 else (cm if x >= x1 - 3 else cg))
        for x, y in ((4, 14), (3, 19), (5, 24)):
            _put(img, x, y, ch)


def build_hero_frames(spec):
    frames = []
    # 0..3: idle (4 khung gốc — thở nhẹ, chớp mắt, phất áo choàng/tóc, lấp lánh vũ khí/trang sức)
    f0 = compose_frame(spec, LEGS_IDLE, breathe=0, back_dx=0, expr="normal", arm_pose="idle")
    frames.append(f0)

    f1 = compose_frame(spec, LEGS_IDLE, breathe=0, back_dx=-1, expr="normal", arm_pose="idle_b")
    _draw_idle_glint(f1, spec, 1)
    frames.append(f1)

    f2 = compose_frame(spec, LEGS_IDLE, breathe=1, back_dx=-1, torso_dy=1, expr="normal", arm_pose="idle")
    frames.append(f2)

    f3 = compose_frame(spec, LEGS_IDLE, breathe=0, back_dx=0, expr="blink", arm_pose="idle_b")
    _draw_idle_glint(f3, spec, 3)
    frames.append(f3)

    # 4..7: walk (4 khung gốc — chạy chibi nảy người + tung bụi bước chân + áo choàng bay)
    walk_arms = ["walk_a", "idle_b", "walk_b", "idle"]
    walk_back = [-1, -2, -1, -2]
    for i in range(4):
        fw = compose_frame(spec, LEGS_WALK[i], bob=BOB[i], head_dx=(1 if i in (0, 2) else 0),
                           arm_pose=walk_arms[i], back_dx=walk_back[i])
        _draw_walk_dust(fw, i)
        frames.append(fw)

    # 8: hurt (1 khung gốc — giật lùi, mắt > < + tia va chạm)
    f8 = compose_frame(spec, LEGS_IDLE, dx=-1, expr="hurt",
                       arm_pose="hurt", back_dx=-1)
    _draw_hurt_fx(f8)
    frames.append(f8)

    # 9..10: attack (2 khung gốc — lao tới vung đòn + tia sáng đặc trưng từng tướng)
    f9 = compose_frame(spec, LEGS_ATTACK_1, dx=1, expr="fierce",
                       arm_pose="attack_1", back_dx=-1)
    _draw_attack_fx(f9, spec, 1)
    frames.append(f9)

    f10 = compose_frame(spec, LEGS_ATTACK_2, dx=1, bob=0, head_dy=1, head_dx=1,
                        expr="fierce", arm_pose="attack_2", back_dx=-2)
    _draw_attack_fx(f10, spec, 2)
    frames.append(f10)

    # 11..12: skill (2 khung gốc — giơ tay tụ lực / tung chiêu + hào quang riêng từng tướng)
    f11 = compose_frame(spec, LEGS_SKILL, dx=0, bob=0, expr="skill",
                        arm_pose="skill_1", back_dx=-1)
    _draw_skill_fx(f11, spec, 1)
    frames.append(f11)

    f12 = compose_frame(spec, LEGS_SKILL, dx=0, bob=-1, expr="skill",
                        arm_pose="skill_2", back_dx=-2)
    _draw_skill_fx(f12, spec, 2)
    frames.append(f12)

    # 13..15: down (3 khung gốc — loạng choạng -> khuỵu gối -> ngã nằm ngang)
    frames.append(compose_frame(spec, LEGS_STAGGER, dx=-2, head_dy=-1,
                                expr="hurt", arm_pose="stagger", back_dx=-1))
    frames.append(compose_frame(spec, LEGS_KNEEL, dx=0, bob=0, head_dy=3, head_dx=1,
                                torso_dy=2, expr="down", arm_pose="kneel", back_dx=0))
    frames.append(compose_fallen(spec))

    # 16..17: 2 khung chuyển tiếp thở (idle 6 khung: [0, 1, 16, 2, 17, 3])
    f16 = compose_frame(spec, LEGS_IDLE, breathe=0, torso_dy=1, back_dx=-2, back_ripple=-1,
                        expr="shimmer", arm_pose="idle_b")
    _draw_armor_highlight(f16, spec, 0)
    frames.append(f16)

    f17 = compose_frame(spec, LEGS_IDLE, breathe=0, torso_dy=1, back_dx=-1, back_ripple=1,
                        expr="shimmer", arm_pose="idle")
    _draw_idle_glint(f17, spec, 1)
    _draw_armor_highlight(f17, spec, 2)
    frames.append(f17)

    # 18..21: 4 khung bước trung gian (walk 8 khung: [4, 18, 5, 19, 6, 20, 7, 21])
    mid_specs = [
        (0, 0, 1, 0, "walk_mid_a", -2, -1, True, 1),
        (1, -1, 0, 1, "walk_mid_b", -2, 1, False, 2),
        (2, 0, 1, 0, "walk_mid_b", -2, -1, True, 3),
        (3, -1, 0, 1, "walk_mid_a", -1, 1, False, 0),
    ]
    for idx, bob, hdx, hdy, apose, bdx, brip, dust, hi_st in mid_specs:
        fm = compose_frame(spec, LEGS_WALK_MID[idx], bob=bob, head_dx=hdx, head_dy=hdy,
                           arm_pose=apose, back_dx=bdx, back_ripple=brip)
        if dust:
            _draw_walk_dust(fm, idx)
        _draw_armor_highlight(fm, spec, hi_st)
        frames.append(fm)

    # 22..23: 2 khung vung tiếp & thu thế (attack 4 khung: [9, 10, 22, 23])
    f22 = compose_frame(spec, LEGS_ATTACK_3, dx=2, bob=0, torso_dy=1, head_dy=1, head_dx=1,
                        expr="fierce", arm_pose="attack_3", back_dx=-2, back_ripple=-1)
    _draw_armor_highlight(f22, spec, 2)
    _draw_attack_fx(f22, spec, 3)
    frames.append(f22)

    f23 = compose_frame(spec, LEGS_ATTACK_4, dx=1, bob=0, torso_dy=0, head_dy=0, head_dx=0,
                        expr="fierce", arm_pose="attack_4", back_dx=-1)
    _draw_armor_highlight(f23, spec, 0)
    _draw_attack_fx(f23, spec, 4)
    frames.append(f23)

    # 24..25: 2 khung tụ lực & bùng nổ hào quang (skill 4 khung: [24, 11, 12, 25])
    f24 = compose_frame(spec, LEGS_SKILL_WINDUP, dx=0, bob=0, torso_dy=1, head_dy=1,
                        expr="shimmer", arm_pose="skill_windup", back_dx=-1, back_ripple=-1)
    _draw_armor_highlight(f24, spec, 1)
    _draw_skill_fx(f24, spec, 0)
    frames.append(f24)

    f25 = compose_frame(spec, LEGS_SKILL, dx=0, bob=-1, head_dy=-1,
                        expr="skill_climax", arm_pose="skill_climax", back_dx=-3, back_ripple=-1)
    _draw_armor_highlight(f25, spec, 3)
    _draw_skill_fx(f25, spec, 3)
    frames.append(f25)

    # 26..27: 2 khung lướt né (dash 2 khung: [26, 27])
    f26 = compose_frame(spec, LEGS_DASH_1, dx=1, bob=0, torso_dy=1, head_dx=1, head_dy=1,
                        expr="fierce", arm_pose="dash_1", back_dx=-1, back_ripple=-1)
    _draw_armor_highlight(f26, spec, 2)
    _draw_dash_fx(f26, spec, 1)
    frames.append(f26)

    f27 = compose_frame(spec, LEGS_DASH_2, dx=1, bob=-1, torso_dy=0, head_dx=1, head_dy=0,
                        expr="fierce", arm_pose="dash_2", back_dx=-1, back_ripple=-2)
    _draw_armor_highlight(f27, spec, 3)
    _draw_dash_fx(f27, spec, 2)
    frames.append(f27)

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
