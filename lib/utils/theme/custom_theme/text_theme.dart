import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FTextTheme {
    FTextTheme._();

    static TextTheme lightTextTheme = TextTheme(
        // Headlines
        displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 57, fontWeight: FontWeight.w400, color: FColors.black),
        displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 45, fontWeight: FontWeight.w400, color: FColors.black),
        displaySmall: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.black),

        headlineLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 31, fontWeight: FontWeight.w400, color: FColors.black), // your original
        headlineMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.black), // your original
        headlineSmall: const TextStyle(fontFamily: 'Koulen', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.black), // your original

        // Titles
        titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.black), // your original
        titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: FColors.black), // your original
        titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.black),

        // Body
        bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.black), // your original
        bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.normal, color: FColors.black), // your original
        bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5)), // your original

        // Labels
        labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.black), // your original
        labelMedium: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5)), // your original
        labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400, color: FColors.black),
    );

    static TextTheme darkTextTheme = TextTheme(
        // Headlines
        displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 57, fontWeight: FontWeight.w400, color: FColors.white),
        displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 45, fontWeight: FontWeight.w400, color: FColors.white),
        displaySmall: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.white),

        headlineLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 31, fontWeight: FontWeight.w400, color: FColors.white), // your original
        headlineMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.white), // your original
        headlineSmall: const TextStyle(fontFamily: 'Koulen', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.white), // your original

        // Titles
        titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.white), // your original
        titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: FColors.white), // your original
        titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.white),

        // Body
        bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.white), // your original
        bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.normal, color: FColors.white), // your original
        bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5)), // your original

        // Labels
        labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.white), // your original
        labelMedium: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5)), // your original
        labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400, color: FColors.white),
    );
}
