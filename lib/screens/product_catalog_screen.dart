import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api.dart';
import '../widgets/product_image.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key, required this.username, this.api});

  final String username;
  final ProductApi? api;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  late final ProductApi _api;
  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product>? _categoryProducts;
  String? _selectedCategory;
  String _search = '';
  bool _isLoading = true;
  bool _isCategoryLoading = false;
  String? _loadError;
  int _categoryRequestGeneration = 0;

  static String _normalizeCategory(String category) =>
      category.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ProductApi();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products.toList();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final categories = _products
        .map((product) => product.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .map((category) => category.trim())
        .toList()
      ..sort((first, second) => first.toLowerCase().compareTo(
        second.toLowerCase(),
      ));
    return categories;
  }

  List<Product> get _filteredProducts {
    final query = _search.trim().toLowerCase();
    final scopedProducts = _categoryScopedProducts;
    final normalizedSelectedCategory = _selectedCategory == null
        ? null
        : _normalizeCategory(_selectedCategory!);

    return scopedProducts
        .where((product) {
          final matchesQuery =
              query.isEmpty ||
              product.title.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
          final matchesCategory = normalizedSelectedCategory == null ||
              _normalizeCategory(product.category) == normalizedSelectedCategory;
          return matchesQuery && matchesCategory;
        })
        .toList(growable: false);
  }

  List<Product> get _categoryScopedProducts {
    final category = _selectedCategory;
    if (category == null) return _products;

    final normalizedCategory = _normalizeCategory(category);

    bool matchesCategory(Product product) =>
        _normalizeCategory(product.category) == normalizedCategory;

    final productsById = {
      for (final product in _categoryProducts ?? _products)
        if (matchesCategory(product)) product.id: product,
    };
    for (final product in _products) {
      if (matchesCategory(product)) {
        productsById[product.id] = product;
      }
    }
    return productsById.values.toList(growable: false);
  }

  void _selectCategory(String? category) {
    final requestGeneration = ++_categoryRequestGeneration;
    _searchController.clear();
    setState(() {
      _search = '';
      _selectedCategory = category;
      _categoryProducts = null;
      _isCategoryLoading = category != null;
    });
    if (category != null) {
      unawaited(_loadCategoryProducts(category, requestGeneration));
    }
  }

  Future<void> _loadCategoryProducts(
    String category,
    int requestGeneration,
  ) async {
    final normalizedCategory = _normalizeCategory(category);
    try {
      final products = await _api.fetchProducts(category: category);
      if (!mounted || requestGeneration != _categoryRequestGeneration) return;
      setState(() {
        _categoryProducts = products
            .where(
              (product) => _normalizeCategory(product.category) == normalizedCategory,
            )
            .toList(growable: false);
        _isCategoryLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestGeneration != _categoryRequestGeneration) return;
      setState(() => _isCategoryLoading = false);
      _showMessage(
        'No se pudo consultar esa categoría en la API. '
        'Se muestran los resultados locales. ${error.message}',
      );
    }
  }

  Future<void> _openForm({Product? product}) async {
    final savedProduct = await Navigator.of(context).push<Product>(
      MaterialPageRoute<Product>(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
    if (savedProduct == null || !mounted) return;

    final productToSave = product == null
        ? Product(
            id: _nextLocalProductId,
            title: savedProduct.title,
            price: savedProduct.price,
            description: savedProduct.description,
            category: savedProduct.category,
            image: savedProduct.image,
          )
        : savedProduct;
    setState(() {
      final index = _products.indexWhere((item) => item.id == productToSave.id);
      if (product == null) {
        _products.insert(0, productToSave);
      } else if (index != -1) {
        _products[index] = productToSave;
      }

      final selectedCategory = _selectedCategory;
      if (selectedCategory != null) {
        final normalizedSelected = _normalizeCategory(selectedCategory);
        final normalizedSaved = _normalizeCategory(productToSave.category);

        if (normalizedSaved == normalizedSelected) {
          final currentIndex = (_categoryProducts ?? []).indexWhere(
            (item) => item.id == productToSave.id,
          );
          if (product == null) {
            _categoryProducts ??= <Product>[];
            if (currentIndex == -1) {
              _categoryProducts = [productToSave, ..._categoryProducts!];
            }
          } else if (currentIndex != -1) {
            _categoryProducts = List<Product>.from(_categoryProducts ?? [])
              ..[currentIndex] = productToSave;
          }
        } else {
          _categoryProducts = _categoryProducts
              ?.where((item) => item.id != productToSave.id)
              .toList(growable: false);
        }
      }
    });
    _showMessage(
      product == null ? 'Producto agregado.' : 'Producto actualizado.',
    );
    if (product == null) {
      unawaited(_syncCreate(productToSave));
    } else if (productToSave.id > 0) {
      unawaited(_syncUpdate(productToSave));
    }
  }

  int get _nextLocalProductId {
    final lowestId = _products
        .where((product) => product.id < 0)
        .fold<int>(
          0,
          (lowest, product) => product.id < lowest ? product.id : lowest,
        );
    return lowestId - 1;
  }

  Future<void> _syncCreate(Product product) async {
    try {
      await _api.createProduct(product);
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(
          'Se guardó en esta sesión, pero no se pudo enviar a la API: ${error.message}',
        );
      }
    }
  }

  Future<void> _syncUpdate(Product product) async {
    try {
      await _api.updateProduct(product);
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(
          'Se actualizó en esta sesión, pero no se pudo enviar a la API: ${error.message}',
        );
      }
    }
  }

  Future<void> _syncDelete(Product product) async {
    try {
      await _api.deleteProduct(product.id);
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(
          'Se eliminó de esta sesión, pero no se pudo enviar a la API: ${error.message}',
        );
      }
    }
  }

  void _openDetails(Product product) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onEdit: () {
            Navigator.of(context).pop();
            _openForm(product: product);
          },
          onDelete: () => _deleteProduct(product),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() => _products.removeWhere((item) => item.id == product.id));
    Navigator.of(context).pop();
    _showMessage('Producto eliminado.');
    if (product.id > 0) unawaited(_syncDelete(product));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFF087E75)),
            const SizedBox(width: 9),
            Text(
              'Tapia Store',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                widget.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu catálogo',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isLoading
                            ? 'Conectando con el catálogo...'
                            : _selectedCategory == null
                            ? '${_products.length} productos disponibles'
                            : _isCategoryLoading
                            ? 'Buscando en ${_selectedCategory!}...'
                            : 'Mostrando ${products.length} de '
                                  '${_products.length} productos · '
                                  '$_selectedCategory',
                        style: const TextStyle(color: Color(0xFF68736E)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _search = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      if (_categories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _CategoryChip(
                                label: 'Todas',
                                selected: _selectedCategory == null,
                                onTap: () => _selectCategory(null),
                              ),
                              ..._categories.map(
                                (category) => _CategoryChip(
                                  label: category,
                                  selected: _selectedCategory == category,
                                  onTap: () => _selectCategory(category),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudo cargar el catálogo',
                    message: _loadError!,
                    actionLabel: 'Reintentar',
                    onAction: _loadProducts,
                  ),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    title: 'No encontramos productos',
                    message: _products.isEmpty
                        ? 'Agrega el primer producto a tu catálogo.'
                        : 'Prueba otra búsqueda o categoría.',
                    actionLabel: _products.isEmpty ? 'Agregar producto' : null,
                    onAction: _products.isEmpty ? () => _openForm() : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = width >= 1000
                          ? 4
                          : width >= 650
                          ? 3
                          : width >= 390
                          ? 2
                          : 1;
                      return SliverGrid.builder(
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 330,
                        ),
                        itemBuilder: (context, index) => _ProductCard(
                          product: products[index],
                          onTap: () => _openDetails(products[index]),
                          onEdit: () => _openForm(product: products[index]),
                          onDelete: () => _deleteFromCard(products[index]),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFromCard(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteFromCatalog(product);
  }

  Future<void> _deleteFromCatalog(Product product) async {
    setState(() => _products.removeWhere((item) => item.id == product.id));
    _showMessage('Producto eliminado.');
    if (product.id > 0) unawaited(_syncDelete(product));
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEBEEEC)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ProductImage(
                  key: ValueKey(product.image),
                  url: product.image,
                  fit: BoxFit.contain,
                  placeholderSize: 42,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF087E75),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF087E75),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar producto',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        tooltip: 'Eliminar producto',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFFD9EEE8),
        side: BorderSide(
          color: selected ? const Color(0xFF087E75) : const Color(0xFFE5E9E6),
        ),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF087E75) : const Color(0xFF59645F),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF87918D)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF68736E), height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
