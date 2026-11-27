"""Đồ họa Mega Expansion v3.0.0 — Giang Sơn Gấm Vóc:
- 3 Trùm thần thoại mới (6 bảng 48 khung lưới 12x4):
  * enemies/boss_thuy_tinh.png & _2.png (84x64 x 48f)
  * enemies/boss_thien_loi.png & _2.png (84x64 x 48f)
  * enemies/boss_hon_mang_yeu_de.png & _2.png (96x72 x 48f)
- 4 Thần thú thức tỉnh:
  * world/animal_dog_evo.png (4f 28x24)
  * world/animal_cat_evo.png (3f 26x22)
  * world/animal_rooster_evo.png (3f 26x26)
  * world/animal_crane_evo.png (4f 28x36)
- Công trình Cổ Loa & Doanh Trại / Vườn Thảo Dược:
  * world/coloa_core.png (48x48)
  * world/tower_luy_tre.png (32x32), tower_no_than.png (32x32), tower_bai_coc.png (32x28)
  * world/tower_phao_dai.png (34x34), tower_lo_ren.png (34x34)
  * world/rescue_cage.png (32x34)
  * world/lobby_skill_tree.png (44x46), lobby_pet_shrine.png (44x44), lobby_sparring_banner.png (34x42)
  * world/garden_linh_chi.png (24x24), garden_uu_dam.png (24x24)
"""
import math
from PIL import Image, ImageDraw
from px import save, polish, shade, outline, auto_shade, hexc, hue_ramp, sheet, sheet_grid, canvas

C = hexc


def _ell(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)


def _with_shadow(outlined_img, sx0, sy0, sx1, sy1, alpha=90):
    w, h = outlined_img.size
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(base)
    sd.ellipse([sx0, sy0, sx1, sy1], fill=(16, 10, 22, alpha))
    base.alpha_composite(outlined_img)
    return base


