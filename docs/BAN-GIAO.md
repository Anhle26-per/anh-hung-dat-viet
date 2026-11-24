# Biên bản bàn giao dự án cho Antigravity (Gemini)

Ngày bàn giao: 24/11/2026
Bên giao: "sếp" dự án (Claude, làm từ đầu đến thẻ G01)
Bên nhận: Antigravity / Gemini, làm việc dưới sự duyệt của chủ dự án

> **Gemini đọc theo thứ tự:**
> 1. Tệp này, để hiểu toàn cảnh.
> 2. `AGENTS.md`, luật bắt buộc.
> 3. `docs/GIAO-VIEC-GEMINI.md`, danh sách việc và lệnh test.
>
> Mỗi phiên chỉ làm MỘT thẻ việc.

---

## 1. Dự án là gì

**Anh Hùng Đất Việt** là game roguelike bắn súng góc nhìn từ trên xuống, pixel art, cảm hứng từ Soul Knight.
- Người chơi điều khiển 10 anh hùng Việt Nam (năm 40 đến năm 1954), đánh quân xâm lược của 10 trận đánh lịch sử.
- Có thêm yêu quái dân gian là phần hư cấu.
- Làm bằng **Godot 4.7, GDScript**.
- Toàn bộ hình vẽ sinh ra từ **mã Python** trong `tools/sprites/`. Không có ảnh vẽ tay, không dùng tài nguyên của game khác.

## 2. Các quyết định đã chốt (không tự ý đổi)

| Quyết định | Lý do |
|---|---|
| Chỉ chơi trong nhóm bạn bè, **không phát hành công khai** | Chủ dự án chốt ngày 24/11/2026 |
| Có 2 cách chơi: **một mình** và **chơi chung qua wifi nhà (LAN)**, 2–4 người | Chủ dự án chọn |
| **Không** quảng cáo, mua trong game, đăng nhập hay máy chủ Internet | Không phát hành nên không cần |
| Hàm `Global.show_rewarded_ad()` còn giữ: nó gọi thẳng phần thưởng, không có quảng cáo thật | Đường hồi sinh lần 2 đang dùng hàm này. Giữ nguyên hoặc đổi tên sau, không cần nối quảng cáo |
| Máy chơi: Windows là chính; Android cài `.apk` tay; **không làm iPhone** | Cần máy Mac và tài khoản Apple |
| Dòng thời gian dừng ở **năm 1954** | Tránh nội dung quá gần và nhạy cảm |
| "Chiến sĩ Điện Biên" là hình tượng chung, không phải người thật | Tránh vẽ người thật |
| Trùm là tướng giặc có thật, "hiện nguyên hình" thành quỷ là **hư cấu tà thuật** | Tăng kịch tính; ghi rõ là hư cấu |
| Trùm **ra ngẫu nhiên**, sức mạnh tăng theo **thứ tự gặp**, không theo từng con | Chủ dự án yêu cầu |
| Thư mục làm việc trên máy chủ dự án: `D:\Games\anh-hung-dat-viet` | Chủ dự án chọn |

## 3. Trạng thái lúc bàn giao

**Đã xong và đã kiểm thử:**
- **Lối chơi một mình đầy đủ:**
  - 10 tướng, mỗi tướng có vũ khí cơ bản và kỹ năng riêng;
  - 67 vũ khí chia 5 cấp;
  - 10 chương × 3 màn (30 màn), hầm ngục sinh ngẫu nhiên.
- **Giặc:**
  - 9 kiểu lính, mỗi đạo quân một bộ hình;
  - 7 yêu quái và lính tinh nhuệ.
- **Trùm:**
  - 10 trùm ngẫu nhiên, máu từ 300 đến 1434 theo thứ tự gặp;
  - còn nửa máu thì **hiện nguyên hình**: hình to gấp đôi, bộ chiêu mới, rồi nổi giận;
  - mỗi trùm có chiêu đặc biệt theo sự tích.
- **Tam Yêu** (Hồ Tinh, Mộc Tinh, Ngư Tinh): trùm giữa chương, ra với tỉ lệ 40%, cũng hiện nguyên hình.
- **Hệ thống trong lượt chơi:**
  - 16 phúc lành;
  - rương sơn mài sau mỗi phòng, gánh hàng rong, hồ lô thuốc;
  - trạng thái cháy và độc, chướng khí.
- **Sảnh "Doanh trại Anh Hùng":** chọn tướng, lò rèn nâng cấp vĩnh viễn, kho vũ khí, hình nhân tập võ, bia thành tích.
- **Điều khiển:** bàn phím và chuột, tay cầm, cảm ứng.
- **G01 (24/11/2026):** lưu lượt chơi dở, "Chơi tiếp" và "Bỏ lượt" ở menu chính, tự lưu khi đóng cửa sổ.

