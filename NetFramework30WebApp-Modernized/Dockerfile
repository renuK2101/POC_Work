# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY NetFramework30WebApp-Modernized.csproj ./
RUN dotnet restore "NetFramework30WebApp-Modernized.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "NetFramework30WebApp-Modernized.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "NetFramework30WebApp-Modernized.csproj" -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Expose port 8080 (Container Apps default)
EXPOSE 8080

# Create non-root user for security
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Copy published app from publish stage
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8080/health || exit 1

# Start the application
ENTRYPOINT ["dotnet", "NetFramework30WebApp-Modernized.dll"]