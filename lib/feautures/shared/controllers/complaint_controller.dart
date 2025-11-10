import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/complaint_model.dart';
import 'package:flutter/material.dart';

class ComplaintController extends GetxController {
  // Observable lists
  var complaintsList = <ComplaintModel>[].obs;
  var driverInfo = Rxn<DriverModel>();

  // Form fields
  var complaintDescription = ''.obs;
  var selectedCategory = ''.obs;
  var uploadedFiles = <String>[].obs;

  // Loading states
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Categories list (can be fetched from backend)
  final List<String> categories = [
    'Fare Dispute',
    'Driver Behavior',
    'Safety Concern',
    'Service Quality',
    'Vehicle Condition',
    'Route Issue',
    'Other'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchComplaints();
    fetchDriverInfo();
  }

  // Fetch complaints from backend
  Future<void> fetchComplaints() async {
    try {
      isLoading.value = true;

      // Simulate API call - Replace with actual API
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      complaintsList.value = [
        ComplaintModel(
          status: 'Open',
          issue: 'Fare Dispute',
          id: '1',
        ),
        ComplaintModel(
          status: 'Resolved',
          issue: 'Driver Behavior',
          id: '2',
        ),
        ComplaintModel(
          status: 'Under Review',
          issue: 'Safety Concern',
          id: '3',
        ),
      ];
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch complaints');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch driver info from backend
  Future<void> fetchDriverInfo() async {
    try {
      // Simulate API call - Replace with actual API
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data with image URL
      driverInfo.value = DriverModel(
        name: 'Malik Shahid',
        rating: 4.8,
        totalRides: 102,
        role: 'Platinum driver',
        imageUrl: 'assets/Dashboard/profile.png', // Replace with actual URL
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch driver info');
    }
  }

  // Update form fields
  void updateDescription(String value) {
    complaintDescription.value = value;
  }

  void updateCategory(String value) {
    selectedCategory.value = value;
  }

  // Handle file upload - FUNCTIONAL
  Future<void> uploadFiles() async {
    try {
      // Show options for image or file
      final choice = await Get.dialog<String>(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Upload Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () => Get.back(result: 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Get.back(result: 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Choose Video'),
                  onTap: () => Get.back(result: 'video'),
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Choose File'),
                  onTap: () => Get.back(result: 'file'),
                ),
              ],
            ),
          ),
        ),
      );

      if (choice == null) return;

      switch (choice) {
        case 'camera':
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (photo != null) {
            uploadedFiles.add(photo.path);
            Get.snackbar('Success', 'Photo added successfully');
          }
          break;

        case 'gallery':
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
          if (image != null) {
            uploadedFiles.add(image.path);
            Get.snackbar('Success', 'Image added successfully');
          }
          break;

        case 'video':
          final XFile? video = await _picker.pickVideo(
            source: ImageSource.gallery,
          );
          if (video != null) {
            uploadedFiles.add(video.path);
            Get.snackbar('Success', 'Video added successfully');
          }
          break;

        case 'file':
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
          );
          if (result != null && result.files.single.path != null) {
            uploadedFiles.add(result.files.single.path!);
            Get.snackbar('Success', 'File added successfully');
          }
          break;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload file: $e');
    }
  }

  // Remove uploaded file
  void removeFile(String filePath) {
    uploadedFiles.remove(filePath);
    Get.snackbar('Removed', 'File removed successfully');
  }

  // Submit complaint
  Future<void> submitComplaint() async {
    // Validation
    if (complaintDescription.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please describe your complaint');
      return;
    }

    if (selectedCategory.value.isEmpty) {
      Get.snackbar('Error', 'Please select a category');
      return;
    }

    try {
      isSubmitting.value = true;

      // Simulate API call - Replace with actual API
      // Send complaintDescription, selectedCategory, and uploadedFiles to backend
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful submission
      Get.snackbar(
        'Success',
        'Your complaint has been submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Clear form
      complaintDescription.value = '';
      selectedCategory.value = '';
      uploadedFiles.clear();

      // Navigate back
      Get.back();

      // Refresh complaints list
      fetchComplaints();
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit complaint: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Navigate to complaint details
  void viewComplaintDetails(ComplaintModel complaint) {
    // Implement navigation to complaint details screen
    Get.snackbar('Info', 'Viewing ${complaint.issue}');
  }
}