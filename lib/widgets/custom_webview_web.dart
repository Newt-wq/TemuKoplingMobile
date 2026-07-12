import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  const CustomWebView({super.key, required this.url});

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'iframe-${widget.url.hashCode}';
    
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      return html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
