import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../screens/auth/index_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/categories_crud_screen.dart';
import '../screens/admin/products_crud_screen.dart';
import '../screens/admin/users_crud_screen.dart';
import '../screens/admin/sales_management_screen.dart';
import '../screens/client/catalog_screen.dart';
import '../screens/client/product_detail_screen.dart';
import '../screens/client/cart_screen.dart';
import '../screens/client/orders_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Definición y gestor centralizado de rutas para la aplicación Percucol.
class AppRoutes {
  // Rutas de Autenticación
  static const String index = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Rutas del Módulo Administrador
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCategories = '/admin/categories';
  static const String adminProducts = '/admin/products';
  static const String adminUsers = '/admin/users';
  static const String adminSales = '/admin/sales';

  // Rutas del Módulo Cliente
  static const String clientCatalog = '/client/catalog';
  static const String productDetail = '/client/product-detail';
  static const String cart = '/client/cart';
  static const String orders = '/client/orders';

  // Chatbot IA
  static const String chat = '/chat';

  // Perfil de Usuario (Común para roles)
  static const String profile = '/profile';

  /// Generador de rutas tipadas y seguras
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case index:
        return MaterialPageRoute(builder: (_) => const IndexScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case adminCategories:
        return MaterialPageRoute(builder: (_) => const CategoriesCrudScreen());

      case adminProducts:
        return MaterialPageRoute(builder: (_) => const ProductsCrudScreen());

      case adminUsers:
        return MaterialPageRoute(builder: (_) => const UsersCrudScreen());

      case adminSales:
        return MaterialPageRoute(builder: (_) => const SalesManagementScreen());

      case clientCatalog:
        return MaterialPageRoute(builder: (_) => const CatalogScreen());

      case productDetail:
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Ruta no encontrada')),
            body: Center(
              child: Text('No existe la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

