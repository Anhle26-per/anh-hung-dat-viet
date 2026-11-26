"""Đồ họa v2.0.0: 3 thú cưỡi, 6 bàn tế/sự kiện [!], 11 biểu tượng Kỹ năng 2 & 5 Tượng Thần."""
import math
from px import hexc, outline, save, canvas, DARK_LINE, Image


C = {k: hexc(v) for k, v in {
    "gold_d": "7c4612", "gold": "d48c28", "gold_l": "ffcf54", "gold_hi": "fff6b8",
    "bronze_d": "582e14", "bronze": "9e5c26", "bronze_l": "d68e42", "bronze_hi": "f6c878",
    "red_d": "681422", "red": "c82c38", "red_l": "f25c54", "red_hi": "ffa898",
    "steel_d": "3e4860", "steel": "7686a8", "steel_l": "b8cae8", "steel_hi": "f0f6ff",
    "wood_d": "462816", "wood": "7c4c2a", "wood_l": "b47846", "wood_hi": "dca46c",
    "stone_d": "2e2a3c", "stone": "544e6a", "stone_l": "847ea0", "stone_hi": "b4aec8",
    "blue_d": "143e8e", "blue": "2a7ee8", "blue_l": "5ec8ff", "blue_hi": "c8f8ff",
    "jade_d": "125240", "jade": "269e74", "jade_l": "5ae4ac", "jade_hi": "c0ffe4",
    "leaf_d": "26541c", "leaf": "4a8e32", "leaf_l": "7ed052", "leaf_hi": "b8f288",
    "purp_d": "3a1c64", "purp": "763cc4", "purp_l": "b478ff", "purp_hi": "ebd0ff",
    "ink_d": "1a1624", "ink": "322c44", "ink_l": "584e72",
    "fire_d": "9a1e18", "fire": "e84c24", "fire_l": "ff9e2c", "fire_hi": "fff088",
    "skin": "f5c7a1", "skin_d": "c89070",
    "ivory": "f6efd8", "ivory_d": "c4b898",
    "ele_d": "4a4658", "ele": "6e6a7e", "ele_l": "9692a8",
    "tank_d": "2d4220", "tank": "4c6c32", "tank_l": "70964c",
    "cream": "fff5dc", "pink": "f07ca4", "pink_hi": "ffd4e4", "white": "ffffff",
}.items()}


def _pp(img, x, y, col):
    w, h = img.size
    ix, iy = int(round(x)), int(round(y))
    if 1 <= ix < w - 1 and 1 <= iy < h - 1:
        img.putpixel((ix, iy), col)


def _rect(img, x0, y0, x1, y1, col):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            _pp(img, x, y, col)


def _disc(img, cx, cy, r, col):
    r2 = r * r
    for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
        for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                _pp(img, x, y, col)


def _ring(img, cx, cy, r_in, r_out, col):
    for y in range(int(math.floor(cy - r_out)), int(math.ceil(cy + r_out)) + 1):
        for x in range(int(math.floor(cx - r_out)), int(math.ceil(cx + r_out)) + 1):
            d = math.hypot(x - cx, y - cy)
            if r_in <= d <= r_out:
                _pp(img, x, y, col)


def _line(img, x0, y0, x1, y1, col, thick=1):
    steps = max(1, int(max(abs(x1 - x0), abs(y1 - y0)) * 2))
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        if thick <= 1:
            _pp(img, x, y, col)
        else:
            _disc(img, x, y, thick * 0.5, col)


def _spark(img, cx, cy, col, core=None, size=1):
    _pp(img, cx, cy, core or C["white"])
    for d in range(1, size + 1):
        _pp(img, cx - d, cy, col)
        _pp(img, cx + d, cy, col)
        _pp(img, cx, cy - d, col)
        _pp(img, cx, cy + d, col)


