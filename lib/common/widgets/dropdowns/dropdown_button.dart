import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../utils/theme/custom_theme/text_theme.dart';

class FDropdown extends StatelessWidget {
  final String? value;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;
  final double width;
  final double height;
  final Color backgroundColor;

  const FDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = double.infinity,
    this.height = 49,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DropdownButtonFormField<String>(
        isDense: true,
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item["lang"],
            child: Row(
              children: [
                _buildFlag(item["flag"] ?? ""),
                const SizedBox(width: 8),
                Text(
                  item["lang"] ?? "",
                  style: FTextTheme.lightTextTheme.headlineMedium!.copyWith(overflow: TextOverflow.ellipsis,height: 1),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// Handle both asset paths & base64 flags
  Widget _buildFlag(String flag) {
    if (flag.startsWith("data:image")) {
      final base64Data = flag.split(",").last;
      return Image.memory(
        const Base64Decoder().convert(base64Data),
        width: 35,
        height: 18,
      );
    } else {
      return Image.asset(flag, width: 24, height: 24);
    }
  }
}
