import 'package:flutter/material.dart';

class CustomWebView extends StatelessWidget {
  final String url;
  const CustomWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('WebView tidak didukung di platform ini'));
  }
}
