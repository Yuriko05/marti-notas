# Consolidación de Componentes - TaskCard Refactor

**Fecha:** 31 de octubre de 2025  
**Tipo:** Refactorización arquitectónica (Opción B)  
**Estado:** ✅ Completado

## Resumen Ejecutivo

Se consolidaron las listas de tareas duplicadas (`AdminTaskList` y `SimpleTaskList`) extrayendo un componente reutilizable `TaskCard`. Se integraron acciones masivas (bulk actions) en ambas pantallas con control de permisos.

## Cambios Realizados

### 1. Componente Nuevo: `TaskCard`
**Archivo:** `lib/widgets/task_card.dart`

- **Propósito:** Widget reutilizable para renderizar tarjetas de tareas
- **Props principales:**
  - `task`: TaskModel (requerido)
  - `user`: UserModel (opcional)
  - `isSelected`: bool (para vista detallada)
  - `isChecked`: bool (para selección múltiple)
  - `onToggleSelect`: callback para checkbox
  - `onTap`, `onPreview`, `onEdit`, `onDelete`: callbacks de acción
  - `showActions`: bool (mostrar menú contextual)

- **Funcionalidad:**
  - Renderiza título, estado, descripción, vencimiento
  - Badge de leído/no leído (estilo WhatsApp)
  - Badge de confirmación (esperando/confirmada/rechazada)
  - Checkbox opcional para selección múltiple
  - Botón de preview
  - Menú de edición/eliminación opcional
  - Soporte para tareas vencidas (border rojo + badge)

### 2. Archivos Modificados

#### `lib/screens/simple_task_assign/simple_task_list.dart`
- **Antes:** Renderizado de tarjeta inline (~200 líneas de UI duplicada)
- **Después:** Usa `TaskCard` (~100 líneas, lógica de filtrado limpia)
- **Nuevas props:**
  - `selectedTaskIds`: Set<String>
  - `onTaskToggleSelection`: ValueChanged<String>?
- **Cambios:**
  - Reemplazó `_buildTaskCard` por instanciación de `TaskCard`
  - Eliminó helpers duplicados (`_getStatusInfo`, `_formatDate`, etc.)

#### `lib/screens/admin_task_assign/admin_task_list.dart`
- **Antes:** Renderizado de tarjeta inline (~350 líneas con badges y checkboxes)
- **Después:** Usa `TaskCard` (~120 líneas)
- **Cambios:**
  - Reemplazó `_buildTaskCard` por `TaskCard`
  - Eliminó métodos duplicados (`_getTaskStatusInfo`, `_buildReadStatusBadge`, `_buildTaskStatusBadge`, `_formatDate`)
  - Mantiene props de selección y callbacks existentes

#### `lib/screens/simple_task_assign_screen.dart`
- **Nuevas funcionalidades:**
  - Estado `_selectedTaskIds` (Set<String>)
  - Handlers bulk: `_handleBulkReassign`, `_handleBulkChangePriority`, `_handleBulkDelete`, `_handleBulkMarkAsRead`
  - Diálogos: `_showUserPickerDialog`, `_showPriorityPickerDialog`, `_showConfirmDialog`
  - Integración de `BulkActionsBar` como `bottomSheet`
- **Control de permisos:**
  - Acciones destructivas (reasignar/eliminar/prioridad) solo para admins
  - `markAsRead` disponible para todos
- **Correcciones:**
  - Arreglado `use_build_context_synchronously` (captura de context antes de awaits)
  - Eliminado `print` de debug

#### `lib/widgets/task_card.dart`
- **Correcciones:**
  - Reemplazado `.withOpacity()` por `.withValues(alpha:)` (5 ocurrencias)

#### `lib/widgets/bulk_actions_bar.dart`
- **Correcciones:**
  - Reemplazado `.withOpacity()` por `.withValues(alpha:)` (3 ocurrencias)

### 3. Archivos Eliminados (Limpieza)
- `lib/services/auth_service_old.dart.bak`
- `lib/screens/admin_task_assign_screen_old.dart.bak`
- `lib/screens/tasks_screen_old.dart.bak`
- `lib/screens/home_screen_old.dart.bak`
- `lib/screens/simple_task_assign_screen.dart.backup`
- `lib/screens/admin_users_screen.dart.backup`

## Métricas de Mejora

