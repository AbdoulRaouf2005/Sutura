using sutura_api.Application.DTOs.Payment;

namespace sutura_api.Application.Interfaces
{
    // Paiements d'une commande. L'atelierId provient du claim JWT :
    // la commande et le paiement doivent appartenir à cet atelier.
    public interface IPaymentService
    {
        // Liste des paiements d'une commande ; null si la commande est introuvable.
        Task<List<PaymentResponse>?> ListAsync(Guid orderId, Guid atelierId);

        // Détail d'un paiement ; null si la commande ou le paiement est introuvable.
        Task<PaymentResponse?> GetByIdAsync(Guid orderId, Guid paymentId, Guid atelierId);

        // Crée un paiement sur la commande ; null si la commande est introuvable.
        Task<PaymentResponse?> CreateAsync(PaymentRequest request, Guid orderId, Guid atelierId);

        // Modifie un paiement ; null si la commande ou le paiement est introuvable.
        Task<PaymentResponse?> UpdateAsync(UpdatePaymentRequest request, Guid orderId, Guid atelierId);
    }
}
