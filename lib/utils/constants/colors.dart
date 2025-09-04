import 'package:flutter/material.dart';

/// App Color Palette for consistent UI styling.
class FColors {
  FColors._(); // Prevent instantiation

  // -------------------------------------------------
  // Brand Colors
  // -------------------------------------------------
  static const Color primaryColor = Color(0xFFFFC300); // Brand Yellow
  static const Color secondaryColor = Color(0xFF003566); // Deep Navy
  static const Color accentColor = Color(0xFF4285F4); // Accent Blue

  // Input Fields Colors
  static const Color phoneInputField = Color(0xFFe3e3e3);
  static const Color radioField = Color(0xFFF2F2F2);
  static const Color rideTypeBg = Color(0xFFd9d9d9);

  // Button Colors
  static const Color buttonPrimary = Color(0xFFbd2c26);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);
  static const Color buttonWhatsApp = Color(0xFF089F00);

  // -------------------------------------------------
  // Hailey Shades (Brand-specific shades)
  // -------------------------------------------------
  static const Color hailey100 = Color(0xFFF3F6FE);
  static const Color hailey500 = Color(0xFF80A5F6);
  static const Color hailey600 = Color(0xFF4285F4);
  static const Color hailey700 = Color(0xFF3B77DA);
  static const Color hailey800 = Color(0xFF3367BD);
  static const Color hailey900 = Color(0xFF2A549A);
  static const Color hailey1000 = Color(0xFF1E3B6D);

  // -------------------------------------------------
  // Neutral & Grayscale
  // -------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black12 = Color(0x1F000000); // For shadows/overlays
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFeeeeee);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFA3A3A3); // lead400
  static const Color grey500 = Color(0xFF939393); // darkGrey
  static const Color grey600 = Color(0xFF6C757D); // textSecondary
  static const Color grey700 = Color(0xFF4F4F4F); // darkerGrey
  static const Color grey800 = Color(0xFF333333); // textPrimary

  // -------------------------------------------------
  // Text Colors
  // -------------------------------------------------
  static const Color textPrimary = grey800;
  static const Color textSecondary = grey600;
  static const Color textWhite = white;
  static const Color textMuted = grey500;
  static const Color textGreen = Color(0xFF34A853);
  static const Color textGreenBG = Color(0xFFF2F8F3);
  static const Color textGrey = Color(0xFF767676);
  static const Color textWarning = Color(0xFFF57C00);
  static const Color textError = Color(0xFFD32F2F);

  // -------------------------------------------------
  // Background Colors
  // -------------------------------------------------
  static const Color backgroundLight = Color(0xFFF6F6F6);
  static const Color backgroundDark = Color(0xFF272727);
  static const Color backgroundPrimary = Color(0xFFF3F5FF);
  static const Color lightContainer = Color(0xFFF6F6F6);
  static const Color darkLightContainer = Color(0xFFE3E8EB);
  static Color darkContainer = white.withOpacity(0.1);

  // -------------------------------------------------
  // Border Colors
  // -------------------------------------------------
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);
  static const Color borderNormal = Color(0xFFF2F2F2);
  static const Color borderHard = Color(0xFFE5E5E5);
  static const Color borderDivider = Color(0xFFC7C7C7);

  // -------------------------------------------------
  // Status & Feedback Colors
  // -------------------------------------------------
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  static const Color rating = Color(0xFFFBBC05);

  // -------------------------------------------------
  // Overlays & Transparency
  // -------------------------------------------------
  static const Color transparent = Color(0x00000000);
  static const Color overlayLight = Color(0x66FFFFFF); // 40% white
  static const Color overlayDark = Color(0x66000000); // 40% black

  // -------------------------------------------------
  // Gradients
  // -------------------------------------------------
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFC300), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF003566), Color(0xFF001D3D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
