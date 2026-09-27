import 'package:flutter/material.dart';

const List<String> monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// "Sep 24"
String fmtDate(DateTime? d) {
  if (d == null) return '';
  return '${monthsShort[d.month - 1]} ${d.day}';
}

/// "Thursday 24" — Bugün başlığı.
String fmtTodayHeader(DateTime d) => '${weekdaysLong[d.weekday - 1]} ${d.day}';

/// [from] gününden [to] gününe kadar geçen tam gün sayısı.
int daysBetween(DateTime from, DateTime to) =>
    DateTime(to.year, to.month, to.day)
        .difference(DateTime(from.year, from.month, from.day))
        .inDays;

int daysSince(DateTime d) => daysBetween(d, DateTime.now());

/// ["a","b","c"] → "a, b and c"
String listJoin(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

String clip(String t, [int n = 34]) => t.length > n ? '${t.substring(0, n - 2)}…' : t;

String confWord(double? c) {
  if (c == null) return '';
  if (c < 0.45) return 'Low';
  if (c < 0.7) return 'Moderate';
  return 'Fairly high';
}

/// 0..1 güven puanını 5 noktaya çevirir.
List<bool> confDots(double? c, {int total = 5}) {
  final value = (c ?? 0) * total;
  return List.generate(total, (i) => i < value.round());
}

String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0, 1))!;
