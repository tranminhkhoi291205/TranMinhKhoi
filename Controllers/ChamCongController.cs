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

/// <summary>
/// Chấm công vào/ra bằng 3 phương thức: GPS (chia sẻ vị trí), QR động, khuôn mặt.
/// Tính năng riêng: ràng buộc thiết bị + chặn vị trí giả lập + điểm chuyên cần (xem ThongKeController).
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChamCongController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly QrTokenService _qr;
    private readonly IConfiguration _cfg;

    public ChamCongController(ApplicationDbContext db, QrTokenService qr, IConfiguration cfg)
    {
        _db = db;
        _qr = qr;
        _cfg = cfg;
    }

    private static readonly Expression<Func<ChamCong, ChamCongDto>> ToDto = c => new ChamCongDto(
        c.Id, c.NhanVienId, c.NhanVien.MaNV, c.NhanVien.HoTen, c.Ngay, c.GioVao, c.GioRa,
        c.PhuongThucVao, c.PhuongThucRa, c.TrangThai, c.SoPhutTre, c.SoPhutVeSom, c.SoGioLam,
        c.NghiNgo, c.GhiChu, c.ViTriChamCong != null ? c.ViTriChamCong.Ten : null);

    // =============== CHẤM CÔNG CỦA NHÂN VIÊN ===============
    [HttpPost("check-in")]
    public Task<IActionResult> CheckIn([FromBody] ChamCongRequest req) => GhiNhanAsync(req, vao: true);

    [HttpPost("check-out")]
    public Task<IActionResult> CheckOut([FromBody] ChamCongRequest req) => GhiNhanAsync(req, vao: false);

    [HttpGet("hom-nay")]
    public async Task<IActionResult> HomNay()
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        var today = VnTime.Today;
        var cc = await _db.ChamCongs.FirstOrDefaultAsync(c => c.NhanVienId == nv.Id && c.Ngay == today);
        var nghiPhep = await _db.DonNghiPheps.AnyAsync(d => d.NhanVienId == nv.Id && d.TrangThai == TrangThaiDon.DaDuyet
                                                            && d.TuNgay <= today && d.DenNgay >= today);
        return Ok(new
        {
            status = true,
            ngay = today,
            daVao = cc?.GioVao != null,
            gioVao = cc?.GioVao,
            daRa = cc?.GioRa != null,
            gioRa = cc?.GioRa,
            trangThai = cc?.TrangThai,
            soPhutTre = cc?.SoPhutTre ?? 0,
            soGioLam = cc?.SoGioLam,
            dangNghiPhep = nghiPhep
        });
    }

    [HttpGet("cua-toi")]
    public async Task<IActionResult> CuaToi([FromQuery] DateOnly? tuNgay, [FromQuery] DateOnly? denNgay)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null) return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên." });

        var today = VnTime.Today;
        var tu = tuNgay ?? new DateOnly(today.Year, today.Month, 1);
        var den = denNgay ?? today;

        var ds = await _db.ChamCongs.Where(c => c.NhanVienId == nv.Id && c.Ngay >= tu && c.Ngay <= den)
            .OrderByDescending(c => c.Ngay).Select(ToDto).ToListAsync();
        return Ok(ds);
    }

    // =============== QUẢN LÝ BẢNG CÔNG (Admin / Quản lý) ===============
    [HttpGet]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetAll([FromQuery] int? nhanVienId, [FromQuery] DateOnly? tuNgay,
        [FromQuery] DateOnly? denNgay, [FromQuery] bool? nghiNgo, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var q = _db.ChamCongs.AsQueryable();
        if (nhanVienId != null) q = q.Where(c => c.NhanVienId == nhanVienId);
        if (tuNgay != null) q = q.Where(c => c.Ngay >= tuNgay);
        if (denNgay != null) q = q.Where(c => c.Ngay <= denNgay);
        if (nghiNgo != null) q = q.Where(c => c.NghiNgo == nghiNgo);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(c => c.Ngay).ThenByDescending(c => c.Id)
            .Skip((page - 1) * pageSize).Take(pageSize).Select(ToDto).ToListAsync();
        return Ok(new PagedResult<ChamCongDto>(total, page, pageSize, items));
    }

    [HttpGet("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> GetById(int id)
    {
        var c = await _db.ChamCongs.Where(x => x.Id == id).Select(ToDto).FirstOrDefaultAsync();
        return c == null ? NotFound(new { status = false, message = "Không tìm thấy bản ghi chấm công." }) : Ok(c);
    }

    /// <summary>Bổ sung công thủ công (quên chấm công, công tác...).</summary>
    [HttpPost]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Create([FromBody] ChamCongAdminInput m)
    {
        var nv = await _db.NhanViens.FindAsync(m.NhanVienId);
        if (nv == null) return BadRequest(new { status = false, message = "Nhân viên không tồn tại." });

        var loi = KiemTraGio(m);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        if (await _db.ChamCongs.AnyAsync(c => c.NhanVienId == m.NhanVienId && c.Ngay == m.Ngay))
            return Conflict(new { status = false, message = "Nhân viên đã có bản ghi chấm công trong ngày này, hãy dùng chức năng sửa." });

        var cc = new ChamCong { NhanVienId = m.NhanVienId, Ngay = m.Ngay };
        cc.GioVao = m.GioVao;
        cc.GioRa = m.GioRa;
        cc.GhiChu = string.IsNullOrWhiteSpace(m.GhiChu) ? "Bổ sung công thủ công" : m.GhiChu;
        TinhLai(cc, await LayCaAsync(nv));

        _db.ChamCongs.Add(cc);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = cc.Id }, await _db.ChamCongs.Where(x => x.Id == cc.Id).Select(ToDto).FirstAsync());
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = AppRoles.AdminQuanLy)]
    public async Task<IActionResult> Update(int id, [FromBody] ChamCongAdminInput m)
    {
        var cc = await _db.ChamCongs.Include(c => c.NhanVien).FirstOrDefaultAsync(c => c.Id == id);
        if (cc == null) return NotFound(new { status = false, message = "Không tìm thấy bản ghi chấm công." });

        var loi = KiemTraGio(m);
        if (loi != null) return BadRequest(new { status = false, message = loi });

        cc.Ngay = m.Ngay;
        cc.GioVao = m.GioVao;
        cc.GioRa = m.GioRa;
        cc.GhiChu = m.GhiChu;
        cc.NghiNgo = false; // quản lý đã xem xét và điều chỉnh
        TinhLai(cc, await LayCaAsync(cc.NhanVien));

        try { await _db.SaveChangesAsync(); }
        catch (DbUpdateException)
        {
            return Conflict(new { status = false, message = "Nhân viên đã có bản ghi chấm công ở ngày này." });
        }
        return Ok(await _db.ChamCongs.Where(x => x.Id == id).Select(ToDto).FirstAsync());
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        var cc = await _db.ChamCongs.FindAsync(id);
        if (cc == null) return NotFound(new { status = false, message = "Không tìm thấy bản ghi chấm công." });

        _db.ChamCongs.Remove(cc);
        await _db.SaveChangesAsync();
        return Ok(new { status = true, message = "Đã xóa bản ghi chấm công." });
    }

    // =============== LÕI CHẤM CÔNG ===============
    private async Task<IActionResult> GhiNhanAsync(ChamCongRequest req, bool vao)
    {
        var nv = await _db.NhanVienHienTaiAsync(User);
        if (nv == null)
            return BadRequest(new { status = false, message = "Tài khoản chưa được liên kết hồ sơ nhân viên. Hãy liên hệ quản trị viên." });
        if (!nv.DangLamViec)
            return BadRequest(new { status = false, message = "Hồ sơ nhân viên đang ở trạng thái nghỉ việc." });

        var today = VnTime.Today;
        var now = VnTime.Now;
        var cc = await _db.ChamCongs.FirstOrDefaultAsync(c => c.NhanVienId == nv.Id && c.Ngay == today);

        if (vao)
        {
            if (cc?.GioVao != null)
                return BadRequest(new { status = false, message = $"Hôm nay bạn đã chấm công vào lúc {cc.GioVao:HH:mm}." });

            var nghiPhep = await _db.DonNghiPheps.AnyAsync(d => d.NhanVienId == nv.Id && d.TrangThai == TrangThaiDon.DaDuyet
                                                                && d.TuNgay <= today && d.DenNgay >= today);
            if (nghiPhep)
                return BadRequest(new { status = false, message = "Hôm nay bạn đang trong thời gian nghỉ phép đã được duyệt." });
        }
        else
        {
            if (cc?.GioVao == null)
                return BadRequest(new { status = false, message = "Bạn chưa chấm công vào hôm nay." });
            if (cc.GioRa != null)
                return BadRequest(new { status = false, message = $"Hôm nay bạn đã chấm công ra lúc {cc.GioRa:HH:mm}." });
        }

        // 1. Xác thực theo phương thức (GPS / QR / khuôn mặt)
        var kq = await XacThucAsync(nv, req);
        if (kq.Loi != null) return BadRequest(new { status = false, message = kq.Loi });

        // 2. Ràng buộc thiết bị
        var canhBao = new List<string>();
        var nghiNgo = false;
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == User.GetUserId());
        if (user != null && !string.IsNullOrWhiteSpace(req.DeviceId))
        {
            if (string.IsNullOrEmpty(user.DeviceId))
                user.DeviceId = req.DeviceId.Trim();
            else if (user.DeviceId != req.DeviceId.Trim())
            {
                nghiNgo = true;
                canhBao.Add("Chấm công từ thiết bị khác thiết bị đã đăng ký - bản ghi được đánh dấu nghi vấn.");
            }
        }

        // 3. Ghi bản ghi
        var ca = await LayCaAsync(nv);
        if (vao)
        {
            cc ??= new ChamCong { NhanVienId = nv.Id, Ngay = today };
            cc.GioVao = now;
            cc.PhuongThucVao = kq.PhuongThuc;
            cc.ViDoVao = req.ViDo;
            cc.KinhDoVao = req.KinhDo;
            cc.ViTriChamCongId = kq.ViTri?.Id;
            cc.DeviceId = req.DeviceId;
            if (cc.Id == 0) _db.ChamCongs.Add(cc);
        }
        else
        {
            cc!.GioRa = now;
            cc.PhuongThucRa = kq.PhuongThuc;
            cc.ViDoRa = req.ViDo;
            cc.KinhDoRa = req.KinhDo;
        }

        if (nghiNgo)
        {
            cc.NghiNgo = true;
            cc.GhiChu = string.IsNullOrEmpty(cc.GhiChu) ? canhBao[0] : $"{cc.GhiChu} | {canhBao[0]}";
        }
        TinhLai(cc, ca);

        try { await _db.SaveChangesAsync(); }
        catch (DbUpdateException)
        {
            return Conflict(new { status = false, message = "Không thể ghi nhận chấm công (có thể bạn vừa chấm công ở thiết bị khác). Vui lòng thử lại." });
        }

        return Ok(new
        {
            status = true,
            message = vao
                ? (cc.SoPhutTre > 0 ? $"Chấm công vào thành công lúc {now:HH:mm} (đi trễ {cc.SoPhutTre} phút)." : $"Chấm công vào thành công lúc {now:HH:mm}.")
                : (cc.SoPhutVeSom > 0 ? $"Chấm công ra thành công lúc {now:HH:mm} (về sớm {cc.SoPhutVeSom} phút)." : $"Chấm công ra thành công lúc {now:HH:mm}."),
            phuongThuc = kq.PhuongThuc,
            thoiGian = now,
            trangThai = cc.TrangThai,
            soPhutTre = cc.SoPhutTre,
            soPhutVeSom = cc.SoPhutVeSom,
            soGioLam = cc.SoGioLam,
            viTri = kq.ViTri?.Ten,
            khoangCachMet = kq.KhoangCach == null ? (int?)null : (int)Math.Round(kq.KhoangCach.Value),
            canhBao
        });
    }

    private record KetQuaXacThuc(string? Loi, string PhuongThuc, ViTriChamCong? ViTri, double? KhoangCach);

    private async Task<KetQuaXacThuc> XacThucAsync(NhanVien nv, ChamCongRequest req)
    {
        var pt = (req.PhuongThuc ?? string.Empty).Trim().ToUpperInvariant();
        KetQuaXacThuc Loi(string msg) => new(msg, pt, null, null);

        if (pt != PhuongThucChamCong.GPS && pt != PhuongThucChamCong.QR && pt != PhuongThucChamCong.FACE)
            return Loi("Phương thức chấm công không hợp lệ (GPS, QR hoặc FACE).");

        if (req.GiaLapViTri)
            return Loi("Phát hiện thiết bị đang giả lập vị trí (mock location). Hãy tắt ứng dụng giả vị trí rồi thử lại.");

        var viTris = await _db.ViTriChamCongs.Where(v => v.HoatDong).ToListAsync();
        if (viTris.Count == 0)
            return Loi("Chưa cấu hình vị trí chấm công nào đang hoạt động.");

        // --- QR động ---
        if (pt == PhuongThucChamCong.QR)
        {
            if (string.IsNullOrWhiteSpace(req.QrToken) || !_qr.Kiem(req.QrToken, viTris, out var vt))
                return Loi("Mã QR không hợp lệ hoặc đã hết hạn (mã đổi mỗi 60 giây). Hãy quét lại.");
            return new KetQuaXacThuc(null, pt, vt, null);
        }

        // --- GPS & FACE đều cần toạ độ ---
        if (req.ViDo is null || req.KinhDo is null)
            return Loi("Thiếu toạ độ GPS. Hãy bật định vị và cấp quyền vị trí cho ứng dụng.");

        if (pt == PhuongThucChamCong.FACE)
        {
            if (string.IsNullOrEmpty(nv.FaceTemplate))
                return Loi("Bạn chưa đăng ký khuôn mặt. Hãy đăng ký khuôn mặt trong phần Hồ sơ.");
            if (req.KhuonMat == null || req.KhuonMat.Length == 0)
                return Loi("Thiếu dữ liệu khuôn mặt.");

            var mau = JsonSerializer.Deserialize<double[]>(nv.FaceTemplate) ?? Array.Empty<double>();
            var giong = FaceHelper.CosineSimilarity(mau, req.KhuonMat);
            var nguong = _cfg.GetValue("Face:Threshold", 0.8);
            if (giong < nguong)
                return Loi($"Khuôn mặt không khớp (độ giống {Math.Round(giong * 100)}%).");
        }

        var gan = viTris
            .Select(v => new { V = v, D = GeoHelper.KhoangCachMet(req.ViDo.Value, req.KinhDo.Value, v.Latitude, v.Longitude) })
            .OrderBy(x => x.D)
            .First();
        if (gan.D > gan.V.BanKinhMet)
            return Loi($"Bạn đang cách \"{gan.V.Ten}\" khoảng {Math.Round(gan.D)} m, vượt bán kính cho phép {gan.V.BanKinhMet} m.");

        return new KetQuaXacThuc(null, pt, gan.V, gan.D);
    }

    // =============== HÀM PHỤ ===============
    private async Task<CaLamViec?> LayCaAsync(NhanVien nv)
    {
        if (nv.CaLamViecId != null)
        {
            var ca = await _db.CaLamViecs.FindAsync(nv.CaLamViecId.Value);
            if (ca != null) return ca;
        }
        return await _db.CaLamViecs.OrderBy(c => c.Id).FirstOrDefaultAsync();
    }

    private static string? KiemTraGio(ChamCongAdminInput m)
    {
        if (m.GioVao != null && DateOnly.FromDateTime(m.GioVao.Value) != m.Ngay)
            return "Giờ vào phải nằm trong ngày chấm công.";
        if (m.GioRa != null && DateOnly.FromDateTime(m.GioRa.Value) != m.Ngay)
            return "Giờ ra phải nằm trong ngày chấm công.";
        if (m.GioRa != null && m.GioVao == null)
            return "Không thể có giờ ra khi chưa có giờ vào.";
        if (m.GioVao != null && m.GioRa != null && m.GioRa <= m.GioVao)
            return "Giờ ra phải sau giờ vào.";
        return null;
    }

    /// <summary>Tính lại số phút trễ / về sớm / số giờ làm / trạng thái theo ca làm việc.</summary>
    private static void TinhLai(ChamCong cc, CaLamViec? ca)
    {
        cc.SoPhutTre = 0;
        cc.SoPhutVeSom = 0;
        cc.SoGioLam = null;

        if (cc.GioVao != null && ca != null)
        {
            var gio = TimeOnly.FromDateTime(cc.GioVao.Value);
            if (gio > ca.GioBatDau.AddMinutes(ca.PhutChoPhepTre))
                cc.SoPhutTre = (int)(gio - ca.GioBatDau).TotalMinutes;
        }
        if (cc.GioRa != null && ca != null)
        {
            var gio = TimeOnly.FromDateTime(cc.GioRa.Value);
            if (gio < ca.GioKetThuc)
                cc.SoPhutVeSom = (int)(ca.GioKetThuc - gio).TotalMinutes;
        }
        if (cc.GioVao != null && cc.GioRa != null && cc.GioRa > cc.GioVao)
            cc.SoGioLam = Math.Round((cc.GioRa.Value - cc.GioVao.Value).TotalHours, 2);

        cc.TrangThai = cc.GioVao == null ? "Vang"
            : cc.SoPhutTre > 0 && cc.SoPhutVeSom > 0 ? "DiTreVeSom"
            : cc.SoPhutTre > 0 ? "DiTre"
            : cc.SoPhutVeSom > 0 ? "VeSom"
            : "DungGio";
    }
}
