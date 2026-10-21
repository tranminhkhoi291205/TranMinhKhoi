using System.Security.Cryptography;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;
using TranMinhKhoi.Services;

namespace TranMinhKhoi.Controllers;

/// <summary>Điểm chấm công: toạ độ GPS + bán kính + mã QR động.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ViTriChamCongController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly QrTokenService _qr;

    public ViTriChamCongController(ApplicationDbContext db, QrTokenService qr)
    {
        _db = db;
        _qr = qr;
    }

    private static ViTriDto ToDto(ViTriChamCong v) =>
        new(v.Id, v.Ten, v.DiaChi, v.Latitude, v.Longitude, v.BanKinhMet, v.HoatDong);

    private static string TaoSecret() => Convert.ToHexString(RandomNumberGenerator.GetBytes(24));

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var ds = await _db.ViTriChamCongs.OrderBy(v => v.Ten).ToListAsync();
        return Ok(ds.Select(ToDto));
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var v = await _db.ViTriChamCongs.FindAsync(id);
        return v == null ? NotFound(new { status = false, message = "Không tìm thấy vị trí chấm công." }) : Ok(ToDto(v));
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Create([FromBody] ViTriInput m)
    {
        var v = new ViTriChamCong
        {
            Ten = m.Ten.Trim(),
            DiaChi = m.DiaChi,
            Latitude = m.Latitude,
            Longitude = m.Longitude,
            BanKinhMet = m.BanKinhMet,
            HoatDong = m.HoatDong,
            QrSecret = TaoSecret()
        };
        _db.ViTriChamCongs.Add(v);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = v.Id }, ToDto(v));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Update(int id, [FromBody] ViTriInput m)
    {
        var v = await _db.ViTriChamCongs.FindAsync(id);
        if (v == null) return NotFound(new { status = false, message = "Không tìm thấy vị trí chấm công." });

        v.Ten = m.Ten.Trim();
        v.DiaChi = m.DiaChi;
        v.Latitude = m.Latitude;
        v.Longitude = m.Longitude;
        v.BanKinhMet = m.BanKinhMet;
        v.HoatDong = m.HoatDong;
        await _db.SaveChangesAsync();
        return Ok(ToDto(v));
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Delete(int id)
    {
        var v = await _db.ViTriChamCongs.FindAsync(id);
        if (v == null) return NotFound(new { status = false, message = "Không tìm thấy vị trí chấm công." });

        _db.ViTriChamCongs.Remove(v);
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa vị trí chấm công." });
    }

    /// <summary>Lấy mã QR hiện tại (đổi mỗi 60 giây) để hiển thị trên màn hình quản lý / máy chiếu tại văn phòng.</summary>
    [HttpGet("{id:int}/qr")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> LayQr(int id)
    {
        var v = await _db.ViTriChamCongs.FindAsync(id);
        if (v == null) return NotFound(new { status = false, message = "Không tìm thấy vị trí chấm công." });

        return Ok(new
        {
            status = true,
            viTri = v.Ten,
            token = _qr.Tao(v),
            hieuLucGiay = QrTokenService.CuaSoGiay,
            conLaiGiay = QrTokenService.GiayConLai()
        });
    }

    /// <summary>Đổi khóa bí mật: mọi mã QR đã phát ra trước đó sẽ vô hiệu.</summary>
    [HttpPut("{id:int}/doi-khoa-qr")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> DoiKhoaQr(int id)
    {
        var v = await _db.ViTriChamCongs.FindAsync(id);
        if (v == null) return NotFound(new { status = false, message = "Không tìm thấy vị trí chấm công." });

        v.QrSecret = TaoSecret();
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã đổi khóa QR." });
    }
}
