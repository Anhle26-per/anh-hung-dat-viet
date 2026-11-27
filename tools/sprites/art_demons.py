"""Hình "hiện nguyên hình" của 10 trùm lịch sử (48 khung lưới 12x4): sắc nét, tương phản mạnh, sừng & hào quang chi tiết."""
import colorsys
import os
from PIL import Image, ImageDraw, ImageFilter
from px import save, polish, shade, hexc, hue_ramp, mix, sheet_grid, OUT

DEMON = {
    "to_dinh":     {"skin": "c44636", "eye": "ffe850", "horn": "ox",     "aura": "ff5438", "horn_c": "f4ead0"},
    "luc_dan":     {"skin": "568452", "eye": "ff3838", "horn": "spikes", "aura": "7eff6a", "horn_c": "d8d8bc"},
    "hoang_thao":  {"skin": "3682a4", "eye": "9efeff", "horn": "fins",   "aura": "44d0ff", "horn_c": "6ce0f4"},
    "quach_quy":   {"skin": "8e66b4", "eye": "ffe850", "horn": "crest",  "aura": "c884ff", "horn_c": "f4e8ff"},
    "thoat_hoan":  {"skin": "8a8ca2", "eye": "ffd844", "horn": "wolf",   "aura": "d4d8ff", "horn_c": "727488"},
    "lieu_thang":  {"skin": "6d823a", "eye": "ff6838", "horn": "antler", "aura": "b8dc42", "horn_c": "8a623c"},
    "ton_si_nghi": {"skin": "b2385c", "eye": "ffff88", "horn": "ox",     "aura": "ff4484", "horn_c": "302236"},
    "tau_hy_vong": {"skin": None,     "eye": "88ff96", "horn": None,     "aura": "5eff8c", "horn_c": None},
    "don_truong":  {"skin": "864d38", "eye": "ff2c2c", "horn": "spikes", "aura": "ff7c3a", "horn_c": "dfd6c4"},
    "do_cat":      {"skin": "4a4c74", "eye": "ff2424", "horn": "ox",     "aura": "ff3838", "horn_c": "d8d0be"},
}


def scale2x(img):
    w, h = img.size
    s = img.load()
    out = Image.new("RGBA", (w * 2, h * 2), (0, 0, 0, 0))
    o = out.load()

    def g(x, y):
        x = min(max(x, 0), w - 1)
        y = min(max(y, 0), h - 1)
        return s[x, y]

    for y in range(h):
        for x in range(w):
            p = s[x, y]
            a, b, c, d = g(x, y - 1), g(x + 1, y), g(x - 1, y), g(x, y + 1)
            o[2 * x, 2 * y] = a if (c == a and c != d and a != b) else p
            o[2 * x + 1, 2 * y] = b if (a == b and a != c and b != d) else p
            o[2 * x, 2 * y + 1] = c if (d == c and d != b and c != a) else p
            o[2 * x + 1, 2 * y + 1] = d if (b == d and b != a and d != c) else p
    return out


def _is_skin(c):
    r, g, b, a = c
    if a < 200:
        return False
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return 0.03 <= h <= 0.10 and 0.50 <= l <= 0.94 and s >= 0.30


