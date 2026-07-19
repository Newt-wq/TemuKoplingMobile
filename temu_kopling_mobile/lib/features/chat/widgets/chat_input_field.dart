import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEnabled;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final String status;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.isEnabled,
    required this.onSend,
    required this.onAttachmentTap,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Icon Button
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryBrown,
                size: 24,
              ),
              onPressed: onAttachmentTap,
            ),

            // Text Area Input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: AppColors.textSecondary),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13.5),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: status == 'Selesai'
                        ? 'Obrolan telah dinonaktifkan'
                        : 'Ketik pesan Anda...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  enabled: isEnabled,
                ),
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // Send Icon Button
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.bgCard,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
