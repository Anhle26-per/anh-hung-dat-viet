"""Hình "hiện nguyên hình" của 10 trùm lịch sử (hư cấu: tà thuật biến giặc thành ma tướng).

Không vẽ lại từ đầu mà biến đổi chính tờ hình của trùm để giữ nhận diện:
  1) phóng to 2 lần bằng thuật toán Scale2x (giữ nét pixel, bo mềm đường chéo);
  2) đổi da người thành da quỷ theo tông riêng từng trùm, mắt rực sáng;
  3) mọc sừng / tai / vây / gai theo "con vật" ứng với từng trùm;
  4) hào quang tà khí quanh viền, rồi qua bước polish() như mọi nhân vật.
"""
import colorsys
from PIL import Image, ImageDraw
from px import save, polish, shade, hexc, OUT
import os

# mỗi trùm: tông da quỷ, màu mắt, kiểu sừng, màu hào quang
DEMON = {
    "to_dinh":     {"skin": "b84a3a", "eye": "ffe040", "horn": "ox",     "aura": "ff5a3a", "horn_c": "e8dcc0"},
    "luc_dan":     {"skin": "5a7a5a", "eye": "ff4040", "horn": "spikes", "aura": "7aff6a", "horn_c": "c8c8b0"},
    "hoang_thao":  {"skin": "3a7a9a", "eye": "a0ffff", "horn": "fins",   "aura": "40c8ff", "horn_c": "60d0e8"},
    "quach_quy":   {"skin": "8a6aa8", "eye": "ffe040", "horn": "crest",  "aura": "c080ff", "horn_c": "f0e0ff"},
    "thoat_hoan":  {"skin": "8a8a9a", "eye": "ffd040", "horn": "wolf",   "aura": "d0d0ff", "horn_c": "6a6a7a"},
    "lieu_thang":  {"skin": "6a7a3a", "eye": "ff6040", "horn": "antler", "aura": "b0d040", "horn_c": "7a5a3a"},
    "ton_si_nghi": {"skin": "a83a5a", "eye": "ffff80", "horn": "ox",     "aura": "ff4080", "horn_c": "2a2030"},
    "tau_hy_vong": {"skin": None,     "eye": "80ff80", "horn": None,     "aura": "60ff90", "horn_c": None},
    "don_truong":  {"skin": "7a4a3a", "eye": "ff3030", "horn": "spikes", "aura": "ff7a3a", "horn_c": "d0c8b8"},
    "do_cat":      {"skin": "4a4a6a", "eye": "ff2020", "horn": "ox",     "aura": "ff3030", "horn_c": "c8c0b0"},
}


def scale2x(img):
    """Thuật toán Scale2x (EPX): phóng to pixel art gấp đôi mà vẫn mượt các đường chéo."""
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
            e0 = a if (c == a and c != d and a != b) else p
            e1 = b if (a == b and a != c and b != d) else p
            e2 = c if (d == c and d != b and c != a) else p
            e3 = d if (b == d and b != a and d != c) else p
            o[2 * x, 2 * y] = e0
            o[2 * x + 1, 2 * y] = e1
            o[2 * x, 2 * y + 1] = e2
            o[2 * x + 1, 2 * y + 1] = e3
    return out


def _is_skin(c):
    r, g, b, a = c
    if a < 200:
        return False
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return 0.03 <= h <= 0.095 and 0.55 <= l <= 0.92 and s >= 0.35


def _is_dark_eye(c):
    return c[3] > 200 and c[0] < 60 and c[1] < 50 and c[2] < 70


