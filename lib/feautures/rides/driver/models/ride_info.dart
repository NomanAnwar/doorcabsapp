// models/ride_info.dart
class RideInfo {
  final String rideId;
  final String? message;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;
  final List<Map<String, dynamic>> dropoffs;
  final String? estimatedArrivalTime;
  final String? estimatedDropoffTime;
  final String? estimatedDistance;
  final double? fare;
  final String? passengerName;
  final String? phone;

  RideInfo({
    required this.rideId,
    this.message,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.dropoffs = const [],
    this.estimatedArrivalTime,
    this.estimatedDropoffTime,
    this.estimatedDistance,
    this.fare,
    this.passengerName,
    this.phone,
  });

  factory RideInfo.fromMap(Map<String, dynamic> m) {
    final pickup = m['pickup'];
    final dropoffsRaw = m['dropoffs'] ?? m['dropoffs'] ?? [];
    List<Map<String, dynamic>> parsedDropoffs = [];
    if (dropoffsRaw is List) {
      for (final e in dropoffsRaw) {
        if (e is Map) parsedDropoffs.add(Map<String, dynamic>.from(e));
      }
    }

    return RideInfo(
      rideId: m['rideId']?.toString() ?? m['_id']?.toString() ?? '',
      message: m['message']?.toString(),
      pickupLat: (pickup != null && (pickup['lat'] != null))
          ? (pickup['lat'] is num ? (pickup['lat'] as num).toDouble() : double.tryParse(pickup['lat'].toString()))
          : null,
      pickupLng: (pickup != null && (pickup['lng'] != null))
          ? (pickup['lng'] is num ? (pickup['lng'] as num).toDouble() : double.tryParse(pickup['lng'].toString()))
          : null,
      pickupAddress: pickup != null ? (pickup['address']?.toString() ?? '') : '',
      dropoffs: parsedDropoffs,
      estimatedArrivalTime: m['estimated_arrival_time']?.toString() ?? m['eta']?.toString(),
      estimatedDropoffTime: m['estimated_drop_time']?.toString(),
      estimatedDistance: m['estimated_distance']?.toString(),
      fare: (m['fare'] is num) ? (m['fare'] as num).toDouble() : (m['fare'] != null ? double.tryParse(m['fare'].toString()) : null),
      passengerName: m['passengerName']?.toString() ?? m['name']?.toString(),
      phone: m['phone']?.toString(),
    );
  }
}
