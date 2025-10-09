class DriverModel {
  final int id;
  final String name;
  final String car;
  final String avatar;
  final String phone;
  final double rating;
  final int totalRatings;
  final String category;
  final int eta; // minutes
  final double distance; // km
  final int fare;
  final String pickup;   // address
  final String dropoff;  // address

  // ✅ NEW: exact coordinates for routing
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  DriverModel({
    required this.id,
    required this.name,
    required this.car,
    required this.avatar,
    required this.phone,
    required this.rating,
    required this.totalRatings,
    required this.category,
    required this.eta,
    required this.distance,
    required this.fare,
    required this.pickup,
    required this.dropoff,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  factory DriverModel.fromMap(Map m) => DriverModel(
    id: m['id'] ?? 0,
    name: m['name'] ?? 'Driver',
    car: m['car'] ?? '',
    avatar: m['avatar'] ?? 'assets/images/profile_img_sample.png',
    phone: m['phone'] ?? '',
    rating: (m['rating'] ?? 4.9).toDouble(),
    totalRatings: m['totalRatings'] ?? 0,
    category: m['category'] ?? 'Standard',
    eta: m['eta'] ?? 2,
    distance: (m['distance'] ?? 0.0).toDouble(),
    fare: m['fare'] ?? 250,
    pickup: m['pickup'] ?? '',
    dropoff: m['dropoff'] ?? '',
    pickupLat: (m['pickupLat'] ?? 0.0).toDouble(),
    pickupLng: (m['pickupLng'] ?? 0.0).toDouble(),
    dropoffLat: (m['dropoffLat'] ?? 0.0).toDouble(),
    dropoffLng: (m['dropoffLng'] ?? 0.0).toDouble(),
  );

  Map toMap() => {
    'id': id,
    'name': name,
    'car': car,
    'avatar': avatar,
    'phone': phone,
    'rating': rating,
    'totalRatings': totalRatings,
    'category': category,
    'eta': eta,
    'distance': distance,
    'fare': fare,
    'pickup': pickup,
    'dropoff': dropoff,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'dropoffLat': dropoffLat,
    'dropoffLng': dropoffLng,
  };
}