# ==================================================================== 3 Mounts (32x32)
def draw_voi_chien_mount():
    img, _ = canvas(32, 32)
    # Chân voi vững chắc
    for lx in (8, 13, 19, 23):
        _rect(img, lx, 22, lx + 2, 28, C["ele_d"] if lx > 15 else C["ele"])
        _pp(img, lx, 28, C["ivory_d"])
        _pp(img, lx + 1, 28, C["ivory"])
    # Đuôi
    _line(img, 5, 17, 3, 22, C["ele_d"])
    # Thân voi xám tròn
    _disc(img, 14, 17, 7.5, C["ele"])
    _disc(img, 13, 15, 5.2, C["ele_l"])
    # Đầu voi bên phải
    _disc(img, 23, 14, 5.0, C["ele"])
    _disc(img, 22, 12, 3.2, C["ele_l"])
    # Tai to
    _disc(img, 19, 14, 3.2, C["ele_d"])
    _disc(img, 19, 13, 2.2, C["ele"])
    # Vòi voi cong hướng phải-lên
    _line(img, 26, 15, 29, 20, C["ele"], 2)
    _line(img, 29, 20, 27, 23, C["ele_l"], 2)
    _pp(img, 26, 22, C["ele_d"])
    # Ngà voi trắng cong
    _line(img, 25, 17, 29, 16, C["ivory"], 2)
    _pp(img, 30, 15, C["white"])
    # Mắt & giáp trán đồng vàng
    _pp(img, 24, 12, C["ink_d"])
    _rect(img, 21, 9, 25, 11, C["gold_l"])
    _pp(img, 23, 10, C["red"])
    # Kiệu chiến giáp đỏ-vàng trên lưng voi
    _rect(img, 9, 9, 18, 15, C["red"])
    _rect(img, 10, 10, 17, 13, C["red_l"])
    _rect(img, 8, 8, 19, 9, C["gold_l"])
    _rect(img, 9, 14, 18, 15, C["gold"])
    _line(img, 11, 5, 11, 9, C["wood_l"])
    _rect(img, 11, 4, 15, 7, C["red_l"])
    _pp(img, 13, 5, C["gold_hi"])
    return outline(img, DARK_LINE)


def draw_ngua_sat_mount():
    img, _ = canvas(32, 32)
    # Lửa phụt dưới chân & đuôi
    _line(img, 3, 17, 7, 15, C["fire"], 2)
    _line(img, 2, 19, 6, 16, C["fire_l"])
    _pp(img, 2, 16, C["fire_hi"])
    # 4 chân sắt phi nước đại
    _line(img, 10, 20, 7, 28, C["steel_d"], 2)
    _line(img, 13, 20, 14, 28, C["steel"], 2)
    _line(img, 19, 20, 21, 28, C["steel_l"], 2)
    _line(img, 22, 19, 26, 25, C["steel_hi"], 2)
    for hx, hy in [(7, 28), (14, 28), (21, 28), (26, 25)]:
        _pp(img, hx, hy, C["fire_l"])
    # Thân ngựa thép sáng
    for y in range(13, 21):
        for x in range(8, 24):
            _pp(img, x, y, C["steel_hi"] if y < 15 else (C["steel_l"] if y < 18 else C["steel_d"]))
    # Yên ngựa đỏ viền vàng
    _rect(img, 12, 12, 19, 15, C["red"])
    _rect(img, 13, 12, 18, 13, C["gold_l"])
    # Cổ & đầu ngựa thép + bờm lửa
    _line(img, 20, 15, 24, 9, C["steel_l"], 4)
    _line(img, 24, 8, 28, 11, C["steel_hi"], 3)
    _line(img, 25, 11, 29, 13, C["steel"], 2)
    _line(img, 22, 6, 23, 9, C["steel_hi"])  # tai
    # Bờm lửa đỏ vàng
    for k in range(4):
        _line(img, 21 - k, 8 + k, 18 - k, 9 + k, C["fire_l"] if k % 2 == 0 else C["red_l"])
    _pp(img, 25, 9, C["fire_hi"])  # mắt rực lửa
    _pp(img, 29, 13, C["fire_l"])  # tia lửa mũi
    _pp(img, 30, 12, C["fire_hi"])
    return outline(img, DARK_LINE)


