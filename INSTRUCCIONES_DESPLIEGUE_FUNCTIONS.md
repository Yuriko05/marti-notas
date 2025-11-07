# 🚀 Despliegue de Cloud Functions - Instrucciones

## Estado Actual

✅ **Firebase Functions inicializado correctamente**
✅ **Código JavaScript creado** (3 funciones)
✅ **APIs habilitadas automáticamente**
⏳ **Esperando permisos de Eventarc** (2-5 minutos)

## Funciones Creadas

1. **sendTaskAssignedNotification** - Trigger cuando se crea tarea
2. **sendTaskRejectedNotification** - Trigger cuando se rechaza tarea
3. **sendTaskApprovedNotification** - Trigger cuando se aprueba tarea

## Próximos Pasos

### 1. Esperar 2-5 minutos

Firebase está configurando automáticamente los permisos del Eventarc Service Agent.

### 2. Reintentar el despliegue

```powershell
firebase deploy --only "functions"
```

### 3. Verificar el despliegue

```powershell
firebase functions:log
```

## Si Sigue Fallando

### Opción A: Esperar más tiempo

A veces puede tardar hasta 10 minutos. Intenta de nuevo.

### Opción B: Verificar permisos en Firebase Console

1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto: **App-Notas**
3. Ve a **Functions** en el menú lateral
4. Verifica que no haya errores de permisos

### Opción C: Habilitar APIs manualmente

1. Ve a: https://console.cloud.google.com/
2. Selecciona proyecto: **app-notas-3d555**
3. Ve a **APIs & Services > Library**
4. Busca y habilita:
   - Eventarc API
   - Cloud Run API
   - Cloud Build API

## Comando Correcto

En PowerShell, SIEMPRE usa comillas para el parámetro:

```powershell
firebase deploy --only "functions"
```

❌ **INCORRECTO:** `firebase deploy --only fun` (abreviatura no funciona)
❌ **INCORRECTO:** `firebase deploy --only functions` (sin comillas en PowerShell puede fallar)
✅ **CORRECTO:** `firebase deploy --only "functions"`

## Verificar Estado

Para ver si las functions se desplegaron:

```powershell
firebase functions:list
```

Para ver los logs en tiempo real:

```powershell
firebase functions:log --only sendTaskAssignedNotification
```

## Testing Después del Despliegue

Una vez desplegadas las functions:

1. **Crear una tarea desde el admin** en la app
2. **Verificar logs:**
   ```powershell
   firebase functions:log
   ```
3. **Buscar en los logs:**
   - "Nueva tarea creada"
   - "Notificación enviada exitosamente"
   - O errores si algo falló

## Notas Importantes

- Las functions v2 usan **Eventarc** en lugar de triggers directos
- Primera vez usando functions v2: tarda más en configurarse
- Una vez configurado, futuros despliegues serán rápidos
- Las functions se ejecutan en **us-central1** por defecto

## Solución de Problemas

### Error: "Permission denied while using the Eventarc Service Agent"

**Solución:** Esperar 2-5 minutos y reintentar.

### Error: "Missing required API"

**Solución:** Firebase lo habilita automáticamente. Espera y reintenta.

### Error: "ENOENT spawn npm"

**Solución:** Usa PowerShell correctamente:
```powershell
cd "D:\ejercicos de SENATI\marti-notas"
firebase deploy --only "functions"
```

## Próximos Pasos Después del Despliegue

1. ✅ Probar creando una tarea como admin
2. ✅ Verificar que el usuario reciba la notificación push
3. ✅ Probar rechazando una tarea
4. ✅ Probar aprobando una tarea
5. ✅ Verificar logs con `firebase functions:log`
