using System.ComponentModel.DataAnnotations;

namespace TranMinhKhoi.Models;

public class CaLamViec
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Ten { get; set; } = string.Empty;

    public TimeOnly GioBatDau { get; set; }
    public TimeOnly GioKetThuc { get; set; }

    /// <summary>Số phút được phép vào trễ mà không bị tính đi trễ.</summary>
    public int PhutChoPhepTre { get; set; } = 10;
}
