using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TranMinhKhoi.Data;
using TranMinhKhoi.DTOs;
using TranMinhKhoi.Models;
using TranMinhKhoi.Services;

namespace TranMinhKhoi.Controllers;

/// <summary>
/// Đăng ký qua email (xác thực OTP) và đăng nhập 2 bước: tên đăng nhập + mật khẩu → OTP email → JWT.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _um;
    private readonly ApplicationDbContext _db;
    private readonly OtpService _otp;
    private readonly IEmailService _mail;
    private readonly JwtService _jwt;
    private readonly IConfiguration _cfg;
    private readonly ILogger<AuthController> _log;

    public AuthController(UserManager<AppUser> um, ApplicationDbContext db, OtpService otp,
        IEmailService mail, JwtService jwt, IConfiguration cfg, ILogger<AuthController> log)
    {
        _um = um;
        _db = db;
        _otp = otp;
        _mail = mail;
        _jwt = jwt;
        _cfg = cfg;
        _log = log;
    }

    private bool TraOtpTrongPhanHoi => _cfg.GetValue("Otp:ReturnOtpInResponse", false);

    // ============ 1. ĐĂNG KÝ QUA EMAIL ============
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] DangKyRequest m)
    {
        if (await _um.FindByNameAsync(m.Username) != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại." });

        var cu = await _um.FindByEmailAsync(m.Email);
        if (cu != null)
        {
            if (cu.EmailConfirmed)
                return BadRequest(new { status = false, message = "Email này đã được sử dụng." });
            await _um.DeleteAsync(cu); // email đăng ký trước đó nhưng chưa xác thực → cho đăng ký lại
        }

        var user = new AppUser
        {
            UserName = m.Username.Trim(),
            Email = m.Email.Trim(),
            HoTen = m.HoTen.Trim(),
            PhoneNumber = m.SoDienThoai,
            EmailConfirmed = false
        };
        var kq = await _um.CreateAsync(user, m.Password);
        if (!kq.Succeeded)
            return BadRequest(new { status = false, message = string.Join(" ", kq.Errors.Select(e => e.Description)) });

        await _um.AddToRoleAsync(user, AppRoles.NhanVien); // đăng ký công khai chỉ được vai trò Nhân viên

        var code = await _otp.TaoAsync(user.Id, MucDichOtp.DangKy);
        var daGui = await GuiOtpAsync(user, code, MucDichOtp.DangKy);
        if (!daGui && !TraOtpTrongPhanHoi)
            return StatusCode(502, new { status = false, message = "Không gửi được email xác thực. Vui lòng thử lại sau." });

        return Ok(new
        {
            status = true,
            message = $"Đăng ký thành công. Mã xác thực đã được gửi tới {user.Email}.",
            requireOtp = true,
            username = user.UserName,
            otpExpiresInSeconds = _otp.HetHanPhut * 60,
            devOtp = TraOtpTrongPhanHoi ? code : null
        });
    }

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] XacThucEmailRequest m)
    {
        var user = await _um.FindByNameAsync(m.Username);
        if (user == null)
            return BadRequest(new { status = false, message = "Tài khoản không tồn tại." });
        if (user.EmailConfirmed)
            return Ok(new { status = true, message = "Email đã được xác thực trước đó." });

        var (ok, msg) = await _otp.KiemTraAsync(user.Id, MucDichOtp.DangKy, m.Otp);
        if (!ok) return BadRequest(new { status = false, message = msg });

        user.EmailConfirmed = true;
        await _um.UpdateAsync(user);

        // Tự liên kết với hồ sơ nhân viên nếu quản trị đã tạo sẵn hồ sơ với cùng email
        var nv = await _db.NhanViens.FirstOrDefaultAsync(n => n.Email == user.Email && n.UserId == null);
        if (nv != null)
        {
            nv.UserId = user.Id;
            await _db.SaveChangesAsync();
        }

        return Ok(new { status = true, message = "Xác thực email thành công. Bạn có thể đăng nhập." });
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] GuiLaiOtpRequest m)
    {
        if (m.MucDich != MucDichOtp.DangKy && m.MucDich != MucDichOtp.DangNhap)
            return BadRequest(new { status = false, message = "Mục đích OTP không hợp lệ (DangKy hoặc DangNhap)." });

        var user = await TimTaiKhoanAsync(m.Username);
        // Trả lời giống nhau dù tài khoản có tồn tại hay không (tránh dò tên đăng nhập)
        var chung = Ok(new { status = true, message = "Nếu tài khoản hợp lệ, mã OTP mới đã được gửi tới email.", otpExpiresInSeconds = _otp.HetHanPhut * 60 });
        if (user == null) return chung;

        if (m.MucDich == MucDichOtp.DangKy && user.EmailConfirmed) return chung;

        var cho = await _otp.GiayConPhaiChoAsync(user.Id, m.MucDich);
        if (cho > 0)
            return StatusCode(429, new { status = false, message = $"Vui lòng chờ {cho} giây rồi gửi lại mã." });

        var code = await _otp.TaoAsync(user.Id, m.MucDich);
        await GuiOtpAsync(user, code, m.MucDich);
        return Ok(new
        {
            status = true,
            message = "Nếu tài khoản hợp lệ, mã OTP mới đã được gửi tới email.",
            otpExpiresInSeconds = _otp.HetHanPhut * 60,
            devOtp = TraOtpTrongPhanHoi ? code : null
        });
    }

    // ============ 2. ĐĂNG NHẬP: BƯỚC 1 - TÊN ĐĂNG NHẬP + MẬT KHẨU ============
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] DangNhapRequest m)
    {
        var user = await TimTaiKhoanAsync(m.Username);
        if (user == null)
            return Unauthorized(new { status = false, message = "Sai tên đăng nhập hoặc mật khẩu." });

        if (await _um.IsLockedOutAsync(user))
            return StatusCode(423, new { status = false, message = "Tài khoản tạm khóa do nhập sai mật khẩu nhiều lần. Vui lòng thử lại sau 5 phút." });

        if (!await _um.CheckPasswordAsync(user, m.Password))
        {
            await _um.AccessFailedAsync(user);
            return Unauthorized(new { status = false, message = "Sai tên đăng nhập hoặc mật khẩu." });
        }
        await _um.ResetAccessFailedCountAsync(user);

        if (!user.HoatDong)
            return StatusCode(403, new { status = false, message = "Tài khoản đã bị vô hiệu hóa. Hãy liên hệ quản trị viên." });

        if (!user.EmailConfirmed)
        {
            var maXacThuc = await _otp.TaoAsync(user.Id, MucDichOtp.DangKy);
            await GuiOtpAsync(user, maXacThuc, MucDichOtp.DangKy);
            return StatusCode(403, new
            {
                status = false,
                requireEmailVerify = true,
                username = user.UserName,
                message = "Email chưa được xác thực. Mã xác thực mới đã được gửi, hãy gọi verify-email.",
                devOtp = TraOtpTrongPhanHoi ? maXacThuc : null
            });
        }

        var code = await _otp.TaoAsync(user.Id, MucDichOtp.DangNhap);
        var daGui = await GuiOtpAsync(user, code, MucDichOtp.DangNhap);
        if (!daGui && !TraOtpTrongPhanHoi)
            return StatusCode(502, new { status = false, message = "Không gửi được email OTP. Vui lòng thử lại sau." });

        return Ok(new
        {
            status = true,
            requireOtp = true,
            username = user.UserName,
            message = $"Mật khẩu đúng. Mã OTP đã được gửi tới {MaHoaEmail(user.Email)}.",
            otpExpiresInSeconds = _otp.HetHanPhut * 60,
            devOtp = TraOtpTrongPhanHoi ? code : null
        });
    }

    // ============ 2. ĐĂNG NHẬP: BƯỚC 2 - OTP → JWT ============
    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] XacThucOtpRequest m)
    {
        var user = await TimTaiKhoanAsync(m.Username);
        if (user == null)
            return Unauthorized(new { status = false, message = "Tài khoản không tồn tại." });
        if (!user.HoatDong)
            return StatusCode(403, new { status = false, message = "Tài khoản đã bị vô hiệu hóa." });

        var (ok, msg) = await _otp.KiemTraAsync(user.Id, MucDichOtp.DangNhap, m.Otp);
        if (!ok) return Unauthorized(new { status = false, message = msg });

        // Ràng buộc thiết bị ở lần đăng nhập đầu tiên
        if (!string.IsNullOrWhiteSpace(m.DeviceId) && string.IsNullOrEmpty(user.DeviceId))
        {
            user.DeviceId = m.DeviceId.Trim();
            await _um.UpdateAsync(user);
        }

        var roles = await _um.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? AppRoles.NhanVien;
        var (token, hetHan) = _jwt.TaoToken(user, roles);
        var nhanVienId = await _db.NhanViens.Where(n => n.UserId == user.Id).Select(n => (int?)n.Id).FirstOrDefaultAsync();

        return Ok(new
        {
            status = true,
            message = "Đăng nhập thành công.",
            token,
            expiresAt = hetHan,
            role,
            redirect = DieuHuong(role),
            nhanVienId,
            user = new { id = user.Id, username = user.UserName, email = user.Email, hoTen = user.HoTen }
        });
    }

    // ============ 3. THÔNG TIN TÀI KHOẢN ============
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var user = await _um.FindByIdAsync(User.GetUserId() ?? string.Empty);
        if (user == null) return Unauthorized();

        var roles = await _um.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? AppRoles.NhanVien;
        var nv = await _db.NhanViens.Where(n => n.UserId == user.Id)
            .Select(n => new { n.Id, n.MaNV, n.HoTen, n.ChucVu }).FirstOrDefaultAsync();

        return Ok(new
        {
            status = true,
            id = user.Id,
            username = user.UserName,
            email = user.Email,
            hoTen = user.HoTen,
            soDienThoai = user.PhoneNumber,
            role,
            redirect = DieuHuong(role),
            nhanVien = nv
        });
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] DoiMatKhauRequest m)
    {
        var user = await _um.FindByIdAsync(User.GetUserId() ?? string.Empty);
        if (user == null) return Unauthorized();

        var kq = await _um.ChangePasswordAsync(user, m.MatKhauCu, m.MatKhauMoi);
        if (!kq.Succeeded)
            return BadRequest(new { status = false, message = string.Join(" ", kq.Errors.Select(e => e.Description)) });
        return Ok(new { status = true, message = "Đổi mật khẩu thành công." });
    }

    // ============ HÀM PHỤ ============
    private async Task<AppUser?> TimTaiKhoanAsync(string tenHoacEmail)
    {
        var ten = tenHoacEmail.Trim();
        return await _um.FindByNameAsync(ten) ?? await _um.FindByEmailAsync(ten);
    }

    /// <summary>Gợi ý màn hình cần mở trên ứng dụng theo vai trò.</summary>
    private static string DieuHuong(string role) => role switch
    {
        AppRoles.Admin => "admin",
        AppRoles.QuanLy => "quanly",
        _ => "nhanvien"
    };

    private static string MaHoaEmail(string? email)
    {
        if (string.IsNullOrEmpty(email) || !email.Contains('@')) return "email của bạn";
        var parts = email.Split('@');
        var ten = parts[0];
        var hien = ten.Length <= 2 ? ten[..1] : ten[..2];
        return $"{hien}***@{parts[1]}";
    }

    private async Task<bool> GuiOtpAsync(AppUser user, string code, string mucDich)
    {
        var tieuDe = mucDich == MucDichOtp.DangKy ? "Xác thực email đăng ký - Chấm công" : "Mã đăng nhập - Chấm công";
        var hanh = mucDich == MucDichOtp.DangKy ? "xác thực email đăng ký tài khoản" : "đăng nhập";
        var html = $"""
            <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:24px;border:1px solid #e5e7eb;border-radius:12px">
              <h2 style="color:#1d4ed8;margin-top:0">Ứng dụng Chấm công</h2>
              <p>Xin chào <b>{System.Net.WebUtility.HtmlEncode(user.HoTen)}</b>,</p>
              <p>Mã OTP để {hanh} của bạn là:</p>
              <p style="font-size:32px;letter-spacing:8px;font-weight:bold;text-align:center;background:#eff6ff;padding:12px;border-radius:8px">{code}</p>
              <p>Mã có hiệu lực trong {_otp.HetHanPhut} phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.</p>
            </div>
            """;
        try
        {
            await _mail.GuiAsync(user.Email!, tieuDe, html);
            return true;
        }
        catch (Exception ex)
        {
            _log.LogError(ex, "Gửi email OTP thất bại tới {Email}", user.Email);
            return false;
        }
    }
}
