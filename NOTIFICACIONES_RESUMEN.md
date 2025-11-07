# Resumen Consolidado de Notificaciones

Fecha: 6 de noviembre de 2025

Este documento consolida la implementación actual, los cambios aplicados en el código para mejorar notificaciones, y pasos para desplegar y probar.

## 1) Qué se implementó (resumen de cambios)

- Soporte multi-dispositivo (fcmTokens): ahora los tokens FCM se almacenan en `users/{uid}.fcmTokens` (array). Esto permite enviar push a varios dispositivos por usuario.
  - Código modificado: `lib/services/notification_service.dart` (_saveFCMToken ahora usa `FieldValue.arrayUnion([token])`, onTokenRefresh agrega tokens al array, y se añadió `removeCurrentDeviceToken()` para eliminar token al hacer logout_).
  - Cloud Functions actualizadas para leer `fcmTokens` y enviar multicast cuando corresponda: `functions/index.js`.

- Limpieza automática de tokens inválidos desde Cloud Functions: si al enviar multicast algunos tokens están desregistrados o inválidos, se eliminan del array `fcmTokens`.
  - Implementado: helper `sendToTokensWithRetries(db, payload, tokens, userId)` en `functions/index.js` realiza retries y limpia `fcmTokens` inválidos.

- Retries en envío de push: las cloud functions reintentan envíos (hasta 3 intentos) con backoff exponencial.

- `createUser` ahora inicializa el perfil con `fcmTokens: []` (en vez de `fcmToken: null`).

- No se eliminó la funcionalidad de notificaciones locales. `lib/services/notification_service.dart` sigue mostrando y programando notificaciones locales (recordatorios, vencimientos y felicitaciones).

- Tokens por sesión (login/logout): ahora el cliente registra el token al iniciar sesión y lo elimina al cerrar sesión. Implementado en `lib/services/auth/session_manager.dart` donde:
  - tras un login exitoso se llama a `NotificationService.registerCurrentDeviceToken()` y `NotificationService.setupLoginNotifications()`;
  - antes de cerrar sesión se llama a `NotificationService.removeCurrentDeviceToken()` para quitar el token del array y borrar el token localmente (llamando `FirebaseMessaging.deleteToken()`).

- **Paso 6 - pruebas automatizadas:** `NotificationService` expone `setTestOverrides`/`resetTestOverrides` para inyectar dependencias fake durante tests y se añadió un log seguro de tokens para evitar `RangeError` cuando el token es corto.

- Firestore rules: se añadió documentación/nota en `firestore.rules` explicando `fcmTokens` y recordando que sólo admins o el propio usuario acceden al documento. Las reglas existentes ya previenen que otros usuarios vean tokens ajenos.

## 2) Archivos modificados

- lib/services/notification_service.dart
  - Guardado de tokens como `fcmTokens` (array)
  - onTokenRefresh agrega al array
  - Nuevo método `removeCurrentDeviceToken()` para logout

- functions/index.js
  - Soporte a `fcmTokens` (array) y multicast
  - Helper `sendToTokensWithRetries` con retries y limpieza de tokens inválidos
  - `createUser` crea perfil con `fcmTokens: []`
  - **NUEVAS FUNCIONES (7 Nov 2025):**
    - `sendTaskReassignedNotification` - reasignación de tarea
    - `sendTaskReviewSubmittedNotification` - envío a revisión (usuario → admin)
    - `sendTaskReviewApprovedNotification` - aprobación tras revisión
    - `sendTaskReviewRejectedNotification` - rechazo en revisión

- firestore.rules
  - Añadida nota descriptiva sobre `fcmTokens` y permisos

- NOTIFICACIONES_RESUMEN.md (este archivo)
- PUSH_NOTIFICATIONS_TODO.md (marcado como consolidado)

> Nota: Algunos archivos Markdown históricos relacionados con notificaciones se marcaron como "consolidado" y su contenido quedó reducido; el contenido actualizado está en este archivo.

## 2.1) Nuevos eventos de notificación (7 Nov 2025)

