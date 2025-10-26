#!/bin/bash
set -euo pipefail

# Script para configurar DNS en Cloudflare vía CLI
# Uso: ./setup-cloudflare-dns.sh YOUR_API_TOKEN

if [ $# -eq 0 ]; then
    echo "❌ Error: Proporciona tu API token de Cloudflare"
    echo "Uso: $0 YOUR_API_TOKEN"
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

echo "🔧 Configurando DNS para $SUBDOMAIN.$DOMAIN"
echo "🎯 Apuntando a: $TARGET"
echo ""

# Obtener Zone ID
echo "📋 Obteniendo Zone ID para $DOMAIN..."
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | \
    jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
    echo "❌ Error: No se pudo obtener el Zone ID para $DOMAIN"
    echo "🔍 Verifica que el dominio esté en tu cuenta de Cloudflare"
    exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# Verificar si el registro ya existe
echo "🔍 Verificando si el registro ya existe..."
EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | \
    jq -r '.result[0].id')

if [ "$EXISTING_RECORD" != "null" ] && [ -n "$EXISTING_RECORD" ]; then
    echo "⚠️  El registro ya existe. Actualizando..."

    # Actualizar registro existente
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"CNAME\",
            \"name\": \"$SUBDOMAIN\",
            \"content\": \"$TARGET\",
            \"proxied\": true
        }")
else
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
fi

# Verificar respuesta
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
    echo "✅ ¡DNS configurado exitosamente!"
    echo "🌐 Subdominio: $SUBDOMAIN.$DOMAIN"
    echo "🎯 Apunta a: $TARGET"
    echo "🔒 Proxy: Activado (SSL automático)"
    echo ""
    echo "⏱️  La propagación puede tardar 1-2 horas"
    echo "🧪 Para probar: curl https://$SUBDOMAIN.$DOMAIN/healthz"
else
    echo "❌ Error al configurar DNS:"
    echo "$RESPONSE" | jq -r '.errors[0].message'
    exit 1
fi
