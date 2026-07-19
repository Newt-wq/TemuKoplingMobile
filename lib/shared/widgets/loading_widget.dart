import 'package:flutter/material.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final bool centered;
  final Color? color;
  final double strokeWidth;

  const LoadingWidget({
    super.key,
    this.centered = true,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: color ?? AppColors.primaryBrown,
      strokeWidth: strokeWidth,
    );

    if (centered) {
      return Center(child: indicator);
    }
    return indicator;
  }
}
