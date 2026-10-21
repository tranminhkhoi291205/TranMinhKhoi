namespace TranMinhKhoi.Services;

/// <summary>Giờ Việt Nam (UTC+7), không phụ thuộc múi giờ của máy chủ.</summary>
public static class VnTime
{
    public static DateTime Now => DateTime.UtcNow.AddHours(7);
    public static DateOnly Today => DateOnly.FromDateTime(Now);
}
