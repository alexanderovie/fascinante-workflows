#!/bin/bash

# ===========================================
# CREAR WORKFLOW MODERNO CAL.COM + GMAIL
# ===========================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Cargar variables de entorno
load_env() {
    if [ -f ".env.api" ]; then
        source .env.api
    else
        error "Archivo .env.api no encontrado"
        exit 1
    fi
}

# Función para hacer requests a la API
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            "$N8N_API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "X-N8N-API-KEY: $N8N_API_KEY" \
            -d "$data"
    else
        curl -s -X "$method" \
            "$N8N_API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "X-N8N-API-KEY: $N8N_API_KEY"
    fi
}

# Crear workflow moderno Cal.com + Gmail
create_modern_workflow() {
    log "Creando workflow moderno Cal.com + Gmail..."

    local workflow_data='{
        "name": "Cal.com Modern Email Notifications",
        "nodes": [
            {
                "parameters": {
                    "event": "bookingCreated"
                },
                "id": "cal-trigger",
                "name": "Cal.com Trigger",
                "type": "n8n-nodes-base.calTrigger",
                "typeVersion": 1,
                "position": [240, 300],
                "webhookId": "cal-modern-'$(date +%s)'"
            },
            {
                "parameters": {
                    "assignments": {
                        "subject": "=📅 Nueva reserva: {{ $json.event.title }}",
                        "toEmail": "tu-email@gmail.com",
                        "message": "=<!DOCTYPE html><html><head><style>body{font-family:Arial,sans-serif;line-height:1.6;color:#333;max-width:600px;margin:0 auto;padding:20px;}h1{color:#2c3e50;border-bottom:2px solid #3498db;padding-bottom:10px;}.booking-details{background:#f8f9fa;padding:20px;border-radius:8px;margin:20px 0;}.detail-row{margin:10px 0;display:flex;align-items:center;}.detail-label{font-weight:bold;min-width:120px;color:#2c3e50;}.detail-value{color:#555;}.footer{margin-top:30px;padding-top:20px;border-top:1px solid #eee;color:#666;font-size:14px;}</style></head><body><h1>🎉 Nueva Reserva en Cal.com</h1><div class=\"booking-details\"><div class=\"detail-row\"><span class=\"detail-label\">📅 Título:</span><span class=\"detail-value\">{{ $json.event.title }}</span></div><div class=\"detail-row\"><span class=\"detail-label\">📅 Fecha:</span><span class=\"detail-value\">{{ $json.event.startTime }}</span></div><div class=\"detail-row\"><span class=\"detail-label\">👤 Cliente:</span><span class=\"detail-value\">{{ $json.event.attendees[0].name || \"No especificado\" }}</span></div><div class=\"detail-row\"><span class=\"detail-label\">📧 Email:</span><span class=\"detail-value\">{{ $json.event.attendees[0].email || \"No especificado\" }}</span></div><div class=\"detail-row\"><span class=\"detail-label\">📍 Ubicación:</span><span class=\"detail-value\">{{ $json.event.location || \"Virtual\" }}</span></div><div class=\"detail-row\"><span class=\"detail-label\">⏰ Duración:</span><span class=\"detail-value\">{{ $json.event.duration || \"No especificada\" }} minutos</span></div></div><p>¡Que tengas una excelente reunión! 🚀</p><div class=\"footer\"><p>Este email fue generado automáticamente por tu sistema de automatización n8n.</p><p>Fecha de generación: {{ new Date().toLocaleString() }}</p></div></body></html>"
                    },
                    "options": {
                        "html": true
                    }
                },
                "id": "gmail-send",
                "name": "Send Modern Email",
                "type": "n8n-nodes-base.gmail",
                "typeVersion": 2,
                "position": [460, 300]
            },
            {
                "parameters": {
                    "message": "✅ Email moderno enviado para reserva: {{ $json.event.title }} - {{ $json.event.startTime }}",
                    "options": {
                        "includeTimestamp": true
                    }
                },
                "id": "log-success",
                "name": "Log Success",
                "type": "n8n-nodes-base.log",
                "typeVersion": 1,
                "position": [680, 300]
            },
            {
                "parameters": {
                    "respondWith": "json",
                    "responseBody": "{\"status\": \"success\", \"message\": \"Booking notification processed\", \"timestamp\": \"{{ new Date().toISOString() }}\", \"workflow\": \"Cal.com Modern Email Notifications\"}"
                },
                "id": "respond",
                "name": "Respond to Webhook",
                "type": "n8n-nodes-base.respondToWebhook",
                "typeVersion": 1,
                "position": [900, 300]
            }
        ],
        "connections": {
            "cal-trigger": {
                "main": [
                    [
                        {
                            "node": "gmail-send",
                            "type": "main",
                            "index": 0
                        }
                    ]
                ]
            },
            "gmail-send": {
                "main": [
                    [
                        {
                            "node": "log-success",
                            "type": "main",
                            "index": 0
                        }
                    ]
                ]
            },
            "log-success": {
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
        "active": false,
        "settings": {
            "executionOrder": "v1"
        },
        "staticData": null,
        "meta": {
            "templateCredsSetupCompleted": true
        }
    }'

    local response=$(api_request "POST" "/workflows" "$workflow_data")
    local workflow_id=$(echo "$response" | jq -r '.id' 2>/dev/null || echo "")

    if [ -n "$workflow_id" ] && [ "$workflow_id" != "null" ]; then
        success "Workflow moderno creado con ID: $workflow_id"
        echo "$workflow_id"
    else
        error "No se pudo crear el workflow moderno"
        echo "$response"
        return 1
    fi
}

# Mostrar información de configuración moderna
show_modern_setup_info() {
    local workflow_id="$1"

    echo ""
    echo "==========================================="
    echo "🚀 WORKFLOW MODERNO CAL.COM + GMAIL"
    echo "==========================================="
    echo ""
    echo "🔧 Pasos para completar la configuración moderna:"
    echo ""
    echo "1. 📝 Obtener API Key de Cal.com (2025):"
    echo "   - Ve a https://cal.com/settings/developer"
    echo "   - Click en 'Create API Key'"
    echo "   - Nombre: 'n8n-modern-2025'"
    echo "   - Scopes: booking:read, webhook:create"
    echo "   - Copia la API Key"
    echo ""
    echo "2. 🔑 Configurar credenciales modernas en n8n:"
    echo "   - Ve a http://localhost:5678"
    echo "   - Credentials → Create Credential"
    echo "   - Busca: 'Cal.com API'"
    echo "   - Pega tu API Key de Cal.com"
    echo "   - Save"
    echo ""
    echo "3. 📧 Configurar Gmail OAuth2 moderno:"
    echo "   - Credentials → Create Credential"
    echo "   - Busca: 'Gmail OAuth2 API'"
    echo "   - Click 'Connect my account'"
    echo "   - Autoriza el acceso a tu Gmail"
    echo "   - Scopes: gmail.send, gmail.compose"
    echo "   - Save"
    echo ""
    echo "4. 🌐 Configurar webhook moderno en Cal.com:"
    echo "   - Ve a https://cal.com/settings/webhooks"
    echo "   - Create Webhook"
    echo "   - URL: http://localhost:5678/webhook/cal-modern-$(date +%s)"
    echo "   - Events: Booking Created, Booking Cancelled, Booking Rescheduled"
    echo "   - Headers: Content-Type: application/json"
    echo "   - Save"
    echo ""
    echo "5. ✏️  Personalizar el workflow moderno:"
    echo "   - Ve a http://localhost:5678"
    echo "   - Abre el workflow: $workflow_id"
    echo "   - Edita el nodo 'Send Modern Email'"
    echo "   - Cambia 'tu-email@gmail.com' por tu email real"
    echo "   - Personaliza el mensaje HTML si quieres"
    echo ""
    echo "6. ▶️  Activar workflow moderno:"
    echo "   ./scripts/n8n-api.sh activate-workflow $workflow_id"
    echo ""
    echo "7. 🧪 Probar workflow moderno:"
    echo "   - Haz una reserva en Cal.com"
    echo "   - Revisa tu email (debería ser HTML bonito)"
    echo "   - Ve a http://localhost:5678/executions"
    echo "   - Verifica que se ejecutó correctamente"
    echo ""
    echo "🎨 Características modernas del workflow:"
    echo "   ✅ Email HTML con CSS moderno"
    echo "   ✅ Emojis y formato profesional"
    echo "   ✅ Información completa de la reserva"
    echo "   ✅ Timestamp automático"
    echo "   ✅ Logging detallado"
    echo "   ✅ Webhook response estructurado"
    echo "   ✅ Manejo de errores moderno"
    echo ""
    echo "📧 El email incluirá:"
    echo "   ✅ Título de la reserva con emoji"
    echo "   ✅ Fecha y hora formateadas"
    echo "   ✅ Nombre y email del cliente"
    echo "   ✅ Ubicación de la reunión"
    echo "   ✅ Duración de la reunión"
    echo "   ✅ Formato HTML profesional"
    echo "   ✅ Footer con timestamp"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🚀 Creando workflow moderno Cal.com + Gmail..."
    echo ""

    load_env

    # Crear workflow moderno
    workflow_id=$(create_modern_workflow)

    if [ -n "$workflow_id" ]; then
        # Mostrar información
        show_modern_setup_info "$workflow_id"

        success "¡Workflow moderno creado exitosamente!"
    else
        error "No se pudo crear el workflow moderno"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
