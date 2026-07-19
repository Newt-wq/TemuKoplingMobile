import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/tracking/services/tracking_service.dart';
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';
import 'package:latlong2/latlong.dart';

/// Panel detail rider yang tampil di bawah layar saat marker dipilih.
class RiderDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? selectedRider;
  final bool isPanelOpen;
  final LatLng? userLocation;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic>? rider) onLihatRute;
  final void Function(Map<String, dynamic>? rider) onChat;
  final void Function(Map<String, dynamic>? rider) onLihatMenu;

  const RiderDetailPanel({
    super.key,
    required this.selectedRider,
    required this.isPanelOpen,
    required this.userLocation,
    required this.onClose,
    required this.onLihatRute,
    required this.onChat,
    required this.onLihatMenu,
  });

  Widget _buildLogo(String logoUrl) {
    if (logoUrl.isEmpty) {
      return const Icon(Icons.coffee, color: Colors.brown, size: 20);
    }

    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.coffee, color: Colors.brown, size: 20),
      );
    }

    final base64Provider = ProfileManager.getProfileImage(logoUrl);
    if (base64Provider != null) {
      return Image(
        image: base64Provider,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.coffee, color: Colors.brown, size: 20),
      );
    }

    String path = logoUrl;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (!path.startsWith('assets/')) {
      path = 'assets/$path';
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.coffee, color: Colors.brown, size: 20);
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required String boldText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accentBrown, size: 16),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF52525B),
                height: 1.4,
              ),
              children: [
                TextSpan(text: text),
                TextSpan(
                  text: boldText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double riderLat =
        double.tryParse(selectedRider?['lat']?.toString() ?? '') ?? -7.2575;
    final double riderLng =
        double.tryParse(selectedRider?['lng']?.toString() ?? '') ?? 112.7521;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        offset: isPanelOpen ? Offset.zero : const Offset(0, 1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isPanelOpen ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.radiusCard,
              border: Border.all(
                color: AppColors.borderTan.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Avatar, Nama, Status & Close Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBrown.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.radiusPill,
                        child: _buildLogo(selectedRider?['logo'] ?? ''),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedRider?['name'] ?? 'Kurir Kopi',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF18181B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  border: Border.all(
                                    color: const Color(0xFFDCFCE7),
                                  ),
                                  borderRadius: AppRadius.radiusCircle,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.xxs),
                                    const Text(
                                      'NGETEM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentBrown.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppRadius.radiusXs,
                            ),
                            child: Text(
                              selectedRider?['brand'] ?? 'Brand Kopi',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Info Card: Landmark, Waktu, Jarak
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightTan,
                    border: Border.all(
                      color: AppColors.borderTan.withValues(alpha: 0.4),
                    ),
                    borderRadius: AppRadius.radiusXl,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on,
                        text: 'Patokan lokasi di ',
                        boldText:
                            selectedRider?['landmark'] ?? 'sekitar titik ini',
                      ),
                      Divider(
                        height: 16,
                        thickness: 0.5,
                        color: AppColors.borderTan.withValues(alpha: 0.5),
                      ),
                      _buildInfoRow(
                        icon: Icons.access_time_filled_rounded,
                        text: 'Sudah ngetem sejak pukul ',
                        boldText:
                            '${TrackingService.formatTime(selectedRider?['start_time'])} WIB',
                      ),
                      Divider(
                        height: 16,
                        thickness: 0.5,
                        color: AppColors.borderTan.withValues(alpha: 0.5),
                      ),
                      _buildInfoRow(
                        icon: Icons.public,
                        text: 'Jaraknya sekitar ',
                        boldText:
                            '${TrackingService.getDistanceText(userLocation, riderLat, riderLng)} dari lokasimu',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Actions: Lihat Rute (Gradient Full-Width)
                Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.radiusLg,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4C36), AppColors.primaryBrownAuth],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBrownAuth.withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => onLihatRute(selectedRider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.bgCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusLg,
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Lihat Rute',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Actions: Chat & Lihat Menu
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => onChat(selectedRider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A3525),
                            side: BorderSide(color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusLg,
                            ),
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppColors.accentBrown,
                          ),
                          label: const Text(
                            'Chat Rider',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => onLihatMenu(selectedRider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A3525),
                            side: BorderSide(color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusLg,
                            ),
                          ),
                          icon: const Icon(
                            Icons.menu_book_rounded,
                            size: 16,
                            color: AppColors.accentBrown,
                          ),
                          label: const Text(
                            'Lihat Menu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
