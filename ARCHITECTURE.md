# Proyecto Marti Notas – Arquitectura

Fecha de referencia: 8 de noviembre de 2025

Este documento resume la estructura técnica actual del proyecto, los módulos clave y cómo se integran los distintos componentes (Flutter, Firebase y Cloud Functions).

## 1. Capas principales

- **Presentación (lib/screens, lib/widgets, lib/theme):** Pantallas y componentes reutilizables. `HomeScreen` orquesta la navegación inicial y, desde Paso 6, permite inyectar vistas stub para pruebas. Las vistas específicas (`AdminDashboard`, `UserDashboard`, paneles de historial, filtros, etc.) consumen servicios mediante llamadas directas.
- **Servicios (lib/services/**):** Núcleo de la lógica de negocio. Se subdividen por dominio (`auth/`, `task/`, `notification_service.dart`, `search_service.dart`, `history_service.dart`, etc.). Cada servicio encapsula el acceso a Firebase y a la infraestructura de notificaciones.
- **Modelos y utilidades (lib/models/, lib/utils/):** Entidades (`TaskModel`, `UserModel`, `Comment`, enums de estado/prioridad) y helpers (`logger`, convertidores). Las constantes de colecciones viven en `lib/constants/`.
- **Funciones en la nube (functions/index.js):** Procesan eventos de tareas, envían notificaciones push y mantienen consistencia (limpieza de tokens, unicidad, flujos de revisión).

## 2. Mapa de módulos

| Módulo | Ruta | Descripción |
| --- | --- | --- |
| Modelos | `lib/models/` | Entidades y enums serializables (`TaskModel` integra comentarios e historial). |
| Servicios de autenticación | `lib/services/auth/` | `SessionManager`, `AuthRepository`, `UserRepository`, `LoginService`, `RegistrationService` y auxiliares para tokens de sesión. |
| Servicios de tareas | `lib/services/task/` + `lib/services/task_service.dart` | Gestionan asignaciones, ciclo de vida, estadísticas y panel admin. `TaskAssignmentService` ofrece overrides de prueba para Firestore/Auth (Paso 6). |
| Notificaciones | `lib/services/notification_service.dart` | Controla FCM + notificaciones locales. Desde Paso 6 expone `setTestOverrides`, `resetTestOverrides` y logging seguro para tokens. |
| Búsqueda y filtros | `lib/services/search_service.dart` | Filtros centralizados usados por UI admin y búsqueda avanzada. |
| Historial | `lib/services/history_service.dart` y `lib/screens/history/` | Cronología de eventos, panel y pantalla completa con timeline interactivo. |
| Widgets compartidos | `lib/widgets/` | Componentes reutilizables (paneles, drawer global, timeline, etc.). |
| Documentación | Raíz + `DOCS/` | Histórico de cambios por paso (Paso 1–6), guías de despliegue y apuntes de seguridad. |

## 3. Integración con Firebase

- **Firestore:** Colecciones principales `users`, `tasks`, subcolecciones para historial y adjuntos. Los servicios usan `FieldValue.serverTimestamp()`, `FieldValue.arrayUnion/arrayRemove` y `Timestamp.fromDate` para compatibilidad directa con Firestore.
- **Auth:** Gestionado por `SessionManager`, que coordina `AuthRepository` (FirebaseAuth) y `UserRepository` (Firestore). `AuthService` mantiene compatibilidad retro con API previa.
- **Messaging (FCM):** `NotificationService` administra tokens (`fcmTokens` array por usuario) y notificaciones locales. Cloud Functions envían push vía `sendToTokensWithRetries` y garantizan unicidad (`ensureUniqueFcmTokens`).
- **Storage:** Abstraído en `lib/services/storage_service.dart` y reglas definidas en `storage.rules` (revisadas en documentación previa).
- **Overrides para pruebas:**
  - `NotificationService.setTestOverrides` y `resetTestOverrides` permiten inyectar `FakeFirebaseFirestore`, `MockFirebaseMessaging` y `MockFirebaseAuth`.
  - `TaskAssignmentService.setTestOverrides`/`resetTestOverrides` habilitan streams con `FakeFirebaseFirestore` evitando dependencia del app default.

## 4. Flujo de tareas y cronología

1. **Creación/asignación:** `TaskAssignmentService` y `AdminService` crean documentos en `tasks`. Los eventos se registran mediante `HistoryService.recordEvent`.
2. **Ejecución y revisión:** `TaskLifecycleService`, `TaskReviewService` y `TaskStatsService` gobiernan cambios de estado (`pending`, `in_progress`, `pending_review`, `completed`) y métricas.
3. **Visualización:**
   - `UserDashboard` muestra próximas tareas, vencidas y estadísticas personales.
   - `AdminDashboard` ofrece visión global, panel de revisión y tarjetas de rendimiento.
   - `TaskHistoryPanel` y `history/task_history_screen.dart` renderizan la línea de tiempo.
4. **Notificaciones:** Cloud Functions disparan eventos push según cambios de estado. `NotificationService` complementa con recordatorios locales (TODO futuro: migrar a Cloud Tasks).

## 5. Notificaciones

- **Cliente (Flutter):**
  - Registra tokens al login (`registerCurrentDeviceToken`) y los limpia en logout (`removeCurrentDeviceToken`).
  - Almacena tokens en `fcmTokens` y maneja `onTokenRefresh` dinámicamente.
  - Permite pruebas unitarias inyectando dependencias y evita fallos de logging con `_formatTokenPreview`.
- **Backend (Cloud Functions):**
  - `sendTask*Notification` maneja asignación, revisión, aprobación, rechazo y reasignación.
  - `sendToTokensWithRetries` limpia tokens inválidos y reintenta envíos.
  - `ensureUniqueFcmTokens` elimina duplicados entre usuarios.
  - Documentación extendida en `NOTIFICACIONES_RESUMEN.md` y `FIREBASE_CLOUD_FUNCTIONS_SETUP.md`.

## 6. Pruebas automatizadas

- **Unit tests (Paso 6):**
  - `test/models/task_model_test.dart` valida serialización/deserialización con `Timestamp` y comentarios anidados.
  - `test/services/notification_service_test.dart` asegura registro, refresh y limpieza de tokens usando `FakeFirebaseFirestore` y mocks de `FirebaseMessaging`/`FirebaseAuth`.
  - `test/services/user_repository_test.dart` cubre normalización de nombres con diacríticos, actualizaciones y consultas.
- **Widget tests:**
  - `test/home_screen_role_test.dart` usa los nuevos builders de `HomeScreen` para verificar vistas por rol sin depender de Firebase.
  - `test/widget_test.dart` mantiene un smoke test simple sin inicializar Firebase.
- **Infraestructura de pruebas:**
  - Dependencias: `fake_cloud_firestore`, `mocktail`, `flutter_test`.
  - `analysis_options.yaml` habilita linting y null-safety.

## 7. Documentación complementaria

- `NOTIFICACIONES_RESUMEN.md`: Estado y pasos de despliegue de notificaciones push + locales (actualizado en Paso 6).
- `REFACTORING_FINAL_REPORT.md`, `REFACTORING_SUMMARY.md`: Contexto de los pasos 1–5.
- `FIREBASE_CLOUD_FUNCTIONS_SETUP.md`, `INSTRUCCIONES_DESPLIEGUE_FUNCTIONS.md`: Despliegue de funciones y configuración.
- `FIRESTORE_RULES_UPDATE.md`, `SECURITY_NOTES.md`: Cambios y lineamientos de seguridad.
- `PASOS PARA MEJORA DEL PROYECTO.md`: Hoja de ruta original con checklist por pasos.

## 8. Próximos pasos sugeridos

1. Consolidar pruebas de UI con `integration_test` o `golden tests` para pantallas críticas (Admin y User dashboards).
2. Migrar recordatorios locales a tareas programadas en backend (Cloud Tasks) manteniendo la API de `NotificationService`.
3. Añadir metadata por dispositivo (`platform`, `lastSeen`) a `fcmTokens` para diagnósticos.
4. Evaluar Provider/Riverpod para inyección explícita de servicios, facilitando testeo y modularidad (actualmente se usan métodos estáticos).

---
Este documento debe mantenerse sincronizado con los informes de pasos (Paso 1–6) y con los cambios en `NOTIFICACIONES_RESUMEN.md`. Actualiza las secciones correspondientes al agregar nuevos servicios, pruebas o flujos.
