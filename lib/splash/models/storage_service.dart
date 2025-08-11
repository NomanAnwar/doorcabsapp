import 'package:get_storage/get_storage.dart';

class StorageService {
  static final _box = GetStorage();

  static Future<void> init() async {
    await GetStorage.init();
  }

  static void saveLanguage(String lang) => _box.write('language', lang);
  static String? getLanguage() => _box.read('language');

  static void saveRole(String role) => _box.write('role', role);
  static String? getRole() => _box.read('role');
}
