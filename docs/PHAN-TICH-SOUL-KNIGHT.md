# Phân tích thiết kế Soul Knight (từ nguồn công khai)

> **Mục đích & nguyên tắc:** Tài liệu này tổng hợp các số liệu và quy luật thiết kế từ nguồn công khai (`soul-knight.fandom.com`, wiki và ghi chú cập nhật công khai của nhà phát hành/cộng đồng), tuyệt đối **không** giải nén, dịch ngược hay trích xuất tài nguyên từ bất kỳ game nào. Mọi đề xuất cho *Anh Hùng Đất Việt* đều được thiết kế lại thuần **chất Việt**, không sao chép tên, hình ảnh, âm thanh hay câu chữ của *Soul Knight*.

---

## 1. Cảm giác chiến đấu

### 1.1. Tốc độ di chuyển
- **Tốc độ nền:** Nhân vật trong *Soul Knight* di chuyển trung bình khoảng **6,5 ô/giây** khi chiến đấu (một số nhân vật thiên phòng thủ/đặt bẫy chậm hơn nhẹ, khoảng **6 ô/giây**). Các kỹ năng lướt/cưỡi đặc biệt có thể đẩy tốc độ lên **12,5–16,25 ô/giây** (nguồn: `soul-knight.fandom.com`).
- **Giảm tốc khi bắn/gồng:** Một số vũ khí nặng (súng bắn tỉa, súng hai nòng/tản, đại bác) áp dụng hệ số giảm tốc độ di chuyển tạm thời khi giữ cò hoặc gồng đòn, buộc người chơi phải chọn vị trí đứng bắn hợp lý (nguồn: `soul-knight.fandom.com`).

### 1.2. Tốc độ đạn và đọc quỹ đạo
- **Phân tầng tốc độ đạn:** Wiki công khai không liệt kê một bảng hằng số pixel/giây cố định cho mọi loại đạn, nhưng chia rõ hai nhóm cảm giác:
  - *Đạn đọc được bằng mắt (mưa đạn):* đạn của quái, trùm và vũ khí tầm gần/trung bay ở tốc độ vừa phải để người chơi kịp lách qua khe đạn.
  - *Đạn tốc độ cực cao / tức thì:* súng bắn tỉa, súng điện từ/railgun cho cảm giác trúng ngay khi bóp cò, giảm trượt mục tiêu di động (nguồn: `soul-knight.fandom.com`).
- **Tác động độ khó:** Có điều kiện thử thách (Challenge Conditions) trực tiếp tăng/giảm tốc độ đạn địch để thay đổi áp lực né tránh.

### 1.3. Thời gian bất tử sau trúng đòn (i-frames) và sát thương tràn giáp
- **Không có cửa sổ bất tử dài mặc định sau mỗi lần trúng đòn thường:** Khác với nhiều game bắn máy bay cho 0,5–1 giây bất tử sau mỗi lần mất máu, *Soul Knight* không cho i-frames kéo dài mặc định khi bị trúng đạn thường; nếu đã vỡ giáp mà đứng trong chùm đạn, các viên kế tiếp trừ máu liên tiếp (nguồn: `soul-knight.fandom.com`, bài phân tích cộng đồng).
- **Bất tử gắn với kỹ năng chủ động:** Khả năng tránh sát thương tức thời chủ yếu nằm ở kỹ năng (ví dụ lộn né, lao lướt tàng hình, khiên năng lượng hấp thụ đạn).
- **Quy tắc tràn giáp (Overflow Damage):** Mặc định khi giáp còn ít hơn sát thương đòn đánh (ví dụ còn **1 giáp** nhưng trúng đạn **5 sát thương**), giáp vỡ về `0` và phần dư (**4 sát thương**) tràn thẳng sang trừ vào **Máu**. Cơ chế chống tràn giáp chỉ có khi sở hữu phúc lành/nội tại chuyên biệt (*Strong Shield* — nguồn: `soul-knight.fandom.com`, NamuWiki).

