import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FTextFormFieldTheme {
  FTextFormFieldTheme._();

  /// Light Theme for Input Fields
  static final InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: FColors.textSecondary,
    suffixIconColor: FColors.textSecondary,

    labelStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: FColors.textPrimary,
    ),
    hintStyle: const TextStyle(
      fontSize: 16,
      color: FColors.textMuted,
    ),
    errorStyle: const TextStyle(
      fontStyle: FontStyle.normal,
      color: FColors.textError,
    ),

    floatingLabelStyle: const TextStyle(
      color: FColors.primaryColor,
      fontWeight: FontWeight.w600,
    ),

    // Borders
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.borderPrimary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: FColors.primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: FColors.warning),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  );

  /// Dark Theme for Input Fields
  static final InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: FColors.grey400,
    suffixIconColor: FColors.grey400,

    labelStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: FColors.textWhite,
    ),
    hintStyle: const TextStyle(
      fontSize: 16,
      color: FColors.textMuted,
    ),
    errorStyle: const TextStyle(
      fontStyle: FontStyle.normal,
      color: FColors.textError,
    ),

    floatingLabelStyle: const TextStyle(
      color: FColors.primaryColor,
      fontWeight: FontWeight.w600,
    ),

    // Borders
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey600),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey600),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: FColors.primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: FColors.warning),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  );
}
