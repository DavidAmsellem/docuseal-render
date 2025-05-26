# DocuSeal Render Deployment Script for Windows PowerShell
param(
    [switch]$Force = $false
)

# Colors for output
$Colors = @{
    Info = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
}

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error
}

Write-Host "🚀 Iniciando deployment de DocuSeal en Render con Docker" -ForegroundColor $Colors.Info

# Check if git repo is clean
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Warning "Hay cambios sin commitear en el repositorio."
    if (-not $Force) {
        $response = Read-Host "¿Deseas continuar? (y/N)"
        if ($response -notmatch '^[Yy]$') {
            Write-Error "Deployment cancelado por el usuario."
            exit 1
        }
    }
}

# Check if render.yaml exists
if (-not (Test-Path "render.yaml")) {
    Write-Error "No se encontró render.yaml. ¿Estás en el directorio correcto?"
    exit 1
}

# Check if Dockerfile exists
if (-not (Test-Path "Dockerfile")) {
    Write-Error "No se encontró Dockerfile. ¿Estás en el directorio correcto?"
    exit 1
}

Write-Status "Verificando configuración..."

# Validate Dockerfile
Write-Status "Validando Dockerfile..."
try {
    $null = docker build --no-cache -f Dockerfile . -t docuseal-test 2>$null
    Write-Success "Dockerfile válido ✓"
    
    # Clean up test image
    docker rmi docuseal-test 2>$null | Out-Null
} catch {
    Write-Error "Error al construir la imagen Docker localmente."
    Write-Error "Por favor, verifica tu Dockerfile y resuelve los errores antes de continuar."
    exit 1
}

# Check git remote
try {
    $repoUrl = git remote get-url origin
    Write-Status "Repositorio: $repoUrl"
} catch {
    Write-Error "No se encontró remote origin. Configura tu repositorio Git primero."
    exit 1
}

# Update render.yaml with correct repo URL if needed
$renderContent = Get-Content "render.yaml" -Raw
if ($renderContent -match "tu-usuario") {
    Write-Warning "render.yaml contiene placeholder 'tu-usuario'"
    Write-Warning "Actualiza el repositorio en render.yaml manualmente antes de continuar."
    Write-Warning "Cambia: https://github.com/tu-usuario/docuseal.git"
    Write-Warning "Por tu URL real: $repoUrl"
}

# Commit and push changes
Write-Status "Preparando código para deployment..."

# Add all changes
git add .

# Check if there are changes to commit
$stagedChanges = git diff --staged --quiet; $LASTEXITCODE -ne 0
if (-not $stagedChanges) {
    Write-Status "No hay cambios para commitear."
} else {
    # Commit changes
    $commitMsg = "Configure Docker deployment for Render - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m $commitMsg
    Write-Success "Cambios commiteados: $commitMsg"
}

# Push to origin
Write-Status "Subiendo cambios a GitHub..."
$currentBranch = git branch --show-current
git push origin $currentBranch
Write-Success "Código subido a repositorio ✓"

Write-Host ""
Write-Success "🎉 ¡Preparación completa!"
Write-Host ""
Write-Host "Próximos pasos:"
Write-Host "1. Ve a https://render.com"
Write-Host "2. Haz clic en 'New' → 'Blueprint'"
Write-Host "3. Conecta tu repositorio de GitHub"
Write-Host "4. Render detectará automáticamente el archivo render.yaml"
Write-Host "5. Configura las variables de entorno si es necesario"
Write-Host "6. Haz clic en 'Apply' para iniciar el deployment"
Write-Host ""
Write-Host "Variables de entorno que se configuran automáticamente:"
Write-Host "  ✓ SECRET_KEY_BASE (generada automáticamente)"
Write-Host "  ✓ DATABASE_URL (desde PostgreSQL service)"
Write-Host "  ✓ REDIS_URL (desde Redis service)"
Write-Host "  ✓ RAILS_ENV=production"
Write-Host "  ✓ RAILS_SERVE_STATIC_FILES=true"
Write-Host ""
Write-Host "Tu aplicación estará disponible en: https://docuseal.onrender.com"
Write-Host "(o el nombre que hayas configurado)"
Write-Host ""
Write-Status "Para monitorear el deployment, ve a Render Dashboard → Logs"
