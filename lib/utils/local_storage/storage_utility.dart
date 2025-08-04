import 'package:get_storage/get_storage.dart';

class FLocalStorage {

  static final FLocalStorage _instanse = FLocalStorage._internal();

  factory FLocalStorage(){
    return _instanse;
  }

  FLocalStorage._internal();

  final _storage = GetStorage();

  Future<void> saveData<F>(String key, F value) async{
    await _storage.write(key, value);
  }

  F? readData<F>(String key) {
    return _storage.read<F>(key);
  }

  Future<void> removeData(String key) async{
    await _storage.remove(key);
  }

  Future<void> clearAll() async {
    await _storage.erase();
  }
}