import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 Swipzee Beautiful Light Theme - Pastel Colors
class SwipzeeColors {
  // Primary Colors - Soft and Beautiful
  static const Color fireOrange = Color(0xFFFF8A65); // Soft Orange
  static const Color accentPurple = Color(0xFFB39DDB); // Soft Purple
  
  // Secondary Colors - Pastel Palette
  static const Color mintGreen = Color(0xFF81C784); // Soft Mint
  static const Color softPink = Color(0xFFF8BBD9); // Soft Pink
  static const Color lightBlue = Color(0xFF90CAF9); // Soft Blue
  static const Color lightYellow = Color(0xFFFFF176); // Soft Yellow
  
  // Neutral Colors - Light and Clean
  static const Color lightGray = Color(0xFFF5F5F5); // Very Light Gray
  static const Color white = Color(0xFFFFFFFF); // Pure White
  static const Color darkGray = Color(0xFF424242); // Soft Dark Gray
  static const Color mediumGray = Color(0xFF9E9E9E); // Medium Gray
  
  // Additional Colors
  static const Color black = Color(0xFF000000);
  static const Color error = Color(0xFFE57373); // Soft Red
  static const Color success = Color(0xFF81C784); // Soft Green
  static const Color warning = Color(0xFFFFB74D); // Soft Orange
}

// 🎨 Swipzee Typography System
class SwipzeeTypography {
  // Headings / Titles → Bricolage Grotesque Bold (primary headings)
  static TextStyle get heading1 => GoogleFonts.bricolageGrotesque(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get heading2 => GoogleFonts.bricolageGrotesque(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get heading3 => GoogleFonts.bricolageGrotesque(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get heading4 => GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get titleMedium => GoogleFonts.bricolageGrotesque(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: SwipzeeColors.darkGray,
  );
  
  // Body Text / Content → Inter (clean, readable)
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: SwipzeeColors.mediumGray,
  );
  
  // UI Labels / Buttons → Poppins (friendly, modern)
  static TextStyle get buttonLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SwipzeeColors.white,
  );
  
  static TextStyle get buttonMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: SwipzeeColors.white,
  );
  
  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SwipzeeColors.white,
  );
  
  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SwipzeeColors.darkGray,
  );
  
  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SwipzeeColors.mediumGray,
  );
  
  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: SwipzeeColors.mediumGray,
  );
  
  // Captions
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: SwipzeeColors.mediumGray,
  );
}

// 🎨 Swipzee Beautiful Light Theme
class SwipzeeTheme {
  static ThemeData get lightTheme {
    return ThemeData(
  useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme - Beautiful Pastels
      colorScheme: const ColorScheme.light(
        primary: SwipzeeColors.fireOrange,
        secondary: SwipzeeColors.accentPurple,
        surface: SwipzeeColors.white,
        error: SwipzeeColors.error,
        onPrimary: SwipzeeColors.white,
        onSecondary: SwipzeeColors.white,
        onSurface: SwipzeeColors.darkGray,
        onError: SwipzeeColors.white,
        outline: SwipzeeColors.mediumGray,
      ),
      
      // App Bar Theme
  appBarTheme: AppBarTheme(
        backgroundColor: SwipzeeColors.white,
        foregroundColor: SwipzeeColors.darkGray,
    elevation: 0,
        centerTitle: true,
        titleTextStyle: SwipzeeTypography.heading3,
        iconTheme: const IconThemeData(
          color: SwipzeeColors.darkGray,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: SwipzeeColors.white,
        elevation: 2,
        shadowColor: SwipzeeColors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SwipzeeColors.fireOrange,
          foregroundColor: SwipzeeColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: SwipzeeTypography.buttonMedium,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SwipzeeColors.accentPurple,
          textStyle: SwipzeeTypography.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SwipzeeColors.accentPurple,
          side: const BorderSide(color: SwipzeeColors.accentPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: SwipzeeTypography.buttonMedium,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SwipzeeColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwipzeeColors.mediumGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwipzeeColors.mediumGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwipzeeColors.accentPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwipzeeColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwipzeeColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: SwipzeeTypography.bodyMedium.copyWith(
          color: SwipzeeColors.mediumGray,
        ),
        labelStyle: SwipzeeTypography.labelMedium,
        errorStyle: SwipzeeTypography.caption.copyWith(
          color: SwipzeeColors.error,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SwipzeeColors.white,
        selectedItemColor: SwipzeeColors.fireOrange,
        unselectedItemColor: SwipzeeColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SwipzeeColors.fireOrange,
        foregroundColor: SwipzeeColors.white,
        elevation: 4,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: SwipzeeColors.mediumGray,
        thickness: 0.5,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: SwipzeeColors.lightGray,
        selectedColor: SwipzeeColors.accentPurple,
        disabledColor: SwipzeeColors.mediumGray,
        labelStyle: SwipzeeTypography.labelMedium,
        secondaryLabelStyle: SwipzeeTypography.labelMedium.copyWith(
          color: SwipzeeColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: SwipzeeTypography.heading1,
        displayMedium: SwipzeeTypography.heading2,
        displaySmall: SwipzeeTypography.heading3,
        headlineLarge: SwipzeeTypography.heading2,
        headlineMedium: SwipzeeTypography.heading3,
        headlineSmall: SwipzeeTypography.heading4,
        titleLarge: SwipzeeTypography.heading4,
        titleMedium: SwipzeeTypography.titleMedium,
        titleSmall: SwipzeeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: SwipzeeTypography.bodyLarge,
        bodyMedium: SwipzeeTypography.bodyMedium,
        bodySmall: SwipzeeTypography.bodySmall,
        labelLarge: SwipzeeTypography.labelLarge,
        labelMedium: SwipzeeTypography.labelMedium,
        labelSmall: SwipzeeTypography.labelSmall,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: SwipzeeColors.darkGray,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: SwipzeeColors.fireOrange,
        size: 24,
      ),
    );
  }
}

// 🎨 Swipzee Custom Widget Styles
class SwipzeeStyles {
  // Card Styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: SwipzeeColors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: SwipzeeColors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Gradient Styles
  static LinearGradient get fireGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SwipzeeColors.fireOrange, Color(0xFFFFAB91)],
  );
  
  static LinearGradient get purpleGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SwipzeeColors.accentPurple, Color(0xFFCE93D8)],
  );
  
  static LinearGradient get mintGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SwipzeeColors.mintGreen, Color(0xFFA5D6A7)],
  );
  
  static LinearGradient get pinkGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SwipzeeColors.softPink, Color(0xFFF8BBD9)],
  );
  
  static LinearGradient get blueGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SwipzeeColors.lightBlue, Color(0xFFBBDEFB)],
  );
  
  // Button Styles
  static ButtonStyle get fireButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: SwipzeeColors.fireOrange,
    foregroundColor: SwipzeeColors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );
  
  static ButtonStyle get purpleButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: SwipzeeColors.accentPurple,
    foregroundColor: SwipzeeColors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );
  
  static ButtonStyle get mintButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: SwipzeeColors.mintGreen,
    foregroundColor: SwipzeeColors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );
}

// 🎨 Swipzee Animation Curves
class SwipzeeAnimations {
  static const Curve swipeCurve = Curves.easeOutBack;
  static const Curve cardTransition = Curves.easeInOutCubic;
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

// Global navigator key for easy navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Export the themes
final ThemeData lightTheme = SwipzeeTheme.lightTheme;