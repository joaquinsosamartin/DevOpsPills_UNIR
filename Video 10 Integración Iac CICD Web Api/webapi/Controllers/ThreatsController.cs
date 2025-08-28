using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using NvdProxyApi.Models;
using System.Text.Json;

namespace NvdProxyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ThreatsController : ControllerBase
{
    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ThreatsController> _logger;
    private readonly IConfiguration _cfg;

    public ThreatsController(IHttpClientFactory factory, IMemoryCache cache, ILogger<ThreatsController> logger, IConfiguration cfg)
    {
        _http = factory.CreateClient("nvd");
        _cache = cache;
        _logger = logger;
        _cfg = cfg;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ThreatDto>>> Get([FromQuery] int? limit, [FromQuery] string? keyword)
    {
        int pageSize = Math.Clamp(limit ?? _cfg.GetValue<int>("Nvd:DefaultPageSize", 5), 1, 2000);
        var url = $"?resultsPerPage={pageSize}";
        if (!string.IsNullOrWhiteSpace(keyword))
            url += $"&keywordSearch={Uri.EscapeDataString(keyword)}";

        string cacheKey = $"nvd:threats:{pageSize}:{keyword ?? ""}";
        if (_cache.TryGetValue(cacheKey, out IEnumerable<ThreatDto>? cached) && cached is not null)
            return Ok(cached);

        var resp = await _http.GetAsync(url);
        if (!resp.IsSuccessStatusCode)
        {
            var body = await resp.Content.ReadAsStringAsync();
            _logger.LogWarning("NVD request failed {StatusCode} {ReasonPhrase}. Url: {Url}. Body: {Body}",
                (int)resp.StatusCode, resp.ReasonPhrase, url, body);
            return StatusCode((int)resp.StatusCode, $"No se pudo consultar NVD: {resp.ReasonPhrase}");
        }

        using var stream = await resp.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);

        var threats = new List<ThreatDto>();
        if (doc.RootElement.TryGetProperty("vulnerabilities", out var vulns) && vulns.ValueKind == JsonValueKind.Array)
        {
            foreach (var v in vulns.EnumerateArray())
            {
                try
                {
                    var cve = v.GetProperty("cve");
                    var id = cve.GetProperty("id").GetString() ?? "N/A";
                    var published = DateTimeOffset.Parse(cve.GetProperty("published").GetString()!);
                    var lastMod = DateTimeOffset.Parse(cve.GetProperty("lastModified").GetString()!);
                    string description = cve.GetProperty("descriptions").EnumerateArray()
                        .Select(d => d.GetProperty("value").GetString())
                        .FirstOrDefault(s => !string.IsNullOrWhiteSpace(s)) ?? "Sin descripción";

                    double? cvss = null;
                    string? severity = null;
                    if (cve.TryGetProperty("metrics", out var metrics))
                    {
                        if (metrics.TryGetProperty("cvssMetricV31", out var v31) && v31.ValueKind == JsonValueKind.Array && v31.GetArrayLength() > 0)
                        {
                            var m = v31[0].GetProperty("cvssData");
                            cvss = m.GetProperty("baseScore").GetDouble();
                            severity = v31[0].GetProperty("baseSeverity").GetString();
                        }
                    }
                    var urlRef = $"https://nvd.nist.gov/vuln/detail/{id}";
                    threats.Add(new ThreatDto(id, published, lastMod, cvss, severity, description, urlRef));
                }
                catch { continue; }
            }
        }

        _cache.Set(cacheKey, threats, TimeSpan.FromSeconds(_cfg.GetValue<int>("Nvd:CacheSeconds", 30)));
        return Ok(threats);
    }

    [HttpGet("{cveId}")]
    public async Task<ActionResult<ThreatDto>> GetById(string cveId)
    {
        if (string.IsNullOrWhiteSpace(cveId)) return BadRequest("cveId requerido");
        string cacheKey = $"nvd:cve:{cveId}";
        if (_cache.TryGetValue(cacheKey, out ThreatDto? cached) && cached is not null)
            return Ok(cached);

        var url = $"?cveId={Uri.EscapeDataString(cveId)}";
        var resp = await _http.GetAsync(url);
        if (!resp.IsSuccessStatusCode)
        {
            var body = await resp.Content.ReadAsStringAsync();
            _logger.LogWarning("NVD request failed {StatusCode} {ReasonPhrase}. Url: {Url}. Body: {Body}",
                (int)resp.StatusCode, resp.ReasonPhrase, url, body);
            return StatusCode((int)resp.StatusCode, $"No se pudo consultar NVD: {resp.ReasonPhrase}");
        }

        using var stream = await resp.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);

        if (!doc.RootElement.TryGetProperty("vulnerabilities", out var arr) || arr.GetArrayLength() == 0)
            return NotFound();

        var cve = arr[0].GetProperty("cve");
        var id = cve.GetProperty("id").GetString() ?? cveId;
        var published = DateTimeOffset.Parse(cve.GetProperty("published").GetString()!);
        var lastMod = DateTimeOffset.Parse(cve.GetProperty("lastModified").GetString()!);
        string description = cve.GetProperty("descriptions").EnumerateArray()
            .Select(d => d.GetProperty("value").GetString())
            .FirstOrDefault(s => !string.IsNullOrWhiteSpace(s)) ?? "Sin descripción";

        var dto = new ThreatDto(id, published, lastMod, null, null, description, $"https://nvd.nist.gov/vuln/detail/{id}");
        _cache.Set(cacheKey, dto, TimeSpan.FromSeconds(_cfg.GetValue<int>("Nvd:CacheSeconds", 30)));
        return Ok(dto);
    }
}