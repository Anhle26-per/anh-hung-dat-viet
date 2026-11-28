"""Đồ họa động đa khung hình (4-tone hue-shifted pixel art):
- 3 Thú Cưỡi 12 khung (48x38 -> 576x38): idle (0..3), move (4..9), charge/fire (10..11)
- Voi chiến / Ngựa sắt kỹ năng 8 khung (40x34 -> 320x34): fx/elephant.png, fx/iron_horse.png
- 8 NPC doanh trại & hầm ngục 8 khung (0..3 idle, 4..7 hành động): blacksmith, tea_lady,
  strategist, scholar, guard, merchant, mentor_npc, rescue_camp
- Lồng giam NPC 6 khung (32x34 -> 192x34): tù nhân lay song sắt & vẫy tay cầu cứu
"""
import math
from px import hexc, outline, save, sheet, canvas, DARK_LINE, Image, ImageDraw

C = {k: hexc(v) for k, v in {
    "ele_hi": "a8a6bc", "ele_l": "84829a", "ele": "646278", "ele_d": "423e54",
    "ivory_hi": "fffaf0", "ivory": "f4ead2", "ivory_d": "b8a88c",
    "gold_hi": "fff6b0", "gold_l": "ffd452", "gold": "d48824", "gold_d": "784414",
    "red_hi": "ff9e8e", "red_l": "ec4e48", "red": "b82430", "red_d": "681422",
    "steel_hi": "f4f8ff", "steel_l": "bccde8", "steel": "7888a8", "steel_d": "3e4862",
    "tank_hi": "94bc68", "tank_l": "6e964a", "tank": "4c6c32", "tank_d": "2c4220",
    "track_l": "54586a", "track": "343644", "track_d": "1e1e2a",
    "fire_hi": "fff494", "fire_l": "ffa630", "fire": "e84e24", "fire_d": "961c18",
    "skin_l": "ffe2c4", "skin": "f4c49c", "skin_d": "c28868",
    "wood_hi": "deaa6e", "wood_l": "b47846", "wood": "7c4c2a", "wood_d": "482818",
    "stone_hi": "beb8d2", "stone_l": "8c86a8", "stone": "5a5472", "stone_d": "322c44",
    "teal_l": "7ef0dc", "teal": "2eb8a8", "teal_d": "166862",
    "blue_hi": "c4f4ff", "blue_l": "62c6ff", "blue": "2a7ae0", "blue_d": "163a7e",
    "jade_l": "64e8b4", "jade": "269c72", "jade_d": "12503e",
    "purp_l": "ba82ff", "purp": "763cc4", "purp_d": "3c1e68",
    "leaf_l": "84d458", "leaf": "4e9234", "leaf_d": "28561e",
    "robe_l": "d6a874", "robe": "a47244", "robe_d": "684228",
    "ink_d": "1a1626", "ink": "322c42", "white": "ffffff", "cream": "fff5dc",
}.items()}


def _pp(img, x, y, col):
    w, h = img.size
    ix, iy = int(round(x)), int(round(y))
    if 1 <= ix < w - 1 and 1 <= iy < h - 1:
        img.putpixel((ix, iy), col)


def _rect(img, x0, y0, x1, y1, col):
    for y in range(int(round(y0)), int(round(y1)) + 1):
        for x in range(int(round(x0)), int(round(x1)) + 1):
            _pp(img, x, y, col)


def _disc(img, cx, cy, r, col):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                _pp(img, x, y, col)


def _line(img, x0, y0, x1, y1, col, thick=1):
    steps = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) * 2.5))
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        if thick <= 1:
            _pp(img, x, y, col)
        else:
            _disc(img, x, y, thick * 0.5, col)


def _shaded_disc(img, cx, cy, r, c_hi, c_l, c_m, c_d):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r2:
                # Nguồn sáng từ trên-trái (-0.6, -0.8)
                lum = (-dx * 0.55 - dy * 0.82) / max(1.0, r)
                col = c_hi if lum > 0.52 else (c_l if lum > 0.12 else (c_m if lum > -0.34 else c_d))
                _pp(img, x, y, col)


def _spark(img, cx, cy, c_outer, c_core=None, sz=1):
    _pp(img, cx, cy, c_core or C["white"])
    for d in range(1, sz + 1):
        _pp(img, cx - d, cy, c_outer)
        _pp(img, cx + d, cy, c_outer)
        _pp(img, cx, cy - d, c_outer)
        _pp(img, cx, cy + d, c_outer)


