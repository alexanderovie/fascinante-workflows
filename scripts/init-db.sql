-- ===========================================
-- SCRIPT DE INICIALIZACIÓN DE BASE DE DATOS
-- ===========================================

-- Crear esquema si no existe
CREATE SCHEMA IF NOT EXISTS public;

-- Configurar permisos
GRANT ALL ON SCHEMA public TO n8n_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO n8n_user;

-- Configurar búsqueda de esquemas
ALTER DATABASE n8n_automatizaciones SET search_path TO public;

-- Crear extensiones útiles si no existen
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Configurar configuración de conexión
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET pg_stat_statements.track = 'all';

-- Configurar logs para debugging (opcional)
-- ALTER SYSTEM SET log_statement = 'all';
-- ALTER SYSTEM SET log_min_duration_statement = 1000;

-- Aplicar configuración
SELECT pg_reload_conf();

-- Mostrar información de la base de datos
SELECT 
    current_database() as database_name,
    current_user as current_user,
    version() as postgresql_version;
