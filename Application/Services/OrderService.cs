using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.Order;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Entities;
using sutura_api.Domain.Enums;
using sutura_api.Infrastructure.Data;

namespace sutura_api.Application.Services
{
    // Commandes de l'atelier : chaque requête est filtrée par l'atelier du token JWT.
    // Le jeu de mensurations utilisé est le jeu courant du client, sans copie.
    public class OrderService : IOrderService
    {
        private readonly SuturaDbContext _db;

        public OrderService(SuturaDbContext db)
        {
            _db = db;
        }

        public async Task<OrderResponse?> CreateAsync(OrderRequest request, Guid atelierId)
        {
            if (!await ReferencesValidAsync(
                    atelierId,
                    request.ClientId,
                    request.GarmentModelId,
                    request.MeasurementSetId))
                return null;

            var measurementSetId = await ResolveMeasurementSetAsync(
                request.ClientId,
                atelierId,
                request.MeasurementSetId);

            var snapshots = await ModelSnapshotsAsync(request.GarmentModelId, atelierId);
            var now = DateTime.UtcNow;

            var order = new Order
            {
                Id = Guid.NewGuid(),
                AtelierId = atelierId,
                ClientId = request.ClientId,
                GarmentModelId = request.GarmentModelId,
                MeasurementSetId = measurementSetId,
                ModelNameSnapshot = snapshots.Name,
                ModelImageSnapshotReference = snapshots.ImageReference,
                Description = request.Description,
                Quantity = request.Quantity,
                TotalPrice = request.TotalPrice,
                DeliveryDate = request.DeliveryDate,
                Status = OrderStatus.ToStart,
                CreatedAt = now,
                UpdatedAt = now,
                Notes = request.Notes
            };

            _db.Orders.Add(order);
            await _db.SaveChangesAsync();

            return ToResponse(order);
        }

        public async Task<OrderResponse?> UpdateAsync(UpdateOrderRequest request, Guid atelierId)
        {
            var order = await _db.Orders
                .FirstOrDefaultAsync(o => o.Id == request.Id && o.AtelierId == atelierId);

            if (order == null)
                return null;

            if (!await ReferencesValidAsync(
                    atelierId,
                    request.ClientId,
                    request.GarmentModelId,
                    request.MeasurementSetId))
                return null;

            var measurementSetId = await ResolveMeasurementSetAsync(
                request.ClientId,
                atelierId,
                request.MeasurementSetId);

            var snapshots = await ModelSnapshotsAsync(request.GarmentModelId, atelierId);

            order.ClientId = request.ClientId;
            order.GarmentModelId = request.GarmentModelId;
            order.MeasurementSetId = measurementSetId;
            order.ModelNameSnapshot = snapshots.Name;
            order.ModelImageSnapshotReference = snapshots.ImageReference;
            order.Description = request.Description;
            order.Quantity = request.Quantity;
            order.TotalPrice = request.TotalPrice;
            order.DeliveryDate = request.DeliveryDate;
            order.Notes = request.Notes;
            order.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return ToResponse(order);
        }

