import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../services/profile_manager.dart';

class TrackingPage extends StatefulWidget {
  final void Function(Map<String, dynamic> riderInfo)? onNavigateToChat;
  final VoidCallback? onBack;
  const TrackingPage({super.key, this.onNavigateToChat, this.onBack});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> with SingleTickerProviderStateMixin {
  String? _selectedRiderId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeRiders = [];
  List<Map<String, dynamic>> _rawRidersList = []; // Simpan data mentah dari stream
  StreamSubscription<List<Map<String, dynamic>>>? _ridersSubscription;
  Timer? _staleCleanupTimer;

  // Filter & Search active riders (seperti di web)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua' atau 'Terdekat'
  bool _isListExpanded = false;

  // Lokasi User
  LatLng? _userLocation;
  StreamSubscription<Position>? _locationSubscription;
  final MapController _mapController = MapController();
  bool _hasCenteredOnUser = false;

  // Pulse animation untuk marker kurir (seperti ngetem-pulse di web)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  double get _topPadding {
    try {
      final padding = MediaQuery.maybePaddingOf(context);
      if (padding != null) {
        return padding.top > 0 ? padding.top : 24.0;
      }
    } catch (_) {}
    return 24.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialRiders();
    _subscribeToRiders();
    _startLocationTracking();
    _startStaleCleanupTimer();

    // Setup pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);
  }

