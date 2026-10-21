using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.DTOs;

public class DangKyRequest
{
    [Required, StringLength(50, MinimumLength = 3)]
    [RegularExpression(@"^[A-Za-z0-9._-]+$", ErrorMessage = "Tên đăng nhập chỉ gồm chữ không dấu, số và các ký tự . _ -")]
    public string Username { get; set; } = string.Empty;

    [Required, EmailAddress, MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string HoTen { get; set; } = string.Empty;

    [Phone, MaxLength(20)]
    public string? SoDienThoai { get; set; }
}

public class XacThucEmailRequest
{
    [Required] public string Username { get; set; } = string.Empty;
    [Required, StringLength(6, MinimumLength = 6)] public string Otp { get; set; } = string.Empty;
}

public class GuiLaiOtpRequest
{
    [Required] public string Username { get; set; } = string.Empty;
    /// <summary>"DangKy" hoặc "DangNhap"</summary>
    [Required] public string MucDich { get; set; } = "DangNhap";
}

public class DangNhapRequest
{
    [Required] public string Username { get; set; } = string.Empty;
    [Required] public string Password { get; set; } = string.Empty;
}

public class XacThucOtpRequest
{
    [Required] public string Username { get; set; } = string.Empty;
    [Required, StringLength(6, MinimumLength = 6)] public string Otp { get; set; } = string.Empty;
    /// <summary>Mã thiết bị (Android ID...) để ràng buộc thiết bị lần đăng nhập đầu.</summary>
    public string? DeviceId { get; set; }
}

public class DoiMatKhauRequest
{
    [Required] public string MatKhauCu { get; set; } = string.Empty;
    [Required, MinLength(6)] public string MatKhauMoi { get; set; } = string.Empty;
}

// ----- Quản lý tài khoản (Admin) -----
public class TaoTaiKhoanRequest
{
    [Required, StringLength(50, MinimumLength = 3)]
    [RegularExpression(@"^[A-Za-z0-9._-]+$")]
    public string Username { get; set; } = string.Empty;
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required, MinLength(6)] public string Password { get; set; } = string.Empty;
    [Required, MaxLength(100)] public string HoTen { get; set; } = string.Empty;
    [Required] public string Role { get; set; } = "NhanVien";
}

public class DoiVaiTroRequest
{
    [Required] public string Role { get; set; } = string.Empty;
}

public class KhoaTaiKhoanRequest
{
    public bool HoatDong { get; set; }
}