# ==================================================================== 1. Voi Chiến 12f (48x38)
def _draw_elephant_frame(f: int, w: int = 48, h: int = 38):
    img, _ = canvas(w, h)
    sx = w / 48.0
    sy = h / 38.0
    is_move = 4 <= f <= 9
    is_charge = f >= 10
    phase = (f - 4) / 6.0 * math.tau if is_move else (f / 4.0 * math.tau)
    bob = -1.2 if is_charge else (-abs(math.sin(phase)) * 2.0 if is_move else (1.0 if f in (1, 2) else 0.0))
    head_dx = 3.0 if is_charge else (0.8 * math.sin(phase) if is_move else 0.0)
    head_dy = 2.0 if is_charge else bob * 0.8

    # 4 chân voi với pha bước chéo tự nhiên
    if is_charge:
        legs = [(13, 33, -2, True), (18, 34, 0, False), (25, 32, 3, True), (30, 31, 4, False)]
    elif is_move:
        p1 = math.sin(phase) * 3.5
        p2 = math.sin(phase + math.pi) * 3.5
        legs = [(13, 34, p1, True), (18, 34, p2, False), (26, 34, p2, True), (31, 34, p1, False)]
    else:
        legs = [(14, 34, 0, True), (18, 34, 0, False), (26, 34, 0, True), (30, 34, 0, False)]

    for lx, ly_base, off_x, back in legs:
        lift = max(0.0, -off_x * 0.55) if is_move else (2.5 if (is_charge and lx > 22) else 0.0)
        ly = int(round((ly_base - lift) * sy))
        hip_x = int(round(lx * sx))
        foot_x = int(round((lx + off_x) * sx))
        hip_y = int(round((24 + bob) * sy))
        c_leg = C["ele_d"] if back else C["ele"]
        _line(img, hip_x, hip_y, foot_x, ly, c_leg, 4)
        if not back:
            _line(img, hip_x - 1, hip_y, foot_x - 1, ly - 1, C["ele_l"], 1)
        # Móng ngà
        _pp(img, foot_x - 1, ly, C["ivory_d"])
        _pp(img, foot_x, ly, C["ivory"])

    # Đuôi voi phe phẩy
    tail_sw = 2.0 * math.sin(phase + 1.0)
    _line(img, int(10 * sx), int((20 + bob) * sy), int((6 + tail_sw * 0.5) * sx), int((26 + bob * 0.5) * sy), C["ele_d"], 1)
    _pp(img, int((6 + tail_sw * 0.5) * sx), int((27 + bob * 0.5) * sy), C["ink"])

    # Thân voi 4 tầng chuyển sắc
    _shaded_disc(img, 20 * sx, (21 + bob) * sy, 10.2 * sx, C["ele_hi"], C["ele_l"], C["ele"], C["ele_d"])

    # Bành voi & thảm giáp gấm đỏ thêu vàng
    ky = (10 + bob) * sy
    _rect(img, 14 * sx, ky + 3, 25 * sx, ky + 11, C["red_d"])
    _rect(img, 14 * sx, ky + 2, 24 * sx, ky + 9, C["red"])
    _rect(img, 15 * sx, ky + 2, 22 * sx, ky + 5, C["red_l"])
    _rect(img, 13 * sx, ky + 1, 25 * sx, ky + 2, C["gold_l"])
    _rect(img, 14 * sx, ky + 9, 25 * sx, ky + 10, C["gold"])
    _pp(img, 19 * sx, ky + 6, C["gold_hi"])
    # Cờ chiến bay phía sau bành
    fwave = 2.0 * math.sin(phase * 1.4) + (2.5 if (is_move or is_charge) else 0.0)
    _line(img, 14 * sx, ky - 5, 14 * sx, ky + 3, C["wood_l"], 1)
    _line(img, 14 * sx, ky - 5, (14 - 5 - abs(fwave) * 0.6) * sx, ky - 4 + fwave * 0.3, C["red_l"], 3)
    _pp(img, (12 - abs(fwave) * 0.3) * sx, ky - 4, C["gold_hi"])

    # Đầu voi
    hx = (31 + head_dx) * sx
    hy = (17 + head_dy) * sy
    _shaded_disc(img, hx, hy, 6.8 * sx, C["ele_hi"], C["ele_l"], C["ele"], C["ele_d"])

    # Tai voi vẫy nhịp
    ear_flap = math.sin(phase * 1.5) * 1.8 + (2.0 if is_charge else 0.0)
    _shaded_disc(img, hx - 5.2 * sx - ear_flap * 0.4, hy + 0.5, 4.4 * sx, C["ele_l"], C["ele"], C["ele_d"], C["ele_d"])

    # Giáp trán đồng vàng + ngọc đỏ
    _rect(img, hx - 2, hy - 6, hx + 4, hy - 3, C["gold"])
    _rect(img, hx - 1, hy - 6, hx + 3, hy - 5, C["gold_hi"])
    _pp(img, hx + 1, hy - 4, C["red_l"])

    # Ngà voi trắng cong sắc
    _line(img, hx + 3, hy + 3, hx + 10, hy + (0 if is_charge else 1), C["ivory"], 2)
    _line(img, hx + 8, hy + 1, hx + 12, hy - (2 if is_charge else 1), C["white"], 1)
    _pp(img, hx + 5, hy + 4, C["ivory_d"])

    # Vòi voi vung theo hành động
    tr_ang = (-0.65 if is_charge else 0.35 * math.sin(phase))
    tx1 = hx + 6 + math.cos(tr_ang) * 4
    ty1 = hy + 3 + math.sin(tr_ang) * 3
    tx2 = tx1 + (4 if is_charge else -2 + math.sin(phase) * 2.5)
    ty2 = ty1 + (-5 if is_charge else 5)
    _line(img, hx + 4, hy + 1, tx1, ty1, C["ele_l"], 3)
    _line(img, tx1, ty1, tx2, ty2, C["ele"], 2)
    _pp(img, tx2, ty2, C["ele_hi"])
    _pp(img, hx + 2, hy - 1, C["ink_d"])  # mắt

    if is_charge:
        _spark(img, hx + 13, hy - 2, C["gold_l"], C["white"], 1)
    return outline(img, DARK_LINE)


