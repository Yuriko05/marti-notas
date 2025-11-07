### Contexto y objetivo
Estamos refactorizando un proyecto Flutter + Firebase. El código actual tiene archivos enormes con múltiples responsabilidades (por ejemplo, `TaskService` combina operaciones de lectura, confirmación, rechazo, reasignación y estadísticas:contentReference[oaicite:0]{index=0}; `functions/index.js` agrupa todas las Cloud Functions en un solo archivo:contentReference[oaicite:1]{index=1}). La meta es modularizar y reorganizar el proyecto sin romper la funcionalidad actual (gestión de usuarios, tareas, notas y notificaciones push FCM).

### Paso 1: Auditoría del proyecto
Antes de modificar nada, recorre todos los archivos en `lib/`, `functions/` y `DOCS/`. Para cada archivo:
- Resume brevemente su propósito y las principales funciones que contiene.
- Identifica secciones o responsabilidades que puedan extraerse a módulos independientes.  
- Por ejemplo, en `lib/services/task_service.dart` anota que “marca tareas como leídas”, “admin confirma/rechaza tareas”, “aprueba o rechaza revisiones”, “agrupa tareas por usuario”, etc. Estas son pistas para crear servicios separados.

Escribe esta auditoría como comentarios en el propio prompt o en un archivo temporal para guiar el refactor.

### Paso 2: Definir enumeraciones y constantes
Crea enumeraciones para estados de tarea y prioridad en un archivo nuevo, por ejemplo `lib/models/task_status.dart`:
```dart
enum TaskStatus { pending, inProgress, pendingReview, completed, confirmed, rejected }
enum TaskPriority { low, medium, high }
Reemplaza las comparaciones de strings en todo el código por estas enums y actualiza la serialización en TaskModel (status y priority) para que guarde y lea el name del enum.

Crea también una clase de constantes para las colecciones de Firestore en lib/constants/collections.dart:

dart
Copiar código
class Collections {
  static const users = 'users';
  static const tasks = 'tasks';
  static const taskHistory = 'task_history';
  // añade las que falten
}
Utiliza estas constantes en todas las llamadas a Firestore y en las Cloud Functions.

### Paso 3: Modularizar servicios en Flutter

Divide el fichero task_service.dart en varios servicios según su responsabilidad:

task_lifecycle_service.dart → iniciar, completar, revertir, confirmar y rechazar tareas.

task_assignment_service.dart → crear, asignar y reasignar tareas.

review_service.dart → enviar tareas a revisión, aprobar revisiones, rechazar revisiones.

stats_service.dart → agrupar tareas por usuario, estadísticas de confirmación.

Haz lo mismo con SessionManager: extrae la lógica de login, registro y gestión de tokens en servicios dedicados (login_service.dart, registration_service.dart, etc.). Conserva la API pública de AuthService reexportando las operaciones para no romper dependencias externas.

### Paso 4: Reorganizar las Cloud Functions

Crea una carpeta functions/src y mueve cada Cloud Function a un archivo independiente:

notifications/assigned.js, notifications/reassigned.js, notifications/review-submitted.js, etc., cada uno exporta una función onDocumentCreated o onDocumentUpdated.

users/create.js, users/removeUniqueToken.js, etc.

Importa y reexporta todas estas funciones desde functions/index.js para mantener la compatibilidad con firebase deploy.

Mantén el helper sendToTokensWithRetries tal cual y la función ensureUniqueFcmTokens que elimina tokens duplicados, pero colócala en un archivo notifications/ensureUniqueFcmTokens.js y documenta su uso.

### Paso 5: Mejoras para la experiencia de admin y usuario

Añade un servicio search_service.dart con métodos para filtrar tareas por fecha, prioridad, estado o texto. Luego, en la UI (Provider o pantalla de tareas), utiliza estos filtros para que el admin pueda buscar fácilmente.

Crea una pantalla de historial de tareas que consuma HistoryService.streamEvents() y muestre un timeline.

Diseña un esqueleto para un chat de comentarios por tarea: agrega en TaskModel un campo opcional List<Comment> y crea el modelo Comment. Añade métodos en TaskService para enviar y recibir comentarios. Puedes dejar los métodos como TODO y documentarlo.

Para futuras migraciones a Cloud Tasks (recordatorios push), inserta comentarios TODO: en la documentación y en el código donde se programan recordatorios locales.

### Paso 6: Tests y documentación

Crea una carpeta test/ e incluye al menos pruebas unitarias para la serialización de TaskModel con los nuevos enums, para el registro y eliminación de tokens FCM en NotificationService y para operaciones básicas de UserRepository.

Añade un archivo ARCHITECTURE.md donde expliques la nueva estructura: cómo se dividen los servicios, dónde se encuentran las Cloud Functions, cómo funcionan los enums y las constantes.

Actualiza NOTIFICACIONES_RESUMEN.md describiendo las nuevas ubicaciones de las funciones y recordando que fcmTokens sigue siendo el campo válido.

Requisitos imprescindibles
No rompas la funcionalidad actual: después del refactor la app debe compilar y comportarse igual (misma API pública de AuthService, AdminService, TaskService —aunque estén divididos— y mismas rutas en Cloud Functions).

Preserva la gestión de tokens FCM por sesión y la función de limpieza de tokens duplicados.

Mantén los permisos y reglas de Firestore compatibles con los cambios (no cambies nombres de colecciones ni estructuras de documentos sin adaptadores).

Usa Null Safety y buenas prácticas de Dart. Marca claramente las partes que dejes como TODO para implementar más adelante.

Una vez completados todos los pasos, genera un pull request con una descripción detallada de los cambios y un checklist de pruebas manuales (crear tarea, asignar, cerrar sesión y reingresar, enviar a revisión, reasignar, etc.) para verificar que todo funciona.





Este prompt ofrece al modelo un plan claro: primero auditar el proyecto, luego modularizar y mejorar la arquitectura con ejemplos concretos de enums, constantes y división de servicios. También incluye instrucciones para reorganizar las Cloud Functions y añadir mejoras de UX sin romper la funcionalidad existente. Ajusta o recorta secciones según tus necesidades, pero mantén siempre los *requisitos imprescindibles* para garantizar que la refactorización no interrumpa el uso actual de la aplicación.

