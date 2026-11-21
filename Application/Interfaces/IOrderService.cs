using sutura_api.Application.DTOs.Order;
using sutura_api.Domain.Enums;

namespace sutura_api.Application.Interfaces
{
    // Contrat des commandes de l'atelier. L'atelierId provient toujours du
    // claim JWT ; les références (client, modèle, mensurations) sont validées côté serveur.
    public interface IOrderService
    {
        // Retourne null si le client, le modèle ou les mensurations n'appartiennent
        // pas à l'atelier.
        Task<OrderResponse?> CreateAsync(OrderRequest request, Guid atelierId);

        Task<OrderResponse?> UpdateAsync(UpdateOrderRequest request, Guid atelierId);

        Task<OrderPagedResponse> ListAsync(
            Guid atelierId,
            int page,
            int pageSize,
            OrderStatus? status,
            Guid? clientId,
            DateOnly? fromDeliveryDate,
            DateOnly? toDeliveryDate,
            string? search);

        Task<OrderResponse?> GetByIdAsync(Guid orderId, Guid atelierId);

        // Changement de statut libre ; null si la commande est introuvable.
        Task<OrderResponse?> UpdateStatusAsync(Guid orderId, OrderStatus status, Guid atelierId);

        // Commandes à livrer dans les N prochains jours, hors Delivered/Cancelled.
        Task<List<OrderResponse>> ListDueSoonAsync(Guid atelierId, int days);
    }
}
