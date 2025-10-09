import 'package:get_storage/get_storage.dart';
import '../../start/models/sign_up_response.dart';
import '../models/place_suggestion.dart';

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

  static Future<void> init() async {
    await GetStorage.init();
  }

  /// ================= LANGUAGE & ROLE =================
  static void saveLanguage(String lang) => _box.write('language', lang);
  static String? getLanguage() => _box.read('language');

  static void saveRole(String role) =>
      _box.write('role', role); // 🔥 always save lowercase
  static String? getRole() => _box.read('role');

  /// ================= RECENT PLACES =================
  static List<PlaceSuggestion> getRecent() {
    final list = _box.read<List>(_recentKey) ?? [];
    return list
        .map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e)))
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
    return m == null ? null : Map<String, dynamic>.from(m);
  }

  static void saveProfile(Map<String, dynamic> profile) {
    _box.write(_profileKey, profile);
    print("profile sata saved");
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
    return SignUpResponse.fromJson(Map<String, dynamic>.from(raw));
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
  static Future<void> saveRideTypesCache(
      List<Map<String, dynamic>> items) async {
    await _box.write(_kRideTypesCache, items);
  }

  static List<Map<String, dynamic>> getRideTypesCache() {
    final raw = _box.read<List>(_kRideTypesCache);
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearRideTypesCache() async {
    await _box.remove(_kRideTypesCache);
  }

  static Future<void> saveCitiesCache(List<Map<String, dynamic>> cities) async {
    await _box.write('cities_cache', cities);
  }

  static List<Map<String, dynamic>> getCitiesCache() {
    return (_box.read('cities_cache') as List?)?.cast<Map<String, dynamic>>() ?? [];
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
      // "referral": getDriverStep("referral"),
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
  /// ✅ ADDED: Save driver's online/offline status
  static Future<void> setDriverOnlineStatus(bool isOnline) async {
    await _box.write(_kDriverOnlineStatus, isOnline);
    print('💾 Driver online status saved: $isOnline');
  }

  /// ✅ ADDED: Get driver's online/offline status
  static bool getDriverOnlineStatus() {
    return _box.read<bool>(_kDriverOnlineStatus) ?? false;
  }

  /// ✅ ADDED: Clear driver online status (useful on logout)
  static Future<void> clearDriverOnlineStatus() async {
    await _box.remove(_kDriverOnlineStatus);
    print('💾 Driver online status cleared');
  }
}