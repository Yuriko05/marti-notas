import 'package:flutter/material.dart';

/// Sistema de tokens de diseño con colores corporativos
/// Paleta: tonos similares a la versión anterior pero más ligeros
/// Azul marino (ligero): #1E3C72
/// Naranja cálido (ligero): #F7A25A

class AppColors {
  // ============================================================================
  // COLORES CORPORATIVOS PRINCIPALES
  // ============================================================================

  /// Azul marino (más ligero) - Color principal
  // --------------------------------------------------------------------------
  // VARIANTAS SUAVES (puedes probar cualquiera cambiando los alias `active*`)
  // --------------------------------------------------------------------------

  // Variante 1 — Soft Navy + Apricot
  static const variantSoft1Primary =
      Color(0xFF274C7D); // más suave que el navy puro
  static const variantSoft1PrimaryLight = Color(0xFF5B82B8);
  static const variantSoft1PrimaryDark = Color(0xFF1B3658);

  static const variantSoft1Secondary = Color(0xFFF2B07C); // apricot suave
  static const variantSoft1SecondaryLight = Color(0xFFF7D4B0);
  static const variantSoft1SecondaryDark = Color(0xFFD8873E);

  // Variante 2 — Pastel Teal + Soft Apricot
  static const variantSoft2Primary = Color(0xFF2A7F7A); // pastel teal
  static const variantSoft2PrimaryLight = Color(0xFF66B9B4);
  static const variantSoft2PrimaryDark = Color(0xFF1D5E5A);

  static const variantSoft2Secondary = Color(0xFFF6C49A); // apricot claro
  static const variantSoft2SecondaryLight = Color(0xFFFCEDE0);
  static const variantSoft2SecondaryDark = Color(0xFFE09A5A);

  // Variante 3 — Muted Indigo + Peach
  static const variantSoft3Primary = Color(0xFF3B4A94); // indigo atenuado
  static const variantSoft3PrimaryLight = Color(0xFF7E8ED1);
  static const variantSoft3PrimaryDark = Color(0xFF2A3570);

  static const variantSoft3Secondary = Color(0xFFFFC9A8); // peach pálido
  static const variantSoft3SecondaryLight = Color(0xFFFFEDE4);
  static const variantSoft3SecondaryDark = Color(0xFFDB8A5A);

  // --------------------------------------------------------------------------
  // ALIAS ACTIVO — cambia aquí para probar otra variante rápidamente
  // --------------------------------------------------------------------------
  // Actualmente apuntamos a la Variante 1 (Soft Navy + Apricot).
  static const activePrimary = variantSoft1Primary;
  static const activePrimaryLight = variantSoft1PrimaryLight;
  static const activePrimaryDark = variantSoft1PrimaryDark;

  static const activeSecondary = variantSoft1Secondary;
  static const activeSecondaryLight = variantSoft1SecondaryLight;
  static const activeSecondaryDark = variantSoft1SecondaryDark;

  /// Azul / color principal (alias al activo)
  static const primary = activePrimary;
  static const primaryLight = activePrimaryLight;
  static const primaryDark = activePrimaryDark;

  /// Color secundario (alias al activo)
  static const secondary = activeSecondary;
  static const secondaryLight = activeSecondaryLight;
  static const secondaryDark = activeSecondaryDark;

  // ============================================================================
  // GRADIENTES CORPORATIVOS
  // ============================================================================

