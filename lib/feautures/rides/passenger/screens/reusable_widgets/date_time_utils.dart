import 'package:flutter/material.dart';

class DateTimeUtils {
  bool sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String formatDateLong(DateTime d) {
    const months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  String fmtFromTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suf = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $suf";
  }

  String fmtHM12(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    return fmtFromTimeOfDay(tod);
  }

  String fmtHM24(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  DateTime ceilToNextQuarter(DateTime now) {
    final minute = ((now.minute + 14) ~/ 15) * 15;
    final addHours = minute ~/ 60;
    final minuteAdj = minute % 60;
    return DateTime(now.year, now.month, now.day, now.hour + addHours, minuteAdj);
  }

  TimeOfDay parseTimeOfDay(String label) {
    final parts = label.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    final isPM = parts.length > 1 && parts[1].toUpperCase() == "PM";
    if (h == 12) h = 0;
    final hour24 = isPM ? h + 12 : h;
    return TimeOfDay(hour: hour24, minute: m);
  }

  DateTime parseLongDate(String s) {
    final parts = s.split(' ');
    final day = int.parse(parts[0]);
    final month = _monthIndex(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  DateTime parseDateTime(DateTime baseDay, String hm24, DateTime now) {
    final hm = hm24.split(':');
    final h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    return DateTime(baseDay.year, baseDay.month, baseDay.day, h, m);
  }

  // Add the missing methods directly to the class
  List<String> dateOptions(DateTime now) {
    final List<String> options = ["Today", "Tomorrow"];
    for (int i = 2; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      options.add(formatDateLong(date));
    }
    return options;
  }

  List<String> timeOptionsFor(String dateLabel, DateTime now) {
    final isToday = dateLabel == "Today";
    final base = DateTime(now.year, now.month, now.day);

    List<String> slots(String startAt) {
      final out = <String>[];
      DateTime t = parseDateTime(base, startAt, now);
      final end = base.add(Duration(hours: 23, minutes: 45));
      while (!t.isAfter(end)) {
        out.add(fmtHM12(t));
        t = t.add(Duration(minutes: 15));
      }
      return out;
    }

    if (isToday) {
      final next = ceilToNextQuarter(now);
      return ["Now", ...slots(fmtHM24(next))];
    } else {
      return slots("00:00");
    }
  }

  int _monthIndex(String name) {
    const months = {
      "January":1,"February":2,"March":3,"April":4,"May":5,"June":6,
      "July":7,"August":8,"September":9,"October":10,"November":11,"December":12
    };
    return months[name]!;
  }
}