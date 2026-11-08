import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/sale_model.dart';
import '../../providers/sale_provider.dart';

/// Pantalla de Gestión de Ventas para el Administrador de Percucol.
class SalesManagementScreen extends StatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  State<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    // SaleProvider carga ventas en su constructor; no se necesita llamada extra.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saleProvider = Provider.of<SaleProvider>(context);

    final filtered = _filterStatus == 'all'
        ? saleProvider.sales
        : saleProvider.sales.where((s) => s.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ventas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGold),
            onPressed: () => saleProvider.loadAllSales(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Métricas rápidas
          _MetricsHeader(
            totalSales: saleProvider.totalSales,
            totalRevenue: saleProvider.totalRevenue,
            isDark: isDark,
          ),

          // Filtros de estado
          _StatusFilterBar(
            current: _filterStatus,
            onChanged: (v) => setState(() => _filterStatus = v),
          ),

          // Lista de ventas
          Expanded(
            child: saleProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : filtered.isEmpty
                    ? _EmptySales(isDark: isDark)
                    : RefreshIndicator(
                        onRefresh: () => saleProvider.loadAllSales(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _SaleTile(
                            sale: filtered[i],
                            isDark: isDark,
                            onChangeStatus: (newStatus) async {
                              await saleProvider.updateStatus(filtered[i].id!, newStatus);
                              if (ctx.mounted) {
                                UIHelpers.showSnackBar(ctx,
                                    message: 'Estado actualizado a: ${_statusLabel(newStatus)}',
                                    isSuccess: true);
                              }
                            },
                            onDelete: () async {
                              final confirm = await UIHelpers.showConfirmationDialog(
                                context,
                                title: '¿Eliminar venta #${filtered[i].id}?',
                                content: 'Esta acción no se puede deshacer.',
                                confirmLabel: 'Eliminar',
                                isDestructive: true,
                              );
                              if (confirm) {
                                await saleProvider.deleteSale(filtered[i].id!);
                              }
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
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
}

// ─── Métricas ────────────────────────────────────────────────────────────────

class _MetricsHeader extends StatelessWidget {
  final int totalSales;
  final double totalRevenue;
  final bool isDark;

  const _MetricsHeader({
    required this.totalSales,
    required this.totalRevenue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Ventas',
                    style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                Text('$totalSales pedidos',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.black26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Ingresos Totales',
                    style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                Text(
                  UIHelpers.formatCOP(totalRevenue),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filtros ──────────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _StatusFilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Todos'),
      ('pending', 'Pendiente'),
      ('confirmed', 'Confirmado'),
      ('delivered', 'Entregado'),
      ('cancelled', 'Cancelado'),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: current == f.$1,
                    selectedColor: AppColors.primaryGold,
                    onSelected: (_) => onChanged(f.$1),
                    labelStyle: TextStyle(
                      color: current == f.$1 ? Colors.black : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Tile de venta ────────────────────────────────────────────────────────────

class _SaleTile extends StatelessWidget {
  final SaleModel sale;
  final bool isDark;
  final ValueChanged<String> onChangeStatus;
  final VoidCallback onDelete;

  const _SaleTile({
    required this.sale,
    required this.isDark,
    required this.onChangeStatus,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(sale.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '#${sale.id}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        title: Text(
          sale.userName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UIHelpers.formatCOP(sale.totalAmount),
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              _formatDate(sale.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            sale.statusLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        children: [
          // Items de la venta
          if (sale.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...sale.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.music_note_rounded, size: 14, color: AppColors.primaryGold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('${item.productName} x${item.quantity}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Text(
                              UIHelpers.formatCOP(item.subtotal),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGold),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                ],
              ),
            ),
          // Acciones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: onChangeStatus,
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'pending', child: Text('⏳ Pendiente')),
                      const PopupMenuItem(value: 'confirmed', child: Text('✅ Confirmado')),
                      const PopupMenuItem(value: 'delivered', child: Text('📦 Entregado')),
                      const PopupMenuItem(value: 'cancelled', child: Text('❌ Cancelado')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryGold),
                          SizedBox(width: 6),
                          Text('Cambiar Estado',
                              style: TextStyle(fontSize: 13, color: AppColors.primaryGold, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.outOfStockRed),
                  tooltip: 'Eliminar venta',
                ),
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
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptySales extends StatelessWidget {
  final bool isDark;
  const _EmptySales({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 72,
              color: (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)
                  .withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Sin ventas registradas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              )),
          const SizedBox(height: 6),
          Text('Las ventas aparecerán aquí cuando los clientes\nrealicen pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              )),
        ],
      ),
    );
  }
}

