# DOCS: Archivos por rol y flujo (marti_notas)

Este documento amplía el `README.md` con un flujo básico (login → dashboard) y una lista más detallada de archivos por rol, además de recomendaciones de seguridad y comprobaciones rápidas.

Fecha: 29/10/2025

---

## 1) Flujo básico de la aplicación

1. Usuario inicia la aplicación.
2. `lib/main.dart` inicializa Firebase y notificaciones y muestra `HomeScreen` o `LoginScreen` según el estado de autenticación.
3. `lib/screens/home_screen.dart` recibe un `UserModel` y elige:
   - admin → `HomeAdminView` (`lib/screens/home/home_admin_view.dart`) — dashboard admin
   - normal → `HomeUserView` (`lib/screens/home/home_user_view.dart`) — dashboard usuario
4. Desde cada dashboard se navega a pantallas funcionales (gestión de usuarios, asignación de tareas, tareas personales, notas, etc.).

Nota: Las pantallas admin deben ir acompañadas de validaciones server-side (reglas Firestore) para evitar accesos no autorizados desde clientes.

---

## 2) Archivos principales por rol (detallado)

### A — Admin (pantallas y utilidades)

- `lib/screens/home/home_admin_view.dart`
  - Dashboard principal admin. Muestra tiles: Gestión de Usuarios, Asignar Tareas, Tareas por Usuario, Estadísticas Avanzadas.

- `lib/screens/admin_users_screen.dart`
  - Pantalla CRUD de usuarios. Usa componentes en `lib/screens/admin_users/`:
    - `admin_users_header.dart`: header con acciones
    - `admin_users_stats.dart`: panel de estadísticas de usuarios
    - `admin_users_search_bar.dart`: búsqueda y filtros
    - `admin_users_list.dart`: listado y acciones por usuario
    - `create_user_dialog.dart`, `edit_user_dialog.dart`, `delete_user_dialog.dart`: diálogos CRUD
    - `admin_users_fab.dart`: FAB para crear usuarios

- `lib/screens/admin_task_assign_screen.dart` + `lib/screens/admin_task_assign/*`
  - Pantalla para asignar y gestionar tareas creadas por admins. Componentes: header, stats, lista, búsqueda, FAB y diálogo para asignar.

- `lib/screens/admin_tasks_by_user_screen.dart`
  - Reporte/agrupado de tareas por usuario: muestra conteos (pendientes, en progreso, completadas) y permite confirmación/rechazo. Importante para supervisión.

- `lib/screens/simple_task_assign_screen.dart` + `lib/screens/simple_task_assign/*`
  - Variante o UI alternativa para asignación de tareas (refactorizada en componentes menores).

- `lib/services/admin_service.dart`
  - Lógica de alto nivel para operaciones admin (crear/obtener/actualizar/eliminar usuarios, asignar tareas, estadísticas). Observación: contiene validaciones de rol en el cliente; reforzar con reglas de servidor.

Widgets/estilos orientados a Admin:
- `lib/widgets/premium_components.dart` — gradientes/estilos admin
- `lib/widgets/status_badges.dart` — `AdminBadge`, `UserRoleBadge`

### B — Usuario (pantallas y utilidades)

- `lib/screens/home/home_user_view.dart`
  - Dashboard usuario: saludo y accesos a `Mis Tareas` y `Mis Notas`.

- `lib/screens/tasks_screen.dart` + `lib/screens/tasks/*`
  - Pantalla principal de tareas personales (tabs: pendiente, progreso, completadas). Componentes: `task_header`, `task_tab_bar`, `task_list`, `task_modal`.

- `lib/screens/notes_screen.dart`
  - Gestión de notas personales. CRUD sobre `notes` filtradas por `createdBy == user.uid`.

### C — Compartido / Servicios / Infraestructura

- `lib/screens/home_screen.dart` — Selector de dashboard según `UserModel.isAdmin`.
- `lib/models/user_model.dart` — Modelo de usuario con `role` y getter `isAdmin`.
- `lib/widgets/global_menu_drawer.dart` — Drawer global; añade elementos admin cuando `user.isAdmin`.
- `lib/services/auth_service.dart` — Autenticación y helper `currentUser`.
- `lib/services/task_service.dart` — Operaciones sobre tareas.
- `lib/services/note_service.dart` — Operaciones sobre notas.
- `lib/services/notification_service.dart` — Inicialización y envío de notificaciones.

Otros: `lib/theme/*`, `lib/widgets/*` (componentes de UI compartidos).

---

## 3) Recomendaciones y comprobaciones rápidas (seguridad y QA)

1. Reglas Firestore (críticas): Verifica `firestore.rules` para asegurar que solo los admins pueden:
   - Leer/escribir en `/users` (o al menos eliminar/actualizar otros usuarios).
   - Asignar tareas globales o ejecutar funciones admin.

   Ejemplo (simplificado):
   - `match /users/{userId} { allow read: if request.auth.uid == userId || isAdmin(request.auth.uid); allow write: if isAdmin(request.auth.uid); }`

2. Tests: Añadí un test widget (`test/home_screen_role_test.dart`) que verifica que `HomeScreen` renderiza Admin/User view. Ejecutar `flutter test` y ajustar si aparecen fallos (textos localizados o pequeños cambios UI pueden romper los asserts).

3. Guards en pantallas: Implementé guards UI mínimos que devuelven `UnauthorizedScreen` si el usuario no es admin. Esto evita accesos desde la UI, pero no reemplaza `firestore.rules`.

4. Dependencias: Considera actualizar paquetes indicados por `flutter pub outdated`. Algunas versiones actuales son compatibles con Dart 3; testea antes de actualizar masivamente.

---

## 4) Cómo probar localmente (comandos)

```powershell
cd 'C:\Users\SOPORTE\Documents\yutiko\marti_notas'
flutter pub get
flutter analyze
flutter test
```

Si ves mensajes sobre symlinks en Windows: activa Developer Mode o ejecuta PowerShell como Administrador.

---

## 5) Próximos pasos sugeridos

- Revisar `firestore.rules` y aplicar restricciones por rol.
- Añadir tests adicionales: permisos UI, servicios admin y reglas Firestore (si usas emulador de Firebase).
- Crear un pequeño script CI (GitHub Actions) que haga `flutter analyze` y `flutter test` en cada PR.

---

Si quieres, puedo:
- Generar la propuesta concreta para `firestore.rules` basada en la estructura actual.
- Añadir el archivo `DOCS/FLOW.plantuml` con diagrama del flujo (login → home → pantallas) para documentación visual.

Indica cuál prefieres y lo añado.
