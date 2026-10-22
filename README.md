# TranMinhKhoi – Web API Chấm công nhân viên (ASP.NET Core 9 + SQL Server)

Dự án Hệ thống Quản trị & Chấm công Doanh nghiệp Đa nền tảng (Web API + Mobile Flutter).  
Sinh viên thực hiện: **Trần Minh Khôi** - MSSV: **2380601106** - Lớp: **23DTHC3** - HUTECH.  
- **Repository Frontend (Mobile App Flutter):** [https://github.com/kihoo2905/appCC-flutter.git](https://github.com/kihoo2905/appCC-flutter.git)

---

## 1. Danh Sách API Trực Tiếp & Kênh Dự Phòng

Hệ thống Web API được thiết kế hỗ trợ đa kênh truy cập giúp việc chấm bài và chạy ứng dụng luôn thông suốt:

| Kênh kết nối | Mục đích | Swagger Documentation | Base URL API |
|---|---|---|---|
| **Conveyor Cloud (Internet)** | Chấm bài từ xa qua internet / mạng 4G | [https://lostgoldroof80.conveyor.cloud/swagger/](https://lostgoldroof80.conveyor.cloud/swagger/) | `https://lostgoldroof80.conveyor.cloud/api/` |
| **Wi-Fi LAN (Dự phòng khuyên dùng khi Demo)** | Kết nối trực tiếp giữa điện thoại & laptop cùng Wi-Fi | `http://192.168.1.3:5145/swagger/` | `http://192.168.1.3:5145/api/` |
| **Android Emulator (Giả lập)** | Chạy máy ảo Android Studio trên cùng máy tính | `http://10.0.2.2:5145/swagger/` | `http://10.0.2.2:5145/api/` |
| **Localhost** | Chạy cục bộ trên máy tính phát triển | `http://localhost:5145/swagger/` | `http://localhost:5145/api/` |

### Chạy cục bộ bằng Visual Studio (Dành cho nhà phát triển):
1. Mở `TranMinhKhoi.sln` bằng Visual Studio 2022 (cần .NET 9 SDK, SQL Server/SQL Express).
2. Sửa `ConnectionStrings:DefaultConnection` trong `appsettings.json` cho đúng tên máy chủ SQL Server (database: `TranMinhKhoi`).
3. Nhấn `Ctrl + F5` (Start Without Debugging) để backend chạy ngầm mượt mà.

### Dùng Migration
Trong Visual Studio mở **Tools > NuGet Package Manager > Package Manager Console**, chọn Default project là `TranMinhKhoi`, rồi chạy:
```powershell
Add-Migration InitTranMinhKhoi
Update-Database
```
Hoặc bằng dòng lệnh: `dotnet tool install --global dotnet-ef`, sau đó `dotnet ef migrations add InitTranMinhKhoi` và `dotnet ef database update`.

---

## 2. OTP qua email
- Môi trường Development (`appsettings.Development.json`): `Otp:ReturnOtpInResponse = true` → mã OTP nằm trong trường `devOtp` của phản hồi, đồng thời được in ra Console nếu chưa cấu hình SMTP. Dùng để test nhanh.
- Khi demo/nộp bài: điền mục `Email` trong `appsettings.json` (Gmail: `smtp.gmail.com`, cổng 587, SSL, mật khẩu là **Mật khẩu ứng dụng** 16 ký tự từ tài khoản Google).

---

## 3. Tài khoản mẫu đăng nhập
| Vai trò | Tên đăng nhập | Mật khẩu | Chuyển hướng màn hình |
|---|---|---|---|
| **Admin** | `admin` | `Admin@123` | Trang Quản trị Doanh nghiệp & Cấu hình |
| **Quản lý** | `quanly01` | `QuanLy@123` | Quản trị Phòng ban, Duyệt đơn |
| **Nhân viên** | `nhanvien01` | `NhanVien@123` | Dashboard Chấm công Cá nhân & Bảng lương |
| **Khách hàng** | `khachhang01` | `KhachHang@123` | Trang Thẻ Khách & Đối tác |

---

## 4. Luồng phân quyền và bảo mật
- **Đăng ký:** `POST /api/Auth/register` → nhận OTP qua Email → `POST /api/Auth/verify-email` kích hoạt tài khoản.
- **Đăng nhập 2 bước:** `POST /api/Auth/login` (username + password) → gửi mã OTP xác thực → `POST /api/Auth/verify-otp` xác nhận mã OTP → Trả về JWT Token và quyền tương ứng (`admin`, `quanly`, `nhanvien`, `khachhang`).
- **Token JWT** chứa đầy đủ Claims: `uid`, `role`, `email`, `name`.

---

## 5. Danh sách API CRUD (5.5đ)
- **Tài khoản:** `GET /api/TaiKhoan`, `PUT {id}/role`, `PUT {id}/khoa`, `DELETE {id}`
- **Phòng ban:** Đầy đủ CRUD `GET /api/PhongBan`, `POST`, `PUT {id}`, `DELETE {id}`
- **Ca làm việc:** Đầy đủ CRUD `GET /api/CaLamViec`, `POST`, `PUT {id}`, `DELETE {id}`
- **Vị trí chấm công:** Đầy đủ CRUD `GET /api/ViTriChamCong`, `POST`, `PUT {id}`, `DELETE {id}`, `GET {id}/qr`
- **Nhân viên:** Đầy đủ CRUD `GET /api/NhanVien`, `POST`, `PUT {id}`, `DELETE {id}`
- **Chấm công:** `POST /api/ChamCong/check-in`, `POST /api/ChamCong/check-out`, `GET /api/ChamCong/cua-toi`
- **Đơn nghỉ phép:** CRUD đơn xin nghỉ và duyệt đơn

---

## 6. Ba công nghệ chọn thuyết trình (3.5đ)
1. **Chia sẻ vị trí GPS (Geofence):** Sử dụng thuật toán Haversine đo bán kính so với tọa độ công ty để xác định hợp lệ khi Check-in / Check-out.
2. **Quét mã QR Code động:** Mã QR Token mã hóa HMAC thay đổi tự động mỗi 60 giây, chống gian lận chụp ảnh gửi chấm công hộ.
3. **Cảm biến Gia tốc (Accelerometer):** Thu thập dữ liệu dao động $X, Y, Z$, đếm bước chân thời gian thực và phát hiện Fake GPS / Mock Location khi nhân viên đứng yên.

---

## 7. Tính năng mới tự đề xuất (1.0đ)
**Bảng Lương Dự Kiến & KPI Thông Minh (Smart Payroll & Attendance Estimation):**
- Tự động liên kết dữ liệu chấm công thực tế để tính toán lương thực nhận theo ngày và theo ca.
- Minh bạch tài chính: Chi tiết khấu trừ đi trễ từng phút, tiền thưởng chuyên cần đúng giờ liên tục, phụ cấp ca làm việc.
- Dự báo thu nhập cuối tháng theo tiến độ công chuẩn.
