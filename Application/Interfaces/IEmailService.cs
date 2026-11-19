using sutura_api.Domain.Entities;

public interface IEmailService
{
    Task SendConfirmationEmailAsync(
        ApplicationUser user,
        string token);

    Task SendPasswordResetEmailAsync(
        ApplicationUser user,
        string token);
}