import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'custom_theme/elevatedButton_theme.dart';
import 'custom_theme/text_theme.dart';
import 'custom_theme/appbar_theme.dart';
import 'custom_theme/bottomsheet_theme.dart';

class FAppTheme {
  FAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: FColors.primaryColor,
    scaffoldBackgroundColor: FColors.white,
    appBarTheme: FAppBarTheme.lightAppBarTheme,
    bottomSheetTheme: FBottomSheetTheme.lightBottomSheetTheme,
    textTheme: FTextTheme.lightTextTheme,
    elevatedButtonTheme: FElevatedButtonTheme.lightElevatedButtonTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: FColors.primaryColor,
    scaffoldBackgroundColor: FColors.black,
    appBarTheme: FAppBarTheme.darkAppBarTheme,
    bottomSheetTheme: FBottomSheetTheme.darkBottomSheetTheme,
    textTheme: FTextTheme.darkTextTheme,
    elevatedButtonTheme: FElevatedButtonTheme.darkElevatedButtonTheme,
  );
}
