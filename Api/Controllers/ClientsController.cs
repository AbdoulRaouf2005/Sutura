using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using sutura_api.Application.DTOs.Client;
using sutura_api.Application.DTOs.MeasurementSet;
using sutura_api.Application.Interfaces;

namespace sutura_api.Api.Controllers
{
    // Endpoints REST des clients, accessibles uniquement avec un JWT valide.
    [Authorize]
    [Route("api/v1/clients")]
    [ApiController]
    public class ClientsController : ControllerBase
    {
        private readonly IClientService _clientService;
        private readonly IMeasurementSetService _measurementSetService;

        public ClientsController(IClientService clientService, IMeasurementSetService measurementSetService)
        {
            _clientService = clientService;
            _measurementSetService = measurementSetService;
        }

        // L'atelier est lu dans le claim du token : Flutter ne l'envoie jamais dans le corps.
        private bool TryGetAtelierId(out Guid atelierId)
        {
            var claimValue = User.FindFirst("atelierId")?.Value;

            return Guid.TryParse(claimValue, out atelierId);
        }

        // POST : api/v1/clients
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ClientRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _clientService.CreateClientAsync(request, atelierId);

            return StatusCode(201, response);
        }

        // GET : api/v1/clients?page=1&pageSize=20&search=Amina
        [HttpGet]
        public async Task<IActionResult> List(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? search = null)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            // Pagination bornée selon la spécification : page >= 1 et pageSize <= 100.
            page = page < 1 ? 1 : page;
            pageSize = pageSize < 1 ? 1 : (pageSize > 100 ? 100 : pageSize);

            var response = await _clientService.ListClientAsync(atelierId, page, pageSize, search);

            return Ok(response);
        }

        // GET : api/v1/clients/{id}
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _clientService.GetClientByIdAsync(id, atelierId);

            if (response == null)
                return NotFound(new { message = "Client introuvable." });

            return Ok(response);
        }

        // PUT : api/v1/clients/{id}
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateClientRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            // L'Id du corps et celui de l'URL doivent désigner le même client.
            if (request.Id != id)
                return BadRequest(new { message = "L'Id du corps doit correspondre à celui de l'URL." });

            var response = await _clientService.UpdateClientAsync(request, atelierId);

            if (response == null)
                return NotFound(new { message = "Client introuvable." });

            return Ok(response);
        }

        // DELETE : api/v1/clients/{id} -> archivage logique, jamais de suppression physique.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Archive(Guid id)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var archived = await _clientService.ArchiveAsync(id, atelierId);

            if (!archived)
                return NotFound(new { message = "Client introuvable." });

            return NoContent();
        }

        // GET : api/v1/clients/{clientId}/measurements -> jeu de mensurations courant.
        [HttpGet("{clientId:guid}/measurements")]
        public async Task<IActionResult> GetMeasurements(Guid clientId)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _measurementSetService.GetCurrentAsync(clientId, atelierId);

            if (response == null)
                return NotFound(new { message = "Client ou mensurations introuvables." });

            return Ok(response);
        }

        // PUT : api/v1/clients/{clientId}/measurements -> remplace le jeu courant.
        [HttpPut("{clientId:guid}/measurements")]
        public async Task<IActionResult> ReplaceMeasurements(
            Guid clientId,
            [FromBody] MeasurementSetRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            if (request.ClientId != clientId)
                return BadRequest(new { message = "L'Id du client du corps doit correspondre à celui de l'URL." });

            var response = await _measurementSetService.ReplaceCurrentAsync(request, clientId, atelierId);

            if (response == null)
                return NotFound(new { message = "Client introuvable." });

            return Ok(response);
        }
    }
}
