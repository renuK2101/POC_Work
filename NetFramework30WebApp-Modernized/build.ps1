# Build script for NetFramework30WebApp-Modernized
# This script builds the .NET 8 application

Write-Host "Building NetFramework30WebApp-Modernized..." -ForegroundColor Cyan

# Clean previous build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
dotnet clean --verbosity quiet

# Restore NuGet packages
Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore --verbosity quiet

# Build the application
Write-Host "Building application..." -ForegroundColor Yellow
dotnet build --configuration Release --no-restore

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit 1
}
