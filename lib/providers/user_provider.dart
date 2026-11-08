import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

/// Provider para la administración y CRUD de Usuarios (módulo exclusivo de Administrador).
class UserProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    loadUsers();
  }

  /// Carga todos los usuarios registrados en SQLite
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _dbHelper.getAllUsers();
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualiza los datos de un usuario (Admin)
  Future<bool> updateUser(UserModel user) async {
    try {
      await _dbHelper.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar usuario: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Cambia el rol de un usuario (ej. de 'client' a 'admin' o viceversa)
  Future<bool> changeUserRole(int userId, String newRole) async {
    try {
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final updated = _users[index].copyWith(role: newRole);
        await _dbHelper.updateUser(updated);
        _users[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error al cambiar rol: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un usuario por su ID
  Future<bool> deleteUser(int id) async {
    try {
      await _dbHelper.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}

