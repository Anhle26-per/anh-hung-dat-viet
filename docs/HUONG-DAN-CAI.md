# Hướng dẫn cài đặt và chơi **Anh Hùng Đất Việt** (`v2.2.0`)

> Tải các gói cài đặt chính thức tại trang [**GitHub Releases**](https://github.com/Anhle26-per/anh-hung-dat-viet/releases/latest).

---

## 1. Cách cài đặt và mở game

### Trên máy tính Windows (`AnhHungDatViet-Windows.zip`)
1. Tải tệp **`AnhHungDatViet-Windows.zip`** và **giải nén toàn bộ thư mục `AnhHungDatViet/`** ra máy tính (không tách lẻ 2 tệp `AnhHungDatViet.exe` và `AnhHungDatViet.pck`).
2. Nhấp đúp **`AnhHungDatViet.exe`** để vào thẳng game (không cần cài thêm Godot hay thư viện rời).
3. Gói `AnhHungDatViet.exe` sử dụng trình chạy chính thức **đã ký số hợp lệ (`Valid`, Prehensile Tales B.V.)** nên chạy mượt ngay cả trên **Windows 11 có bật Smart App Control** mà không bị chặn.

*(Nếu tự chạy từ mã nguồn: mở `project.godot` bằng Godot 4.7.2 và bấm **F5**, hoặc chạy `Godot_v4.7.2-stable_win64.exe --main-pack "build\AnhHungDatViet.pck"`).*

### Trên máy tính MacBook (`AnhHungDatViet-macOS.dmg` / `.zip`)
Hỗ trợ chuẩn **Universal** cho cả **Apple Silicon (M1–M4)** và **Intel**. Bản dựng đã được ký nội bộ (*ad-hoc codesign*) trên GitHub Actions, chỉ cần xác nhận **1 lần duy nhất ở lần mở đầu tiên**:
1. Tải **`AnhHungDatViet-macOS.dmg`**, mở ra và kéo **`AnhHungDatViet.app`** vào thư mục **Applications** (hoặc tải `AnhHungDatViet-macOS.zip` rồi giải nén).
2. Nhấp mở **`AnhHungDatViet.app`** lần đầu: nếu macOS báo chưa xác minh nhà phát triển, bấm **Done (Xong)**.
3. Mở **System Settings → Privacy & Security**, kéo xuống bấm **Open Anyway (Vẫn mở)**.  
   *(Hoặc mở Terminal và chạy nhanh 1 dòng:)*
   ```bash
   xattr -cr /Applications/AnhHungDatViet.app
   ```
4. Từ lần mở thứ 2 trở đi chỉ cần nhấp đúp mở bình thường (và khi tự cập nhật trong game cũng không cần xác nhận lại).

### Trên điện thoại Android (`AnhHungDatViet.apk`)
1. Chép **`AnhHungDatViet.apk`** vào điện thoại Android 64-bit (`arm64-v8a`, xoay ngang màn hình).
2. Mở tệp `.apk` từ trình quản lý tệp, bật **Cho phép cài đặt từ nguồn này** nếu được hỏi, rồi bấm **Cài đặt**.

---

## 2. Bảng phím điều khiển (`v2.2.0`)

| Hành động | Máy tính (`PC`) | Điện thoại (`Touch`) | Tay cầm (`Gamepad`) |
|---|---|---|---|
| **Di chuyển** | `WASD` hoặc phím mũi tên | Cần gạt trái | Cần trái |
| **Tấn công / Tụ lực** | Giữ chuột trái hoặc `J` | Giữ nút Tấn công | `A` / Cò phải (`RT`) |
| **Ngắm bắn** | Con trỏ chuột | Tự ngắm giặc gần nhất | Tự ngắm |
| **Tung Kỹ năng** | Chuột phải hoặc `K` | Nút Kỹ năng | `B` |
| **Lướt né (i-frame)** | `Space` | Nút Lướt | `X` |
| **Chạy nhanh** | `Shift` | — | Nhấn cần trái (`L3`) / Cò trái (`LT`) |
| **Đổi vũ khí** | `Q` hoặc **Lăn chuột** | Nút **Đổi** | `LB` |
| **Vứt vũ khí (chia sẻ LAN)** | `G` *(khi cầm ≥ 2 món)* | Nút **Vứt** | `D-Pad Xuống` |
| **Nhặt / Tương tác** | `E` | Nút **Nhặt / Dùng** | `Y` |
| **Hợp nhất vũ khí** | `R` *(khi đứng cạnh đồ ghép được)* | Nút **Hợp nhất** | `RB` |
| **Tạm dừng / Cài đặt** | `Esc` hoặc `P` | Nút `II` | `Start` |

*(Gợi ý nhỏ: `E` dùng để nhặt vũ khí dưới chân hoặc tương tác rương, thương nhân, bàn thờ sự kiện `[!]`, thú cưỡi; `G` vứt vũ khí đang cầm xuống sàn để nhường cho đồng đội LAN hoặc dọn ô; `R` tự hiện gợi ý khi vũ khí trên tay ghép được với vũ khí gần cạnh hoặc trong túi).*

---

## 3. Kỹ năng 2, Đồng điệu binh khí (`★★` / `★`) & 6 Ấn hệ

- **Chọn Chiêu 1 / Chiêu 2 & xem Nội tại**: trong Doanh trại, bấm `E` vào tượng tướng → chuyển đổi tự do giữa **Chiêu 1** và **Chiêu 2** trước khi vào cổng xuất trận.
- **Đồng điệu khi tung chiêu** (`Chuột phải` / `K`):
  - **★★ Tâm đắc (Vàng):** Cầm **vũ khí khởi đầu** của chính tướng đó hoặc **binh khí định mệnh** (*Nỏ thần Liên Châu* cho Lý Thường Kiệt, *Gươm Thuận Thiên* cho Lê Lợi, *Hỏa hổ* cho Quang Trung, *Súng hỏa mai* cho Hoàng Hoa Thám).
  - **★ Cùng hệ (Bạc):** Cầm vũ khí cùng hệ với vũ khí khởi đầu hoặc vũ khí hệ **Thần khí**.
  - **Chưa đồng điệu:** Giữ nguyên hiệu ứng gốc.

### Bảng 6 Ấn hệ (luôn kích hoạt thêm theo vũ khí trên tay lúc tung chiêu)

| Hệ vũ khí | Tên Ấn hệ | Hiệu ứng cộng thêm |
|---|---|---|
| Đao kiếm | **Kiếm khí** | Phóng 6 luồng sóng kiếm tỏa 360° quanh mình (sát thương = vũ khí đang cầm, tối thiểu 4) |
| Côn thương | **Trấn địa** | Tạo sóng chấn địa bán kính 60 (sát thương 4, đẩy lùi mạnh, choáng 0,6 giây) |
| Cung nỏ | **Mưa tên** | Trong 1,5 giây rơi 12 mũi tên quanh mình bán kính 90 (ưu tiên chỗ có giặc, 3 sát thương/mũi) |
| Hỏa khí | **Hỏa ấn** | Đặt 3 vùng lửa nhỏ hình tam giác quanh mình tồn tại 2 giây |
| Súng | **Nạp đạn thần tốc** | Trong 4 giây: tốc độ bắn **+30%** và đạn xuyên thêm 1 giặc |
| Thần khí | **Linh khí** | Hồi ngay **40 năng lượng**, lần hồi chiêu này ngắn hơn **30%** |

---

## 4. Tu luyện tướng, Rèn binh khí & Tầng Hầm

Trong Doanh trại (sảnh chính), đứng cạnh tượng tướng đã mở khóa, bấm `E` và mở thẻ **Tu luyện**:
- **Tu luyện tướng (Cấp 1 → 5):** Cấp 2 `+1 máu` (`150 xu`), Cấp 3 `+1 giáp` (`300 xu`), Cấp 4 `+30 năng lượng` (`500 xu + 2 Yêu hồn`), Cấp 5 `hồi kỹ năng ×0,85` (`800 xu + 1 Ngọc thần`). *(Cộng dồn với nâng cấp Lò rèn.)*
- **Rèn binh khí khởi đầu (Bậc 1 → 5):** Bậc 2 (`100 xu + 3 Đồng`): sát thương `×1,25`; Bậc 3 (`220 xu + 5 Sắt + 2 Đồng`): sát thương `×1,5`, hồi đòn `×0,92`, mở **Đặc tính 1**; Bậc 4 (`400 xu + 6 Sắt + 2 Yêu hồn`): sát thương `×1,8`, hồi đòn `×0,88`; Bậc 5 — **Thức tỉnh** (`700 xu + 8 Sắt + 3 Yêu hồn + 2 Ngọc thần`): sát thương `×2,2`, hồi đòn `×0,85`, mở **Đặc tính 2**.
- **Lò rèn, Rương báu & Tầng Hầm Vinh Quang:** Dùng Xu và 6 loại nguyên liệu (*Đồng, Sắt, Gỗ lim, Hỏa dược, Yêu hồn, Ngọc thần*) để rèn vũ khí mang vào trận khi đã mở **Bản vẽ**. Từ `v2.2.0`, Rương ải (`35%` / `42%` Ác Mộng) và Rương báu ưu tiên rơi vũ khí **Cấp 3–5** và có thể nổ hũ **Thần Binh Đỏ**; đồng thời rơi **Mảnh Bản Vẽ** (`1` mảnh cho Cấp 1–2, `2` cho Cấp 3, `3` cho Cấp 4, `4` cho Cấp 5 thường, `5` cho Thần Binh Đỏ & Hợp nhất) để ghép tại **Bàn Bản Vẽ** dưới Tầng Hầm hoặc ngay trong **Lò Rèn**.

---

## 5. Nơi lưu game & nhật ký trận (`nhat_ky.csv`)

Game lưu tự động hoàn toàn trên máy bạn:
- **Windows:** `%APPDATA%\Godot\app_userdata\Anh Hùng Đất Việt\` *(chứa `save.json`, `run.json`, `nhat_ky.csv`)*
- **macOS:** `~/Library/Application Support/Godot/app_userdata/Anh Hùng Đất Việt/`
- **Mở nhanh trong game:** bấm `Esc` (tạm dừng) → **Cài đặt** → **"Mở thư mục nhật ký"**.

---

## 6. Chơi chung qua mạng LAN (Co-op 2–4 người)

Game hỗ trợ **2 đến 4 người** chơi chung trong cùng mạng Wi-Fi / LAN nhà (không cần Internet, không dùng máy chủ ngoài):
1. Đảm bảo mọi máy kết nối **cùng một mạng Wi-Fi hoặc mạng dây LAN**.
2. Ở màn hình chính, mỗi người bấm **"Chơi LAN"** và nhập tên hiển thị.
3. **Chủ phòng (Host):** nhập tên phòng → bấm **"Tạo phòng LAN"** (IP hiện ở góc trên bên phải).
4. **Người tham gia (Khách):** chọn phòng ở mục **"Phòng LAN đang mở (tự tìm)"** hoặc nhập IP của Chủ phòng vào **"Vào bằng IP thủ công"**.
5. Khi mọi người bấm **"Sẵn sàng"**, Chủ phòng bấm **"Bắt đầu trận"**.

### Mở tường lửa & Tìm IP nội bộ (Windows)
- Lần đầu tạo phòng, nếu **Windows Defender Firewall** hỏi, tích **Private networks (Mạng riêng)** → **Allow access**.
- Nếu không tự thấy phòng, mở 2 cổng nội bộ **TCP/UDP `7777`** (trận đấu) và **UDP `7778`** (tự tìm phòng).
- Xem IP máy Host: mở `cmd` → gõ `ipconfig` → lấy dòng **`IPv4 Address`** dưới mục Wi-Fi/Ethernet.

### Quy tắc đồng bộ LAN
- Đội dùng chung tiến độ mở khóa tướng, nâng cấp Lò rèn, tu luyện và độ khó của **Chủ phòng**; file `save.json` máy Khách **không bị ghi đè**. Có thể bấm **`G`** (hoặc nút **Vứt**) để thả vũ khí đang cầm xuống sàn chia sẻ cho đồng đội; mọi thao tác nhặt/đổi vũ khí và mở rương đều được Chủ phòng xác nhận chống nhặt trùng, còn **Mảnh Bản Vẽ** rơi riêng cho từng người chơi.
- Khi máu về 0 lúc đồng đội còn sống, bạn chỉ **gục ngã** — đồng đội đứng cạnh **3 giây** sẽ cứu dậy (hồi 2 máu). Nếu Khách rớt mạng, chỗ được giữ **60 giây** để vào lại với đúng tên cũ.

---

## 7. Tự động cập nhật ngay trong game (`patch.pck`)

- Khi mở game có Internet, **Anh Hùng Đất Việt** tự kiểm tra phiên bản mới từ GitHub Releases (`https://github.com/Anhle26-per/anh-hung-dat-viet`). Nếu chơi offline, game bỏ qua im lặng.
- Khi có bản mới, màn hình chính hiện hộp thoại thông báo cùng nút **"Có bản mới!"** ở góc trên phải (hoặc bấm **Cài đặt → Kiểm tra cập nhật**).
- Bấm **Cập nhật ngay** → game tự tải gói vá `.pck` (~7,8 MB ở `v2.0.0`), kiểm tra `SHA-256` và tự khởi động lại lên bản mới — **không cần tải lại tệp `.zip` và giữ nguyên 100% file lưu (`save.json`)**.
