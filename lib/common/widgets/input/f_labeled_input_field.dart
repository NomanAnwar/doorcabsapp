import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';

class FLabeledInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final bool isReadOnly;

  const FLabeledInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0xFFE3E3E3),
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52, // Design size
        padding: const EdgeInsets.symmetric(horizontal: 12), // Design size
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14), // Design size
        ),
        child: Row(
          children: [
            Container(
              width: 34, // Design size
              height: 34, // Design size
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FColors.phoneInputField,
                borderRadius: BorderRadius.circular(6), // Design size
              ),
              child: Icon(icon, size: 18, color: FColors.black), // Design size
            ),
            const SizedBox(width: 10), // Design size
            Expanded(
              child: Text(
                hintText,
                style: FTextTheme.lightTextTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}