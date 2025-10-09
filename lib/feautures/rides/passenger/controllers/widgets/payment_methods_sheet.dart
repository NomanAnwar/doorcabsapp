import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ride_booking_controller.dart';

class PaymentBottomSheet {
  static void show() {
    final controller = Get.find<RideBookingController>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Obx(
                () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Choose Your Payment Method",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),

                /// Payment Options
                _buildPaymentTile(
                  title: "Cash Payment",
                  iconPath: "assets/images/cash.png",
                  controller: controller,
                  isDefault: true,
                ),
                _buildPaymentTile(
                  title: "Easypaisa",
                  iconPath: "assets/images/easypaisa.png",
                  controller: controller,
                ),
                _buildPaymentTile(
                  title: "JazzCash",
                  iconPath: "assets/images/Jazzcash.png",
                  controller: controller,
                ),
                _buildPaymentTile(
                  title: "Debit/Credit Card",
                  iconPath: "assets/images/card.png",
                  controller: controller,
                ),
                _buildPaymentTile(
                  title: "DoorCabs Wallet",
                  iconPath: "assets/images/Door Cabs logo1 1.png",
                  controller: controller,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildPaymentTile({
    required String title,
    required String iconPath,
    required RideBookingController controller,
    bool isDefault = false,
  }) {
    final isSelected = controller.selectedPaymentLabel.value == title ||
        (isDefault && controller.selectedPaymentLabel.value.isEmpty);

    // Map to backend values for display
    final backendValueMap = {
      "Cash Payment": "cash",
      "Easypaisa": "easypaisa",
      "JazzCash": "jazzcash",
      "Debit/Credit Card": "card",
      "DoorCabs Wallet": "cash"
    };

    return GestureDetector(
      onTap: () {
        controller.setPaymentMethod(title);
        Get.back();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFF3B0) // Yellow for selected
              : const Color(0xFFE3E3E3), // Grey for others
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            if (isSelected && isDefault)
              const Text(
                "Default",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

// class PaymentBottomSheet {
//   static void show() {
//     final controller = Get.find<RideRequestController>();
//
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         child: SafeArea(
//           top: false,
//           child: Obx(
//                 () => Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.black12,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const Text(
//                   "Choose Your Payment Method",
//                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
//                 ),
//                 const SizedBox(height: 16),
//
//                 /// Payment Options
//                 _buildPaymentTile(
//                   title: "Cash Payment",
//                   iconPath: "assets/images/cash.png",
//                   controller: controller,
//                   isDefault: true,
//                 ),
//                 _buildPaymentTile(
//                   title: "Easypaisa",
//                   iconPath: "assets/images/easypaisa.png",
//                   controller: controller,
//                 ),
//                 _buildPaymentTile(
//                   title: "JazzCash",
//                   iconPath: "assets/images/Jazzcash.png",
//                   controller: controller,
//                 ),
//                 _buildPaymentTile(
//                   title: "Debit/Credit Card",
//                   iconPath: "assets/images/card.png",
//                   controller: controller,
//                 ),
//                 _buildPaymentTile(
//                   title: "DoorCabs Wallet",
//                   iconPath: "assets/images/Door Cabs logo1 1.png",
//                   controller: controller,
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }
//
//   static Widget _buildPaymentTile({
//     required String title,
//     required String iconPath,
//     required RideRequestController controller,
//     bool isDefault = false,
//   }) {
//     final isSelected = controller.selectedPaymentLabel.value == title ||
//         (isDefault && controller.selectedPaymentLabel.value.isEmpty);
//
//     return GestureDetector(
//       onTap: () {
//         controller.selectedPaymentLabel.value = title;
//         Get.back();
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? const Color(0xFFFFF3B0) // Yellow for selected
//               : const Color(0xFFE3E3E3), // Grey for others
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Image.asset(
//               iconPath,
//               width: 28,
//               height: 28,
//               fit: BoxFit.contain,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),
//             ),
//             if (isSelected && isDefault)
//               const Text(
//                 "Default",
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
