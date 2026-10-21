using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TranMinhKhoi.Models;

namespace TranMinhKhoi.Services;

public class JwtService
{
    private readonly IConfiguration _cfg;

    public JwtService(IConfiguration cfg) => _cfg = cfg;

    public (string Token, DateTime HetHan) TaoToken(AppUser user, IEnumerable<string> roles)
    {
        var jwt = _cfg.GetSection("JWTKey");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Secret"]!));
        var gio = double.Parse(jwt["TokenExpiryTimeInHour"] ?? "8", CultureInfo.InvariantCulture);
        var hetHan = DateTime.UtcNow.AddHours(gio);

        var claims = new List<Claim>
        {
            new("uid", user.Id),
            new(JwtRegisteredClaimNames.Sub, user.UserName ?? string.Empty),
            new("unique_name", user.UserName ?? string.Empty),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new("name", user.HoTen),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        // Claim tên "role" (ngắn gọn, dễ đọc bằng jwt_decoder bên Flutter)
        claims.AddRange(roles.Select(r => new Claim("role", r)));

        var token = new JwtSecurityToken(
            issuer: jwt["ValidIssuer"],
            audience: jwt["ValidAudience"],
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: hetHan,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return (new JwtSecurityTokenHandler().WriteToken(token), hetHan);
    }
}
