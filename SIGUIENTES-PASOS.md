# ===========================================
# SIGUIENTES PASOS CON TU API KEY DE N8N
# ===========================================

## 🎯 PASO 1: CREAR TU PRIMER WORKFLOW VIA API

### Crear un workflow básico de prueba
```bash
# Crear workflow de prueba
./scripts/n8n-api.sh create-workflow "Mi Primer Workflow API"

# Listar workflows para ver el ID
./scripts/n8n-api.sh list-workflows
```

### Activar y ejecutar el workflow
```bash
# Activar workflow (reemplaza WORKFLOW_ID con el ID real)
./scripts/n8n-api.sh activate-workflow WORKFLOW_ID

# Ejecutar workflow manualmente
./scripts/n8n-api.sh execute-workflow WORKFLOW_ID
```

## 🔑 PASO 2: CONFIGURAR CREDENCIALES VIA API

### Crear credenciales para servicios externos
```bash
# Crear credencial HTTP Header (para APIs externas)
./scripts/n8n-api.sh create-credential "API Externa"

# Crear credencial Basic Auth
curl -s -X POST "http://localhost:5678/api/v1/credentials" \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $(grep N8N_API_KEY .env.api | cut -d'=' -f2)" \
  -d '{
    "name": "Servicio Web",
    "type": "httpBasicAuth",
    "data": {
      "user": "usuario",
      "password": "contraseña"
    }
  }'
```

## 📊 PASO 3: MONITOREAR EJECUCIONES

### Ver todas las ejecuciones
```bash
# Listar ejecuciones recientes
./scripts/n8n-api.sh list-executions

# Ver detalles de una ejecución específica
curl -s -X GET "http://localhost:5678/api/v1/executions/EXECUTION_ID" \
  -H "X-N8N-API-KEY: $(grep N8N_API_KEY .env.api | cut -d'=' -f2)"
```

## 🔄 PASO 4: AUTOMATIZAR LA GESTIÓN

### Crear script personalizado para tu caso de uso
```bash
# Crear script personalizado
cat > scripts/mi-automatizacion.sh << 'EOF'
#!/bin/bash
source .env.api

# Tu lógica personalizada aquí
echo "Ejecutando mi automatización..."

# Crear workflow
./scripts/n8n-api.sh create-workflow "Workflow Automático $(date)"

# Activar workflow
WORKFLOW_ID=$(./scripts/n8n-api.sh list-workflows | jq -r '.data[0].id')
./scripts/n8n-api.sh activate-workflow "$WORKFLOW_ID"

# Ejecutar workflow
./scripts/n8n-api.sh execute-workflow "$WORKFLOW_ID"
EOF

chmod +x scripts/mi-automatizacion.sh
```

## 🌐 PASO 5: INTEGRAR CON SERVICIOS EXTERNOS

### Ejemplo: Integración con webhook
```bash
# Crear workflow que responda a webhooks
curl -s -X POST "http://localhost:5678/api/v1/workflows" \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $(grep N8N_API_KEY .env.api | cut -d'=' -f2)" \
  -d '{
    "name": "Webhook Handler",
    "nodes": [
      {
        "parameters": {
          "httpMethod": "POST",
          "path": "mi-webhook",
          "responseMode": "responseNode"
        },
        "id": "webhook",
        "name": "Webhook",
        "type": "n8n-nodes-base.webhook",
        "typeVersion": 1,
        "position": [240, 300]
      },
      {
        "parameters": {
          "respondWith": "json",
          "responseBody": "{\"status\": \"success\", \"message\": \"Webhook recibido\"}"
        },
        "id": "respond",
        "name": "Respond to Webhook",
        "type": "n8n-nodes-base.respondToWebhook",
        "typeVersion": 1,
        "position": [460, 300]
      }
    ],
    "connections": {
      "webhook": {
        "main": [
          [
            {
              "node": "respond",
              "type": "main",
              "index": 0
            }
          ]
        ]
      }
    },
    "active": true
  }'
```

