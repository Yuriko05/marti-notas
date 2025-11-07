import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skeleton loader para tarjetas de tareas
class TaskCardSkeleton extends StatefulWidget {
  const TaskCardSkeleton({super.key});

  @override
  State<TaskCardSkeleton> createState() => _TaskCardSkeletonState();
}

class _TaskCardSkeletonState extends State<TaskCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.lgRadius,
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [AppColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: _buildShimmer(height: 20, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Descripción línea 1
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: _buildShimmer(height: 14, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Descripción línea 2
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: _buildShimmer(height: 14, width: 200),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metadatos
          Row(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value,
                    child: child,
                  );
                },
                child: _buildShimmer(height: 24, width: 100),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value,
                    child: child,
                  );
                },
                child: _buildShimmer(height: 24, width: 80),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundMedium,
            AppColors.backgroundMedium.withValues(alpha: 0.5),
            AppColors.backgroundMedium,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
    );
  }
}

/// Skeleton loader para lista de usuarios
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.mdRadius,
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundMedium,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMedium,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundMedium.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de estado vacío mejorado
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool useCorporateColors;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.useCorporateColors = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono con gradiente
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: useCorporateColors
                    ? AppColors.gradientCorporate
                    : LinearGradient(
                        colors: [
                          AppColors.textSecondary.withValues(alpha: 0.2),
                          AppColors.textTertiary.withValues(alpha: 0.1),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: useCorporateColors
                    ? [AppColors.shadowPrimary]
                    : [AppColors.shadowSm],
              ),
              child: Icon(
                icon,
                size: AppIconSizes.xxl,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Título
            Text(
              title,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Mensaje
            Text(
              message,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),

            // Botón de acción (opcional)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: AppIconSizes.sm),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de carga con logo corporativo
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool showBackground;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            shape: BoxShape.circle,
            boxShadow: [AppColors.shadowPrimary],
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            message!,
            style: AppTextStyles.body1.copyWith(
              color: showBackground ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientCorporate,
        ),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
