# Local run script for NetFramework30WebApp-Modernized
# This script runs the application locally for testing

param(
    [switch]$Docker,
    [string]$Port = "5000"
)

Write-Host "Starting NetFramework30WebApp-Modernized..." -ForegroundColor Cyan

if ($Docker) {
    # Run in Docker
    Write-Host "Running in Docker container..." -ForegroundColor Yellow
    Write-Host "Port: $Port" -ForegroundColor Yellow
    
    # Stop any existing container
    docker stop netframework30webapp-modernized 2>$null
    docker rm netframework30webapp-modernized 2>$null
    
    # Run the container
    docker run -d `
        --name netframework30webapp-modernized `
        -p "${Port}:8080" `
        -e ASPNETCORE_ENVIRONMENT=Development `
        netframework30webapp-modernized:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully!" -ForegroundColor Green
        Write-Host "Application URL: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "Health Check: http://localhost:$Port/health" -ForegroundColor Cyan
        Write-Host "`nTo view logs: docker logs -f netframework30webapp-modernized" -ForegroundColor Yellow
        Write-Host "To stop: docker stop netframework30webapp-modernized" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Failed to start container!" -ForegroundColor Red
        exit 1
    }
} else {
    # Run with dotnet
    Write-Host "Running with dotnet..." -ForegroundColor Yellow
    Write-Host "Port: $Port" -ForegroundColor Yellow
    Write-Host "`nNOTE: Before running, configure appsettings.json with your Azure AD credentials" -ForegroundColor Magenta
    Write-Host "Press Ctrl+C to stop the application`n" -ForegroundColor Yellow
    
    $env:ASPNETCORE_URLS = "http://localhost:$Port"
    dotnet run
}
