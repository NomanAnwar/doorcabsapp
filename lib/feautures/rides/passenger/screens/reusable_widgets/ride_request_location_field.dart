import 'package:flutter/material.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.label,
    required this.text,
    required this.hasIcon,
    required this.onTap,
    required this.sw,
    this.showAddStop = false,
    this.onAddStop,
  });

  final String label;
  final String text;
  final bool hasIcon;
  final VoidCallback onTap;
  final double Function(double) sw;
  final bool showAddStop;
  final VoidCallback? onAddStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: sw(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3E3),
          borderRadius: BorderRadius.circular(sw(14)),
        ),
        child: Row(
          children: [
            hasIcon
                ? Container(
              width: sw(34),
              height: sw(34),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FColors.phoneInputField,
                borderRadius: BorderRadius.circular(sw(6)),
              ),
              child: Image.asset("assets/images/place.png"),
            )
                : const SizedBox(),
            SizedBox(width: sw(10)),
            Expanded(
              child: Text(
                text,
                style: FTextTheme.lightTextTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (showAddStop && onAddStop != null)
              SizedBox(
                width: sw(120),
                height: sw(30),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    padding: EdgeInsets.symmetric(horizontal: sw(8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(9)),
                    ),
                  ),
                  onPressed: onAddStop,
                  label: const Text(
                    "ADD STOP",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  icon: Icon(Icons.add, size: 16, color: Colors.black),
                  iconAlignment: IconAlignment.end,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
