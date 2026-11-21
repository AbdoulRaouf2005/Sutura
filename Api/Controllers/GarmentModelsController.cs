using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using sutura_api.Application.DTOs.GarmentModel;
using sutura_api.Application.Interfaces;

namespace sutura_api.Api.Controllers
{
    // Catalogue des modèles de vêtements, accessible uniquement avec un JWT valide.
    [Authorize]
    [Route("api/v1/models")]
    [ApiController]
    public class GarmentModelsController : ControllerBase
    {
        private readonly IGarmentModelService _garmentModelService;

        public GarmentModelsController(IGarmentModelService garmentModelService)
        {
            _garmentModelService = garmentModelService;
        }

        // L'atelier est lu dans le claim du token : Flutter ne l'envoie jamais dans le corps.
        private bool TryGetAtelierId(out Guid atelierId)
        {
            var claimValue = User.FindFirst("atelierId")?.Value;

            return Guid.TryParse(claimValue, out atelierId);
        }

        // POST : api/v1/models
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] GarmentModelRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _garmentModelService.CreateAsync(request, atelierId);

            return StatusCode(201, response);
        }

        // GET : api/v1/models?page=1&pageSize=20&search=robe
        [HttpGet]
        public async Task<IActionResult> List(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? search = null)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            page = page < 1 ? 1 : page;
            pageSize = pageSize < 1 ? 1 : (pageSize > 100 ? 100 : pageSize);

            var response = await _garmentModelService.ListAsync(atelierId, page, pageSize, search);

            return Ok(response);
        }

        // GET : api/v1/models/{id}
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _garmentModelService.GetByIdAsync(id, atelierId);

            if (response == null)
                return NotFound(new { message = "Modèle introuvable." });

            return Ok(response);
        }

        // PUT : api/v1/models/{id}
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateGarmentModelRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            if (request.Id != id)
                return BadRequest(new { message = "L'Id du corps doit correspondre à celui de l'URL." });

            var response = await _garmentModelService.UpdateAsync(request, atelierId);

            if (response == null)
                return NotFound(new { message = "Modèle introuvable." });

            return Ok(response);
        }

        // DELETE : api/v1/models/{id} -> archivage logique, jamais de suppression physique.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Archive(Guid id)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var archived = await _garmentModelService.ArchiveAsync(id, atelierId);

            if (!archived)
                return NotFound(new { message = "Modèle introuvable." });

            return NoContent();
        }
    }
}
