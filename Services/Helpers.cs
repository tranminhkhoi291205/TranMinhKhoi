using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Services;

public static class GeoHelper
{
    /// <summary>Khoảng cách Haversine giữa hai toạ độ (mét).</summary>
    public static double KhoangCachMet(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371000;
        double dLat = Rad(lat2 - lat1), dLon = Rad(lon2 - lon1);
        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Cos(Rad(lat1)) * Math.Cos(Rad(lat2)) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return 2 * R * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double Rad(double deg) => deg * Math.PI / 180.0;
}

public static class FaceHelper
{
    /// <summary>Độ tương đồng cosine giữa hai vector đặc trưng khuôn mặt (0..1).</summary>
    public static double CosineSimilarity(double[] a, double[] b)
    {
        if (a.Length == 0 || a.Length != b.Length) return 0;
        double dot = 0, na = 0, nb = 0;
        for (int i = 0; i < a.Length; i++)
        {
            dot += a[i] * b[i];
            na += a[i] * a[i];
            nb += b[i] * b[i];
        }
        if (na == 0 || nb == 0) return 0;
        return dot / (Math.Sqrt(na) * Math.Sqrt(nb));
    }
}

public static class ClaimsExtensions
{
    /// <summary>Id tài khoản lấy từ claim "uid" trong JWT.</summary>
    public static string? GetUserId(this ClaimsPrincipal user) => user.FindFirst("uid")?.Value;

    /// <summary>Hồ sơ nhân viên gắn với tài khoản đang đăng nhập.</summary>
    public static async Task<NhanVien?> NhanVienHienTaiAsync(this ApplicationDbContext db, ClaimsPrincipal user)
    {
        var uid = user.GetUserId();
        if (string.IsNullOrEmpty(uid)) return null;
        return await db.NhanViens.FirstOrDefaultAsync(n => n.UserId == uid);
    }
}
