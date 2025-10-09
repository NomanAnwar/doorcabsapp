import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';

/// A small widget implementing the "More" chip replaced by inline dropdown (5..9)
class MorePassengersChip extends StatelessWidget {
  final String selectedPassengers;
  final ValueChanged<String> onSelected;

  const MorePassengersChip({
    required this.selectedPassengers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Show selected value if > 4, otherwise show "More"
    final display =
    (int.tryParse(selectedPassengers) ?? 0) > 4
        ? selectedPassengers
        : "More";

    final isSelected = (int.tryParse(selectedPassengers) ?? 0) > 4;

    return PopupMenuButton<String>(
      onSelected: (val) => onSelected(val),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: FColors.secondaryColor, // menu background
      elevation: 6,
      itemBuilder: (_) => List.generate(5, (i) => (5 + i).toString()).map((s) {
        return PopupMenuItem<String>(
          value: s,
          child: Text(
            s,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12,
              color: FColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: FColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: FColors.secondaryColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.person,
                color: FColors.secondaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              display,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? FColors.secondaryColor : FColors.white,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isSelected ? FColors.secondaryColor : FColors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}