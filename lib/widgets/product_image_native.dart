import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    required this.fit,
    required this.placeholderSize,
  });

  final String url;
  final BoxFit fit;
  final double placeholderSize;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Icon(
        Icons.image_not_supported_outlined,
        size: placeholderSize,
        color: const Color(0xFF87918D),
      ),
    );
  }
}
