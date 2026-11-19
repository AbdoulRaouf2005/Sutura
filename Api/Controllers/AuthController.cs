using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using sutura_api.Application.DTOs.Auth;

namespace sutura_api.Api.Controllers
{
    [Route("api/v1/auth")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }
        // Post : api/v1/auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterRequest request)
        {
            try
            {
                var response = await _authService.RegisterAsync(request);
                return StatusCode(201, response);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // Post : api/v1/auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginRequest request)
        {
            var response = await _authService.LoginAsync(request);

            if (response == null)
                return Unauthorized(new
                {

                    message = "Email ou mot de passe incorrect."
                });

            return Ok(response);
        }

        // Post : api/v1/auth/refresh
        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh(RefreshTokenRequest request)
        {
            var response = await _authService.RefreshAsync(request);

            if (response == null)
                return Unauthorized(new
                {
                    message = "Refresh token invalide ou expiré."
                });

            return Ok(response);
        }

        // POST: api/v1/auth/logout
        [HttpPost("logout")]
        public async Task<IActionResult> Logout(RefreshTokenRequest request)
        {
            var result = await _authService.LogoutAsync(request);

            if (!result)
                return BadRequest(new
                {
                    message = "Session invalide ou déjà révoquée."
                });

            return NoContent();
        }
    }
}
