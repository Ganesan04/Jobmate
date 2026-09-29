import 'package:flutter/foundation.dart';

import '../models/admin.dart';
import '../models/application.dart';
import '../models/enums.dart';
import '../models/job.dart';
import '../models/job_draft.dart';
import '../services/api/api_exception.dart';
import '../services/repositories/application_repository.dart';
import '../services/repositories/earning_repository.dart';
import '../services/repositories/job_repository.dart';
import 'job_feed_provider.dart';

/// Work giver state: own jobs, applicants, selection, payments and ratings.
class GiverProvider extends ChangeNotifier {
  GiverProvider({
    required ApplicationRepository repository,
    required JobRepository jobRepository,
    required EarningRepository earningRepository,
  }) : _repository = repository,
       _jobs = jobRepository,
       _earnings = earningRepository;

  final ApplicationRepository _repository;
  final JobRepository _jobs;
  final EarningRepository _earnings;

  String _giverId = 'u-giver-1';

  LoadState _state = LoadState.idle;
  String? _error;
  List<Job> _myJobs = <Job>[];
  List<JobApplicant> _applicants = <JobApplicant>[];
  Map<String, List<JobApplicant>> _applicantsByJob =
      <String, List<JobApplicant>>{};
  final Map<String, int> _pendingSelections = <String, int>{};
  final List<PaymentReceipt> _receipts = <PaymentReceipt>[];
  final List<WorkerRating> _ratings = <WorkerRating>[];
  final Set<String> _rated = <String>{};

  LoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;
  List<Job> get myJobs => _myJobs;
  List<JobApplicant> get applicants => _applicants;
  List<PaymentReceipt> get receipts => _receipts;
  String get giverId => _giverId;

  void setGiverId(String id) {
    if (id == _giverId) return;
    _giverId = id;
  }