### 1.4. Cách hồi giáp
- **Thời gian chờ hồi giáp:** Khi không nhận thêm sát thương trong **5 giây**, giáp tự động hồi lại (nguồn: `soul-knight.fandom.com`).
- **Điều kiện rút ngắn:** Một số điều kiện/hiệu ứng đặc biệt có thể rút thời gian chờ hồi giáp xuống còn **2 giây** (nguồn: `soul-knight.fandom.com`).
- **Ý nghĩa thiết kế:** Độ trễ 5 giây tạo ra nhịp *"xông lên xả đạn → lùi sau vật cản 5 giây hồi giáp → tiếp tục giao tranh"*, khiến người chơi luôn phải tìm chỗ ẩn nấp thay vì lao đầu vào mưa đạn.

---

## 2. Nhịp màn chơi

### 2.1. Số phòng mỗi màn và cấu trúc hầm ngục
- **Chuỗi màn chuẩn:** **3 tầng × 5 màn** (từ `1-1` đến `3-5`, kèm khu ẩn tùy chọn); trùm chính xuất hiện ở các màn cuối tầng `X-5` (nguồn: `soul-knight.fandom.com`).
- **Số phòng mỗi màn:** Mỗi màn thường có tối thiểu **5 phòng** (trừ phòng trùm cuối tầng):
  - `1` phòng xuất phát;
  - `2–3` phòng đánh giặc trên trục chính (thường chỉ cần dọn **2 phòng giặc** là thông đường tới cổng qua màn, các phòng nhánh có thể bỏ qua hoặc khám phá thêm);
  - `0–2` phòng đặc biệt;
  - `1` phòng rương / thương nhân (cửa hàng);
  - `1` phòng cổng qua màn hoặc phòng trùm (nguồn: `soul-knight.fandom.com`).

### 2.2. Số đợt giặc trong phòng
- Phòng chiến đấu tiêu chuẩn thường sinh **1 đợt giặc** ngẫu nhiên theo chủ đề tầng (có thể tăng mật độ/số đợt ở các phòng đặc biệt hoặc khi bật điều kiện thử thách như *Strength in Numbers* — nguồn: `soul-knight.fandom.com`).

### 2.3. Tỉ lệ rơi vũ khí và bình hồi phục
- **Phân cấp rương:** Rương nâu cho vũ khí tối đa cấp Hiếm (Blue), rương xanh dương cho phép rơi tới cấp Sử thi/Huyền thoại (Orange/Mythical), kèm biến thể rương giả (Chester) tạo bất ngờ (nguồn: `soul-knight.fandom.com`).
- **Bình máu và năng lượng:** Các thùng gỗ trong phòng mặc định chủ yếu rơi **xu** và **hạt năng lượng**; tỉ lệ rơi bình máu miễn phí ngoài cửa hàng rất thấp trừ khi người chơi chọn phúc lành chuyên tăng rơi bình từ thùng gỗ (*Crate Buff* — nguồn: `soul-knight.fandom.com`). Nhờ vậy, máu là tài nguyên quý và cửa hàng giữ vai trò sống còn.

### 2.4. Giá cửa hàng (Trader)
- **Nhịp xuất hiện:** Thương nhân không xuất hiện ở `1-1` và `1-2` (trừ điều kiện *Sales Day*) để người chơi kịp tích xu đầu trận; bán **3–4 món** khi chơi đơn và mở rộng lên **6–8 món** khi chơi Co-op hoặc có sự kiện (nguồn: `soul-knight.fandom.com`).
- **Bảng giá bình hồi phục theo màn** (nguồn: `soul-knight.fandom.com`):

