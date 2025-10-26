#!/bin/bash

# ===========================================
# SCRIPT DE INICIALIZACIÓN DE N8N
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

# Verificar que Docker esté instalado
check_docker() {
    log "Verificando instalación de Docker..."
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Por favor instala Docker primero."
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        exit 1
    fi
    
    success "Docker y Docker Compose están instalados"
}

# Verificar archivo .env
check_env() {
    log "Verificando archivo .env..."
    if [ ! -f ".env" ]; then
        error "Archivo .env no encontrado. Por favor crea el archivo .env primero."
        exit 1
    fi
    
    # Verificar variables críticas
    source .env
    if [ -z "${POSTGRES_PASSWORD:-}" ]; then
        error "POSTGRES_PASSWORD no está definido en .env"
        exit 1
    fi
    
    if [ -z "${N8N_BASIC_AUTH_PASSWORD:-}" ]; then
        error "N8N_BASIC_AUTH_PASSWORD no está definido en .env"
        exit 1
    fi
    
    success "Archivo .env configurado correctamente"
}

# Crear directorios necesarios
create_directories() {
    log "Creando directorios necesarios..."
    
    mkdir -p workflows
    mkdir -p credentials
    mkdir -p local-files
    mkdir -p backups
    mkdir -p scripts
    
    success "Directorios creados correctamente"
}

# Generar contraseñas seguras si no existen
generate_passwords() {
    log "Generando contraseñas seguras..."
    
    if [ ! -f ".env.generated" ]; then
        # Generar contraseña para PostgreSQL
        POSTGRES_PASSWORD_GEN=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        
        # Generar contraseña para n8n
        N8N_PASSWORD_GEN=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        
        # Crear archivo con contraseñas generadas
        cat > .env.generated << EOF
# Contraseñas generadas automáticamente - NO COMPARTIR
POSTGRES_PASSWORD_GENERATED=${POSTGRES_PASSWORD_GEN}
N8N_PASSWORD_GENERATED=${N8N_PASSWORD_GEN}
EOF
        
        warning "Contraseñas generadas y guardadas en .env.generated"
        warning "Para usar estas contraseñas, actualiza tu archivo .env"
    else
        log "Contraseñas ya generadas anteriormente"
    fi
}

# Inicializar Docker Compose
start_services() {
    log "Iniciando servicios con Docker Compose..."
    
    # Crear volúmenes si no existen
    docker volume create n8n_data 2>/dev/null || true
    docker volume create postgres_data 2>/dev/null || true
    
    # Levantar servicios
    docker compose up -d
    
    success "Servicios iniciados correctamente"
}

# Esperar a que los servicios estén listos
wait_for_services() {
    log "Esperando a que los servicios estén listos..."
    
    # Esperar PostgreSQL
    log "Esperando PostgreSQL..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose exec postgres pg_isready -U ${POSTGRES_USER:-n8n_user} -d ${POSTGRES_DB:-n8n_automatizaciones} &>/dev/null; then
            success "PostgreSQL está listo"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        error "PostgreSQL no se inició en el tiempo esperado"
        exit 1
    fi
    
    # Esperar n8n
    log "Esperando n8n..."
    timeout=120
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:5678/healthz &>/dev/null; then
            success "n8n está listo"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
        error "n8n no se inició en el tiempo esperado"
        exit 1
    fi
}

# Importar workflows si existen
import_workflows() {
    log "Verificando workflows para importar..."
    
    if [ -d "workflows" ] && [ "$(ls -A workflows 2>/dev/null)" ]; then
        log "Importando workflows..."
        docker compose exec n8n n8n import:workflow --separate --input /home/node/.n8n/workflows || warning "No se pudieron importar todos los workflows"
        success "Workflows importados"
    else
        log "No hay workflows para importar"
    fi
}

# Mostrar información de acceso
show_access_info() {
    echo ""
    echo "==========================================="
    echo "🚀 N8N AUTOMATIZACIONES INICIADO"
    echo "==========================================="
    echo ""
    echo "📱 Acceso a n8n:"
    echo "   URL: http://localhost:5678"
    echo "   Usuario: ${N8N_BASIC_AUTH_USER:-admin}"
    echo "   Contraseña: ${N8N_BASIC_AUTH_PASSWORD:-admin123}"
    echo ""
    echo "🗄️  Base de datos PostgreSQL:"
    echo "   Host: localhost:5432"
    echo "   Base de datos: ${POSTGRES_DB:-n8n_automatizaciones}"
    echo "   Usuario: ${POSTGRES_USER:-n8n_user}"
    echo ""
    echo "📁 Directorios:"
    echo "   Workflows: ./workflows"
    echo "   Credenciales: ./credentials"
    echo "   Archivos locales: ./local-files"
    echo "   Backups: ./backups"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   Ver logs: docker compose logs -f"
    echo "   Parar servicios: docker compose down"
    echo "   Reiniciar: docker compose restart"
    echo "   Backup: ./scripts/backup.sh"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🚀 Iniciando configuración de n8n Automatizaciones..."
    echo ""
    
    check_docker
    check_env
    create_directories
    generate_passwords
    start_services
    wait_for_services
    import_workflows
    show_access_info
    
    success "¡Configuración completada exitosamente!"
}

# Ejecutar función principal
main "$@"
