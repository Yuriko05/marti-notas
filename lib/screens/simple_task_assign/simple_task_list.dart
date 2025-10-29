import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/task_preview_dialog.dart';

/// Widget de lista de tareas con filtrado
class SimpleTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<UserModel> users;
  final String searchQuery;
  final String statusFilter;
  final Function(TaskModel) onEdit;
  final Function(TaskModel) onDelete;

  const SimpleTaskList({
    super.key,
    required this.tasks,
    required this.users,
    required this.searchQuery,
    required this.statusFilter,
    required this.onEdit,
    required this.onDelete,
  });

  List<TaskModel> get filteredTasks {
    return tasks.where((task) {
      bool matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesStatus = statusFilter == 'all' ||
          (statusFilter == 'pending' && task.isPending) ||
          (statusFilter == 'completed' && task.isCompleted) ||
          (statusFilter == 'overdue' && task.isOverdue);

      return matchesSearch && matchesStatus;
    }).toList();
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
          return _buildTaskCard(context, task);
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
                    searchQuery.isNotEmpty || statusFilter != 'all'
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
                    searchQuery.isNotEmpty || statusFilter != 'all'
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

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    final user = users.firstWhere(
      (u) => u.uid == task.assignedTo,
      orElse: () => UserModel(
        uid: task.assignedTo,
        email: 'Usuario eliminado',
        name: 'Usuario eliminado',
        role: 'normal',
        createdAt: DateTime.now(),
      ),
    );

    final statusInfo = _getStatusInfo(task.status);
    final isOverdue = task.isOverdue;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskPreviewDialog(task: task),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue ? Border.all(color: Colors.red, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: statusInfo['gradient'] as Gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusInfo['icon'] as IconData,
                    color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VENCIDA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit(task);
                    if (value == 'delete') onDelete(task);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${_formatDate(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: statusInfo['gradient'] as Gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusInfo['text'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'color': const Color(0xFFf093fb),
          'text': 'Pendiente',
          'icon': Icons.schedule,
          'gradient': const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
        };
      case 'completed':
        return {
          'color': const Color(0xFF43e97b),
          'text': 'Completada',
          'icon': Icons.check_circle,
          'gradient': const LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          ),
        };
      default:
        return {
          'color': Colors.grey,
          'text': 'Desconocido',
          'icon': Icons.help,
          'gradient': const LinearGradient(colors: [Colors.grey, Colors.grey]),
        };
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
