# PowerShell Script para deployment de DocuSeal en Fly.io
# Autor: GitHub Copilot
# Fecha: 27 de Mayo de 2025

param(
    [string]$AppName = "",
    [string]$Region = "mad",
    [switch]$SkipBuild = $false,
    [switch]$Help = $false
)

# Mostrar ayuda
if ($Help) {
    Write-Host @"
🚀 Script de Deployment de DocuSeal para Fly.io

USAGE:
    .\deploy_to_fly.ps1 [-AppName <nombre>] [-Region <región>] [-SkipBuild] [-Help]

PARAMETERS:
    -AppName     Nombre de la aplicación en Fly.io (opcional, se genera automáticamente)
    -Region      Región de deployment (default: mad - Madrid)
    -SkipBuild   Omitir la construcción de Docker (para deploys rápidos)
    -Help        Mostrar esta ayuda

EXAMPLES:
    .\deploy_to_fly.ps1
    .\deploy_to_fly.ps1 -AppName "mi-docuseal" -Region "fra"
    .\deploy_to_fly.ps1 -SkipBuild

REQUIREMENTS:
    - flyctl instalado y configurado
    - Docker Desktop ejecutándose
    - Cuenta de Fly.io autenticada
"@
    exit 0
}

# Función para logging con colores
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "INFO"    { Write-Host "[$timestamp] " -ForegroundColor Gray -NoNewline; Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host "[$timestamp] " -ForegroundColor Gray -NoNewline; Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[$timestamp] " -ForegroundColor Gray -NoNewline; Write-Host "❌ $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[$timestamp] " -ForegroundColor Gray -NoNewline; Write-Host "✅ $Message" -ForegroundColor Cyan }
    }
}

