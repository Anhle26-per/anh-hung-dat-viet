# Nhật ký dự án Anh Hùng Đất Việt

Tài liệu tổng hợp tiến trình dự án theo dòng thời gian từ `Mốc gốc` qua trọn đợt lệnh tổng hợp (`G01`–`G19`, `G05`, `G04`), các đợt mở rộng tiếp theo (`G12`, `G06–G13`, `N1–N8 LAN`, `v1.2.0`–`v1.5.0`) đến trạng thái hiện tại trên `main`.

---

## 1. Dòng thời gian đợt nền tảng & bàn giao (Mốc gốc -> G04)

### Mốc gốc
- **Ngày / Người làm:** 24/11/2026 — Claude
- **Commit:** `a788ed0` (*Mốc gốc trước khi giao việc*)
- **Tóm tắt:** Dựng xong khung game chơi một mình đầy đủ: 10 tướng anh hùng lịch sử, 67 vũ khí 5 cấp, 10 chương × 3 màn, 10 trùm có biến hình hiện nguyên hình, Tam Yêu, 16 phúc lành, Sảnh "Doanh trại Anh Hùng" và `tests/smoke_test.tscn`.
- **Tệp chính:** Toàn bộ khung ban đầu `scripts/`, `scenes/`, `tools/sprites/`, `tests/smoke_test.*`, `AGENTS.md`.
- **Test & kết quả:** K1 (`KIỂM TRA XONG: 0 lỗi`), K2 (`SMOKE TEST OK`).
- **Quyết định:** Không phát hành công khai; dừng dòng thời gian ở năm 1954; không quảng cáo/nạp tiền; toàn bộ đồ họa sinh tự động bằng Python.

### G01 — Lưu giữa lượt và giữ xu khi thoát
- **Ngày / Người làm:** 24/11/2026 — Claude
- **Commit:** `99ff673` (*G01: Lưu giữa lượt và giữ xu khi thoát*)
- **Tóm tắt:** Thêm lưu trạng thái lượt chơi dở (`user://run.json`) ghi nguyên tử qua `.tmp`, tự lưu ở đầu mỗi màn và khi nhận `WM_CLOSE_REQUEST` / `APPLICATION_PAUSED`, kèm nút "Chơi tiếp" và "Bỏ lượt" giữ xu ở menu chính.
- **Tệp chính:** `scripts/autoload/global.gd`, `scripts/entities/player.gd`, `scripts/game/game.gd`, `scripts/ui/main_menu.gd`, `tests/run_save_test.gd/.tscn`, `docs/GIAO-VIEC-GEMINI.md`.
- **Test & kết quả:** K1 (`0 lỗi`), `tests/run_save_test.tscn` (`RUN SAVE TEST OK`), K2 (`SMOKE TEST OK`).
- **Quyết định / Lỗi:** Tách `Global.run_path()` theo `Global.save_path` để test không đụng tệp lưu thật; đọc JSON bằng `JSON.new().parse()` để tệp hỏng không in lỗi đỏ.

### Bàn giao dự án cho Antigravity (Gemini)
- **Ngày / Người làm:** 24/11/2026 — Claude
- **Commit:** `24979bd` (*Bàn giao dự án cho Antigravity: docs/BAN-GIAO.md*)
- **Tóm tắt:** Đóng gói kiến trúc hệ thống, danh sách 11 bẫy kỹ thuật ban đầu, bảng 0b các thẻ việc và quy trình nhánh `gemini/<mã thẻ>` merge vào `main` trước khi chuyển sang Gemini triển khai.
- **Tệp chính:** `docs/BAN-GIAO.md`.

### G00 — Chuẩn bị môi trường Windows
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `8c109a6` (*G00: chuẩn bị môi trường Windows*)
- **Tóm tắt:** Cấu hình đường dẫn `Godot_v4.7.2-stable_win64_console.exe` vào `tools/run_tests.bat`, đối chiếu môi trường Windows thực tế và cập nhật hướng dẫn chạy test PowerShell trong `docs/BAN-GIAO.md` và `docs/GIAO-VIEC-GEMINI.md`.
- **Tệp chính:** `tools/run_tests.bat`, `docs/BAN-GIAO.md`, `docs/GIAO-VIEC-GEMINI.md`, `tests/run_save_test.gd.uid`.
- **Test & kết quả:** `tools\run_tests.bat nhanh` -> `K1 OK`, `tools\run_tests.bat run_save` -> `RUN SAVE TEST OK`.
- **Lỗi gặp:** Trên Windows lệnh `python` có thể trỏ sang Microsoft Store alias; cần dùng `py`.

