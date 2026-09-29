import '../../models/enums.dart';
import '../../models/job.dart';
import '../../models/job_draft.dart';

/// Read + write access to job listings.
///
/// Implemented against `GET/POST /api/v1/jobs` and the worker's saved-job
/// endpoints; the app depends only on this interface.
abstract class JobRepository {
  /// Active, published jobs visible to workers.
  Future<List<Job>> activeJobs();

  /// Every job created by the signed-in giver (drafts, active, closed).
  Future<List<Job>> jobsByGiver(String giverId);

  Future<Job> jobById(String id);

  Future<List<Job>> searchJobs(JobFilter filter, JobSort sort);

  /// Creates a job from the six-step wizard. When [publishImmediately] is true
  /// the job goes straight to `active`, otherwise it is left as a draft.
  Future<Job> createJob(JobDraft draft, {required bool publishImmediately});

  /// Edits an existing job. Only the fields carried by [draft] are sent.
  Future<Job> updateJob(String jobId, JobDraft draft);

  /// Drives the job lifecycle. `draft` and `expired` are server-driven and are
  /// rejected here; use [deleteJob] to remove a draft.
  Future<Job> updateJobStatus(String jobId, JobStatus status);

  /// Removes a draft.
  Future<void> deleteJob(String jobId);

  Future<List<String>> savedJobIds();

  /// Bookmarks or un-bookmarks a job. Returns true when it is now saved.
  Future<bool> toggleSaved(String jobId);

  Future<List<Job>> recommendedJobs(int limit);

  Future<List<Job>> nearbyJobs(int limit);
}