        public async Task<OrderPagedResponse> ListAsync(
            Guid atelierId,
            int page,
            int pageSize,
            OrderStatus? status,
            Guid? clientId,
            DateOnly? fromDeliveryDate,
            DateOnly? toDeliveryDate,
            string? search)
        {
            var query = _db.Orders.Where(o => o.AtelierId == atelierId);

            if (status.HasValue)
                query = query.Where(o => o.Status == status.Value);

            if (clientId.HasValue)
                query = query.Where(o => o.ClientId == clientId.Value);

            if (fromDeliveryDate.HasValue)
                query = query.Where(o => o.DeliveryDate >= fromDeliveryDate.Value);

            if (toDeliveryDate.HasValue)
                query = query.Where(o => o.DeliveryDate <= toDeliveryDate.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();

                query = query.Where(o =>
                    o.Client.FullName.Contains(term) ||
                    (o.Description != null && o.Description.Contains(term)) ||
                    (o.Notes != null && o.Notes.Contains(term)) ||
                    (o.ModelNameSnapshot != null && o.ModelNameSnapshot.Contains(term)));
            }

            var totalCount = await query.CountAsync();

            var orders = await query
                .OrderByDescending(o => o.DeliveryDate)
                .ThenByDescending(o => o.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new OrderPagedResponse
            {
                Items = orders.Select(ToResponse).ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            };
        }

        public async Task<OrderResponse?> GetByIdAsync(Guid orderId, Guid atelierId)
        {
            var order = await _db.Orders
                .FirstOrDefaultAsync(o => o.Id == orderId && o.AtelierId == atelierId);

            return order == null ? null : ToResponse(order);
        }

        public async Task<OrderResponse?> UpdateStatusAsync(
            Guid orderId,
            OrderStatus status,
            Guid atelierId)
        {
            var order = await _db.Orders
                .FirstOrDefaultAsync(o => o.Id == orderId && o.AtelierId == atelierId);

            if (order == null)
                return null;

            order.Status = status;
            order.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return ToResponse(order);
        }

        public async Task<List<OrderResponse>> ListDueSoonAsync(Guid atelierId, int days)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var limit = today.AddDays(days);

            var orders = await _db.Orders
                .Where(o =>
                    o.AtelierId == atelierId &&
                    o.DeliveryDate >= today &&
                    o.DeliveryDate <= limit &&
                    o.Status != OrderStatus.Delivered &&
                    o.Status != OrderStatus.Cancelled)
                .OrderBy(o => o.DeliveryDate)
                .ToListAsync();

            return orders.Select(ToResponse).ToList();
        }

        private async Task<bool> ReferencesValidAsync(
            Guid atelierId,
            Guid clientId,
            Guid? garmentModelId,
            Guid? measurementSetId)
        {
            if (!await _db.Clients.AnyAsync(c => c.Id == clientId && c.AtelierId == atelierId))
                return false;

            if (garmentModelId.HasValue &&
                !await _db.Garments.AnyAsync(m => m.Id == garmentModelId.Value && m.AtelierId == atelierId))
                return false;

            if (measurementSetId.HasValue &&
                !await _db.MeasurementsSet.AnyAsync(s =>
                    s.Id == measurementSetId.Value &&
                    s.AtelierId == atelierId &&
                    s.ClientId == clientId))
                return false;

            return true;
        }

        private async Task<Guid?> ResolveMeasurementSetAsync(
            Guid clientId,
            Guid atelierId,
            Guid? requestedId)
        {
            if (requestedId.HasValue)
                return requestedId.Value;

            return await _db.MeasurementsSet
                .Where(s => s.ClientId == clientId && s.AtelierId == atelierId)
                .OrderByDescending(s => s.MeasuredAt)
                .ThenByDescending(s => s.CreatedAt)
                .Select(s => (Guid?)s.Id)
                .FirstOrDefaultAsync();
        }

        private async Task<(string? Name, string? ImageReference)> ModelSnapshotsAsync(
            Guid? garmentModelId,
            Guid atelierId)
        {
            if (!garmentModelId.HasValue)
                return (null, null);

            var model = await _db.Garments
                .AsNoTracking()
                .FirstOrDefaultAsync(m => m.Id == garmentModelId.Value && m.AtelierId == atelierId);

            return model == null ? (null, null) : (model.Name, model.ImageReference);
        }

        private static OrderResponse ToResponse(Order order) => new OrderResponse
        {
            Id = order.Id,
            ClientId = order.ClientId,
            GarmentModelId = order.GarmentModelId,
            MeasurementSetId = order.MeasurementSetId,
            ModelNameSnapshot = order.ModelNameSnapshot,
            ModelImageSnapshotReference = order.ModelImageSnapshotReference,
            Description = order.Description,
            Quantity = order.Quantity,
            TotalPrice = order.TotalPrice,
            DeliveryDate = order.DeliveryDate,
            Status = order.Status,
            CreatedAt = order.CreatedAt,
            UpdatedAt = order.UpdatedAt,
            Notes = order.Notes
        };
    }
}
