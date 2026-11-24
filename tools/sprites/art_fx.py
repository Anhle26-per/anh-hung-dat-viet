"""Hiệu ứng: nhát chém, nổ, khói, đạn, vật phẩm, cổng, cọc Bạch Đằng, hào quang, trống đồng."""
import math
import random
from px import hexc, grid, outline, sheet, save, canvas, auto_shade, Image, ImageDraw

WHITE = (255, 255, 255, 255)


def _blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def _pp(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((int(x), int(y)), c)


# ---------------------------------------------------------------- Nhát chém hình lưỡi liềm (màu trắng, game tô màu theo vũ khí)
def slash_frames():
    S = 48
    c = S / 2
    frames = []
    half = math.radians(80)
    for f in range(4):
        img = _blank(S, S)
        prog = [0.45, 0.85, 1.0, 1.0][f]
        fade = [1.0, 1.0, 0.75, 0.4][f]
        thin = [1.0, 1.0, 0.8, 0.5][f]
        for y in range(S):
            for x in range(S):
                dx, dy = x + 0.5 - c, y + 0.5 - c
                r = math.hypot(dx, dy)
                a = math.atan2(dy, dx)
                # quét từ trên (-half) xuống dưới (+half)
                t = (a + half) / (2 * half)
                if t < 0 or t > prog:
                    continue
                k = math.sin(math.pi * min(1, t / max(prog, 0.01)))
                outer = 21
                thick = 8 * k * thin
                inner = outer - thick
                if inner <= r <= outer and thick >= 1:
                    edge = (r - inner) / max(thick, 1)
                    lead = t / max(prog, 0.01)
                    if edge > 0.65:
                        alpha = 255
                    elif edge > 0.3:
                        alpha = 190
                    else:
                        alpha = 110
                    alpha = int(alpha * fade * (0.55 + 0.45 * lead))
                    col = (255, 255, 255, alpha) if edge > 0.5 else (215, 230, 255, alpha)
                    img.putpixel((x, y), col)
        frames.append(img)
    save(sheet(frames), "fx/slash.png")


def thrust_frames():
    frames = []
    for f in range(4):
        img = _blank(48, 12)
        length = [26, 40, 44, 44][f]
        fade = [1.0, 1.0, 0.7, 0.35][f]
        for x in range(length):
            k = x / length
            half = 1 + int(3 * math.sin(math.pi * min(1.0, k * 1.15)))
            for dy in range(-half, half + 1):
                a = 255 if abs(dy) < half - 1 else 150
                img.putpixel((x + 2, 6 + dy), (255, 255, 255, int(a * fade * (0.4 + 0.6 * k))))
        frames.append(img)
    save(sheet(frames), "fx/thrust.png")


def spark_frames():
    frames = []
    for f in range(4):
        img = _blank(15, 15)
        r = [3, 6, 5, 3][f]
        col = [WHITE, hexc("fff4b0"), hexc("ffd060"), hexc("ff9a40", 200)][f]
        for i in range(-r, r + 1):
            _pp(img, 7 + i, 7, col)
            _pp(img, 7, 7 + i, col)
        if f >= 1:
            d = r - 2
            for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
                _pp(img, 7 + sx * d, 7 + sy * d, col)
        if f < 2:
            _pp(img, 7, 7, WHITE)
        frames.append(img)
    save(sheet(frames), "fx/spark.png")


def explosion_frames():
    rng = random.Random(3)
    S = 44
    frames = []
    jag = [rng.uniform(-2, 2) for _ in range(36)]
    for f in range(7):
        img = _blank(S, S)
        d = ImageDraw.Draw(img)
        c = S // 2
        if f <= 3:
            r = [6, 11, 15, 17][f]
            layers = [(r, hexc("e8402a")), (r * 0.78, hexc("ff8a2a")), (r * 0.5, hexc("ffd84a")), (r * 0.25, WHITE)]
            if f == 0:
                layers = [(r, WHITE)]
            for rr, col in layers:
                pts = []
                for i in range(36):
                    a = i / 36 * math.tau
                    j = jag[i] if f >= 2 else 0
                    pts.append((c + math.cos(a) * (rr + j), c + math.sin(a) * (rr + j)))
                d.polygon(pts, fill=col)
        else:
            k = f - 4
            for i in range(7):
                a = i / 7 * math.tau + k * 0.4
                dist = 8 + k * 5
                rr = [6, 5, 3][k]
                x, y = c + math.cos(a) * dist, c + math.sin(a) * dist - k * 2
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=[hexc("6a5a6e"), hexc("8a7c90", 200), hexc("aa9cb0", 130)][k])
                d.ellipse([x - rr + 1, y - rr + 1, x + rr - 2, y + rr - 2], fill=[hexc("9a8aa0"), hexc("b0a2b6", 200), hexc("c8bcd0", 130)][k])
        frames.append(img)
    save(sheet(frames), "fx/explosion.png")


