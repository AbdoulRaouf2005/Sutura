using System.ComponentModel.DataAnnotations;

namespace sutura_api.Application.DTOs.Client
{
    public class ClientRequest
    {
        [Required]
        [StringLength(150)]
        public string FullName { get; set; } = string.Empty;
        [StringLength(30)]
        public string? Phone {  get; set; }
        [StringLength(1000)]
        public string? Notes { get; set; }
    }
}
