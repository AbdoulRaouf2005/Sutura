using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Auth
{
    public class RegisterRequest
    {
 
        [Required]
        [StringLength(100, MinimumLength = 2)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [ MinLength(8)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [StringLength(150, MinimumLength = 2)]
        public string AtelierName { get; set; } = string.Empty;
    }
}

