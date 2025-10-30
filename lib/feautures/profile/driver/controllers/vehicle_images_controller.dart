import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/vehicle_verification_model.dart';

class VehicleImagesController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxBool isLoading = false.obs;

  final RxList<String?> capturedImages = List<String?>.filled(7, null).obs;

  final List<VehicleImagesStep> steps = [
    VehicleImagesStep(
      title: 'Front Side',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/Front.svg',
      stepNumber: 1,
      width: 380,
      height: 285,
    ),
    VehicleImagesStep(
      title: 'Back Side',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/back.svg',
      stepNumber: 2,
      width: 380,
      height: 285,
    ),
    VehicleImagesStep(
      title: 'Side One',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/left.svg',
      stepNumber: 3,
      width: 420,
      height: 300,
    ),
    VehicleImagesStep(
      title: 'Side Two',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/right.svg',
      stepNumber: 4,
      width: 420,
      height: 300,
    ),
    VehicleImagesStep(
      title: 'Inside Front',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/finside.svg',
      stepNumber: 5,
      width: 360,
      height: 270,
    ),
    VehicleImagesStep(
      title: 'Inside Back',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/binside.svg',
      stepNumber: 6,
      width: 360,
      height: 270,
    ),
    VehicleImagesStep(
      title: 'Vehicle Photo',
      description: 'Please provide detailed information about the vehicle',
      imagePath: 'assets/images/Front.svg',
      stepNumber: 7,
      width: 400,
      height: 320,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    pageController.addListener(() {
      currentPage.value = pageController.page?.round() ?? 0;
    });
  }

  void nextPage() {
    if (currentPage.value < steps.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void submitVerification() async {
    final allPhotosUploaded = capturedImages.take(6).every((image) => image != null);
    if (!allPhotosUploaded) {
      Get.snackbar(
        'Incomplete',
        'Please capture all 6 photos before submitting.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;

    final result = {
      "front_side": capturedImages[0],
      "back_side": capturedImages[1],
      "side_one": capturedImages[2],
      "side_two": capturedImages[3],
      "inside_front": capturedImages[4],
      "inside_back": capturedImages[5],
    };

    Get.back(result: result);

    Get.snackbar(
      'Success',
      'Vehicle verification photos added successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void jumpToStep(int index) {
    if (index >= 0 && index < steps.length - 1) {
      pageController.jumpToPage(index);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}