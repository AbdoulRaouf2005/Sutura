using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Payment
{
    public class PaymentRequest
    {
        [Required]
        public Guid OrderId { get; set; }

        [Range(0, 1000000000)]
        public decimal Amount { get; set; }

        public DateTimeOffset PaidAtUtc { get; set; }

        [StringLength(1000)]
        public string? Note { get; set; }
    }
}
