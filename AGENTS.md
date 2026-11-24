# AGENTS.md: Anh Hùng Đất Việt

Bạn là lập trình viên hỗ trợ cho game "Anh Hùng Đất Việt": roguelike bắn súng góc nhìn từ trên xuống, pixel art, phong cách Soul Knight. Chủ đề là anh hùng Việt Nam từ năm 40 đến năm 1954.

**Game KHÔNG phát hành công khai.** Game chỉ để chủ dự án và bạn bè chơi:
- chơi một mình;
- chơi chung qua mạng wifi nhà (LAN).

Không làm quảng cáo, mua trong game, đăng nhập tài khoản, máy chủ Internet hay gửi dữ liệu ra ngoài.

Phiên đầu tiên: đọc `docs/BAN-GIAO.md` (biên bản bàn giao: kiến trúc, quyết định đã chốt, bẫy kỹ thuật).
Đọc hết tệp này trước khi làm. Mỗi phiên chỉ làm MỘT thẻ việc trong `docs/GIAO-VIEC-GEMINI.md`.
Xem bảng theo dõi ở mục 0b của tệp đó để biết thẻ nào đã xong và thẻ nào phải làm trước. Sau khi mọi test bắt buộc đã đạt và gộp vào `main`, Gemini tự cập nhật cột Trạng thái trong bảng 0b.

## 1. Công nghệ và phiên bản
- Godot **4.7** (bản Standard), GDScript 2.0, renderer "GL Compatibility".
- Màn hình gốc 640×360, chế độ stretch canvas_items. Autoload duy nhất là `Global`.
- KHÔNG BAO GIỜ viết mã Godot 3. Không chắc một API thì tra tài liệu Godot 4.
- Python 3 + Pillow cho công cụ vẽ hình trong `tools/sprites/` (trên máy này dùng lệnh `py` để chạy Python).
- Lệnh Godot trên máy này: `D:\Games\Godot\Godot_v4.7.2-stable_win64_console.exe`.

## 2. Bản đồ thư mục
- `scripts/autoload/global.gd`: `Global`, gồm:
  - xu, nâng cấp, tướng đã mở;
  - lưu game vào `user://save.json`; biến `save_path` đổi được khi test;
  - trạng thái lượt chơi, thứ tự trùm `boss_order`, Tam Yêu.
- `scripts/data/`: DỮ LIỆU.
  - `heroes.gd`, `weapons.gd`, `buffs.gd`.
  - `enemies.gd`: ARCHETYPES, FOLK, BOSSES, LEGENDS, CHAPTERS.
- `scripts/entities/`: người chơi (`player.gd`), giặc và trùm (`enemy.gd`), đạn (`bullet.gd`), vật phẩm, rương, vật tương tác.
- `scripts/effects/`: hiệu ứng.
  - Nổ, lửa, chướng khí (`miasma.gd`), trạng thái cháy và độc (`status_fx.gd`).
  - Hiệu ứng kỹ năng của từng tướng.
- `scripts/game/`:
  - `game.gd`: màn chơi.
  - `dungeon.gd`: sinh hầm ngục.
  - `room.gd`: phòng; cửa khóa, đợt giặc, rương.
  - `lobby.gd`: sảnh.
  - `shop.gd`: gánh hàng rong.
- `scripts/ui/`: giao diện dựng bằng mã qua `ui.gd`; HUD, menu, nút cảm ứng.
- `scenes/`: `main_menu.tscn`, `hero_select.tscn`, `lobby.tscn`, `game.tscn`.
- `assets/sprites/`: ảnh PNG SINH TỰ ĐỘNG. `assets/fonts/`: VT323 (giấy phép OFL).
- `tools/sprites/`: mã Python vẽ toàn bộ hình. `tests/`: kiểm thử headless.
- `docs/`: tài liệu, ảnh chụp, sách tranh, bảng giao việc.

## 3. Lệnh kiểm tra (BẮT BUỘC trước khi báo xong)
1. **K1, kiểm tra biên dịch** (chạy sau MỖI lần sửa .gd):
   `godot --headless --path . res://tests/check_scripts.tscn`
   - Đạt khi in `KIỂM TRA XONG: 0 lỗi`.
   - Lệnh này chỉ quét `res://scripts`. Test mới trong `tests/` phải chạy riêng.
2. **K2, máy tự chơi** (chạy MỘT lần ở cuối việc, mất 15–25 phút):
   `godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn > logs/smoke.txt 2>&1`
   - Tạo thư mục `logs/` trước nếu chưa có.
   - Đạt khi `logs/smoke.txt` có dòng `SMOKE TEST OK`.
   - Nếu công cụ của bạn không chờ được lâu như vậy, DỪNG và nhờ chủ dự án chạy. KHÔNG báo "đã xong" khi chưa thấy `SMOKE TEST OK`.
