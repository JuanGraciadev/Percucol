import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product_model.dart';

/// Provider para la gestión del inventario de productos, filtros de catálogo,
/// búsqueda reactiva y actualización de stock en tiempo real.
class ProductProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<ProductModel> _products = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    loadProducts();
  }

  /// Carga todos los productos desde SQLite
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _dbHelper.getAllProducts();
    } catch (e) {
      _errorMessage = 'Error al cargar inventario: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualiza el término de búsqueda de productos
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  /// Retorna los productos aplicando el filtro de categoría y de búsqueda
  List<ProductModel> getFilteredProducts({int? categoryId}) {
    return _products.where((prod) {
      final matchesCategory = (categoryId == null || prod.categoryId == categoryId);
      final matchesQuery = _searchQuery.isEmpty ||
          prod.name.toLowerCase().contains(_searchQuery) ||
          prod.description.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Crear un nuevo producto en el catálogo (Admin)
  Future<bool> createProduct(ProductModel product) async {
    try {
      final id = await _dbHelper.insertProduct(product);
      _products.insert(0, product.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar producto: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Modificar un producto existente (Admin)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _dbHelper.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar producto: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar un producto (Admin)
  Future<bool> deleteProduct(int id) async {
    try {
      await _dbHelper.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar producto: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Disminuye el stock cuando se procesa una compra
  Future<bool> decrementStock(int productId, int quantity) async {
    try {
      await _dbHelper.decrementProductStock(productId, quantity);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final currentStock = _products[index].stock;
        final newStock = (currentStock - quantity) < 0 ? 0 : (currentStock - quantity);
        _products[index] = _products[index].copyWith(stock: newStock);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error decrementing stock: $e');
      return false;
    }
  }

  /// Obtiene un producto por su ID
  ProductModel? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

