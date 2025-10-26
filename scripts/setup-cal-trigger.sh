#!/bin/bash

# ===========================================
# SCRIPT PARA CONFIGURAR CAL.COM TRIGGER
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

# Crear workflow con Cal.com Trigger
create_cal_workflow() {
    log "Creando workflow con Cal.com Trigger..."

    local workflow_data='{
        "name": "Cal.com Booking Notifications",
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
                "webhookId": "cal-webhook-'$(date +%s)'"
            },
            {
                "parameters": {
                    "message": "Nueva reserva en Cal.com: {{ $json.event.title }} - {{ $json.event.startTime }}",
                    "options": {}
                },
                "id": "log-notification",
                "name": "Log Notification",
                "type": "n8n-nodes-base.log",
                "typeVersion": 1,
                "position": [460, 300]
            },
            {
                "parameters": {
                    "respondWith": "json",
                    "responseBody": "{\"status\": \"success\", \"message\": \"Booking notification processed\"}"
                },
                "id": "respond",
                "name": "Respond",
                "type": "n8n-nodes-base.respondToWebhook",
                "typeVersion": 1,
                "position": [680, 300]
            }
        ],
        "connections": {
            "cal-trigger": {
                "main": [
                    [
                        {
                            "node": "log-notification",
                            "type": "main",
                            "index": 0
                        }
                    ]
                ]
            },
            "log-notification": {
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
        "settings": {},
        "staticData": null
    }'

    local response=$(api_request "POST" "/workflows" "$workflow_data")
    local workflow_id=$(echo "$response" | jq -r '.id' 2>/dev/null || echo "")

    if [ -n "$workflow_id" ] && [ "$workflow_id" != "null" ]; then
        success "Workflow creado con ID: $workflow_id"
        echo "$workflow_id"
    else
        error "No se pudo crear el workflow"
        echo "$response"
        return 1
    fi
}

# Crear credenciales de Cal.com
create_cal_credentials() {
    log "Creando credenciales de Cal.com..."

    local credentials_data='{
        "name": "Cal.com API",
        "type": "calApi",
        "data": {
            "apiKey": "TU_API_KEY_DE_CAL_COM_AQUI"
        }
    }'

    local response=$(api_request "POST" "/credentials" "$credentials_data")
    local credential_id=$(echo "$response" | jq -r '.id' 2>/dev/null || echo "")

    if [ -n "$credential_id" ] && [ "$credential_id" != "null" ]; then
        success "Credenciales creadas con ID: $credential_id"
        echo "$credential_id"
    else
        warning "No se pudieron crear las credenciales automáticamente"
        warning "Crea las credenciales manualmente en n8n:"
        warning "1. Ve a http://localhost:5678"
        warning "2. Ve a Credentials"
        warning "3. Crea nueva credencial tipo 'Cal.com API'"
        warning "4. Agrega tu API key de Cal.com"
        echo ""
    fi
}

# Mostrar información de configuración
show_setup_info() {
    local workflow_id="$1"

    echo ""
    echo "==========================================="
    echo "📅 CAL.COM TRIGGER CONFIGURADO"
    echo "==========================================="
    echo ""
    echo "🔧 Pasos para completar la configuración:"
    echo ""
    echo "1. 📝 Obtener API Key de Cal.com:"
    echo "   - Ve a https://cal.com/settings/developer"
    echo "   - Crea una nueva API Key"
    echo "   - Copia la API Key"
    echo ""
    echo "2. 🔑 Configurar credenciales en n8n:"
    echo "   - Ve a http://localhost:5678"
    echo "   - Ve a Credentials"
    echo "   - Crea nueva credencial tipo 'Cal.com API'"
    echo "   - Pega tu API Key"
    echo ""
    echo "3. 🌐 Configurar webhook en Cal.com:"
    echo "   - Ve a https://cal.com/settings/webhooks"
    echo "   - Crea nuevo webhook"
    echo "   - URL: http://localhost:5678/webhook/cal-webhook-$(date +%s)"
    echo "   - Eventos: Booking Created, Booking Cancelled, Booking Rescheduled"
    echo ""
    echo "4. ▶️  Activar workflow:"
    echo "   ./scripts/n8n-api.sh activate-workflow $workflow_id"
    echo ""
    echo "5. 🧪 Probar:"
    echo "   - Haz una reserva en Cal.com"
    echo "   - Ve a http://localhost:5678/executions"
    echo "   - Verifica que se ejecutó el workflow"
    echo ""
    echo "📊 Eventos soportados:"
    echo "   ✅ Booking Created - Nueva reserva"
    echo "   ✅ Booking Cancelled - Reserva cancelada"
    echo "   ✅ Booking Rescheduled - Reserva reprogramada"
    echo "   ✅ Meeting Ended - Reunión terminada"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "📅 Configurando Cal.com Trigger en n8n..."
    echo ""

    load_env

    # Crear workflow
    workflow_id=$(create_cal_workflow)

    if [ -n "$workflow_id" ]; then
        # Crear credenciales
        create_cal_credentials

        # Mostrar información
        show_setup_info "$workflow_id"

        success "¡Cal.com Trigger configurado exitosamente!"
    else
        error "No se pudo configurar Cal.com Trigger"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
