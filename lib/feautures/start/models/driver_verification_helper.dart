// lib/utils/helpers/driver_verification_helper.dart
class DriverVerificationHelper {
  static Map<String, String> getVerificationStatus(Map<String, dynamic> driverProfile) {
    final status = <String, String>{};

    // Check CNIC status
    final cnicStatus = driverProfile['document']?['cnic']?['status']?.toString();
    status['cnic'] = cnicStatus ?? 'missing';

    // Check License status
    final licenseStatus = driverProfile['document']?['license']?['status']?.toString();
    status['license'] = licenseStatus ?? 'missing';

    // Check Registration status
    final regStatus = driverProfile['vehicle']?['registration_card']?['status']?.toString();
    status['registration'] = regStatus ?? 'missing';

    // Check Vehicle status
    final vehicleStatus = driverProfile['vehicle']?['status']?.toString();
    status['vehicle'] = vehicleStatus ?? 'missing';

    // Check Selfie verification
    final isSelfieVerified = driverProfile['is_selfie_verified'] ?? false;
    status['selfie'] = isSelfieVerified ? 'verified' : 'pending';

    // Check overall approval
    final isApproved = driverProfile['isApproved'] ?? false;
    status['overall'] = isApproved ? 'approved' : 'pending';

    return status;
  }

  // ✅ ADDED: Check if any document is rejected
  static bool hasRejectedDocuments(Map<String, dynamic> driverProfile) {
    final status = getVerificationStatus(driverProfile);

    return status['cnic'] == 'rejected' ||
        status['license'] == 'rejected' ||
        status['registration'] == 'rejected' ||
        status['vehicle'] == 'rejected';
  }

  // ✅ ADDED: Get specific rejected reasons
  static List<String> getRejectedReasons(Map<String, dynamic> driverProfile) {
    final status = getVerificationStatus(driverProfile);
    final rejectedReasons = <String>[];

    if (status['cnic'] == 'rejected') rejectedReasons.add('CNIC was rejected');
    if (status['license'] == 'rejected') rejectedReasons.add('License was rejected');
    if (status['registration'] == 'rejected') rejectedReasons.add('Registration was rejected');
    if (status['vehicle'] == 'rejected') rejectedReasons.add('Vehicle was rejected');

    return rejectedReasons;
  }

  // ✅ UPDATED: Check if fully verified (must have no rejections)
  static bool isFullyVerified(Map<String, dynamic> driverProfile) {
    final status = getVerificationStatus(driverProfile);

    return status['cnic'] == 'approved' &&
        status['license'] == 'approved' &&
        status['registration'] == 'approved' &&
        status['vehicle'] == 'approved' &&
        status['selfie'] == 'verified' &&
        status['overall'] == 'approved' &&
        !hasRejectedDocuments(driverProfile); // ✅ ADDED: No rejections
  }

  // ✅ UPDATED: Get blocking reason that distinguishes rejected vs pending
  static String getBlockingReason(Map<String, dynamic> driverProfile) {
    final status = getVerificationStatus(driverProfile);

    // ✅ FIRST: Check for rejected documents
    if (status['cnic'] == 'rejected') return 'CNIC was rejected - please re-upload';
    if (status['license'] == 'rejected') return 'License was rejected - please re-upload';
    if (status['registration'] == 'rejected') return 'Registration was rejected - please re-upload';
    if (status['vehicle'] == 'rejected') return 'Vehicle was rejected - please re-upload';

    // ✅ THEN: Check for pending approvals
    if (status['cnic'] != 'approved') return 'CNIC verification pending';
    if (status['license'] != 'approved') return 'License verification pending';
    if (status['registration'] != 'approved') return 'Registration verification pending';
    if (status['vehicle'] != 'approved') return 'Vehicle verification pending';
    if (status['selfie'] != 'verified') return 'Selfie verification pending';
    if (status['overall'] != 'approved') return 'Profile approval pending';

    return 'All verifications completed';
  }

  static bool hasUploadedAllDocuments(Map<String, dynamic> driverProfile) {
    final cnic = driverProfile['document']?['cnic'];
    final license = driverProfile['document']?['license'];
    final registration = driverProfile['vehicle']?['registration_card'];
    final vehicleImages = driverProfile['vehicle']?['vehicle_images'];
    final selfie = driverProfile['selfie'];

    // Check if all required documents are uploaded (not necessarily approved)
    final hasCnic = cnic != null && cnic['front'] != null && cnic['back'] != null;
    final hasLicense = license != null && license['front'] != null && license['back'] != null;
    final hasRegistration = registration != null && registration['front'] != null && registration['back'] != null;
    final hasVehicleImages = vehicleImages != null &&
        vehicleImages['front_side'] != null &&
        vehicleImages['back_side'] != null &&
        vehicleImages['side_one'] != null &&
        vehicleImages['side_two'] != null &&
        vehicleImages['inside_front'] != null &&
        vehicleImages['inside_back'] != null;
    final hasSelfie = selfie != null;

    return hasCnic && hasLicense && hasRegistration && hasVehicleImages && hasSelfie;
  }
}