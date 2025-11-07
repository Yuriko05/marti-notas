import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../theme/app_theme.dart';

/// Widget de estadísticas para las tareas del usuario
class UserTaskStats extends StatelessWidget {
  final List<TaskModel> allTasks;

  const UserTaskStats({
    super.key,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    print('📊 UserTaskStats: Recibidas ${allTasks.length} tareas para analizar');
    for (var task in allTasks) {
      print('   📋 Tarea: "${task.title}" - Status: "${task.status}" - isPending: ${task.isPending}, isInProgress: ${task.isInProgress}, isPendingReview: ${task.isPendingReview}, isCompleted: ${task.isCompleted}');
    }
    
    final pending = allTasks.where((t) => t.isPending).length;
    final inProgress = allTasks.where((t) => t.isInProgress).length;
    final pendingReview = allTasks.where((t) => t.isPendingReview).length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final overdue = allTasks.where((t) => t.isOverdue && !t.isCompleted).length;
    final total = allTasks.length;
    
    print('📊 UserTaskStats: Total=$total, Pendientes=$pending, EnProgreso=$inProgress, EnRevisión=$pendingReview, Completadas=$completed, Vencidas=$overdue');
    
    // Calcular progreso
    final progress = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.lgRadius,
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientCorporate,
                      borderRadius: AppBorderRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Mi Progreso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Grid de estadísticas
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule_rounded,
                  label: 'Pendientes',
                  value: pending.toString(),
                  color: const Color(0xFFf7b733),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'En Progreso',
                  value: inProgress.toString(),
                  color: const Color(0xFF667eea),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Completadas',
                  value: completed.toString(),
                  color: const Color(0xFF43e97b),
                ),
              ),
            ],
          ),
          if (pendingReview > 0 || overdue > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (pendingReview > 0) ...[
                  Expanded(
                    child: _StatCard(
                      icon: Icons.rate_review,
                      label: 'En Revisión',
                      value: pendingReview.toString(),
                      color: const Color(0xFF764ba2),
                    ),
                  ),
                  if (overdue > 0) const SizedBox(width: AppSpacing.sm),
                ],
                if (overdue > 0)
                  Expanded(
                    child: _StatCard(
                      icon: Icons.warning_rounded,
                      label: 'Vencidas',
                      value: overdue.toString(),
                      color: const Color(0xFFfc4a1a),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.mdRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
