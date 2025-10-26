# ===========================================
# CONFIGURACIÓN MANUAL DE CAL.COM TRIGGER
# ===========================================

## 🚀 **CAL.COM ES EL MÁS RÁPIDO DE PROBAR**

### ✅ **Lo que ya tienes:**
- ✅ Cuenta de Cal.com
- ✅ n8n funcionando
- ✅ API key configurada

### 📋 **Lo que necesitas hacer:**

#### **PASO 1: Obtener API Key de Cal.com**
1. Ve a: https://cal.com/settings/developer
2. Click en: "Create API Key"
3. Dale un nombre: "n8n-automatizaciones"
4. **COPIA** la API key que aparece

#### **PASO 2: Crear Credenciales en n8n**
1. Ve a: http://localhost:5678
2. Login con: admin / admin123
3. Ve a: **Credentials** (en el menú lateral)
4. Click en: **"Create Credential"**
5. Busca: **"Cal.com API"**
6. Configura:
   - **Name**: Cal.com API
   - **API Key**: [Pega tu API key de Cal.com]
7. Click en: **"Save"**

#### **PASO 3: Crear Workflow con Cal.com Trigger**
1. Ve a: **Workflows** (en el menú lateral)
2. Click en: **"Create Workflow"**
3. Busca: **"Cal.com Trigger"** en los nodos
4. Arrastra el nodo **Cal.com Trigger** al canvas
5. Configura el nodo:
   - **Credential**: Selecciona "Cal.com API"
   - **Event**: Selecciona "Booking Created"
6. Agrega un nodo **"Log"** después del trigger
7. Conecta los nodos
8. Click en: **"Save"**

#### **PASO 4: Configurar Webhook en Cal.com**
1. Ve a: https://cal.com/settings/webhooks
2. Click en: **"Create Webhook"**
3. Configura:
   - **URL**: `http://localhost:5678/webhook/[webhook-id-del-nodo]`
   - **Events**: Selecciona "Booking Created"
4. Click en: **"Save"**

#### **PASO 5: Activar y Probar**
1. En n8n, click en: **"Activate"** en tu workflow
2. Ve a tu Cal.com y haz una reserva de prueba
3. Ve a n8n > **Executions** para ver si se ejecutó

## 🎯 **EVENTOS DISPONIBLES:**

### **Booking Created** ⭐ (Más fácil de probar)
- Se dispara cuando alguien hace una reserva
- Datos disponibles: título, fecha, hora, email del cliente

### **Booking Cancelled**
- Se dispara cuando se cancela una reserva
- Útil para liberar recursos automáticamente

### **Booking Rescheduled**
- Se dispara cuando se reprograma una reserva
- Perfecto para actualizar otros sistemas

### **Meeting Ended**
- Se dispara cuando termina una reunión
- Ideal para enviar follow-ups automáticos

## 🚀 **EJEMPLOS DE AUTOMATIZACIÓN:**

### **1. Notificación por Email**
```
Cal.com Trigger → Gmail → Enviar email de confirmación
```

### **2. Actualizar Google Sheets**
```
Cal.com Trigger → Google Sheets → Agregar nueva fila con datos de la reserva
```

### **3. Enviar WhatsApp**
```
Cal.com Trigger → WhatsApp → Enviar mensaje de confirmación
```

### **4. Crear Tarea en Notion**
```
Cal.com Trigger → Notion → Crear página con detalles de la reunión
```

## 🔧 **COMANDOS ÚTILES:**

```bash
# Ver workflows creados
./scripts/n8n-api.sh list-workflows

# Activar workflow
./scripts/n8n-api.sh activate-workflow WORKFLOW_ID

# Ver ejecuciones
./scripts/n8n-api.sh list-executions

# Crear backup
./scripts/manage-api-keys.sh backup
```

## ⚡ **¿POR QUÉ CAL.COM ES EL MÁS RÁPIDO?**

1. **Visual**: Ves inmediatamente cuando se dispara
2. **Real**: Usas tu cuenta real de Cal.com
3. **Inmediato**: Se ejecuta en segundos
4. **Útil**: Puedes usar las notificaciones en tu día a día
5. **Escalable**: Fácil agregar más automatizaciones

## 🎉 **¡EMPEZAR AHORA!**

1. **Obtén tu API key** de Cal.com (2 minutos)
2. **Crea las credenciales** en n8n (1 minuto)
3. **Crea el workflow** (3 minutos)
4. **Configura el webhook** (2 minutos)
5. **¡Prueba haciendo una reserva!** (1 minuto)

**Total: ~9 minutos para tener tu primera automatización funcionando** 🚀
