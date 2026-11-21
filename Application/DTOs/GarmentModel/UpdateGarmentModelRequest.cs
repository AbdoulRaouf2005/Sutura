using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.GarmentModel
{
    public class UpdateGarmentModelRequest
    {
        [Required]
        public Guid Id { get; set; }

        [Required]
        [StringLength(150)]
        public string Name { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Category { get; set; }

        [StringLength(1000)]
        public string? Description { get; set; }

        [StringLength(500)]
        public string? ImageReference { get; set; }
    }
}
