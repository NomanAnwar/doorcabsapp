import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'ride_home_controller.dart'; // ← reuse map + ride types + recent logic

class RideRequestController extends RideHomeController {
  /// Incoming args from previous screen:
  /// { pickup: String, dropoff: String, stops: List<Map> }
  final stops = <Map<String, dynamic>>[].obs;

  // Fare input
  final fareController = TextEditingController(text: "250");
  final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  // Passengers
  final passengerOptions = const ["1", "2", "3", "4", "More"];
  final selectedPassengers = "1".obs;

  // Auto accept
  final autoAccept = false.obs;

  // Payment
  final selectedPaymentLabel = "Cash".obs;

  // Date/Time state
  final selectedDate = Rx<DateTime?>(null);
  final selectedTime = Rx<TimeOfDay?>(null);
  final dateLabel = "Today".obs; // UI label (Today/Tomorrow/29 August 2025)
  final timeLabel = "Now".obs;   // UI label (Now / 10:15 AM)

  @override
  void onInit() {
    super.onInit();

    // Get args for pickup/dropoff
    final args = Get.arguments;
    if (args is Map) {
      pickupText.value = (args['pickup'] ?? '').toString();
      dropoffText.value = (args['dropoff'] ?? '').toString();
      if (args['stops'] is List) {
        stops.assignAll((args['stops'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
    }

    // Initialize date/time: Today + Now
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    selectedTime.value = TimeOfDay.now();
    _syncLabels();
  }

  // ======= Map (already inherited) =======
  @override
  void onMapCreated(GoogleMapController controller) {
    super.onMapCreated(controller);
  }

  // ======= Fare controls =======
  void incrementFare() {
    final v = int.tryParse(fareController.text) ?? 0;
    fareController.text = (v + 10).toString();
  }

  void decrementFare() {
    final v = int.tryParse(fareController.text) ?? 0;
    if (v > 0) fareController.text = (v - 10).toString();
  }

  // ======= Request ride =======
  void onRequestRide() {
    if (pickupText.value.isEmpty || dropoffText.value.isEmpty) {
      Get.snackbar('Missing fields', 'Pickup and Drop-off are required.');
      return;
    }

    Get.toNamed('/available-drivers');
    // TODO: call API / next step as per your flow.
    // Get.snackbar('Ride Requested', 'We are finding nearby drivers.');
  }

  // ======= Date/Time helpers =======
  void openDateTimePopup() {
    final now = DateTime.now();

    // Build date options: Today, Tomorrow, +2d, +3d
    final options = _dateOptions(now);

    // Current selections as labels
    String currentDateLabel = dateLabel.value;
    String currentTimeLabel = timeLabel.value;

    // For dialog temp state (so cancel won’t affect live state)
    final tmpDateLabel = currentDateLabel.obs;
    final tmpTimeLabel = currentTimeLabel.obs;

    // Build initial time options for temp date
    var timeOptions = _timeOptionsFor(tmpDateLabel.value, now);

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image/hero (use a simple banner for now)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade700,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.schedule, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Schedule",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date row (like your screenshot "Today" with dropdown)
                  Text("Date", style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Obx(
                        () => _pillDropdown(
                      value: tmpDateLabel.value,
                      items: options,
                      onChanged: (val) {
                        if (val == null) return;
                        tmpDateLabel.value = val;
                        // If date != Today -> "Now" not valid; reset time to first slot
                        timeOptions = _timeOptionsFor(val, now);
                        if (!timeOptions.contains(tmpTimeLabel.value)) {
                          tmpTimeLabel.value = timeOptions.first;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time row ("Now" when Today; otherwise 15-min slots)
                  Text("Time", style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Obx(
                        () => _pillDropdown(
                      value: tmpTimeLabel.value,
                      items: timeOptions,
                      onChanged: (val) {
                        if (val == null) return;
                        tmpTimeLabel.value = val;
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Commit temp → live
                            _applyDateTimeSelection(
                              tmpDateLabel.value,
                              tmpTimeLabel.value,
                              now,
                            );
                            Get.back();
                          },
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: true,
    );
  }

  List<String> _dateOptions(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final list = <String>[];
    list.add("Today");
    list.add("Tomorrow");
    list.add(_formatDateLong(today.add(const Duration(days: 2))));
    list.add(_formatDateLong(today.add(const Duration(days: 3))));
    return list;
  }

  List<String> _timeOptionsFor(String dateLabel, DateTime now) {
    final isToday = dateLabel == "Today";
    final base = DateTime(now.year, now.month, now.day);

    // Generate 15-min slots
    List<String> slots(String startAt) {
      final out = <String>[];
      DateTime t = _parseDateTime(base, startAt, now);
      // last slot 23:45
      final end = base.add(const Duration(hours: 23, minutes: 45));
      while (!t.isAfter(end)) {
        out.add(_fmtHM12(t));
        t = t.add(const Duration(minutes: 15));
      }
      return out;
    }

    if (isToday) {
      // Next quarter-hour (>= now). Include special "Now" as first item.
      final next = _ceilToNextQuarter(now);
      final list = ["Now", ...slots(_fmtHM24(next))];
      return list;
    } else {
      // Full day from 00:00
      return slots("00:00");
    }
  }

  void _applyDateTimeSelection(String dLabel, String tLabel, DateTime now) {
    // Update labels first
    dateLabel.value = dLabel;
    timeLabel.value = tLabel;

    // Map labels -> actual DateTime & TimeOfDay
    if (dLabel == "Today") {
      final d = DateTime(now.year, now.month, now.day);
      selectedDate.value = d;
      if (tLabel == "Now") {
        selectedTime.value = TimeOfDay.fromDateTime(now);
      } else {
        selectedTime.value = _parseTimeOfDay(tLabel);
      }
    } else if (dLabel == "Tomorrow") {
      final d = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      selectedDate.value = d;
      selectedTime.value = _parseTimeOfDay(tLabel);
    } else {
      // Parse "29 August 2025"
      final d = _parseLongDate(dLabel);
      selectedDate.value = d;
      selectedTime.value = _parseTimeOfDay(tLabel);
    }
    _syncLabels();
  }

  void _syncLabels() {
    final now = DateTime.now();
    final selD = selectedDate.value;
    final selT = selectedTime.value;

    if (selD == null || selT == null) return;

    // Date label
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (_sameDate(selD, today)) {
      dateLabel.value = "Today";
    } else if (_sameDate(selD, tomorrow)) {
      dateLabel.value = "Tomorrow";
    } else {
      dateLabel.value = _formatDateLong(selD);
    }

    // Time label
    if (_sameDate(selD, today)) {
      // If selected time <= now + ~5 minutes, call it "Now"
      final dt = DateTime(selD.year, selD.month, selD.day, selT.hour, selT.minute);
      if (!dt.isAfter(now.add(const Duration(minutes: 5)))) {
        timeLabel.value = "Now";
      } else {
        timeLabel.value = _fmtFromTimeOfDay(selT);
      }
    } else {
      timeLabel.value = _fmtFromTimeOfDay(selT);
    }
  }

  // ======= Payment popup =======
  void openPaymentMethods() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Payment Method",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _payTile("Cash Payment", Icons.attach_money),
              _payTile("Easypaisa", Icons.account_balance_wallet),
              _payTile("JazzCash", Icons.account_balance_wallet),
              _payTile("Debit/Credit Card", Icons.credit_card),
              _payTile("DoorCabs Wallet", Icons.account_balance_wallet),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _payTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        selectedPaymentLabel.value = title.contains("Cash") ? "Cash" : title;
        Get.back();
      },
    );
  }

  // ======= Comments popup =======
  void openComments() {
    final ctrl = TextEditingController();
    Get.defaultDialog(
      title: "Comments",
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Column(
        children: [
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Anything your driver should know?",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // You can store ctrl.text somewhere if needed.
                    Get.back();
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======= Utilities (no intl dependency) =======
  String _formatDateLong(DateTime d) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  String _fmtFromTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suf = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $suf";
  }

  String _fmtHM12(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    return _fmtFromTimeOfDay(tod);
  }

  String _fmtHM24(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  DateTime _ceilToNextQuarter(DateTime now) {
    final minute = ((now.minute + 14) ~/ 15) * 15; // ceil
    final addHours = minute ~/ 60;
    final minuteAdj = minute % 60;
    return DateTime(now.year, now.month, now.day, now.hour + addHours, minuteAdj);
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  TimeOfDay _parseTimeOfDay(String label) {
    // expects "10:15 AM"
    final parts = label.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    final isPM = parts.length > 1 && parts[1].toUpperCase() == "PM";
    if (h == 12) h = 0;
    final hour24 = isPM ? h + 12 : h;
    return TimeOfDay(hour: hour24, minute: m);
  }

  DateTime _parseLongDate(String s) {
    // "29 August 2025"
    final parts = s.split(' ');
    final day = int.parse(parts[0]);
    final month = _monthIndex(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  int _monthIndex(String name) {
    const months = {
      "January":1,"February":2,"March":3,"April":4,"May":5,"June":6,
      "July":7,"August":8,"September":9,"October":10,"November":11,"December":12
    };
    return months[name]!;
  }

  DateTime _parseDateTime(DateTime baseDay, String hm24, DateTime now) {
    // hm24 "HH:mm"
    final hm = hm24.split(':');
    final h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    return DateTime(baseDay.year, baseDay.month, baseDay.day, h, m);
  }
}


Widget _pillDropdown({
  // required String label,
  required String value,
  required List<String> items,
  required void Function(String?) onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(30),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(fontSize: 14)),
        ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    ),
  );
}


