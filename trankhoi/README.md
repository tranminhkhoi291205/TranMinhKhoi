# Ứng Dụng Chấm Công Nhân Viên (Mobile App Flutter)

Họ tên sinh viên: **Trần Minh Khôi**  
MSSV: **2380601106**  
Lớp: **23DTHC3 - CNTT - HUTECH**  

---

## 1. Đầu API Chính Thức & Chạy Thử
- **Conveyor Cloud Public URL**: `https://largetealbike39.conveyor.cloud/api/`
- **Swagger Documentation**: [https://largetealbike39.conveyor.cloud/swagger/](https://largetealbike39.conveyor.cloud/swagger/)

> **Lưu ý quan trọng:** Ứng dụng chạy thử nghiệm và chấm điểm bằng đường dẫn **Conveyor Cloud** để đảm bảo kết nối mượt mà từ mọi mạng internet (4G / Wi-Fi trường học / Wi-Fi gia đình), không cần chạy localhost.

Ứng dụng Flutter đã được cấu hình mặc định kết nối tới API Conveyor Cloud này qua file `.env` và cơ chế fallback tự động:
```env
BASE_URL=https://largetealbike39.conveyor.cloud/api/
```

Ngoài ra, tại màn hình Đăng nhập (nút icon cài đặt bánh răng ở góc trên bên phải), người dùng có thể đổi nhanh giữa:
- **Conveyor Cloud (Chính)**: `https://largetealbike39.conveyor.cloud/api/`
- **Emulator**: `http://10.0.2.2:5145/api/`
- **Wi-Fi LAN**: `http://192.168.1.3:5145/api/`
- **Localhost**: `http://localhost:5145/api/`

---

## 2. Tài khoản mẫu đăng nhập
- **Admin**: `admin` / `Admin@123` *(Chuyển hướng vào Trang Quản trị Doanh nghiệp)*
- **Quản lý**: `quanly01` / `QuanLy@123` *(Quản lý ca, duyệt phép)*
- **Nhân viên**: `nhanvien01` / `NhanVien@123` *(Vào Dashboard Chấm công cá nhân & Bảng lương dự kiến)*
- **Khách hàng**: `khachhang01` / `KhachHang@123` *(Vào Trang Thẻ khách / Đối tác)*

*(Tại màn hình Đăng nhập có các nút 1 chạm để điền nhanh các tài khoản trên)*

---

## 3. Cách chạy ứng dụng Flutter
1. Cài đặt thư viện:
   ```bash
   flutter pub get
   ```
2. Chạy ứng dụng trên thiết bị Android / Emulator / Windows:
   ```bash
   flutter run
   ```
