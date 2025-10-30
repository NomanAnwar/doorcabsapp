import 'dart:convert';
import 'dart:typed_data';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../driver/screens/reuseable_widgets/drawer.dart';
import '../controllers/ride_type_controller.dart';
import '../models/ride_type_screen_model.dart';

class RideTypeScreen extends StatelessWidget {
  final RideTypeController controller = Get.put(RideTypeController());

  RideTypeScreen({super.key});

  // Helper that tries Get.snackbar and falls back to ScaffoldMessenger
  void _showFeatureSnack(String label, BuildContext context) {
    final msg = "$label feature is coming soon!";
    debugPrint("DEBUG: tapped -> $label");

    try {
      Get.snackbar(
        label,
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      debugPrint("DEBUG: Get.snackbar called");
    } catch (e, st) {
      debugPrint("ERROR: Get.snackbar threw: $e\n$st");
    }

    try {
      Future.delayed(const Duration(milliseconds: 20), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        debugPrint("DEBUG: ScaffoldMessenger.showSnackBar called (fallback)");
      });
    } catch (e) {
      debugPrint("ERROR: ScaffoldMessenger failed: $e");
    }
  }

  // Decide route for a category (keeps your old routing intent - adjust if needed)
  String _routeFromCategory(String category) {
    final lower = category.toLowerCase();
    switch (lower) {
      case 'courier':
      case 'freight':
      case 'city to city':
      case 'instant ride':
      case 'delivery':
      case 'schedule ride':
        return "/dropoff"; // same as your earlier mapping
      default:
        return "/dropoff";
    }
  }

  // Fallback asset image per category (used when API icon missing/invalid)
  String _defaultImageForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('courier')) return "assets/images/courier.png";
    if (name.contains('freight')) return "assets/images/frieght.png";
    if (name.contains('city to city')) return "assets/images/city.png";
    if (name.contains('instant ride')) return "assets/images/instant.png";
    if (name.contains('delivery')) return "assets/images/delievrybike.png";
    if (name.contains('schedule ride')) return "assets/images/scity.png";
    return "assets/images/courier.png";
  }

  // Detect roughly if a string is base64 data URI or pure base64
  bool _looksLikeBase64(String s) {
    if (s.isEmpty) return false;
    if (s.startsWith('data:image')) return true;
    // A very loose sanity check for base64 characters
    final sanitized = s.replaceAll(RegExp(r'\s+'), '');
    // base64 chars only (plus padding '=')
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sanitized);
  }

  // Safely decode base64 image data (returns null on failure)
  Uint8List? _decodeBase64Image(String raw) {
    try {
      var encoded = raw;
      if (encoded.contains(',')) {
        // data:image/png;base64,.... -> take part after comma
        encoded = encoded.split(',').last;
      }
      // strip whitespace/newlines
      encoded = encoded.replaceAll(RegExp(r'\s+'), '');
      // strip any characters not in base64 alphabet (defensive)
      encoded = encoded.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      if (encoded.isEmpty) return null;
      final bytes = base64.decode(encoded);
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (e) {
      // decoding failed - return null so UI falls back to asset
      if (kDebugMode) {
        print('[RideTypeScreen] base64 decode failed: $e');
      }
      return null;
    }
  }

  void _navigateToService(RideTypeScreenModel service, BuildContext context) {
    // Quick check without complex computations
    if (controller.isLoading.value || controller.isLoadingLocation.value) {
      _showFeatureSnack("Please wait...", context);
      return;
    }

    if (service.vehicleList.isEmpty) {
      _showFeatureSnack(service.categoryName, context);
      return;
    }

    // Prepare arguments efficiently
    final userLocation = controller.userLocation.value;
    final arguments = {
      'service': service,
      'vehicles': service.vehicleList,
      'cities': controller.cities,
      if (userLocation != null) ...{
        'userLocation': userLocation.toJson(),
        'userCurrentLocation': userLocation.toLatLng(),
        'userCurrentAddress': userLocation.address,
        'pickup': userLocation.address,
        'pickupLatLng': userLocation.toLatLng(),
      }
    };

    // Use a small delay to ensure the ripple effect is visible
    Future.delayed(Duration(milliseconds: 20), () {
      Get.toNamed(
        _routeFromCategory(service.categoryName),
        arguments: arguments,
        // Add these for smoother transition
        // duration: Duration(milliseconds: 300),
        // transition: Transition.cupertino,
      );
    });
  }

  // Helper widget to handle both base64 and network images (falls back to asset)
  Widget _buildServiceImage(
      RideTypeScreenModel service,
      double width,
      double height,
      ) {
    final icon = service.categoryIcon ?? '';
    if (icon.isNotEmpty) {
      if (_looksLikeBase64(icon)) {
        final bytes = _decodeBase64Image(icon);
        if (bytes != null) {
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) debugPrint("Base64 image error: $error");
              return Image.asset(
                _defaultImageForCategory(service.categoryName),
                width: width,
                height: height,
                fit: BoxFit.contain,
              );
            },
          );
        } else {
          // decode failed -> fallback to asset
          return Image.asset(
            _defaultImageForCategory(service.categoryName),
            width: width,
            height: height,
            fit: BoxFit.contain,
          );
        }
      } else {
        // treat as network URL
        return Image.network(
          icon,
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) debugPrint("Network image error: $error");
            return Image.asset(
              _defaultImageForCategory(service.categoryName),
              width: width,
              height: height,
              fit: BoxFit.contain,
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      }
    }

    // No icon from API -> show default asset
    return Image.asset(
      _defaultImageForCategory(service.categoryName),
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  // Find service by partial match on categoryName; returns null if not found (no dummy fallback)
  RideTypeScreenModel? _findService(
      RxList<RideTypeScreenModel> services,
      String key,
      ) {
    try {
      return services.firstWhere(
            (s) => s.categoryName.toLowerCase().contains(key),
      );
    } catch (_) {
      return null;
    }
  }

  // Tappable container with ripple effect (same as IconButton)
  Widget _buildTappableContainer({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: FColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: child,
      ),
    );
  }