| Màn | Bình máu nhỏ | Bình máu lớn | Bình năng lượng nhỏ | Bình năng lượng lớn |
|---|---:|---:|---:|---:|
| `1-1` | 25 xu | 40 xu | 20 xu | 30 xu |
| `1-2` | 31 xu | 49 xu | 24 xu | 37 xu |
| `1-3` | 34 xu | 54 xu | 27 xu | 40 xu |
| `1-4` | 37 xu | 59 xu | 29 xu | 44 xu |
| `1-5` | 39 xu | 63 xu | 31 xu | 47 xu |
| `2-1` | 43 xu | 68 xu | 34 xu | 51 xu |
| `2-5` | 54 xu | 87 xu | 43 xu | 65 xu |
| `3-1` | 58 xu | 92 xu | 46 xu | 69 xu |
| `3-3` | 64 xu | 102 xu | 51 xu | 76 xu |

*(Giá vũ khí cũng tăng tương ứng theo tầng và độ hiếm; cửa hàng Co-op luôn tăng số món bán để 2–4 người đều có thể mua.)*

---

## 3. Chơi chung (Co-op) — tham khảo cho các thẻ N1–N8

Dựa trên tài liệu công khai của *Soul Knight* về chế độ nhiều người chơi (`soul-knight.fandom.com`, thông báo cập nhật công khai của ChillyRoom):

1. **Cách hồi sinh đồng đội:**
   - Khi hết máu, người chơi chuyển sang trạng thái **gục** thay vì thua ngay lập tức; ván chỉ thua khi **tất cả** thành viên cùng gục cùng lúc.
   - Đồng đội đứng cạnh và tương tác để cứu; người được cứu dậy với **1 Máu và 0 Giáp** (giáp sẽ tự hồi sau đó).
   - **Không giới hạn số lần cứu** trong cả trận miễn còn ít nhất 1 người sống sót (và có một số kỹ năng hỗ trợ hồi sinh từ xa trong vòng phép).
2. **Chia đồ & mở rộng cửa hàng:**
   - Rương và vũ khí rơi ra là tài nguyên chung trên sàn — nhóm tự phân chia theo vai trò/vũ khí đang cầm; xu và năng lượng giúp nuôi riêng từng người.
   - Cửa hàng Co-op tăng số lượng vật phẩm bày bán (thường **2 bình + 4 vũ khí**) để không bị cảnh 4 người tranh nhau 1–2 món.
3. **Độ khó tăng theo số người:**
   - Máu kẻ địch trong Co-op tăng thêm khoảng **+50%** so với chơi đơn (và tiếp tục nhân thêm theo số người / độ khó) để bù lại hỏa lực tổng hợp của cả đội.
4. **Gợi ý áp dụng cho thẻ N1–N8 trong `docs/GIAO-VIEC-GEMINI.md`:**
   - **Thẻ N3 (Giặc do host điều khiển):** Công thức hiện dự kiến `×(1 + 0,6 × (số người − 1))` khá hợp lý (nếu test 4 người thấy trùm quá trâu có thể giảm về `0,5`).
   - **Thẻ N5 (Cửa hàng, rương):** Gánh hàng rong hiện chỉ có **3 kệ tre** (`shop.gd`) — khi chơi 2–4 người sẽ bị thiếu đồ. Nên tăng số kệ tỉ lệ theo số người chơi.
   - **Thẻ N7 (Gục ngã và cứu đồng đội):** Bản dự kiến ghi vòng đếm ngược **20 giây** rồi chết hẳn và cứu dậy **50% máu**. Theo kinh nghiệm *Soul Knight*, với nhóm bạn bè chơi vui qua LAN, bỏ giới hạn chết hẳn sau 20 giây (chỉ thua khi cả nhóm cùng gục) nhưng cứu dậy với ít máu (**2 máu, 0 giáp, kèm 1,5 giây bất tử để chạy thoát**) sẽ giữ được cả tinh thần căng thẳng lẫn sự gắn kết đồng đội.

---

## 4. So sánh trực tiếp với *Anh Hùng Đất Việt*

Số liệu bên dưới đối chiếu trực tiếp từ mã nguồn hiện tại trong `scripts/data/*`, `scripts/entities/player.gd`, `scripts/entities/enemy.gd`, `scripts/entities/loot_chest.gd`, `scripts/game/dungeon.gd`, `scripts/game/room.gd`, `scripts/game/shop_stand.gd`:

