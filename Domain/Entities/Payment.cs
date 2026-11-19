using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
    public class Payment : BaseEntity
    {
        public Guid AtelierId { get; set; }

        public Guid OrderId { get; set; }

        public decimal Amount { get; set; }

        public DateTimeOffset PaidAtUtc { get; set; }

        public string? Note { get; set; }

        public Atelier Atelier { get; set; } = null!;

        public Order Order { get; set; } = null!;
    }
}
