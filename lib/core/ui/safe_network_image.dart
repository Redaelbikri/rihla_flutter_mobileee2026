import 'package:flutter/material.dart';

import '../config/app_config.dart';

String resolveImageUrl(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;

  final base = AppConfig.baseUrl.endsWith('/')
      ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
      : AppConfig.baseUrl;

  final path = v.startsWith('/') ? v : '/$v';
  return '$base$path';
}

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(imageUrl);
    if (url.isEmpty) {
      return placeholder ?? _defaultPlaceholder(context);
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(context),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder ?? _defaultPlaceholder(context);
      },
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary.withOpacity(0.10);
    return Container(color: c);
  }
}
