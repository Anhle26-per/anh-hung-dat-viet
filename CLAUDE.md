# CLAUDE.md — Anh Hùng Đất Việt

## 1. Dự án là gì
**Anh Hùng Đất Việt** là game roguelike bắn súng góc nhìn từ trên xuống (pixel art, Godot 4.7, GDScript 2.0) lấy cảm hứng từ Soul Knight, chủ đề các anh hùng Việt Nam từ năm 40 đến năm 1954 kết hợp yếu tố yêu quái dân gian hư cấu.
Định hướng đã chốt: **không phát hành công khai**, chỉ chơi trong nhóm bạn (chơi một mình hoặc chơi chung qua mạng LAN 2–4 người), **không** quảng cáo, mua trong game hay máy chủ Internet ngoài.

## 2. Vai trò trong dự án
- **Chủ dự án:** Sếp lớn — duyệt ý tưởng, câu chữ lịch sử, thứ tự ưu tiên; không làm thao tác kỹ thuật.
- **Claude:** Quản lý dự án — đặt kiến trúc, ra lệnh thẻ việc, nghiệm thu, và có thể tự triển khai hoặc sửa mã khi cần.
- **Gemini / Antigravity:** Lập trình viên triển khai theo thẻ việc, chạy kiểm thử và báo cáo bằng tiếng Việt.

## 3. Môi trường trên máy này
- Thư mục mã nguồn: `D:\Games\anh-hung-dat-viet` (nhánh chính `main`).
- Godot Console: `D:\Games\Godot\Godot_v4.7.2-stable_win64_console.exe` (luôn dùng bản `_console` để đọc được log stdout).
- Python 3 + Pillow: chạy bằng lệnh `py` (tránh gọi `python` vì Windows dễ trỏ nhầm Microsoft Store alias).
- Git: đã cài sẵn; lưu ý `CRLF` trên Windows, tệp `.uid` do Godot 4.7 sinh tự động, và kiểm tra `core.fileMode`.
- Thư mục `user://`: sandbox có thể chặn ghi `%APPDATA%` — các test ghi `user://` phải chạy ngoài sandbox hoặc cô lập biến môi trường `$env:APPDATA` / `Global.save_path`.

## 4. Lệnh test & danh sách đầy đủ test riêng
Chạy từ `D:\Games\anh-hung-dat-viet`:
- `tools\run_tests.bat nhanh` — **K1**: biên dịch toàn bộ `res://scripts`, đạt khi in `KIỂM TRA XONG: 0 lỗi`.
- `tools\run_tests.bat <tên>` — chạy K1 rồi chạy `res://tests/<tên>_test.tscn`.
- `tools\run_tests.bat` — **K2**: K1 + máy tự chơi hết game (`tests/smoke_test.tscn`, ~15–25 phút), đạt khi `logs\smoke.txt` có `SMOKE TEST OK`.

| Tên `<tên>` | Tệp test | Dòng báo đạt |
|---|---|---|
| `audio` | `tests/audio_test.tscn` | `AUDIO TEST OK` |
| `bugfix` | `tests/bugfix_test.tscn` | `BUGFIX TEST OK` |
| `challenge` | `tests/challenge_test.tscn` | `CHALLENGE TEST OK` |
| `cover` | `tests/cover_test.tscn` | `COVER TEST OK` |
| `craft` | `tests/craft_test.tscn` | `CRAFT TEST OK` |
| `dungeon_rework` | `tests/dungeon_rework_test.tscn` | `DUNGEON REWORK TEST OK` |
| `feel_smith` | `tests/feel_smith_test.tscn` | `FEEL SMITH TEST OK` |
| `giong` | `tests/giong_test.tscn` | `GIONG TEST OK` |
| `hero_anim` | `tests/hero_anim_test.tscn` | `HERO ANIM TEST OK` |
| `hotamkinh` | `tests/hotamkinh_test.tscn` | `HO TAM KINH TEST OK` |
| `input` | `tests/input_test.tscn` | `INPUT TEST OK` |
| `lan` | `tests/lan_test.tscn` | `LAN TEST OK` |
| `lobby_rooms` | `tests/lobby_rooms_test.tscn` | `LOBBY ROOMS TEST OK` |
| `log` | `tests/log_test.tscn` | `LOG TEST OK` |
| `merchant_buffs` | `tests/merchant_buffs_test.tscn` | `MERCHANT BUFFS TEST OK` |
| `pacing` | `tests/pacing_test.tscn` | `PACING TEST OK` |
| `progression` | `tests/progression_test.tscn` | `PROGRESSION TEST OK` |
| `run_save` | `tests/run_save_test.tscn` | `RUN SAVE TEST OK` |
| `settings` | `tests/settings_test.tscn` | `SETTINGS TEST OK` |
| `synergy` | `tests/synergy_test.tscn` | `SYNERGY TEST OK` |
| `updater` | `tests/updater_test.tscn` | `UPDATER TEST OK` |
| `v13_features` | `tests/v13_features_test.tscn` | `V13 FEATURES TEST OK` |
| `v14_audio_blueprints` | `tests/v14_audio_blueprints_test.tscn` | `V14 AUDIO BLUEPRINTS TEST OK` |
| `v15_dynamic_bgm` | `tests/v15_dynamic_bgm_test.tscn` | `V15 DYNAMIC BGM TEST OK` |

