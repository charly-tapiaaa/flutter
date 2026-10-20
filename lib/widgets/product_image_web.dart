import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class ProductImage extends StatefulWidget {
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
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = _buildViewType(widget.url);
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _viewType = _buildViewType(widget.url);
      _registerViewFactory();
      setState(() {});
    }
  }

  String _buildViewType(String url) =>
      'product-image-${url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final container = web.document.createElement('div') as web.HTMLDivElement
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%')
        ..style.setProperty('display', 'flex')
        ..style.setProperty('align-items', 'center')
        ..style.setProperty('justify-content', 'center')
        ..style.setProperty('overflow', 'hidden');
      final image = web.document.createElement('img') as web.HTMLImageElement
        ..src = widget.url
        ..alt = 'Imagen del producto'
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%')
        ..style.setProperty('object-fit', _objectFit);

      image.addEventListener(
        'error',
        ((web.Event _) {
          container.textContent = 'Imagen no disponible';
          container.style.setProperty('color', '#68736E');
          container.style.setProperty('font', '14px sans-serif');
        }).toJS,
      );
      container.append(image);
      return container;
    });
  }

  String get _objectFit => switch (widget.fit) {
        BoxFit.cover => 'cover',
        BoxFit.fill => 'fill',
        BoxFit.none => 'none',
        BoxFit.scaleDown => 'scale-down',
        _ => 'contain',
      };

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: ValueKey(_viewType),
      viewType: _viewType,
    );
  }
}
