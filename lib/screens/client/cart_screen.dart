import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../database/db_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

/// Pantalla de Carrito y Checkout de Percucol con pasarela de pago realista.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cartProvider = Provider.of<CartProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);

    final items = cartProvider.itemList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar Carrito',
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.outOfStockRed),
              onPressed: () async {
                final confirm = await UIHelpers.showConfirmationDialog(
                  context,
                  title: '¿Vaciar Carrito?',
                  content: 'Se removerán todos los instrumentos agregados.',
                  confirmLabel: 'Vaciar',
                );
                if (confirm) cartProvider.clear();
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          size: 48, color: AppColors.secondaryGold),
                    ),
                    const SizedBox(height: 20),
                    Text('Tu carrito está vacío',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Explora nuestro catálogo exclusivo y añade tus instrumentos favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Explorar Catálogo'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // ── Lista de productos ──────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final freshProduct =
                          prodProvider.getProductById(item.product.id!) ?? item.product;
                      final availableStock = freshProduct.stock;
                      final bool hasStockIssue = availableStock < item.quantity;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasStockIssue
                                ? AppColors.outOfStockRed
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: hasStockIssue ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 68,
                                height: 68,
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                                child: ProductImageView(
                                  imagePath: freshProduct.imageUrl,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  iconSize: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(freshProduct.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(UIHelpers.formatCurrency(freshProduct.price),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkCardElevated
                                              : AppColors.lightInput,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cartProvider
                                                  .decrementQuantity(freshProduct.id!),
                                              child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(Icons.remove, size: 16)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Text('${item.quantity}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13)),
                                            ),
                                            InkWell(
                                              onTap: item.quantity < availableStock
                                                  ? () => cartProvider.addToCart(
                                                        freshProduct,
                                                        currentStock: availableStock,
                                                      )
                                                  : null,
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(Icons.add,
                                                    size: 16,
                                                    color: item.quantity >= availableStock
                                                        ? Colors.grey
                                                        : null),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        availableStock > 0
                                            ? 'Disp: $availableStock'
                                            : '¡Agotado!',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: hasStockIssue
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: hasStockIssue
                                              ? AppColors.outOfStockRed
                                              : (isDark
                                                  ? AppColors.textDarkMuted
                                                  : AppColors.textLightMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  color: AppColors.textDarkMuted,
                                  onPressed: () =>
                                      cartProvider.removeItem(freshProduct.id!),
                                ),
                                const SizedBox(height: 8),
                                Text(UIHelpers.formatCurrency(item.totalPrice),
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ── Resumen y botón de pago ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                        top: BorderSide(
                            color:
                                isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, -4))
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total a Pagar:',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary)),
                            Text(UIHelpers.formatCurrency(cartProvider.totalAmount),
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryGold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleCheckoutInitiation(
                                      context,
                                      authProvider: authProvider,
                                      cartProvider: cartProvider,
                                      prodProvider: prodProvider,
                                      saleProvider: saleProvider,
                                    ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.black))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text('Proceder al Pago',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
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
    );
  }

  // ── Flujo de checkout ────────────────────────────────────────────────────────

  Future<void> _handleCheckoutInitiation(
    BuildContext context, {
    required AuthProvider authProvider,
    required CartProvider cartProvider,
    required ProductProvider prodProvider,
    required SaleProvider saleProvider,
  }) async {
    final user = authProvider.currentUser;

    if (user != null) {
      await _showPaymentGateway(
        context,
        userId: user.id!,
        userName: user.name,
        contactPhone: user.phone,
        deliveryAddress: user.address,
        cartProvider: cartProvider,
        prodProvider: prodProvider,
        saleProvider: saleProvider,
      );
    } else {
      await _showGuestCheckoutSheet(
        context,
        cartProvider: cartProvider,
        prodProvider: prodProvider,
        saleProvider: saleProvider,
      );
    }
  }

  /// Pasarela de pago realista
  Future<void> _showPaymentGateway(
    BuildContext context, {
    required int userId,
    required String userName,
    required String contactPhone,
    required String deliveryAddress,
    required CartProvider cartProvider,
    required ProductProvider prodProvider,
    required SaleProvider saleProvider,
  }) async {
    final totalAmount = cartProvider.totalAmount;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PaymentGatewaySheet(
        totalAmount: totalAmount,
        userName: userName,
        onConfirm: () async {
          Navigator.pop(sheetCtx);
          await _confirmOrderAndExecute(
            context,
            userId: userId,
            userName: userName,
            contactPhone: contactPhone,
            deliveryAddress: deliveryAddress,
            cartProvider: cartProvider,
            prodProvider: prodProvider,
            saleProvider: saleProvider,
          );
        },
      ),
    );
  }

  /// Modal de entrega para compras de invitados
  Future<void> _showGuestCheckoutSheet(
    BuildContext context, {
    required CartProvider cartProvider,
    required ProductProvider prodProvider,
    required SaleProvider saleProvider,
  }) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(children: [
                    Icon(Icons.local_shipping_outlined, color: AppColors.primaryGold),
                    SizedBox(width: 10),
                    Text('Datos para la Entrega',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nombre Completo *',
                        prefixIcon: Icon(Icons.person_outline_rounded)),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono / WhatsApp *',
                        prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Ingresa tu teléfono' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Dirección de Entrega *',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Ingresa tu dirección' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(sheetCtx);

                        final guestId = await DBHelper().getOrCreateGuestUserId();
                        if (!context.mounted) return;

                        await _showPaymentGateway(
                          context,
                          userId: guestId,
                          userName: nameCtrl.text.trim(),
                          contactPhone: phoneCtrl.text.trim(),
                          deliveryAddress: addressCtrl.text.trim(),
                          cartProvider: cartProvider,
                          prodProvider: prodProvider,
                          saleProvider: saleProvider,
                        );
                      },
                      child: const Text('Continuar al Pago',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        Navigator.of(context).pushNamed(AppRoutes.login);
                      },
                      child: const Text('¿Ya tienes cuenta? Inicia sesión aquí'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ejecuta la compra atómica y presenta confirmación visual
  Future<void> _confirmOrderAndExecute(
    BuildContext context, {
    required int userId,
    required String userName,
    required String contactPhone,
    required String deliveryAddress,
    required CartProvider cartProvider,
    required ProductProvider prodProvider,
    required SaleProvider saleProvider,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);

    final result = await cartProvider.processCheckout(
      productProvider: prodProvider,
      saleProvider: saleProvider,
      userId: userId,
      userName: userName,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.isSuccess) {
      await showDialog<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.stockGreen, size: 30),
              SizedBox(width: 12),
              Text('¡Pago Aprobado!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primaryGold, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedido #${result.saleId}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Cliente: $userName',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '¡Gracias por tu compra en Percucol!\n'
                'Tu pedido ha sido registrado y el inventario actualizado.',
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                navigator.pushReplacementNamed(AppRoutes.orders);
              },
              child: const Text('Ver Mis Pedidos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                navigator.pop();
              },
              child: const Text('Seguir Comprando'),
            ),
          ],
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF2E1717),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.outOfStockRed.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.outOfStockRed, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(result.message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
            ),
          ],
        ),
      ));
    }
  }
}