### Líneas de código
- **Antes:**
  - `simple_task_list.dart`: ~380 líneas
  - `admin_task_list.dart`: ~544 líneas
  - **Total:** ~924 líneas
- **Después:**
  - `task_card.dart`: ~346 líneas (nuevo, reutilizable)
  - `simple_task_list.dart`: ~180 líneas
  - `admin_task_list.dart`: ~120 líneas
  - **Total:** ~646 líneas
- **Reducción:** ~278 líneas (~30% menos código)

### Calidad del código
- **Avisos del analizador:** 230 → 208 (22 avisos corregidos)
- **Duplicación:** Eliminada (helper methods, UI rendering)
- **Reutilización:** 1 componente usado en 2+ pantallas

### Mantenibilidad
- ✅ Un solo lugar para actualizar UI de tarjetas
- ✅ Consistencia visual garantizada
- ✅ Tests centralizados (futuros)
- ✅ Menor superficie de error

## Testing

### Tests Existentes
- `test/bulk_actions_bar_test.dart`: 7/7 pasando ✅

### Tests Recomendados (Pendientes)
- [ ] `test/widgets/task_card_test.dart`:
  - Renderizado básico
  - Callbacks (onTap, onEdit, onDelete, onToggleSelect)
  - Checkbox visible cuando `onToggleSelect != null`
  - Badge de leído/no leído
  - Badge de confirmación
  - Comportamiento con tareas vencidas
- [ ] Integración: selección múltiple + bulk actions en `SimpleTaskAssignScreen`

## Compatibilidad

### Cambios Breaking
- ❌ Ninguno (APIs públicas sin cambios)

### Migración
- ✅ No requiere cambios en otros archivos
- ✅ Imports existentes siguen funcionando

## Problemas Conocidos

### Errores de Firestore (Esperados)
1. **Índice compuesto faltante:**
   ```
   The query requires an index. You can create it here:
   https://console.firebase.google.com/v1/r/project/app-notas-3d555/firestore/indexes?create_composite=...
   ```
   - **Causa:** Query en `task_cleanup_service.dart` (status + completedAt)
   - **Solución:** Desplegar `firestore.indexes.json`
   - **Estado:** Pendiente (TODO #2)

2. **Permisos de history:**
   ```
   [cloud_firestore/permission-denied] Missing or insufficient permissions.
   ```
   - **Causa:** Escritura en `tasks/{taskId}/history` (legacy path)
   - **Solución:** Actualizar reglas de Firestore
   - **Estado:** Pendiente (TODO #3)
   - **Impacto:** No crítico (eventos se guardan en `task_history/{taskId}/events`)

### Avisos del Analizador (No Críticos)
- 208 avisos restantes (mayoría: `deprecated_member_use`, `prefer_const_constructors`)
- Prioridad: Media (mejora de calidad, no funcional)

## Próximos Pasos

### Inmediatos
1. ✅ Corregir `use_build_context_synchronously` en `simple_task_assign_screen.dart`
2. ✅ Reemplazar `.withOpacity()` por `.withValues(alpha:)` en widgets críticos
3. ✅ Eliminar archivos `.bak` y `.backup`

### Corto Plazo
1. [ ] Añadir tests para `TaskCard`
2. [ ] Desplegar índices de Firestore (TODO #2)
3. [ ] Verificar/actualizar reglas de Firestore (TODO #3)
4. [ ] Corregir avisos restantes del analizador (batch)

### Mediano Plazo
1. [ ] Implementar campo `priority` en `TaskModel`
2. [ ] Añadir subcolección `comments`
3. [ ] Implementar notificaciones push
4. [ ] Añadir tags/search avanzado

## Lecciones Aprendidas

1. **Refactorización incremental:** Extraer componente primero, luego integrar funcionalidad nueva
2. **Tests antes de refactor:** Tener tests de widgets existentes habría acelerado validación
3. **Deprecations proactivas:** Actualizar a nuevas APIs (`.withValues()`) al mismo tiempo que el refactor
4. **Control de permisos:** Importante validar en cliente y servidor (Firestore rules)

## Referencias

- Commit principal: (pendiente de commit)
- PRs relacionados: N/A (cambios directos en master)
- Issues: N/A

---

**Autor:** GitHub Copilot (con supervisión del usuario)  
**Revisado por:** Pendiente
