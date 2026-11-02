import '../../models/application.dart';
import '../../models/enums.dart';

/// Applications, applicants, assignments, work history and ratings.
///
/// Implemented against `/api/v1/jobs/{id}/apply`, `/api/v1/applications/*`,
/// `/api/v1/assignments/*`, `/api/v1/ratings` and the worker/giver work-history
/// endpoints.
abstract class ApplicationRepository {
  Future<List<JobApplication>> applicationsForWorker(String workerId);

  Future<JobApplication> apply({
    required String jobId,
    required String workerId,
    String message,
    int? expectedPay,
    required String availability,
  });

  Future<JobApplication?> applicationFor(String jobId, String workerId);

  /// The worker's live application for a job, ignoring withdrawn, rejected and
  /// expired rows. Returns null when the job can still be applied to.
  Future<JobApplication?> activeApplicationFor(String jobId, String workerId);

  Future<void> withdrawApplication(String applicationId);

  /// Nudges workers who have not checked in yet.
  Future<int> remindWorkers(String jobId);

  Future<List<JobApplicant>> applicantsForJob(String jobId);

  /// Moves an applicant to shortlisted or rejected. Selecting is handled by
  /// [selectWorker] because it creates a booking.
  Future<JobApplicant> updateApplicantStatus(
    String applicantId,
    ApplicantStatus status,
  );

  /// Offers a different pay to one applicant.
  Future<JobApplicant> proposePay(String applicantId, int pay);

  /// Books one applicant, taking a slot on the job.
  Future<WorkerAssignment> selectWorker({
    required String applicationId,
    int? agreedPay,
  });

  /// Books several applicants in one call, releasing the shortlists that were
  /// not chosen.
  Future<List<WorkerAssignment>> selectWorkers({
    required String jobId,
    required Map<String, int> agreedPays,
  });

  Future<List<WorkerAssignment>> assignmentsForWorker(String workerId);

  Future<List<WorkerAssignment>> assignmentsForJob(String jobId);

  /// The 4-digit code a worker reads out on arrival.
  ///
  /// Giver-only: the backend never returns this to the worker, because a worker
  /// who could read their own code could check in unsupervised. The worker
  /// screen therefore asks for the code instead of calling this.
  Future<String> checkInCode(String jobId, String assignmentId);

  /// Checks a worker in with the code the giver read out. Duplicate check-ins
  /// are rejected. The code is single use.
  Future<WorkerAssignment> checkIn(String assignmentId, String code);

  Future<WorkerAssignment> markCompleted(
    String assignmentId, {
    int? overtimeAmount,
  });

  Future<List<WorkHistoryEntry>> workHistory(String workerId);

  // ------------------------------------------------------------- ratings

  /// Records feedback about the other participant in a completed job.
  ///
  /// One rating per person per job, so a repeat call answers 409; callers use
  /// [hasGivenRating] to check first.
  Future<WorkerRating> rate({
    required String jobId,
    required String toUserId,
    required int stars,
    String feedback,
  });

  /// Ratings the caller received, newest first. [toUserId] reads someone
  /// else's and [jobId] narrows to a single job.
  Future<List<WorkerRating>> ratings({String? toUserId, String? jobId});
}
