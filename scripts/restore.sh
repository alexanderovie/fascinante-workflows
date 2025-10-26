#!/bin/bash

# ===========================================
# SCRIPT DE RESTAURACIÓN DE N8N AUTOMATIZACIONES
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

# Mostrar ayuda
show_help() {
    echo "Uso: $0 <archivo_backup.tar.gz> [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --force     Forzar restauración sin confirmación"
    echo "  --help      Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 backups/20241201_143022.tar.gz"
    echo "  $0 backups/20241201_143022.tar.gz --force"
}

# Verificar argumentos
check_arguments() {
    if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    backup_file="$1"
    force_restore="${2:-}"
    
    if [ ! -f "$backup_file" ]; then
        error "Archivo de backup no encontrado: $backup_file"
        exit 1
    fi
    
    if [[ "$backup_file" != *.tar.gz ]]; then
        error "El archivo de backup debe ser un archivo .tar.gz"
        exit 1
    fi
}

# Confirmar restauración
confirm_restore() {
    if [ "$force_restore" != "--force" ]; then
        echo ""
        warning "⚠️  ADVERTENCIA: Esta operación reemplazará todos los datos actuales"
        warning "⚠️  Asegúrate de hacer un backup antes de continuar"
        echo ""
        read -p "¿Estás seguro de que quieres continuar? (escribe 'SI' para confirmar): " confirmation
        
        if [ "$confirmation" != "SI" ]; then
            log "Restauración cancelada por el usuario"
            exit 0
        fi
    fi
}

# Cargar variables de entorno
load_env() {
    if [ -f ".env" ]; then
        source .env
    else
        error "Archivo .env no encontrado"
        exit 1
    fi
}

# Parar servicios
stop_services() {
    log "Parando servicios..."
    docker compose down
    success "Servicios parados"
}

# Extraer backup
extract_backup() {
    local backup_file="$1"
    local temp_dir="/tmp/n8n_restore_$(date +%s)"
    
    log "Extrayendo backup..."
    
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Encontrar el directorio extraído
    extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "20*" | head -n 1)
    
    if [ -z "$extracted_dir" ]; then
        error "No se pudo encontrar el directorio de backup extraído"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    echo "$extracted_dir"
}

# Restaurar PostgreSQL
restore_postgres() {
    local backup_dir="$1"
    
    log "Restaurando PostgreSQL..."
    
    # Buscar archivo de backup de PostgreSQL
    local pg_backup=$(find "$backup_dir" -name "n8n_backup_*.dump" | head -n 1)
    
    if [ -z "$pg_backup" ]; then
        error "No se encontró backup de PostgreSQL"
        return 1
    fi
    
    # Copiar archivo de backup al contenedor
    docker compose cp "$pg_backup" postgres:/tmp/restore.dump
    
    # Restaurar base de datos
    docker compose exec postgres pg_restore \
        -U "${POSTGRES_USER:-n8n_user}" \
        -d "${POSTGRES_DB:-n8n_automatizaciones}" \
        --verbose \
        --clean \
        --if-exists \
        /tmp/restore.dump || warning "Algunos objetos no se pudieron restaurar (esto es normal)"
    
    # Limpiar archivo temporal
    docker compose exec postgres rm -f /tmp/restore.dump
    
    success "PostgreSQL restaurado"
}

# Restaurar datos de n8n
restore_n8n_data() {
    local backup_dir="$1"
    
    log "Restaurando datos de n8n..."
    
    # Restaurar workflows
    if [ -d "$backup_dir/n8n_data/workflows" ]; then
        rm -rf workflows
        cp -r "$backup_dir/n8n_data/workflows" .
        log "Workflows restaurados"
    fi
    
    # Restaurar credenciales
    if [ -d "$backup_dir/n8n_data/credentials" ]; then
        rm -rf credentials
        cp -r "$backup_dir/n8n_data/credentials" .
        log "Credenciales restauradas"
    fi
    
    # Restaurar archivos locales
    if [ -d "$backup_dir/n8n_data/local-files" ]; then
        rm -rf local-files
        cp -r "$backup_dir/n8n_data/local-files" .
        log "Archivos locales restaurados"
    fi
    
    success "Datos de n8n restaurados"
}

# Restaurar configuración
restore_config() {
    local backup_dir="$1"
    
    log "Restaurando configuración..."
    
    # Crear backup de configuración actual
    if [ -f ".env" ]; then
        cp .env ".env.backup.$(date +%Y%m%d_%H%M%S)"
        log "Backup de .env actual creado"
    fi
    
    # Restaurar archivos de configuración si existen
    if [ -f "$backup_dir/.env" ]; then
        cp "$backup_dir/.env" .env
        log "Archivo .env restaurado"
    fi
    
    if [ -f "$backup_dir/.env.generated" ]; then
        cp "$backup_dir/.env.generated" .env.generated
        log "Archivo .env.generated restaurado"
    fi
    
    success "Configuración restaurada"
}

# Iniciar servicios
start_services() {
    log "Iniciando servicios..."
    docker compose up -d
    success "Servicios iniciados"
}

# Esperar a que los servicios estén listos
wait_for_services() {
    log "Esperando a que los servicios estén listos..."
    
    # Esperar PostgreSQL
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose exec postgres pg_isready -U ${POSTGRES_USER:-n8n_user} -d ${POSTGRES_DB:-n8n_automatizaciones} &>/dev/null; then
            success "PostgreSQL está listo"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    # Esperar n8n
    timeout=120
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:5678/healthz &>/dev/null; then
            success "n8n está listo"
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
}

# Limpiar archivos temporales
cleanup() {
    local temp_dir="$1"
    rm -rf "$temp_dir"
    log "Archivos temporales limpiados"
}

# Mostrar información de restauración
show_restore_info() {
    echo ""
    echo "==========================================="
    echo "🔄 RESTAURACIÓN COMPLETADA"
    echo "==========================================="
    echo ""
    echo "📱 Acceso a n8n:"
    echo "   URL: http://localhost:5678"
    echo "   Usuario: ${N8N_BASIC_AUTH_USER:-admin}"
    echo "   Contraseña: ${N8N_BASIC_AUTH_PASSWORD:-admin123}"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   Ver logs: docker compose logs -f"
    echo "   Parar servicios: docker compose down"
    echo "   Reiniciar: docker compose restart"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "🔄 Iniciando restauración de n8n Automatizaciones..."
    echo ""
    
    check_arguments "$@"
    confirm_restore
    load_env
    stop_services
    
    # Extraer backup
    backup_dir=$(extract_backup "$backup_file")
    
    # Restaurar componentes
    restore_postgres "$backup_dir"
    restore_n8n_data "$backup_dir"
    restore_config "$backup_dir"
    
    # Iniciar servicios
    start_services
    wait_for_services
    
    # Limpiar archivos temporales
    cleanup "$backup_dir"
    
    # Mostrar información
    show_restore_info
    
    success "¡Restauración completada exitosamente!"
}

# Ejecutar función principal
main "$@"
