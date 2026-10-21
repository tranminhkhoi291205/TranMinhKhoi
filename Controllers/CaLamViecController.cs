using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CaLamViecController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public CaLamViecController(ApplicationDbContext db) => _db = db;

    private static CaLamViecDto ToDto(CaLamViec c) => new(c.Id, c.Ten, c.GioBatDau, c.GioKetThuc, c.PhutChoPhepTre);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var ds = await _db.CaLamViecs.OrderBy(c => c.GioBatDau).ToListAsync();
        return Ok(ds.Select(ToDto));
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var c = await _db.CaLamViecs.FindAsync(id);
        return c == null ? NotFound(new { status = false, message = "Không tìm thấy ca làm việc." }) : Ok(ToDto(c));
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Create([FromBody] CaLamViecInput m)
    {
        if (m.GioKetThuc <= m.GioBatDau)
            return BadRequest(new { status = false, message = "Giờ kết thúc phải sau giờ bắt đầu." });

        var c = new CaLamViec { Ten = m.Ten.Trim(), GioBatDau = m.GioBatDau, GioKetThuc = m.GioKetThuc, PhutChoPhepTre = m.PhutChoPhepTre };
        _db.CaLamViecs.Add(c);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = c.Id }, ToDto(c));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Update(int id, [FromBody] CaLamViecInput m)
    {
        var c = await _db.CaLamViecs.FindAsync(id);
        if (c == null) return NotFound(new { status = false, message = "Không tìm thấy ca làm việc." });
        if (m.GioKetThuc <= m.GioBatDau)
            return BadRequest(new { status = false, message = "Giờ kết thúc phải sau giờ bắt đầu." });

        c.Ten = m.Ten.Trim();
        c.GioBatDau = m.GioBatDau;
        c.GioKetThuc = m.GioKetThuc;
        c.PhutChoPhepTre = m.PhutChoPhepTre;
        await _db.SaveChangesAsync();
        return Ok(ToDto(c));
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Delete(int id)
    {
        var c = await _db.CaLamViecs.FindAsync(id);
        if (c == null) return NotFound(new { status = false, message = "Không tìm thấy ca làm việc." });

        _db.CaLamViecs.Remove(c); // nhân viên đang dùng ca này sẽ được đặt CaLamViecId = null
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa ca làm việc." });
    }
}
