import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FFormatter {
  /// Format date according to locale.
  static String formatDate(DateTime? date, {String? locale}) {
    date ??= DateTime.now();
    locale ??= Intl.getCurrentLocale();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Format currency for PKR (₨) and USD ($) based on locale.
  static String formatCurrency(double amount, {String? locale, String? symbol}) {
    locale ??= Intl.getCurrentLocale();

    if (locale == 'ur_PK' || locale == 'en_PK') {
      symbol ??= '₨';
    } else if (locale == 'en_US') {
      symbol ??= '\$';
    }

    return NumberFormat.currency(locale: locale, symbol: symbol).format(amount);
  }

  /// Format phone number for PK and US.
  static String formatPhoneNumber(String phoneNumber, {String? locale}) {
    locale ??= Intl.getCurrentLocale();

    if (locale == 'ur_PK' || locale == 'en_PK') {
      // Pakistan format: +92 XXX XXXXXXX
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      return '+92 ${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3)}';
    } else if (locale == 'en_US') {
      // US format: (XXX) XXX XXXX
      if (phoneNumber.length == 10) {
        return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
      }
    }

    return phoneNumber;
  }

  /// Normalize number before sending OTP.
  static String normalizePhone(String phone, {String? countryCode}) {
    if (!phone.startsWith('+')) {
      phone = '$countryCode$phone';
    }
    return phone.replaceAll(' ', '');
  }
}



class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}