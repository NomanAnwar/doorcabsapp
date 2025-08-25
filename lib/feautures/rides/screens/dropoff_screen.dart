import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dropoff_controller.dart';

class DropOffScreen extends StatelessWidget {
  const DropOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = const String.fromEnvironment('MAPS_API_KEY', defaultValue: 'AIzaSyCCFXa-6kwZp4bqe8ROHXzaRDpnkgZQIJ4');
    final c = Get.put(DropOffController(apiKey));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// Back arrow (top:42, left:23)
            Positioned(
              top: 42,
              left: 23,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: Get.back,
              ),
            ),

            /// Title (top:81)
            Positioned(
              top: 81,
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
              top: 121,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// --- PICKUP field (with dot icon box) ---
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: FColors.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                    const SizedBox(height: 16),

                    /// --- DROPOFF field (with ADD STOPS button aligned) ---
                    Stack(
                      children: [
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Text("Drop Off", style: FTextTheme.lightTextTheme.bodyMedium),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: c.dropCtrl,
                                  focusNode: c.dropFocus,
                                  decoration: const InputDecoration(
                                    hintText: "Where do you want to go?",
                                    border: InputBorder.none,
                                  ),
                                  onTap: () => c.toggleField(ActiveField.dropoff),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// ADD STOPS button (top:208, left:310 in design → right aligned here)
                        Positioned(
                          right: 0,
                          top: 6,
                          bottom: 6,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(110, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: c.addStop,
                            icon: const Icon(Icons.add, size: 18, color: Colors.black),
                            label: const Text("ADD STOPS", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /// Choose on map
                    GestureDetector(
                      onTap: c.chooseOnMap,
                      child: Row(
                        children: const [
                          SizedBox(width: 19),
                          Icon(Icons.near_me_outlined, size: 20),
                          SizedBox(width: 8),
                          Text("Choose on Map"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// ---- Suggestions under the active field ----
                    if (c.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: c.suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(c.suggestions[i].description),
                          onTap: () => c.selectSuggestion(c.suggestions[i]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    /// Recent locations list (same as RideHome design)
                    const SizedBox(height: 6),
                    for (int i = 0; i < c.recent.length && i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.navigation, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.recent[i].description,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  const Text("Lahore, Province Punjab",
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("25 min", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 8),
                            const Icon(Icons.sync, size: 18, color: Colors.black54),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: FColors.primaryColor),
                        onPressed: c.confirmSelection,
                        child: const Text("Confirm"),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
