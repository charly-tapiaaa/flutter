import 'dart:convert';

import 'package:examen_ecomerce/models/product.dart';
import 'package:examen_ecomerce/services/product_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('product API reads and performs catalog operations', () async {
    final requests = <String>[];
    final api = ProductApi(
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        final responseProduct = <String, dynamic>{
          'id': request.method == 'POST' ? 21 : 1,
          'title': 'Producto de prueba',
          'price': 12.5,
          'description': 'Una descripción de prueba suficientemente larga.',
          'category': 'electronics',
          'image': 'https://example.com/product.jpg',
        };

        if (request.method == 'GET') {
          return http.Response(jsonEncode([responseProduct]), 200);
        }
        return http.Response(
          jsonEncode(responseProduct),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );

    final products = await api.fetchProducts();
    expect(products, hasLength(1));
    expect(products.single.title, 'Producto de prueba');

    const product = Product(
      id: 1,
      title: 'Producto de prueba',
      price: 12.5,
      description: 'Una descripción de prueba suficientemente larga.',
      category: 'electronics',
      image: 'https://example.com/product.jpg',
    );
    final created = await api.createProduct(product);
    expect(created.id, 21);
    final updated = await api.updateProduct(product);
    expect(updated.id, 1);
    await api.deleteProduct(1);

    expect(requests, [
      'GET /products/',
      'POST /products/',
      'PUT /products/1',
      'DELETE /products/1',
    ]);
  });

  test('product API requests products from the selected category', () async {
    Uri? requestedUri;
    final api = ProductApi(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode([
            {
              'id': 9,
              'title': 'Disco externo',
              'price': 59.99,
              'description': 'Disco externo de almacenamiento.',
              'category': 'electronics',
              'image': 'https://example.com/drive.jpg',
            },
          ]),
          200,
        );
      }),
    );

    final products = await api.fetchProducts(category: 'electronics');

    expect(requestedUri?.path, '/products/category/electronics');
    expect(products, hasLength(1));
    expect(products.single.category, 'electronics');
  });
}
