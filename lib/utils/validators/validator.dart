

class FValidator {

  static String? validateEmail( String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  static String? validatePassword(String? value){

    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 8 ) {
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

  static String? validatePhoneNumber(String? value){

    if (value == null || value.isEmpty) {
      return 'Phone Number is required.';
    }

    final emailRegExp = RegExp(r'^\d{10}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid Phone number format 10 digits required.';
    }

    return null;
  }


}