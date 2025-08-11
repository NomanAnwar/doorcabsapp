import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';

class FHelperFunctions {
  /// Get a color from theme-based mapping
  /// This ensures your colors adapt to the current ThemeData and Dark Mode
  static Color? getColor(BuildContext context, String value) {
    final scheme = Theme.of(context).colorScheme;

    final Map<String, Color> colorMap = {
      'Primary': scheme.primary,
      'OnPrimary': scheme.onPrimary,
      'Secondary': scheme.secondary,
      'OnSecondary': scheme.onSecondary,
      'Error': scheme.error,
      'OnError': scheme.onError,
      'Background': scheme.background,
      'OnBackground': scheme.onBackground,
      'Surface': scheme.surface,
      'OnSurface': scheme.onSurface,
    };

    return colorMap[value];
  }

  /// Show an alert dialog
  static Future<void> showAlert(String title, String message) async {
    final context = Get.context;
    if (context == null) return; // Safety check

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  /// Show a snackbar
  static void showSnackBar(String message) {
    final context = Get.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Navigate to another screen
  static Future<T?> navigateToScreen<T>(
      BuildContext context, Widget screen) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Truncate text to max length
  static String truncateText(String text, int maxLength) {
    return (text.length <= maxLength)
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  /// Check dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Screen size utilities
  static Size? screenSize() => Get.context?.size;
  static double? screenHeight() => Get.context?.size?.height;
  static double? screenWidth() => Get.context?.size?.width;

  /// Format date
  static String getFormattedDate(
      DateTime date, {
        String format = 'dd MMM yyyy',
      }) {
    return DateFormat(format).format(date);
  }

  /// Remove duplicates from list
  static List<F> removeDuplicates<F>(List<F> list) {
    return list.toSet().toList();
  }

  /// Wrap widgets in rows
  static List<Widget> wrapWidget(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
        i,
        (i + rowSize > widgets.length) ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }
}
