using sutura_api.Application.DTOs.Client;

namespace sutura_api.Application.Interfaces
{
    // Contrat du service Client. L'atelierId est toujours fourni par le contrôleur
    // depuis le claim JWT : jamais accepté depuis le corps de la requête.
    public interface IClientService
    {
        // Crée un client dans l'atelier courant.
        Task<ClientResponse> CreateClientAsync(ClientRequest request, Guid atelierId);

        // Modifie un client ; retourne null s'il n'appartient pas à l'atelier.
        Task<ClientResponse?> UpdateClientAsync(UpdateClientRequest request, Guid atelierId);

        // Liste paginée des clients, avec recherche sur le nom ou le téléphone.
        Task<ClientPagedResponse> ListClientAsync(Guid atelierId, int page, int pageSize, string? search);

        // Détail d'un client ; null s'il est introuvable dans l'atelier.
        Task<ClientResponse?> GetClientByIdAsync(Guid clientId, Guid atelierId);

        // Archivage logique (IsArchived = true) ; false si le client est introuvable.
        Task<bool> ArchiveAsync(Guid clientId, Guid atelierId);
    }
}
