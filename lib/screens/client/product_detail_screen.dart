import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

/// Pantalla de Detalle de Producto en Percucol.
/// Muestra especificaciones completas del instrumento, estado de stock
/// y bloqueo dinámico del botón de compra cuando el producto está agotado.
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);

    // Obtener siempre la información más reciente de la base de datos
    final product = prodProvider.getProductById(widget.product.id ?? -1) ?? widget.product;
    final isOutOfStock = product.isOutOfStock;
    final categoryName = catProvider.getCategoryName(product.categoryId);

    // Ajustar cantidad si el stock disminuyó por debajo de lo seleccionado
    if (!isOutOfStock && _quantity > product.stock) {
      _quantity = product.stock;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Consultar a PercuBot IA',
              icon: const Icon(Icons.smart_toy_rounded, color: AppColors.primaryGold, size: 20),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chat),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Imagen Principal con Badge de Stock
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                        child: ProductImageView(
                          imagePath: product.imageUrl,
                          width: double.infinity,
                          height: 320,
                          fit: BoxFit.cover,
                          iconSize: 70,
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: const Center(
                              child: Text(
                                'PRODUCTO AGOTADO',
                                style: TextStyle(
                                  color: AppColors.outOfStockRed,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Contenido Informativo
                  Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categoría y Badge de Stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryGold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            StockBadge(stock: product.stock),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Nombre del Instrumento
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Calificación y Reseñas
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.secondaryGold, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating} / 5.0',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  Auténtico Percucol',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Precio
                        Text(
                          UIHelpers.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Divider(),
                        const SizedBox(height: 12),

                        // Descripción y Detalles
                        const Text(
                          'Descripción & Especificaciones',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : 'Instrumento fabricado con altos estándares de sonoridad, maderas curadas y herrajes resistentes para percusionistas exigentes.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Beneficios de compra
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_outlined, color: AppColors.primaryGold, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Garantía de luthier oficial de 1 año e inspección acústica previa al envío.',
                                  style: TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra Inferior de Compra Fija
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Selector de Cantidad (si hay stock disponible)
                  if (!isOutOfStock) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: _quantity < product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botón Secundario: Añadir al carrito
                    IconButton.filledTonal(
                      tooltip: 'Añadir al carrito',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryGold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 22),
                      onPressed: () {
                        final added = cartProvider.addToCart(
                          product,
                          quantity: _quantity,
                          currentStock: product.stock,
                        );
                        if (added) {
                          UIHelpers.showSnackBar(
                            context,
                            message: '¡Añadido(s) $_quantity a tu carrito!',
                            isSuccess: true,
                          );
                        } else {
                          UIHelpers.showSnackBar(
                            context,
                            message: 'No puedes superar el stock disponible (${product.stock})',
                            isError: true,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Botón Principal: Comprar Ahora o Producto Agotado
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? (isDark ? Colors.grey[800] : Colors.grey[300])
                              : AppColors.primaryGold,
                          foregroundColor: isOutOfStock
                              ? (isDark ? Colors.grey[500] : Colors.grey[600])
                              : Colors.black,
                          elevation: isOutOfStock ? 0 : 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                final added = cartProvider.addToCart(
                                  product,
                                  quantity: _quantity,
                                  currentStock: product.stock,
                                );
                                if (added || cartProvider.items.containsKey(product.id)) {
                                  Navigator.of(context).pushNamed(AppRoutes.cart);
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOutOfStock ? Icons.block_rounded : Icons.flash_on_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOutOfStock ? 'PRODUCTO AGOTADO' : 'Comprar Ahora',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

