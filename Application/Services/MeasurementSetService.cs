using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.Measurement;
using sutura_api.Application.DTOs.MeasurementSet;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Entities;
using sutura_api.Infrastructure.Data;

namespace sutura_api.Application.Services
{
    // Le jeu courant est le plus récent (MeasuredAt, puis CreatedAt).
    // Chaque requête est filtrée par l'atelier du token JWT.
    public class MeasurementSetService : IMeasurementSetService
    {
        private readonly SuturaDbContext _db;

        public MeasurementSetService(SuturaDbContext db)
        {
            _db = db;
        }

        public async Task<MeasurementSetResponse?> GetCurrentAsync(Guid clientId, Guid atelierId)
        {
            var set = await CurrentSets(clientId, atelierId)
                .Include(s => s.Measurements)
                .FirstOrDefaultAsync();

            return set == null ? null : ToResponse(set, set.Measurements);
        }

        public async Task<MeasurementSetResponse?> ReplaceCurrentAsync(
            MeasurementSetRequest request,
            Guid clientId,
            Guid atelierId)
        {
            var set = await CurrentSets(clientId, atelierId).FirstOrDefaultAsync();
            var now = DateTime.UtcNow;

            if (set == null)
            {
                var clientExists = await _db.Clients
                    .AnyAsync(c => c.Id == clientId && c.AtelierId == atelierId);

                if (!clientExists)
                    return null;

                set = new MeasurementSet
                {
                    Id = Guid.NewGuid(),
                    AtelierId = atelierId,
                    ClientId = clientId,
                    CreatedAt = now
                };

                _db.MeasurementsSet.Add(set);
            }
            else
            {
                await _db.Measurements
                    .Where(m => m.MeasurementSetId == set.Id)
                    .ExecuteDeleteAsync();
            }

            set.Notes = request.Notes;
            set.MeasuredAt = request.MeasuredAt;
            set.UpdatedAt = now;

            var measurements = request.Measurements
                .Select(m => new Measurement
                {
                    Id = Guid.NewGuid(),
                    MeasurementSetId = set.Id,
                    Name = m.Name,
                    Value = m.Value,
                    Unit = m.Unit
                })
                .ToList();

            _db.Measurements.AddRange(measurements);
            await _db.SaveChangesAsync();

            return ToResponse(set, measurements);
        }

        private IQueryable<MeasurementSet> CurrentSets(Guid clientId, Guid atelierId) =>
            _db.MeasurementsSet
                .Where(s => s.ClientId == clientId && s.AtelierId == atelierId)
                .OrderByDescending(s => s.MeasuredAt)
                .ThenByDescending(s => s.CreatedAt);

        private static MeasurementSetResponse ToResponse(
            MeasurementSet set,
            IEnumerable<Measurement> measurements) => new MeasurementSetResponse
        {
            Id = set.Id,
            ClientId = set.ClientId,
            Notes = set.Notes,
            MeasuredAt = set.MeasuredAt,
            CreatedAt = set.CreatedAt,
            UpdatedAt = set.UpdatedAt,
            Measurements = measurements
                .Select(m => new MeasurementResponse
                {
                    Id = m.Id,
                    MeasurementSetId = m.MeasurementSetId,
                    Name = m.Name,
                    Value = m.Value,
                    Unit = m.Unit
                })
                .ToList()
        };
    }
}
