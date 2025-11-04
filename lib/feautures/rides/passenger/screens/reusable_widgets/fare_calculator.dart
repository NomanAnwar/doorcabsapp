
import '../../models/city_model.dart';
import '../../models/vehicle_model.dart';

// class FareCalculator {
//   double calculateFare({
//     required double distanceKm,
//     required int durationMinutes,
//     required CityModel city,
//     required VehicleModel vehicle,
//   }) {
//     try {
//       double distance = distanceKm;
//
//       // 🔹 Enforce per_km_req (minimum billable distance)
//       if (city.perKmReq > 0 && distance < city.perKmReq) {
//         distance = city.perKmReq.toDouble();
//       }
//
//       double fare = city.perKmCharge * distance;
//
//       // 🔹 Apply waiting charges (per minute after free limit)
//       if (city.isWaitingChargesApplied == 1 && city.waitingCharges > 0) {
//         int chargeableMinutes = durationMinutes;
//         if (city.waitingTimeLimit > 0) {
//           chargeableMinutes = (durationMinutes - city.waitingTimeLimit).clamp(0, durationMinutes);
//         }
//         fare += chargeableMinutes * city.waitingCharges;
//       }
//
//       // 🔹 Apply surge
//       if (city.isSurged && city.surgeValue > 0) {
//         fare *= city.surgeValue;
//       }
//
//       // 🔹 Apply vehicle markup (if provided)
//       final double percent = vehicle.fareValue ?? 0.0;
//       if (percent > 0) {
//         fare += fare * (percent / 100.0);
//       }
//
//       // 🔹 Ensure base fare
//       if (fare < city.baseFare) fare = city.baseFare;
//
//       return double.parse(fare.toStringAsFixed(2));
//     } catch (e) {
//       print("Error calculating fare: $e");
//       return city.baseFare.toDouble();
//     }
//   }
// }


class FareCalculator {
  double calculateFare({
    required double distanceKm,
    required int durationMinutes,
    required CityModel city,
    required VehicleModel vehicle,
  }) {
    try {
      final double baseFare = city.fare.toDouble();
      // final double perKmCharge = city.perKmCharge.toDouble();
      final double perKmCharge = city.fare.toDouble();
      final double waitingCharges = city.waitingCharges.toDouble();
      final double surgeValue = city.surgeValue.toDouble();
      final bool isSurged = city.isSurged;
      final bool applyWaiting = city.isWaitingChargesApplied == 1;

      double fare = perKmCharge * distanceKm;

      if (applyWaiting && waitingCharges > 0) {
        fare += waitingCharges;
      }

      if (isSurged && surgeValue > 0) {
        fare *= surgeValue;
      }

      final double percent = vehicle.fareValue ?? 0.0;
      if (percent > 0) {
        fare += fare * (percent / 100.0);
      }

      if (fare < baseFare) fare = baseFare;

      return double.parse(fare.toStringAsFixed(2));
    } catch (e) {
      print('Error calculating fare: $e');
      return city.fare.toDouble();
    }
  }
}