| Hạng mục | *Soul Knight* (wiki công khai) | *Anh Hùng Đất Việt* (mã nguồn hiện tại) | Đánh giá |
|---|---|---|---|
| **Tốc độ chạy** | ~6,5 ô/giây | `92–100 px/s` với ô `T = 16 px` → **5,75–6,25 ô/giây** (`heroes.gd`, `dungeon.gd`) | Rất sát, hơi chậm nhẹ ~6–10% |
| **Bất tử sau trúng đòn** | Không có i-frames kéo dài mặc định | `_invuln = 0.7s` sau **mọi** đòn đánh (`player.gd:768`) | **Hơi dễ** — người chơi dính 1 viên vẫn chạy xuyên mưa đạn an toàn 0,7s |
| **Trễ hồi giáp** | **5,0 giây** | `ARMOR_REGEN_DELAY = 3.5s`, hồi `1` giáp/giây (`player.gd:30, 200-204`) | **Hơi dễ** — giáp `4–6` (cộng tối đa `+3` Lò rèn, `+10` *Giáp đồng*) hồi khá nhanh |
| **Sát thương tràn giáp** | Mặc định tràn sang máu (trừ khi có buff) | Mặc định tràn sang máu (`hp -= amount - absorbed`, `player.gd:773`), chưa có phúc lành chống tràn | Thiếu 1 phúc lành phòng thủ quan trọng khi gặp trùm đánh to |
| **Số màn mỗi lượt** | 15 màn (3 tầng × 5 màn) | **30 màn** (10 chương × 3 màn, `enemies.gd`) | Dài gấp đôi số màn |
| **Số phòng mỗi màn** | Tối thiểu 5 phòng (chỉ cần dọn 2 phòng giặc) | `5 + mini(level, 5)` = **6–10 phòng/màn** (`dungeon.gd:37`), phần lớn phải đi hết nhánh dẫn tới cổng | **Hơi dài và mệt** từ màn 5 trở đi (tới 4–6 phòng giặc × 2–3 đợt = 10–18 đợt/màn) |
| **Số đợt giặc/phòng** | Thường 1 đợt gọn | 1 đợt (màn 1), 2 đợt (màn 2–6), **3 đợt** (màn 7+, `room.gd:77`) | Màn 7+ tốn nhiều thời gian dọn phòng thường |
| **Rương & rơi hồ lô** | Thùng gỗ hiếm rơi máu; rương tách cấp | **100%** phòng combat rớt rương sơn mài: 58% xu/linh khí, **27% hồ lô**, 15% vũ khí (`loot_chest.gd`); lính thường thêm 4% rơi hồ lô (`enemy.gd:981`) | **Quá dễ hồi phục**, khó thiếu máu nếu đi đều các phòng |
| **Giá cửa hàng** | Bình máu lớn: 40–102 xu; Bình năng lượng lớn: 30–76 xu | Hồ lô lớn: `10 + int(level / 2)` (**10–25 xu**); Hồ lô linh khí: `7 + int(level / 2)` (**7–22 xu**, `shop_stand.gd:25`) | **Quá rẻ** so với lượng xu rơi mỗi màn |
| **Tăng máu quái/trùm** | Tăng theo tầng | Lính: `×(1 + 0,12 × depth)` (màn 30 tăng **×4,48**); Trùm: `300 → 1434 HP` (`enemies.gd`) | Chênh lệch lớn: thiếu phúc lành sát thương sẽ bắn mỏi tay, đủ combo (*Rượu thuốc* + *Mắt thần* + *Mũi tên đôi* + *Giày cỏ*) lại hạ quá nhanh |
| **Vật cản trong phòng** | Có nhiều cột/thùng gỗ/tường chắn giữa phòng | Phòng chiến đấu **hoàn toàn trống trơn** (chỉ có tường bao 4 phía và đồ trang trí sát mép, `dungeon.gd:280-325`) | **Thiếu chỗ ẩn nấp** để né đạn trùm và chờ hồi giáp |

