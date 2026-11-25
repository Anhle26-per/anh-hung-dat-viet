# Hướng dẫn phát hành bản cập nhật (Auto-Updater 2,4 MB)

Game đã gắn sẵn bộ **Tự động cập nhật** trỏ tới GitHub Releases tại:
`https://github.com/Anhle26-per/anh-hung-dat-viet`

Bạn bè chỉ cần cài bản đầy đủ (`AnhHungDatViet-Windows.zip`, `AnhHungDatViet-macOS.zip`, `AnhHungDatViet.apk`) **1 lần duy nhất**. Các lần sau khi bạn sửa lỗi hay thêm tính năng, bạn chỉ cần up đúng **2 tệp nhỏ (~2,4 MB)**: `version.json` và `AnhHungDatViet.pck`.

---

## Bước 1 (Chỉ làm 1 lần): Tạo kho chứa trên GitHub
1. Đăng nhập tài khoản **https://github.com/Anhle26-per**.
2. Bấm dấu **`+`** góc trên phải → **New repository**.
3. Đặt đúng tên: **`anh-hung-dat-viet`**, chọn **Public**, bấm **Create repository**.
   *(Bắt buộc là **Public** thì game trên máy bạn bè mới tải được bản vá không cần đăng nhập; bạn có thể giữ kho trống hoặc chỉ đẩy code/release tùy ý.)*

---

## Bước 2: Tạo gói vá mỗi khi có bản mới (1 lệnh)
Mở Terminal / PowerShell tại `D:\Games\anh-hung-dat-viet` và chạy (thay số phiên bản + build tăng dần):

```powershell
python tools/tao_ban_cap_nhat.py --version 1.2.1 --build 121 --notes "Mô tả bản cập nhật mới"
```

Công cụ sẽ tự động:
1. Tăng số phiên bản trong `scripts/data/version.gd`.
2. Xuất tệp vá mới `build/AnhHungDatViet.pck` (~2,4 MB).
3. Tính mã kiểm tra `SHA-256` và tạo sẵn **2 tệp** trong `build/release_patch/`:
   - `AnhHungDatViet.pck`
   - `version.json`

---

## Bước 3: Đăng lên GitHub Releases (30 giây)
1. Vào **`https://github.com/Anhle26-per/anh-hung-dat-viet/releases/new`**.
2. Ô **Tag version**: gõ `v1.2.1` (khớp với `--version` ở Bước 2); **Release title**: gõ tiêu đề bất kỳ.
3. Kéo thả **đúng 2 tệp** từ `D:\Games\anh-hung-dat-viet\build\release_patch\` vào ô **Attach binaries**:
   - `AnhHungDatViet.pck`
   - `version.json`
   *(Lưu ý: giữ nguyên đúng tên 2 tệp này, không đổi tên!)*
4. Bấm **Publish release**.

**Xong!** Ngay lúc đó, ai mở game trên **Windows, macOS hay Android** có mạng đều tự thấy hộp thoại *"CẬP NHẬT MỚI"* → bấm **Cập nhật ngay** → tải ~2,4 MB trong vài giây và tự khởi động lại lên bản mới, **giữ nguyên 100% file lưu `save.json`**.

> **Lưu ý khi nâng cấp bộ máy Godot:** Nếu sau này bạn nâng cấp lên bản Godot mới hơn (ví dụ 4.8), hãy gửi lại bộ cài `.zip`/`.apk` đầy đủ 1 lần rồi mới tiếp tục vá `.pck`. Với các bản sửa code/tướng/quái/map/cân bằng trên cùng Godot 4.7.2, dùng `.pck` này vĩnh viễn!
