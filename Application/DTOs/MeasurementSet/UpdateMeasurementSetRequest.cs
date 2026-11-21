using System.ComponentModel.DataAnnotations;
using sutura_api.Application.DTOs.Measurement;

namespace sutura_api.Application.DTOs.MeasurementSet
{
    public class UpdateMeasurementSetRequest
    {
        [Required]
        public Guid Id { get; set; }

        [Required]
        public Guid ClientId { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }

        [Required]
        public DateOnly MeasuredAt { get; set; }

        public List<MeasurementRequest> Measurements { get; set; } = new List<MeasurementRequest>();
    }
}
