# Bảng giao việc cho Gemini

Cập nhật: 24/11/2026. Người lập: "sếp" dự án (Claude).

## 0. Định hướng đã chốt

- Game **chỉ để chủ dự án và bạn bè chơi**, không phát hành lên cửa hàng.
  - Bỏ hẳn: quảng cáo, mua trong game, tài khoản Google Play, thủ tục 12 người thử × 14 ngày, giấy tờ Nghị định 147, bản tiếng Anh.
- Hai cách chơi:
  1. **Chơi một mình**: giữ nguyên như hiện tại, làm cho tiện và hay hơn.
  2. **Chơi chung qua wifi nhà (LAN)**: 2–4 người, mỗi người một máy, cùng mạng wifi. Không cần máy chủ Internet.
- Máy chơi: máy tính Windows là chính. Điện thoại Android cài file `.apk` gửi tay vẫn chơi LAN chung được. iPhone thì không làm, vì cần máy Mac và tài khoản Apple.

## 0b. Bảng theo dõi toàn bộ việc còn lại

Đây là **tất cả** những việc chưa làm của dự án. Sau khi test đạt và gộp nhánh vào `main`, Gemini tự sửa cột "Trạng thái" thành **Xong** kèm ngày và commit vào git. Gemini cũng phải đọc bảng này để biết thẻ nào đã xong.

| Thẻ | Việc | Đợt | Phụ thuộc | Trạng thái |
|---|---|---|---|---|
| G01 | Lưu giữa lượt, giữ xu khi thoát | 1 | — | **Xong** 24/11/2026 (Claude làm, đã qua K1, run_save, K2) |
| G02 | Âm thanh và nhạc nền (CC0) | 1 | — | **Xong** 24/11/2026 (Gemini làm, tự sinh WAV, đã qua K1, audio, K2) |
| G03 | Menu cài đặt và độ khó | 1 | G02 (âm lượng) | **Xong** 24/11/2026 (Gemini làm, đã qua K1, settings, run_save, audio, K2) |
| G15 | Âm thanh va chạm | 1 | G02, G03 | **Xong** 24/11/2026 (Gemini làm, đã qua K1, audio, settings, K2) |
| G14 | Gọn nhịp hầm ngục | 1 | — | **Xong** 24/11/2026 (Gemini làm, đã qua K1, pacing, K2) |
| G16 | Nguyên liệu rơi và Lò rèn binh khí | 1 | G01, G02 | **Xong** 24/11/2026 (Gemini làm, đã qua K1, craft, run_save, settings, audio, K2) |
| G17 | Đổi vũ khí bằng lăn chuột | 1 | — | **Xong** 24/11/2026 (Gemini làm, đã qua K1, input, K2) |
| G18 | Đồng điệu binh khí và Ấn hệ | 1 | G17 | **Xong** 25/11/2026 (Gemini làm, đã qua K1, synergy, input, craft, K2) |
| G19 | Tu luyện tướng và rèn binh khí khởi đầu | 1 | G16, G18 | **Xong** 25/11/2026 (Gemini làm, đã qua K1, progression, synergy, craft, run_save, K2) |
| G04 | Đóng gói `.exe` / `.apk` gửi bạn bè | 1 | — | Chưa làm |
| G05 | Sửa lỗi nhỏ (đạn bay vùng tối, chữ chồng nhau) | 1 | — | Chưa làm |
| N1 | Menu mạng và phòng chờ LAN | 2 | G04 | Chưa làm |
| N2 | Nhiều người chơi trong cùng màn | 2 | N1 | Chưa làm |
| N3 | Giặc do host điều khiển | 2 | N2 | Chưa làm |
| N4 | Đạn và đòn đánh trong mạng | 2 | N3 | Chưa làm |
| N5 | Phòng, rương, vật phẩm, cửa hàng, qua màn | 2 | N4 | Chưa làm |
| N6 | Kỹ năng tướng trong mạng | 2 | N4 | Chưa làm |
| N7 | Gục ngã và cứu đồng đội | 2 | N5 | Chưa làm |
| N8 | Rớt mạng và hoàn thiện LAN | 2 | N7, G01 | Chưa làm |
| G06 | Mã thử thách và bảng điểm so tài | 3 | — | Chưa làm |
| G07 | Hướng dẫn chơi lần đầu | 3 | — | Chưa làm |
| G08 | Vẽ lại tướng đầu to kiểu chibi | 3 | — | Chưa làm |
| G09 | Nội dung mới theo ý nhóm (mỗi món một thẻ) | 3 | — | Chưa làm |
| G10 | Hoạt ảnh tấn công, kỹ năng, chết riêng cho từng tướng | 3 | G08 (nên làm sau) | Chưa làm |
| G12 | Vật cản che đạn thuần Việt | 3 | G15 | Chưa làm |
| G13 | Phúc lành Hộ tâm kính | 3 | — | Chưa làm |
| G11 | Cân bằng độ khó theo phản hồi của nhóm chơi | 1–3 | G03, G04 | Bước 1 xong, chờ số liệu |

**Đã xong trước khi giao cho Gemini** (không cần làm lại):
- Toàn bộ lối chơi một mình: 10 tướng, 67 vũ khí, 30 màn, 10 trùm có hiện nguyên hình, Tam Yêu.
- Sảnh, rương, gánh hàng rong, cháy và độc.
- Bài test tự động, `AGENTS.md`, script `tools/run_tests`.

**Đã bỏ vì không phát hành công khai:** quảng cáo, mua trong game, Google Play, bản tiếng Anh, giấy tờ pháp lý.

## 1. Chuẩn bị của chủ dự án (làm một lần)

1. **Sao lưu:** nén cả thư mục thành `anh-hung-dat-viet-goc.zip`, để ngoài thư mục dự án.
2. **Cài Git, rồi trong thư mục dự án chạy:**
   ```bash
   git init
   ```
   ```bash
   git add -A
   ```
   ```bash
   git commit -m "Mốc gốc trước Gemini"
   ```
   File `.gitignore` đã có sẵn.
3. **Kiểm tra `AGENTS.md`** ở gốc dự án. File này đã có sẵn, kèm bản sao `GEMINI.md`. Sửa dòng "Lệnh Godot trên máy này" cho đúng máy bạn.
4. **Cài Python 3 và Pillow** để vẽ lại hình:
   ```bash
   pip install pillow
   ```
