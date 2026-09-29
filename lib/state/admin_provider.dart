import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/admin.dart';
import '../models/enums.dart';
import '../services/repositories/admin_repository.dart';
import 'job_feed_provider.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({required AdminRepository repository})
    : _repository = repository;

  final AdminRepository _repository;

  bool _signedIn = false;
  bool _busy = false;
  String? _error;

  LoadState _dashboardState = LoadState.idle;
  AdminStats _stats = const AdminStats();

  LoadState _usersState = LoadState.idle;
  List<AdminUser> _users = <AdminUser>[];
  String _email = '';
  String _userQuery = '';
  UserRole? _userRole;
  VerificationStatus? _userVerification;

  LoadState _disputesState = LoadState.idle;
  List<Dispute> _disputes = <Dispute>[];
  DisputeStatus? _disputeFilter;

  LoadState _verificationsState = LoadState.idle;
  List<VerificationRequest> _verifications = <VerificationRequest>[];
  VerificationStatus? _verificationFilter;

  bool get signedIn => _signedIn;
  String get email => _email;
  bool get busy => _busy;
  String? get error => _error;
  AdminStats get stats => _stats;
  LoadState get dashboardState => _dashboardState;
  List<AdminUser> get users => _users;
  String get userQuery => _userQuery;
  UserRole? get userRole => _userRole;
  VerificationStatus? get userVerification => _userVerification;
  LoadState get usersState => _usersState;
  List<Dispute> get disputes => _disputes;
  DisputeStatus? get disputeFilter => _disputeFilter;
  LoadState get disputesState => _disputesState;
  List<VerificationRequest> get verifications => _verifications;
  VerificationStatus? get verificationFilter => _verificationFilter;
  LoadState get verificationsState => _verificationsState;

  int get pendingVerifications => _verifications
      .where((VerificationRequest v) => v.status == VerificationStatus.pending)
      .length;

  int get openDisputes => _disputes
      .where(
        (Dispute d) =>
            d.status == DisputeStatus.open ||
            d.status == DisputeStatus.underReview,
      )
      .length;

  Future<bool> signIn({required String email, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.signIn(email: email, password: password);
      _signedIn = true;
      _email = email.trim();
      _busy = false;
      notifyListeners();
      return true;
    } on AdminFailure catch (failure) {
      _error = failure.message;
      _busy = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to sign in. Try again.';
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  /// Drops the console session right away; revoking the token on the server
  /// happens in the background and never blocks the sign-out.
  void signOut() {
    unawaited(_repository.signOut());
    _signedIn = false;
    _email = '';
    _error = null;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _dashboardState = LoadState.loading;
    notifyListeners();
    try {
      _stats = await _repository.stats();
      _dashboardState = LoadState.ready;
    } catch (_) {
      _dashboardState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadUsers({bool showLoader = true}) async {
    if (showLoader) {
      _usersState = LoadState.loading;
      notifyListeners();
    }
    try {
      _users = await _repository.users(
        query: _userQuery,
        role: _userRole,
        verification: _userVerification,
      );
      _usersState = LoadState.ready;
    } catch (_) {
      _usersState = LoadState.error;
    }
    notifyListeners();
  }

  void setUserQuery(String value) {
    if (_userQuery == value) return;
    _userQuery = value;
    unawaited(loadUsers(showLoader: false));
  }

  void setUserRole(UserRole? role) {
    if (_userRole == role) return;
    _userRole = role;
    unawaited(loadUsers(showLoader: false));
  }

  void setUserVerification(VerificationStatus? status) {
    if (_userVerification == status) return;
    _userVerification = status;
    unawaited(loadUsers(showLoader: false));
  }

  Future<void> setUserActive(String userId, bool active) async {
    await _repository.setUserActive(userId, active);
    await loadUsers(showLoader: false);
  }

  Future<void> loadDisputes() async {
    _disputesState = LoadState.loading;
    notifyListeners();
    try {
      _disputes = await _repository.disputes(status: _disputeFilter);
      _disputesState = LoadState.ready;
    } catch (_) {
      _disputesState = LoadState.error;
    }
    notifyListeners();
  }

  void setDisputeFilter(DisputeStatus? status) {
    if (_disputeFilter == status) return;
    _disputeFilter = status;
    unawaited(loadDisputes());
  }

  Future<String?> resolveDispute(
    String id,
    DisputeStatus status, {
    String notes = '',
  }) async {
    try {
      await _repository.resolveDispute(id, status, notes: notes);
      await loadDisputes();
      await loadDashboard();
      return null;
    } on AdminFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Could not update the dispute';
    }
  }

  Future<void> loadVerifications() async {
    _verificationsState = LoadState.loading;
    notifyListeners();
    try {
      _verifications = await _repository.verificationRequests(
        status: _verificationFilter,
      );
      _verificationsState = LoadState.ready;
    } catch (_) {
      _verificationsState = LoadState.error;
    }
    notifyListeners();
  }

  void setVerificationFilter(VerificationStatus? status) {
    if (_verificationFilter == status) return;
    _verificationFilter = status;
    unawaited(loadVerifications());
  }

  Future<String?> reviewVerification(
    String id,
    VerificationStatus decision, {
    String note = '',
  }) async {
    try {
      await _repository.reviewVerification(id, decision, note: note);
      await loadVerifications();
      await loadDashboard();
      return null;
    } on AdminFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Could not update the request';
    }
  }
}
