# Anh Hùng Đất Việt: Tiến độ và kế hoạch

Cập nhật: 27/11/2026 — **Mega Expansion v3.0.0 (*Giang Sơn Gấm Vóc*)**

Đây là game roguelike bắn súng góc nhìn từ trên xuống, kiểu Soul Knight, làm bằng **Godot 4.7.2** với đồ họa pixel art. Người chơi điều khiển các anh hùng Việt Nam từ thời Hồng Bàng – Âu Lạc đến năm 1954 và thế giới Thần Thoại Lĩnh Nam, hỗ trợ chơi đơn, chơi LAN Co-op (2–4 người) và chế độ Thủ Thành Cổ Loa. **Định hướng:** game phi thương mại, chạy cục bộ & chơi LAN cùng bạn bè.

---

## 0. Lộ trình phát triển v2.0 → v3.0.0 (*Giang Sơn Gấm Vóc*)

| Phiên bản | Tên gọi | Điểm nhấn chính |
|---|---|---|
| **v2.0.0** | *Linh Hồn Chiến Trận* | 18 công thức hợp nhất & 6 Thần binh Hợp nhất Cấp 5, Tiến Hóa vũ khí, 13 Thần binh Trùm Đỏ, 11 Nội tại + 11 Chiêu 2 + 5 Tượng Thần Việt, Dodge Dash, Charge, Combo 3 đòn, Thú cưỡi, EventAltar, Hazards, Boss Rush 1..13, Badass & 8 Mutators. |
| **v2.1.0** | *Vạn Binh Khởi Trận* | Toàn bộ 13 trùm Pha 1 & Pha 2 nâng cấp 48 khung lưới 12×4 (10 trạng thái), Sảnh Solo click-to-select & 5 NPC sinh động, Linh thú theo xuống Tầng Hầm, LAN cho phép trùng tướng & nhịp độ Horde (tối đa 28 giặc/phòng). |
| **v2.2.0** | *Kho Báu Lĩnh Nam* | Vứt vũ khí `[G]`, Rương phân tầng & Mảnh bản vẽ (T1–T5), Ghép Bản Vẽ tại Tầng Hầm, tự động cập nhật hotpatch `.pck` + `HotpatchSync`. |
| **v2.3.0** | *Anh Linh Khởi Thế* | Đồng bộ 28 khung (896×32) cho tất cả anh hùng, 24 khung cho 49 quái nhỏ, `SkillCastFx` riêng cho từng tuyệt kỹ, sửa triệt để UI Đại Sảnh không chồng lấn. |
| **v2.4.0** | *Hồn Sử Đại Việt* | Thời tiết 10 chương + Bloom, Vết chiến trường (`GroundDecal`) & vệt vũ khí, Hợp Chiêu Đại Việt LAN (`CoopSynergyData`), 16 trang Hồn Sử & Tường Kỷ Vật, Võ Đường DPS Meter & Thử Binh Khí. |
| **v3.0.0** | *Giang Sơn Gấm Vóc* | **4 Trụ Cột Đại Mở Rộng**: (1) Thủ Thành Cổ Loa (Nỏ Thần, 8 bệ & 5 loại tháp Lv1–3, Boss Công Thành mỗi 5 đợt), Ping chiến thuật 4 loại, Bảng tổng kết MVP & Võ Đài Tỷ Thí; (2) 14 Tướng (thêm An Dương Vương, Lạc Long Quân, Sơn Tinh — 28 kỹ năng), Trang phục Anh Hùng (`HeroSkins`), 15 Cổ Vật Sử Việt (`Relics`), Cây Thiên Phú 4 nhánh 16 nút (`SkillTree`), 12 Bùa + 8 Thuộc tính (`Affixes`) + 8 Vũ khí mới (tổng 225 vũ khí); (3) Cổng phân nhánh, 2 Bí Cảnh (*Thủy Cung Bạch Đằng* – Thủy Tinh, *Đỉnh Tản Viên* – Thiên Lôi Ma Vương, 48f 12×4), Độ khó Hào Khí 1..10 & Boss Pha 3 Cuồng Nộ (`<= 25% HP`); (4) 4 Thần Thú Thức Tỉnh (`*_evo.png`), 4 Danh Sĩ giải cứu trong hầm ngục (mở rộng Vườn Thảo Dược 3→6 luống + Linh Chi Vàng & Hoa Ưu Đàm), Kết Thúc Thực Màn 33 (*Đỉnh Hồng Lĩnh — Cửu Trùng*, Trùm **Hỗn Mang Yêu Đế** 48f & **Thái Tổ Thiên Kiếm**), 24 trang Hồn Sử, 30 Thành Tựu & tương thích ngược file lưu v2.4.0. |

