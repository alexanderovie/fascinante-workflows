#!/bin/bash

# ===========================================
# SCRIPT PARA CONFIGURAR API KEY DE N8N
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

# Verificar que n8n esté corriendo
check_n8n() {
    log "Verificando que n8n esté corriendo..."
    if ! curl -s http://localhost:5678/healthz &>/dev/null; then
        error "n8n no está corriendo. Ejecuta: docker compose up -d"
        exit 1
    fi
    success "n8n está corriendo"
}

# Crear usuario admin si no existe
create_admin_user() {
    log "Creando usuario administrador..."
    
    # Verificar si ya existe un usuario
    if curl -s -X GET "http://localhost:5678/api/v1/users" \
        -H "Content-Type: application/json" \
        -u "admin:admin123" &>/dev/null; then
        log "Usuario admin ya existe"
        return 0
    fi
    
    # Crear usuario admin
    curl -s -X POST "http://localhost:5678/api/v1/users" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "admin@automatizaciones.local",
            "firstName": "Admin",
            "lastName": "User",
            "password": "admin123",
            "role": "owner"
        }' || warning "No se pudo crear usuario (puede que ya exista)"
}

# Generar API key
generate_api_key() {
    log "Generando API key..."
    
    # Intentar generar API key
    API_KEY=$(curl -s -X POST "http://localhost:5678/api/v1/api-keys" \
        -H "Content-Type: application/json" \
        -u "admin:admin123" \
        -d '{
            "name": "automatizaciones-api-key",
            "scopes": ["workflow:read", "workflow:write", "credential:read", "credential:write", "execution:read", "execution:write"]
        }' | jq -r '.apiKey' 2>/dev/null || echo "")
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
        warning "No se pudo generar API key automáticamente"
        warning "Genera una API key manualmente desde la interfaz web:"
        warning "1. Ve a http://localhost:5678"
        warning "2. Login con admin/admin123"
        warning "3. Ve a Settings > API Keys"
        warning "4. Crea una nueva API key"
        return 1
    fi
    
    success "API key generada: $API_KEY"
    echo "$API_KEY"
}

# Guardar API key en archivo
save_api_key() {
    local api_key="$1"
    
    log "Guardando API key en archivo..."
    
    cat > .env.api << EOF
# API Key de n8n para automatizaciones
N8N_API_KEY=$api_key
N8N_API_URL=http://localhost:5678/api/v1
EOF
    
    success "API key guardada en .env.api"
}

# Crear script de ejemplo para usar la API
create_api_examples() {
    log "Creando ejemplos de uso de la API..."
    
    cat > scripts/api-examples.sh << 'EOF'
#!/bin/bash

# ===========================================
# EJEMPLOS DE USO DE LA API DE N8N
# ===========================================

# Cargar variables de entorno
if [ -f ".env.api" ]; then
    source .env.api
else
    echo "Error: Archivo .env.api no encontrado"
    echo "Ejecuta primero: ./scripts/setup-api.sh"
    exit 1
fi

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

# Ejemplos de uso
echo "=== EJEMPLOS DE USO DE LA API DE N8N ==="
echo ""

echo "1. Listar todos los workflows:"
api_request "GET" "/workflows" | jq '.'

echo ""
echo "2. Crear un nuevo workflow:"
api_request "POST" "/workflows" '{
    "name": "Mi Workflow API",
    "nodes": [
        {
            "parameters": {},
            "id": "start",
            "name": "Start",
            "type": "n8n-nodes-base.start",
            "typeVersion": 1,
            "position": [240, 300]
        }
    ],
    "connections": {},
    "active": false,
    "settings": {},
    "staticData": null
}' | jq '.'

echo ""
echo "3. Activar un workflow (reemplaza WORKFLOW_ID):"
# api_request "PATCH" "/workflows/WORKFLOW_ID" '{"active": true}' | jq '.'

echo ""
echo "4. Listar credenciales:"
api_request "GET" "/credentials" | jq '.'

echo ""
echo "5. Crear credenciales:"
api_request "POST" "/credentials" '{
    "name": "Mi API Key",
    "type": "httpHeaderAuth",
    "data": {
        "name": "Authorization",
        "value": "Bearer tu-token-aqui"
    }
}' | jq '.'

echo ""
echo "6. Ejecutar un workflow manualmente:"
# api_request "POST" "/workflows/WORKFLOW_ID/execute" '{}' | jq '.'

echo ""
echo "7. Obtener ejecuciones de un workflow:"
# api_request "GET" "/executions?workflowId=WORKFLOW_ID" | jq '.'

echo ""
echo "=== FIN DE EJEMPLOS ==="
EOF
    
    chmod +x scripts/api-examples.sh
    success "Ejemplos de API creados en scripts/api-examples.sh"
}

# Mostrar información de la API
show_api_info() {
    local api_key="$1"
    
    echo ""
    echo "==========================================="
    echo "🔑 API DE N8N CONFIGURADA"
    echo "==========================================="
    echo ""
    echo "📡 Endpoint de la API:"
    echo "   URL: http://localhost:5678/api/v1"
    echo "   API Key: $api_key"
    echo ""
    echo "🔧 Headers requeridos:"
    echo "   X-N8N-API-KEY: $api_key"
    echo "   Content-Type: application/json"
    echo ""
    echo "📚 Endpoints principales:"
    echo "   GET    /workflows          - Listar workflows"
    echo "   POST   /workflows          - Crear workflow"
    echo "   PATCH  /workflows/{id}     - Actualizar workflow"
    echo "   DELETE /workflows/{id}     - Eliminar workflow"
    echo "   GET    /credentials        - Listar credenciales"
    echo "   POST   /credentials        - Crear credenciales"
    echo "   GET    /executions         - Listar ejecuciones"
    echo "   POST   /workflows/{id}/execute - Ejecutar workflow"
    echo ""
    echo "🧪 Probar la API:"
    echo "   ./scripts/api-examples.sh"
    echo ""
    echo "📖 Documentación completa:"
    echo "   https://docs.n8n.io/api/"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🔑 Configurando API de n8n Automatizaciones..."
    echo ""
    
    check_n8n
    create_admin_user
    
    # Generar API key
    API_KEY=$(generate_api_key)
    
    if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
        save_api_key "$API_KEY"
        create_api_examples
        show_api_info "$API_KEY"
        success "¡API configurada exitosamente!"
    else
        warning "Configuración manual requerida"
        show_api_info "TU_API_KEY_AQUI"
    fi
}

# Ejecutar función principal
main "$@"
