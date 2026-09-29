import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/job.dart';
import '../models/job_draft.dart';
import '../services/api/api_exception.dart';
import '../services/repositories/job_repository.dart';

/// Loading state shared by data-driven screens.
enum LoadState { idle, loading, ready, error }

/// Jobs shown to workers (feed, search, saved) plus saved-job toggling.
class JobFeedProvider extends ChangeNotifier {
  JobFeedProvider({required JobRepository repository})
    : _repository = repository;

  final JobRepository _repository;

  LoadState _state = LoadState.idle;
  List<Job> _jobs = <Job>[];
  List<Job> _saved = <Job>[];
  String? _error;

  LoadState get state => _state;
  List<Job> get jobs => _jobs;
  List<Job> get savedJobs => _saved;
  String? get error => _error;
  bool get isLoading => _state == LoadState.loading;
  bool get hasError => _state == LoadState.error;
  bool get isEmpty => _state == LoadState.ready && _jobs.isEmpty;

  /// Loads the feed. The delay only exists so the skeleton is not skipped on a
  /// fast connection; it is not a data source.
  Future<void> load({Duration delay = Duration.zero}) async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      _jobs = await _repository.activeJobs();
      _state = LoadState.ready;
    } on ApiException catch (failure) {
      _error = failure.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Could not load jobs';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadSaved() async {
    try {
      final List<String> ids = await _repository.savedJobIds();
      final List<Job> all = _jobs.isEmpty
          ? await _repository.activeJobs()
          : _jobs;
      _saved = all.where((Job job) => ids.contains(job.id)).toList();
      notifyListeners();
    } catch (_) {
      _saved = <Job>[];
    }
  }

  Future<void> retry() => load();

  Future<List<Job>> recommended(int limit) =>
      _repository.recommendedJobs(limit);

  Future<List<Job>> nearby(int limit) => _repository.nearbyJobs(limit);

  Future<List<Job>> search(JobFilter filter, JobSort sort) =>
      _repository.searchJobs(filter, sort);

  Future<Job> jobById(String id) => _repository.jobById(id);

  bool isSaved(String jobId) => _saved.any((Job job) => job.id == jobId);

  Future<void> toggleSaved(Job job) async {
    await _repository.toggleSaved(job.id);
    await loadSaved();
  }

  /// Publishes a job from the create-job wizard. [JobDraft] is what the wizard
  /// collects; the backend returns the stored job.
  Future<Job> publish(JobDraft draft, {required bool publishImmediately}) =>
      _repository.createJob(draft, publishImmediately: publishImmediately);

  Future<Job> setStatus(String jobId, JobStatus status) =>
      _repository.updateJobStatus(jobId, status);
}
