
import '../../models/city_model.dart';
import '../../models/vehicle_model.dart';

class FareCalculator {
  double calculateFare({
    required double distanceKm,
    required int durationMinutes,
    required CityModel city,
    required VehicleModel vehicle,
  }) {
    try {
      final double baseFare = city.baseFare.toDouble();
      final double perKmCharge = city.perKmCharge.toDouble();
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

      final double percent = vehicle.fareValue;
      if (percent > 0) {
        fare += fare * (percent / 100.0);
      }

      if (fare < baseFare) fare = baseFare;

      return double.parse(fare.toStringAsFixed(2));
    } catch (e) {
      print('Error calculating fare: $e');
      return city.baseFare.toDouble();
    }
  }
}