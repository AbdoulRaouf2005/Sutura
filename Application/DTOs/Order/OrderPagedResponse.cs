namespace sutura_api.Application.DTOs.Order
{
    public class OrderPagedResponse
    {
        public List<OrderResponse> Items { get; set; } = new List<OrderResponse>();

        public int Page { get; set; }

        public int PageSize { get; set; }

        public int TotalCount { get; set; }

        public int TotalPages => PageSize == 0
            ? 0
            : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
