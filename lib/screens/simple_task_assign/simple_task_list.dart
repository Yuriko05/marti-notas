import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/search_service.dart';
import '../../widgets/task_preview_dialog.dart';
import '../../widgets/task_card.dart';

/// Widget de lista de tareas con filtrado
class SimpleTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<UserModel> users;
  final TaskSearchFilters filters;
  final Function(TaskModel) onEdit;
  final Function(TaskModel) onDelete;
  final String currentUserId;
  final Set<String> selectedTaskIds;
  final ValueChanged<String>? onTaskToggleSelection;
  final TaskModel? selectedTask; // Para highlight de tarea seleccionada
  final Function(TaskModel)? onTaskSelected; // Callback para seleccionar tarea

  const SimpleTaskList({
    super.key,
    required this.tasks,
    required this.users,
  required this.filters,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    this.selectedTaskIds = const {},
    this.onTaskToggleSelection,
    this.selectedTask,
    this.onTaskSelected,
  });

  List<TaskModel> get filteredTasks {
    return SearchService.applyFilters(tasks, filters);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredTasks;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final task = filtered[index];
          final user = users.firstWhere(
            (u) => u.uid == task.assignedTo,
            orElse: () => UserModel(
              uid: task.assignedTo,
              email: 'usuario.eliminado@example.com',
              name: 'Usuario eliminado',
              role: 'normal',
              username: 'usuarioeliminado',
              hasPassword: false,
              createdAt: DateTime.now(),
            ),
          );

          final isChecked = selectedTaskIds.contains(task.id);
          final isSelected = selectedTask?.id == task.id;

          return TaskCard(
            task: task,
            user: user,
            isChecked: isChecked,
            isSelected: isSelected,
            onToggleSelect: onTaskToggleSelection,
            showActions: true,
            onTap: () {
              // Seleccionar tarea para ver historial
              onTaskSelected?.call(task);
              
              if (task.assignedTo == currentUserId) {
                showDialog(
                  context: context,
                  builder: (context) => TaskPreviewDialog(task: task),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solo el usuario asignado puede abrir la tarea')),
              );
            },
            onEdit: (t) => onEdit(t),
            onDelete: (t) => onDelete(t),
            onPreview: (t) {
              // Same restriction: only assigned user can open preview
              if (task.assignedTo == currentUserId) {
                showDialog(
                  context: context,
                  builder: (context) => TaskPreviewDialog(task: task),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solo el usuario asignado puede abrir la tarea')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filters.hasActiveFilters
                        ? 'No se encontraron tareas'
                        : 'No hay tareas asignadas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filters.hasActiveFilters
                        ? 'Intenta ajustar los filtros de búsqueda'
                        : 'Comienza asignando tareas a tu equipo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}
