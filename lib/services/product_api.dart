import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductApi {
  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _productsUri = Uri.parse(
    'https://fakestoreapi.com/products/',
  );
  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Future<List<Product>> fetchProducts({String? category}) async {
    final uri = switch (category) {
      null => _productsUri,
      _ => _productsUri.resolve(
          'category/${Uri.encodeComponent(
            category.trim().replaceAll(RegExp(r'\s+'), ' '),
          )}',
        ),
    };
    final response = await _send(() => _client.get(uri));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const ApiException(
        'La respuesta del catálogo tiene un formato inválido.',
      );
    }

    try {
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Un producto tiene un formato inválido.',
              );
            }
            return Product.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException('No se pudo leer el catálogo: ${error.message}');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await _send(
      () => _client.post(
        _productsUri,
        headers: _headers,
        body: jsonEncode(product.toJson()),
      ),
    );
    return _productFromResponse(response);
  }

  Future<Product> updateProduct(Product product) async {
    final response = await _send(
      () => _client.put(
        _productsUri.resolve('${product.id}'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      ),
    );
    return _productFromResponse(response);
  }

  Future<void> deleteProduct(int id) async {
    await _send(() => _client.delete(_productsUri.resolve('$id')));
  }

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'La API respondió con el código ${response.statusCode}.',
        );
      }
      return response;
    } on TimeoutException {
      throw const ApiException(
        'La solicitud tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on http.ClientException catch (error) {
      throw ApiException('No se pudo conectar con la API: ${error.message}');
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('La API devolvió una respuesta ilegible.');
    }
  }

  Product _productFromResponse(http.Response response) {
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'La API devolvió un producto con formato inválido.',
      );
    }
    try {
      return Product.fromJson(decoded);
    } on FormatException catch (error) {
      throw ApiException('No se pudo confirmar el producto: ${error.message}');
    }
  }
}
