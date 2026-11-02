import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/core/widgets/app_text_field.dart';
import 'package:jobmate/features/giver/screens/create_job_screen.dart';
import 'package:jobmate/features/giver/screens/giver_home_screen.dart';
import 'package:jobmate/features/giver/screens/my_jobs_screen.dart';
import 'package:jobmate/models/application.dart';
import 'package:jobmate/models/earning.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/job.dart';
import 'package:jobmate/models/job_draft.dart';
import 'package:jobmate/services/repositories/application_repository.dart';
import 'package:jobmate/services/repositories/earning_repository.dart';
import 'package:jobmate/services/service_locator.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:jobmate/state/giver_provider.dart';
import 'package:jobmate/state/worker_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Signs in as a work giver and lands on the giver shell.
  ///
  /// Provider futures use `Future.delayed`, which only advances when the test
  /// pumps, so nothing here is awaited directly — every step ends in a pump.
  Future<(AuthProvider, GiverProvider)> pumpAsGiver(WidgetTester tester) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    final GiverProvider giver = Provider.of<GiverProvider>(
      context,
      listen: false,
    );

    auth.completeOnboarding();
    await tester.pumpAndSettle();

    unawaited(auth.signIn(identifier: 'meera@shop.in', password: 'jobmate123'));
    await tester.pump(const Duration(seconds: 2));
    unawaited(giver.load());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    return (auth, giver);
  }

  /// A giver provider with no widget tree, for logic level assertions.
  Future<GiverProvider> buildGiver() async {
    final AppRepositories repositories = buildFakeRepositories();
    final GiverProvider giver = GiverProvider(
      repository: repositories.applications,
      jobRepository: repositories.jobs,
      earningRepository: repositories.earnings,
    );
    await giver.load();
    return giver;
  }

  group('giver screens', () {
    testWidgets('shell shows giver destinations, not worker ones', (
      WidgetTester tester,
    ) async {
      await pumpAsGiver(tester);

      expect(find.byType(GiverHomeScreen), findsOneWidget);
      for (final String label in <String>[
        'Home',
        'My jobs',
        'Messages',
        'Alerts',
        'Profile',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing tab $label');
      }
      expect(find.text('Find work'), findsNothing);
    });

    testWidgets('create job wizard blocks an empty step 1', (
      WidgetTester tester,
    ) async {
      await pumpAsGiver(tester);

      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pushNamed('/create-job');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a job title'), findsOneWidget);
      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('create job wizard walks all six steps and publishes', (
      WidgetTester tester,
    ) async {
      final (AuthProvider _, GiverProvider giver) = await pumpAsGiver(tester);
      final int before = giver.myJobs.length;

      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pushNamed('/create-job');
      await tester.pumpAndSettle();
      expect(find.byType(CreateJobScreen), findsOneWidget);
      expect(find.text('Step 1 of 6'), findsOneWidget);

      // Step 1 - basics: title, category, description.
      await tester.enterText(
        find.widgetWithText(
          AppTextField,
          'e.g. Packing helper for evening shift',
        ),
        'Evening warehouse packing',
      );
      await tester.pump();
      await tester.tap(find.text(JobCategory.events.label));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(
          AppTextField,
          'Describe the tasks, the site and anything workers should bring',
        ),
        'Pack and label incoming cartons on the evening shift.',
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 6'), findsOneWidget);

      // Step 2 - requirements keeps the default worker count of one.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 6'), findsOneWidget);

      // Step 3 - schedule: date picker plus three time slots.
      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      for (final String label in <String>[
        'Shift starts',
        'Shift ends',
        'Report time',
      ]) {
        await tester.tap(find.widgetWithText(AppTextField, label));
        await tester.pumpAndSettle();
        // The sheet overlays the form, so its slot is the last match.
        await tester.tap(find.text('6:00 AM').last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 6'), findsOneWidget);

      // Step 4 - payment.
      await tester.enterText(
        find.widgetWithText(AppTextField, 'e.g. 650'),
        '700',
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 5 of 6'), findsOneWidget);

      // Step 5 - location.
      await tester.enterText(
        find.widgetWithText(AppTextField, 'e.g. Koramangala, Bengaluru'),
        'Koramangala',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Building, street, landmark'),
        '4th Block, Koramangala, Bengaluru',
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 6 of 6'), findsOneWidget);

      // Step 6 - review and publish.
      expect(find.text('Contact & safety'), findsWidgets);
      expect(find.text('Review before publishing'), findsOneWidget);
      expect(find.text('Evening warehouse packing'), findsWidgets);
      expect(find.text('Publish job'), findsOneWidget);

      await tester.tap(find.text('Publish job'));
      await tester.pumpAndSettle();
      expect(find.text('Job published'), findsOneWidget);

      expect(giver.myJobs.length, before + 1);
      expect(
        giver.myJobs
            .firstWhere((Job j) => j.title == 'Evening warehouse packing')
            .status,
        JobStatus.active,
      );
    });

    testWidgets('my jobs tab lists the seeded postings', (
      WidgetTester tester,
    ) async {
      final (AuthProvider _, GiverProvider giver) = await pumpAsGiver(tester);

      await tester.tap(find.text('My jobs'));
      await tester.pumpAndSettle();
      expect(find.byType(MyJobsScreen), findsOneWidget);
      expect(giver.myJobs, isNotEmpty);
    });
  });

  group('giver job lifecycle', () {
    test('publishes a job that lands in the job list', () async {
      final GiverProvider giver = await buildGiver();
      final int before = giver.myJobs.length;

      final Job published = await giver.publishDraft(
        const JobDraft(
          title: 'Weekend event staff',
          description: 'Serve guests and manage the queue at the counter.',
          category: JobCategory.events,
          pay: 700,
          payType: PayType.daily,
          workersNeeded: 4,
          area: 'Koramangala',
          address: '4th Block, Koramangala, Bengaluru',
          startTime: '6:00 PM',
          endTime: '11:00 PM',
          skills: <String>['Customer service'],
          experience: 'Fresher is fine',
        ),
        publishImmediately: true,
      );

      expect(giver.myJobs.length, before + 1);
      expect(published.title, 'Weekend event staff');
      // The company is not part of the draft any more: the backend stamps it
      // from the signed-in giver's own profile.
      expect(published.company, 'Bright Events');
      expect(published.giverId, giver.giverId);
      expect(published.status, JobStatus.active);
    });

    test('an application made after sign-in shows up on refresh', () async {
      final AppRepositories repos = buildFakeRepositories();
      final GiverProvider giver = GiverProvider(
        repository: repos.applications,
        jobRepository: repos.jobs,
        earningRepository: repos.earnings,
      );
      await giver.load();
      final String jobId = giver.myJobs.first.id;
      final int before = giver.applicantsForJob(jobId).length;

      // Another account applies while the giver is already signed in.
      await repos.applications.apply(
        jobId: jobId,
        workerId: 'u-new-applicant',
        message: 'I can start tomorrow.',
        availability: '1',
      );
      expect(giver.applicantsForJob(jobId).length, before);

      await giver.refreshApplicants(jobId);
      expect(giver.applicantsForJob(jobId).length, before + 1);
    });

    test('selecting, paying and rating a worker updates giver state', () async {
      final GiverProvider giver = await buildGiver();
      final String jobId = giver.myJobs.first.id;
      final List<JobApplicant> applicants = giver.applicantsForJob(jobId);
      expect(
        applicants,
        isNotEmpty,
        reason: 'mock data should seed applicants',
      );

      final List<WorkerAssignment> assignments = await giver.confirmSelection(
        jobId: jobId,
        agreedPays: <String, int>{applicants.first.id: 800},
      );
      expect(assignments, isNotEmpty);
      expect(giver.totalHired, greaterThan(0));

      final PaymentReceipt receipt = await giver.pay(
        jobId: jobId,
        workerId: assignments.first.workerId,
        basePay: 800,
        overtime: 0,
        method: PaymentMethod.upi,
      );
      expect(receipt.amount, greaterThan(0));
      expect(giver.receipts, isNotEmpty);

      await giver.rateWorker(
        jobId: jobId,
        workerId: assignments.first.workerId,
        stars: 5,
        feedback: 'Punctual and careful with the stock.',
      );
      expect(giver.hasRated(jobId, assignments.first.workerId), isTrue);
    });

    test('cancelling a job moves it out of the active list', () async {
      final GiverProvider giver = await buildGiver();
      final Job job = giver.activeJobs.first;

      final Job? updated = await giver.setJobStatus(
        job.id,
        JobStatus.cancelled,
      );
      expect(updated?.status, JobStatus.cancelled);
      expect(giver.activeJobs.any((Job j) => j.id == job.id), isFalse);
      expect(giver.cancelledCount, greaterThan(0));
    });
  });

  group('giver payment credits the worker wallet', () {
    /// Confirms one applicant on a job so there is a real assignment to pay.
    Future<
      ({
        GiverProvider giver,
        ApplicationRepository applications,
        EarningRepository earnings,
        String jobId,
        WorkerAssignment assignment,
      })
    >
    prepareHiredWorker() async {
      final AppRepositories repos = buildFakeRepositories();
      final GiverProvider giver = GiverProvider(
        repository: repos.applications,
        jobRepository: repos.jobs,
        earningRepository: repos.earnings,
      );
      await giver.load();
      final String jobId = giver.myJobs.first.id;
      final List<JobApplicant> applicants = giver.applicantsForJob(jobId);
      final List<WorkerAssignment> assignments = await giver.confirmSelection(
        jobId: jobId,
        agreedPays: <String, int>{applicants.first.id: 800},
      );
      return (
        giver: giver,
        applications: repos.applications,
        earnings: repos.earnings,
        jobId: jobId,
        assignment: assignments.first,
      );
    }

    test(
      'paying marks the assignment paid and creates a worker earning',
      () async {
        final prepared = await prepareHiredWorker();
        final GiverProvider giver = prepared.giver;
        final ApplicationRepository applications = prepared.applications;
        final EarningRepository earnings = prepared.earnings;
        final String jobId = prepared.jobId;
        final WorkerAssignment assignment = prepared.assignment;

        expect(assignment.isPaid, isFalse);
        final int walletBefore = (await earnings.allEarnings(
          assignment.workerId,
        )).length;

        final PaymentReceipt receipt = await giver.pay(
          jobId: jobId,
          workerId: assignment.workerId,
          basePay: 800,
          overtime: 0,
          method: PaymentMethod.upi,
        );

        // The assignment is now settled.
        final List<WorkerAssignment> after = await applications
            .assignmentsForJob(jobId);
        final WorkerAssignment settled = after.firstWhere(
          (WorkerAssignment a) => a.id == assignment.id,
        );
        expect(settled.isPaid, isTrue);
        expect(settled.paymentId, receipt.paymentId);
        expect(settled.paidAt, isNotNull);

        // And the worker wallet has exactly one new record for it.
        final List<Earning> wallet = await earnings.allEarnings(
          assignment.workerId,
        );
        expect(wallet.length, walletBefore + 1);
        final Earning created = wallet.firstWhere(
          (Earning e) => e.assignmentId == assignment.id,
        );
        expect(created.amount, receipt.amount);
        expect(created.status, PaymentStatus.paid);
        expect(created.jobId, jobId);
        expect(created.workerId, assignment.workerId);
        expect(created.paymentId, receipt.paymentId);
      },
    );

    test('paying twice does not create a duplicate earning', () async {
      final prepared = await prepareHiredWorker();
      final GiverProvider giver = prepared.giver;
      final EarningRepository earnings = prepared.earnings;
      final String jobId = prepared.jobId;
      final WorkerAssignment assignment = prepared.assignment;

      final PaymentReceipt first = await giver.pay(
        jobId: jobId,
        workerId: assignment.workerId,
        basePay: 800,
        overtime: 0,
        method: PaymentMethod.upi,
      );
      final List<Earning> afterFirst = await earnings.allEarnings(
        assignment.workerId,
      );

      // A second trigger, e.g. a double tap. The key is derived from job and
      // worker, so the backend replays the first receipt instead of paying
      // again.
      final PaymentReceipt second = await giver.pay(
        jobId: jobId,
        workerId: assignment.workerId,
        basePay: 800,
        overtime: 0,
        method: PaymentMethod.upi,
      );

      final List<Earning> afterSecond = await earnings.allEarnings(
        assignment.workerId,
      );
      expect(afterSecond.length, afterFirst.length);
      expect(
        afterSecond
            .where((Earning e) => e.assignmentId == assignment.id)
            .length,
        1,
      );
      // The first payout is the one that stands, and the retry echoes it back.
      expect(second.paymentId, first.paymentId);
      expect(
        afterSecond
            .firstWhere((Earning e) => e.assignmentId == assignment.id)
            .paymentId,
        first.paymentId,
      );
    });

    test(
      'the worker provider loads those earnings from the repository',
      () async {
        final prepared = await prepareHiredWorker();
        final GiverProvider giver = prepared.giver;
        final ApplicationRepository applications = prepared.applications;
        final EarningRepository earnings = prepared.earnings;
        final String jobId = prepared.jobId;
        final WorkerAssignment assignment = prepared.assignment;

        final WorkerProvider worker = WorkerProvider(
          applicationRepository: applications,
          earningRepository: earnings,
        );
        await worker.load();
        final int before = worker.earnings.length;

        await giver.pay(
          jobId: jobId,
          workerId: assignment.workerId,
          basePay: 1200,
          overtime: 100,
          method: PaymentMethod.upi,
        );

        // Reload from the same repository the giver credited.
        await worker.load();
        expect(worker.earnings.length, before + 1);
        final Earning added = worker.earnings.firstWhere(
          (Earning e) => e.assignmentId == assignment.id,
        );
        expect(added.amount, 1300);
        expect(added.status, PaymentStatus.paid);
        expect(worker.totalEarned, greaterThan(0));
      },
    );
  });
}