def demonize_frame(fr, cfg):
    """fr: 1 khung đã phóng to (RGBA). Trả về khung ma tướng (chưa viền)."""
    w, h = fr.size
    px = fr.load()
    skin = hexc(cfg["skin"]) if cfg["skin"] else None
    eye = hexc(cfg["eye"])
    # vùng da: tìm khung bao để đặt sừng ở đỉnh đầu
    skin_pts = []
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if skin and _is_skin(c):
                l = colorsys.rgb_to_hls(c[0] / 255, c[1] / 255, c[2] / 255)[1]
                px[x, y] = shade(skin, (l - 0.7) * 1.4)
                skin_pts.append((x, y))
            elif skin is None and c[3] > 200:
                # tàu ma: chuyển sang xám xanh u ám
                lum = (c[0] * 0.3 + c[1] * 0.59 + c[2] * 0.11) / 255
                px[x, y] = (int(40 + 60 * lum), int(70 + 110 * lum), int(60 + 70 * lum), 255)
    # nhuộm tà khí: quần áo ngả về tông hào quang, tối đi một chút
    au = hexc(cfg["aura"])
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] > 200 and (x, y) not in skin_set(skin_pts):
                px[x, y] = (int(c[0] * 0.78 + au[0] * 0.12), int(c[1] * 0.78 + au[1] * 0.12), int(c[2] * 0.78 + au[2] * 0.12), 255)
    if not skin_pts:
        return fr, None
    sk = skin_set(skin_pts)

    xs = [p[0] for p in skin_pts]
    ys = [p[1] for p in skin_pts]
    fy0, fy1 = min(ys), max(ys)
    # mắt: pixel tối ở nửa trên khuôn mặt, có da cả bên trái lẫn bên phải (cùng hàng)
    eyes = []
    for y in range(fy0, fy0 + int((fy1 - fy0) * 0.55) + 1):
        for x in range(w):
            c = px[x, y]
            if c[3] > 200 and (x, y) not in sk and (c[0] + c[1] + c[2]) < 260:
                left = any((x - k, y) in sk for k in range(1, 4))
                right = any((x + k, y) in sk for k in range(1, 4))
                if left and right:
                    eyes.append((x, y))
    for x, y in eyes:
        px[x, y] = eye
        if y > 0 and px[x, y - 1][3] > 200 and (x, y - 1) not in sk:
            px[x, y - 1] = shade(eye, -0.25)
    box = (min(xs), max(xs), min(ys), max(ys))
    # răng nanh: dưới mắt thấp nhất, chỗ miệng
    if eyes:
        ey = max(e[1] for e in eyes)
        ex = sum(e[0] for e in eyes) / len(eyes)
        my = ey + 5
        for fx in (int(ex) - 3, int(ex) + 2):
            for k in range(2):
                if 0 <= fx < w and my + k < h:
                    px[fx, my + k] = (250, 245, 230, 255)
    return fr, box


_sk_cache = {}


def skin_set(pts):
    key = id(pts)
    if key not in _sk_cache:
        _sk_cache.clear()
        _sk_cache[key] = set(pts)
    return _sk_cache[key]


def add_horns(img, box, cfg):
    """Sừng mọc từ hai bên đầu (kể cả mũ), vượt lên trên đỉnh đầu."""
    if box is None or cfg["horn"] is None:
        return img
    d = ImageDraw.Draw(img)
    x0, x1, y0, y1 = box
    px = img.load()
    w, h = img.size
    cx = (x0 + x1) / 2
    # đỉnh đầu thật (mũ) phía trên khuôn mặt
    head_top = y0
    for y in range(y0, -1, -1):
        if any(px[int(cx) + dx, y][3] > 200 for dx in (-2, 0, 2)):
            head_top = y
    # bề ngang đầu ở giữa mũ và mặt
    ym = int((head_top + y0) / 2)
    row = [x for x in range(w) if px[x, ym][3] > 200 and abs(x - cx) < 30]
    hl, hr = (min(row), max(row)) if row else (x0, x1)
    c = hexc(cfg["horn_c"])
    cd = shade(c, -0.35)
    cl = shade(c, 0.3)
    kind = cfg["horn"]
    for sgn in (-1, 1):
        bx = hr - 2 if sgn > 0 else hl + 2
        by = ym + 2
        if kind == "ox":        # sừng trâu quỷ: chĩa ngang rồi vút lên
            pts = [(bx, by + 3), (bx + sgn * 9, by - 2), (bx + sgn * 14, by - 10), (bx + sgn * 13, by - 20),
                   (bx + sgn * 17, by - 12), (bx + sgn * 15, by - 2), (bx + sgn * 6, by + 6), (bx, by + 7)]
            d.polygon(pts, fill=c)
            d.line([(bx + sgn * 2, by + 2), (bx + sgn * 10, by - 2), (bx + sgn * 14, by - 12)], fill=cl)
            d.line([(bx + sgn * 6, by + 5), (bx + sgn * 14, by)], fill=cd)
        elif kind == "spikes":  # gai nhọn tua tủa
            for i in range(3):
                ox = bx - sgn * i * 7
                oy = head_top + 6 + i * 2 if i else by
                d.polygon([(ox - 3, oy + 4), (ox + sgn * 4, oy - 14 + i * 3), (ox + 4, oy + 4)], fill=c)
                d.line([(ox, oy + 2), (ox + sgn * 3, oy - 10 + i * 3)], fill=cl)
        elif kind == "fins":    # vây cá xòe hai bên
            d.polygon([(bx, by - 4), (bx + sgn * 16, by - 14), (bx + sgn * 13, by - 4), (bx + sgn * 18, by + 2),
                       (bx + sgn * 12, by + 6), (bx, by + 8)], fill=c)
            for k in range(3):
                d.line([(bx + sgn * 2, by + k * 3 - 2), (bx + sgn * (14 - k), by - 12 + k * 6)], fill=cd)
        elif kind == "crest":   # mào ưng dựng trên đỉnh
            if sgn == 1:
                for i in range(5):
                    xx = cx - 10 + i * 5
                    d.polygon([(xx - 3, head_top + 4), (xx - 1 + (i - 2), head_top - 12 - (2 - abs(i - 2)) * 3), (xx + 3, head_top + 4)], fill=c)
                    d.line([(xx, head_top + 2), (xx - 1 + (i - 2), head_top - 8 - (2 - abs(i - 2)) * 3)], fill=cd)
        elif kind == "wolf":    # tai sói dựng to
            d.polygon([(bx - sgn * 4, head_top + 8), (bx + sgn * 6, head_top - 14), (bx + sgn * 8, head_top + 10)], fill=c)
            d.polygon([(bx - sgn * 1, head_top + 7), (bx + sgn * 5, head_top - 7), (bx + sgn * 6, head_top + 8)], fill=hexc("e08a9a"))
        elif kind == "antler":  # gạc cành mục mọc rêu
            d.line([(bx, by), (bx + sgn * 9, by - 16)], fill=c, width=3)
            d.line([(bx + sgn * 5, by - 7), (bx + sgn * 16, by - 10)], fill=c, width=2)
            d.line([(bx + sgn * 8, by - 13), (bx + sgn * 4, by - 22)], fill=c, width=2)
            d.line([(bx + sgn * 13, by - 9), (bx + sgn * 17, by - 17)], fill=c, width=2)
            for q in ((16, -10), (4, -22), (17, -17)):
                d.point([(bx + sgn * q[0], by + q[1])], fill=hexc("7acc3a"))
    return img


