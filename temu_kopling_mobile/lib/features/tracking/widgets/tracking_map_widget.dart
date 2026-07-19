import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';

/// Widget peta yang menampilkan marker riders dan lokasi user.
class TrackingMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? userLocation;
  final List<Map<String, dynamic>> filteredRiders;
  final String? selectedRiderId;
  final Animation<double> pulseAnim;
  final void Function(String riderId) onMarkerTapped;
  final VoidCallback onMapTapped;

  const TrackingMapWidget({
    super.key,
    required this.mapController,
    required this.userLocation,
    required this.filteredRiders,
    required this.selectedRiderId,
    required this.pulseAnim,
    required this.onMarkerTapped,
    required this.onMapTapped,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(-7.2575, 112.7521),
            initialZoom: 14.0,
            minZoom: 3.0,
            maxZoom: 21.0,
            onTap: (_, _) => onMapTapped(),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}?access_token=pk.eyJ1IjoicmxkeW5uIiwiYSI6ImNtcnFkbHQ3eTNxamwyeHNlbHlid3lvdXEifQ.RWhbqX2IppS-TtBpeZvt6g',
              userAgentPackageName: 'com.example.temu_kopling_mobile',
              maxZoom: 21,
              tileDimension: 512,
              zoomOffset: -1,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('❌ Tile load error: $error');
              },
            ),
            // Titik biru lokasi user
            if (userLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLocation!,
                    radius: 10,
                    color: AppColors.googleBlue,
                    borderStrokeWidth: 3,
                    borderColor: AppColors.bgCard,
                    useRadiusInMeter: false,
                  ),
                  CircleMarker(
                    point: userLocation!,
                    radius: 40,
                    color: AppColors.googleBlue.withValues(alpha: 0.15),
                    useRadiusInMeter: false,
                  ),
                ],
              ),
            MarkerLayer(
              markers: filteredRiders.map((rider) {
                final lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
                final lng =
                    double.tryParse(rider['lng'].toString()) ?? 112.7521;
                final isSelected =
                    selectedRiderId == rider['rider_id']?.toString();

                return Marker(
                  point: LatLng(lat, lng),
                  width: 90,
                  height: 80,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      debugPrint(
                        "Marker tapped for rider: ${rider['rider_id']}",
                      );
                      onMarkerTapped(rider['rider_id']?.toString() ?? '');
                    },
                    child: AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (context, child) {
                        final double pulseSize = 16.0 * pulseAnim.value;
                        final double pulseOpacity =
                            0.5 * (1.0 - pulseAnim.value);
                        return SizedBox(
                          width: 90,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Pulse ring (breathing effect)
                              Positioned(
                                top: (64 - (64 + pulseSize)) / 2,
                                left: (90 - (64 + pulseSize)) / 2,
                                child: Container(
                                  width: 64 + pulseSize,
                                  height: 64 + pulseSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          (isSelected
                                                  ? AppColors.accentBrown
                                                  : AppColors.primaryBrown)
                                              .withValues(alpha: pulseOpacity),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                              // Main pin: circle + triangle
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgCard,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accentBrown
                                            : AppColors.primaryBrown,
                                        width: 3.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: AppRadius.radiusFull,
                                      child: _buildLogo(rider['logo'] ?? ''),
                                    ),
                                  ),
                                  // Segitiga lancip (pin pointer)
                                  CustomPaint(
                                    size: const Size(16, 12),
                                    painter: _TrianglePainter(
                                      color: isSelected
                                          ? AppColors.accentBrown
                                          : AppColors.primaryBrown,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for triangle pin pointer.
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
