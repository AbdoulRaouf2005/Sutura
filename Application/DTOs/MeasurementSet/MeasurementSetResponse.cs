using sutura_api.Application.DTOs.Measurement;

namespace sutura_api.Application.DTOs.MeasurementSet
{
    public class MeasurementSetResponse
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public string? Notes { get; set; }
        public DateOnly MeasuredAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<MeasurementResponse> Measurements { get; set; } = new List<MeasurementResponse>();
    }
}
