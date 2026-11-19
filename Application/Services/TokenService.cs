
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using sutura_api.Api.Options;
using sutura_api.Domain.Entities;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace sutura_api.Application.Services;
public class TokenService : ITokenService
{
    private readonly JwtSettings _settings;
    public TokenService(IOptions<JwtSettings> settings)
    {
        _settings = settings.Value;
    }
    public string GenerateAccessToken(ApplicationUser user,Guid atelierId)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub,user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email!),
            new Claim("atelierId",atelierId.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti,Guid.NewGuid().ToString()),
        };
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.SecretKey));

        var credentials = new SigningCredentials(key , SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience : _settings.Audience,
            claims : claims,
            expires : DateTime.UtcNow.AddMinutes(_settings.AccessTokenExpirationMinutes),
            signingCredentials : credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
    public string GenerateRefreshToken()
    {
        var randomBytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(randomBytes);
    }

    public string HashRefreshToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}