  static const gradientPrimary = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCorporate = LinearGradient(
    colors: [primary, primaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // ROLES DE USUARIO
  // ============================================================================

  /// Color para administradores
  static const adminColor = Color(0xFFE57373);
  static const adminLight = Color(0xFFFFCDD2);
  static const adminDark = Color(0xFFD32F2F);

  /// Color para usuarios normales
  static const userColor = Color(0xFF64B5F6);
  static const userLight = Color(0xFFBBDEFB);
  static const userDark = Color(0xFF1976D2);

  // ============================================================================
  // ESTADOS DE TAREAS
  // ============================================================================

  /// Tarea pendiente
  static const pendingColor = secondary; // usar naranja corporativo más claro
  static const pendingLight = secondaryLight;
  static const pendingDark = secondaryDark;

  /// Tarea completada
  static const completedColor = Color(0xFF81C784);
  static const completedLight = Color(0xFFC8E6C9);
  static const completedDark = Color(0xFF66BB6A);

  /// Tarea vencida
  static const overdueColor = Color(0xFFE57373);
  static const overdueLight = Color(0xFFFFCDD2);
  static const overdueDark = Color(0xFFD32F2F);

  /// Tarea en progreso
  static const inProgressColor = Color(0xFF64B5F6);
  static const inProgressLight = Color(0xFFBBDEFB);
  static const inProgressDark = Color(0xFF1976D2);

  // ============================================================================
  // PRIORIDADES
  // ============================================================================

  static const priorityHigh = Color(0xFFE57373);
  static const priorityMedium = secondary;
  static const priorityLow = Color(0xFF81C784);

  // ============================================================================
  // BACKGROUNDS
  // ============================================================================

  static const backgroundLight = Color(0xFFF5F7FA);
  static const backgroundMedium = Color(0xFFECEFF1);
  static const cardBackground = Colors.white;
  static const surfaceBackground = Color(0xFFFAFAFA);

  // ============================================================================
  // TEXTOS
  // ============================================================================

  static const textPrimary = primary; // Azul marino (ligero) para textos
  static const textSecondary = Color(0xFF546E7A);
  static const textTertiary = Color(0xFF78909C);
  static const textDisabled = Color(0xFFBDC3C7);
  static const textOnPrimary = Colors.white;
  static const textOnSecondary = Colors.white;

  // ============================================================================
  // BORDES Y DIVISORES
  // ============================================================================

  static const border = Color(0xFFE0E0E0);
  static const borderLight = Color(0xFFEEEEEE);
  static const divider = Color(0xFFE0E0E0);

  // ============================================================================
  // ESTADOS INTERACTIVOS
  // ============================================================================

  static const hover = Color(0xFFF5F5F5);
  static const pressed = Color(0xFFEEEEEE);
  static const focused = Color(0xFFF47C20); // Naranja corporativo

  // ============================================================================
  // ALERTAS Y NOTIFICACIONES
  // ============================================================================

  static const success = Color(0xFF66BB6A);
  static const warning = Color(0xFFF47C20); // Naranja corporativo
  static const error = Color(0xFFE57373);
  static const info = Color(0xFF64B5F6);

  // ============================================================================
  // SOMBRAS
  // ============================================================================

  static BoxShadow shadowSm = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMd = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static BoxShadow shadowLg = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );

  static BoxShadow shadowXl = BoxShadow(
    color: Colors.black.withValues(alpha: 0.10),
    blurRadius: 24,
    offset: const Offset(0, 12),
  );

  // Sombras con color corporativo
  static BoxShadow shadowPrimary = BoxShadow(
    color: primary.withValues(alpha: 0.2),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow shadowSecondary = BoxShadow(
    color: secondary.withValues(alpha: 0.3),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
}

// ==============================================================================
// ESPACIADO
// ==============================================================================

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// ==============================================================================
// BORDES REDONDEADOS
// ==============================================================================

class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;

  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

// ==============================================================================
// TIPOGRAFÍA
// ==============================================================================

class AppTextStyles {
  // Títulos grandes
  static const display1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const display2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.3,
  );

  // Títulos
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Subtítulos
  static const subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Cuerpo de texto
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Texto pequeño
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
    height: 1.6,
  );

  // Botones
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );
}

// ==============================================================================
// TEMA PRINCIPAL DE LA APLICACIÓN
// ==============================================================================

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colores principales
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBackground,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnSecondary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Tarjetas
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mdRadius,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mdRadius,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.smRadius,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mdRadius,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.focused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.body2,
        hintStyle: AppTextStyles.body2.copyWith(
          color: AppColors.textDisabled,
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Iconos
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundMedium,
        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
        labelStyle: AppTextStyles.caption,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.fullRadius,
        ),
      ),

      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.lgRadius,
        ),
        titleTextStyle: AppTextStyles.heading2,
        contentTextStyle: AppTextStyles.body1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.body2.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mdRadius,
        ),
      ),
    );
  }

  // Tema oscuro (opcional para futuro)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0A0F1F),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        surface: Color(0xFF1A1F35),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF0D1B45),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==============================================================================
// ANIMACIONES
// ==============================================================================

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
}

// ==============================================================================
// TAMAÑOS DE ÍCONOS
// ==============================================================================

class AppIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}
