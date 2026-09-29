import 'package:flutter/foundation.dart';

import '../models/application.dart';
import '../models/earning.dart';
import '../models/enums.dart';
import '../models/job.dart';
import '../services/api/api_exception.dart';
import '../services/repositories/application_repository.dart';
import '../services/repositories/earning_repository.dart';
import 'job_feed_provider.dart';

/// Everything the worker tabs need: applications, bookings, check-in, earnings.
class WorkerProvider extends ChangeNotifier {
  WorkerProvider({
    required ApplicationRepository applicationRepository,
    required EarningRepository earningRepository,
  }) : _applications = applicationRepository,
       _earnings = earningRepository;

  final ApplicationRepository _applications;
  final EarningRepository _earnings;

  LoadState _state = LoadState.idle;
  String? _error;
  List<JobApplication> _myApplications = <JobApplication>[];
  List<WorkerAssignment> _assignments = <WorkerAssignment>[];
  List<Earning> _earningList = <Earning>[];
  List<WorkHistoryEntry> _history = <WorkHistoryEntry>[];
  int _totalEarned = 0;
  int _pendingAmount = 0;
  int _disputedAmount = 0;
  String _workerId = 'u-worker-1';

  LoadState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;
  List<JobApplication> get applications => _myApplications;
  List<WorkerAssignment> get assignments => _assignments;
  List<Earning> get earnings => _earningList;
  List<WorkHistoryEntry> get history => _history;
  int get totalEarned => _totalEarned;
  int get pendingAmount => _pendingAmount;
  int get disputedAmount => _disputedAmount;
  String get workerId => _workerId;

  void setWorkerId(String id) {
    if (id == _workerId) return;
    _workerId = id;
  }

  /// Applications that ended in an acceptance — the worker's "bookings".
  List<WorkerAssignment> get activeAssignments => _assignments
      .where((WorkerAssignment a) => a.paymentStatus != PaymentStatus.paid)
      .toList();

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      await Future.wait<void>([
        _loadApplications(),
        _loadAssignments(),
        _loadEarnings(),
        _loadHistory(),
      ]);
      _state = LoadState.ready;
    } on ApiException catch (failure) {
      _error = failure.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Could not load your work data';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> retry() => load();

  Future<void> _loadApplications() async {
    _myApplications = await _applications.applicationsForWorker(_workerId);
  }

  Future<void> _loadAssignments() async {
    _assignments = await _applications.assignmentsForWorker(_workerId);
  }

  Future<void> _loadEarnings() async {
    _earningList = await _earnings.allEarnings(_workerId);
    _totalEarned = await _earnings.totalEarned(_workerId);
    _pendingAmount = await _earnings.pendingAmount(_workerId);
    _disputedAmount = await _earnings.disputedAmount(_workerId);
  }

  Future<void> _loadHistory() async {
    _history = await _applications.workHistory(_workerId);
  }

  WorkerStats get stats => WorkerStats(
    applied: _myApplications.length,
    active: _assignments
        .where((WorkerAssignment a) => !a.isCheckedIn && a.completedAt == null)
        .length,
    completed: _history.length,
    earnings: _totalEarned,
  );

  List<JobApplication> applicationsByStatus(List<ApplicationStatus> statuses) =>
      _myApplications
          .where((JobApplication a) => statuses.contains(a.status))
          .toList();

  Future<JobApplication?> applicationForJob(String jobId) =>
      _applications.applicationFor(jobId, _workerId);

  /// Applies to a job. Returns the created application, or null if the worker
  /// already has a live application for it or the call failed.
  Future<JobApplication?> apply({
    required Job job,
    required String message,
    int? expectedPay,
    required String availability,
  }) async {
    try {
      // Guard here as well as in the UI so a repeated action cannot create a
      // second application for the same job.
      final JobApplication? existing = await _applications.activeApplicationFor(
        job.id,
        _workerId,
      );
      if (existing != null) return null;

      final JobApplication created = await _applications.apply(
        jobId: job.id,
        workerId: _workerId,
        message: message,
        expectedPay: expectedPay,
        availability: availability,
      );
      _myApplications = <JobApplication>[created, ..._myApplications];
      notifyListeners();
      return created;
    } catch (_) {
      return null;
    }
  }

  /// True when the worker already has a live application for the job.
  Future<bool> hasActiveApplication(String jobId) async {
    final JobApplication? existing = await _applications.activeApplicationFor(
      jobId,
      _workerId,
    );
    return existing != null;
  }

  Future<void> withdraw(JobApplication application) async {
    await _applications.withdrawApplication(application.id);
    await _loadApplications();
    notifyListeners();
  }

  /// Single check-in per assignment. Returns an error message on failure.
  Future<String?> checkIn(WorkerAssignment assignment, String code) async {
    try {
      await _applications.checkIn(assignment.id, code);
      await _loadAssignments();
      notifyListeners();
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Check-in failed. Please try again.';
    }
  }

  /// Closes a checked in shift. Returns an error message on failure.
  Future<String?> completeShift(WorkerAssignment assignment) async {
    try {
      await _applications.markCompleted(assignment.id);
      await _loadAssignments();
      await _loadEarnings();
      notifyListeners();
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not mark the shift complete. Please try again.';
    }
  }

  Future<List<Earning>> earningsFiltered(PaymentStatus? status) =>
      _earnings.earningsByStatus(_workerId, status);

  Future<List<EarningSummary>> monthlySummary() =>
      _earnings.monthlySummary(_workerId);
}