def _ghost_flames(img, f):
    """Tàu ma: lửa xanh lè cháy trên boong và ống khói."""
    d = ImageDraw.Draw(img)
    w, h = img.size
    px = img.load()
    for k, fx in enumerate(range(20, w - 20, 17)):
        top = next((y for y in range(h) if px[fx, y][3] > 200), None)
        if top is None:
            continue
        hgt = 7 + ((k + f) % 3) * 3
        d.polygon([(fx - 4, top + 2), (fx + ((f + k) % 2) * 2 - 1, top - hgt), (fx + 4, top + 2)], fill=hexc("3ad860"))
        d.polygon([(fx - 2, top + 2), (fx, top - hgt + 4), (fx + 2, top + 2)], fill=hexc("c8ffb0"))


def aura(img, color, width=2):
    """Hào quang tà khí: 2 lớp viền ngoài trong suốt dần."""
    w, h = img.size
    src = img.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o = out.load()
    for layer in range(width, 0, -1):
        a = int(150 / layer)
        for y in range(h):
            for x in range(w):
                if src[x, y][3] > 0:
                    continue
                near = False
                for dy in range(-layer - 1, layer + 2):
                    for dx in range(-layer - 1, layer + 2):
                        nx, ny = x + dx, y + dy
                        if abs(dx) + abs(dy) <= layer + 1 and 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200:
                            near = True
                            break
                    if near:
                        break
                if near and o[x, y][3] == 0:
                    o[x, y] = color[:3] + (a,)
    out.alpha_composite(img)
    return out


def demon_sheet(boss_id, fw, fh, n):
    cfg = DEMON[boss_id]
    src = Image.open(os.path.join(OUT, "enemies/boss_%s.png" % boss_id)).convert("RGBA")
    frames = []
    for i in range(n):
        fr = src.crop((i * fw, 0, (i + 1) * fw, fh))
        # gỡ viền cũ để viền lại sau khi phóng to
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
        pad = aura(pad, hexc(cfg["aura"]))
        frames.append(pad)
    W, H = frames[0].size
    sheet = Image.new("RGBA", (W * n, H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * W, 0))
    save(sheet, "enemies/boss_%s_2.png" % boss_id)
    return W, H


def build():
    sizes = {}
    for b in DEMON:
        if b == "tau_hy_vong":
            sizes[b] = demon_sheet(b, 64, 44, 7)
        else:
            sizes[b] = demon_sheet(b, 48, 48, 7)
    return sizes


if __name__ == "__main__":
    print(build())