3. Test riêng của thẻ việc (nếu có): `godot --headless --path . res://tests/<ten>_test.tscn`.
4. Sau khi thêm tài nguyên mới (âm thanh, ảnh), chạy `godot --headless --path . --import` trước khi chạy test.
5. Khi báo xong, DÁN NGUYÊN VĂN 20 dòng cuối của mỗi lệnh test.
6. Có sẵn script chạy test: `bash tools/run_tests.sh [nhanh|<ten>]` (Linux/Mac) và `tools\run_tests.bat [nhanh|<ten>]` (Windows).
   Bảng lệnh test của từng thẻ việc nằm ở mục 1b của `docs/GIAO-VIEC-GEMINI.md`.
7. Test mới đặt tên `tests/<ten>_test.gd` + `tests/<ten>_test.tscn`, khi đạt in dòng `<TÊN> TEST OK`, khi lỗi thoát với mã 1
   (`get_tree().quit(1)`). Phải có bộ đếm giờ tự dừng để không treo mãi. Test dùng `Global.save_path` riêng.

## 4. Luật Godot 4 (cấm cú pháp Godot 3)
| Cấm (Godot 3) | Dùng (Godot 4) |
|---|---|
| `yield(obj, "signal")` | `await obj.signal`, `await get_tree().create_timer(1.0).timeout` |
| `export var x = 1` / `onready var` / `tool` | `@export var x: int = 1` / `@onready var` / `@tool` |
| `KinematicBody2D`, `move_and_slide(velocity, ...)` | `CharacterBody2D`, gán `velocity` rồi `move_and_slide()` |
| `scene.instance()` | `scene.instantiate()` |
| `connect("sig", obj, "method")` | `sig.connect(callable)` |
| `setget` | `var x: int: set(v): ... get: ...` |
| `File.new()`, `Directory.new()` | `FileAccess.open()`, `DirAccess.open()` |
| `rand_range()`, `stepify()`, `deg2rad()` | `randf_range()`, `snapped()`, `deg_to_rad()` |
| `change_scene("...")` | `change_scene_to_file("...")` |
| `remote`, `master`, `puppet`, `rpc("f")` kiểu cũ | `@rpc("any_peer", "call_local", "reliable")`, `f.rpc(...)`, `f.rpc_id(id, ...)` |
| `NetworkedMultiplayerENet` | `ENetMultiplayerPeer` |
| `get_tree().network_peer` | `multiplayer.multiplayer_peer` |

## 5. Kiểu dữ liệu: tránh lỗi `:=` suy ra Variant
- Luôn ghi kiểu tường minh cho biến, tham số và giá trị trả về: `func f(a: int) -> void:`.
- KHÔNG dùng `:=` khi vế phải trả về Variant, vì sẽ thành lỗi biên dịch. Các trường hợp hay gặp:
  - `Dictionary.get()`, `dict[key]`;
  - phần tử của `Array` không có kiểu;
  - `JSON.parse_string()`, `get_node()`;
  - dữ liệu trong `scripts/data/*`;
  - thuộc tính của node lấy qua nhóm (`get_first_node_in_group`).

  Viết `var cost: int = HeroData.DATA[id].cost`, `var a: float = (p.global_position - global_position).angle()`.
- `:=` chỉ dùng khi vế phải có kiểu rõ ràng, ví dụ `Vector2(...)` hay `Node2D.new()`.
- Lambda dùng trong timer phải giữ `weakref` tới node, không giữ node trực tiếp.
- Ảnh vẽ trong `_draw()` phải nạp qua `Art.tex()`. Ảnh đã được nạp sẵn ở `Art.preload_all()`.

## 6. Quy tắc dự án
- Nội dung (tướng, vũ khí, giặc, trùm, phúc lành) chỉ nằm trong `scripts/data/`. KHÔNG đổi mã định danh đã có, vì `save.json` dùng chúng.
- Tệp lưu:
  - Chỉ THÊM khóa mới, kèm giá trị mặc định khi thiếu; không xóa hay đổi nghĩa khóa cũ.
  - Test phải dùng `Global.save_path` riêng, không đụng tệp lưu thật.
