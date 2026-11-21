using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Payment
{
    public class UpdatePaymentRequest
    {
        // Identifiants répétés dans le corps et vérifiés par le contrôleur.
        [Required]
        public Guid Id { get; set; }

        [Required]
        public Guid OrderId { get; set; }

        [Range(0, 1000000000)]
        public decimal Amount { get; set; }

        public DateTimeOffset PaidAtUtc { get; set; }

        [StringLength(1000)]
        public string? Note { get; set; }
    }
}
