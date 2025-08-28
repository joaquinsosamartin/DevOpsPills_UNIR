namespace NvdProxyApi.Models;

public record ThreatDto(
    string Id,
    DateTimeOffset Published,
    DateTimeOffset LastModified,
    double? Cvss,
    string? Severity,
    string Description,
    string Url);