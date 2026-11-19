using sutura_api.Domain.Commun;

namespace sutura_api.Domain.Entities
{
        public class Atelier 
        {
            public Guid Id {get; set; }
            public Guid OwnerId { get; set; }

            public ApplicationUser Owner { get; set; } = null!;

            public string Name { get; set; } = string.Empty;
            public DateTime CreatedAt {get; set;} = DateTime.UtcNow;

        }
}
