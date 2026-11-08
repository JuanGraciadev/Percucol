import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sale_provider.dart';

/// Historial de pedidos del cliente en Percucol.
/// Escucha al SaleProvider para reflejar cambios de estado del administrador
/// en tiempo real (sin necesidad de recargar manualmente).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);

    if (user != null) {
      await saleProvider.loadUserSalesIntoState(user.id!);
    } else {
      saleProvider.clearUserOrders();
    }

    if (mounted && _firstLoad) setState(() => _firstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios del SaleProvider para refrescar cuando el admin
    // actualiza un estado desde el panel de administración
    final saleProvider = Provider.of<SaleProvider>(context);
    final orders = saleProvider.userOrders;
    final isLoading = saleProvider.isLoadingUserOrders || _firstLoad;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGold),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : orders.isEmpty
              ? _EmptyOrders(isDark: isDark)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) =>
                        _OrderCard(order: orders[i], isDark: isDark),
                  ),
                ),
    );
  }
}

// ── Tarjeta de pedido ─────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final SaleModel order;
  final bool isDark;

  const _OrderCard({required this.order, required this.isDark});

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return AppColors.primaryGold;
      case 'delivered':
        return AppColors.inStock;
      case 'cancelled':
        return AppColors.outOfStockRed;
      default:
        return AppColors.info;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusDescription(String s) {
    switch (s) {
      case 'confirmed':
        return 'Tu pedido fue confirmado y está siendo preparado.';
      case 'delivered':
        return '¡Tu pedido fue entregado! Esperamos que lo disfrutes.';
      case 'cancelled':
        return 'Este pedido fue cancelado.';
      default:
        return 'Tu pedido está en cola de procesamiento.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.status == 'delivered'
              ? AppColors.inStock.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: order.status == 'delivered' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Ícono de estado
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(order.status), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                // Número y fecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido #${order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(_formatDate(order.createdAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightMuted)),
                    ],
                  ),
                ),
                // Badge de estado
                _StatusBadge(status: order.status, color: color),
              ],
            ),
          ),

          // ── Barra de progreso del pedido ──────────────────────────────────
          _OrderProgressBar(status: order.status),

          // ── Descripción del estado ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _statusDescription(order.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Productos ─────────────────────────────────────────────────────
          if (order.items.isNotEmpty) ...[
            Divider(
                height: 1,
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Text('Productos',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text('${order.items.length} artículo(s)',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted)),
                ],
              ),
            ),
            ...order.items.map((item) => _ProductItemRow(
                  item: item,
                  isDark: isDark,
                  isCancelled: order.status == 'cancelled',
                )),
          ],

          // ── Total ─────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total pagado',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary)),
                Text(UIHelpers.formatCOP(order.totalAmount),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${months[dt.month - 1]}. ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Badge de estado ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  String get _label {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ── Barra de progreso ─────────────────────────────────────────────────────────

class _OrderProgressBar extends StatelessWidget {
  final String status;
  const _OrderProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    // pending=0, confirmed=1, delivered=2, cancelled=-1
    final steps = ['Pendiente', 'Confirmado', 'Entregado'];
    final isCancelled = status == 'cancelled';
    int current = 0;
    if (status == 'confirmed') current = 1;
    if (status == 'delivered') current = 2;

    if (isCancelled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.outOfStockRed, size: 16),
            const SizedBox(width: 6),
            Text('Pedido cancelado',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.outOfStockRed,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Línea conectora
            final filled = i ~/ 2 < current;
            return Expanded(
              child: Container(
                height: 2,
                color: filled
                    ? AppColors.primaryGold
                    : AppColors.darkBorder.withValues(alpha: 0.4),
              ),
            );
          }
          // Paso
          final step = i ~/ 2;
          final isDone = step < current;
          final isActive = step == current;
          Color c = isDone || isActive ? AppColors.primaryGold : AppColors.darkBorder;

          return Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primaryGold
                      : (isActive
                          ? AppColors.primaryGold.withValues(alpha: 0.2)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 1.8),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                    : isActive
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.primaryGold,
                                  shape: BoxShape.circle),
                            ))
                        : null,
              ),
              const SizedBox(height: 3),
              Text(steps[step],
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isDone
                          ? AppColors.primaryGold
                          : AppColors.textDarkMuted)),
            ],
          );
        }),
      ),
    );
  }
}

// ── Fila de producto en el pedido ──────────────────────────────────────────────

class _ProductItemRow extends StatelessWidget {
  final SaleItemModel item;
  final bool isDark;
  final bool isCancelled;

  const _ProductItemRow({
    required this.item,
    required this.isDark,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          // Foto del producto guardada al momento de la compra
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ColorFiltered(
              colorFilter: isCancelled
                  ? const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ])
                  : const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply),
              child: Container(
                width: 56,
                height: 56,
                color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                child: ProductImageView(
                  imagePath: item.productImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  iconSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre y cantidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCancelled
                          ? (isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted)
                          : (isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textLightPrimary),
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${UIHelpers.formatCOP(item.unitPrice)} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
              ],
            ),
          ),
          // Subtotal
          Text(UIHelpers.formatCOP(item.subtotal),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCancelled
                    ? (isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted)
                    : AppColors.primaryGold,
              )),
        ],
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  final bool isDark;
  const _EmptyOrders({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 80,
              color: (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)
                  .withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Aún no tienes pedidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              )),
          const SizedBox(height: 8),
          Text('Explora el catálogo y realiza tu primera compra.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.clientCatalog),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Ver Catálogo'),
          ),
        ],
      ),
    );
  }
}