5. **Chạy thử 2 lệnh test một lần** để biết máy bạn chạy được (xem mục 3 của AGENTS.md).
6. **Cài công cụ Gemini:** từ giữa năm 2026, Google khuyên dùng **Antigravity** (ứng dụng máy tính hoặc lệnh `agy`) cho tài khoản cá nhân. Gemini CLI cũ không còn phục vụ tài khoản cá nhân miễn phí.
   - Đây là thông tin từ đợt nghiên cứu, chưa kiểm chứng tận tay, nên bạn xem lại trang chính thức trước.
   - Mở đúng thư mục dự án.
   - Để chế độ **hỏi trước khi chạy lệnh**.
7. **Quy trình mỗi thẻ việc:**
   1. Gemini tự tạo nhánh mới từ `main`, ví dụ:
      ```bash
      git switch -c gemini/G02
      ```
   2. Gemini đọc `AGENTS.md` và thẻ việc trong `docs/GIAO-VIEC-GEMINI.md`, triển khai trực tiếp (không cần chờ chủ dự án gõ đồng ý; kế hoạch ghi trong báo cáo cuối).
   3. Gemini chạy K1 sau mỗi lần sửa `.gd`, chạy test riêng của thẻ, và chạy K2 ở cuối cho đến khi đạt `SMOKE TEST OK`.
   4. Khi mọi test bắt buộc đã đạt, Gemini tự commit và gộp nhánh vào `main`:
      ```bash
      git add -A
      ```
      ```bash
      git commit -m "<mã thẻ>: <mô tả>"
      ```
      ```bash
      git switch main
      ```
      ```bash
      git merge gemini/G02
      ```
   5. Gemini cập nhật cột Trạng thái trong bảng 0b thành **Xong <ngày>** và commit lại; không `git push`, không `--force`, không xóa nhánh `main`.
   6. Nếu không đạt hoặc có lỗi không tự sửa được thì báo cáo rõ; chủ dự án có thể đối chiếu theo **danh sách kiểm tra ở mục 6**.

**Hai lệnh test dùng chung** (chi tiết trong AGENTS.md):
- **K1**: kiểm tra biên dịch, đạt khi in `KIỂM TRA XONG: 0 lỗi`.
- **K2**: máy tự chơi 10 tướng, 30 màn, đạt khi in `SMOKE TEST OK`.

**Thang độ lớn của thẻ việc:**

| Mức | Khối lượng |
|---|---|
| S | ≤ 100 dòng, 1 phiên |
| M | 100–300 dòng, 1–2 phiên |
| L | 300–700 dòng, chia 2–3 phiên |

## 1b. Lệnh test (chép dán dùng ngay)

### Cách nhanh nhất: chạy script có sẵn
| Máy | Lệnh | Làm gì |
|---|---|---|
| Windows | `tools\run_tests.bat nhanh` | Chỉ K1, kiểm tra biên dịch (khoảng 10 giây) |
| Windows | `tools\run_tests.bat` | K1 + K2, máy tự chơi hết game (15–25 phút) |
| Windows | `tools\run_tests.bat run_save` | K1 + test riêng `tests/run_save_test.tscn` |
| Linux/Mac | `bash tools/run_tests.sh nhanh` | Chỉ K1 |
| Linux/Mac | `bash tools/run_tests.sh` | K1 + K2 |
| Linux/Mac | `bash tools/run_tests.sh lan` | K1 + test riêng `tests/lan_test.tscn` |

- Lần đầu trên Windows: mở `tools\run_tests.bat` bằng Notepad, sửa dòng `set GODOT=...` cho đúng đường dẫn tới **`Godot_v4.7.2-stable_win64_console.exe`**. Dùng bản `_console`, vì bản thường không in chữ ra màn hình.
- Trên Linux/Mac: nếu lệnh `godot` không có sẵn, chạy kiểu `GODOT=/duong/dan/godot bash tools/run_tests.sh`.
- Kết quả chi tiết nằm trong thư mục `logs/`: `k1.txt`, `smoke.txt`, `<ten>.txt`.
- Script `.bat` được viết theo cú pháp chuẩn nhưng **chưa chạy thử trên Windows thật**. Nếu báo lỗi lạ, chạy các lệnh đầy đủ bên dưới.

### Lệnh đầy đủ, chạy từ thư mục dự án

**Windows (PowerShell).** Đặt đường dẫn Godot một lần cho mỗi cửa sổ:
```powershell
$GODOT = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
```

K1, kiểm tra biên dịch. Đạt khi in `KIỂM TRA XONG: 0 lỗi`:
```powershell
& $GODOT --headless --path . res://tests/check_scripts.tscn
```

K2, máy tự chơi (15–25 phút). Đạt khi file log có `SMOKE TEST OK`:
```powershell
mkdir logs -Force; & $GODOT --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn *> logs\smoke.txt; Select-String "SMOKE TEST|THẤT BẠI|SCRIPT ERROR" logs\smoke.txt
```

Test riêng của một thẻ, ví dụ G01:
```powershell
& $GODOT --headless --path . res://tests/run_save_test.tscn
```

Nhập tài nguyên mới (sau khi thêm âm thanh hoặc ảnh):
```powershell
& $GODOT --headless --path . --import
```

**Linux / macOS:**
```bash
godot --headless --path . res://tests/check_scripts.tscn
```
```bash
mkdir -p logs && godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn > logs/smoke.txt 2>&1; grep -E "SMOKE TEST|THẤT BẠI|SCRIPT ERROR" logs/smoke.txt
```
```bash
godot --headless --path . res://tests/run_save_test.tscn
```
```bash
godot --headless --path . --import
```

**Vẽ lại toàn bộ hình** (sau khi sửa `tools/sprites/*.py`), rồi chạy lệnh nhập tài nguyên ở trên:
```bash
python3 tools/sprites/build_all.py
```
```bash
python3 tools/sprites/artbook.py
```

### Test của từng thẻ việc

