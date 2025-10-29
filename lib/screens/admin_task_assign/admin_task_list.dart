import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/task_preview_dialog.dart';

/// Widget que muestra la lista de tareas asignadas con soporte de búsqueda y filtrado
class AdminTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<UserModel> users;
  final String searchQuery;
  final String statusFilter;

  const AdminTaskList({
    super.key,
    required this.tasks,
    required this.users,
    required this.searchQuery,
    required this.statusFilter,
  });

  @override
  Widget build(BuildContext context) {
    List<TaskModel> filteredTasks = tasks.where((task) {
      bool matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesStatus = statusFilter == 'all' ||
          (statusFilter == 'pending' && task.isPending) ||
          (statusFilter == 'completed' && task.isCompleted) ||
          (statusFilter == 'overdue' && task.isOverdue);

      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _buildTaskCard(context, task, index);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildTaskCard(BuildContext context, TaskModel task, int index) {
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

    final statusInfo = _getTaskStatusInfo(task);
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue
              ? Border.all(color: const Color(0xFFfc4a1a), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? const Color(0xFFfc4a1a).withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isOverdue ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono de estado y título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: statusInfo['gradient'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'],
                      color: Colors.white,
                      size: 16,
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
                            color: isOverdue
                                ? const Color(0xFFfc4a1a)
                                : const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            fontSize: 12,
                            color: statusInfo['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildReadStatusBadge(task),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
                        ),
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
              const SizedBox(height: 8),
              // Badge de estado de la tarea
              _buildTaskStatusBadge(task),
              const SizedBox(height: 12),
              // Descripción
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Información de asignación y vencimiento
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignado a',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFfc4a1a).withOpacity(0.1)
                            : const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue
                            ? const Color(0xFFfc4a1a)
                            : const Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vencimiento',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOverdue
                                ? const Color(0xFFfc4a1a)
                                : const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTaskStatusInfo(TaskModel task) {
    switch (task.status) {
      case 'pending':
        return {
          'color': const Color(0xFFf093fb),
          'text': 'Pendiente',
          'icon': Icons.schedule,
          'gradient': const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
        };
      case 'in_progress':
        return {
          'color': const Color(0xFF4facfe),
          'text': 'En Progreso',
          'icon': Icons.autorenew,
          'gradient': const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
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
      case 'confirmed':
        return {
          'color': const Color(0xFF667eea),
          'text': 'Confirmada',
          'icon': Icons.verified,
          'gradient': const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        };
      case 'rejected':
        return {
          'color': const Color(0xFFfc4a1a),
          'text': 'Rechazada',
          'icon': Icons.cancel,
          'gradient': const LinearGradient(
            colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
          ),
        };
      default:
        return {
          'color': Colors.grey,
          'text': 'Desconocido',
          'icon': Icons.help,
          'gradient': const LinearGradient(
            colors: [Colors.grey, Colors.grey],
          ),
        };
    }
  }

  Widget _buildReadStatusBadge(TaskModel task) {
    if (task.isRead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF34B7F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done_all,
              color: const Color(0xFF34B7F1),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Leída',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF34B7F1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done,
              color: Colors.grey,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'No leída',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTaskStatusBadge(TaskModel task) {
    String badgeText = '';
    Color badgeColor = Colors.grey;

    if (task.isCompleted && !task.isConfirmed && !task.isRejected) {
      badgeText = 'Esperando Confirmación';
      badgeColor = const Color(0xFFf093fb);
    } else if (task.isConfirmed) {
      badgeText = 'Confirmada por Admin';
      badgeColor = const Color(0xFF667eea);
    } else if (task.isRejected) {
      badgeText = 'Rechazada';
      badgeColor = const Color(0xFFfc4a1a);
    }

    if (badgeText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task.isConfirmed
                ? Icons.verified
                : task.isRejected
                    ? Icons.cancel
                    : Icons.pending,
            color: badgeColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