### G02 — Âm thanh và nhạc nền
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `de18d36`, `b17bc29`
- **Tóm tắt:** Thêm autoload `Sfx` với 2 bus (`Music`, `SFX`), giới hạn 8 giọng SFX đồng thời; viết trình tổng hợp thuần Python (`tools/audio/build_audio.py`) tạo bộ SFX 8-bit và 3 bản nhạc nền ngũ cung Việt Nam (`lobby`, `battle`, `boss`).
- **Tệp chính:** `tools/audio/build_audio.py`, `scripts/audio/sfx.gd`, `project.godot`, `tests/audio_test.gd/.tscn`, `scripts/entities/*`, `scripts/game/*`, `scripts/ui/*`.
- **Test & kết quả:** `--import`, K1, `tests/audio_test.tscn` (`AUDIO TEST OK`), K2 (`SMOKE TEST OK`).
- **Quyết định:** Tự tổng hợp `.wav` mono 22050 Hz bằng Python chuẩn thay vì tải gói CC0 bên ngoài, đảm bảo chủ động hoàn toàn và không phụ thuộc mạng.

### Phân tích Soul Knight & bổ sung thẻ G12–G16
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `13e669f`, `e306b42`, `61ea19b`
- **Tóm tắt:** Phân tích vòng lặp chiến đấu, âm thanh va chạm, vật cản che đạn và chế tạo binh khí từ nguồn công khai của Soul Knight, đề xuất và bổ sung 5 thẻ việc G12–G16 vào bảng kế hoạch.
- **Tệp chính:** `docs/PHAN-TICH-SOUL-KNIGHT.md`, `docs/GIAO-VIEC-GEMINI.md`, `project.godot`.

### G03 — Menu cài đặt và độ khó
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `a7c7e7c`, `2bbbdd9`, `d4ac2fe`
- **Tóm tắt:** Thêm màn cài đặt (`âm lượng Music/SFX`, rung màn hình, cần điều khiển cảm ứng, chọn độ khó Thường / Khó / Ác Mộng) truy cập được từ cả Menu chính lẫn Menu tạm dừng; nhân hệ số máu/giáp/sát thương địch theo độ khó.
- **Tệp chính:** `scripts/ui/settings_menu.gd`, `scripts/autoload/global.gd`, `scripts/data/enemies.gd`, `scripts/ui/main_menu.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/touch_controls.gd`, `tests/settings_test.gd/.tscn`.
- **Test & kết quả:** `tests/settings_test.tscn` (`SETTINGS TEST OK`), `run_save`, `audio`, K1, K2.
- **Lỗi gặp & sửa (`2bbbdd9`):** Test kiểm tra tỷ lệ máu/giáp theo hệ số độ khó ban đầu gãy do làm tròn ngẫu nhiên/làm tròn nguyên ở mức thấp; đã chỉnh test kiểm tra theo biên hợp lệ.

### G15 — Âm thanh va chạm
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `44b7a77`, `fdc6ebc`
- **Tóm tắt:** Bổ sung 7 hiệu ứng va chạm chuyên biệt (`hit_flesh`, `hit_bullet`, `hit_metal`, `hit_wall`, `hit_wood`, `hit_crit`, `hit_boss`) kèm bộ chống ồn debounce theo thời gian (`MIN_INTERVAL_MS := 50`) tránh chói tai khi trúng loạt đạn.
- **Tệp chính:** `tools/audio/build_audio.py`, `scripts/audio/sfx.gd`, `scripts/entities/bullet.gd`, `scripts/entities/enemy.gd`, `scripts/entities/player.gd`, `scripts/game/dummy.gd`, `tests/audio_test.gd`.
- **Test & kết quả:** `audio_test.tscn` (`AUDIO TEST OK`), `settings_test`, K1, K2.

### G14 — Gọn nhịp hầm ngục
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `995ed53`, `9c4cb0c`
- **Tóm tắt:** Tinh chỉnh số lượng và kích thước phòng chiến đấu trong `dungeon.gd` và số đợt giặc trong `room.gd` để nhịp đi qua mỗi màn nhanh, gọn và bớt đường vòng thừa.
- **Tệp chính:** `scripts/game/dungeon.gd`, `scripts/game/room.gd`, `tests/pacing_test.gd/.tscn`.
- **Test & kết quả:** `tests/pacing_test.tscn` (`PACING TEST OK`), K1, K2.