| Thẻ | Lệnh test bắt buộc | Dòng phải thấy |
|---|---|---|
| G01 | K1 → `run_tests run_save` → K2 | `RUN SAVE TEST OK`, `SMOKE TEST OK` |
| G02 | `--import` → K1 → `audio` → K2 | `0 lỗi`, `AUDIO TEST OK`, `SMOKE TEST OK` |
| G03 | K1 → `settings` → `run_save` → `audio` → K2 | `SETTINGS TEST OK`, `RUN SAVE TEST OK`, `AUDIO TEST OK`, `SMOKE TEST OK` |
| G15 | `py tools/audio/build_audio.py` → `--import` → K1 → `audio` → `settings` → K2 | `AUDIO TEST OK`, `SETTINGS TEST OK`, `SMOKE TEST OK` |
| G14, G05 | K1 → K2 | `0 lỗi`, `SMOKE TEST OK` |
| G16 | `build_all.py` → `build_audio.py` → `--import` → K1 → `craft` → K2 | `CRAFT TEST OK`, `SMOKE TEST OK` |
| G04 | K1 → lệnh xuất bản bên dưới | Có tệp `build/AnhHungDatViet.exe` và `build/AnhHungDatViet.apk` |
| N1 → N8 | K1 → `run_tests lan` → K2 → **thử LAN bằng tay** | `LAN TEST OK`, `SMOKE TEST OK` |
| G06 | K1 → `run_tests challenge` → K2 | `CHALLENGE TEST OK` (cùng mã thì cùng bản đồ) |
| G07, G09, G11, G13 | K1 → K2 | `0 lỗi`, `SMOKE TEST OK` |
| G12 | K1 → `cover` → K2 | `COVER TEST OK`, `SMOKE TEST OK` |
| G10 | `build_all.py` → `artbook.py` → `--import` → K1 → K2 | Xem ảnh `docs/artbook/`, tự chơi thử từng tướng |
| G08 | `build_all.py` → `artbook.py` → `--import` → K1 → K2 | Xem ảnh `docs/artbook/` trước khi duyệt |

Các test `run_save`, `lan`, `challenge` **chưa có sẵn**: Gemini tạo ra khi làm thẻ tương ứng. Trong lúc chờ, `run_tests <ten>` sẽ báo "THẤT BẠI" vì chưa có tệp, như vậy là bình thường.

### Xuất bản thử (sau thẻ G04)

Cần tải Export Templates trong Godot trước: Editor → Manage Export Templates → Download.

Bản Windows:
```powershell
mkdir build -Force; & $GODOT --headless --path . --export-release "Windows Desktop" build/AnhHungDatViet.exe
```

Bản Android (khóa debug):
```powershell
& $GODOT --headless --path . --export-debug "Android" build/AnhHungDatViet.apk
```

### Thử chơi LAN bằng tay (sau mỗi thẻ N)

- **Trên 1 máy, 2 cửa sổ:**
  1. Trong Godot chọn Debug → Customize Run Instances → bật Enable Multiple Instances, đặt số lượng 2, bấm F5.
  2. Cửa sổ 1 chọn "Tạo phòng", cửa sổ 2 chọn "Vào phòng" (tìm tự động, hoặc gõ IP `127.0.0.1`).
- **Trên 2 máy cùng wifi:**
  1. Máy tạo phòng chạy lệnh `ipconfig` để xem dòng IPv4, ví dụ `192.168.1.5`.
  2. Máy kia vào phòng bằng IP đó.
  3. Lần đầu Windows hỏi tường lửa thì chọn **Allow** (cho phép) với mạng Private.
- Chơi 10 phút, kiểm tra 3 điều:
  - cả hai thấy nhau di chuyển mượt;
  - giặc giống nhau ở cả 2 máy;
  - nhặt đồ không bị nhân đôi.

## 2. Thứ tự làm

| Đợt | Thẻ việc | Mục đích |
|---|---|---|
| **Đợt 1: Nền tảng** | G01 → G02 → G03 → G15 → G14 → G16 → G04 → G05 | Chơi một mình thoải mái, gửi được cho bạn bè |
| **Đợt 2: Chơi LAN** | N1 → N2 → N3 → N4 → N5 → N6 → N7 → N8 | Chơi chung qua wifi nhà. **Phải làm đúng thứ tự**, thẻ sau dựa trên thẻ trước |
| **Đợt 3: Thêm vui** | G06 → G07 → G08 → G10 → G09 | So tài, hướng dẫn, đẹp hơn, nội dung mới |
| **Xen kẽ** | G11 | Làm sau khi nhóm đã chơi bản `.exe` / `.apk` được 1–2 tuần. Lặp lại mỗi khi có phản hồi mới |

Chơi LAN là phần lớn nhất từ trước tới giờ, ước khoảng 1.500–2.500 dòng mã. Nên làm xong đợt 1 và chơi ổn định trước. Sau mỗi thẻ N, **chơi thử thật bằng 2 máy** rồi mới sang thẻ tiếp.

---

## 3. Đợt 1: Nền tảng

### G01: Lưu giữa lượt và giữ xu khi thoát

| Mục | Nội dung |
|---|---|
| Mục tiêu | Tắt game giữa lượt không mất gì. Mở lại có nút "Chơi tiếp (Màn N)" và "Bỏ lượt (nhận X xu)". |
| File liên quan | `scripts/autoload/global.gd`: thêm `run_save_path`, `save_run()`, `load_run()`, `clear_run()`, `abandon_run()`. `scripts/game/game.gd`: lưu ở đầu mỗi màn. `scripts/ui/main_menu.gd`, `scripts/entities/player.gd` (đọc/ghi máu, giáp, năng lượng, vũ khí). Tạo mới: `tests/run_save_test.gd` + `.tscn`. |
| Tiêu chí nghiệm thu | 1. `user://run.json` lưu các trường `version`, tướng, màn, máu/giáp/năng lượng, 2 vũ khí, `run_buffs`, `run_coins`, `boss_order`, `legend_last`, `revived`, `free_revives`. Ghi vào tệp `.tmp` rồi đổi tên. 2. Khi nhận `NOTIFICATION_WM_CLOSE_REQUEST` hoặc `NOTIFICATION_APPLICATION_PAUSED` thì lưu cả `run.json` và `save.json`. 3. "Bỏ lượt" gọi `end_run()`: xu lượt được cộng vào kho, `run.json` bị xóa. Chết hoặc về sảnh cũng xóa `run.json`. 4. `run.json` hỏng hoặc sai phiên bản thì bỏ qua, không văng game. `save.json` cũ vẫn nạp được. 5. `tests/run_save_test` in `RUN SAVE TEST OK`. |
| Lệnh kiểm tra | K1; `godot --headless --path . res://tests/run_save_test.tscn`; K2 |
| Không được đụng | Các khóa đang có trong `save.json`, `tests/smoke_test.gd`, `scripts/data/*`, `assets/`, `tools/` |
| Độ lớn | M. Chơi tiếp sẽ dựng lại màn từ đầu, chấp nhận được. |