def _boss_pose(f):
    """Tính thông số chuyển động chuẩn 48 khung (lưới 12x4) cho trùm hình người thần thoại."""
    is_idle = f < 6
    is_walk = 6 <= f < 14
    is_wind = 14 <= f < 20
    is_atk = 20 <= f < 26
    is_rng = 26 <= f < 32
    is_cast = 32 <= f < 36
    is_dash = 36 <= f < 40
    is_leap = 40 <= f < 44
    is_rage = f in (44, 45)
    is_spec = f >= 46

    t = (((f - 6) if is_walk else f) / 8.0) * math.tau
    bob = 0
    sway = 0
    lunge = 0
    leg_l = 0
    leg_r = 0
    arm_ang = 0.0

    if is_idle:
        bob = [0, -1, -2, -2, -1, 0][f]
        sway = [0, 1, 1, 0, -1, 0][f]
        arm_ang = math.sin(f * 1.05) * 0.12
    elif is_walk:
        bob = round(-1.5 + math.cos(t * 2) * 1.5)
        sway = round(math.sin(t) * 2)
        leg_l = round(math.sin(t) * 5)
        leg_r = round(-math.sin(t) * 5)
        arm_ang = math.sin(t) * 0.32
    elif is_wind:
        k = f - 14
        bob = [0, 1, 1, 2, 2, 1][k]
        lunge = -(k // 2 + 2)
        arm_ang = -0.75 - k * 0.14
    elif is_atk:
        k = f - 20
        prog = [2, 5, 7, 6, 3, 1][k]
        lunge = prog
        bob = -1 if k in (1, 2) else 1
        arm_ang = [-0.6, 0.35, 1.15, 1.35, 0.8, 0.25][k]
    elif is_rng:
        k = f - 26
        lunge = [1, 3, 4, 2, 0, -1][k]
        bob = [0, -1, -1, 1, 0, 0][k]
        arm_ang = [0.1, 0.45, 0.6, 0.35, 0.1, 0.0][k]
    elif is_cast:
        k = f - 32
        bob = [-1, -2, -3, -1][k]
        sway = [-1, 1, -1, 1][k]
        arm_ang = -1.35 - 0.15 * (k % 2)
    elif is_dash:
        k = f - 36
        lunge = [6, 8, 8, 5][k]
        bob = 2 if k in (0, 1) else 1
        arm_ang = 0.85
    elif is_leap:
        k = f - 40
        if k == 0:
            bob, lunge, arm_ang = 3, -1, -0.5
        elif k in (1, 2):
            bob = -6 if k == 1 else -8
            lunge = 3 if k == 1 else 4
            arm_ang = -1.25
        else:
            bob, lunge, arm_ang = 3, 2, 1.2
    elif is_rage:
        bob = -2 if f == 44 else -1
        arm_ang = -1.1 if f == 44 else -0.8
    else:
        bob = -2 if f == 46 else -1
        sway = 2 if f == 46 else -2
        arm_ang = -1.3

    return {
        "is_idle": is_idle, "is_walk": is_walk, "is_wind": is_wind,
        "is_atk": is_atk, "is_rng": is_rng, "is_cast": is_cast,
        "is_dash": is_dash, "is_leap": is_leap, "is_rage": is_rage,
        "is_spec": is_spec, "t": t, "bob": bob, "sway": sway,
        "lunge": lunge, "leg_l": leg_l, "leg_r": leg_r, "arm_ang": arm_ang,
    }


# ------------------------------------------------------------------ 1. Thủy Tinh (84x64 x 48f)
def thuy_tinh_frame(f, phase):
    W, H = 84, 64
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    p = _boss_pose(f)

    if phase == 1:
        _, robe_d, robe, robe_l, _ = hue_ramp("1c6c94")
        _, armor_d, armor, armor_l, armor_s = hue_ramp("32a8b8")
        _, skin_d, skin, skin_l, _ = hue_ramp("6ed4c8")
        trim_d, _, trim, trim_l, trim_s = hue_ramp("eab444")
        aura = C("48e4ff")
        aura_s = C("e2ffff")
        eye = C("fff078")
    else:
        _, robe_d, robe, robe_l, _ = hue_ramp("242668")
        _, armor_d, armor, armor_l, armor_s = hue_ramp("4e349c")
        _, skin_d, skin, skin_l, _ = hue_ramp("4494b8")
        trim_d, _, trim, trim_l, trim_s = hue_ramp("ff4664")
        aura = C("38f0ff")
        aura_s = C("ffffff")
        eye = C("ff3858")

    cx = 40 + p["lunge"] + p["sway"] // 2
    cy = 34 + p["bob"]

    # Vòng sóng nước dưới chân (càng dữ dội ở pha 2 / special / cast)
    wave_w = 28 if not (p["is_spec"] or p["is_rage"]) else 34
    _ell(d, cx, 57, wave_w, 5, C("1a5a8c", 160) if phase == 1 else C("28206c", 180))
    d.arc([cx - wave_w + 2, 52, cx + wave_w - 2, 60], 0, 180, fill=aura, width=2)
    for k in range(4):
        wx = cx - 22 + k * 14 + ((f * 3) % 7) - 3
        d.arc([wx - 4, 51 - (f + k) % 2, wx + 4, 57], 180, 360, fill=aura_s, width=1)

    if p["is_cast"]:
        d.arc([12, 48, 72, 62], 0, 360, fill=aura_s if f % 2 == 0 else trim_s, width=2)

    # Áo choàng sóng phía sau tung bay
    cape_dx = -6 - p["lunge"] // 2 + p["sway"]
    d.polygon([
        (cx - 10, cy - 12),
        (cx + 10, cy - 12),
        (cx + 16 + cape_dx // 2, cy + 16),
        (cx - 18 + cape_dx, cy + 18),
    ], fill=robe_d)
    d.polygon([
        (cx - 8, cy - 10),
        (cx + 8, cy - 10),
        (cx + 12 + cape_dx // 2, cy + 14),
        (cx - 13 + cape_dx, cy + 15),
    ], fill=robe)

    # Chân / sóng quấn
    for sgn, lx_off in ((-1, p["leg_l"]), (1, p["leg_r"])):
        fx = cx + sgn * 7 + lx_off // 2
        fy = 53 - (3 if p["is_leap"] and f in (41, 42) else 0)
        d.line([(cx + sgn * 5, cy + 8), (fx, fy)], fill=robe_d, width=5)
        _ell(d, fx, fy, 4, 2, armor_d)

    # Giáp vảy giao long & đai vàng/đỏ san hô
    _ell(d, cx, cy + 1, 13, 14, robe)
    _ell(d, cx, cy - 1, 11, 10, armor)
    d.line([(cx - 10, cy + 6), (cx + 10, cy + 6)], fill=trim, width=3)
    _ell(d, cx, cy + 6, 3, 3, aura_s)
    # Vây vai vảy rồng
    for sgn in (-1, 1):
        d.polygon([
            (cx + sgn * 9, cy - 9),
            (cx + sgn * 20, cy - 14 - (3 if phase == 2 else 0)),
            (cx + sgn * 16, cy - 3),
        ], fill=armor_l if phase == 1 else trim)
        d.line([(cx + sgn * 10, cy - 9), (cx + sgn * 19, cy - 13)], fill=trim_l)

    # Tay trái phụ (lượng nước)
    d.line([(cx - 9, cy - 5), (cx - 17, cy + 2 + p["bob"])], fill=skin, width=4)
    _ell(d, cx - 18, cy + 3 + p["bob"], 3, 3, aura)

    # Đầu Thủy Tinh + vương miện san hô / sừng giao long
    hx = cx + (2 if p["is_dash"] or p["is_atk"] else 0)
    hy = cy - 16
    _ell(d, hx, hy, 9, 8, skin)
    # Tóc thủy tảo / bờm sóng sau đầu
    d.polygon([(hx - 8, hy - 4), (hx - 16, hy + 2), (hx - 9, hy + 6)], fill=armor_d)
    # Vương miện 3 chĩa / sừng rồng biển
    d.polygon([(hx - 7, hy - 6), (hx - 11, hy - 15 - (3 if phase == 2 else 0)), (hx - 3, hy - 8)], fill=trim)
    d.polygon([(hx + 7, hy - 6), (hx + 11, hy - 15 - (3 if phase == 2 else 0)), (hx + 3, hy - 8)], fill=trim)
    d.polygon([(hx - 3, hy - 7), (hx, hy - 16), (hx + 3, hy - 7)], fill=trim_l)
    _ell(d, hx, hy - 9, 2, 2, aura_s)
    # Mắt rực sáng
    eye_draw = C("ffffff") if (p["is_wind"] and f == 19) else (C("ff2c3c") if p["is_rage"] else eye)
    d.rectangle([hx - 5, hy - 1, hx - 2, hy + 1], fill=eye_draw)
    d.rectangle([hx + 2, hy - 1, hx + 5, hy + 1], fill=eye_draw)
    if phase == 2 or p["is_rage"]:
        d.line([(hx - 6, hy - 3), (hx - 2, hy - 2)], fill=skin_d, width=2)
        d.line([(hx + 6, hy - 3), (hx + 2, hy - 2)], fill=skin_d, width=2)

    # Đinh ba Thủy Thần (tay phải xoay theo arm_ang)
    ax, ay = cx + 11, cy - 4
    ang = p["arm_ang"]
    hx_hand = ax + round(math.cos(ang) * 9)
    hy_hand = ay + round(math.sin(ang) * 7)
    d.line([(ax, ay), (hx_hand, hy_hand)], fill=skin, width=4)
    # Trục đinh ba dài hướng về phía trước-trên
    staff_ang = ang - 0.55
    sx0 = hx_hand - round(math.cos(staff_ang) * 14)
    sy0 = hy_hand - round(math.sin(staff_ang) * 14)
    sx1 = hx_hand + round(math.cos(staff_ang) * 22)
    sy1 = hy_hand + round(math.sin(staff_ang) * 22)
    sx0, sy0 = max(3, min(W - 4, sx0)), max(3, min(H - 4, sy0))
    sx1, sy1 = max(4, min(W - 5, sx1)), max(4, min(H - 5, sy1))
    d.line([(sx0, sy0), (sx1, sy1)], fill=trim_d, width=2)
    # 3 mũi nhọn đinh ba sáng rực
    nx = math.cos(staff_ang)
    ny = math.sin(staff_ang)
    px_n, py_n = -ny, nx
    tip_x = max(2, min(W - 3, round(sx1 + nx * 6)))
    tip_y = max(2, min(H - 3, round(sy1 + ny * 6)))
    d.line([(sx1, sy1), (tip_x, tip_y)], fill=aura_s, width=2)
    for side in (-1, 1):
        bx = max(2, min(W - 3, round(sx1 + px_n * 4 * side)))
        by = max(2, min(H - 3, round(sy1 + py_n * 4 * side)))
        tx = max(2, min(W - 3, round(bx + nx * 5)))
        ty = max(2, min(H - 3, round(by + ny * 5)))
        d.line([(sx1, sy1), (bx, by), (tx, ty)], fill=trim_s, width=2)

    # Hiệu ứng từng pha hành động
    if p["is_atk"] and f in (21, 22, 23, 24):
        d.arc([44, 10, 81, 52], -70, 65, fill=aura_s, width=3)
        d.arc([48, 14, 79, 48], -60, 55, fill=aura, width=2)
    elif p["is_rng"] and f in (27, 28, 29):
        ox = min(79, 64 + (f - 27) * 5)
        _ell(d, ox, cy - 2, 5, 4, aura)
        _ell(d, ox, cy - 2, 2, 2, aura_s)
    elif p["is_dash"]:
        for sy in (22, 34, 46):
            d.line([(3 + (f % 2) * 3, sy), (16 + (f % 2) * 3, sy)], fill=aura_s, width=1)
    elif f == 43:
        d.arc([8, 46, 76, 61], 180, 360, fill=aura_s, width=3)
    elif p["is_rage"]:
        d.arc([8, 46, 76, 62], 0, 360, fill=C("ff3848") if f == 44 else aura_s, width=2)
    elif p["is_spec"]:
        k = f - 46
        for sx_w in (10, 22, 62, 74):
            wh = 20 + ((k + sx_w) % 2) * 6
            d.polygon([(sx_w - 4, 60), (sx_w, 60 - wh), (sx_w + 4, 60)], fill=aura)
            d.line([(sx_w, 59), (sx_w, 60 - wh + 2)], fill=aura_s, width=1)
    if phase == 2 or p["is_spec"]:
        for k_o in range(4):
            ang_o = k_o * 1.57 + f * 0.6
            ox = max(3, min(W - 4, cx + math.cos(ang_o) * 27))
            oy = max(3, min(H - 4, cy + math.sin(ang_o) * 18))
            _ell(d, ox, oy, 2.2, 2.2, aura_s if k_o % 2 == 0 else trim_s)

    return polish(img, texture=False)


# ------------------------------------------------------------------ 2. Thiên Lôi (84x64 x 48f)
def thien_loi_frame(f, phase):
    W, H = 84, 64
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    p = _boss_pose(f)

    if phase == 1:
        _, armor_d, armor, armor_l, _ = hue_ramp("9e6426")
        _, cloth_d, cloth, cloth_l, _ = hue_ramp("32385c")
        _, skin_d, skin, skin_l, _ = hue_ramp("d89a6c")
        bolt = C("ffe048")
        bolt_s = C("ffffff")
        drum = C("c43832")
    else:
        _, armor_d, armor, armor_l, _ = hue_ramp("562888")
        _, cloth_d, cloth, cloth_l, _ = hue_ramp("1c183c")
        _, skin_d, skin, skin_l, _ = hue_ramp("7464b8")
        bolt = C("58f2ff")
        bolt_s = C("ffffff")
        drum = C("ff3858")

    cx = 40 + p["lunge"] + p["sway"] // 2
    cy = 34 + p["bob"]

    # Đám mây sấm dưới chân
    _ell(d, cx, 55, 24, 6, cloth_d)
    for mx in (-14, -5, 5, 14):
        _ell(d, cx + mx, 54 + (mx % 2), 7, 4, cloth)
    if p["is_cast"]:
        d.arc([12, 46, 72, 62], 0, 360, fill=bolt if f % 2 == 0 else bolt_s, width=2)

    # Vòng trống sấm Thiên Lôi sau lưng (3 trống pha 1, 5 trống pha 2)
    n_drums = 3 if phase == 1 else 5
    for i in range(n_drums):
        da = math.radians(-155 + i * (130 / max(1, n_drums - 1))) + math.radians(p["sway"] * 2)
        dx = cx + round(math.cos(da) * 22)
        dy = cy - 4 + round(math.sin(da) * 18)
        _ell(d, dx, dy, 4, 4, drum)
        d.ellipse([dx - 3, dy - 3, dx + 3, dy + 3], outline=bolt)
        d.point([dx, dy], fill=bolt_s)

    # Chân đứng trên mây
    for sgn, lx_off in ((-1, p["leg_l"]), (1, p["leg_r"])):
        fx = cx + sgn * 8 + lx_off // 2
        fy = 53 - (4 if p["is_leap"] and f in (41, 42) else 0)
        d.line([(cx + sgn * 5, cy + 8), (fx, fy)], fill=cloth_d, width=5)
        d.rectangle([fx - 3, fy - 2, fx + 3, fy + 2], fill=armor_d)

    # Thân vạm vỡ giáp đồng / lôi thần
    _ell(d, cx, cy + 1, 14, 13, armor)
    d.polygon([(cx - 11, cy - 8), (cx + 11, cy - 8), (cx + 8, cy + 10), (cx - 8, cy + 10)], fill=armor_l)
    d.line([(cx - 10, cy + 4), (cx + 10, cy + 4)], fill=drum, width=3)
    _ell(d, cx, cy + 4, 3, 3, bolt_s)
    # Giáp vai có gai sét
    for sgn in (-1, 1):
        d.polygon([
            (cx + sgn * 10, cy - 9),
            (cx + sgn * 21, cy - 13),
            (cx + sgn * 15, cy - 2),
        ], fill=armor_l)
        d.line([(cx + sgn * 14, cy - 10), (cx + sgn * 20, cy - 15)], fill=bolt, width=2)

    # Tay trái cầm đục sấm
    d.line([(cx - 10, cy - 5), (cx - 19, cy + 1 + p["bob"])], fill=skin, width=4)
    d.line([(cx - 19, cy + 1 + p["bob"]), (cx - 24, cy - 6 + p["bob"])], fill=bolt_s, width=2)

    # Đầu uy nghiêm, mỏ nhọn chim lôi/mặt thần sấm & mắt chớp
    hx = cx + (2 if p["is_dash"] or p["is_atk"] else 0)
    hy = cy - 16
    _ell(d, hx, hy, 9, 8, skin)
    # Mũ chiến giáp cánh sét hai bên
    d.polygon([(hx - 7, hy - 5), (hx - 14, hy - 14), (hx - 3, hy - 8)], fill=bolt)
    d.polygon([(hx + 7, hy - 5), (hx + 14, hy - 14), (hx + 3, hy - 8)], fill=bolt)
    d.rectangle([hx - 7, hy - 9, hx + 7, hy - 5], fill=armor_d)
    eye_c = bolt_s if (p["is_wind"] and f == 19) else (C("ff2c3c") if p["is_rage"] else bolt)
    d.rectangle([hx - 5, hy - 2, hx - 2, hy], fill=eye_c)
    d.rectangle([hx + 2, hy - 2, hx + 5, hy], fill=eye_c)
    # Mỏ / râu đỏ dữ dội
    d.polygon([(hx - 2, hy + 2), (hx + 2, hy + 2), (hx, hy + 6)], fill=armor_l)

    # Búa Thiên Lôi cỡ lớn tay phải
    ax, ay = cx + 11, cy - 4
    ang = p["arm_ang"]
    hx_hand = ax + round(math.cos(ang) * 9)
    hy_hand = ay + round(math.sin(ang) * 7)
    d.line([(ax, ay), (hx_hand, hy_hand)], fill=skin, width=4)
    h_ang = ang - 0.35
    bx = max(6, min(W - 8, hx_hand + round(math.cos(h_ang) * 14)))
    by = max(6, min(H - 8, hy_hand + round(math.sin(h_ang) * 14)))
    d.line([(hx_hand, hy_hand), (bx, by)], fill=armor_d, width=3)
    _ell(d, bx, by, 7, 5, armor_l)
    d.ellipse([bx - 6, by - 4, bx + 6, by + 4], outline=bolt)
    d.point([bx, by], fill=bolt_s)

    # Tia sét hành động
    if p["is_atk"] and f in (21, 22, 23, 24):
        d.arc([44, 10, 81, 54], -75, 65, fill=bolt_s, width=3)
        d.line([(62, 16), (72, 26), (65, 34), (77, 46)], fill=bolt, width=2)
    elif p["is_rng"] and f in (27, 28, 29):
        ox = min(78, 63 + (f - 27) * 5)
        d.line([(56, cy - 4), (ox - 4, cy - 8), (ox, cy - 2)], fill=bolt_s, width=2)
        _ell(d, ox, cy - 2, 3, 3, bolt)
    elif p["is_dash"]:
        for sy in (20, 32, 44):
            d.line([(4 + (f % 2) * 3, sy), (18, sy)], fill=bolt_s, width=2)
    elif f == 43:
        d.arc([10, 45, 74, 61], 180, 360, fill=bolt_s, width=3)
    elif p["is_rage"]:
        d.arc([8, 46, 76, 62], 0, 360, fill=C("ff3848") if f == 44 else bolt_s, width=2)
    elif p["is_spec"]:
        for lx_s in (16, 68):
            mid = lx_s + (3 if f == 46 else -3)
            d.line([(lx_s, 4), (mid, 24), (lx_s - 3, 38), (lx_s + 2, 58)], fill=bolt, width=2)
            d.line([(lx_s, 4), (mid, 24), (lx_s - 3, 38)], fill=bolt_s, width=1)
    if phase == 2 or p["is_rage"] or p["is_wind"]:
        for k_b in range(3):
            ba = k_b * 2.1 + f * 0.75
            bx_s = max(4, min(W - 5, cx + round(math.cos(ba) * 26)))
            by_s = max(4, min(H - 5, cy + round(math.sin(ba) * 18)))
            d.line([(bx_s, by_s), (bx_s + 3, by_s - 4)], fill=bolt_s, width=1)

    return polish(img, texture=False)


# ------------------------------------------------------------------ 3. Hỗn Mang Yêu Đế (96x72 x 48f)
def hon_mang_frame(f, phase):
    W, H = 96, 72
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    p = _boss_pose(f)

    if phase == 1:
        _, robe_d, robe, robe_l, _ = hue_ramp("2a1a3e")
        _, armor_d, armor, armor_l, _ = hue_ramp("562248")
        _, skin_d, skin, skin_l, _ = hue_ramp("6a4c7a")
        gold_d, _, gold, gold_l, gold_s = hue_ramp("e0a438")
        void = C("d844ff")
        void_s = C("ffe4ff")
        eye = C("ff4058")
    else:
        _, robe_d, robe, robe_l, _ = hue_ramp("1c0e28")
        _, armor_d, armor, armor_l, _ = hue_ramp("78142e")
        _, skin_d, skin, skin_l, _ = hue_ramp("461e44")
        gold_d, _, gold, gold_l, gold_s = hue_ramp("ff5830")
        void = C("ff3878")
        void_s = C("fff0a8")
        eye = C("ffe848")

    cx = 46 + p["lunge"] + p["sway"] // 2
    cy = 38 + p["bob"]

    # Đĩa hỗn mang / hào quang ma đế sau lưng
    halo_r = 25 if phase == 1 else 30
    if phase == 2 or p["is_spec"] or p["is_rage"]:
        d.arc([cx - halo_r, cy - halo_r - 2, cx + halo_r, cy + halo_r - 2], 0, 360, fill=void, width=2)
        for k_r in range(6):
            ra = k_r * (math.tau / 6) + f * 0.45
            rx = max(4, min(W - 5, cx + round(math.cos(ra) * (halo_r + 3))))
            ry = max(4, min(H - 5, cy - 2 + round(math.sin(ra) * (halo_r + 3))))
            _ell(d, rx, ry, 2.5, 2.5, void_s if k_r % 2 == 0 else gold_s)

    # Cánh dơi / cánh hắc ám khổng lồ ở pha 2
    if phase == 2:
        flap = round(math.sin(f * 0.7) * 3)
        for sgn in (-1, 1):
            d.polygon([
                (cx + sgn * 8, cy - 8),
                (cx + sgn * 36, cy - 24 + flap),
                (cx + sgn * 32, cy + 2 + flap),
                (cx + sgn * 20, cy + 8),
            ], fill=robe_d)
            d.line([(cx + sgn * 8, cy - 8), (cx + sgn * 36, cy - 24 + flap)], fill=gold, width=2)

    # Vòng khói hỗn mang dưới chân
    _ell(d, cx, 64, 28, 6, C("1a0a24", 180))
    d.arc([cx - 26, 58, cx + 26, 68], 0, 360, fill=void if p["is_cast"] else armor, width=2)

    # Áo choàng đế vương rách tà
    cape_dx = -6 - p["lunge"] // 2 + p["sway"]
    d.polygon([
        (cx - 13, cy - 14),
        (cx + 13, cy - 14),
        (cx + 20 + cape_dx // 2, cy + 20),
        (cx - 22 + cape_dx, cy + 22),
    ], fill=robe)
    for tx in range(-16, 18, 8):
        d.polygon([(cx + tx, cy + 16), (cx + tx + 4, cy + 25), (cx + tx + 8, cy + 16)], fill=robe_d)

    # Chân giáp nặng
    for sgn, lx_off in ((-1, p["leg_l"]), (1, p["leg_r"])):
        fx = cx + sgn * 8 + lx_off // 2
        fy = 61 - (4 if p["is_leap"] and f in (41, 42) else 0)
        d.line([(cx + sgn * 6, cy + 10), (fx, fy)], fill=robe_d, width=6)
        _ell(d, fx, fy, 4, 3, gold_d)

    # Giáp ngực Yêu Đế chạm ấn hỗn mang
    _ell(d, cx, cy, 16, 15, armor)
    d.polygon([(cx - 12, cy - 10), (cx + 12, cy - 10), (cx + 9, cy + 11), (cx - 9, cy + 11)], fill=armor_l)
    d.line([(cx - 12, cy + 5), (cx + 12, cy + 5)], fill=gold, width=3)
    _ell(d, cx, cy - 2, 4, 4, void)
    _ell(d, cx, cy - 2, 2, 2, void_s)

    # Giáp vai sừng quỷ
    for sgn in (-1, 1):
        d.polygon([
            (cx + sgn * 12, cy - 10),
            (cx + sgn * 24, cy - 18),
            (cx + sgn * 18, cy - 1),
        ], fill=gold_d)
        d.line([(cx + sgn * 13, cy - 10), (cx + sgn * 24, cy - 18)], fill=gold_l, width=2)

    # Tay trái nâng cầu hỗn mang
    d.line([(cx - 12, cy - 6), (cx - 22, cy + p["bob"])], fill=skin, width=5)
    orb_r = 5 if (phase == 2 or p["is_cast"] or p["is_rng"]) else 4
    _ell(d, cx - 24, cy - 2 + p["bob"], orb_r, orb_r, void)
    _ell(d, cx - 24, cy - 2 + p["bob"], 2, 2, void_s)

    # Đầu Yêu Đế với 2 cặp sừng & con mắt thứ 3
    hx = cx + (2 if p["is_dash"] or p["is_atk"] else 0)
    hy = cy - 19
    _ell(d, hx, hy, 10, 9, skin)
    # Sừng chính lớn uốn cong
    for sgn in (-1, 1):
        d.polygon([
            (hx + sgn * 6, hy - 6),
            (hx + sgn * 15, hy - 18),
            (hx + sgn * 11, hy - 4),
        ], fill=gold_d)
        d.line([(hx + sgn * 7, hy - 7), (hx + sgn * 15, hy - 18)], fill=gold_s, width=1)
        if phase == 2:
            d.polygon([
                (hx + sgn * 4, hy - 8),
                (hx + sgn * 8, hy - 20),
                (hx + sgn * 2, hy - 9),
            ], fill=void)
    # Mắt ác + mắt thứ 3 giữa trán
    eye_c = C("ffffff") if (p["is_wind"] and f == 19) else (C("ff2438") if p["is_rage"] else eye)
    d.rectangle([hx - 6, hy - 1, hx - 2, hy + 1], fill=eye_c)
    d.rectangle([hx + 2, hy - 1, hx + 6, hy + 1], fill=eye_c)
    _ell(d, hx, hy - 5, 2, 2, void_s if phase == 2 else gold_s)

    # Đại Kích Hỗn Mang tay phải
    ax, ay = cx + 13, cy - 5
    ang = p["arm_ang"]
    hx_hand = ax + round(math.cos(ang) * 10)
    hy_hand = ay + round(math.sin(ang) * 8)
    d.line([(ax, ay), (hx_hand, hy_hand)], fill=skin, width=5)
    w_ang = ang - 0.5
    sx0 = max(4, min(W - 5, hx_hand - round(math.cos(w_ang) * 16)))
    sy0 = max(4, min(H - 5, hy_hand - round(math.sin(w_ang) * 16)))
    sx1 = max(6, min(W - 7, hx_hand + round(math.cos(w_ang) * 26)))
    sy1 = max(6, min(H - 7, hy_hand + round(math.sin(w_ang) * 26)))
    d.line([(sx0, sy0), (sx1, sy1)], fill=gold_d, width=3)
    # Lưỡi kích trăng khuyết + ngọn giáo hỗn mang
    nx, ny = math.cos(w_ang), math.sin(w_ang)
    tip_x = max(2, min(W - 3, round(sx1 + nx * 7)))
    tip_y = max(2, min(H - 3, round(sy1 + ny * 7)))
    d.line([(sx1, sy1), (tip_x, tip_y)], fill=void_s, width=2)
    d.ellipse([sx1 - 6, sy1 - 6, sx1 + 6, sy1 + 6], outline=gold_l, width=2)
    _ell(d, sx1, sy1, 3, 3, void)

    if p["is_atk"] and f in (21, 22, 23, 24):
        d.arc([48, 12, 92, 60], -75, 65, fill=void_s, width=3)
        d.arc([52, 16, 88, 56], -65, 55, fill=void, width=2)
    elif p["is_rng"] and f in (27, 28, 29):
        ox = min(90, 72 + (f - 27) * 5)
        _ell(d, ox, cy - 4, 6, 5, void)
        _ell(d, ox, cy - 4, 3, 2, void_s)
    elif p["is_dash"]:
        for sy in (22, 36, 50):
            d.line([(4 + (f % 2) * 3, sy), (20, sy)], fill=void_s, width=2)
    elif f == 43:
        d.arc([10, 50, 86, 68], 180, 360, fill=void_s, width=3)
    elif p["is_rage"]:
        d.arc([10, 50, 86, 68], 0, 360, fill=C("ff3040") if f == 44 else gold_s, width=3)
    elif p["is_spec"]:
        for k_s in range(4):
            sx_r = 14 + k_s * 22
            d.polygon([(sx_r - 4, 66), (sx_r, 34 - (f - 46) * 6), (sx_r + 4, 66)], fill=void)
            d.line([(sx_r, 65), (sx_r, 36 - (f - 46) * 6)], fill=void_s, width=1)

    return polish(img, texture=False)


# ------------------------------------------------------------------ 4. 4 Thần Thú Thức Tỉnh
def build_evolved_pets():
    gold, gold_l, gold_d = C("f2b838"), C("fff4a8"), C("a46818")
    flame, flame_l = C("ff5a22"), C("ffd852")

    # 1. Nghê Thần Lửa (dog: 4 khung 28x24)
    dog_frames = []
    fur, fur_l, fur_d = C("e89432"), C("ffd068"), C("9e4e18")
    cream = C("fff4dc")
    for f in range(4):
        img, d = canvas(28, 24)
        sit_dy = 2 if f in (2, 3) else 0
        fl_wob = 1 if f in (1, 3) else 0
        # Đuôi lửa Nghê Thần rực cháy
        d.arc([1, 4 + sit_dy, 10, 14 + sit_dy], 90, 320, fill=flame, width=3)
        d.polygon([(3, 7 + sit_dy), (1, 2 + fl_wob), (6, 5 + sit_dy)], fill=flame_l)
        d.point([2, 3 + fl_wob], fill=gold_l)
        # Thân bờm lửa vàng óng & ức kem
        d.ellipse([6, 10 + sit_dy, 19, 18 + sit_dy // 2], fill=fur)
        auto_shade(img, fur, fur_l, fur_d)
        d.ellipse([13, 12 + sit_dy // 2, 19, 18], fill=cream)
        # Chân chạy + móng lửa vàng
        for lx, ly in ([(8, 18), (15, 18)], [(7, 17), (16, 17)], [(9, 18), (16, 18)], [(9, 18), (16, 18)])[f]:
            d.line([(lx, 15), (lx, ly + 2)], fill=fur_d, width=2)
            d.point([lx, ly + 2], fill=flame_l)
        # Bờm sư tử lửa quanh cổ & chuông vàng
        d.ellipse([12, 8, 20, 15], fill=flame)
        d.rectangle([15, 12, 18, 14], fill=C("d82424"))
        d.point([17, 14], fill=gold_l)
        # Đầu Nghê + sừng vàng nhỏ trên trán + tai vểnh
        d.ellipse([13, 4, 23, 13], fill=fur)
        d.ellipse([18, 8, 24, 12], fill=cream)
        d.polygon([(17, 4), (18, 0), (19, 4)], fill=gold_l)  # sừng Nghê Thần
        d.polygon([(14, 5), (12, 9), (15, 9)], fill=flame)
        d.point([23, 9], fill=C("1c141c"))
        d.point([20, 7], fill=C("ff3828"))
        d.point([20, 6], fill=C("ffffff"))
        if f in (2, 3):
            d.point([21, 11], fill=flame_l)
        dog_frames.append(_with_shadow(outline(img), 5, 18, 22, 23, 85))
    save(sheet(dog_frames), "world/animal_dog_evo.png")

    # 2. Linh Miêu Chiêu Bảo (cat: 3 khung 26x22)
    cat_frames = []
    cr = C("fff7e8")
    jade = C("38d49c")
    for f in range(3):
        img, d = canvas(26, 22)
        tx = 1 if f == 2 else 0
        # Song vĩ (hai đuôi linh miêu)
        d.arc([2 + tx, 7, 10 + tx, 17], 110, 270, fill=gold, width=2)
        d.arc([4 + tx, 9, 11 + tx, 18], 120, 260, fill=C("e87a2e"), width=1)
        # Thân mèo linh thú + đốm vàng/ngọc
        d.ellipse([8, 10, 17, 18], fill=cr)
        d.ellipse([9, 12, 13, 16], fill=C("38343c"))
        d.rectangle([10, 10, 15, 11], fill=C("d82828"))
        d.point([13, 11], fill=gold_l)
        # Đầu mèo + vương miện vàng nhỏ
        d.ellipse([9, 4, 18, 12], fill=cr)
        d.polygon([(9, 6), (10, 2), (12, 5)], fill=gold)
        d.polygon([(15, 5), (17, 2), (18, 6)], fill=C("38343c"))
        d.polygon([(12, 4), (14, 1), (15, 4)], fill=gold_l)  # vương miện chiêu bảo
        eye_col = jade if f != 1 else C("382c28")
        d.point([12, 8], fill=eye_col)
        d.point([16, 8], fill=eye_col)
        d.point([14, 9], fill=C("f48ca4"))
        # Đồng xu vàng bay lơ lửng bên cạnh
        cy_coin = 6 if f != 2 else 4
        _ell(d, 22, cy_coin, 2.5, 2.5, gold)
        d.point([22, cy_coin], fill=gold_l)
        cat_frames.append(_with_shadow(outline(img), 4, 16, 21, 21, 80))
    save(sheet(cat_frames), "world/animal_cat_evo.png")

    # 3. Kim Kê Mặt Trời (rooster: 3 khung 26x26)
    rooster_frames = []
    for f in range(3):
        img, d = canvas(26, 26)
        lean_y = -1 if f == 2 else 0
        # Hào quang mặt trời sau đầu
        hx, hy = 17, 8 + lean_y
        d.arc([hx - 6, hy - 6, hx + 6, hy + 6], 190, 380, fill=gold_l, width=1)
        if f == 2:
            for ang in (-2.2, -1.5, -0.8):
                d.line([(hx + round(math.cos(ang) * 7), hy + round(math.sin(ang) * 7)),
                        (hx + round(math.cos(ang) * 9), hy + round(math.sin(ang) * 9))], fill=flame_l)
        # Chân vàng
        l1x, l2x = [(10, 14), (13, 10), (11, 13)][f]
        d.line([(l1x, 18), (l1x, 23)], fill=gold, width=2)
        d.line([(l2x, 18), (l2x, 23)], fill=gold_d, width=2)
        # Đuôi phượng hoàng rực rỡ
        d.arc([1, 4, 12, 18], 110, 275, fill=flame, width=2)
        d.arc([2, 6, 11, 17], 120, 260, fill=gold_l, width=2)
        d.arc([3, 8, 11, 17], 130, 250, fill=C("22b88c"), width=1)
        # Thân & cổ kim kê rực vàng đỏ
        d.ellipse([6, 11, 17, 19], fill=C("b82a24"))
        d.ellipse([8, 12, 15, 17], fill=gold)
        d.polygon([(12, 12), (15, 7 + lean_y), (19, 9 + lean_y), (16, 15)], fill=gold)
        d.ellipse([14, 6 + lean_y, 20, 11 + lean_y], fill=gold_l)
        # Mào vương miện mặt trời + tích đỏ + mỏ vàng
        d.polygon([(15, 6 + lean_y), (16, 2 + lean_y), (18, 4 + lean_y), (19, 2 + lean_y), (20, 6 + lean_y)], fill=flame)
        d.ellipse([17, 10 + lean_y, 19, 13 + lean_y], fill=C("e22626"))
        d.polygon([(20, 8 + lean_y), (24, 9 + lean_y), (20, 10 + lean_y)], fill=gold_l)
        d.point([18, 8 + lean_y], fill=C("1a101c"))
        rooster_frames.append(_with_shadow(outline(img), 6, 20, 20, 25, 80))
    save(sheet(rooster_frames), "world/animal_rooster_evo.png")

    # 4. Lạc Điểu Hồng Bàng (crane: 4 khung 28x36)
    crane_frames = []
    wh, wh_s = C("fffdf8"), C("c8e4f4")
    cyan_g = C("6cf4ff")
    for f in range(4):
        img, d = canvas(28, 36)
        # Vòng hào quang Lạc Điểu trên lưng
        d.arc([6, 2, 22, 14], 190, 350, fill=gold_l, width=1)
        # Chân cao thanh mảnh ánh vàng đồng
        d.line([(12, 21), (12, 33)], fill=gold_d, width=1)
        d.line([(15, 21), (15, 33)], fill=gold_d, width=1)
        d.line([(11, 33), (14, 33)], fill=gold_d, width=1)
        # Thân & cánh Lạc Điểu viền vàng kim + lông đuôi xanh ngọc
        d.ellipse([7, 14, 19, 23], fill=wh)
        if f == 3:
            d.polygon([(8, 14), (2, 8), (13, 16)], fill=gold_l)
            d.line([(3, 9), (10, 14)], fill=cyan_g)
        d.polygon([(7, 17), (2, 23), (10, 21)], fill=C("1d6c7a"))
        d.arc([8, 15, 17, 21], 10, 160, fill=gold)
        # Cổ cong + chỏm mào Lạc Việt + mỏ vàng dài
        if f == 2:
            d.line([(16, 16), (20, 18), (19, 23)], fill=wh, width=2)
            d.ellipse([17, 22, 21, 26], fill=wh)
            d.polygon([(17, 22), (19, 19), (20, 22)], fill=gold_l)
            d.line([(20, 25), (25, 30)], fill=gold)
        else:
            hx = 14 if f == 1 else 17
            d.line([(16, 16), (18, 11), (hx, 7)], fill=wh, width=2)
            d.ellipse([hx - 2, 4, hx + 2, 8], fill=wh)
            d.polygon([(hx - 1, 4), (hx, 1), (hx + 2, 4)], fill=C("e83838"))
            d.point([hx + (1 if f != 1 else -1), 6], fill=C("18141c"))
            beak_x = hx - 6 if f == 1 else hx + 7
            d.line([(hx + (1 if f != 1 else -1), 6), (beak_x, 7)], fill=gold)
        crane_frames.append(_with_shadow(outline(img), 6, 30, 21, 35, 75))
    save(sheet(crane_frames), "world/animal_crane_evo.png")


# ------------------------------------------------------------------ 5. Cổ Loa & Doanh Trại / Vườn Thảo Dược
def build_coloa_and_camp():
    bronze_d, bronze, bronze_l, bronze_s = C("6e441c"), C("c68638"), C("f4be58"), C("fff4a6")
    wood_d, wood, wood_l = C("4a2812"), C("7e4c28"), C("b07644")
    stone_d, stone, stone_l = C("4c4944"), C("827e74"), C("b4afa4")
    jade_d, jade, jade_l = C("1c7c6c"), C("34cca8"), C("a8fff0")
    red_d, red, red_l = C("781c22"), C("c43238"), C("f46a5a")

    # 1. Nỏ Thần Cổ Loa Core (48x48)
    img, d = canvas(48, 48)
    d.ellipse([4, 24, 43, 44], fill=stone_d)
    d.ellipse([5, 20, 42, 40], fill=stone)
    auto_shade(img, stone, stone_l, stone_d)
    d.ellipse([9, 22, 38, 36], fill=bronze_d)
    d.ellipse([11, 20, 36, 33], fill=bronze)
    # Hoa văn mặt trống đồng Đông Sơn
    d.ellipse([15, 22, 32, 31], outline=bronze_l)
    d.ellipse([20, 24, 27, 29], fill=bronze_l)
    # Cột ngọc & Nỏ Thần phát sáng ở tâm
    d.rectangle([20, 12, 27, 25], fill=bronze_d)
    d.rectangle([21, 12, 26, 24], fill=bronze_l)
    d.polygon([(23, 3), (30, 11), (23, 19), (16, 11)], fill=jade)
    d.polygon([(23, 5), (27, 11), (23, 17), (19, 11)], fill=jade_l)
    # Cung nỏ vàng ngang
    d.arc([10, 9, 37, 22], 190, 350, fill=bronze_s, width=2)
    d.line([(12, 15), (35, 15)], fill=jade_l)
    save(_with_shadow(outline(img), 4, 34, 43, 46, 100), "world/coloa_core.png")

    # 2. Lũy Tre Ngà (32x32)
    img, d = canvas(32, 32)
    d.rectangle([3, 21, 28, 28], fill=wood_d)
    for bx in range(4, 28, 4):
        top = 7 if (bx // 4) % 2 == 0 else 10
        d.rectangle([bx, top, bx + 2, 26], fill=C("7aa840"))
        d.line([(bx, top), (bx, 26)], fill=C("b8e668"))
        d.polygon([(bx, top), (bx + 1, top - 3), (bx + 2, top)], fill=bronze_s)
        d.point([bx + 1, top + 6], fill=C("445c20"))
        d.point([bx + 1, top + 12], fill=C("445c20"))
    d.rectangle([3, 16, 28, 19], fill=wood)
    d.line([(3, 16), (28, 16)], fill=wood_l)
    save(_with_shadow(outline(img), 3, 24, 28, 30, 90), "world/tower_luy_tre.png")

    # 3. Tháp Nỏ Thần (32x32)
    img, d = canvas(32, 32)
    d.polygon([(6, 28), (10, 12), (21, 12), (25, 28)], fill=wood)
    auto_shade(img, wood, wood_l, wood_d)
    d.rectangle([7, 10, 24, 14], fill=bronze_d)
    d.rectangle([8, 9, 23, 12], fill=bronze)
    # Nỏ vàng gắn trên đài
    d.arc([7, 3, 24, 13], 185, 355, fill=bronze_s, width=2)
    d.line([(16, 2), (16, 12)], fill=bronze_l, width=2)
    d.point([16, 2], fill=jade_l)
    save(_with_shadow(outline(img), 5, 25, 26, 30, 90), "world/tower_no_than.png")

    # 4. Bãi Cọc Bạch Đằng (32x28)
    img, d = canvas(32, 28)
    d.ellipse([2, 16, 29, 25], fill=C("1c628a"))
    d.arc([4, 17, 27, 24], 0, 180, fill=C("7ee8ff"), width=1)
    for sx, sy, lean in ((7, 6, 2), (14, 3, 0), (22, 5, -2), (11, 10, 1), (19, 10, -1)):
        d.line([(sx, 22), (sx + lean, sy)], fill=wood_d, width=3)
        d.line([(sx, 22), (sx + lean, sy)], fill=wood, width=1)
        d.polygon([(sx + lean - 1, sy + 2), (sx + lean, sy - 2), (sx + lean + 2, sy + 2)], fill=C("cbd4e0"))
    save(_with_shadow(outline(img), 2, 19, 29, 26, 80), "world/tower_bai_coc.png")

    # 5. Pháo Đài Điện Biên (34x34)
    img, d = canvas(34, 34)
    d.ellipse([3, 16, 30, 30], fill=stone_d)
    d.ellipse([4, 13, 29, 26], fill=stone)
    auto_shade(img, stone, stone_l, stone_d)
    # Bao cát quanh pháo đài
    for bx in (5, 13, 21):
        d.rounded_rectangle([bx, 20, bx + 7, 25], 2, fill=C("a88a5a"), outline=C("5e482c"))
    # Nòng pháo cối vươn lên + sao vàng
    d.line([(16, 18), (24, 6)], fill=C("3a404c"), width=5)
    d.line([(16, 18), (24, 6)], fill=C("768092"), width=2)
    d.ellipse([22, 4, 26, 8], fill=C("1c1c24"))
    d.point([16, 20], fill=bronze_s)
    save(_with_shadow(outline(img), 3, 25, 30, 32, 95), "world/tower_phao_dai.png")

    # 6. Lò Rèn Dã Chiến (34x34)
    img, d = canvas(34, 34)
    d.rectangle([4, 10, 20, 29], fill=C("8a3e32"))
    auto_shade(img, C("8a3e32"), C("b85646"), C("52201a"))
    d.rectangle([8, 17, 16, 25], fill=C("221010"))
    d.polygon([(9, 25), (12, 17), (15, 25)], fill=C("ff8224"))
    d.polygon([(11, 25), (12, 20), (13, 25)], fill=C("ffe460"))
    d.rectangle([6, 5, 11, 10], fill=C("52201a"))
    # Đe rèn & cờ búa vàng
    d.rectangle([21, 21, 30, 24], fill=C("565266"))
    d.rectangle([23, 24, 28, 29], fill=C("383446"))
    d.line([(27, 8), (27, 21)], fill=wood, width=1)
    d.polygon([(27, 8), (32, 10), (27, 13)], fill=bronze_l)
    save(_with_shadow(outline(img), 3, 25, 30, 32, 95), "world/tower_lo_ren.png")

    # 7. Lồng Giam NPC (32x34)
    img, d = canvas(32, 34)
    iron_d, iron, iron_l = C("383e4c"), C("667084"), C("a4b0c8")
    # Ánh sáng hào quang người bị giam bên trong
    _ell(d, 16, 17, 8, 9, C("ffe878", 120))
    _ell(d, 16, 14, 4, 4, C("fff2a8"))
    d.rectangle([12, 18, 19, 26], fill=C("e8a848"))
    # Khung sắt & song chắn
    d.rectangle([4, 5, 27, 29], outline=iron_d, width=2)
    d.rectangle([5, 6, 26, 28], outline=iron, width=1)
    for bx in (8, 12, 16, 20, 24):
        d.line([(bx, 6), (bx, 28)], fill=iron)
        d.point([bx, 7], fill=iron_l)
    # Ổ khóa vàng lớn ở giữa
    d.rectangle([13, 18, 18, 23], fill=bronze_l, outline=bronze_d)
    d.arc([14, 15, 17, 19], 180, 360, fill=bronze_s, width=1)
    save(_with_shadow(outline(img), 4, 26, 27, 32, 95), "world/rescue_cage.png")

    # 8. Cây Cổ Thụ Thiên Mệnh / Skill Tree (44x46)
    img, d = canvas(44, 46)
    # Bệ đá cổ
    d.ellipse([10, 33, 33, 42], fill=stone_d)
    d.ellipse([11, 31, 32, 39], fill=stone)
    # Thân cổ thụ uốn lượn & rễ bám đá
    d.polygon([(18, 36), (20, 18), (24, 18), (26, 36)], fill=wood)
    auto_shade(img, wood, wood_l, wood_d)
    d.line([(20, 23), (12, 16)], fill=wood, width=3)
    d.line([(23, 21), (31, 15)], fill=wood, width=3)
    # Tán lá ngọc bích & quả sáng vàng linh khí
    for cx_l, cy_l, r_l in ((22, 14, 13), (12, 16, 8), (32, 16, 8), (17, 8, 8), (27, 8, 8)):
        _ell(d, cx_l, cy_l, r_l, r_l * 0.78, C("2a7a42"))
    for cx_l, cy_l, r_l in ((22, 12, 11), (13, 14, 6), (31, 14, 6), (22, 7, 7)):
        _ell(d, cx_l, cy_l, r_l, r_l * 0.72, C("48b858"))
    for gx, gy in ((14, 14), (22, 9), (29, 13), (19, 17), (26, 16)):
        _ell(d, gx, gy, 1.5, 1.5, bronze_s)
    save(_with_shadow(outline(img), 8, 36, 35, 44, 95), "world/lobby_skill_tree.png")

    # 9. Đài Thức Tỉnh Thần Thú (44x44)
    img, d = canvas(44, 44)
    # Bậc đá tròn 2 tầng
    d.ellipse([4, 28, 39, 41], fill=stone_d)
    d.ellipse([5, 25, 38, 37], fill=stone)
    d.ellipse([10, 22, 33, 32], fill=bronze_d)
    d.ellipse([11, 20, 32, 29], fill=bronze)
    # Hai trụ đá Nghê hai bên
    for px_p in (9, 31):
        d.rectangle([px_p, 14, px_p + 3, 29], fill=stone_l, outline=stone_d)
        _ell(d, px_p + 1, 13, 2.5, 2.5, bronze_l)
    # Viên ngọc thức tỉnh lam-vàng lơ lửng giữa đài
    d.polygon([(22, 4), (28, 12), (22, 20), (16, 12)], fill=jade)
    d.polygon([(22, 6), (25, 12), (22, 18), (19, 12)], fill=jade_l)
    d.arc([14, 8, 30, 17], 0, 360, fill=bronze_s, width=1)
    save(_with_shadow(outline(img), 4, 33, 39, 42, 95), "world/lobby_pet_shrine.png")

    # 10. Cờ Võ Đài Tỷ Thí (34x42)
    img, d = canvas(34, 42)
    # Chân đế đá & hai cây giáo/kiếm bắt chéo
    d.rectangle([9, 34, 24, 39], fill=stone_d)
    d.rectangle([10, 32, 23, 36], fill=stone)
    d.line([(6, 32), (27, 8)], fill=C("b8c4d8"), width=2)
    d.line([(27, 32), (6, 8)], fill=C("b8c4d8"), width=2)
    # Cán cờ giữa & lá cờ đỏ viền vàng
    d.line([(16, 3), (16, 34)], fill=wood, width=2)
    d.point([16, 2], fill=bronze_s)
    d.polygon([(10, 7), (23, 7), (22, 26), (16, 30), (11, 26)], fill=red)
    d.polygon([(10, 7), (23, 7), (22, 9), (11, 9)], fill=bronze_l)
    d.ellipse([13, 13, 20, 20], outline=bronze_s, width=1)
    d.point([16, 16], fill=bronze_s)
    save(_with_shadow(outline(img), 7, 34, 26, 41, 90), "world/lobby_sparring_banner.png")

    # 11. Linh Chi Vàng (24x24)
    img, d = canvas(24, 24)
    d.ellipse([5, 16, 18, 21], fill=C("4a301e"))
    # Thân & tán nấm Linh Chi nhiều tầng vàng rực
    d.line([(11, 18), (11, 10)], fill=bronze_d, width=3)
    d.ellipse([4, 7, 15, 13], fill=bronze)
    d.ellipse([5, 6, 14, 10], fill=bronze_s)
    d.ellipse([10, 10, 20, 15], fill=bronze)
    d.ellipse([11, 9, 19, 12], fill=bronze_l)
    d.ellipse([7, 3, 16, 8], fill=bronze_l)
    d.ellipse([9, 3, 14, 6], fill=bronze_s)
    for gx, gy in ((6, 4), (18, 6), (12, 1)):
        d.point([gx, gy], fill=C("fff8c4"))
    save(_with_shadow(outline(img), 4, 17, 19, 22, 80), "world/garden_linh_chi.png")

    # 12. Hoa Ưu Đàm (24x24)
    img, d = canvas(24, 24)
    d.ellipse([5, 16, 18, 21], fill=C("285c48"))
    # Thân mảnh thanh khiết & chùm hoa trắng ngọc phát sáng
    d.line([(11, 18), (11, 10)], fill=C("a8f0c8"), width=1)
    d.line([(11, 14), (7, 9)], fill=C("a8f0c8"), width=1)
    d.line([(11, 13), (16, 8)], fill=C("a8f0c8"), width=1)
    for fx, fy in ((11, 7), (7, 8), (16, 7)):
        _ell(d, fx, fy, 3, 3, C("e8ffff"))
        _ell(d, fx, fy, 1.5, 1.5, bronze_s)
    for sx, sy in ((5, 4), (18, 3), (12, 2)):
        d.point([sx, sy], fill=C("ffffff"))
    save(_with_shadow(outline(img), 4, 17, 19, 22, 80), "world/garden_uu_dam.png")


def build_hero_skill_icons():
    """6 biểu tượng kỹ năng (Chiêu 1 + Chiêu 2) 22x22 cho 3 vị tướng mới v3.0.0."""
    gold, gold_l, gold_d = C("f6c43c"), C("fff0a0"), C("a86a2a")
    jade, jade_l = C("38d8c8"), C("98fff4")
    sea, sea_l, sea_d = C("2894e8"), C("84e0ff"), C("18528e")
    stone, stone_l, stone_d = C("6e8c4c"), C("9ec86e"), C("3a4e26")

    # 1. Mưa tên Cổ Loa (An Dương Vương - Chiêu 1)
    img, d = canvas(22, 22)
    for ax, ay in ((4, 15), (9, 10), (14, 15)):
        d.line([(ax, ay), (ax + 5, ay - 6)], fill=gold_l, width=2)
        d.point([(ax + 5, ay - 6), (ax + 4, ay - 6), (ax + 5, ay - 5)], fill=jade_l)
        d.point([(ax, ay), (ax + 1, ay)], fill=jade)
    d.arc([3, 3, 18, 18], 200, 340, fill=gold, width=1)
    save(outline(img), "ui/skill_mua_ten_co_loa.png")

    # 2. Loa Thành Trấn (An Dương Vương - Chiêu 2)
    img, d = canvas(22, 22)
    d.rectangle([5, 13, 16, 18], fill=gold_d, outline=gold)
    d.rectangle([7, 8, 14, 13], fill=gold)
    d.line([(10, 8), (10, 3)], fill=jade_l, width=2)
    d.line([(6, 10), (15, 10)], fill=gold_l, width=1)
    d.point([(10, 3), (10, 4)], fill=jade_l)
    save(outline(img), "ui/skill_loa_thanh_tran.png")

    # 3. Thủy Long Triều (Lạc Long Quân - Chiêu 1)
    img, d = canvas(22, 22)
    d.arc([3, 4, 18, 19], 10, 220, fill=sea_l, width=2)
    d.arc([5, 6, 16, 17], 190, 360, fill=sea, width=2)
    _ell(d, 15, 7, 2.5, 2.5, gold_l)
    _ell(d, 6, 14, 2.0, 2.0, jade_l)
    save(outline(img), "ui/skill_thuy_long_trieu.png")

    # 4. Trăm Trứng Hào Quang (Lạc Long Quân - Chiêu 2)
    img, d = canvas(22, 22)
    d.arc([2, 2, 19, 19], 0, 360, fill=gold_l, width=1)
    _ell(d, 11, 11, 4.5, 5.5, sea_l)
    _ell(d, 10, 10, 2.5, 3.5, gold_l)
    for sx, sy in ((4, 6), (17, 6), (4, 16), (17, 16)):
        d.point([(sx, sy)], fill=jade_l)
    save(outline(img), "ui/skill_tram_trung_hao_quang.png")

    # 5. Dời Non Lấp Bể (Sơn Tinh - Chiêu 1)
    img, d = canvas(22, 22)
    d.polygon([(3, 18), (8, 7), (13, 18)], fill=stone_d, outline=stone)
    d.polygon([(9, 18), (14, 5), (19, 18)], fill=stone, outline=stone_l)
    d.polygon([(6, 18), (11, 10), (16, 18)], fill=stone_l)
    d.line([(4, 18), (18, 18)], fill=gold, width=1)
    save(outline(img), "ui/skill_doi_non_lap_be.png")

    # 6. Thạch Giáp Tản Viên (Sơn Tinh - Chiêu 2)
    img, d = canvas(22, 22)
    d.polygon([(5, 5), (16, 5), (17, 13), (11, 19), (4, 13)], fill=stone, outline=gold)
    d.polygon([(7, 7), (14, 7), (14, 12), (11, 16), (7, 12)], fill=stone_l)
    d.line([(11, 6), (11, 16)], fill=gold_l, width=1)
    save(outline(img), "ui/skill_thach_giap_tan_vien.png")


def build():
    for fn, rel in (
        (thuy_tinh_frame, "boss_thuy_tinh"),
        (thien_loi_frame, "boss_thien_loi"),
        (hon_mang_frame, "boss_hon_mang_yeu_de"),
    ):
        for phase in (1, 2):
            frames = [fn(i, phase) for i in range(48)]
            save(sheet_grid(frames, cols=12), "enemies/%s%s.png" % (rel, "" if phase == 1 else "_2"))
    build_evolved_pets()
    build_coloa_and_camp()
    build_hero_skill_icons()


if __name__ == "__main__":
    build()
