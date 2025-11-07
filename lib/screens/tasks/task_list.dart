import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../services/task_service.dart';
import '../../widgets/task_preview_dialog.dart';

/// Lista de tareas con integración real a Firestore
class TaskList extends StatelessWidget {
  final String userId;
  final TaskStatus status;
  final Animation<double> fadeAnimation;
  final String searchQuery;
  final String priorityFilter;

  const TaskList({
    super.key,
  required this.userId,
  required this.status,
    required this.fadeAnimation,
    this.searchQuery = '',
    this.priorityFilter = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: StreamBuilder<List<TaskModel>>(
  stream: TaskService.getUserTasksByStatus(userId, status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar tareas',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data ?? [];
          
          // Aplicar filtros
          final filteredTasks = tasks.where((task) {
            // Filtro de búsqueda
            final matchesSearch = searchQuery.isEmpty ||
                task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                task.description.toLowerCase().contains(searchQuery.toLowerCase());
            
            // Filtro de prioridad (si existe el campo en el modelo)
            final matchesPriority = priorityFilter == 'all';
            // TODO: Implementar filtro de prioridad cuando se agregue al modelo
            
            return matchesSearch && matchesPriority;
          }).toList();
          
          // Mostrar primero las tareas asignadas por admin (isPersonal == false),
          // y después las personales.
          final adminTasks = filteredTasks.where((t) => !t.isPersonal).toList();
          final personalTasks = filteredTasks.where((t) => t.isPersonal).toList();
          final orderedTasks = [...adminTasks, ...personalTasks];

          if (orderedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForStatus(status),
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'No se encontraron tareas'
                        : _getEmptyMessageForStatus(status),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderedTasks.length,
            itemBuilder: (context, index) {
              return _buildTaskCard(context, orderedTasks[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    final isOverdue = task.isOverdue;
    final statusInfo = _getTaskStatusInfo(task);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TaskPreviewDialog(task: task),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: statusInfo['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            fontSize: 12,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'VENCIDA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  // Etiqueta: si la tarea fue asignada por admin mostrar 'Admin',
                  // si es personal mostrar 'Personal'.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.isPersonal ? Colors.blue.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          task.isPersonal ? Icons.person : Icons.admin_panel_settings,
                          size: 12,
                          color: task.isPersonal ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.isPersonal ? 'Personal' : 'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            color: task.isPersonal ? Colors.blue.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTaskStatusInfo(TaskModel task) {
    switch (task.status) {
      case TaskStatus.pending:
        return {
          'text': 'Pendiente',
          'icon': Icons.schedule,
          'color': Colors.orange,
        };
      case TaskStatus.inProgress:
        return {
          'text': 'En Progreso',
          'icon': Icons.autorenew,
          'color': Colors.blue,
        };
      case TaskStatus.pendingReview:
        return {
          'text': 'En Revisión',
          'icon': Icons.rate_review,
          'color': Colors.amber,
        };
      case TaskStatus.completed:
        return {
          'text': 'Completada',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case TaskStatus.confirmed:
        return {
          'text': 'Confirmada',
          'icon': Icons.verified,
          'color': Colors.indigo,
        };
      case TaskStatus.rejected:
        return {
          'text': 'Rechazada',
          'icon': Icons.cancel,
          'color': Colors.red,
        };
    }
  }

  IconData _getIconForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.autorenew;
      case TaskStatus.pendingReview:
        return Icons.rate_review;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.confirmed:
        return Icons.verified;
      case TaskStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getEmptyMessageForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'No tienes tareas pendientes';
      case TaskStatus.inProgress:
        return 'No tienes tareas en progreso';
      case TaskStatus.pendingReview:
        return 'No tienes tareas en revisión';
      case TaskStatus.completed:
        return 'No tienes tareas completadas';
      case TaskStatus.confirmed:
        return 'No tienes tareas confirmadas';
      case TaskStatus.rejected:
        return 'No tienes tareas rechazadas';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
