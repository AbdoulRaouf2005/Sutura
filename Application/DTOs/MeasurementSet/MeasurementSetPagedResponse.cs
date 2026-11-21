namespace sutura_api.Application.DTOs.MeasurementSet
{
    public class MeasurementSetPagedResponse
    {
        public List<MeasurementSetResponse> Items { get; set; } = new List<MeasurementSetResponse>();

        public int Page { get; set; }

        public int PageSize { get; set; }

        public int TotalCount { get; set; }

        public int TotalPages => PageSize == 0
            ? 0
            : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }
}
