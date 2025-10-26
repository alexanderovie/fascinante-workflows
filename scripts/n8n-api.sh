#!/bin/bash

# ===========================================
# SCRIPT PARA GESTIÓN COMPLETA VIA API
# ===========================================

# Cargar variables de entorno
if [ -f ".env.api" ]; then
    source .env.api
else
    echo "⚠️  Archivo .env.api no encontrado"
    echo "📝 Crea el archivo .env.api con tu API key:"
    echo "   echo 'N8N_API_KEY=tu_api_key_aqui' > .env.api"
    echo "   echo 'N8N_API_URL=http://localhost:5678/api/v1' >> .env.api"
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

# Función para mostrar ayuda
show_help() {
    echo "🔧 Gestión de n8n via API"
    echo ""
    echo "Uso: $0 <comando> [argumentos]"
    echo ""
    echo "Comandos disponibles:"
    echo "  list-workflows              - Listar todos los workflows"
    echo "  create-workflow <nombre>    - Crear un workflow básico"
    echo "  activate-workflow <id>      - Activar un workflow"
    echo "  deactivate-workflow <id>    - Desactivar un workflow"
    echo "  execute-workflow <id>       - Ejecutar un workflow"
    echo "  delete-workflow <id>        - Eliminar un workflow"
    echo "  list-credentials            - Listar credenciales"
    echo "  create-credential <nombre>  - Crear credencial HTTP Header"
    echo "  list-executions             - Listar ejecuciones"
    echo "  get-workflow <id>           - Obtener detalles de workflow"
    echo "  export-workflow <id>        - Exportar workflow como JSON"
    echo "  import-workflow <archivo>   - Importar workflow desde JSON"
    echo ""
    echo "Ejemplos:"
    echo "  $0 list-workflows"
    echo "  $0 create-workflow 'Mi Workflow'"
    echo "  $0 activate-workflow 123"
    echo "  $0 execute-workflow 123"
}

# Listar workflows
list_workflows() {
    echo "📋 Listando workflows..."
    api_request "GET" "/workflows" | jq '.data[] | {id: .id, name: .name, active: .active, createdAt: .createdAt}' 2>/dev/null || api_request "GET" "/workflows"
}

# Crear workflow básico
create_workflow() {
    local name="$1"
    echo "➕ Creando workflow: $name"
    
    api_request "POST" "/workflows" "{
        \"name\": \"$name\",
        \"nodes\": [
            {
                \"parameters\": {},
                \"id\": \"start\",
                \"name\": \"Start\",
                \"type\": \"n8n-nodes-base.start\",
                \"typeVersion\": 1,
                \"position\": [240, 300]
            }
        ],
        \"connections\": {},
        \"active\": false,
        \"settings\": {},
        \"staticData\": null
    }" | jq '.' 2>/dev/null || echo "Workflow creado"
}

# Activar workflow
activate_workflow() {
    local id="$1"
    echo "▶️  Activando workflow: $id"
    api_request "PATCH" "/workflows/$id" '{"active": true}' | jq '.' 2>/dev/null || echo "Workflow activado"
}

# Desactivar workflow
deactivate_workflow() {
    local id="$1"
    echo "⏸️  Desactivando workflow: $id"
    api_request "PATCH" "/workflows/$id" '{"active": false}' | jq '.' 2>/dev/null || echo "Workflow desactivado"
}

# Ejecutar workflow
execute_workflow() {
    local id="$1"
    echo "🚀 Ejecutando workflow: $id"
    api_request "POST" "/workflows/$id/execute" '{}' | jq '.' 2>/dev/null || echo "Workflow ejecutado"
}

# Eliminar workflow
delete_workflow() {
    local id="$1"
    echo "🗑️  Eliminando workflow: $id"
    api_request "DELETE" "/workflows/$id" | jq '.' 2>/dev/null || echo "Workflow eliminado"
}

# Listar credenciales
list_credentials() {
    echo "🔑 Listando credenciales..."
    api_request "GET" "/credentials" | jq '.data[] | {id: .id, name: .name, type: .type}' 2>/dev/null || api_request "GET" "/credentials"
}

# Crear credencial HTTP Header
create_credential() {
    local name="$1"
    echo "🔑 Creando credencial: $name"
    
    api_request "POST" "/credentials" "{
        \"name\": \"$name\",
        \"type\": \"httpHeaderAuth\",
        \"data\": {
            \"name\": \"Authorization\",
            \"value\": \"Bearer tu-token-aqui\"
        }
    }" | jq '.' 2>/dev/null || echo "Credencial creada"
}

# Listar ejecuciones
list_executions() {
    echo "📊 Listando ejecuciones..."
    api_request "GET" "/executions" | jq '.data[] | {id: .id, workflowId: .workflowId, status: .status, startedAt: .startedAt}' 2>/dev/null || api_request "GET" "/executions"
}

# Obtener detalles de workflow
get_workflow() {
    local id="$1"
    echo "📄 Obteniendo detalles del workflow: $id"
    api_request "GET" "/workflows/$id" | jq '.' 2>/dev/null || api_request "GET" "/workflows/$id"
}

# Exportar workflow
export_workflow() {
    local id="$1"
    echo "📤 Exportando workflow: $id"
    api_request "GET" "/workflows/$id" | jq '.' > "workflow_${id}_$(date +%Y%m%d_%H%M%S).json" 2>/dev/null || echo "Workflow exportado"
}

# Importar workflow
import_workflow() {
    local file="$1"
    echo "📥 Importando workflow desde: $file"
    
    if [ ! -f "$file" ]; then
        echo "❌ Archivo no encontrado: $file"
        return 1
    fi
    
    api_request "POST" "/workflows" "$(cat "$file")" | jq '.' 2>/dev/null || echo "Workflow importado"
}

# Función principal
main() {
    case "${1:-help}" in
        "list-workflows")
            list_workflows
            ;;
        "create-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el nombre del workflow"
                echo "Uso: $0 create-workflow 'Mi Workflow'"
                exit 1
            fi
            create_workflow "$2"
            ;;
        "activate-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 activate-workflow 123"
                exit 1
            fi
            activate_workflow "$2"
            ;;
        "deactivate-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 deactivate-workflow 123"
                exit 1
            fi
            deactivate_workflow "$2"
            ;;
        "execute-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 execute-workflow 123"
                exit 1
            fi
            execute_workflow "$2"
            ;;
        "delete-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 delete-workflow 123"
                exit 1
            fi
            delete_workflow "$2"
            ;;
        "list-credentials")
            list_credentials
            ;;
        "create-credential")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el nombre de la credencial"
                echo "Uso: $0 create-credential 'Mi API Key'"
                exit 1
            fi
            create_credential "$2"
            ;;
        "list-executions")
            list_executions
            ;;
        "get-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 get-workflow 123"
                exit 1
            fi
            get_workflow "$2"
            ;;
        "export-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el ID del workflow"
                echo "Uso: $0 export-workflow 123"
                exit 1
            fi
            export_workflow "$2"
            ;;
        "import-workflow")
            if [ -z "${2:-}" ]; then
                echo "❌ Error: Debes especificar el archivo del workflow"
                echo "Uso: $0 import-workflow workflow.json"
                exit 1
            fi
            import_workflow "$2"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
