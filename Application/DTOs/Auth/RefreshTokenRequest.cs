using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Auth
{
    public class RefreshTokenRequest
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}