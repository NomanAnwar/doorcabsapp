import 'package:intl/intl.dart';

class FValidator {
  static String? validatePhoneNumber(String? value, {String? countryCode}) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    value = value.replaceAll(RegExp(r'\s+'), '');

    if (countryCode == 'PK') {
      // 🇵🇰 Pakistan: 03XXXXXXXXX or +923XXXXXXXXX (total 10 digits after 03)
      final pkRegExp = RegExp(r'^(?:\+92|0)?3\d{9}$');
      if (!pkRegExp.hasMatch(value)) {
        return 'Invalid phone number format.';
      }
    } else {
      // 🌍 International: + followed by 10–15 digits
      final intlRegExp = RegExp(r'^\+?\d{10,15}$');
      if (!intlRegExp.hasMatch(value)) {
        return 'Invalid phone number format.';
      }
    }

    return null;
  }
}
