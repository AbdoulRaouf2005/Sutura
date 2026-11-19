namespace sutura_api.Application.DTOs.Client
{
    // Réponse paginée de GET /api/v1/clients : la liste et les métadonnées nécessaires à Flutter.
    public class ClientPagedResponse
    {
        // Clients de la page courante.
        public List<ClientResponse> Items { get; set; } = new List<ClientResponse>();

        // Numéro de la page (1-based).
        public int Page { get; set; }

        // Nombre maximal d'éléments par page.
        public int PageSize { get; set; }

        // Nombre total de clients correspondant au filtre.
        public int TotalCount { get; set; }

        // Nombre de pages disponibles, calculé côté serveur.
        public int TotalPages => PageSize == 0
            ? 0
            : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
