using Microsoft.AspNetCore.Identity;

namespace TranMinhKhoi.Models;

/// <summary>Tài khoản đăng nhập = IdentityUser + thông tin bổ sung.</summary>
public class AppUser : IdentityUser
{
    public string HoTen { get; set; } = string.Empty;
    public DateTime NgayTao { get; set; } = DateTime.UtcNow;
    public bool HoatDong { get; set; } = true;

    /// <summary>Thiết bị đã đăng ký (ràng buộc thiết bị - chống chấm công hộ).</summary>
    public string? DeviceId { get; set; }
}