// Build the positioned widgets; skip a widget if API didn't return that category
  List<Widget> _buildServiceWidgets(
      RxList<RideTypeScreenModel> services,
      double Function(num) sw,
      double Function(num) sh,
      double screenWidth,
      double baseWidth,
      BuildContext context,
      ) {
    final widgets = <Widget>[];

    final courier = _findService(services, 'courier');
    final freight = _findService(services, 'freight');
    final cityToCity = _findService(services, 'city to city');
    final instantRide = _findService(services, 'instant ride');
    final delivery = _findService(services, 'delivery');
    final scheduleRide = _findService(services, 'schedule ride');

    // Enhanced tappable container with better hit detection
    Widget _buildTappableContainer({
      required Widget child,
      required VoidCallback onTap,
      required double top,
      required double left,
      required double width,
      required double height,
      BorderRadius? borderRadius,
    }) {
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              splashColor: FColors.secondaryColor.withOpacity(0.2),
              highlightColor: FColors.secondaryColor.withOpacity(0.1),
              child: child,
            ),
          ),
        ),
      );
    }

    // Courier Box Image + label
    if (courier != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(332),
          left: sw(33),
          width: sw(184),
          height: sh(95),
          onTap: () => _navigateToService(courier, context),
          borderRadius: BorderRadius.circular(12),
          child: _buildServiceImage(courier, sw(184), sh(95)),
        ),
        _buildTappableContainer(
          top: sh(425),
          left: sw(47),
          width: sw(120),
          height: sh(30),
          onTap: () => _navigateToService(courier, context),
          child: Padding(
            padding: EdgeInsets.all(sw(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  courier.categoryName,
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset("assets/images/rightarrow.png", height: sh(14)),
              ],
            ),
          ),
        ),
      ]);
    }

    // Freight Box Image + label
    if (freight != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(329),
          left: sw(249),
          width: sw(184),
          height: sh(95),
          onTap: () => _navigateToService(freight, context),
          borderRadius: BorderRadius.circular(12),
          child: _buildServiceImage(freight, sw(184), sh(95)),
        ),
        _buildTappableContainer(
          top: sh(425),
          left: sw(278),
          width: sw(120),
          height: sh(35),
          onTap: () => _navigateToService(freight, context),
          child: Padding(
            padding: EdgeInsets.all(sw(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  freight.categoryName,
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset("assets/images/rightarrow.png", height: sh(14)),
              ],
            ),
          ),
        ),
      ]);
    }

    // City to City image + label
    if (cityToCity != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(448),
          left: sw(18),
          width: sw(220),
          height: sh(160),
          onTap: () => _navigateToService(cityToCity, context),
          borderRadius: BorderRadius.circular(12),
          child: _buildServiceImage(cityToCity, sw(220), sh(160)),
        ),
        _buildTappableContainer(
          top: sh(595),
          left: sw(47),
          width: sw(120),
          height: sh(35),
          onTap: () => _navigateToService(cityToCity, context),
          child: Padding(
            padding: EdgeInsets.all(sw(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cityToCity.categoryName,
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset("assets/images/rightarrow.png", height: sh(14)),
              ],
            ),
          ),
        ),
      ]);
    }

    // Instant Ride image + label
    if (instantRide != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(448),
          left: sw(244),
          width: sw(220),
          height: sh(160),
          onTap: () => _navigateToService(instantRide, context),
          borderRadius: BorderRadius.circular(12),
          child: _buildServiceImage(instantRide, sw(220), sh(160)),
        ),
        _buildTappableContainer(
          top: sh(595),
          left: sw(278),
          width: sw(120),
          height: sh(35),
          onTap: () => _navigateToService(instantRide, context),
          child: Padding(
            padding: EdgeInsets.all(sw(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instantRide.categoryName,
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset("assets/images/rightarrow.png", height: sh(14)),
              ],
            ),
          ),
        ),
      ]);
    }

    // Delivery image + label
    if (delivery != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(634),
          left: sw(33),
          width: sw(82),
          height: sh(85),
          onTap: () => _navigateToService(delivery, context),
          borderRadius: BorderRadius.circular(10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: _buildServiceImage(delivery, sw(82), sh(85)),
          ),
        ),
        _buildTappableContainer(
          top: sh(715),
          left: sw(47),
          width: sw(120),
          height: sh(35),
          onTap: () => _navigateToService(delivery, context),
          child: Padding(
            padding: EdgeInsets.all(sw(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  delivery.categoryName,
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset("assets/images/rightarrow.png", height: sh(14)),
              ],
            ),
          ),
        ),
      ]);
    }

    // Schedule box + image
    if (scheduleRide != null) {
      widgets.addAll([
        _buildTappableContainer(
          top: sh(632),
          left: sw(158),
          width: sw(265),
          height: sh(95),
          onTap: () => _navigateToService(scheduleRide, context),
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: FColors.primaryColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: sw(6  ), vertical: sw(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Schedule Your Ride?",
                  textAlign: TextAlign.center,
                  style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
                    fontSize:
                    (FTextTheme.lightTextTheme.headlineSmall!.fontSize! - 1) *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "(up to 20% off)",
                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                    fontSize:
                    FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          scheduleRide.categoryName,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                screenWidth /
                                baseWidth,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        "assets/images/rightarrow.png",
                        height: sh(14),
                      ),
                    ],
                  ),

                ),
              ],
            ),
          ),
        ),
        _buildTappableContainer(
          top: sh(653),
          left: sw(148),
          width: sw(125),
          height: sh(113),
          onTap: () => _navigateToService(scheduleRide, context),
          borderRadius: BorderRadius.circular(12),
          child: _buildServiceImage(scheduleRide, sw(125), sh(113)),
        ),
      ]);
    }

    return widgets;
  }

  Widget _buildLoadingUI(RideTypeController controller) {
    String loadingText = 'Loading services...';
    if (controller.isLoadingLocation.value) {
      loadingText = 'Getting your location...';
    } else if (controller.isLoadingCities.value) {
      loadingText = 'Loading cities...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003566)),
          ),
          SizedBox(height: 20),
          Text(
            loadingText,
            style: TextStyle(
              color: Color(0xFF003566),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (controller.locationError.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              'Location: ${controller.locationError.value}',
              style: TextStyle(color: Colors.orange, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorUI(RideTypeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Error: ${controller.error.value}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.loadAllData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF003566),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(num w) => w * screenWidth / baseWidth;
    double sh(num h) => h * screenHeight / baseHeight;

    return Scaffold(
      drawer: const PassengerDrawer(),
      backgroundColor: const Color(0xFFFFC300),
      body: Obx(() {
        // ✅ SHOW LOADING until both APIs complete
        if (controller.isLoading.value ||
            !controller.areAllDataLoaded.value ||
            controller.isLoadingLocation.value) {
          return _buildLoadingUI(controller);
        }

        // If API returned error (controller sets error), show retry UI
        if (controller.error.isNotEmpty) {
          return _buildErrorUI(controller);
        }

        // ✅ Only show UI when both APIs are successfully loaded
        return Stack(
          children: [
            // Header image
            Positioned(
              top: sh(50),
              left: 0,
              right: 0,
              child: SizedBox(
                width: screenWidth,
                height: sh(177),
                child: Image.asset(
                  "assets/images/started_bg.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Menu button
            Positioned(
              top: 33,
              right: 10,
              child: Container(
                width: 39,
                height: 39,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Image.asset(
                        "assets/images/Menu.png",
                        width: 24,
                        height: 24,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              ),
            ),

            // Main White Container
            Positioned(
              top: sh(178),
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: screenWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(31),
                    topRight: Radius.circular(31),
                  ),
                ),
              ),
            ),

            // Logo
            Positioned(
              top: sh(198),
              left: sw(149),
              child: SizedBox(
                width: sw(134),
                height: sh(84),
                child: Image.asset(
                  "assets/images/Door Cabs.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Tagline
            Positioned(
              top: sh(287),
              left: sw(62),
              child: SizedBox(
                width: sw(303),
                height: sh(30),
                child: Text(
                  "Pakistan's 1st Actual Ride Hailing App",
                  style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Dynamic service widgets based on API data
            ..._buildServiceWidgets(
              controller.services,
              sw,
              sh,
              screenWidth,
              baseWidth,
              context,
            ),

            // Ad banner
            Positioned(
              top: sh(776),
              left: sw(22),
              child: Container(
                width: sw(400),
                height: sh(141),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.asset("assets/images/ad.png", fit: BoxFit.cover),
                ),
              ),
            ),

            // ✅ Optional: Show loading indicator for cities if still loading
            if (controller.isLoadingCities.value)
              Positioned(
                top: sh(400),
                left: 0,
                right: 0,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF003566),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}