def draw_xe_tang_mount():
    img, _ = canvas(32, 32)
    # Xích xe tăng thép tối & bánh răng
    _rect(img, 4, 21, 26, 27, C["ink"])
    _rect(img, 5, 22, 25, 26, C["steel_d"])
    for wx in (7, 11, 15, 19, 23):
        _disc(img, wx, 24, 1.8, C["steel"])
        _pp(img, wx, 24, C["steel_hi"])
    # Thân xe tăng xanh quân đội
    _rect(img, 5, 15, 25, 21, C["tank"])
    _rect(img, 6, 15, 24, 17, C["tank_l"])
    _rect(img, 5, 20, 25, 21, C["tank_d"])
    # Ngôi sao vàng trên thân
    _spark(img, 15, 18, C["gold"], C["gold_hi"], 1)
    # Tháp pháo & nòng pháo hướng phải
    _rect(img, 9, 10, 20, 15, C["tank_l"])
    _rect(img, 10, 10, 18, 12, C["leaf_l"])
    _rect(img, 12, 8, 16, 10, C["tank"])
    _rect(img, 20, 11, 29, 13, C["steel_l"])
    _rect(img, 20, 13, 29, 13, C["steel_d"])
    _rect(img, 28, 10, 30, 14, C["steel_hi"])
    _pp(img, 30, 12, C["fire_hi"])
    return outline(img, DARK_LINE)


# ==================================================================== 6 Event Altars (32x32)
def draw_reforge_furnace():
    img, _ = canvas(32, 32)
    # Bệ đá & thân lò rèn cổ gạch đỏ
    _rect(img, 5, 25, 26, 29, C["stone_d"])
    _rect(img, 6, 24, 25, 26, C["stone_l"])
    _rect(img, 7, 10, 24, 24, C["red_d"])
    _rect(img, 8, 11, 23, 23, C["red"])
    for y in (14, 18, 22):
        _line(img, 8, y, 23, y, C["red_d"])
    # Miệng lò lửa rực
    _rect(img, 11, 15, 20, 23, C["ink_d"])
    _disc(img, 15.5, 20, 3.6, C["fire"])
    _disc(img, 15.5, 20, 2.2, C["fire_l"])
    _disc(img, 15.5, 21, 1.3, C["fire_hi"])
    # Mái vòm đồng vàng & ống khói
    _rect(img, 13, 4, 18, 9, C["stone"])
    _rect(img, 6, 8, 25, 11, C["gold"])
    _rect(img, 7, 8, 24, 9, C["gold_hi"])
    # Búa rèn vàng trên đỉnh
    _line(img, 22, 6, 26, 10, C["wood_l"], 2)
    _rect(img, 20, 4, 24, 7, C["steel_hi"])
    _spark(img, 16, 4, C["fire_l"], C["white"], 1)
    return outline(img, DARK_LINE)


def draw_decomposer():
    img, _ = canvas(32, 32)
    # Bệ đá cổ ma thuật tím-ngọc phân tách binh khí
    _rect(img, 6, 23, 25, 28, C["stone_d"])
    _rect(img, 7, 21, 24, 24, C["stone_l"])
    _rect(img, 9, 16, 22, 21, C["purp_d"])
    _rect(img, 11, 16, 20, 18, C["purp"])
    # Lõi năng lượng xoay ở giữa
    _ring(img, 16, 12, 4.5, 6.2, C["purp_l"])
    _disc(img, 16, 12, 3.2, C["jade_l"])
    _disc(img, 16, 12, 1.6, C["white"])
    # Mảnh kiếm bị tách rời bay lên hai bên
    _line(img, 7, 13, 11, 8, C["steel_hi"], 2)
    _line(img, 24, 13, 20, 8, C["gold_l"], 2)
    _spark(img, 8, 6, C["jade_hi"], C["white"], 1)
    _spark(img, 24, 6, C["purp_hi"], C["white"], 1)
    return outline(img, DARK_LINE)


