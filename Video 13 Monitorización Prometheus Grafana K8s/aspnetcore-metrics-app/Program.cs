using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Configurar para escuchar en todas las interfaces
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(8080);
});

builder.Services.AddControllers();

var app = builder.Build();
app.UseRouting();

// Habilita el endpoint /metrics
app.UseMetricServer();
app.UseHttpMetrics(); // Prometheus middleware

app.MapGet("/", () => "Hello, metrics!");
app.MapGet("/health", () => "OK");
app.MapMetrics(); // Expose /metrics
app.Run();