# Deployment de DocuSeal con Docker en Render

## Configuración para Docker Deployment

Este proyecto está configurado para hacer deployment usando Docker en Render. La configuración incluye:

### 1. Archivos Clave

- **`Dockerfile`** - Multi-stage build optimizado para producción
- **`render.yaml`** - Configuración Infrastructure as Code con Docker
- **`docker-compose.yml`** - Para desarrollo local (opcional)

### 2. Pasos para Deployment

#### Opción A: Usando render.yaml (Recomendado)

1. **Preparar el repositorio:**
   ```bash
   git add .
   git commit -m "Configure Docker deployment for Render"
   git push origin main
   ```

2. **Conectar con Render:**
   - Ve a [render.com](https://render.com)
   - Haz clic en "New" → "Blueprint"
   - Conecta tu repositorio de GitHub
   - Render detectará automáticamente el `render.yaml`

3. **Configurar variables de entorno:**
   - `SECRET_KEY_BASE` - Se genera automáticamente
   - `DATABASE_URL` - Se configura automáticamente desde PostgreSQL
   - `REDIS_URL` - Se configura automáticamente desde Redis
   - Variables adicionales según necesidades

#### Opción B: Configuración Manual

1. **Crear Web Service:**
   - Ve a Render Dashboard
   - Clic en "New" → "Web Service"
   - Conecta tu repositorio

2. **Configuración del servicio:**
   - **Environment**: Docker
   - **Dockerfile Path**: `./Dockerfile`
   - **Docker Context**: `./`
   - **Auto-Deploy**: Yes

3. **Variables de entorno requeridas:**
   ```
   RAILS_ENV=production
   SECRET_KEY_BASE=[auto-generated]
   DATABASE_URL=[from database service]
   REDIS_URL=[from redis service]
   RAILS_SERVE_STATIC_FILES=true
   RAILS_LOG_TO_STDOUT=true
   WEB_CONCURRENCY=2
   RAILS_MAX_THREADS=5
   ```

### 3. Configuración de Servicios Adicionales

#### Base de Datos PostgreSQL
```yaml
databases:
  - name: docuseal-db
    databaseName: docuseal
    user: docuseal
    plan: starter  # o free para desarrollo
```

#### Redis
```yaml
services:
  - type: redis
    name: docuseal-redis
    plan: starter  # o free para desarrollo
```

### 4. Optimizaciones Docker

El `Dockerfile` incluye:

- **Multi-stage build** para reducir tamaño final
- **Caching de dependencias** de Ruby y Node.js
- **Precompilación de assets** en build time
- **Configuración optimizada** para Alpine Linux
- **Fonts** y **librerías** necesarias para PDFs

### 5. Verificación del Deployment

1. **Health Check:**
   - Render automáticamente configura health checks en `/health`
   - También puedes verificar en `/`

2. **Logs:**
   - Ve a tu servicio en Render Dashboard
   - Clic en "Logs" para monitorear el deployment

3. **Performance:**
   - El contenedor se inicia en `/data/docuseal`
   - Puerto 3000 expuesto automáticamente
   - Puma configurado para producción

### 6. Variables de Entorno Importantes

#### Básicas
- `RAILS_ENV=production`
- `SECRET_KEY_BASE` - Para sesiones y cookies
- `DATABASE_URL` - Conexión a PostgreSQL
- `REDIS_URL` - Conexión a Redis

#### Configuración Web
- `HOST` - Tu dominio (ej: `myapp.onrender.com`)
- `FORCE_SSL=true` - Forzar HTTPS
- `RAILS_SERVE_STATIC_FILES=true` - Servir assets

#### Performance
- `WEB_CONCURRENCY=2` - Número de workers Puma
- `RAILS_MAX_THREADS=5` - Hilos por worker
- `RAILS_MIN_THREADS=5` - Hilos mínimos

#### Email (Opcional)
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=tu-email@gmail.com
SMTP_PASSWORD=tu-app-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

#### Almacenamiento S3 (Opcional)
```
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_REGION=us-east-1
S3_BUCKET=tu-bucket-name
```

### 7. Comandos Útiles

#### Desarrollo Local con Docker
```bash
# Construir imagen
docker build -t docuseal .

# Ejecutar contenedor
docker run -p 3000:3000 -e RAILS_ENV=development docuseal

# Con docker-compose
docker-compose up
```

#### Debug en Render
```bash
# Ver logs en tiempo real
# (desde Render Dashboard > Logs)

# Acceder al shell del contenedor (si está habilitado)
# Render no permite shell access por defecto
```

### 8. Solución de Problemas

#### Error de Build
- Verifica que el `Dockerfile` esté en la raíz
- Asegúrate de que todas las dependencias estén en `Gemfile` y `package.json`
- Revisa los logs de build para errores específicos

#### Error de Inicio
- Verifica que `DATABASE_URL` esté configurado
- Asegúrate de que las migraciones se ejecuten correctamente
- Revisa la configuración de Puma

#### Performance
- Ajusta `WEB_CONCURRENCY` según tu plan de Render
- Para plan gratuito: `WEB_CONCURRENCY=1`
- Para planes pagados: `WEB_CONCURRENCY=2` o más

#### Memoria
- El contenedor Docker está optimizado para uso mínimo de memoria
- Si hay problemas de memoria, reduce `RAILS_MAX_THREADS`

### 9. Ventajas del Deployment con Docker

1. **Consistencia:** Mismo ambiente en desarrollo y producción
2. **Reproducibilidad:** Build determinístico
3. **Optimización:** Multi-stage build reduce tamaño
4. **Dependencias:** Todas las librerías incluidas en la imagen
5. **Seguridad:** Contenedor aislado

### 10. Próximos Pasos

1. **Monitoring:** Configura alertas en Render
2. **Backups:** Configurar backups automáticos de PostgreSQL
3. **CDN:** Considerar CloudFlare para assets estáticos
4. **Scaling:** Ajustar plan según tráfico
5. **Custom Domain:** Configurar dominio personalizado

### 11. Costos Estimados

- **Free Tier:** $0/mes (con limitaciones)
- **Starter:** $7/mes para web service + $7/mes para PostgreSQL
- **Professional:** $25/mes con más recursos

### 12. Support y Recursos

- [Documentación Docker en Render](https://render.com/docs/docker)
- [Render Community Forum](https://community.render.com/)
- [Ruby on Rails en Render](https://render.com/docs/deploy-rails)

## Comandos de Deployment Rápido

```bash
# 1. Preparar código
git add .
git commit -m "Ready for Docker deployment on Render"
git push origin main

# 2. Ir a render.com y crear Blueprint desde render.yaml
# 3. Configurar variables de entorno
# 4. Deploy automático iniciará
```

¡Tu aplicación estará disponible en `https://tu-app-name.onrender.com`!
