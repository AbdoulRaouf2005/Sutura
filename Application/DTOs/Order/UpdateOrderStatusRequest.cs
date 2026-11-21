using System.ComponentModel.DataAnnotations;
using sutura_api.Domain.Enums;

namespace sutura_api.Application.DTOs.Order
{
    public class UpdateOrderStatusRequest
    {
        [Required]
        public OrderStatus Status { get; set; }
    }
}
