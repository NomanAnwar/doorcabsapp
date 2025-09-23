import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/buttons/responsive_button.dart';
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
              top: sh(42),
              left: sw(23),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: sw(24)),
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
                  style: FTextTheme.lightTextTheme.titleLarge,
                ),
              ),
            ),

            /// Main scrollable content
            Positioned(
              top: sh(121),
              left: 0,
              right: 0,
              bottom: sh(100), // Leave space for the confirm button at bottom
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw(23)),
                child: Obx(
                      () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Pickup
                      Container(
                        // height: sh(52),
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/images/place.png"),
                            // Container(
                            //   width: sw(16),
                            //   height: sw(16),
                            //   decoration: const BoxDecoration(
                            //     color: FColors.secondaryColor,
                            //     shape: BoxShape.circle,
                            //   ),
                            // ),
                            SizedBox(width: sw(12)),
                            Expanded(
                              child: TextField(
                                controller: c.pickupCtrl,
                                focusNode: c.pickupFocus,
                                style: FTextTheme.lightTextTheme.titleSmall!.copyWith(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: "Model Town Link Rd Zainab Tower",
                                  hintStyle: FTextTheme.lightTextTheme.bodyLarge,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sw(5),
                                    vertical: sh(12),
                                  ),
                                ),
                                onTap: () => c.toggleField(ActiveField.pickup),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sh(16)),

                      /// Drop-off + Add Stops
                      Stack(
                        children: [
                          /// Background field
                          Container(
                            width: double.infinity,
                            // height: sh(52),
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
                                ),
                                // Container(
                                  // width: sw(16),
                                  // height: sw(16),
                                  // decoration: const BoxDecoration(
                                  //   color: FColors.secondaryColor,
                                  //   shape: BoxShape.circle,
                                  // ),
                                // ),
                                SizedBox(width: sw(12)),
                                Expanded(
                                  child: TextField(
                                    controller: c.dropCtrl,
                                    focusNode: c.dropFocus,
                                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: "Drop Off",
                                      hintStyle: FTextTheme.lightTextTheme.bodyLarge,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: sw(2),
                                        vertical: sh(12),
                                      ),
                                    ),
                                    onTap:
                                        () =>
                                        c.toggleField(ActiveField.dropoff),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// ADD STOP button
                          Positioned(
                            right: sw(10),
                            top: sh(14),
                            child: SizedBox(
                              width: sw(116),
                              height: sh(30),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC107),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: sw(8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(sw(9)),
                                  ),
                                ),
                                onPressed: c.addStop,
                                label: Text(
                                  "ADD STOP",
                                  style: FTextTheme.lightTextTheme.labelSmall,
                                ),
                                icon: SvgPicture.asset(
                                  "assets/images/add_stop_plus.svg",
                                  width: sw(16),
                                  height: sw(16),
                                  color: Colors.black,
                                ),
                                // Icon(
                                //   Icons.add,
                                //   size: sw(16),
                                //   color: Colors.black,
                                // ),
                                iconAlignment: IconAlignment.end,
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// Choose on Map
                      SizedBox(height: sh(18)),
                      GestureDetector(
                        onTap: c.chooseOnMap,
                        child: Row(
                          children: [
                            SizedBox(width: sw(19)),
                            // Icon(Icons.near_me_outlined, size: sw(20)),
                            SvgPicture.asset(
                              "assets/images/choose_on_map.svg",
                              // width: sw(16),
                              // height: sw(16),
                              color: Colors.black,
                            ),
                            SizedBox(width: sw(8)),
                            Text("Choose on Map", style: FTextTheme.lightTextTheme.bodySmall,),
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
                      if (c.suggestions.isNotEmpty) ...[
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
                              size: sw(20),
                            ),
                            title: Text(c.suggestions[i].description, style: TextStyle(
                              fontWeight:
                              FontWeight.w600,
                              fontSize: sw(14),
                            ),),
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
                              padding: EdgeInsets.only(bottom: sh(4),top: sh(4)),
                              child: InkWell(
                                onTap: () => c.setFieldValue(c.recent[i]),   //  update field when clicked
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(
                                            sw(6)),
                                        color:
                                        FColors.phoneInputField,
                                      ),
                                      height: sh(34),
                                      width: sw(34),
                                      padding: EdgeInsets.all(sw(2)),
                                      child: Icon(
                                        Icons.near_me_sharp,
                                        color: FColors.black,
                                      ),
                                    ),
                                    SizedBox(width: sw(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.recent[i].description,
                                            style: TextStyle(
                                              fontWeight:
                                              FontWeight.w600,
                                              fontSize: sw(14),
                                            ),
                                          ),
                                          SizedBox(height: sh(2)),
                                          Text(
                                            "${c.recent[i].city ?? ''}, ${c.recent[i].province ?? ''}, ${c.recent[i].country ?? ''}",
                                            style: TextStyle(
                                                fontSize: sw(12),
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: sw(2)),
                                    Text(
                                      c.recent[i].eta ?? '',
                                      style: TextStyle(
                                          fontSize: sw(12),
                                          color: Colors.black54),
                                    ),
                                    SizedBox(width: sw(8)),
                                    Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(3.14), // flip horizontally
                                      child: Icon(Icons.refresh_sharp,
                                          color: FColors.black,
                                          size: sw(32)),
                                    ),
                                  ],
                                ),
                                // Row(
                                //   children: [
                                //     // Icon(Icons.near_me_sharp, size: sw(20)),
                                //     Container(
                                //       decoration: BoxDecoration(
                                //         borderRadius:
                                //         BorderRadius.circular(
                                //             sw(6)),
                                //         color:
                                //         FColors.phoneInputField,
                                //       ),
                                //       height: sh(34),
                                //       width: sw(34),
                                //       padding: EdgeInsets.all(sw(2)),
                                //       child: Icon(
                                //         Icons.near_me_sharp,
                                //         color: FColors.black,
                                //       ),
                                //     ),
                                //     SizedBox(width: sw(12)),
                                //     Expanded(
                                //       child: Column(
                                //         crossAxisAlignment: CrossAxisAlignment.start,
                                //         children: [
                                //           Text(
                                //             c.recent[i].description,
                                //             style: const TextStyle(
                                //               fontWeight: FontWeight.w600,
                                //             ),
                                //           ),
                                //           SizedBox(height: sh(2)),
                                //           Text(
                                //             "${c.recent[i].city ?? ''}, ${c.recent[i].province ?? ''}, ${c.recent[i].country ?? ''}",
                                //             style: const TextStyle(fontSize: 12, color: Colors.grey),
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //     SizedBox(width: sw(8)),
                                //     Text(
                                //       c.recent[i].eta ?? '',
                                //       style: const TextStyle(fontSize: 12, color: Colors.black54),
                                //     ),
                                //     SizedBox(width: sw(8)),
                                //     Icon(
                                //       Icons.sync,
                                //       size: sw(18),
                                //       color: Colors.black54,
                                //     ),
                                //   ],
                                // ),
                              ),
                            ),
                            Divider(
                              color: FColors.buttonDisabled,
                              thickness: 2,
                              height: sh(10),
                            ),
                          ],
                        ),

                      SizedBox(height: sh(28)),
                    ],
                  ),
                ),
              ),
            ),

            /// Confirm button fixed at bottom
            Positioned(
              left: sw(45),
              right: sw(45),
              bottom: sh(30),
              child: SizedBox(
                height: sh(48),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                  ),
                  onPressed: c.confirmSelection,
                  child: Text("Done", style: FTextTheme.darkTextTheme.labelLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}