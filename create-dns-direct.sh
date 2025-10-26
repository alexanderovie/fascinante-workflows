#!/bin/bash
set -euo pipefail

# Script para crear registro DNS directamente en Cloudflare
# Uso: ./create-dns-direct.sh TU_API_TOKEN

if [ $# -eq 0 ]; then
    echo "❌ Error: Proporciona tu API token de Cloudflare"
    echo "Uso: $0 TU_API_TOKEN"
    echo ""
    echo "📋 Para obtener tu API token:"
    echo "1. Ve a: https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Crea un token con permisos: Zone:Read, DNS:Edit"
    echo "3. Copia el token y úsalo con este script"
    exit 1
fi

API_TOKEN="$1"
DOMAIN="fascinantedigital.com"
SUBDOMAIN="workflows"
TARGET="uuwjibek.up.railway.app"

echo "🔧 CREANDO REGISTRO DNS DIRECTAMENTE"
echo "====================================="
echo "🌐 Dominio: $DOMAIN"
echo "🔧 Subdominio: $SUBDOMAIN"
echo "🎯 Apunta a: $TARGET"
echo ""

# Obtener Zone ID
echo "📋 Obteniendo Zone ID para $DOMAIN..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

# Verificar si hay errores
if echo "$ZONE_RESPONSE" | grep -q '"success":false'; then
    echo "❌ Error de autenticación:"
    echo "$ZONE_RESPONSE" | grep -o '"message":"[^"]*"'
    exit 1
fi

# Extraer Zone ID
ZONE_ID=$(echo "$ZONE_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//' | sed 's/"//')

if [ -z "$ZONE_ID" ]; then
    echo "❌ Error: No se pudo obtener el Zone ID para $DOMAIN"
    echo "🔍 Verifica que el dominio esté en tu cuenta de Cloudflare"
    echo "📋 Respuesta: $ZONE_RESPONSE"
    exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# Verificar si el registro ya existe
echo "🔍 Verificando si el registro ya existe..."
EXISTING_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

# Verificar si hay resultados
if echo "$EXISTING_RESPONSE" | grep -q '"result":\[\]'; then
    echo "➕ Creando nuevo registro DNS..."

    # Crear nuevo registro
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"CNAME\",
            \"name\": \"$SUBDOMAIN\",
            \"content\": \"$TARGET\",
            \"proxied\": true
        }")
else
    echo "⚠️  El registro ya existe. Actualizando..."

    # Extraer ID del registro existente
    EXISTING_ID=$(echo "$EXISTING_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//' | sed 's/"//')

    # Actualizar registro existente
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_ID" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"CNAME\",
            \"name\": \"$SUBDOMAIN\",
            \"content\": \"$TARGET\",
            \"proxied\": true
        }")
fi

# Verificar respuesta
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ ¡DNS configurado exitosamente!"
    echo "🌐 Subdominio: $SUBDOMAIN.$DOMAIN"
    echo "🎯 Apunta a: $TARGET"
    echo "🔒 Proxy: Activado (SSL automático)"
    echo ""
    echo "⏱️  La propagación puede tardar 5-15 minutos"
    echo "🧪 Para probar: curl https://$SUBDOMAIN.$DOMAIN/healthz"
else
    echo "❌ Error al configurar DNS:"
    echo "$RESPONSE"
    exit 1
fi
