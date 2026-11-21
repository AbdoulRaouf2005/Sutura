using sutura_api.Domain.Commun;
using sutura_api.Domain.Enums;


namespace sutura_api.Domain.Entities
{
    public class Order 
    {
        public Guid Id { get; set; }
        public Guid AtelierId { get; set; }

        public Guid ClientId { get; set; }

        public Guid? GarmentModelId { get; set; }

        public Guid? MeasurementSetId { get; set; }

        // Instantané du modèle au moment de la commande
        public string? ModelNameSnapshot { get; set; }

        public string? ModelImageSnapshotReference { get; set; }

        public string? Description { get; set; }

        public int Quantity { get; set; } = 1;

        public decimal TotalPrice { get; set; }

        public DateOnly DeliveryDate { get; set; }

        public OrderStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public string? Notes { get; set; }

        public Atelier Atelier { get; set; } = null!;

        public Client Client { get; set; } = null!;

        public GarmentModel? GarmentModel { get; set; }

        public MeasurementSet? MeasurementSet { get; set; }

        public ICollection<Payment> Payments { get; set; }
            = new List<Payment>();
    }

}
