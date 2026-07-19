import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/tracking/services/tracking_service.dart';
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';
import 'package:latlong2/latlong.dart';

/// Panel daftar rider aktif yang muncul di bagian bawah ketika tidak ada rider yang dipilih.
class RiderListSheet extends StatelessWidget {
  final bool isExpanded;
  final int activeRidersCount;
  final List<Map<String, dynamic>> filteredRiders;
  final LatLng? userLocation;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedFilter;
  final VoidCallback onToggleExpanded;
  final void Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final void Function(String) onFilterChanged;
  final void Function(String riderId, double lat, double lng) onRiderTapped;

  const RiderListSheet({
    super.key,
    required this.isExpanded,
    required this.activeRidersCount,
    required this.filteredRiders,
    required this.userLocation,
    required this.searchController,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onToggleExpanded,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onRiderTapped,
  });

  Widget _buildLogo(String logoUrl) {
    if (logoUrl.isEmpty) {
      return const Icon(Icons.coffee, color: Colors.brown, size: 20);
    }
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.coffee, color: Colors.brown, size: 20),
      );
    }
    final base64Provider = ProfileManager.getProfileImage(logoUrl);
    if (base64Provider != null) {
      return Image(
        image: base64Provider,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.coffee, color: Colors.brown, size: 20),
      );
    }
    String path = logoUrl;
    if (path.startsWith('/')) path = path.substring(1);
    if (!path.startsWith('assets/')) path = 'assets/$path';
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) =>
          const Icon(Icons.coffee, color: Colors.brown, size: 20),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF0E6) : AppColors.bgCard,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5E3C)
                : AppColors.textSecondary,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: AppRadius.radiusCard,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF8B5E3C)
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: isExpanded ? 420 : 120,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.radiusCard,
          border: Border.all(color: AppColors.borderTan.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag/Toggle Handle & Header
            GestureDetector(
              onTap: onToggleExpanded,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cari Rider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$activeRidersCount rider aktif di sekitarmu',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: AppColors.accentBrown,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Section
            if (isExpanded) ...[
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari rider atau patokan...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: onClearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.lightTan,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.radiusLg,
                        borderSide: const BorderSide(
                          color: AppColors.borderTan,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.radiusLg,
                        borderSide: const BorderSide(
                          color: AppColors.accentBrown,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Terdekat'),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Scrollable Rider List
              Expanded(
                child: filteredRiders.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada rider aktif yang cocok.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredRiders.length,
                        itemBuilder: (context, index) {
                          final rider = filteredRiders[index];
                          final double lat =
                              double.tryParse(rider['lat'].toString()) ??
                              -7.2575;
                          final double lng =
                              double.tryParse(rider['lng'].toString()) ??
                              112.7521;

                          return Card(
                            color: AppColors.bgCard,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusLg,
                              side: const BorderSide(
                                color: AppColors.borderTan,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: AppRadius.radiusLg,
                              onTap: () => onRiderTapped(
                                rider['rider_id']?.toString() ?? '',
                                lat,
                                lng,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar logo
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightTan,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderTan,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: AppRadius.radiusCard,
                                        child: _buildLogo(rider['logo'] ?? ''),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.md),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rider['name'] ?? 'Kurir',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.primaryBrown,
                                            ),
                                          ),
                                          Text(
                                            rider['brand'] ?? 'Brand Kopi',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.xxs),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: AppColors.accentBrown,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Berjarak ${TrackingService.getDistanceText(userLocation, lat, lng)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Tag & Arrow
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
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
                                            borderRadius: AppRadius.radiusLg,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              SizedBox(width: AppSpacing.xxs),
                                              const Text(
                                                'Ngetem',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.xxs),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}
