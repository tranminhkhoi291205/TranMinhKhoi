using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.DTOs;

public record PagedResult<T>(int Total, int Page, int PageSize, List<T> Items);

// ----- Phòng ban -----
public class PhongBanInput
{
    [Required, MaxLength(100)] public string Ten { get; set; } = string.Empty;
    [MaxLength(300)] public string? MoTa { get; set; }
}
public record PhongBanDto(int Id, string Ten, string? MoTa, int SoNhanVien);

// ----- Ca làm việc -----
public class CaLamViecInput
{
    [Required, MaxLength(100)] public string Ten { get; set; } = string.Empty;
    [Required] public TimeOnly GioBatDau { get; set; }
    [Required] public TimeOnly GioKetThuc { get; set; }
    [Range(0, 120)] public int PhutChoPhepTre { get; set; } = 10;
}
public record CaLamViecDto(int Id, string Ten, TimeOnly GioBatDau, TimeOnly GioKetThuc, int PhutChoPhepTre);

// ----- Vị trí chấm công -----
public class ViTriInput
{
    [Required, MaxLength(100)] public string Ten { get; set; } = string.Empty;
    [MaxLength(250)] public string? DiaChi { get; set; }
    [Range(-90, 90)] public double Latitude { get; set; }
    [Range(-180, 180)] public double Longitude { get; set; }
    [Range(10, 5000)] public int BanKinhMet { get; set; } = 100;
    public bool HoatDong { get; set; } = true;
}
public record ViTriDto(int Id, string Ten, string? DiaChi, double Latitude, double Longitude, int BanKinhMet, bool HoatDong);

// ----- Nhân viên -----
public class NhanVienInput
{
    [Required, MaxLength(20)] public string MaNV { get; set; } = string.Empty;
    [Required, MaxLength(100)] public string HoTen { get; set; } = string.Empty;
    public DateOnly? NgaySinh { get; set; }
    [MaxLength(10)] public string GioiTinh { get; set; } = "Nam";
    [Phone, MaxLength(20)] public string? SoDienThoai { get; set; }
    [EmailAddress, MaxLength(150)] public string? Email { get; set; }
    [MaxLength(250)] public string? DiaChi { get; set; }
    [MaxLength(100)] public string? ChucVu { get; set; }
    [Range(0, double.MaxValue)] public decimal LuongCoBan { get; set; }
    public DateOnly NgayVaoLam { get; set; }
    public bool DangLamViec { get; set; } = true;
    public int? PhongBanId { get; set; }
    public int? CaLamViecId { get; set; }
}

public class CapNhatHoSoRequest
{
    [Phone, MaxLength(20)] public string? SoDienThoai { get; set; }
    [MaxLength(250)] public string? DiaChi { get; set; }
}

public class DangKyKhuonMatRequest
{
    [Required, MinLength(32), MaxLength(2048)]
    public double[] KhuonMat { get; set; } = Array.Empty<double>();
}

public record NhanVienDto(
    int Id, string MaNV, string HoTen, DateOnly? NgaySinh, string GioiTinh,
    string? SoDienThoai, string? Email, string? DiaChi, string? ChucVu,
    decimal LuongCoBan, DateOnly NgayVaoLam, bool DangLamViec,
    int? PhongBanId, string? TenPhongBan, int? CaLamViecId, string? TenCaLamViec,
    string? UserId, bool CoKhuonMat);
