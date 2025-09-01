using Xunit;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PrimeNumbersWebApi.Tests;

public class IntegrationTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Theory]
    [InlineData("/api/primes/5", true)]
    [InlineData("/api/primes/10", false)]
    public async Task PrimesEndpoint_ReturnsExpected(string url, bool expected)
    {
        using var client = factory.CreateClient();
        var response = await client.GetAsync(url);
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        Assert.Equal(expected.ToString().ToLowerInvariant(), content);
    }
}
