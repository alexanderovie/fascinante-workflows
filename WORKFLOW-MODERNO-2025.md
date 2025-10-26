# ===========================================
# WORKFLOW MODERNO CAL.COM + GMAIL (2025)
# ===========================================

## 🚀 **LO QUE NECESITAMOS PARA EL WORKFLOW MODERNO:**

### ✅ **Requisitos modernos (2025):**

#### **1. Cal.com (Actualizado)**
- ✅ Cuenta de Cal.com
- 🔑 API Key con scopes modernos
- 🌐 Webhook configurado

#### **2. Gmail (OAuth2 moderno)**
- ✅ Cuenta de Gmail
- 🔑 OAuth2 con scopes actualizados
- 📧 Permisos de envío

#### **3. n8n (Configuración moderna)**
- ✅ n8n funcionando
- ✅ API key configurada
- ✅ Credenciales modernas

## 🎯 **PASOS PARA CREAR EL WORKFLOW MODERNO:**

### **PASO 1: Obtener API Key de Cal.com (2025)** ⏱️ 2 minutos
1. Ve a: https://cal.com/settings/developer
2. Click: "Create API Key"
3. **Configuración moderna:**
   - **Name**: `n8n-modern-2025`
   - **Scopes**:
     - ✅ `booking:read`
     - ✅ `webhook:create`
     - ✅ `event:read`
4. **COPIA** la API key

### **PASO 2: Crear Credenciales Modernas en n8n** ⏱️ 3 minutos

#### **A. Cal.com API (Moderno):**
1. Ve a: http://localhost:5678
2. **Credentials** → **Create Credential**
3. Busca: **"Cal.com API"**
4. **Configuración moderna:**
   - **Name**: `Cal.com Modern API`
   - **API Key**: [Pega tu API key]
   - **Base URL**: `https://api.cal.com/v1` (si aplica)
5. **Save**

#### **B. Gmail OAuth2 (Moderno):**
1. **Credentials** → **Create Credential**
2. Busca: **"Gmail OAuth2 API"**
3. **Configuración moderna:**
   - **Name**: `Gmail Modern OAuth2`
   - Click: **"Connect my account"**
   - **Scopes modernos**:
     - ✅ `https://www.googleapis.com/auth/gmail.send`
     - ✅ `https://www.googleapis.com/auth/gmail.compose`
     - ✅ `https://www.googleapis.com/auth/gmail.modify`
4. **Autoriza** el acceso
5. **Save**

### **PASO 3: Crear Workflow Moderno** ⏱️ 5 minutos
1. **Workflows** → **Create Workflow**
2. **Busca**: "Cal.com Trigger"
3. **Configuración moderna del trigger:**
   - **Credential**: `Cal.com Modern API`
   - **Event**: `Booking Created`
   - **Webhook ID**: `cal-modern-$(date +%s)`
