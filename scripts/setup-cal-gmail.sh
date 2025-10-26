#!/bin/bash

# ===========================================
# SCRIPT PARA CONFIGURAR CAL.COM + GMAIL
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

# Crear workflow Cal.com + Gmail
create_cal_gmail_workflow() {
    log "Creando workflow Cal.com + Gmail..."

    local workflow_data='{
        "name": "Cal.com Email Notifications",
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
                    "assignments": {
                        "subject": "=Nueva reserva en Cal.com: {{ $json.event.title }}",
                        "toEmail": "tu-email@ejemplo.com",
                        "message": "=Hola!<br><br>Has recibido una nueva reserva en Cal.com:<br><br><strong>Detalles de la reserva:</strong><br>📅 <strong>Título:</strong> {{ $json.event.title }}<br>📅 <strong>Fecha:</strong> {{ $json.event.startTime }}<br>👤 <strong>Cliente:</strong> {{ $json.event.attendees[0].name || \"No especificado\" }}<br>📧 <strong>Email:</strong> {{ $json.event.attendees[0].email || \"No especificado\" }}<br>📍 <strong>Ubicación:</strong> {{ $json.event.location || \"Virtual\" }}<br><br>¡Que tengas una excelente reunión!<br><br>Saludos,<br>Tu sistema de automatización"
                    },
                    "options": {
                        "html": true
                    }
                },
                "id": "gmail-send",
                "name": "Send Email",
                "type": "n8n-nodes-base.gmail",
                "typeVersion": 2,
                "position": [460, 300]
            },
            {
                "parameters": {
                    "message": "Email enviado para reserva: {{ $json.event.title }}",
                    "options": {}
                },
                "id": "log-success",
                "name": "Log Success",
                "type": "n8n-nodes-base.log",
                "typeVersion": 1,
                "position": [680, 300]
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

# Mostrar información de configuración
show_setup_info() {
    local workflow_id="$1"

    echo ""
    echo "==========================================="
    echo "📧 CAL.COM + GMAIL CONFIGURADO"
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
    echo "   - Pega tu API Key de Cal.com"
    echo ""
    echo "3. 📧 Configurar Gmail en n8n:"
    echo "   - Ve a Credentials"
    echo "   - Crea nueva credencial tipo 'Gmail OAuth2 API'"
    echo "   - Sigue el proceso de OAuth2"
    echo "   - Autoriza el acceso a tu Gmail"
    echo ""
    echo "4. 🌐 Configurar webhook en Cal.com:"
    echo "   - Ve a https://cal.com/settings/webhooks"
    echo "   - Crea nuevo webhook"
    echo "   - URL: http://localhost:5678/webhook/cal-webhook-$(date +%s)"
    echo "   - Eventos: Booking Created"
    echo ""
    echo "5. ✏️  Editar email en el workflow:"
    echo "   - Ve a http://localhost:5678"
    echo "   - Abre el workflow: $workflow_id"
    echo "   - Edita el nodo 'Send Email'"
    echo "   - Cambia 'tu-email@ejemplo.com' por tu email real"
    echo ""
    echo "6. ▶️  Activar workflow:"
    echo "   ./scripts/n8n-api.sh activate-workflow $workflow_id"
    echo ""
    echo "7. 🧪 Probar:"
    echo "   - Haz una reserva en Cal.com"
    echo "   - Revisa tu email"
    echo "   - Ve a http://localhost:5678/executions"
    echo ""
    echo "📧 El email incluirá:"
    echo "   ✅ Título de la reserva"
    echo "   ✅ Fecha y hora"
    echo "   ✅ Nombre del cliente"
    echo "   ✅ Email del cliente"
    echo "   ✅ Ubicación de la reunión"
    echo "   ✅ Formato HTML bonito"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "📧 Configurando Cal.com + Gmail en n8n..."
    echo ""

    load_env

    # Crear workflow
    workflow_id=$(create_cal_gmail_workflow)

    if [ -n "$workflow_id" ]; then
        # Mostrar información
        show_setup_info "$workflow_id"

        success "¡Cal.com + Gmail configurado exitosamente!"
    else
        error "No se pudo configurar Cal.com + Gmail"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
