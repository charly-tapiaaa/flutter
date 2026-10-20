import 'dart:async';
import 'dart:convert';

import 'package:examen_ecomerce/main.dart';
import 'package:examen_ecomerce/screens/login_screen.dart';
import 'package:examen_ecomerce/screens/product_catalog_screen.dart';
import 'package:examen_ecomerce/services/product_api.dart';
import 'package:examen_ecomerce/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('login requires a username and password', (tester) async {
    await tester.pumpWidget(const StoreApp());
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });

  testWidgets('login rejects credentials that do not match', (tester) async {
    await tester.pumpWidget(const StoreApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'incorrecto');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('demo credentials open the product catalog', (tester) async {
    final api = ProductApi(
      client: MockClient((request) async => http.Response('[]', 200)),
    );
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Tu catálogo'), findsOneWidget);
    expect(find.text('0 productos disponibles'), findsOneWidget);
  });

  testWidgets('new product appears before the API request completes', (
    tester,
  ) async {
    final postResponse = Completer<http.Response>();
    var postRequested = false;
    final api = ProductApi(
      client: MockClient((request) async {
        if (request.method == 'GET') return http.Response('[]', 200);
        postRequested = true;
        return postResponse.future;
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCatalogScreen(username: 'admin', api: api),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Camiseta nueva');
    await tester.enterText(find.byType(TextFormField).at(1), '24.99');
    await tester.enterText(find.byType(TextFormField).at(2), 'Ropa');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Camiseta suave para uso diario.',
    );
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'https://example.com/camiseta.jpg',
    );
    await tester.ensureVisible(find.text('Guardar producto'));
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    expect(postRequested, isTrue);
    expect(find.text('Camiseta nueva'), findsOneWidget);
    expect(find.text('1 productos disponibles'), findsOneWidget);

    postResponse.complete(
      http.Response(
        jsonEncode({
          'id': 21,
          'title': 'Camiseta nueva',
          'price': 24.99,
          'description': 'Camiseta suave para uso diario.',
          'category': 'Ropa',
          'image': 'https://example.com/camiseta.jpg',
        }),
        201,
      ),
    );
    await tester.pump();
  });

  testWidgets('selecting a category shows its products and clears search', (
    tester,
  ) async {
    final api = ProductApi(
      client: MockClient((request) async {
        if (request.method != 'GET') return http.Response('{}', 200);
        final products = [
          {
            'id': 1,
            'title': 'Producto de electrónica',
            'price': 20,
            'description': 'Producto de prueba de electrónica.',
            'category': ' Electronics ',
            'image': 'https://example.com/electronics.jpg',
          },
          {
            'id': 2,
            'title': 'Producto de joyería',
            'price': 30,
            'description': 'Producto de prueba de joyería.',
            'category': 'jewelery',
            'image': 'https://example.com/jewelry.jpg',
          },
        ];
        if (request.url.path.endsWith('/category/Electronics')) {
          return http.Response(jsonEncode([products.first]), 200);
        }
        return http.Response(jsonEncode(products), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProductCatalogScreen(username: 'admin', api: api),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'texto sin coincidencias');
    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();

    expect(find.text('Producto de electrónica'), findsOneWidget);
    expect(find.text('Producto de joyería'), findsNothing);
    expect(find.text('texto sin coincidencias'), findsNothing);
    expect(
      find.text('Mostrando 1 de 2 productos · Electronics'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('https://example.com/electronics.jpg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('https://example.com/jewelry.jpg')),
      findsNothing,
    );
    expect(
      tester
          .widget<ProductImage>(
            find.byKey(const ValueKey('https://example.com/electronics.jpg')),
          )
          .url,
      'https://example.com/electronics.jpg',
    );
  });
}
