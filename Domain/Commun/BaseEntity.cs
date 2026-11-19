namespace sutura_api.Domain.Commun
{
    public abstract class BaseEntity
    {
        public Guid Id { get; set; }

        public DateTimeOffset CreatedAtUtc { get; set; }

        public DateTimeOffset LastModifiedAtUtc { get; set; }

        public DateTimeOffset? ServerUpdatedAtUtc { get; set; }

        public int SyncVersion { get; set; } = 1;

        public bool IsDeleted { get; set; } = false;

        public DateTimeOffset? DeletedAtUtc { get; set; }
    }
}
