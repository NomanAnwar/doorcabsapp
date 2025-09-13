import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../screens/reusable_widgets/date_time_utils.dart';
import '../date_time_picker_dialog.dart';

class DateTimeController extends GetxController {
  final selectedDate = Rx<DateTime?>(null);
  final selectedTime = Rx<TimeOfDay?>(null);
  final dateLabel = "Today".obs;
  final timeLabel = "Now".obs;

  final DateTimeUtils _dateTimeUtils = DateTimeUtils();

  void initialize() {
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    selectedTime.value = TimeOfDay.now();
    _syncLabels();
  }

  void _syncLabels() {
    final now = DateTime.now();
    final selD = selectedDate.value;
    final selT = selectedTime.value;
    if (selD == null || selT == null) return;

    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    if (_dateTimeUtils.sameDate(selD, today)) {
      dateLabel.value = "Today";
    } else if (_dateTimeUtils.sameDate(selD, tomorrow)) {
      dateLabel.value = "Tomorrow";
    } else {
      dateLabel.value = _dateTimeUtils.formatDateLong(selD);
    }

    final dt = DateTime(selD.year, selD.month, selD.day, selT.hour, selT.minute);
    if (_dateTimeUtils.sameDate(selD, today) && !dt.isAfter(now.add(Duration(minutes: 5)))) {
      timeLabel.value = "Now";
    } else {
      timeLabel.value = _dateTimeUtils.fmtFromTimeOfDay(selT);
    }
  }

  void openDateTimePopup() {
    DateTimePickerWidget.show(
        selectedDate: selectedDate.value!,
        selectedTime: selectedTime.value!,
        onDateTimeSelected: (date, time) {
          selectedDate.value = date;
          selectedTime.value = time;
          _syncLabels();
        }
    );
  }
}