# Función para verificar comandos
function Test-Command {
    param([string]$Command)
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Banner de inicio
Write-Host @"

 ____             _   _  ____            _ 
|  _ \  ___   ___| | | |/ ___|  ___  __ _| |
| | | |/ _ \ / __| | | |\___ \ / _ \/ _\` | |
| |_| | (_) | (__| |_| | ___) |  __/ (_| | |
|____/ \___/ \___|\___/|____/ \___|\__,_|_|
                                           
🚀 Deployment Script para Fly.io

"@ -ForegroundColor Cyan

Write-Log "Iniciando deployment de DocuSeal en Fly.io..." "INFO"

# Verificaciones preliminares
Write-Log "Verificando requisitos del sistema..." "INFO"

# Verificar flyctl
if (-not (Test-Command "flyctl")) {
    Write-Log "flyctl no está instalado. Descárgalo desde: https://fly.io/docs/getting-started/installing-flyctl/" "ERROR"
    exit 1
}

# Verificar autenticación en Fly.io
try {
    $authCheck = flyctl auth whoami 2>$null
    if (-not $authCheck) {
        Write-Log "No estás logueado en Fly.io. Ejecuta: flyctl auth login" "ERROR"
        exit 1
    }
    Write-Log "Autenticado en Fly.io como: $authCheck" "SUCCESS"
}
catch {
    Write-Log "Error verificando autenticación en Fly.io" "ERROR"
    exit 1
}

# Verificar Docker
try {
    docker info 2>$null | Out-Null
    Write-Log "Docker está ejecutándose correctamente" "SUCCESS"
}
catch {
    Write-Log "Docker no está ejecutándose. Inicia Docker Desktop y vuelve a intentar." "ERROR"
    exit 1
}

# Generar nombre de aplicación si no se especifica
if (-not $AppName) {
    $username = $env:USERNAME
    $AppName = "docuseal-$username".ToLower() -replace '[^a-z0-9-]', '-'
    Write-Log "Nombre de aplicación generado: $AppName" "INFO"
}

Write-Log "Configuración del deployment:" "INFO"
Write-Host "  📱 Aplicación: $AppName"
Write-Host "  🌍 Región: $Region"
Write-Host "  🐳 Skip Build: $SkipBuild"
Write-Host ""

# Crear aplicación si no existe
Write-Log "Verificando si la aplicación existe..." "INFO"
$appExists = flyctl apps list 2>$null | Select-String $AppName

if (-not $appExists) {
    Write-Log "Creando nueva aplicación en Fly.io..." "INFO"
    try {
        flyctl apps create $AppName --region $Region
        Write-Log "Aplicación '$AppName' creada exitosamente" "SUCCESS"
    }
    catch {
        Write-Log "Error creando la aplicación: $_" "ERROR"
        exit 1
    }
}
else {
    Write-Log "Usando aplicación existente: $AppName" "INFO"
}

# Actualizar fly.toml
Write-Log "Actualizando configuración fly.toml..." "INFO"
$flyTomlContent = Get-Content "fly.toml" -Raw
$flyTomlContent = $flyTomlContent -replace 'app = ".*"', "app = `"$AppName`""
$flyTomlContent = $flyTomlContent -replace 'primary_region = ".*"', "primary_region = `"$Region`""
Set-Content "fly.toml" $flyTomlContent

# Configurar variables de entorno
Write-Log "Configurando variables de entorno..." "INFO"

# Generar SECRET_KEY_BASE si no existe
try {
    $secretExists = flyctl secrets list --app $AppName 2>$null | Select-String "SECRET_KEY_BASE"
    if (-not $secretExists) {
        $secretKey = -join ((1..64) | ForEach { '{0:X}' -f (Get-Random -Maximum 16) })
        flyctl secrets set SECRET_KEY_BASE=$secretKey --app $AppName
        Write-Log "SECRET_KEY_BASE configurado" "SUCCESS"
    }
}
catch {
    Write-Log "Error configurando SECRET_KEY_BASE: $_" "WARNING"
}

# Variables de entorno para producción
$envVars = @{
    "RAILS_ENV" = "production"
    "RAILS_SERVE_STATIC_FILES" = "true"
    "RAILS_LOG_TO_STDOUT" = "true"
    "WEB_CONCURRENCY" = "2"
    "RAILS_MAX_THREADS" = "5"
    "FORCE_SSL" = "true"
}

foreach ($env in $envVars.GetEnumerator()) {
    try {
        flyctl secrets set "$($env.Key)=$($env.Value)" --app $AppName
    }
    catch {
        Write-Log "Error configurando $($env.Key): $_" "WARNING"
    }
}

Write-Log "Variables de entorno configuradas" "SUCCESS"

# Configurar base de datos PostgreSQL
Write-Log "Configurando base de datos PostgreSQL..." "INFO"
$dbName = "$AppName-db"

$dbExists = flyctl postgres list 2>$null | Select-String $dbName
if (-not $dbExists) {
    Write-Log "Creando nueva base de datos PostgreSQL..." "INFO"
    try {
        flyctl postgres create --name $dbName --region $Region --vm-size shared-cpu-1x --volume-size 3
        flyctl postgres attach $dbName --app $AppName
        Write-Log "Base de datos '$dbName' creada y adjuntada" "SUCCESS"
    }
    catch {
        Write-Log "Error configurando base de datos: $_" "WARNING"
    }
}
else {
    Write-Log "Usando base de datos existente: $dbName" "INFO"
}

# Configurar volumen para almacenamiento
Write-Log "Configurando almacenamiento persistente..." "INFO"
$volumeName = "$AppName-data"

$volumeExists = flyctl volumes list --app $AppName 2>$null | Select-String $volumeName
if (-not $volumeExists) {
    Write-Log "Creando volumen para datos persistentes..." "INFO"
    try {
        flyctl volumes create $volumeName --size 10gb --region $Region --app $AppName
        Write-Log "Volumen '$volumeName' creado" "SUCCESS"
    }
    catch {
        Write-Log "Error creando volumen: $_" "WARNING"
    }
}
else {
    Write-Log "Usando volumen existente: $volumeName" "INFO"
}

# Agregar configuración de volumen a fly.toml si no existe
$flyTomlContent = Get-Content "fly.toml" -Raw
if (-not ($flyTomlContent -match "\[\[mounts\]\]")) {
    $mountConfig = @"

[[mounts]]
  source = "$volumeName"
  destination = "/data"
"@
    Add-Content "fly.toml" $mountConfig
    Write-Log "Configuración de volumen agregada a fly.toml" "SUCCESS"
}

# Deployment
Write-Log "🚀 Iniciando deployment..." "INFO"

$deployArgs = @(
    "deploy"
    "--app", $AppName
    "--config", "fly.toml"
    "--dockerfile", "Dockerfile"
    "--build-arg", "RAILS_ENV=production"
)

if ($SkipBuild) {
    $deployArgs += "--no-build-cache"
}

try {
    & flyctl @deployArgs
    Write-Log "Deployment completado exitosamente!" "SUCCESS"
}
catch {
    Write-Log "Error durante el deployment: $_" "ERROR"
    exit 1
}

# Verificar health checks
Write-Log "Verificando estado de la aplicación..." "INFO"
$maxAttempts = 30
$attempt = 0

do {
    Start-Sleep -Seconds 10
    $attempt++
    $status = flyctl status --app $AppName 2>$null
    
    if ($status -match "healthy") {
        Write-Log "Aplicación saludable!" "SUCCESS"
        break
    }
    
    Write-Log "Esperando health check... (intento $attempt/$maxAttempts)" "INFO"
} while ($attempt -lt $maxAttempts)

# Obtener URL de la aplicación
$appInfo = flyctl info --app $AppName 2>$null
$appUrl = ($appInfo | Select-String "https://.*\.fly\.dev").Matches.Value

# Resumen final
Write-Host @"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 DocuSeal desplegado exitosamente en Fly.io!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Aplicación: $AppName
🌍 URL: $appUrl
🗄️ Base de datos: $dbName
💾 Volumen: $volumeName
🌍 Región: $Region
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Comandos útiles:
  flyctl logs --app $AppName
  flyctl status --app $AppName
  flyctl ssh console --app $AppName -C "rails console"
  flyctl scale count 2 --app $AppName

"@ -ForegroundColor Green

# Abrir en navegador
if ($appUrl) {
    Write-Log "Abriendo aplicación en el navegador..." "INFO"
    Start-Process $appUrl
}

Write-Log "🎊 ¡Deployment completado! Tu aplicación DocuSeal está lista." "SUCCESS"