**Kết quả test cuối cùng:**

| Lệnh | Kết quả |
|---|---|
| K1 | `KIỂM TRA XONG: 0 lỗi` |
| `run_save` | `RUN SAVE TEST OK` |
| K2 | `SMOKE TEST OK` (10 tướng, 30 màn, 20 lần biến hình) |

**Git:** nhánh `main` có 2 mốc: `Mốc gốc trước khi giao việc` và `G01: Lưu giữa lượt và giữ xu khi thoát`.

**Lỗi đã biết, chưa sửa** (có trong thẻ G05):
- Đạn có thể bay ra vùng tối ngoài tường.
- Thông báo giữa màn hình đôi khi chồng nhau.

## 4. Kiến trúc mã

### Luồng màn hình
`main_menu.tscn` (Chơi tiếp / Bỏ lượt / Vào doanh trại) → `lobby.tscn` (sảnh, đi vào cổng xuất quân) → `game.tscn` (trận đánh).

Các tệp `.tscn` chỉ có 1 nút gốc gắn script. **Mọi thứ khác đều tạo bằng mã** trong `_ready()`.

### Autoload `Global` (`scripts/autoload/global.gd`)
- **Dữ liệu lưu lâu dài:** `coins`, `best_level`, `unlocked`, `upgrades`, `discovered`, `stats`, `selected_hero`, nằm trong `user://save.json`.
- **Trạng thái lượt chơi:** `level`, `run_coins`, `run_buffs`, `revived`, `free_revives`, `boss_order`, `legend_last`, `legend_chance`.
- **Lượt chơi dở (G01):**
  - Hàm: `save_run(player)`, `peek_run()`, `load_run()`, `clear_run()`, `abandon_run()`, `run_path()`.
  - Tệp lưu: `user://run.json`.
  - `_notification()` bắt tín hiệu đóng cửa sổ và ẩn ứng dụng.
- **Ghi tệp an toàn:** `_write_json_atomic()` ghi ra `.tmp` rồi đổi tên. `_read_json()` dùng `JSON.new().parse()` nên tệp hỏng không in lỗi.
- **Thử nghiệm:** đổi `Global.save_path`, và tệp lượt chơi tự tách theo `run_path()`.
- **Điều khiển:** `touch_mode`, `joy_vector`, `touch_attack`, `touch_skill`, `touch_swap`, và hàm `_setup_inputs()`.

### Dữ liệu (`scripts/data/`): mọi nội dung nằm ở đây
- `heroes.gd`: `ORDER`, `DATA` (tên, thời kỳ, vũ khí cơ bản, kỹ năng, chỉ số, giá mở khóa).
- `weapons.gd`: 67 vũ khí.
  - Kiểu `melee`, `ranged`, `beam`, `wave`, `spikes`.
  - `TIER_NAMES`, `TIER_COLORS`, `roll(level, bonus)`.
  - `grip()` đọc `assets/sprites/weapons/grips.json`, tệp sinh tự động.
- `enemies.gd`:
  - `ARCHETYPES` (lính), `FOLK` (yêu quái).
  - `BOSSES`: `patterns`, `patterns2`, `special`, `form2`.
  - `LEGENDS` (Tam Yêu), `CHAPTERS` (10 chương).
  - Các hàm `info()`, `pool()`, `boss_id()`, `boss_index()`, `home_chapter()`.
  - Mã `"linh_sung@phap_1954"` nghĩa là lính súng của đạo quân `phap_1954`.
  - Mã `"legend:ho_tinh_vuong"` nghĩa là Tam Yêu.
- `buffs.gd`: 16 phúc lành, `offer()`.

### Thực thể và trò chơi
- **`player.gd`** (874 dòng):
  - Di chuyển, ngắm (tự ngắm khi dùng cảm ứng hoặc tay cầm).
  - 6 kiểu đánh, 10 kỹ năng (`_use_skill`), phúc lành (`buff()`, `apply_buff()`).
  - Máu và giáp (`take_damage`, `dot_damage`, `_check_death`), `snapshot()` và `restore()`.
  - Biến `interact_target` (vật đang tương tác) và `nearby_pickup` (vũ khí dưới chân).
- **`enemy.gd`** (990 dòng):
  - Các AI: `chase`, `shoot`, `tank`, `caster`, `ring`, `charge`, `rifle`, `mg`, `mortar`, `tank_elite`, `slam`, `kamikaze`, `ngu`, `boss`.
  - Trùm có: `_boss()` (xoay vòng `patterns`), `_start_special()`, `_start_morph()` / `_finish_morph()` (hiện nguyên hình, bất tử 1,4 giây), `_enrage()` + `_rage_skill()` (bộ chiêu thứ hai), `power()` (bậc sức mạnh).
