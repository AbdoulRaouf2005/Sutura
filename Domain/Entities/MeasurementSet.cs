

using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class MeasurementSet 
    {
        public Guid Id { get; set; }
        public Guid AtelierId { get; set; }

        public Guid ClientId { get; set; }

        public string? Notes { get; set; }

        public DateOnly MeasuredAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set;}

        public Client Client { get; set; } = null!;

        public ICollection<Measurement> Measurements { get; set; }
            = new List<Measurement>();

        public ICollection<Order> Orders { get; set; }
            = new List<Order>();

    }
}
