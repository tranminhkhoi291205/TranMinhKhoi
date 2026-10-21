# Ứng Dụng Chấm Công Nhân Viên (Mobile App Flutter)

Họ tên sinh viên: **Trần Minh Khôi**  
MSSV: **2380601106**  
Lớp: **23DTHC3 - CNTT - HUTECH**  

---

## 1. Đầu API Chính Thức
- **Conveyor Cloud Public URL**: `https://goodyellowbox76.conveyor.cloud/api/`
- **Swagger Documentation**: `https://goodyellowbox76.conveyor.cloud/swagger`

Ứng dụng Flutter đã được cấu hình mặc định kết nối tới API Conveyor Cloud này qua file `.env`:
```env
BASE_URL=https://goodyellowbox76.conveyor.cloud/api/
```

Ngoài ra, tại màn hình Đăng nhập (icon bánh răng cài đặt ở góc trên bên phải), người dùng có thể đổi nhanh giữa:
- **Conveyor Cloud**: `https://goodyellowbox76.conveyor.cloud/api/` (Chạy được từ mọi nơi, 4G, Wi-Fi khác mạng)
- **Emulator**: `http://10.0.2.2:5145/api/`
- **Wi-Fi LAN**: `http://192.168.1.3:5145/api/`
- **Localhost**: `http://localhost:5145/api/`

---

## 2. Tài khoản mẫu đăng nhập
- **Admin**: `admin` / `Admin@123`
- **Quản lý**: `quanly01` / `QuanLy@123`
- **Nhân viên**: `nhanvien01` / `NhanVien@123`
- **Khách hàng**: `khachhang01` / `KhachHang@123`
*(Tại màn hình Đăng nhập có các nút bấm 1 chạm để điền nhanh các tài khoản này)*

---

## 3. Cách chạy ứng dụng Flutter
1. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```
2. Chạy ứng dụng trên thiết bị Android / Emulator / Windows:
   ```bash
   flutter run
   ```