### Tóm tắt chỗ quá dễ, quá khó và chỗ còn thiếu
1. **Chỗ đang quá dễ:**
   - Hồi phục máu quá dư dả (27% rương sơn mài cho hồ lô + 4% rơi từ lính + giá hồ lô ở gánh hàng rong chỉ 7–25 xu), làm mất đi áp lực giữ máu và lựa chọn ở Gánh hàng rong.
   - Bất tử `0.7s` sau mỗi lần trúng đòn kết hợp hồi giáp sau `3.5s` khiến người chơi ít bị trừng phạt khi đứng sai vị trí.
2. **Chỗ đang dễ gây mệt / khó không đều:**
   - Từ màn 7 trở đi, mỗi màn có tới 8–10 phòng và mỗi phòng đánh 3 đợt giặc trong một hành trình dài 30 màn dễ làm người chơi mỏi tay trước khi tới trùm cuối Điện Biên Phủ.
   - Phòng chiến đấu trống trơn ở giữa khiến một số chiêu đạn dày của trùm (như *Quách Quỳ*, *Tô Định*, *Đờ Cát*) không có vật cản để người chơi nấp nhịp hồi giáp, nhất là khi chọn tướng không có chiêu phòng thủ.
3. **Chỗ còn thiếu:**
   - Thiếu vật cản chiến thuật giữa phòng (vừa để nấp né đạn, vừa tăng không khí chiến trường Việt).
   - Thiếu phúc lành chống sát thương tràn giáp.
   - Gánh hàng rong mới thiết kế 3 kệ cho chơi đơn, chưa dự phòng mở rộng khi sang Co-op LAN.

---

## 5. Đề xuất tối đa 5 thay đổi (CHƯA sửa mã)

Mỗi đề xuất dưới đây đều thiết kế lại theo chất Việt của *Anh Hùng Đất Việt*; khi chủ dự án duyệt mới thực hiện (có thể ghép vào thẻ **G11** hoặc các thẻ **N3/N5/N7**).

### Đề xuất 1: Cân chỉnh nhịp phòng thủ & thêm phúc lành **"Hộ tâm kính"**
- **Nội dung:**
  - Tăng thời gian chờ hồi giáp `ARMOR_REGEN_DELAY` từ `3.5` giây lên `4.5` giây; giảm thời gian bất tử sau trúng đòn `_invuln` từ `0.7` giây xuống `0.45` giây.
  - Bù lại, thêm 1 phúc lành mới là **Hộ tâm kính** (*"Khi vỡ giáp, sát thương dư không tràn vào máu"*, `max: 1`) lấy cảm hứng từ tấm hộ tâm kính trên áo giáp cổ.
- **Lý do:** Giảm cảm giác "đứng giữa mưa đạn vẫn sống khỏe", khuyến khích di chuyển né đạn có chủ đích, đồng thời trao cho người chơi một lựa chọn phòng thủ rõ rệt khi gặp trùm cuối sát thương cao.
- **Tệp sẽ sửa:** `scripts/entities/player.gd`, `scripts/data/buffs.gd`, `tools/sprites/art_buffs.py`.

### Đề xuất 2: Làm gọn nhịp hầm ngục từ màn 5 trở đi
- **Nội dung:**
  - Giảm nhẹ số phòng mỗi màn từ `5 + mini(level, 5)` (6–10 phòng) xuống `5 + mini(int((level + 1) / 3), 3)` (**6–8 phòng/màn**).
  - Trong phòng chiến đấu (`combat`), giữ mức 2 đợt giặc từ màn 2 đến màn 20, chỉ bật 3 đợt ở chặng cuối (từ màn 21 trở đi — giai đoạn kháng chiến chống Pháp).
- **Lý do:** Giữ trọn đủ 10 chương (30 màn) lịch sử mà không khiến mỗi màn kéo quá dài, tập trung cao trào vào trận Tam Yêu (màn giữa chương) và Trùm cuối chương.
- **Tệp sẽ sửa:** `scripts/game/dungeon.gd`, `scripts/game/room.gd`.

