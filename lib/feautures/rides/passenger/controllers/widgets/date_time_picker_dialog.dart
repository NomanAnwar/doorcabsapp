import 'package:doorcab/feautures/rides/passenger/controllers/widgets/pill_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../screens/reusable_widgets/date_time_utils.dart';


class DateTimePickerWidget {
  static void show({
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required Function(DateTime, TimeOfDay) onDateTimeSelected,
  }) {
    final now = DateTime.now();
    final DateTimeUtils _dateTimeUtils = DateTimeUtils();

    final tmpDateLabel = _getDateLabel(selectedDate, now).obs;
    final tmpTimeLabel = _getTimeLabel(selectedTime, selectedDate, now).obs;

    var timeOptions = _dateTimeUtils.timeOptionsFor(tmpDateLabel.value, now);

    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Schedule Your Ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Obx(() => PillDropdownWidget(
                value: tmpDateLabel.value,
                items: _dateTimeUtils.dateOptions(now),
                onChanged: (val) {
                  if (val == null) return;
                  tmpDateLabel.value = val;
                  timeOptions = _dateTimeUtils.timeOptionsFor(val, now);
                  if (!timeOptions.contains(tmpTimeLabel.value)) {
                    tmpTimeLabel.value = timeOptions.first;
                  }
                },
              )),
              SizedBox(height: 16),

              Text("Time", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Obx(() => PillDropdownWidget(
                value: tmpTimeLabel.value,
                items: timeOptions,
                onChanged: (val) {
                  if (val == null) return;
                  tmpTimeLabel.value = val;
                },
              )),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final dateTime = _applyDateTimeSelection(tmpDateLabel.value, tmpTimeLabel.value, now);
                    onDateTimeSelected(dateTime['date']!, dateTime['time']!);
                    Get.back();
                  },
                  child: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Use your FColors.secondaryColor
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getDateLabel(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return "Today";
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return "Tomorrow";
    } else {
      const months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    }
  }

  static String _getTimeLabel(TimeOfDay time, DateTime date, DateTime now) {
    final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final nowPlus5 = now.add(Duration(minutes: 5));

    if (date.year == now.year && date.month == now.month && date.day == now.day &&
        !selectedDateTime.isAfter(nowPlus5)) {
      return "Now";
    } else {
      final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final m = time.minute.toString().padLeft(2, '0');
      final suf = time.period == DayPeriod.am ? "AM" : "PM";
      return "$h:$m $suf";
    }
  }

  static Map<String, dynamic> _applyDateTimeSelection(String dLabel, String tLabel, DateTime now) {
    final DateTimeUtils _dateTimeUtils = DateTimeUtils();

    DateTime date;
    TimeOfDay time;

    if (dLabel == "Today") {
      date = DateTime(now.year, now.month, now.day);
      time = (tLabel == "Now") ? TimeOfDay.fromDateTime(now) : _dateTimeUtils.parseTimeOfDay(tLabel);
    } else if (dLabel == "Tomorrow") {
      date = DateTime(now.year, now.month, now.day).add(Duration(days: 1));
      time = _dateTimeUtils.parseTimeOfDay(tLabel);
    } else {
      date = _dateTimeUtils.parseLongDate(dLabel);
      time = _dateTimeUtils.parseTimeOfDay(tLabel);
    }

    return {'date': date, 'time': time};
  }
}