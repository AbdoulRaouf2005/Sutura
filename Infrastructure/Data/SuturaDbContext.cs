using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using sutura_api.Domain.Entities;

namespace sutura_api.Infrastructure.Data
{
    public class SuturaDbContext : IdentityDbContext<ApplicationUser,IdentityRole<Guid>,Guid>
    {
        public SuturaDbContext(DbContextOptions<SuturaDbContext> options) : base(options)
        {
        }

        // Tables de la base de données
        public DbSet<Client> Clients { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Measurement> Measurements { get; set; }
        public DbSet<GarmentModel> Garments { get; set; }
        public DbSet<MeasurementSet> MeasurementsSet { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<Atelier> Ateliers { get; set; }


        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);
            builder.Entity<Atelier>(entity =>
            {
                entity.HasKey(a => a.Id);

                entity.Property(a => a.Name)
                    .IsRequired()
                    .HasMaxLength(150);

                entity.HasOne(a => a.Owner)
                    .WithOne(u => u.Atelier)
                    .HasForeignKey<Atelier>(a => a.OwnerId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            builder.Entity<RefreshToken>(entity =>
            {
                entity.HasKey(t => t.Id);

                entity.Property(t => t.TokenHash)
                    .IsRequired()
                    .HasMaxLength(512);

                entity.HasIndex(t => t.TokenHash)
                    .IsUnique();

                entity.Property(t => t.DeviceName)
                    .HasMaxLength(150);

                entity.HasOne(t => t.User)
                    .WithMany(u => u.RefreshTokens)
                    .HasForeignKey(t => t.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }

}
