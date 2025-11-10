import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride_detail_model.dart';
import '../models/ride_model.dart';

class RideDetailController extends GetxController {
  final Rx<RideDetailModel?> rideDetails = Rx<RideDetailModel?>(null);
  var polylines = <Polyline>{}.obs;
  var markers = <Marker>{}.obs;

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropIcon;

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    pickupIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5, size: Size(64, 64)),
      "assets/images/pickup.png",
    );
    dropIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5, size: Size(64, 64)),
      "assets/images/drop.png",
    );
    update();
  }


  void getRideDetails(RideModel ride) {
    final detail = RideDetailModel(
      date: ride.date,
      time: ride.time,
      rideType: ride.rideType,
      location: "Faisal Town",
      dropLocation: "Township, Lahore",
      ridePrice: 320,
      promoAmount: 70,
      totalFare: 250,
      paymentMethod: "Cash",
      driverName: "Malik Shahid",
      driverRating: "4.95",
      driverProfilePic: "assets/images/profile_img_sample.png",
      carModel: "Suzuki Alto",
      licensePlate: "FS9247",
      arrivalTime: "11:05 PM",
      dropTime: "11:25 PM",
      totalrides: "125",
      pickupLat: 31.4765,
      pickupLng: 74.3070,
      dropLat: 31.4469,
      dropLng: 74.3161,
    );

    rideDetails.value = detail;

    updateRoute(
      LatLng(detail.pickupLat, detail.pickupLng),
      LatLng(detail.dropLat, detail.dropLng),
    );

    _updateMarkers();
  }

  void _updateMarkers() {
    if (rideDetails.value == null) return;

    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: LatLng(
          rideDetails.value!.pickupLat,
          rideDetails.value!.pickupLng,
        ),
        icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );
    markers.add(
      Marker(
          markerId: const MarkerId("drop"),
          position: LatLng(
            rideDetails.value!.dropLat,
            rideDetails.value!.dropLng,
          ),
          icon: dropIcon ?? BitmapDescriptor.defaultMarker
      ),
    );

    markers.refresh();
  }

  void updateRoute(LatLng pickup, LatLng drop) {
    polylines.clear();
    polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: [pickup, drop],
        color: Colors.deepPurpleAccent,
        width: 5,
      ),
    );
  }
}
