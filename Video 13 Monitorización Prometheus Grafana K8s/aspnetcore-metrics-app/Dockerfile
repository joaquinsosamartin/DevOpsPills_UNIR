FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["aspnetcore-metrics-app.csproj", "./"]
RUN dotnet restore "aspnetcore-metrics-app.csproj"
COPY . .
RUN dotnet publish "aspnetcore-metrics-app.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "aspnetcore-metrics-app.dll"]