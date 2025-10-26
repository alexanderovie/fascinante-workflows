#!/bin/bash

# ===========================================
# CONFIGURAR NGROK PARA CAL.COM WEBHOOK
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

# Verificar si ngrok está instalado
check_ngrok() {
    if command -v ngrok &> /dev/null; then
        success "✅ ngrok está instalado"
        ngrok version
    else
        warning "❌ ngrok no está instalado"
        echo ""
        echo "📥 Instalar ngrok:"
        echo "1. Ve a: https://ngrok.com/download"
        echo "2. Descarga para tu sistema operativo"
        echo "3. Extrae y mueve a /usr/local/bin/"
        echo "4. O usa: curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok"
        echo ""
        return 1
    fi
}

# Configurar ngrok
setup_ngrok() {
    log "Configurando ngrok para Cal.com webhook..."

    # Verificar si ngrok está autenticado
    if ngrok config check &>/dev/null; then
        success "✅ ngrok está configurado"
    else
        warning "⚠️  ngrok necesita autenticación"
        echo ""
        echo "🔑 Configurar ngrok:"
        echo "1. Ve a: https://dashboard.ngrok.com/get-started/your-authtoken"
        echo "2. Copia tu authtoken"
        echo "3. Ejecuta: ngrok config add-authtoken TU_TOKEN"
        echo ""
        return 1
    fi
}

# Iniciar túnel ngrok
start_ngrok_tunnel() {
    log "Iniciando túnel ngrok..."

    # Iniciar ngrok en background
    ngrok http 5678 --log=stdout > ngrok.log 2>&1 &
    NGROK_PID=$!

    # Esperar a que ngrok se inicie
    sleep 3

    # Obtener URL pública
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")

    if [ -n "$NGROK_URL" ] && [ "$NGROK_URL" != "null" ]; then
        success "✅ Túnel ngrok iniciado"
        success "URL pública: $NGROK_URL"
        echo "$NGROK_URL"
    else
        error "❌ No se pudo obtener URL de ngrok"
        kill $NGROK_PID 2>/dev/null || true
        return 1
    fi
}

# Mostrar información del webhook
show_webhook_info() {
    local ngrok_url="$1"

    echo ""
    echo "==========================================="
    echo "🌐 WEBHOOK URL PÚBLICA CONFIGURADA"
    echo "==========================================="
    echo ""
    echo "📋 Información del webhook:"
    echo "   URL pública: $ngrok_url/webhook/cal-elite-1761494050"
    echo "   URL local: http://localhost:5678/webhook/cal-elite-1761494050"
    echo ""
    echo "🔧 Configurar en Cal.com:"
    echo "   1. Ve a: https://cal.com/settings/webhooks"
    echo "   2. Create Webhook"
    echo "   3. URL: $ngrok_url/webhook/cal-elite-1761494050"
    echo "   4. Events: BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED"
    echo "   5. Save"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - ngrok debe estar corriendo mientras uses el webhook"
    echo "   - La URL cambia cada vez que reinicias ngrok"
    echo "   - Para producción, usa un dominio fijo"
    echo ""
    echo "🛑 Para detener ngrok:"
    echo "   kill $NGROK_PID"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🌐 Configurando ngrok para Cal.com webhook..."
    echo ""

    # Verificar ngrok
    if ! check_ngrok; then
        error "Instala ngrok primero"
        exit 1
    fi

    # Configurar ngrok
    if ! setup_ngrok; then
        error "Configura ngrok primero"
        exit 1
    fi

    # Iniciar túnel
    ngrok_url=$(start_ngrok_tunnel)

    if [ -n "$ngrok_url" ]; then
        # Mostrar información
        show_webhook_info "$ngrok_url"

        success "¡ngrok configurado exitosamente!"
        warning "Recuerda mantener ngrok corriendo mientras uses el webhook"
    else
        error "No se pudo configurar ngrok"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
