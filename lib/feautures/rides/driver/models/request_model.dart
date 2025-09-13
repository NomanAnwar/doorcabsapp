// models/request_model.dart
import 'package:flutter/material.dart';

class RequestModel {
  final String id;
  final String passengerName;
  final String passengerImage; // asset path or network
  final double rating;
  final String pickupAddress;
  final String dropoffAddress;
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
}