def draw_statue_shrine():
    img, _ = canvas(32, 32)
    # Bệ đá & cột đỏ miếu thần Việt
    _rect(img, 5, 25, 26, 29, C["stone"])
    _rect(img, 7, 13, 9, 25, C["red"])
    _rect(img, 22, 13, 24, 25, C["red"])
    # Tượng ngọc-vàng ở giữa miếu
    _disc(img, 16, 16, 3.2, C["jade_l"])
    _rect(img, 13, 18, 19, 24, C["gold_l"])
    _rect(img, 14, 19, 18, 23, C["jade"])
    # Mái đình cong 2 tầng đỏ-vàng
    for dx in range(-12, 13):
        lift = max(0, abs(dx) - 8) // 2
        _pp(img, 16 + dx, 12 - lift, C["gold_hi"])
        _pp(img, 16 + dx, 11 - lift, C["red_l"])
        if abs(dx) <= 9:
            _pp(img, 16 + dx, 10 - lift, C["red"])
            _pp(img, 16 + dx, 9, C["gold"])
    _rect(img, 10, 7, 21, 9, C["red_l"])
    _disc(img, 16, 5, 2.0, C["gold_hi"])
    return outline(img, DARK_LINE)


def draw_mentor_npc():
    img, _ = canvas(32, 32)
    # Bóng & áo dài quân sư lam-vàng
    _rect(img, 10, 17, 21, 28, C["blue_d"])
    _rect(img, 11, 17, 20, 27, C["blue"])
    _rect(img, 14, 18, 17, 27, C["gold_l"])
    # Đầu & râu bạc hiền triết
    _disc(img, 16, 12, 4.5, C["skin"])
    _pp(img, 14, 11, C["ink_d"])
    _pp(img, 18, 11, C["ink_d"])
    _line(img, 14, 15, 16, 19, C["white"], 2)
    _line(img, 18, 15, 16, 19, C["steel_hi"], 1)
    # Mũ cánh chuồn quân sư
    _rect(img, 11, 6, 20, 9, C["ink"])
    _rect(img, 13, 4, 18, 7, C["gold_l"])
    _line(img, 6, 8, 11, 8, C["gold"])
    _line(img, 20, 8, 25, 8, C["gold"])
    # Cuộn thư trúc trên tay
    _rect(img, 21, 17, 25, 22, C["cream"])
    _rect(img, 21, 17, 25, 18, C["gold"])
    _rect(img, 21, 21, 25, 22, C["gold"])
    return outline(img, DARK_LINE)


def draw_rescue_camp():
    img, _ = canvas(32, 32)
    # Lều quân y xanh lá - kem với cờ thập đỏ vàng
    for dy in range(16):
        hw = 2 + int(dy * 0.72)
        for dx in range(-hw, hw + 1):
            y = 11 + dy
            col = C["leaf_hi"] if dx < -hw + 3 else (C["leaf"] if abs(dx) > 4 else C["cream"])
            _pp(img, 16 + dx, y, col)
    # Cửa lều tối & rương thuốc
    _rect(img, 13, 19, 18, 26, C["ink"])
    _rect(img, 13, 14, 18, 15, C["red_l"])
    # Biểu tượng chữ thập đỏ hồi máu
    _rect(img, 15, 12, 16, 17, C["red"])
    _rect(img, 13, 14, 18, 15, C["red"])
    # Cờ quân y trên đỉnh
    _line(img, 16, 4, 16, 11, C["wood_l"])
    _rect(img, 16, 4, 22, 8, C["red_l"])
    _pp(img, 19, 6, C["white"])
    _spark(img, 7, 14, C["leaf_hi"], C["white"], 1)
    return outline(img, DARK_LINE)


def draw_challenge_arena():
    img, _ = canvas(32, 32)
    # Đài thách đấu đá đen viền đỏ rực lửa
    _rect(img, 5, 23, 26, 28, C["ink_d"])
    _rect(img, 6, 21, 25, 24, C["stone"])
    _rect(img, 7, 20, 24, 21, C["red"])
    # Hai thanh kích chéo sau đài
    _line(img, 7, 20, 24, 6, C["steel_hi"], 2)
    _line(img, 24, 20, 7, 6, C["steel_l"], 2)
    _pp(img, 24, 6, C["white"])
    _pp(img, 7, 6, C["white"])
    # Vạc lửa thách đấu ở tâm
    _disc(img, 16, 16, 4.2, C["gold_d"])
    _disc(img, 16, 14, 3.6, C["fire"])
    _disc(img, 16, 13, 2.2, C["fire_l"])
    _pp(img, 16, 11, C["white"])
    _spark(img, 16, 7, C["red_l"], C["fire_hi"], 1)
    return outline(img, DARK_LINE)


