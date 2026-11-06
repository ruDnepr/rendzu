import 'package:flutter/material.dart';

/// Цветовая схема «Рэндзю для Дианы» — тёплые древесные тона, яркие акценты.
/// Соответствует оформлению «Шашек для Дианы»: та же тёплая палитра.
class AppColors {
  AppColors._();

  // Фоны
  static const Color cream = Color(0xFFFFF8E7);
  static const Color creamDark = Color(0xFFF5E8C7);
  static const Color warmWhite = Color(0xFFFFFDF7);

  // Дерево доски
  static const Color woodLight = Color(0xFFE2B87C);
  static const Color woodMid = Color(0xFFD4A574);
  static const Color woodDark = Color(0xFFB8864E);
  static const Color woodLine = Color(0xFF5D4037);

  // Камни
  static const Color stoneBlack = Color(0xFF1A1A1A);
  static const Color stoneBlackHi = Color(0xFF6E6E6E);
  static const Color stoneWhite = Color(0xFFFBFBF6);
  static const Color stoneWhiteEdge = Color(0xFFC9C2B5);

  // Акценты
  static const Color coral = Color(0xFFFF7A5C);
  static const Color coralDark = Color(0xFFE85A3C);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color skyDark = Color(0xFF29B6F6);
  static const Color sunflower = Color(0xFFFFC857);
  static const Color grass = Color(0xFF7CB342);

  // Текст
  static const Color textDark = Color(0xFF3E2723);
  static const Color textMid = Color(0xFF6D4C41);
  static const Color textLight = Color(0xFF8D6E63);

  // Подсказки
  static const Color hintMove = Color(0x554FC3F7);
  static const Color hintThree = Color(0x66FFC857);
  static const Color hintFour = Color(0x66FF7A5C);
  static const Color forbiddenMarker = Color(0xCCFF1744);
  static const Color lastMoveRing = Color(0xFFFFC857);
}

/// Светлая тема приложения.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.light,
      primary: AppColors.coral,
      secondary: AppColors.sky,
      surface: AppColors.cream,
      background: AppColors.cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark),
        displayMedium: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark),
        headlineSmall: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark),
        titleLarge: TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark),
        bodyLarge: TextStyle(
            fontFamily: 'Nunito', fontSize: 16, color: AppColors.textDark),
        bodyMedium: TextStyle(
            fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid),
        labelLarge: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          elevation: 3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coral,
          side: const BorderSide(color: AppColors.coral, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Baloo2',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.warmWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }
}
