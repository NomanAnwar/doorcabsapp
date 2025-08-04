import 'package:intl/intl.dart';

class FFormatter {

  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  static String formatCurrency( double amount){
    return NumberFormat.currency(locale: 'en-US', symbol: '\$').format(amount);
  }

  static String formatPhoneNumber(String phoneNumber){
    if (phoneNumber.length == 10){
      return '(${phoneNumber.substring(0,3)}) ${phoneNumber.substring(3,6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11){
      return '(${phoneNumber.substring(0,4)}) ${phoneNumber.substring(4,7)} ${phoneNumber.substring(7)}';
    }

    return phoneNumber;
  }

  // static String formatInternalPhoneNumber(String phoneNumber){
  //
  //   var digitsonly = phoneNumber.replaceAll(RegExp(r'\D'), '');
  //
  //   //Extract the country code from the digits
  //   String countryCode = '+${digitsonly.substring(0,2)}';
  //   digitsonly = digitsonly.substring(2);
  //
  //   //add the remaining digits with proper formatting
  //   final formattedNumber = StringBuffer();
  //   formattedNumber.write('($countryCode)');
  //
  //   int i = 0;
  //   while (i < digitsonly.length){
  //     int groupLength = 2;
  //     if(i == 0 && countryCode == '+1'){
  //       groupLength = 3;
  //     }
  //
  //     int end = i + groupLength ;
  //     formattedNumber.write(digitsonly.substring(i, end));
  //
  //     if(end < digitsonly.length){
  //       formattedNumber.write(' ');
  //     }
  //
  //     i = end;
  //
  //
  //   }
  //
  //
  // }

}