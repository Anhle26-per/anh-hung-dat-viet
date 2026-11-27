"""Thư viện nhỏ để vẽ pixel art bằng code.

- Vẽ tay: mô tả hình bằng lưới ký tự, mỗi ký tự là một màu trong bảng màu.
- Vẽ thủ tục: dùng ImageDraw của Pillow (không khử răng cưa nên giữ được nét pixel).
- Tự thêm viền tối, tự đổ bóng theo hướng sáng từ trên-trái.
"""
import os
from PIL import Image, ImageDraw

OUTLINE = (24, 16, 30, 255)
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREVIEW = os.environ.get("PREVIEW_DIR", "")


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def shade(c, k):
    """k > 0 sáng hơn (ngả vàng), k < 0 tối hơn (ngả tím)."""
    r, g, b, a = c
    if k >= 0:
        r, g, b = r + (255 - r) * k, g + (245 - g) * k, b + (200 - b) * k * 0.8
    else:
        k = -k
        r, g, b = r * (1 - k) + 40 * k * 0.3, g * (1 - k), b * (1 - k) + 70 * k * 0.4
    return (int(max(0, min(255, r))), int(max(0, min(255, g))), int(max(0, min(255, b))), a)


def grid(rows, pal, w=None):
    """Lưới ký tự -> ảnh RGBA. '.' hoặc ' ' là trong suốt."""
    w = w or max(len(r) for r in rows)
    img = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        assert len(row) <= w, f"Hàng {y} dài {len(row)} > {w}: {row!r}"
        for x, ch in enumerate(row):
            if ch in ". ":
                continue
            if ch not in pal:
                raise KeyError(f"Ký tự {ch!r} không có trong bảng màu (hàng {y}: {row!r})")
            img.putpixel((x, y), pal[ch])
    return img


SELECTIVE = True   # viền màu theo vật thể (kiểu họa sĩ pixel chuyên nghiệp)


def _sel(c):
    """Màu viền = màu kề bên pha tối về tím than."""
    k = 0.32
    return (int(c[0] * k + OUTLINE[0] * (1 - k)), int(c[1] * k + OUTLINE[1] * (1 - k)),
            int(c[2] * k + OUTLINE[2] * (1 - k)), 255)


