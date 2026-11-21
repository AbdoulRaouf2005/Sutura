namespace sutura_api.Application.DTOs.Payment
{
    public class PaymentResponse
    {
        public Guid Id { get; set; }
        public Guid OrderId { get; set; }
        public decimal Amount { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTimeOffset PaidAtUtc { get; set; }
        public string? Note { get; set; }
    }
}
