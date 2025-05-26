# 🚀 Guía de Deployment de DocuSeal en Fly.io

Esta guía te ayudará a desplegar DocuSeal en [Fly.io](https://fly.io), una plataforma moderna de deployment que ofrece excelente performance global y simplicidad de uso.

## 📋 Prerrequisitos

### 1. Instalar Fly.io CLI
```powershell
# Windows (PowerShell)
iwr https://fly.io/install.ps1 -useb | iex

# Verificar instalación
flyctl version
```

### 2. Crear cuenta y autenticarse
```powershell
# Registrarse/iniciar sesión
flyctl auth signup
# o si ya tienes cuenta
flyctl auth login
```

### 3. Verificar Docker
```powershell
# Verificar que Docker está ejecutándose
docker --version
```

## 🏗️ Arquitectura del Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                        Fly.io Edge                         │
├─────────────────────────────────────────────────────────────┤
│  📱 DocuSeal App (Container)                               │
│  ├── Ruby on Rails Application                             │
│  ├── Puma Web Server                                       │
│  ├── Assets & File Storage                                 │
│  └── Health Checks (/health, /up)                          │
├─────────────────────────────────────────────────────────────┤
│  🗄️ PostgreSQL Database                                    │
│  ├── Managed PostgreSQL Instance                           │
│  ├── Automatic Backups                                     │
│  └── Connection Pooling                                    │
├─────────────────────────────────────────────────────────────┤
│  💾 Persistent Storage                                      │
│  ├── Volume for uploads                                    │
│  ├── Document storage                                      │
│  └── Application data                                      │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Deployment Automático

### Opción 1: Script PowerShell (Recomendado para Windows)
```powershell
# Deployment completo automático
.\deploy_to_fly.ps1

# Con parámetros personalizados
.\deploy_to_fly.ps1 -AppName "mi-docuseal" -Region "fra"

# Ver ayuda
.\deploy_to_fly.ps1 -Help
```

### Opción 2: Script Bash (Linux/Mac/WSL)
```bash
# Hacer ejecutable
chmod +x bin/deploy_to_fly

# Ejecutar deployment
./bin/deploy_to_fly
```

## 🔧 Deployment Manual Paso a Paso

### 1. Crear aplicación
```powershell
# Crear nueva app
flyctl apps create docuseal-tuusuario --region mad

# O usar un nombre específico
flyctl apps create mi-docuseal-app --region mad
```

### 2. Configurar variables de entorno
```powershell
# Variables obligatorias
flyctl secrets set SECRET_KEY_BASE="$(openssl rand -hex 64)" --app tu-app-name

# Variables de configuración
flyctl secrets set `
  RAILS_ENV=production `
  RAILS_SERVE_STATIC_FILES=true `
  RAILS_LOG_TO_STDOUT=true `
  WEB_CONCURRENCY=2 `
  RAILS_MAX_THREADS=5 `
  FORCE_SSL=true `
  --app tu-app-name
```

### 3. Crear base de datos
```powershell
# Crear PostgreSQL
flyctl postgres create --name docuseal-db --region mad --vm-size shared-cpu-1x --volume-size 3

# Adjuntar a la aplicación
flyctl postgres attach docuseal-db --app tu-app-name
```

### 4. Crear almacenamiento persistente
```powershell
# Crear volumen para archivos
flyctl volumes create docuseal_data --size 10gb --region mad --app tu-app-name
```

### 5. Configurar fly.toml
Actualiza el archivo `fly.toml` con tu nombre de aplicación:
```toml
app = "tu-app-name"
primary_region = "mad"

[[mounts]]
  source = "docuseal_data"
  destination = "/data"
```

### 6. Desplegar
```powershell
flyctl deploy --app tu-app-name
```

## 🌍 Regiones Disponibles

| Código | Ciudad | País |
|--------|--------|------|
| `mad` | Madrid | España |
| `fra` | Frankfurt | Alemania |
| `lhr` | Londres | Reino Unido |
| `cdg` | París | Francia |
| `ams` | Amsterdam | Países Bajos |
| `iad` | Ashburn | Estados Unidos |
| `lax` | Los Angeles | Estados Unidos |
| `nrt` | Tokyo | Japón |
| `syd` | Sydney | Australia |

```powershell
# Ver todas las regiones disponibles
flyctl platform regions
```

## 📊 Monitoreo y Mantenimiento

### Logs en tiempo real
```powershell
# Ver logs
flyctl logs --app tu-app-name

# Seguir logs en vivo
flyctl logs -f --app tu-app-name
```

### Estado de la aplicación
```powershell
# Estado general
flyctl status --app tu-app-name

# Información detallada
flyctl info --app tu-app-name
```

### Consola Rails
```powershell
# Acceder a Rails console
flyctl ssh console --app tu-app-name -C "rails console"

# Ejecutar migraciones
flyctl ssh console --app tu-app-name -C "rails db:migrate"
```

### Scaling
```powershell
# Escalar horizontalmente (más instancias)
flyctl scale count 2 --app tu-app-name

# Escalar verticalmente (más recursos)
flyctl scale memory 1024 --app tu-app-name
flyctl scale vm dedicated-cpu-1x --app tu-app-name
```

## 🔒 Configuración de Seguridad

### Variables de entorno adicionales
```powershell
# Configurar autenticación externa (opcional)
flyctl secrets set `
  OAUTH_GOOGLE_CLIENT_ID=tu_google_client_id `
  OAUTH_GOOGLE_CLIENT_SECRET=tu_google_secret `
  --app tu-app-name

# Configurar SMTP (opcional)
flyctl secrets set `
  SMTP_ADDRESS=tu_smtp_server `
  SMTP_PORT=587 `
  SMTP_USERNAME=tu_usuario `
  SMTP_PASSWORD=tu_password `
  --app tu-app-name
```

### Certificados SSL
Fly.io maneja automáticamente los certificados SSL. Tu aplicación estará disponible con HTTPS desde el primer deployment.

## 🎯 Configuraciones de Rendimiento

### Configuración recomendada por tamaño de uso

#### Uso Pequeño (1-10 usuarios)
```powershell
flyctl scale vm shared-cpu-1x --memory 512 --app tu-app-name
```

#### Uso Medio (10-50 usuarios)
```powershell
flyctl scale vm shared-cpu-1x --memory 1024 --app tu-app-name
flyctl scale count 2 --app tu-app-name
```

#### Uso Grande (50+ usuarios)
```powershell
flyctl scale vm dedicated-cpu-1x --memory 2048 --app tu-app-name
flyctl scale count 3 --app tu-app-name
```

## 🔄 Actualizaciones

### Deployment automático desde Git
```powershell
# Configurar auto-deploy desde GitHub
flyctl apps create --generate-name
flyctl launch --dockerfile Dockerfile --remote-only
```

### Deployment manual
```powershell
# Actualizar aplicación
git add .
git commit -m "Actualización de DocuSeal"
flyctl deploy --app tu-app-name
```

## 🐛 Troubleshooting

### Problemas comunes

#### Error de base de datos
```powershell
# Reiniciar aplicación
flyctl apps restart tu-app-name

# Verificar conexión DB
flyctl postgres connect --app tu-db-name
```

#### Error de almacenamiento
```powershell
# Verificar volúmenes
flyctl volumes list --app tu-app-name

# Verificar punto de montaje
flyctl ssh console --app tu-app-name -C "ls -la /data"
```

#### Error de memoria
```powershell
# Aumentar memoria
flyctl scale memory 1024 --app tu-app-name

# Ver uso de recursos
flyctl metrics --app tu-app-name
```

### Logs útiles
```powershell
# Logs de error
flyctl logs --app tu-app-name | Select-String "ERROR"

# Logs de la aplicación Rails
flyctl logs --app tu-app-name | Select-String "Rails"

# Logs de Puma
flyctl logs --app tu-app-name | Select-String "Puma"
```

## 💰 Costos Estimados

### Plan gratuito (Hobby)
- ✅ 3 máquinas shared-cpu-1x
- ✅ 160GB de transferencia
- ✅ Certificados SSL automáticos
- ✅ Ideal para testing y uso personal

### Plan de pago (recomendado para producción)
- 💼 Máquinas dedicadas desde $1.94/mes
- 💼 PostgreSQL gestionado desde $1.94/mes
- 💼 Volúmenes persistentes desde $0.15/GB/mes
- 💼 Ancho de banda adicional $0.02/GB

```powershell
# Ver facturación actual
flyctl billing show
```

## 📞 Soporte

### Recursos oficiales
- 📖 [Documentación Fly.io](https://fly.io/docs/)
- 💬 [Community Forum](https://community.fly.io/)
- 🐦 [Twitter @flydotio](https://twitter.com/flydotio)

### Comandos de ayuda
```powershell
# Ayuda general
flyctl help

# Ayuda específica de deploy
flyctl deploy --help

# Estado del sistema Fly.io
flyctl platform status
```

## 🎉 ¡Listo!

Una vez completado el deployment, tu aplicación DocuSeal estará disponible en:
- **URL:** `https://tu-app-name.fly.dev`
- **Región:** Tu región seleccionada
- **SSL:** Habilitado automáticamente
- **Backups:** Automáticos (PostgreSQL)

¡Disfruta de tu nueva instalación de DocuSeal en Fly.io! 🚀
