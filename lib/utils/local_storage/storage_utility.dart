import 'package:get_storage/get_storage.dart';

class FLocalStorage {
  static late GetStorage _storage;

  static Future<void> init() async {
    await GetStorage.init();
    _storage = GetStorage();
  }

  static void writeData(String key, dynamic value) {
    _storage.write(key, value);
  }

  static dynamic readData(String key) {
    return _storage.read(key);
  }

  static bool hasData(String key) {
    return _storage.hasData(key);
  }

  static void removeData(String key) {
    _storage.remove(key);
  }
}
