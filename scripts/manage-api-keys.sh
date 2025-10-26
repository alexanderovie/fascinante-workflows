#!/bin/bash

# ===========================================
# SCRIPT PARA GESTIÓN Y ROTACIÓN DE API KEYS
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

# Mostrar información de la API key actual
show_api_info() {
    log "Información de la API key actual:"
    echo ""
    echo "📁 Archivo: .env.api"
    echo "🔑 API Key: ${N8N_API_KEY:0:20}..."
    echo "🌐 URL: $N8N_API_URL"
    echo ""

    # Decodificar JWT para mostrar información
    if command -v jq &> /dev/null; then
        log "Información del token JWT:"
        echo "$N8N_API_KEY" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.' 2>/dev/null || echo "No se pudo decodificar el token"
    else
        warning "Instala jq para ver información del token: sudo apt install jq"
    fi
}

# Probar la API key actual
test_api_key() {
    log "Probando la API key actual..."

    # Probar endpoint básico
    response=$(api_request "GET" "/workflows" 2>/dev/null)

    if echo "$response" | grep -q "data"; then
        success "✅ API key funciona correctamente"
        echo "Respuesta: $response"
    else
        error "❌ API key no funciona o ha expirado"
        echo "Respuesta: $response"
        return 1
    fi
}

# Crear backup de la API key actual
backup_api_key() {
    local backup_file=".env.api.backup.$(date +%Y%m%d_%H%M%S)"

    log "Creando backup de la API key actual..."
    cp .env.api "$backup_file"
    success "Backup creado: $backup_file"
}

# Rotar API key (crear nueva y actualizar archivo)
rotate_api_key() {
    local new_api_key="$1"

    if [ -z "$new_api_key" ]; then
        error "Debes proporcionar una nueva API key"
        echo "Uso: $0 rotate 'nueva_api_key_aqui'"
        exit 1
    fi

    log "Rotando API key..."

    # Crear backup de la actual
    backup_api_key

    # Actualizar archivo con nueva API key
    cat > .env.api << EOF
N8N_API_KEY=$new_api_key
N8N_API_URL=http://localhost:5678/api/v1
EOF

    success "API key rotada exitosamente"

    # Probar nueva API key
    log "Probando nueva API key..."
    if test_api_key; then
        success "✅ Nueva API key funciona correctamente"
    else
        error "❌ Nueva API key no funciona"
        warning "Restaurando API key anterior..."
        cp .env.api.backup.* .env.api 2>/dev/null || true
        exit 1
    fi
}

# Listar backups de API keys
list_backups() {
    log "Listando backups de API keys:"
    echo ""

    if ls .env.api.backup.* 2>/dev/null; then
        for backup in .env.api.backup.*; do
            echo "📁 $backup"
            echo "   Creado: $(stat -c %y "$backup" 2>/dev/null || echo "Fecha no disponible")"
            echo "   API Key: $(grep N8N_API_KEY "$backup" | cut -d'=' -f2 | cut -c1-20)..."
            echo ""
        done
    else
        echo "No hay backups disponibles"
    fi
}

# Restaurar API key desde backup
restore_api_key() {
    local backup_file="$1"

    if [ -z "$backup_file" ]; then
        error "Debes especificar el archivo de backup"
        echo "Uso: $0 restore .env.api.backup.20241201_143022"
        exit 1
    fi

    if [ ! -f "$backup_file" ]; then
        error "Archivo de backup no encontrado: $backup_file"
        exit 1
    fi

    log "Restaurando API key desde: $backup_file"

    # Crear backup de la actual antes de restaurar
    backup_api_key

    # Restaurar desde backup
    cp "$backup_file" .env.api

    success "API key restaurada desde $backup_file"

    # Probar API key restaurada
    test_api_key
}

# Limpiar backups antiguos
cleanup_backups() {
    local keep_days="${1:-7}"

    log "Limpiando backups más antiguos de $keep_days días..."

    find . -name ".env.api.backup.*" -type f -mtime +$keep_days -delete 2>/dev/null || true

    success "Limpieza de backups completada"
}

# Mostrar ayuda
show_help() {
    echo "🔑 Gestión de API Keys de n8n"
    echo ""
    echo "Uso: $0 <comando> [argumentos]"
    echo ""
    echo "Comandos disponibles:"
    echo "  info                    - Mostrar información de la API key actual"
    echo "  test                    - Probar la API key actual"
    echo "  backup                  - Crear backup de la API key actual"
    echo "  rotate <nueva_key>      - Rotar a una nueva API key"
    echo "  list-backups            - Listar todos los backups"
    echo "  restore <backup_file>   - Restaurar API key desde backup"
    echo "  cleanup [días]          - Limpiar backups antiguos (default: 7 días)"
    echo "  help                    - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 info"
    echo "  $0 test"
    echo "  $0 backup"
    echo "  $0 rotate 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'"
    echo "  $0 restore .env.api.backup.20241201_143022"
    echo "  $0 cleanup 30"
    echo ""
    echo "📁 Ubicación de archivos:"
    echo "  API key actual: .env.api"
    echo "  Backups: .env.api.backup.YYYYMMDD_HHMMSS"
    echo "  Gitignore: .env.api está protegido en .gitignore"
}

# Función principal
main() {
    case "${1:-help}" in
        "info")
            load_env
            show_api_info
            ;;
        "test")
            load_env
            test_api_key
            ;;
        "backup")
            load_env
            backup_api_key
            ;;
        "rotate")
            load_env
            rotate_api_key "${2:-}"
            ;;
        "list-backups")
            list_backups
            ;;
        "restore")
            restore_api_key "${2:-}"
            ;;
        "cleanup")
            cleanup_backups "${2:-7}"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
