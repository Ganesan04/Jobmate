import 'package:jobmate/models/admin.dart';
import 'package:jobmate/models/application.dart';
import 'package:jobmate/models/earning.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/job.dart';
import 'package:jobmate/models/job_draft.dart';
import 'package:jobmate/models/messaging.dart';
import 'package:jobmate/models/support.dart';
import 'package:jobmate/models/user.dart';
import 'package:jobmate/services/repositories/admin_repository.dart';
import 'package:jobmate/services/repositories/application_repository.dart';
import 'package:jobmate/services/repositories/earning_repository.dart';
import 'package:jobmate/services/repositories/help_repository.dart';
import 'package:jobmate/services/repositories/job_repository.dart';
import 'package:jobmate/services/repositories/messaging_repository.dart';
import 'package:jobmate/services/repositories/notification_repository.dart';
import 'package:jobmate/services/repositories/user_repository.dart';
import 'package:jobmate/services/service_locator.dart';

import 'fixtures.dart';

/// An in-memory stand-in for the whole data layer.
///
/// The fakes share one store, so a cross-repository effect stays consistent:
/// releasing a payment both closes the assignment and credits the worker
/// wallet, which is what the payment tests assert.
///
/// Filtering, sorting and search run here rather than in the providers, because
/// the providers now forward those parameters to the server. Implementing the
/// contract faithfully is what keeps the existing widget assertions meaningful.
class FakeStore {
  FakeStore()
    : accounts = <String, UserProfile>{
        for (final UserProfile p in Fixtures.members()) p.id: p,
      },
      adminUsers = Fixtures.adminUsers(),
      jobs = Fixtures.jobs(),
      applications = Fixtures.applications(),
      applicants = <String, JobApplicant>{
        for (final JobApplicant a in Fixtures.jobApplicants()) a.id: a,
      },
      assignments = Fixtures.assignments(),
      earnings = Fixtures.earnings(),
      history = Fixtures.workHistory(),
      conversations = Fixtures.conversations(),
      threads = Fixtures.threads(),
      notifications = Fixtures.notifications(),
      disputes = Fixtures.disputes(),
      verificationRequests = Fixtures.verificationRequests(),
      verifications = Fixtures.verifications();

  final Map<String, UserProfile> accounts;
  final List<AdminUser> adminUsers;
  final List<Job> jobs;
  final List<JobApplication> applications;
  final Map<String, JobApplicant> applicants;
  final List<WorkerAssignment> assignments;
  final List<Earning> earnings;
  final List<WorkHistoryEntry> history;
  final List<Conversation> conversations;
  final Map<String, List<Message>> threads;
  final List<AppNotification> notifications;
  final List<Dispute> disputes;
  final List<VerificationRequest> verificationRequests;
  final Map<String, Map<VerificationType, VerificationRecord>> verifications;

  final Set<String> _savedJobIds = <String>{};
  final Map<String, PaymentReceipt> _receiptsByKey = <String, PaymentReceipt>{};
  final List<PaymentReceipt> receipts = <PaymentReceipt>[];
  final List<WorkerRating> ratings = <WorkerRating>[];
  final List<SupportTicket> tickets = <SupportTicket>[];

  String? _sessionUserId;
  int _sequence = 100;

  String get actorId => _sessionUserId ?? Fixtures.defaultActorId;

  String nextId(String prefix) => '$prefix-${_sequence++}';

  UserProfile? get sessionUser {
    final String? id = _sessionUserId;
    return id == null ? null : accounts[id];
  }

  // ------------------------------------------------------------------ jobs

  Job jobById(String id) {
    for (final Job job in jobs) {
      if (job.id == id) return job;
    }
    throw StateError('No job with id $id');
  }

  Job _replaceJob(Job updated) {
    final int index = jobs.indexWhere((Job job) => job.id == updated.id);
    jobs[index] = updated;
    return updated;
  }

  String companyFor(String giverId) =>
      Fixtures.giverProfile(giverId).organisation;

  WorkerAssignment assignmentById(String id) {
    for (final WorkerAssignment a in assignments) {
      if (a.id == id) return a;
    }
    throw StateError('No assignment with id $id');
  }

  WorkerAssignment _replaceAssignment(WorkerAssignment updated) {
    final int index = assignments.indexWhere(
      (WorkerAssignment a) => a.id == updated.id,
    );
    assignments[index] = updated;
    return updated;
  }

  // -------------------------------------------------------------- earnings

  List<Earning> earningsFor(String workerId) => earnings
      .where((Earning e) => e.workerId == workerId)
      .toList();
}