Kiểm thử tự động hiện có **35 bộ kiểm thử (`tests/*_test.tscn`) + `check_scripts.tscn`** (gồm `smoke_test.tscn` và `v30_mega_expansion_test.tscn`), xác minh cả hotpatch GPU `v2.4.0 -> v3.0.0`.

---

## 1. Tóm tắt nhanh

| Hạng mục | Hiện trạng |
|---|---|
| Lối chơi chính (đánh, nhặt đồ, qua màn) | Xong, chơi được từ đầu đến cuối |
| Nội dung | 10 tướng, 67 vũ khí, 10 chương (30 màn), 10 trùm, 3 trùm Tam Yêu, 16 loại lính, 7 yêu quái |
| Sảnh chính (doanh trại) | Xong: chọn tướng, nâng cấp, kho vũ khí, hình nhân tập, bia thành tích |
| Đồ họa | Toàn bộ là pixel art tự vẽ bằng code (264 ảnh), không dùng hình của ai |
| Âm thanh | **Chưa có** |
| Cân bằng độ khó | **Chưa chơi thử bằng tay** |
| Đóng gói gửi bạn bè (`.exe` / `.apk`) | **Chưa làm** (đã có điều khiển cảm ứng) |
| Chơi chung qua LAN | **Chưa làm** (đã có thiết kế chi tiết, thẻ N1–N8) |
| Quảng cáo / kiếm tiền | **Đã bỏ**, vì không phát hành công khai |
| Kiểm thử tự động | Có: một bài test máy tự chơi 10 tướng, 30 màn, kiểm tra mọi hệ thống |

Quy mô mã nguồn:
- Khoảng 7.200 dòng GDScript (game).
- Khoảng 5.200 dòng Python (công cụ vẽ hình).

---

## 2. Đã làm được, theo từng giai đoạn

### Giai đoạn 1: Chọn công cụ và dựng khung game
- Chọn **Godot 4** thay vì Unity: miễn phí hoàn toàn, nhẹ, hợp game 2D pixel, xuất được Android/iOS.
- Màn hình 640×360 phóng to sắc nét, font pixel VT323 có tiếng Việt.
- Hầm ngục sinh ngẫu nhiên. Mỗi màn có:
  - phòng an toàn và phòng đánh giặc (giặc ra theo đợt, cửa khóa lại);
  - phòng kho báu và cổng sang màn mới.
- Điều khiển:
  - Bàn phím và chuột: WASD, chuột trái đánh, chuột phải hoặc Space dùng kỹ năng, E nhặt hoặc đổi vũ khí, Esc dừng.
  - Tay cầm chơi game.
  - Màn hình cảm ứng: cần gạt trái, nút đánh, kỹ năng và đổi đồ; tự ngắm giặc gần nhất.

### Giai đoạn 2: Tướng, kỹ năng, vũ khí
- **10 vị tướng**, mỗi người một vũ khí cơ bản và một kỹ năng riêng theo sự tích:

  | Tướng | Thời kỳ | Kỹ năng |
  |---|---|---|
  | Hai Bà Trưng | Năm 40, Mê Linh | Song Trưng (Trưng Nhị đánh theo) |
  | Bà Triệu | Năm 248, núi Nưa | Voi chiến |
  | Ngô Quyền | Năm 938, Bạch Đằng | Cọc Bạch Đằng |
  | Lý Thường Kiệt | Năm 1077, Như Nguyệt | Nam quốc sơn hà (vòng phản đạn) |
  | Trần Hưng Đạo | Năm 1285 | Hịch tướng sĩ (gọi quân) |
  | Lê Lợi | Năm 1427, Chi Lăng | Gươm Thuận Thiên (kiếm bay quanh người) |
  | Quang Trung | Năm 1789 | Thần tốc (lướt chém) |
  | Nguyễn Trung Trực | Năm 1861 | Hỏa hồng Nhật Tảo (biển lửa) |
  | Hoàng Hoa Thám | Năm 1890, Yên Thế | Hùm thiêng (hổ, sóng làm choáng) |
  | Chiến sĩ Điện Biên | Năm 1954 | Kéo pháo (đặt pháo tự bắn) |

