namespace sutura_api.Application.DTOs.Auth
{
    public class LogoutRequest
    {
        public string RefreshToken { get; set; } = string.Empty;
    }
}