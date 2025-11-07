import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/enhanced_task_assign_dialog.dart';

/// Diálogos reutilizables para la gestión de tareas
class TaskDialogs {
  /// Muestra diálogo para editar una tarea existente
  static Future<void> showEditTaskDialog({
    required BuildContext context,
    required TaskModel task,
    required VoidCallback onSuccess,
  }) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tarea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El título es requerido')),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final success = await AdminService.updateTask(
                taskId: task.id,
                title: titleController.text,
                description: descriptionController.text,
                assignedToUserId: task.assignedTo,
                dueDate: task.dueDate,
              );

              if (!context.mounted) return;
              navigator.pop();

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tarea actualizada correctamente')),
                );
                onSuccess();
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Error al actualizar la tarea')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para confirmar eliminación de una tarea
  static Future<void> showDeleteTaskDialog({
    required BuildContext context,
    required TaskModel task,
    required VoidCallback onSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: Text('¿Estás seguro de que quieres eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final success = await AdminService.deleteTask(task.id);

              if (!context.mounted) return;
              navigator.pop();

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tarea eliminada correctamente')),
                );
                onSuccess();
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Error al eliminar la tarea')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para crear y asignar una nueva tarea
  static Future<void> showSimpleAssignDialog({
    required BuildContext context,
    required List<UserModel> users,
    required VoidCallback onSuccess,
  }) async {
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuarios disponibles')),
      );
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedTaskAssignDialog(
        users: users,
        onSuccess: onSuccess,
      ),
    );
  }

  /// Muestra diálogo para seleccionar un usuario
  static Future<UserModel?> showUserPickerDialog({
    required BuildContext context,
    required List<UserModel> users,
  }) async {
    return showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar usuario'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => Navigator.pop(context, user),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para seleccionar prioridad
  static Future<String?> showPriorityPickerDialog({
    required BuildContext context,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar prioridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Color(0xFFfc4a1a)),
              title: const Text('Alta'),
              onTap: () => Navigator.pop(context, 'high'),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Color(0xFFf7b733)),
              title: const Text('Media'),
              onTap: () => Navigator.pop(context, 'medium'),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Color(0xFF43e97b)),
              title: const Text('Baja'),
              onTap: () => Navigator.pop(context, 'low'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo de confirmación genérico
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String message,
    bool isDestructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDestructive ? '¿Estás seguro?' : 'Confirmar acción',
          style: TextStyle(
            color: isDestructive ? const Color(0xFFfc4a1a) : null,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? const Color(0xFFfc4a1a)
                  : const Color(0xFF667eea),
            ),
            child: Text(isDestructive ? 'Eliminar' : 'Confirmar'),
          ),
        ],
      ),
    );
  }
}