- **67 vũ khí, chia 5 cấp**:

  | Cấp | Màu | Số vũ khí |
  |---|---|---|
  | Thường | xám | 20 |
  | Tốt | xanh lá | 11 |
  | Hiếm | xanh dương | 11 |
  | Sử thi | tím | 12 |
  | Huyền thoại | vàng | 13 |

  - Đủ thời đại, từ kiếm đồng, nỏ, giáo đến súng trường và súng phóng tên lửa.
  - Có vũ khí truyền thuyết: Rìu Thạch Sanh (bay về tay như boomerang), Đàn thần, Gậy Sơn Tinh (gai đá), Đinh ba Thủy Tinh, Búa thiên lôi (sét lan), Tre trăm đốt…
  - 5 kiểu đánh: chém cận chiến, bắn xa, tia, sóng, gai đất.
- Nhặt vũ khí: vũ khí rơi có cột sáng theo màu cấp và mũi tên chỉ. Đứng gần sẽ hiện chỉ số. Mang tối đa 2 món.

### Giai đoạn 3: Giặc, yêu quái, trùm
- **10 chương lịch sử**, mỗi chương 3 màn, có cảnh vật và quân địch riêng: Đông Hán, Đông Ngô, Nam Hán, Tống, Nguyên Mông, Minh, Thanh, thủy quân Pháp, quân viễn chinh Pháp, tập đoàn cứ điểm Điện Biên.
- **Lính**:
  - Thời phong kiến: bộ binh, cung thủ, khiên binh (đỡ đòn phía trước), pháp sư (gọi yêu, bắn đạn độc), kỵ binh.
  - Thời cận đại: lính súng trường, xạ thủ súng máy, pháo cối, xe tăng.
- **Yêu quái do tà thuật gọi ra** (hư cấu cho kịch tính): Tiểu yêu, Hồ tinh, Mộc tinh, Chằn tinh, Đại bàng tinh, Ma trơi, Ngư Tinh.
- **Giặc tinh nhuệ**: to hơn, phát sáng vàng, trâu gấp 2,4 lần, hay rơi vũ khí.
- **10 trùm**, mỗi con có 4 chiêu thường và 1 chiêu đặc biệt dựng theo sự tích. Ví dụ:
  - Tô Định cạo râu bỏ chạy.
  - Thoát Hoan chui ống đồng.
  - Liễu Thăng sa lầy ở Chi Lăng.
  - Tàu Hy Vọng bốc cháy.
  - Đờ Cát rút vào hầm chỉ huy.

### Giai đoạn 4: Sức mạnh trong lượt chơi
- **Phúc lành**: qua mỗi màn chọn 1 trong 3, cộng dồn. Có 16 loại, như Bánh chưng, Rượu thuốc, Mắt thần (chí mạng), Ngựa ô, Bùa hộ mệnh…
- **Vũ khí cơ bản** cho mỗi tướng. Vũ khí mạnh hơn phải nhặt trong trận.

### Giai đoạn 5: Sảnh chính (Doanh trại Anh Hùng)
- Đi lại tự do trong sảnh:
  - Tượng các tướng trên sân khấu gỗ; tướng chưa mở khóa là tượng đá xám.
  - Lò rèn: nâng cấp vĩnh viễn, gồm Rèn thân, Rèn giáp, Luyện khí, Lễ xuất quân, Thuốc hồi sinh.
  - Giá binh khí: kho vũ khí đã khám phá.
  - Hình nhân tập võ: đo sát thương mỗi giây.
  - Bia đá thành tích và cổng xuất quân.
- Cảnh sống động: lá rơi, đom đóm, khói hương, đèn lồng, ao sen, lính tuần, gà chạy. Nền sảnh vẽ lại thành đình làng có mái cong, cột son, sân gạch Bát Tràng.
- Lưu tiến trình: xu, tướng đã mở, nâng cấp, vũ khí đã khám phá, thành tích.

### Giai đoạn 6: Làm đẹp đồ họa
- Vẽ lại lính (khung 24×26, có mũ riêng từng đạo quân), gạch nền 7 kiểu, tường cao 2 ô có bóng đổ, ánh sáng đuốc.
- Sách tranh pixel art trong `docs/artbook/` để xem phóng to mọi hình.

