// import 'package:get/get.dart';
//
// import '../../../utils/local_storage/storage_utility.dart';
//
//
// class AppController extends GetxController {
//   final storage = FLocalStorage();
//
//   String? language;
//   String? role;
//   bool isLoggedIn = false;
//
//   @override
//   void onInit() {
//     super.onInit();
//     language = storage.readData<String>('language');
//     role = storage.readData<String>('role');
//     isLoggedIn = storage.readData<bool>('isLoggedIn') ?? false;
//   }
//
//   bool get isFirstTime => language == null || role == null;
//
//   void saveLanguage(String lang) {
//     language = lang;
//     storage.saveData('language', lang);
//   }
//
//   void saveRole(String userRole) {
//     role = userRole;
//     storage.saveData('role', userRole);
//   }
//
//   void setLoggedIn(bool value) {
//     isLoggedIn = value;
//     storage.saveData('isLoggedIn', value);
//   }
// }
