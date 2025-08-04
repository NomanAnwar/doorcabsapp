import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class FTextTheme {
  FTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
      headlineLarge: const TextStyle().copyWith(fontSize: 31, fontFamily: 'MadaRegular', color: FColors.black,),
      headlineMedium: const TextStyle().copyWith(fontSize: 24, fontFamily: 'MadaRegular', color: FColors.black,),
      headlineSmall: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', color: FColors.black,),


      titleLarge: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w600, color: FColors.black,),
      titleMedium: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.black,),
      titleSmall: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w400, color: FColors.black,),

      bodyLarge: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.black,),
      bodyMedium: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.normal, color: FColors.black,),
      bodySmall: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5),),


      labelLarge: const TextStyle().copyWith(fontSize: 12, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.black,),
      labelMedium: const TextStyle().copyWith(fontSize: 12, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.black.withOpacity(0.5),),
  );

  static TextTheme darkTextTheme = TextTheme(
      headlineLarge: const TextStyle().copyWith(fontSize: 31, fontFamily: 'MadaRegular', color: FColors.white,),
      headlineMedium: const TextStyle().copyWith(fontSize: 24, fontFamily: 'MadaRegular', color: FColors.white,),
      headlineSmall: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', color: FColors.white,),


      titleLarge: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w600, color: FColors.white,),
      titleMedium: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.white,),
      titleSmall: const TextStyle().copyWith(fontSize: 16, fontFamily: 'MadaRegular', fontWeight: FontWeight.w400, color: FColors.white,),

      bodyLarge: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.white,),
      bodyMedium: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.normal, color: FColors.white,),
      bodySmall: const TextStyle().copyWith(fontSize: 14, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5),),


      labelLarge: const TextStyle().copyWith(fontSize: 12, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.white,),
      labelMedium: const TextStyle().copyWith(fontSize: 12, fontFamily: 'MadaRegular', fontWeight: FontWeight.w500, color: FColors.white.withOpacity(0.5),),
  );

}
