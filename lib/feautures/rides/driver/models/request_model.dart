// models/request_model.dart
import 'package:flutter/material.dart';

class RequestModel {
  final String id;
  final String passengerName;
  final String passengerImage; // asset path or network
  final double rating;

  // Updated pickup (with lat/lng + address)
  final LocationPoint pickupAddress;

  // Updated dropoff (list of stops)
  final List<DropoffPoint> dropoffAddress;

  final String phone;
  final int etaMinutes; // estimated driver->pickup minutes (initial)
  final double distanceKm; // estimated distance from driver -> pickup
  final double offerAmount; // initial offered amount by passenger (if any)
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.passengerName,
    required this.passengerImage,
    required this.rating,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.phone,
    required this.etaMinutes,
    required this.distanceKm,
    required this.offerAmount,
    required this.createdAt,
  });

  // ---------- JSON Factory ----------
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // FIXED: Handle rating field which can be string or number
    double ratingValue = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is num) {
        ratingValue = (json['rating'] as num).toDouble();
      } else if (json['rating'] is String && json['rating'].toString().isNotEmpty) {
        ratingValue = double.tryParse(json['rating'].toString()) ?? 0.0;
      }
    }

    return RequestModel(
      id: json['rideId']?.toString() ?? json['id']?.toString() ?? '',
      passengerName: json['passengerName']?.toString() ?? 'Unknown Passenger',
      passengerImage: json['passengerImage']?.toString() ?? '',
      rating: ratingValue, // FIXED: Use the properly parsed rating
      pickupAddress: LocationPoint.fromJson(json['pickupAddress'] ?? {}),
      dropoffAddress: (json['dropoffAddress'] is List)
          ? (json['dropoffAddress'] as List)
          .map((e) => DropoffPoint.fromJson(e ?? {}))
          .toList()
          : [],
      phone: json['phone']?.toString() ?? '',
      etaMinutes: (json['etaMinutes'] as int?) ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      offerAmount: (json['offerAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "passengerName": passengerName,
      "passengerImage": passengerImage,
      "rating": rating,
      "pickupAddress": pickupAddress.toJson(),
      "dropoffAddress": dropoffAddress.map((e) => e.toJson()).toList(),
      "phone": phone,
      "etaMinutes": etaMinutes,
      "distanceKm": distanceKm,
      "offerAmount": offerAmount,
      "createdAt": createdAt.millisecondsSinceEpoch,
    };
  }
}

// ---------- Extra Models ----------
class LocationPoint {
  final double lat;
  final double lng;
  final String address;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0, // FIXED: Handle null case
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0, // FIXED: Handle null case
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lng": lng,
      "address": address,
    };
  }
}

class DropoffPoint extends LocationPoint {
  final int stopOrder;

  DropoffPoint({
    required double lat,
    required double lng,
    required String address,
    required this.stopOrder,
  }) : super(lat: lat, lng: lng, address: address);

  factory DropoffPoint.fromJson(Map<String, dynamic> json) {
    return DropoffPoint(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0, // FIXED: Handle null case
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0, // FIXED: Handle null case
      address: json['address']?.toString() ?? '',
      stopOrder: json['stop_order'] ?? json['order'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lng": lng,
      "address": address,
      "stop_order": stopOrder,
      "order": stopOrder,
    };
  }
}