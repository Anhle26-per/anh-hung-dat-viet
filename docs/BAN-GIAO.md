# Biên bản bàn giao dự án

Ngày bàn giao đầu: 24/11/2026 | Cập nhật hiện trạng cho Claude: 26/11/2026
Bên bàn giao: Antigravity (Gemini) tổng hợp lại cho Claude (quản lý) và chủ dự án

> **Đọc theo thứ tự:**
> 1. `CLAUDE.md` — Tóm tắt môi trường, vai trò, danh sách test và việc mở phiên.
> 2. Tệp này (`docs/BAN-GIAO.md`) — Kiến trúc mã, quyết định đã chốt, bẫy kỹ thuật và việc còn lại.
> 3. `AGENTS.md` — Luật kỹ thuật bắt buộc.
> 4. `docs/GIAO-VIEC-GEMINI.md` — Bảng 0b và danh sách thẻ việc.

---

## 1. Dự án là gì

**Anh Hùng Đất Việt** là game roguelike bắn súng góc nhìn từ trên xuống, pixel art, cảm hứng từ Soul Knight.
- Người chơi điều khiển các anh hùng Việt Nam (năm 40 đến năm 1954), đánh quân xâm lược qua các trận đánh lịch sử.
- Có thêm yêu quái dân gian là phần hư cấu.
- Làm bằng **Godot 4.7, GDScript**.
- Toàn bộ hình vẽ và âm thanh sinh ra từ **mã Python** trong `tools/sprites/` và `tools/audio/`. Không dùng tài nguyên lậu của game khác.

## 2. Các quyết định đã chốt (không tự ý đổi)

| Quyết định | Lý do |
|---|---|
| Chỉ chơi trong nhóm bạn bè, **không phát hành công khai** | Chủ dự án chốt ngày 24/11/2026 |
| Có 2 cách chơi: **một mình** và **chơi chung qua wifi nhà (LAN)**, 2–4 người | Chủ dự án chọn |
| **Không** quảng cáo, mua trong game, đăng nhập hay máy chủ Internet | Không phát hành nên không cần |
| Hàm `Global.show_rewarded_ad()` còn giữ: nó gọi thẳng phần thưởng, không có quảng cáo thật | Đường hồi sinh lần 2 đang dùng hàm này. Giữ nguyên hoặc đổi tên sau, không cần nối quảng cáo |
| Máy chơi: Windows là chính; Android cài `.apk` tay; macOS có workflow build + ký ad-hoc | Chủ dự án bổ sung |
| Dòng thời gian dừng ở **năm 1954** | Tránh nội dung quá gần và nhạy cảm |
| "Chiến sĩ Điện Biên" là hình tượng chung, không phải người thật | Tránh vẽ người thật |
| Trùm là tướng giặc có thật, "hiện nguyên hình" thành quỷ là **hư cấu tà thuật** | Tăng kịch tính; ghi rõ là hư cấu |
| Trùm **ra ngẫu nhiên**, sức mạnh tăng theo **thứ tự gặp**, không theo từng con | Chủ dự án yêu cầu |
| Thư mục làm việc trên máy chủ dự án: `D:\Games\anh-hung-dat-viet` | Chủ dự án chọn |

## 3. Trạng thái hiện tại (sau đợt G17–G04 và nâng cấp v1.2.0–v1.5.0)

