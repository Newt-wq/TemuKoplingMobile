import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

/// Service yang mengelola data riders dari Supabase dan lokasi user.
class TrackingService {
  /// Fetch data riders dari Supabase (one-shot).
  static Future<List<Map<String, dynamic>>> fetchRiders() async {
    final response = await Supabase.instance.client
        .from('active_riders')
        .select();
    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream realtime data riders dari Supabase.
  static Stream<List<Map<String, dynamic>>> ridersStream() {
    return Supabase.instance.client
        .from('active_riders')
        .stream(primaryKey: ['rider_id']);
  }

  /// Filter riders: hanya yang status 'online' dan dalam radius 4 km dari user.
  static List<Map<String, dynamic>> filterActiveRiders(
    List<Map<String, dynamic>> rawList, {
    LatLng? userLocation,
    double maxDistanceKm = 4.0,
  }) {
    final List<Map<String, dynamic>> filtered = [];

    for (final rider in rawList) {
      if (rider['status']?.toString().toLowerCase() != 'online') continue;

      // Filter berdasarkan jarak jika lokasi user tersedia
      if (userLocation != null) {
        final lat = double.tryParse(rider['lat']?.toString() ?? '');
        final lng = double.tryParse(rider['lng']?.toString() ?? '');
        if (lat != null && lng != null) {
          final distance = const Distance().distance(
            userLocation,
            LatLng(lat, lng),
          );
          if (distance > maxDistanceKm * 1000) continue;
        }
      }

      filtered.add(rider);
    }
    return filtered;
  }

  /// Minta permission lokasi dan kembalikan posisi user.
  /// Untuk Web: return posisi sekali. Untuk mobile: return null (gunakan stream).
  static Future<Position?> getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    if (kIsWeb) {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    }
    return null;
  }

  /// Stream posisi user untuk mobile.
  static Stream<Position> userPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Hitung jarak antara dua titik dan return sebagai text.
  static String getDistanceText(LatLng? userLocation, double lat, double lng) {
    try {
      final double myLat = userLocation?.latitude ?? -7.2575;
      final double myLng = userLocation?.longitude ?? 112.7521;
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

  /// Hitung raw distance (meter) untuk sorting.
  static double getRawDistance(LatLng? userLocation, double lat, double lng) {
    try {
      final double myLat = userLocation?.latitude ?? -7.2575;
      final double myLng = userLocation?.longitude ?? 112.7521;
      return const Distance().distance(LatLng(myLat, myLng), LatLng(lat, lng));
    } catch (_) {
      return 999999.0;
    }
  }

  /// Format waktu dari string ISO ke HH:mm.
  static String formatTime(String? timeStr) {
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
}
