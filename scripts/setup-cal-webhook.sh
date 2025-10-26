#!/bin/bash

# ===========================================
# CONFIGURAR WEBHOOK DE CAL.COM VIA CLI
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

# Variables
CAL_API_KEY="cal_live_893d6bd5d039a1cc0202d8e6c335767c"
WEBHOOK_URL="http://localhost:5678/webhook/cal-elite-1761494050"
CAL_API_BASE="https://api.cal.com/v1"

# Función para hacer requests a Cal.com API
cal_api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            "$CAL_API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $CAL_API_KEY" \
            -H "X-API-Key: $CAL_API_KEY" \
            -d "$data"
    else
        curl -s -X "$method" \
            "$CAL_API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $CAL_API_KEY" \
            -H "X-API-Key: $CAL_API_KEY"
    fi
}

# Verificar que la API key funciona
test_cal_api() {
    log "Probando conexión con Cal.com API..."

    local response=$(cal_api_request "GET" "/me")

    if echo "$response" | grep -q "id"; then
        success "✅ Conexión con Cal.com API exitosa"
        local username=$(echo "$response" | jq -r '.username' 2>/dev/null || echo "Usuario")
        log "Usuario: $username"
    else
        error "❌ No se pudo conectar con Cal.com API"
        echo "Respuesta: $response"
        return 1
    fi
}

# Listar webhooks existentes
list_webhooks() {
    log "Listando webhooks existentes..."

    local response=$(cal_api_request "GET" "/webhooks")

    if echo "$response" | grep -q "data"; then
        echo "$response" | jq '.data[] | {id: .id, url: .subscriberUrl, events: .eventTriggers}' 2>/dev/null || echo "$response"
    else
        warning "No se pudieron listar webhooks o no hay webhooks existentes"
        echo "$response"
    fi
}

# Crear webhook
create_webhook() {
    log "Creando webhook en Cal.com..."

    local webhook_data='{
        "subscriberUrl": "'$WEBHOOK_URL'",
        "eventTriggers": [
            "BOOKING_CREATED",
            "BOOKING_CANCELLED",
            "BOOKING_RESCHEDULED"
        ],
        "active": true,
        "secret": "n8n-webhook-secret-'$(date +%s)'"
    }'

    local response=$(cal_api_request "POST" "/webhooks" "$webhook_data")
    local webhook_id=$(echo "$response" | jq -r '.id' 2>/dev/null || echo "")

    if [ -n "$webhook_id" ] && [ "$webhook_id" != "null" ]; then
        success "✅ Webhook creado exitosamente"
        success "Webhook ID: $webhook_id"
        success "URL: $WEBHOOK_URL"
        success "Eventos: BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED"
        echo "$webhook_id"
    else
        error "❌ No se pudo crear el webhook"
        echo "Respuesta: $response"
        return 1
    fi
}

# Eliminar webhook existente
delete_webhook() {
    local webhook_id="$1"

    if [ -z "$webhook_id" ]; then
        warning "No se proporcionó ID de webhook para eliminar"
        return 0
    fi

    log "Eliminando webhook existente: $webhook_id"

    local response=$(cal_api_request "DELETE" "/webhooks/$webhook_id")

    if echo "$response" | grep -q "success\|deleted"; then
        success "✅ Webhook eliminado exitosamente"
    else
        warning "No se pudo eliminar el webhook o ya no existe"
        echo "Respuesta: $response"
    fi
}

# Verificar webhook
test_webhook() {
    local webhook_id="$1"

    if [ -z "$webhook_id" ]; then
        warning "No se proporcionó ID de webhook para probar"
        return 0
    fi

    log "Verificando webhook: $webhook_id"

    local response=$(cal_api_request "GET" "/webhooks/$webhook_id")

    if echo "$response" | grep -q "id"; then
        success "✅ Webhook verificado exitosamente"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        error "❌ No se pudo verificar el webhook"
        echo "Respuesta: $response"
        return 1
    fi
}

# Mostrar información del webhook
show_webhook_info() {
    local webhook_id="$1"

    echo ""
    echo "==========================================="
    echo "🌐 WEBHOOK DE CAL.COM CONFIGURADO"
    echo "==========================================="
    echo ""
    echo "📋 Información del webhook:"
    echo "   ID: $webhook_id"
    echo "   URL: $WEBHOOK_URL"
    echo "   Eventos: BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED"
    echo ""
    echo "🔧 Configuración en n8n:"
    echo "   Workflow ID: yTdjHnb86epGEoL7"
    echo "   Webhook ID: cal-elite-1761494050"
    echo ""
    echo "🧪 Próximos pasos:"
    echo "   1. Activar workflow en n8n"
    echo "   2. Hacer reserva de prueba en Cal.com"
    echo "   3. Verificar email recibido"
    echo "   4. Revisar ejecuciones en n8n"
    echo ""
    echo "📊 Comandos útiles:"
    echo "   ./scripts/n8n-api.sh activate-workflow yTdjHnb86epGEoL7"
    echo "   ./scripts/n8n-api.sh list-executions"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🌐 Configurando webhook de Cal.com via CLI..."
    echo ""

    # Verificar conexión
    if ! test_cal_api; then
        error "No se puede continuar sin conexión a Cal.com API"
        exit 1
    fi

    # Listar webhooks existentes
    list_webhooks

    # Crear nuevo webhook
    webhook_id=$(create_webhook)

    if [ -n "$webhook_id" ]; then
        # Verificar webhook
        test_webhook "$webhook_id"

        # Mostrar información
        show_webhook_info "$webhook_id"

        success "¡Webhook de Cal.com configurado exitosamente via CLI!"
    else
        error "No se pudo configurar el webhook"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
