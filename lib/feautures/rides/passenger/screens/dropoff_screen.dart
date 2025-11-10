import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/constants/text_strings.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../utils/system_ui_mixin.dart';
import '../controllers/dropoff_controller.dart';

class DropOffScreen extends StatelessWidget {
  const DropOffScreen({super.key});

  @override
  Widget build(BuildContext context) {


    const apiKey = String.fromEnvironment(
      'MAPS_API_KEY',
      defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4',
    );

    final c = Get.put(DropOffController(apiKey));

    /// Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;


    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            /// Back
            Positioned(
              top: sh(43),
              left: sw(23),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: sw(28)),
                onPressed: Get.back,
              ),
            ),

            /// Title
            Positioned(
              top: sh(81),
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Enter Your Route",
                  style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
                    fontSize:
                    FTextTheme.lightTextTheme.headlineMedium!.fontSize! *
                        screenWidth /
                        baseWidth,
                  ),
                ),
              ),
            ),

            /// Main scrollable content
            Positioned(
              top: sh(121),
              left: 0,
              right: 0,
              bottom: sh(100),
              // Leave space for the confirm button at bottom
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw(10)),
                child: Obx(
                      () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Pickup
                      Container(
                        height: sh(52),
                        width: screenWidth,
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              "assets/images/place.png",
                              width: sw(22),
                            ),
                            SizedBox(width: sw(12)),

                            Expanded(
                              child: TextField(
                                controller: c.pickupCtrl,
                                focusNode: c.pickupFocus,
                                style: FTextTheme.lightTextTheme.titleMedium!
                                    .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize:
                                  FTextTheme
                                      .lightTextTheme
                                      .titleMedium!
                                      .fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Model Town Link Rd Zainab Tower",
                                  hintStyle: FTextTheme
                                      .lightTextTheme
                                      .titleMedium!
                                      .copyWith(
                                    color: FColors.chipBg,
                                    fontWeight: FontWeight.w500,
                                    fontSize:
                                    FTextTheme
                                        .lightTextTheme
                                        .titleMedium!
                                        .fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sw(5),
                                    vertical: sh(12),
                                  ),
                                ),
                                onTap: () {
                                  c.toggleField(ActiveField.pickup);
                                  // Select all text when tapped
                                  c.pickupCtrl.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: c.pickupCtrl.text.length,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sh(6)),

                      /// Drop-off
                      Container(
                        width: screenWidth,
                        height: sh(52),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: sw(4)),
                            Icon(
                              Icons.near_me_sharp,
                              color: FColors.black,
                              size: sw(20),
                            ),
                            SizedBox(width: sw(12)),

                            Expanded(
                              child: TextField(
                                controller: c.dropCtrl,
                                focusNode: c.dropFocus,
                                style: FTextTheme
                                    .lightTextTheme
                                    .titleMedium!
                                    .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize:
                                  FTextTheme
                                      .lightTextTheme
                                      .titleMedium!
                                      .fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Drop Off",
                                  hintStyle: FTextTheme
                                      .lightTextTheme
                                      .titleMedium!
                                      .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: FColors.chipBg,
                                    fontSize:
                                    FTextTheme
                                        .lightTextTheme
                                        .titleMedium!
                                        .fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sw(2),
                                    vertical: sh(12),
                                  ),
                                ),
                                onTap: () {
                                  c.toggleField(ActiveField.dropoff);
                                  // Select all text when tapped
                                  c.dropCtrl.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: c.dropCtrl.text.length,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Choose on Map
                      SizedBox(height: sh(20)),
                      GestureDetector(
                        onTap: c.chooseOnMap,
                        child: Row(
                          children: [
                            SizedBox(width: sw(19)),
                            SvgPicture.asset(
                              "assets/images/choose_on_map.svg",
                              width: sw(24),
                              height: sw(24),
                              color: Colors.black,
                            ),
                            SizedBox(width: sw(8)),
                            Text(
                              "Choose on Map",
                              style: FTextTheme.lightTextTheme.bodyLarge!
                                  .copyWith(
                                fontSize:
                                FTextTheme
                                    .lightTextTheme
                                    .bodyLarge!
                                    .fontSize! *
                                    screenWidth /
                                    baseWidth,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Loading + Suggestions
                      SizedBox(height: sh(10)),
                      if (c.isLoading.value)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: sh(8)),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (c.suggestions.isNotEmpty &&
                          c.showSuggestions.value) ...[
                        SizedBox(height: sh(10)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: c.suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder:
                              (_, i) => ListTile(
                            leading: Icon(
                              Icons.location_on_outlined,
                              size: sw(18),
                              color: FColors.secondaryColor,
                            ),
                            title: Text(
                              c.suggestions[i].description,
                              style: FTextTheme.lightTextTheme.bodyLarge!
                                  .copyWith(
                                fontSize:
                                FTextTheme
                                    .lightTextTheme
                                    .bodyLarge!
                                    .fontSize! *
                                    screenWidth /
                                    baseWidth,
                              ),
                            ),
                            onTap:
                                () => c.selectSuggestion(c.suggestions[i]),
                          ),
                        ),
                        SizedBox(height: sh(16)),
                      ],

                      /// Recent
                      SizedBox(height: sh(6)),
                      for (int i = 0; i < c.recent.length && i < 4; i++)
                        Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: sh(4),
                                  top: sh(4),
                                  right: sw(13),
                                  left: sw(13)
                              ),
                              child: InkWell(
                                onTap: () => c.selectRecent(c.recent[i]),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          sw(6),
                                        ),
                                        color: FColors.phoneInputField,
                                      ),
                                      height: sh(34),
                                      width: sw(34),
                                      padding: EdgeInsets.all(sw(2)),
                                      child: Icon(
                                        Icons.near_me_sharp,
                                        color: FColors.black,
                                        size: sw(18),
                                      ),
                                    ),
                                    SizedBox(width: sw(8)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.recent[i].description,
                                            style: FTextTheme
                                                .lightTextTheme
                                                .bodyLarge!
                                                .copyWith(
                                              fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .bodyLarge!
                                                  .fontSize! *
                                                  screenWidth /
                                                  baseWidth,
                                            ),
                                          ),
                                          SizedBox(height: sh(2)),
                                          Text(
                                            "${c.recent[i].city ?? ''}, ${c.recent[i].province ?? ''}, ${c.recent[i].country ?? ''}",
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                              color: FColors.chipBg,
                                              fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .labelSmall!
                                                  .fontSize! *
                                                  screenWidth /
                                                  baseWidth,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: sw(2)),
                                    Text(
                                      c.recent[i].eta ?? '',
                                      style: FTextTheme
                                          .lightTextTheme
                                          .labelSmall!
                                          .copyWith(
                                        fontWeight: FontWeight.w400,
                                        color: FColors.chipBg,
                                        fontSize:
                                        FTextTheme
                                            .lightTextTheme
                                            .labelSmall!
                                            .fontSize! *
                                            screenWidth /
                                            baseWidth,
                                      ),
                                    ),
                                    SizedBox(width: sw(8)),
                                    Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(3.14),
                                      // flip horizontally
                                      child: Icon(
                                        Icons.refresh_sharp,
                                        color: FColors.black,
                                        size: sw(32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: sw(15)),
                              child: Divider(
                                color: FColors.buttonDisabled,
                                thickness: 2,
                                height: sh(10),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: sh(28)),
                    ],
                  ),
                ),
              ),
            ),

            /// ADD STOP button - Positioned independently in main Stack
            Positioned(
              top: sh(162), // Position between the two fields
              right: sw(9),
              child: SizedBox(
                width: sw(35),
                height: sw(35),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: c.addStop,
                    // borderRadius: BorderRadius.circular(sw(8)),
                    child: Container(
                      width: sw(35),
                      height: sw(35),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        // shape: BoxShape.circle,
                        borderRadius: BorderRadius.circular(sw(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: sw(4),
                            offset: Offset(0, sw(2)),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/images/add_stop_plus.svg",
                          width: sw(15),
                          height: sw(15),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Confirm button fixed at bottom (for manual confirmation)
            Positioned(
              left: sw(45),
              right: sw(45),
              bottom: sh(30),
              child: SizedBox(
                height: sh(48),
                width: sw(358),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                  ),
                  onPressed: c.confirmSelection,
                  child: Text(
                    FTextStrings.done,
                    style: FTextTheme.darkTextTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize:
                      FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}