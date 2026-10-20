import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _imageController;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product?.title ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _categoryController = TextEditingController(text: product?.category ?? '');
    _imageController = TextEditingController(text: product?.image ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.product;
    final product = Product(
      id: existing?.id ?? 0,
      title: _titleController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      image: _imageController.text.trim(),
    );
    Navigator.of(context).pop(product);
  }

  String? _requiredText(String? value, String label, {int minLength = 1}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa $label.';
    if (text.length < minLength) {
      return '$label debe tener al menos $minLength caracteres.';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    if (price == null || !price.isFinite || price <= 0) {
      return 'Ingresa un precio mayor que cero.';
    }
    return null;
  }

  String? _validateImage(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return 'Ingresa una URL de imagen válida (https://...).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Agregar producto'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Información del producto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        _requiredText(value, 'el nombre', minLength: 3),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                    ),
                    validator: _validatePrice,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator: (value) =>
                        _requiredText(value, 'la categoría'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        _requiredText(value, 'la descripción', minLength: 10),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _imageController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL de la imagen',
                      hintText: 'https://ejemplo.com/producto.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    validator: _validateImage,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Guardar producto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