# ==================================================================== 2. Ngựa Sắt 12f (48x38)
def _draw_horse_frame(f: int, w: int = 48, h: int = 38):
    img, _ = canvas(w, h)
    sx = w / 48.0
    sy = h / 38.0
    is_move = 4 <= f <= 9
    is_charge = f >= 10
    phase = (f - 4) / 6.0 * math.tau if is_move else (f / 4.0 * math.tau)
    bob = -2.2 if is_charge else (math.sin(phase * 2.0) * 1.8 if is_move else (0.8 if f in (1, 2) else 0.0))
    tilt = -3.0 if is_charge else 0.0

    # Đuôi lửa bùng cháy
    fl_jit = math.sin(phase * 1.7) * 2.0
    _line(img, 11 * sx, (19 + bob) * sy, (5 - fl_jit * 0.4) * sx, (16 + bob) * sy, C["fire"], 3)
    _line(img, (6 - fl_jit * 0.3) * sx, (17 + bob) * sy, (3 + fl_jit * 0.5) * sx, (21 + bob) * sy, C["fire_l"], 2)
    _pp(img, 4 * sx, (15 + bob) * sy, C["fire_hi"])

    # 4 chân sắt phi nước đại (có khớp gối tự nhiên, thân dày cân đối)
    if is_charge:
        legs = [(13, 33, -2.5), (17, 33, -0.5), (27, 23, 5.5), (30, 25, 4.5)]
    elif is_move:
        s1 = math.sin(phase) * 4.5
        s2 = math.sin(phase + math.pi * 0.85) * 4.5
        legs = [(14, 33, s1), (17, 32, -s1 * 0.7), (27, 33, s2), (30, 32, -s2 * 0.7)]
    else:
        paw = -2.0 if f == 2 else 0.0
        legs = [(14, 32, -0.5), (17, 32, 0.5), (27, 32, 0.0), (30, 32 + paw, 1.5 if f == 2 else 0.0)]

    for idx, (lx, ly_b, sw) in enumerate(legs):
        back = idx in (1, 2)
        hip_x = int(round(lx * sx))
        hip_y = int(round((23 + bob + (tilt if idx >= 2 else 0)) * sy))
        fx = int(round((lx + sw) * sx))
        fy = int(round(ly_b * sy))
        kx = int(round((hip_x + fx) * 0.5 + (1.5 if idx >= 2 else -1.0)))
        ky = int(round((hip_y + fy) * 0.5))
        col_leg = C["steel_d"] if back else C["steel_l"]
        _line(img, hip_x, hip_y, kx, ky, col_leg, 3)
        _line(img, kx, ky, fx, fy, col_leg, 2)
        _pp(img, fx, fy, C["fire_l"])
        if is_move or is_charge or (idx == 3 and f == 2):
            _pp(img, fx - 1, fy, C["fire_hi"])

    # Thân ngựa thép 4 tầng ánh kim dày dặn
    for y in range(int((14 + bob) * sy), int((25 + bob) * sy) + 1):
        for x in range(int(12 * sx), int(31 * sx) + 1):
            t_y = (y - (14 + bob) * sy) / max(1.0, 11.0 * sy)
            col = C["steel_hi"] if t_y < 0.25 else (C["steel_l"] if t_y < 0.55 else (C["steel"] if t_y < 0.82 else C["steel_d"]))
            _pp(img, x, y, col)

    # Yên chiến đỏ thêu vàng
    _rect(img, 16 * sx, (13 + bob) * sy, 25 * sx, (18 + bob) * sy, C["red"])
    _rect(img, 17 * sx, (13 + bob) * sy, 24 * sx, (15 + bob) * sy, C["red_l"])
    _rect(img, 17 * sx, (13 + bob) * sy, 24 * sx, (14 + bob) * sy, C["gold_l"])

    # Cổ & đầu ngựa thép rực lửa
    nx = 29 * sx
    ny = (17 + bob + tilt) * sy
    hx = (34 + (1.2 if is_move else 0.0)) * sx
    hy = (10 + bob + tilt) * sy
    _line(img, nx, ny, hx - 2, hy + 2, C["steel_l"], 5)
    _line(img, nx - 1, ny, hx - 3, hy + 1, C["steel_hi"], 2)
    # Đầu
    _line(img, hx - 2, hy, hx + 5, hy + 3, C["steel_hi"], 4)
    _line(img, hx + 2, hy + 2, hx + 7, hy + 5, C["steel"], 3)
    _line(img, hx - 4, hy - 3, hx - 2, hy, C["steel_hi"], 1)  # tai
    # Bờm lửa chuyển động
    for k in range(5):
        fk = math.sin(phase * 1.8 + k) * 1.2
        _line(img, hx - 3 - k * 1.4, hy - 1 + k * 1.5, hx - 6 - k * 1.4 + fk, hy + k * 1.6, C["fire_hi"] if k % 2 == 0 else C["fire_l"], 2)
    _pp(img, hx + 2, hy + 1, C["fire_hi"])  # mắt rực sáng
    if is_charge or f in (1, 3):
        _spark(img, hx + 8, hy + 5, C["fire_l"], C["fire_hi"], 1 if is_charge else 0)
    return outline(img, DARK_LINE)


