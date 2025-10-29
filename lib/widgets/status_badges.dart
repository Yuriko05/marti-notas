import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

/// Indicador visual de estado de tarea con badges mejorados
class TaskStatusIndicator extends StatelessWidget {
  final TaskModel task;
  final bool showLabel;
  final double? size;

  const TaskStatusIndicator({
    super.key,
    required this.task,
    this.showLabel = true,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size ?? AppSpacing.sm + 4,
        vertical: size != null ? size! / 4 : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(size != null ? size! : 20),
        border: Border.all(
          color: _getStatusColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: size ?? AppIconSizes.xs,
            color: _getStatusColor(),
          ),
          if (showLabel) ...[
            SizedBox(width: size != null ? size! / 3 : AppSpacing.xs),
            Text(
              _getStatusText(),
              style: AppTextStyles.caption.copyWith(
                fontSize: size != null ? size! / 1.5 : 12,
                fontWeight: FontWeight.w700,
                color: _getStatusColor(),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (task.isOverdue) return AppColors.overdueColor;
    if (task.isCompleted) return AppColors.completedColor;
    return AppColors.pendingColor;
  }

  IconData _getStatusIcon() {
    if (task.isOverdue) return Icons.warning_rounded;
    if (task.isCompleted) return Icons.check_circle_rounded;
    return Icons.schedule_rounded;
  }

  String _getStatusText() {
    if (task.isOverdue) return 'VENCIDA';
    if (task.isCompleted) return 'COMPLETADA';
    return 'PENDIENTE';
  }
}

/// Badge mejorado de administrador
class AdminBadge extends StatelessWidget {
  final double? size;
  final bool showIcon;

  const AdminBadge({
    super.key,
    this.size,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size ?? 12;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize * 0.67,
        vertical: badgeSize * 0.33,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, AppColors.adminDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(badgeSize),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.verified_user_rounded,
              size: badgeSize * 1.17,
              color: Colors.white,
            ),
            SizedBox(width: badgeSize * 0.33),
          ],
          Text(
            'ADMIN',
            style: TextStyle(
              fontSize: badgeSize * 0.92,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de rol de usuario
class UserRoleBadge extends StatelessWidget {
  final bool isAdmin;
  final double? size;

  const UserRoleBadge({
    super.key,
    required this.isAdmin,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return AdminBadge(size: size);
    }

    final badgeSize = size ?? 12;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize * 0.67,
        vertical: badgeSize * 0.33,
      ),
      decoration: BoxDecoration(
        color: AppColors.userColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(badgeSize),
        border: Border.all(
          color: AppColors.userColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: badgeSize * 1.17,
            color: AppColors.userColor,
          ),
          SizedBox(width: badgeSize * 0.33),
          Text(
            'USUARIO',
            style: TextStyle(
              fontSize: badgeSize * 0.92,
              fontWeight: FontWeight.w600,
              color: AppColors.userColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de prioridad de tarea
class PriorityIndicator extends StatelessWidget {
  final String priority; // 'high', 'medium', 'low'
  final bool showLabel;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.12),
        borderRadius: AppBorderRadius.fullRadius,
        border: Border.all(
          color: _getPriorityColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getPriorityColor(),
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              _getPriorityText(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: _getPriorityColor(),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'alta':
        return AppColors.priorityHigh;
      case 'medium':
      case 'media':
        return AppColors.priorityMedium;
      case 'low':
      case 'baja':
        return AppColors.priorityLow;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getPriorityText() {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'alta':
        return 'ALTA';
      case 'medium':
      case 'media':
        return 'MEDIA';
      case 'low':
      case 'baja':
        return 'BAJA';
      default:
        return priority.toUpperCase();
    }
  }
}