/// Assembles the fake graph. Synchronous so a test can mount it inline.
AppRepositories buildFakeRepositories() {
  final FakeStore store = FakeStore();
  return AppRepositories.custom(
    jobs: _FakeJobRepository(store),
    applications: _FakeApplicationRepository(store),
    earnings: _FakeEarningRepository(store),
    messaging: _FakeMessagingRepository(store),
    notifications: _FakeNotificationRepository(store),
    users: _FakeUserRepository(store),
    admin: _FakeAdminRepository(store),
    help: _FakeHelpRepository(store),
  );
}

// ===================================================================== jobs

class _FakeJobRepository implements JobRepository {
  _FakeJobRepository(this._store);

  final FakeStore _store;

  List<Job> get _active =>
      _store.jobs.where((Job j) => j.status == JobStatus.active).toList();

  @override
  Future<List<Job>> activeJobs() async => _active;

  @override
  Future<List<Job>> jobsByGiver(String giverId) async => _store.jobs
      .where((Job job) => job.giverId == giverId)
      .toList();

  @override
  Future<Job> jobById(String id) async => _store.jobById(id);

  @override
  Future<List<Job>> searchJobs(JobFilter filter, JobSort sort) async {
    final String query = filter.query.trim().toLowerCase();
    final List<Job> result = _active.where((Job job) {
      if (query.isNotEmpty) {
        final bool matches =
            job.title.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query) ||
            job.company.toLowerCase().contains(query);
        if (!matches) return false;
      }
      if (filter.categories.isNotEmpty &&
          !filter.categories.contains(job.category)) {
        return false;
      }
      if (filter.date != null && !isSameDay(job.date, filter.date!)) {
        return false;
      }
      if (filter.minPay != null && job.pay < filter.minPay!) return false;
      if (filter.maxPay != null && job.pay > filter.maxPay!) return false;
      if (filter.maxDistanceKm != null &&
          job.distanceKm > filter.maxDistanceKm!) {
        return false;
      }
      if (filter.jobType != null && job.jobType != filter.jobType) {
        return false;
      }
      if (filter.urgentOnly && !job.isUrgent) return false;
      return true;
    }).toList();

