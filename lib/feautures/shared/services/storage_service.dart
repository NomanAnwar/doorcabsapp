import 'package:get_storage/get_storage.dart';
import '../models/place_suggestion.dart';

class StorageService {
  static final _box = GetStorage();
  static const _recentKey = 'recent_places';
  static const _profileKey = 'profile_data';


  static Future<void> init() async {
    await GetStorage.init();
  }

  static void saveLanguage(String lang) => _box.write('language', lang);
  static String? getLanguage() => _box.read('language');

  static void saveRole(String role) => _box.write('role', role);
  static String? getRole() => _box.read('role');

  /// Recent places: keep last 3
  static List<PlaceSuggestion> getRecent() {
    final list = _box.read<List>(_recentKey) ?? [];
    return list.map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static void addRecent(PlaceSuggestion p) {
    final items = getRecent();
    // Remove if exists
    items.removeWhere((e) => e.description == p.description);
    // Insert at start
    final newList = [p, ...items];
    // Keep top 3
    final top3 = newList.take(3).toList();
    _box.write(_recentKey, top3.map((e) => e.toJson()).toList());
  }

  /// Profile
  static Map<String, dynamic>? getProfile() {
    final m = _box.read<Map>(_profileKey);
    return m == null ? null : Map<String, dynamic>.from(m);
  }

  static void saveProfile(Map<String, dynamic> profile) {
    _box.write(_profileKey, profile);
  }
}
