using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;
using TranMinhKhoi.Services;

namespace TranMinhKhoi.Controllers;

/// <summary>
/// Dashboard + TÍNH NĂNG MỚI: Điểm chuyên cần (0-100), xếp loại, chuỗi ngày đúng giờ, bảng xếp hạng.
/// Điểm = 100 - 3*đi trễ - 2*về sớm - 10*vắng không phép - 5*bản ghi nghi vấn.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ThongKeController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public ThongKeController(ApplicationDbContext db) => _db = db;

    // ---------- Dashboard Admin / Quản lý ----------
    [HttpGet("tong-quan")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> TongQuan()
    {
        var today = VnTime.Today;
        var tongNv = await _db.NhanViens.CountAsync(n => n.DangLamViec);
        var homNay = await _db.ChamCongs.Where(c => c.Ngay == today && c.GioVao != null).ToListAsync();
        var nghiPhep = await _db.DonNghiPheps.CountAsync(d => d.TrangThai == TrangThaiDon.DaDuyet
                                                              && d.TuNgay <= today && d.DenNgay >= today);
        var choDuyet = await _db.DonNghiPheps.CountAsync(d => d.TrangThai == TrangThaiDon.ChoDuyet);

        var tu = today.AddDays(-6);
        var theoNgay = await _db.ChamCongs.Where(c => c.Ngay >= tu && c.Ngay <= today && c.GioVao != null)
            .GroupBy(c => c.Ngay).Select(g => new { Ngay = g.Key, SoNguoi = g.Count() }).ToListAsync();
        var bayNgay = Enumerable.Range(0, 7).Select(i =>
        {
            var d = tu.AddDays(i);
            return new { ngay = d, coMat = theoNgay.FirstOrDefault(x => x.Ngay == d)?.SoNguoi ?? 0 };
        });

        return Ok(new
        {
            status = true,
            ngay = today,
            tongNhanVien = tongNv,
            coMatHomNay = homNay.Count,
            diTreHomNay = homNay.Count(c => c.SoPhutTre > 0),
            nghiPhepHomNay = nghiPhep,
            vangHomNay = Math.Max(0, tongNv - homNay.Count - nghiPhep),
            banGhiNghiNgo = homNay.Count(c => c.NghiNgo),
            donChoDuyet = choDuyet,
            bayNgayGanNhat = bayNgay
        });
    }

    // ---------- Dashboard nhân viên ----------
    [HttpGet("cua-toi")]
    public async Task<IActionResult> CuaToi([FromQuery] string? thang)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });
        if (!TryLayThang(thang, out var dau, out var cuoi))
            return BadRequest(new { status = false, message = "Tháng không hợp lệ, dùng định dạng yyyy-MM (ví dụ 2026-10)." });

        var ccs = await _db.ChamCongs.Where(c => c.NhanVienId == nv.Id && c.Ngay >= dau && c.Ngay <= cuoi).ToListAsync();
        var dons = await _db.DonNghiPheps.Where(d => d.NhanVienId == nv.Id && d.TrangThai == TrangThaiDon.DaDuyet
                                                     && d.TuNgay <= cuoi && d.DenNgay >= dau).ToListAsync();

        var tk = TinhThongKe(dau, cuoi, nv.NgayVaoLam, ccs, dons);
        var xepHang = await TinhXepHangAsync(dau, cuoi, nv.Id);
        return Ok(new { status = true, thongKe = tk, xepHang = xepHang.Hang, tongNhanVien = xepHang.Tong });
    }

    // ---------- Báo cáo tháng + bảng xếp hạng chuyên cần ----------
    [HttpGet("bao-cao-thang")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> BaoCaoThang([FromQuery] string? thang)
    {
        if (!TryLayThang(thang, out var dau, out var cuoi))
            return BadRequest(new { status = false, message = "Tháng không hợp lệ, dùng định dạng yyyy-MM (ví dụ 2026-10)." });

        var ds = await TinhTatCaAsync(dau, cuoi);
        return Ok(ds.OrderByDescending(x => x.ThongKe.DiemChuyenCan).ThenBy(x => x.MaNV)
            .Select((x, i) => new { hang = i + 1, x.NhanVienId, x.MaNV, x.HoTen, x.TenPhongBan, x.ThongKe }));
    }

    // ---------- Hàm tính ----------
    private record KetQuaNv(int NhanVienId, string MaNV, string HoTen, string? TenPhongBan, ThongKeThangDto ThongKe);

    private async Task<List<KetQuaNv>> TinhTatCaAsync(DateOnly dau, DateOnly cuoi)
    {
        var nvs = await _db.NhanViens.Where(n => n.DangLamViec)
            .Select(n => new { n.Id, n.MaNV, n.HoTen, n.NgayVaoLam, Phong = n.PhongBan != null ? n.PhongBan.Ten : null })
            .ToListAsync();
        var ccs = (await _db.ChamCongs.Where(c => c.Ngay >= dau && c.Ngay <= cuoi).ToListAsync())
            .GroupBy(c => c.NhanVienId).ToDictionary(g => g.Key, g => g.ToList());
        var dons = (await _db.DonNghiPheps.Where(d => d.TrangThai == TrangThaiDon.DaDuyet && d.TuNgay <= cuoi && d.DenNgay >= dau).ToListAsync())
            .GroupBy(d => d.NhanVienId).ToDictionary(g => g.Key, g => g.ToList());

        return nvs.Select(n => new KetQuaNv(n.Id, n.MaNV, n.HoTen, n.Phong,
            TinhThongKe(dau, cuoi, n.NgayVaoLam,
                ccs.GetValueOrDefault(n.Id) ?? new List<ChamCong>(),
                dons.GetValueOrDefault(n.Id) ?? new List<DonNghiPhep>()))).ToList();
    }

    private async Task<(int Hang, int Tong)> TinhXepHangAsync(DateOnly dau, DateOnly cuoi, int nhanVienId)
    {
        var ds = (await TinhTatCaAsync(dau, cuoi))
            .OrderByDescending(x => x.ThongKe.DiemChuyenCan).ThenBy(x => x.MaNV).ToList();
        var idx = ds.FindIndex(x => x.NhanVienId == nhanVienId);
        return (idx < 0 ? 0 : idx + 1, ds.Count);
    }

    private static ThongKeThangDto TinhThongKe(DateOnly dau, DateOnly cuoi, DateOnly ngayVaoLam,
        List<ChamCong> ccs, List<DonNghiPhep> donDaDuyet)
    {
        var today = VnTime.Today;
        var den = cuoi < today ? cuoi : today;
        var tu = dau > ngayVaoLam ? dau : ngayVaoLam;

        bool CuoiTuan(DateOnly d) => d.DayOfWeek == DayOfWeek.Saturday || d.DayOfWeek == DayOfWeek.Sunday;
        bool NghiPhep(DateOnly d) => donDaDuyet.Any(x => x.TuNgay <= d && d <= x.DenNgay);

        // Số ngày công chuẩn của cả tháng (Thứ 2 - Thứ 6)
        int congChuan = 0;
        for (var d = dau; d <= cuoi; d = d.AddDays(1))
            if (!CuoiTuan(d)) congChuan++;

        int ngayCong = 0, ngayNghiPhep = 0, vang = 0;
        for (var d = tu; d <= den; d = d.AddDays(1))
        {
            if (CuoiTuan(d)) continue;
            var c = ccs.FirstOrDefault(x => x.Ngay == d);
            if (c?.GioVao != null) { ngayCong++; continue; }
            if (NghiPhep(d)) { ngayNghiPhep++; continue; }
            if (d < today) vang++; // hôm nay chưa kết thúc nên chưa tính vắng
        }

        int diTre = ccs.Count(c => c.SoPhutTre > 0);
        int veSom = ccs.Count(c => c.SoPhutVeSom > 0);
        int nghiNgo = ccs.Count(c => c.NghiNgo);
        double tongGio = Math.Round(ccs.Sum(c => c.SoGioLam ?? 0), 2);

        int diem = Math.Clamp(100 - 3 * diTre - 2 * veSom - 10 * vang - 5 * nghiNgo, 0, 100);
        string xepLoai = diem >= 90 ? "Xuất sắc" : diem >= 75 ? "Tốt" : diem >= 60 ? "Khá" : "Cần cải thiện";

        // Chuỗi ngày làm việc liên tiếp đến giờ không đi trễ
        int chuoi = 0;
        for (var d = den; d >= tu; d = d.AddDays(-1))
        {
            if (CuoiTuan(d) || NghiPhep(d)) continue;
            var c = ccs.FirstOrDefault(x => x.Ngay == d);
            if (c?.GioVao != null && c.SoPhutTre == 0) chuoi++;
            else if (d == today && c == null) continue; // hôm nay chưa chấm công thì không làm đứt chuỗi
            else break;
        }

        return new ThongKeThangDto($"{dau:yyyy-MM}", congChuan, ngayCong, ngayNghiPhep, vang,
            diTre, veSom, nghiNgo, tongGio, diem, xepLoai, chuoi);
    }

    private static bool TryLayThang(string? thang, out DateOnly dau, out DateOnly cuoi)
    {
        var today = VnTime.Today;
        dau = new DateOnly(today.Year, today.Month, 1);
        if (!string.IsNullOrWhiteSpace(thang))
        {
            if (!DateOnly.TryParseExact(thang.Trim() + "-01", "yyyy-MM-dd", out dau))
            {
                cuoi = dau;
                return false;
            }
        }
        cuoi = dau.AddMonths(1).AddDays(-1);
        return true;
    }
}
