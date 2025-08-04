import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class FTextFormFieldTheme{

  FTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationtheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: FColors.grey,
    suffixIconColor: FColors.grey,

    labelStyle: const TextStyle().copyWith(fontSize: 16,color: FColors.black),
    hintStyle: const TextStyle().copyWith(fontSize: 16,color: FColors.black),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),

    floatingLabelStyle: const TextStyle().copyWith(color: FColors.black.withOpacity(0.8)),
    border: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey)
    ),
    enabledBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey)
    ),
    focusedBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.black12)
    ),
    errorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.red)
    ),
    focusedErrorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.orange)
    ),
  );

  static InputDecorationTheme darkInputDecorationtheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: FColors.grey,
    suffixIconColor: FColors.grey,

    labelStyle: const TextStyle().copyWith(fontSize: 16,color: FColors.white),
    hintStyle: const TextStyle().copyWith(fontSize: 16,color: FColors.white),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),

    floatingLabelStyle: const TextStyle().copyWith(color: FColors.white.withOpacity(0.8)),
    border: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey)
    ),
    enabledBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.grey)
    ),
    focusedBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.white)
    ),
    errorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.red)
    ),
    focusedErrorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: FColors.orange)
    ),
  );

}