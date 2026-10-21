using System.Linq.Expressions;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;
using TranMinhKhoi.Services;

namespace TranMinhKhoi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NhanVienController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public NhanVienController(ApplicationDbContext db) => _db = db;

    private static readonly Expression<Func<NhanVien, NhanVienDto>> ToDto = n => new NhanVienDto(
        n.Id, n.MaNV, n.HoTen, n.NgaySinh, n.GioiTinh, n.SoDienThoai, n.Email, n.DiaChi, n.ChucVu,
        n.LuongCoBan, n.NgayVaoLam, n.DangLamViec,
        n.PhongBanId, n.PhongBan != null ? n.PhongBan.Ten : null,
        n.CaLamViecId, n.CaLamViec != null ? n.CaLamViec.Ten : null,
        n.UserId, n.FaceTemplate != null);

    // ---------- CRUD (Admin / Quản lý) ----------
    [HttpGet]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] int? phongBanId,
        [FromQuery] bool? dangLamViec, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var q = _db.NhanViens.AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            q = q.Where(n => n.HoTen.Contains(s) || n.MaNV.Contains(s) || (n.Email != null && n.Email.Contains(s)));
        }
        if (phongBanId != null) q = q.Where(n => n.PhongBanId == phongBanId);
        if (dangLamViec != null) q = q.Where(n => n.DangLamViec == dangLamViec);

        var total = await q.CountAsync();
        var items = await q.OrderBy(n => n.MaNV).Skip((page - 1) * pageSize).Take(pageSize).Select(ToDto).ToListAsync();
        return Ok(new PagedResult<NhanVienDto>(total, page, pageSize, items));
    }

    [HttpGet("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetById(int id)
    {
        var n = await _db.NhanViens.Where(x => x.Id == id).Select(ToDto).FirstOrDefaultAsync();
        return n == null ? NotFound(new { status = false, message = "Không tìm thấy nhân viên." }) : Ok(n);
    }

    [HttpPost]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Create([FromBody] NhanVienInput m)
    {
        var loi = await KiemTraAsync(m, null);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        var nv = new NhanVien();
        GanDuLieu(nv, m);
        await LienKetTaiKhoanAsync(nv);

        _db.NhanViens.Add(nv);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = nv.Id }, await _db.NhanViens.Where(x => x.Id == nv.Id).Select(ToDto).FirstAsync());
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Update(int id, [FromBody] NhanVienInput m)
    {
        var nv = await _db.NhanViens.FindAsync(id);
        if (nv == null) return NotFound(new { status = false, message = "Không tìm thấy nhân viên." });

        var loi = await KiemTraAsync(m, id);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        GanDuLieu(nv, m);
        if (nv.UserId == null) await LienKetTaiKhoanAsync(nv);
        await _db.SaveChangesAsync();
        return Ok(await _db.NhanViens.Where(x => x.Id == id).Select(ToDto).FirstAsync());
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        var nv = await _db.NhanViens.FindAsync(id);
        if (nv == null) return NotFound(new { status = false, message = "Không tìm thấy nhân viên." });

        _db.NhanViens.Remove(nv); // xóa luôn dữ liệu chấm công & đơn nghỉ phép của nhân viên
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa nhân viên." });
    }

    // ---------- Hồ sơ của chính mình ----------
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var uid = User.GetUserId();
        var n = await _db.NhanViens.Where(x => x.UserId == uid).Select(ToDto).FirstOrDefaultAsync();
        return n == null
            ? NotFound(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." })
            : Ok(n);
    }

    [HttpPut("me")]
    public async Task<IActionResult> CapNhatHoSo([FromBody] CapNhatHoSoRequest m)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return NotFound(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        nv.SoDienThoai = m.SoDienThoai;
        nv.DiaChi = m.DiaChi;
        await _db.SaveChangesAsync();
        return Ok(await _db.NhanViens.Where(x => x.Id == nv.Id).Select(ToDto).FirstAsync());
    }

    // ---------- Khuôn mặt (phục vụ chấm công FACE) ----------
    [HttpPost("me/khuon-mat")]
    public async Task<IActionResult> DangKyKhuonMat([FromBody] DangKyKhuonMatRequest m)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return NotFound(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        nv.FaceTemplate = JsonSerializer.Serialize(m.KhuonMat);
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã lưu dữ liệu khuôn mặt." });
    }

    [HttpDelete("me/khuon-mat")]
    public async Task<IActionResult> XoaKhuonMat()
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return NotFound(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        nv.FaceTemplate = null;
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa dữ liệu khuôn mặt." });
    }

    // ---------- Hàm phụ ----------
    private async Task<string?> KiemTraAsync(NhanVienInput m, int? idHienTai)
    {
        var ma = m.MaNV.Trim();
        if (await _db.NhanViens.AnyAsync(n => n.MaNV == ma && n.Id != idHienTai))
            return "Mã nhân viên đã tồn tại.";
        if (m.PhongBanId != null && !await _db.PhongBans.AnyAsync(p => p.Id == m.PhongBanId))
            return "Phòng ban không tồn tại.";
        if (m.CaLamViecId != null && !await _db.CaLamViecs.AnyAsync(c => c.Id == m.CaLamViecId))
            return "Ca làm việc không tồn tại.";
        return null;
    }

    private static void GanDuLieu(NhanVien nv, NhanVienInput m)
    {
        nv.MaNV = m.MaNV.Trim();
        nv.HoTen = m.HoTen.Trim();
        nv.NgaySinh = m.NgaySinh;
        nv.GioiTinh = m.GioiTinh;
        nv.SoDienThoai = m.SoDienThoai;
        nv.Email = m.Email?.Trim();
        nv.DiaChi = m.DiaChi;
        nv.ChucVu = m.ChucVu;
        nv.LuongCoBan = m.LuongCoBan;
        nv.NgayVaoLam = m.NgayVaoLam;
        nv.DangLamViec = m.DangLamViec;
        nv.PhongBanId = m.PhongBanId;
        nv.CaLamViecId = m.CaLamViecId;
    }

    /// <summary>Nếu đã có tài khoản (đã xác thực email) trùng email → gắn vào hồ sơ nhân viên.</summary>
    private async Task LienKetTaiKhoanAsync(NhanVien nv)
    {
        if (string.IsNullOrWhiteSpace(nv.Email)) return;
        var u = await _db.Users.FirstOrDefaultAsync(x => x.Email == nv.Email && x.EmailConfirmed);
        if (u == null) return;
        if (await _db.NhanViens.AnyAsync(n => n.UserId == u.Id && n.Id != nv.Id)) return;
        nv.UserId = u.Id;
    }
}
