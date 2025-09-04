import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/rate_driver_controller.dart';
import '../models/driver_model.dart';

class RateDriverScreen extends StatelessWidget {
  const RateDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final driver = args != null ? DriverModel.fromMap(args) : null;
    final c = Get.put(RateDriverController());

    final tags = ['Price', 'Professionalism', 'Driving', 'Experience', 'Navigation', 'Other'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PositionedScaled(top: 43, left: 23, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())),
          PositionedScaled(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                CircleAvatar(radius: 44, backgroundImage: AssetImage(driver?.avatar ?? 'assets/images/profile_img_sample.png')),
                const SizedBox(height: 12),
                Text("Rate Your Experience With ${driver?.name ?? 'Driver'}?", style: FTextTheme.lightTextTheme.titleMedium),
                const SizedBox(height: 16),
                Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = c.rating.value >= idx;
                      return GestureDetector(
                        onTap: () => c.rating.value = idx.toDouble(),
                        child: Icon(Icons.star, size: 40, color: filled ? Colors.amber : Colors.grey.shade300),
                      );
                    }),
                  );
                }),
                const SizedBox(height: 18),
                Text("What did you like the most?"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) {
                    return Obx(() {
                      final sel = c.selectedTags.contains(t);
                      return ChoiceChip(
                        label: Text(t),
                        selected: sel,
                        onSelected: (_) => c.toggleTag(t),
                        selectedColor: Colors.yellow.shade100,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(color: sel ? Colors.black : Colors.black87),
                      );
                    });
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    controller: c.messageController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: "Write Message",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 320,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: const Color(0xFF003366)),
                    onPressed: () => c.submitRating(),
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
