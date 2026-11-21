using sutura_api.Application.DTOs.MeasurementSet;

namespace sutura_api.Application.Interfaces
{
    // Gestion du jeu de mensurations courant d'un client.
    // L'atelierId provient toujours du claim JWT, jamais du corps de la requête.
    public interface IMeasurementSetService
    {
        // Retourne le jeu le plus récent, ou null si le client est introuvable
        // dans l'atelier ou s'il n'a aucune mensuration.
        Task<MeasurementSetResponse?> GetCurrentAsync(Guid clientId, Guid atelierId);

        // Remplace le jeu courant (ou le crée s'il n'existe pas encore).
        // Retourne null si le client n'appartient pas à l'atelier.
        Task<MeasurementSetResponse?> ReplaceCurrentAsync(
            MeasurementSetRequest request,
            Guid clientId,
            Guid atelierId);
    }
}
