using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Client
{
    // Données envoyées par Flutter pour modifier un client existant.
    // L'Id est répété dans le corps et doit correspondre à celui de l'URL.
    public class UpdateClientRequest
    {
        // Identifiant du client à modifier (jamais fourni par le client pour la création).
        [Required]
        public Guid Id { get; set; }

        [Required]
        [StringLength(150)]
        public string FullName { get; set; } = string.Empty;

        [StringLength(30)]
        public string? Phone { get; set; }

        [StringLength(1000)]
        public string? Notes { get; set; }
    }
}
