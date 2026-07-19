import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bgCard,
        borderRadius: borderRadius ?? AppRadius.radiusCard,
        border: border,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: AppColors.primaryBrown.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
