using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.Client;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Entities;
using sutura_api.Infrastructure.Data;

namespace sutura_api.Application.Services
{
    // Implémentation du CRUD Client : chaque requête est filtrée par l'atelier du token JWT.
    public class ClientService : IClientService
    {
        private readonly SuturaDbContext _db;

        public ClientService(SuturaDbContext db)
        {
            _db = db;
        }

        // Création : le serveur génère l'Id, les dates UTC et positionne IsArchived à false.
        public async Task<ClientResponse> CreateClientAsync(ClientRequest request, Guid atelierId)
        {
            var now = DateTime.UtcNow;

            var client = new Client
            {
                Id = Guid.NewGuid(),
                AtelierId = atelierId,
                FullName = request.FullName,
                Phone = request.Phone,
                Notes = request.Notes,
                CreatedAt = now,
                UpdatedAt = now,
                IsArchived = false
            };

            _db.Clients.Add(client);
            await _db.SaveChangesAsync();

            return ToResponse(client);
        }

        // Modification : seuls les champs autorisés par le DTO sont écrasés.
        public async Task<ClientResponse?> UpdateClientAsync(UpdateClientRequest request, Guid atelierId)
        {
            var client = await _db.Clients
                .FirstOrDefaultAsync(c => c.Id == request.Id && c.AtelierId == atelierId);

            if (client == null)
                return null;

            client.FullName = request.FullName;
            client.Phone = request.Phone;
            client.Notes = request.Notes;
            client.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return ToResponse(client);
        }

        // Liste : les clients archivés sont masqués, recherche sur le nom ou le téléphone.
        public async Task<ClientPagedResponse> ListClientAsync(
            Guid atelierId,
            int page,
            int pageSize,
            string? search)
        {
            var query = _db.Clients
                .Where(c => c.AtelierId == atelierId && !c.IsArchived);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();

                query = query.Where(c =>
                    c.FullName.Contains(term) ||
                    (c.Phone != null && c.Phone.Contains(term)));
            }

            var totalCount = await query.CountAsync();

            var clients = await query
                .OrderBy(c => c.FullName)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new ClientPagedResponse
            {
                Items = clients.Select(ToResponse).ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount
            };
        }

        // Détail : le filtre atelierId empêche la lecture des clients d'un autre atelier.
        public async Task<ClientResponse?> GetClientByIdAsync(Guid clientId, Guid atelierId)
        {
            var client = await _db.Clients
                .FirstOrDefaultAsync(c => c.Id == clientId && c.AtelierId == atelierId);

            return client == null ? null : ToResponse(client);
        }

        // Suppression : archivage logique uniquement, la ligne n'est jamais effacée.
        public async Task<bool> ArchiveAsync(Guid clientId, Guid atelierId)
        {
            var client = await _db.Clients
                .FirstOrDefaultAsync(c => c.Id == clientId && c.AtelierId == atelierId);

            if (client == null)
                return false;

            client.IsArchived = true;
            client.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return true;
        }

        // Mapping entité -> DTO : aucune entité EF n'est exposée au contrôleur.
        private static ClientResponse ToResponse(Client client) => new ClientResponse
        {
            Id = client.Id,
            FullName = client.FullName,
            Phone = client.Phone,
            Notes = client.Notes,
            CreatedAt = client.CreatedAt,
            UpdatedAt = client.UpdatedAt,
            IsArchived = client.IsArchived
        };
    }
}
