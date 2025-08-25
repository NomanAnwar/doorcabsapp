import 'package:flutter/material.dart';

/// Centralized text constants for DoorCabs app.
/// Covers both Passenger & Driver flows similar to inDrive.
/// Updated for phone number + OTP only authentication.
class FTextStrings {
  FTextStrings._();

  // -------------------
  // App Info
  // -------------------
  static const String baseUrl = '';
  static const String cloudinaryKey = '';
  static const String appName = "DoorCabs";

  // -------------------
  // Splash

  static const String splahTagLine = "Pakistan’s 1st Actual Ride Hailing App";
  static const String wellcomeTagLine = "Get Start With DoorCabs";
  static const String wellcomeSubheading = "With Your Phone Number";
  static const String otpTagLine = "PHone Verificatrion";
  static const String otpSubheading = "Enter Your OTP Code Here";

  // -------------------
  // Roles
  static const String selectUserType = "Select Your Role";
  static const String driver = "Driver";
  static const String passenger = "Passenger";


  // -------------------
  // Languages
  static const String english = "English";
  static const String urdu = "Urdu";



  // -------------------
  static const String home = "Home";
  static const String done = "Done";
  static const String submit = "Submit";
  static const String save = "Save";
  static const String skip = "Skip";
  static const String next = "Next";
  static const String continueText = "Continue";
  static const String edit = "Edit";
  static const String cancel = "Cancel";
  static const String back = "Back";
  static const String yes = "Yes";
  static const String no = "No";
  static const String search = "Search";
  static const String requiredField = "Field is Required";
  static const String loading = "Loading...";
  static const String tryAgain = "Try Again";

  // -------------------
  // Phone Auth
  // -------------------
  static const String welcomeToApp = "Welcome to DoorCabs";
  static const String enterPhoneNumber = "Enter your phone number";
  static const String phoneNumber = "Phone Number";
  static const String sendOtp = "Send Code";
  static const String enterOtp = "Enter the verification code";
  static const String otpSentTo = "We sent a code to";
  static const String resendCode = "Resend Code";
  static const String verifyingCode = "Verifying Code...";
  static const String otpVerificationSuccess = "Phone number verified successfully";
  static const String incorrectOtp = "Incorrect code. Please try again.";
  static const String phoneAuthDescription =
      "Enter your phone number and we’ll send you a verification code to sign in or create an account.";

  // -------------------
  // Onboarding After Verification
  // -------------------
  static const String completeProfile = "Complete Your Profile";
  static const String firstName = "First Name";
  static const String lastName = "Last Name";
  static const String uploadProfilePhoto = "Upload Profile Photo";
  // -------------------
  // Ride Booking (Passenger)
  // -------------------
  static const String whereTo = "Where to?";
  static const String setPickupLocation = "Set Pickup Location";
  static const String setDropoffLocation = "Set Drop-off Location";
  static const String confirmPickup = "Confirm Pickup";
  static const String confirmDropoff = "Confirm Drop-off";
  static const String rideType = "Select Ride Type";
  static const String offerYourFare = "Offer Your Fare";
  static const String fareAmount = "Fare Amount";
  static const String enterFare = "Enter Your Offer";
  static const String searchDrivers = "Searching for Drivers...";
  static const String driverFound = "Driver Found";
  static const String noDriversFound = "No Drivers Found Nearby";
  static const String waitingForDriver = "Waiting for Driver to Accept";

  // -------------------
  // Driver Offers (Driver)
  // -------------------
  static const String newRideRequest = "New Ride Request";
  static const String acceptRide = "Accept Ride";
  static const String rejectRide = "Reject Ride";
  static const String counterOffer = "Counter Offer";
  static const String passengerOffer = "Passenger's Offer";
  static const String yourCounterOffer = "Your Counter Offer";

  // -------------------
  // Trip Details
  // -------------------
  static const String tripStarted = "Trip Started";
  static const String tripCompleted = "Trip Completed";
  static const String tripCancelled = "Trip Cancelled";
  static const String cancelTrip = "Cancel Trip";
  static const String confirmCancelTrip = "Are you sure you want to cancel the trip?";
  static const String rateYourDriver = "Rate Your Driver";
  static const String rateYourPassenger = "Rate Your Passenger";
  static const String leaveAReview = "Leave a Review";

  // -------------------
  // Chat
  // -------------------
  static const String chatWithDriver = "Chat with Driver";
  static const String chatWithPassenger = "Chat with Passenger";
  static const String typeMessage = "Type a message...";
  static const String send = "Send";

  // -------------------
  // Payments
  // -------------------
  static const String paymentMethod = "Payment Method";
  static const String cash = "Cash";
  static const String card = "Card";
  static const String addPaymentMethod = "Add Payment Method";
  static const String paymentSuccessful = "Payment Successful";
  static const String paymentFailed = "Payment Failed";
  static const String fare = "Fare";
  static const String totalFare = "Total Fare";
  static const String tripReceipt = "Trip Receipt";

  // -------------------
  // Notifications
  // -------------------
  static const String notification = "Notification";
  static const String newMessage = "New Message";
  static const String rideRequest = "Ride Request";
  static const String rideStatusUpdate = "Ride Status Update";

  // -------------------
  // Profile
  // -------------------
  static const String profile = "Profile";
  static const String editProfile = "Edit Profile";
  static const String logout = "Log out";
  static const String accountVerification = "Account Verification";
  static const String verified = "Verified";
  static const String notVerified = "Not Verified";

  // -------------------
  // Driver Specific
  // -------------------
  static const String vehicleDetails = "Vehicle Details";
  static const String vehicleType = "Vehicle Type";
  static const String vehicleModel = "Vehicle Model";
  static const String vehicleColor = "Vehicle Color";
  static const String licensePlate = "License Plate Number";
  static const String uploadLicense = "Upload Driver's License";
  static const String uploadVehicleDocs = "Upload Vehicle Documents";

  // -------------------
  // Success Messages
  // -------------------
  static const String successMessage = "Success!";
  static const String profileSetupComplete = "Your profile has been set up successfully";
}
