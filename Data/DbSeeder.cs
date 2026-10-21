using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider sp)
    {
        var db = sp.GetRequiredService<ApplicationDbContext>();
        var um = sp.GetRequiredService<UserManager<AppUser>>();
        var rm = sp.GetRequiredService<RoleManager<IdentityRole>>();
        var cfg = sp.GetRequiredService<IConfiguration>();

        // Nếu project đã có Migration (thư mục Migrations) thì áp dụng Migration;
        // nếu chưa có thì tự tạo database bằng EnsureCreated để chạy thử ngay.
        if (db.Database.GetMigrations().Any())
            await db.Database.MigrateAsync();
        else
            await db.Database.EnsureCreatedAsync();

        // Vai trò
        foreach (var role in AppRoles.TatCa)
            if (!await rm.RoleExistsAsync(role))
                await rm.CreateAsync(new IdentityRole(role));

        // Tài khoản
        await TaoTaiKhoanAsync(um, cfg["Seed:AdminUsername"] ?? "admin", cfg["Seed:AdminEmail"] ?? "admin@trankhoi.local",
            cfg["Seed:AdminPassword"] ?? "Admin@123", "Trần Minh Khôi (Quản trị)", AppRoles.Admin);
        var ql = await TaoTaiKhoanAsync(um, "quanly01", "quanly01@trankhoi.local", "QuanLy@123", "Nguyễn Văn Quản Lý", AppRoles.QuanLy);
        var nvUser = await TaoTaiKhoanAsync(um, "nhanvien01", "nhanvien01@trankhoi.local", "NhanVien@123", "Lê Thị Nhân Viên", AppRoles.NhanVien);

        // Dữ liệu mẫu
        if (!await db.PhongBans.AnyAsync())
        {
            db.PhongBans.AddRange(
                new PhongBan { Ten = "Kỹ thuật", MoTa = "Phát triển phần mềm và hạ tầng" },
                new PhongBan { Ten = "Nhân sự", MoTa = "Tuyển dụng, đào tạo, chính sách" },
                new PhongBan { Ten = "Kinh doanh", MoTa = "Bán hàng và chăm sóc khách hàng" });
        }

        if (!await db.CaLamViecs.AnyAsync())
        {
            db.CaLamViecs.AddRange(
                new CaLamViec { Ten = "Ca hành chính", GioBatDau = new TimeOnly(8, 0), GioKetThuc = new TimeOnly(17, 0), PhutChoPhepTre = 10 },
                new CaLamViec { Ten = "Ca chiều", GioBatDau = new TimeOnly(13, 0), GioKetThuc = new TimeOnly(21, 0), PhutChoPhepTre = 10 });
        }

        if (!await db.ViTriChamCongs.AnyAsync())
        {
            // Toạ độ gần khu vực HUTECH - hãy sửa lại đúng nơi bạn demo (qua API ViTriChamCong)
            db.ViTriChamCongs.Add(new ViTriChamCong
            {
                Ten = "Văn phòng chính",
                DiaChi = "475A Điện Biên Phủ, P.25, Q.Bình Thạnh, TP.HCM",
                Latitude = 10.8018,
                Longitude = 106.7143,
                BanKinhMet = 150,
                QrSecret = Convert.ToHexString(RandomNumberGenerator.GetBytes(24)),
                HoatDong = true
            });
        }
        await db.SaveChangesAsync();

        if (!await db.NhanViens.AnyAsync())
        {
            var pbKyThuat = await db.PhongBans.OrderBy(p => p.Id).FirstAsync();
            var ca = await db.CaLamViecs.OrderBy(c => c.Id).FirstAsync();

            db.NhanViens.AddRange(
                new NhanVien
                {
                    MaNV = "NV001", HoTen = "Lê Thị Nhân Viên", GioiTinh = "Nữ", Email = nvUser?.Email,
                    SoDienThoai = "0901234567", ChucVu = "Lập trình viên", LuongCoBan = 12000000,
                    NgayVaoLam = new DateOnly(2025, 1, 6), PhongBanId = pbKyThuat.Id, CaLamViecId = ca.Id,
                    UserId = nvUser?.Id
                },
                new NhanVien
                {
                    MaNV = "NV002", HoTen = "Nguyễn Văn Quản Lý", GioiTinh = "Nam", Email = ql?.Email,
                    SoDienThoai = "0907654321", ChucVu = "Trưởng nhóm", LuongCoBan = 20000000,
                    NgayVaoLam = new DateOnly(2024, 3, 1), PhongBanId = pbKyThuat.Id, CaLamViecId = ca.Id,
                    UserId = ql?.Id
                });
            await db.SaveChangesAsync();
        }
    }

    private static async Task<AppUser?> TaoTaiKhoanAsync(UserManager<AppUser> um, string username, string email,
        string password, string hoTen, string role)
    {
        var u = await um.FindByNameAsync(username);
        if (u != null) return u;

        u = new AppUser { UserName = username, Email = email, EmailConfirmed = true, HoTen = hoTen };
        var r = await um.CreateAsync(u, password);
        if (!r.Succeeded) return null;
        await um.AddToRoleAsync(u, role);
        return u;
    }
}