// ── Pasarela de Pago ─────────────────────────────────────────────────────────

class _PaymentGatewaySheet extends StatefulWidget {
  final double totalAmount;
  final String userName;
  final VoidCallback onConfirm;

  const _PaymentGatewaySheet({
    required this.totalAmount,
    required this.userName,
    required this.onConfirm,
  });

  @override
  State<_PaymentGatewaySheet> createState() => _PaymentGatewaySheetState();
}

class _PaymentGatewaySheetState extends State<_PaymentGatewaySheet> {
  final _formKey = GlobalKey<FormState>();

  // Método de pago seleccionado
  String _method = 'card'; // 'card' | 'pse' | 'nequi' | 'cash'

  // Tarjeta
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvcCtrl = TextEditingController();
  bool _isSaving = false;

  // PSE
  final _bankCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  String _docType = 'CC';

  // Nequi
  final _nequiPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvcCtrl.dispose();
    _bankCtrl.dispose();
    _docCtrl.dispose();
    _nequiPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tirador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),

              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pago Seguro',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('SSL · Cifrado 256-bit',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightMuted)),
                    ],
                  ),
                  const Spacer(),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightMuted)),
                      Text(UIHelpers.formatCOP(widget.totalAmount),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryGold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 14),

              // Selector de método de pago
              const Text('Método de pago',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _MethodSelector(
                  selected: _method,
                  onChanged: (m) => setState(() => _method = m)),
              const SizedBox(height: 20),

              // Formulario según método
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildMethodForm(isDark),
              ),

              const SizedBox(height: 20),

              // Resumen del pedido
              _OrderSummaryBox(totalAmount: widget.totalAmount, isDark: isDark),
              const SizedBox(height: 20),

              // Botón confirmar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Confirmar pago de ${UIHelpers.formatCOP(widget.totalAmount)}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Sellos de seguridad
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SecurityBadge(icon: Icons.security_rounded, label: 'Pago Seguro'),
                  const SizedBox(width: 16),
                  _SecurityBadge(icon: Icons.verified_user_rounded, label: 'PCI DSS'),
                  const SizedBox(width: 16),
                  _SecurityBadge(
                      icon: Icons.lock_outline_rounded, label: 'AES-256'),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodForm(bool isDark) {
    switch (_method) {
      case 'pse':
        return _PseForm(
            key: const ValueKey('pse'),
            bankCtrl: _bankCtrl,
            docCtrl: _docCtrl,
            docType: _docType,
            onDocTypeChanged: (v) => setState(() => _docType = v),
            isDark: isDark);
      case 'nequi':
        return _NequiForm(
            key: const ValueKey('nequi'),
            phoneCtrl: _nequiPhoneCtrl,
            isDark: isDark);
      case 'cash':
        return _CashInfo(key: const ValueKey('cash'), isDark: isDark);
      default:
        return _CardForm(
            key: const ValueKey('card'),
            numberCtrl: _cardNumberCtrl,
            nameCtrl: _cardNameCtrl,
            expiryCtrl: _cardExpiryCtrl,
            cvcCtrl: _cardCvcCtrl,
            isDark: isDark);
    }
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    // Simular procesamiento de pago (~1.5 s)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isSaving = false);

    widget.onConfirm();
  }
}

