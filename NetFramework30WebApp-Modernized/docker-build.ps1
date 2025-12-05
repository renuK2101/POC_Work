# Docker build script for NetFramework30WebApp-Modernized
# This script builds the Docker container image

param(
    [string]$Tag = "netframework30webapp-modernized:latest",
    [string]$Registry = ""
)

Write-Host "Building Docker image for NetFramework30WebApp-Modernized..." -ForegroundColor Cyan

$ImageName = if ($Registry) { "$Registry/$Tag" } else { $Tag }

Write-Host "Image name: $ImageName" -ForegroundColor Yellow

# Build the Docker image
docker build -t $ImageName -f Dockerfile ..

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Docker image built successfully!" -ForegroundColor Green
    Write-Host "Image: $ImageName" -ForegroundColor Green
    
    # Show image details
    Write-Host "`nImage details:" -ForegroundColor Cyan
    docker images $ImageName
    
    if ($Registry) {
        Write-Host "`nTo push to registry, run:" -ForegroundColor Yellow
        Write-Host "docker push $ImageName" -ForegroundColor White
    }
} else {
    Write-Host "✗ Docker build failed!" -ForegroundColor Red
    exit 1
}
