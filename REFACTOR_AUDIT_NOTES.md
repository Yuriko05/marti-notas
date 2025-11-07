# Auditoría Inicial del Proyecto (Paso 1)

_Fecha: 7 nov 2025_

Objetivo: mapear las responsabilidades actuales en `lib/`, `functions/` y `DOCS/` para orientar la refactorización sin romper la funcionalidad existente.

---

## 1. Carpeta `lib/`

### 1.1 Archivos raíz
- **main.dart** – Bootstrap de la app: inicializa Firebase, registra `FirebaseMessaging.onBackgroundMessage`, llama a `NotificationService.initialize()` y monta `MyApp` con `MultiProvider`. _(Posible extracción: mover la inicialización a un módulo `app_bootstrap.dart`.)_
- **firebase_options.dart** – Configuración generada por FlutterFire (no modificar).
- **debug_helper.dart** – Utilidades de diagnóstico (generar correos fake, crear usuarios, listar usuarios). Mezcla funciones de Auth + Firestore; podríamos dividir en utilidades de autenticación vs herramientas Firestore.

### 1.2 Modelos (`lib/models`)
- **task_model.dart** – Modelo central de tareas (estado, prioridad, adjuntos, timestamps, helpers `isPending`, `isCompleted`, etc.). Usa `String` para estado/prioridad; convertir a enums y actualizar serialización.
- **user_model.dart** – Representa usuarios (roles, tokens FCM, configuraciones). Candidato a usar enums de roles y constantes de colecciones.
- **note_model.dart** – Modelo de notas personales.
- **history_event.dart** – Evento de historial (`action`, `actor`, `payload`). Base para la nueva pantalla timeline.

### 1.3 Providers (`lib/providers`)
- **auth_provider.dart** – Gestiona estado de autenticación, roles y usuario actual. Depende de `AuthService` y `SessionManager`.
- **task_provider.dart** – Streams de tareas, agrupaciones por usuario, estadísticas y filtros. Necesita delegar filtros a `SearchService` y estadísticas a `StatsService`.
- **note_provider.dart** – CRUD de notas vía `NoteService`.

