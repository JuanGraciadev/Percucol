/// Modelo de datos para Productos (Instrumentos y Accesorios de Percusión).
class ProductModel {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String imageUrl;
  final double rating;

  const ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl = '',
    this.rating = 4.8,
  });

  bool get isOutOfStock => stock <= 0;
  bool get hasStock => stock > 0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'rating': rating,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      categoryId: (map['categoryId'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    int? categoryId,
    String? imageUrl,
    double? rating,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
    );
  }
}

