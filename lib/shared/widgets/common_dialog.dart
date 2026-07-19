import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/shared/widgets/custom_button.dart';

class CommonDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? contentWidget;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Color? confirmColor;
  final Color? iconColor;
  final Color? iconBgColor;

  const CommonDialog({
    super.key,
    required this.icon,
    required this.title,
    this.content,
    this.contentWidget,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.confirmColor,
    this.iconColor,
    this.iconBgColor,
  }) : assert(
         content != null || contentWidget != null,
         'Must provide either content or contentWidget',
       );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusDialog),
      backgroundColor: AppColors.bgCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: iconBgColor ?? AppColors.statusRedBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.deleteRed,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (contentWidget != null)
              contentWidget!
            else
              Text(
                content!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelText,
                    onPressed: onCancel,
                    backgroundColor: Colors.transparent,
                    textColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomButton(
                    text: confirmText,
                    onPressed: onConfirm,
                    backgroundColor: confirmColor ?? AppColors.deleteRed,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showCommonDialog<T>({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? content,
  Widget? contentWidget,
  required String confirmText,
  required String cancelText,
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
  Color? confirmColor,
  Color? iconColor,
  Color? iconBgColor,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => CommonDialog(
      icon: icon,
      title: title,
      content: content,
      contentWidget: contentWidget,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmColor: confirmColor,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
    ),
  );
}
