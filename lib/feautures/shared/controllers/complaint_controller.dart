import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../../../common/widgets/snakbar/snackbar.dart';
import '../../../utils/http/http_client.dart';
import '../models/complaint_model.dart';
import 'package:flutter/material.dart';
import '../screens/complaint_detail_screen.dart';
import '../screens/complaint_screen.dart';
import '../services/storage_service.dart';

class ComplaintController extends GetxController {
  // Observable lists
  var complaintsList = <ComplaintModel>[].obs;
  var driverInfo = Rxn<DriverModel>();

  // Form fields
  var complaintDescription = ''.obs;
  var selectedCategory = ''.obs;
  var uploadedFiles = <String>[].obs;
  var uploadedBase64Files = <Map<String, dynamic>>[].obs;

  // Loading states
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var hasError = false.obs; // Added error state

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Complaint arguments storage
  var rideId = ''.obs;
  var complaintForId = ''.obs;
  var driverId = ''.obs;
  var passengerId = ''.obs;

  // Categories list
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
      hasError.value = false;

      // Get user data from storage
      final userId = StorageService.getSignUpResponse()!.userId;
      if (userId == null) {
        FSnackbar.show(title: "Error", message: "User data not found");
        hasError.value = true;
        return;
      }

      final userRole = StorageService.getRole();

      // Call API
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('complaint/by/$userId/$userRole');

