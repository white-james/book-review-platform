#Requires -Version 5.1
<#
.SYNOPSIS
    Book Review Platform - Development Setup Script

.DESCRIPTION
    This PowerShell script helps you get started with the Book Review Platform quickly.
    It provides commands to build, start, stop, and manage the Docker containers.

.PARAMETER Command
    The command to execute. Valid options: start, stop, restart, logs, clean, build, status, help

.EXAMPLE
    .\start.ps1 start
    Builds and starts all services

.EXAMPLE
    .\start.ps1 logs
    Shows logs from all services

.NOTES
    Requires Docker Desktop to be installed and running
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('start', 'stop', 'restart', 'logs', 'clean', 'build', 'status', 'push', 'help')]
    [string]$Command = 'start',
    
    [Parameter()]
    [string]$AcrName = 'bookreviewdevacr'
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $Reset
    )
    Write-Host "$Color$Message$Reset"
}

function Show-Header {
    Write-ColorOutput "🚀 Book Review Platform - Setup & Start Script" $Blue
    Write-ColorOutput "=================================================" $Blue
}

function Test-DockerRunning {
    try {
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker command failed"
        }
        Write-ColorOutput "✅ Docker is running" $Green
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker is not running. Please start Docker Desktop and try again." $Red
        exit 1
    }
}

function Test-DockerCompose {
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose command failed"
        }
        Write-ColorOutput "✅ Docker Compose is available" $Green
        return $true
    }
    catch {
        Write-ColorOutput "❌ Docker Compose is not installed. Please install Docker Compose and try again." $Red
        exit 1
    }
}

function Show-ServiceUrls {
    Write-Host ""
    Write-ColorOutput "📋 Service URLs:" $Yellow
    Write-Host "   Frontend: http://localhost:8080"
    Write-Host "   API:      http://localhost:3000"
    Write-Host "   Database: localhost:5432"
    Write-Host ""
    Write-ColorOutput "📊 To view logs: " $Yellow -NoNewline
    Write-Host ".\start.ps1 logs"
    Write-ColorOutput "🛑 To stop:      " $Yellow -NoNewline
    Write-Host ".\start.ps1 stop"
}

function Show-Usage {
    Write-Host ""
    Write-ColorOutput "Usage: .\start.ps1 [COMMAND]" $Blue
    Write-Host ""
    Write-ColorOutput "Commands:" $Blue
    Write-Host "  start       Build and start all services (default)"
    Write-Host "  stop        Stop all services"
    Write-Host "  restart     Restart all services"
    Write-Host "  logs        Show logs from all services"
    Write-Host "  clean       Stop services and remove volumes"
    Write-Host "  build       Build all images"
    Write-Host "  status      Show status of all services"
    Write-Host "  push        Build, tag, and push images to Azure Container Registry"
    Write-Host "  help        Show this help message"
    Write-Host ""
    Write-ColorOutput "Parameters:" $Blue
    Write-Host "  -AcrName    Azure Container Registry name (default: bookreviewdevacr)"
    Write-Host ""
}

