using sutura_api.Application.DTOs.Auth;

public interface ISessionService
{
    Task<AuthResponse> RefreshAsync(
        RefreshTokenRequest request);

    Task RevokeSessionAsync(
        LogoutRequest request,
        string userId);

    Task RevokeAllSessionsAsync(string userId);
}