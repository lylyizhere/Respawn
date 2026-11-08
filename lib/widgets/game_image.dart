import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameImage extends StatelessWidget {
  const GameImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    required this.placeholder,
    required this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget placeholder;
  final Widget errorWidget;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // CachedNetworkImage has no web cache; use Flutter's network image cache.
      return Image.network(
        imageUrl,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          return progress == null ? child : placeholder;
        },
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => errorWidget,
    );
  }
}
