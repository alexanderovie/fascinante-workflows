# Dockerfile Elite Pro para n8n en Railway (Octubre 2025)
FROM docker.n8n.io/n8nio/n8n:latest

# Instalar curl para healthcheck personalizado
USER root
RUN apk add --no-cache curl
USER node

# Crear script de healthcheck personalizado
RUN echo '#!/bin/sh\ncurl -f http://localhost:5678/healthz || exit 1' > /home/node/healthcheck.sh && \
    chmod +x /home/node/healthcheck.sh

# Configurar variables de entorno por defecto
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV NODE_ENV=production
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV N8N_RUNNERS_ENABLED=true

# Exponer puerto
EXPOSE 5678

# Comando de inicio optimizado
CMD ["n8n", "start"]
