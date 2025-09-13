import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
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

            /// Main content
            Positioned.fill(
              top: sh(121),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw(23)),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Pickup
                      Container(
                        height: sh(52),
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: sw(16),
                              height: sw(16),
                              decoration: const BoxDecoration(
                                color: FColors.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: sw(12)),
                            Expanded(
                              child: TextField(
                                controller: c.pickupCtrl,
                                focusNode: c.pickupFocus,
                                decoration: const InputDecoration(
                                  hintText: "Model Town Link Rd Zainab Tower",
                                  border: InputBorder.none,
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
                            width: sw(393),
                            height: sh(52),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEFEF),
                              borderRadius: BorderRadius.circular(sw(10)),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: sw(12)),
                            child: Row(
                              children: [
                                SizedBox(width: sw(4)),
                                Container(
                                  width: sw(16),
                                  height: sw(16),
                                  decoration: const BoxDecoration(
                                    color: FColors.secondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: sw(12)),
                                Expanded(
                                  child: TextField(
                                    controller: c.dropCtrl,
                                    focusNode: c.dropFocus,
                                    decoration: const InputDecoration(
                                      hintText: "Drop Off",
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 0,
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
                            right: sw(6),
                            top: sh(11),
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
                                icon: Icon(
                                  Icons.add,
                                  size: sw(16),
                                  color: Colors.black,
                                ),
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
                            Icon(Icons.near_me_outlined, size: sw(20)),
                            SizedBox(width: sw(8)),
                            const Text("Choose on Map"),
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
                                title: Text(c.suggestions[i].description),
                                onTap:
                                    () => c.selectSuggestion(c.suggestions[i]),
                              ),
                        ),
                        SizedBox(height: sh(16)),
                      ],

                      /// Recent
                      SizedBox(height: sh(6)),
                      for (int i = 0; i < c.recent.length && i < 4; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: sh(14)),
                          child: InkWell(
                            onTap: () => c.setFieldValue(c.recent[i]),   // ✅ update field when clicked
                            child: Row(
                              children: [
                                Icon(Icons.navigation, size: sw(20)),
                                SizedBox(width: sw(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.recent[i].description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: sh(2)),
                                      // const Text(
                                      //   "Lahore, Province Punjab",
                                      //   style: TextStyle(
                                      //     fontSize: 12,
                                      //     color: Colors.grey,
                                      //   ),
                                      // ),
                                      Text(
                                        "${c.recent[i].city ?? ''}, ${c.recent[i].province ?? ''}, ${c.recent[i].country ?? ''}",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: sw(8)),
                                // const Text(
                                //   "25 min",
                                //   style: TextStyle(
                                //     fontSize: 12,
                                //     color: Colors.black54,
                                //   ),
                                // ),
                                Text(
                                  c.recent[i].eta ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                SizedBox(width: sw(8)),
                                Icon(
                                  Icons.sync,
                                  size: sw(18),
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),


                      SizedBox(height: sh(28)),
                    ],
                  ),
                ),
              ),
            ),

            /// Confirm button outside the scrollable Column
            // Positioned(
            //   top: sh(805),
            //   left: sw(45),
            //   child: ResponsiveButton(
            //     text: "Confirm",
            //     onPressed: c.confirmSelection,
            //     backgroundColor: FColors.secondaryColor,
            //     textColor: Colors.white,
            //     sw: sw,
            //     sh: sh,
            //     baseWidth: baseWidth,
            //     screenWidth: screenWidth,
            //     width: sw(360),
            //     height: sh(48),
            //     borderRadius: sw(14),
            //     textStyle: TextStyle(
            //       fontWeight: FontWeight.w600,
            //       fontSize: sh(16),
            //       color: Colors.white,
            //     ),
            //   ),
            // ),

            Positioned(
              left: 45,
              right: 45,
              bottom: 30,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: c.confirmSelection,
                  child: Text("Confirm", style: FTextTheme.darkTextTheme.labelLarge,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