    switch (sort) {
      case JobSort.newest:
        result.sort(
          (Job a, Job b) => b.date.compareTo(a.date),
        );
      case JobSort.payHigh:
        result.sort((Job a, Job b) => b.pay.compareTo(a.pay));
      case JobSort.payLow:
        result.sort((Job a, Job b) => a.pay.compareTo(b.pay));
      case JobSort.nearest:
        result.sort(
          (Job a, Job b) => a.distanceKm.compareTo(b.distanceKm),
        );
    }
    return result;
  }

  @override
  Future<Job> createJob(
    JobDraft draft, {
    required bool publishImmediately,
  }) async {
    final String giverId = _store.actorId;
    final DateTime now = DateTime.now();
    final Job job = Job(
      id: _store.nextId('j'),
      title: draft.title,
      company: _store.companyFor(giverId),
      giverId: giverId,
      category: draft.category ?? JobCategory.other,
      description: draft.description,
      date: draft.date ?? now,
      startTime: draft.startTime ?? '9:00 AM',
      endTime: draft.endTime ?? '6:00 PM',
      reportTime: draft.reportTime ?? '8:30 AM',
      pay: draft.pay ?? 0,
      payType: draft.payType,
      workersNeeded: draft.workersNeeded,
      workersFilled: 0,
      area: draft.area,
      address: draft.address,
      applicants: 0,
      skills: draft.skills,
      experience: draft.experience,
      distanceKm: 1.8,
      status: publishImmediately ? JobStatus.active : JobStatus.draft,
      breakMinutes: draft.breakMinutes,
      overtimeRate: draft.overtimeRate,
      travelAllowance: draft.travelAllowance,
      foodAllowance: draft.foodAllowance,
      paymentDate: draft.paymentDate,
      paymentMethod: draft.paymentMethod,
      isRecurring: draft.isRecurring,
      weekdays: draft.weekdays,
      workplaceType: draft.workplaceType,
      locationVisible: draft.locationVisible,
      contactPerson: draft.contactPerson,
      safetyInfo: draft.safetyInfo,
      physicalRequirement: draft.physicalRequirement,
      dressCode: draft.dressCode,
      vehicleRequired: draft.vehicleRequired,
      emergencyContact: draft.emergencyContact,
      createdAt: now,
    );
    _store.jobs.insert(0, job);
    return job;
  }

  @override
  Future<Job> updateJob(String jobId, JobDraft draft) async {
    final Job job = _store.jobById(jobId);
    return _store._replaceJob(
      job.copyWith(
        title: draft.title.isEmpty ? null : draft.title,
        description: draft.description.isEmpty ? null : draft.description,
        category: draft.category,
        pay: draft.pay,
        payType: draft.payType,
        workersNeeded: null,
        area: draft.area.isEmpty ? null : draft.area,
        address: draft.address.isEmpty ? null : draft.address,
        skills: draft.skills.isEmpty ? null : draft.skills,
      ),
    );
  }

  @override
  Future<Job> updateJobStatus(String jobId, JobStatus status) async =>
      _store._replaceJob(_store.jobById(jobId).copyWith(status: status));

  @override
  Future<void> deleteJob(String jobId) async {
    final Job job = _store.jobById(jobId);
    if (job.status != JobStatus.draft) {
      throw StateError('Only a draft can be deleted');
    }
    _store.jobs.removeWhere((Job j) => j.id == jobId);
  }

  @override
  Future<List<String>> savedJobIds() async => _store._savedJobIds.toList();

  @override
  Future<bool> toggleSaved(String jobId) async {
    if (!_store._savedJobIds.remove(jobId)) _store._savedJobIds.add(jobId);
    return _store._savedJobIds.contains(jobId);
  }

  @override
  Future<List<Job>> recommendedJobs(int limit) async =>
      _active.take(limit).toList();

  @override
  Future<List<Job>> nearbyJobs(int limit) async {
    final List<Job> sorted = <Job>[..._active]
      ..sort((Job a, Job b) => a.distanceKm.compareTo(b.distanceKm));
    return sorted.take(limit).toList();
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ============================================================= applications

class _FakeApplicationRepository implements ApplicationRepository {
  _FakeApplicationRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<JobApplication>> applicationsForWorker(String workerId) async =>
      _store.applications
          .where((JobApplication a) => a.workerId == workerId)
          .toList();

  @override
  Future<JobApplication> apply({
    required String jobId,
    required String workerId,
    String message = '',
    int? expectedPay,
    required String availability,
  }) async {
    final Job job = _store.jobById(jobId);
    final JobApplication created = JobApplication(
      id: _store.nextId('a'),
      jobId: jobId,
      workerId: workerId,
      message: message,
      expectedPay: expectedPay,
      availableFrom: availability,
      appliedAt: DateTime.now(),
    );
    _store.applications.insert(0, created);
    _store._replaceJob(
      job.copyWith(applicants: job.applicants + 1),
    );
    _store.applicants[created.id] = JobApplicant(
      id: created.id,
      jobId: jobId,
      worker: _store.accounts[workerId] ?? Fixtures.ravi(),
      message: message,
      expectedPay: expectedPay,
      appliedAt: DateTime.now(),
    );
    return created;
  }

  @override
  Future<JobApplication?> applicationFor(String jobId, String workerId) async {
    for (final JobApplication a in _store.applications.reversed) {
      if (a.jobId == jobId && a.workerId == workerId) return a;
    }
    return null;
  }

  @override
  Future<JobApplication?> activeApplicationFor(
    String jobId,
    String workerId,
  ) async {
    for (final JobApplication a in _store.applications.reversed) {
      if (a.jobId == jobId &&
          a.workerId == workerId &&
          !a.status.isTerminal) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> withdrawApplication(String applicationId) async {
    final int index = _store.applications.indexWhere(
      (JobApplication a) => a.id == applicationId,
    );
    if (index == -1) return;
    _store.applications[index] = _store.applications[index].copyWith(
      status: ApplicationStatus.withdrawn,
    );
  }

  @override
  Future<int> remindWorkers(String jobId) async => _store.assignments
      .where(
        (WorkerAssignment a) => a.jobId == jobId && a.checkedInAt == null,
      )
      .length;

  @override
  Future<List<JobApplicant>> applicantsForJob(String jobId) async =>
      _store.applicants.values
          .where((JobApplicant a) => a.jobId == jobId)
          .toList();

  @override
  Future<JobApplicant> updateApplicantStatus(
    String applicantId,
    ApplicantStatus status,
  ) async {
    final JobApplicant updated = _store.applicants[applicantId]!.copyWith(
      status: status,
    );
    _store.applicants[applicantId] = updated;
    return updated;
  }

  @override
  Future<JobApplicant> proposePay(String applicantId, int pay) async {
    final JobApplicant updated = _store.applicants[applicantId]!.copyWith(
      proposedPay: pay,
    );
    _store.applicants[applicantId] = updated;
    return updated;
  }

  @override
  Future<WorkerAssignment> selectWorker({
    required String applicationId,
    int? agreedPay,
  }) async {
    final List<WorkerAssignment> created = await selectWorkers(
      jobId: _store.applicants[applicationId]!.jobId,
      agreedPays: <String, int>{applicationId: agreedPay ?? 0},
    );
    return created.first;
  }

  @override
  Future<List<WorkerAssignment>> selectWorkers({
    required String jobId,
    required Map<String, int> agreedPays,
  }) async {
    final List<WorkerAssignment> created = <WorkerAssignment>[];
    for (final MapEntry<String, int> entry in agreedPays.entries) {
      final JobApplicant applicant = _store.applicants[entry.key]!;
      _store.applicants[entry.key] = applicant.copyWith(
        status: ApplicantStatus.selected,
        proposedPay: entry.value,
      );
      final WorkerAssignment assignment = WorkerAssignment(
        id: _store.nextId('as'),
        jobId: jobId,
        workerId: applicant.worker.id,
        giverId: _store.jobById(jobId).giverId,
        agreedPay: entry.value,
        confirmedAt: DateTime.now(),
        checkInCode: '4821',
      );
      _store.assignments.add(assignment);
      created.add(assignment);
    }
    // Shortlists that were not chosen are released back to applied.
    for (final JobApplicant applicant in _store.applicants.values.toList()) {
      if (applicant.jobId == jobId &&
          !agreedPays.containsKey(applicant.id) &&
          applicant.status == ApplicantStatus.shortlisted) {
        _store.applicants[applicant.id] = applicant.copyWith(
          status: ApplicantStatus.applied,
        );
      }
    }
    final Job job = _store.jobById(jobId);
    final int filled = _store.applicants.values
        .where(
          (JobApplicant a) =>
              a.jobId == jobId && a.status == ApplicantStatus.selected,
        )
        .length;
    _store._replaceJob(
      job.copyWith(
        workersFilled: filled,
        status: filled >= job.workersNeeded
            ? JobStatus.inProgress
            : job.status,
      ),
    );
    return created;
  }

  @override
  Future<List<WorkerAssignment>> assignmentsForWorker(String workerId) async =>
      _store.assignments
          .where((WorkerAssignment a) => a.workerId == workerId)
          .toList();

  @override
  Future<List<WorkerAssignment>> assignmentsForJob(String jobId) async =>
      _store.assignments
          .where((WorkerAssignment a) => a.jobId == jobId)
          .toList();

  @override
  Future<String> checkInCode(String jobId, String assignmentId) async {
    final String? code = _store.assignmentById(assignmentId).checkInCode;
    if (code == null) throw StateError('No check-in code for that shift');
    return code;
  }

  @override
  Future<WorkerAssignment> checkIn(String assignmentId, String code) async {
    final WorkerAssignment assignment = _store.assignmentById(assignmentId);
    if (assignment.isCheckedIn) {
      throw StateError('You have already checked in for this shift.');
    }
    if (assignment.checkInCode != code) {
      throw StateError('That check-in code is not correct.');
    }
    return _store._replaceAssignment(
      assignment.copyWith(
        checkedInAt: DateTime.now(),
        clearCheckInCode: true,
      ),
    );
  }

  @override
  Future<WorkerAssignment> markCompleted(
    String assignmentId, {
    int? overtimeAmount,
  }) async {
    final WorkerAssignment assignment = _store.assignmentById(assignmentId);
    if (!assignment.isCheckedIn) {
      throw StateError('Check in before completing the shift.');
    }
    if (assignment.completedAt != null) {
      throw StateError('This shift is already completed.');
    }
    return _store._replaceAssignment(
      assignment.copyWith(
        completedAt: DateTime.now(),
        paymentStatus: PaymentStatus.paid,
      ),
    );
  }

  @override
  Future<List<WorkHistoryEntry>> workHistory(String workerId) async {
    final List<WorkHistoryEntry> result = <WorkHistoryEntry>[
      for (final WorkHistoryEntry entry in _store.history)
        if (_store.assignments.any(
          (WorkerAssignment a) => a.id == entry.id && a.workerId == workerId,
        ))
          entry,
    ];
    for (final WorkerAssignment assignment in _store.assignments) {
      if (assignment.workerId != workerId || assignment.completedAt == null) {
        continue;
      }
      if (result.any((WorkHistoryEntry e) => e.id == assignment.id)) continue;
      final Job job = _store.jobById(assignment.jobId);
      result.add(
        WorkHistoryEntry(
          id: assignment.id,
          jobTitle: job.title,
          company: job.company,
          date: assignment.completedAt!,
          durationHours: 7.5,
          earnings: assignment.agreedPay,
          paymentStatus: assignment.paymentStatus,
        ),
      );
    }
    return result;
  }

  @override
  Future<WorkerRating> rate({
    required String jobId,
    required String toUserId,
    required int stars,
    String feedback = '',
  }) async {
    final String giverId = _store.jobById(jobId).giverId;
    final bool exists = _store.ratings.any(
      (WorkerRating r) => r.jobId == jobId && r.workerId == toUserId,
    );
    if (exists) {
      throw StateError('You have already rated this worker for this job.');
    }
    final WorkerRating rating = WorkerRating(
      id: _store.nextId('r'),
      jobId: jobId,
      workerId: toUserId,
      giverId: giverId,
      stars: stars,
      feedback: feedback,
      createdAt: DateTime.now(),
    );
    _store.ratings.insert(0, rating);
    return rating;
  }

  @override
  Future<List<WorkerRating>> ratings({String? toUserId, String? jobId}) async =>
      _store.ratings.where((WorkerRating r) {
        if (toUserId != null && r.workerId != toUserId) return false;
        if (jobId != null && r.jobId != jobId) return false;
        return true;
      }).toList();
}

// ================================================================ earnings

class _FakeEarningRepository implements EarningRepository {
  _FakeEarningRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<Earning>> allEarnings(String workerId) async =>
      _store.earningsFor(workerId);

  @override
  Future<List<Earning>> earningsByStatus(
    String workerId,
    PaymentStatus? status,
  ) async {
    final List<Earning> all = _store.earningsFor(workerId);
    if (status == null) return all;
    return all.where((Earning e) => e.status == status).toList();
  }

  @override
  Future<int> totalEarned(String workerId) async => _store
      .earningsFor(workerId)
      .where((Earning e) => e.status == PaymentStatus.paid)
      .fold<int>(0, (int sum, Earning e) => sum + e.amount);

  @override
  Future<int> pendingAmount(String workerId) async => _store
      .earningsFor(workerId)
      .where((Earning e) => e.status.isOutstanding)
      .fold<int>(0, (int sum, Earning e) => sum + e.amount);

  @override
  Future<int> disputedAmount(String workerId) async => _store
      .earningsFor(workerId)
      .where((Earning e) => e.status == PaymentStatus.disputed)
      .fold<int>(0, (int sum, Earning e) => sum + e.amount);

  @override
  Future<List<EarningSummary>> monthlySummary(String workerId) async {
    final Map<String, List<Earning>> grouped = <String, List<Earning>>{};
    for (final Earning e in _store.earningsFor(workerId)) {
      final String key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => <Earning>[]).add(e);
    }
    final List<String> keys = (grouped.keys.toList()..sort()).reversed.toList();
    return <EarningSummary>[
      for (final String key in keys)
        EarningSummary(
          month: key,
          earned: grouped[key]!
              .where((Earning e) => e.status == PaymentStatus.paid)
              .fold<int>(0, (int sum, Earning e) => sum + e.amount),
          pending: grouped[key]!
              .where((Earning e) => e.status.isOutstanding)
              .fold<int>(0, (int sum, Earning e) => sum + e.amount),
        ),
    ];
  }

  /// Credits the wallet and closes the assignment in one step. The idempotency
  /// key is what makes a double tap safe: the same key always returns the first
  /// receipt instead of paying again.
  @override
  Future<PaymentReceipt> releasePayment({
    required String jobId,
    required String workerId,
    required int basePay,
    required int overtime,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    final PaymentReceipt? existing = _store._receiptsByKey[idempotencyKey];
    if (existing != null) return existing;

    // A job can hold older assignments for the same worker, so pay the newest
    // open one rather than whichever fixture happens to come first.
    final List<WorkerAssignment> matching = _store.assignments
        .where(
          (WorkerAssignment a) =>
              a.jobId == jobId && a.workerId == workerId,
        )
        .toList();
    final WorkerAssignment? assignment = matching
        .where((WorkerAssignment a) => a.paymentStatus != PaymentStatus.paid)
        .lastOrNull;
    if (assignment == null && matching.isNotEmpty) {
      throw StateError('That shift has already been paid.');
    }

    final Job job = _store.jobById(jobId);
    final UserProfile? worker = _store.accounts[workerId];
    final DateTime now = DateTime.now();
    final PaymentReceipt receipt = PaymentReceipt(
      paymentId: _store.nextId('pay'),
      amount: basePay + overtime,
      method: method,
      paidAt: now,
      workerName: worker?.name ?? 'Worker',
      overtime: overtime,
    );
    _store._receiptsByKey[idempotencyKey] = receipt;
    _store.receipts.insert(0, receipt);

    _store.earnings.insert(
      0,
      Earning(
        id: _store.nextId('e'),
        workerId: workerId,
        assignmentId: assignment?.id,
        jobId: jobId,
        jobTitle: job.title,
        company: job.company,
        date: now,
        amount: receipt.amount,
        status: PaymentStatus.paid,
        paymentId: receipt.paymentId,
        method: method,
      ),
    );

    if (assignment != null) {
      _store._replaceAssignment(
        assignment.copyWith(
          paymentStatus: PaymentStatus.paid,
          paymentId: receipt.paymentId,
          paidAt: now,
        ),
      );
    }
    return receipt;
  }

  @override
  Future<PaymentReceipt> confirmPayment(
    String paymentId, {
    String? transactionReference,
  }) async {
    for (final PaymentReceipt receipt in _store.receipts) {
      if (receipt.paymentId == paymentId) return receipt;
    }
    throw StateError('No payment with id $paymentId');
  }

  @override
  Future<List<PaymentReceipt>> payments() async => _store.receipts;
}

// ================================================================ messaging

class _FakeMessagingRepository implements MessagingRepository {
  _FakeMessagingRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<Conversation>> conversations() async =>
      _store.conversations.toList();

  @override
  Future<List<Message>> messages(String conversationId) async =>
      _store.threads[conversationId]?.toList() ?? <Message>[];

  @override
  Future<Message> send(String conversationId, String text) async {
    final Message message = Message(
      id: _store.nextId('m'),
      conversationId: conversationId,
      text: text,
      sentAt: DateTime.now(),
      isMine: true,
    );
    _store.threads.putIfAbsent(conversationId, () => <Message>[]).add(message);
    final Conversation thread = _store.conversations.firstWhere(
      (Conversation c) => c.id == conversationId,
    );
    _store.conversations
      ..remove(thread)
      ..insert(
        0,
        thread.copyWith(lastMessage: text, lastMessageAt: message.sentAt),
      );
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final int index = _store.conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index == -1) return;
    _store.conversations[index] = _store.conversations[index].copyWith(
      unread: 0,
    );
  }

  @override
  Future<Conversation> startConversation({
    required String participantId,
    required String participantName,
    String jobContext = '',
    String? jobId,
  }) async {
    final Conversation created = Conversation(
      id: _store.nextId('c'),
      participantId: participantId,
      participantName: participantName,
      jobContext: jobContext,
      lastMessageAt: DateTime.now(),
    );
    _store.conversations.insert(0, created);
    _store.threads[created.id] = <Message>[];
    return created;
  }

  @override
  Future<void> archiveConversation(
    String conversationId, {
    bool archived = true,
  }) async => _store.conversations.removeWhere(
    (Conversation c) => c.id == conversationId,
  );

  @override
  Future<int> unreadMessageCount() async => _store.conversations.fold<int>(
    0,
    (int sum, Conversation c) => sum + c.unread,
  );
}

// ============================================================ notifications

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<AppNotification>> notifications() async =>
      _store.notifications.toList();

  @override
  Future<int> unreadCount() async =>
      _store.notifications.where((AppNotification n) => !n.isRead).length;

  @override
  Future<({int messages, int notifications})> unreadCounts() async {
    final int notifications = _store.notifications
        .where((AppNotification n) => !n.isRead)
        .length;
    final int messages = _store.conversations.fold<int>(
      0,
      (int sum, Conversation c) => sum + c.unread,
    );
    return (notifications: notifications, messages: messages);
  }

  @override
  Future<void> markAllRead() async {
    for (int i = 0; i < _store.notifications.length; i++) {
      _store.notifications[i] = _store.notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markRead(String id) async {
    final int index = _store.notifications.indexWhere(
      (AppNotification n) => n.id == id,
    );
    if (index == -1) return;
    _store.notifications[index] = _store.notifications[index].copyWith(
      isRead: true,
    );
  }
}

// ===================================================================== user

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this._store);

  final FakeStore _store;

  @override
  Future<UserProfile?> currentUser() async => _store.sessionUser;

  @override
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final String needle = identifier.trim().toLowerCase();
    UserProfile? match;
    for (final UserProfile profile in _store.accounts.values) {
      if (profile.phone == needle || profile.email.toLowerCase() == needle) {
        match = profile;
        break;
      }
    }
    if (match == null) {
      throw AuthFailure('We could not find an account for $identifier.');
    }
    if (password != Fixtures.memberPassword) {
      throw const AuthFailure('That password is not correct.');
    }
    _store._sessionUserId = match.id;
    return match;
  }

  @override
  Future<UserProfile?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
    String area = '',
  }) async {
    final UserProfile created = UserProfile(
      id: _store.nextId('u'),
      name: name,
      phone: phone,
      email: email,
      role: role,
      area: area,
    );
    _store.accounts[created.id] = created;
    _store.adminUsers.add(
      AdminUser(
        id: created.id,
        name: name,
        phone: phone,
        role: role,
        verification: VerificationStatus.notVerified,
        isActive: true,
        joinedOn: DateTime.now(),
        area: area,
      ),
    );
    return created;
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
  }) async {
    final UserProfile? existing = _store.accounts.values
        .where((UserProfile p) => p.phone == phone)
        .firstOrNull;
    final UserProfile verified =
        existing?.copyWith(role: role) ??
        UserProfile(id: _store.nextId('u'), name: '', phone: phone, role: role);
    _store.accounts[verified.id] = verified;
    _store._sessionUserId = verified.id;
    return verified;
  }

  @override
  Future<void> resendOtp({required String phone}) async {}

  @override
  Future<void> forgotPassword({required String phone}) async {}

  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String area,
    required List<String> skills,
  }) async {
    final String id = _store.actorId;
    final UserProfile updated = (_store.accounts[id] ?? Fixtures.ravi()).copyWith(
      name: name,
      phone: phone,
      email: email,
      area: area,
      skills: skills,
    );
    _store.accounts[id] = updated;
    return updated;
  }

  @override
  Future<UserRole> switchRole(UserRole role) async {
    final String id = _store.actorId;
    _store.accounts[id] = (_store.accounts[id] ?? Fixtures.ravi()).copyWith(role: role);
    return role;
  }

  @override
  Future<void> signOut() async => _store._sessionUserId = null;

  @override
  Future<WorkGiverProfile> giverProfile() async =>
      Fixtures.giverProfile(_store.actorId);

  @override
  Future<VerificationSummary> verificationSummary() async {
    VerificationStatus statusOf(VerificationType type) {
      final Map<VerificationType, VerificationRecord> rows =
          _store.verifications[_store.actorId] ??
          <VerificationType, VerificationRecord>{};
      return rows[type]?.status ?? VerificationStatus.notVerified;
    }

    return VerificationSummary(
      identity: statusOf(VerificationType.identity),
      phone: statusOf(VerificationType.phone),
      email: statusOf(VerificationType.email),
      skills: statusOf(VerificationType.skills),
    );
  }

  @override
  Future<List<VerificationRecord>> verificationRecords() async =>
      (_store.verifications[_store.actorId] ??
              <VerificationType, VerificationRecord>{})
          .values
          .toList();

  @override
  Future<VerificationRecord> startVerification(
    VerificationType type, {
    String documentName = '',
  }) async {
    final String id = _store.actorId;
    final Map<VerificationType, VerificationRecord> rows = _store.verifications
        .putIfAbsent(id, () => <VerificationType, VerificationRecord>{});
    final VerificationRecord record = VerificationRecord(
      type: type,
      status: VerificationStatus.pending,
      submittedOn: DateTime.now(),
      documentName: documentName,
    );
    rows[type] = record;
    return record;
  }

  @override
  Future<void> withdrawVerification(String requestId) async {
    for (final Map<VerificationType, VerificationRecord> rows
        in _store.verifications.values) {
      rows.removeWhere(
        (VerificationType _, VerificationRecord r) =>
            r.documentName == requestId,
      );
    }
  }

  @override
  Future<void> setPresence({required bool isOnline}) async {}

  @override
  Future<HelpPreference> helpPreference() async => const HelpPreference();
}

