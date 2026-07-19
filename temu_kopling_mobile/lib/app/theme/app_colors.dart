import 'package:flutter/material.dart';

/// Centralized color constants for the Temu Kopling app.
///
/// Menghilangkan duplikasi warna yang tersebar di seluruh codebase.
class AppColors {
  AppColors._();

  // ===== PRIMARY PALETTE =====
  /// Coklat utama dipakai di home, chat, like, profile, order_history, main_screen
  static const Color primaryBrown = Color(0xFF4A3324);

  /// Coklat utama dipakai di auth screens & tracking (sedikit lebih terang)
  static const Color primaryBrownAuth = Color(0xFF5C3D2E);

  /// Aksen coklat dipakai di auth screens & tracking
  static const Color accentBrown = Color(0xFFA06C46);

  /// Aksen coklat dipakai di profile
  static const Color accentBrownProfile = Color(0xFF7B5544);

  /// Coklat muda dipakai di profile (gradient, badge)
  static const Color lightBrown = Color(0xFFD4A27A);

  /// Tan muda dipakai di home & chat
  static const Color lightTan = Color(0xFFF5E6D3);

  // ===== BACKGROUND =====
  /// Background krem utama (hampir semua halaman)
  static const Color bgCream = Color(0xFFFCFAF8);

  /// Background gelombang header
  static const Color bgWave = Color(0xFFF3EAE1);

  /// Background kartu putih
  static const Color bgCard = Color(0xFFFFFFFF);

  /// Background filter tab order history
  static const Color bgFilterTab = Color(0xFFF5EDE8);

  /// Background chat detail
  static const Color bgChatDetail = Color(0xFFF9F7F5);

  /// Background tan tracking
  static const Color bgTanTracking = Color(0xFFFAF8F5);

  // ===== AUTH GRADIENT =====
  static const Color creamBgStart = Color(0xFFFFFCF8);
  static const Color creamBgMiddle = Color(0xFFF7EFE5);
  static const Color creamBgEnd = Color(0xFFE8DCCB);

  // ===== TEXT =====
  /// Teks utama gelap
  static const Color textPrimary = Color(0xFF2D1F14);

  /// Teks sekunder (coklat muda)
  static const Color textSecondary = Color(0xFF8D6E63);

  /// Teks sangat gelap (judul auth)
  static const Color textDark = Color(0xFF1E1410);

  /// Label input field
  static const Color textLabel = Color(0xFF4A3F35);

  /// Teks body tracking
  static const Color textBody = Color(0xFF52525B);

  /// Teks bold tracking
  static const Color textBold = Color(0xFF18181B);

  // ===== BORDER & DIVIDER =====
  /// Border tan
  static const Color borderTan = Color(0xFFE8DCCB);

  /// Border coklat muda (like page clear button)
  static const Color borderBrownLight = Color(0xFFD7CCC8);

  /// Border chat bubble
  static const Color borderChatBubble = Color(0xFFEFEBE9);

  /// Divider order history
  static const Color dividerLight = Color(0xFFF5EDE8);

  // ===== STATUS COLORS =====
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color statusOrange = Color(0xFFEF6C00);
  static const Color statusRed = Color(0xFFC62828);
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusOrangeBg = Color(0xFFFFF3E0);
  static const Color statusRedBg = Color(0xFFFFEBEE);

  // ===== SEMANTIC =====
  /// Merah untuk hapus/delete
  static const Color deleteRed = Color(0xFFD32F2F);

  /// Merah badge unread chat
  static const Color badgeRed = Color(0xFFE53935);

  /// Hijau online indicator
  static const Color onlineGreen = Color(0xFF4CAF50);

  /// Biru lokasi user (Google Maps style)
  static const Color googleBlue = Color(0xFF4285F4);

  /// Warna animasi wave di like page
  static const Color waveColor = Color(0xFF6B4E3D);

  /// Amber highlight chat
  static const Color chatHighlight = Color(0xFFFFE0B2);

  // ===== TRACKING CHIP =====
  static const Color selectedChipBg = Color(0xFFFAF0E6);
  static const Color selectedChipBorder = Color(0xFF8B5E3C);

  // ===== TRACKING BADGE =====
  static const Color greenBadgeBg = Color(0xFFF0FDF4);
  static const Color greenBadgeBorder = Color(0xFFDCFCE7);

  // ===== TRACKING GRADIENT =====
  static const Color gradientBrownStart = Color(0xFF6B4C36);
  static const Color gradientBrownEnd = Color(0xFF5C3D2E);

  /// Foreground button outline tracking
  static const Color trackingOutlineBtn = Color(0xFF4A3525);

  // ===== BRAND COLORS =====
  static const Color brandBlue = Color(0xFF1565C0);
  static const Color brandPurple = Color(0xFF7B1FA2);
  static const Color brandRed = Color(0xFFD32F2F);

  // ===== PROFILE BADGE =====
  static const Color goldStart = Color(0xFFD4A027);
  static const Color goldEnd = Color(0xFFB8860B);
}
