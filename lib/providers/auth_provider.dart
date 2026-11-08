import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

/// Provider central para la autenticación, gestión de sesión persistente en SQLite
/// y control de tema visual (Dark / Light) en Percucol.
class AuthProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.dark; // Dark por defecto para la estética premium

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isClient => _currentUser?.isClient ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AuthProvider() {
    checkActiveSession();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Verifica si existe una sesión guardada en la base de datos local SQLite
  Future<bool> checkActiveSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final activeUserId = await _dbHelper.getActiveSessionUserId();
      if (activeUserId != null) {
        final user = await _dbHelper.getUserById(activeUserId);
        if (user != null) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Inicia sesión validando credenciales y guardando el estado en SQLite
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        _errorMessage = 'No existe una cuenta registrada con este correo.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.password != password) {
        _errorMessage = 'Contraseña incorrecta. Por favor verifica tus datos.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Guardar usuario en memoria y persistir sesión en SQLite
      _currentUser = user;
      if (user.id != null) {
        await _dbHelper.saveActiveSession(user.id!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ocurrió un error al iniciar sesión: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro de un nuevo usuario en la base de datos
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    String role = 'client',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        _errorMessage = 'El correo electrónico ya está registrado por otro usuario.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newUser = UserModel(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone.trim(),
        address: address.trim(),
        role: role,
        createdAt: DateTime.now().toIso8601String(),
      );

      final newId = await _dbHelper.insertUser(newUser);
      final registeredUser = newUser.copyWith(id: newId);

      _currentUser = registeredUser;
      await _dbHelper.saveActiveSession(newId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error durante el registro: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar el perfil del usuario activo
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
    String? newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        password: (newPassword != null && newPassword.isNotEmpty)
            ? newPassword
            : _currentUser!.password,
      );

      await _dbHelper.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar perfil: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa y limpia la tabla SQLite
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.clearActiveSession();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

