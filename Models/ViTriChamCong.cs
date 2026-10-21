using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

/// <summary>Điểm chấm công (văn phòng/chi nhánh) có hàng rào địa lý (geofence) và mã QR động.</summary>
public class ViTriChamCong
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Ten { get; set; } = string.Empty;

    [MaxLength(250)]
    public string? DiaChi { get; set; }

    public double Latitude { get; set; }
    public double Longitude { get; set; }

    /// <summary>Bán kính cho phép chấm công (mét).</summary>
    public int BanKinhMet { get; set; } = 100;

    /// <summary>Khóa bí mật để sinh mã QR động (không trả ra ngoài API).</summary>
    [MaxLength(100)]
    public string QrSecret { get; set; } = string.Empty;

    public bool HoatDong { get; set; } = true;
}