      // Check if response contains 'complaints' key
      if (response.containsKey('complaints')) {
        final complaintsData = response['complaints'];

        if (complaintsData is List && complaintsData.isNotEmpty) {
          // Has complaints data
          complaintsList.assignAll(complaintsData.map((complaintData) => ComplaintModel.fromJson(complaintData)).toList());
        } else {
          // 'complaints' key exists but is empty or null
          complaintsList.clear();
        }
      } else {
        // 'complaints' key doesn't exist in response
        hasError.value = true;
        FSnackbar.show(title: "Error", message: "Invalid response from server");
        complaintsList.clear();
      }

    } catch (e) {
      print('Error fetching complaints: $e');
      hasError.value = true;
      FSnackbar.show(title: "Error", message: "Failed to fetch complaints");
      complaintsList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Retry fetching complaints
  void retryFetchComplaints() {
    fetchComplaints();
  }

  // Set complaint arguments from ride details
  void setComplaintArguments({
    required String rideId,
    required String complaintForId,
    String? driverId,
    String? passengerId,
  }) {
    this.rideId.value = rideId;
    this.complaintForId.value = complaintForId;
    this.driverId.value = driverId ?? '';
    this.passengerId.value = passengerId ?? '';

    print('📝 Complaint arguments set:');
    print('   Ride ID: $rideId');
    print('   Complaint For ID: $complaintForId');
    print('   Driver ID: $driverId');
    print('   Passenger ID: $passengerId');
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
        imageUrl: 'assets/Dashboard/profile.png',
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

  // Convert file to base64 with metadata
  Future<Map<String, dynamic>?> _fileToBase64(File file) async {
    try {
      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);

      // Get file info
      String fileName = path.basename(file.path);
      String fileExtension = path.extension(file.path).toLowerCase();
      int fileSize = await file.length();
      String mimeType = _getMimeType(fileExtension);

      return {
        'base64': base64String,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'extension': fileExtension,
      };
    } catch (e) {
      print('❌ Error converting file to base64: $e');
      return null;
    }
  }

  // Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  // Handle file upload with base64 conversion
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

      File? selectedFile;

      switch (choice) {
        case 'camera':
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (photo != null) {
            selectedFile = File(photo.path);
          }
          break;

        case 'gallery':
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
          if (image != null) {
            selectedFile = File(image.path);
          }
          break;

        case 'video':
          final XFile? video = await _picker.pickVideo(
            source: ImageSource.gallery,
          );
          if (video != null) {
            selectedFile = File(video.path);
          }
          break;

        case 'file':
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'mp4', 'avi'],
          );
          if (result != null && result.files.single.path != null) {
            selectedFile = File(result.files.single.path!);
          }
          break;
      }

      if (selectedFile != null) {
        // Convert file to base64
        Map<String, dynamic>? base64File = await _fileToBase64(selectedFile);

        if (base64File != null) {
          uploadedBase64Files.add(base64File);
          uploadedFiles.add(selectedFile.path);

          FSnackbar.show(
              title: "Success",
              message: "File added successfully (${_formatFileSize(base64File['fileSize'])})"
          );
        } else {
          FSnackbar.show(
              title: "Error",
              message: "Failed to process file",
              isError: true
          );
        }
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      FSnackbar.show(
          title: "Error",
          message: "Failed to upload file",
          isError: true
      );
    }
  }

  // Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // Remove uploaded file
  void removeFile(int index) {
    if (index >= 0 && index < uploadedBase64Files.length) {
      uploadedBase64Files.removeAt(index);
      if (index < uploadedFiles.length) {
        uploadedFiles.removeAt(index);
      }
      FSnackbar.show(title: "Removed", message: "File removed successfully");
    }
  }

  // Submit complaint with base64 files
  // Future<void> submitComplaint() async {
  //   // Validation
  //   if (complaintDescription.value.trim().isEmpty) {
  //     FSnackbar.show(title: "Error", message: "Please describe your complaint", isError: true);
  //     return;
  //   }
  //
  //   if (selectedCategory.value.isEmpty) {
  //     FSnackbar.show(title: "Error", message: "Please select a category", isError: true);
  //     return;
  //   }
  //
  //   // Validate required IDs
  //   if (rideId.value.isEmpty || complaintForId.value.isEmpty) {
  //     FSnackbar.show(title: "Error", message: "Missing required ride information", isError: true);
  //     return;
  //   }
  //
  //   try {
  //     isSubmitting.value = true;
  //
  //     final requestBody = {
  //       "rideId": rideId.value,
  //       "complaintForId": complaintForId.value,
  //       "type": _mapCategoryToType(selectedCategory.value),
  //       "comment": complaintDescription.value.trim(),
  //       "complaint_type": "ride_issue",
  //       "attachments": uploadedBase64Files.isNotEmpty
  //           ? uploadedBase64Files.map((file) => {
  //         'data': file['base64'],
  //         'fileName': file['fileName'],
  //         'fileSize': file['fileSize'],
  //         'mimeType': file['mimeType'],
  //       }).toList()
  //           : [],
  //     };
  //
  //     print('📤 Submitting complaint with ${uploadedBase64Files.length} files');
  //     print('📤 Request body keys: ${requestBody.keys}');
  //     print('📤 Attachment count: ${uploadedBase64Files.length}');
  //
  //     final response = await FHttpHelper.post(
  //       'complaint/add',
  //       requestBody,
  //     );
  //
  //     print('📥 Complaint API response: $response');
  //
  //     if (response['success'] == true || response['message'] != null) {
  //       FSnackbar.show(
  //         title: "Success",
  //         message: "Your complaint has been submitted successfully",
  //       );
  //
  //       // Clear form
  //       _clearForm();
  //
  //       // Refresh complaints list
  //       fetchComplaints();
  //
  //       Get.to(() => ComplaintsListScreen());
  //     } else {
  //       throw Exception('Failed to submit complaint: ${response['error']}');
  //     }
  //
  //   } catch (e) {
  //     print('❌ Error submitting complaint: $e');
  //     FSnackbar.show(
  //         title: "Error",
  //         message: "Failed to submit complaint: ${e.toString()}",
  //         isError: true
  //     );
  //   } finally {
  //     isSubmitting.value = false;
  //   }
  // }

  // Clear form data
  void _clearForm() {
    complaintDescription.value = '';
    selectedCategory.value = '';
    uploadedFiles.clear();
    uploadedBase64Files.clear();
  }

  // Get file count for UI
  int get fileCount => uploadedBase64Files.length;

  // Get total file size for UI
  String get totalFileSize {
    if (uploadedBase64Files.isEmpty) return '0 B';

    int totalBytes = uploadedBase64Files.fold(0, (sum, file) => sum + (file['fileSize'] as int));
    return _formatFileSize(totalBytes);
  }

  // Helper method to map category to type
  String _mapCategoryToType(String category) {
    switch (category.toLowerCase()) {
      case 'fare dispute':
        return 'refund';
      case 'lost item':
        return 'lost item';
      default:
        return 'dispute';
    }
  }

  // Navigate to complaint details
  void viewComplaintDetails(ComplaintModel complaint) {
    Get.to(() => ComplaintDetailScreen(complaint: complaint));
  }
}


