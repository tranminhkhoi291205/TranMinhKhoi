using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

public class NhanVien
{
    public int Id { get; set; }

    [Required, MaxLength(20)]
    public string MaNV { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string HoTen { get; set; } = string.Empty;

    public DateOnly? NgaySinh { get; set; }

    [MaxLength(10)]
    public string GioiTinh { get; set; } = "Nam";

    [MaxLength(20)]
    public string? SoDienThoai { get; set; }

    [MaxLength(150)]
    public string? Email { get; set; }

    [MaxLength(250)]
    public string? DiaChi { get; set; }

    [MaxLength(100)]
    public string? ChucVu { get; set; }

    public decimal LuongCoBan { get; set; }
    public DateOnly NgayVaoLam { get; set; }
    public bool DangLamViec { get; set; } = true;

    public int? PhongBanId { get; set; }
    public PhongBan? PhongBan { get; set; }

    public int? CaLamViecId { get; set; }
    public CaLamViec? CaLamViec { get; set; }

    /// <summary>Tài khoản đăng nhập gắn với nhân viên này.</summary>
    public string? UserId { get; set; }
    public AppUser? User { get; set; }

    /// <summary>Vector đặc trưng khuôn mặt (JSON double[]) dùng cho chấm công bằng khuôn mặt.</summary>
    public string? FaceTemplate { get; set; }
}
