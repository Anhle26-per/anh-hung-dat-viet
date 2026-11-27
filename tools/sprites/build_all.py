"""Chạy file này để vẽ lại toàn bộ đồ họa vào assets/sprites/.
   python3 tools/sprites/build_all.py
"""
import art_heroes, art_chars, art_demons, art_legends, art_weapons, art_enemies, art_fx, art_world, art_soldiers, art_buffs, art_tiles, art_lobby, art_lobby_props, art_v30
from px import save, outline, Image, OUT
import os

art_heroes.build()
art_chars.build_ally()
art_chars.build_elephant()
art_chars.build_enemies()
art_weapons.build()
art_enemies.build()
art_soldiers.build()   # lính chi tiết 24x26 (ghi đè bản cũ)
art_demons.build()     # trùm hiện nguyên hình (dựa trên hình trùm ở trên)
art_legends.build()    # Tam Yêu: Ngư Tinh, Hồ Tinh, Mộc Tinh
art_fx.build()
art_world.build()
art_buffs.build()
art_tiles.build()     # gạch nền + tường 2 tầng (ghi đè bản cũ)
art_lobby.build()     # tranh nền doanh trại
art_lobby_props.build()  # công trình & đồ trang trí sảnh chính
art_v30.build()       # mở rộng v3.0.0: 3 trùm mới, 4 thần thú, Cổ Loa & doanh trại
# biểu tượng Hịch tướng sĩ = mặt trống đồng nhỏ có viền
with Image.open(os.path.join(OUT, "ui/skill_hich_tuong_si_raw.png")) as f_raw:
	f_raw.load()
	raw = f_raw.copy()
os.remove(os.path.join(OUT, "ui/skill_hich_tuong_si_raw.png"))
img = Image.new("RGBA", (22, 22), (0, 0, 0, 0))
img.alpha_composite(raw, (1, 1))
save(outline(img), "ui/skill_hich_tuong_si.png")
n = sum(len(f) for _, _, f in os.walk(OUT))
print("Đã vẽ xong", n, "tệp")
