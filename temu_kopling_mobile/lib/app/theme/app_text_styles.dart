import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_colors.dart';

/// Centralized text styles for the Temu Kopling app.
///
/// Warna tidak di-hardcode agar bisa di-override via `.copyWith(color: ...)`.
/// Default color: [AppColors.textPrimary].
class AppTextStyles {
  AppTextStyles._();

  /// 28px, bold — Judul besar (auth screen headers)
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// 20px, bold — Section header
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 18px, bold — Sub-section header
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 16px, bold — Subtitle / nama user
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 15px, bold — Harga total
  static const TextStyle priceLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBrown,
  );

  /// 14px, normal — Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  /// 14px, bold — Body text bold
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 13px, bold — Menu name, item list
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 13px, w500 — Order item text
  static const TextStyle bodySmallMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// 12.5px, normal — Deskripsi empty state
  static const TextStyle description = TextStyle(fontSize: 12.5, height: 1.4);

  /// 12px, normal — Caption text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  /// 12px, bold — Caption text bold
  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 12px, w500 — Greeting text
  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// 12px, bold — Input field label
  static const TextStyle inputLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textLabel,
  );

  /// 11px, normal — Small text (date, status)
  static const TextStyle small = TextStyle(
    fontSize: 11,
    color: AppColors.textPrimary,
  );

  /// 11px, bold — Small text bold
  static const TextStyle smallBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// 10px, normal — Tiny text (brand filter label)
  static const TextStyle tiny = TextStyle(fontSize: 10);

  /// 10px, bold — Tiny text bold
  static const TextStyle tinyBold = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  /// 8px, bold — Brand badge on menu card
  static const TextStyle brandBadge = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.bold,
  );

  /// 16px, bold, white — Button text
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// 12px, bold — Small button text
  static const TextStyle buttonTextSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
}
