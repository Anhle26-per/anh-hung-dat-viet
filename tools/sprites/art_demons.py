"""Hình "hiện nguyên hình" của 10 trùm lịch sử: sắc nét, tương phản mạnh, sừng & hào quang chi tiết."""
import colorsys
import os
from PIL import Image, ImageDraw, ImageFilter
from px import save, polish, shade, hexc, hue_ramp, mix, OUT

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
            elif skin is None and c[3] > 200:
                lum = (c[0] * 0.3 + c[1] * 0.59 + c[2] * 0.11) / 255
                px[x, y] = (int(34 + 62 * lum), int(78 + 125 * lum), int(64 + 80 * lum), 255)
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


def _ghost_flames(img, f):
    d = ImageDraw.Draw(img)
    w, h = img.size
    px = img.load()
    for k, fx in enumerate(range(20, w - 20, 16)):
        top = next((y for y in range(h) if px[fx, y][3] > 200), None)
        if top is None:
            continue
        hgt = 8 + ((k + f) % 3) * 3
        d.polygon([(fx - 4, top + 2), (fx + ((f + k) % 2) * 2 - 1, top - hgt), (fx + 4, top + 2)], fill=hexc("38e468"))
        d.polygon([(fx - 2, top + 2), (fx, top - hgt + 4), (fx + 2, top + 2)], fill=hexc("d8ffc0"))


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


def demon_sheet(boss_id, fw, fh, n):
    cfg = DEMON[boss_id]
    src = Image.open(os.path.join(OUT, "enemies/boss_%s.png" % boss_id)).convert("RGBA")
    frames = []
    for i in range(n):
        fr = src.crop((i * fw, 0, (i + 1) * fw, fh))
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
        pad = aura(pad, hexc(cfg["aura"]), i)
        frames.append(pad)
    W, H = frames[0].size
    sh = Image.new("RGBA", (W * n, H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sh.alpha_composite(f, (i * W, 0))
    save(sh, "enemies/boss_%s_2.png" % boss_id)
    return W, H


def build():
    sizes = {}
    for b in DEMON:
        if b == "tau_hy_vong":
            sizes[b] = demon_sheet(b, 64, 44, 24)
        else:
            sizes[b] = demon_sheet(b, 48, 48, 24)
    return sizes


if __name__ == "__main__":
    print(build())