# ==================================================================== 3. Xe Tăng Chiến 12f (48x38)
def _draw_tank_frame(f: int):
    img, _ = canvas(48, 38)
    is_move = 4 <= f <= 9
    is_charge = f >= 10
    vibe = (f % 2) if is_move else 0
    recoil = -3 if f == 10 else (-1 if f == 11 else 0)

    # Bóng & khói ống xả phía sau
    ex_off = (f % 4) * 1.5
    if f % 2 == 1 or is_move or is_charge:
        _disc(img, 6 - ex_off * 0.4, 21 - ex_off, 2.0, C["stone_l"])
        _pp(img, 5 - ex_off * 0.6, 18 - ex_off, C["stone_hi"])

    # Hộp xích xe tăng + mắt xích chuyển động thực sự
    _rect(img, 7, 25 + vibe, 39, 33 + vibe, C["track_d"])
    _rect(img, 8, 26 + vibe, 38, 32 + vibe, C["track"])
    tread_shift = (f * 2) % 4 if (is_move or is_charge) else 0
    for tx in range(8 + tread_shift, 39, 4):
        _pp(img, tx, 25 + vibe, C["steel_l"])
        _pp(img, 46 - tx, 33 + vibe, C["steel"])
    for idx, wx in enumerate((11, 17, 23, 29, 35)):
        _shaded_disc(img, wx, 29 + vibe, 2.3, C["steel_hi"], C["steel_l"], C["steel"], C["steel_d"])
        spoke_ang = (f * 0.9 + idx) if is_move else 0.0
        _pp(img, wx + math.cos(spoke_ang) * 1.2, 29 + vibe + math.sin(spoke_ang) * 1.2, C["ink_d"])

    # Thân xe tăng 4 sắc độ xanh rêu quân sự
    _rect(img, 8, 19 + vibe, 38, 26 + vibe, C["tank_d"])
    _rect(img, 9, 18 + vibe, 37, 24 + vibe, C["tank"])
    _rect(img, 10, 18 + vibe, 35, 20 + vibe, C["tank_hi"])
    _rect(img, 10, 21 + vibe, 35, 22 + vibe, C["tank_l"])
    # Ngôi sao vàng trên thân
    _spark(img, 23, 22 + vibe, C["gold_l"], C["gold_hi"], 1)

    # Tháp pháo & nòng giật khi bắn
    _rect(img, 14 + recoil, 12 + vibe, 29 + recoil, 18 + vibe, C["tank_l"])
    _rect(img, 15 + recoil, 12 + vibe, 27 + recoil, 14 + vibe, C["tank_hi"])
    _rect(img, 18 + recoil, 10 + vibe, 24 + recoil, 12 + vibe, C["tank"])
    # Nòng pháo thép
    _rect(img, 29 + recoil, 13 + vibe, 42 + recoil, 16 + vibe, C["steel"])
    _rect(img, 29 + recoil, 13 + vibe, 42 + recoil, 14 + vibe, C["steel_hi"])
    _rect(img, 29 + recoil, 16 + vibe, 42 + recoil, 16 + vibe, C["steel_d"])
    _rect(img, 41 + recoil, 12 + vibe, 44 + recoil, 17 + vibe, C["steel_l"])
    if is_charge:
        _disc(img, 45, 14, 2.6 if f == 10 else 1.6, C["fire_l"])
        _pp(img, 45, 14, C["white"])
    return outline(img, DARK_LINE)


