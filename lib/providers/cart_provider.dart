import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import 'product_provider.dart';
import 'sale_provider.dart';

/// Resultado detallado del procesamiento de una compra.
class CheckoutResult {
  final bool isSuccess;
  final String message;
  final int? saleId;

  const CheckoutResult({
    required this.isSuccess,
    required this.message,
    this.saleId,
  });
}

/// Elemento individual dentro del carrito de compras.
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

/// Provider para la gestión del carrito de compras y proceso de checkout en Percucol.
class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Añade un producto al carrito respetando el stock disponible.
  /// [currentStock] es el stock fresco desde el ProductProvider; si se omite
  /// se usa el stock del objeto producto (válido al momento de agregarlo).
  bool addToCart(ProductModel product, {int quantity = 1, int? currentStock}) {
    final stockLimit = currentStock ?? product.stock;

    if (stockLimit <= 0) return false;

    if (_items.containsKey(product.id)) {
      final currentQuantity = _items[product.id!]!.quantity;
      if (currentQuantity + quantity > stockLimit) return false;
      _items[product.id!]!.quantity += quantity;
    } else {
      if (quantity > stockLimit) return false;
      _items[product.id!] = CartItem(product: product, quantity: quantity);
    }

    notifyListeners();
    return true;
  }

  /// Disminuye una unidad o remueve si llega a 0
  void decrementQuantity(int productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity -= 1;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  /// Remueve completamente un ítem del carrito
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Limpia todo el carrito
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Procesa la compra de forma 100% ATÓMICA:
  /// Valida existencias -> descuenta stock -> registra venta e ítems en una sola transacción SQLite.
  /// Si algo falla, el stock queda intacto y el carrito no se pierde.
  Future<CheckoutResult> processCheckout({
    required ProductProvider productProvider,
    required SaleProvider saleProvider,
    required int userId,
    required String userName,
  }) async {
    if (_items.isEmpty) {
      return const CheckoutResult(
        isSuccess: false,
        message: 'El carrito de compras está vacío.',
      );
    }

    final dbHelper = DBHelper();

    // Preparar cabecera de la venta
    final sale = SaleModel(
      userId: userId,
      userName: userName,
      totalAmount: totalAmount,
      status: 'confirmed', // Confirmada al realizar la compra
      createdAt: DateTime.now().toIso8601String(),
    );

    // Preparar ítems de la venta
    final saleItems = _items.values
        .map((ci) => SaleItemModel(
              saleId: 0,
              productId: ci.product.id!,
              productName: ci.product.name,
              unitPrice: ci.product.price,
              quantity: ci.quantity,
              productImageUrl: ci.product.imageUrl,
            ))
        .toList();

    try {
      // Ejecución atómica en la base de datos
      final saleId = await dbHelper.executeAtomicPurchase(
        sale: sale,
        items: saleItems,
      );

      // Limpiar carrito solo tras confirmación exitosa en SQLite
      clear();

      // Recargar productos e inventario fresco
      await productProvider.loadProducts();
      await saleProvider.loadAllSales();

      return CheckoutResult(
        isSuccess: true,
        saleId: saleId,
        message: '¡Pedido #$saleId confirmado exitosamente!',
      );
    } catch (e) {
      debugPrint('Error en compra atómica: $e');
      // Recargar productos por si el stock en pantalla estaba desactualizado
      await productProvider.loadProducts();

      String userMessage = e.toString();
      if (userMessage.startsWith('Exception: ')) {
        userMessage = userMessage.substring(11);
      }

      return CheckoutResult(
        isSuccess: false,
        message: userMessage,
      );
    }
  }
}

