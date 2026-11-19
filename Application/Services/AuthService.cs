using sutura_api.Infrastructure.Data;
using sutura_api.Application.DTOs.Auth;
using Microsoft.AspNetCore.Identity;
using sutura_api.Domain.Entities;
using sutura_api.Api.Options;
using Microsoft.EntityFrameworkCore;
using sutura_api.Application.DTOs.User;

namespace sutura_api.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly SuturaDbContext _db;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITokenService _tokenService;
        private readonly JwtSettings _settings;
        public AuthService(ITokenService tokenService, SuturaDbContext db, UserManager<ApplicationUser> userManager,Microsoft.Extensions.Options.IOptions<JwtSettings> settings)
        {
            _db = db;
            _userManager = userManager;
            _tokenService = tokenService;
            _settings =settings.Value;
        }

        // Inscription

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            var existingUser = await _userManager.FindByEmailAsync(request.Email);

            if (existingUser != null)
                throw new InvalidOperationException("Cet email est deja utilisé.");

            var user = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                FullName = request.FullName,
                UserName = request.Email,
                IsActive = true,
                Email = request.Email
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
                throw new InvalidOperationException(string.Join(", ", result.Errors.Select(e => e.Description)));

            var atelier = new Atelier
            {
                Id = Guid.NewGuid(),
                Name = request.AtelierName,
                OwnerId = user.Id
            };
            _db.Ateliers.Add(atelier);
            await _db.SaveChangesAsync();

            return await CreateAuthResponseAsync(user, atelier.Id, null);
        }

        // Connexion
        public async Task<AuthResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);

            if(user == null || !user.IsActive)
                return null;

            var passwordValid = await _userManager.CheckPasswordAsync(user, request.Password);

            if (!passwordValid)
                return null;

            var atelier = await _db.Ateliers.FirstOrDefaultAsync(a => a.OwnerId == user.Id);
            
            if(atelier == null)
                return null;

            return await CreateAuthResponseAsync(user, atelier.Id,request.DeviceName);
        }

        // Rafraichissement du token
        public async Task<AuthResponse?> RefreshAsync(RefreshTokenRequest token)
        {
            var hash = _tokenService.HashRefreshToken(token.RefreshToken);

            var storedToken = await _db.RefreshTokens
                .Include(rt => rt.User)
                .ThenInclude(u => u.Atelier)
                .FirstOrDefaultAsync(rt => rt.TokenHash == hash);

            if(storedToken == null || !storedToken.IsActive)
                return null;
            if(!storedToken.User.IsActive || storedToken.User.Atelier == null)
                return null;

            // Revoquer l'ancien refresh token
            storedToken.RevokedAt = DateTime.UtcNow;

            // Créer une nouvelle paire de tokens
            var response = await CreateAuthResponseAsync(
                storedToken.User, 
                storedToken.User.Atelier.Id, 
                storedToken.DeviceName);

            storedToken.ReplacedByTokenHash = _tokenService.HashRefreshToken(response.RefreshToken);
            await _db.SaveChangesAsync();

            return response;
        }

        // Deconnexion
        public async Task<bool> LogoutAsync(RefreshTokenRequest request)
        {
            var hash = _tokenService.HashRefreshToken(request.RefreshToken);

            var storedToken = await _db.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash);

            if(storedToken == null || !storedToken.IsActive)
                return false;

            storedToken.RevokedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return true;
        }

        // Creation de la reponse d'authentification

        private async Task<AuthResponse> CreateAuthResponseAsync(ApplicationUser user, Guid atelierId, string? deviceName)
        {
            var accessToken = _tokenService.GenerateAccessToken(user, atelierId);

            var refreshToken = _tokenService.GenerateRefreshToken();

            var now = DateTime.UtcNow;

            var accessExpiration = now.AddMinutes(_settings.AccessTokenExpirationMinutes);

            var refreshExpiration = now.AddDays(_settings.RefreshTokenExpirationDays);

            var refreshTokenEntity = new RefreshToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                TokenHash = _tokenService.HashRefreshToken(refreshToken),
                DeviceName = deviceName,
                CreatedAt = now,
                ExpiresAt = refreshExpiration
            };

            await _db.SaveChangesAsync();

            return new AuthResponse
            {
                AccessToken = accessToken,
                AccessTokenExpiresAt = accessExpiration,
                RefreshToken = refreshToken,
                RefreshTokenExpiresAt = refreshExpiration,
                User = new UserProfile
                {
                    Id = user.Id,
                    FullName = user.FullName,
                    Email = user.Email!,
                    AtelierId = atelierId,
                    AtelierName = (await _db.Ateliers
                                            .Where(a => a.Id == atelierId)
                                            .Select(a => a.Name)
                                            .FirstAsync())
                }
            };
        }
    }
}
