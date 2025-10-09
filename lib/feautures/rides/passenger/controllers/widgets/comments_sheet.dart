import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ride_booking_controller.dart';

class CommentsBottomSheet {
  static void show() {
    final textController = TextEditingController();
    final rideController = Get.find<RideBookingController>(); // ✅ ADDED: Get controller

    // ✅ ADDED: Pre-fill with existing comment if any
    if (rideController.comment.value.isNotEmpty) {
      textController.text = rideController.comment.value;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2)
                  )
              ),
              const Text(
                  "Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Anything your driver should know?",
                  filled: true, // ✅ ADDED: Enable background fill
                  fillColor: FColors.phoneInputField, // ✅ ADDED: Light grey background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // ✅ ADDED: Remove border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: FColors.secondaryColor, // ✅ ADDED: Yellow border when focused
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
                  // ✅ ADDED: Save button
                  Container(
                    width: 121,
                    // height: 37,
                    child: ElevatedButton(
                      onPressed: () {
                        final comment = textController.text.trim();
                        rideController.setComment(comment); // ✅ ADDED: Save to controller
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FColors.primaryColor,
                        foregroundColor: FColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Save"),
                    ),
                  ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class CommentsBottomSheet {
//   static void show() {
//     final controller = TextEditingController();
//
//     Get.bottomSheet(
//       Container(
//         padding: EdgeInsets.all(20),
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
//         child: SafeArea(
//           top: false,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
//               Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
//               SizedBox(height: 16),
//               TextField(controller: controller, maxLines: 4, decoration: InputDecoration(hintText: "Anything your driver should know?", border: OutlineInputBorder())),
//               SizedBox(height: 16),
//               SizedBox(
//                 width: 121,
//                 height: 37,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // You can persist comment if needed
//                     Get.back();
//                   },
//                   child: Text("Save"),
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }
// }