def demonize_frame(fr, cfg):
    w, h = fr.size
    px = fr.load()
    skin = hexc(cfg["skin"]) if cfg["skin"] else None
    eye = hexc(cfg["eye"])
    au = hexc(cfg["aura"])
    skin_pts = []
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if skin and _is_skin(c):
                l = colorsys.rgb_to_hls(c[0] / 255, c[1] / 255, c[2] / 255)[1]
                px[x, y] = shade(skin, (l - 0.68) * 1.55)
                skin_pts.append((x, y))
            elif skin is None and c[3] > 60:
                lum = (c[0] * 0.3 + c[1] * 0.59 + c[2] * 0.11) / 255
                px[x, y] = (int(34 + 62 * lum), int(78 + 125 * lum), int(64 + 80 * lum), c[3])
    sk = set(skin_pts)
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] > 200 and (x, y) not in sk:
                lum = (c[0] * 0.3 + c[1] * 0.59 + c[2] * 0.11) / 255.0
                if lum > 0.72:
                    px[x, y] = mix(c, (255, 240, 190, 255), 0.18)
                else:
                    px[x, y] = mix(mix(c, (20, 12, 34, 255), 0.24), au, 0.18)
    if not skin_pts:
        return fr, None
    xs = [p[0] for p in skin_pts]
    ys = [p[1] for p in skin_pts]
    fy0, fy1 = min(ys), max(ys)
    eyes = []
    for y in range(fy0, fy0 + int((fy1 - fy0) * 0.56) + 1):
        for x in range(w):
            c = px[x, y]
            if c[3] > 200 and (x, y) not in sk and (c[0] + c[1] + c[2]) < 320:
                left = any((x - k, y) in sk for k in range(1, 5))
                right = any((x + k, y) in sk for k in range(1, 5))
                if left and right:
                    eyes.append((x, y))
    for x, y in eyes:
        px[x, y] = eye
        if y > 0 and px[x, y - 1][3] > 200 and (x, y - 1) not in sk:
            px[x, y - 1] = shade(eye, -0.3)
        # Làm tối tròng trắng quanh mắt quỷ để đôi mắt rực sáng sắc nét
        for ddx in (-2, -1, 1, 2):
            nx = x + ddx
            if 0 <= nx < w and (nx, y) not in sk and px[nx, y][3] > 200 and px[nx, y] != eye:
                c_adj = px[nx, y]
                if c_adj[0] + c_adj[1] + c_adj[2] > 600:
                    px[nx, y] = (36, 14, 30, 255)
    box = (min(xs), max(xs), min(ys), max(ys))
    if eyes:
        ey = max(e[1] for e in eyes)
        ex = sum(e[0] for e in eyes) / len(eyes)
        my = ey + 5
        for fx in (int(ex) - 3, int(ex) + 2):
            for k in range(2):
                if 0 <= fx < w and my + k < h:
                    px[fx, my + k] = (255, 250, 236, 255)
    return fr, box


def add_horns(img, box, cfg):
    if box is None or cfg["horn"] is None:
        return img
    d = ImageDraw.Draw(img)
    x0, x1, y0, _ = box
    px = img.load()
    w, _ = img.size
    cx = (x0 + x1) / 2
    head_top = y0
    for y in range(y0, -1, -1):
        if any(0 <= int(cx) + dx < w and px[int(cx) + dx, y][3] > 200 for dx in (-2, 0, 2)):
            head_top = y
    ym = int((head_top + y0) / 2)
    row = [x for x in range(w) if px[x, ym][3] > 200 and abs(x - cx) < 30]
    hl, hr = (min(row), max(row)) if row else (x0, x1)
    _, cd, c, cl, cs = hue_ramp(cfg["horn_c"])
    au = hexc(cfg["aura"])
    kind = cfg["horn"]
    for sgn in (-1, 1):
        bx = hr - 2 if sgn > 0 else hl + 2
        by = ym + 2
        if kind == "ox":
            pts = [(bx, by + 3), (bx + sgn * 9, by - 2), (bx + sgn * 14, by - 10), (bx + sgn * 13, by - 20),
                   (bx + sgn * 18, by - 12), (bx + sgn * 15, by - 2), (bx + sgn * 6, by + 6), (bx, by + 7)]
            d.polygon(pts, fill=c)
            d.line([(bx + sgn * 2, by + 2), (bx + sgn * 10, by - 2), (bx + sgn * 14, by - 14)], fill=cs)
            d.line([(bx + sgn * 6, by + 5), (bx + sgn * 14, by)], fill=cd)
        elif kind == "spikes":
            for i in range(3):
                ox = bx - sgn * i * 7
                oy = head_top + 6 + i * 2 if i else by
                d.polygon([(ox - 3, oy + 4), (ox + sgn * 4, oy - 14 + i * 3), (ox + 4, oy + 4)], fill=c)
                d.line([(ox, oy + 2), (ox + sgn * 3, oy - 10 + i * 3)], fill=cs)
        elif kind == "fins":
            d.polygon([(bx, by - 4), (bx + sgn * 16, by - 14), (bx + sgn * 13, by - 4), (bx + sgn * 18, by + 2),
                       (bx + sgn * 12, by + 6), (bx, by + 8)], fill=c)
            for k in range(3):
                d.line([(bx + sgn * 2, by + k * 3 - 2), (bx + sgn * (14 - k), by - 12 + k * 6)], fill=au)
        elif kind == "crest":
            if sgn == 1:
                for i in range(5):
                    xx = cx - 10 + i * 5
                    d.polygon([(xx - 3, head_top + 4), (xx - 1 + (i - 2), head_top - 12 - (2 - abs(i - 2)) * 3), (xx + 3, head_top + 4)], fill=c)
                    d.line([(xx, head_top + 2), (xx - 1 + (i - 2), head_top - 8 - (2 - abs(i - 2)) * 3)], fill=cs if i == 2 else cd)
        elif kind == "wolf":
            d.polygon([(bx - sgn * 4, head_top + 8), (bx + sgn * 6, head_top - 14), (bx + sgn * 8, head_top + 10)], fill=c)
            d.polygon([(bx - sgn * 1, head_top + 7), (bx + sgn * 5, head_top - 7), (bx + sgn * 6, head_top + 8)], fill=hexc("ea8ca0"))
        elif kind == "antler":
            d.line([(bx, by), (bx + sgn * 9, by - 16)], fill=c, width=3)
            d.line([(bx + sgn * 5, by - 7), (bx + sgn * 16, by - 10)], fill=cl, width=2)
            d.line([(bx + sgn * 8, by - 13), (bx + sgn * 4, by - 22)], fill=cl, width=2)
            d.line([(bx + sgn * 13, by - 9), (bx + sgn * 17, by - 17)], fill=c, width=2)
            for q in ((16, -10), (4, -22), (17, -17)):
                d.point([(bx + sgn * q[0], by + q[1])], fill=hexc("8ce842"))
    return img


