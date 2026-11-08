import 'package:flutter/material.dart';

/// Paleta de colores premium para Percucol.
/// Inspirada en maderas nobles (ébano, nogal, caoba), parches de cuero
/// y herrajes de bronce/oro para instrumentos de percusión.
class AppColors {
  // --- Colores Principales (Gold / Amber / Bronze) ---
  static const Color primaryGold = Color(0xFFD4881A);
  static const Color secondaryGold = Color(0xFFE5A93C);
  static const Color lightGold = Color(0xFFFFD580);
  static const Color bronze = Color(0xFFA66A2C);
  static const Color deepBronze = Color(0xFF7A4A1C);

  // --- Modo Oscuro (Ébano, Carbón y Caoba Nocturna) ---
  static const Color darkBackground = Color(0xFF111113);
  static const Color darkSurface = Color(0xFF191817);
  static const Color darkCard = Color(0xFF23201D);
  static const Color darkCardElevated = Color(0xFF2C2723);
  static const Color darkBorder = Color(0xFF38322C);
  static const Color darkInput = Color(0xFF1E1B19);

  // --- Modo Claro (Pergamino, Madera Clara y Cárstico Cálido) ---
  static const Color lightBackground = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF9F7F3);
  static const Color lightBorder = Color(0xFFE4DFD5);
  static const Color lightInput = Color(0xFFF2EFE9);

  // --- Tipografía y Contraste ---
  static const Color textDarkPrimary = Color(0xFFF7F4EE);
  static const Color textDarkSecondary = Color(0xFFAAA195);
  static const Color textDarkMuted = Color(0xFF6E675D);

  static const Color textLightPrimary = Color(0xFF1F1C18);
  static const Color textLightSecondary = Color(0xFF686055);
  static const Color textLightMuted = Color(0xFF9E9588);

  // --- Estados y Badges ---
  static const Color stockGreen = Color(0xFF10B981);
  static const Color inStock = stockGreen;
  static const Color stockGreenLight = Color(0xFFD1FAE5);
  static const Color outOfStockRed = Color(0xFFEF4444);
  static const Color outOfStockRedLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // --- Degradados Especiales ---
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5A93C), Color(0xFFD4881A), Color(0xFFA66A2C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF2A2522), Color(0xFF1E1B19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E1610), Color(0xFF0F0E0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

