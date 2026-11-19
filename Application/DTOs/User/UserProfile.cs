namespace sutura_api.Application.DTOs.User
{
    public class UserProfile
    {
        public Guid Id {get; set;}
        public string FullName {get; set;} = string.Empty;
        public string Email {get; set;} = string.Empty;
        public Guid AtelierId { get; set; }
        public string AtelierName { get; set; } = string.Empty;
    }
}