# Verificación de Deployment Docker para Render
param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Colors
$Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
}

function Write-CheckResult {
    param(
        [string]$Check,
        [bool]$Result,
        [string]$Message = ""
    )
    
    $status = if ($Result) { "✓" } else { "✗" }
    $color = if ($Result) { $Colors.Success } else { $Colors.Error }
    
    Write-Host "$status $Check" -ForegroundColor $color
    if ($Message -and $Verbose) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

Write-Host "🔍 Verificando configuración de Docker para Render" -ForegroundColor $Colors.Info
Write-Host ""

# 1. Verificar archivos requeridos
$requiredFiles = @(
    "Dockerfile",
    "render.yaml",
    "docker-compose.yml",
    ".dockerignore",
    "config/puma_render.rb",
    "app/controllers/health_controller.rb"
)

foreach ($file in $requiredFiles) {
    $exists = Test-Path $file
    Write-CheckResult "Archivo $file" $exists
}

# 2. Verificar Dockerfile
Write-Host ""
Write-Host "📋 Verificando Dockerfile..." -ForegroundColor $Colors.Info

try {
    $dockerfileContent = Get-Content "Dockerfile" -Raw
    
    $checks = @{
        "Multi-stage build" = $dockerfileContent -match "FROM.*AS"
        "Ruby 3.4.2" = $dockerfileContent -match "ruby:3\.4\.2"
        "Alpine base" = $dockerfileContent -match "alpine"
        "EXPOSE 3000" = $dockerfileContent -match "EXPOSE 3000"
        "Puma command" = $dockerfileContent -match "puma.*puma_render\.rb"
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        Write-CheckResult $check.Key $check.Value
    }
} catch {
    Write-CheckResult "Lectura de Dockerfile" $false "Error: $_"
}

# 3. Verificar render.yaml
Write-Host ""
Write-Host "📋 Verificando render.yaml..." -ForegroundColor $Colors.Info

try {
    $renderContent = Get-Content "render.yaml" -Raw
    
    $checks = @{
        "Environment Docker" = $renderContent -match "env:\s*docker"
        "Dockerfile path" = $renderContent -match "dockerfilePath:"
        "Health check" = $renderContent -match "healthCheckPath:"
        "Database service" = $renderContent -match "type:\s*postgres" -or $renderContent -match "databases:"
        "Redis service" = $renderContent -match "type:\s*redis"
        "Auto deploy" = $renderContent -match "autoDeploy:"
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        Write-CheckResult $check.Key $check.Value
    }
    
    # Warning si todavía tiene placeholder
    if ($renderContent -match "tu-usuario") {
        Write-Host "⚠️  Actualiza la URL del repositorio en render.yaml" -ForegroundColor $Colors.Warning
    }
} catch {
    Write-CheckResult "Lectura de render.yaml" $false "Error: $_"
}

# 4. Verificar docker-compose.yml
Write-Host ""
Write-Host "📋 Verificando docker-compose.yml..." -ForegroundColor $Colors.Info

try {
    $composeContent = Get-Content "docker-compose.yml" -Raw
    
    $checks = @{
        "Build context" = $composeContent -match "build:"
        "PostgreSQL service" = $composeContent -match "postgres:"
        "Redis service" = $composeContent -match "redis:"
        "Health checks" = $composeContent -match "healthcheck:"
        "Volume mounts" = $composeContent -match "volumes:"
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        Write-CheckResult $check.Key $check.Value
    }
} catch {
    Write-CheckResult "Lectura de docker-compose.yml" $false "Error: $_"
}

# 5. Verificar configuración de rutas
Write-Host ""
Write-Host "📋 Verificando rutas..." -ForegroundColor $Colors.Info

try {
    $routesContent = Get-Content "config/routes.rb" -Raw
    
    $checks = @{
        "Health endpoint /health" = $routesContent -match "get\s+['\"]health['\"]"
        "Rails health /up" = $routesContent -match "get\s+['\"]up['\"]"
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        Write-CheckResult $check.Key $check.Value
    }
} catch {
    Write-CheckResult "Lectura de routes.rb" $false "Error: $_"
}

# 6. Verificar Git
Write-Host ""
Write-Host "📋 Verificando Git..." -ForegroundColor $Colors.Info

try {
    $gitStatus = git status --porcelain 2>$null
    $hasRemote = git remote get-url origin 2>$null
    
    Write-CheckResult "Repositorio Git inicializado" ($LASTEXITCODE -eq 0)
    Write-CheckResult "Remote origin configurado" ($hasRemote -ne $null)
    
    if ($gitStatus) {
        Write-Host "⚠️  Hay cambios sin commitear" -ForegroundColor $Colors.Warning
        if ($Verbose) {
            Write-Host "  Archivos modificados:" -ForegroundColor Gray
            $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    } else {
        Write-CheckResult "Working directory limpio" $true
    }
} catch {
    Write-CheckResult "Git disponible" $false
}

# 7. Verificar Docker (opcional)
Write-Host ""
Write-Host "📋 Verificando Docker (opcional)..." -ForegroundColor $Colors.Info

try {
    $dockerVersion = docker --version 2>$null
    Write-CheckResult "Docker instalado" ($LASTEXITCODE -eq 0) $dockerVersion
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   💡 Puedes probar localmente con: docker-compose up" -ForegroundColor $Colors.Info
    }
} catch {
    Write-CheckResult "Docker disponible" $false "No es requerido para Render"
}

# 8. Resumen final
Write-Host ""
Write-Host "📊 Resumen:" -ForegroundColor $Colors.Info

$allFilesExist = $requiredFiles | ForEach-Object { Test-Path $_ } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count
$readyForDeploy = $allFilesExist -eq 0

if ($readyForDeploy) {
    Write-Host "✅ ¡Tu proyecto está listo para deployment en Render!" -ForegroundColor $Colors.Success
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor $Colors.Info
    Write-Host "1. Ejecuta: ./deploy_to_render.ps1" -ForegroundColor White
    Write-Host "2. O manualmente:" -ForegroundColor White
    Write-Host "   - Ve a https://render.com" -ForegroundColor White
    Write-Host "   - Haz clic en 'New' → 'Blueprint'" -ForegroundColor White
    Write-Host "   - Conecta tu repositorio de GitHub" -ForegroundColor White
    Write-Host "   - Render detectará automáticamente render.yaml" -ForegroundColor White
} else {
    Write-Host "❌ Faltan archivos requeridos. Revisa los errores arriba." -ForegroundColor $Colors.Error
}

Write-Host ""
Write-Host "📚 Documentación:" -ForegroundColor $Colors.Info
Write-Host "- DOCKER_RENDER_DEPLOYMENT.md - Guía completa" -ForegroundColor White
Write-Host "- RENDER_DEPLOYMENT.md - Guía general" -ForegroundColor White
