using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class ProfileEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public ProfileEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private async Task AuthorizeAsync()
    {
        var token = await _factory.GetDemoTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
    }

    [Fact]
    public async Task GetProfile_WithoutAuth_Returns401()
    {
        var resp = await _client.GetAsync("/api/profile/me");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetProfile_WithAuth_ReturnsDemoUser()
    {
        await AuthorizeAsync();

        var resp = await _client.GetAsync("/api/profile/me");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("fullName");
        body!["fullName"].ToString().Should().Be("Dr. Siti Aminah");
        body.Should().ContainKey("email");
    }

    [Fact]
    public async Task UpdateProfile_WithValidData_Returns200()
    {
        await AuthorizeAsync();

        var resp = await _client.PutAsJsonAsync("/api/profile/me", new
        {
            fullName = "Dr. Siti Aminah Updated",
            specialization = "TB Specialist",
            facilityName = "RSUD Test",
            facilityRole = "Supervisor",
            assignmentLocation = "Surabaya",
            phone = "+62 812 0000 0000"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body!["fullName"].ToString().Should().Be("Dr. Siti Aminah Updated");
    }
}