  Future<void> _fetchInitialRiders() async {
    try {
      final response = await Supabase.instance.client
          .from('active_riders')
          .select();
      if (mounted) {
        setState(() {
          _rawRidersList = List<Map<String, dynamic>>.from(response);
          _updateActiveRidersList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching initial riders: $e");
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      if (kIsWeb) {
        // Di web: ambil posisi sekali saja
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 10));
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_userLocation!, 14.0);
        }
      } else {
        // Di mobile: stream posisi realtime
        _locationSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
            });
            if (!_hasCenteredOnUser) {
              _hasCenteredOnUser = true;
              _mapController.move(_userLocation!, 14.0);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Location tracking not available: $e");
    }
  }

  void _centerToUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  void _startStaleCleanupTimer() {
    _staleCleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateActiveRidersList();
      }
    });
  }

  void _updateActiveRidersList() {
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> filtered = [];

    for (final rider in _rawRidersList) {
      // 1. Status harus 'online'
      if (rider['status']?.toString().toLowerCase() != 'online') {
        continue;
      }

      // 2. Heartbeat check: maksimal 5 menit tidak kirim lokasi dianggap offline
      final updatedAtStr = rider['updated_at']?.toString() ?? rider['start_time']?.toString();
      if (updatedAtStr != null && updatedAtStr.isNotEmpty) {
        try {
          final updatedAt = DateTime.parse(updatedAtStr).toUtc();
          if (now.difference(updatedAt).inMinutes > 5) {
            // Lewati jika sudah 5 menit tidak update lokasi (stale)
            continue;
          }
        } catch (_) {
          // Tetap masukkan jika parsing tanggal gagal
        }
      }

      filtered.add(rider);
    }

    setState(() {
      _activeRiders = filtered;
      
      // Jika rider yang sedang dipilih tiba-tiba offline/stale, tutup panel detailnya
      if (_selectedRiderId != null) {
        final isStillActive = _activeRiders.any((r) => r['rider_id']?.toString() == _selectedRiderId);
        if (!isStillActive) {
          _selectedRiderId = null;
        }
      }
      });
  }

  Future<void> _manualRefresh() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('active_riders')
          .select();
      
      if (mounted) {
        _rawRidersList = List<Map<String, dynamic>>.from(response);
        _updateActiveRidersList();
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi kurir berhasil diperbarui'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error manually refreshing riders: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRiders() {
    try {
      // Menarik data realtime dari tabel active_riders yang berstatus online
      _ridersSubscription = Supabase.instance.client
          .from('active_riders')
          .stream(primaryKey: ['rider_id'])
          .listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          _rawRidersList = data;
          _updateActiveRidersList();
          setState(() {
            _isLoading = false;
          });
        }
      }, onError: (error) {
        debugPrint("Error streaming active riders: $error");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint("Exception setting up stream: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ridersSubscription?.cancel();
    _locationSubscription?.cancel();
    _staleCleanupTimer?.cancel();
    _pulseController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
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

    final base64Provider = ProfileManager.getProfileImage(logoUrl);
    if (base64Provider != null) {
      return Image(
        image: base64Provider,
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

  Future<void> _onLihatRute(Map<String, dynamic>? rider) async {
    if (rider == null) return;
    final lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
    final lng = double.tryParse(rider['lng'].toString()) ?? 112.7521;
    final url = 'https://www.google.com/maps?daddr=$lat,$lng';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch $url");
      }
    } catch (e) {
      debugPrint("Error launching maps: $e");
    }
  }

  void _onChat(Map<String, dynamic>? rider) {
    if (rider == null) return;
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

  double _getRawDistance(double lat, double lng) {
    try {
      final double myLat = _userLocation?.latitude ?? -7.2575;
      final double myLng = _userLocation?.longitude ?? 112.7521;
      return const Distance().distance(
        LatLng(myLat, myLng),
        LatLng(lat, lng),
      );
    } catch (_) {
      return 999999.0;
    }
  }

  List<Map<String, dynamic>> get _filteredRiders {
    List<Map<String, dynamic>> list = List.from(_activeRiders);

    // 1. Terapkan pencarian (by name, brand, atau landmark/patokan)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((rider) {
        final name = (rider['name']?.toString() ?? '').toLowerCase();
        final brand = (rider['brand']?.toString() ?? '').toLowerCase();
        final landmark = (rider['landmark']?.toString() ?? '').toLowerCase();
        return name.contains(q) || brand.contains(q) || landmark.contains(q);
      }).toList();
    }

    // 2. Terapkan filter terdekat (urutkan berdasarkan jarak)
    if (_selectedFilter == 'Terdekat') {
      list.sort((a, b) {
        final double latA = double.tryParse(a['lat'].toString()) ?? 0.0;
        final double lngA = double.tryParse(a['lng'].toString()) ?? 0.0;
        final double latB = double.tryParse(b['lat'].toString()) ?? 0.0;
        final double lngB = double.tryParse(b['lng'].toString()) ?? 0.0;
        
        final distA = _getRawDistance(latA, lngA);
        final distB = _getRawDistance(latB, lngB);
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  String _getDistanceText(double lat, double lng) {
    try {
      final double myLat = _userLocation?.latitude ?? -7.2575;
      final double myLng = _userLocation?.longitude ?? 112.7521;
      final distance = const Distance().distance(
        LatLng(myLat, myLng),
        LatLng(lat, lng),
      );
      if (distance < 1000) {
        return '${distance.toStringAsFixed(0)} m';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)} km';
      }
    } catch (_) {
      return 'Belum diketahui';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '08:00';
    try {
      final dateTime = DateTime.parse(timeStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '08:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF5C3D2E);
    const Color accentBrown = Color(0xFFA06C46);
    const Color lightTan = Color(0xFFFAF8F5);
    const Color borderTan = Color(0xFFE8DCCB);

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

    // Ambil detail koordinat untuk jarak
    double riderLat = -7.2575;
    double riderLng = 112.7521;
    if (selectedRider != null) {
      riderLat = double.tryParse(selectedRider['lat'].toString()) ?? -7.2575;
      riderLng = double.tryParse(selectedRider['lng'].toString()) ?? 112.7521;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8),
      body: Stack(
        children: [
          // 1. NATIVE FLUTTER MAP
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBrown),
                  );
                }
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(-7.2575, 112.7521),
                    initialZoom: 14.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    onTap: (_, __) => _closePanel(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.temu_kopling',
                      maxZoom: 19,
                    ),
                    // Titik biru lokasi user (seperti GeolocateControl di web) - Digambar di belakang marker
                    if (_userLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _userLocation!,
                            radius: 10,
                            color: const Color(0xFF4285F4),
                            borderStrokeWidth: 3,
                            borderColor: Colors.white,
                            useRadiusInMeter: false,
                          ),
                          CircleMarker(
                            point: _userLocation!,
                            radius: 40,
                            color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                            useRadiusInMeter: false,
                          ),
                        ],
                      ),
                MarkerLayer(
                  markers: _filteredRiders.map((rider) {
                    final lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
                    final lng = double.tryParse(rider['lng'].toString()) ?? 112.7521;
                    final isSelected = _selectedRiderId == rider['rider_id']?.toString();

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          debugPrint("Marker tapped for rider: ${rider['rider_id']}");
                          setState(() {
                            _selectedRiderId = rider['rider_id']?.toString();
                          });
                        },
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? accentBrown : primaryBrown,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSelected ? accentBrown : primaryBrown)
                                            .withValues(alpha: 0.4 * (1.0 - _pulseAnim.value)),
                                        spreadRadius: 15.0 * _pulseAnim.value,
                                        blurRadius: 15.0 * _pulseAnim.value,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: _buildLogo(rider['logo'] ?? ''),
                                  ),
                                ),
                                // Segitiga lancip map pin (tri) mengarah ke bawah, persis seperti web
                                CustomPaint(
                                  size: const Size(16, 12),
                                  painter: TrianglePainter(
                                    color: isSelected ? accentBrown : primaryBrown,
                                  ),
                                ),
                              ],
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

          // TOMBOL BACK (Kiri Atas)
          Positioned(
            left: 16,
            top: _topPadding + 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      color: primaryBrown,
                      size: 22,
                    ),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
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
                    color: Colors.white,
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
                      color: primaryBrown,
                      size: 22,
                    ),
                    onPressed: _manualRefresh,
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            top: _topPadding + 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  color: _userLocation != null ? const Color(0xFF4285F4) : Colors.grey,
                  size: 22,
                ),
                onPressed: _centerToUserLocation,
                tooltip: 'Ke lokasi saya',
              ),
            ),
          ),

          // 3. FLOATING PANEL (SAMA DENGAN WEB POPUP)
          Positioned(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderTan.withOpacity(0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
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
                              border: Border.all(color: primaryBrown.withOpacity(0.1), width: 2),
                            ),
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        border: Border.all(color: const Color(0xFFDCFCE7)),
                                        borderRadius: BorderRadius.circular(100),
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
                                          const SizedBox(width: 4),
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
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentBrown.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    selectedRider?['brand'] ?? 'Brand Kopi',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: accentBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                            onPressed: _closePanel,
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
                          color: lightTan,
                          border: Border.all(color: borderTan.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.location_on,
                              text: 'Patokan lokasi di ',
                              boldText: selectedRider?['landmark'] ?? 'sekitar titik ini',
                            ),
                            Divider(height: 16, thickness: 0.5, color: borderTan.withOpacity(0.5)),
                            _buildInfoRow(
                              icon: Icons.access_time_filled_rounded,
                              text: 'Sudah ngetem sejak pukul ',
                              boldText: '${_formatTime(selectedRider?['start_time'])} WIB',
                            ),
                            Divider(height: 16, thickness: 0.5, color: borderTan.withOpacity(0.5)),
                            _buildInfoRow(
                              icon: Icons.public,
                              text: 'Jaraknya sekitar ',
                              boldText: '${_getDistanceText(riderLat, riderLng)} dari lokasimu',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions: Lihat Rute (Gradient Full-Width)
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B4C36), Color(0xFF5C3D2E)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5C3D2E).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _onLihatRute(selectedRider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: const Text(
                            'Lihat Rute',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                                onPressed: () => _onChat(selectedRider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4A3525),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: accentBrown),
                                label: const Text(
                                  'Chat Rider',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                                  foregroundColor: const Color(0xFF4A3525),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book_rounded, size: 16, color: accentBrown),
                                label: const Text(
                                  'Lihat Menu',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

          // 4. FLOATING ACTIVE RIDERS LIST PANEL (SAMA DENGAN WEB SIDEBAR)
          if (!isPanelOpen)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: _isListExpanded ? 420 : 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderTan.withOpacity(0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                      onTap: () {
                        setState(() {
                          _isListExpanded = !_isListExpanded;
                        });
                      },
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
                                  color: Colors.grey[300],
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
                                        color: primaryBrown,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_activeRiders.length} rider aktif di sekitarmu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isListExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: accentBrown,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Section
                    if (_isListExpanded) ...[
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari rider atau patokan...',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: lightTan,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: borderTan),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: accentBrown, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildFilterChip('Semua'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Terdekat'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Scrollable Rider List
                      Expanded(
                        child: _filteredRiders.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada rider aktif yang cocok.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _filteredRiders.length,
                                itemBuilder: (context, index) {
                                  final rider = _filteredRiders[index];
                                  final double lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
                                  final double lng = double.tryParse(rider['lng'].toString()) ?? 112.7521;
                                  
                                  return Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: borderTan),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setState(() {
                                          _selectedRiderId = rider['rider_id']?.toString();
                                          _isListExpanded = false;
                                        });
                                        _mapController.move(LatLng(lat, lng), 15.0);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Avatar logo
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: lightTan,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: borderTan),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: _buildLogo(rider['logo'] ?? ''),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    rider['name'] ?? 'Kurir',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: primaryBrown,
                                                    ),
                                                  ),
                                                  Text(
                                                    rider['brand'] ?? 'Brand Kopi',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 12, color: accentBrown),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'Berjarak ${_getDistanceText(lat, lng)}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status Tag & Arrow
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0FDF4),
                                                    border: Border.all(color: const Color(0xFFDCFCE7)),
                                                    borderRadius: BorderRadius.circular(12),
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
                                                      const SizedBox(width: 4),
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
                                                const SizedBox(height: 4),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Colors.grey,
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
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text, required String boldText}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFA06C46), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF52525B), height: 1.4),
              children: [
                TextSpan(text: text),
                TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF0E6) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5E3C) : Colors.grey[350]!,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF8B5E3C) : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

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