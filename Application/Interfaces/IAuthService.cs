
using sutura_api.Application.DTOs.Auth;
using sutura_api.Domain.Entities;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(
        RegisterRequest request);

    Task<AuthResponse?> LoginAsync(
        LoginRequest request);

    Task<AuthResponse?> RefreshAsync(RefreshTokenRequest request);

    Task<bool> LogoutAsync(RefreshTokenRequest request);
}