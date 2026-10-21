using System.Net;
using System.Net.Mail;
using System.Text;

namespace TranMinhKhoi.Services;

public interface IEmailService
{
    Task GuiAsync(string den, string tieuDe, string noiDungHtml);
}

public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _cfg;
    private readonly ILogger<SmtpEmailService> _log;

    public SmtpEmailService(IConfiguration cfg, ILogger<SmtpEmailService> log)
    {
        _cfg = cfg;
        _log = log;
    }

    public async Task GuiAsync(string den, string tieuDe, string noiDungHtml)
    {
        var host = _cfg["Email:Host"];
        if (string.IsNullOrWhiteSpace(host))
        {
            // Chưa cấu hình SMTP: ghi ra console để vẫn chạy thử được khi phát triển.
            _log.LogWarning("[EMAIL chưa cấu hình SMTP] Đến: {To} | Tiêu đề: {Subject} | Nội dung: {Body}", den, tieuDe, noiDungHtml);
            return;
        }

        var user = _cfg["Email:User"];
        var from = string.IsNullOrWhiteSpace(_cfg["Email:From"]) ? user : _cfg["Email:From"];

        using var client = new SmtpClient(host, _cfg.GetValue("Email:Port", 587))
        {
            EnableSsl = _cfg.GetValue("Email:EnableSsl", true),
            Credentials = new NetworkCredential(user, _cfg["Email:Password"])
        };
        using var msg = new MailMessage(new MailAddress(from!, "Chấm công - TranMinhKhoi", Encoding.UTF8), new MailAddress(den))
        {
            Subject = tieuDe,
            Body = noiDungHtml,
            IsBodyHtml = true,
            SubjectEncoding = Encoding.UTF8,
            BodyEncoding = Encoding.UTF8
        };
        await client.SendMailAsync(msg);
    }
}
