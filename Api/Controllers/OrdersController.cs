using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using sutura_api.Application.DTOs.Order;
using sutura_api.Application.Interfaces;
using sutura_api.Domain.Enums;

namespace sutura_api.Api.Controllers
{
    // Commandes de l'atelier, accessibles uniquement avec un JWT valide.
    [Authorize]
    [Route("api/v1/orders")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly IOrderService _orderService;

        public OrdersController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        // L'atelier est lu dans le claim du token : Flutter ne l'envoie jamais dans le corps.
        private bool TryGetAtelierId(out Guid atelierId)
        {
            var claimValue = User.FindFirst("atelierId")?.Value;

            return Guid.TryParse(claimValue, out atelierId);
        }

        // POST : api/v1/orders
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] OrderRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _orderService.CreateAsync(request, atelierId);

            if (response == null)
                return NotFound(new { message = "Client, modèle ou mensurations introuvables." });

            return StatusCode(201, response);
        }

        // GET : api/v1/orders?status=Ready&clientId=...&page=1&pageSize=20
        [HttpGet]
        public async Task<IActionResult> List(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] OrderStatus? status = null,
            [FromQuery] Guid? clientId = null,
            [FromQuery] DateOnly? fromDeliveryDate = null,
            [FromQuery] DateOnly? toDeliveryDate = null,
            [FromQuery] string? search = null)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            page = page < 1 ? 1 : page;
            pageSize = pageSize < 1 ? 1 : (pageSize > 100 ? 100 : pageSize);

            var response = await _orderService.ListAsync(
                atelierId,
                page,
                pageSize,
                status,
                clientId,
                fromDeliveryDate,
                toDeliveryDate,
                search);

            return Ok(response);
        }

        // GET : api/v1/orders/due-soon?days=7
        [HttpGet("due-soon")]
        public async Task<IActionResult> DueSoon([FromQuery] int days = 7)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            days = days < 1 ? 1 : (days > 365 ? 365 : days);

            var response = await _orderService.ListDueSoonAsync(atelierId, days);

            return Ok(response);
        }

        // GET : api/v1/orders/{id}
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _orderService.GetByIdAsync(id, atelierId);

            if (response == null)
                return NotFound(new { message = "Commande introuvable." });

            return Ok(response);
        }

        // PUT : api/v1/orders/{id}
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateOrderRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            if (request.Id != id)
                return BadRequest(new { message = "L'Id du corps doit correspondre à celui de l'URL." });

            var response = await _orderService.UpdateAsync(request, atelierId);

            if (response == null)
                return NotFound(new { message = "Commande ou référence introuvable." });

            return Ok(response);
        }

        // PATCH : api/v1/orders/{id}/status
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateOrderStatusRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _orderService.UpdateStatusAsync(id, request.Status, atelierId);

            if (response == null)
                return NotFound(new { message = "Commande introuvable." });

            return Ok(response);
        }
    }
}