### 🔄 Reasignación de tarea (`task_reassigned`)
- **Trigger:** Cambio en campo `assignedTo` de un documento de tarea
- **Destinatario:** Nuevo usuario asignado
- **Mensaje:** "{adminName} te reasignó la tarea '{title}'"
- **Datos:** taskId, type="task_reassigned", priority

### 📥 Envío a revisión (`task_review_submitted`) 
- **Trigger:** Cambio de estado a `pending_review`
- **Destinatario:** Todos los usuarios con rol `admin`
- **Mensaje:** "{userName} envió la tarea '{title}' para revisión"
- **Datos:** taskId, type="task_review_submitted"

### ✅ Aprobación de revisión (`task_review_approved`)
- **Trigger:** Cambio de `pending_review` → `completed`
- **Destinatario:** Usuario asignado a la tarea
- **Mensaje:** "Tu tarea '{title}' fue aprobada por el admin"
- **Datos:** taskId, type="task_review_approved"

### ❌ Rechazo de revisión (`task_review_rejected`)
- **Trigger:** Cambio de `pending_review` → `in_progress`
- **Destinatario:** Usuario asignado a la tarea
- **Mensaje:** "Tu tarea '{title}' fue rechazada; revisa los comentarios del admin"
- **Datos:** taskId, type="task_review_rejected"

## 3) Qué acciones debes ejecutar para desplegar y verificar

1) Desplegar Cloud Functions (desde la carpeta `functions/`):

```powershell
# 1) Ir a la carpeta de funciones
Set-Location -Path "d:\ejercicos de SENATI\marti-notas\functions"

# 2) Instalar dependencias (si es necesario)
npm install

# 3) Desplegar funciones (solo funciones)
firebase deploy --only functions
```

2) Verificar logs (tras deploy):

```powershell
# Ver logs de una función específica (por ejemplo sendTaskAssignedNotification)
firebase functions:log --only sendTaskAssignedNotification
```

3) Probar flujo en app / emulador:
- Iniciar app en dispositivo A (login con usuario X) y generar token (se guarda automáticamente).
- Iniciar app en dispositivo B (mismo usuario X) y generar token (debe añadirse al array `fcmTokens`).
- Asignar tarea desde admin a usuario X y verificar que ambos dispositivos reciben push.
- Marcar como completada / rechazada y verificar notificaciones push con razón y que los tokens inválidos se limpian si se desinstala app en un dispositivo.

## 4) Tests rápidos sugeridos

- Ver que en Firestore `users/{uid}.fcmTokens` es un array y contiene tokens.
- Asignar tarea → revisar logs de la Cloud Function y ver `send`/`sendMulticast` exitoso.
- Simular token inválido (por ejemplo enviar a token fake) y verificar que la Cloud Function lo elimina del array.
- Probar `removeCurrentDeviceToken()` al logout y ver que token se elimina.
- Probar notificaciones locales programadas: crear tarea personal y confirmar recordatorio 1 día antes y notificación al vencimiento.

## 5) Limitaciones y siguientes pasos recomendados

- Actualmente se guarda sólo el token (sin metadatos por dispositivo). Para una solución más completa se recomienda guardar objetos con `token`, `platform`, `deviceId` y `lastSeen` para gestión avanzada y políticas de expiración.

- Para grandes volúmenes de envíos (muchos tokens) considerar usar topics o un servicio de terceros (OneSignal) para mayor escalabilidad.

- Revisar `firestore.rules` si quieres que sólo los admins puedan listar usuarios (hoy la regla de lectura previene listados por usuarios no-admin).

- Añadir monitoreo (Sentry / Cloud Monitoring) en Cloud Functions para alertar sobre aumentos de errores en envíos.
- TODO: Migrar los recordatorios locales a Cloud Tasks para unificar recordatorios push programados.

## 6) Cambios de código relevantes (resumen técnico)

- `lib/services/notification_service.dart`:
  - `_saveFCMToken()` ahora usa `FieldValue.arrayUnion([token])` para `fcmTokens`.
  - **CRITICAL FIX (7 Nov 2025):** El listener `onTokenRefresh` ahora consulta `FirebaseAuth.instance.currentUser` en cada invocación en lugar de usar una variable capturada, evitando que tokens se reinserten en usuarios anteriores tras logout.
  - `removeCurrentDeviceToken()` ahora cancela el listener de token refresh para evitar reinserciones.
  - `onTokenRefresh` ahora agrega automáticamente nuevos tokens al array solo si hay usuario autenticado.
  - `setTestOverrides` y `resetTestOverrides` permiten inyectar `FakeFirebaseFirestore`/mocks durante pruebas unitarias y `_formatTokenPreview()` recorta tokens de manera segura antes de loguearlos.

