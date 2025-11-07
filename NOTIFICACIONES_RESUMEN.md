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

- firestore.rules
  - Añadida nota descriptiva sobre `fcmTokens` y permisos

- NOTIFICACIONES_RESUMEN.md (este archivo)
- PUSH_NOTIFICATIONS_TODO.md (marcado como consolidado)

> Nota: Algunos archivos Markdown históricos relacionados con notificaciones se marcaron como "consolidado" y su contenido quedó reducido; el contenido actualizado está en este archivo.

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

## 6) Cambios de código relevantes (resumen técnico)

- `lib/services/notification_service.dart`:
  - `_saveFCMToken()` ahora usa `FieldValue.arrayUnion([token])` para `fcmTokens`.
  - `removeCurrentDeviceToken()` añadido (usa `FieldValue.arrayRemove([token])`).
  - `onTokenRefresh` ahora agrega automáticamente nuevos tokens al array.

- `functions/index.js`:
  - Se agregó `sendToTokensWithRetries(db, payload, tokens, userId)` que implementa retries y limpieza de tokens inválidos.
  - `sendTaskAssignedNotification`, `sendTaskRejectedNotification` y `sendTaskApprovedNotification` usan `fcmTokens` y la helper.
  - `createUser` crea perfiles con `fcmTokens: []`.

## 7) Nota sobre eliminación de archivos .md

Por seguridad y rastreabilidad no eliminé físicamente los archivos existentes; en su lugar los marqué como "consolidado" (su contenido reducido) y centralicé la documentación en este archivo `NOTIFICACIONES_RESUMEN.md`.

Si prefieres que elimine físicamente los archivos antiguos, puedo hacerlo (confirma y lo ejecuto).

---

Si quieres, hago ahora alguno de estos pasos automáticos:
- Preparar un PR con estos cambios.
- Ejecutar comandos de despliegue (si me autorizas a correr npm/firebase CLI aquí).
- Cambiar `firestore.rules` para negar lectura de `users` fuera de admins (más restrictivo).

Dime qué prefieres y lo hago a continuación.
