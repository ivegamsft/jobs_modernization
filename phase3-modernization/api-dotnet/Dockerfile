# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/JobSite.Api/JobSite.Api.csproj", "src/JobSite.Api/"]
COPY ["src/JobSite.Core/JobSite.Core.csproj", "src/JobSite.Core/"]
COPY ["src/JobSite.Application/JobSite.Application.csproj", "src/JobSite.Application/"]
COPY ["src/JobSite.Infrastructure/JobSite.Infrastructure.csproj", "src/JobSite.Infrastructure/"]

RUN dotnet restore "src/JobSite.Api/JobSite.Api.csproj"

COPY . .
WORKDIR "/src/src/JobSite.Api"
RUN dotnet build "JobSite.Api.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "JobSite.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=publish /app/publish .

ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

ENTRYPOINT ["dotnet", "JobSite.Api.dll"]
