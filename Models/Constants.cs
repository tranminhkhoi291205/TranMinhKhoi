namespace TranMinhKhoi.Models;

public static class AppRoles
{
    public const string Admin = "Admin";
    public const string QuanLy = "QuanLy";
    public const string NhanVien = "NhanVien";
    public const string AdminQuanLy = Admin + "," + QuanLy;
    public static readonly string[] TatCa = { Admin, QuanLy, NhanVien };
}

public static class PhuongThucChamCong
{
    public const string GPS = "GPS";
    public const string QR = "QR";
    public const string FACE = "FACE";
}

public static class TrangThaiDon
{
    public const string ChoDuyet = "ChoDuyet";
    public const string DaDuyet = "DaDuyet";
    public const string TuChoi = "TuChoi";
}

public static class MucDichOtp
{
    public const string DangKy = "DangKy";
    public const string DangNhap = "DangNhap";
}
