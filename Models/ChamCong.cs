using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

public class ChamCong
{
    public int Id { get; set; }

    public int NhanVienId { get; set; }
    public NhanVien NhanVien { get; set; } = null!;

    public DateOnly Ngay { get; set; }

    // Giờ lưu theo giờ Việt Nam (UTC+7)
    public DateTime? GioVao { get; set; }
    public DateTime? GioRa { get; set; }

    [MaxLength(10)] public string? PhuongThucVao { get; set; }
    [MaxLength(10)] public string? PhuongThucRa { get; set; }

    public double? ViDoVao { get; set; }
    public double? KinhDoVao { get; set; }
    public double? ViDoRa { get; set; }
    public double? KinhDoRa { get; set; }

    public int? ViTriChamCongId { get; set; }
    public ViTriChamCong? ViTriChamCong { get; set; }

    [MaxLength(100)] public string? DeviceId { get; set; }

    /// <summary>Đúng giờ / đi trễ / về sớm / vắng...</summary>
    [MaxLength(20)] public string TrangThai { get; set; } = "DungGio";

    public int SoPhutTre { get; set; }
    public int SoPhutVeSom { get; set; }
    public double? SoGioLam { get; set; }

    /// <summary>Bản ghi nghi vấn (thiết bị lạ...). Quản lý cần kiểm tra.</summary>
    public bool NghiNgo { get; set; }

    [MaxLength(500)] public string? GhiChu { get; set; }
}
