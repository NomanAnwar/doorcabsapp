// controllers/ride_request_list_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/request_model.dart';

class RideRequestListController extends GetxController {
  // Requests list
  final requests = <RequestModel>[].obs;

  // Map of requestId -> remaining seconds for the offer countdown
  final remainingSeconds = <String, int>{}.obs;

  // Map of requestId -> Timer
  final _timers = <String, Timer>{};

  // Online toggle
  final isOnline = true.obs;

  // Per-request total countdown (in seconds)
  final int offerCountdownSeconds = 60;

  @override
  void onInit() {
    super.onInit();
    // load sample requests
    final sample = _sampleRequests();
    requests.assignAll(sample);

    // start timers for each
    for (final r in sample) {
      _startTimerForRequest(r.id);
    }
  }

  // Start a per-card timer
  void _startTimerForRequest(String requestId) {
    // Cancel if already running
    _timers[requestId]?.cancel();

    remainingSeconds[requestId] = offerCountdownSeconds;

    _timers[requestId] = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = remainingSeconds[requestId] ?? 0;
      if (current <= 1) {
        // expired
        t.cancel();
        remainingSeconds[requestId] = 0;
        _handleRequestTimeout(requestId);
      } else {
        remainingSeconds[requestId] = current - 1;
      }
    });
  }

  // Stops timer (when user taps/responds)
  void stopTimerForRequest(String requestId) {
    _timers[requestId]?.cancel();
    _timers.remove(requestId);
    remainingSeconds.remove(requestId);
  }

  // Handle automatic rejection when countdown expires
  void _handleRequestTimeout(String requestId) {
    // Locally mark request as rejected by removing it:
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) {
      requests.removeAt(idx);
    }
    // TODO: call the API to notify server that request expired/rejected.
    // e.g. await api.rejectRequest(requestId);
    // Show a small snackbar
    Get.snackbar('Request timed out', 'Request $requestId has been removed.');
  }

  // When driver taps the request card or Offer/Accept
  void acceptRequest(RequestModel request) {
    // Stop timer and navigate to detail screen
    stopTimerForRequest(request.id);

    // Navigate to request detail screen and pass the request object
    Get.toNamed('/ride-request-detail', arguments: {'request': request});
  }

  // If driver explicitly rejects / ignores
  void rejectRequest(String requestId) {
    stopTimerForRequest(requestId);
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) requests.removeAt(idx);

    // TODO: call API to notify server about rejection if needed
    Get.snackbar('Request rejected', 'You rejected the request');
  }

  // Toggle online/offline
  void toggleOnline(bool val) {
    isOnline.value = val;
    // TODO call your API to update driver online status or local storage
  }

  // Clean up timers on close
  @override
  void onClose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.onClose();
  }

  // Dummy sample data to demo UI
  List<RequestModel> _sampleRequests() {
    final now = DateTime.now();
    return [
      RequestModel(
        id: 'req_1',
        passengerName: 'Ayesha Khan',
        passengerImage: 'assets/images/passenger1.jpg',
        rating: 4.98,
        pickupAddress: 'House 12, Model Town, Lahore',
        dropoffAddress: 'Gulberg, Lahore',
        phone: '+92300XXXXXXX',
        etaMinutes: 2,
        distanceKm: 1.2,
        offerAmount: 250.0,
        createdAt: now.subtract(const Duration(seconds: 10)),
      ),
      RequestModel(
        id: 'req_2',
        passengerName: 'Bilal Ahmed',
        passengerImage: 'assets/images/passenger2.jpg',
        rating: 4.9,
        pickupAddress: 'Main Boulevard, DHA',
        dropoffAddress: 'Airport Road, Lahore',
        phone: '+92301XXXXXXX',
        etaMinutes: 4,
        distanceKm: 3.6,
        offerAmount: 350.0,
        createdAt: now.subtract(const Duration(seconds: 5)),
      ),
      RequestModel(
        id: 'req_3',
        passengerName: 'Zara Malik',
        passengerImage: 'assets/images/passenger3.jpg',
        rating: 4.7,
        pickupAddress: 'Lower Mall',
        dropoffAddress: 'Liberty',
        phone: '+92321XXXXXXX',
        etaMinutes: 3,
        distanceKm: 2.3,
        offerAmount: 300.0,
        createdAt: now,
      ),
    ];
  }
}
