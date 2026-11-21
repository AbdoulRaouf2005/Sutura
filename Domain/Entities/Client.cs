using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class Client 
    {
        public Guid Id { get; set; }
        public Guid AtelierId { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string? Phone { get; set; }

        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime UpdatedAt { get; set; }

        public bool IsArchived { get; set; } = false;

        public Atelier Atelier { get; set; } = null!;

        // Relations
        public ICollection<Order> Orders { get; set; }
            = new List<Order>();

        public ICollection<MeasurementSet> MeasurementSets { get; set; }
            = new List<MeasurementSet>();
    }
}