**Đã xong và đã kiểm thử đến mốc `v1.5.0` (`9ff7949`, chưa push lên GitHub):**
- **Đợt 1 (G01–G19, G04, G05) đã hoàn tất:** Lưu giữa lượt (`user://run.json`), hệ thống âm thanh/va chạm (`Sfx`), menu cài đặt & 3 độ khó, gọn nhịp hầm ngục, 6 nguyên liệu rơi & Lò rèn binh khí, đổi vũ khí bằng lăn chuột, Đồng điệu binh khí & 6 Ấn hệ (`synergy.gd`), Tu luyện tướng 5 cấp & rèn vũ khí khởi đầu 5 bậc (`progression.gd`), sửa lỗi nhỏ, đóng gói Windows `.exe`/`.pck`, Android `.apk`, macOS `.zip` (kèm workflow GitHub Actions tự build + ký ad-hoc macOS).
- **Đợt 2 (N1–N8 LAN) đã hoàn tất:** Chơi chung qua wifi LAN (2–4 người) theo kiến trúc host-authority (`ENetMultiplayerPeer` + tìm phòng `Discovery` + đồng bộ `NetSync`), hỗ trợ cứu đồng đội gục ngã và kết nối lại giữa trận (`lan_test.tscn`: `LAN TEST OK`).
- **Đợt 3 & mở rộng `v1.2.0`–`v1.5.0`:**
  - **11 tướng anh hùng** (10 tướng lịch sử + tướng ẩn Thánh Gióng) với bộ chibi 32×32 và 16 khung hoạt ảnh riêng, lướt nhanh bằng `Shift` tiêu năng lượng.
  - **200 vũ khí** thuộc 5 bậc (gồm **190 bản vẽ** chế tạo tại Bàn Bản Vẽ/Lò Rèn: 14 bản vẽ thành tựu + bản vẽ nhặt/rớt từ Boss, công thức Bậc 5 ★ Huyền thoại đòi hỏi cao).
  - **10 chương lịch sử + các chương Thần Thoại (`4-1..6-6`)** theo cấu trúc Soul Knight (5 màn/chương, Sảnh Khải Hoàn `3-6`, Sảnh Huyền Thoại `6-6`), vật cản thuần Việt che đạn, 31 phúc lành 32×32, Thợ rèn dã chiến, Thương nhân & Thương nhân nguyên liệu, mã thử thách (`challenge_test`), tự cập nhật `.pck` (`updater.gd`).
  - **Doanh trại 4 phòng + Tầng Hầm Chiến Tích:** Vườn Thuốc Nam 3 ô, Linh Thú đồng hành (4 thú cưng có công dụng thật), hệ thống 24 mốc thành tựu (`achievements.gd`).
  - **Âm thanh & Nhạc nền (`v1.4.0`–`v1.5.0`):** 74 SFX (11 âm thanh chiêu riêng từng tướng + 32 nhóm âm thanh tạo hồ sơ riêng cho toàn bộ 200 vũ khí) và **14 bản nhạc nền** ngũ cung/sử thi crossfade 2 kênh thay đổi liên tục qua từng màn, từng phòng chiến đấu, pha Boss/Tam Yêu/Thần Thoại và bùng nổ `boss_frenzy` ở Pha 2, kèm thẻ tên nhạc trên HUD.

**Kết quả test gần nhất (cô lập `%APPDATA%`):**

| Lệnh | Kết quả |
|---|---|
| K1 (`check_scripts`) | `KIỂM TRA XONG: 0 lỗi` |
| `v15_dynamic_bgm`, `v14_audio_blueprints`, `v13_features` | Toàn bộ `... TEST OK` |
| `audio`, `craft`, `lobby_rooms`, `lan`, `progression`, `synergy`, `settings`, `run_save`, `log`, `bugfix`, `challenge`, `giong`, `hero_anim`, `hotamkinh`, `input`, `pacing`, `dungeon_rework`, `feel_smith`, `merchant_buffs` | Đều `... TEST OK` (22/24 test nhanh đạt; xem ghi chú mục 7 về `cover_test` và `updater_test`) |

**Git:** Nhánh `main` đang ở `9ff7949` (tag cục bộ `v1.5.0`, chưa push lên GitHub). Xem lịch sử từng thẻ tại `docs/NHAT-KY-DU-AN.md`.

## 4. Kiến trúc mã

### Luồng màn hình
`main_menu.tscn` (Chơi tiếp / Bỏ lượt / Vào doanh trại / Chơi LAN / Cài đặt) → `lobby.tscn` (Doanh trại 4 phòng + Tầng Hầm Chiến Tích) → `game.tscn` (trận đánh).

Các tệp `.tscn` chỉ có 1 nút gốc gắn script. **Mọi thứ khác đều tạo bằng mã** trong `_ready()`. Bốn Autoload trong `project.godot`: `Updater`, `Global`, `Sfx`, `Net`.

