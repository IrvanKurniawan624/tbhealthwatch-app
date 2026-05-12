using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class AdherenceEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public AdherenceEndpointsTests(TestWebApplicationFactory factory)
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

    private async Task<string> GetFirstPatientIdAsync()
    {
        var resp = await _client.GetAsync("/api/patients");
        var patients = await resp.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        return patients![0]["id"].ToString()!;
    }

    [Fact]
    public async Task GetSummary_WithAuth_ReturnsAdherenceData()
    {
        await AuthorizeAsync();
        var patientId = await GetFirstPatientIdAsync();

        var resp = await _client.GetAsync($"/api/patients/{patientId}/adherence/summary");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("percentage");
        body.Should().ContainKey("target");
        body.Should().ContainKey("dosesTaken");
        body.Should().ContainKey("dosesTotal");
        body.Should().ContainKey("streakDays");
        body!["target"].ToString().Should().Be("95");
    }

    [Fact]
    public async Task GetCalendar_WithAuth_ReturnsAllDaysInMonth()
    {
        await AuthorizeAsync();
        var patientId = await GetFirstPatientIdAsync();
        var now = DateTime.UtcNow;

        var resp = await _client.GetAsync(
            $"/api/patients/{patientId}/adherence/calendar?year={now.Year}&month={now.Month}");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await resp.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("year");
        body.Should().ContainKey("month");
        body.Should().ContainKey("days");
    }

    [Fact]
    public async Task GetCalendar_WithInvalidMonth_Returns400()
    {
        await AuthorizeAsync();
        var patientId = await GetFirstPatientIdAsync();

        var resp = await _client.GetAsync(
            $"/api/patients/{patientId}/adherence/calendar?year=2024&month=13");

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task LogAdherence_IsIdempotent()
    {
        await AuthorizeAsync();
        var patientId = await GetFirstPatientIdAsync();
        var logDate = DateTime.UtcNow.AddDays(-5).ToString("yyyy-MM-dd");

        var payload = new { logDate, status = "taken" };

        var resp1 = await _client.PostAsJsonAsync(
            $"/api/patients/{patientId}/adherence/log", payload);
        var resp2 = await _client.PostAsJsonAsync(
            $"/api/patients/{patientId}/adherence/log", payload);

        resp1.StatusCode.Should().Be(HttpStatusCode.NoContent);
        resp2.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task GetSummary_WithoutAuth_Returns401()
    {
        var resp = await _client.GetAsync($"/api/patients/{Guid.NewGuid()}/adherence/summary");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
