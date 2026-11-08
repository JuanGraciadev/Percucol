import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

/// Catálogo Interactivo de Percucol (Módulo Cliente).
/// Cuenta con filtro horizontal de categorías, buscador reactivo, Grid de productos,
/// badges de stock ("En Stock" / "Agotado") y bloqueo dinámico de compras cuando stock <= 0.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // CategoryProvider y ProductProvider cargan datos en sus constructores.
    // No se necesita ninguna llamada extra aquí.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProvider = Provider.of<AuthProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final filteredProducts = prodProvider.getFilteredProducts(
      categoryId: catProvider.selectedCategoryId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'PERCUCOL',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Botón de Carrito con Contador
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Carrito de Compras',
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart),
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Menú Desplegable de Usuario
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              switch (value) {
                case 'theme':
                  authProvider.toggleTheme();
                  break;
                case 'profile':
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                  break;
                case 'orders':
                  Navigator.of(context).pushNamed(AppRoutes.orders);
                  break;
                case 'chat':
                  Navigator.of(context).pushNamed(AppRoutes.chat);
                  break;
                case 'admin':
                  Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
                  break;
                case 'login':
                  Navigator.of(context).pushNamed(AppRoutes.login);
                  break;
                case 'logout':
                  final confirm = await UIHelpers.showConfirmationDialog(
                    context,
                    title: '¿Cerrar Sesión?',
                    content: '¿Deseas salir de tu cuenta?',
                    confirmLabel: 'Cerrar Sesión',
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
                  break;
              }
            },
            itemBuilder: (ctx) => [
              if (authProvider.isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, color: AppColors.primaryGold, size: 20),
                      SizedBox(width: 10),
                      Text('Panel Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              if (authProvider.isAuthenticated)
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Mi Perfil'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, color: AppColors.primaryGold, size: 20),
                      SizedBox(width: 10),
                      Text('Iniciar Sesión'),
                    ],
                  ),
                ),
              if (authProvider.isAuthenticated)
                const PopupMenuItem(
                  value: 'orders',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Mis Pedidos'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: AppColors.primaryGold, size: 20),
                    SizedBox(width: 10),
                    Text('PercuBot IA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(isDark ? 'Modo Claro' : 'Modo Oscuro'),
                  ],
                ),
              ),
              if (authProvider.isAuthenticated)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.outOfStockRed, size: 20),
                      SizedBox(width: 10),
                      Text('Cerrar Sesión', style: TextStyle(color: AppColors.outOfStockRed)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            catProvider.loadCategories(),
            prodProvider.loadProducts(),
          ]);
        },
        child: Column(
          children: [
            // Barra de Búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => prodProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Buscar tambores, congas, platillos, shakers...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            prodProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filtro Horizontal de Categorías (Chips interactivos)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: catProvider.selectedCategoryId == null,
                      onSelected: (selected) {
                        if (selected) catProvider.selectCategory(null);
                      },
                    ),
                  ),
                  ...catProvider.categories.map((cat) {
                    final isSelected = catProvider.selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.album_outlined,
                          size: 16,
                          color: isSelected ? Colors.black : AppColors.primaryGold,
                        ),
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          catProvider.selectCategory(selected ? cat.id : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Feed tipo Grid interactivo de Productos
            Expanded(
              child: prodProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay instrumentos disponibles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Prueba con otra categoría o término de búsqueda.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _ProductGridCard(
                              product: product,
                              categoryName: catProvider.getCategoryName(product.categoryId),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.productDetail,
                                  arguments: product,
                                );
                              },
                              onAddToCart: () {
                                if (product.isOutOfStock) return;
                                final success = cartProvider.addToCart(
                                  product,
                                  currentStock: product.stock,
                                );
                                if (success) {
                                  UIHelpers.showSnackBar(
                                    context,
                                    message: '¡"${product.name}" añadido al carrito!',
                                    isSuccess: true,
                                    icon: Icons.check_circle_rounded,
                                  );
                                } else {
                                  UIHelpers.showSnackBar(
                                    context,
                                    message: 'No hay más unidades disponibles en stock',
                                    isError: true,
                                  );
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text(
          'PercuBot IA',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chat),
      ),
    );
  }
}

/// Tarjeta de Producto Elevada con Sombras Suaves y Bloqueo de Stock
class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final String categoryName;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductGridCard({
    required this.product,
    required this.categoryName,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isOutOfStock = product.isOutOfStock;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenedor de Imagen y Badge de Stock
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      height: 125,
                      width: double.infinity,
                      color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                      child: ProductImageView(
                        imagePath: product.imageUrl,
                        width: double.infinity,
                        height: 125,
                        fit: BoxFit.cover,
                        iconSize: 40,
                      ),
                    ),
                  ),

                  // Overlay atenuado si está agotado
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                      ),
                    ),

                  // Badge de Stock
                  Positioned(
                    top: 8,
                    left: 8,
                    child: StockBadge(stock: product.stock, compact: true),
                  ),
                ],
              ),

              // Contenido / Datos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryGold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // Precio
                      Text(
                        UIHelpers.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Botón "Comprar" / "Agregar" (BLOQUEO AUTOMÁTICO SI AGOTADO)
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOutOfStock
                                ? (isDark ? Colors.grey[800] : Colors.grey[300])
                                : AppColors.primaryGold,
                            foregroundColor: isOutOfStock
                                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                                : Colors.black,
                            elevation: isOutOfStock ? 0 : 2,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Si el producto está agotado (stock <= 0), el botón queda INHABILITADO
                          onPressed: isOutOfStock ? null : onAddToCart,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOutOfStock ? Icons.block_rounded : Icons.shopping_bag_outlined,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOutOfStock ? 'Agotado' : 'Agregar',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

