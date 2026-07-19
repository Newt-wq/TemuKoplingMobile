import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import '../models/chat_model.dart';
import 'package:temu_kopling_mobile/shared/widgets/wavy_header_clipper.dart';

class ChatListView extends StatelessWidget {
  final List<ChatSession> filteredSessions;
  final String searchQuery;
  final String activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<ChatSession> onSessionTapped;
  final ValueChanged<ChatSession> onDeleteSession;
  final Widget Function(String avatarPath, String brandName) buildAvatar;

  const ChatListView({
    super.key,
    required this.filteredSessions,
    required this.searchQuery,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSessionTapped,
    required this.onDeleteSession,
    required this.buildAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: Stack(
        children: [
          // Elegant wavy background header matching Home & Favorite page style
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
              color: AppColors.bgWave,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Titles
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obrolan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Hubungi rider kopling untuk koordinasi pesananmu',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: AppRadius.radiusPill,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari rider atau brand kopi...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primaryBrown,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.md),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: ['Semua', 'Sedang Aktif', 'Selesai'].map((
                      filter,
                    ) {
                      final isSelected = activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              onFilterChanged(filter);
                            }
                          },
                          selectedColor: AppColors.primaryBrown,
                          backgroundColor: AppColors.bgCard,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.bgCard
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusXxxl,
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: AppSpacing.sm),

                // Chat Items List
                Expanded(
                  child: filteredSessions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
                            return _buildDismissibleChatCard(context, session);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppColors.primaryBrown,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            const Text(
              'Tidak Ada Obrolan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBrown,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              searchQuery.isNotEmpty
                  ? 'Tidak ada rider yang cocok dengan "$searchQuery"'
                  : 'Belum ada obrolan aktif. Riwayat chat akan muncul saat Anda memesan kopi!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleChatCard(BuildContext context, ChatSession session) {
    return Dismissible(
      key: Key('chat_${session.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCard),
            title: const Text(
              'Hapus Obrolan?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Obrolan dengan ${session.riderName} akan dihapus secara permanen.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmed = false;
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.badgeRed,
                  foregroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (direction) => onDeleteSession(session),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.badgeRed,
          borderRadius: AppRadius.radiusXxl,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: AppColors.bgCard, size: 26),
            SizedBox(height: AppSpacing.xxs),
            Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.bgCard,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _buildChatItemCard(session),
    );
  }

  Widget _buildChatItemCard(ChatSession session) {
    final lastMsg = session.messages.isNotEmpty
        ? session.messages.last.text
        : '';
    final hasUnread = session.unreadCount > 0;

    return Card(
      color: AppColors.bgCard,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusXxl,
        side: BorderSide(color: AppColors.textSecondary),
      ),
      child: InkWell(
        onTap: () => onSessionTapped(session),
        borderRadius: AppRadius.radiusXxl,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  buildAvatar(session.avatarPath, session.brandName),
                  if (session.status != 'Selesai')
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgCard, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: AppSpacing.md),

              // Title and Message details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session.riderName,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        Text(
                          session.lastMessageTime,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: hasUnread
                                ? AppColors.primaryBrown
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.brandName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: hasUnread
                                  ? Colors.black87
                                  : Colors.black45,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Unread Badge
              if (hasUnread) ...[
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${session.unreadCount}',
                    style: const TextStyle(
                      color: AppColors.bgCard,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