# ==================================================================== 4. NPC Hoạt Ảnh 2 Hành Động (0..3 Idle, 4..7 Action)
def _draw_humanoid_base(w: int, h: int, robe_col: tuple, robe_l: tuple, robe_d: tuple, bob: float, skin_hair: tuple, arm_l: tuple, arm_r: tuple, hat: str = ""):
    img, _ = canvas(w, h)
    cx = w // 2
    by = h - 4 + bob
    # Chân & giày
    _rect(img, cx - 4, by - 2, cx - 1, by + 2, C["ink"])
    _rect(img, cx + 1, by - 2, cx + 4, by + 2, C["ink"])
    # Áo bào 3 sắc độ
    _rect(img, cx - 6, by - 13, cx + 6, by - 2, robe_d)
    _rect(img, cx - 5, by - 13, cx + 5, by - 3, robe_col)
    _rect(img, cx - 4, by - 13, cx + 1, by - 5, robe_l)
    _rect(img, cx - 5, by - 7, cx + 5, by - 6, C["gold"])  # đai lưng
    # Đầu tròn có bóng
    hy = by - 18
    _shaded_disc(img, cx, hy, 4.6, C["skin_l"], C["skin"], C["skin"], C["skin_d"])
    _pp(img, cx - 2, hy + 1, C["ink_d"])
    _pp(img, cx + 2, hy + 1, C["ink_d"])
    # Tóc / Mũ
    if hat == "turban_red":
        _rect(img, cx - 5, hy - 5, cx + 5, hy - 2, C["red"])
        _rect(img, cx - 4, hy - 6, cx + 4, hy - 4, C["red_l"])
    elif hat == "bun":
        _rect(img, cx - 5, hy - 5, cx + 5, hy - 2, skin_hair)
        _disc(img, cx, hy - 6, 2.2, skin_hair)
    elif hat == "helm":
        _rect(img, cx - 5, hy - 6, cx + 5, hy - 2, C["steel"])
        _rect(img, cx - 4, hy - 6, cx + 3, hy - 4, C["steel_hi"])
        _pp(img, cx, hy - 7, C["red_l"])
    elif hat == "scholar_cap":
        _rect(img, cx - 6, hy - 5, cx + 6, hy - 2, C["ink"])
        _rect(img, cx - 4, hy - 7, cx + 4, hy - 4, C["gold"])
    elif hat == "medic_band":
        _rect(img, cx - 5, hy - 5, cx + 5, hy - 2, C["wood_d"])
        _rect(img, cx - 5, hy - 3, cx + 5, hy - 2, C["jade_l"])
    else:
        _rect(img, cx - 5, hy - 5, cx + 5, hy - 2, skin_hair)
    # Tay trái & tay phải
    _line(img, cx - 5, by - 11, arm_l[0], arm_l[1], robe_col, 2)
    _pp(img, arm_l[0], arm_l[1], C["skin"])
    _line(img, cx + 5, by - 11, arm_r[0], arm_r[1], robe_l, 2)
    _pp(img, arm_r[0], arm_r[1], C["skin_l"])
    return img


