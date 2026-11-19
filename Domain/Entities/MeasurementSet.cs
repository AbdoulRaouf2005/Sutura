

using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class MeasurementSet : BaseEntity
    {
        public Guid AtelierId { get; set; }

        public Guid ClientId { get; set; }

        public string GarmentType { get; set; } = string.Empty;

        public string? Notes { get; set; }

        public DateOnly MeasuredAt { get; set; }

        public Atelier Atelier { get; set; } = null!;

        public Client Client { get; set; } = null!;

        public ICollection<Measurement> Measurements { get; set; }
            = new List<Measurement>();

        public ICollection<Order> Orders { get; set; }
            = new List<Order>();

    }
}