// import 'package:file_picker/file_picker.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../../common/widgets/snakbar/snackbar.dart';
// import '../../../utils/http/http_client.dart';
// import '../models/complaint_model.dart';
// import 'package:flutter/material.dart';
// import '../screens/complaint_detail_screen.dart';
// import '../services/storage_service.dart';
//
// class ComplaintController extends GetxController {
//   // Observable lists
//   var complaintsList = <ComplaintModel>[].obs;
//   var driverInfo = Rxn<DriverModel>();
//
//   // Form fields
//   var complaintDescription = ''.obs;
//   var selectedCategory = ''.obs;
//   var uploadedFiles = <String>[].obs;
//
//   // Loading states
//   var isLoading = false.obs;
//   var isSubmitting = false.obs;
//
//   // Image picker instance
//   final ImagePicker _picker = ImagePicker();
//
//   // ✅ ADDED: Complaint arguments storage
//   var rideId = ''.obs;
//   var complaintForId = ''.obs;
//   var driverId = ''.obs;
//   var passengerId = ''.obs;
//
//   // Categories list (can be fetched from backend)
//   final List<String> categories = [
//     'Fare Dispute',
//     'Driver Behavior',
//     'Safety Concern',
//     'Service Quality',
//     'Vehicle Condition',
//     'Route Issue',
//     'Other'
//   ];
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchComplaints();
//     fetchDriverInfo();
//   }
//
//   // Fetch complaints from backend
//   Future<void> fetchComplaints() async {
//     try {
//       isLoading.value = true;
//
//       // Get user data from storage
//       final userId = StorageService.getSignUpResponse()!.userId;
//       if (userId == null) {
//         FSnackbar.show(title: "Error", message: "User data not found");
//         return;
//       }
//
//       final userRole = StorageService.getRole();
//
//       // Call API
//       final response = await FHttpHelper.get('complaint/by/$userId/$userRole');
//
//       if (response['complaints'] != null) {
//         final complaintsData = List<Map<String, dynamic>>.from(response['complaints'] ?? []);
//         complaintsList.assignAll(complaintsData.map((complaintData) => ComplaintModel.fromJson(complaintData)).toList());
//       }
//     } catch (e) {
//       print('Error fetching complaints: $e');
//       FSnackbar.show(title: "Error", message: "Failed to fetch complaints");
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // ✅ ADDED: Set complaint arguments from ride details
//   void setComplaintArguments({
//     required String rideId,
//     required String complaintForId,
//     String? driverId,
//     String? passengerId,
//   }) {
//     this.rideId.value = rideId;
//     this.complaintForId.value = complaintForId;
//     this.driverId.value = driverId ?? '';
//     this.passengerId.value = passengerId ?? '';
//
//     print('📝 Complaint arguments set:');
//     print('   Ride ID: $rideId');
//     print('   Complaint For ID: $complaintForId');
//     print('   Driver ID: $driverId');
//     print('   Passenger ID: $passengerId');
//   }
//
//
//   // Fetch driver info from backend
//   Future<void> fetchDriverInfo() async {
//     try {
//       // Simulate API call - Replace with actual API
//       await Future.delayed(const Duration(milliseconds: 500));
//
//       // Mock data with image URL
//       driverInfo.value = DriverModel(
//         name: 'Malik Shahid',
//         rating: 4.8,
//         totalRides: 102,
//         role: 'Platinum driver',
//         imageUrl: 'assets/Dashboard/profile.png', // Replace with actual URL
//       );
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to fetch driver info');
//     }
//   }
//
//   // Update form fields
//   void updateDescription(String value) {
//     complaintDescription.value = value;
//   }
//
//   void updateCategory(String value) {
//     selectedCategory.value = value;
//   }
//
//   // Handle file upload - FUNCTIONAL
//   Future<void> uploadFiles() async {
//     try {
//       // Show options for image or file
//       final choice = await Get.dialog<String>(
//         Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Choose Upload Type',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ListTile(
//                   leading: const Icon(Icons.camera_alt),
//                   title: const Text('Take Photo'),
//                   onTap: () => Get.back(result: 'camera'),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.photo_library),
//                   title: const Text('Choose from Gallery'),
//                   onTap: () => Get.back(result: 'gallery'),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.videocam),
//                   title: const Text('Choose Video'),
//                   onTap: () => Get.back(result: 'video'),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.insert_drive_file),
//                   title: const Text('Choose File'),
//                   onTap: () => Get.back(result: 'file'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//
//       if (choice == null) return;
//
//       switch (choice) {
//         case 'camera':
//           final XFile? photo = await _picker.pickImage(
//             source: ImageSource.camera,
//             imageQuality: 80,
//           );
//           if (photo != null) {
//             uploadedFiles.add(photo.path);
//             Get.snackbar('Success', 'Photo added successfully');
//           }
//           break;
//
//         case 'gallery':
//           final XFile? image = await _picker.pickImage(
//             source: ImageSource.gallery,
//             imageQuality: 80,
//           );
//           if (image != null) {
//             uploadedFiles.add(image.path);
//             Get.snackbar('Success', 'Image added successfully');
//           }
//           break;
//
//         case 'video':
//           final XFile? video = await _picker.pickVideo(
//             source: ImageSource.gallery,
//           );
//           if (video != null) {
//             uploadedFiles.add(video.path);
//             Get.snackbar('Success', 'Video added successfully');
//           }
//           break;
//
//         case 'file':
//           FilePickerResult? result = await FilePicker.platform.pickFiles(
//             type: FileType.custom,
//             allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
//           );
//           if (result != null && result.files.single.path != null) {
//             uploadedFiles.add(result.files.single.path!);
//             Get.snackbar('Success', 'File added successfully');
//           }
//           break;
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to upload file: $e');
//     }
//   }
//
//   // Remove uploaded file
//   void removeFile(String filePath) {
//     uploadedFiles.remove(filePath);
//     Get.snackbar('Removed', 'File removed successfully');
//   }
//
// // ✅ UPDATED: Submit complaint with API call
//   Future<void> submitComplaint() async {
//     // Validation
//     if (complaintDescription.value.trim().isEmpty) {
//       Get.snackbar('Error', 'Please describe your complaint');
//       return;
//     }
//
//     if (selectedCategory.value.isEmpty) {
//       Get.snackbar('Error', 'Please select a category');
//       return;
//     }
//
//     // ✅ ADDED: Validate required IDs
//     if (rideId.value.isEmpty || complaintForId.value.isEmpty) {
//       Get.snackbar('Error', 'Missing required ride information');
//       return;
//     }
//
//     try {
//       isSubmitting.value = true;
//
//       // ✅ UPDATED: Prepare request body for API
//       final requestBody = {
//         "rideId": rideId.value,
//         "complaintForId": complaintForId.value,
//         "type": _mapCategoryToType(selectedCategory.value), // Map category to type
//         "comment": complaintDescription.value.trim(),
//         "complaint_type": "ride_issue", // Default value
//         "attachment_url": uploadedFiles.isNotEmpty ? uploadedFiles.join(',') : "", // Simple attachment handling
//       };
//
//       print('📤 Submitting complaint with data: $requestBody');
//
//       // ✅ UPDATED: Make actual API call
//       final response = await FHttpHelper.post(
//         'complaint/add',
//         requestBody,
//       );
//
//       print('📥 Complaint API response: $response');
//
//       if (response['success'] == true || response['message'] != null) {
//         Get.snackbar(
//           'Success',
//           'Your complaint has been submitted successfully',
//           snackPosition: SnackPosition.BOTTOM,
//         );
//
//         // Clear form
//         complaintDescription.value = '';
//         selectedCategory.value = '';
//         uploadedFiles.clear();
//
//         // Navigate back
//         Get.back();
//
//         // Refresh complaints list
//         fetchComplaints();
//       } else {
//         throw Exception('Failed to submit complaint: ${response['error']}');
//       }
//
//     } catch (e) {
//       print('❌ Error submitting complaint: $e');
//       Get.snackbar('Error', 'Failed to submit complaint: ${e.toString()}');
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
//
//   // ✅ ADDED: Helper method to map category to type
//   String _mapCategoryToType(String category) {
//     switch (category.toLowerCase()) {
//       case 'fare dispute':
//         return 'refund';
//       case 'lost item':
//         return 'lost item';
//       default:
//         return 'dispute';
//     }
//   }
//
//   // Navigate to complaint details
//   void viewComplaintDetails(ComplaintModel complaint) {
//     Get.to(() => ComplaintDetailScreen(complaint: complaint));
//   }
// }