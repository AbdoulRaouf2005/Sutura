using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class GarmentModel 
    {
        public Guid Id { get; set; }
        public Guid AtelierId { get; set; }

        public string Name { get; set; } = string.Empty;

        public string? Category { get; set; }

        public string? Description { get; set; }

        public string? ImageReference { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime UpdatedAt { get; set; }

        public bool IsArchived { get; set; } = false;

        public Atelier Atelier { get; set; } = null!;

        // Relations
        public ICollection<Order> Orders { get; set; }
            = new List<Order>();
    }
}
