import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import 'cart_provider.dart';

/// Provider para la gestión de ventas y pedidos en Percucol.
class SaleProvider with ChangeNotifier {
  final DBHelper _db = DBHelper();

  List<SaleModel> _sales = [];
  List<SaleModel> _userOrders = [];
  bool _isLoading = false;
  bool _isLoadingUserOrders = false;
  Map<String, dynamic> _metrics = {'totalSales': 0, 'totalRevenue': 0.0};

  List<SaleModel> get sales => _sales;
  /// Pedidos del cliente activo (para OrdersScreen)
  List<SaleModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  bool get isLoadingUserOrders => _isLoadingUserOrders;
  int get totalSales => (_metrics['totalSales'] as int?) ?? 0;
  double get totalRevenue => (_metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;

  SaleProvider() {
    loadAllSales();
  }

  Future<void> loadAllSales() async {
    _isLoading = true;
    notifyListeners();
    _sales = await _db.getAllSales();
    _metrics = await _db.getSalesMetrics();
    _isLoading = false;
    notifyListeners();
  }

  /// Carga los pedidos de un usuario específico en [userOrders] y notifica.
  /// La OrdersScreen escucha estos cambios para refrescarse automáticamente.
  Future<void> loadUserSalesIntoState(int userId) async {
    _isLoadingUserOrders = true;
    notifyListeners();
    _userOrders = await _db.getSalesByUser(userId);
    _isLoadingUserOrders = false;
    notifyListeners();
  }

  /// Limpia los pedidos del cliente (cuando cierra sesión)
  void clearUserOrders() {
    _userOrders = [];
    notifyListeners();
  }

  Future<List<SaleModel>> loadUserSales(int userId) async {
    return await _db.getSalesByUser(userId);
  }

  /// Crea una venta completa a partir del carrito actual
  Future<int?> createSaleFromCart(CartProvider cart, UserModel user) async {
    if (cart.itemList.isEmpty) return null;

    final sale = SaleModel(
      userId: user.id!,
      userName: user.name,
      totalAmount: cart.totalAmount,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    final items = cart.itemList
        .map((cartItem) => SaleItemModel(
              saleId: 0, // será reemplazado en la transacción
              productId: cartItem.product.id!,
              productName: cartItem.product.name,
              unitPrice: cartItem.product.price,
              quantity: cartItem.quantity,
            ))
        .toList();

    // Usar executeAtomicPurchase para que también descuente el stock
    final saleId = await _db.executeAtomicPurchase(sale: sale, items: items);
    await loadAllSales();
    return saleId;
  }

  Future<bool> updateStatus(int saleId, String newStatus) async {
    try {
      await _db.updateSaleStatus(saleId, newStatus);
      final idx = _sales.indexWhere((s) => s.id == saleId);
      if (idx != -1) {
        _sales[idx] = _sales[idx].copyWith(status: newStatus);
      }
      // Reflejar el cambio en userOrders si ese pedido está cargado
      final userIdx = _userOrders.indexWhere((s) => s.id == saleId);
      if (userIdx != -1) {
        _userOrders[userIdx] = _userOrders[userIdx].copyWith(status: newStatus);
      }
      _metrics = await _db.getSalesMetrics();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSale(int saleId) async {
    try {
      await _db.deleteSale(saleId);
      _sales.removeWhere((s) => s.id == saleId);
      _userOrders.removeWhere((s) => s.id == saleId);
      _metrics = await _db.getSalesMetrics();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

