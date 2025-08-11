import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/local_storage/storage_utility.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? selectedLanguage;
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Language selection
            DropdownButton<String>(
              value: selectedLanguage,
              hint: const Text("Select Language"),
              items: ['English', 'Urdu'].map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedLanguage = val;
                });
              },
            ),
            const SizedBox(height: 20),

            // Role selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => selectedRole = 'Driver'),
                  child: const Text("Driver"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => setState(() => selectedRole = 'Passenger'),
                  child: const Text("Passenger"),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (selectedLanguage != null && selectedRole != null) {
                  FLocalStorage.writeData('language', selectedLanguage);
                  FLocalStorage.writeData('role', selectedRole);
                  Get.offAllNamed('/getting-started');
                }
              },
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}
