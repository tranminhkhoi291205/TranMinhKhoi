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
public class PhongBanController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public PhongBanController(ApplicationDbContext db) => _db = db;

    /// <summary>Truy vấn PhongBan kèm đếm nhân viên — dùng cho GetById, Create, Update.</summary>
    private IQueryable<PhongBanDto> Truy() =>
        _db.PhongBans.Select(p => new PhongBanDto(p.Id, p.Ten, p.MoTa,
            _db.NhanViens.Count(n => n.PhongBanId == p.Id)));

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var ds = await _db.PhongBans
            .OrderBy(p => p.Ten)
            .Select(p => new PhongBanDto(
                p.Id,
                p.Ten,
                p.MoTa,
                _db.NhanViens.Count(n => n.PhongBanId == p.Id)))
            .ToListAsync();
        return Ok(ds);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var p = await Truy().FirstOrDefaultAsync(x => x.Id == id);
        return p == null ? NotFound(new { status = false, message = "Không tìm thấy phòng ban." }) : Ok(p);
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Create([FromBody] PhongBanInput m)
    {
        var ten = m.Ten.Trim();
        if (await _db.PhongBans.AnyAsync(p => p.Ten == ten))
            return BadRequest(new { status = false, message = "Tên phòng ban đã tồn tại." });

        var pb = new PhongBan { Ten = ten, MoTa = m.MoTa };
        _db.PhongBans.Add(pb);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = pb.Id }, await Truy().FirstAsync(x => x.Id == pb.Id));
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Update(int id, [FromBody] PhongBanInput m)
    {
        var pb = await _db.PhongBans.FindAsync(id);
        if (pb == null) return NotFound(new { status = false, message = "Không tìm thấy phòng ban." });

        var ten = m.Ten.Trim();
        if (await _db.PhongBans.AnyAsync(p => p.Ten == ten && p.Id != id))
            return BadRequest(new { status = false, message = "Tên phòng ban đã tồn tại." });

        pb.Ten = ten;
        pb.MoTa = m.MoTa;
        await _db.SaveChangesAsync();
        return Ok(await Truy().FirstAsync(x => x.Id == id));
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Delete(int id)
    {
        var pb = await _db.PhongBans.FindAsync(id);
        if (pb == null) return NotFound(new { status = false, message = "Không tìm thấy phòng ban." });

        _db.PhongBans.Remove(pb); // nhân viên thuộc phòng ban sẽ được đặt PhongBanId = null
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa phòng ban." });
    }
}