## 📈 PASO 6: CONFIGURAR MONITOREO Y ALERTAS

### Script de monitoreo automático
```bash
# Crear script de monitoreo
cat > scripts/monitor.sh << 'EOF'
#!/bin/bash
source .env.api

# Verificar estado de n8n
if ! curl -s http://localhost:5678/healthz > /dev/null; then
    echo "❌ n8n no está respondiendo"
    exit 1
fi

# Verificar ejecuciones fallidas
FAILED_EXECUTIONS=$(curl -s -X GET "http://localhost:5678/api/v1/executions?status=error&limit=10" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" | jq '.data | length')

if [ "$FAILED_EXECUTIONS" -gt 0 ]; then
    echo "⚠️  Hay $FAILED_EXECUTIONS ejecuciones fallidas"
fi

echo "✅ Sistema funcionando correctamente"
EOF

chmod +x scripts/monitor.sh
```

## 🔧 PASO 7: CONFIGURAR BACKUPS AUTOMÁTICOS

### Programar backups automáticos
```bash
# Agregar a crontab para backups diarios
(crontab -l 2>/dev/null; echo "0 2 * * * cd /home/alexander/proyectos/automatizaciones && ./scripts/backup.sh") | crontab -

# Agregar monitoreo cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * cd /home/alexander/proyectos/automatizaciones && ./scripts/monitor.sh") | crontab -
```

## 🚀 PASO 8: ESCALAR Y OPTIMIZAR

### Configurar múltiples entornos
```bash
# Crear configuración para producción
cp .env.api .env.api.production
cp .env.api .env.api.staging

# Script para cambiar entre entornos
cat > scripts/switch-env.sh << 'EOF'
#!/bin/bash
ENV=${1:-development}

case $ENV in
    "production")
        cp .env.api.production .env.api
        echo "Cambiado a entorno de producción"
        ;;
    "staging")
        cp .env.api.staging .env.api
        echo "Cambiado a entorno de staging"
        ;;
    "development")
        cp .env.api.backup.* .env.api 2>/dev/null || echo "Usando API key de desarrollo"
        echo "Cambiado a entorno de desarrollo"
        ;;
esac
EOF

chmod +x scripts/switch-env.sh
```

## 📚 PASO 9: DOCUMENTAR Y COMPARTIR

### Crear documentación de tus automatizaciones
```bash
# Crear documentación personalizada
cat > MI-DOCUMENTACION.md << 'EOF'
# Mis Automatizaciones con n8n

## Workflows Configurados
- [ ] Workflow 1: Descripción
- [ ] Workflow 2: Descripción

## Credenciales Configuradas
- [ ] API Externa: Para conectar con servicios externos
- [ ] Base de Datos: Para operaciones de BD

## Scripts Personalizados
- [ ] mi-automatizacion.sh: Mi lógica personalizada
- [ ] monitor.sh: Monitoreo del sistema

## Próximos Pasos
- [ ] Integrar con más servicios
- [ ] Configurar alertas avanzadas
- [ ] Optimizar rendimiento
EOF
```

## 🎯 PASO 10: PRÓXIMOS OBJETIVOS AVANZADOS

### Integraciones avanzadas
1. **Conectar con APIs externas** (Google Sheets, Slack, etc.)
2. **Configurar webhooks** para recibir datos
3. **Crear workflows complejos** con múltiples nodos
4. **Implementar manejo de errores** robusto
5. **Configurar notificaciones** por email/SMS
6. **Integrar con bases de datos** externas
7. **Crear dashboards** de monitoreo
8. **Implementar CI/CD** para workflows

---

## 🚀 ¡EMPEZAR AHORA!

```bash
# 1. Crear tu primer workflow
./scripts/n8n-api.sh create-workflow "Mi Primer Workflow"

# 2. Ver que se creó
./scripts/n8n-api.sh list-workflows

# 3. Probar la API
./scripts/api-examples.sh

# 4. Crear backup
./scripts/manage-api-keys.sh backup
```

**¡Tu sistema está listo para automatizar todo lo que necesites! 🎉**
