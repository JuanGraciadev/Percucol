/// Modelo para un ítem dentro de una venta registrada en Percucol.
class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String productImageUrl; // imagen guardada al momento de la compra

  const SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.productImageUrl = '',
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'saleId': saleId,
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'productImageUrl': productImageUrl,
      };

  factory SaleItemModel.fromMap(Map<String, dynamic> map) => SaleItemModel(
        id: map['id'] as int?,
        saleId: map['saleId'] as int,
        productId: map['productId'] as int,
        productName: map['productName'] as String,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        quantity: map['quantity'] as int,
        productImageUrl: map['productImageUrl'] as String? ?? '',
      );
}

/// Modelo de Venta / Pedido registrado en Percucol.
class SaleModel {
  final int? id;
  final int userId;
  final String userName;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'delivered', 'cancelled'
  final String createdAt;
  final List<SaleItemModel> items;

  SaleModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    List<SaleItemModel>? items,
  }) : items = items ?? [];

  /// Etiqueta legible del estado de la venta
  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'userId': userId,
        'userName': userName,
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt,
      };

  factory SaleModel.fromMap(Map<String, dynamic> map) => SaleModel(
        id: map['id'] as int?,
        userId: map['userId'] as int,
        userName: map['userName'] as String,
        totalAmount: (map['totalAmount'] as num).toDouble(),
        status: map['status'] as String,
        createdAt: map['createdAt'] as String,
      );

  SaleModel copyWith({String? status, List<SaleItemModel>? items}) => SaleModel(
        id: id,
        userId: userId,
        userName: userName,
        totalAmount: totalAmount,
        status: status ?? this.status,
        createdAt: createdAt,
        items: items ?? this.items,
      );
}
