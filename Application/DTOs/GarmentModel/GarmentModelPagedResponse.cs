namespace sutura_api.Application.DTOs.GarmentModel
{
    public class GarmentModelPagedResponse
    {
        public List<GarmentModelResponse> Items { get; set; } = new List<GarmentModelResponse>();

        public int Page { get; set; }

        public int PageSize { get; set; }

        public int TotalCount { get; set; }

        public int TotalPages => PageSize == 0
            ? 0
            : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
