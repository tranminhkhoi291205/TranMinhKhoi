using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.DTOs;

public class ChamCongRequest
{
    /// <summary>GPS | QR | FACE</summary>
    [Required] public string PhuongThuc { get; set; } = "GPS";
    public double? ViDo { get; set; }
    public double? KinhDo { get; set; }
    /// <summary>Chuỗi đọc được từ mã QR (khi PhuongThuc = QR)</summary>
    public string? QrToken { get; set; }
    /// <summary>Vector đặc trưng khuôn mặt (khi PhuongThuc = FACE)</summary>
    public double[]? KhuonMat { get; set; }
    public string? DeviceId { get; set; }
    /// <summary>Ứng dụng báo thiết bị đang bật giả lập vị trí (mock location)</summary>
    public bool GiaLapViTri { get; set; }
}

public class ChamCongAdminInput
{
    [Required] public int NhanVienId { get; set; }
    [Required] public DateOnly Ngay { get; set; }
    public DateTime? GioVao { get; set; }
    public DateTime? GioRa { get; set; }
    [MaxLength(500)] public string? GhiChu { get; set; }
}

public record ChamCongDto(
    int Id, int NhanVienId, string MaNV, string HoTen, DateOnly Ngay,
    DateTime? GioVao, DateTime? GioRa, string? PhuongThucVao, string? PhuongThucRa,
    string TrangThai, int SoPhutTre, int SoPhutVeSom, double? SoGioLam,
    bool NghiNgo, string? GhiChu, string? TenViTri);

// ----- Nghỉ phép -----
public class DonNghiInput
{
    [Required] public DateOnly TuNgay { get; set; }
    [Required] public DateOnly DenNgay { get; set; }
    [Required, MaxLength(500)] public string LyDo { get; set; } = string.Empty;
}

public class DuyetDonRequest
{
    public bool DongY { get; set; }
    [MaxLength(300)] public string? GhiChu { get; set; }
}

public record DonNghiDto(
    int Id, int NhanVienId, string MaNV, string HoTen, DateOnly TuNgay, DateOnly DenNgay,
    string LyDo, string TrangThai, DateTime NgayTao, DateTime? NgayDuyet, string? GhiChuDuyet)
{
    public int SoNgay => DenNgay.DayNumber - TuNgay.DayNumber + 1;
}

// ----- Thống kê -----
public record ThongKeThangDto(
    string Thang, int NgayCongChuan, int NgayCong, int NgayNghiPhep, int NgayVang,
    int SoLanDiTre, int SoLanVeSom, int SoLanNghiNgo, double TongGioLam,
    int DiemChuyenCan, string XepLoai, int ChuoiDungGio);
