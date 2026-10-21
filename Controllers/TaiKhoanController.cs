using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;
using TranMinhKhoi.Services;

namespace TranMinhKhoi.Controllers;

/// <summary>Quản lý tài khoản & phân quyền (chỉ Admin).</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = AppRoles.Admin)]
public class TaiKhoanController : ControllerBase
{
    private readonly UserManager<AppUser> _um;
    private readonly ApplicationDbContext _db;

    public TaiKhoanController(UserManager<AppUser> um, ApplicationDbContext db)
    {
        _um = um;
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search)
    {
        var q = from u in _db.Users
                join ur in _db.UserRoles on u.Id equals ur.UserId into urs
                from ur in urs.DefaultIfEmpty()
                join r in _db.Roles on ur.RoleId equals r.Id into rs
                from r in rs.DefaultIfEmpty()
                select new
                {
                    u.Id,
                    u.UserName,
                    u.Email,
                    u.HoTen,
                    u.EmailConfirmed,
                    u.HoatDong,
                    u.DeviceId,
                    Role = r != null ? r.Name : null
                };

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            q = q.Where(x => x.UserName!.Contains(s) || x.Email!.Contains(s) || x.HoTen.Contains(s));
        }

        return Ok(await q.OrderBy(x => x.UserName).ToListAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] TaoTaiKhoanRequest m)
    {
        if (!AppRoles.TatCa.Contains(m.Role))
            return BadRequest(new { status = false, message = "Vai trò không hợp lệ (Admin, QuanLy, NhanVien)." });
        if (await _um.FindByNameAsync(m.Username) != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại." });
        if (await _um.FindByEmailAsync(m.Email) != null)
            return BadRequest(new { status = false, message = "Email đã được sử dụng." });

        var user = new AppUser { UserName = m.Username.Trim(), Email = m.Email.Trim(), HoTen = m.HoTen.Trim(), EmailConfirmed = true };
        var kq = await _um.CreateAsync(user, m.Password);
        if (!kq.Succeeded)
            return BadRequest(new { status = false, message = string.Join(" ", kq.Errors.Select(e => e.Description)) });
        await _um.AddToRoleAsync(user, m.Role);

        return Ok(new { status = true, message = "Đã tạo tài khoản.", id = user.Id });
    }

    [HttpPut("{id}/role")]
    public async Task<IActionResult> DoiVaiTro(string id, [FromBody] DoiVaiTroRequest m)
    {
        if (!AppRoles.TatCa.Contains(m.Role))
            return BadRequest(new { status = false, message = "Vai trò không hợp lệ (Admin, QuanLy, NhanVien)." });
        if (id == User.GetUserId())
            return BadRequest(new { status = false, message = "Không thể tự đổi vai trò của chính mình." });

        var user = await _um.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy tài khoản." });

        var cu = await _um.GetRolesAsync(user);
        await _um.RemoveFromRolesAsync(user, cu);
        await _um.AddToRoleAsync(user, m.Role);
        return Ok(new { status = true, message = $"Đã đổi vai trò thành {m.Role}." });
    }

    [HttpPut("{id}/khoa")]
    public async Task<IActionResult> Khoa(string id, [FromBody] KhoaTaiKhoanRequest m)
    {
        if (id == User.GetUserId())
            return BadRequest(new { status = false, message = "Không thể tự khóa tài khoản của chính mình." });

        var user = await _um.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy tài khoản." });

        user.HoatDong = m.HoatDong;
        await _um.UpdateAsync(user);
        return Ok(new { status = true, message = m.HoatDong ? "Đã mở khóa tài khoản." : "Đã khóa tài khoản." });
    }

    /// <summary>Gỡ ràng buộc thiết bị (khi nhân viên đổi điện thoại).</summary>
    [HttpPut("{id}/reset-thiet-bi")]
    public async Task<IActionResult> ResetThietBi(string id)
    {
        var user = await _um.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy tài khoản." });

        user.DeviceId = null;
        await _um.UpdateAsync(user);
        return Ok(new { status = true, message = "Đã gỡ thiết bị đã đăng ký. Lần đăng nhập tới sẽ ràng buộc thiết bị mới." });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        if (id == User.GetUserId())
            return BadRequest(new { status = false, message = "Không thể tự xóa tài khoản của chính mình." });

        var user = await _um.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy tài khoản." });

        await _um.DeleteAsync(user);
        return Ok(new { status = true, message = "Đã xóa tài khoản." });
    }
}
