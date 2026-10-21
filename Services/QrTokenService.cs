using System.Security.Cryptography;
using System.Text;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Services;

/// <summary>
/// Mã QR động: token = {idViTri}.{cửaSổThờiGian}.{chữKý}. Đổi mỗi 60 giây nên chụp màn hình
/// gửi cho người khác chấm công hộ sẽ không dùng được.
/// </summary>
public class QrTokenService
{
    public const int CuaSoGiay = 60;

    private static long CuaSoHienTai() => DateTimeOffset.UtcNow.ToUnixTimeSeconds() / CuaSoGiay;

    public static int GiayConLai() => CuaSoGiay - (int)(DateTimeOffset.UtcNow.ToUnixTimeSeconds() % CuaSoGiay);

    public string Tao(ViTriChamCong vt)
    {
        var w = CuaSoHienTai();
        return $"{vt.Id}.{w}.{Ky(vt, w)}";
    }

    public bool Kiem(string token, IEnumerable<ViTriChamCong> viTris, out ViTriChamCong? viTri)
    {
        viTri = null;
        var p = token.Trim().Split('.');
        if (p.Length != 3) return false;
        if (!int.TryParse(p[0], out var id) || !long.TryParse(p[1], out var w)) return false;

        var now = CuaSoHienTai();
        if (w > now || now - w > 1) return false; // chỉ chấp nhận cửa sổ hiện tại và liền trước

        var vt = viTris.FirstOrDefault(v => v.Id == id);
        if (vt == null) return false;

        var dung = CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(Ky(vt, w)),
            Encoding.UTF8.GetBytes(p[2]));
        if (!dung) return false;

        viTri = vt;
        return true;
    }

    private static string Ky(ViTriChamCong vt, long w)
    {
        using var h = new HMACSHA256(Encoding.UTF8.GetBytes(vt.QrSecret));
        var mac = h.ComputeHash(Encoding.UTF8.GetBytes($"{vt.Id}.{w}"));
        return Convert.ToHexString(mac).Substring(0, 16);
    }
}
