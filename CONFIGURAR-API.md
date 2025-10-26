# ===========================================
# CONFIGURACIÓN SEGURA DE API DE N8N
# ===========================================

# PASO 1: Obtener tu API Key
echo "🔑 PASO 1: Obtener tu API Key"
echo ""
echo "1. Ve a: http://localhost:5678"
echo "2. Login con: admin / admin123"
echo "3. Ve a: Settings (⚙️) > API Keys"
echo "4. Click en: 'Create API Key'"
echo "5. Dale un nombre: 'automatizaciones-api'"
echo "6. Selecciona los scopes:"
echo "   ✅ workflow:read"
echo "   ✅ workflow:write"
echo "   ✅ credential:read"
echo "   ✅ credential:write"
echo "   ✅ execution:read"
echo "   ✅ execution:write"
echo "7. Click en: 'Create'"
echo "8. COPIA la API key que aparece"
echo ""

# PASO 2: Crear archivo de configuración
echo "📝 PASO 2: Crear archivo de configuración"
echo ""
echo "Ejecuta estos comandos (reemplaza TU_API_KEY con la que copiaste):"
echo ""
echo "echo 'N8N_API_KEY=TU_API_KEY' > .env.api"
echo "echo 'N8N_API_URL=http://localhost:5678/api/v1' >> .env.api"
echo ""

# PASO 3: Probar la API
echo "🧪 PASO 3: Probar la API"
echo ""
echo "Una vez configurado, puedes usar:"
echo ""
echo "# Listar workflows"
echo "./scripts/n8n-api.sh list-workflows"
echo ""
echo "# Crear un workflow"
echo "./scripts/n8n-api.sh create-workflow 'Mi Workflow'"
echo ""
echo "# Ver ejemplos completos"
echo "./scripts/api-examples.sh"
echo ""

# PASO 4: Seguridad
echo "🔒 PASO 4: Seguridad"
echo ""
echo "✅ El archivo .env.api está en .gitignore"
echo "✅ No compartas tu API key"
echo "✅ Puedes regenerar la API key cuando quieras"
echo "✅ La API key tiene permisos limitados"
echo ""

echo "==========================================="
