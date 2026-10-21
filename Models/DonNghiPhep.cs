using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

public class DonNghiPhep
{
    public int Id { get; set; }

    public int NhanVienId { get; set; }
    public NhanVien NhanVien { get; set; } = null!;

    public DateOnly TuNgay { get; set; }
    public DateOnly DenNgay { get; set; }

    [Required, MaxLength(500)]
    public string LyDo { get; set; } = string.Empty;

    [MaxLength(20)]
    public string TrangThai { get; set; } = TrangThaiDon.ChoDuyet;

    public DateTime NgayTao { get; set; } = DateTime.UtcNow.AddHours(7);

    public string? NguoiDuyetId { get; set; }
    public DateTime? NgayDuyet { get; set; }

    [MaxLength(300)]
    public string? GhiChuDuyet { get; set; }
}
