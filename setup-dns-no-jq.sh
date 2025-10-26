#!/bin/bash
set -euo pipefail

# Script para configurar DNS en Cloudflare sin jq
# Uso: ./setup-dns-no-jq.sh

DOMAIN="fascinantedigital.com"
SUBDOMAIN="workflows"
TARGET="uuwjibek.up.railway.app"
OAUTH_TOKEN="y9uU4YxaOSHpgfM4sAvVZITvNfaaa4bktHJF8PKxXbk.-J5KatunZ_Bh400LjOcLVhlpWHtn4G3YJCFE3JQI25c"

echo "🔧 Configurando DNS para $SUBDOMAIN.$DOMAIN"
echo "🎯 Apuntando a: $TARGET"
echo ""

# Obtener Zone ID
echo "📋 Obteniendo Zone ID para $DOMAIN..."
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $OAUTH_TOKEN" \
    -H "Content-Type: application/json")

# Extraer Zone ID usando grep y sed (sin jq)
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
    -H "Authorization: Bearer $OAUTH_TOKEN" \
    -H "Content-Type: application/json")

# Verificar si hay resultados
if echo "$EXISTING_RESPONSE" | grep -q '"result":\[\]'; then
    echo "➕ Creando nuevo registro DNS..."
    
    # Crear nuevo registro
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "Authorization: Bearer $OAUTH_TOKEN" \
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
        -H "Authorization: Bearer $OAUTH_TOKEN" \
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
    echo "⏱️  La propagación puede tardar 1-2 horas"
    echo "🧪 Para probar: curl https://$SUBDOMAIN.$DOMAIN/healthz"
else
    echo "❌ Error al configurar DNS:"
    echo "$RESPONSE"
    exit 1
fi
