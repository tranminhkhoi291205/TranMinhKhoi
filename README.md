# TranMinhKhoi – Web API Chấm công nhân viên (ASP.NET Core 9 + SQL Server)

Project, namespace, WebAPI và cơ sở dữ liệu đều đặt theo tên cá nhân: **TranMinhKhoi**.

## 1. Chạy thử
1. Mở `TranMinhKhoi.sln` bằng Visual Studio 2022 (cần .NET 9 SDK, SQL Server/SQL Express).
2. Sửa `ConnectionStrings:DefaultConnection` trong `appsettings.json` cho đúng tên máy chủ SQL Server (database: `TranMinhKhoi`).
3. Nhấn F5 (profile `http`). Lần chạy đầu tự tạo database, vai trò, tài khoản và dữ liệu mẫu. Swagger mở tại `http://localhost:5145/swagger`.
4. Android emulator gọi API qua `http://10.0.2.2:5145/api/`. Điện thoại thật: dùng IP LAN của máy (ví dụ `http://192.168.1.x:5145/api/`) và mở cổng 5145 trên Windows Firewall.

### Dùng Migration (khuyến nghị khi nộp bài)
Trong Visual Studio mở **Tools > NuGet Package Manager > Package Manager Console**, chọn Default project là `TranMinhKhoi`, rồi chạy:
```
Add-Migration InitTranMinhKhoi
Update-Database
```
Hoặc bằng dòng lệnh: `dotnet tool install --global dotnet-ef`, sau đó `dotnet ef migrations add InitTranMinhKhoi` và `dotnet ef database update`.
Nếu database `TranMinhKhoi` đã được tạo từ lần chạy trước (chưa có Migration), hãy xóa database đó trong SSMS (hoặc `Drop-Database`) trước khi chạy `Update-Database`. Sau khi có thư mục `Migrations`, ứng dụng tự áp dụng Migration mỗi lần khởi động.

## 2. OTP qua email
- Môi trường Development (`appsettings.Development.json`): `Otp:ReturnOtpInResponse = true` → mã OTP nằm trong trường `devOtp` của phản hồi, đồng thời được in ra Console nếu chưa cấu hình SMTP. Dùng để test nhanh.
- Khi demo/nộp bài: đặt `ReturnOtpInResponse = false` và điền mục `Email` trong `appsettings.json` (Gmail: `smtp.gmail.com`, cổng 587, SSL, mật khẩu là **Mật khẩu ứng dụng** 16 ký tự bật từ tài khoản Google có xác minh 2 bước).

## 3. Tài khoản mẫu
| Vai trò | Tên đăng nhập | Mật khẩu |
|---|---|---|
| Admin | admin | Admin@123 |
| Quản lý | quanly01 | QuanLy@123 |
| Nhân viên | nhanvien01 | NhanVien@123 |

## 4. Luồng chính
**Đăng ký:** `POST /api/Auth/register` → nhận OTP email → `POST /api/Auth/verify-email`. Đăng ký công khai luôn là vai trò `NhanVien`; Admin đổi vai trò ở `PUT /api/TaiKhoan/{id}/role`.

**Đăng nhập 2 bước:** `POST /api/Auth/login` (tên đăng nhập + mật khẩu) → OTP email → `POST /api/Auth/verify-otp` → nhận `token`, `role`, `redirect` (`admin` | `quanly` | `nhanvien`) để app mở đúng màn hình. Sai mật khẩu 5 lần khóa 5 phút; OTP hết hạn sau 5 phút, tối đa 5 lần thử.

**Token JWT** chứa: `uid`, `sub`/`unique_name` (tên đăng nhập), `email`, `name` (họ tên), `role`, `exp`. Bên Flutter dùng `JwtDecoder.decode(token)['role']`.

