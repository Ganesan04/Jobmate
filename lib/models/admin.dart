import 'enums.dart';

/// A row in the admin users table.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.verification,
    required this.isActive,
    required this.joinedOn,
    this.jobsCount = 0,
    this.area = '',
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final VerificationStatus verification;
  final bool isActive;
  final DateTime joinedOn;
  final int jobsCount;
  final String area;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

/// A dispute raised by either side of a booking.
class Dispute {
  const Dispute({
    required this.id,
    required this.reason,
    required this.raisedBy,
    required this.againstUser,
    required this.jobTitle,
    required this.company,
    required this.raisedAt,
    required this.status,
    this.amount = 0,
    this.details = '',
    this.notes = '',
  });

  final String id;
  final ReportReason reason;
  final String raisedBy;
  final String againstUser;
  final String jobTitle;
  final String company;
  final DateTime raisedAt;
  final DisputeStatus status;
  final int amount;
  final String details;
  final String notes;

  Dispute copyWith({DisputeStatus? status, String? notes}) {
    return Dispute(
      id: id,
      reason: reason,
      raisedBy: raisedBy,
      againstUser: againstUser,
      jobTitle: jobTitle,
      company: company,
      raisedAt: raisedAt,
      status: status ?? this.status,
      amount: amount,
      details: details,
      notes: notes ?? this.notes,
    );
  }
}

/// A verification request awaiting an admin decision.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.type,
    required this.submittedAt,
    this.status = VerificationStatus.pending,
    this.document = '',
    this.note = '',
  });

  final String id;
  final String userId;
  final String userName;
  final UserRole userRole;
  final VerificationType type;
  final DateTime submittedAt;
  final VerificationStatus status;
  final String document;
  final String note;

  VerificationRequest copyWith({VerificationStatus? status, String? note}) {
    return VerificationRequest(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      type: type,
      submittedAt: submittedAt,
      status: status ?? this.status,
      document: document,
      note: note ?? this.note,
    );
  }
}

/// Platform-wide metrics for the admin dashboard.
class AdminStats {
  const AdminStats({
    this.totalUsers = 0,
    this.workers = 0,
    this.workGivers = 0,
    this.activeJobs = 0,
    this.applications = 0,
    this.completedJobs = 0,
    this.payments = 0,
    this.verificationRequests = 0,
    this.openDisputes = 0,
  });

  final int totalUsers;
  final int workers;
  final int workGivers;
  final int activeJobs;
  final int applications;
  final int completedJobs;
  final int payments;
  final int verificationRequests;
  final int openDisputes;

  AdminStats copyWith({
    int? totalUsers,
    int? workers,
    int? workGivers,
    int? activeJobs,
    int? applications,
    int? completedJobs,
    int? payments,
    int? verificationRequests,
    int? openDisputes,
  }) {
    return AdminStats(
      totalUsers: totalUsers ?? this.totalUsers,
      workers: workers ?? this.workers,
      workGivers: workGivers ?? this.workGivers,
      activeJobs: activeJobs ?? this.activeJobs,
      applications: applications ?? this.applications,
      completedJobs: completedJobs ?? this.completedJobs,
      payments: payments ?? this.payments,
      verificationRequests: verificationRequests ?? this.verificationRequests,
      openDisputes: openDisputes ?? this.openDisputes,
    );
  }
}

/// A released payment, as returned by the payments endpoints.
class PaymentReceipt {
  const PaymentReceipt({
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.workerName,
    this.fee = 0,
    this.overtime = 0,
  });

  final String paymentId;
  final int amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final String workerName;
  final int fee;
  final int overtime;

  int get base => amount - fee - overtime;
}

/// A completed giver -> worker rating.
class WorkerRating {
  const WorkerRating({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.giverId,
    required this.stars,
    this.feedback = '',
    this.createdAt,
  });

  final String id;
  final String jobId;
  final String workerId;
  final String giverId;
  final int stars;
  final String feedback;
  final DateTime? createdAt;
}
