import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import '../models/chat_model.dart';
import 'chat_bubble.dart';
import 'chat_input_field.dart';

class ChatDetailView extends StatelessWidget {
  final ChatSession session;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final bool isTyping;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onBack;
  final VoidCallback onShowAttachmentBottomSheet;
  final VoidCallback onShowOrderDetails;
  final Widget Function(String avatarPath, String brandName) buildAvatar;

  const ChatDetailView({
    super.key,
    required this.session,
    required this.scrollController,
    required this.messageController,
    required this.isTyping,
    required this.onSendMessage,
    required this.onBack,
    required this.onShowAttachmentBottomSheet,
    required this.onShowOrderDetails,
    required this.buildAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final quickReplies = [
      'Sesuai titik ya mas 👍',
      'Uang pas ya mas 💵',
      'Kopinya jangan terlalu manis ya ☕',
      'Tolong esnya agak dikurangi 🧊',
      'Terima kasih banyak! 🙏',
      'Ditunggu ya mas, terima kasih! 😊',
      'Saya sudah di depan ya mas 📍',
      'Hati-hati di jalan ya mas 🛵',
      'Kembaliannya ambil saja mas/mba 💵',
      'Tolong ditaruh di pagar/meja depan ya 🚪',
      'Oke siap! 👍',
      'Apakah pesanannya sudah sesuai? 🥤',
      'Sedang di jalan ya mas? 🛵',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),

      // Custom Detail AppBar
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBrown),
          onPressed: onBack,
        ),
        title: Row(
          children: [
            // Rider Avatar
            buildAvatar(session.avatarPath, session.brandName),
            const SizedBox(width: 10),

            // Rider Details & Online Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.riderName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.brandName} • ${session.status == 'Selesai' ? 'Offline' : 'Online'}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: session.status == 'Selesai'
                          ? AppColors.textSecondary
                          : AppColors.onlineGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Info Info Button
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.primaryBrown,
              size: 20,
            ),
            onPressed: onShowOrderDetails,
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),

      body: Column(
        children: [
          // Notification Tag for context
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFFE0B2).withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.security, size: 14, color: Colors.orange),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Demi keamanan, hindari transaksi di luar aplikasi Temu Kopling.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Bubbles Area
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: session.messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == session.messages.length) {
                  return ChatTypingIndicator(name: session.riderName);
                }

                final message = session.messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),

          // Vertical Quick Replies (Scrollable)
          if (session.status != 'Selesai')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 13,
                        color: AppColors.primaryBrown,
                      ),
                      SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Pesan Cepat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBrown.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: quickReplies.length,
                    itemBuilder: (context, index) {
                      final reply = quickReplies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => onSendMessage(reply),
                          borderRadius: AppRadius.radiusLg,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: AppRadius.radiusLg,
                              border: Border.all(
                                color: const Color(0xFFEFEBE9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: AppColors.primaryBrown,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    reply,
                                    style: const TextStyle(
                                      color: AppColors.primaryBrown,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          SizedBox(height: AppSpacing.xs),

          // Message Input Field
          ChatInputField(
            controller: messageController,
            isEnabled: session.status != 'Selesai',
            status: session.status,
            onSend: () {
              onSendMessage(messageController.text);
              messageController.clear();
            },
            onAttachmentTap: onShowAttachmentBottomSheet,
          ),
        ],
      ),
    );
  }
}
