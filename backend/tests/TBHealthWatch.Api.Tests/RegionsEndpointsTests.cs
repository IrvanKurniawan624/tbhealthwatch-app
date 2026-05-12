using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TBHealthWatch.Api.Tests;

public class RegionsEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public RegionsEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetRegions_WithoutAuth_Returns401()
    {
        var resp = await _client.GetAsync("/api/regions");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetRegions_WithAuth_Returns31Kecamatan()
    {
        var token = await _factory.GetDemoTokenAsync();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var resp = await _client.GetAsync("/api/regions");

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
        var regions = await resp.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        regions.Should().HaveCount(31);
        regions.Should().AllSatisfy(r =>
        {
            r.Should().ContainKey("id");
            r.Should().ContainKey("name");
            r.Should().ContainKey("code");
        });
    }
}