## 5. Luật chính (xem đầy đủ trong `AGENTS.md`)
1. **Godot 4.7 thuần & định kiểu tường minh:** Cấm cú pháp Godot 3; không dùng `:=` khi vế phải trả về `Variant` (như `dict.get()`, `JSON.parse_string()`, `scripts/data/*`); timer lambda phải dùng `weakref`.
2. **Tài nguyên sinh bằng mã:** Không vẽ tay đè lên `assets/sprites/` hay sửa tay WAV — sửa mã Python trong `tools/sprites/` hoặc `tools/audio/build_audio.py`, chạy lại bằng `py` rồi chạy `Godot --headless --path . --import`.
3. **An toàn dữ liệu lưu & test:** Không đổi ID cũ trong `scripts/data/` làm hỏng `user://save.json`; mọi bài test phải dùng `Global.save_path` riêng và không được xóa hoặc nới lỏng assertion để ép pass.
4. **Nội dung & lịch sử:** Game dừng ở mốc năm **1954**, tiếng Việt có dấu (UTF-8, font VT323); câu chữ lịch sử mới chỉ là bản nháp chờ chủ dự án duyệt.
5. **Quy trình Git & kiểm thử:** Chỉ commit lên `main` sau khi test đạt; **tuyệt đối không tự ý `git push`, `--force`, hay sửa lịch sử Git**.

## 6. Bản đồ tài liệu
- `AGENTS.md` — Toàn bộ luật kỹ thuật, quy chuẩn Godot 4, mạng LAN, quy trình làm việc.
- `docs/BAN-GIAO.md` — Biên bản bàn giao hiện trạng kiến trúc, hệ thống mã nguồn, bẫy kỹ thuật và việc còn lại.
- `docs/GIAO-VIEC-GEMINI.md` — **Bảng 0b** theo dõi trạng thái toàn bộ thẻ việc và lệnh test từng thẻ.
- `docs/NHAT-KY-DU-AN.md` — Nhật ký lịch sử dự án theo từng mốc commit/thẻ và bẫy Windows/Antigravity.
- `docs/Y-TUONG.md` — Kho ý tưởng đề xuất đang **Chờ chủ dự án chọn** kèm thứ tự ưu tiên.
- `docs/PHAN-TICH-SOUL-KNIGHT.md` — Ghi chú phân tích thiết kế tham khảo từ Soul Knight.
- `docs/HUONG-DAN-CAI.md` — Hướng dẫn cài đặt và chạy bản đóng gói Windows, Android, macOS cho bạn bè.

## 7. Việc đầu tiên khi mở phiên mới
1. Đọc bảng **0b** trong `docs/GIAO-VIEC-GEMINI.md` và `docs/BAN-GIAO.md` để nắm trạng thái mới nhất.
2. Chạy `git log --oneline -20` để kiểm tra lịch sử commit gần đây trên `main`.
3. Chạy `tools\run_tests.bat nhanh` để xác nhận toàn bộ script biên dịch sạch (`0 lỗi`).
