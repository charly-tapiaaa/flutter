class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final price = json['price'];
    if (id is! num || price is! num) {
      throw const FormatException('El producto recibido no tiene ID o precio válido.');
    }

    return Product(
      id: id.toInt(),
      title: _requiredString(json, 'title'),
      price: price.toDouble(),
      description: _requiredString(json, 'description'),
      category: _requiredString(json, 'category'),
      image: _requiredString(json, 'image'),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'image': image,
      };

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido.');
    }
    return value;
  }
}
