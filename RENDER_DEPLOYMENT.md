# Guía de Deployment en Render para DocuSeal

## Preparación del Proyecto

Este repositorio está preparado para deployment en Render con las siguientes configuraciones:

### Archivos de Configuración

1. **`render.yaml`** - Configuración Infrastructure as Code para Render
2. **`config/puma_render.rb`** - Configuración optimizada de Puma para Render
3. **`bin/start_render`** - Script de inicio personalizado

## Pasos para Deployment

### 1. Crear Cuenta en Render
- Ve a [render.com](https://render.com)
- Crea una cuenta o inicia sesión
- Conecta tu cuenta de GitHub

### 2. Crear el Servicio Web

#### Opción A: Usando render.yaml (Recomendado)
1. En el dashboard de Render, haz clic en "New +"
2. Selecciona "Blueprint"
3. Conecta tu repositorio GitHub que contiene DocuSeal
4. Render detectará automáticamente el archivo `render.yaml`
5. Revisa la configuración y haz clic en "Apply"

#### Opción B: Configuración Manual
1. En el dashboard de Render, haz clic en "New +"
2. Selecciona "Web Service"
3. Conecta tu repositorio GitHub
4. Configura los siguientes campos:

**Build & Deploy:**
- **Build Command:** `bundle install && yarn install && bundle exec rails assets:precompile`
- **Start Command:** `./bin/start_render` o `bundle exec puma -C config/puma_render.rb`

**Environment Variables:**
```
RAILS_ENV=production
SECRET_KEY_BASE=<será generado automáticamente>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5
```

### 3. Configurar Base de Datos

1. Crear PostgreSQL Database:
   - En el dashboard, "New +" → "PostgreSQL"
   - Nombre: `docuseal-db`
   - Plan: Free (para pruebas)

2. Agregar variable de entorno:
   - En tu Web Service, ve a "Environment"
   - Agrega: `DATABASE_URL` → Conecta a tu base de datos PostgreSQL

### 4. Configurar Redis (Opcional)

1. Crear Redis Service:
   - En el dashboard, "New +" → "Redis"
   - Nombre: `docuseal-redis`
   - Plan: Starter (Free)

2. Agregar variable de entorno:
   - `REDIS_URL` → Conecta a tu servicio Redis

### 5. Variables de Entorno Adicionales

Según tus necesidades, puedes agregar:

```bash
# Configuración de correo (ejemplo con Gmail)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# Configuración de almacenamiento (ejemplo con AWS S3)
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_REGION=us-east-1
S3_BUCKET=tu-bucket-name

# Host de la aplicación
HOST=tu-app.onrender.com
FORCE_SSL=true
```

## Solución de Problemas

### Error de Compilación de Assets
Si falla la compilación de assets, prueba:
- Asegúrate de que Node.js 18+ esté disponible
- Verifica que yarn.lock esté presente
- Revisa los logs de build para errores específicos

### Error de Base de Datos
- Verifica que DATABASE_URL esté configurado correctamente
- Asegúrate de que las migraciones se ejecuten: `bundle exec rails db:migrate`

### Error de Puma/Puerto
- Render automáticamente asigna la variable PORT
- La configuración en `puma_render.rb` está optimizada para Render
- Si hay problemas, cambia el Start Command a: `bundle exec puma -C config/puma.rb`

### Logs y Debugging
- Ve a tu servicio en Render Dashboard
- Haz clic en "Logs" para ver los logs en tiempo real
- Los logs de Puma se guardan en `/app/log/` dentro del contenedor

## Configuración de Dominio Personalizado

1. En tu servicio web, ve a "Settings"
2. Scroll hasta "Custom Domains"
3. Agrega tu dominio
4. Configura los DNS records según las instrucciones de Render

## Backup y Monitoreo

- Render incluye backups automáticos para PostgreSQL
- Configura alertas en "Settings" → "Alerts"
- Usa herramientas como UptimeRobot para monitoreo externo

## Optimizaciones de Rendimiento

1. **Workers:** Ajusta `WEB_CONCURRENCY` según tu plan
2. **Threads:** Configura `RAILS_MAX_THREADS` (máximo 5 para plan gratuito)
3. **CDN:** Considera usar un CDN para assets estáticos
4. **Database:** Upgrade a un plan pagado de PostgreSQL para mejor rendimiento

## Support

Si encuentras problemas:
1. Revisa los logs en Render Dashboard
2. Consulta la documentación de Render
3. Verifica la configuración de variables de entorno
4. Prueba primero con la configuración básica antes de agregar funcionalidades avanzadas

## Diferencias con Railway

- Render es más estable para aplicaciones Ruby on Rails
- Mejor soporte nativo para PostgreSQL
- Configuración de environment variables más sencilla
- Mejor manejo automático del puerto y binding
- Dashboard más intuitivo
- Mejor documentación y soporte comunitario