### G02: Âm thanh (nguồn CC0)

| Mục | Nội dung |
|---|---|
| Mục tiêu | Có tiếng và nhạc nền. |
| File liên quan | Tạo mới: `scripts/audio/sfx.gd` (thêm vào autoload `Sfx`), `assets/audio/`, `CREDITS.md`. Thêm 1 dòng gọi `Sfx.play(...)` ở `player.gd`, `enemy.gd`, `bullet.gd`, `pickup.gd`, `room.gd`, `ui.gd`. |
| Tiêu chí nghiệm thu | 1. Tối thiểu 15 tiếng: chém, bắn tên, bắn súng, nổ, trúng đòn (người chơi và giặc), nhặt xu, nhặt vũ khí, mở rương, mua hàng, cửa đóng, trùm xuất hiện, trùm hiện nguyên hình, qua màn, bấm nút, chết. 2. Có 2 bản nhạc nền: sảnh và trận đánh. Trận trùm đổi nhạc nếu có. Nhạc có tiếng sáo, trống hoặc đàn dân tộc càng tốt. 3. Giới hạn 8 tiếng cùng lúc, chọn giọng ngẫu nhiên để tiếng không chồng chói. 4. Mọi tệp đều là CC0 (Kenney, OpenGameArt CC0, Freesound CC0) và có dòng trong `CREDITS.md`. 5. Âm lượng đọc từ cài đặt (chuẩn bị sẵn cho G03). |
| Lệnh kiểm tra | `godot --headless --path . --import`; K1; K2 |
| Không được đụng | Lối chơi, số liệu cân bằng, test |
| Độ lớn | M |

### G03: Menu cài đặt và độ khó

| Mục | Nội dung |
|---|---|
| Mục tiêu | Có màn hình Cài đặt trong menu chính và menu tạm dừng. |
| File liên quan | Tạo mới: `scripts/ui/settings_menu.gd`. Sửa: `scripts/autoload/global.gd` (khóa mới `settings` trong save), `main_menu.gd`, `pause_menu.gd`, `scripts/data/enemies.gd` (hàm nhân độ khó). |
| Tiêu chí nghiệm thu | 1. Có các mục: âm lượng nhạc, âm lượng hiệu ứng, rung màn hình (bật/tắt), toàn màn hình (máy tính), cỡ nút cảm ứng (điện thoại), **độ khó Dễ / Thường / Khó**. 2. Độ khó nhân máu giặc ×0,7 / ×1 / ×1,4 và sát thương giặc ×0,75 / ×1 / ×1,25. 3. Cài đặt được lưu lại; tệp lưu cũ thiếu khóa thì dùng mặc định "Thường". 4. Font và theme giống các màn hình khác (`theme = UI.make_theme()`). |
| Lệnh kiểm tra | K1; K2 (độ khó mặc định "Thường" nên K2 không đổi) |
| Không được đụng | Test, ảnh |
| Độ lớn | M |

### G04: Đóng gói để gửi bạn bè

| Mục | Nội dung |
|---|---|
| Mục tiêu | Có file `.exe` (Windows) và `.apk` (Android) để gửi qua Zalo hoặc Google Drive. Bạn bè không cần cài Godot. |
| File liên quan | Tạo mới: `export_presets.cfg` (2 mẫu: "Windows Desktop", "Android"), `docs/HUONG-DAN-CAI.md`. Có thể sửa `project.godot` (icon, tên ứng dụng, quyền mạng). |
| Tiêu chí nghiệm thu | 1. Bản Windows xuất ra một tệp `.exe`, đã nhúng dữ liệu vào (embed pck). 2. Bản Android dùng **khóa debug**, đủ quyền `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` để chơi LAN sau này, màn hình nằm ngang, bật nút cảm ứng. 3. `docs/HUONG-DAN-CAI.md` hướng dẫn bằng tiếng Việt, có ảnh minh họa nếu được: cách bạn bè cài `.exe` (Windows SmartScreen → "Vẫn chạy"), cách cài `.apk` (cho phép nguồn không xác định), và cách cho phép qua tường lửa Windows khi chơi LAN. 4. KHÔNG đưa keystore hay mật khẩu vào git. |
| Việc chủ dự án làm | Trong Godot: Editor → Manage Export Templates → tải về. Với Android: cài JDK 17 và Android SDK theo tài liệu Godot "Exporting for Android". |
| Lệnh kiểm tra | K1; tự xuất bản rồi chạy thử trên 1 máy tính và 1 điện thoại |
| Không được đụng | Mã lối chơi |
| Độ lớn | S–M |

### G05: Sửa lỗi nhỏ

| Mục | Nội dung |
|---|---|
| Mục tiêu | Sửa các lỗi đã biết. |
| Danh sách | 1. Đạn bay ra vùng tối ngoài tường rồi bay mãi: tự hủy khi ra khỏi vùng có sàn. 2. Thông báo giữa màn hình chồng lên nhau: xếp hàng đợi, mỗi thông báo hiện 2 giây. 3. Tên phòng và chữ trên đầu nhân vật chồng nhau khi nhiều vật thể đứng gần. |
| File liên quan | `scripts/entities/bullet.gd`, `scripts/ui/hud.gd` |
| Lệnh kiểm tra | K1; K2 |
| Độ lớn | S |

### G14: Gọn nhịp hầm ngục

| Mục | Nội dung |
|---|---|
| Mục tiêu | Rút gọn độ dài từng màn từ màn 5 trở đi để hành trình 30 màn bớt mệt, dồn cao trào vào trùm và Tam Yêu. |
| File liên quan | `scripts/game/dungeon.gd`, `scripts/game/room.gd` |
| Tiêu chí nghiệm thu | 1. Số phòng mỗi màn = `5 + mini(level, 3)`. 2. Số đợt giặc trong phòng thường (`combat`): màn 1 có `1` đợt, màn `2–12` có `2` đợt, từ màn `13` trở đi có `3` đợt. |
| Lệnh kiểm tra | K1; K2 |
| Không được đụng | Số liệu cân bằng máu/sát thương, test |
| Độ lớn | S |

### G15: Âm thanh va chạm

