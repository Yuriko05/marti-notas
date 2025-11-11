import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../widgets/task_preview_dialog.dart';

/// Lista de tareas con integración real a Firestore
class TaskList extends StatelessWidget {
  final String userId;
  final String status;
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
          
          final filteredTasks = tasks.where((task) {
            final matchesSearch = searchQuery.isEmpty ||
                task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                task.description.toLowerCase().contains(searchQuery.toLowerCase());
            
            final matchesPriority = priorityFilter == 'all' || 
                                    task.priority == priorityFilter;
            
            return matchesSearch && matchesPriority;
          }).toList();
          
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

  // =======================================================================
  // INICIO DE LÓGICA DE TASKCARD FUSIONADA
  // =======================================================================

  /// Construye la tarjeta de tarea avanzada
  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    final isMobile = MediaQuery.of(context).size.width < 420;
    final statusInfo = _getStatusInfo(task); 
    final isOverdue = task.isOverdue;
    final UserModel? user = null; // No lo usamos en esta vista

    return InkWell(
      onTap: () {
        TaskPreviewDialog.open(context, task, showActions: true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
                  ? Border.all(color: const Color(0xFFfc4a1a), width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? const Color(0xFFfc4a1a).withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
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
              // SECCIÓN DE CABECERA
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
                            fontSize: isMobile ? 15 : 16, 
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? const Color(0xFFfc4a1a)
                                : const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusInfo['text'] as String,
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: statusInfo['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Ver detalle',
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () {
                      TaskPreviewDialog.open(context, task, showActions: true);
                    },
                  ),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'VENCIDA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // SECCIÓN DE DESCRIPCIÓN
              Text(
                task.description,
                style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey.shade700,
                    height: 1.4),
                maxLines: isMobile ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // SECCIÓN DE BADGES (PRIORIDAD, LEÍDA, ETC.)
              _buildBadgeSection(context, task),

              // SECCIÓN INFERIOR (ASIGNADO Y VENCIMIENTO)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAssignedToInfo(isOverdue, task, user),
                          const SizedBox(height: 8),
                          _buildDueDateInfo(isOverdue, task),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildAssignedToInfo(isOverdue, task, user)),
                          _buildDueDateInfo(isOverdue, task),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers de la Tarjeta Avanzada ---

  // !! CAMBIO: Esta función ahora muestra "Admin" o "Personal"
  Widget _buildAssignedToInfo(bool isOverdue, TaskModel task, UserModel? user) {
    final bool isPersonal = task.isPersonal;
    final String titleText = isPersonal ? 'Tipo de Tarea' : 'Asignado por';
    final String valueText = isPersonal ? 'Personal' : 'Admin';
    final IconData icon = isPersonal ? Icons.person : Icons.admin_panel_settings;
    final Color color = isPersonal ? const Color(0xFF667eea) : Colors.orange.shade700;
    final Color bgColor = isPersonal ? const Color(0xFF667eea).withOpacity(0.1) : Colors.orange.shade50;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor, // Usa el color de fondo dinámico
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color), // Usa el icono y color dinámico
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titleText, // Usa el título dinámico
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              Text(valueText, // Usa el valor dinámico
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateInfo(bool isOverdue, TaskModel task) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOverdue
                ? const Color(0xFFfc4a1a).withOpacity(0.1)
                : const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.calendar_today,
              size: 16,
              color:
                  isOverdue ? const Color(0xFFfc4a1a) : const Color(0xFF667eea)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vencimiento',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
            Text(_formatDate(task.dueDate),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? const Color(0xFFfc4a1a)
                        : const Color(0xFF2D3748))),
          ],
        ),
      ],
    );
  }

  // !! CAMBIO: Se eliminó _buildReadStatusBadge de esta lista
  Widget _buildBadgeSection(BuildContext context, TaskModel task) {
    final List<Widget> badges = [
      _buildPriorityBadge(task),
      // _buildReadStatusBadge(task), // <-- ELIMINADO
      _buildTaskStatusBadge(task),
      if (task.reviewComment != null && task.reviewComment!.isNotEmpty)
        _buildNewCommentBadge(task),
      if ((task.status == 'completed' ||
              task.status == 'confirmed' ||
              task.status == 'rejected') &&
          task.reviewComment != null &&
          task.reviewComment!.isNotEmpty)
        _buildReviewCommentSection(task),
    ];

    final visibleBadges = badges
        .where((b) => !(b is SizedBox && (b.width == 0 || b.height == 0)))
        .toList();

    if (visibleBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: visibleBadges,
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(TaskModel task) {
    if (task.status == 'in_progress' &&
        task.reviewComment != null &&
        task.reviewComment!.isNotEmpty) {
      return {
        'color': const Color(0xFFfc4a1a),
        'text': 'Rechazada (Corregir)',
        'icon': Icons.warning_amber_rounded,
        'gradient':
            const LinearGradient(colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
      };
    }

    switch (task.status) {
      case 'pending':
        return {
          'color': const Color(0xFFf093fb),
          'text': 'Pendiente',
          'icon': Icons.schedule,
          'gradient':
              const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
        };
      case 'in_progress':
        return {
          'color': const Color(0xFF4facfe),
          'text': 'En Progreso',
          'icon': Icons.autorenew,
          'gradient':
              const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
        };
      case 'pending_review':
        return {
          'color': const Color(0xFF43e97b),
          'text': 'En Revisión',
          'icon': Icons.check_circle,
          'gradient':
              const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
        };
      case 'completed':
         return {
          'color': const Color(0xFF43e97b),
          'text': 'Completada',
          'icon': Icons.check_circle_outline,
          'gradient':
              const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
        };
      case 'confirmed':
        return {
          'color': const Color(0xFF667eea),
          'text': 'Confirmada',
          'icon': Icons.verified,
          'gradient':
              const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        };
      case 'rejected':
        return {
          'color': const Color(0xFFfc4a1a),
          'text': 'Rechazada',
          'icon': Icons.cancel,
          'gradient':
              const LinearGradient(colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
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

  // !! ESTA FUNCIÓN AÚN EXISTE, PERO YA NO SE LLAMA (la dejamos por si acaso)
  Widget _buildReadStatusBadge(TaskModel task) {
    if (task.isRead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFF34B7F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, color: const Color(0xFF34B7F1), size: 14),
            const SizedBox(width: 4),
            Text('Leída',
                style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF34B7F1),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, color: Colors.grey, size: 14),
            const SizedBox(width: 4),
            Text('No leída',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  Widget _buildNewCommentBadge(TaskModel task) {
    final isRejected = (task.status == 'in_progress' &&
        task.reviewComment != null &&
        task.reviewComment!.isNotEmpty);

    final isApprovedComment = (task.status == 'completed' ||
            task.status == 'confirmed' ||
            task.status == 'pending_review') &&
        task.reviewComment != null &&
        task.reviewComment!.isNotEmpty;

    final Color color;
    final String text;
    final IconData icon;

    if (isRejected) {
      color = const Color(0xFFfc4a1a);
      text = '❗️ Tarea Rechazada';
      icon = Icons.warning;
    } else if (isApprovedComment) {
      color = const Color(0xFF667eea);
      text = '💬 Comentario Admin';
      icon = Icons.message;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
            icon,
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
      case 'high':
        priorityInfo = {
          'color': const Color(0xFFfc4a1a),
          'icon': Icons.priority_high,
          'text': 'Alta',
        };
        break;
      case 'low':
        priorityInfo = {
          'color': const Color(0xFF43e97b),
          'icon': Icons.arrow_downward,
          'text': 'Baja',
        };
        break;
      case 'medium':
      default:
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
        color: (priorityInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (priorityInfo['color'] as Color).withOpacity(0.3),
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

    if (task.status == 'pending_review') {
      badgeText = 'Esperando Confirmación';
      badgeColor = const Color(0xFFf093fb);
    } else if (task.status == 'confirmed') {
      badgeText = 'Confirmada por Admin';
      badgeColor = const Color(0xFF667eea);
    }

    if (badgeText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              task.isConfirmed
                  ? Icons.verified
                  : Icons.pending,
              color: badgeColor,
              size: 14),
          const SizedBox(width: 6),
          Text(badgeText,
              style: TextStyle(
                  fontSize: 11,
                  color: badgeColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReviewCommentSection(TaskModel task) {
    final isApprovedComment = (task.status == 'completed' ||
            task.status == 'confirmed' ||
            task.status == 'pending_review');

    if (!isApprovedComment) {
      return const SizedBox.shrink();
    }
    
    final color = const Color(0xFF667eea);
    final icon = Icons.rate_review;
    final title = 'Comentario de Revisión';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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

  // =======================================================================
  // FIN DE LÓGICA DE TASKCARD FUSIONADA
  // =======================================================================


  // --- Helpers originales de TaskList (para mensajes de "vacío") ---
  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }

  String _getEmptyMessageForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'No tienes tareas pendientes';
      case 'in_progress':
        return 'No tienes tareas en progreso';
      case 'completed':
        return 'No tienes tareas completadas';
      default:
        return 'No hay tareas';
    }
  }
}