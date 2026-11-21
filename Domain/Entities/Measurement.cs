using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class Measurement 
    {
        public Guid Id { get; set; }
        public Guid MeasurementSetId { get; set; }

        public string Name { get; set; } = string.Empty;

        public decimal Value { get; set; }

        public string Unit { get; set; } = "cm";

        public MeasurementSet MeasurementSet { get; set; } = null!;
    }
}