// ==================================================================== admin

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository(this._store);

  final FakeStore _store;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    if (email.trim().toLowerCase() != Fixtures.adminEmail ||
        password != Fixtures.adminPassword) {
      throw const AdminFailure('Those console credentials are not correct.');
    }
    return true;
  }

  @override
  Future<void> signOut() async {}

  /// Computed from the seeded rows so the dashboard stays self-consistent:
  /// `totalUsers` is members only, which is why it equals workers + givers.
  @override
  Future<AdminStats> stats() async {
    final List<AdminUser> members = _store.adminUsers;
    return AdminStats(
      totalUsers: members.length,
      workers: members
          .where((AdminUser u) => u.role == UserRole.worker)
          .length,
      workGivers: members
          .where((AdminUser u) => u.role == UserRole.workGiver)
          .length,
      activeJobs: _store.jobs
          .where((Job j) => j.status == JobStatus.active)
          .length,
      applications: _store.applications.length,
      completedJobs: _store.jobs
          .where((Job j) => j.status == JobStatus.completed)
          .length,
      payments: _store.earnings
          .where((Earning e) => e.status == PaymentStatus.paid)
          .length,
      verificationRequests: _store.verificationRequests
          .where(
            (VerificationRequest v) =>
                v.status == VerificationStatus.pending,
          )
          .length,
      openDisputes: _store.disputes
          .where(
            (Dispute d) =>
                d.status == DisputeStatus.open ||
                d.status == DisputeStatus.underReview,
          )
          .length,
    );
  }

  @override
  Future<List<AdminUser>> users({
    String query = '',
    UserRole? role,
    VerificationStatus? verification,
  }) async {
    final String needle = query.trim().toLowerCase();
    return _store.adminUsers.where((AdminUser user) {
      if (needle.isNotEmpty) {
        final bool matches =
            user.name.toLowerCase().contains(needle) ||
            user.phone.contains(needle) ||
            user.id.toLowerCase().contains(needle);
        if (!matches) return false;
      }
      if (role != null && user.role != role) return false;
      if (verification != null && user.verification != verification) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> setUserActive(
    String userId,
    bool isActive, {
    String reason = '',
  }) async {
    final int index = _store.adminUsers.indexWhere(
      (AdminUser user) => user.id == userId,
    );
    if (index == -1) return;
    final AdminUser user = _store.adminUsers[index];
    _store.adminUsers[index] = AdminUser(
      id: user.id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      verification: user.verification,
      isActive: isActive,
      joinedOn: user.joinedOn,
      jobsCount: user.jobsCount,
      area: user.area,
    );
  }

  @override
  Future<List<Job>> jobs({
    String query = '',
    JobStatus? status,
    JobCategory? category,
  }) async {
    final String needle = query.trim().toLowerCase();
    return _store.jobs.where((Job job) {
      if (needle.isNotEmpty &&
          !job.title.toLowerCase().contains(needle) &&
          !job.company.toLowerCase().contains(needle)) {
        return false;
      }
      if (status != null && job.status != status) return false;
      if (category != null && job.category != category) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> remindApplicants(String jobId) async {}

  @override
  Future<List<Dispute>> disputes({DisputeStatus? status}) async =>
      _store.disputes
          .where((Dispute d) => status == null || d.status == status)
          .toList();

  @override
  Future<Dispute> reviewDispute(String disputeId) async {
    final Dispute dispute = _findDispute(disputeId);
    return _replaceDispute(
      dispute.copyWith(status: DisputeStatus.underReview),
    );
  }

  @override
  Future<Dispute> resolveDispute(
    String disputeId,
    DisputeStatus status, {
    String notes = '',
  }) async => _replaceDispute(
    _findDispute(disputeId).copyWith(status: status, notes: notes),
  );

  Dispute _findDispute(String id) => _store.disputes.firstWhere(
    (Dispute d) => d.id == id,
    orElse: () => throw StateError('No dispute with id $id'),
  );

  Dispute _replaceDispute(Dispute updated) {
    final int index = _store.disputes.indexWhere(
      (Dispute d) => d.id == updated.id,
    );
    _store.disputes[index] = updated;
    return updated;
  }

  @override
  Future<List<VerificationRequest>> verificationRequests({
    VerificationStatus? status,
  }) async => _store.verificationRequests
      .where(
        (VerificationRequest v) => status == null || v.status == status,
      )
      .toList();

  @override
  Future<VerificationRequest> reviewVerification(
    String requestId,
    VerificationStatus decision, {
    String note = '',
  }) async {
    final int index = _store.verificationRequests.indexWhere(
      (VerificationRequest v) => v.id == requestId,
    );
    if (index == -1) throw StateError('No verification request $requestId');
    final VerificationRequest updated = _store.verificationRequests[index]
        .copyWith(status: decision, note: note);
    _store.verificationRequests[index] = updated;
    return updated;
  }
}

// ===================================================================== help

class _FakeHelpRepository implements HelpRepository {
  _FakeHelpRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<HelpArticle>> articles() async => Fixtures.articles();

  @override
  Future<List<HelpArticle>> articlesFor(String category) async =>
      Fixtures.articles()
          .where((HelpArticle a) => a.category == category)
          .toList();

  @override
  Future<List<HelpCategory>> helpCategories() async =>
      Fixtures.helpCategories();

  @override
  Future<SupportReport> submitReport({
    required ReportReason reason,
    required String details,
    required String relatedJob,
  }) async {
    final String id = _store.nextId('t');
    _store.tickets.insert(
      0,
      SupportTicket(
        id: id,
        subject: reason.label,
        body: details,
        createdAt: DateTime.now(),
      ),
    );
    return SupportReport(
      id: id,
      reason: reason,
      details: details,
      submittedAt: DateTime.now(),
      relatedJob: relatedJob,
    );
  }

  @override
  Future<List<SupportTicket>> myTickets() async => _store.tickets.toList();

  @override
  Future<String> supportPhone() async => '+91 80 4000 1234';

  @override
  Future<String> supportEmail() async => 'support@jobmate.in';
}