### Autoload `Global` (`scripts/autoload/global.gd`), Cài đặt & Nhật ký trận
- **Dữ liệu lưu lâu dài (`user://save.json`):** `coins`, `best_level`, `unlocked`, `upgrades`, `discovered`, `blueprints`, `materials`, `hero_levels`, `weapon_ranks`, `achievements`, `selected_hero`, `selected_pet`, `garden_plots`, `settings`, `run_logs`, `challenge_scores`.
- **Trạng thái lượt chơi & lưu giữa lượt (`user://run.json`):** `level`, `run_coins`, `run_buffs`, `revived`, `free_revives`, `boss_order`, `legend_last`, `legend_chance`, `challenge_code`, `save_run()`, `peek_run()`, `load_run()`, `clear_run()`, `abandon_run()`, `run_path()`.
- **Menu cài đặt & Độ khó (`scripts/ui/settings_menu.gd`):** Chỉnh âm lượng `Music`/`SFX`, rung màn hình, cảm ứng, xem nhật ký trận và chọn độ khó (Thường / Khó / Ác Mộng — nhân hệ số lên máu/giáp/sát thương quái).
- **Nhật ký trận (G11 bước 1):** Tự ghi tóm tắt mỗi lượt kết thúc (`_append_run_log()` / `run_logs`) làm dữ liệu đầu vào cho thẻ G11 bước 2.
- **Bản vẽ & Khám phá (`v1.4.0`):** `discover()` tự mở bản vẽ cho các vũ khí thường (trừ 14 bản vẽ thành tựu), `roll_boss_blueprint(mythic)` rơi bản vẽ mới khi hạ Trùm, `can_craft()`/`try_craft()` kiểm tra theo công thức từng bậc.

### Âm thanh & Nhạc nền (`scripts/audio/sfx.gd`, `tools/audio/build_audio.py`)
- Hai bus riêng `Music` và `SFX`, giới hạn 8 giọng SFX đồng thời, debounce va chạm `MIN_INTERVAL_MS := 50`.
- **74 SFX** (`SFX_FILES`): gồm 11 âm thanh kỹ năng riêng (`skill_<hero_id>`, gọi qua `Sfx.play_skill()`), 32 nhóm vũ khí kết hợp pitch/âm lượng tính theo hash + bậc vũ khí tạo 200 hồ sơ âm thanh riêng (`weapon_sfx_profile()`, `play_weapon()`), và 7 âm thanh va chạm.
- **14 BGM** (`MUSIC_FILES` / `MUSIC_TITLES`): phát qua 2 kênh `_music_a`/`_music_b` có crossfade mượt, phát tín hiệu `music_changed(track_id, title)` cho HUD; tự chuyển bài qua `stage_music_id(level, room_seq)` (xoay vòng mỗi màn & mỗi phòng chiến đấu) và `boss_music_id(level, kind, enraged)` (đẩy lên `boss_frenzy` khi Trùm Pha 2 / nổi giận).

### Dữ liệu (`scripts/data/`): mọi nội dung nằm ở đây
- `heroes.gd`: `ORDER`, `DATA` (11 anh hùng, thời kỳ, vũ khí cơ bản, kỹ năng, chỉ số, giá mở khóa).
- `weapons.gd` & `weapon_mods.gd`: 200 vũ khí 5 bậc; kiểu `melee`, `ranged`, `beam`, `wave`, `spikes`; `TIER_NAMES`, `TIER_COLORS`, `roll()`, `grip()`.
- `materials.gd`: 6 nguyên liệu (`ORDER := ["dong", "sat", "go_lim", "hoa_duoc", "yeu_hon", "ngoc_than"]`), quản lý 190 vũ khí chế tạo được (`all_blueprint_weapons()`, `is_achievement_blueprint()`), công thức 5 bậc (`RECIPES`, `recipe_for()` — Bậc 5 ★ Huyền thoại tốn 850 xu + lượng lớn nguyên liệu hiếm).
- `synergy.gd`: Đồng điệu binh khí (`0 / 1 / 2 Tâm đắc`) và 6 Ấn hệ (`kiem`, `truong`, `cung_no`, `hoa_khi`, `sung`, `than_khi`).
- `progression.gd`: Tu luyện tướng 5 cấp và rèn binh khí khởi đầu 5 bậc (`effective_weapon()`).
- `achievements.gd`: 24 mốc thành tựu kèm phần thưởng nguyên liệu và 14 bản vẽ thành tựu tại Tầng Hầm Chiến Tích.
- `enemies.gd`: `ARCHETYPES`, `FOLK`, `BOSSES`, `MYTHIC_BOSSES`, `LEGENDS`, `CHAPTERS`, `MYTHIC_CHAPTERS`.
- `buffs.gd`: 31 phúc lành, phân hệ & độ hiếm.
- `version.gd`: `VERSION`, `BUILD`, địa chỉ GitHub Releases cho `updater.gd`.