### G16 — Nguyên liệu rơi và Lò rèn binh khí
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `30316bc`, `93202f3`, `0380bf2`
- **Tóm tắt:** Chia làm 2 giai đoạn: Giai đoạn 1 thêm 6 loại nguyên liệu (`dong`, `sat`, `go_lim`, `hoa_duoc`, `yeu_hon`, `ngoc_than`) rơi từ quái/trùm/rương; Giai đoạn 2 mở Lò rèn binh khí ở Sảnh để chế tạo vũ khí bậc cao mang sẵn vào trận.
- **Tệp chính:** `scripts/data/materials.gd`, `scripts/autoload/global.gd`, `scripts/ui/lobby_ui.gd`, `scripts/game/lobby.gd`, `scripts/ui/hud.gd`, `scripts/entities/pickup.gd`, `tools/sprites/art_world.py`, `tests/craft_test.gd/.tscn`.
- **Test & kết quả:** `tests/craft_test.tscn` (`CRAFT TEST OK`), `run_save`, `settings`, `audio`, K1, K2.

### G17 — Đổi vũ khí bằng lăn chuột
- **Ngày / Người làm:** 24/11/2026 — Antigravity (Gemini)
- **Commit:** `ca90665`, `dd0c29f`
- **Tóm tắt:** Cho phép cuộn chuột lên/xuống để đảo vũ khí tức thì ngoài phím `Q` và chạm HUD, hỗ trợ cả trong sảnh lẫn trong trận và thêm `tests/input_test.tscn`.
- **Tệp chính:** `scripts/entities/player.gd`, `scripts/autoload/global.gd`, `scripts/game/room.gd`, `scripts/ui/lobby_ui.gd`, `tests/input_test.gd/.tscn`.
- **Test & kết quả:** `tests/input_test.tscn` (`INPUT TEST OK`), K1, K2.

### G18 — Đồng điệu binh khí và Ấn hệ
- **Ngày / Người làm:** 24–25/11/2026 — Antigravity (Gemini)
- **Commit:** `f7ab876`, `183ff7d`, `172ab12`
- **Tóm tắt:** Tạo `scripts/data/synergy.gd` tính mức Đồng điệu (`0 / 1 / 2 Tâm đắc`) giữa tướng và vũ khí đang cầm, đồng thời kích hoạt 6 Ấn hệ (`Kiếm khí`, `Trấn địa`, `Mưa tên`, `Hỏa ấn`, `Nạp đạn thần tốc`, `Linh khí`) cộng thêm khi tung chiêu.
- **Tệp chính:** `scripts/data/synergy.gd`, `scripts/data/heroes.gd`, `scripts/entities/player.gd`, `scripts/effects/*`, `scripts/ui/hero_select.gd`, `scripts/ui/hud.gd`, `scripts/ui/lobby_ui.gd`, `tests/synergy_test.gd/.tscn`.
- **Test & kết quả:** `tests/synergy_test.tscn` (`SYNERGY TEST OK`), `input`, `craft`, K1, K2.

### G19 — Tu luyện tướng và Rèn binh khí khởi đầu
- **Ngày / Người làm:** 25/11/2026 — Antigravity (Gemini)
- **Commit:** `c413e87`, `e641729`
- **Tóm tắt:** Tạo `scripts/data/progression.gd` cho phép tu luyện từng tướng 5 cấp (`+HP`, `+Giáp`, `+Năng lượng`, giảm hồi chiêu) và rèn nâng vũ khí khởi đầu qua 5 bậc kèm hình `_b3.png` và `_b5.png` phát sáng.
- **Tệp chính:** `scripts/data/progression.gd`, `scripts/autoload/global.gd`, `scripts/ui/lobby_ui.gd`, `scripts/entities/player.gd`, `tools/sprites/art_weapons.py`, `tests/progression_test.gd/.tscn`.
- **Test & kết quả:** `tests/progression_test.tscn` (`PROGRESSION TEST OK`), `synergy`, `craft`, `run_save`, K1, K2.

### G11a — Nhật ký trận (Bước 1)
- **Ngày / Người làm:** 25/11/2026 — Antigravity (Gemini)
- **Commit:** `adc08e8`, `a7eafa0`
- **Tóm tắt:** Ghi tự động lịch sử mỗi lượt chơi vào `save.json` (tướng, độ khó, màn cao nhất, lý do thua/thắng, thời gian, lượng sát thương/trận) làm căn cứ cân bằng cho Bước 2 sau khi nhóm bạn chơi thử thực tế.
- **Tệp chính:** `scripts/autoload/global.gd`, `scripts/entities/player.gd`, `scripts/entities/enemy.gd`, `scripts/game/game.gd`, `scripts/ui/settings_menu.gd`, `tests/log_test.gd/.tscn`.
- **Test & kết quả:** `tests/log_test.tscn` (`LOG TEST OK`), K1, K2.
- **Trạng thái:** Hoàn thành Bước 1; Bước 2 chờ thu thập số liệu thực tế từ nhóm chơi.

