import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'custom_theme/elevatedButton_theme.dart';
import 'custom_theme/text_theme.dart';

class FAppTheme {
  FAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'MadaBold, MadaMedium, MadaRegular',
    brightness: Brightness.light,
    primaryColor: FColors.primaryColor,
    scaffoldBackgroundColor: FColors.white,
    textTheme: FTextTheme.lightTextTheme,
    elevatedButtonTheme: FElevatedButtonTheme.lightElevatedButtonTheme
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'MadaBold, MadaMedium, MadaRegular',
    brightness: Brightness.dark,
    primaryColor: FColors.primaryColor,
    scaffoldBackgroundColor: FColors.black,
    textTheme: FTextTheme.darkTextTheme,
    elevatedButtonTheme: FElevatedButtonTheme.darkElevatedButtonTheme,
  );
}
