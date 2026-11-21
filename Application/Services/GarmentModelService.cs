using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.GarmentModel;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Entities;
using sutura_api.Infrastructure.Data;

namespace sutura_api.Application.Services
{
    // Catalogue des modèles : chaque requête est filtrée par l'atelier du token JWT.
    public class GarmentModelService : IGarmentModelService
    {
        private readonly SuturaDbContext _db;

        public GarmentModelService(SuturaDbContext db)
        {
            _db = db;
        }

        public async Task<GarmentModelResponse> CreateAsync(
            GarmentModelRequest request,
            Guid atelierId)
        {
            var now = DateTime.UtcNow;

            var model = new GarmentModel
            {
                Id = Guid.NewGuid(),
                AtelierId = atelierId,
                Name = request.Name,
                Category = request.Category,
                Description = request.Description,
                ImageReference = request.ImageReference,
                CreatedAt = now,
                UpdatedAt = now,
                IsArchived = false
            };

            _db.Garments.Add(model);
            await _db.SaveChangesAsync();

            return ToResponse(model);
        }

        public async Task<GarmentModelResponse?> UpdateAsync(
            UpdateGarmentModelRequest request,
            Guid atelierId)
        {
            var model = await _db.Garments
                .FirstOrDefaultAsync(m => m.Id == request.Id && m.AtelierId == atelierId);

            if (model == null)
                return null;

            model.Name = request.Name;
            model.Category = request.Category;
            model.Description = request.Description;
            model.ImageReference = request.ImageReference;
            model.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return ToResponse(model);
        }

        public async Task<GarmentModelPagedResponse> ListAsync(
            Guid atelierId,
            int page,
            int pageSize,
            string? search)
        {
            var query = _db.Garments
                .Where(m => m.AtelierId == atelierId && !m.IsArchived);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();

                query = query.Where(m =>
                    m.Name.Contains(term) ||
                    (m.Category != null && m.Category.Contains(term)) ||
                    (m.Description != null && m.Description.Contains(term)));
            }

            var totalCount = await query.CountAsync();

            var models = await query
                .OrderBy(m => m.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new GarmentModelPagedResponse
            {
                Items = models.Select(ToResponse).ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            };
        }

        public async Task<GarmentModelResponse?> GetByIdAsync(Guid modelId, Guid atelierId)
        {
            var model = await _db.Garments
                .FirstOrDefaultAsync(m => m.Id == modelId && m.AtelierId == atelierId);

            return model == null ? null : ToResponse(model);
        }

        public async Task<bool> ArchiveAsync(Guid modelId, Guid atelierId)
        {
            var model = await _db.Garments
                .FirstOrDefaultAsync(m => m.Id == modelId && m.AtelierId == atelierId);

            if (model == null)
                return false;

            model.IsArchived = true;
            model.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return true;
        }

        private static GarmentModelResponse ToResponse(GarmentModel model) => new GarmentModelResponse
        {
            Id = model.Id,
            Name = model.Name,
            Category = model.Category,
            Description = model.Description,
            ImageReference = model.ImageReference,
            CreatedAt = model.CreatedAt,
            UpdatedAt = model.UpdatedAt,
            IsArchived = model.IsArchived
        };
    }
}