function Start-Services {
    Write-ColorOutput "🔨 Building and starting all services..." $Yellow
    
    try {
        docker-compose up --build -d
        if ($LASTEXITCODE -ne 0) {
            throw "Docker compose failed"
        }
        
        Write-Host ""
        Write-ColorOutput "🎉 Services are starting up!" $Green
        Show-ServiceUrls
    }
    catch {
        Write-ColorOutput "❌ Failed to start services: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Stop-Services {
    Write-ColorOutput "🛑 Stopping all services..." $Yellow
    
    try {
        docker-compose down
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ All services stopped" $Green
        } else {
            Write-ColorOutput "⚠️  Some services may not have stopped cleanly" $Yellow
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to stop services: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Restart-Services {
    Write-ColorOutput "🔄 Restarting all services..." $Yellow
    
    try {
        docker-compose down
        docker-compose up --build -d
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ All services restarted" $Green
            Show-ServiceUrls
        } else {
            throw "Failed to restart services"
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to restart services: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Show-Logs {
    Write-ColorOutput "📋 Showing logs from all services (Ctrl+C to exit)..." $Yellow
    Write-Host ""
    
    try {
        docker-compose logs -f
    }
    catch {
        Write-ColorOutput "❌ Failed to show logs: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Clean-Environment {
    Write-ColorOutput "🧹 Stopping services and cleaning up..." $Yellow
    
    try {
        docker-compose down -v
        docker system prune -f
        Write-ColorOutput "✅ Cleanup complete" $Green
    }
    catch {
        Write-ColorOutput "❌ Failed to clean environment: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Build-Images {
    Write-ColorOutput "🔨 Building all images..." $Yellow
    
    try {
        docker-compose build
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Build complete" $Green
        } else {
            throw "Build failed"
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to build images: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Show-Status {
    Write-ColorOutput "📊 Service Status:" $Blue
    Write-Host ""
    
    try {
        docker-compose ps
    }
    catch {
        Write-ColorOutput "❌ Failed to get service status: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Push-ToAcr {
    param(
        [string]$RegistryName
    )
    
    Write-ColorOutput "📦 Pushing images to Azure Container Registry: $RegistryName" $Yellow
    Write-Host ""
    
    # Login to ACR
    Write-ColorOutput "🔐 Logging into Azure Container Registry..." $Blue
    try {
        az acr login --name $RegistryName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to login to ACR"
        }
        Write-ColorOutput "✅ Successfully logged into ACR" $Green
    }
    catch {
        Write-ColorOutput "❌ Failed to login to ACR. Make sure Azure CLI is installed and you're authenticated." $Red
        Write-ColorOutput "   Run: az login" $Yellow
        exit 1
    }
    
    # Build images
    Write-ColorOutput "🔨 Building images..." $Blue
    try {
        docker-compose build
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        Write-ColorOutput "✅ Images built successfully" $Green
    }
    catch {
        Write-ColorOutput "❌ Failed to build images: $($_.Exception.Message)" $Red
        exit 1
    }
    
    # Tag and push images
    $registryUrl = "$RegistryName.azurecr.io"
    $images = @(
        @{Local = "book-review-platform-postgres"; Remote = "postgres-custom"},
        @{Local = "book-review-platform-book-api"; Remote = "book-api"},
        @{Local = "book-review-platform-book-ui"; Remote = "book-ui"}
    )
    
    Write-Host ""
    Write-ColorOutput "🏷️  Tagging and pushing images..." $Blue
    
    foreach ($image in $images) {
        $localTag = "$($image.Local):latest"
        $remoteTag = "$registryUrl/$($image.Remote):latest"
        
        try {
            Write-Host "   Tagging $localTag -> $remoteTag"
            docker tag $localTag $remoteTag
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to tag image"
            }
            
            Write-Host "   Pushing $remoteTag"
            docker push $remoteTag
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to push image"
            }
            
            Write-ColorOutput "   ✅ $($image.Remote) pushed successfully" $Green
        }
        catch {
            Write-ColorOutput "   ❌ Failed to push $($image.Remote): $($_.Exception.Message)" $Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-ColorOutput "🎉 All images successfully pushed to $registryUrl" $Green
}

# Main execution
try {
    Show-Header
    Test-DockerRunning
    Test-DockerCompose

    switch ($Command.ToLower()) {
        'start' {
            Start-Services
        }
        'stop' {
            Stop-Services
        }
        'restart' {
            Restart-Services
        }
        'logs' {
            Show-Logs
        }
        'clean' {
            Clean-Environment
        }
        'build' {
            Build-Images
        }
        'status' {
            Show-Status
        }
        'push' {
            Push-ToAcr -RegistryName $AcrName
        }
        'help' {
            Show-Usage
        }
        default {
            Write-ColorOutput "❌ Unknown command: $Command" $Red
            Show-Usage
            exit 1
        }
    }
}
catch {
    Write-ColorOutput "❌ An unexpected error occurred: $($_.Exception.Message)" $Red
    exit 1
}