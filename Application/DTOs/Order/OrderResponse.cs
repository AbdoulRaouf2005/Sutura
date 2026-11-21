using sutura_api.Domain.Enums;

namespace sutura_api.Application.DTOs.Order
{
    public class OrderResponse
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }
        public Guid? GarmentModelId { get; set; }
        public Guid? MeasurementSetId { get; set; }
        public string? ModelNameSnapshot { get; set; }
        public string? ModelImageSnapshotReference { get; set; }
        public string? Description { get; set; }
        public int Quantity { get; set; }
        public decimal TotalPrice { get; set; }
        public DateOnly DeliveryDate { get; set; }
        public OrderStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? Notes { get; set; }
    }
}
