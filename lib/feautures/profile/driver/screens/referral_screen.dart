import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/referral_controller.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReferralController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Back + Title
          PositionedScaled(
            top: 48,
            left: 29,
            right: 29,
            child: SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 12,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Referral Code",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Instruction text
          const PositionedScaled(
            top: 101,
            left: 25,
            right: 25,
            child: Text(
              "Enter your referral code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),

          /// Input field
          PositionedScaled(
            top: 150,
            left: 24,
            right: 24,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (val) => controller.referralCode.value = val,
                decoration: const InputDecoration(
                  hintText: "Referral Code",
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          /// Submit button
          PositionedScaled(
            top: 230,
            left: 42,
            right: 42,
            height: 48,
            child: Obx(
                  () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  final completed = await controller.submitReferralCode();
                  if (completed) {
                    Get.back(result: true); // return to ProfileCompletionScreen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
