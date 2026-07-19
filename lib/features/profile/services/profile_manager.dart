import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileManager extends ChangeNotifier {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;

  /// Mendekode string base64 menjadi ImageProvider secara aman (try-catch)
  static ImageProvider? getProfileImage(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      String cleanBase64 = base64String.trim();
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      final bytes = base64Decode(cleanBase64);
      if (bytes.isEmpty) return null;
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("Error decoding base64 image: $e");
      return null;
    }
  }

  ProfileManager._internal() {
    _loadFromPrefs();
  }

  String _name = 'Budi Sudarsono';
  String _email = 'pengguna@email.com';
  String _phone = '+62 812-3456-7890';
  String? _profileImage; // Menyimpan data foto dalam format base64 string

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String? get profileImage => _profileImage;

  /// Memuat data profil dari penyimpanan lokal (SharedPreferences)
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('profile_name') ?? 'Budi Sudarsono';
      _email = prefs.getString('profile_email') ?? 'pengguna@email.com';
      _phone = prefs.getString('profile_phone') ?? '+62 812-3456-7890';
      _profileImage = prefs.getString('profile_image');
      notifyListeners();

      // Coba fetch dari Supabase secara asinkron jika ada session aktif
      _syncFromSupabase();
    } catch (e) {
      debugPrint("Error loading profile from SharedPreferences: $e");
    }
  }

  /// Sinkronisasi data profil dari tabel Supabase jika user sedang login
  Future<void> _syncFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profile != null) {
          _name = profile['name'] ?? _name;
          _email = currentUser.email ?? _email;
          _phone = profile['phone'] ?? _phone;
          _profileImage = profile['logo'] ?? _profileImage;

          // Simpan ulang ke prefs agar cache terupdate
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_name', _name);
          await prefs.setString('profile_email', _email);
          await prefs.setString('profile_phone', _phone);
          if (_profileImage != null) {
            await prefs.setString('profile_image', _profileImage!);
          }

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Failed to sync profile from Supabase: $e");
    }
  }

  /// Memperbarui data profil secara lokal dan menyimpannya ke SharedPreferences
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? profileImage,
  }) async {
    _name = name;
    _email = email;
    _phone = phone;
    _profileImage = profileImage;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name);
      await prefs.setString('profile_email', email);
      await prefs.setString('profile_phone', phone);
      if (profileImage != null && profileImage.isNotEmpty) {
        await prefs.setString('profile_image', profileImage);
      } else {
        await prefs.remove('profile_image');
      }
    } catch (e) {
      debugPrint("Error saving profile to SharedPreferences: $e");
    }
  }
}
