using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Testcontainers.PostgreSql;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class TestWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16")
        .WithDatabase("testdb")
        .WithUsername("postgres")
        .WithPassword("test")
        .Build();

    public async Task InitializeAsync() => await _postgres.StartAsync();

    public new async Task DisposeAsync() => await _postgres.DisposeAsync();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration(config =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = _postgres.GetConnectionString(),
                ["Jwt:Key"] = "test-secret-key-minimum-32-bytes-long!!",
                ["Jwt:Issuer"] = "tbhealthwatch",
                ["Jwt:Audience"] = "tbhealthwatch-mobile"
            });
        });
    }

    // Returns a valid access token for the seeded demo user
    public async Task<string> GetDemoTokenAsync()
    {
        var client = CreateClient();
        var resp = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "siti.aminah@tbhealthwatch.test",
            password = "Demo123!"
        });
        resp.EnsureSuccessStatusCode();
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        return body!["accessToken"].ToString()!;
    }
}
