import 'package:flutter/material.dart';

/// The two consumer roles supported by Jobmate (admins are a separate console).
enum UserRole {
  worker('Worker', 'Find work and earn daily'),
  workGiver('Work Giver', 'Hire reliable workers near you'),
  admin('Admin', 'Platform administrator');

  const UserRole(this.label, this.tagline);

  final String label;
  final String tagline;

  String get storageValue => name;

  /// Roles a member can pick for themselves. `admin` is assigned by the backend
  /// and is never offered on the role selection screen.
  static const List<UserRole> selectable = <UserRole>[worker, workGiver];

  static UserRole fromStorage(String? value) => UserRole.values.firstWhere(
    (UserRole role) => role.name == value,
    orElse: () => UserRole.worker,
  );
}

/// Lifecycle status of a job posting owned by a work giver.
enum JobStatus {
  draft('Draft', Icons.edit_note_rounded, Color(0xFF64748B)),
  pending('Pending', Icons.schedule_rounded, Color(0xFFF59E0B)),
  active('Active', Icons.bolt_rounded, Color(0xFF10B981)),
  inProgress('In progress', Icons.play_circle_fill_rounded, Color(0xFF0EA5E9)),
  completed('Completed', Icons.task_alt_rounded, Color(0xFF0F766E)),
  cancelled('Cancelled', Icons.cancel_rounded, Color(0xFFEF4444)),
  expired('Expired', Icons.history_toggle_off_rounded, Color(0xFF94A3B8));

  const JobStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Status of a worker's application to a job.
enum ApplicationStatus {
  applied('Applied', Icons.send_rounded, Color(0xFF0EA5E9)),
  viewed('Viewed', Icons.visibility_rounded, Color(0xFF7C3AED)),
  shortlisted('Shortlisted', Icons.star_rounded, Color(0xFFF59E0B)),
  accepted('Accepted', Icons.check_circle_rounded, Color(0xFF10B981)),
  rejected('Rejected', Icons.cancel_rounded, Color(0xFFEF4444)),
  withdrawn('Withdrawn', Icons.undo_rounded, Color(0xFF64748B)),
  expired('Expired', Icons.timer_off_rounded, Color(0xFF94A3B8));

  const ApplicationStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  bool get isTerminal =>
      this == rejected || this == withdrawn || this == expired;

  bool get isOpen => !isTerminal;
}

/// Admin-side view of an application: same lifecycle, giver-driven wording.
enum ApplicantStatus {
  applied('Applied'),
  shortlisted('Shortlisted'),
  rejected('Rejected'),
  selected('Selected');

  const ApplicantStatus(this.label);

  final String label;

  bool get isOpen => this != rejected;
}

enum PaymentStatus {
  pending('Pending', Icons.schedule_rounded, Color(0xFFF59E0B)),
  processing('Processing', Icons.autorenew_rounded, Color(0xFF0EA5E9)),
  paid('Paid', Icons.check_circle_rounded, Color(0xFF10B981)),
  disputed('Disputed', Icons.gavel_rounded, Color(0xFFEF4444)),
  failed('Failed', Icons.error_outline_rounded, Color(0xFFEF4444)),
  refunded('Refunded', Icons.undo_rounded, Color(0xFF64748B)),
  cancelled('Cancelled', Icons.cancel_rounded, Color(0xFF94A3B8));

  const PaymentStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Money that has actually reached the worker.
  bool get isSettled => this == paid;

  /// Money that is still expected to arrive.
  bool get isOutstanding => this == pending || this == processing;
}

enum VerificationStatus {
  notVerified(
    'Not verified',
    Icons.radio_button_unchecked_rounded,
    Color(0xFF94A3B8),
  ),
  pending('Pending', Icons.schedule_rounded, Color(0xFFF59E0B)),
  verified('Verified', Icons.verified_rounded, Color(0xFF10B981)),
  rejected('Rejected', Icons.error_rounded, Color(0xFFEF4444));

  const VerificationStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum VerificationType {
  identity('Identity proof'),
  phone('Phone number'),
  email('Email address'),
  skills('Skills & experience'),
  address('Address');

  const VerificationType(this.label);

  final String label;
}

enum PaymentMethod {
  upi('UPI', Icons.account_balance_wallet_rounded),
  bank('Bank transfer', Icons.account_balance_rounded),
  cash('Cash after work', Icons.payments_rounded);

  const PaymentMethod(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum PayType {
  fixed('Fixed pay'),
  hourly('Per hour'),
  daily('Per day'),
  perPiece('Per piece');

  const PayType(this.label);

  final String label;
}

enum JobCategory {
  retail('Retail', Icons.storefront_rounded),
  events('Events', Icons.celebration_rounded),
  delivery('Delivery', Icons.local_shipping_rounded),
  cleaning('Cleaning', Icons.cleaning_services_rounded),
  security('Security', Icons.shield_rounded),
  office('Office', Icons.business_center_rounded),
  hospitality('Hospitality', Icons.room_service_rounded),
  construction('Construction', Icons.construction_rounded),
  teaching('Teaching', Icons.school_rounded),
  healthcare('Healthcare', Icons.medical_services_rounded),
  itSupport('IT Support', Icons.devices_rounded),
  other('Other', Icons.more_horiz_rounded);

  const JobCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum WorkplaceType {
  onSite('On site'),
  remote('Remote'),
  hybrid('Hybrid');

  const WorkplaceType(this.label);

  final String label;
}

enum JobType {
  oneTime('One-time'),
  recurring('Recurring');

  const JobType(this.label);

  final String label;
}

enum WorkDay {
  monday('Mon', 1),
  tuesday('Tue', 2),
  wednesday('Wed', 3),
  thursday('Thu', 4),
  friday('Fri', 5),
  saturday('Sat', 6),
  sunday('Sun', 7);

  const WorkDay(this.shortLabel, this.weekday);

  final String shortLabel;
  final int weekday;
}

enum NotificationType {
  applicationUpdate(
    'Application update',
    Icons.assignment_turned_in_rounded,
    Color(0xFF0EA5E9),
  ),
  jobAccepted('Job accepted', Icons.celebration_rounded, Color(0xFF10B981)),
  jobShortlisted('Shortlisted', Icons.star_rounded, Color(0xFFF59E0B)),
  payment('Payment', Icons.payments_rounded, Color(0xFF7C3AED)),
  jobReminder('Job reminder', Icons.alarm_rounded, Color(0xFFEF4444)),
  newApplicant(
    'New applicant',
    Icons.person_add_alt_rounded,
    Color(0xFF0F766E),
  ),
  system('System', Icons.info_rounded, Color(0xFF64748B));

  const NotificationType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum DisputeStatus {
  open('Open', Icons.error_rounded, Color(0xFFEF4444)),
  underReview('Under review', Icons.hourglass_top_rounded, Color(0xFFF59E0B)),
  resolved('Resolved', Icons.task_alt_rounded, Color(0xFF10B981)),
  rejected('Rejected', Icons.block_rounded, Color(0xFF64748B));

  const DisputeStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum ReportReason {
  unsafeWorkplace('Unsafe workplace'),
  notPaid('Payment not received'),
  abusiveBehaviour('Abusive behaviour'),
  fakeJob('Fake job listing'),
  noShow('Worker did not show up'),
  other('Other');

  const ReportReason(this.label);

  final String label;
}

enum AdminSection {
  dashboard('Dashboard', Icons.dashboard_rounded),
  users('Users', Icons.group_rounded),
  jobs('Jobs', Icons.work_rounded),
  disputes('Disputes', Icons.gavel_rounded),
  verifications('Verifications', Icons.verified_user_rounded);

  const AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}
