# ⏰ iOS Alarm Tester (Sideload Tool)

Ứng dụng kiểm thử đồng hồ báo thức dành cho iOS, được tối ưu hoá đặc biệt để cài đặt qua **Sideloading** (Sideloadly, AltStore, SideStore, TrollStore) mà không cần tài khoản Apple Developer trả phí.

---

## 🌟 Tính Năng Kiểm Thử (Test Features)

1. **Bypass chế độ Im Lặng (Silent Mode / Mute Switch)**:
   - Sử dụng `AVAudioSession` với danh mục `.playback`.
   - Chuông vẫn reo to hết cỡ ngay cả khi bạn gạt cần gạt rung/im lặng sang màu cam hoặc bật chế độ Focus / Không làm phiền.
2. **Cơ chế Duy trì chạy ngầm (Silent Audio Keep-Alive)**:
   - Phát luồng âm thanh tĩnh nhẹ trong nền để ngăn iOS tự động "đóng băng" (suspend) hoặc "kill" ứng dụng khi bạn tắt màn hình.
3. **Cơ chế Phục hồi dự phòng (Local Notifications)**:
   - Tự động lên lịch thông báo hệ thống đi kèm âm thanh chuông lớn (`alarm.wav`). Kể cả khi người dùng vuốt tắt app khỏi đa nhiệm, thông báo iOS vẫn reo đúng giờ.
4. **Bộ nút Test nhanh (Quick Presets)**:
   - Hẹn giờ test tức thì: **5 giây**, **15 giây**, **30 giây**, **1 phút** để bạn dễ dàng khoá màn hình và quan sát phản hồi của máy.
5. **Bảng Log chẩn đoán thời gian thực (Live Diagnostics Console)**:
   - Hiển thị chính xác thời điểm app chuyển trạng thái (`ACTIVE` ➔ `BACKGROUND` ➔ `INACTIVE`).
   - Đếm nhịp tim ngầm (Heartbeat counter) mỗi vài giây để chứng minh app vẫn đang sống và xử lý mã lệnh trong nền.
   - Nút 1-click để Copy toàn bộ log gửi phân tích.

---

## 🚀 Hướng Dẫn Tự Động Build File `.ipa` (Miễn phí qua GitHub Actions)

Vì bạn đang sử dụng hệ điều hành **Windows**, bạn không cần cài máy Mac ảo hay Xcode. GitHub sẽ build file `.ipa` giúp bạn hoàn toàn miễn phí:

### Bước 1: Đẩy mã nguồn lên GitHub cá nhân
1. Đăng nhập vào [GitHub.com](https://github.com) và tạo một repository mới (ví dụ: `ios-alarm-test`), để chế độ **Private** hoặc **Public**.
2. Mở terminal tại thư mục này và chạy các lệnh:
   ```bash
   git init
   git add .
   git commit -m "Initial commit for iOS Alarm Tester"
   git branch -M main
   git remote add origin https://github.com/TÊN_GITHUB_CỦA_BẠN/ios-alarm-test.git
   git push -u origin main
   ```

### Bước 2: Tải file `.ipa` đã build
1. Vào mục **Actions** trên GitHub repository của bạn.
2. Bạn sẽ thấy luồng công việc **Build iOS IPA** đang chạy tự động (khoảng 2-3 phút).
3. Khi hoàn tất (dấu tích xanh), bấm vào bản build đó.
4. Kéo xuống phần **Artifacts** và tải về tệp **`AlarmTestApp-IPA.zip`**.
5. Giải nén file zip ra, bạn sẽ nhận được file **`AlarmTestApp.ipa`**.

---

## 📲 Hướng Dẫn Cài Đặt Lên iPhone (Sideloading từ Windows)

### Cách 1: Dùng Sideloadly (Khuyên dùng - Cực nhanh & dễ nhất trên Windows)
1. Tải và cài đặt [Sideloadly cho Windows](https://sideloadly.io/) (Cài thêm iTunes và iCloud bản cài từ trang chủ Apple nếu Sideloadly yêu cầu).
2. Kết nối iPhone với máy tính bằng dây cáp (chọn **Tin cậy máy tính này** trên iPhone).
3. Mở Sideloadly:
   - Kéo file `AlarmTestApp.ipa` thả vào ô IPA.
   - Nhập tài khoản **Apple ID** cá nhân của bạn (miễn phí).
   - Bấm **Start**.
4. Chờ 1-2 phút thông báo "Done!".
5. Trên iPhone:
   - Vào **Cài đặt (Settings)** ➔ **Cài đặt chung (General)** ➔ **Quản lý VPN & Thiết bị (VPN & Device Management)**.
   - Bấm vào Apple ID của bạn và chọn **Tin cậy (Trust)**.
   - *(Nếu dùng iOS 16 trở lên)*: Vào **Cài đặt** ➔ **Quyền riêng tư & Bảo mật** ➔ Kéo xuống dưới cùng bật **Chế độ nhà phát triển (Developer Mode)** và khởi động lại máy theo hướng dẫn.

### Cách 2: Dùng TrollStore (Nếu iPhone của bạn đang chạy TrollStore)
- Chỉ cần gửi file `.ipa` qua AirDrop hoặc tải trực tiếp về máy, mở bằng TrollStore và bấm **Install** (không bị giới hạn 7 ngày, vĩnh viễn không bị thu hồi).

---

## 🧪 Các Bài Test Bạn Nên Thử:

- **Bài test 1: Khoá màn hình (Lock Screen Test)**
  - Mở app ➔ Bấm nút **15 Giây** ➔ Ngay lập tức bấm nút nguồn khoá màn hình iPhone.
  - Quan sát: Sau 15 giây, chuông báo thức có reo to và màn hình có sáng lên không.
- **Bài test 2: Gạt cần gạt im lặng (Mute Switch Test)**
  - Gạt iPhone sang chế độ im lặng (viền cam) hoặc bật Không làm phiền (Focus).
  - Bấm nút **Bật thử chuông báo ngay** ở góc trên hoặc trong mục Cài đặt.
  - Quan sát: Chuông vẫn phải phát âm thanh to rõ qua loa ngoài.
- **Bài test 3: Chuyển sang đa nhiệm (App Switcher Test)**
  - Bấm nút **30 Giây** ➔ Vuốt ra màn hình chính, mở app YouTube hoặc lướt web.
  - Quan sát: Đến giây thứ 30 thông báo và chuông báo thức xuất hiện.