# ==================================================================== 11 Skill 2 Icons (22x22)
def _skill_blank():
    return Image.new("RGBA", (22, 22), (0, 0, 0, 0))


def _skill_co_lenh_me_linh():
    img = _skill_blank()
    _line(img, 5, 3, 5, 19, C["gold_l"], 2)
    _rect(img, 6, 4, 17, 13, C["red"])
    _rect(img, 7, 5, 15, 11, C["red_l"])
    _disc(img, 11, 8, 2.2, C["gold_hi"])
    return outline(img, DARK_LINE)


def _skill_chieng_nui_nua():
    img = _skill_blank()
    _ring(img, 11, 11, 6.2, 7.8, C["gold_l"])
    _disc(img, 11, 11, 5.2, C["bronze"])
    _disc(img, 11, 11, 2.5, C["gold_hi"])
    _spark(img, 17, 5, C["fire_hi"], C["white"], 1)
    return outline(img, DARK_LINE)


def _skill_thuy_trieu_dang():
    img = _skill_blank()
    for row_y, col in [(7, C["blue_hi"]), (11, C["blue_l"]), (15, C["blue"])]:
        for x in range(3, 19):
            y = row_y + int(round(math.sin(x * 0.65) * 1.5))
            _pp(img, x, y, col)
            _pp(img, x, y + 1, col)
    return outline(img, DARK_LINE)


def _skill_tuong_nhu_nguyet():
    img = _skill_blank()
    for bx in (5, 10, 15):
        _rect(img, bx, 6, bx + 2, 18, C["leaf"])
        _rect(img, bx, 6, bx + 1, 9, C["leaf_hi"])
    _rect(img, 4, 10, 18, 12, C["gold_l"])
    _rect(img, 4, 15, 18, 16, C["wood_l"])
    return outline(img, DARK_LINE)


def _skill_hoa_cong_bach_dang():
    img = _skill_blank()
    _rect(img, 4, 13, 17, 17, C["wood_l"])
    _rect(img, 6, 15, 15, 17, C["wood_d"])
    _disc(img, 11, 10, 3.6, C["fire"])
    _disc(img, 11, 9, 2.2, C["fire_l"])
    _pp(img, 11, 7, C["white"])
    return outline(img, DARK_LINE)


def _skill_kim_quy_ho_gia():
    img = _skill_blank()
    _disc(img, 11, 12, 6.4, C["gold_d"])
    _disc(img, 11, 11, 5.2, C["gold_l"])
    _ring(img, 11, 11, 2.2, 3.2, C["gold_hi"])
    _pp(img, 11, 11, C["jade_hi"])
    _pp(img, 11, 4, C["gold_hi"])
    return outline(img, DARK_LINE)


def _skill_hoa_ho_dai_phao():
    img = _skill_blank()
    _line(img, 4, 15, 13, 9, C["bronze_l"], 4)
    _disc(img, 15, 8, 3.0, C["fire"])
    _disc(img, 16, 7, 1.8, C["fire_hi"])
    _disc(img, 7, 16, 2.2, C["wood_d"])
    return outline(img, DARK_LINE)


def _skill_nhat_tao_xung_kich():
    img = _skill_blank()
    _line(img, 3, 14, 17, 8, C["fire"], 3)
    _line(img, 6, 13, 18, 8, C["fire_hi"], 1)
    _pp(img, 18, 8, C["white"])
    _spark(img, 7, 15, C["red_l"], C["fire_hi"], 1)
    return outline(img, DARK_LINE)


