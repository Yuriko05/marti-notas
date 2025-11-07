import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/history_service.dart';
import '../../services/task_service.dart';
import 'task_dialogs.dart';

/// Handlers para acciones masivas (bulk actions) sobre tareas
class BulkActionHandlers {
  /// Reasigna múltiples tareas a un usuario seleccionado (solo admins)
  static Future<void> handleBulkReassign({
    required BuildContext context,
    required Set<String> selectedTaskIds,
    required List<UserModel> users,
    required UserModel currentUser,
    required VoidCallback onSuccess,
    required VoidCallback onClearSelection,
  }) async {
    if (!currentUser.isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado')),
        );
      }
      return;
    }

    final selectedUser = await TaskDialogs.showUserPickerDialog(
      context: context,
      users: users,
    );
    if (selectedUser == null) return;

    final confirm = await TaskDialogs.showConfirmDialog(
      context: context,
      message: 'Reasignar ${selectedTaskIds.length} tarea(s) a ${selectedUser.name}?',
    );
    if (confirm != true) return;

    try {
      for (final taskId in selectedTaskIds) {
        await AdminService.reassignTask(taskId, selectedUser.uid);
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'bulk_reassign',
          actorUid: currentUser.uid,
          actorRole: currentUser.isAdmin ? 'admin' : 'user',
          payload: {'to': selectedUser.uid},
        );
      }
      onClearSelection();
      onSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tareas reasignadas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reasignar: $e')),
        );
      }
    }
  }

  /// Cambia la prioridad de múltiples tareas (solo admins)
  static Future<void> handleBulkChangePriority({
    required BuildContext context,
    required Set<String> selectedTaskIds,
    required UserModel currentUser,
    required VoidCallback onSuccess,
    required VoidCallback onClearSelection,
  }) async {
    if (!currentUser.isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado')),
        );
      }
      return;
    }

    final priority = await TaskDialogs.showPriorityPickerDialog(
      context: context,
    );
    if (priority == null) return;

    final confirm = await TaskDialogs.showConfirmDialog(
      context: context,
      message: 'Cambiar prioridad de ${selectedTaskIds.length} tarea(s) a $priority?',
    );
    if (confirm != true) return;

    try {
      for (final taskId in selectedTaskIds) {
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'bulk_priority_change',
          actorUid: currentUser.uid,
          actorRole: currentUser.isAdmin ? 'admin' : 'user',
          payload: {'priority': priority},
        );
      }
      onClearSelection();
      onSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prioridad actualizada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar prioridad: $e')),
        );
      }
    }
  }

  /// Elimina múltiples tareas (solo admins)
  static Future<void> handleBulkDelete({
    required BuildContext context,
    required Set<String> selectedTaskIds,
    required UserModel currentUser,
    required VoidCallback onSuccess,
    required VoidCallback onClearSelection,
  }) async {
    if (!currentUser.isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autorizado')),
        );
      }
      return;
    }

    final confirm = await TaskDialogs.showConfirmDialog(
      context: context,
      message: '¿Eliminar ${selectedTaskIds.length} tarea(s)? Esta acción no se puede deshacer.',
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      for (final taskId in selectedTaskIds) {
        await AdminService.deleteTask(taskId);
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'bulk_delete',
          actorUid: currentUser.uid,
          actorRole: 'admin',
          payload: {},
        );
      }
      onClearSelection();
      onSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tareas eliminadas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  /// Marca múltiples tareas como leídas (disponible para todos los usuarios)
  static Future<void> handleBulkMarkAsRead({
    required BuildContext context,
    required Set<String> selectedTaskIds,
    required VoidCallback onSuccess,
    required VoidCallback onClearSelection,
  }) async {
    final confirm = await TaskDialogs.showConfirmDialog(
      context: context,
      message: 'Marcar ${selectedTaskIds.length} tarea(s) como leída(s)?',
    );
    if (confirm != true) return;

    try {
      for (final taskId in selectedTaskIds) {
        await TaskService.markTaskAsRead(taskId);
      }
      onClearSelection();
      onSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tareas marcadas como leídas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como leído: $e')),
        );
      }
    }
  }
}
