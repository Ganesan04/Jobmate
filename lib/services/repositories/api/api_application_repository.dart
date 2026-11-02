import '../../../models/application.dart';
import '../../../models/enums.dart';
import '../../api/api_client.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../application_repository.dart';
import 'api_query.dart';

/// [ApplicationRepository] backed by the jobs, applications and assignments
/// endpoints.
class ApiApplicationRepository implements ApplicationRepository {
  ApiApplicationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<JobApplication>> applicationsForWorker(String workerId) async {
    // The worker is derived from the access token, so [workerId] is not sent.
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/applications',
      query: pageArgs(),
    );
    return body.dataList(Mappers.jobApplication);
  }

  @override
  Future<JobApplication> apply({
    required String jobId,
    required String workerId,
    String message = '',
    int? expectedPay,
    required String availability,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/jobs/$jobId/apply',
      body: jsonBody(<String, dynamic>{
        'message': message.trim(),
        'expectedPay': expectedPay,
        'availableFrom': availability.trim(),
      }, nulls: <String>{'expectedPay', 'message'}),
    );
    return Mappers.jobApplication(body.dataMap());
  }

  @override
  Future<JobApplication?> applicationFor(String jobId, String workerId) async {
    // There is no "application by job" endpoint, so the worker's applications
    // are scanned. The page size covers a worker's realistic history.
    final List<JobApplication> all = await applicationsForWorker(workerId);
    for (final JobApplication application in all) {
      if (application.jobId == jobId) return application;
    }
    return null;
  }

  @override
  Future<JobApplication?> activeApplicationFor(
    String jobId,
    String workerId,
  ) async {
    final JobApplication? application = await applicationFor(jobId, workerId);
    if (application == null) return null;
    if (application.status.isTerminal) return null;
    return application;
  }

  @override
  Future<void> withdrawApplication(String applicationId) =>
      _api.post('/api/v1/applications/$applicationId/withdraw');

  @override
  Future<int> remindWorkers(String jobId) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/jobs/$jobId/remind',
    );
    return body.dataMap().integer('remindedCount');
  }

  @override
  Future<List<JobApplicant>> applicantsForJob(String jobId) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/jobs/$jobId/applications',
      query: pageArgs(),
    );
    return body.dataList(Mappers.jobApplicant);
  }

  @override
  Future<JobApplicant> updateApplicantStatus(
    String applicantId,
    ApplicantStatus status,
  ) async {
    // Selection is a separate flow that produces an assignment, so it is not
    // reachable through this method.
    if (status == ApplicantStatus.selected) {
      throw StateError('Use selectWorker to book an applicant.');
    }
    // There is no endpoint to move a shortlisted applicant back to `applied`.
    // `selectWorkers` releases the shortlists that were not chosen, which is how
    // the API expects that reversal to happen.
    if (status == ApplicantStatus.applied) {
      throw StateError(
        'A shortlist can only be cleared by confirming a selection.',
      );
    }
    final String path = switch (status) {
      ApplicantStatus.shortlisted =>
        '/api/v1/applications/$applicantId/shortlist',
      ApplicantStatus.rejected => '/api/v1/applications/$applicantId/reject',
      ApplicantStatus.applied || ApplicantStatus.selected =>
        throw StateError('unreachable'),
    };
    final Map<String, dynamic> body = await _api.post(path);
    return _applicantFromApplication(body.dataMap(), applicantId);
  }

  @override
  Future<JobApplicant> proposePay(String applicantId, int pay) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/applications/$applicantId/shortlist',
      body: <String, dynamic>{'proposedPay': pay},
    );
    return _applicantFromApplication(body.dataMap(), applicantId);
  }

  @override
  Future<WorkerAssignment> selectWorker({
    required String applicationId,
    int? agreedPay,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/applications/$applicationId/select',
      body: jsonBody(<String, dynamic>{'agreedPay': agreedPay},
          nulls: <String>{'agreedPay'}),
    );
    return Mappers.workerAssignment(body.dataMap());
  }

  @override
  Future<List<WorkerAssignment>> selectWorkers({
    required String jobId,
    required Map<String, int> agreedPays,
  }) async {
    // `selections` is a map of applicantId -> agreed pay, not a list of objects.
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/jobs/$jobId/select-workers',
      body: <String, dynamic>{
        'selections': <String, dynamic>{
          for (final MapEntry<String, int> entry in agreedPays.entries)
            entry.key: entry.value,
        },
        'releaseUnselectedShortlists': true,
      },
    );
    return body
        .dataMap()
        .objects('selected')
        .map(Mappers.workerAssignment)
        .toList();
  }

  @override
  Future<List<WorkerAssignment>> assignmentsForWorker(String workerId) async {
    // The signed-in worker's bookings are the worker work-history feed.
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/work-history',
      query: pageArgs(),
    );
    return _assignmentsFromHistory(body.dataList((Map<String, dynamic> j) => j));
  }

  @override
  Future<List<WorkerAssignment>> assignmentsForJob(String jobId) async {
    // Applicants carry the booking state, which is the only per-job view the
    // API offers to a giver.
    final List<JobApplicant> applicants = await applicantsForJob(jobId);
    return <WorkerAssignment>[
      for (final JobApplicant applicant in applicants)
        if (applicant.status == ApplicantStatus.selected)
          WorkerAssignment(
            id: applicant.id,
            jobId: jobId,
            workerId: applicant.worker.id,
            giverId: '',
            agreedPay: applicant.proposedPay ?? applicant.expectedPay ?? 0,
            confirmedAt: applicant.appliedAt ?? DateTime.now(),
            paymentStatus: PaymentStatus.pending,
          ),
    ];
  }

  @override
  Future<String> checkInCode(String jobId, String assignmentId) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/jobs/$jobId/check-in-code/$assignmentId',
    );
    return body.dataString();
  }

  @override
  Future<WorkerAssignment> checkIn(String assignmentId, String code) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/assignments/$assignmentId/check-in',
      body: <String, dynamic>{'code': code.trim()},
    );
    return Mappers.workerAssignment(body.dataMap());
  }

  @override
  Future<WorkerAssignment> markCompleted(
    String assignmentId, {
    int? overtimeAmount,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/assignments/$assignmentId/complete',
      body: jsonBody(<String, dynamic>{'overtimeAmount': overtimeAmount},
          nulls: <String>{'overtimeAmount'}),
    );
    return Mappers.workerAssignment(body.dataMap());
  }

  @override
  Future<List<WorkHistoryEntry>> workHistory(String workerId) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/work-history',
      query: pageArgs(),
    );
    return body.dataList(Mappers.workHistoryEntry);
  }

  // ------------------------------------------------------------- ratings

  @override
  Future<WorkerRating> rate({
    required String jobId,
    required String toUserId,
    required int stars,
    String feedback = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/ratings',
      body: jsonBody(<String, dynamic>{
        'jobId': jobId,
        'toUserId': toUserId,
        'stars': stars,
        'feedback': feedback.trim(),
      }, nulls: <String>{'feedback'}),
    );
    return Mappers.workerRating(body.dataMap());
  }

  @override
  Future<List<WorkerRating>> ratings({String? toUserId, String? jobId}) async {
    final Map<String, Object?> query = <String, Object?>{...pageArgs()};
    if (toUserId != null) query['toUserId'] = toUserId;
    if (jobId != null) query['jobId'] = jobId;
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/ratings',
      query: query,
    );
    return body.dataList(Mappers.workerRating);
  }

  // ------------------------------------------------------------- internals

  /// The shortlist/reject endpoints answer with a `JobApplicationDto`, but the
  /// caller works with a `JobApplicant`, so the fields the UI needs are carried
  /// across from the response.
  JobApplicant _applicantFromApplication(
    Map<String, dynamic> application,
    String applicantId,
  ) {
    final Map<String, dynamic> worker =
        application.objectOrNull('worker') ?? const <String, dynamic>{};
    return JobApplicant(
      id: application.str('id', applicantId),
      jobId: application.str('jobId'),
      worker: Mappers.userProfile(worker),
      status: applicantStatusFromWire(application['status']),
      proposedPay: application.intOrNull('proposedPay'),
      message: application.str('message'),
      appliedAt: application.date('appliedAt'),
      expectedPay: application.intOrNull('expectedPay'),
    );
  }

  /// Rebuilds bookings from the work-history feed, which is the only place the
  /// API reports a worker's own assignments.
  ///
  /// `WorkHistoryEntryDto` carries no check-in code, `checkedInAt` or agreed pay
  /// as separate fields, so those are left at their defaults: the UI treats a
  /// missing code as "the giver has not opened the booking yet" and never shows
  /// the worker a code of their own.
  List<WorkerAssignment> _assignmentsFromHistory(
    List<Map<String, dynamic>> rows,
  ) => <WorkerAssignment>[
    for (final Map<String, dynamic> row in rows)
      WorkerAssignment(
        id: row.str('id'),
        jobId: row.str('jobId'),
        workerId: '',
        giverId: '',
        agreedPay: row.integer('earnings'),
        confirmedAt: row.dateOr('date', DateTime.now()),
        paymentStatus: paymentStatusFromWire(row['paymentStatus']),
        completedAt: row.date('date'),
      ),
  ];
}
