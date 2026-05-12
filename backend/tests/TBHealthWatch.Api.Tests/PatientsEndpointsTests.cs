using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class PatientsEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public PatientsEndpointsTests(TestWebApplicationFactory factory)
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
    public async Task ListPatients_WithoutAuth_Returns401()
    {
        var resp = await _client.GetAsync("/api/patients");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ListPatients_WithAuth_Returns5SeededPatients()
    {
        await AuthorizeAsync();

        var resp = await _client.GetAsync("/api/patients");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var patients = await resp.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        patients.Should().HaveCount(5);
        patients.Should().AllSatisfy(p =>
        {
            p.Should().ContainKey("id");
            p.Should().ContainKey("name");
            p.Should().ContainKey("status");
            p.Should().ContainKey("phase");
            p.Should().ContainKey("currentMonth");
            p.Should().ContainKey("totalMonths");
        });
    }

    [Fact]
    public async Task GetPatientById_WithValidId_ReturnsDetail()
    {
        await AuthorizeAsync();

        // Get list first to find a valid ID
        var listResp = await _client.GetAsync("/api/patients");
        var patients = await listResp.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        var id = patients![0]["id"].ToString();

        var resp = await _client.GetAsync($"/api/patients/{id}");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("phone");
        body.Should().ContainKey("dob");
    }

    [Fact]
    public async Task GetPatientById_WithUnknownId_Returns404()
    {
        await AuthorizeAsync();

        var resp = await _client.GetAsync($"/api/patients/{Guid.NewGuid()}");
        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task UpdatePatient_WithValidData_Returns200()
    {
        await AuthorizeAsync();

        var listResp = await _client.GetAsync("/api/patients");
        var patients = await listResp.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        var id = patients![0]["id"].ToString();

        var resp = await _client.PutAsJsonAsync($"/api/patients/{id}", new
        {
            fullName = "Updated Name",
            phone = "+62 812 9999 9999"
        });

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body!["name"].ToString().Should().Be("Updated Name");
    }
}
