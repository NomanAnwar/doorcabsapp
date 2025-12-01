import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:doorcab/utils/http/http_client.dart';
import '../models/help_model.dart';
import '../services/storage_service.dart';

class HelpController extends GetxController {
  final RxList<FAQ> faqs = <FAQ>[].obs;
  final RxList<FAQ> filteredFaqs = <FAQ>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final TextEditingController searchController = TextEditingController(); // Added controller

  @override
  void onInit() {
    super.onInit();
    fetchFAQs();

    // Listen to search controller changes
    searchController.addListener(() {
      updateSearchQuery(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose(); // Dispose the controller
    super.onClose();
  }

  Future<void> fetchFAQs() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.get('faq/get');

      if (response['success'] == true && response['faqs'] is List) {
        final faqsData = response['faqs'] as List;

        final fetchedFAQs = <FAQ>[];

        for (var faqData in faqsData) {
          final faq = FAQ(
            id: faqData['_id']?.toString() ?? '',
            question: faqData['question']?.toString() ?? '',
            answer: faqData['answer']?.toString() ?? '',
            isExpanded: false,
          );
          fetchedFAQs.add(faq);
        }

        faqs.assignAll(fetchedFAQs);
        filteredFaqs.assignAll(fetchedFAQs);
      } else {
        hasError.value = true;
        // Fallback to static data if API fails
        _loadFallbackFAQs();
      }

    } catch (e) {
      print('Error fetching FAQs: $e');
      hasError.value = true;
      // Fallback to static data on error
      _loadFallbackFAQs();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFallbackFAQs() {
    final fallbackFAQs = [
      FAQ(
        id: '1',
        question: "How do I rate a rider?",
        answer: "After your ride, you'll be prompted to rate the rider on a scale of 1 to 5 stars. You can also leave additional feedback.",
      ),
      FAQ(
        id: '2',
        question: "What happens if I have a problem with a rider?",
        answer: "If you experience any issues with a rider, you can report the problem through our support system. We take all complaints seriously and will investigate accordingly.",
      ),
      FAQ(
        id: '3',
        question: "Can I change my rating after submitting it?",
        answer: "Once you submit a rating, it cannot be changed. Please make sure you're satisfied with your rating before confirming it.",
      ),
    ];

    faqs.assignAll(fallbackFAQs);
    filteredFaqs.assignAll(fallbackFAQs);
  }

  void toggleFAQ(int index) {
    if (index >= 0 && index < filteredFaqs.length) {
      filteredFaqs[index].isExpanded = !filteredFaqs[index].isExpanded;
      filteredFaqs.refresh();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();

    if (searchQuery.isEmpty) {
      // Show all FAQs if search is empty
      filteredFaqs.assignAll(faqs);
    } else {
      // Filter FAQs based on search query
      final filtered = faqs.where((faq) =>
      faq.question.toLowerCase().contains(searchQuery.value) ||
          faq.answer.toLowerCase().contains(searchQuery.value)
      ).toList();

      filteredFaqs.assignAll(filtered);
    }
  }

  void clearSearch() {
    searchController.clear(); // Clear the text field
    searchQuery.value = '';
    filteredFaqs.assignAll(faqs);
  }

  void contactSupport() {
    // Handle contact support action
    Get.snackbar(
      "Support",
      "Redirecting to support...",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void retryFetchFAQs() {
    fetchFAQs();
  }
}