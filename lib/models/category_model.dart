/// Modelo de datos para Categoría de Instrumentos de Percusión.
class CategoryModel {
  final int? id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;

  const CategoryModel({
    this.id,
    required this.name,
    required this.description,
    this.iconName = 'drum',
    this.colorHex = '0xFFD4881A',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'drum',
      colorHex: map['colorHex'] as String? ?? '0xFFD4881A',
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

