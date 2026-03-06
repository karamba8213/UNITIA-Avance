import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, accent }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final Widget? leadingWidget;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.leadingWidget,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color bg, fg;
    List<BoxShadow> shadows = [];
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.accent:
        bg = AppColors.primary; fg = Colors.white;
        if (!isDisabled) shadows = primaryShadow;
      case AppButtonVariant.secondary:
        bg = AppColors.surface; fg = AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 1.5);
      case AppButtonVariant.danger:
        bg = AppColors.error; fg = Colors.white;
      case AppButtonVariant.ghost:
        bg = Colors.transparent; fg = AppColors.primary;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isDisabled ? bg.withOpacity(0.5) : bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDisabled ? [] : shadows,
          border: border,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget!,
                      const SizedBox(width: 10),
                    ] else if (icon != null) ...[
                      Icon(icon, size: 20, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
