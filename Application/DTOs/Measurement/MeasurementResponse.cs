namespace sutura_api.Application.DTOs.Measurement
{
    public class MeasurementResponse
    {
        public Guid Id { get; set; }
        public Guid MeasurementSetId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Value { get; set; }
        public string Unit { get; set; } = "cm";
    }
}
