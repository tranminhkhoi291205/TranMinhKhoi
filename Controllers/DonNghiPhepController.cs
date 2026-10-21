using System.Linq.Expressions;
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
public class DonNghiPhepController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public DonNghiPhepController(ApplicationDbContext db) => _db = db;

    private static readonly Expression<Func<DonNghiPhep, DonNghiDto>> ToDto = d => new DonNghiDto(
        d.Id, d.NhanVienId, d.NhanVien.MaNV, d.NhanVien.HoTen, d.TuNgay, d.DenNgay,
        d.LyDo, d.TrangThai, d.NgayTao, d.NgayDuyet, d.GhiChuDuyet);

    // ---------- Nhân viên ----------
    [HttpGet("cua-toi")]
    public async Task<IActionResult> CuaToi()
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        var ds = await _db.DonNghiPheps.Where(d => d.NhanVienId == nv.Id)
            .OrderByDescending(d => d.NgayTao).Select(ToDto).ToListAsync();
        return Ok(ds);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] DonNghiInput m)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        var loi = await KiemTraAsync(nv.Id, m, null);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        var don = new DonNghiPhep
        {
            NhanVienId = nv.Id,
            TuNgay = m.TuNgay,
            DenNgay = m.DenNgay,
            LyDo = m.LyDo.Trim(),
            TrangThai = TrangThaiDon.ChoDuyet,
            NgayTao = VnTime.Now
        };
        _db.DonNghiPheps.Add(don);
        await _db.SaveChangesAsync();
        return Ok(await _db.DonNghiPheps.Where(d => d.Id == don.Id).Select(ToDto).FirstAsync());
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] DonNghiInput m)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        var don = await _db.DonNghiPheps.FirstOrDefaultAsync(d => d.Id == id);
        if (nv == null || don == null || don.NhanVienId != nv.Id)
            return NotFound(new { status = false, message = "Không tìm thấy đơn nghỉ phép của bạn." });
        if (don.TrangThai != TrangThaiDon.ChoDuyet)
            return BadRequest(new { status = false, message = "Chỉ được sửa đơn đang chờ duyệt." });

        var loi = await KiemTraAsync(nv.Id, m, id);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        don.TuNgay = m.TuNgay;
        don.DenNgay = m.DenNgay;
        don.LyDo = m.LyDo.Trim();
        await _db.SaveChangesAsync();
        return Ok(await _db.DonNghiPheps.Where(d => d.Id == id).Select(ToDto).FirstAsync());
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var don = await _db.DonNghiPheps.FirstOrDefaultAsync(d => d.Id == id);
        if (don == null) return NotFound(new { status = false, message = "Không tìm thấy đơn nghỉ phép." });

        var laQuanTri = User.IsInRole(AppRoles.Admin);
        if (!laQuanTri)
        {
            var nv = await _db.NhanVienHienTaiAsync(User);
            if (nv == null || don.NhanVienId != nv.Id)
                return NotFound(new { status = false, message = "Không tìm thấy đơn nghỉ phép của bạn." });
            if (don.TrangThai != TrangThaiDon.ChoDuyet)
                return BadRequest(new { status = false, message = "Chỉ được hủy đơn đang chờ duyệt." });
        }

        _db.DonNghiPheps.Remove(don);
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa đơn nghỉ phép." });
    }

    // ---------- Quản lý ----------
    [HttpGet]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetAll([FromQuery] string? trangThai, [FromQuery] int? nhanVienId,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var q = _db.DonNghiPheps.AsQueryable();
        if (!string.IsNullOrWhiteSpace(trangThai)) q = q.Where(d => d.TrangThai == trangThai);
        if (nhanVienId != null) q = q.Where(d => d.NhanVienId == nhanVienId);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(d => d.NgayTao).Skip((page - 1) * pageSize).Take(pageSize)
            .Select(ToDto).ToListAsync();
        return Ok(new PagedResult<DonNghiDto>(total, page, pageSize, items));
    }

    [HttpGet("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetById(int id)
    {
        var d = await _db.DonNghiPheps.Where(x => x.Id == id).Select(ToDto).FirstOrDefaultAsync();
        return d == null ? NotFound(new { status = false, message = "Không tìm thấy đơn nghỉ phép." }) : Ok(d);
    }

    [HttpPut("{id:int}/duyet")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Duyet(int id, [FromBody] DuyetDonRequest m)
    {
        var don = await _db.DonNghiPheps.Include(d => d.NhanVien).FirstOrDefaultAsync(d => d.Id == id);
        if (don == null) return NotFound(new { status = false, message = "Không tìm thấy đơn nghỉ phép." });
        if (don.TrangThai != TrangThaiDon.ChoDuyet)
            return BadRequest(new { status = false, message = "Đơn này đã được xử lý." });
        if (don.NhanVien.UserId != null && don.NhanVien.UserId == User.GetUserId())
            return BadRequest(new { status = false, message = "Bạn không thể tự duyệt đơn của chính mình." });

        don.TrangThai = m.DongY ? TrangThaiDon.DaDuyet : TrangThaiDon.TuChoi;
        don.NguoiDuyetId = User.GetUserId();
        don.NgayDuyet = VnTime.Now;
        don.GhiChuDuyet = m.GhiChu;
        await _db.SaveChangesAsync();
        return Ok(await _db.DonNghiPheps.Where(d => d.Id == id).Select(ToDto).FirstAsync());
    }

    // ---------- Hàm phụ ----------
    private async Task<string?> KiemTraAsync(int nhanVienId, DonNghiInput m, int? idHienTai)
    {
        if (m.DenNgay < m.TuNgay) return "Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.";
        if (m.TuNgay < VnTime.Today) return "Không thể xin nghỉ cho những ngày đã qua.";
        if (m.DenNgay.DayNumber - m.TuNgay.DayNumber > 30) return "Mỗi đơn nghỉ tối đa 31 ngày.";

        var trung = await _db.DonNghiPheps.AnyAsync(d => d.NhanVienId == nhanVienId && d.Id != idHienTai
            && d.TrangThai != TrangThaiDon.TuChoi && d.TuNgay <= m.DenNgay && d.DenNgay >= m.TuNgay);
        return trung ? "Khoảng ngày này trùng với một đơn nghỉ phép khác của bạn." : null;
    }
}
