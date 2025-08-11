import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            Row(
              children: [
                Checkbox(
                  value: acceptedPolicy,
                  onChanged: (val) => setState(() => acceptedPolicy = val!),
                ),
                const Text("Accept Privacy Policy"),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                if (acceptedPolicy && phoneController.text.isNotEmpty) {
                  Get.offAllNamed('/otp', arguments: phoneController.text);
                }
              },
              child: const Text("Proceed"),
            )
          ],
        ),
      ),
    );
  }
}