### Giai đoạn 7: Học từ bản tham khảo Soul Knight (C++, CalvinWan0101)
Chỉ lấy ý tưởng. Không chép mã, không dùng hình gốc.
- **Rương sơn mài** sau mỗi phòng dọn sạch: thường ra xu, đôi khi ra hồ lô hoặc vũ khí.
- **Gánh hàng rong**: bà hàng nón lá bán vũ khí, hồ lô và bùa, trả bằng xu.
- **Hồ lô thuốc**: nhỏ (+2 máu), lớn (+5 máu), linh khí (+80 năng lượng).
- **Trạng thái Cháy và Trúng độc**, có biểu tượng trên đầu. Thêm **chướng khí** (đám mây độc).
- **Bước hoàn thiện nét vẽ** `polish()`, học kỹ thuật chung từ thư mục Resources:
  - viền gần đen;
  - mỗi mảng màu có khối riêng;
  - vân trên mảng lớn.

### Giai đoạn 8: Trùm ngẫu nhiên, biến hình, Tam Yêu (vừa làm xong)
- **Trùm ngẫu nhiên**: mỗi lượt xáo 10 trùm, không trùng cho đến khi gặp đủ.
- **Sức mạnh tăng theo thứ tự gặp**, không theo từng con:
  - Máu từ 300 (trùm thứ 1) đến 1434 (trùm thứ 10).
  - Ra chiêu nhanh hơn, đạn nhanh hơn, gọi thêm lính.
- **Hiện nguyên hình**: còn nửa máu thì trùm biến thành ma tướng to gấp đôi, có sừng, mắt rực và bộ chiêu mới. Ví dụ Thoát Hoan thành Lang Quỷ, Hoằng Tháo thành Thủy Quỷ, Tàu Hy Vọng thành Tàu Ma Lửa Xanh.
- **Tam Yêu** (theo truyền thuyết Lạc Long Quân diệt yêu): Hồ Tinh chín đuôi, Mộc Tinh cây chiên đàn, Ngư Tinh Biển Đông.
  - Xuất hiện ở màn giữa chương với tỉ lệ 40%.
  - Mỗi yêu có chiêu riêng (phân thân, rễ cây trồi, lặn và tường nước) và cũng hiện nguyên hình.

---

## 3. Cách làm việc và công cụ

| Việc | Cách làm |
|---|---|
| Mở game | Tải Godot 4.x (bản Standard), Import thư mục dự án, bấm F5 |
| Sửa nội dung | Dữ liệu nằm gọn trong `scripts/data/`: `heroes.gd`, `weapons.gd`, `enemies.gd`, `buffs.gd`. Thêm một dòng là có tướng, vũ khí hoặc giặc mới |
| Vẽ lại hình | `python3 tools/sprites/build_all.py`. Mọi hình đều sinh từ code Python nên sửa và vẽ lại được hàng loạt |
| Kiểm tra lỗi mã | `godot --headless --path . res://tests/check_scripts.tscn` |
| Máy tự chơi thử | `godot --headless --path . --fixed-fps 60 res://tests/smoke_test.tscn` (khoảng 15–25 phút, in `SMOKE TEST OK`) |

Những gì bài test tự chơi kiểm tra:
- Sảnh chính và nâng cấp.
- Kỹ năng của cả 10 tướng, bắn thử cả 67 vũ khí.
- Đi hết 30 màn: 10 trùm và đủ Tam Yêu, 20 lần hiện nguyên hình, chiêu đặc biệt, cơn nổi giận.
- Mở rương, mua hàng, trúng độc, chết rồi hồi sinh.

Kết quả gần nhất (23/11/2026): **SMOKE TEST OK**.
- Gặp đủ Tam Yêu.
- 20/20 lần hiện nguyên hình.
- 10 trùm không trùng nhau, máu tăng dần.

---

## 4. Những điểm còn yếu (nói thật)

1. **Chưa có âm thanh.** Game im lặng là điểm trừ lớn nhất khi phát hành.
2. **Chưa cân bằng độ khó bằng tay.** Bài test chỉ chứng minh game không lỗi, chưa chứng minh game vui. Trùm cuối, giá hàng và tỉ lệ rơi đồ cần người thật chơi thử.
3. **Tỉ lệ nhân vật.** Đầu nhân vật nhỏ hơn kiểu chibi đầu to của Soul Knight, nên nhìn chưa "đáng yêu" bằng. Muốn bằng thì phải vẽ lại tướng và lính theo tỉ lệ mới.
4. **Chưa có hoạt ảnh tấn công riêng** cho từng tướng (đang dùng chung hoạt ảnh đi và vung vũ khí).
5. **Đạn bay qua vùng tối** ngoài tường ở vài chỗ (lỗi nhỏ về va chạm, chưa sửa).
6. **Chưa đóng gói** `.exe` và `.apk`, chưa thử trên điện thoại thật.
7. **Chưa lưu giữa lượt**: tắt game giữa trận thì mất xu của lượt đó.
8. **Chưa chơi chung được.**
9. **Nhạy cảm nội dung** (ít quan trọng hơn vì chỉ chơi trong nhóm bạn):
   - Game dừng ở năm 1954, không có kháng chiến chống Mỹ.
   - Dùng hình tượng chung "Chiến sĩ Điện Biên" thay vì người có thật.
   - Biến tướng giặc có thật thành quỷ là hư cấu ("tà thuật"). Nên cân nhắc khi phát hành quốc tế, ví dụ ghi chú hư cấu ở màn hình đầu.