- **`bullet.gd`:** bảng `PROJ` mô tả hình đạn; khóa `status` gây cháy hoặc độc.
- **`game/dungeon.gd`:** sinh lưới phòng, hành lang, phòng kho báu, gánh hàng rong, phòng Tam Yêu; vẽ ô gạch qua `TileMapLayer` dựng bằng mã.
- **`game/room.gd`:**
  - Các loại phòng: `start`, `combat`, `treasure`, `shop`, `exit`, `boss`, `legend`.
  - Bước vào thì khóa cửa, sinh từng đợt giặc, dọn xong thì hiện rương.
- **`game/game.gd`:** dựng màn, chọn phúc lành khi qua cổng, thua và hồi sinh, tự lưu đầu màn.

### Nhóm node (dùng `get_tree().get_nodes_in_group`)

| Nhóm | Là gì |
|---|---|
| `player` | Người chơi. **Có khoảng 15 chỗ gọi `get_first_node_in_group("player")`; khi làm LAN phải đổi** (thẻ N2) |
| `enemies`, `boss` | Giặc và trùm |
| `game`, `hud`, `dungeon` | Màn chơi, giao diện, hầm ngục |
| `pickups`, `portals` | Vật phẩm rơi, cổng qua màn |
| `enemy_bullets`, `player_bullets` | Đạn của giặc, đạn của người chơi |

## 5. Hệ thống đồ họa (`tools/sprites/`)

- **Vẽ lại toàn bộ:** chạy `python3 tools/sprites/build_all.py`, rồi `python3 tools/sprites/artbook.py` (sách tranh trong `docs/artbook/`), rồi `godot --headless --path . --import`.
- **`px.py`** chứa các hàm dùng chung:
  - `grid()` (vẽ từ lưới ký tự), `outline()`, `auto_shade()`, `shade()`;
  - **`polish()`**: bước hoàn thiện cho nhân vật (viền gần đen, khối theo từng mảng màu, vân);
  - `save()`, `sheet()`.
- **`art_heroes.py`:** tướng vẽ bằng lưới ký tự, hàm `R(x, "...")` đặt đoạn màu vào hàng.
- **Các tệp còn lại:**
  - `art_soldiers.py`: lính, ghép theo lớp.
  - `art_enemies.py`, `art_chars.py`: yêu quái, trùm.
  - `art_demons.py`: hình hiện nguyên hình, dùng Scale2x, đổi da, mọc sừng.
  - `art_legends.py`: Tam Yêu.
  - `art_weapons.py`, `art_fx.py`, `art_world.py`, `art_tiles.py`, `art_lobby.py`, `art_buffs.py`.

**Bố cục các tờ hình** (khung xếp ngang từ trái sang):

| Loại | Kích thước khung | Thứ tự khung |
|---|---|---|
| Tướng `heroes/<id>.png` | 32×32 | 0–3 đứng, 4–7 đi, 8 bị đánh |
| Lính `enemies/<đạo quân>_<loại>.png` | 24×26 | 0–3 đi, 4 tấn công |
| Trùm `enemies/boss_<id>.png` | 48×48 (tàu 64×44) | 0–3 đi, 4 tấn công, 5 nổi giận, 6 tung chiêu |
| Trùm hiện nguyên hình `boss_<id>_2.png` | 112×114 (tàu 144×106) | như trên |
| Tam Yêu `boss_<id>.png` / `_2.png` | Hồ Tinh và Ngư Tinh 84×60, Mộc Tinh 72×72 | như trên |

**Muốn thêm hoạt ảnh** (thẻ G10):
- **Thêm khung vào cuối tờ hình**, không chèn vào giữa.
- Khai báo tên hoạt ảnh mới ở chỗ gọi `Art.frames(...)` trong `player.gd` hoặc `enemy.gd`.
- **Không sửa tay tệp PNG**: sửa mã Python rồi vẽ lại.

## 6. Bẫy kỹ thuật đã gặp (đọc kỹ để khỏi mất thời gian)

