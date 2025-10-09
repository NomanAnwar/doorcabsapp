import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';

class FDropdown extends StatelessWidget {
  final String? value;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;
  final double? width;
  final double? height;
  final Color backgroundColor;

  const FDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reference screen size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final double finalWidth = width ?? sw(200);
    final double finalHeight = height ?? sh(49);

    return SizedBox(
      width: finalWidth,
      height: finalHeight,
      child: DropdownButtonFormField<String>(
        isDense: true,
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: sw(12),
            vertical: sh(2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw(14)),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item["lang"],
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFlag(item["flag"] ?? "", screenWidth, screenHeight),
                SizedBox(width: sw(8)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: finalWidth - sw(20)),
                  child: Text(
                    item["lang"].toString().toUpperCase() ?? "",
                    style: FTextTheme.lightTextTheme.headlineMedium!.copyWith(
                      fontSize: FTextTheme
                          .lightTextTheme.headlineMedium!.fontSize! *
                          screenWidth /
                          baseWidth,
                      overflow: TextOverflow.ellipsis,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(
          Icons.arrow_drop_down_rounded, // you can change to any icon
          // size: 32,                   // make it bigger
          weight: 900,                // bold (works in Flutter 3.7+ with MaterialSymbols)
          color: FColors.black,        // change color
        ),
        iconSize: sw(32), // fallback if using default
      ),
    );
  }

  /// Handle both asset paths & base64 flags
  Widget _buildFlag(String flag, double screenWidth, double screenHeight) {
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    if (flag.startsWith("data:image")) {
      final base64Data = flag.split(",").last;
      return Image.memory(
        const Base64Decoder().convert(base64Data),
        width: sw(35),
        height: sh(18),
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(
        flag,
        width: sw(24),
        height: sh(24),
        fit: BoxFit.contain,
      );
    }
  }
}