### Thực thể, Trò chơi, Giao diện & Mạng LAN
- **`player.gd`:** Di chuyển + chạy nhanh `Shift` (tiêu năng lượng), lăn chuột đổi vũ khí, tự ngắm cảm ứng/tay cầm, 6 kiểu đánh, 11 kỹ năng gắn Đồng điệu & Ấn hệ, Z-order vũ khí khi quay lên, bắn qua `Sfx.play_weapon()`/`play_skill()`.
- **`enemy.gd`:** Đầy đủ hitbox toàn thân, AI né tách mượt, hoạt ảnh lao tới & nhảy đập đất của Trùm, biến hình Pha 2 / nổi giận kích hoạt `boss_frenzy`, `_drop_loot()` rơi nguyên liệu & bản vẽ Trùm.
- **`cover.gd`, `bullet.gd`, `trap.gd`, `loot_chest.gd`, `pet.gd`:** Vật cản che đạn thuần Việt & thùng nổ, đạn gây cháy/độc/âm thanh va chạm, bẫy phòng, rương sơn mài, thú cưng đồng hành.
- **`game/dungeon.gd`, `game/room.gd`, `game/game.gd`, `game/lobby.gd`:** Sinh hầm ngục 5 màn/chương & các chương Thần Thoại, đổi nhạc theo từng phòng chiến đấu và phòng Trùm, chuyển cảnh Tầng Hầm Chiến Tích và Vườn Thuốc Nam.
- **`ui/hud.gd`, `ui/lobby_ui.gd`, `ui/buff_select.gd`:** Giao diện HUD (kèm thẻ tên bản nhạc `♪`), Bàn Bản Vẽ 190 món & Lò Rèn, vòng chọn phúc lành có hoạt ảnh, bảng giới thiệu Trùm điện ảnh.
- **`net/` (`net.gd`, `discovery.gd`, `net_sync.gd`):** Chơi LAN `ENetMultiplayerPeer` cổng 7777, tối đa 4 người, host giữ trạng thái giặc/rương/cổng/vật phẩm.
- **`autoload/updater.gd`:** Kiểm tra & tải bản vá `.pck` qua `version.json` trên GitHub Releases.

## 5. Hệ thống đồ họa (`tools/sprites/`)

- **Vẽ lại toàn bộ:** chạy `py tools/sprites/build_all.py`, rồi `py tools/sprites/artbook.py` (sách tranh trong `docs/artbook/`), rồi `Godot --headless --path . --import`.
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
| Tướng `heroes/<id>.png` | 32×32 | 0–3 đứng, 4–7 đi, 8 bị đánh (bản mới 512×32 gồm 16 khung) |
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
8. **Sau khi thêm hoặc đổi PNG/WAV, phải chạy `--import`.** Nếu không, Godot vẫn dùng tài nguyên cũ trong thư mục `.godot/`.
9. **`change_scene_to_file()` xóa luôn cảnh đang chạy**, kể cả script đang gọi nó. Muốn chụp màn hình hay test tiếp thì thêm cảnh mới vào `get_tree().root`.
10. **`JSON.parse_string()` in lỗi đỏ khi tệp hỏng.** Dùng `JSON.new().parse()` như `Global._read_json()`.
11. **K2 phải chạy với `--fixed-fps 60`.** Nếu không, test chạy theo thời gian thật nên rất lâu và có thể hết giờ.
12. **Sandbox chặn `%APPDATA%` (`user://`):** Test ghi `user://` phải chạy ngoài sandbox hoặc đặt `$env:APPDATA` tạm thời; luôn khôi phục `$env:APPDATA` thật trước khi chạy `--export-*`.
13. **Lệnh `python` trên Windows trỏ nhầm Microsoft Store:** Phải gọi **`py`** (hoặc đường dẫn Python thật) thay vì `python`.
14. **Xuống dòng `CRLF`, tệp `.uid` và `core.fileMode`:** Godot 4.7 tự tạo tệp `.gd.uid`; nhớ xóa cặp `.uid` nếu xóa script tạm, giữ `core.fileMode false` trên Windows và thống nhất CRLF/LF.
15. **PowerShell 5.1 & chạy `.exe` chưa ký:** PowerShell 5.1 không hỗ trợ `&&` (dùng `;` và kiểm tra `$LASTEXITCODE`). Nếu Windows Application Control chặn chạy trực tiếp `.exe` chưa ký, kiểm thử `.pck` qua `Godot --headless --main-pack`.

