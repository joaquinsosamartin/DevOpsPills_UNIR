# NVD Proxy API (.NET 8)
Proxy hacia la API pública de NVD (CVE 2.0).

## Ejecutar
```bash
dotnet run --project NvdProxyApi
```

### Endpoints
- GET /api/threats?limit=5&keyword=kubernetes
- GET /api/threats/CVE-2024-12345

## Docker
```bash
docker build -t nvd-proxy .
docker run -p 8080:8080 nvd-proxy
```