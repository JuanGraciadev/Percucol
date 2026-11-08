import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../database/db_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';

/// Panel Principal de Administración (Dashboard Admin) para Percucol.
/// Centraliza métricas del negocio y accesos directos a los CRUDs.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context);

    final currentUser = authProvider.currentUser;
    final totalCategories = catProvider.categories.length;
    final totalProducts = prodProvider.products.length;
    final outOfStockCount = prodProvider.products.where((p) => p.isOutOfStock).length;
    final totalUsers = userProvider.users.length;
    final totalSales = saleProvider.totalSales;
    final totalRevenue = saleProvider.totalRevenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            tooltip: 'Cambiar Tema',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.primaryGold,
            ),
            onPressed: () => authProvider.toggleTheme(),
          ),
          IconButton(
            tooltip: 'Mi Perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded, color: AppColors.outOfStockRed),
            onPressed: () async {
              final confirm = await UIHelpers.showConfirmationDialog(
                context,
                title: '¿Cerrar Sesión?',
                content: 'Saldrás de tu cuenta de administrador de Percucol.',
                confirmLabel: 'Salir',
                isDestructive: false,
              );
              if (confirm && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.index,
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            catProvider.loadCategories(),
            prodProvider.loadProducts(),
            userProvider.loadUsers(),
            saleProvider.loadAllSales(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de Bienvenida al Administrador
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryGold,
                      child: Text(
                        (currentUser?.name.isNotEmpty == true)
                            ? currentUser!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentUser?.name ?? 'Administrador',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser?.email ?? 'admin@percucol.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'ROL: ADMINISTRADOR GLOBAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryGold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Métricas Clave
              Text(
                'Métricas del Sistema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _MetricCard(
                    title: 'Categorías',
                    value: '$totalCategories',
                    icon: Icons.category_rounded,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(width: 12),
                  _MetricCard(
                    title: 'Productos',
                    value: '$totalProducts',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.secondaryGold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetricCard(
                    title: 'Sin Stock',
                    value: '$outOfStockCount',
                    icon: Icons.warning_rounded,
                    color: AppColors.outOfStockRed,
                    subtitle: 'Productos agotados',
                  ),
                  const SizedBox(width: 12),
                  _MetricCard(
                    title: 'Usuarios',
                    value: '$totalUsers',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.info,
                    subtitle: 'Clientes y admins',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Módulos de Gestión (CRUDs)
              Text(
                'Módulos de Gestión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Métricas de ventas
              Row(
                children: [
                  _MetricCard(
                    title: 'Ventas',
                    value: '$totalSales',
                    icon: Icons.point_of_sale_rounded,
                    color: AppColors.inStock,
                    subtitle: 'Pedidos realizados',
                  ),
                  const SizedBox(width: 12),
                  _MetricCard(
                    title: 'Ingresos',
                    value: UIHelpers.formatCOP(totalRevenue),
                    icon: Icons.attach_money_rounded,
                    color: AppColors.primaryGold,
                    subtitle: 'Total confirmado',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Módulos de Gestión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 14),

              _AdminNavTile(
                title: 'Gestión de Categorías',
                subtitle: 'Crear, editar y organizar familias de instrumentos',
                icon: Icons.folder_special_rounded,
                badgeText: '$totalCategories activas',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCategories),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'Gestión de Productos (Inventario)',
                subtitle: 'Administrar catálogo, precios, imágenes y stock',
                icon: Icons.inventory_rounded,
                badgeText: '$totalProducts en total',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'Gestión de Usuarios',
                subtitle: 'Supervisar cuentas, cambiar roles y permisos',
                icon: Icons.manage_accounts_rounded,
                badgeText: '$totalUsers registrados',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminUsers),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'Gestión de Ventas',
                subtitle: 'Ver pedidos, ingresos y cambiar estados de entrega',
                icon: Icons.point_of_sale_rounded,
                badgeText: '$totalSales pedidos',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminSales),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'PercuBot — Asistente IA',
                subtitle: 'Chatbot inteligente con recomendaciones de productos',
                icon: Icons.smart_toy_rounded,
                isSecondary: true,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.chat),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'Explorar Catálogo como Cliente',
                subtitle: 'Ver la experiencia de compra en vivo',
                icon: Icons.storefront_rounded,
                isSecondary: true,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.clientCatalog),
              ),
              const SizedBox(height: 12),

              _AdminNavTile(
                title: 'Reabastecer Inventario (Pruebas)',
                subtitle: 'Restablecer stock de productos agotados a 6 unidades',
                icon: Icons.published_with_changes_rounded,
                onTap: () async {
                  final confirm = await UIHelpers.showConfirmationDialog(
                    context,
                    title: '¿Reabastecer Stock?',
                    content: 'Los productos agotados volverán a tener 6 unidades disponibles.',
                    confirmLabel: 'Reabastecer',
                  );
                  if (confirm && context.mounted) {
                    await DBHelper().restockProducts();
                    await prodProvider.loadProducts();
                    if (context.mounted) {
                      UIHelpers.showSnackBar(
                        context,
                        message: '¡Inventario reabastecido correctamente!',
                        isSuccess: true,
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
  final VoidCallback onTap;
  final bool isSecondary;

  const _AdminNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSecondary
                  ? AppColors.primaryGold.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSecondary ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSecondary
                      ? AppColors.primaryGold.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkCardElevated : AppColors.lightInput),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSecondary ? AppColors.primaryGold : AppColors.secondaryGold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryGold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textDarkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