### G05 — Sửa lỗi nhỏ
- **Ngày / Người làm:** 25/11/2026 — Antigravity (Gemini)
- **Commit:** `03e87e1`, `a265691`
- **Tóm tắt:** Chặn đạn bay ra vùng tối ngoài tường, thêm hàng đợi thông báo HUD tránh chồng chữ giữa màn hình, bổ sung an toàn tương tác vật phẩm và giới hạn tiếng SFX.
- **Tệp chính:** `scripts/entities/bullet.gd`, `scripts/ui/hud.gd`, `scripts/entities/pickup.gd`, `scripts/entities/interactable.gd`, `scripts/game/station.gd`, `scripts/audio/sfx.gd`, `tests/bugfix_test.gd/.tscn`.
- **Test & kết quả:** `tests/bugfix_test.tscn` (`BUGFIX TEST OK`), `audio`, `craft`, `synergy`, `progression`, K1, K2.

### G04 — Đóng gói bản chơi cho bạn bè
- **Ngày / Người làm:** 25/11/2026 — Antigravity (Gemini)
- **Commit:** `ee0012f`, `69a316f`, `4da2724`, `996d987`
- **Tóm tắt:** Thiết lập `export_presets.cfg` cho **Windows Desktop** (`.exe`/`.pck`), **Android** (`.apk` debug-signed) và **macOS** (`.zip`), kèm hướng dẫn cài đặt chi tiết cho bạn bè trong `docs/HUONG-DAN-CAI.md`.
- **Tệp chính:** `export_presets.cfg`, `docs/HUONG-DAN-CAI.md`, `project.godot`.
- **Test & kết quả:** Xuất thử thành công `.exe`, `.pck` khởi động sạch với Godot `--main-pack`, `.apk`, `.zip` macOS; K1 & K2 đạt.

---

## 2. Các đợt mở rộng sau G17–G04 đến hiện tại (`25–26/11/2026`)

- **G12 — Vật cản che đạn thuần Việt (`3309f8f`, `12f2e98`, `557d261`):** Thêm cột đá, bia, bao cát, chum/hòm và thùng nổ (`cover.gd`) che đạn; bổ sung `tests/cover_test.tscn` (`COVER TEST OK`).
- **Thiết kế lại hầm ngục & ngoại cảnh (`07e9e07`):** Sinh phòng đa hình dạng, đa sắc theo chương và đổ bóng (`dungeon_rework_test.tscn`: `DUNGEON REWORK TEST OK`).
- **Đợt 3: G06, G08, G10, G13 (`f1101c6`):** Mã thử thách (`challenge_test`), vẽ lại 10 tướng chibi 32×32 + 16 khung hoạt ảnh (`hero_anim_test`), và phúc lành Hộ tâm kính (`hotamkinh_test`).
- **G09 & Game Feel (`6b7c30a`):** Tướng ẩn **Thánh Gióng** (`giong_test`), Thợ rèn dã chiến (`feel_smith_test`), thanh máu quái, hitstop, mũi tên chỉ đường.
- **Đợt 2: N1–N8 Chơi chung qua mạng LAN (`df77e08`, `1caa696`):** Hệ thống `Net`, `Discovery`, `NetSync` qua `ENetMultiplayerPeer` 2–4 người, host điều phối toàn bộ, cứu đồng đội gục ngã và kết nối lại giữa trận (`tests/lan_test.tscn`: `LAN TEST OK`).
- **Các bản nâng cấp nội dung & trải nghiệm (`v1.2.0` -> `v1.5.0`, chưa push lên GitHub):**
  - `f93b942`, `3bab7e4` (`v1.2.0`): Sạp thương nhân, 31 phúc lành (`merchant_buffs_test`), hệ thống tự cập nhật `.pck` (`updater_test`, `version.gd`).
  - `47d0db7`..`c754afc` (`v1.2.1`–`v1.2.9`): Doanh trại 4 phòng rộng (`lobby_rooms_test`), Vườn Thuốc Nam 3 ô, Công dụng Linh Thú đồng hành, Thương nhân nguyên liệu, cấu trúc 5 màn/chương kiểu Soul Knight (`3-6` Sảnh Khải Hoàn, `4-1..6-6` chương Thần Thoại).
  - `8c43fde`, `d1196f4`, `ac296cd` (`v1.2.10`–`v1.2.12`): Full-body hurtbox quái/trùm, AI né vật cản mượt, hoạt ảnh tay chân/lao tới/nhảy đập đất của Trùm, thẻ giới thiệu Trùm điện ảnh và bỏ mũi tên chỉ phòng/rương.
  - `94f3f2e`, `dfd7828`, `6461fa3` (`v1.3.0`): **Tầng Hầm Chiến Tích** với 24 thành tựu (`achievements.gd`), mở rộng kho lên **200 vũ khí** (`weapon_mods.gd`), biểu tượng phúc lành 32×32 & hoạt ảnh `BuffSelect`, sửa Z-order vũ khí khi quay lên trên (`v13_features_test`), workflow GitHub Actions build + ký ad-hoc macOS (`.github/workflows/build-macos.yml`), và chạy nhanh bằng `Shift` tiêu năng lượng.
  - `22c0003` (`v1.4.0`): 74 SFX (11 âm thanh chiêu riêng từng tướng + 32 nhóm vũ khí phủ 200 hồ sơ âm thanh riêng), mở rộng **190 bản vẽ vũ khí** bậc 1–5 (14 bản vẽ thành tựu + tự mở khi nhặt/Boss rơi) và công thức Bậc 5 ★ Huyền Thoại đắt đỏ (`850 xu` + nguyên liệu hiếm), nâng cấp UI Bàn Bản Vẽ & Lò Rèn (`v14_audio_blueprints_test`).
  - `9ff7949` (`v1.5.0`, `HEAD` hiện tại): 14 bản nhạc nền ngũ cung/sử thi (33.75s–45.18s) crossfade 2 kênh chuyển liên tục qua từng màn, phòng chiến đấu, Tầng Hầm, Trùm/Trùm Thần Thoại/Tam Yêu, bùng nổ `boss_frenzy` ở Pha 2, kèm thẻ `♪ <Tên bản nhạc>` ở góc dưới phải HUD (`v15_dynamic_bgm_test`).

