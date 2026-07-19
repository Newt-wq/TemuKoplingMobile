import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

/// Tombol-tombol kontrol peta (Back, Refresh, Center to User).
class MapControlButtons extends StatelessWidget {
  final double topPadding;
  final LatLng? userLocation;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;
  final VoidCallback onCenterToUser;

  const MapControlButtons({
    super.key,
    required this.topPadding,
    required this.userLocation,
    this.onBack,
    required this.onRefresh,
    required this.onCenterToUser,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left: Back + Refresh
        Positioned(
          left: 16,
          top: topPadding + 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primaryBrown,
                    size: 22,
                  ),
                  onPressed: () {
                    if (onBack != null) {
                      onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  tooltip: 'Kembali',
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryBrown,
                    size: 22,
                  ),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
        ),

        // Right: Center to user
        Positioned(
          right: 16,
          top: topPadding + 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: userLocation != null
                    ? AppColors.googleBlue
                    : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: onCenterToUser,
              tooltip: 'Ke lokasi saya',
            ),
          ),
        ),
      ],
    );
  }
}
