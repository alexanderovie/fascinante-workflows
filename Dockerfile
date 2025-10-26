FROM docker.n8n.io/n8nio/n8n:latest

# Exponer puerto
EXPOSE 5678

# Comando por defecto
CMD ["n8n", "start"]
