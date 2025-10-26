#!/bin/bash

# ===========================================
# EJEMPLOS DE USO DE LA API DE N8N
# ===========================================

# Cargar variables de entorno
if [ -f ".env.api" ]; then
    source .env.api
else
    echo "⚠️  Archivo .env.api no encontrado"
    echo "📝 Crea el archivo .env.api con tu API key:"
    echo "   echo 'N8N_API_KEY=tu_api_key_aqui' > .env.api"
    echo "   echo 'N8N_API_URL=http://localhost:5678/api/v1' >> .env.api"
    echo ""
    echo "🔑 Para obtener tu API key:"
    echo "   1. Ve a http://localhost:5678"
    echo "   2. Login con admin/admin123"
    echo "   3. Ve a Settings > API Keys"
    echo "   4. Crea una nueva API key"
    echo ""
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

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== EJEMPLOS DE USO DE LA API DE N8N ===${NC}"
echo ""

echo -e "${GREEN}1. Listar todos los workflows:${NC}"
api_request "GET" "/workflows" | jq '.' 2>/dev/null || echo "Error: Instala jq para mejor formato: sudo apt install jq"

echo ""
echo -e "${GREEN}2. Crear un nuevo workflow:${NC}"
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
}' | jq '.' 2>/dev/null || echo "Workflow creado (usa jq para ver formato)"

echo ""
echo -e "${GREEN}3. Listar credenciales:${NC}"
api_request "GET" "/credentials" | jq '.' 2>/dev/null || echo "Credenciales listadas"

echo ""
echo -e "${GREEN}4. Crear credenciales HTTP Header:${NC}"
api_request "POST" "/credentials" '{
    "name": "Mi API Key",
    "type": "httpHeaderAuth",
    "data": {
        "name": "Authorization",
        "value": "Bearer tu-token-aqui"
    }
}' | jq '.' 2>/dev/null || echo "Credencial creada"

echo ""
echo -e "${GREEN}5. Obtener información del usuario:${NC}"
api_request "GET" "/me" | jq '.' 2>/dev/null || echo "Info de usuario obtenida"

echo ""
echo -e "${YELLOW}=== COMANDOS ÚTILES ===${NC}"
echo ""
echo "Para activar un workflow:"
echo "api_request 'PATCH' '/workflows/WORKFLOW_ID' '{\"active\": true}'"
echo ""
echo "Para ejecutar un workflow:"
echo "api_request 'POST' '/workflows/WORKFLOW_ID/execute' '{}'"
echo ""
echo "Para obtener ejecuciones:"
echo "api_request 'GET' '/executions?workflowId=WORKFLOW_ID'"
echo ""
echo "Para eliminar un workflow:"
echo "api_request 'DELETE' '/workflows/WORKFLOW_ID'"
echo ""
echo -e "${BLUE}=== FIN DE EJEMPLOS ===${NC}"
