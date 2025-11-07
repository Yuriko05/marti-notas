import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../theme/app_theme.dart';

/// Widget de estadísticas del dashboard de tareas con colores corporativos
class SimpleTaskStats extends StatelessWidget {
  final List<TaskModel> tasks;

  const SimpleTaskStats({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((task) => task.isPending).length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final overdueTasks = tasks.where((task) => task.isOverdue).length;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCorporate,
                  borderRadius: AppBorderRadius.smRadius,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: AppIconSizes.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Estadísticas de Tareas',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total", tasks.length, Icons.assignment_rounded,
                  AppColors.primary),
              _buildStatItem("Pendientes", pendingTasks, Icons.schedule_rounded,
                  AppColors.pendingColor),
              _buildStatItem("Completadas", completedTasks,
                  Icons.check_circle_rounded, AppColors.completedColor),
            ],
          ),
          if (overdueTasks > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.overdueColor.withValues(alpha: 0.1),
                    AppColors.overdueLight.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: AppBorderRadius.smRadius,
                border: Border.all(color: AppColors.overdueColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded,
                      color: AppColors.overdueColor, size: AppIconSizes.sm),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$overdueTasks tareas vencidas requieren atención',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.overdueDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: AppIconSizes.md),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value.toString(),
          style: AppTextStyles.heading2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
