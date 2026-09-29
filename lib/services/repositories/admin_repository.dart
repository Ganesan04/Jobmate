import '../../models/admin.dart';
import '../../models/enums.dart';
import '../../models/job.dart';

/// Admin console data + moderation actions.
///
/// Implemented against `/api/v1/admin/*`.
abstract class AdminRepository {
  Future<bool> signIn({required String email, required String password});

  Future<void> signOut();

  Future<AdminStats> stats();

  Future<List<AdminUser>> users({
    String query,
    UserRole? role,
    VerificationStatus? verification,
  });

  Future<void> setUserActive(String userId, bool isActive, {String reason});

  Future<List<Job>> jobs({String query, JobStatus? status, JobCategory? category});

  Future<void> remindApplicants(String jobId);

  Future<List<Dispute>> disputes({DisputeStatus? status});

  /// Marks a dispute as being looked at.
  Future<Dispute> reviewDispute(String disputeId);

  /// Closes a dispute with a resolution note.
  Future<Dispute> resolveDispute(
    String disputeId,
    DisputeStatus status, {
    String notes,
  });

  Future<List<VerificationRequest>> verificationRequests({
    VerificationStatus? status,
  });

  Future<VerificationRequest> reviewVerification(
    String requestId,
    VerificationStatus decision, {
    String note,
  });
}

/// Error type for admin console actions.
class AdminFailure implements Exception {
  const AdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
