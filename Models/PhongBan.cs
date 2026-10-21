using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

public class PhongBan
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Ten { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? MoTa { get; set; }

    public ICollection<NhanVien> NhanViens { get; set; } = new List<NhanVien>();
}
