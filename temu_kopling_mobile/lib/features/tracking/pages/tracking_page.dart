import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/shared/widgets/loading_widget.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../services/tracking_service.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/rider_menu_sheet.dart';
import '../widgets/map_control_buttons.dart';
import '../widgets/rider_detail_panel.dart';
import '../widgets/rider_list_sheet.dart';

class TrackingPage extends StatefulWidget {
  final void Function(Map<String, dynamic> riderInfo)? onNavigateToChat;
  final VoidCallback? onBack;
  const TrackingPage({super.key, this.onNavigateToChat, this.onBack});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with SingleTickerProviderStateMixin {
  String? _selectedRiderId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeRiders = [];
  List<Map<String, dynamic>> _rawRidersList = [];
  StreamSubscription<List<Map<String, dynamic>>>? _ridersSubscription;
  Timer? _staleCleanupTimer;

  // Filter & Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  bool _isListExpanded = false;

  // Lokasi User
  LatLng? _userLocation;
  StreamSubscription<Position>? _locationSubscription;
  final MapController _mapController = MapController();
  bool _hasCenteredOnUser = false;

  // Pulse animation
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  // ───────────────────────────────────────────────
  // Business Logic (delegated to TrackingService)
  // ───────────────────────────────────────────────

  Future<void> _fetchInitialRiders() async {
    try {
      final response = await TrackingService.fetchRiders();
      if (mounted) {
        setState(() {
          _rawRidersList = List<Map<String, dynamic>>.from(response);
          _activeRiders = TrackingService.filterActiveRiders(_rawRidersList, userLocation: _userLocation);
          _validateSelectedRider();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching initial riders: $e");
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      if (kIsWeb) {
        final position = await TrackingService.getUserPosition();
        if (position != null && mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            _activeRiders = TrackingService.filterActiveRiders(
              _rawRidersList,
              userLocation: _userLocation,
            );
            _validateSelectedRider();
          });
          _mapController.move(_userLocation!, 14.0);
        }
      } else {
        final position = await TrackingService.getUserPosition();
        // getUserPosition returns null for mobile → use stream
        if (position == null) {
          _locationSubscription = TrackingService.userPositionStream().listen((
            Position pos,
          ) {
            if (mounted) {
              setState(() {
                _userLocation = LatLng(pos.latitude, pos.longitude);
                _activeRiders = TrackingService.filterActiveRiders(
                  _rawRidersList,
                  userLocation: _userLocation,
                );
                _validateSelectedRider();
              });
              if (!_hasCenteredOnUser) {
                _hasCenteredOnUser = true;
                _mapController.move(_userLocation!, 14.0);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Location tracking not available: $e");
    }
  }

  void _startStaleCleanupTimer() {
    _staleCleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _activeRiders = TrackingService.filterActiveRiders(_rawRidersList, userLocation: _userLocation);
          _validateSelectedRider();
        });
      }
    });
  }

  void _subscribeToRiders() {
    try {
      _ridersSubscription = TrackingService.ridersStream().listen(
        (data) {
          if (mounted) {
            _rawRidersList = data;
            setState(() {
              _activeRiders = TrackingService.filterActiveRiders(
                _rawRidersList,
                userLocation: _userLocation,
              );
              _validateSelectedRider();
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          debugPrint("Error streaming active riders: $error");
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint("Exception setting up stream: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _validateSelectedRider() {
    if (_selectedRiderId != null) {
      final isStillActive = _activeRiders.any(
        (r) => r['rider_id']?.toString() == _selectedRiderId,
      );
      if (!isStillActive) _selectedRiderId = null;
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isLoading = true);
    try {
      final response = await TrackingService.fetchRiders();
      if (mounted) {
        _rawRidersList = List<Map<String, dynamic>>.from(response);
        setState(() {
          _activeRiders = TrackingService.filterActiveRiders(_rawRidersList, userLocation: _userLocation);
          _validateSelectedRider();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _centerToUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  // ───────────────────────────────────────────────
  // Actions
  // ───────────────────────────────────────────────

  Future<void> _onLihatRute(Map<String, dynamic>? rider) async {
    if (rider == null) return;
    final lat = double.tryParse(rider['lat'].toString()) ?? -7.2575;
    final lng = double.tryParse(rider['lng'].toString()) ?? 112.7521;

    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final String geoUrl = 'geo:$lat,$lng?q=$lat,$lng';

    try {
      final Uri geoUri = Uri.parse(geoUrl);
      final Uri webUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24, // beri jarak dari atas
          ),
          child: RiderMenuSheet(rider: rider),
        );
      },
    );
  }

  void _closePanel() {
    setState(() => _selectedRiderId = null);
  }

  // ───────────────────────────────────────────────
  // Filter logic
  // ───────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredRiders {
    List<Map<String, dynamic>> list = List.from(_activeRiders);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((rider) {
        final name = (rider['name']?.toString() ?? '').toLowerCase();
        final brand = (rider['brand']?.toString() ?? '').toLowerCase();
        final landmark = (rider['landmark']?.toString() ?? '').toLowerCase();
        return name.contains(q) || brand.contains(q) || landmark.contains(q);
      }).toList();
    }

    if (_selectedFilter == 'Terdekat') {
      list.sort((a, b) {
        final double latA = double.tryParse(a['lat'].toString()) ?? 0.0;
        final double lngA = double.tryParse(a['lng'].toString()) ?? 0.0;
        final double latB = double.tryParse(b['lat'].toString()) ?? 0.0;
        final double lngB = double.tryParse(b['lng'].toString()) ?? 0.0;
        final distA = TrackingService.getRawDistance(_userLocation, latA, lngA);
        final distB = TrackingService.getRawDistance(_userLocation, latB, lngB);
        return distA.compareTo(distB);
      });
    }

    return list;
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

  // ───────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.bgCream,
      body: Stack(
        children: [
          // 1. MAP
          Positioned.fill(
            child: TrackingMapWidget(
              mapController: _mapController,
              userLocation: _userLocation,
              filteredRiders: _filteredRiders,
              selectedRiderId: _selectedRiderId,
              pulseAnim: _pulseAnim,
              onMarkerTapped: (riderId) {
                setState(() => _selectedRiderId = riderId);
              },
              onMapTapped: _closePanel,
            ),
          ),

          // 2. LOADING OVERLAY
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppColors.bgCard,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingWidget(),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Memuat kurir di sekitar Anda...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. MAP CONTROL BUTTONS
          MapControlButtons(
            topPadding: _topPadding,
            userLocation: _userLocation,
            onBack: widget.onBack,
            onRefresh: _manualRefresh,
            onCenterToUser: _centerToUserLocation,
          ),

          // 4. RIDER DETAIL PANEL
          RiderDetailPanel(
            selectedRider: selectedRider,
            isPanelOpen: isPanelOpen,
            userLocation: _userLocation,
            onClose: _closePanel,
            onLihatRute: _onLihatRute,
            onChat: _onChat,
            onLihatMenu: _onLihatMenu,
          ),

          // 5. RIDER LIST SHEET
          if (!isPanelOpen)
            RiderListSheet(
              isExpanded: _isListExpanded,
              activeRidersCount: _activeRiders.length,
              filteredRiders: _filteredRiders,
              userLocation: _userLocation,
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedFilter: _selectedFilter,
              onToggleExpanded: () {
                setState(() => _isListExpanded = !_isListExpanded);
              },
              onSearchChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onFilterChanged: (label) {
                setState(() => _selectedFilter = label);
              },
              onRiderTapped: (riderId, lat, lng) {
                setState(() {
                  _selectedRiderId = riderId;
                  _isListExpanded = false;
                });
                _mapController.move(LatLng(lat, lng), 15.0);
              },
            ),
        ],
      ),
    );
  }
}
