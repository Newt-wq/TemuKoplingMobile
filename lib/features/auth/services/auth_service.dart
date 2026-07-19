import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Handles user login and profile synchronization
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Gagal masuk: Pengguna tidak ditemukan.');
    }

    // Fetch profile to match data
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    // Check if profile exists and if role is rider
    final role =
        profile?['role'] ?? response.user!.userMetadata?['role'] ?? 'customer';
    if (role == 'rider') {
      await _supabase.auth.signOut();
      throw const AuthException(
        'Gagal login: Akun ini terdaftar sebagai Rider. Silakan login di web/aplikasi Rider.',
      );
    }

    // Sync to ProfileManager
    final nameToSave =
        profile?['name'] ?? response.user!.userMetadata?['name'] ?? 'Pelanggan';
    final phoneToSave = profile?['phone'] ?? '';
    final imageToSave =
        profile?['logo'] ?? response.user!.userMetadata?['logo'];

    await ProfileManager().updateProfile(
      name: nameToSave,
      email: response.user!.email ?? email,
      phone: phoneToSave,
      profileImage: imageToSave,
    );
  }

  /// Handles user registration and inserts profile data
  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw const AuthException('Password minimal 6 karakter.');
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': 'customer'},
    );

    if (response.user != null) {
      // Manual sync to profiles table
      try {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'role': 'customer',
        });
      } catch (e) {
        // Ignore error if database trigger is already running
        debugPrint(
          "Info: Gagal manual sync profile (mungkin sudah ada trigger): $e",
        );
      }
    }
  }
}
