# SETUP (Salon Booking App)

## 1) Chạy dự án
### Yêu cầu
- Flutter SDK (stable)
- Android Studio + Android SDK + Emulator (hoặc điện thoại thật)

### Chạy
```bash
flutter pub get
flutter run
```

> Lưu ý: Project này hiện **chỉ cấu hình Firebase cho Android**. Nếu chạy Web/Windows sẽ báo màn hình hướng dẫn.

---

## 2) Firebase (Android)
### Bắt buộc
1. Tạo project trên Firebase Console
2. Thêm Android app:
   - Android package name: xem `android/app/build.gradle` (applicationId)
3. Tải `google-services.json` và đặt vào:
   - `android/app/google-services.json`
4. Bật Authentication:
   - Email/Password
   - Google (nếu dùng đăng nhập Google)

### Firestore Rules (gợi ý đơn giản cho demo)
> Khi làm thật bạn nên siết rule theo userId.
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## 3) Seed dữ liệu Firestore (phần hay bị thiếu)
App cần 2 collection:

### (A) `services`
Mỗi document nên có:
- `name` (string)

Ví dụ tạo 3 dịch vụ:
- services/001: { "name": "Cắt tóc" }
- services/002: { "name": "Gội đầu" }
- services/003: { "name": "Nhuộm tóc" }

### (B) `workers`
Tối thiểu có:
- `booked`: array (list) — chứa các bookingKey đã đặt

Ví dụ:
- workers/G9ZvAbTR9HvoiMChKrTA: { "booked": [] }

> Nếu bạn muốn đổi workerId: sửa biến `workerId` trong `lib/screens/booking/booking_screen.dart`.

### (C) `bookings`
App sẽ tự tạo record trong `bookings` khi bấm "Xác nhận đặt lịch".

---

## 4) Google Maps API Key (nếu màn hình Maps không hiện)
File: `android/app/src/main/AndroidManifest.xml`

Bạn sẽ thấy:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
    android:value="API_KEY"/>
```

Hãy thay `API_KEY` bằng key thật (Google Cloud Console -> Maps SDK for Android).

---

## 5) Lỗi thường gặp
- **Undefined class `BottomNavigationComponent`**: đã fix trong `lib/components/bottom_navigationbar.dart`.
- **AuthController không tồn tại**: đã fix trong `lib/controller/auth_controller.dart`.
- **Đặt lịch không lưu**: thường do bạn chưa tạo `workers/{workerId}` hoặc `services`.