## 7. Kiểm thử

| Lệnh | Tác dụng | Thời gian |
|---|---|---|
| `tools\run_tests.bat nhanh` / `bash tools/run_tests.sh nhanh` | K1: biên dịch mọi script (`KIỂM TRA XONG: 0 lỗi`) | khoảng 10 giây |
| `tools\run_tests.bat <ten>` | K1 + chạy `tests/<ten>_test.tscn` | 5–20 giây |
| `tools\run_tests.bat` / `bash tools/run_tests.sh` | K1 + K2: máy tự chơi hết game (`SMOKE TEST OK`) | 15–25 phút |

**Danh sách đầy đủ 24 test riêng hiện có trong `tests/`:**
- Nền tảng & Đợt 1–3: `run_save`, `audio`, `settings`, `pacing`, `craft`, `input`, `synergy`, `progression`, `log`, `bugfix`, `lan`, `challenge`, `cover`, `hero_anim`, `hotamkinh`, `giong`, `feel_smith`.
- Mở rộng `v1.2.0`–`v1.5.0`: `merchant_buffs`, `updater`, `lobby_rooms`, `dungeon_rework`, `v13_features`, `v14_audio_blueprints`, `v15_dynamic_bgm`.
- *(Lưu ý kỹ thuật: `cover_test` đang có lỗi ở vật cản màn hiện đại 25 và `updater_test` còn so sánh cứng `build == 130` với `version.gd` mới — cần lưu ý hoặc cập nhật khi đụng tới 2 mảng này).*

Cách viết test mới:
- Đặt tên `tests/<ten>_test.gd` + `.tscn`.
- Đạt thì in `<TÊN> TEST OK` và `quit(0)`; lỗi thì `quit(1)`.
- Có bộ đếm giờ tự dừng để không treo mãi và đổi `Global.save_path` sang tệp tạm.

## 8. Việc còn lại (theo bảng 0b trong `docs/GIAO-VIEC-GEMINI.md`)

Tất cả các thẻ Đợt 1 (`G01`–`G19`, `G04`, `G05`), Đợt 2 (`N1`–`N8 LAN`) và phần lớn Đợt 3 (`G06`, `G08`, `G09`, `G10`, `G12`, `G13`) đều đã **Xong**. Theo bảng 0b chỉ còn lại:
1. **G07 — Hướng dẫn chơi lần đầu:** chưa làm.
2. **G11 (Bước 2) — Cân bằng độ khó theo phản hồi thực tế của nhóm chơi:** Bước 1 (`run_logs`) đã xong, đang chờ số liệu thực tế từ nhóm bạn.
3. *(Ngoài bảng 0b)* Các ý tưởng mở rộng mới đang tổng hợp ở `docs/Y-TUONG.md` (trạng thái **Chờ chủ dự án chọn**) và các commit từ `v1.3.0` đến `v1.5.0` hiện đang nằm cục bộ trên `main`, chờ lệnh của chủ dự án trước khi `git push`.

## 9. Quy trình làm việc

1. Gemini tự tạo nhánh `gemini/<mã thẻ>` từ `main` (hoặc điều phối `/swarm` khi cần).
2. Đọc `CLAUDE.md`, `AGENTS.md` và thẻ việc, triển khai và chạy K1 + test riêng + K2 đến khi đạt.
3. Test đạt thì tự `git add`, `git commit`, gộp về `main`, cập nhật cột "Trạng thái" trong bảng 0b thành **Xong <ngày>** và cập nhật `docs/NHAT-KY-DU-AN.md`. **KHÔNG `git push` khi chưa có lệnh của chủ dự án**, không `--force`, không viết lại lịch sử, không xóa nhánh `main`.
4. Gửi báo cáo theo mục 10 của `AGENTS.md`.
