import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.textColor,
    this.width,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        (gradient != null ? Colors.transparent : AppColors.primaryBrown);
    final txtColor = textColor ?? Colors.white;

    Widget buttonContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: txtColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: txtColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: AppTextStyles.buttonText.copyWith(color: txtColor),
              ),
            ],
          );

    final style = ElevatedButton.styleFrom(
      backgroundColor: gradient != null ? Colors.transparent : bgColor,
      shadowColor: gradient != null ? Colors.transparent : null,
      foregroundColor: txtColor,
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.radiusMd,
      ),
      elevation: gradient != null ? 0 : 2,
    );

    Widget button;
    if (icon != null && !isLoading) {
      button = ElevatedButton(
        onPressed: isLoading ? () {} : onPressed,
        style: style,
        child: buttonContent,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? () {} : onPressed,
        style: style,
        child: buttonContent,
      );
    }

    if (gradient != null || boxShadow != null) {
      button = Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius ?? AppRadius.radiusMd,
          boxShadow: boxShadow,
        ),
        child: button,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