| Mục | Nội dung |
|---|---|
| Mục tiêu | Có tiếng va chạm phân biệt chất liệu (thịt, đạn, kim loại/khiên, tường, gỗ, chí mạng, trùm) và chống ồn khi bắn nhanh. |
| File liên quan | `tools/audio/build_audio.py`, `scripts/audio/sfx.gd`, `scripts/entities/bullet.gd`, `scripts/entities/player.gd`, `scripts/entities/enemy.gd`, `scripts/game/dummy.gd`, `tests/audio_test.gd`, `CREDITS.md` |
| Tiêu chí nghiệm thu | 1. Sinh thêm 7 tiếng bằng `build_audio.py` (thư viện chuẩn, hạt giống cố định): `hit_flesh`, `hit_bullet`, `hit_metal`, `hit_wall`, `hit_wood`, `hit_crit`, `hit_boss`. 2. Gắn đúng ngữ cảnh va chạm: đạn trúng giặc (`hit_bullet`), đạn chạm tường/đá (`hit_wall`), cận chiến trúng giặc mỗi nhát 1 tiếng (`hit_flesh`), đỡ đòn/chiêu giáp (`hit_metal`), chí mạng (`hit_crit`), trúng trùm (`hit_boss`), hình nhân rơm (`hit_wood`). 3. Chống ồn: khoảng cách tối thiểu `0,05` giây cho mỗi tên tiếng, tổng tối đa vẫn 8 tiếng cùng lúc, lệch cao độ ngẫu nhiên `±8%`. 4. `tests/audio_test` kiểm tra đủ 7 tệp mới, 30 lần `hit_bullet` cùng 1 khung chỉ phát 1 tiếng, bắn đạn vào giặc trong cảnh thử có phát `hit_bullet`. |
| Lệnh kiểm tra | `py tools/audio/build_audio.py` → `--import` → K1 → `audio` → `settings` → K2 |
| Không được đụng | Logic chiến đấu, sát thương |
| Độ lớn | M |

### G16: Nguyên liệu rơi và Lò rèn binh khí

| Mục | Nội dung |
|---|---|
| Mục tiêu | Giặc, trùm, Tam Yêu và rương rơi nguyên liệu rèn vũ khí; Lò rèn trong sảnh cho phép rèn vũ khí đã khám phá (cấp ≥ 2) để mang sang lượt chơi kế tiếp. |
| File liên quan | Tạo mới: `scripts/data/materials.gd`, `tests/craft_test.gd` + `.tscn`. Sửa: `scripts/entities/enemy.gd` (chỉ `_drop_loot`), `scripts/entities/pickup.gd`, `scripts/entities/loot_chest.gd`, `scripts/autoload/global.gd`, `scripts/game/lobby.gd`, `scripts/ui/lobby_ui.gd`, `scripts/game/game.gd`, `scripts/ui/hud.gd`, `tools/sprites/art_world.py`, `tools/audio/build_audio.py`. |
| Tiêu chí nghiệm thu | 1. `scripts/data/materials.gd` khai báo 6 nguyên liệu: `dong` (Đồng), `sat` (Sắt), `go_lim` (Gỗ lim), `hoa_duoc` (Hỏa dược) từ lính; `yeu_hon` (Yêu hồn) từ yêu quái; `ngoc_than` (Ngọc thần) hiếm từ trùm và Tam Yêu. Các tỉ lệ rơi và bảng giá rèn để thành hằng số/bảng trong `materials.gd`. 2. Tỉ lệ rơi: lính thường `8%` rơi 1 món theo đạo quân (thời cổ ra đồng/sắt/gỗ lim, từ 1861 ra sắt/hỏa dược); tinh nhuệ `40%`; yêu quái `15%` rơi `yeu_hon`; trùm rơi `2–3` món + `50%` ra `ngoc_than`; Tam Yêu chắc chắn rơi `1 ngoc_than` + `2 yeu_hon`; rương sơn mài `20%` kèm `1–2` món. 3. Vật phẩm kiểu `"material"` tự bay về người chơi như xu, hiện tên nguyên liệu, có tiếng nhặt; gom vào `run_materials`, kết thúc lượt (`end_run` / `abandon_run`) cộng vào khóa mới `"materials"` trong `save.json`, lưu kèm trong `run.json` (thiếu khóa coi là rỗng). 4. Lò rèn có thẻ "Rèn binh khí": chỉ rèn vũ khí đã khám phá, cấp `>= 2`, không gồm vũ khí cơ bản. Giá theo bảng: cấp 2 (`3` đồng + `2` sắt + `50` xu), cấp 3 (`4` sắt + `3` gỗ lim hoặc hỏa dược + `1` yêu hồn + `120` xu), cấp 4 (`5` sắt + `4` đồng + `2` yêu hồn + `1` ngọc thần + `250` xu), cấp 5 (`6` sắt + `3` yêu hồn + `3` ngọc thần + `400` xu). Rèn xong bày lên giá binh khí, lượt kế tiếp mang vào ô thứ 2 (dùng 1 lần, khóa mới `"forged"`), có tiếng búa rèn `"forge"` sinh bằng `build_audio.py` và tia lửa. 5. Hình 6 nguyên liệu vẽ bằng `art_world.py` (`items/mat_<mã>.png`) qua `polish()`, không sửa tay PNG. 6. `tests/craft_test` in `CRAFT TEST OK`, kiểm đủ: cộng kho cuối lượt, `run.json` giữ nguyên liệu, trừ nguyên liệu/xu khi rèn, thiếu không rèn được, vũ khí rèn vào ô 2 lượt sau rồi biến mất, save cũ thiếu `"materials"` và `"forged"` vẫn nạp được. |
| Lệnh kiểm tra | `py tools/sprites/build_all.py` → `py tools/audio/build_audio.py` → `--import` → K1 → `craft` → K2 |
| Không được đụng | Số liệu cân bằng chiến đấu, test cũ |
| Độ lớn | L (chia 2 phiên) |

---

## 4. Đợt 2: Chơi chung qua LAN

### Thiết kế chung (đọc trước khi làm bất kỳ thẻ N nào)

- **Host:** người bấm "Tạo phòng" là host. Host vừa chơi vừa làm "trọng tài".
- **Việc chỉ host làm:**
  - chạy AI giặc và trùm;
  - sinh đợt giặc, đóng/mở cửa phòng;
  - quyết định rương, vật phẩm rơi, hàng ở gánh hàng rong, cổng qua màn.
