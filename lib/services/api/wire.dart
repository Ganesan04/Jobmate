/// Conversions between the API's JSON enum values and the app's enums.
///
/// The API spells its enum members exactly like the Dart enum constants
/// (`workGiver`, `perPiece`, `underReview`, ...), so parsing is a
/// case-insensitive name lookup. Anything unrecognised falls back to a safe
/// default rather than throwing, so one unexpected value from the backend can
/// never take a whole screen down.
library;

import '../../models/enums.dart';

T _fromWire<T extends Enum>(
  List<T> values,
  String Function(T value) name,
  Object? raw,
  T fallback,
) {
  if (raw is! String) return fallback;
  final String needle = raw.trim().toLowerCase();
  for (final T value in values) {
    if (name(value).toLowerCase() == needle) return value;
  }
  return fallback;
}

/// `YYYY-MM-DD`, the format every date-only API field expects.
String wireDate(DateTime value) {
  final DateTime local = value.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String wireDateTime(DateTime value) => value.toLocal().toIso8601String();

// ------------------------------------------------------------------ identity

UserRole userRoleFromWire(Object? raw, {UserRole fallback = UserRole.worker}) =>
    _fromWire(UserRole.values, (UserRole v) => v.name, raw, fallback);

String wireUserRole(UserRole value) => value.name;

// ---------------------------------------------------------------------- jobs

JobStatus jobStatusFromWire(Object? raw) => _fromWire(
  JobStatus.values,
  (JobStatus v) => v.name,
  raw,
  JobStatus.active,
);

String wireJobStatus(JobStatus value) => value.name;

JobType jobTypeFromWire(Object? raw) =>
    _fromWire(JobType.values, (JobType v) => v.name, raw, JobType.oneTime);

String wireJobType(JobType value) => value.name;

JobCategory jobCategoryFromWire(Object? raw) =>
    _fromWire(JobCategory.values, (JobCategory v) => v.name, raw, JobCategory.other);

String wireJobCategory(JobCategory value) => value.name;

WorkplaceType workplaceTypeFromWire(Object? raw) => _fromWire(
  WorkplaceType.values,
  (WorkplaceType v) => v.name,
  raw,
  WorkplaceType.onSite,
);

String wireWorkplaceType(WorkplaceType value) => value.name;

PayType payTypeFromWire(Object? raw) =>
    _fromWire(PayType.values, (PayType v) => v.name, raw, PayType.fixed);

String wirePayType(PayType value) => value.name;

PaymentMethod paymentMethodFromWire(Object? raw) => _fromWire(
  PaymentMethod.values,
  (PaymentMethod v) => v.name,
  raw,
  PaymentMethod.upi,
);

String wirePaymentMethod(PaymentMethod value) => value.name;

PaymentStatus paymentStatusFromWire(Object? raw) => _fromWire(
  PaymentStatus.values,
  (PaymentStatus v) => v.name,
  raw,
  PaymentStatus.pending,
);

String wirePaymentStatus(PaymentStatus value) => value.name;

/// The API sends ISO weekday numbers (1 = Monday .. 7 = Sunday).
WorkDay? workDayFromNumber(Object? raw) {
  if (raw is! num) return null;
  final int index = raw.toInt() - 1;
  if (index < 0 || index >= WorkDay.values.length) return null;
  return WorkDay.values[index];
}

int wireWorkDayNumber(WorkDay value) => value.weekday;

// ------------------------------------------------------------- applications

ApplicationStatus applicationStatusFromWire(Object? raw) => _fromWire(
  ApplicationStatus.values,
  (ApplicationStatus v) => v.name,
  raw,
  ApplicationStatus.applied,
);

String wireApplicationStatus(ApplicationStatus value) => value.name;

ApplicantStatus applicantStatusFromWire(Object? raw) => _fromWire(
  ApplicantStatus.values,
  (ApplicantStatus v) => v.name,
  raw,
  ApplicantStatus.applied,
);

String wireApplicantStatus(ApplicantStatus value) => value.name;

/// `AssignmentStatus` is only surfaced through assignment DTOs; the app models
/// an assignment's progress through its timestamps, so this is parse-only.
String assignmentStatusFromWire(Object? raw) => raw is String ? raw : 'pending';

// --------------------------------------------------------- trust + payments

VerificationStatus verificationStatusFromWire(Object? raw) => _fromWire(
  VerificationStatus.values,
  (VerificationStatus v) => v.name,
  raw,
  VerificationStatus.notVerified,
);

String wireVerificationStatus(VerificationStatus value) => value.name;

VerificationType verificationTypeFromWire(Object? raw) => _fromWire(
  VerificationType.values,
  (VerificationType v) => v.name,
  raw,
  VerificationType.identity,
);

String wireVerificationType(VerificationType value) => value.name;

ReportReason reportReasonFromWire(Object? raw) => _fromWire(
  ReportReason.values,
  (ReportReason v) => v.name,
  raw,
  ReportReason.other,
);

String wireReportReason(ReportReason value) => value.name;

// -------------------------------------------------- messaging + notification

/// The app only ever sends plain text; `system` messages are backend-authored.
const String wireMessageTypeText = 'text';

NotificationType notificationTypeFromWire(Object? raw) => _fromWire(
  NotificationType.values,
  (NotificationType v) => v.name,
  raw,
  NotificationType.system,
);

String wireNotificationType(NotificationType value) => value.name;
