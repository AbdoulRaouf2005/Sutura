using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Atelier
{
    public class UpdateAtelierRequest
    {
        [Required]
        [StringLength(150)]
        public string Name { get; set; } = string.Empty;
    }
}
