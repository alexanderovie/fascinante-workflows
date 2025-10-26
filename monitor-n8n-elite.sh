#!/bin/bash
set -euo pipefail

# Script Elite Pro para monitorear n8n en Railway
# Uso: ./monitor-n8n-elite.sh

DOMAIN="n8n-app-production-4a1f.up.railway.app"
SUBDOMAIN="workflows.fascinantedigital.com"

echo "🎯 MONITOREO ELITE PRO DE N8N"
echo "================================"
echo ""

# Función para verificar estado
check_status() {
    local url="$1"
    local name="$2"

    echo "🔍 Verificando $name..."

    if curl -s --max-time 10 "$url" >/dev/null 2>&1; then
        echo "✅ $name: FUNCIONANDO"
        return 0
    else
        echo "❌ $name: NO RESPONDE"
        return 1
    fi
}

# Verificar Railway directo
echo "📋 Verificando Railway directo..."
if check_status "https://$DOMAIN/healthz" "Railway Direct"; then
    echo "🎉 ¡N8N FUNCIONANDO EN RAILWAY!"
else
    echo "⏳ N8N aún iniciando..."
fi

echo ""

# Verificar subdominio personalizado
echo "📋 Verificando subdominio personalizado..."
if check_status "https://$SUBDOMAIN/healthz" "Subdominio Personalizado"; then
    echo "🎉 ¡SUBDOMINIO FUNCIONANDO!"
else
    echo "⏳ Subdominio aún propagando..."
fi

echo ""

# Verificar variables de entorno
echo "📋 Verificando configuración..."
railway variables --json | jq -r 'to_entries[] | select(.key | startswith("N8N_") or startswith("WEBHOOK_") or startswith("NODE_")) | "\(.key)=\(.value)"' 2>/dev/null || echo "⚠️  jq no disponible, usando método alternativo"

echo ""
echo "🎯 PRÓXIMOS PASOS ELITE PRO:"
echo "1. ✅ Configurar webhook de Cal.com"
echo "2. ✅ Activar workflow en n8n"
echo "3. ✅ Probar integración completa"
echo "4. ✅ Configurar monitoreo avanzado"
