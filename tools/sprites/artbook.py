"""Xuất "sách tranh" pixel art: các trang PNG phóng to để xem / giới thiệu game.
   python3 tools/sprites/artbook.py   ->  docs/artbook/*.png
"""
import os
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SP = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(ROOT, "docs", "artbook")
FONT = os.path.join(ROOT, "assets", "fonts", "VT323-Regular.ttf")
BG = (28, 18, 26)
GOLD = (255, 205, 90)
CREAM = (240, 226, 205)
TIER = {1: (200, 200, 208), 2: (106, 208, 106), 3: (74, 168, 255), 4: (192, 112, 255), 5: (255, 176, 48)}


def font(size):
    return ImageFont.truetype(FONT, size)


def img(rel):
    return Image.open(os.path.join(SP, rel)).convert("RGBA")


def frames(rel, fw, fh=None):
    s = img(rel)
    fh = fh or s.height
    return [s.crop((i * fw, 0, i * fw + fw, fh)) for i in range(s.width // fw)]


def up(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


class Page:
    def __init__(self, title, subtitle, h=1400):
        self.im = Image.new("RGB", (1600, h), BG)
        self.d = ImageDraw.Draw(self.im)
        for y in range(0, h, 4):
            self.d.line([(0, y), (1600, y)], fill=(32, 20, 30))
        self.d.rectangle([12, 12, 1587, h - 13], outline=(170, 110, 45), width=3)
        self.d.rectangle([20, 20, 1579, h - 21], outline=(90, 55, 30), width=1)
        self.text((800, 52), title, 64, GOLD, center=True)
        self.text((800, 124), subtitle, 28, CREAM, center=True)
        self.y = 170

    def text(self, pos, t, size, color, center=False):
        f = font(size)
        x, y = pos
        if center:
            x -= self.d.textlength(t, font=f) / 2
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
            self.d.text((x + dx, y + dy), t, font=f, fill=(12, 6, 12))
        self.d.text((x, y), t, font=f, fill=color)

    def paste(self, im, x, y):
        self.im.paste(im, (int(x), int(y)), im)

    def save(self, name):
        os.makedirs(OUT, exist_ok=True)
        self.im = self.im.crop((0, 0, 1600, min(self.im.height, self.y + 40)))
        ImageDraw.Draw(self.im).rectangle([12, 12, 1587, self.im.height - 13], outline=(170, 110, 45), width=3)
        self.im.save(os.path.join(OUT, name))


HEROES = [
    ("hai_ba_trung", "Hai Bà Trưng", "Năm 40 - Mê Linh", "Kiếm đồng Mê Linh", "Song Trưng", "song_trung"),
    ("ba_trieu", "Bà Triệu", "Năm 248 - Núi Nưa", "Đoản đao", "Voi chiến", "voi_chien"),
    ("ngo_quyen", "Ngô Quyền", "Năm 938 - Bạch Đằng", "Giáo tre", "Cọc Bạch Đằng", "coc_bach_dang"),
    ("ly_thuong_kiet", "Lý Thường Kiệt", "Năm 1077 - Như Nguyệt", "Nỏ tay", "Nam quốc sơn hà", "nam_quoc_son_ha"),
    ("tran_hung_dao", "Trần Hưng Đạo", "Năm 1285 - Thăng Long", "Gươm lệnh", "Hịch tướng sĩ", "hich_tuong_si"),
    ("le_loi", "Lê Lợi", "Năm 1427 - Chi Lăng", "Côn Lam Sơn", "Gươm Thuận Thiên", "thuan_thien_kiem"),
    ("quang_trung", "Quang Trung", "Năm 1789 - Đống Đa", "Ống lửa", "Thần tốc", "than_toc"),
    ("nguyen_trung_truc", "Nguyễn Trung Trực", "Năm 1861 - Nhật Tảo", "Dao rựa", "Hỏa hồng Nhật Tảo", "hoa_hong"),
    ("hoang_hoa_tham", "Hoàng Hoa Thám", "Năm 1890 - Yên Thế", "Súng hỏa mai Yên Thế", "Hùm thiêng Yên Thế", "hum_thieng"),
    ("chien_si_dien_bien", "Chiến sĩ Điện Biên", "Năm 1954 - Điện Biên Phủ", "Súng trường bộ binh", "Kéo pháo vào trận", "keo_phao"),
]


def page_heroes():
    p = Page("10 VỊ TƯỚNG", "Khung 32x32 - thở 4 khung, đi 4 khung, trúng đòn 1 khung - vũ khí cơ bản riêng", 2300)
    for hid, name, era, wpn, skill, sk in HEROES:
        fr = frames(f"heroes/{hid}.png", 32)
        p.paste(up(fr[0], 6), 40, p.y - 20)
        p.text((260, p.y - 6), name, 40, GOLD)
        p.text((260, p.y + 36), f"{era}   |   Vũ khí cơ bản: {wpn}   |   Chiêu: {skill}", 24, (150, 210, 255))
        for i, f in enumerate(fr):
            p.paste(up(f, 3), 260 + i * 104, p.y + 66)
        w = img(f"weapons/{_basic(hid)}.png")
        p.paste(up(w, 3), 1230, p.y + 90)
        p.paste(up(img(f"ui/skill_{sk}.png"), 4), 1470, p.y)
        p.y += 205
    p.save("1-tuong.png")


def _basic(hid):
    src = open(os.path.join(ROOT, "scripts", "data", "heroes.gd"), encoding="utf-8").read()
    m = re.search(r'"%s": \{.*?"weapon": "([a-z_]+)"' % hid, src, re.S)
    return m.group(1)


def skill_id(hid):
    return {"ngo_quyen": "coc_bach_dang", "ba_trieu": "voi_chien", "tran_hung_dao": "hich_tuong_si", "quang_trung": "than_toc"}[hid]


def page_enemies():
    armies = [("dong_han", "Quân Đông Hán (năm 40)"), ("dong_ngo", "Quân Đông Ngô (năm 248)"), ("nam_han", "Quân Nam Hán (năm 938)"),
              ("tong", "Quân Tống (năm 1077)"), ("nguyen_mong", "Quân Nguyên Mông (năm 1285)"), ("minh", "Quân Minh (năm 1427)"),
              ("thanh", "Quân Thanh (năm 1789)"), ("phap_thuy", "Thủy quân Pháp (năm 1861)"),
              ("phap_vien_chinh", "Quân viễn chinh Pháp (năm 1890)"), ("phap_1954", "Tập đoàn cứ điểm (năm 1954)")]
    old = [("bo_binh", "Bộ binh"), ("cung_thu", "Cung thủ"), ("khien_binh", "Khiên binh"), ("phap_su", "Pháp sư")]
    new = [("bo_binh", "Lính lưỡi lê"), ("linh_sung", "Lính súng trường"), ("xa_thu", "Xạ thủ súng máy"), ("phao_binh", "Pháo cối")]
    p = Page("QUÂN XÂM LƯỢC", "10 đạo quân (khung 24x26: đi + tấn công) - kỵ binh, xe tăng, yêu quái", 3400)
    for aid, aname in armies:
        p.text((60, p.y), aname, 32, GOLD)
        kinds = new if aid.startswith("phap") else old
        for k, (kid, kname) in enumerate(kinds):
            fr = frames(f"enemies/{aid}_{kid}.png", 24)
            x = 60 + k * 380
            p.paste(up(fr[0], 5), x, p.y + 38)
            p.paste(up(fr[4], 5), x + 130, p.y + 38)
            p.text((x + 10, p.y + 172), kname, 24, CREAM)
        p.y += 215
    p.text((60, p.y), "Kỵ binh, xe tăng và yêu quái", 32, GOLD)
    x = 60
    for rel, fw, name in (("enemies/nguyen_mong_ky_binh.png", 34, "Kỵ binh"), ("enemies/xe_tang.png", 40, "Xe tăng"),
                          ("enemies/tieu_yeu.png", 16, "Tiểu yêu"), ("enemies/ho_tinh.png", 22, "Hồ tinh"),
                          ("enemies/moc_tinh.png", 26, "Mộc tinh"), ("enemies/chan_tinh.png", 30, "Chằn tinh"),
                          ("enemies/dai_bang.png", 36, "Đại bàng tinh"), ("enemies/ma_troi.png", 14, "Ma trơi")):
        f = frames(rel, fw)[0]
        k = 4
        if x + f.width * k > 1540:
            x = 60
            p.y += 190
        p.paste(up(f, k), x, p.y + 44)
        p.text((x, p.y + 50 + f.height * k), name, 24, CREAM)
        x += f.width * k + 50
    p.y += 230
    p.save("2-quan-dich.png")


def page_bosses():
    bosses = [("to_dinh", "Tô Định", "Thái thú Giao Chỉ", "Cắt tóc cạo râu trốn chạy"),
              ("luc_dan", "Lục Dận", "Tướng nhà Đông Ngô", "Bày trận khiên"),
              ("hoang_thao", "Hoằng Tháo", "Thái tử Nam Hán", "Gọi Thủy quái Ngư Tinh"),
              ("quach_quy", "Quách Quỳ", "Tướng nhà Tống", "Mưa tên"),
              ("thoat_hoan", "Thoát Hoan", "Trấn Nam Vương nhà Nguyên", "Chui vào ống đồng"),
              ("lieu_thang", "Liễu Thăng", "Tổng binh nhà Minh", "Sa lầy ải Chi Lăng"),
              ("ton_si_nghi", "Tôn Sĩ Nghị", "Tổng đốc Lưỡng Quảng", "Bỏ cả ấn tín mà chạy"),
              ("don_truong", "Đồn trưởng Nhã Nam", "Chỉ huy quân viễn chinh", "Gọi pháo kích"),
              ("do_cat", "Đờ Cát", "Chỉ huy tập đoàn cứ điểm", "Rút vào hầm chỉ huy")]
    p = Page("10 TRÙM", "Mỗi chương một kẻ cầm đầu, mỗi trùm một chiêu đặc biệt", 3200)
    for bid, name, title, special in bosses:
        fr = frames(f"enemies/boss_{bid}.png", 48)
        p.paste(up(fr[0], 4), 50, p.y - 10)
        p.text((280, p.y), name, 40, GOLD)
        p.text((280, p.y + 42), f"{title}  -  Chiêu: {special}", 24, CREAM)
        for i, f in enumerate(fr[1:]):
            p.paste(up(f, 2), 280 + i * 110, p.y + 76)
        p.y += 200
    ship = frames("enemies/boss_tau_hy_vong.png", 64)
    p.text((60, p.y), "Tàu chiến Hy Vọng - Chiến thuyền thủy quân Pháp - Chiêu: Bốc cháy", 32, GOLD)
    for i, f in enumerate([ship[0], ship[4], ship[6]]):
        p.paste(up(f, 4), 60 + i * 300, p.y + 46)
    p.y += 240
    ngu = frames("enemies/ngu_tinh.png", 60)
    p.text((60, p.y), "Thủy quái Ngư Tinh (do Hoằng Tháo gọi ra)", 32, GOLD)
    for i, f in enumerate(ngu[:3] + ngu[4:6]):
        p.paste(up(f, 4), 60 + i * 300, p.y + 46)
    p.y += 240
    p.save("3-trum.png")


def page_weapons():
    src = open(os.path.join(ROOT, "scripts", "data", "weapons.gd"), encoding="utf-8").read()
    items = re.findall(r'^\t"([a-z_]+)": \{"name": "([^"]+)", "tier": (\d)', src, re.M)
    items.sort(key=lambda t: (int(t[2]), t[1]))
    p = Page("67 VŨ KHÍ", "10 vũ khí cơ bản của tướng + 57 vũ khí nhặt trong trận - 5 cấp", 2600)
    names = ["", "Thường", "Tốt", "Hiếm", "Sử thi", "Huyền thoại"]
    cur = 0
    col = 0
    for wid, name, t in items:
        t = int(t)
        if t != cur:
            if col:
                p.y += 120
            cur = t
            col = 0
            p.text((60, p.y), f"Cấp {t}: {names[t]}", 40, TIER[t])
            p.y += 54
        w = img(f"weapons/{wid}.png")
        k = 3 if w.width <= 40 else 2
        x = 60 + col * 300
        p.paste(up(w, k), x, p.y + (60 - w.height * k) // 2)
        p.text((x, p.y + 70), name, 24, TIER[t])
        col += 1
        if col == 5:
            col = 0
            p.y += 120
    p.y += 130
    p.save("4-vu-khi.png")


def page_fx():
    p = Page("HIỆU ỨNG CHIÊU THỨC", "Cọc Bạch Đằng - Voi chiến - Hịch tướng sĩ - Thần tốc - và hơn thế", 2000)
    rows = [
        ("Cọc Bạch Đằng: cọc trồi lên khỏi mặt nước", [("fx/stake.png", 14, 6), ("fx/ripple.png", 72, 2)]),
        ("Voi chiến của Bà Triệu", [("fx/elephant.png", 40, 4), ("fx/dust.png", 10, 6)]),
        ("Hịch tướng sĩ: ấn trống đồng + binh sĩ", [("fx/drum.png", 64, 3), ("fx/ally.png", 18, 5)]),
        ("Hùm thiêng Yên Thế, Kéo pháo vào trận, Hỏa hồng Nhật Tảo", [("fx/tiger.png", 40, 4), ("fx/turret.png", 30, 4), ("fx/fire_pot.png", 10, 6)]),
        ("Thần tốc: hào quang tia sét", [("fx/aura.png", 40, 4)]),
        ("Nhát chém, đâm, tia lửa, nổ, khói", [("fx/slash.png", 48, 3), ("fx/spark.png", 15, 5), ("fx/explosion.png", 44, 3)]),
        ("Đạn, cổng dịch chuyển, vật phẩm", [("fx/portal.png", 44, 3), ("fx/fireball.png", 12, 5), ("items/coin.png", 9, 6), ("items/chest.png", 18, 5)]),
    ]
    for title, sheets in rows:
        p.text((60, p.y), title, 34, GOLD)
        x = 60
        hmax = 0
        for rel, fw, k in sheets:
            fr = frames(rel, fw)
            for f in fr[:8]:
                if x + f.width * k > 1540:
                    break
                p.paste(up(f, k), x, p.y + 46)
                x += f.width * k + 8
                hmax = max(hmax, f.height * k)
            x += 30
        p.y += hmax + 80
    p.save("5-hieu-ung.png")


if __name__ == "__main__":
    page_heroes()
    page_enemies()
    page_bosses()
    page_weapons()
    page_fx()
    print("Đã xuất sách tranh vào", OUT)