  /// Loads the giver's own jobs and, for each one, its applicants.
  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _myJobs = await _fetchJobs();
      _applicants = <JobApplicant>[];
      _applicantsByJob = <String, List<JobApplicant>>{};
      for (final Job job in _myJobs) {
        final List<JobApplicant> list = await _repository.applicantsForJob(
          job.id,
        );
        _applicantsByJob[job.id] = list;
        _applicants = <JobApplicant>[..._applicants, ...list];
      }
      _state = LoadState.ready;
    } on ApiException catch (failure) {
      _error = failure.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Could not load your jobs';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<List<Job>> _fetchJobs() => _jobs.jobsByGiver(_giverId);

  Future<void> retry() => load();

  List<Job> jobsWithStatus(JobStatus status) =>
      _myJobs.where((Job job) => job.status == status).toList();

  List<Job> get activeJobs => jobsWithStatus(JobStatus.active);

  List<Job> get inProgressJobs => jobsWithStatus(JobStatus.inProgress);

  List<Job> get draftJobs => jobsWithStatus(JobStatus.draft);

  int get completedCount => jobsWithStatus(JobStatus.completed).length;

  int get cancelledCount => jobsWithStatus(JobStatus.cancelled).length;

  int get totalApplicants =>
      _applicants.where((JobApplicant a) => a.status.isOpen).length;

  int get toConfirm => _applicants
      .where((JobApplicant a) => a.status == ApplicantStatus.shortlisted)
      .length;

  int get totalHired => _applicants
      .where((JobApplicant a) => a.status == ApplicantStatus.selected)
      .length;

  int get spentThisMonth => _receipts.fold<int>(
    0,
    (int sum, PaymentReceipt r) =>
        r.paidAt.month == DateTime.now().month ? sum + r.amount : sum,
  );

  GiverStats get stats => GiverStats(
    activeJobs: activeJobs.length,
    applications: totalApplicants,
    toConfirm: toConfirm,
    totalHired: totalHired,
    spentThisMonth: spentThisMonth,
  );

  List<JobApplicant> applicantsForJob(String jobId) =>
      _applicantsByJob[jobId] ?? <JobApplicant>[];

  Job jobById(String id) => _myJobs.firstWhere(
    (Job job) => job.id == id,
    orElse: () => _myJobs.first,
  );

  int selectedCount(String jobId) => applicantsForJob(
    jobId,
  ).where((JobApplicant a) => a.status == ApplicantStatus.selected).length;

  /// Publishes a job built by the multi-step create-job wizard.
  Future<Job> publishDraft(JobDraft draft, {required bool publishImmediately}) async {
    final Job job = await _jobs.createJob(
      draft,
      publishImmediately: publishImmediately,
    );
    final int index = _myJobs.indexWhere((Job j) => j.id == job.id);
    if (index == -1) {
      _myJobs = <Job>[job, ..._myJobs];
    } else {
      _myJobs = <Job>[..._myJobs]..[index] = job;
    }
    _applicantsByJob[job.id] = <JobApplicant>[];
    notifyListeners();
    return job;
  }

  /// Moves a job through its lifecycle on the backend and mirrors the result.
  Future<Job?> setJobStatus(String jobId, JobStatus status) async {
    final int index = _myJobs.indexWhere((Job job) => job.id == jobId);
    if (index == -1) return null;
    try {
      final Job updated = await _jobs.updateJobStatus(jobId, status);
      _myJobs = <Job>[..._myJobs]..[index] = updated;
      notifyListeners();
      return updated;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return null;
    }
  }

  /// Marks a job completed once every selected worker is paid.
  Future<void> completeJob(String jobId) async {
    await setJobStatus(jobId, JobStatus.completed);
  }

  Future<void> deleteDraft(String jobId) async {
    try {
      await _jobs.deleteJob(jobId);
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return;
    }
    _myJobs = _myJobs.where((Job job) => job.id != jobId).toList();
    notifyListeners();
  }

  Future<JobApplicant> updateApplicant(
    String id,
    ApplicantStatus status,
  ) async {
    final JobApplicant updated = await _repository.updateApplicantStatus(
      id,
      status,
    );
    _syncApplicant(updated);
    notifyListeners();
    return updated;
  }

  Future<JobApplicant> proposePay(String id, int pay) async {
    final JobApplicant updated = await _repository.proposePay(id, pay);
    _syncApplicant(updated);
    notifyListeners();
    return updated;
  }

  void _syncApplicant(JobApplicant updated) {
    final List<JobApplicant> list = <JobApplicant>[
      for (final JobApplicant a in _applicants)
        if (a.id == updated.id) updated else a,
    ];
    _applicants = list;
    _applicantsByJob[updated.jobId] = applicantsForJob(
      updated.jobId,
    ).map((JobApplicant a) => a.id == updated.id ? updated : a).toList();
  }

  void rememberPendingSelection(String jobId, int count) {
    _pendingSelections[jobId] = count;
    notifyListeners();
  }

  int pendingSelection(String jobId) => _pendingSelections[jobId] ?? 0;

  /// Confirms a selection and books every chosen worker in one call. The
  /// backend also releases the shortlists that were not chosen.
  Future<List<WorkerAssignment>> confirmSelection({
    required String jobId,
    required Map<String, int> agreedPays,
  }) async {
    if (agreedPays.isEmpty) return <WorkerAssignment>[];

    final List<WorkerAssignment> created = await _repository.selectWorkers(
      jobId: jobId,
      agreedPays: agreedPays,
    );

    // Reflect the selection locally without a full reload, marking the chosen
    // applicants selected and the rest back to applied.
    final Set<String> chosen = agreedPays.keys.toSet();
    final List<JobApplicant> updated = <JobApplicant>[
      for (final JobApplicant applicant in applicantsForJob(jobId))
        if (chosen.contains(applicant.id))
          applicant.copyWith(
            status: ApplicantStatus.selected,
            proposedPay: agreedPays[applicant.id],
          )
        else if (applicant.status == ApplicantStatus.shortlisted)
          applicant.copyWith(status: ApplicantStatus.applied)
        else
          applicant,
    ];
    _applicantsByJob[jobId] = updated;
    _applicants = <JobApplicant>[
      for (final JobApplicant applicant in _applicants)
        if (applicant.jobId != jobId)
          applicant
        else
          updated.firstWhere(
            (JobApplicant a) => a.id == applicant.id,
            orElse: () => applicant,
          ),
    ];

    final int index = _myJobs.indexWhere((Job j) => j.id == jobId);
    if (index != -1) {
      final Job job = _myJobs[index];
      final int filled = updated
          .where((JobApplicant a) => a.status == ApplicantStatus.selected)
          .length;
      _myJobs = <Job>[..._myJobs]..[index] = job.copyWith(
        workersFilled: filled,
        status: filled >= job.workersNeeded
            ? JobStatus.inProgress
            : job.status,
      );
    }
    notifyListeners();
    return created;
  }

  /// Pays a confirmed worker.
  ///
  /// The backend credits the worker wallet and closes the assignment in one
  /// call. The idempotency key is derived from job and worker, so a double tap
  /// or a retry returns the first receipt instead of paying twice.
  Future<PaymentReceipt> pay({
    required String jobId,
    required String workerId,
    required int basePay,
    required int overtime,
    required PaymentMethod method,
  }) async {
    final PaymentReceipt receipt = await _earnings.releasePayment(
      jobId: jobId,
      workerId: workerId,
      basePay: basePay,
      overtime: overtime,
      method: method,
      idempotencyKey: 'pay-$jobId-$workerId',
    );
    _receipts
      ..removeWhere((PaymentReceipt r) => r.paymentId == receipt.paymentId)
      ..insert(0, receipt);
    await load();
    return receipt;
  }

  // ----------------------------------------------------------------- ratings

  /// Sends feedback about a worker on a completed job.
  ///
  /// The API only accepts one rating per person per job and only after the job
  /// is completed, so a 409 is reported as a message rather than thrown.
  Future<bool> rateWorker({
    required String jobId,
    required String workerId,
    required int stars,
    String feedback = '',
  }) async {
    try {
      final WorkerRating rating = await _repository.rate(
        jobId: jobId,
        toUserId: workerId,
        stars: stars,
        feedback: feedback,
      );
      _ratings
        ..removeWhere(
          (WorkerRating r) => r.jobId == jobId && r.workerId == workerId,
        )
        ..insert(0, rating);
      _rated.add('$jobId:$workerId');
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  /// Ratings this giver has already left, read from the server so the rate sheet
  /// opens pre-disabled.
  Future<void> loadRatings(String jobId) async {
    try {
      final List<WorkerRating> rows = await _repository.ratings(jobId: jobId);
      for (final WorkerRating row in rows) {
        // Only rows where this account is the giver count as "already rated".
        if (row.giverId == _giverId && row.workerId.isNotEmpty) {
          _rated.add('${row.jobId}:${row.workerId}');
        }
      }
      notifyListeners();
    } on ApiException {
      // Leave the sheet open if the history call fails.
    }
  }

  bool hasRated(String jobId, String workerId) =>
      _rated.contains('$jobId:$workerId');
}
