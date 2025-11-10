import 'package:get/get.dart';

import '../models/help_model.dart';


class HelpController extends GetxController {
  final RxList<FAQ> faqs = <FAQ>[
    FAQ(
      question: "How do I rate a rider?",
      answer: "After your ride, you'll be prompted to rate the rider on a scale of 1 to 5 stars. You can also leave additional feedback.",
    ),
    FAQ(
      question: "What happens if I have a problem with a rider?",
      answer: "If you experience any issues with a rider, you can report the problem through our support system. We take all complaints seriously and will investigate accordingly.",
    ),
    FAQ(
      question: "Can I change my rating after submitting it?",
      answer: "Once you submit a rating, it cannot be changed. Please make sure you're satisfied with your rating before confirming it.",
    ),
  ].obs;

  void toggleFAQ(int index) {
    faqs[index].isExpanded = !faqs[index].isExpanded;
    faqs.refresh();
  }

  void contactSupport() {
    // Handle contact support action
    Get.snackbar(
      "Support",
      "Redirecting to support...",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
