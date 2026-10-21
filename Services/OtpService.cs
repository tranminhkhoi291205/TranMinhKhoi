using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Services;

public class OtpService
{
    private const int SoLanThuToiDa = 5;
    private const int GiayChoGuiLai = 60;

    private readonly ApplicationDbContext _db;
    private readonly IConfiguration _cfg;

    public OtpService(ApplicationDbContext db, IConfiguration cfg)
    {
        _db = db;
        _cfg = cfg;
    }

    public int HetHanPhut => _cfg.GetValue("Otp:ExpiryMinutes", 5);

    /// <summary>Tạo OTP 6 số mới (vô hiệu các OTP cũ cùng mục đích) và trả về mã gốc để gửi email.</summary>
    public async Task<string> TaoAsync(string userId, string mucDich)
    {
        var cu = await _db.OtpCodes
            .Where(o => o.UserId == userId && o.MucDich == mucDich && !o.DaDung)
            .ToListAsync();
        foreach (var o in cu) o.DaDung = true;

        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        _db.OtpCodes.Add(new OtpCode
        {
            UserId = userId,
            MucDich = mucDich,
            MaBam = Bam(userId, mucDich, code),
            HetHan = DateTime.UtcNow.AddMinutes(HetHanPhut),
            NgayTao = DateTime.UtcNow
        });
        await _db.SaveChangesAsync();
        return code;
    }

    public async Task<(bool Ok, string Message)> KiemTraAsync(string userId, string mucDich, string code)
    {
        var otp = await _db.OtpCodes
            .Where(o => o.UserId == userId && o.MucDich == mucDich && !o.DaDung)
            .OrderByDescending(o => o.Id)
            .FirstOrDefaultAsync();

        if (otp == null)
            return (false, "Mã OTP không tồn tại hoặc đã được sử dụng. Vui lòng yêu cầu mã mới.");

        if (otp.HetHan < DateTime.UtcNow)
        {
            otp.DaDung = true;
            await _db.SaveChangesAsync();
            return (false, "Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        if (otp.SoLanThu >= SoLanThuToiDa)
        {
            otp.DaDung = true;
            await _db.SaveChangesAsync();
            return (false, "Bạn đã nhập sai quá nhiều lần. Vui lòng yêu cầu mã mới.");
        }

        var dung = CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(otp.MaBam),
            Encoding.UTF8.GetBytes(Bam(userId, mucDich, code)));

        if (!dung)
        {
            otp.SoLanThu++;
            await _db.SaveChangesAsync();
            return (false, $"Mã OTP không đúng (còn {SoLanThuToiDa - otp.SoLanThu} lần thử).");
        }

        otp.DaDung = true;
        await _db.SaveChangesAsync();
        return (true, "OK");
    }

    /// <summary>Số giây còn phải chờ trước khi được gửi lại OTP (0 = được gửi).</summary>
    public async Task<int> GiayConPhaiChoAsync(string userId, string mucDich)
    {
        var gan = await _db.OtpCodes
            .Where(o => o.UserId == userId && o.MucDich == mucDich)
            .OrderByDescending(o => o.Id)
            .Select(o => (DateTime?)o.NgayTao)
            .FirstOrDefaultAsync();
        if (gan == null) return 0;
        var troi = (DateTime.UtcNow - gan.Value).TotalSeconds;
        return troi >= GiayChoGuiLai ? 0 : (int)Math.Ceiling(GiayChoGuiLai - troi);
    }

    private string Bam(string userId, string mucDich, string code)
    {
        var khoa = Encoding.UTF8.GetBytes(_cfg["JWTKey:Secret"] ?? "TranMinhKhoi");
        using var h = new HMACSHA256(khoa);
        return Convert.ToHexString(h.ComputeHash(Encoding.UTF8.GetBytes($"{userId}|{mucDich}|{code}")));
    }
}
