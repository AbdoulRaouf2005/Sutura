namespace sutura_api.Application.DTOs.Atelier
{
    public class AtelierResponse
    {
        public Guid Id { get; set; }
        public Guid OwnerId { get; set; }
        public string Name { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
