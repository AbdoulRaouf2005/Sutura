using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Measurement
{
    public class MeasurementRequest
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Range(0, 1000000000)]
        public decimal Value { get; set; }

        [Required]
        [StringLength(10)]
        public string Unit { get; set; } = "cm";
    }
}
