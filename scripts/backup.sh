#!/bin/bash

# ===========================================
# SCRIPT DE BACKUP DE N8N AUTOMATIZACIONES
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
    if [ -f ".env" ]; then
        source .env
    else
        error "Archivo .env no encontrado"
        exit 1
    fi
}

# Crear directorio de backups
create_backup_dir() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Backup de PostgreSQL
backup_postgres() {
    local backup_dir="$1"
    
    log "Creando backup de PostgreSQL..."
    
    # Verificar que PostgreSQL esté corriendo
    if ! docker compose ps postgres | grep -q "Up"; then
        error "PostgreSQL no está corriendo"
        return 1
    fi
    
    # Crear backup
    docker compose exec -T postgres pg_dump \
        -U "${POSTGRES_USER:-n8n_user}" \
        -d "${POSTGRES_DB:-n8n_automatizaciones}" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --format=custom \
        --file="/tmp/n8n_backup_$(date +%Y%m%d_%H%M%S).dump"
    
    # Copiar backup al host
    docker compose cp postgres:/tmp/n8n_backup_$(date +%Y%m%d_%H%M%S).dump "$backup_dir/"
    
    # Limpiar archivo temporal en el contenedor
    docker compose exec postgres rm -f /tmp/n8n_backup_*.dump
    
    success "Backup de PostgreSQL completado: $backup_dir/n8n_backup_$(date +%Y%m%d_%H%M%S).dump"
}

# Backup de workflows y credenciales
backup_n8n_data() {
    local backup_dir="$1"
    
    log "Creando backup de datos de n8n..."
    
    # Crear directorio para datos de n8n
    mkdir -p "$backup_dir/n8n_data"
    
    # Copiar workflows
    if [ -d "workflows" ] && [ "$(ls -A workflows 2>/dev/null)" ]; then
        cp -r workflows "$backup_dir/n8n_data/"
        log "Workflows copiados"
    fi
    
    # Copiar credenciales
    if [ -d "credentials" ] && [ "$(ls -A credentials 2>/dev/null)" ]; then
        cp -r credentials "$backup_dir/n8n_data/"
        log "Credenciales copiadas"
    fi
    
    # Copiar archivos locales
    if [ -d "local-files" ] && [ "$(ls -A local-files 2>/dev/null)" ]; then
        cp -r local-files "$backup_dir/n8n_data/"
        log "Archivos locales copiados"
    fi
    
    success "Backup de datos de n8n completado"
}

# Backup de configuración
backup_config() {
    local backup_dir="$1"
    
    log "Creando backup de configuración..."
    
    # Copiar archivos de configuración
    cp docker-compose.yml "$backup_dir/" 2>/dev/null || true
    cp .env "$backup_dir/" 2>/dev/null || true
    cp .env.generated "$backup_dir/" 2>/dev/null || true
    
    # Crear archivo de información del backup
    cat > "$backup_dir/backup_info.txt" << EOF
Backup creado: $(date)
Versión de n8n: $(docker compose exec n8n n8n --version 2>/dev/null || echo "No disponible")
Versión de PostgreSQL: $(docker compose exec postgres psql -U ${POSTGRES_USER:-n8n_user} -d ${POSTGRES_DB:-n8n_automatizaciones} -c "SELECT version();" 2>/dev/null | head -n 3 || echo "No disponible")
Directorio de backup: $backup_dir
EOF
    
    success "Backup de configuración completado"
}

# Comprimir backup
compress_backup() {
    local backup_dir="$1"
    local backup_name=$(basename "$backup_dir")
    
    log "Comprimiendo backup..."
    
    cd backups
    tar -czf "${backup_name}.tar.gz" "$backup_name"
    rm -rf "$backup_name"
    cd ..
    
    success "Backup comprimido: backups/${backup_name}.tar.gz"
}

# Limpiar backups antiguos
cleanup_old_backups() {
    local keep_days="${1:-7}"
    
    log "Limpiando backups más antiguos de $keep_days días..."
    
    find backups -name "*.tar.gz" -type f -mtime +$keep_days -delete 2>/dev/null || true
    
    success "Limpieza de backups antiguos completada"
}

# Mostrar información del backup
show_backup_info() {
    local backup_file="$1"
    
    echo ""
    echo "==========================================="
    echo "💾 BACKUP COMPLETADO"
    echo "==========================================="
    echo ""
    echo "📁 Archivo de backup: $backup_file"
    echo "📊 Tamaño: $(du -h "$backup_file" | cut -f1)"
    echo "📅 Fecha: $(date)"
    echo ""
    echo "🔧 Para restaurar:"
    echo "   ./scripts/restore.sh $backup_file"
    echo ""
    echo "==========================================="
}

# Función principal
main() {
    echo "💾 Iniciando backup de n8n Automatizaciones..."
    echo ""
    
    load_env
    
    # Crear directorio de backup
    backup_dir=$(create_backup_dir)
    
    # Realizar backups
    backup_postgres "$backup_dir"
    backup_n8n_data "$backup_dir"
    backup_config "$backup_dir"
    
    # Comprimir backup
    compress_backup "$backup_dir"
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    # Mostrar información
    show_backup_info "backups/$(basename "$backup_dir").tar.gz"
    
    success "¡Backup completado exitosamente!"
}

# Ejecutar función principal
main "$@"
