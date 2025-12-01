// lib/shared/services/storage_service.dart
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../start/models/sign_up_response.dart';
import '../models/payment_method_model.dart';
import '../models/place_suggestion.dart';
import '../models/support_chat_model.dart';

class StorageService {
  static final _box = GetStorage();

  // Common Keys
  static const _recentKey = 'recent_places';
  static const _profileKey = 'profile_data';
  static const _kSignUpResponse = 'signup_response';
  static const _kUserId = 'userId';
  static const _kAuthToken = 'auth_token';
  static const _kIsLoggedIn = 'isLoggedIn';

  // Ride types cache
  static const _kRideTypesCache = 'ride_types_cache_v1';

  // Passenger Profile Completion
  static const _kProfileCompleted = 'profile_completed';

  // Driver profile completion flag
  static const _kDriverProfileCompleted = 'driver_profile_completed';

  // ✅ ADDED: Driver Online Status
  static const _kDriverOnlineStatus = 'driver_online_status';

  static const _kAutoAcceptStatus = 'auto_accept_status';

  // Chat storage keys
  static const _kChatMessages = 'chat_messages_';

  // Payment Methods Storage
  static const _kPaymentMethod = 'payment_method';

  // Support Chat Storage Keys
  static const _kSupportChatMessages = 'support_chat_messages';
  static const _kSupportChatId = 'support_chat_id';
  static const _kSupportChatStatus = 'support_chat_status';

  // For Que Ride

  // Add to StorageService class - Queue Rides for Driver
  static const kDriverQueueRides = 'driver_queue_rides';
  static const kMaxQueueRides = 1; // Only one ride in queue

// Active Rides Storage
  static const kActiveRides = 'active_rides';
  static const kMaxActiveRides = 3;


  // Driver Queue ride

  /// Save a ride to driver's queue
  static Future<void> saveQueueRide(String rideId, Map<String, dynamic> rideData) async {
    final queueRides = getQueueRides();

    // Remove existing ride with same ID
    queueRides.removeWhere((ride) => ride['rideId'] == rideId);

    // Ensure all data is serializable
    final serializableData = _makeSerializable(rideData);

    // Add new ride with timestamp
    queueRides.add({
      'rideId': rideId,
      'rideData': serializableData,
      'queuedAt': DateTime.now().millisecondsSinceEpoch,
      'version': 1,
    });

    await _box.write(kDriverQueueRides, queueRides);
    print('💾 Queue ride saved: $rideId, total in queue: ${queueRides.length}');
  }

  /// Get all queued rides for driver
  static List<Map<String, dynamic>> getQueueRides() {
    final rides = _box.read<List>(kDriverQueueRides) ?? [];
    return rides.map((ride) => _convertToStringMap(ride)).toList();
  }


  /// Remove a queued ride
  static Future<void> removeQueueRide(String rideId) async {
    final queueRides = getQueueRides();
    queueRides.removeWhere((ride) => ride['rideId'] == rideId);
    await _box.write(kDriverQueueRides, queueRides);
    print('🗑️ Queue ride removed: $rideId, remaining: ${queueRides.length}');
  }

  /// Check if driver can add more rides to queue
  static bool canAddMoreQueueRides() {
    return getQueueRides().length < kMaxQueueRides;
  }

  /// Get the current number of queued rides
  static int getQueueRidesCount() {
    return getQueueRides().length;
  }

  /// Clear all queued rides (for testing/logout)
  static Future<void> clearAllQueueRides() async {
    await _box.remove(kDriverQueueRides);
    print('🧹 All queue rides cleared');
  }

  /// Get the next queued ride (FIFO - First In First Out)
  static Map<String, dynamic>? getNextQueueRide() {
    final queueRides = getQueueRides();
    return queueRides.isNotEmpty ? queueRides.first : null;
  }


  // Driver Queue ride

