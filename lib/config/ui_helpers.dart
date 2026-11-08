import 'dart:io';
import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

/// Funciones auxiliares de formateo monetario y diálogos de UI elegantes.
class UIHelpers {
  /// Formatea valores numéricos a formato de moneda (COP / USD)
  static String formatCurrency(double amount) {
    final integerPart = amount.toInt();
    final formatted = integerPart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '\$$formatted COP';
  }

  /// Alias conveniente para formatear en Pesos Colombianos
  static String formatCOP(double amount) => formatCurrency(amount);

  /// Muestra un SnackBar moderno y flotante con estilo premium
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color bgColor = AppColors.darkCardElevated;
    Color iconColor = AppColors.primaryGold;
    IconData displayIcon = icon ?? Icons.info_outline;

    if (isError) {
      bgColor = const Color(0xFF2E1717);
      iconColor = AppColors.outOfStockRed;
      displayIcon = icon ?? Icons.error_outline_rounded;
    } else if (isSuccess) {
      bgColor = const Color(0xFF14291F);
      iconColor = AppColors.stockGreen;
      displayIcon = icon ?? Icons.check_circle_outline_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: iconColor.withValues(alpha: 0.4), width: 1),
        ),
        content: Row(
          children: [
            Icon(displayIcon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  /// Muestra un modal de confirmación elegante para operaciones destructivas (Eliminar)
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.outOfStockRed.withValues(alpha: 0.15)
                      : AppColors.primaryGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                  color: isDestructive ? AppColors.outOfStockRed : AppColors.primaryGold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? AppColors.outOfStockRed : AppColors.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

/// Badge reutilizable para el estado de stock
class StockBadge extends StatelessWidget {
  final int stock;
  final bool compact;

  const StockBadge({
    super.key,
    required this.stock,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool inStock = stock > 0;
    final Color color = inStock ? AppColors.stockGreen : AppColors.outOfStockRed;
    final Color bgColor = inStock
        ? AppColors.stockGreen.withValues(alpha: 0.15)
        : AppColors.outOfStockRed.withValues(alpha: 0.15);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            inStock ? (compact ? 'Stock: $stock' : 'En Stock ($stock)') : 'Agotado',
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget inteligente que muestra imágenes locales del dispositivo (File)
/// o imágenes web (Network) con fallback elegante para Percucol.
class ProductImageView extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  const ProductImageView({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imagePath.trim();
    if (trimmed.isEmpty) {
      return _buildFallback();
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    try {
      final file = File(trimmed);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    } catch (_) {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.primaryGold,
        size: iconSize,
      ),
    );
  }
}