---

## 5. Kế hoạch còn lại (giao cho Gemini)

Chi tiết từng việc, lệnh test và cách duyệt nằm trong **[GIAO-VIEC-GEMINI.md](GIAO-VIEC-GEMINI.md)**. Luật làm việc cho Gemini nằm trong **`AGENTS.md`** ở gốc dự án.

| Đợt | Thẻ việc | Kết quả khi xong |
|---|---|---|
| **1. Nền tảng** | G01 lưu giữa lượt · G02 âm thanh · G03 cài đặt và độ khó · G04 đóng gói `.exe`/`.apk` · G05 sửa lỗi nhỏ | Chơi một mình thoải mái, gửi được cho bạn bè |
| **2. Chơi LAN** | N1 phòng chờ · N2 nhiều người · N3 giặc do host điều khiển · N4 đạn và đòn đánh · N5 phòng, rương, cửa hàng · N6 kỹ năng · N7 gục và cứu đồng đội · N8 rớt mạng | 2–4 người chơi chung qua wifi nhà |
| **3. Thêm vui** | G06 mã thử thách · G07 hướng dẫn · G08 tướng đầu to · G10 hoạt ảnh riêng · G09 nội dung mới | Đẹp hơn, nhiều thứ để so tài |
| **Xen kẽ** | G11 cân bằng độ khó theo nhật ký trận của nhóm | Độ khó vừa sức nhóm bạn |

**Đã bỏ** vì không phát hành công khai: quảng cáo, mua trong game, tài khoản Google Play, thủ tục thử nghiệm kín, giấy tờ theo Nghị định 147, bản tiếng Anh, bản iOS.

---

## 6. Thứ tự đề xuất

1. **Chuẩn bị** theo mục 1 của GIAO-VIEC-GEMINI.md: sao lưu, `git init`, cài Antigravity, chạy thử `tools/run_tests`.
2. **Đợt 1**: làm G01 đến G05 rồi gửi `.exe`/`.apk` cho bạn bè chơi thử.
3. **G11 bước 1** (nhật ký trận) để nhóm chơi có số liệu.
4. **Đợt 2**: chơi LAN, làm từng thẻ N theo thứ tự, mỗi thẻ đều chơi thử bằng 2 máy.
5. **Đợt 3** và **G11 bước 2**: làm dần theo ý thích của nhóm.

---

## 7. Cấu trúc thư mục chính

```
anh-hung-dat-viet/
├─ project.godot            cấu hình game
├─ scenes/                  màn hình: menu, chọn tướng, sảnh, trận đánh
├─ scripts/
│  ├─ autoload/global.gd    lưu tiến trình, xu, nâng cấp, thứ tự trùm
│  ├─ data/                 DỮ LIỆU: tướng, vũ khí, giặc, trùm, Tam Yêu, phúc lành
│  ├─ entities/             người chơi, giặc, đạn, vật phẩm, rương
│  ├─ effects/              hiệu ứng: nổ, lửa, độc, chướng khí, kỹ năng
│  ├─ game/                 sinh hầm ngục, phòng, sảnh, gánh hàng rong
│  └─ ui/                   thanh máu, bản đồ nhỏ, menu, nút cảm ứng
├─ assets/sprites/          264 ảnh pixel (sinh tự động từ tools/sprites)
├─ tools/sprites/           code Python vẽ toàn bộ hình
├─ tools/run_tests.*        script chạy test (Windows .bat, Linux/Mac .sh)
├─ AGENTS.md, GEMINI.md     luật làm việc cho Gemini
├─ tests/                   kiểm thử tự động
└─ docs/                    ảnh chụp, sách tranh, tài liệu này
```
