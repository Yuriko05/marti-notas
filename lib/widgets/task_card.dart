import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';
import '../models/user_model.dart';
import 'task_preview_dialog.dart';

/// Tarjeta reutilizable para mostrar una tarea.
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel? user;
  final bool isSelected;
  final bool isChecked;
  final ValueChanged<String>? onToggleSelect;
  final VoidCallback? onTap;
  final ValueChanged<TaskModel>? onPreview;
  final ValueChanged<TaskModel>? onEdit;
  final ValueChanged<TaskModel>? onDelete;
  final bool showActions;

  const TaskCard({
    super.key,
    required this.task,
    this.user,
    this.isSelected = false,
    this.isChecked = false,
    this.onToggleSelect,
    this.onTap,
    this.onPreview,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
  final statusInfo = _getStatusInfo(task.status);
    final isOverdue = task.isOverdue;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF667eea), width: 2)
              : isOverdue
                  ? Border.all(color: const Color(0xFFfc4a1a), width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? const Color(0xFFfc4a1a).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
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
              Row(
                children: [
                  if (onToggleSelect != null)
                    Checkbox(
                      value: isChecked,
                      onChanged: (_) => onToggleSelect!(task.id),
                      activeColor: const Color(0xFF667eea),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: statusInfo['gradient'] as Gradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo['icon'] as IconData,
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
                            color: isOverdue ? const Color(0xFFfc4a1a) : const Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusInfo['text'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusInfo['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(task),
                  const SizedBox(width: 4),
                  // Badge de nuevo comentario del admin
          if ((task.isCompleted || task.isConfirmed || task.isRejected) && 
                      task.reviewComment != null && 
                      task.reviewComment!.isNotEmpty) ...[
                    _buildNewCommentBadge(task),
                    const SizedBox(width: 4),
                  ],
                  _buildReadStatusBadge(task),
                  IconButton(
                    tooltip: 'Ver detalle',
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () {
                      if (onPreview != null) {
                        onPreview!(task);
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => TaskPreviewDialog(task: task),
                        );
                      }
                    },
                  ),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'VENCIDA',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) onEdit!(task);
                        if (value == 'delete' && onDelete != null) onDelete!(task);
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
              const SizedBox(height: 8),
              _buildTaskStatusBadge(task),
              const SizedBox(height: 12),
              Text(
                task.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Mostrar comentario de revisión si existe y la tarea está completada/confirmada/rechazada
        if ((task.isCompleted || task.isConfirmed || task.isRejected) && 
                  task.reviewComment != null && 
                  task.reviewComment!.isNotEmpty)
                _buildReviewCommentSection(task),
              const SizedBox(height: 12),
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
                        color: const Color(0xFF667eea).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person, size: 16, color: Color(0xFF667eea)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Asignado a', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          Text(user?.name ?? task.assignedTo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isOverdue ? const Color(0xFFfc4a1a).withValues(alpha: 0.1) : const Color(0xFF667eea).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.calendar_today, size: 16, color: isOverdue ? const Color(0xFFfc4a1a) : const Color(0xFF667eea)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vencimiento', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        Text(_formatDate(task.dueDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOverdue ? const Color(0xFFfc4a1a) : const Color(0xFF2D3748))),
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

  Map<String, dynamic> _getStatusInfo(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return {
          'color': const Color(0xFFf093fb),
          'text': 'Pendiente',
          'icon': Icons.schedule,
          'gradient': const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
        };
      case TaskStatus.inProgress:
        return {
          'color': const Color(0xFF4facfe),
          'text': 'En Progreso',
          'icon': Icons.autorenew,
          'gradient': const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
        };
      case TaskStatus.completed:
        return {
          'color': const Color(0xFF43e97b),
          'text': 'Completada',
          'icon': Icons.check_circle,
          'gradient': const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
        };
      case TaskStatus.confirmed:
        return {
          'color': const Color(0xFF667eea),
          'text': 'Confirmada',
          'icon': Icons.verified,
          'gradient': const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        };
      case TaskStatus.pendingReview:
        return {
          'color': const Color(0xFFf7b733),
          'text': 'En Revisión',
          'icon': Icons.rate_review,
          'gradient': const LinearGradient(colors: [Color(0xFFf7b733), Color(0xFFfceabb)]),
        };
      case TaskStatus.rejected:
        return {
          'color': const Color(0xFFfc4a1a),
          'text': 'Rechazada',
          'icon': Icons.cancel,
          'gradient': const LinearGradient(colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
        };
    }
  }

  Widget _buildReadStatusBadge(TaskModel task) {
    if (task.isRead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFF34B7F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, color: const Color(0xFF34B7F1), size: 14),
            const SizedBox(width: 4),
            Text('Leída', style: TextStyle(fontSize: 10, color: const Color(0xFF34B7F1), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, color: Colors.grey, size: 14),
            const SizedBox(width: 4),
            Text('No leída', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  Widget _buildNewCommentBadge(TaskModel task) {
  final isRejected = task.isRejected;
    final color = isRejected ? const Color(0xFFfc4a1a) : const Color(0xFF667eea);
    final text = isRejected ? '¡Admin rechazó!' : '💬 Comentario';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRejected ? Icons.warning : Icons.message,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TaskModel task) {
    Map<String, dynamic> priorityInfo;

    switch (task.priority) {
      case TaskPriority.high:
        priorityInfo = {
          'color': const Color(0xFFfc4a1a),
          'icon': Icons.priority_high,
          'text': 'Alta',
        };
        break;
      case TaskPriority.low:
        priorityInfo = {
          'color': const Color(0xFF43e97b),
          'icon': Icons.arrow_downward,
          'text': 'Baja',
        };
        break;
      case TaskPriority.medium:
        priorityInfo = {
          'color': const Color(0xFFf7b733),
          'icon': Icons.remove,
          'text': 'Media',
        };
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (priorityInfo['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (priorityInfo['color'] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityInfo['icon'] as IconData,
            color: priorityInfo['color'] as Color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            priorityInfo['text'] as String,
            style: TextStyle(
              fontSize: 10,
              color: priorityInfo['color'] as Color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(task.isConfirmed ? Icons.verified : task.isRejected ? Icons.cancel : Icons.pending, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(badgeText, style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReviewCommentSection(TaskModel task) {
    // Determinar si es un rechazo para cambiar color y estilo
  final isRejected = task.isRejected;
    final color = isRejected ? const Color(0xFFfc4a1a) : const Color(0xFF667eea);
    final icon = isRejected ? Icons.cancel : Icons.rate_review;
    final title = isRejected ? 'Motivo de Rechazo' : 'Comentario de Revisión';
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.reviewComment!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $hour:$minute';
  }
}