### 1.4 Pantallas (`lib/screens`)
- **home_screen.dart** – Shell principal; determina la vista según rol.
- **login_screen.dart** – Formulario de acceso (usa `AuthProvider`).
- **notes_screen.dart** – Lista y edición básica de notas.
- **unauthorized_screen.dart** – Mensaje de acceso restringido.
- **admin_tasks_by_user_screen.dart** – Agrupa tareas por usuario (usa `TaskProvider.groupTasksByUser`).
- **admin_users_screen.dart** – Entrada al módulo de administración de usuarios.
- **home/**
  - `admin_dashboard.dart`, `home_admin_view.dart` – Widgets dashboard para admin (muestran stats, acciones rápidas).
  - `home_user_view.dart`, `user_dashboard.dart` – Dashboard para usuarios finales.
  - `home_screen_app_bar.dart`, `home_screen_fab.dart`, `home_stats_dialog.dart` – Componentes reutilizables de la pantalla principal.
- **tasks/**
  - `tasks_screen.dart` – Pantalla principal de tareas (lista, filtros, stats, acciones a `TaskService`).
  - `task_header.dart`, `task_tab_bar.dart`, `user_task_search_bar.dart`, `user_task_stats.dart`, `task_modal.dart`, `task_list.dart` – Widgets asociados; deberán integrarse con `SearchService` y timeline.
- **admin_users/**
  - `admin_users_header.dart`, `admin_users_list.dart`, `admin_users_search_bar.dart`, `admin_users_stats.dart`, `admin_users_fab.dart` – Componentes UI.
  - `create_user_dialog.dart`, `edit_user_dialog.dart`, `delete_user_dialog.dart` – Modales para gestión de usuarios (`AdminService`, `UserService`).
- **simple_task_assign_screen.dart** – Pantalla de asignación rápida.
- **simple_task_assign/**
  - `bulk_action_handlers.dart`, `simple_task_header.dart`, `simple_task_list.dart`, `simple_task_search_bar.dart`, `simple_task_stats.dart`, `task_dialogs.dart` – Componentes para asignación masiva; lógica pasará a `task_assignment_service.dart`.

### 1.5 Servicios (`lib/services`)
- **task_service.dart** (≈750 líneas) – Monolítico con múltiples dominios:
  - *Ciclo de vida*: marcar leída, completar, reabrir, confirmar, rechazar, revertir.
  - *Review*: enviar a revisión, aprobar/rechazar revisión, comentarios.
  - *Asignación*: crear tareas, asignar, reasignar, quick assign, adjuntos iniciales.
  - *Estadísticas*: agrupaciones por usuario, conteos dashboard, limpieza periódica.
  - *Recordatorios*: programación de notificaciones locales.
  - *Integraciones*: `HistoryService`, `NotificationService`.
  - **Refactor**: dividir en `task_lifecycle_service.dart`, `task_assignment_service.dart`, `review_service.dart`, `stats_service.dart` y dejar `TaskService` como fachada temporal.
- **admin_service.dart** – Herramientas de administración (creación masiva de usuarios, reasignaciones rápidas). Debe coordinarse con `task_assignment_service.dart` y `user_service.dart`.
- **note_service.dart** – CRUD de notas (ya aislado).
- **notification_service.dart** – Manejo de FCM + notificaciones locales; registra/elimina tokens por sesión.
- **server_notification_service.dart** – Envío directo de FCM desde el cliente (obsoleto); documentar como deprecado.
- **history_service.dart** – Escritura de eventos en `task_history` y `streamEvents()`.
- **storage_service.dart** – Subida/descarga de archivos a Firebase Storage.
- **task_cleanup_service.dart** – Limpieza periódica de tareas (necesita rol admin).
- **cloud_functions_service.dart** – Invoca funciones HTTPS (`createUser`, etc.); usar constantes de colecciones.
- **user_service.dart** – Operaciones con documentos de usuario (roles, últimos accesos, tokens).
- **services/auth/**
  - `auth_service.dart` – Fachada pública para login/registro/logout.
  - `auth_repository.dart` – Acceso bajo nivel a `FirebaseAuth`.
  - `session_manager.dart` – Orquesta login/logout, registra tokens (mover lógica a `LoginService`, `RegistrationService`, `SessionTokenManager`).
  - `user_repository.dart` – Operaciones con colecciones de usuarios.

### 1.6 Tema (`lib/theme`)
- **app_theme.dart** – Tema claro/oscuro, estilos globales.

### 1.7 Utilidades (`lib/utils`)
- **logger.dart** – Wrapper de logging (`AppLogger`).
- **ui_helper.dart** – Helpers de UI (snackbars, diálogos, formatos).
- **validators.dart** – Validaciones de formularios.

### 1.8 Widgets reutilizables (`lib/widgets`)
- **app_button.dart** – Botón estilizado.
- **bulk_actions_bar.dart** – Barra de acciones masivas.
- **enhanced_task_assign_dialog.dart** – Modal de asignación avanzada.
- **global_menu_drawer.dart** – Drawer lateral principal.
- **loading_widgets.dart** – Indicadores de progreso.
- **premium_components.dart** – Componentes adicionales (badges, banners).
- **status_badges.dart** – Chips de estado (usar enums nuevos).
- **task_card.dart** – Card principal con acciones de tarea.
- **task_completion_dialog.dart**, **task_review_dialog.dart**, **task_preview_dialog.dart** – Modales del flujo de tareas.
- **task_history_panel.dart** – Panel lateral que usa `HistoryService` (base para la futura pantalla timeline).

---

## 2. Carpeta `functions/`

- **index.js** (≈700 líneas) – Contiene toda la lógica de Cloud Functions:
  - Helper `sendToTokensWithRetries` (reintentos + limpieza de tokens inválidos).
  - Triggers:
    - `sendTaskAssignedNotification`
    - `sendTaskRejectedNotification`
    - `sendTaskApprovedNotification`
    - `sendTaskReassignedNotification`
    - `sendTaskReviewSubmittedNotification`
    - `sendTaskReviewApprovedNotification`
    - `sendTaskReviewRejectedNotification`
    - `ensureUniqueFcmTokens`
  - Callable: `createUser`.
  - **Refactor:** mover cada trigger a `functions/src/notifications/*.js`, funciones de usuario a `functions/src/users/*.js`, dejar `helpers.js` para utilidades y reexportar desde `index.js`.
- **package.json / .eslintrc.js** – Mantener scripts de lint (`eslint . || true`) y actualizarlos tras modularizar.

---

## 3. Carpeta `DOCS/`

- **NOTIFICACIONES_RESUMEN.md** – Documenta el flujo actual de notificaciones push y tokens (debe actualizarse con nuevas rutas y módulos).
- **README_FIREBASE_RECONFIG.md** – Guía para reconfigurar Firebase.
- **STORAGE_RULES_DEPLOYMENT.md** – Pasos para desplegar reglas de Storage.
- **TESTING_STORAGE_ATTACHMENTS.md** – Guía de pruebas para adjuntos.
- **FILES_BY_ROLE.md** – Mapa de archivos por rol/responsabilidad.
- Otros documentos en la raíz del repositorio (ANALISIS_*, BUG_*, etc.) contienen histórico; evaluar consolidación posterior en `ARCHITECTURE.md`.

---

## 4. Conclusiones y oportunidades

1. **Enums & constantes** – Crear `lib/models/task_status.dart` (enums `TaskStatus`, `TaskPriority`) y `lib/constants/collections.dart` para nombres de colecciones.
2. **Servicios modulares** – Dividir `task_service.dart` y `session_manager.dart` siguiendo el plan propuesto, reexportando desde las clases originales para mantener compatibilidad.
3. **Cloud Functions modulares** – Estructurar `functions/src/**`, mantener helper compartido, documentar en `NOTIFICACIONES_RESUMEN.md`.
4. **Búsqueda/estadísticas** – Crear `search_service.dart` y `stats_service.dart` para reutilización en UI admin y usuario.
5. **Timeline y comentarios** – Extender `HistoryService` y `TaskModel` con `Comment`, dejando TODOs para implementar chat por tarea.
6. **Migración Cloud Tasks** – Añadir TODOs donde se programan recordatorios locales para futura migración a Cloud Tasks.
7. **Pruebas unitarias** – Crear carpeta `test/` con suites para enums `TaskModel`, registro/elim tokens FCM (`NotificationService`) y operaciones básicas de `UserRepository`.
8. **Documentación** – Añadir `ARCHITECTURE.md` describiendo la nueva organización. Actualizar `NOTIFICACIONES_RESUMEN.md` cuando las funciones se reubiquen.

---

_Este documento deja constancia del paso 1 (auditoría). Servirá como guía para los pasos siguientes del refactor._