## 5. Danh sách API
| Nhóm | Endpoint | Quyền |
|---|---|---|
| Auth | register, verify-email, resend-otp, login, verify-otp, me, change-password | công khai / đã đăng nhập |
| Tài khoản | GET/POST `/api/TaiKhoan`, PUT `{id}/role`, `{id}/khoa`, `{id}/reset-thiet-bi`, DELETE `{id}` | Admin |
| Phòng ban (CRUD) | `/api/PhongBan` | xem: mọi người; sửa: Admin, Quản lý |
| Ca làm việc (CRUD) | `/api/CaLamViec` | xem: mọi người; sửa: Admin, Quản lý |
| Vị trí chấm công (CRUD) | `/api/ViTriChamCong`, GET `{id}/qr`, PUT `{id}/doi-khoa-qr` | xem: mọi người; sửa/QR: Admin, Quản lý |
| Nhân viên (CRUD) | `/api/NhanVien`, `me`, `me/khuon-mat` | CRUD: Admin, Quản lý (xóa: Admin); `me`: mọi người |
| Chấm công | POST `check-in`, `check-out`; GET `hom-nay`, `cua-toi`; CRUD bảng công `/api/ChamCong` | nhân viên; sửa công: Admin, Quản lý |
| Nghỉ phép (CRUD) | `/api/DonNghiPhep`, `cua-toi`, PUT `{id}/duyet` | nhân viên tạo/sửa/hủy; duyệt: Admin, Quản lý |
| Thống kê | `tong-quan`, `bao-cao-thang`, `cua-toi` | Admin/Quản lý; `cua-toi`: mọi người |

Giờ trong `ca làm việc` nhập dạng `"08:00:00"`, ngày dạng `"2026-10-21"`.

## 6. Ba chức năng để thuyết trình (3/6)
1. **Chia sẻ vị trí (GPS geofence):** `check-in/check-out` với `phuongThuc = "GPS"`, server tính khoảng cách Haversine tới điểm chấm công gần nhất và so với bán kính cho phép.
2. **Quét QR:** Admin/Quản lý mở `GET /api/ViTriChamCong/{id}/qr` (đổi mỗi 60 giây) và hiển thị thành mã QR; nhân viên quét rồi gửi `phuongThuc = "QR"`, `qrToken`.
3. **Khuôn mặt:** nhân viên đăng ký vector khuôn mặt ở `POST /api/NhanVien/me/khuon-mat`; khi chấm công gửi `phuongThuc = "FACE"`, `khuonMat` (+ toạ độ GPS). Server so khớp cosine với ngưỡng `Face:Threshold`. Vector được tạo ở phía app (ML Kit/TFLite).

## 7. Tính năng mới tự đề xuất
**Chấm công chống gian lận + Điểm chuyên cần:**
- Ràng buộc thiết bị: lần đăng nhập đầu lưu `deviceId`; chấm công từ máy khác bị đánh dấu *nghi vấn* cho quản lý xem (`GET /api/ChamCong?nghiNgo=true`); Admin gỡ ràng buộc khi nhân viên đổi máy.
- Chặn vị trí giả lập: app gửi `giaLapViTri = true` thì server từ chối.
- QR động đổi mỗi 60 giây nên không chụp màn hình gửi người khác để chấm công hộ được.
- Điểm chuyên cần 0–100 = `100 − 3×đi trễ − 2×về sớm − 10×vắng không phép − 5×bản ghi nghi vấn`, kèm xếp loại, chuỗi ngày đúng giờ và bảng xếp hạng trong công ty (`/api/ThongKe/cua-toi`, `/api/ThongKe/bao-cao-thang`).

## 8. Ghi chú nghiệp vụ
- Giờ lưu theo giờ Việt Nam (UTC+7). Ngày công chuẩn là Thứ 2–Thứ 6.
- Đi trễ khi vào sau giờ bắt đầu ca + số phút cho phép; về sớm khi ra trước giờ kết thúc ca.
- Hồ sơ nhân viên được liên kết với tài khoản qua **email trùng nhau** (khi tài khoản xác thực email hoặc khi tạo hồ sơ).
