import 'package:doorcab/utils/constants/sizes.dart';
import 'package:doorcab/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  final phoneController = TextEditingController();
  bool acceptedPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // <-- prevents overflow on small screens
        child: SizedBox(
          height: MediaQuery.of(context).size.height, // force full screen
          width: double.infinity,
          child: Stack(
            children: [
              /// Background container
              Positioned(
                top: 54,
                left: 13,
                right: 13,
                child: Container(
                  height: 365,
                  decoration: BoxDecoration(
                    color: FColors.primaryColor,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(30),topLeft: Radius.circular(30)),
                  ),
                ),
              ),

              /// Logo
              Positioned(
                top: 114,
                left: 63,
                child: Image.asset(
                  FImages.logo,
                  width: 99,
                  height: 62,
                ),
              ),

              /// First Text
              Positioned(
                top: 181,
                left: 63,
                child: Text(
                  FTextStrings.wellcomeTagLine.toUpperCase(),
                  style: FTextTheme.lightTextTheme.displayMedium!.copyWith(color: FColors.secondaryColor),
                ),
              ),

              /// Second Text
              Positioned(
                top: 220,
                left: 63,
                child: Text(
                  FTextStrings.wellcomeSubheading,
                  style: FTextTheme.lightTextTheme.titleLarge,
                ),
              ),

              /// City Background
              Positioned(
                top: 252,
                left: 14,
                right: 14,
                child: Image.asset(
                  FImages.started_bg_down,
                  // height: 167,
                  fit: BoxFit.fitWidth,
                ),
              ),

              /// Phone Input
              Positioned(
                top: 430,
                left: 42,
                // right: 14,
                child: Container(
                  width: 356,
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FColors.phoneInputField,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Image.asset(FImages.urdu_flag),
                      // const SizedBox(width: FSizes.xs),
                      Icon(Icons.arrow_drop_down_rounded, size: 40,color: FColors.black,),
                      // const SizedBox(width: FSizes.sm),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: FTextTheme.lightTextTheme.titleLarge,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Phone Number",
                            hintStyle: FTextTheme.lightTextTheme.titleLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Privacy Policy Row
              Positioned(
                top: 485,
                left: 54,
                child: Row(
                  children: [
                    Checkbox(
                      value: acceptedPolicy,
                      onChanged: (val) =>
                          setState(() => acceptedPolicy = val ?? false),
                    ),
                    Text("Privacy Policy", style: FTextTheme.lightTextTheme.bodyLarge ,),
                  ],
                ),
              ),


              /// Verification text
              Positioned(
                top: 529,
                left: 119,
                child: Center(
                  child: Text(
                    "get verification code via",
                    style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(color: Colors.grey.shade600) ,
                  ),
                ),
              ),

              /// Buttons Row
              Positioned(
                top: 560,
                left: 14,
                right: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 41,
                      width: 165,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (acceptedPolicy &&
                              phoneController.text.isNotEmpty) {
                            Get.offAllNamed('/otp',
                                arguments: phoneController.text);
                          }
                        },
                        icon: Image.asset(
                          "assets/icons/message.png",
                        ),
                        label: Text("Text",style: FTextTheme.darkTextTheme.bodyLarge,),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FColors.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          // padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 41,
                      width: 165,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (acceptedPolicy &&
                              phoneController.text.isNotEmpty) {
                            Get.offAllNamed('/otp',
                                arguments: phoneController.text);
                          }
                        },
                        icon: Image.asset(
                          "assets/icons/whatsapp.png",
                        ),
                        label: Text("WhatsApp",style: FTextTheme.darkTextTheme.bodyLarge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FColors.buttonWhatsApp,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          // padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Login Link
              Positioned(
                top: 620,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Already Have an account ", style: FTextTheme.lightTextTheme.bodyLarge,),
                      GestureDetector(
                        onTap: () => Get.toNamed('/login'),
                        child: Text(
                          "Log-In",
                          style: FTextTheme.lightTextTheme.titleSmall!.copyWith(color: FColors.secondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