- **Việc mỗi người tự làm:**
  - điều khiển nhân vật của mình: di chuyển, ngắm, tấn công, kỹ năng;
  - **tự kiểm tra đạn giặc có trúng mình không**, cách này công bằng và ít giật.
- **Cùng bản đồ:** host gửi một số `map_seed`. Mọi máy gọi `seed(map_seed + level)` ngay trước `dungeon.generate()`, nên bản đồ giống hệt nhau. Thứ tự trùm `boss_order` và yêu `legend_id` cũng do host gửi.
- **Mã mạng cho từng vật thể:** giặc, vật phẩm, rương, cổng đều có `net_id` (số nguyên do host cấp) để các máy biết đang nói về vật nào.
- **Tần suất gửi:**
  - Vị trí người chơi và vị trí, máu của giặc: 15–20 lần/giây, kiểu `unreliable_ordered`. Máy nhận nội suy cho mượt.
  - Sự kiện (sinh, chết, nhặt, mở cửa, qua màn): kiểu `reliable`.
- **Chơi một mình phải giữ nguyên:** khi không có mạng thì mọi `rpc` gọi thẳng như hàm thường, và K2 phải vẫn `SMOKE TEST OK`.
- **Đã kiểm tra trong mã hiện tại:** có khoảng **15 chỗ** dùng `get_tree().get_first_node_in_group("player")` (giặc ngắm người chơi, vật phẩm bay về người chơi, phòng kiểm tra người chơi bước vào). Khi chơi chung, những chỗ này phải đổi sang **người chơi gần nhất** hoặc **người chơi của máy này**. Thẻ N2 xử lý việc này.

### N1: Menu mạng và phòng chờ

| Mục | Nội dung |
|---|---|
| Mục tiêu | Từ menu chính vào "Chơi LAN" → Tạo phòng hoặc Vào phòng → phòng chờ: thấy danh sách người, mỗi người chọn tướng và bấm Sẵn sàng → host bấm Bắt đầu. |
| File liên quan | Tạo mới: `scripts/net/net.gd` (autoload `Net`: tạo/vào phòng, danh sách người chơi, tín hiệu), `scripts/net/discovery.gd` (tìm phòng tự động), `scripts/ui/lan_menu.gd`, `scenes/lan_lobby.tscn`. Sửa: `main_menu.gd` (thêm nút), `project.godot` (autoload). |
| Tiêu chí nghiệm thu | 1. Host mở `ENetMultiplayerPeer` cổng 7777, tối đa 4 người. 2. **Tự tìm phòng:** host phát gói UDP mỗi giây trên cổng 7778 (tên phòng, số người); máy khách hiện danh sách để bấm vào. Có thêm ô nhập IP tay phòng khi tìm không thấy. 3. Phòng chờ hiện tên người chơi (nhập lúc đầu, lưu vào save), tướng đã chọn (chỉ chọn trong số tướng **đã mở khóa trên máy mình**) và trạng thái Sẵn sàng. 4. Ai thoát thì danh sách cập nhật ngay. Host thoát thì mọi người về menu kèm thông báo "Chủ phòng đã rời". 5. `tests/lan_test.tscn` chạy 1 host và 1 khách (2 tiến trình headless hoặc 2 peer trong cùng tiến trình) qua 127.0.0.1, kiểm tra kết nối được và thấy nhau. In `LAN TEST OK`. |
| Lệnh kiểm tra | K1; `godot --headless --path . res://tests/lan_test.tscn`; K2 |
| Không được đụng | Lối chơi một mình |
| Độ lớn | M–L |

### N2: Nhiều người chơi trong cùng màn

| Mục | Nội dung |
|---|---|
| Mục tiêu | Bấm Bắt đầu thì mọi máy vào cùng bản đồ, thấy nhau chạy, thấy vũ khí của nhau. |
| File liên quan | `scripts/game/game.gd` (sinh nhiều Player, camera theo người của máy mình), `scripts/entities/player.gd` (cờ `is_local`; người của máy khác không đọc phím mà nhận trạng thái qua mạng), `scripts/game/dungeon.gd` (dùng seed), `scripts/autoload/global.gd` (hàm `nearest_player(pos)` và `local_player()`). Thay 15 chỗ `get_first_node_in_group("player")`. |
| Tiêu chí nghiệm thu | 1. Cùng seed thì bản đồ, phòng và Tam Yêu giống nhau ở mọi máy. Test so sánh danh sách phòng giữa 2 peer. 2. Mỗi máy gửi vị trí, hướng ngắm, hoạt ảnh, vũ khí đang cầm và cờ lướt 20 lần/giây. Máy nhận nội suy mượt. 3. Mỗi người có màu tên khác nhau hiện trên đầu. 4. HUD chỉ hiện máu của người mình, kèm thanh máu nhỏ của đồng đội ở góc. 5. Chơi một mình vẫn y như cũ (K2 OK). |
| Lệnh kiểm tra | K1; lan_test (thêm kiểm tra cùng bản đồ); K2 |
| Độ lớn | L |

### N3: Giặc do host điều khiển

| Mục | Nội dung |
|---|---|
| Mục tiêu | Giặc và trùm chỉ "suy nghĩ" ở host, máy khách thấy giống hệt. |
| File liên quan | `scripts/entities/enemy.gd` (nhánh "bản sao": không chạy AI, chỉ nhận trạng thái), `scripts/game/room.gd` (host sinh đợt giặc rồi gửi sự kiện sinh), tạo mới: `scripts/net/net_sync.gd` (gom trạng thái giặc gửi đi theo lô). |
| Tiêu chí nghiệm thu | 1. Host gửi lô trạng thái (net_id, vị trí, máu, hoạt ảnh, hướng mặt, cờ biến hình hoặc lặn) 15 lần/giây. 2. Giặc ngắm và đuổi **người chơi gần nhất**. 3. Trùm hiện nguyên hình, nổi giận, chiêu đặc biệt và thông báo hiện ở mọi máy. 4. Sinh và chết là sự kiện `reliable`, có hiệu ứng ở mọi máy. 5. Máu giặc theo số người: ×(1 + 0,5 × (số người − 1)). |
| Lệnh kiểm tra | K1; lan_test (host sinh giặc, khách thấy đủ số lượng); K2 |
| Độ lớn | L |

### N4: Đạn và đòn đánh trong mạng

