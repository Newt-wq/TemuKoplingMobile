import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/shared/widgets/loading_widget.dart';
import '../models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = message.isMe
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Color bubbleColor = message.isMe
        ? AppColors.primaryBrown
        : AppColors.bgCard;
    final Color textColor = message.isMe ? AppColors.bgCard : Colors.black87;
    final double leftPadding = message.isMe ? 50 : 0;
    final double rightPadding = message.isMe ? 0 : 50;

    // Formatting timestamp
    final String timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
          right: rightPadding,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // If the message has an image (simulated attach)
            if (message.imageUrl != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.radiusLg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.radiusLg,
                  child: Image.network(
                    message.imageUrl!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 180,
                        height: 180,
                        color: AppColors.textSecondary,
                        child: const Center(child: LoadingWidget()),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Standard Text bubble
            if (message.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                    bottomRight: Radius.circular(message.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    if (!message.isMe)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),

            const SizedBox(height: 3),

            // Time & Read Status Ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (message.isMe) ...[
                  SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.done_all,
                    size: 13,
                    color: AppColors
                        .primaryBrown, // Colored brown to represent "Read" status
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTypingIndicator extends StatelessWidget {
  final String name;

  const ChatTypingIndicator({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 50, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$name sedang mengetik',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: LoadingWidget(strokeWidth: 1.5, centered: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
