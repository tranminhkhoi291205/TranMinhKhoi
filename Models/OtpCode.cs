using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

/// <summary>Mã OTP gửi qua email (lưu dạng băm, không lưu mã gốc).</summary>
public class OtpCode
{
    public int Id { get; set; }

    [Required, MaxLength(450)]
    public string UserId { get; set; } = string.Empty;

    [Required, MaxLength(20)]
    public string MucDich { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string MaBam { get; set; } = string.Empty;

    public DateTime HetHan { get; set; }
    public int SoLanThu { get; set; }
    public bool DaDung { get; set; }
    public DateTime NgayTao { get; set; } = DateTime.UtcNow;
}
