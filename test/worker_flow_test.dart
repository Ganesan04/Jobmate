import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/features/worker/screens/applications_screen.dart';
import 'package:jobmate/features/worker/screens/earnings_screen.dart';
import 'package:jobmate/features/worker/screens/search_jobs_screen.dart';
import 'package:jobmate/features/worker/screens/worker_home_screen.dart';
import 'package:jobmate/models/application.dart';
import 'package:jobmate/models/earning.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/job.dart';

import 'package:jobmate/services/service_locator.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:jobmate/state/job_feed_provider.dart';
import 'package:jobmate/state/worker_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Signs in as the worker and lands on the worker shell.
  Future<(AuthProvider, WorkerProvider, JobFeedProvider)> pumpAsWorker(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    final WorkerProvider worker = Provider.of<WorkerProvider>(
      context,
      listen: false,
    );
    final JobFeedProvider feed = Provider.of<JobFeedProvider>(
      context,
      listen: false,
    );

    auth.completeOnboarding();
    await tester.pumpAndSettle();
    unawaited(auth.signIn(identifier: '9876543210', password: 'jobmate123'));
    await tester.pump(const Duration(seconds: 2));
    unawaited(worker.load());
    await tester.pump(const Duration(seconds: 2));
    unawaited(feed.load());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    return (auth, worker, feed);
  }

  /// A worker provider with no widget tree, for lifecycle assertions.
  Future<WorkerProvider> buildWorker() async {
    final AppRepositories repositories = buildFakeRepositories();
    final WorkerProvider worker = WorkerProvider(
      applicationRepository: repositories.applications,
      earningRepository: repositories.earnings,
    );
    await worker.load();
    return worker;
  }

  /// The first seeded assignment that still accepts a check in.
  WorkerAssignment openAssignment(WorkerProvider worker) =>
      worker.assignments.firstWhere(
        (WorkerAssignment a) => !a.isCheckedIn && a.checkInCode != null,
        orElse: () => worker.assignments.first,
      );

  /// Applications for a job that are still running, matching the rule the
  /// provider enforces: withdrawn, rejected and expired rows do not count.
  int liveApplications(WorkerProvider worker, String jobId) => worker
      .applications
      .where(
        (JobApplication a) =>
            a.jobId == jobId &&
            a.status != ApplicationStatus.withdrawn &&
            a.status != ApplicationStatus.rejected &&
            a.status != ApplicationStatus.expired,
      )
      .length;

  /// The first active job this worker has no live application for.
  Future<Job> findOpenJob(WorkerProvider worker, List<Job> jobs) async {
    for (final Job job in jobs) {
      if (!await worker.hasActiveApplication(job.id)) return job;
    }
    return jobs.first;
  }

  group('worker screens', () {
    testWidgets('worker shell shows worker destinations, not giver ones', (
      WidgetTester tester,
    ) async {
      await pumpAsWorker(tester);

      expect(find.byType(WorkerHomeScreen), findsOneWidget);
      for (final String label in <String>[
        'Home',
        'Find work',
        'Applications',
        'Messages',
        'Profile',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing tab $label');
      }
      expect(find.text('My jobs'), findsNothing);
    });

    testWidgets('search lists jobs, sorts them and filters the feed', (
      WidgetTester tester,
    ) async {
      final (_, _, JobFeedProvider feed) = await pumpAsWorker(tester);

      await tester.tap(find.text('Find work'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchJobsScreen), findsOneWidget);
      expect(find.textContaining('job'), findsWidgets);

      // Sort by pay changes the ordering of the feed.
      final List<Job> before = await feed.search(
        const JobFilter(),
        JobSort.newest,
      );
      final List<Job> byPay = await feed.search(
        const JobFilter(),
        JobSort.payHigh,
      );
      expect(before, isNotEmpty);
      expect(byPay, isNotEmpty);
      expect(
        byPay.first.pay,
        greaterThanOrEqualTo(byPay.last.pay),
        reason: 'highest pay sort should be descending',
      );

      // Text query narrows the result set.
      final List<Job> filtered = await feed.search(
        const JobFilter(query: 'event'),
        JobSort.newest,
      );
      expect(filtered, isNotEmpty);
      expect(
        filtered.every(
          (Job j) =>
              j.title.toLowerCase().contains('event') ||
              j.description.toLowerCase().contains('event') ||
              j.company.toLowerCase().contains('event'),
        ),
        isTrue,
      );
    });

    testWidgets('applications screen lists the worker history and filters it', (
      WidgetTester tester,
    ) async {
      final (_, WorkerProvider worker, _) = await pumpAsWorker(tester);

      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();
      expect(find.byType(ApplicationsScreen), findsOneWidget);
      expect(worker.applications, isNotEmpty);
    });

    testWidgets(
      'earnings screen opens from the home card and filters payments',
      (WidgetTester tester) async {
        final (_, WorkerProvider worker, _) = await pumpAsWorker(tester);

        // Earnings is reached from a home stat card, not a bottom nav tab.
        final Finder card = find.text('This month');
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(EarningsScreen), findsOneWidget);
        expect(worker.earnings, isNotEmpty);

        final List<EarningSummary> summary = await worker.monthlySummary();
        expect(summary, isNotEmpty);
        expect(await worker.earningsFiltered(PaymentStatus.paid), isNotEmpty);
      },
    );
  });

  group('worker job lifecycle', () {
    test('applying adds an application the worker can see', () async {
      final WorkerProvider worker = await buildWorker();
      final AppRepositories repositories = buildFakeRepositories();
      final List<Job> jobs = await repositories.jobs.activeJobs();
      final Job target = await findOpenJob(worker, jobs);

      final int before = worker.applications.length;
      final JobApplication? created = await worker.apply(
        job: target,
        message: 'I have packed goods for three years and can start early.',
        expectedPay: 700,
        availability: '1',
      );
      expect(created, isNotNull);
      expect(worker.applications.length, before + 1);
      expect(worker.applications.first.jobId, target.id);
      expect(worker.applications.first.status, ApplicationStatus.applied);
      expect(worker.applications.first.message, contains('packed goods'));

      // The job details screen keys its "You have applied" guard off this list.
      expect(
        worker.applications.any((JobApplication a) => a.jobId == target.id),
        isTrue,
      );
    });

    test('an account cannot apply to a job it posted', () async {
      // One account both hires and works: here the giver is in worker mode.
      final WorkerProvider worker = await buildWorker();
      worker.setWorkerId('u-giver-1');
      final AppRepositories repositories = buildFakeRepositories();
      final Job own = (await repositories.jobs.activeJobs()).firstWhere(
        (Job job) => job.giverId == 'u-giver-1',
      );

      final JobApplication? created = await worker.apply(
        job: own,
        message: 'Applying to my own posting.',
        availability: '1',
      );
      expect(created, isNull);
      expect(
        worker.applyError,
        'You posted this job, so you cannot apply to it.',
      );
    });

    test('a worker cannot apply to the same job twice', () async {
      final WorkerProvider worker = await buildWorker();
      final AppRepositories repositories = buildFakeRepositories();
      final List<Job> jobs = await repositories.jobs.activeJobs();
      final Job target = await findOpenJob(worker, jobs);

      final JobApplication? first = await worker.apply(
        job: target,
        message: 'Available and experienced for this work.',
        availability: '1',
      );
      expect(first, isNotNull);
      expect(await worker.hasActiveApplication(target.id), isTrue);

      // A second attempt is refused by the provider, not just the button.
      final JobApplication? second = await worker.apply(
        job: target,
        message: 'Applying a second time.',
        availability: '1',
      );
      expect(second, isNull);
      expect(
        liveApplications(worker, target.id),
        1,
        reason: 'only one live application may exist per job',
      );

      // Withdrawing frees the job up again.
      await worker.withdraw(
        worker.applications.firstWhere(
          (JobApplication a) => a.jobId == target.id,
        ),
      );
      expect(await worker.hasActiveApplication(target.id), isFalse);
      final JobApplication? third = await worker.apply(
        job: target,
        message: 'Reapplying after withdrawing.',
        availability: '1',
      );
      expect(third, isNotNull);
    });

    test('withdrawing flips the application to withdrawn', () async {
      final WorkerProvider worker = await buildWorker();
      final JobApplication application = worker.applications.firstWhere(
        (JobApplication a) => a.status == ApplicationStatus.applied,
        orElse: () => worker.applications.first,
      );

      await worker.withdraw(application);
      final JobApplication updated = worker.applications.firstWhere(
        (JobApplication a) => a.id == application.id,
      );
      expect(updated.status, ApplicationStatus.withdrawn);
    });

    test(
      'check in rejects a wrong code and accepts the right one once',
      () async {
        final WorkerProvider worker = await buildWorker();
        final WorkerAssignment assignment = openAssignment(worker);
        final String code = assignment.checkInCode!;

        final String? wrong = await worker.checkIn(
          assignment,
          code == '9999' ? '1111' : '9999',
        );
        expect(wrong, isNotNull, reason: 'a wrong code must be rejected');
        expect(
          worker.assignments
              .firstWhere((WorkerAssignment a) => a.id == assignment.id)
              .isCheckedIn,
          isFalse,
        );

        expect(await worker.checkIn(assignment, code), isNull);
        final WorkerAssignment checkedIn = worker.assignments.firstWhere(
          (WorkerAssignment a) => a.id == assignment.id,
        );
        expect(checkedIn.isCheckedIn, isTrue);
        expect(checkedIn.checkInCode, isNull, reason: 'the code is consumed');

        // A second check in is refused.
        final String? again = await worker.checkIn(assignment, code);
        expect(again, isNotNull);
      },
    );

    test('a shift completes only after check in', () async {
      final WorkerProvider worker = await buildWorker();
      final WorkerAssignment assignment = openAssignment(worker);
      final String code = assignment.checkInCode!;

      // Too early: the work giver has not paid out yet, so completion is a
      // no-op error path rather than a crash.
      final String? beforeCheckIn = await worker.completeShift(assignment);
      expect(beforeCheckIn, isNotNull);
      expect(
        worker.assignments
            .firstWhere((WorkerAssignment a) => a.id == assignment.id)
            .completedAt,
        isNull,
      );

      await worker.checkIn(assignment, code);
      final WorkerAssignment checkedIn = worker.assignments.firstWhere(
        (WorkerAssignment a) => a.id == assignment.id,
      );
      expect(await worker.completeShift(checkedIn), isNull);

      final WorkerAssignment done = worker.assignments.firstWhere(
        (WorkerAssignment a) => a.id == assignment.id,
      );
      expect(done.completedAt, isNotNull);
      expect(done.paymentStatus, PaymentStatus.paid);

      // Completing again is refused rather than double counted.
      expect(await worker.completeShift(done), isNotNull);
    });
  });
}