| Mục | Nội dung |
|---|---|
| Mục tiêu | Ai bắn cũng thấy, trúng ai cũng đúng. |
| Cách làm | **Đạn giặc:** host gửi sự kiện "bắn" (vị trí, hướng, tốc độ, loại đạn). Mọi máy tự tạo viên đạn giống nhau, và mỗi máy chỉ kiểm tra đạn trúng **người của máy mình**. **Đòn người chơi:** máy người bắn tạo đạn hoặc nhát chém, rồi gửi sự kiện cho máy khác để vẽ. Khi trúng giặc, máy người bắn gửi `damage_enemy(net_id, dmg, knock)` cho host. Host trừ máu (có giới hạn hợp lý để chống gian lận) rồi phát lại kết quả. Trạng thái cháy và độc tính ở host. |
| File liên quan | `scripts/entities/bullet.gd`, `scripts/entities/player.gd` (`_shoot`, `_melee`, `_beam`, `_wave`, `_spikes`, `_chain_lightning`), `scripts/entities/enemy.gd` (`take_damage` → yêu cầu lên host), `scripts/effects/mortar_strike.gd`, `scripts/effects/miasma.gd` |
| Tiêu chí nghiệm thu | 1. Cả 67 vũ khí bắn được trong mạng. lan_test bắn thử mỗi loại một lần. 2. Không bị trừ máu hai lần. 3. Chí mạng và phúc lành tính ở máy người đánh. |
| Lệnh kiểm tra | K1; lan_test; K2 |
| Độ lớn | L |

### N5: Phòng, rương, vật phẩm, cửa hàng, qua màn

| Mục | Nội dung |
|---|---|
| Mục tiêu | Mọi thứ trên bản đồ đồng bộ. |
| Tiêu chí nghiệm thu | 1. Cửa phòng đóng khi **bất kỳ ai** bước vào phòng chưa đánh. Người ở ngoài được dịch chuyển vào trong. 2. Rương: ai bấm mở cũng được, host quyết định đồ rơi. 3. **Xu, năng lượng và nguyên liệu rơi:** mỗi người thấy và nhặt phần riêng của mình. **Vũ khí và hồ lô:** ai nhặt trước được trước, host khóa vật phẩm để không ai nhặt trùng. 4. Gánh hàng rong có `3 + (số người − 1)` kệ: mỗi món chỉ bán 1 lần, ai mua thì trừ xu người đó. 5. Cổng qua màn mở khi mọi người còn sống đều đứng trong cổng, hoặc sau 10 giây đếm ngược từ khi người đầu tiên vào. 6. Phúc lành: mỗi người tự chọn trên máy mình; màn mới bắt đầu khi tất cả đã chọn. |
| File liên quan | `room.gd`, `loot_chest.gd`, `pickup.gd`, `shop.gd`, `shop_stand.gd`, `portal.gd`, `game.gd`, `buff_select.gd` |
| Lệnh kiểm tra | K1; lan_test (đi hết 1 màn với 2 người); K2 |
| Độ lớn | L |

### N6: Kỹ năng tướng trong mạng

| Mục | Nội dung |
|---|---|
| Mục tiêu | 10 kỹ năng hiển thị đúng ở mọi máy. |
| Tiêu chí nghiệm thu | 1. Dùng kỹ năng thì gửi sự kiện `skill(id, vị trí, hướng)`, các máy khác vẽ hiệu ứng: cọc Bạch Đằng, voi chiến, trống đồng, kiếm bay, biển lửa, hổ, pháo… 2. Sát thương của kỹ năng gửi lên host như N4. 3. Vật thể sống lâu (cọc, pháo, đồng minh) do máy người dùng điều khiển và gửi vị trí. 4. Vòng phản đạn Nam quốc sơn hà phản được đạn giặc ở máy chủ kỹ năng. |
| File liên quan | `player.gd` (`_use_skill`), `scripts/effects/*` (stake, ally, turret, tiger, fire_zone, orbit_blades, reflect_ring, drum_sigil) |
| Lệnh kiểm tra | K1; lan_test (dùng 10 kỹ năng); K2 |
| Độ lớn | M–L |

### N7: Gục ngã và cứu đồng đội

| Mục | Nội dung |
|---|---|
| Mục tiêu | Chơi chung có tình đồng đội như Soul Knight. |
| Tiêu chí nghiệm thu | 1. Hết máu thì **gục**: nằm xuống, **không giới hạn thời gian** khi còn đồng đội đứng. 2. Đồng đội đứng cạnh 3 giây thì cứu dậy với **2 máu, 0 giáp và 1,5 giây bất tử**. 3. Tất cả cùng gục thì thua; màn thua hiện ở mọi máy. 4. "Thuốc hồi sinh" ở lò rèn dùng cho chính mình. 5. Cuối lượt, xu nhặt của ai cộng vào save trên máy người đó. Thành tích tính riêng từng người. |
| File liên quan | `player.gd`, `game.gd`, `hud.gd` |
| Lệnh kiểm tra | K1; lan_test; K2 |
| Độ lớn | M |

### N8: Rớt mạng và hoàn thiện

| Mục | Nội dung |
|---|---|
| Mục tiêu | Mạng chập chờn không làm hỏng ván. |
| Tiêu chí nghiệm thu | 1. Khách rớt mạng thì nhân vật biến mất kèm thông báo, ván vẫn chạy. Vào lại phòng trong 60 giây thì tiếp tục được. 2. Host rớt mạng thì mọi người về menu, xu đã nhặt vẫn được cộng (dùng G01). 3. Chơi LAN thì không có nút Tạm dừng; menu Esc chỉ để Cài đặt hoặc Rời phòng. 4. Hiện độ trễ (ms) ở góc màn hình. 5. Cập nhật `docs/HUONG-DAN-CAI.md`: cách chơi LAN, mở tường lửa Windows, kiểm tra 2 máy cùng wifi, cách xem IP máy. |
| Lệnh kiểm tra | K1; lan_test (giả lập ngắt kết nối); K2 |
| Độ lớn | M |

---

## 5. Đợt 3: Thêm vui

