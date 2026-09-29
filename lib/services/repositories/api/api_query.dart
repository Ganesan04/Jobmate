/// Helpers shared by the API repository implementations.
library;

import '../../../models/job.dart';

/// Paging arguments every list endpoint accepts.
Map<String, Object?> pageArgs({int page = 1, int pageSize = 50}) =>
    <String, Object?>{'Page': page, 'PageSize': pageSize};

/// `SortBy` values for the job feed.
///
/// The API takes these as free-form strings and the spec does not enumerate
/// them, so these mirror the `JobDto` property names. If the backend rejects
/// one it is ignored server-side and the default order is used.
String wireJobSortBy(JobSort sort) => switch (sort) {
  JobSort.newest => 'createdAt',
  JobSort.payHigh => 'pay',
  JobSort.payLow => 'pay',
  JobSort.nearest => 'distanceKm',
};

/// `pay` is sorted in both directions, so the flag differs per option.
bool wireJobSortDescending(JobSort sort) => sort == JobSort.payHigh;

/// Normalises a time-of-day string to the 24-hour `HH:mm:ss` form the API's
/// `TimeOnly` fields bind from.
///
/// The create-job wizard collects times as `9:00 AM`; anything already in
/// 24-hour form is passed through untouched.
String wireTimeOfDay(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return '09:00:00';

  final RegExpMatch? twelveHour = RegExp(
    r'^(\d{1,2})(?::(\d{2}))?\s*([AaPp])\.?[Mm]\.?$',
  ).firstMatch(trimmed);
  if (twelveHour != null) {
    int hour = int.parse(twelveHour.group(1)!);
    final String minute = twelveHour.group(2) ?? '00';
    final bool isPm = twelveHour.group(3)!.toLowerCase() == 'p';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  final RegExpMatch? twentyFourHour = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(
    trimmed,
  );
  if (twentyFourHour != null) {
    final String hour = twentyFourHour.group(1)!.padLeft(2, '0');
    return '$hour:${twentyFourHour.group(2)}:00';
  }
  return trimmed;
}
