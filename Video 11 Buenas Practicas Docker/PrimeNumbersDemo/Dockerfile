## Dockerfile optimizado con multistage build

# Etapa 1: restaurar dependencias
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS restore
WORKDIR /src

# Copiar únicamente los archivos de proyecto para aprovechar el cache de capas
COPY PrimeNumbersWebApi/*.csproj PrimeNumbersWebApi/
COPY MathLibrary/*.csproj MathLibrary/
COPY MathLibrary.Tests/*.csproj MathLibrary.Tests/
COPY PrimeNumbersWebApi.Tests/*.csproj PrimeNumbersWebApi.Tests/

# Restaurar las dependencias
RUN dotnet restore "PrimeNumbersWebApi/PrimeNumbersWebApi.csproj"

# Etapa 2: compilar la solución
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .

# Compilar toda la solución en modo Release (genera bin/Release/... para todos los proyectos)
RUN dotnet build -c Release

# Etapa 3: ejecutar pruebas
FROM build AS test
WORKDIR /src
RUN dotnet test "MathLibrary.Tests/MathLibrary.Tests.csproj" -c Release --no-build \
    && dotnet test "PrimeNumbersWebApi.Tests/PrimeNumbersWebApi.Tests.csproj" -c Release --no-build

# Etapa 4: publicar la aplicación
FROM build AS publish
RUN dotnet publish "PrimeNumbersWebApi/PrimeNumbersWebApi.csproj" -c Release -o /app/publish --no-build

# Etapa final: runtime optimizada
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Crear un usuario no root para ejecutar la aplicación de forma más segura
RUN useradd -m appuser

# Copiar únicamente los binarios publicados desde la etapa publish
COPY --from=publish /app/publish .

# Establecer el usuario no root
USER appuser

# Exponer el puerto 8080 y definir la URL de escucha de Kestrel
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Punto de entrada
ENTRYPOINT ["dotnet", "PrimeNumbersWebApi.dll"]