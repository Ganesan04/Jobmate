import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/token_store.dart';
import '../services/repositories/user_repository.dart';

/// Top level app stage — drives which entry flow is shown.
enum AppStage { splash, onboarding, auth, profileSetup, ready }

/// Owns the session: onboarding, credentials, OTP, profile setup and the
/// worker / work giver mode switch.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required UserRepository repository, TokenStore? tokens})
    : _repository = repository,
      _tokens = tokens;

  final UserRepository _repository;

  /// Local persistence for the onboarding flag. Null in tests that do not need
  /// it, in which case the flag is session-scoped.
  final TokenStore? _tokens;

  AppStage _stage = AppStage.splash;
  UserProfile? _user;
  bool _busy = false;
  String? _error;
  String? _pendingPhone;
  String _pendingArea = '';
  bool _onboardingSeen = false;
  final Map<VerificationType, VerificationRecord> _verifications =
      <VerificationType, VerificationRecord>{};

  AppStage get stage => _stage;
  UserProfile? get user => _user;
  bool get busy => _busy;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _stage == AppStage.ready;
  bool get onboardingSeen => _onboardingSeen;

  /// The active mode. Every account is both a worker and a work giver; this
  /// only decides which experience is shown.
  UserRole get role => _user?.role ?? UserRole.worker;

  // ---------------------------------------------------------- verification

  /// Cached verification rows, refreshed from the API on demand.
  List<VerificationRecord> get verifications =>
      VerificationType.values
          .map(
            (VerificationType type) =>
                _verifications[type] ??
                VerificationRecord(
                  type: type,
                  status: VerificationStatus.notVerified,
                  note: _seedNoteFor(type),
                ),
          )
          .toList();

  VerificationStatus statusOf(VerificationType type) =>
      verifications.firstWhere((VerificationRecord r) => r.type == type).status;

  VerificationSummary get verificationSummary => VerificationSummary(
    identity: statusOf(VerificationType.identity),
    phone: statusOf(VerificationType.phone),
    email: statusOf(VerificationType.email),
    skills: statusOf(VerificationType.skills),
  );

  /// Pulls the badge and its history from the API.
  Future<void> loadVerifications() async {
    try {
      final List<VerificationRecord> records = await _repository
          .verificationRecords();
      _verifications
        ..clear()
        ..addEntries(
          records.map(
            (VerificationRecord r) => MapEntry<VerificationType, VerificationRecord>(
              r.type,
              r,
            ),
          ),
        );
      notifyListeners();
    } on ApiException {
      // Keep the last known rows rather than blanking the screen.
    }
  }

  /// Submits one kind of check. The backend approves it on submission, and the
  /// result applies to the account in both modes.
  Future<bool> submitVerification(
    VerificationType type, {
    String documentName = '',
  }) async {
    return _guard(() async {
      final VerificationRecord record = await _repository.startVerification(
        type,
        documentName: documentName,
      );
      _verifications[type] = record;
      notifyListeners();
      return true;
    });
  }

  String _seedNoteFor(VerificationType type) {
    switch (type) {
      case VerificationType.phone:
        return 'Verified with OTP';
      case VerificationType.email:
        return _user != null && _user!.email.isNotEmpty
            ? 'Link sent to your email'
            : 'Add an email address to verify';
      case VerificationType.identity:
        return 'Upload a government photo ID';
      case VerificationType.skills:
        return 'List your skills to get verified';
      case VerificationType.address:
        return 'Add your address to unlock nearby jobs';
    }
  }

  /// Restores a stored session on launch, otherwise falls through to onboarding.
  Future<void> bootstrap() async {
    _onboardingSeen = _tokens?.onboardingSeen ?? false;
    final UserProfile? session = await _repository.currentUser();
    _user = session;
    if (session != null) {
      _stage = AppStage.ready;
      unawaited(loadVerifications());
    } else {
      _stage = _onboardingSeen ? AppStage.auth : AppStage.onboarding;
    }
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingSeen = true;
    unawaited(_tokens?.setOnboardingSeen(true) ?? Future<void>.value());
    _stage = AppStage.auth;
    notifyListeners();
  }

  /// Lets the user re-run onboarding from Settings.
  Future<void> replayOnboarding() async {
    _onboardingSeen = false;
    await _tokens?.setOnboardingSeen(false);
    _stage = AppStage.onboarding;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------- login

  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    return _guard(() async {
      final UserProfile signedIn = await _repository.signIn(
        identifier: identifier,
        password: password,
      );
      // The backend remembers the last active mode, so the app mirrors it
      // rather than overlaying a locally chosen one.
      _user = signedIn;
      _stage = AppStage.ready;
      return true;
    });
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _pendingPhone = phone;
    notifyListeners();
    return _guard(() async {
      await _repository.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        area: _pendingArea,
      );
      // Stage stays `auth` until the OTP is verified so the OTP route can be
      // pushed on top of the current one; [verifyOtp] then moves to profile setup.
      return true;
    });
  }

  Future<bool> verifyOtp(String otp) async {
    return _guard(() async {
      _user = await _repository.verifyOtp(
        phone: _pendingPhone ?? _user?.phone ?? '',
        otp: otp,
      );
      // A new account can both work and hire, so there is no role to pick: it
      // goes straight to its profile and starts in worker mode.
      _stage = AppStage.profileSetup;
      return true;
    });
  }

  Future<void> resendOtp() async {
    _error = null;
    notifyListeners();
    final String phone = _pendingPhone ?? _user?.phone ?? '';
    if (phone.isEmpty) return;
    try {
      await _repository.resendOtp(phone: phone);
    } on AuthFailure catch (failure) {
      _error = failure.message;
      notifyListeners();
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
    }
  }

  /// Starts the password reset flow. The API answers the same way whether or not
  /// the phone is registered, so there is nothing to surface to the user here.
  Future<bool> requestPasswordReset(String phone) async {
    return _guard(() async {
      await _repository.forgotPassword(phone: phone);
      return true;
    });
  }

  Future<bool> setPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    if (password.length < 8) {
      _error = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }
    return _guard(() async {
      await _repository.resetPassword(
        phone: phone,
        code: code,
        newPassword: password,
      );
      return true;
    });
  }

  // ----------------------------------------------------------- profile set

  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String email,
    required String area,
    required List<String> skills,
  }) async {
    return _guard(() async {
      _pendingArea = area;
      _user = await _repository.updateProfile(
        name: name,
        phone: phone,
        email: email,
        area: area,
        skills: skills,
      );
      _stage = AppStage.ready;
      return true;
    });
  }

  // ------------------------------------------------------------- role switch

  /// Moves the account between the worker and work giver experiences. The
  /// backend stores the active mode and reissues the session for it.
  Future<bool> switchRole(UserRole next) async {
    if (_user == null || _user!.role == next) return false;
    return _guard(() async {
      _user = await _repository.switchRole(next);
      return _user!.role == next;
    });
  }

  // ------------------------------------------------------------------ signout

  Future<void> signOut() async {
    await _repository.signOut();
    _dropSession();
  }

  /// The refresh token was rejected, so the stored tokens are already gone.
  /// Returns to the sign-in screen without another API call. Ignored outside
  /// [AppStage.ready], where [bootstrap] or the entry flow owns the stage.
  void expireSession() {
    if (_stage != AppStage.ready) return;
    _dropSession();
    _error = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  void _dropSession() {
    _user = null;
    _verifications.clear();
    _stage = _onboardingSeen ? AppStage.auth : AppStage.onboarding;
    _error = null;
    notifyListeners();
  }

  /// Re-applies a locally edited profile (used after editing from the Profile tab).
  void applyProfileUpdate(UserProfile profile) {
    _user = profile;
    notifyListeners();
  }

  /// Surfaces an API failure on the current screen. Used by actions that report
  /// their own success/failure rather than going through [_guard].
  void reportError(Object failure) {
    _error = switch (failure) {
      AuthFailure e => e.message,
      ApiException e => e.message,
      _ => 'Something went wrong. Please try again.',
    };
    notifyListeners();
  }

  Future<bool> _guard(Future<bool> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final bool result = await action();
      _busy = false;
      notifyListeners();
      return result;
    } on AuthFailure catch (failure) {
      _busy = false;
      _error = failure.message;
      notifyListeners();
      return false;
    } on ApiException catch (failure) {
      _busy = false;
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (_) {
      _busy = false;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
