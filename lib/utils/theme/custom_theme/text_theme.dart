import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FTextTheme {
    FTextTheme._();

    static TextTheme lightTextTheme = TextTheme(
        // Headlines (biggest titles)
        displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.secondaryColor), // Koulen 36 Regular
        displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 32, fontWeight: FontWeight.w400, color: FColors.black), // Koulen 32 Regular
        displaySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w700, color: FColors.black), // Poppins 32 Bold

        // Headlines (section headers)
        headlineLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w500, color: FColors.black), // Poppins 28 Medium
        headlineMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.black), // Poppins 24 Regular
        headlineSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w500, color: FColors.black), // Poppins 20 Medium

        // Titles
        titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w400, color: FColors.black), // Poppins 20 Regular
        titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: FColors.black), // Poppins 18 SemiBold
        titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.black), // Poppins 16 SemiBold

        // Body
        bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.black), // Poppins 16 Regular
        bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: FColors.black), // Poppins 15 SemiBold
        bodySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.black), // Poppins 14 Regular

        // Labels & Captions
        labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.black), // Poppins 14 Medium
        labelMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: FColors.black), // Poppins 13 Regular
        labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.black), // Poppins 12 Medium
    );

    static TextTheme darkTextTheme = TextTheme(
        displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.white),
        displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 32, fontWeight: FontWeight.w400, color: FColors.white),
        displaySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w700, color: FColors.white),

        headlineLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w500, color: FColors.white),
        headlineMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.white),
        headlineSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w500, color: FColors.white),

        titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w400, color: FColors.white),
        titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: FColors.white),
        titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.white),

        bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.white),
        bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: FColors.white),
        bodySmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.white),

        labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.white),
        labelMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: FColors.white),
        labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.white),
    );
}





// import 'package:flutter/material.dart';
// import '../../constants/colors.dart';
//
// class FTextTheme {
//     FTextTheme._();
//
//     static TextTheme lightTextTheme = TextTheme(
//         // Headlines
//         displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 57, fontWeight: FontWeight.w400, color: FColors.black),
//         displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 45, fontWeight: FontWeight.w400, color: FColors.black),
//         displaySmall: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.black),
//
//         headlineLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 31, fontWeight: FontWeight.w400, color: FColors.black), // your original
//         headlineMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.black), // your original
//         headlineSmall: const TextStyle(fontFamily: 'Koulen', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.black), // your original
//
//         // Titles
//         titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.black), // your original
//         titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: FColors.black), // your original
//         titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.black),
//
//         // Body
//         bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.black), // your original
//         bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.normal, color: FColors.black), // your original
//         bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5)), // your original
//
//         // Labels
//         labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.black), // your original
//         labelMedium: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5)), // your original
//         labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400, color: FColors.black),
//     );
//
//     static TextTheme darkTextTheme = TextTheme(
//         // Headlines
//         displayLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 57, fontWeight: FontWeight.w400, color: FColors.white),
//         displayMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 45, fontWeight: FontWeight.w400, color: FColors.white),
//         displaySmall: const TextStyle(fontFamily: 'Koulen', fontSize: 36, fontWeight: FontWeight.w400, color: FColors.white),
//
//         headlineLarge: const TextStyle(fontFamily: 'Koulen', fontSize: 31, fontWeight: FontWeight.w400, color: FColors.white), // your original
//         headlineMedium: const TextStyle(fontFamily: 'Koulen', fontSize: 24, fontWeight: FontWeight.w400, color: FColors.white), // your original
//         headlineSmall: const TextStyle(fontFamily: 'Koulen', fontSize: 16, fontWeight: FontWeight.w400, color: FColors.white), // your original
//
//         // Titles
//         titleLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: FColors.white), // your original
//         titleMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: FColors.white), // your original
//         titleSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: FColors.white),
//
//         // Body
//         bodyLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.white), // your original
//         bodyMedium: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.normal, color: FColors.white), // your original
//         bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5)), // your original
//
//         // Labels
//         labelLarge: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.white), // your original
//         labelMedium: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5)), // your original
//         labelSmall: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w400, color: FColors.white),
//     );
// }
