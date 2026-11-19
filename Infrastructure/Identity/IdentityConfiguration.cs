using Npgsql.Replication;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using sutura_api.Domain.Entities;
using Microsoft.Extensions.Options;
using sutura_api.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;

namespace sutura_api.Infrastructure.Identity
{
    public static class IdentityConfiguration
    {
        public static IServiceCollection AddIdentityConfiguration(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
            {
                options.User.RequireUniqueEmail = true;
                options.Password.RequiredLength = 8;
                options.Password.RequireDigit = true;
                options.Password.RequireUppercase = false;
                options.Password.RequireLowercase = true;
                options.Password.RequireNonAlphanumeric = false;

                // verification de l'email facultative
                options.SignIn.RequireConfirmedEmail = false;

                options.Lockout.MaxFailedAccessAttempts = 5;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(10);
            })
            .AddEntityFrameworkStores<SuturaDbContext>()
            .AddDefaultTokenProviders();
            return services;
        }
    }
}