def poof_frames():
    frames = []
    for f in range(5):
        img = _blank(28, 28)
        d = ImageDraw.Draw(img)
        alpha = [255, 255, 220, 150, 80][f]
        for i in range(6):
            a = i / 6 * math.tau + 0.3
            dist = 3 + f * 3
            r = [4, 5, 5, 4, 3][f]
            x, y = 14 + math.cos(a) * dist, 14 + math.sin(a) * dist - f
            d.ellipse([x - r, y - r, x + r, y + r], fill=(196, 186, 210, alpha))
            d.ellipse([x - r + 1, y - r, x + r - 1, y + r - 2], fill=(236, 232, 244, alpha))
        frames.append(img)
    save(sheet(frames), "fx/poof.png")


def dust_frames():
    frames = []
    for f in range(4):
        img = _blank(10, 10)
        d = ImageDraw.Draw(img)
        r = [2, 3, 4, 3][f]
        a = [230, 200, 140, 70][f]
        d.ellipse([5 - r, 6 - r - f // 2, 5 + r, 6 + r - f // 2], fill=(200, 180, 150, a))
        d.point([5 - r + 1, 6 - r], fill=(236, 222, 196, a))
        frames.append(img)
    save(sheet(frames), "fx/dust.png")


# ---------------------------------------------------------------- Đạn
def projectiles():
    # mũi tên
    arrow = grid([
        "RR..........",
        ".RRooooooomn",
        "RR.......M",
    ], {"R": hexc("e04848"), "o": hexc("9a6234"), "m": hexc("d8dce8"), "M": hexc("8a92ac"), "n": WHITE})
    save(outline(arrow), "fx/arrow.png")
    # cầu lửa (hỏa hổ) 3 khung
    fr = []
    for f in range(3):
        img = _blank(12, 10)
        d = ImageDraw.Draw(img)
        wob = [0, 1, -1][f]
        d.ellipse([4, 2, 10, 8], fill=hexc("ff6a20"))
        d.polygon([(5, 2 + wob), (0, 5), (5, 8 - wob)], fill=hexc("e8402a"))
        d.ellipse([5, 3, 9, 7], fill=hexc("ffb040"))
        d.rectangle([7, 4, 8, 5], fill=hexc("fff4b0"))
        fr.append(img)
    save(sheet(fr), "fx/fireball.png")
    # tên lửa (hỏa tiễn) 2 khung
    fr = []
    for f in range(2):
        img = grid([
            "......RRRR",
            "..ooooooooommn",
            "......RRRR",
        ], {"R": hexc("c43c3c"), "o": hexc("7a4622"), "m": hexc("d8dce8"), "n": WHITE}, 16)
        img = outline(img)
        d = ImageDraw.Draw(img)
        d.point([1, 2], fill=hexc("ffd84a"))
        d.point([0, 2 + (f * 2 - 1)], fill=hexc("ff8a2a"))
        fr.append(img)
    save(sheet(fr), "fx/rocket.png")
    # đạn thần cơ
    img, d = canvas(9, 9)
    d.ellipse([1, 1, 7, 7], fill=hexc("4a4458"))
    d.rectangle([3, 2, 4, 3], fill=hexc("9a94b0"))
    d.point([3, 2], fill=WHITE)
    save(outline(img), "fx/cannonball.png")
    # đạn yêu khí (quái) + đạn nước (trùm) 2 khung
    for name, outer, mid in (("orb_pink", hexc("c8287a"), hexc("ff6ab0")), ("orb_water", hexc("1e6ad0"), hexc("62c8ff"))):
        fr = []
        for f in range(2):
            img, d = canvas(11, 11)
            r = 4 if f == 0 else 5
            d.ellipse([5 - r, 5 - r, 5 + r, 5 + r], fill=outer[:3] + (150,))
            d.ellipse([2, 2, 8, 8], fill=outer)
            d.ellipse([3, 3, 7, 7], fill=mid)
            d.rectangle([4, 4, 5, 5], fill=WHITE)
            fr.append(img)
        save(sheet(fr), f"fx/{name}.png")


# ---------------------------------------------------------------- Vật phẩm
def pickups():
    gold, gold_l, gold_d = hexc("e8b04a"), hexc("fff0a0"), hexc("a86a2a")
    # đồng xu cổ có lỗ vuông, xoay 4 khung
    fr = []
    for f, w in enumerate((7, 5, 2, 5)):
        img, d = canvas(9, 9)
        x0 = 4 - w // 2
        d.ellipse([x0, 1, x0 + w, 7], fill=gold)
        if w >= 5:
            d.rectangle([3, 3, 5, 5], fill=gold_d)
            d.point([4, 4], fill=(0, 0, 0, 0))
            d.point([x0 + 1, 2], fill=gold_l)
        elif w >= 2:
            d.line([4, 1, 4, 7], fill=gold_l)
        fr.append(outline(img))
    save(sheet(fr), "items/coin.png")
    # tinh thể năng lượng
    fr = []
    for f in range(4):
        img = grid([
            "...c...",
            "..cCc..",
            ".cwCCc.",
            ".cwCCd.",
            "cwCCCdd",
            ".cCCdd.",
            ".cCdd..",
            "..cd...",
            "...d...",
        ], {"c": hexc("62c8ff"), "C": hexc("2a8ae0"), "d": hexc("1a4ea8"), "w": WHITE if f != 2 else hexc("a8e8ff")}, 7)
        if f == 1:
            img.putpixel((2, 2), WHITE)
            img.putpixel((3, 1), WHITE)
        fr.append(outline(img))
    save(sheet(fr), "items/energy.png")
    # bầu hồ lô thuốc đỏ
    img = grid([
        "...oo...",
        "...OO...",
        "..rrrr..",
        "..rwrR..",
        "...rR...",
        ".rrrrrr.",
        "rrwrrrRR",
        "rwrrrrRR",
        "rrrrrRRR",
        ".rrrRRR.",
        "..RRRR..",
    ], {"o": hexc("9a6234"), "O": hexc("5e3a20"), "r": hexc("e04848"), "R": hexc("8e2632"), "w": hexc("ffb0b0")}, 8)
    save(outline(img), "items/potion.png")
    # rương sơn mài đỏ viền vàng: đóng / mở
    pal = {"r": hexc("b8323a"), "R": hexc("7a1e2c"), "l": hexc("e8605a"), "g": gold, "G": gold_d, "y": gold_l,
           "k": hexc("2a1428"), "Y": hexc("fff4c0")}
    closed = grid([
        "",
        "..gggggggggggggg",
        ".glllllllllllllRg",
        ".grrrrrrrrrrrrrRg",
        ".grrrrrryyrrrrrRg",
        ".gGGGGGGygGGGGGGg",
        ".grrrrrrGGrrrrrRg",
        ".grrrrrrrrrrrrrRg",
        ".grrrrrrrrrrrrrRg",
        ".gRRRRRRRRRRRRRRg",
        ".gggggggggggggggg",
    ], pal, 18)
    opened = grid([
        "..gggggggggggggg",
        ".gRRRRRRRRRRRRRRg",
        ".gkkkkkkkkkkkkkkg",
        ".gkYYyYYYyYYkkkkg",
        ".gGGGGGGGGGGGGGGg",
        ".grrrrrrGGrrrrrRg",
        ".grrrrrrrrrrrrrRg",
        ".grrrrrrrrrrrrrRg",
        ".grrrrrrrrrrrrrRg",
        ".gRRRRRRRRRRRRRRg",
        ".gggggggggggggggg",
    ], pal, 18)
    save(sheet([outline(closed), outline(opened)]), "items/chest.png")


# ---------------------------------------------------------------- Cổng dịch chuyển
def portal_frames():
    S = 44
    c = S / 2
    frames = []
    cols = [hexc("1a3a8a"), hexc("2a6ad0"), hexc("4aa8ff"), hexc("9ae0ff"), WHITE]
    for f in range(8):
        img = _blank(S, S)
        rot = f / 8 * math.tau
        for y in range(S):
            for x in range(S):
                dx, dy = (x + 0.5 - c), (y + 0.5 - c) * 1.25
                r = math.hypot(dx, dy)
                if r > 19:
                    continue
                a = math.atan2(dy, dx)
                swirl = math.sin(a * 3 + r * 0.45 - rot * 3)
                if r > 16:
                    idx = 1 if swirl > 0 else 0
                elif r < 4:
                    idx = 4
                else:
                    v = swirl * 0.5 + 0.5 + (1 - r / 16) * 0.8
                    idx = min(4, max(0, int(v * 3)))
                img.putpixel((x, y), cols[idx])
        # tia sáng li ti
        rng = random.Random(f)
        for _ in range(4):
            a = rng.random() * math.tau
            r = rng.uniform(17, 21)
            _pp(img, c + math.cos(a) * r, c + math.sin(a) * r / 1.25, hexc("bff0ff"))
        frames.append(outline(img))
    save(sheet(frames), "fx/portal.png")


# ---------------------------------------------------------------- Cọc Bạch Đằng + sóng nước
def stake_frames():
    wood, wood_l, wood_d = hexc("8a5a32"), hexc("b8844e"), hexc("4e3018")
    iron, iron_l = hexc("8a92ac"), hexc("e8ecf4")
    water, foam = hexc("4aa8e0", 220), hexc("dff4ff", 230)
    frames = []
    for f in range(6):
        img, d = canvas(14, 26)
        h = [4, 11, 18, 18, 18, 9][f]   # chiều cao lộ lên khỏi mặt nước
        base = 22
        top = base - h
        if h > 3:
            d.rectangle([5, top + 3, 8, base], fill=wood)
            auto_shade(img, wood, wood_l, wood_d)
            d.line([5, top + 7, 8, top + 7], fill=hexc("c8a870")) if h > 8 else None
            d.line([5, top + 8, 8, top + 8], fill=hexc("8a6a3a")) if h > 8 else None
        d.polygon([(5, top + 3), (8, top + 3), (6.5, top)], fill=iron)
        d.point([6, top + 1], fill=iron_l)
        img = outline(img)
        d = ImageDraw.Draw(img)
        # vòng nước bắn lên quanh chân cọc
        sp = [3, 5, 6, 5, 4, 5][f]
        d.ellipse([7 - sp, base - 1, 7 + sp, base + 2], outline=water)
        if f in (0, 1, 5):
            for dx in (-sp, sp):
                d.point([7 + dx, base - 3], fill=foam)
                d.point([7 + dx // 2, base - 4 - f % 2], fill=foam)
        frames.append(img)
    save(sheet(frames), "fx/stake.png")


def ripple_frames():
    frames = []
    for f in range(5):
        img, d = canvas(72, 34)
        for k, (rx, a) in enumerate(((8 + f * 7, 255), (4 + f * 6, 170))):
            ry = rx * 0.45
            d.ellipse([36 - rx, 17 - ry, 36 + rx, 17 + ry], outline=(120, 200, 255, int(a * (1 - f / 5))))
        frames.append(img)
    save(sheet(frames), "fx/ripple.png")


# ---------------------------------------------------------------- Hào quang Thần tốc (vàng, có tia điện)
def aura_frames():
    S = 40
    frames = []
    for f in range(4):
        img, d = canvas(S, S)
        rng = random.Random(f * 11)
        rx, ry = 15 + f % 2, 7
        d.ellipse([20 - rx, 30 - ry, 20 + rx, 30 + ry], outline=hexc("ffd84a", 230))
        d.ellipse([20 - rx + 3, 30 - ry + 2, 20 + rx - 3, 30 + ry - 2], outline=hexc("fff0a0", 120))
        for _ in range(4):
            a = rng.random() * math.tau
            x, y = 20 + math.cos(a) * rx, 30 + math.sin(a) * ry
            for k in range(rng.randint(4, 8)):
                _pp(img, x, y, hexc("fff8c0"))
                x += rng.choice((-1, 0, 1))
                y -= 1
        frames.append(img)
    save(sheet(frames), "fx/aura.png")


# ---------------------------------------------------------------- Mặt trống đồng Đông Sơn
def drum(size=64, bright=True, rel="fx/drum.png"):
    img = _blank(size, size)
    c = size / 2
    if bright:
        base, mid, hi, dark = hexc("e8b04a"), hexc("c4803e"), hexc("fff0a0"), hexc("7a4622")
    else:
        base, mid, hi, dark = hexc("6a5a52", 160), hexc("5a4a44", 160), hexc("8a7a6a", 170), hexc("3a302c", 160)
    R = size / 2 - 1
    for y in range(size):
        for x in range(size):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            r = math.hypot(dx, dy)
            if r > R:
                continue
            a = math.atan2(dy, dx)
            ring = r / R
            col = None
            # ngôi sao nhiều cánh ở giữa
            if ring < 0.22:
                star = 0.12 + 0.10 * (0.5 + 0.5 * math.cos(a * 12))
                col = hi if ring < star else mid
            elif ring < 0.26 or 0.47 < ring < 0.5 or 0.73 < ring < 0.76 or ring > 0.95:
                col = dark
            elif ring < 0.47:
                # vành vạch chéo
                col = base if int((a / math.tau) * 48 + ring * 6) % 2 == 0 else mid
            elif ring < 0.73:
                # vành chim Lạc bay (vệt sáng ngắn)
                seg = (a / math.tau * 8) % 1
                col = hi if 0.2 < seg < 0.5 and 0.55 < ring < 0.66 else base
            else:
                col = mid if int(a / math.tau * 72) % 2 else base
            img.putpixel((x, y), col)
    save(img, rel)


# ---------------------------------------------------------------- Biểu tượng kỹ năng 20x20
def skill_icons():
    pal = {"o": hexc("9a6234"), "O": hexc("5e3a20"), "m": hexc("e8ecf4"), "M": hexc("8a92ac"),
           "b": hexc("4aa8e0"), "B": hexc("2a6ad0"), "w": WHITE,
           "a": hexc("9a9ab0"), "A": hexc("5e5e7a"), "i": hexc("f4ecd8"), "e": hexc("1a1222"),
           "r": hexc("c43c3c"), "g": hexc("e8b04a"), "G": hexc("a86a2a"), "y": hexc("fff0a0"),
           "z": hexc("c4803e"), "Z": hexc("7a4622")}
    icons = {
        "song_trung": [
            "...m..........m.....",
            "...mm........mm.....",
            "....mm......mm......",
            ".....mm....mm.......",
            "......mm..mm........",
            ".......mmmm.........",
            "........gg..........",
            ".......mmmm.........",
            "......gm..mg........",
            ".....gg....gg.......",
            "....rr......rr......",
            "...rr........rr.....",
        ],
        "nam_quoc_son_ha": [
            "..oooooooooooooooo..",
            ".oOyyyyyyyyyyyyyyOo.",
            "..yyrryyrryyrryyyy..",
            "..yyyyyyyyyyyyyyyy..",
            "..yrryyrryyrryyrry..",
            "..yyyyyyyyyyyyyyyy..",
            "..yyrryyrryyrryyyy..",
            "..yyyyyyyyyyyyyyyy..",
            "..yrryyrryyrryyrry..",
            ".oOyyyyyyyyyyyyyyOo.",
            "..oooooooooooooooo..",
        ],
        "thuan_thien_kiem": [
            ".........yy.........",
            "........ymmy........",
            "........ymmy........",
            "........ymmy........",
            "........ymmy........",
            "........ymmy........",
            "........ymmy........",
            "........ymmy........",
            "......ggggggg.......",
            "........bOb.........",
            "........OOO.........",
            ".........g..........",
        ],
        "hoa_hong": [
            ".........r..........",
            "........rgr.........",
            ".......rgygr........",
            "......rgyyygr.......",
            ".....rrgyyygrr......",
            "......rggyggr.......",
            "....OOOOOOOOOOO.....",
            "...OoooooooooooO....",
            "....OoooooooooO.....",
            ".bbbbbbbbbbbbbbbbbb.",
            "bwbbbbbwbbbbbbwbbbbb",
        ],
        "hum_thieng": [
            "...gg..........gg...",
            "..gzzg........gzzg..",
            "..gggggggggggggggg..",
            ".ggOgggOggggOgggOgg.",
            ".gggwwgggggggwwgggg.",
            ".ggwegggOOgggewgggg.",
            ".gggggggOOgggggggg..",
            "..ggOggwwwwggOggg...",
            "...ggggwOOwggggg....",
            "....gggggggggg......",
            "......gggggg........",
        ],
        "keo_phao": [
            "..............MMM...",
            "...........MMMMMMM..",
            "........MMMMMMMM....",
            ".....MMMMMMMMM......",
            "...oMMMMMMM.........",
            "..oooMMM............",
            ".ooooo..............",
            "..OOO...............",
            ".OoooO..............",
            ".OoOoO..............",
            ".OoooO..............",
            "..OOO...............",
        ],
        "coc_bach_dang": [
            "....m.....m.....m...",
            "...mMm...mMm...mMm..",
            "...oOo...oOo...oOo..",
            "...oOo...oOo...oOo..",
            "...oOo...oOo...oOo..",
            "...oOo...oOo...oOo..",
            "...oOo...oOo...oOo..",
            "...oOo...oOo...oOo..",
            "..boOob.boOob.boOob.",
            ".bbbbbbbbbbbbbbbbbbb",
            "bwbbbbwbbbbbwbbbbbwb",
            "bbbBbbbbbBbbbbbBbbbb",
            ".BBBBBBBBBBBBBBBBBB.",
        ],
        "voi_chien": [
            "......aaaaaa........",
            "....aaaaaaaaaa......",
            "...aaAAaaaaaaaa.....",
            "..aaAAAAaaaaaeaa....",
            "..aAAAAAaaaaaaaaa...",
            "..aAAAAAaaaaaaaaa...",
            "..aAAAAaaaaaaaaaa...",
            "...aAAaaaaaaiiiiaa..",
            "....aaaaaaaaa...aa..",
            ".......aaaaa.....aa.",
            ".......aaaa......aa.",
            ".......aa.......aa..",
            "................a...",
        ],
        "hich_tuong_si": [
            "......gggggggg......",
            "....ggyyyyyyyygg....",
            "...gyzzzzzzzzzzyg...",
            "..gyzzZzzggzzZzzyg..",
            "..gyzzzzgyygzzzzyg..",
            "..gyzzZzzggzzZzzyg..",
            "...gyzzzzzzzzzzyg...",
            "....ggyyyyyyyygg....",
            "....GzGzGzGzGzGG....",
            "....GzGzGzGzGzGG....",
            "....GGGGGGGGGGGG....",
        ],
        "than_toc": [
            "...........yyy......",
            "..........yyy.......",
            ".........yyy........",
            "........yyyyyyy.....",
            ".............yy.....",
            "............yy......",
            "...........yy.......",
            "..........yy........",
            ".........y..........",
            "....rrrrr...........",
            "...rrrrrrgg.........",
            "...OOOOOOOO.........",
        ],
    }
    for k, rows in icons.items():
        img = Image.new("RGBA", (22, 22), (0, 0, 0, 0))
        g = grid(rows, pal, 20)
        img.alpha_composite(g, (1, (22 - g.height) // 2))
        save(outline(img), f"ui/skill_{k}.png")


def misc():
    # bóng dưới chân
    img, d = canvas(16, 6)
    d.ellipse([0, 0, 15, 5], fill=(0, 0, 0, 90))
    d.ellipse([3, 1, 12, 4], fill=(0, 0, 0, 120))
    save(img, "fx/shadow.png")
    # ánh sáng: các vòng tròn đồng tâm (kiểu pixel, có bậc)
    S = 128
    img = _blank(S, S)
    for y in range(S):
        for x in range(S):
            r = math.hypot(x + 0.5 - S / 2, y + 0.5 - S / 2) / (S / 2)
            if r < 1:
                v = (1 - r) ** 1.8
                img.putpixel((x, y), (255, 255, 255, int(255 * v)))
    save(img, "fx/light.png")


def more_projectiles():
    # đá (ná)
    img, d = canvas(7, 7)
    d.ellipse([1, 1, 5, 5], fill=hexc("8a8478"))
    d.point([2, 2], fill=hexc("c8c2b4"))
    save(outline(img), "fx/stone.png")
    # phi tiêu
    img = grid(["r.....", ".mmmmn", "r....."], {"r": hexc("e04848"), "m": hexc("b8c0d4"), "n": WHITE})
    save(outline(img), "fx/dart.png")
    # đạn súng (vệt vàng)
    img = grid(["yyyyw", "Gyyyw"], {"y": hexc("ffd84a"), "G": hexc("e8902a"), "w": WHITE})
    save(img, "fx/bullet.png")
    img = grid([".y.", "ywy", ".y."], {"y": hexc("ffd84a"), "w": WHITE})
    save(img, "fx/pellet.png")
    # lựu đạn
    fr = []
    for f in range(4):
        img, d = canvas(9, 9)
        d.ellipse([1, 1, 7, 7], fill=hexc("5a6a3a"))
        d.point([2 + f % 2, 2], fill=hexc("8e9e56"))
        d.rectangle([3 + (f == 1), 0, 5 - (f == 3), 1], fill=hexc("8a92ac"))
        fr.append(outline(img))
    save(sheet(fr), "fx/grenade.png")
    # cầu plasma tím
    fr = []
    for f in range(2):
        img, d = canvas(11, 11)
        r = 5 if f else 4
        d.ellipse([5 - r, 5 - r, 5 + r, 5 + r], fill=hexc("a050e0", 140))
        d.ellipse([2, 2, 8, 8], fill=hexc("c070ff"))
        d.ellipse([3, 3, 7, 7], fill=hexc("e8c0ff"))
        d.point([4, 4], fill=WHITE)
        fr.append(img)
    save(sheet(fr), "fx/plasma.png")
    # sóng kiếm (Thuận Thiên, Rồng Tiên) - trăng lưỡi liềm bay
    fr = []
    for f in range(2):
        img = _blank(14, 22)
        for y in range(22):
            for x in range(14):
                dx, dy = x - 2, y - 10.5
                r = math.hypot(dx, dy)
                if 8 + f * 0.5 < r < 11.5 and dx > 0:
                    a = 255 if r > 10 else 170
                    img.putpixel((x, y), (255, 255, 255, a))
        fr.append(img)
    save(sheet(fr), "fx/sword_wave.png")
    # lửa đầu nòng 3 khung
    fr = []
    for f in range(3):
        img, d = canvas(12, 10)
        if f < 2:
            r = 4 - f
            d.polygon([(0, 5), (6, 5 - r), (11 - f * 3, 5), (6, 5 + r)], fill=hexc("ffb040"))
            d.polygon([(0, 5), (5, 4), (8 - f * 2, 5), (5, 6)], fill=hexc("fff4b0"))
        else:
            d.ellipse([2, 2, 8, 8], fill=(200, 190, 210, 150))
        fr.append(img)
    save(sheet(fr), "fx/muzzle.png")


def new_skill_fx():
    # hổ thần (Hùm thiêng Yên Thế) 4 khung
    org, org_l, org_d = hexc("f08a2a"), hexc("ffbe6a"), hexc("a8501a")
    fr = []
    for f in range(4):
        img, d = canvas(40, 24)
        lift = [0, 1, 0, 1][f]
        lo = [(0, 2), (1, 1), (2, 0), (1, 1)][f]
        for x, ph in ((8, 0), (13, 1), (25, 0), (30, 1)):
            d.rectangle([x, 15 - lift, x + 3, 21 - lo[ph]], fill=org_d if ph else org)
        d.ellipse([4, 7 - lift, 32, 18 - lift], fill=org)
        d.ellipse([27, 3 - lift, 38, 14 - lift], fill=org)
        auto_shade(img, org, org_l, org_d)
        for x in range(9, 30, 4):
            d.line([x, 8 - lift, x + 1, 13 - lift], fill=hexc("2a1414"))
        d.line([(5, 10 - lift), (1, 5 - lift), (0, 2 - lift)], fill=org_d, width=2)
        d.polygon([(28, 4 - lift), (30, 0 - lift), (32, 4 - lift)], fill=org)
        d.polygon([(33, 4 - lift), (35, 0 - lift), (37, 4 - lift)], fill=org)
        d.ellipse([33, 9 - lift, 38, 13 - lift], fill=hexc("fff4e0"))
        d.point([34, 7 - lift], fill=hexc("2a1414"))
        d.point([36, 7 - lift], fill=hexc("ffe040"))
        d.line([(31, 5 - lift), (31, 8 - lift)], fill=hexc("2a1414"))
        d.line([(36, 12 - lift), (38, 12 - lift)], fill=hexc("2a1414"))
        fr.append(outline(img))
    save(sheet(fr), "fx/tiger.png")
    # khẩu pháo dã chiến (Kéo pháo vào trận) 2 khung: thường / giật
    fr = []
    for f in range(2):
        img, d = canvas(30, 20)
        back = 2 if f else 0
        d.polygon([(4, 16), (12, 8), (15, 10), (8, 17)], fill=hexc("5a5a2e"))
        d.line([(10 - back, 9), (27 - back, 4)], fill=hexc("6a6a3a"), width=4)
        d.line([(24 - back, 5), (28 - back, 4)], fill=hexc("4a4a26"), width=5)
        auto_shade(img, hexc("6a6a3a"), hexc("9a9a5a"), hexc("3a3a1e"))
        d.ellipse([9, 10, 19, 19], fill=hexc("6a4028"))
        d.ellipse([12, 13, 16, 16], fill=hexc("3e2416"))
        d.rectangle([2, 15, 9, 17], fill=hexc("4a4a26"))
        fr.append(outline(img))
    save(sheet(fr), "fx/turret.png")
    # bầu lửa (Hỏa hồng Nhật Tảo)
    img, d = canvas(10, 11)
    d.ellipse([1, 3, 8, 10], fill=hexc("9a5a2e"))
    d.rectangle([4, 1, 5, 3], fill=hexc("6a3a1e"))
    d.point([4, 0], fill=hexc("ffb040"))
    d.point([5, 0], fill=hexc("ff6a20"))
    d.point([3, 5], fill=hexc("c8844e"))
    save(outline(img), "fx/fire_pot.png")


def build():
    slash_frames()
    thrust_frames()
    spark_frames()
    explosion_frames()
    poof_frames()
    dust_frames()
    projectiles()
    more_projectiles()
    pickups()
    portal_frames()
    stake_frames()
    ripple_frames()
    aura_frames()
    drum(64, True, "fx/drum.png")
    drum(64, False, "world/drum_floor.png")
    drum(20, True, "ui/skill_hich_tuong_si_raw.png")
    skill_icons()
    new_skill_fx()
    misc()


if __name__ == "__main__":
    build()
