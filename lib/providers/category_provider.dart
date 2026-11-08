import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/category_model.dart';

/// Provider para la gestión del estado de Categorías (CRUD y selección).
class CategoryProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId; // null = Todas las categorías
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CategoryProvider() {
    loadCategories();
  }

  /// Carga todas las categorías desde SQLite
  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _dbHelper.getAllCategories();
    } catch (e) {
      _errorMessage = 'Error al cargar categorías: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cambia la categoría seleccionada para el filtro del catálogo
  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Crear una nueva categoría (Admin)
  Future<bool> createCategory(CategoryModel category) async {
    try {
      final id = await _dbHelper.insertCategory(category);
      _categories.add(category.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar categoría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Modificar una categoría existente (Admin)
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _dbHelper.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar categoría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar una categoría y sus productos asociados (Admin)
  Future<bool> deleteCategory(int id) async {
    try {
      await _dbHelper.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      if (_selectedCategoryId == id) {
        _selectedCategoryId = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar categoría: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Obtener el nombre de una categoría por su ID
  String getCategoryName(int categoryId) {
    final cat = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => const CategoryModel(id: 0, name: 'General', description: ''),
    );
    return cat.name;
  }
}