def outline(img, color=OUTLINE, diagonal=False):
    """Thêm viền 1 pixel quanh các vùng có màu.
    Viền mặc định (color=OUTLINE) dùng màu theo vật thể; truyền màu khác để viền 1 màu."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diagonal:
        nb += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in nb:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200 and src[nx, ny] != color:
                    dst[x, y] = _sel(src[nx, ny]) if (SELECTIVE and color == OUTLINE) else color
                    break
    return out


def auto_shade(img, base, light, dark, mask_color=None):
    """Đổ bóng cho các pixel có màu `base`: cạnh trên-trái sáng, cạnh dưới-phải tối."""
    w, h = img.size
    px = img.load()
    src = img.copy().load()

    def same(x, y):
        return 0 <= x < w and 0 <= y < h and src[x, y] == base

    for y in range(h):
        for x in range(w):
            if src[x, y] != base:
                continue
            br = not same(x + 1, y) or not same(x, y + 1)
            tl = not same(x - 1, y) or not same(x, y - 1)
            if br and not tl:
                px[x, y] = dark
            elif tl and not br:
                px[x, y] = light


def paste(dst, src, x, y):
    dst.alpha_composite(src, (x, y))


def flip(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def sheet(frames):
    """Ghép các khung hình thành 1 hàng ngang."""
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.alpha_composite(f, (i * w, 0))
    return s


def sheet_grid(frames, cols=12):
    """Ghép các khung hình cùng kích thước thành lưới nhiều hàng (tối đa `cols` cột)."""
    if not frames:
        raise ValueError("frames không được rỗng")
    cols = max(1, int(cols))
    w, h = frames[0].size
    actual_cols = min(cols, len(frames))
    rows = (len(frames) + actual_cols - 1) // actual_cols
    s = Image.new("RGBA", (w * actual_cols, h * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        col = i % actual_cols
        row = i // actual_cols
        s.alpha_composite(f, (col * w, row * h))
    return s


def save(img, rel):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    if PREVIEW:
        p = os.path.join(PREVIEW, rel.replace("/", "_"))
        scale = 6 if img.width * 6 <= 1800 else max(1, 1800 // img.width)
        bg = Image.new("RGBA", img.size, (70, 66, 80, 255))
        bg.alpha_composite(img)
        bg.resize((img.width * scale, img.height * scale), Image.NEAREST).save(p)
    return path


def canvas(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def polish(img, rim=0.24, shadow=0.26, contrast=0.12, region=0.14, texture=True):
    """Bước hoàn thiện cho nhân vật (học kỹ thuật chung của pixel art chibi):
    - tăng tương phản để màu nhấn nổi hơn;
    - mỗi mảng màu có khối riêng: mép trên mảng sáng, mép dưới mảng tối,
      chỗ hai mảng tương phản gặp nhau có nét chia vùng tối;
    - viền sáng mép trên-trái hình, bóng mép dưới-phải, nửa dưới thân tối dần;
    - mảng màu lớn và phẳng được rắc chút vân (lông, vải) cho đỡ trơn;
    - viền ngoài gần đen để hình đọc rõ trên mọi nền."""
    w, h = img.size
    src = img.copy().load()
    px = img.load()

    def solid(x, y):
        return 0 <= x < w and 0 <= y < h and src[x, y][3] > 200

    def g(x, y):
        return src[x, y] if 0 <= x < w and 0 <= y < h else (0, 0, 0, 0)

    def diff(a, b):
        return abs(_lum(a) - _lum(b)) + 0.35 * (abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])) / 3

    ys = [y for y in range(h) for x in range(w) if src[x, y][3] > 200]
    if not ys:
        return outline(img)
    top, bot = min(ys), max(ys)
    for y in range(h):
        for x in range(w):
            c = src[x, y]
            if c[3] <= 200:
                continue
            l = _lum(c)
            k = contrast * (1 if l > 110 else -1)
            c2 = shade(c, k * 0.6) if k > 0 else shade(c, k)
            edge_tl = not solid(x, y - 1) or not solid(x - 1, y)
            edge_br = not solid(x, y + 1) or not solid(x + 1, y)
            if edge_tl and not edge_br and l > 40:
                c2 = shade(c2, rim)
            elif edge_br and not edge_tl:
                c2 = shade(c2, -shadow)
            else:
                up = g(x, y - 1)
                dn = g(x, y + 1)
                d_up = diff(c, up)
                d_dn = diff(c, dn)
                if d_dn > 70 and _lum(dn) > l:
                    c2 = shade(c2, -0.32)          # nét chia vùng (phía tối)
                elif d_up > 22 and l > 35:
                    c2 = shade(c2, region)         # mép trên của mảng
                elif d_dn > 22:
                    c2 = shade(c2, -region)        # mép dưới của mảng
                elif texture and g(x - 1, y) == c and g(x + 1, y) == c and up == c and dn == c:
                    if ((x * 7 + y * 13) % 11 == 0) or ((x * 3 + y * 5) % 17 == 0):
                        c2 = shade(c2, -0.09)
            t = (y - top) / max(1, bot - top)
            if t > 0.6:
                c2 = shade(c2, -0.12 * (t - 0.6) / 0.4)
            px[x, y] = c2
    return outline(img, DARK_LINE)


def mix(c1, c2, t):
    """Pha màu tuyến tính giữa c1 và c2 theo tỉ lệ t (0..1)."""
    k = max(0.0, min(1.0, t))
    return (
        int(c1[0] + (c2[0] - c1[0]) * k),
        int(c1[1] + (c2[1] - c1[1]) * k),
        int(c1[2] + (c2[2] - c1[2]) * k),
        int(c1[3] + (c2[3] - c1[3]) * k) if len(c1) > 3 and len(c2) > 3 else 255,
    )


def hue_ramp(h):
    """Tạo dải 5 sắc độ pixel art (deep, dark, base, light, spec) có dịch chuyển tông màu tự nhiên:
    vùng tối ngả lạnh tím-chàm, vùng sáng ngả ấm vàng-kem."""
    b = hexc(h)
    deep = mix(shade(b, -0.52), (24, 14, 42, 255), 0.28)
    dark = mix(shade(b, -0.28), (36, 20, 56, 255), 0.14)
    light = mix(shade(b, 0.28), (255, 244, 198, 255), 0.16)
    spec = mix(shade(b, 0.52), (255, 252, 232, 255), 0.34)
    return deep, dark, b, light, spec


DARK_LINE = (16, 10, 20, 255)
