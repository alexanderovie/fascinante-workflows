# ===========================================
# CONFIGURACIÓN CAL.COM + GMAIL (SIN WHATSAPP)
# ===========================================

## 📧 **CAL.COM + GMAIL ES PERFECTO PARA EMAIL**

### ✅ **Lo que necesitas:**

#### **1. Cal.com (ya tienes)**
- ✅ Cuenta de Cal.com
- 🔑 API Key de Cal.com

#### **2. Gmail (fácil de configurar)**
- ✅ Cuenta de Gmail
- 🔑 OAuth2 de Gmail (se configura automáticamente)

#### **3. n8n (ya tienes)**
- ✅ n8n funcionando
- ✅ API key configurada

## 🚀 **PASOS SÚPER RÁPIDOS:**

### **PASO 1: Obtener API Key de Cal.com** (2 minutos)
1. Ve a: https://cal.com/settings/developer
2. Click: "Create API Key"
3. Nombre: "n8n-automatizaciones"
4. **COPIA** la API key

### **PASO 2: Crear Credenciales en n8n** (3 minutos)

#### **A. Cal.com API:**
1. Ve a: http://localhost:5678
2. Credentials → Create Credential
3. Busca: "Cal.com API"
4. Pega tu API key de Cal.com
5. Save

#### **B. Gmail OAuth2:**
1. Credentials → Create Credential
2. Busca: "Gmail OAuth2 API"
3. Click: "Connect my account"
4. Autoriza el acceso a tu Gmail
5. Save

### **PASO 3: Crear Workflow** (5 minutos)
1. Workflows → Create Workflow
2. Busca: "Cal.com Trigger"
3. Configura:
   - **Credential**: Cal.com API
   - **Event**: Booking Created
4. Busca: "Gmail"
5. Configura:
   - **Credential**: Gmail OAuth2 API
   - **To Email**: tu-email@gmail.com
   - **Subject**: Nueva reserva en Cal.com: {{ $json.event.title }}
   - **Message**:
   ```
   Hola!

   Has recibido una nueva reserva en Cal.com:

   📅 Título: {{ $json.event.title }}
   📅 Fecha: {{ $json.event.startTime }}
   👤 Cliente: {{ $json.event.attendees[0].name }}
   📧 Email: {{ $json.event.attendees[0].email }}
   📍 Ubicación: {{ $json.event.location }}

   ¡Que tengas una excelente reunión!
   ```
6. Conecta los nodos
7. Save

### **PASO 4: Configurar Webhook en Cal.com** (2 minutos)
1. Ve a: https://cal.com/settings/webhooks
2. Create Webhook
3. URL: `http://localhost:5678/webhook/[webhook-id-del-nodo]`
4. Event: "Booking Created"
5. Save

### **PASO 5: ¡Probar!** (1 minuto)
1. Activa el workflow en n8n
2. Haz una reserva en Cal.com
3. **¡Revisa tu email!** 📧

## 📧 **EJEMPLO DE EMAIL QUE RECIBIRÁS:**

```
Subject: Nueva reserva en Cal.com: Reunión de Consultoría

Hola!

Has recibido una nueva reserva en Cal.com:

📅 Título: Reunión de Consultoría
📅 Fecha: 2025-10-27 14:00:00
👤 Cliente: Juan Pérez
📧 Email: juan@ejemplo.com
📍 Ubicación: Virtual (Zoom)

¡Que tengas una excelente reunión!
```

## 🎯 **VENTAJAS DE GMAIL vs WHATSAPP:**

### **✅ Gmail es mejor porque:**
- **📧 Universal**: Todos tienen email
- **🔒 Seguro**: OAuth2 nativo de Google
- **📱 Móvil**: Notificaciones push en el teléfono
- **💾 Historial**: Queda guardado en Gmail
- **🔍 Búsqueda**: Fácil encontrar emails antiguos
- **📎 Adjuntos**: Puedes agregar archivos
- **🎨 Formato**: HTML bonito con emojis

### **❌ WhatsApp requiere:**
- WhatsApp Business API
- Número de teléfono verificado
- Configuración más compleja
- Costos adicionales

## 🚀 **AUTOMATIZACIONES ADICIONALES:**

### **1. Email de Confirmación al Cliente**
```
Cal.com Trigger → Gmail → Email al cliente con detalles
```

### **2. Actualizar Google Sheets**
```
Cal.com Trigger → Google Sheets → Agregar nueva reserva
```

### **3. Crear Evento en Google Calendar**
```
Cal.com Trigger → Google Calendar → Crear evento automático
```

### **4. Enviar Recordatorio**
```
Cal.com Trigger → Wait (1 día) → Gmail → Recordatorio
```

## 🔧 **COMANDOS ÚTILES:**

```bash
# Crear workflow automáticamente
./scripts/setup-cal-gmail.sh

# Ver workflows
./scripts/n8n-api.sh list-workflows

# Activar workflow
./scripts/n8n-api.sh activate-workflow WORKFLOW_ID

# Ver ejecuciones
./scripts/n8n-api.sh list-executions
```

## ⏱️ **TIEMPO TOTAL: ~13 minutos**

1. **API Key Cal.com**: 2 minutos
2. **Credenciales n8n**: 3 minutos
3. **Crear workflow**: 5 minutos
4. **Configurar webhook**: 2 minutos
5. **Probar**: 1 minuto

## 🎉 **¡EMPEZAR AHORA!**

**Cal.com + Gmail es la combinación perfecta:**
- ✅ **Rápido de configurar**
- ✅ **Visual e inmediato**
- ✅ **Útil para el día a día**
- ✅ **Fácil de personalizar**
- ✅ **Sin costos adicionales**

**¿Quieres que te ayude con algún paso específico?** 🚀