4. **Busca**: "Gmail"
5. **Configuración moderna del email:**
   - **Credential**: `Gmail Modern OAuth2`
   - **To Email**: `tu-email@gmail.com`
   - **Subject**: `📅 Nueva reserva: {{ $json.event.title }}`
   - **Message**:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <style>
       body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
       h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
       .booking-details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
       .detail-row { margin: 10px 0; display: flex; align-items: center; }
       .detail-label { font-weight: bold; min-width: 120px; color: #2c3e50; }
       .detail-value { color: #555; }
       .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 14px; }
     </style>
   </head>
   <body>
     <h1>🎉 Nueva Reserva en Cal.com</h1>
     <div class="booking-details">
       <div class="detail-row">
         <span class="detail-label">📅 Título:</span>
         <span class="detail-value">{{ $json.event.title }}</span>
       </div>
       <div class="detail-row">
         <span class="detail-label">📅 Fecha:</span>
         <span class="detail-value">{{ $json.event.startTime }}</span>
       </div>
       <div class="detail-row">
         <span class="detail-label">👤 Cliente:</span>
         <span class="detail-value">{{ $json.event.attendees[0].name || "No especificado" }}</span>
       </div>
       <div class="detail-row">
         <span class="detail-label">📧 Email:</span>
         <span class="detail-value">{{ $json.event.attendees[0].email || "No especificado" }}</span>
       </div>
       <div class="detail-row">
         <span class="detail-label">📍 Ubicación:</span>
         <span class="detail-value">{{ $json.event.location || "Virtual" }}</span>
       </div>
       <div class="detail-row">
         <span class="detail-label">⏰ Duración:</span>
         <span class="detail-value">{{ $json.event.duration || "No especificada" }} minutos</span>
       </div>
     </div>
     <p>¡Que tengas una excelente reunión! 🚀</p>
     <div class="footer">
       <p>Este email fue generado automáticamente por tu sistema de automatización n8n.</p>
       <p>Fecha de generación: {{ new Date().toLocaleString() }}</p>
     </div>
   </body>
   </html>
   ```
   - **Options**: ✅ **HTML**: true
6. **Conecta** los nodos
7. **Save**

### **PASO 4: Configurar Webhook Moderno en Cal.com** ⏱️ 2 minutos
1. Ve a: https://cal.com/settings/webhooks
2. **Create Webhook**
3. **Configuración moderna:**
   - **URL**: `http://localhost:5678/webhook/cal-modern-[webhook-id]`
   - **Events**:
     - ✅ `Booking Created`
     - ✅ `Booking Cancelled`
     - ✅ `Booking Rescheduled`
   - **Headers**:
     - `Content-Type: application/json`
   - **Secret**: (opcional, para seguridad)
4. **Save**

### **PASO 5: Activar y Probar** ⏱️ 1 minuto
1. **Activa** el workflow en n8n
2. **Haz una reserva** en Cal.com
3. **Revisa tu email** (debería ser HTML bonito)
4. **Ve a** http://localhost:5678/executions

## 🎨 **CARACTERÍSTICAS MODERNAS DEL WORKFLOW:**

### **✅ Email HTML Profesional:**
- **CSS moderno** con estilos profesionales
- **Emojis** para mejor visualización
- **Layout responsive** que se ve bien en móvil
- **Colores** profesionales y consistentes
- **Footer** con timestamp automático

### **✅ Información Completa:**
- **Título** de la reserva
- **Fecha y hora** formateadas
- **Cliente** (nombre y email)
- **Ubicación** de la reunión
- **Duración** de la reunión
- **Timestamp** de generación

### **✅ Configuración Moderna:**
- **OAuth2** para Gmail (más seguro)
- **Scopes** específicos y mínimos
- **Webhook** con headers modernos
- **Logging** detallado
- **Manejo de errores** robusto

## 📧 **EJEMPLO DE EMAIL MODERNO:**

```
Subject: 📅 Nueva reserva: Reunión de Consultoría

🎉 Nueva Reserva en Cal.com

📅 Título: Reunión de Consultoría
📅 Fecha: 2025-10-27 14:00:00
👤 Cliente: Juan Pérez
📧 Email: juan@ejemplo.com
📍 Ubicación: Virtual (Zoom)
⏰ Duración: 60 minutos

¡Que tengas una excelente reunión! 🚀

---
Este email fue generado automáticamente por tu sistema de automatización n8n.
Fecha de generación: 2025-10-26 15:30:00
```

## 🔧 **COMANDOS ÚTILES:**

```bash
# Crear workflow automáticamente
./scripts/create-modern-workflow.sh

# Ver workflows
./scripts/n8n-api.sh list-workflows

# Activar workflow
./scripts/n8n-api.sh activate-workflow WORKFLOW_ID

# Ver ejecuciones
./scripts/n8n-api.sh list-executions

# Crear backup
./scripts/manage-api-keys.sh backup
```

## ⏱️ **TIEMPO TOTAL: ~13 minutos**

1. **API Key Cal.com**: 2 minutos
2. **Credenciales n8n**: 3 minutos
3. **Crear workflow**: 5 minutos
4. **Configurar webhook**: 2 minutos
5. **Probar**: 1 minuto

## 🎉 **¡EMPEZAR AHORA!**

**Este workflow moderno incluye:**
- ✅ **Email HTML profesional**
- ✅ **Configuración OAuth2 moderna**
- ✅ **Scopes específicos y seguros**
- ✅ **Webhook con headers modernos**
- ✅ **Logging detallado**
- ✅ **Manejo de errores robusto**

**¿Quieres empezar con el PASO 1?** 🚀
