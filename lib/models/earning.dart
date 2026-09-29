import 'enums.dart';

/// One earnings record for the worker wallet.
class Earning {
  const Earning({
    required this.id,
    required this.workerId,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.date,
    required this.amount,
    required this.status,
    this.assignmentId,
    this.paymentId,
    this.method = PaymentMethod.upi,
    this.hours,
  });

  final String id;
  final String workerId;
  final String jobId;
  final String jobTitle;
  final String company;
  final DateTime date;
  final int amount;
  final PaymentStatus status;

  /// Set when the record was produced by paying a confirmed assignment. It
  /// makes the record idempotent, so one shift can only ever be paid once.
  final String? assignmentId;
  final String? paymentId;
  final PaymentMethod method;
  final double? hours;

  Earning copyWith({
    PaymentStatus? status,
    String? paymentId,
    DateTime? paidOn,
  }) {
    return Earning(
      id: id,
      workerId: workerId,
      assignmentId: assignmentId,
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      date: paidOn ?? date,
      amount: amount,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      method: method,
      hours: hours,
    );
  }
}

/// Month-grouped earnings summary.
class EarningSummary {
  const EarningSummary({
    required this.month,
    required this.earned,
    required this.pending,
  });

  final String month;
  final int earned;
  final int pending;

  int get total => earned + pending;
}