---

## 3. Bẫy kỹ thuật mới gặp trên Windows / Antigravity

1. **Sandbox chặn `%APPDATA%` (`user://`):** Khi chạy Godot test trong môi trường hạn chế quyền ghi `AppData`, phải gán `$env:APPDATA` và `$env:LOCALAPPDATA` sang thư mục tạm ngoài workspace (hoặc `Global.save_path`), rồi **nhớ khôi phục lại `$env:APPDATA` thật trước khi chạy `--export-*`** để Godot tìm thấy thư mục `export_templates`.
2. **Lệnh `python` trỏ nhầm Microsoft Store:** Trên máy Windows này gõ `python` dễ mở stub Microsoft Store (trả exit code 49/9009). Luôn dùng **`py`** hoặc đường dẫn Python cài đặt trực tiếp.
3. **Xuống dòng `CRLF` vs `LF`:** Nhiều tệp `.gd`/`.md` trên Windows dùng `CRLF`; giữ nguyên định dạng file đang có và cấu hình so khớp/patch không nhầm dấu kết thúc dòng để tránh diff nhiễu.
4. **Tệp `.uid` do Godot 4.7 tự sinh:** Mỗi khi tạo script mới hoặc chạy `--import`, Godot tự sinh `<file>.gd.uid`. Khi thêm script hay xóa script test tạm (`_tmp_*`), nhớ xử lý/dọn cả tệp `.uid` tương ứng để tránh rác Git.
5. **Khác biệt `core.fileMode`:** Nếu làm việc chéo WSL/Linux và Windows dễ nhảy trạng thái thay đổi quyền thực thi file; trên Windows nên giữ `git config core.fileMode false`.
6. **PowerShell 5.1 & chính sách binary chưa ký:** PowerShell 5.1 **không hỗ trợ `&&`** (phải dùng `;` kèm kiểm tra `$LASTEXITCODE`). Ngoài ra, chạy trực tiếp file `.exe` chưa ký số có thể bị Windows Application Control chặn cục bộ — muốn kiểm tra `.pck` vừa export, boot qua `Godot_v4.7.2-stable_win64_console.exe --headless --main-pack build\AnhHungDatViet.pck --quit`.
7. **Hai test cũ đang cần rà soát khi mở rộng thêm:** Hiện tại `cover_test.tscn` báo lỗi vật cản màn hiện đại 25 và `updater_test.tscn` kiểm tra cứng `build == 130` (do `version.gd` đã lên `160`), cần lưu ý nếu chạy trọn gói cả 24 test phụ.