### Đề xuất 3: Siết nhẹ kinh tế Gánh hàng rong và tỉ lệ hồ lô trong Rương sơn mài
- **Nội dung:**
  - Điều chỉnh giá ở `shop_stand.gd`: Hồ lô lớn (`potion_big`) lên `18 + level * 2` xu (20–78 xu); Hồ lô linh khí (`potion_energy`) lên `14 + int(level * 1.5)` xu (15–59 xu); Bùa phúc lành giữ mức tăng nhẹ `35 + level * 3`.
  - Giảm tỉ lệ rơi hồ lô từ Rương sơn mài trong `loot_chest.gd` từ **27%** (`0.58..0.85`) xuống **16%** (`0.68..0.84`), tăng phần rơi xu/linh khí lên **68%** (`< 0.68`) và giữ vũ khí **16%**.
- **Lý do:** Đưa kinh tế về gần đường cong giá trị của *Soul Knight*: người chơi phải cân nhắc tích xu để mua hồ lô hoặc bùa ở Gánh hàng rong thay vì lúc nào cũng dư máu và xu.
- **Tệp sẽ sửa:** `scripts/game/shop_stand.gd`, `scripts/entities/loot_chest.gd`.

### Đề xuất 4: Thêm vật cản che đạn thuần Việt giữa phòng chiến đấu
- **Nội dung:**
  - Trong mỗi phòng `combat` (và rìa phòng `boss`), sinh **2–4 cụm vật cản** vừa phải để không kẹt đường:
    - Chương cổ–trung đại (40–1789): **chum gốm** (vỡ khi trúng 3–4 phát đạn, rơi 1 xu hoặc 1 hạt linh khí) và **cụm cọc gỗ/bia đá** (che đạn bền vững).
    - Chương cận–hiện đại (1861–1954): **thùng đạn gỗ** (vỡ được) và **ụ bao cát** (che đạn bền vững).
- **Lý do:** Tạo điểm nấp chiến thuật giữa phòng để né loạt đạn dày và chờ 4,5 giây hồi giáp; đồng thời làm phong phú bối cảnh từng thời kỳ lịch sử.
- **Tệp sẽ sửa:** tạo mới `scripts/entities/cover.gd`; sửa `scripts/game/room.gd`, `scripts/entities/bullet.gd`, `tools/sprites/art_world.py`.

### Đề xuất 5: Tinh chỉnh thông số Co-op cho đợt 2 (thẻ N3, N5, N7)
- **Nội dung:**
  - **Thẻ N5 (`shop.gd`):** Khi chơi LAN có `n` người (`n >= 2`), Gánh hàng rong bày thêm kệ tre (`3 + (n - 1)` kệ, tối đa 6 kệ gồm 2 hồ lô + vũ khí/bùa) để cả nhóm cùng có đồ mua.
  - **Thẻ N7 (`player.gd`):** Thay vì gục 20 giây là chết hẳn, giữ cơ chế giống *Soul Knight*: người gục nằm chờ đồng đội tới cứu (không giới hạn thời gian, chỉ thua khi cả nhóm cùng gục), cứu xong dậy với **2 Máu, 0 Giáp** và **1,5 giây bất tử** để kịp rút lui.
  - **Thẻ N3 (`enemy.gd`):** Thử nghiệm hệ số máu giặc `×(1 + 0,5 × (n - 1))` (ví dụ 2 người là `+50%` như Co-op *Soul Knight*) trước khi chốt ở G11.
- **Lý do:** Thân thiện khi bạn bè chơi LAN cùng nhau (không ai bị ngồi xem suốt màn vì hết 20 giây), chia đồ công bằng ở Gánh hàng rong, và cân bằng tốc độ dọn phòng.
- **Tệp sẽ sửa (khi làm đợt 2):** `scripts/game/shop.gd`, `scripts/entities/player.gd`, `scripts/entities/enemy.gd`, `docs/GIAO-VIEC-GEMINI.md`.