1. **`:=` với giá trị Variant gây lỗi biên dịch.** Ví dụ `var a := (p.global_position - x).angle()` khi `p` không có kiểu. Luôn ghi kiểu tường minh.
2. **Ảnh nạp lần đầu trong `_draw()` hiện thành ô trắng.** Phải nạp qua `Art.tex()`; mọi ảnh đã được nạp sẵn ở `Art.preload_all()` khi mở game.
3. **Chủ đề giao diện phải gán cho từng màn hình** (`theme = UI.make_theme()`), nếu không nút sẽ xám.
4. **Lambda dùng trong timer phải giữ `weakref`.** Nếu giữ node trực tiếp, node bị xóa sẽ gây lỗi "lambda capture freed".
5. **Màn chọn phúc lành dừng cả cây cảnh** (`paused`). Test phải chờ `buff_ui.visible` rồi gọi `pick(0)`.
6. **Test phải dùng `Global.save_path` riêng**, nếu không sẽ ghi đè tệp lưu thật của người chơi.
7. **Trùm đang biến hình hoặc Ngư Tinh đang lặn thì không nhận sát thương.** Test muốn hạ trùm phải đặt `boss._submerged = false` hoặc đặt máu trực tiếp.
8. **Sau khi thêm hoặc đổi PNG, phải chạy `--import`.** Nếu không, Godot vẫn dùng ảnh cũ trong thư mục `.godot/`.
9. **`change_scene_to_file()` xóa luôn cảnh đang chạy**, kể cả script đang gọi nó. Muốn chụp màn hình hay test tiếp thì thêm cảnh mới vào `get_tree().root`.
10. **`JSON.parse_string()` in lỗi đỏ khi tệp hỏng.** Dùng `JSON.new().parse()` như `Global._read_json()`.
11. **K2 phải chạy với `--fixed-fps 60`.** Nếu không, test chạy theo thời gian thật nên rất lâu và có thể hết giờ.

## 7. Kiểm thử

| Lệnh | Tác dụng | Thời gian |
|---|---|---|
| `tools\run_tests.bat nhanh` / `bash tools/run_tests.sh nhanh` | K1: biên dịch mọi script | khoảng 10 giây |
| `tools\run_tests.bat` / `bash tools/run_tests.sh` | K1 + K2: máy tự chơi 10 tướng, 67 vũ khí, 30 màn, Tam Yêu, biến hình, rương, chợ, độc, chết rồi hồi sinh | 15–25 phút |
| `tools\run_tests.bat run_save` | Test riêng của G01 | khoảng 10 giây |

Cách viết test mới:
- Đặt tên `tests/<ten>_test.gd` + `.tscn`.
- Đạt thì in `<TÊN> TEST OK` và `quit(0)`; lỗi thì `quit(1)`.
- Có bộ đếm giờ tự dừng để không treo mãi.
- **Thử phá mã một lần** để chắc test bắt được lỗi thật (G01 đã làm vậy).

Bản `.bat` chưa từng chạy trên Windows thật. Nếu lỗi, dùng các lệnh PowerShell ở mục 1b của `GIAO-VIEC-GEMINI.md`.

## 8. Việc còn lại

Xem **bảng 0b trong `docs/GIAO-VIEC-GEMINI.md`**. Có 18 thẻ chưa làm:
- **Đợt 1:** G02 âm thanh → G03 cài đặt và độ khó → G04 đóng gói `.exe`/`.apk` → G05 sửa lỗi nhỏ.
- **Đợt 2 (LAN), làm đúng thứ tự:** N1 → N2 → N3 → N4 → N5 → N6 → N7 → N8.
- **Đợt 3:** G06 mã thử thách → G07 hướng dẫn → G08 tướng đầu to → G10 hoạt ảnh riêng → G09 nội dung mới.
- **Xen kẽ:** G11 cân bằng độ khó theo nhật ký trận.

**Thẻ tiếp theo là G02 (âm thanh).**

## 9. Quy trình làm việc của Gemini

1. Chủ dự án tạo nhánh `gemini/<mã thẻ>` từ `main`.
2. Gemini đọc `AGENTS.md`, đọc thẻ việc, **trình kế hoạch 5–8 dòng và chờ chủ dự án đồng ý**.
3. Gemini làm việc:
   - chạy K1 sau mỗi lần sửa `.gd`;
   - chạy test riêng của thẻ;
   - chạy K2 ở cuối, hoặc nhờ chủ dự án chạy.
4. Gemini báo cáo theo mục 10 của `AGENTS.md`. **Không tự commit hay push.**
5. Chủ dự án duyệt theo danh sách kiểm tra (mục 6 của `GIAO-VIEC-GEMINI.md`), rồi commit và gộp vào `main`.
6. Chủ dự án sửa cột "Trạng thái" trong bảng 0b.

## 10. Câu mở đầu cho phiên Antigravity đầu tiên

```
Bạn là lập trình viên tiếp quản dự án game "Anh Hùng Đất Việt" (Godot 4.7).
Đọc theo thứ tự: docs/BAN-GIAO.md, AGENTS.md, docs/GIAO-VIEC-GEMINI.md.
Phiên này KHÔNG sửa tệp nào. Hãy:
1. Tóm tắt trong 10 dòng: dự án là gì, các quyết định đã chốt, trạng thái hiện tại, thẻ việc tiếp theo.
2. Chạy kiểm tra biên dịch K1 và dán 10 dòng cuối kết quả.
3. Chạy git log --oneline và cho biết đang ở nhánh nào.
4. Liệt kê 3 điều bạn còn chưa rõ và cần hỏi chủ dự án trước khi làm thẻ G02.
```