- `functions/index.js`:
  - Se agregó `sendToTokensWithRetries(db, payload, tokens, userId)` que implementa retries y limpieza de tokens inválidos.
  - `sendTaskAssignedNotification`, `sendTaskRejectedNotification` y `sendTaskApprovedNotification` usan `fcmTokens` y la helper.
  - `createUser` crea perfiles con `fcmTokens: []`.
  - **NUEVAS FUNCIONES (7 Nov 2025):**
    - `sendTaskReassignedNotification` - reasignación de tarea
    - `sendTaskReviewSubmittedNotification` - envío a revisión (usuario → admin)
    - `sendTaskReviewApprovedNotification` - aprobación tras revisión
    - `sendTaskReviewRejectedNotification` - rechazo en revisión
    - `ensureUniqueFcmTokens` - garantiza tokens únicos entre usuarios (elimina duplicados automáticamente)

## 6.1) Corrección crítica del problema de tokens duplicados (7 Nov 2025)

### **Problema identificado:**
El listener `onTokenRefresh` capturaba el usuario en una variable cerrada al momento de la llamada y no se actualizaba durante logout/login. Cuando se llamaba a `deleteToken()` durante logout, Firebase generaba un nuevo token, el listener se ejecutaba y volvía a escribir ese token en el documento del usuario anterior.

### **Solución implementada:**
1. **Consulta dinámica del usuario:** El listener ahora llama a `FirebaseAuth.instance.currentUser` en cada ejecución.
2. **Validación de sesión:** Si no hay usuario autenticado, el callback no guarda nada.
3. **Cancelación del listener:** `removeCurrentDeviceToken()` cancela la suscripción antes de eliminar el token.
4. **Cloud Function de unicidad:** `ensureUniqueFcmTokens` elimina automáticamente tokens duplicados entre usuarios.

### **Flujo corregido:**
- Login de "yuri" → se añade su token a `fcmTokens`
- Logout de "yuri" → se cancela listener, elimina token y lo invalida localmente
- Login de "admin" → nuevo listener, nuevo token solo se añade al documento de admin
- `ensureUniqueFcmTokens` limpia cualquier token duplicado automáticamente

## 7) Cobertura de pruebas automatizadas (actualizado Paso 6)

- `test/services/notification_service_test.dart` valida registro de token, escucha de `onTokenRefresh` y borrado de tokens usando `FakeFirebaseFirestore` + mocks inyectados vía `setTestOverrides`.
- `test/models/task_model_test.dart` usa `Timestamp.fromDate` para asegurar que la serialización/deserialización maneja tipos Firestore reales (incluye comentarios incrustados).
- `test/services/user_repository_test.dart` confirma normalización de nombres con acentos, actualizaciones y consultas; ayuda a verificar `_stripDiacritics` y la conversión a `FieldValue.serverTimestamp()`.
- `test/widget_test.dart` mantiene una prueba rápida de interacción UI reemplazando dependencias Firebase por un `ValueNotifier`, acelerando la suite.

## 8) Nota sobre eliminación de archivos .md

Por seguridad y rastreabilidad no eliminé físicamente los archivos existentes; en su lugar los marqué como "consolidado" (su contenido reducido) y centralicé la documentación en este archivo `NOTIFICACIONES_RESUMEN.md`.

Si prefieres que elimine físicamente los archivos antiguos, puedo hacerlo (confirma y lo ejecuto).

---

Si quieres, hago ahora alguno de estos pasos automáticos:
- Preparar un PR con estos cambios.
- Ejecutar comandos de despliegue (si me autorizas a correr npm/firebase CLI aquí).
- Cambiar `firestore.rules` para negar lectura de `users` fuera de admins (más restrictivo).

Dime qué prefieres y lo hago a continuación.
