using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.Payment;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Entities;
using sutura_api.Infrastructure.Data;

namespace sutura_api.Application.Services
{
    // Paiements imbriqués dans une commande : chaque requête est filtrée par
    // l'atelier du token JWT et par la commande de l'URL.
    public class PaymentService : IPaymentService
    {
        private readonly SuturaDbContext _db;

        public PaymentService(SuturaDbContext db)
        {
            _db = db;
        }

        public async Task<List<PaymentResponse>?> ListAsync(Guid orderId, Guid atelierId)
        {
            if (!await OrderExistsAsync(orderId, atelierId))
                return null;

            var payments = await _db.Payments
                .Where(p => p.OrderId == orderId && p.AtelierId == atelierId)
                .OrderByDescending(p => p.PaidAtUtc)
                .ToListAsync();

            return payments.Select(ToResponse).ToList();
        }

        public async Task<PaymentResponse?> GetByIdAsync(Guid orderId, Guid paymentId, Guid atelierId)
        {
            var payment = await _db.Payments.FirstOrDefaultAsync(p =>
                p.Id == paymentId &&
                p.OrderId == orderId &&
                p.AtelierId == atelierId);

            return payment == null ? null : ToResponse(payment);
        }

        public async Task<PaymentResponse?> CreateAsync(
            PaymentRequest request,
            Guid orderId,
            Guid atelierId)
        {
            if (!await OrderExistsAsync(orderId, atelierId))
                return null;

            var now = DateTime.UtcNow;

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                AtelierId = atelierId,
                OrderId = orderId,
                Amount = request.Amount,
                PaidAtUtc = request.PaidAtUtc,
                Note = request.Note,
                CreatedAt = now,
                UpdatedAt = now
            };

            _db.Payments.Add(payment);
            await _db.SaveChangesAsync();

            return ToResponse(payment);
        }

        public async Task<PaymentResponse?> UpdateAsync(
            UpdatePaymentRequest request,
            Guid orderId,
            Guid atelierId)
        {
            // L'Id du corps est déjà vérifié par le contrôleur ; le filtre
            // OrderId/AtelierId empêche toute modification hors de la commande.
            var payment = await _db.Payments.FirstOrDefaultAsync(p =>
                p.Id == request.Id &&
                p.OrderId == orderId &&
                p.AtelierId == atelierId);

            if (payment == null)
                return null;

            payment.Amount = request.Amount;
            payment.PaidAtUtc = request.PaidAtUtc;
            payment.Note = request.Note;
            payment.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return ToResponse(payment);
        }

        private Task<bool> OrderExistsAsync(Guid orderId, Guid atelierId) =>
            _db.Orders.AnyAsync(o => o.Id == orderId && o.AtelierId == atelierId);

        private static PaymentResponse ToResponse(Payment payment) => new PaymentResponse
        {
            Id = payment.Id,
            OrderId = payment.OrderId,
            Amount = payment.Amount,
            CreatedAt = payment.CreatedAt,
            UpdatedAt = payment.UpdatedAt,
            PaidAtUtc = payment.PaidAtUtc,
            Note = payment.Note
        };
    }
}
