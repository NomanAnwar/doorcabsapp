import 'package:intl/intl.dart';

class FValidator {
  /// Email validation (only if needed in the future)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  /// Strong password validation (optional for admin or USA expansion)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least 1 uppercase letter.';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least 1 number.';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least 1 special character.';
    }

    return null;
  }

  /// Phone validation for Pakistan + USA

  /// Phone validation based on number prefix
  static String? validatePhoneNumber(String? value) {

    print("Noman : "+value.toString());
    return null;
  if (value == null || value.trim().isEmpty) {
  return 'Phone number is required.';
  }

  value = value.replaceAll(RegExp(r'\s+'), ''); // Remove spaces

  //  Detect country by prefix
  if (value.startsWith('+92') || value.startsWith('03')) {
  // Pakistan
  final pkRegExp = RegExp(r'^(?:\+92|0)?3\d{9}$');
  if (!pkRegExp.hasMatch(value)) {
  return 'Invalid Pakistan phone number format.';
  }
  return null;
  } else if (value.startsWith('+1')) {
  // USA
  final usRegExp = RegExp(r'^(?:\+1)?\d{10}$');
  if (!usRegExp.hasMatch(value)) {
  return 'Invalid USA phone number format.';
  }

  // 🌍 Fallback: International 10–15 digits
  final intlRegExp = RegExp(r'^\+?\d{10,15}$');
  if (!intlRegExp.hasMatch(value)) {
  return 'Invalid phone number format.';
  }

  return null;
  }
  }


  // static String? validatePhoneNumber(String? value, {String? countryCode}) {
  //   if (value == null || value.trim().isEmpty) {
  //     return 'Phone number is required.';
  //   }
  //
  //   value = value.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
  //   countryCode ??= _detectCountryCode();
  //
  //   if (countryCode == 'US') {
  //     // Accepts formats: XXXXXXXXXX or +1XXXXXXXXXX
  //     final usRegExp = RegExp(r'^(?:\+1)?\d{10}$');
  //     if (!usRegExp.hasMatch(value)) {
  //       return 'Invalid USA phone number format.';
  //     }
  //   } else if (countryCode == 'PK') {
  //     // Accepts formats: 03XXXXXXXXX or +923XXXXXXXXX
  //     final pkRegExp = RegExp(r'^(?:\+92|0)?3\d{9}$');
  //     if (!pkRegExp.hasMatch(value)) {
  //       return 'Invalid Pakistan phone number format.';
  //     }
  //   } else {
  //     // Fallback: 10–15 digits international format
  //     final intlRegExp = RegExp(r'^\+?\d{10,15}$');
  //     if (!intlRegExp.hasMatch(value)) {
  //       return 'Invalid phone number format.';
  //     }
  //   }
  //
  //   return null;
  // }

  /// Detect country from device locale
  static String _detectCountryCode() {
    try {
      final locale = Intl.getCurrentLocale();
      print("Pakistan : "+locale.toString());
      if (locale.endsWith('_PK')) return 'PK';
      if (locale.endsWith('_US')) return 'US';
    } catch (_) {}
    return 'INTL'; // Default to international format
  }
}
