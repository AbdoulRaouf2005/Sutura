namespace sutura_api.Application.DTOs.Client
{
    public class ClientResponse
    {
        public Guid Id { get; set; }    
        public string FullName { get; set; } = string.Empty;
        public string? Phone {  get; set; }
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsArchived { get; set; }
    }
}
