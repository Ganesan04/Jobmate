import 'enums.dart';
import 'user.dart';

/// A worker's application to a job.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = ApplicationStatus.applied,
    this.message = '',
    this.expectedPay,
    this.availableFrom = 'Immediately available',
    this.appliedAt,
    this.viewedAt,
    this.shortlistedAt,
    this.acceptedAt,
  });

  final String id;
  final String jobId;
  final String workerId;
  final ApplicationStatus status;
  final String message;
  final int? expectedPay;
  final String availableFrom;
  final DateTime? appliedAt;
  final DateTime? viewedAt;
  final DateTime? shortlistedAt;
  final DateTime? acceptedAt;

  /// Sort key used to group applications into "Active" and "Closed" sections.
  DateTime get appliedDate => appliedAt ?? DateTime(2026, 1, 1);

  JobApplication copyWith({
    ApplicationStatus? status,
    String? message,
    int? expectedPay,
    String? availableFrom,
    DateTime? appliedAt,
    DateTime? viewedAt,
    DateTime? shortlistedAt,
    DateTime? acceptedAt,
  }) {
    return JobApplication(
      id: id,
      jobId: jobId,
      workerId: workerId,
      status: status ?? this.status,
      message: message ?? this.message,
      expectedPay: expectedPay ?? this.expectedPay,
      availableFrom: availableFrom ?? this.availableFrom,
      appliedAt: appliedAt ?? this.appliedAt,
      viewedAt: viewedAt ?? this.viewedAt,
      shortlistedAt: shortlistedAt ?? this.shortlistedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

/// A giver's view of one applicant for a specific job.
class JobApplicant {
  const JobApplicant({
    required this.id,
    required this.jobId,
    required this.worker,
    this.status = ApplicantStatus.applied,
    this.proposedPay,
    this.message = '',
    this.appliedAt,
    this.expectedPay,
    this.distanceKm = 2.4,
  });

  final String id;
  final String jobId;
  final UserProfile worker;
  final ApplicantStatus status;
  final int? proposedPay;
  final String message;
  final DateTime? appliedAt;
  final int? expectedPay;
  final double distanceKm;

  JobApplicant copyWith({
    ApplicantStatus? status,
    int? proposedPay,
    String? message,
    DateTime? appliedAt,
    int? expectedPay,
    double? distanceKm,
  }) {
    return JobApplicant(
      id: id,
      jobId: jobId,
      worker: worker,
      status: status ?? this.status,
      proposedPay: proposedPay ?? this.proposedPay,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      expectedPay: expectedPay ?? this.expectedPay,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

/// Confirmed booking between a giver and a worker.
class WorkerAssignment {
  const WorkerAssignment({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.giverId,
    required this.agreedPay,
    required this.confirmedAt,
    this.paymentStatus = PaymentStatus.pending,
    this.checkedInAt,
    this.checkInCode,
    this.completedAt,
    this.paymentId,
    this.paidAt,
  });

  final String id;
  final String jobId;
  final String workerId;
  final String giverId;
  final int agreedPay;
  final DateTime confirmedAt;
  final PaymentStatus paymentStatus;
  final DateTime? checkedInAt;
  final String? checkInCode;
  final DateTime? completedAt;
  final String? paymentId;
  final DateTime? paidAt;

  bool get isCheckedIn => checkedInAt != null;
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  /// Copies the assignment. Nullable fields are only overwritten when a value is
  /// supplied, so pass the matching `clear*` flag to reset one to null.
  WorkerAssignment copyWith({
    int? agreedPay,
    PaymentStatus? paymentStatus,
    DateTime? checkedInAt,
    String? checkInCode,
    DateTime? completedAt,
    String? paymentId,
    DateTime? paidAt,
    bool clearCheckInCode = false,
    bool clearCompletedAt = false,
    bool clearPaymentId = false,
    bool clearPaidAt = false,
  }) {
    return WorkerAssignment(
      id: id,
      jobId: jobId,
      workerId: workerId,
      giverId: giverId,
      agreedPay: agreedPay ?? this.agreedPay,
      confirmedAt: confirmedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkInCode: clearCheckInCode ? null : checkInCode ?? this.checkInCode,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      paymentId: clearPaymentId ? null : paymentId ?? this.paymentId,
      paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
    );
  }
}

/// Aggregated giver dashboard numbers.
class GiverStats {
  const GiverStats({
    this.activeJobs = 0,
    this.applications = 0,
    this.toConfirm = 0,
    this.totalHired = 0,
    this.spentThisMonth = 0,
  });

  final int activeJobs;
  final int applications;
  final int toConfirm;
  final int totalHired;
  final int spentThisMonth;

  GiverStats copyWith({
    int? activeJobs,
    int? applications,
    int? toConfirm,
    int? totalHired,
    int? spentThisMonth,
  }) {
    return GiverStats(
      activeJobs: activeJobs ?? this.activeJobs,
      applications: applications ?? this.applications,
      toConfirm: toConfirm ?? this.toConfirm,
      totalHired: totalHired ?? this.totalHired,
      spentThisMonth: spentThisMonth ?? this.spentThisMonth,
    );
  }
}

/// Aggregated worker dashboard numbers.
class WorkerStats {
  const WorkerStats({
    this.applied = 0,
    this.active = 0,
    this.completed = 0,
    this.earnings = 0,
  });

  final int applied;
  final int active;
  final int completed;
  final int earnings;

  WorkerStats copyWith({
    int? applied,
    int? active,
    int? completed,
    int? earnings,
  }) {
    return WorkerStats(
      applied: applied ?? this.applied,
      active: active ?? this.active,
      completed: completed ?? this.completed,
      earnings: earnings ?? this.earnings,
    );
  }
}

/// A completed job shown in Work History.
class WorkHistoryEntry {
  const WorkHistoryEntry({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.date,
    required this.durationHours,
    required this.earnings,
    required this.paymentStatus,
    this.rating,
    this.ratedByGiver = false,
  });

  final String id;
  final String jobTitle;
  final String company;
  final DateTime date;
  final double durationHours;
  final int earnings;
  final PaymentStatus paymentStatus;
  final double? rating;
  final bool ratedByGiver;

  WorkHistoryEntry copyWith({
    PaymentStatus? paymentStatus,
    double? rating,
    bool? ratedByGiver,
  }) {
    return WorkHistoryEntry(
      id: id,
      jobTitle: jobTitle,
      company: company,
      date: date,
      durationHours: durationHours,
      earnings: earnings,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      ratedByGiver: ratedByGiver ?? this.ratedByGiver,
    );
  }
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