- KHÔNG sửa con số cân bằng (máu, sát thương, giá, tỉ lệ rơi) trừ khi thẻ việc ghi rõ.
- Hình ảnh:
  - KHÔNG BAO GIỜ sửa tay PNG trong `assets/sprites/`.
  - Sửa mã trong `tools/sprites/art_*.py`, rồi chạy `python3 tools/sprites/build_all.py`, và `python3 tools/sprites/artbook.py` để cập nhật sách tranh.
  - Nhân vật dùng bước hoàn thiện `polish()` trong `tools/sprites/px.py`.
- Hạn chế sửa tay `.tscn`, `.tres`, `project.godot`. Ưu tiên tạo node bằng mã như phong cách hiện có.
- KHÔNG xóa, nới bớt hay "sửa cho qua" bài test. Muốn kiểm thêm thì tạo test mới trong `tests/`.
- Phạm vi: chỉ sửa tệp ghi trong thẻ việc.
  - Cần sửa hơn khoảng 3 tệp hoặc 300 dòng ngoài dự kiến thì DỪNG và hỏi.
  - Không tái cấu trúc, không đổi tên, không thêm addon nếu thẻ không yêu cầu.
- Git: bạn được tự chạy `git add`, `git commit`, `git switch`, `git merge` trên máy này, sau khi mọi test bắt buộc đã đạt. KHÔNG `git push`, KHÔNG `--force`, KHÔNG viết lại lịch sử, KHÔNG xóa nhánh `main`.

## 7. Chơi chung qua LAN (khi làm các thẻ N1–N8)
- Dùng `ENetMultiplayerPeer` có sẵn trong Godot, cổng mặc định 7777, tối đa 4 người. KHÔNG dùng máy chủ Internet hay dịch vụ ngoài.
- Mô hình **máy chủ là người tạo phòng (host)**:
  - Host quyết định giặc, trùm, phòng, cửa, rương, vật phẩm rơi và cổng qua màn.
  - Mỗi người tự điều khiển nhân vật của mình và báo vị trí cho người khác.
- Bản đồ sinh giống nhau ở mọi máy nhờ **cùng hạt giống (seed)** do host gửi: gọi `seed(...)` ngay trước `dungeon.generate()`.
- Chơi một mình phải chạy y như cũ. Khi không có mạng, `multiplayer.multiplayer_peer` là `OfflineMultiplayerPeer`; mọi mã mạng phải kiểm tra điều này.
- Mọi hàm `@rpc` ghi rõ chế độ:
  - `"authority"` cho lệnh từ host;
  - `"any_peer"` cho yêu cầu từ người chơi;
  - `"reliable"` cho sự kiện như sinh giặc, chết, nhặt đồ;
  - `"unreliable_ordered"` cho vị trí cập nhật liên tục.
- Host phải kiểm tra yêu cầu từ người chơi (`multiplayer.get_remote_sender_id()`), không tin mù quáng.
- KHÔNG đổi `tests/smoke_test.gd` để chạy mạng. Test mạng là test riêng `tests/lan_test.tscn`: chạy 1 host và 1 khách trên 127.0.0.1.

## 8. Tiếng Việt và nội dung lịch sử
- Mọi chữ hiển thị viết tiếng Việt CÓ DẤU, UTF-8, font VT323. Giữ nguyên chú thích tiếng Việt trong mã.
- Game dừng ở năm 1954, không thêm nội dung sau 1954. Không biếm họa hay xúc phạm bất kỳ dân tộc nào.
- Yêu quái, tà thuật và "hiện nguyên hình" là hư cấu. Chiến sĩ Điện Biên là hình tượng chung, không phải người thật.
- Không tự tạo bản đồ địa lý. Nếu có, Hoàng Sa và Trường Sa phải thuộc Việt Nam, TUYỆT ĐỐI không có "đường chín đoạn".
- Mọi câu chữ mới về lịch sử chỉ là BẢN NHÁP. Liệt kê chúng trong báo cáo để chủ dự án duyệt.

## 9. Tài nguyên bên ngoài
- Chỉ dùng tài nguyên CC0, ưu tiên Kenney (kenney.nl). Ghi mỗi tệp vào `CREDITS.md`: tên tệp, URL nguồn, giấy phép.
- Không dùng tệp không rõ giấy phép. Không ghi mật khẩu hay khóa vào bất kỳ tệp nào.

## 10. Mẫu báo cáo khi xong việc
1. Mã thẻ việc và tóm tắt một câu.
2. Danh sách tệp đã sửa hoặc tạo, mỗi tệp một dòng lý do.
3. 20 dòng cuối của từng lệnh test (K1, test riêng, K2).
4. Những gì CHƯA làm được, rủi ro còn lại, câu chữ lịch sử cần chủ dự án duyệt.
