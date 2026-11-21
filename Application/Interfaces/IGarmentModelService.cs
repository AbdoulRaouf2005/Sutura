using sutura_api.Application.DTOs.GarmentModel;

namespace sutura_api.Application.Interfaces
{
    // Contrat du catalogue de modèles de vêtements de l'atelier.
    // L'atelierId provient toujours du claim JWT, jamais du corps de la requête.
    public interface IGarmentModelService
    {
        Task<GarmentModelResponse> CreateAsync(GarmentModelRequest request, Guid atelierId);

        // null si le modèle n'appartient pas à l'atelier.
        Task<GarmentModelResponse?> UpdateAsync(UpdateGarmentModelRequest request, Guid atelierId);

        // Liste paginée des modèles non archivés, avec recherche sur nom/catégorie/description.
        Task<GarmentModelPagedResponse> ListAsync(Guid atelierId, int page, int pageSize, string? search);

        Task<GarmentModelResponse?> GetByIdAsync(Guid modelId, Guid atelierId);

        // Archivage logique ; false si le modèle est introuvable.
        Task<bool> ArchiveAsync(Guid modelId, Guid atelierId);
    }
}
