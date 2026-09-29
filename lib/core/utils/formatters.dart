import 'package:intl/intl.dart';

/// Formatting helpers shared across the app (INR currency, dates, time).
abstract final class AppFormat {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekdayDate = DateFormat('EEE, d MMM');

  /// ₹12,500
  static String money(num value) => _inr.format(value);

  /// ₹12.5K — used inside tight stat tiles.
  static String moneyCompact(num value) => _inrCompact.format(value);

  /// "1,200/hr" style pay suffix.
  static String paySuffix(num value, String suffix) => '$money/$suffix';

  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String dayMonthYear(DateTime date) => _dayMonthYear.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String time(DateTime date) => _time.format(date);

  static String weekdayDate(DateTime date) => _weekdayDate.format(date);

  /// "Today", "Tomorrow", "Yesterday" or a short date.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final DateTime a = DateTime(date.year, date.month, date.day);
    final DateTime b = DateTime(reference.year, reference.month, reference.day);
    final int diff = a.difference(b).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    return _dayMonth.format(date);
  }

  /// Chat style timestamps: 09:41 AM / Yesterday / 4 Mar.
  static String messageTime(DateTime date, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    if (date.year == reference.year &&
        date.month == reference.month &&
        date.day == reference.day) {
      return _time.format(date);
    }
    return _dayMonth.format(date);
  }

  /// "2 hours ago" style for notifications and messages.
  static String timeAgo(DateTime date, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration diff = reference.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dayMonth.format(date);
  }

  static String durationHours(double hours) {
    final int whole = hours.floor();
    final int minutes = ((hours - whole) * 60).round();
    if (minutes == 0) return '$whole hrs';
    return '$whole h $minutes m';
  }

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
  }
}
