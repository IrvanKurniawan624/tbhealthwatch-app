using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Infrastructure.Auth;
using TBHealthWatch.Infrastructure.Persistence;
using TBHealthWatch.Infrastructure.Repositories;
using TBHealthWatch.Infrastructure.Services;

namespace TBHealthWatch.Infrastructure;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

        services.AddDbContext<AppDbContext>(opt =>
            opt.UseNpgsql(connectionString).UseSnakeCaseNamingConvention());

        services.AddScoped<IPasswordHasher, BcryptPasswordHasher>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IProfileRepository, ProfileRepository>();
        services.AddScoped<IPatientRepository, PatientRepository>();
        services.AddScoped<IAdherenceRepository, AdherenceRepository>();
        services.AddScoped<IRegionRepository, RegionRepository>();
        services.AddScoped<ISurveillanceRepository, SurveillanceRepository>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        return services;
    }
}
