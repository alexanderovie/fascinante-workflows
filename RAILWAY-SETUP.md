# ===========================================
# CONFIGURACIÓN COMPLETA DE RAILWAY PARA N8N
# ===========================================

## 🚀 **PASO 2: Autenticación con Railway**

### 📋 **Instrucciones para login:**

1. **🌐 Ejecuta el comando:**
   ```bash
   railway login
   ```

2. **🔗 Se abrirá tu navegador** automáticamente

3. **🔑 Autenticación:**
   - **Opción A**: Login con GitHub (recomendado)
   - **Opción B**: Login con email

4. **✅ Autorizar Railway** en tu cuenta

5. **🔄 Regresa a la terminal** - debería mostrar "Logged in successfully"

### 🎯 **PASO 3: Crear proyecto Railway**

Una vez autenticado, ejecuta:

```bash
# Crear nuevo proyecto
railway init

# Seleccionar opciones:
# - Project name: n8n-automatizaciones
# - Template: Empty Project
```

### 🎯 **PASO 4: Agregar PostgreSQL**

```bash
# Agregar base de datos PostgreSQL
railway add postgresql

# Esto creará automáticamente:
# - Base de datos PostgreSQL
# - Variables de entorno
# - Conexión automática
```

### 🎯 **PASO 5: Configurar variables de entorno**

```bash
# Configurar variables para n8n
railway variables set N8N_BASIC_AUTH_ACTIVE=true
railway variables set N8N_BASIC_AUTH_USER=admin
railway variables set N8N_BASIC_AUTH_PASSWORD=admin123
railway variables set DB_TYPE=postgresdb
railway variables set DB_POSTGRESDB_HOST=\${{Postgres.PGHOST}}
railway variables set DB_POSTGRESDB_PORT=\${{Postgres.PGPORT}}
railway variables set DB_POSTGRESDB_DATABASE=\${{Postgres.PGDATABASE}}
railway variables set DB_POSTGRESDB_USER=\${{Postgres.PGUSER}}
railway variables set DB_POSTGRESDB_PASSWORD=\${{Postgres.PGPASSWORD}}
railway variables set N8N_DIAGNOSTICS_ENABLED=false
railway variables set WEBHOOK_URL=https://\${{RAILWAY_PUBLIC_DOMAIN}}/
```

### 🎯 **PASO 6: Crear Dockerfile para n8n**

```bash
# Crear Dockerfile
cat > Dockerfile << 'EOF'
FROM docker.n8n.io/n8nio/n8n:latest

# Exponer puerto
EXPOSE 5678

# Comando por defecto
CMD ["n8n", "start"]
```

### 🎯 **PASO 7: Crear railway.json**

```bash
# Crear configuración de Railway
cat > railway.json << 'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE"
  },
  "deploy": {
    "startCommand": "n8n start",
    "healthcheckPath": "/healthz",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 🎯 **PASO 8: Deploy a Railway**

```bash
# Deploy del proyecto
railway up

# Esto hará:
# - Build de la imagen Docker
# - Deploy a Railway
# - Configurar dominio público
# - Conectar con PostgreSQL
```

### 🎯 **PASO 9: Obtener URL pública**

```bash
# Ver información del proyecto
railway status

# Obtener URL pública
railway domain

# La URL será algo como:
# https://n8n-automatizaciones-production.up.railway.app
```

### 🎯 **PASO 10: Configurar webhook en Cal.com**

1. **🌐 Ve a Cal.com webhooks:**
   - https://cal.com/settings/webhooks

2. **➕ Create Webhook:**
   - **URL**: `https://tu-dominio.railway.app/webhook/cal-elite-1761494050`
   - **Events**: BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED
   - **Save**

### 🎯 **PASO 11: Activar workflow en n8n**

```bash
# Conectar a n8n desplegado
railway connect

# O usar la URL pública para acceder a n8n
# https://tu-dominio.railway.app
# Login: admin / admin123
```

### 🎯 **COMANDOS ÚTILES DE RAILWAY:**

```bash
# Ver logs en tiempo real
railway logs --follow

# Conectar a base de datos
railway connect postgresql

# Ver variables de entorno
railway variables

# Ver estado del proyecto
railway status

# Ver dominios
railway domain

# Reiniciar servicio
railway redeploy
```

### 🎯 **COSTOS ESPERADOS:**

- **Mes 1**: $0 (crédito gratis $5)
- **Mes 2**: $3-5 (uso real)
- **Mes 3+**: $5-8 (escalado)

### 🎯 **TIEMPO TOTAL: ~45 minutos**

1. **Login**: 2 minutos
2. **Setup proyecto**: 5 minutos
3. **Configurar variables**: 10 minutos
4. **Deploy**: 15 minutos
5. **Configurar webhook**: 10 minutos
6. **Probar**: 3 minutos

### 🚀 **¡EMPEZAR AHORA!**

**Ejecuta: `railway login` y sigue los pasos** 🚀