// ── Selector de método ────────────────────────────────────────────────────────

class _MethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methods = [
      ('card', Icons.credit_card_rounded, 'Tarjeta'),
      ('pse', Icons.account_balance_rounded, 'PSE'),
      ('nequi', Icons.smartphone_rounded, 'Nequi'),
      ('cash', Icons.storefront_rounded, 'Efectivo'),
    ];

    return Row(
      children: methods.map((m) {
        final isSelected = selected == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGold.withValues(alpha: 0.15)
                    : (isDark ? AppColors.darkCard : AppColors.lightCardElevated),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGold
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Icon(m.$2,
                      size: 22,
                      color: isSelected
                          ? AppColors.primaryGold
                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 4),
                  Text(m.$3,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryGold
                              : (isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Formulario tarjeta ────────────────────────────────────────────────────────

class _CardForm extends StatefulWidget {
  final TextEditingController numberCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvcCtrl;
  final bool isDark;

  const _CardForm({
    super.key,
    required this.numberCtrl,
    required this.nameCtrl,
    required this.expiryCtrl,
    required this.cvcCtrl,
    required this.isDark,
  });

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  bool _obscureCvc = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vista previa de la tarjeta
        _CardPreview(
            number: widget.numberCtrl.text,
            name: widget.nameCtrl.text,
            expiry: widget.expiryCtrl.text),
        const SizedBox(height: 16),

        // Número
        TextFormField(
          controller: widget.numberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Número de tarjeta',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card_rounded),
            counterText: '',
          ),
          validator: (v) {
            final digits = v?.replaceAll(' ', '') ?? '';
            if (digits.length < 16) return 'Ingresa un número de tarjeta válido';
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Nombre
        TextFormField(
          controller: widget.nameCtrl,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nombre en la tarjeta',
            hintText: 'JUAN PEREZ',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del titular' : null,
        ),
        const SizedBox(height: 12),

        // Expiración y CVC
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.expiryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
                maxLength: 5,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'MM/AA',
                  hintText: '12/27',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.length < 5) return 'Fecha inválida';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.cvcCtrl,
                keyboardType: TextInputType.number,
                obscureText: _obscureCvc,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'CVC',
                  hintText: '•••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCvc
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureCvc = !_obscureCvc),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 3) return 'CVC inválido';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Vista previa de la tarjeta ────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  final String number;
  final String name;
  final String expiry;

  const _CardPreview(
      {required this.number, required this.name, required this.expiry});

  @override
  Widget build(BuildContext context) {
    final displayNumber = number.isEmpty
        ? '•••• •••• •••• ••••'
        : number.padRight(19, '•');
    final displayName = name.isEmpty ? 'NOMBRE TITULAR' : name.toUpperCase();
    final displayExpiry = expiry.isEmpty ? 'MM/AA' : expiry;

    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1208), Color(0xFF3A2810), Color(0xFF1A1208)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Percucol mini
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        gradient: AppColors.goldGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.music_note, color: Colors.black, size: 16),
                  ),
                  const SizedBox(width: 6),
                  const Text('PERCUCOL',
                      style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5)),
                ],
              ),
              // Chip
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                    color: AppColors.secondaryGold.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const Spacer(),
          // Número
          Text(
            displayNumber,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TITULAR',
                      style: TextStyle(
                          color: AppColors.textDarkMuted,
                          fontSize: 9,
                          letterSpacing: 1)),
                  Text(displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('VENCE',
                      style: TextStyle(
                          color: AppColors.textDarkMuted,
                          fontSize: 9,
                          letterSpacing: 1)),
                  Text(displayExpiry,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Formulario PSE ─────────────────────────────────────────────────────────────

class _PseForm extends StatelessWidget {
  final TextEditingController bankCtrl;
  final TextEditingController docCtrl;
  final String docType;
  final ValueChanged<String> onDocTypeChanged;
  final bool isDark;

  const _PseForm({
    super.key,
    required this.bankCtrl,
    required this.docCtrl,
    required this.docType,
    required this.onDocTypeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final banks = [
      'Bancolombia',
      'Banco de Bogotá',
      'Davivienda',
      'BBVA Colombia',
      'Banco Popular',
      'Nequi (Bancolombia)',
      'AV Villas',
      'Banco Caja Social',
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Serás redirigido al portal de tu banco para autorizar el débito.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: bankCtrl.text.isEmpty ? null : bankCtrl.text,
          decoration: const InputDecoration(
            labelText: 'Banco *',
            prefixIcon: Icon(Icons.account_balance_rounded),
          ),
          items: banks
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) {
            if (v != null) bankCtrl.text = v;
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Selecciona tu banco' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                initialValue: docType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: ['CC', 'CE', 'NIT', 'PP']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onDocTypeChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: docCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Número de documento *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => (v == null || v.length < 5)
                    ? 'Documento inválido'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Formulario Nequi ──────────────────────────────────────────────────────────

class _NequiForm extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final bool isDark;

  const _NequiForm(
      {super.key, required this.phoneCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF6C1FBF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF6C1FBF).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C1FBF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pago con Nequi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Se enviará una notificación push a tu app Nequi.',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Número Nequi *',
            hintText: '3001234567',
            prefixIcon: Icon(Icons.phone_rounded),
            counterText: '',
          ),
          validator: (v) =>
              (v == null || v.length < 10) ? 'Ingresa tu número Nequi' : null,
        ),
      ],
    );
  }
}

// ── Información efectivo ──────────────────────────────────────────────────────

class _CashInfo extends StatelessWidget {
  final bool isDark;
  const _CashInfo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.stockGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.stockGreen.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  color: AppColors.stockGreen, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pago contra entrega',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Tu pedido será procesado y un asesor de Percucol se pondrá en contacto contigo para coordinar el pago y la entrega.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Resumen del pedido ────────────────────────────────────────────────────────

class _OrderSummaryBox extends StatelessWidget {
  final double totalAmount;
  final bool isDark;

  const _OrderSummaryBox(
      {required this.totalAmount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final subtotal = totalAmount;
    final shipping = 0.0; // gratis
    final total = subtotal + shipping;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'Subtotal',
              value: UIHelpers.formatCOP(subtotal),
              isDark: isDark),
          const SizedBox(height: 6),
          _SummaryRow(
              label: 'Envío',
              value: 'Gratis',
              valueColor: AppColors.stockGreen,
              isDark: isDark),
          const Divider(height: 16),
          _SummaryRow(
            label: 'Total',
            value: UIHelpers.formatCOP(total),
            bold: true,
            valueColor: AppColors.primaryGold,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary))),
      ],
    );
  }
}

// ── Sello de seguridad ─────────────────────────────────────────────────────────

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textDarkMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDarkMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
