import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botón personalizado con estados visuales y animaciones
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height,
  });

  /// Botón primario (azul marino)
  factory AppButton.primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isPrimary: true,
      icon: icon,
      isFullWidth: isFullWidth,
    );
  }

  /// Botón secundario (naranja)
  factory AppButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isPrimary: false,
      icon: icon,
      isFullWidth: isFullWidth,
    );
  }

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedContainer(
      duration: AppAnimations.normal,
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: widget.height ?? 52,
      decoration: BoxDecoration(
        gradient: widget.isPrimary && !isDisabled
            ? AppColors.gradientPrimary
            : (isDisabled ? null : AppColors.gradientSecondary),
        color: isDisabled ? AppColors.backgroundMedium : null,
        borderRadius: AppBorderRadius.mdRadius,
        boxShadow: !isDisabled && !_isPressed
            ? [
                widget.isPrimary
                    ? AppColors.shadowPrimary
                    : AppColors.shadowSecondary
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: AppBorderRadius.mdRadius,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        isDisabled ? AppColors.textDisabled : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: AppIconSizes.sm,
                          color: isDisabled
                              ? AppColors.textDisabled
                              : Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.text,
                        style: AppTextStyles.button.copyWith(
                          color: isDisabled
                              ? AppColors.textDisabled
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Botón de texto simple
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.sm, color: buttonColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// Botón con contorno
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppColors.primary : AppColors.secondary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.sm, color: color),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(text),
        ],
      ),
    );
  }
}
