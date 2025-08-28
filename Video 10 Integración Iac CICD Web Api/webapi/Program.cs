using Microsoft.Extensions.Caching.Memory;
using Polly;
using Polly.Extensions.Http;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddMemoryCache();

static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy() =>
    HttpPolicyExtensions.HandleTransientHttpError()
        .OrResult(msg => (int)msg.StatusCode == 429)
        .WaitAndRetryAsync(3, retryAttempt => TimeSpan.FromMilliseconds(200 * retryAttempt));

var baseUrl = builder.Configuration.GetValue<string>("Nvd:BaseUrl") ?? "https://services.nvd.nist.gov/rest/json/cves/2.0";
builder.Services.AddHttpClient("nvd", client =>
{
    client.BaseAddress = new Uri(baseUrl);
    client.DefaultRequestHeaders.UserAgent.ParseAdd("NvdProxyApi/1.0");
}).AddPolicyHandler(GetRetryPolicy());

var app = builder.Build();
app.MapControllers();
app.Run();