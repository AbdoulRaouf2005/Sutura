using sutura_api.Domain.Entities;


public interface ITokenService
{
    string GenerateAccessToken(ApplicationUser user, Guid atelierId);
    string GenerateRefreshToken();
    string HashRefreshToken(string token);
}