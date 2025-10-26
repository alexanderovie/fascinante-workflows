#!/bin/bash
set -euo pipefail

# Script para configurar DNS en Cloudflare usando wrangler
# Uso: ./setup-cloudflare-dns-wrangler.sh

DOMAIN="fascinantedigital.com"
SUBDOMAIN="workflows"
TARGET="uuwjibek.up.railway.app"

echo "🔧 Configurando DNS para $SUBDOMAIN.$DOMAIN usando wrangler"
echo "🎯 Apuntando a: $TARGET"
echo ""

# Verificar que wrangler esté configurado
if ! wrangler whoami >/dev/null 2>&1; then
    echo "❌ Error: wrangler no está configurado"
    echo "🔧 Ejecuta: wrangler login"
    exit 1
fi

echo "✅ wrangler configurado correctamente"

# Obtener Account ID
ACCOUNT_ID=$(wrangler whoami | grep "Account ID" | awk '{print $3}')
echo "🔑 Account ID: $ACCOUNT_ID"

# Obtener Zone ID usando la API de Cloudflare
echo "📋 Obteniendo Zone ID para $DOMAIN..."

# Usar el token de wrangler para hacer la llamada API
WRANGLER_CONFIG="$HOME/.config/.wrangler/config"
if [ -f "$WRANGLER_CONFIG" ]; then
    # Extraer el token del archivo de configuración de wrangler
    OAUTH_TOKEN=$(grep -o '"oauth_token":"[^"]*"' "$WRANGLER_CONFIG" | cut -d'"' -f4)
    
    if [ -n "$OAUTH_TOKEN" ]; then
        echo "🔑 Token OAuth encontrado"
        
        # Obtener Zone ID
        ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
            -H "Authorization: Bearer $OAUTH_TOKEN" \
            -H "Content-Type: application/json")
        
        ZONE_ID=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].id')
        
        if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
            echo "❌ Error: No se pudo obtener el Zone ID para $DOMAIN"
            echo "🔍 Verifica que el dominio esté en tu cuenta de Cloudflare"
            exit 1
        fi
        
        echo "✅ Zone ID: $ZONE_ID"
        
        # Verificar si el registro ya existe
        echo "🔍 Verificando si el registro ya existe..."
        EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
            -H "Authorization: Bearer $OAUTH_TOKEN" \
            -H "Content-Type: application/json" | \
            jq -r '.result[0].id')
        
        if [ "$EXISTING_RECORD" != "null" ] && [ -n "$EXISTING_RECORD" ]; then
            echo "⚠️  El registro ya existe. Actualizando..."
            
            # Actualizar registro existente
            RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD" \
                -H "Authorization: Bearer $OAUTH_TOKEN" \
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
        
    else
        echo "❌ No se pudo extraer el token OAuth de wrangler"
        echo "🔧 Intenta hacer login nuevamente: wrangler login"
        exit 1
    fi
else
    echo "❌ No se encontró el archivo de configuración de wrangler"
    echo "🔧 Ejecuta: wrangler login"
    exit 1
fi
