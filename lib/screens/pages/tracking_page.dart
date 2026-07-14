import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class TrackingPage extends StatefulWidget {
  final void Function(Map<String, dynamic> riderInfo)? onNavigateToChat;
  const TrackingPage({super.key, this.onNavigateToChat});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String? _selectedRiderId;
  bool _isLoading = true;

  // ---------------------------------------------------------------------
  // DUMMY DATA
  // Nanti tinggal diganti balik ke fetch dari Supabase kalau sudah siap.
  // ---------------------------------------------------------------------
  final List<Map<String, dynamic>> _activeRiders = [
    {
      'rider_id': '1',
      'name': 'Pak Slamet',
      'brand': 'Kopi Klotok',
      'landmark': 'Depan Gedung Rektorat',
      'logo': '',
      'lat': -7.2575,
      'lng': 112.7521,
    },
    {
      'rider_id': '2',
      'name': 'Mas Dedi',
      'brand': 'Kopi Tjangkir',
      'landmark': 'Taman Bungkul',
      'logo': '',
      'lat': -7.2660,
      'lng': 112.7386,
    },
    {
      'rider_id': '3',
      'name': 'Mang Asep',
      'brand': 'Es Kopi Susu Nyoman',
      'landmark': 'Jl. Raya Darmo',
      'logo': '',
      'lat': -7.2925,
      'lng': 112.7378,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulasi loading singkat sebelum marker muncul di peta
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildLogo(String logoUrl) {
    if (logoUrl.isEmpty) {
      return const Icon(Icons.coffee, color: Colors.brown, size: 20);
    }

    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee, color: Colors.brown, size: 20),
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

  void _onLihatRute(Map<String, dynamic>? rider) {
    if (rider == null) return;
    // TODO: navigasi/gambar rute menuju lokasi rider ini di peta
  }

  void _onChat(Map<String, dynamic>? rider) {
    if (rider == null) return;
    // Kirim data rider lengkap ke MainScreen → ChatPage akan buat sesi baru
    widget.onNavigateToChat?.call({
      'rider_id': rider['rider_id']?.toString() ?? '',
      'name': rider['name'] ?? 'Kurir',
      'brand': rider['brand'] ?? 'Brand Kopi',
      'logo': rider['logo'] ?? '',
      'status': 'Mengantar',
    });
  }

  void _onLihatMenu(Map<String, dynamic>? rider) {
    if (rider == null) return;
    // TODO: navigasi ke halaman menu kopi milik rider ini
  }

  void _closePanel() {
    setState(() {
      _selectedRiderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF4A3324);

    Map<String, dynamic>? selectedRider;
    if (_selectedRiderId != null) {
      try {
        selectedRider = _activeRiders.firstWhere(
          (r) => r['rider_id']?.toString() == _selectedRiderId,
        );
      } catch (_) {
        selectedRider = null;
      }
    }

    final bool isPanelOpen = selectedRider != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8),
      body: Stack(
        children: [
          // 1. NATIVE FLUTTER MAP
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-7.2575, 112.7521),
                initialZoom: 14.0,
                onTap: (_, __) => _closePanel(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.temu_kopling',
                ),
                MarkerLayer(
                  markers: _activeRiders.map((rider) {
                    final lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
                    final lng = double.tryParse(rider['lng'].toString()) ?? 112.7521;
                    final isSelected = _selectedRiderId == rider['rider_id']?.toString();

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRiderId = rider['rider_id']?.toString();
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.brown : primaryBrown,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: _buildLogo(rider['logo'] ?? ''),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isSelected ? Colors.brown : primaryBrown,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 2. LOADING INDICATOR OVERLAY
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryBrown),
                      SizedBox(height: 16),
                      Text(
                        'Memuat kurir di sekitar Anda...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. BOTTOM SHEET PANEL
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              offset: isPanelOpen ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isPanelOpen ? 1 : 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      // Status Kurir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.directions_bike, color: Colors.green, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Riders Sedang Ngetem',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Status: Online',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBrown),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),

                      // Informasi Kurir
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.brown.shade50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _buildLogo(selectedRider?['logo'] ?? ''),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedRider?['name'] ?? 'Kurir Kopi',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBrown),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${selectedRider?['brand'] ?? 'Brand Kopi'} • ${selectedRider?['landmark'] ?? 'Tanpa Landmark'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Tombol Lihat Rute
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _onLihatRute(selectedRider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBrown,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.alt_route, size: 18),
                          label: const Text(
                            'Lihat Rute',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tombol Chat & Lihat Menu
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _onChat(selectedRider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBrown,
                                  side: const BorderSide(color: primaryBrown),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text(
                                  'Chat',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _onLihatMenu(selectedRider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBrown,
                                  side: const BorderSide(color: primaryBrown),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_outlined, size: 16),
                                label: const Text(
                                  'Lihat Menu',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
          ),
        ],
      ),
    );
  }
}