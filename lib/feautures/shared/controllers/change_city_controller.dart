import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../utils/http/http_client.dart';
import '../services/storage_service.dart';

class ChangeCityController extends GetxController {
  var currentCity = "Islamabad".obs;
  var selectedCity = "".obs;
  var availableCities = <String>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentCity();
    fetchCities();
  }

  void _loadCurrentCity() {
    // try {
    //   final data = StorageService.getProfile();
    //   if (data != null && data.isNotEmpty && data['address']['city'] != null) {
    //     String city = data['address']['city'].toString();
    //     print("Loaded city from storage: $city");
    //     currentCity.value = city;
    //   }
    // } catch (e) {
    //   print("Error loading city: $e");
    // }

    try {
      final data = StorageService.getProfile();

      if (data != null && data.isNotEmpty) {
        final city = data['address']['city']?.toString();
        if (city != null && city.isNotEmpty) {
          print("the city : " + city);
          currentCity.value = city;
        } else {
          currentCity.value = "N/A"; // Default if empty
        }
      } else {
        currentCity.value = "N/A"; // Default if no profile
      }
    } catch (e) {
      print("Error loading city from storage: $e");
      currentCity.value = "N/A"; // Default on error
    }

  }

  Future<void> fetchCities() async {
    try {
      isLoading.value = true;

      // Get current location for country
      Position position = await _getCurrentLocation();
      String country = await _getCountryFromLocation(position);

      print("Fetching cities for country: $country");

      // Fetch cities from API with country parameter
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('city/active/$country');

      if (response['success'] == true) {
        final List<dynamic> citiesData = response['data'] ?? [];

        availableCities.value = citiesData.map((item) {
          return item['city_name']?.toString() ?? 'Unknown City';
        }).toList();

        // Sort cities alphabetically
        availableCities.sort((a, b) => a.compareTo(b));

        print("Loaded ${availableCities.length} cities from API");
      } else {
        FSnackbar.show(title: "Error", message: "Failed to load cities", isError: true);
        // Fallback to static cities if API fails
        availableCities.value = _getDefaultCities();
      }
    } catch (e) {
      FSnackbar.show(title: "Error", message: "Failed to load cities: ${e.toString()}", isError: true);
      // Fallback to static cities
      availableCities.value = _getDefaultCities();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> _getDefaultCities() {
    return [
      "Islamabad",
      "Lahore",
      "Karachi",
      "Rawalpindi",
      "Faisalabad",
      "Multan",
      "Peshawar",
      "Quetta",
      "Sialkot",
      "Hyderabad",
      "Bahawalpur",
      "Gujranwala",
      "Sukkur",
      "Mirpur",
      "Abbottabad",
    ];
  }

  Future<Position> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print("Location error: $e");
      throw Exception('Unable to get location: ${e.toString()}');
    }
  }

  Future<String> _getCountryFromLocation(Position position) async {
    try {
      // Use reverse geocoding to get country from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String country = placemark.country ?? 'Pakistan'; // Default to Pakistan if null
        print("Detected country: $country");
        return country;
      } else {
        print("No placemarks found, defaulting to Pakistan");
        return "Pakistan";
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
      return "Pakistan"; // Default fallback
    }
  }

  Future<void> saveCity() async {
    final newCity = selectedCity.value;

    if (newCity.isEmpty) {
      FSnackbar.show(title: "Error", message: "Please select a city.", isError: true);
      return;
    }

    try {
      isSaving.value = true;

      // Call update city API
      final response = await FHttpHelper.post(
          'service/update-profile',
          {"city": newCity}
      );

      if (response['message'] == "Profile updated successfully.") {
        currentCity.value = newCity;
        await _saveProfile();
        FSnackbar.show(title: "Success", message: "City changed to $newCity.", isError: false);

        // Update in storage if needed
        // await StorageService.updateProfile({'city': newCity});

        Get.back();
      } else {
        FSnackbar.show(title: "Error", message: "Failed to update city.", isError: true);
      }
    } catch (e) {
      FSnackbar.show(title: "Error", message: "Failed to update city: ${e.toString()}", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveProfile() async {


    final role = StorageService.getRole();

    if(role == "Driver" || role == "driver") {
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final profileResponse = await FHttpHelper.get(
        "driver/${StorageService
            .getSignUpResponse()
            ?.userId
            .toString()}",
      );

      final driverProfile = profileResponse["driver"];
      StorageService.saveProfile(driverProfile);

      print("After language change profile saved.");
    }

    if(role == "Passenger" || role == "passenger") {
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response1 = await FHttpHelper.get("passenger/get-profile-info");
      StorageService.saveProfile(response1["passenger"]);

      print("After language change profile saved.");

    }


  }
}