  static Future<void> saveActiveRide(String rideId, Map<String, dynamic> rideData) async {
    final activeRides = getActiveRides();

    // Remove existing ride with same ID
    activeRides.removeWhere((ride) => ride['rideId'] == rideId);

    // Ensure all data is serializable
    final serializableData = _makeSerializable(rideData);

    // Add new ride with timestamp
    activeRides.add({
      'rideId': rideId,
      'rideData': serializableData,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'version': 1, // Add version for future compatibility
    });

    await _box.write(kActiveRides, activeRides);
    print('💾 Active ride saved: $rideId, total: ${activeRides.length}');
  }

  /// Helper to make data serializable
  static Map<String, dynamic> _makeSerializable(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is DateTime) {
        result[key] = value.millisecondsSinceEpoch;
      } else if (value is LatLng) {
        result[key] = {'lat': value.latitude, 'lng': value.longitude};
      } else if (value is Map) {
        result[key] = _makeSerializable(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map) {
            return _makeSerializable(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Get all active rides
  static List<Map<String, dynamic>> getActiveRides() {
    final rides = _box.read<List>(kActiveRides) ?? [];
    return rides.map((ride) => _convertToStringMap(ride)).toList();
  }

  /// Remove an active ride
  static Future<void> removeActiveRide(String rideId) async {
    final activeRides = getActiveRides();
    activeRides.removeWhere((ride) => ride['rideId'] == rideId);
    await _box.write(kActiveRides, activeRides);
    print('🗑️ Active ride removed: $rideId, remaining: ${activeRides.length}');
  }

  /// Check if user can add more active rides
  static bool canAddMoreRides() {
    return getActiveRides().length < kMaxActiveRides;
  }

  /// Get the current number of active rides
  static int getActiveRidesCount() {
    return getActiveRides().length;
  }

  /// Clear all active rides (for testing/logout)
  static Future<void> clearAllActiveRides() async {
    await _box.remove(kActiveRides);
    print('🧹 All active rides cleared');
  }


  // For Que Ride


  static final Rx<Map<String, dynamic>?> _profile = Rx<Map<String, dynamic>?>(null);
  static Rx<Map<String, dynamic>?> get observableProfile => _profile;

  static Future<void> init() async {
    await GetStorage.init();
  }

  /// ================= LANGUAGE & ROLE =================
  static void saveLanguage(String lang) => _box.write('language', lang);
  static String? getLanguage() => _box.read('language');

  static void saveRole(String role) => _box.write('role', role);
  static String? getRole() => _box.read('role');

  static void saveDriverType(String selectedDriverType) => _box.write('selectedDriverType', selectedDriverType);
  static String? getDriverType() => _box.read('selectedDriverType');

  static void saveVehicleType(String selectedVehicleType) => _box.write('selectedVehicleType', selectedVehicleType);
  static String? getVehicleType() => _box.read('selectedVehicleType');

  /// ================= RECENT PLACES =================
  static List<PlaceSuggestion> getRecent() {
    final list = _box.read<List>(_recentKey) ?? [];
    return list
        .map((e) => PlaceSuggestion.fromJson(_convertToStringMap(e)))
        .toList();
  }

  static void addRecent(PlaceSuggestion p) {
    final items = getRecent();
    items.removeWhere((e) => e.description == p.description);
    final newList = [p, ...items];
    final top3 = newList.take(4).toList();
    _box.write(_recentKey, top3.map((e) => e.toJson()).toList());
  }

  /// ================= PASSENGER PROFILE =================
  static Map<String, dynamic>? getProfile() {
    final m = _box.read<Map>(_profileKey);
    final profile = m == null ? null : _convertToStringMap(m);
    _profile.value = profile;
    return profile;
  }

  static void saveProfile(Map<String, dynamic> profile) {
    _box.write(_profileKey, profile);
    _profile.value = profile;
    print("profile data saved");
  }

  static void setProfileCompleted(bool value) {
    _box.write(_kProfileCompleted, value);
  }

  static bool getProfileCompleted() {
    return _box.read<bool>(_kProfileCompleted) ?? false;
  }

  /// ================= SIGN UP RESPONSE =================
  static Future<void> saveSignUpResponse(SignUpResponse data) async {
    await _box.write(_kSignUpResponse, data.toJson());
    await _box.write(_kUserId, data.userId);
  }

  static SignUpResponse? getSignUpResponse() {
    final raw = _box.read(_kSignUpResponse);
    if (raw == null) return null;
    return SignUpResponse.fromJson(_convertToStringMap(raw));
  }

  static String? getPassengerId() {
    return _box.read<String>(_kUserId);
  }

  /// ================= AUTH TOKEN =================
  static Future<void> saveAuthToken(String token) async {
    await _box.write(_kAuthToken, token);
  }

  static String? getAuthToken() {
    return _box.read<String>(_kAuthToken);
  }

  /// ================= LOGIN STATUS =================
  static Future<void> saveLoginStatus(bool value) async {
    await _box.write(_kIsLoggedIn, value);
  }

  static bool getLoginStatus() {
    return _box.read<bool>(_kIsLoggedIn) ?? false;
  }

  /// ================= RIDE TYPES CACHE =================
  static Future<void> saveRideTypesCache(List<Map<String, dynamic>> items) async {
    await _box.write(_kRideTypesCache, items);
  }

  static List<Map<String, dynamic>> getRideTypesCache() {
    final raw = _box.read<List>(_kRideTypesCache);
    if (raw == null) return [];
    return raw.map((e) => _convertToStringMap(e)).toList();
  }

  static Future<void> clearRideTypesCache() async {
    await _box.remove(_kRideTypesCache);
  }

  static Future<void> saveCitiesCache(List<Map<String, dynamic>> cities) async {
    await _box.write('cities_cache', cities);
  }

  static List<Map<String, dynamic>> getCitiesCache() {
    final raw = _box.read<List>('cities_cache');
    if (raw == null) return [];
    return raw.map((e) => _convertToStringMap(e)).toList();
  }

  /// ================= DRIVER PROFILE STEPS =================
  static void setDriverStep(String step, bool value) {
    _box.write('driver_step_$step', value);
  }

  static bool getDriverStep(String step) {
    return _box.read('driver_step_$step') ?? false;
  }

  /// Returns all driver steps as a Map
  static Map<String, bool> getDriverSteps() {
    return {
      "basic": getDriverStep("basic"),
      "cnic": getDriverStep("cnic"),
      "selfie": getDriverStep("selfie"),
      "licence": getDriverStep("licence"),
      "vehicle": getDriverStep("vehicle"),
      "registration": getDriverStep("registration"),
      "policy": getDriverStep("policy"),
    };
  }

  /// Check if all driver steps are completed
  static bool isDriverProfileCompleted() {
    final steps = getDriverSteps();
    return steps.values.every((v) => v == true);
  }

  /// Debugging helper
  static void printDriverSteps() {
    final steps = getDriverSteps();
    print("🚖 Driver Steps Status: $steps");
    print(" Driver Profile Completed: ${isDriverProfileCompleted()}");
  }

  /// ================= DRIVER ONLINE STATUS =================
  static Future<void> setDriverOnlineStatus(bool isOnline) async {
    await _box.write(_kDriverOnlineStatus, isOnline);
    print('💾 Driver online status saved: $isOnline');
  }

  static bool getDriverOnlineStatus() {
    return _box.read<bool>(_kDriverOnlineStatus) ?? false;
  }

  static Future<void> setAutoAcceptStatus(bool isAllow) async {
    await _box.write(_kAutoAcceptStatus, isAllow);
    print('💾 Auto accept status saved: $isAllow');
  }

  static bool getAutoAcceptStatus() {
    return _box.read<bool>(_kAutoAcceptStatus) ?? false;
  }

  static Future<void> clearDriverOnlineStatus() async {
    await _box.remove(_kDriverOnlineStatus);
    print('💾 Driver online status cleared');
  }

  /// ================= CHAT STORAGE =================
  static Future<void> saveChatMessages(String rideId, List<Map<String, dynamic>> messages) async {
    final key = '$_kChatMessages$rideId';
    await _box.write(key, messages);
    print('💾 Saved ${messages.length} chat messages for ride: $rideId');
  }

  static List<Map<String, dynamic>> getChatMessages(String rideId) {
    final key = '$_kChatMessages$rideId';
    final messages = _box.read<List>(key) ?? [];
    return messages.map((e) => _convertToStringMap(e)).toList();
  }

  static Future<void> clearChatMessages(String rideId) async {
    final key = '$_kChatMessages$rideId';
    await _box.remove(key);
    print('💾 Cleared chat messages for ride: $rideId');
  }

  static Future<void> addChatMessage(String rideId, Map<String, dynamic> message) async {
    final messages = getChatMessages(rideId);

    if (messages.any((msg) => msg['_id'] == message['_id'])) {
      print('💾 Message already exists in local storage, skipping: ${message['_id']}');
      return;
    }

    messages.add(message);
    await saveChatMessages(rideId, messages);
    print('💾 Added new message to local storage: ${message['_id']}');
  }

  /// ================= UTILITY METHODS =================
  /// ✅ NEW: Convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _convertToStringMap(dynamic map) {
    if (map is! Map) {
      return {};
    }

    final result = <String, dynamic>{};

    map.forEach((key, value) {
      final stringKey = key.toString();

      if (value is Map) {
        result[stringKey] = _convertToStringMap(value);
      } else if (value is List) {
        result[stringKey] = _convertList(value);
      } else {
        result[stringKey] = value;
      }
    });

    return result;
  }

  /// ✅ NEW: Convert List with potential Map<dynamic, dynamic> items
  static List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertToStringMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// ✅ NEW: Debug method to print storage contents
  static void printStorageContents() {
    print('\n📦 STORAGE CONTENTS');
    print('==================');
    final keys = _box.getKeys();
    for (final key in keys) {
      final value = _box.read(key);
      print('$key: $value');
    }
    print('==================\n');
  }

  /// ✅ NEW: Clear all storage (use with caution)
  static Future<void> clearAll() async {
    await _box.erase();
    _profile.value = null;
    print('🧹 All storage cleared');
  }

  /// ✅ NEW: Get storage statistics
  static Map<String, dynamic> getStorageStats() {
    final keys = _box.getKeys();
    final stats = <String, dynamic>{
      'totalKeys': keys.length,
      'keys': keys.toList(),
    };

    // Count by type
    final typeCount = <String, int>{};
    for (final key in keys) {
      final value = _box.read(key);
      final type = value.runtimeType.toString();
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    stats['typeCount'] = typeCount;

    return stats;
  }

  static Future<void> savePaymentMethod(PaymentMethodModel paymentMethod) async {
    await _box.write(_kPaymentMethod, paymentMethod.toJson());
    print('💾 Payment method saved: ${paymentMethod.activeMethod}');
  }

  static PaymentMethodModel? getPaymentMethod() {
    final data = _box.read<Map>(_kPaymentMethod);
    if (data == null) return null;
    return PaymentMethodModel.fromJson(_convertToStringMap(data));
  }

  static Future<void> clearPaymentMethod() async {
    await _box.remove(_kPaymentMethod);
    print('🧹 Payment method cleared');
  }

  // Add this to StorageService class
  static Future<void> logout() async {
    // Clear only authentication-related data
    await _box.remove(_kAuthToken);
    await _box.remove(_kIsLoggedIn);
    await _box.remove(_kUserId);
    await _box.remove(_kSignUpResponse);
    await _box.remove(_profileKey);
    await _box.remove(_kDriverOnlineStatus);
    await _box.remove(_kAutoAcceptStatus);
    await clearAllActiveRides();
    await clearAllQueueRides();
    await clearPaymentMethod();

    _profile.value = null;
    print('🧹 User data cleared for logout');
  }

  /// Save support chat messages
  static Future<void> saveSupportChatMessages(List<Message> messages) async {
    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await _box.write(_kSupportChatMessages, messagesJson);
    print('💾 Saved ${messages.length} support chat messages');
  }

  /// Get support chat messages
  static List<Message> getSupportChatMessages() {
    final messages = _box.read<List>(_kSupportChatMessages) ?? [];
    return messages.map((msg) => Message.fromJson(_convertToStringMap(msg))).toList();
  }

  /// Save support chat ID
  static Future<void> saveSupportChatId(String chatId) async {
    await _box.write(_kSupportChatId, chatId);
  }

  /// Get support chat ID
  static String? getSupportChatId() {
    return _box.read<String>(_kSupportChatId);
  }

  /// Save support chat status
  static Future<void> saveSupportChatStatus(String status) async {
    await _box.write(_kSupportChatStatus, status);
  }

  /// Get support chat status
  static String getSupportChatStatus() {
    return _box.read<String>(_kSupportChatStatus) ?? 'open';
  }

  /// Clear support chat data
  static Future<void> clearSupportChat() async {
    await _box.remove(_kSupportChatMessages);
    await _box.remove(_kSupportChatId);
    await _box.remove(_kSupportChatStatus);
    print('🧹 Support chat data cleared');
  }

  /// Check if support chat exists
  static bool hasSupportChat() {
    return getSupportChatMessages().isNotEmpty && getSupportChatStatus() == 'open';
  }

}

// // lib/shared/services/storage_service.dart
// import 'package:get/get_rx/src/rx_types/rx_types.dart';
// import 'package:get_storage/get_storage.dart';
// import '../../start/models/sign_up_response.dart';
// import '../models/place_suggestion.dart';
//
// class StorageService {
//   static final _box = GetStorage();
//
//   // Common Keys
//   static const _recentKey = 'recent_places';
//   static const _profileKey = 'profile_data';
//   static const _kSignUpResponse = 'signup_response';
//   static const _kUserId = 'userId';
//   static const _kAuthToken = 'auth_token';
//   static const _kIsLoggedIn = 'isLoggedIn';
//
//   // Ride types cache
//   static const _kRideTypesCache = 'ride_types_cache_v1';
//
//   // Passenger Profile Completion
//   static const _kProfileCompleted = 'profile_completed';
//
//   // Driver profile completion flag
//   static const _kDriverProfileCompleted = 'driver_profile_completed';
//
//   // ✅ ADDED: Driver Online Status
//   static const _kDriverOnlineStatus = 'driver_online_status';
//
//   static const _kAutoAcceptStatus = 'auto_accept_status';
//
//   // Chat storage keys
//   static const _kChatMessages = 'chat_messages_';
//
//   static final Rx<Map<String, dynamic>?> _profile = Rx<Map<String, dynamic>?>(null);
//   static Rx<Map<String, dynamic>?> get observableProfile => _profile;
//
//   static Future<void> init() async {
//     await GetStorage.init();
//   }
//
//   /// ================= LANGUAGE & ROLE =================
//   static void saveLanguage(String lang) => _box.write('language', lang);
//   static String? getLanguage() => _box.read('language');
//
//   static void saveRole(String role) =>
//       _box.write('role', role); // 🔥 always save lowercase
//   static String? getRole() => _box.read('role');
//
//   static void saveDriverType(String selectedDriverType) =>
//       _box.write('selectedDriverType', selectedDriverType); // 🔥 always save lowercase
//   static String? getDriverType() => _box.read('selectedDriverType');
//
//   static void saveVehicleType(String selectedVehicleType) =>
//       _box.write('selectedVehicleType', selectedVehicleType); // 🔥 always save lowercase
//   static String? getVehicleType() => _box.read('selectedVehicleType');
//
//   /// ================= RECENT PLACES =================
//   static List<PlaceSuggestion> getRecent() {
//     final list = _box.read<List>(_recentKey) ?? [];
//     return list
//         .map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
//
//   static void addRecent(PlaceSuggestion p) {
//     final items = getRecent();
//     items.removeWhere((e) => e.description == p.description);
//     final newList = [p, ...items];
//     final top3 = newList.take(4).toList();
//     _box.write(_recentKey, top3.map((e) => e.toJson()).toList());
//   }
//
//   /// ================= PASSENGER PROFILE =================
//   // static Map<String, dynamic>? getProfile() {
//   //   final m = _box.read<Map>(_profileKey);
//   //   return m == null ? null : Map<String, dynamic>.from(m);
//   // }
//   //
//   // static void saveProfile(Map<String, dynamic> profile) {
//   //   _box.write(_profileKey, profile);
//   //   print("profile sata saved");
//   // }
//
//   static Map<String, dynamic>? getProfile() {
//     final m = _box.read<Map>(_profileKey);
//     final profile = m == null ? null : Map<String, dynamic>.from(m);
//     _profile.value = profile; // Update the observable
//     return profile;
//   }
//
//   static void saveProfile(Map<String, dynamic> profile) {
//     _box.write(_profileKey, profile);
//     _profile.value = profile; // Update the observable
//     print("profile data saved");
//   }
//
//   static void setProfileCompleted(bool value) {
//     _box.write(_kProfileCompleted, value);
//   }
//
//   static bool getProfileCompleted() {
//     return _box.read<bool>(_kProfileCompleted) ?? false;
//   }
//
//   /// ================= SIGN UP RESPONSE =================
//   static Future<void> saveSignUpResponse(SignUpResponse data) async {
//     await _box.write(_kSignUpResponse, data.toJson());
//     await _box.write(_kUserId, data.userId);
//   }
//
//   static SignUpResponse? getSignUpResponse() {
//     final raw = _box.read(_kSignUpResponse);
//     if (raw == null) return null;
//     return SignUpResponse.fromJson(Map<String, dynamic>.from(raw));
//   }
//
//   static String? getPassengerId() {
//     return _box.read<String>(_kUserId);
//   }
//
//   /// ================= AUTH TOKEN =================
//   static Future<void> saveAuthToken(String token) async {
//     await _box.write(_kAuthToken, token);
//   }
//
//   static String? getAuthToken() {
//     return _box.read<String>(_kAuthToken);
//   }
//
//   /// ================= LOGIN STATUS =================
//   static Future<void> saveLoginStatus(bool value) async {
//     await _box.write(_kIsLoggedIn, value);
//   }
//
//   static bool getLoginStatus() {
//     return _box.read<bool>(_kIsLoggedIn) ?? false;
//   }
//
//   /// ================= RIDE TYPES CACHE =================
//   static Future<void> saveRideTypesCache(
//       List<Map<String, dynamic>> items) async {
//     await _box.write(_kRideTypesCache, items);
//   }
//
//   static List<Map<String, dynamic>> getRideTypesCache() {
//     final raw = _box.read<List>(_kRideTypesCache);
//     if (raw == null) return [];
//     return raw.map((e) => Map<String, dynamic>.from(e)).toList();
//   }
//
//   static Future<void> clearRideTypesCache() async {
//     await _box.remove(_kRideTypesCache);
//   }
//
//   static Future<void> saveCitiesCache(List<Map<String, dynamic>> cities) async {
//     await _box.write('cities_cache', cities);
//   }
//
//   static List<Map<String, dynamic>> getCitiesCache() {
//     return (_box.read('cities_cache') as List?)?.cast<Map<String, dynamic>>() ?? [];
//   }
//
//   /// ================= DRIVER PROFILE STEPS =================
//   static void setDriverStep(String step, bool value) {
//     _box.write('driver_step_$step', value);
//   }
//
//   static bool getDriverStep(String step) {
//     return _box.read('driver_step_$step') ?? false;
//   }
//
//   /// Returns all driver steps as a Map
//   static Map<String, bool> getDriverSteps() {
//     return {
//       "basic": getDriverStep("basic"),
//       "cnic": getDriverStep("cnic"),
//       "selfie": getDriverStep("selfie"),
//       "licence": getDriverStep("licence"),
//       "vehicle": getDriverStep("vehicle"),
//       // "referral": getDriverStep("referral"),
//       "registration": getDriverStep("registration"),
//       "policy": getDriverStep("policy"),
//     };
//   }
//
//   /// Check if all driver steps are completed
//   static bool isDriverProfileCompleted() {
//     final steps = getDriverSteps();
//     return steps.values.every((v) => v == true);
//   }
//
//   /// Debugging helper
//   static void printDriverSteps() {
//     final steps = getDriverSteps();
//     print("🚖 Driver Steps Status: $steps");
//     print(" Driver Profile Completed: ${isDriverProfileCompleted()}");
//   }
//
//
//   /// ================= DRIVER ONLINE STATUS =================
//   /// ✅ ADDED: Save driver's online/offline status
//   static Future<void> setDriverOnlineStatus(bool isOnline) async {
//     await _box.write(_kDriverOnlineStatus, isOnline);
//     print('💾 Driver online status saved: $isOnline');
//   }
//
//   /// ✅ ADDED: Get driver's online/offline status
//   static bool getDriverOnlineStatus() {
//     return _box.read<bool>(_kDriverOnlineStatus) ?? false;
//   }
//
//   static Future<void> setAutoAcceptStatus(bool isAllow) async {
//     await _box.write(_kAutoAcceptStatus, isAllow);
//     print('💾 Driver online status saved: $isAllow');
//   }
//
//   /// ✅ ADDED: Get driver's online/offline status
//   static bool getAutoAcceptStatus() {
//     return _box.read<bool>(_kAutoAcceptStatus) ?? false;
//   }
//
//
//   /// ✅ ADDED: Clear driver online status (useful on logout)
//   static Future<void> clearDriverOnlineStatus() async {
//     await _box.remove(_kDriverOnlineStatus);
//     print('💾 Driver online status cleared');
//   }
//
//   /// ================= CHAT STORAGE =================
//   /// Save chat messages for a specific ride
//   static Future<void> saveChatMessages(String rideId, List<Map<String, dynamic>> messages) async {
//     final key = '$_kChatMessages$rideId';
//     await _box.write(key, messages);
//     print('💾 Saved ${messages.length} chat messages for ride: $rideId');
//   }
//
//   /// Get chat messages for a specific ride
//   static List<Map<String, dynamic>> getChatMessages(String rideId) {
//     final key = '$_kChatMessages$rideId';
//     final messages = _box.read<List>(key) ?? [];
//     return messages.map((e) => Map<String, dynamic>.from(e)).toList();
//   }
//
//   /// Clear chat messages for a specific ride (when ride ends)
//   static Future<void> clearChatMessages(String rideId) async {
//     final key = '$_kChatMessages$rideId';
//     await _box.remove(key);
//     print('💾 Cleared chat messages for ride: $rideId');
//   }
//
//   /// Add a single message to chat storage
//   static Future<void> addChatMessage(String rideId, Map<String, dynamic> message) async {
//     final messages = getChatMessages(rideId);
//
//     // Check for duplicates using _id
//     if (messages.any((msg) => msg['_id'] == message['_id'])) {
//       print('💾 Message already exists in local storage, skipping: ${message['_id']}');
//       return;
//     }
//
//     messages.add(message);
//     await saveChatMessages(rideId, messages);
//     print('💾 Added new message to local storage: ${message['_id']}');
//   }
// }