# Hướng dẫn cài đặt và chơi thử **Anh Hùng Đất Việt**

> **Lưu ý:** Đây là **bản thử nội bộ** chỉ dùng để gửi trong nhóm bạn bè chơi thử và góp ý cân bằng, **không phải bản phát hành công khai**.

---

## 1. Cách cài đặt và chạy game

### Trên máy tính Windows (`AnhHungDatViet.exe`)
1. Chép tệp `AnhHungDatViet.exe` vào một thư mục bất kỳ (ví dụ `D:\Games\AnhHungDatViet\`). Không cần cài đặt thêm, mọi dữ liệu đã được nhúng sẵn trong tệp `.exe`.
2. Nhấp đúp `AnhHungDatViet.exe` để mở game.
3. Vì bản thử nội bộ chưa mua chữ ký số thương mại, **Windows SmartScreen** có thể hiện màn hình xanh cảnh báo *"Windows protected your PC"*:
   - Bấm **"More info"** (**"Thông tin thêm"**).
   - Bấm **"Run anyway"** (**"Vẫn chạy"**).

### Chạy thử trực tiếp bằng Godot (khuyên dùng trên máy có Windows Smart App Control)
Trên Windows 11 bật chính sách **Smart App Control**, tệp `.exe` tự xuất chưa ký số có thể bị Windows chặn không cho mở trực tiếp. Khi đó bạn có thể test ngay bản đóng gói thông qua trình Godot đã có chữ ký số hợp lệ:
1. Chạy tệp `build\choi_bang_godot.bat`, hoặc chạy lệnh:
   `"D:\Games\Godot\Godot_v4.7.2-stable_win64.exe" --main-pack "build\AnhHungDatViet.pck"`
2. Hoặc mở `project.godot` trong Godot 4.7.2 và bấm **F5** để chạy trực tiếp từ dự án.

### Trên điện thoại Android (`AnhHungDatViet.apk`)
1. Chép tệp `AnhHungDatViet.apk` vào điện thoại (chỉ hỗ trợ máy 64-bit `arm64-v8a`, xoay ngang màn hình).
2. Mở tệp `.apk` từ trình quản lý tệp.
3. Khi Android hỏi quyền cài ngoài Play Store: vào **Cài đặt → Cho phép từ nguồn này (Cho phép nguồn không xác định)** rồi bấm **Cài đặt**.
4. Nếu Google Play Protect hỏi khi cài bản debug nội bộ, chọn **"Vẫn cài đặt"**.

### Trên máy tính MacBook (`AnhHungDatViet-macOS.zip`)
Hỗ trợ cả chip **Apple Silicon (M1–M4)** và **Intel**. Vì đây là bản thử nội bộ chưa ký số/công chứng với Apple:
1. Giải nén `AnhHungDatViet-macOS.zip` để lấy `Anh Hùng Đất Việt.app` (có thể kéo vào thư mục *Applications* hoặc để ngay ngoài *Downloads*).
2. Mở **Terminal** tại thư mục chứa tệp `.app` (hoặc gõ `xattr -cr ` rồi kéo biểu tượng `Anh Hùng Đất Việt.app` vào cửa sổ Terminal) và chạy:
   ```bash
   xattr -cr "Anh Hùng Đất Việt.app"
   ```
3. Nhấp chuột phải vào `Anh Hùng Đất Việt.app` → chọn **Open** (nếu macOS vẫn hỏi, vào **System Settings → Privacy & Security → Open Anyway**).

---

## 2. Bảng phím điều khiển

| Hành động | Máy tính | Điện thoại (cảm ứng) | Tay cầm |
|---|---|---|---|
| Di chuyển | `WASD` hoặc phím mũi tên | Cần gạt bên trái | Cần trái |
| Tấn công | Giữ chuột trái hoặc `J` | Giữ nút vũ khí | `A` / Cò phải (`RT`) |
| Ngắm bắn | Con trỏ chuột | Tự ngắm giặc gần nhất | Tự ngắm |
| Tung kỹ năng | Chuột phải / `Space` / `K` | Nút kỹ năng | `B` |
| **Đổi vũ khí** | **Lăn chuột** (lên/xuống) hoặc `Q` | Nút **Đổi** | `LB` |
| **Nhặt / dùng** | `E` | Nút **Nhặt / Dùng** | `Y` |
| Tạm dừng / Cài đặt | `Esc` hoặc `P` | Nút **II** | `Start` |

*(Gợi ý nhỏ: `E` chỉ nhặt vũ khí dưới chân hoặc tương tác trạm/chợ/rương, không bao giờ đổi nhầm vũ khí khi đang đứng trống!)*

---

## 3. Đồng điệu binh khí (`★★` / `★`) và 6 Ấn hệ

Khi tung kỹ năng (`Space` / Chuột phải), game kiểm tra vũ khí **đang cầm trên tay** và kích hoạt đồng thời **mức Đồng điệu** + **Ấn hệ**:

- **★★ Tâm đắc (Vàng):** Đang cầm **vũ khí khởi đầu** của chính tướng đó, hoặc **binh khí định mệnh**:
  - Lý Thường Kiệt → *Nỏ thần Liên Châu*
  - Lê Lợi → *Gươm Thuận Thiên*
  - Quang Trung → *Hỏa hổ*
  - Hoàng Hoa Thám → *Súng hỏa mai*
- **★ Cùng hệ (Bạc):** Đang cầm vũ khí cùng hệ với vũ khí khởi đầu, hoặc bất kỳ vũ khí hệ **Thần khí**.
- **Chưa đồng điệu:** Giữ nguyên hiệu ứng kỹ năng gốc. *(Hiệu ứng kéo dài luôn giữ nguyên mức lúc bạn tung chiêu, đổi vũ khí giữa chừng không bị mất.)*

### Bảng 6 Ấn hệ (luôn cộng thêm vào chiêu gốc)

| Hệ vũ khí | Tên Ấn hệ | Hiệu ứng cộng thêm khi tung chiêu |
|---|---|---|
| Đao kiếm | **Kiếm khí** | Phóng 6 luồng sóng kiếm tỏa 360° quanh mình (sát thương = vũ khí đang cầm, tối thiểu 4) |
| Côn thương | **Trấn địa** | Tạo sóng chấn địa bán kính 60 (sát thương 4, đẩy lùi mạnh, choáng 0,6 giây) |
| Cung nỏ | **Mưa tên** | Trong 1,5 giây rơi 12 mũi tên quanh mình bán kính 90 (ưu tiên chỗ có giặc, 3 sát thương/mũi) |
| Hỏa khí | **Hỏa ấn** | Đặt 3 vùng lửa nhỏ hình tam giác quanh mình tồn tại 2 giây |
| Súng | **Nạp đạn thần tốc** | Trong 4 giây: tốc độ bắn **+30%** và đạn xuyên thêm 1 giặc |
| Thần khí | **Linh khí** | Hồi ngay **40 năng lượng**, lần hồi chiêu này ngắn hơn **30%** |

---

## 4. Tu luyện tướng và Rèn binh khí khởi đầu

Trong doanh trại (sảnh chính), đứng cạnh tượng tướng đã mở khóa, bấm `E` và chuyển sang thẻ **Tu luyện**:

- **Tu luyện tướng (Cấp 1 → 5):**
  - Cấp 2 (`150 xu`): `+1 máu tối đa`
  - Cấp 3 (`300 xu`): `+1 giáp tối đa`
  - Cấp 4 (`500 xu + 2 Yêu hồn`): `+30 năng lượng tối đa`
  - Cấp 5 (`800 xu + 1 Ngọc thần`): `hồi kỹ năng ×0,85` *(đạt tối đa: "Đã viên mãn")*
  - *(Cộng dồn trực tiếp với nâng cấp chung ở Lò rèn.)*
- **Rèn binh khí khởi đầu (Bậc 1 → 5):**
  - Bậc 2 (`100 xu + 3 Đồng`): sát thương `×1,25`
  - Bậc 3 (`220 xu + 5 Sắt + 2 Đồng`): sát thương `×1,5`, hồi đòn `×0,92`, **mở Đặc tính 1** *(viền xanh lam)*
  - Bậc 4 (`400 xu + 6 Sắt + 2 Yêu hồn`): sát thương `×1,8`, hồi đòn `×0,88`
  - Bậc 5 — **Thức tỉnh** (`700 xu + 8 Sắt + 3 Yêu hồn + 2 Ngọc thần`): sát thương `×2,2`, hồi đòn `×0,85`, **mở Đặc tính 2** *(viền vàng lấp lánh)*

Ngoài ra, tại **Lò rèn** trong sảnh (thẻ *Rèn binh khí*), bạn có thể dùng **Xu** và **6 loại nguyên liệu** nhặt từ giặc/rương (*Đồng, Sắt, Gỗ lim, Hỏa dược, Yêu hồn, Ngọc thần*) để rèn sẵn 1 vũ khí cấp 2–5 đã sưu tầm mang vào ô 2 ở lượt xuất trận kế tiếp.

---

## 5. Nơi lưu game và cách gửi lại tệp nhật ký trận (`nhat_ky.csv`)

Mỗi khi kết thúc một lượt chơi (kể cả khi bỏ lượt), game tự động ghi thêm 1 dòng thống kê vào tệp `nhat_ky.csv` trên máy bạn (không hề gửi qua mạng đi đâu).

- **Đường dẫn lưu trên Windows:**
  `%APPDATA%\Godot\app_userdata\Anh Hùng Đất Việt\`
  *(Trong đó có `save.json`, `run.json` và `nhat_ky.csv`.)*
- **Đường dẫn lưu trên macOS:**
  `~/Library/Application Support/Godot/app_userdata/Anh Hùng Đất Việt/`
- **Cách mở nhanh ngay trong game:** bấm `Esc` (tạm dừng) → **Cài đặt** → bấm nút **"Mở thư mục nhật ký"**.
- Sau vài trận chơi thử, bạn chỉ cần nén hoặc gửi trực tiếp tệp `nhat_ky.csv` lại cho nhóm phát triển để cân bằng độ khó ở bản cập nhật sau!