| Thẻ | Việc | Độ lớn |
|---|---|---|
| **G06** | **Mã thử thách:** nhập cùng một mã (ví dụ `TET2027`) thì ra cùng bản đồ, cùng thứ tự trùm và phúc lành. Cuối lượt hiện điểm (màn, thời gian, số giặc). Bảng điểm lưu trên máy, có nút "Chép kết quả" để dán vào nhóm Zalo so tài. | M |
| **G07** | **Hướng dẫn chơi lần đầu** trong sảnh: 5 bước ngắn (đi, đánh, nhặt, kỹ năng, vào cổng), bỏ qua được. | S–M |
| **G08** | **Vẽ lại tướng đầu to kiểu chibi** trong `tools/sprites/art_heroes.py`: đầu chiếm khoảng 55% chiều cao, giữ nhận diện từng tướng, chạy `build_all.py`. Chủ dự án duyệt ảnh trong `docs/artbook/` trước khi gộp. | L |
| **G10** | **Hoạt ảnh riêng cho từng tướng** trong `tools/sprites/art_heroes.py`: 2 khung tấn công, 2 khung tung kỹ năng, 3 khung gục ngã. Thêm tên hoạt ảnh `attack`, `skill`, `down` trong `player.gd`. Chơi lúc tấn công, dùng kỹ năng, và lúc gục (dùng chung với N7). Giữ khung cũ 0–8, chỉ thêm khung mới phía sau. | L |
| **G12** | **Vật cản che đạn thuần Việt** (theo đề xuất số 4 trong `docs/PHAN-TICH-SOUL-KNIGHT.md`): thời cổ có chum gốm, cọc gỗ; từ năm 1861 có bao cát, thùng đạn. Chặn đạn cả hai phe, vỡ sau 3–5 đòn (có hiệu ứng và tiếng). Không sinh trên cửa, lối đi giữa các cửa, phòng đầu, phòng trùm. Tạo `cover.gd`, sửa `room.gd`, `bullet.gd`, `art_world.py`, thêm `tests/cover_test.gd` + `.tscn` (`COVER TEST OK`). | M |
| **G13** | **Phúc lành Hộ tâm kính** (trong `buffs.gd`, `player.gd`, `art_buffs.py`): khi giáp đã vỡ, chặn trọn đòn đầu tiên làm tràn sang máu, hồi lại sau 8 giây. Biểu tượng vẽ bằng `tools/sprites/art_buffs.py`. | S |
| **G11** | **Cân bằng độ khó** (xem mô tả ngay dưới bảng). *Lưu ý:* đề xuất số 1 (trễ hồi giáp, thời gian bất tử) và số 3 (giá hồ lô, tỉ lệ rơi) trong `docs/PHAN-TICH-SOUL-KNIGHT.md` chỉ xét khi có nhật ký trận. | M, lặp lại |
| **G09** | **Nội dung mới theo ý nhóm bạn**, ví dụ tướng Thánh Gióng, sự kiện Tết (bánh chưng, pháo hoa trong sảnh), trùm Sơn Tinh – Thủy Tinh. Mỗi món một thẻ riêng. | tùy món |

### G11: Cân bằng độ khó theo phản hồi

| Mục | Nội dung |
|---|---|
| Mục tiêu | Game không quá dễ hay quá khó với nhóm bạn, dựa trên số liệu thật thay vì đoán. |
| Bước 1: Nhật ký trận (làm một lần) | Cuối mỗi lượt ghi 1 dòng vào `user://nhat_ky.csv` gồm: ngày, tướng, độ khó, màn xa nhất, thời gian, giặc đã hạ, chết ở màn nào và do ai (tên giặc hoặc trùm), máu còn lại khi qua từng trùm, xu nhặt, phúc lành đã chọn. Có nút "Mở thư mục nhật ký" trong Cài đặt. **Không gửi đi đâu cả**, chỉ nằm trên máy. |
| Bước 2: Chỉnh số liệu (lặp lại) | Chủ dự án gom file `nhat_ky.csv` của cả nhóm, dán vào phiên Gemini kèm nhận xét (ví dụ "trùm thứ 4 quá khó, giặc chương 2 quá dễ"). Gemini đề xuất bảng thay đổi số liệu trong `scripts/data/*` (máu, sát thương, giá, tỉ lệ rơi, `BOSS_HP_STEP`…), kèm lý do. **Chủ dự án duyệt bảng rồi Gemini mới sửa.** |
| File liên quan | `scripts/autoload/global.gd` (ghi nhật ký), `scripts/ui/settings_menu.gd` (nút mở thư mục), `scripts/data/*` (chỉ ở bước 2, theo bảng đã duyệt) |
| Tiêu chí nghiệm thu | Nhật ký ghi đúng, không lỗi khi thư mục không ghi được. Sau mỗi lần chỉnh số liệu, K2 vẫn `SMOKE TEST OK`. Có bảng "trước → sau" trong báo cáo. |
| Lệnh kiểm tra | K1; K2 |
| Độ lớn | M (bước 1), S mỗi lần chỉnh (bước 2) |

---

## 6. Danh sách kiểm tra khi duyệt việc Gemini làm

Mục nào "không" thì trả việc.

- [ ] `git diff main --stat` chỉ có các tệp ghi trong thẻ việc. Không có tệp lạ, không có tệp bị xóa.
- [ ] `tests/smoke_test.gd` không bị xóa hay nới bớt kiểm tra.
- [ ] Tự chạy K1 và K2 trên máy mình, thấy `0 lỗi` và `SMOKE TEST OK`. Không tin kết quả máy tự báo.
- [ ] Test riêng của thẻ (ví dụ `RUN SAVE TEST OK`, `LAN TEST OK`) thật sự kiểm tra điều ghi trong tiêu chí, không phải chỉ `print("OK")`.
- [ ] Không có cú pháp Godot 3 (`yield(`, `export var`, `onready var`, `.instance()`, `connect("`, `rand_range`, `File.new`, `NetworkedMultiplayerENet`).
- [ ] Không có PNG nào trong `assets/sprites/` đổi mà không kèm thay đổi trong `tools/sprites/*.py`.
- [ ] Tệp `save.json` cũ vẫn nạp được, xu và tướng đã mở còn nguyên. Chép file này ra chỗ khác trước khi thử.
- [ ] Chữ tiếng Việt đủ dấu, không có ô vuông hay dấu `?`.
- [ ] Tài nguyên mới có dòng trong `CREDITS.md`, giấy phép CC0.
- [ ] Không có kết nối Internet, quảng cáo, thu thập dữ liệu hay khóa API.
- [ ] **Tự chơi 10 phút một mình**, và với các thẻ N thì **chơi 10 phút bằng 2 máy** trên cùng wifi.
- [ ] Gemini có báo cáo đúng mẫu ở mục 10 của AGENTS.md.
