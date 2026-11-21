using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Order
{
    public class UpdateOrderRequest
    {
        [Required]
        public Guid Id { get; set; }

        [Required]
        public Guid ClientId { get; set; }

        public Guid? GarmentModelId { get; set; }

        public Guid? MeasurementSetId { get; set; }

        [StringLength(2000)]
        public string? Description { get; set; }

        [Range(1, 1000)]
        public int Quantity { get; set; } = 1;

        [Range(0, 1000000000)]
        public decimal TotalPrice { get; set; }

        [Required]
        public DateOnly DeliveryDate { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }
    }
}
