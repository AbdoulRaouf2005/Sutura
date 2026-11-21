using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using sutura_api.Application.DTOs.Payment;
using sutura_api.Application.Interfaces;

namespace sutura_api.Api.Controllers
{
    // Paiements d'une commande : ressource imbriquée sous /orders/{orderId}.
    [Authorize]
    [Route("api/v1/orders/{orderId:guid}/payments")]
    [ApiController]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentsController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        // L'atelier est lu dans le claim du token : Flutter ne l'envoie jamais dans le corps.
        private bool TryGetAtelierId(out Guid atelierId)
        {
            var claimValue = User.FindFirst("atelierId")?.Value;

            return Guid.TryParse(claimValue, out atelierId);
        }

        // GET : api/v1/orders/{orderId}/payments
        [HttpGet]
        public async Task<IActionResult> List(Guid orderId)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _paymentService.ListAsync(orderId, atelierId);

            if (response == null)
                return NotFound(new { message = "Commande introuvable." });

            return Ok(response);
        }

        // GET : api/v1/orders/{orderId}/payments/{paymentId}
        [HttpGet("{paymentId:guid}")]
        public async Task<IActionResult> GetById(Guid orderId, Guid paymentId)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            var response = await _paymentService.GetByIdAsync(orderId, paymentId, atelierId);

            if (response == null)
                return NotFound(new { message = "Paiement introuvable." });

            return Ok(response);
        }

        // POST : api/v1/orders/{orderId}/payments
        [HttpPost]
        public async Task<IActionResult> Create(Guid orderId, [FromBody] PaymentRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            if (request.OrderId != orderId)
                return BadRequest(new { message = "L'Id de la commande du corps doit correspondre à celui de l'URL." });

            var response = await _paymentService.CreateAsync(request, orderId, atelierId);

            if (response == null)
                return NotFound(new { message = "Commande introuvable." });

            return StatusCode(201, response);
        }

        // PUT : api/v1/orders/{orderId}/payments/{paymentId}
        [HttpPut("{paymentId:guid}")]
        public async Task<IActionResult> Update(
            Guid orderId,
            Guid paymentId,
            [FromBody] UpdatePaymentRequest request)
        {
            if (!TryGetAtelierId(out var atelierId))
                return Unauthorized(new { message = "Claim 'atelierId' absent du token." });

            if (request.Id != paymentId || request.OrderId != orderId)
                return BadRequest(new { message = "Les Id du corps doivent correspondre à ceux de l'URL." });

            var response = await _paymentService.UpdateAsync(request, orderId, atelierId);

            if (response == null)
                return NotFound(new { message = "Paiement introuvable." });

            return Ok(response);
        }
    }
}