def _skill_phuc_kich_yen_the():
    img = _skill_blank()
    _disc(img, 11, 11, 6.0, C["leaf_d"])
    _disc(img, 11, 11, 4.0, C["leaf"])
    _pp(img, 9, 10, C["gold_hi"])
    _pp(img, 13, 10, C["gold_hi"])
    _line(img, 7, 15, 15, 15, C["steel_hi"])
    return outline(img, DARK_LINE)


def _skill_boc_pha_nghin_can():
    img = _skill_blank()
    _rect(img, 6, 8, 15, 17, C["red_d"])
    _rect(img, 7, 9, 14, 16, C["red"])
    _rect(img, 6, 11, 15, 13, C["gold_l"])
    _line(img, 11, 8, 14, 4, C["cream"])
    _spark(img, 15, 4, C["fire"], C["white"], 1)
    return outline(img, DARK_LINE)


def _skill_nho_tre_danh_giac():
    img = _skill_blank()
    _line(img, 5, 17, 16, 5, C["leaf_l"], 2)
    _line(img, 4, 16, 15, 4, C["leaf_hi"], 1)
    _ring(img, 11, 11, 6.0, 7.2, C["jade_hi"])
    _spark(img, 16, 6, C["gold_l"], C["white"], 1)
    return outline(img, DARK_LINE)


# ==================================================================== 5 Statues (24x24)
def _statue_draw(base_d, base_m, base_l, aura):
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    _rect(img, 6, 18, 17, 21, C["stone_d"])
    _rect(img, 7, 17, 16, 19, C["stone_l"])
    _rect(img, 8, 10, 15, 17, base_d)
    _rect(img, 9, 10, 14, 16, base_m)
    _disc(img, 12, 7, 3.2, base_m)
    _disc(img, 11, 6, 1.8, base_l)
    _spark(img, 12, 3, aura, C["white"], 1)
    return outline(img, DARK_LINE)


def build():
    mounts = {
        "voi_chien_mount": draw_voi_chien_mount,
        "ngua_sat_mount": draw_ngua_sat_mount,
        "xe_tang_mount": draw_xe_tang_mount,
    }
    for k, fn in mounts.items():
        save(fn(), f"world/{k}.png")

    altars = {
        "reforge_furnace": draw_reforge_furnace,
        "decomposer": draw_decomposer,
        "statue_shrine": draw_statue_shrine,
        "mentor_npc": draw_mentor_npc,
        "rescue_camp": draw_rescue_camp,
        "challenge_arena": draw_challenge_arena,
    }
    for k, fn in altars.items():
        save(fn(), f"world/{k}.png")

    skill2s = {
        "co_lenh_me_linh": _skill_co_lenh_me_linh,
        "chieng_nui_nua": _skill_chieng_nui_nua,
        "thuy_trieu_dang": _skill_thuy_trieu_dang,
        "tuong_nhu_nguyet": _skill_tuong_nhu_nguyet,
        "hoa_cong_bach_dang": _skill_hoa_cong_bach_dang,
        "kim_quy_ho_gia": _skill_kim_quy_ho_gia,
        "hoa_ho_dai_phao": _skill_hoa_ho_dai_phao,
        "nhat_tao_xung_kich": _skill_nhat_tao_xung_kich,
        "phuc_kich_yen_the": _skill_phuc_kich_yen_the,
        "boc_pha_nghin_can": _skill_boc_pha_nghin_can,
        "nho_tre_danh_giac": _skill_nho_tre_danh_giac,
    }
    for k, fn in skill2s.items():
        save(fn(), f"ui/skill_{k}.png")

    statues = {
        "lac_long": (C["blue_d"], C["blue"], C["blue_hi"], C["blue_l"]),
        "au_co": (C["red_d"], C["pink"], C["pink_hi"], C["pink_hi"]),
        "son_tinh": (C["bronze_d"], C["bronze"], C["bronze_hi"], C["gold_l"]),
        "chu_dong_tu": (C["gold_d"], C["gold"], C["gold_hi"], C["gold_hi"]),
        "phu_dong": (C["fire_d"], C["fire"], C["fire_hi"], C["fire_l"]),
    }
    for k, cols in statues.items():
        save(_statue_draw(*cols), f"ui/statue_{k}.png")


if __name__ == "__main__":
    build()
