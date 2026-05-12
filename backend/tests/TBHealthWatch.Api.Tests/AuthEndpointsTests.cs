using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class AuthEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public AuthEndpointsTests(TestWebApplicationFactory factory)
        => _client = factory.CreateClient();

    [Fact]
    public async Task Login_WithValidCredentials_Returns200WithTokens()
    {
        var resp = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "siti.aminah@tbhealthwatch.test",
            password = "Demo123!"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("accessToken");
        body.Should().ContainKey("refreshToken");
        body!["accessToken"].ToString().Should().NotBeEmpty();
    }

    [Fact]
    public async Task Login_WithWrongPassword_Returns401()
    {
        var resp = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "siti.aminah@tbhealthwatch.test",
            password = "wrong-password"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Login_WithUnknownEmail_Returns401()
    {
        var resp = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "nobody@example.com",
            password = "Demo123!"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Register_WithNewEmail_Returns200WithTokens()
    {
        var resp = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = "newuser@tbhealthwatch.test",
            password = "NewUser123!",
            fullName = "New User"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("accessToken");
    }

    [Fact]
    public async Task Register_WithDuplicateEmail_Returns409()
    {
        var resp = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = "siti.aminah@tbhealthwatch.test",
            password = "Demo123!",
            fullName = "Duplicate"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task Refresh_WithValidToken_Returns200WithNewTokens()
    {
        var loginResp = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "siti.aminah@tbhealthwatch.test",
            password = "Demo123!"
        });
        var loginBody = await loginResp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var refreshToken = loginBody!["refreshToken"].ToString()!;

        var refreshResp = await _client.PostAsJsonAsync("/api/auth/refresh",
            new { refreshToken });

        refreshResp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await refreshResp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("accessToken");
    }

    [Fact]
    public async Task Logout_WithValidToken_Returns204()
    {
        var token = await new TestWebApplicationFactory().GetDemoTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.PostAsync("/api/auth/logout", null);

        resp.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }
}
