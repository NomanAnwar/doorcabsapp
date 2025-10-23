import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doorcab/feautures/shared/services/storage_service.dart';

import '../../../../utils/http/http_client.dart';

class RatingController extends GetxController {
  final rating = 0.0.obs;
  final selectedTags = <String>[].obs;
  final messageController = TextEditingController();
  final isLoading = true.obs;
  final tags = <String>[].obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTags();
  }

  Future<void> fetchTags() async {
    try {
      isLoading.value = true;

      final token = StorageService.getAuthToken();
      final role = StorageService.getRole(); // Get user role ("Driver" or "Passenger")

      // ✅ Determine endpoint based on user role
      final endpoint = '/tags/list/$role'; // This will be either /tags/list/Driver or /tags/list/Passenger

      final response = await http.get(
        Uri.parse('${FHttpHelper.baseUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        // ✅ No need to filter anymore - just extract tag names directly
        final tagNames = responseData.map<String>((tag) {
          return tag['name']?.toString() ?? '';
        }).where((name) => name.isNotEmpty).toList();

        tags.assignAll(tagNames);

        print('Fetched ${tags.length} tags from $endpoint for role: $role');
      } else {
        print('Failed to load tags from $endpoint: ${response.statusCode}');
        tags.assignAll([]);
      }
    } catch (e) {
      print('Error fetching tags: $e');
      tags.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  Future<void> submitRating() async {
    try {
      isSubmitting.value = true;

      // Get the arguments passed to the screen
      final args = Get.arguments as Map<String, dynamic>?;

      // Extract required data from arguments
      final ratedToUserId = args?['userId'] ?? ''; // Adjust based on your argument structure
      final rideId = args?['rideId'] ?? ''; // Adjust based on your argument structure

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "rated_to": ratedToUserId, // This should come from your screen arguments
        "rate": rating.value,
        "comments": messageController.text.trim(),
        "ride_id": rideId, // This should come from your screen arguments
        "rating_tags": selectedTags.toList(),
      };

      // Call the API using FHttpHelper
      final response = await FHttpHelper.post('rating/give-rating', requestBody);

      print("Rating API Response : "+ response.toString());
      // Show success message
      Get.snackbar("Success", "Your rating has been submitted successfully");

      // Navigate to ride history
      // Get.offNamed('/ride-history');
      if( StorageService.getRole() == "Driver" ){
        Get.offNamed('/go-online');
      } else {
        Get.offNamed('/ride-type');
      }

    } catch (e) {
      print('Error submitting rating: $e');
      Get.snackbar("Error", "Failed to submit rating. Please try again.");
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}