import '../../../core/constants/app_config.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../../models/job_draft.dart';
import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../job_repository.dart';
import 'api_query.dart';

/// [JobRepository] backed by the Jobmate jobs endpoints.
class ApiJobRepository implements JobRepository {
  ApiJobRepository(this._api);

  final ApiClient _api;

  /// Bookmarked job ids, loaded on demand and kept in step with each toggle.
  Set<String>? _savedCache;

  @override
  Future<List<Job>> activeJobs() => _search(<String, Object?>{
    'Statuses': <String>[wireJobStatus(JobStatus.active)],
  });

  @override
  Future<List<Job>> jobsByGiver(String giverId) async {
    // The giver is derived from the access token, so [giverId] is not sent.
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/giver/jobs',
      query: pageArgs(),
    );
    return body.dataList(Mappers.job);
  }

  @override
  Future<Job> jobById(String id) async {
    final Map<String, dynamic> body = await _api.get('/api/v1/jobs/$id');
    return Mappers.job(body.dataMap());
  }

  @override
  Future<List<Job>> searchJobs(JobFilter filter, JobSort sort) =>
      _search(_filterQuery(filter, sort));

  @override
  Future<Job> createJob(
    JobDraft draft, {
    required bool publishImmediately,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/jobs',
      body: <String, dynamic>{
        ..._draftBody(draft),
        'publishImmediately': publishImmediately,
      },
    );
    return Mappers.job(body.dataMap());
  }

  @override
  Future<Job> updateJob(String jobId, JobDraft draft) async {
    final Map<String, dynamic> body = await _api.put(
      '/api/v1/jobs/$jobId',
      body: _draftBody(draft),
    );
    return Mappers.job(body.dataMap());
  }

  @override
  Future<Job> updateJobStatus(String jobId, JobStatus status) async {
    // Each lifecycle step is its own endpoint on the backend.
    final (String path, Map<String, dynamic> body) = switch (status) {
      JobStatus.active => ('/api/v1/jobs/$jobId/publish', const <String, dynamic>{}),
      JobStatus.inProgress => (
        '/api/v1/jobs/$jobId/start',
        const <String, dynamic>{},
      ),
      JobStatus.completed => (
        '/api/v1/jobs/$jobId/complete',
        const <String, dynamic>{},
      ),
      JobStatus.cancelled => (
        '/api/v1/jobs/$jobId/cancel',
        <String, dynamic>{'refundPayments': false},
      ),
      JobStatus.pending ||
      JobStatus.draft ||
      JobStatus.expired => throw ApiException(
        message: 'A job cannot be moved to ${status.label} from here.',
      ),
    };
    final Map<String, dynamic> response = await _api.post(path, body: body);
    return Mappers.job(response.dataMap());
  }

  @override
  Future<void> deleteJob(String jobId) => _api.delete('/api/v1/jobs/$jobId');

  @override
  Future<List<String>> savedJobIds() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/worker/saved-jobs',
      query: pageArgs(pageSize: 200),
    );
    final Set<String> ids = <String>{
      for (final Map<String, dynamic> row in body.dataList(
        (Map<String, dynamic> json) => json,
      ))
        if (row.object('job').str('id').isNotEmpty) row.object('job').str('id'),
    };
    _savedCache = ids;
    return ids.toList();
  }

  @override
  Future<bool> toggleSaved(String jobId) async {
    // The bookmark state is read once and then tracked locally, so a toggle
    // costs a single request instead of a list-then-write round trip.
    final Set<String> saved = _savedCache ?? (await savedJobIds()).toSet();
    if (saved.contains(jobId)) {
      await _api.delete('/api/v1/worker/saved-jobs/$jobId');
      saved.remove(jobId);
    } else {
      await _api.post('/api/v1/worker/saved-jobs/$jobId');
      saved.add(jobId);
    }
    _savedCache = saved;
    return saved.contains(jobId);
  }

  @override
  Future<List<Job>> recommendedJobs(int limit) => _search(<String, Object?>{
    'Statuses': <String>[wireJobStatus(JobStatus.active)],
    'SortBy': 'applicants',
    'Descending': true,
    'Take': limit,
  });

  @override
  Future<List<Job>> nearbyJobs(int limit) => _search(<String, Object?>{
    'Statuses': <String>[wireJobStatus(JobStatus.active)],
    'SortBy': 'distanceKm',
    'Take': limit,
  });

  // ------------------------------------------------------------- internals

  Future<List<Job>> _search(Map<String, Object?> query) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/jobs',
      query: <String, Object?>{...pageArgs(pageSize: ApiConfig.defaultPageSize), ...query},
    );
    return body.dataList(Mappers.job);
  }

  /// Translates the search screen's filter object into query parameters.
  Map<String, Object?> _filterQuery(JobFilter filter, JobSort sort) =>
      <String, Object?>{
        if (filter.query.trim().isNotEmpty) 'Search': filter.query.trim(),
        if (filter.categories.isNotEmpty)
          'Categories': <String>[
            for (final JobCategory c in filter.categories) wireJobCategory(c),
          ],
        if (filter.date != null) 'StartDate': wireDate(filter.date!),
        if (filter.minPay != null) 'MinPay': filter.minPay,
        if (filter.maxPay != null) 'MaxPay': filter.maxPay,
        if (filter.maxDistanceKm != null) 'RadiusKm': filter.maxDistanceKm,
        if (filter.jobType != null) 'JobType': wireJobType(filter.jobType!),
        if (filter.verifiedOnly) 'VerifiedGiverOnly': true,
        if (filter.urgentOnly) 'UrgentOnly': true,
        'SortBy': wireJobSortBy(sort),
        'Descending': wireJobSortDescending(sort),
      };

  /// Builds the `CreateJobRequest` / `UpdateJobRequest` payload.
  ///
  /// `company` and `giverId` are deliberately absent: the backend derives them
  /// from the access token.
  Map<String, dynamic> _draftBody(JobDraft draft) => jsonBody(
    <String, dynamic>{
      'title': draft.title.trim(),
      'category': wireJobCategory(draft.category ?? JobCategory.other),
      'description': draft.description.trim(),
      'workersNeeded': draft.workersNeeded,
      'skills': draft.skills,
      'experience': draft.experience.trim(),
      'date': wireDate(draft.date ?? DateTime.now().add(const Duration(days: 1))),
      'startTime': wireTimeOfDay(draft.startTime ?? '09:00 AM'),
      'endTime': wireTimeOfDay(draft.endTime ?? '06:00 PM'),
      'reportTime': wireTimeOfDay(draft.reportTime ?? '08:45 AM'),
      'isRecurring': draft.isRecurring,
      if (draft.isRecurring)
        'weekdays': <int>[
          for (final WorkDay day in draft.weekdays) wireWorkDayNumber(day),
        ],
      'breakMinutes': draft.breakMinutes,
      'pay': draft.pay,
      'payType': wirePayType(draft.payType),
      'overtimeRate': draft.overtimeRate,
      'travelAllowance': draft.travelAllowance,
      'foodAllowance': draft.foodAllowance,
      'paymentDate': draft.paymentDate == null
          ? null
          : wireDate(draft.paymentDate!),
      'paymentMethod': wirePaymentMethod(draft.paymentMethod),
      'area': draft.area.trim(),
      'address': draft.address.trim(),
      'workplaceType': wireWorkplaceType(draft.workplaceType),
      'locationVisible': draft.locationVisible,
      'contactPerson': draft.contactPerson.trim(),
      'safetyInfo': draft.safetyInfo.trim(),
      'physicalRequirement': draft.physicalRequirement.trim(),
      'dressCode': draft.dressCode.trim(),
      'vehicleRequired': draft.vehicleRequired,
      'emergencyContact': draft.emergencyContact.trim(),
    },
    // These must be sent as explicit nulls so a partial edit clears them.
    nulls: <String>{'overtimeRate', 'paymentDate'},
  );
}
