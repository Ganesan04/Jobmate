import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/mappers.dart';
import '../../api/wire.dart';
import '../user_repository.dart';

/// [UserRepository] backed by the auth, profile and verification endpoints.
class ApiUserRepository implements UserRepository {
  ApiUserRepository(this._api);

  final ApiClient _api;

  /// Cached so the shell does not refetch the profile on every rebuild. Reset by
  /// [signIn] and [signOut].
  UserProfile? _current;

  @override
  Future<UserProfile?> currentUser() async {
    if (_current != null) return _current;
    if (_api.hasSession == false) return null;
    try {
      final Map<String, dynamic> body = await _api.get('/api/v1/profile/me');
      final Map<String, dynamic> profile = body.dataMap();
      _current = Mappers.userProfile(profile.object('user'));
      return _current;
    } on ApiException {
      return null;
    }
  }

  @override
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/auth/login',
      body: <String, dynamic>{
        'identifier': identifier.trim(),
        'password': password,
      },
      authenticated: false,
    );
    return _adopt(body.dataMap());
  }

  @override
  Future<UserProfile?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String area = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/auth/register',
      body: jsonBody(<String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'area': area.trim(),
      }, nulls: <String>{'email', 'area'}),
      authenticated: false,
    );
    // The account exists but is unverified, so there is no usable session yet;
    // the caller continues to the OTP step.
    final Map<String, dynamic> auth = body.dataMap();
    if (auth.flag('requiresOtpVerification')) return null;
    return _adopt(auth);
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/auth/verify-otp',
      body: <String, dynamic>{'phone': phone.trim(), 'code': otp.trim()},
      authenticated: false,
    );
    return _adopt(body.dataMap());
  }

  @override
  Future<void> resendOtp({required String phone}) => _api.post(
    '/api/v1/auth/resend-otp',
    body: <String, dynamic>{
      'phone': phone.trim(),
      'purpose': 'phoneVerification',
    },
    authenticated: false,
  );

  @override
  Future<void> forgotPassword({required String phone}) => _api.post(
    '/api/v1/auth/forgot-password',
    body: <String, dynamic>{'phone': phone.trim()},
    authenticated: false,
  );

  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) => _api.post(
    '/api/v1/auth/reset-password',
    body: <String, dynamic>{
      'phone': phone.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    },
    // Every session is revoked server-side, so the stored pair is dropped.
    authenticated: false,
  );

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String area,
    required List<String> skills,
  }) async {
    // The shared fields (name, phone, area, skills) live on the worker profile
    // endpoint; the giver endpoint covers organisation details only.
    final Map<String, dynamic> body = await _api.put(
      '/api/v1/profile/worker',
      body: jsonBody(<String, dynamic>{
        'location': area.trim(),
        'skills': skills,
      }, nulls: <String>{'location'}),
    );
    final Map<String, dynamic> updated = body.dataMap();
    final UserProfile merged = Mappers.userProfile(<String, dynamic>{
      ...updated.object('user'),
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'area': area.trim(),
      'skills': skills,
      // `PUT /profile/worker` echoes the worker row, whose `user` is the
      // authoritative profile; fall back to the cached one when absent.
      ..._current == null ? const <String, dynamic>{} : _profileOverrides(),
    });
    return _cache(merged);
  }

  @override
  Future<UserProfile> switchRole(UserRole role) async {
    // The backend answers with a fresh token pair whose role claim is the new
    // mode, so it is adopted exactly like a sign-in.
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/auth/switch-role',
      body: <String, dynamic>{'role': wireUserRole(role)},
    );
    return _adopt(body.dataMap());
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post('/api/v1/auth/logout');
    } on ApiException {
      // A failed revoke must not trap the user in a signed-in state.
    }
    await _api.clearSession();
    _current = null;
  }

  @override
  Future<WorkGiverProfile> giverProfile() async {
    final Map<String, dynamic> body = await _api.get('/api/v1/profile/me');
    return Mappers.workGiverProfile(body.dataMap().object('giver'));
  }

  @override
  Future<VerificationSummary> verificationSummary() async {
    final Map<String, dynamic> body = await _api.get(
      '/api/v1/verifications/summary',
    );
    return Mappers.verificationSummary(body.dataMap());
  }

  @override
  Future<List<VerificationRecord>> verificationRecords() async {
    final Map<String, dynamic> body = await _api.get('/api/v1/verifications');
    return body
        .dataMap()
        .objects('requests')
        .map(Mappers.verificationRecord)
        .toList();
  }

  @override
  Future<VerificationRecord> startVerification(
    VerificationType type, {
    String documentName = '',
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/verifications',
      body: jsonBody(<String, dynamic>{
        'type': wireVerificationType(type),
        'documentName': documentName.trim(),
      }, nulls: <String>{'documentName'}),
    );
    return Mappers.verificationRecord(body.dataMap());
  }

  @override
  Future<void> withdrawVerification(String requestId) =>
      _api.post('/api/v1/verifications/$requestId/withdraw');

  @override
  Future<void> setPresence({required bool isOnline}) => _api.put(
    '/api/v1/profile/presence',
    body: <String, dynamic>{'isOnline': isOnline},
  );

  @override
  Future<HelpPreference> helpPreference() async => const HelpPreference();

  // ------------------------------------------------------------- internals

  /// Stores the tokens from an `AuthResultDto` and returns the signed-in user.
  Future<UserProfile> _adopt(Map<String, dynamic> auth) async {
    await _api.adoptSession(auth);
    return _cache(Mappers.authenticatedUser(auth));
  }

  /// Keeps the fields the API cannot change through this call site.
  Map<String, dynamic> _profileOverrides() => <String, dynamic>{
    'isOnline': _current?.isOnline ?? false,
    'rating': _current?.rating ?? 0,
    'jobsCompleted': _current?.jobsCompleted ?? 0,
    'role': _current?.role.name,
  };

  UserProfile _cache(UserProfile profile) {
    _current = profile;
    return profile;
  }
}