def _flame_tongue(d, x, y, hgt, w_half, outer_c, core_c, tilt=0):
    d.polygon([(x - w_half, y), (x + tilt, max(1, y - hgt)), (x + w_half, y)], fill=outer_c)
    d.polygon([(x - max(1, w_half // 2), y), (x + tilt // 2, max(2, y - max(2, hgt // 2))), (x + max(1, w_half // 2), y)], fill=core_c)


def _ghost_flames(img, f):
    d = ImageDraw.Draw(img)
    w, h = img.size
    px = img.load()
    g_out = hexc("38e468")
    g_mid = hexc("7cff9c")
    g_core = hexc("e6ffd8")
    tilt = -5 if 36 <= f < 40 else (-2 if 6 <= f < 14 else 0)
    extra = 6 if f >= 44 else (4 if 14 <= f < 32 else 0)
    step = 12 if f >= 44 else 16
    for k, fx in enumerate(range(18, w - 18, step)):
        top = next((y for y in range(h) if px[fx, y][3] > 200), None)
        if top is None:
            continue
        hgt = 8 + ((k + f) % 3) * 3 + extra
        _flame_tongue(d, fx, top + 2, hgt, 4 if f < 44 else 5, g_out, g_core, tilt + ((f + k) % 2) * 2 - 1)
    if 14 <= f < 20:  # windup: ngọn lửa xanh bùng quanh đại bác
        k = f - 14
        for px_c in (34, 58, 82, 106):
            d.ellipse([px_c - 3 - k // 2, 74 - k // 2, px_c + 3 + k // 2, 80 + k // 2], fill=g_mid if k < 3 else g_core)
    elif 20 <= f < 26:  # melee_sweep: vệt chém ma hỏa ở mũi tàu
        d.arc([w - 38, 28, w - 4, h - 14], -75, 65, fill=g_core if f in (22, 23) else g_out, width=3)
    elif 26 <= f < 32:  # ranged_shot: loạt đại bác ma hỏa xanh
        for px_c in (36, 60, 84, 108):
            if f in (27, 28, 29):
                r = 7 if f == 29 else 5
                d.ellipse([px_c - r, 78, px_c + r, 78 + r * 2], fill=g_out)
                d.ellipse([px_c - r // 2, 80, px_c + r // 2, 80 + r], fill=g_core)
            elif f in (30, 31):
                d.ellipse([px_c - 4, 72 - (f - 30) * 2, px_c + 4, 80 - (f - 30) * 2], fill=hexc("98f8b8", 185))
    elif 32 <= f < 36:  # cast_summon: vòng ấn ma trơi quanh mặt nước
        d.arc([12, h - 22, w - 12, h - 4], 0, 360, fill=g_mid if f % 2 == 0 else g_core, width=2)
    elif 36 <= f < 40:  # dash: vệt lửa ma lao ngang
        for sy in (34, 52, 70):
            off = (f % 2) * 5
            d.line([(4 + off, sy), (28 + off, sy)], fill=g_core, width=2)
            d.line([(10 + off, sy + 2), (34 + off, sy + 2)], fill=g_out, width=1)
    elif f == 43:  # leap slam splash
        d.arc([8, h - 24, w - 8, h - 3], 185, 355, fill=g_core, width=3)
    elif f >= 44:  # rage & boc_chay: biển lửa xanh bùng nổ
        for k_s in range(6):
            sx = 20 + k_s * 20 + (f % 2) * 4
            _flame_tongue(d, sx, h - 18, 18 + (k_s + f) % 3 * 5, 5, g_out, g_core, ((f + k_s) % 3) - 1)


def _action_demon_fx(img, f, cfg, boss_id):
    if boss_id == "tau_hy_vong":
        return img
    d = ImageDraw.Draw(img)
    w, h = img.size
    au = hexc(cfg["aura"])
    au_hot = mix(au, (255, 250, 220, 255), 0.55)
    eye = hexc(cfg["eye"])

    if f < 6:  # idle: đốm tà khí lơ lửng nhịp nhàng
        for k in range(3):
            sx = 18 + ((k * 31 + f * 9) % (w - 36))
            sy = 22 + ((k * 19 + f * 5) % (h - 44))
            d.ellipse([sx - 1, sy - 1, sx + 1, sy + 1], fill=au_hot if k == 0 else au)
    elif 6 <= f < 14:  # walk: tà hỏa nhẹ dưới gót chân
        t = f - 6
        for fx in (26 + (t % 3) * 4, w - 28 - (t % 3) * 4):
            _flame_tongue(d, fx, h - 8, 7 + (t % 2) * 3, 2, au, au_hot, -2)
    elif 14 <= f < 20:  # windup: tà hỏa bùng lên theo 6 nhịp lấy đà
        k = f - 14
        for fx in (20, w // 2, w - 20):
            _flame_tongue(d, fx, h - 10, 8 + k * 2, 3, au, au_hot)
        if f >= 17:
            d.ellipse([w // 2 - 2, 24, w // 2 + 2, 28], fill=eye)
    elif 20 <= f < 26:  # melee_sweep: vệt quỷ hỏa dọc đường chém
        if f in (21, 22, 23, 24):
            d.arc([w - 44, 16, w - 4, h - 12], -75, 55, fill=au_hot if f in (22, 23) else au, width=3)
            d.point([w - 10, 32 + (f - 21) * 9], fill=eye)
    elif 26 <= f < 32:  # ranged_shot: tụ hỏa cầu & phóng tia tà khí phía trước
        if f in (27, 28, 29):
            rx = w - 12 if f == 27 else w - 7
            d.ellipse([rx - 5, h // 2 - 5, rx + 5, h // 2 + 5], fill=au)
            d.ellipse([rx - 2, h // 2 - 2, rx + 2, h // 2 + 2], fill=au_hot)
        elif f in (30, 31):
            d.ellipse([w - 18, h // 2 - 8 - (f - 30) * 2, w - 10, h // 2 - (f - 30) * 2], fill=au[:3] + (180,))
    elif 32 <= f < 36:  # cast_summon: vòng ấn ma quỷ rực sáng
        d.arc([12, h - 22, w - 12, h - 4], 0, 360, fill=au_hot if f % 2 == 0 else au, width=2)
        for sx in (16, w - 16):
            _flame_tongue(d, sx, h - 14 - (f - 32) * 3, 10, 3, au, au_hot)
    elif 36 <= f < 40:  # dash: vệt lửa quỷ kéo dài về sau
        for sy in (28, 52, 76):
            off = (f % 2) * 5
            d.line([(4 + off, sy), (24 + off, sy)], fill=au_hot, width=2)
            d.line([(8 + off, sy + 2), (28 + off, sy + 2)], fill=au, width=1)
    elif 40 <= f < 44:  # leap
        if f in (41, 42):
            for fx in (32, w // 2, w - 32):
                _flame_tongue(d, fx, h - 12, 14, 3, au, au_hot)
        elif f == 43:
            d.arc([8, h - 24, w - 8, h - 4], 185, 355, fill=au_hot, width=3)
    elif f in (44, 45):  # rage: cuồng nộ bùng nổ tà hỏa + vòng chấn động đỏ/vàng
        k = f - 44
        d.arc([6 + k * 2, h - 26, w - 6 - k * 2, h - 2], 0, 360, fill=hexc("ff3838") if k == 0 else hexc("ffe868"), width=2)
        for fx in (18, 36, w - 36, w - 18):
            _flame_tongue(d, fx, h - 10, 20 + k * 3, 4, au, au_hot)
    else:  # 46..47 special: ngọn lửa quỷ đặc trưng bao quanh
        k = f - 46
        for fx in (16, 32, w - 32, w - 16):
            _flame_tongue(d, fx, h - 10, 15 + ((fx + k) % 2) * 5, 4, au, au_hot, -1 if k == 0 else 1)
    return img


def aura(img, color, f_idx=0, width=2):
    w, h = img.size
    a_chan = img.getchannel("A")
    # Chỉ lấy phần lõi đặc (>200) để viền tà khí mượt và nhanh hơn gấp 20 lần vòng lặp pixel
    core = a_chan.point(lambda v: 255 if v > 200 else 0)
    r1 = core.filter(ImageFilter.MaxFilter(3))
    r2 = core.filter(ImageFilter.MaxFilter(5))
    # Tính alpha hào quang: lớp trong alpha=165, lớp ngoài alpha=82 (giảm dần mượt)
    c1 = Image.new("RGBA", (w, h), color[:3] + (165,))
    c2 = Image.new("RGBA", (w, h), color[:3] + (82,))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(c2, (0, 0), r2)
    out.paste(c1, (0, 0), r1)
    out.alpha_composite(img)
    src = img.load()
    d = ImageDraw.Draw(out)
    for k in range(4):
        sx = 18 + ((k * 29 + f_idx * 11) % max(12, w - 36))
        sy = 16 + ((k * 23 + f_idx * 17) % max(16, h - 30))
        if src[sx, sy][3] == 0:
            d.point([sx, sy], fill=color[:3] + (220,))
            if sy > 1 and src[sx, sy - 1][3] == 0:
                d.point([sx, sy - 1], fill=(255, 245, 220, 200))
    return out


def demon_sheet(boss_id, fw, fh, n=48):
    cfg = DEMON[boss_id]
    src = Image.open(os.path.join(OUT, "enemies/boss_%s.png" % boss_id)).convert("RGBA")
    cols = max(1, src.width // fw)
    frames = []
    for i in range(n):
        cx = (i % cols) * fw
        cy = (i // cols) * fh
        fr = src.crop((cx, cy, cx + fw, cy + fh))
        big = scale2x(fr)
        big, box = demonize_frame(big, cfg)
        pad = Image.new("RGBA", (fw * 2 + 16, fh * 2 + 18), (0, 0, 0, 0))
        pad.alpha_composite(big, (8, 18))
        if box:
            box = (box[0] + 8, box[1] + 8, box[2] + 18, box[3] + 18)
        add_horns(pad, box, cfg)
        if boss_id == "tau_hy_vong":
            _ghost_flames(pad, i)
        pad = polish(pad, texture=False)
        _action_demon_fx(pad, i, cfg, boss_id)
        pad = aura(pad, hexc(cfg["aura"]), i)
        frames.append(pad)
    W, H = frames[0].size
    save(sheet_grid(frames, cols=12), "enemies/boss_%s_2.png" % boss_id)
    return W, H


def build():
    sizes = {}
    for b in DEMON:
        if b == "tau_hy_vong":
            sizes[b] = demon_sheet(b, 64, 44, 48)
        else:
            sizes[b] = demon_sheet(b, 48, 48, 48)
    return sizes


if __name__ == "__main__":
    print(build())