def build_npcs():
    # 1. npc_blacksmith (28x30, 8f: 0..3 thở/lau mồ hôi, 4..7 vung búa nện đe tóe lửa)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 2, 5) else 0
        if f < 4:
            # Idle: cầm búa gác vai, vung nhẹ thở
            arm_l = (8, 17 + (1 if f == 1 else 0))
            arm_r = (21, 14 if f != 2 else 10)
            img = _draw_humanoid_base(28, 30, C["wood"], C["wood_l"], C["wood_d"], bob, C["ink"], arm_l, arm_r, "bun")
            _line(img, arm_r[0], arm_r[1], arm_r[0] + 2, arm_r[1] - 5, C["wood_l"], 1)
            _rect(img, arm_r[0] + 1, arm_r[1] - 7, arm_r[0] + 4, arm_r[1] - 4, C["steel_hi"])
        else:
            # Action: giơ búa cao rồi đập mạnh xuống đe
            swing = [(-3, -8), (0, -10), (4, 1), (3, -2)][f - 4]
            arm_l = (7, 19)
            arm_r = (20 + swing[0] * 0.3, 15 + swing[1] * 0.4)
            img = _draw_humanoid_base(28, 30, C["wood"], C["wood_l"], C["wood_d"], bob, C["ink"], arm_l, arm_r, "bun")
            hx, hy = arm_r[0] + swing[0] * 0.5, arm_r[1] + swing[1] * 0.6
            _line(img, arm_r[0], arm_r[1], hx, hy, C["wood_l"], 1)
            _rect(img, hx - 2, hy - 2, hx + 2, hy + 1, C["steel_hi"])
            if f == 6:
                _spark(img, hx + 2, hy + 2, C["fire_l"], C["fire_hi"], 2)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/npc_blacksmith.png")

    # 2. npc_tea_lady (24x30, 8f: 0..3 phẩy quạt, 4..7 nhấc ấm rót trà nóng)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 5) else 0
        fan = [-2, 0, 2, 0][f % 4]
        if f < 4:
            img = _draw_humanoid_base(24, 30, C["jade"], C["jade_l"], C["jade_d"], bob, C["ink_d"], (5, 19), (18, 15 + fan * 0.4), "turban_red")
            # Quạt nan tre
            _line(img, 18, 15, 21, 11 + fan, C["gold_l"], 2)
            _pp(img, 21, 11 + fan, C["cream"])
        else:
            lift = [0, -2, -1, 0][f - 4]
            img = _draw_humanoid_base(24, 30, C["jade"], C["jade_l"], C["jade_d"], bob, C["ink_d"], (6, 17 + lift), (18, 17 + lift), "turban_red")
            # Ấm trà gốm + dòng trà vàng rót xuống
            _disc(img, 19, 16 + lift, 2.3, C["wood_l"])
            _pp(img, 19, 14 + lift, C["gold_hi"])
            if f in (5, 6):
                _line(img, 21, 17 + lift, 21, 24, C["gold_hi"], 1)
                _pp(img, 21, 12, C["cream"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/npc_tea_lady.png")

    # 3. npc_strategist (24x30, 8f: 0..3 vuốt râu/đọc sách, 4..7 giơ quạt chỉ sa bàn)
    fr = []
    for f in range(8):
        bob = 1 if f in (2, 6) else 0
        if f < 4:
            img = _draw_humanoid_base(24, 30, C["blue"], C["blue_l"], C["blue_d"], bob, C["ivory"], (6, 18), (16, 16 + (f % 2)), "scholar_cap")
            _line(img, 12, 13, 12, 18 + (f % 2), C["white"], 1)  # râu bạc
            _rect(img, 4, 15, 8, 19, C["cream"])  # cuộn binh thư
        else:
            p_y = [14, 11, 12, 15][f - 4]
            img = _draw_humanoid_base(24, 30, C["blue"], C["blue_l"], C["blue_d"], bob, C["ivory"], (6, 17), (19, p_y), "scholar_cap")
            _line(img, 12, 13, 12, 18, C["white"], 1)
            _line(img, 19, p_y, 22, p_y - 3, C["gold_hi"], 2)  # quạt lông chỉ huy
            if f in (5, 6):
                _spark(img, 22, p_y - 4, C["blue_l"], C["white"], 0)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/npc_strategist.png")

    # 4. npc_scholar (24x30, 8f: 0..3 lật sử sách, 4..7 múa bút lông ánh vàng)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 6) else 0
        if f < 4:
            img = _draw_humanoid_base(24, 30, C["gold"], C["gold_l"], C["gold_d"], bob, C["ink_d"], (7, 18), (17, 18 - (f % 2)), "scholar_cap")
            _rect(img, 8, 16, 16, 20, C["ivory"])
            _line(img, 12, 16, 12, 20, C["red"], 1)
        else:
            sw = [-2, 0, 2, 1][f - 4]
            img = _draw_humanoid_base(24, 30, C["gold"], C["gold_l"], C["gold_d"], bob, C["ink_d"], (6, 18), (18 + sw, 14), "scholar_cap")
            _line(img, 18 + sw, 14, 20 + sw, 10, C["wood_l"], 1)
            _spark(img, 20 + sw, 9, C["gold_l"], C["white"], 1 if f in (5, 6) else 0)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/npc_scholar.png")

    # 5. npc_guard (24x30, 8f: 0..3 đứng gác nghiêm, 4..7 dập giáo chào & múa thương)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 5) else 0
        if f < 4:
            img = _draw_humanoid_base(24, 30, C["red"], C["red_l"], C["red_d"], bob, C["ink"], (6, 18), (17, 17 + (f % 2)), "helm")
            _line(img, 18, 5, 18, 28, C["wood_l"], 1)
            _line(img, 18, 3, 18, 7, C["steel_hi"], 2)
        else:
            ang = [0, -3, -5, -2][f - 4]
            img = _draw_humanoid_base(24, 30, C["red"], C["red_l"], C["red_d"], bob, C["ink"], (6, 17), (18, 15 + ang * 0.4), "helm")
            _line(img, 18, 28, 19 - ang, 4, C["wood_l"], 1)
            _line(img, 19 - ang, 4, 20 - ang, 2, C["steel_hi"], 2)
            if f == 6:
                _spark(img, 20 - ang, 3, C["gold_hi"], C["white"], 1)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/npc_guard.png")

    # 6. merchant (32x32, 8f: 0..3 phe phẩy quạt gấm, 4..7 vẫy tay mời chào & tung xu)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 2, 5) else 0
        if f < 4:
            img = _draw_humanoid_base(32, 32, C["red"], C["red_l"], C["red_d"], bob, C["ink_d"], (9, 20), (22, 18 + (f % 2)), "turban_red")
            _line(img, 22, 18, 26, 13 + (f % 2), C["gold_l"], 3)
            _pp(img, 25, 14, C["cream"])
        else:
            wave = [0, -3, -5, -2][f - 4]
            img = _draw_humanoid_base(32, 32, C["red"], C["red_l"], C["red_d"], bob, C["ink_d"], (9, 18), (24, 15 + wave), "turban_red")
            _spark(img, 25, 12 + wave, C["gold_l"], C["gold_hi"], 1)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/merchant.png")

    # 7. mentor_npc (32x32, 8f: 0..3 thiền định bùa xoay, 4..7 kết ấn truyền linh khí)
    fr = []
    for f in range(8):
        bob = [0, -1, -1, 0, -1, -2, -1, 0][f]
        hand_y = 18 if f < 4 else (14 if f in (5, 6) else 16)
        img = _draw_humanoid_base(32, 32, C["purp"], C["purp_l"], C["purp_d"], bob, C["ivory"], (9, hand_y), (23, hand_y), "scholar_cap")
        ang = f * math.pi / 4.0
        ox, oy = 16 + math.cos(ang) * 11, 14 + math.sin(ang) * 5
        _spark(img, ox, oy, C["purp_l"], C["white"], 1 if f >= 4 else 0)
        _spark(img, 32 - ox, 28 - oy, C["gold_l"], C["white"], 1 if f >= 4 else 0)
        if f in (5, 6):
            _disc(img, 16, 13 + bob, 3.0, C["teal_l"])
            _pp(img, 16, 13 + bob, C["white"])
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/mentor_npc.png")

    # 8. rescue_camp (32x32, 8f: trại quân y lều mái cong + y sĩ khuấy vạc thuốc & giơ bình linh dược)
    fr = []
    for f in range(8):
        bob = 1 if f in (1, 5) else 0
        img = _draw_humanoid_base(32, 32, C["leaf"], C["leaf_l"], C["leaf_d"], bob, C["ink"], (10, 20), (22, 16 if f < 4 else 12), "medic_band")
        # Cờ chữ thập xanh y sĩ & nồi thuốc bên cạnh
        _rect(img, 3, 21, 10, 27, C["steel_d"])
        _rect(img, 4, 20, 9, 22, C["jade_l"])
        if f % 2 == 0:
            _pp(img, 6, 17 - (f % 3), C["jade_l"])
            _pp(img, 8, 16, C["white"])
        if f >= 4:
            _rect(img, 21, 9, 25, 13, C["jade_l"])
            _spark(img, 23, 8, C["jade_l"], C["white"], 1)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/rescue_camp.png")

    # 9. rescue_cage (32x34, 6f: lồng sắt có tù nhân bên trong lay song sắt & vẫy cầu cứu)
    fr = []
    for f in range(6):
        img, _ = canvas(32, 34)
        shake = -1 if f in (1, 4) else (1 if f == 2 else 0)
        # Bóng nền lồng
        _rect(img, 5 + shake, 6, 26 + shake, 30, C["ink_d"])
        # NPC bên trong lồng đang vẫy tay & ngó ra
        hx = 16 + shake + (1 if f in (2, 3) else (-1 if f == 0 else 0))
        _rect(img, hx - 4, 17, hx + 4, 27, C["robe"])
        _shaded_disc(img, hx, 13, 3.8, C["skin_l"], C["skin"], C["skin"], C["skin_d"])
        _pp(img, hx - 1, 13, C["ink_d"])
        _pp(img, hx + 1, 13, C["ink_d"])
        wave_y = 14 if f in (1, 2, 4, 5) else 17
        _line(img, hx + 4, 19, hx + 7, wave_y, C["skin_l"], 2)
        # Song sắt & mái đồng lồng giam
        for bx in (6, 11, 16, 21, 26):
            _line(img, bx + shake, 6, bx + shake, 29, C["steel_hi"] if bx in (6, 26) else C["steel"], 1)
        _rect(img, 4 + shake, 4, 27 + shake, 7, C["steel_d"])
        _rect(img, 5 + shake, 4, 26 + shake, 5, C["gold_l"])
        _rect(img, 4 + shake, 28, 27 + shake, 31, C["stone_d"])
        _rect(img, 5 + shake, 28, 26 + shake, 29, C["stone_l"])
        if f in (2, 5):
            _spark(img, 16 + shake, 3, C["gold_hi"], C["white"], 0)
        fr.append(outline(img, DARK_LINE))
    save(sheet(fr), "world/rescue_cage.png")


def build():
    # 3 mounts 12f (48x38)
    save(sheet([_draw_elephant_frame(f, 48, 38) for f in range(12)]), "world/voi_chien_mount.png")
    save(sheet([_draw_horse_frame(f, 48, 38) for f in range(12)]), "world/ngua_sat_mount.png")
    save(sheet([_draw_tank_frame(f) for f in range(12)]), "world/xe_tang_mount.png")
    # Skill charge elephant & iron_horse 8f (40x34)
    save(sheet([_draw_elephant_frame(f + 4, 40, 34) for f in range(8)]), "fx/elephant.png")
    save(sheet([_draw_horse_frame(f + 4, 40, 34) for f in range(8)]), "fx/iron_horse.png")
    build_npcs()
    print("Da ve thu cuoi 12 khung va NPC 8 khung!")


if __name__ == "__main__":
    build()
