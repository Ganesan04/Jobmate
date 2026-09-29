import '../../../models/admin.dart';
import '../../../models/enums.dart';
import '../../../models/job.dart';
import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../admin_repository.dart';
import 'api_query.dart';

/// [AdminRepository] backed by the admin console endpoints.
class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._api);

  final ApiClient _api;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/admin/auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
      authenticated: false,
    );
    await _api.adoptSession(body.dataMap());
    return true;
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post('/api/v1/auth/logout');
    } on ApiException {
      // A failed revoke must not trap the admin in a signed-in state.
    }
    await _api.clearSession();
  }

  @override
  Future<AdminStats> stats() async {
    final Map<String, dynamic> body = await _api.get('/api/v1/admin/dashboard');
    return Mappers.adminStats(body.dataMap());
  }

  @override
  Future<List<AdminUser>> users({
    String query = '',
    UserRole? role,
    VerificationStatus? verification,
  }) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/admin/users',
      query: <String, Object?>{
        ...pageArgs(),
        if (query.trim().isNotEmpty) 'Search': query.trim(),
        if (role != null) 'Role': wireUserRole(role),
        if (verification != null)
          'Verification': wireVerificationStatus(verification),
      },
    );
    return body.dataList(Mappers.adminUser);
  }

  @override
  Future<void> setUserActive(
    String userId,
    bool isActive, {
    String reason = '',
  }) => _api.post(
    '/api/v1/admin/users/$userId/status',
    body: jsonBody(<String, dynamic>{
      'isActive': isActive,
      'reason': reason.trim(),
    }, nulls: <String>{'reason'}),
  );

  @override
  Future<List<Job>> jobs({
    String query = '',
    JobStatus? status,
    JobCategory? category,
  }) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/admin/jobs',
      query: <String, Object?>{
        ...pageArgs(),
        if (query.trim().isNotEmpty) 'Search': query.trim(),
        if (status != null) 'Status': wireJobStatus(status),
        if (category != null) 'Category': wireJobCategory(category),
      },
    );
    return body.dataList(_adminJob);
  }

  @override
  Future<void> remindApplicants(String jobId) =>
      _api.post('/api/v1/jobs/$jobId/remind');

  @override
  Future<List<Dispute>> disputes({DisputeStatus? status}) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/admin/disputes',
      query: <String, Object?>{
        ...pageArgs(),
        if (status != null) 'Status': wireDisputeStatus(status),
      },
    );
    return body.dataList(Mappers.dispute);
  }

  @override
  Future<Dispute> reviewDispute(String disputeId) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/admin/disputes/$disputeId/review',
    );
    return Mappers.dispute(body.dataMap());
  }

  @override
  Future<Dispute> resolveDispute(
    String disputeId,
    DisputeStatus status, {
    String notes = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/admin/disputes/$disputeId/resolve',
      body: jsonBody(<String, dynamic>{
        'status': wireDisputeStatus(status),
        'resolution': notes.trim(),
      }, nulls: <String>{'resolution'}),
    );
    return Mappers.dispute(body.dataMap());
  }

  @override
  Future<List<VerificationRequest>> verificationRequests({
    VerificationStatus? status,
  }) async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/admin/verifications',
      query: <String, Object?>{
        ...pageArgs(),
        if (status != null) 'Status': wireVerificationStatus(status),
      },
    );
    return body.dataList(Mappers.verificationRequest);
  }

  @override
  Future<VerificationRequest> reviewVerification(
    String requestId,
    VerificationStatus decision, {
    String note = '',
  }) async {
    final bool approve = decision == VerificationStatus.verified;
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/admin/verifications/$requestId/'
      '${approve ? 'approve' : 'reject'}',
      body: jsonBody(<String, dynamic>{
        'note': note.trim(),
        if (!approve) 'rejectionReason': note.trim(),
      }, nulls: <String>{'note', 'rejectionReason'}),
    );
    return Mappers.verificationRequest(body.dataMap());
  }

  // ------------------------------------------------------------- internals

  /// `AdminJobDto` is a slimmer job row than `JobDto`, so it is projected onto
  /// the full [Job] shape with the fields the admin jobs table reads.
  Job _adminJob(Map<String, dynamic> json) => Job(
    id: json.str('id'),
    title: json.str('title'),
    company: json.str('company'),
    giverId: json.str('giverId'),
    category: jobCategoryFromWire(json['category']),
    description: '',
    date: json.dateOr('jobDate', DateTime.now()),
    startTime: '',
    endTime: '',
    reportTime: '',
    pay: json.integer('pay'),
    payType: payTypeFromWire(json['payType']),
    workersNeeded: json.integer('workersNeeded'),
    workersFilled: json.integer('workersFilled'),
    area: json.str('area'),
    address: '',
    applicants: json.integer('applicants'),
    skills: const <String>[],
    experience: '',
    distanceKm: 0,
    status: jobStatusFromWire(json['status']),
    createdAt: json.date('createdAt'),
  );
}
