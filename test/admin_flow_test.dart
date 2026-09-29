import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/core/widgets/app_card.dart';
import 'package:jobmate/core/widgets/status_chip.dart';
import 'package:jobmate/features/admin/screens/admin_dashboard_screen.dart';
import 'package:jobmate/features/admin/screens/admin_disputes_screen.dart';
import 'package:jobmate/features/admin/screens/admin_jobs_screen.dart';
import 'package:jobmate/features/admin/screens/admin_login_screen.dart';
import 'package:jobmate/features/admin/screens/admin_settings_screen.dart';
import 'package:jobmate/features/admin/screens/admin_users_screen.dart';
import 'package:jobmate/features/admin/screens/admin_verifications_screen.dart';
import 'package:jobmate/models/admin.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/job.dart';
import 'package:jobmate/navigation/app_router.dart';
import 'package:jobmate/state/admin_provider.dart';
import 'package:jobmate/state/job_feed_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Gives the test a tall surface so long scroll views build every row.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Signs the admin in through the console login screen.
  Future<(AdminProvider, JobFeedProvider)> pumpAsAdmin(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AdminProvider admin = Provider.of<AdminProvider>(
      context,
      listen: false,
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.adminLogin);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Admin email'),
      'admin@jobmate.in',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'admin123',
    );
    await tester.tap(find.text('Sign in to console'));
    await tester.pumpAndSettle();
    expect(admin.signedIn, isTrue);
    return (admin, Provider.of<JobFeedProvider>(context, listen: false));
  }

  /// Opens the admin navigation tab called [label].
  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// Lets a mock repository load finish before asserting on the list.
  Future<void> settleLoad(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  group('Admin console', () {
    testWidgets('login screen rejects bad credentials then signs in', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final BuildContext context = tester.element(
        find.byType(MaterialApp).first,
      );
      final AdminProvider admin = Provider.of<AdminProvider>(
        context,
        listen: false,
      );

      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      navigator.pushNamed(AppRoutes.adminLogin);
      await tester.pumpAndSettle();
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('Jobmate Admin'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Admin email'),
        'admin@jobmate.in',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrong-password',
      );
      await tester.tap(find.text('Sign in to console'));
      await tester.pumpAndSettle();
      expect(admin.signedIn, isFalse);
      expect(admin.error, isNotNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'admin123',
      );
      await tester.tap(find.text('Sign in to console'));
      await tester.pumpAndSettle();
      expect(admin.signedIn, isTrue);
      expect(admin.error, isNull);
    });

    testWidgets('dashboard loads stats and pending counts', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      unawaited(admin.loadDashboard());
      await settleLoad(tester);

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(admin.dashboardState, LoadState.ready);
      final AdminStats stats = admin.stats;
      expect(stats.totalUsers, greaterThan(0));
      expect(stats.workers, greaterThan(0));
      expect(stats.workGivers, greaterThan(0));
      expect(stats.activeJobs, greaterThan(0));
      expect(stats.totalUsers, stats.workers + stats.workGivers);
      expect(find.text('${stats.totalUsers}'), findsWidgets);
    });

    testWidgets('users tab filters by query, role and status', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      unawaited(admin.loadUsers());
      await settleLoad(tester);
      await openTab(tester, 'Users');
      expect(find.byType(AdminUsersScreen), findsOneWidget);
      final int all = admin.users.length;
      expect(all, greaterThan(1));

      await tester.enterText(
        find.widgetWithText(TextField, 'Search by name, phone or id'),
        'a',
      );
      await tester.pumpAndSettle();
      expect(admin.userQuery, 'a');
      expect(
        admin.users.length,
        lessThanOrEqualTo(all),
        reason: 'a query must never widen the result set',
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Search by name, phone or id'),
        '',
      );
      await tester.pumpAndSettle();
      expect(admin.users.length, all);

      await tester.tap(find.text('All roles'));
      await tester.pumpAndSettle();
      expect(admin.userRole, isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(SelectableChip),
          matching: find.text('Worker'),
        ),
      );
      await tester.pumpAndSettle();
      expect(admin.userRole, UserRole.worker);
      expect(
        admin.users.every((AdminUser user) => user.role == UserRole.worker),
        isTrue,
      );
      expect(admin.users.length, lessThan(all));

      await tester.tap(
        find.descendant(
          of: find.byType(SelectableChip),
          matching: find.text('Worker'),
        ),
      );
      await tester.pumpAndSettle();
      expect(admin.userRole, isNull);
      expect(admin.users.length, all);

      await tester.tap(
        find.descendant(
          of: find.byType(SelectableChip),
          matching: find.text('Verified'),
        ),
      );
      await tester.pumpAndSettle();
      expect(admin.userVerification, VerificationStatus.verified);
      expect(
        admin.users.every(
          (AdminUser user) => user.verification == VerificationStatus.verified,
        ),
        isTrue,
      );
      expect(admin.users.length, lessThan(all));
    });

    testWidgets('deactivating a user asks for confirmation and persists', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      unawaited(admin.loadUsers());
      await settleLoad(tester);
      await openTab(tester, 'Users');
      final AdminUser target = admin.users.firstWhere(
        (AdminUser user) => user.isActive,
      );

      await tester.tap(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(target.name),
                matching: find.byType(AppCard),
              ),
              matching: find.text('Deactivate'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Deactivate ${target.name}?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
      await tester.pumpAndSettle();
      expect(
        admin.users
            .firstWhere((AdminUser user) => user.id == target.id)
            .isActive,
        isFalse,
      );
    });

    testWidgets('jobs tab lists every posted job', (WidgetTester tester) async {
      useTallSurface(tester);
      final (admin, feed) = await pumpAsAdmin(tester);
      unawaited(feed.load());
      await settleLoad(tester);

      await openTab(tester, 'Jobs');
      expect(find.byType(AdminJobsScreen), findsOneWidget);
      expect(feed.jobs.length, greaterThan(0));
      for (final Job job in feed.jobs.take(3)) {
        expect(
          find.text(job.title),
          findsWidgets,
          reason: 'the admin job list must show ${job.title}',
        );
      }
    });

    testWidgets('disputes tab filters and resolves an open dispute', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      unawaited(admin.loadDisputes());
      await settleLoad(tester);
      await openTab(tester, 'Disputes');
      expect(find.byType(AdminDisputesScreen), findsOneWidget);
      final int total = admin.disputes.length;
      expect(total, greaterThan(0));

      admin.setDisputeFilter(DisputeStatus.open);
      await settleLoad(tester);
      expect(
        admin.disputes.every((Dispute d) => d.status == DisputeStatus.open),
        isTrue,
      );

      final Dispute target = admin.disputes.firstWhere(
        (Dispute d) => d.status == DisputeStatus.open,
      );
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(target.reason.label).first,
            matching: find.byType(AppCard),
          ),
          matching: find.text('Resolve'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Moderator notes'),
        'Payment released to the worker after checking the UPI reference.',
      );
      await tester.tap(find.text('Resolve').last);
      await tester.pumpAndSettle();

      // The open filter hides the resolved case, so reload unfiltered.
      admin.setDisputeFilter(null);
      await settleLoad(tester);
      final Dispute resolved = admin.disputes.firstWhere(
        (Dispute d) => d.id == target.id,
      );
      expect(resolved.status, DisputeStatus.resolved);
      expect(resolved.notes, contains('UPI reference'));
    });

    testWidgets('verification queue approves a pending request', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      unawaited(admin.loadVerifications());
      await settleLoad(tester);
      await openTab(tester, 'Verify');
      expect(find.byType(AdminVerificationsScreen), findsOneWidget);
      expect(admin.verifications.length, greaterThan(0));

      admin.setVerificationFilter(VerificationStatus.pending);
      await settleLoad(tester);
      expect(
        admin.verifications.every(
          (VerificationRequest r) => r.status == VerificationStatus.pending,
        ),
        isTrue,
      );

      final VerificationRequest target = admin.verifications.firstWhere(
        (VerificationRequest r) => r.status == VerificationStatus.pending,
      );
      final String targetId = target.id;
      final int pendingBefore = admin.pendingVerifications;
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(target.userName).first,
            matching: find.byType(AppCard),
          ),
          matching: find.text('Approve'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Reviewer note'),
        'Checked the uploaded document against the profile details.',
      );
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      // The pending filter drops the reviewed row, so reload unfiltered.
      admin.setVerificationFilter(null);
      await settleLoad(tester);
      final VerificationRequest reviewed = admin.verifications.firstWhere(
        (VerificationRequest r) => r.id == targetId,
      );
      expect(reviewed.status, VerificationStatus.verified);
      expect(reviewed.note, contains('uploaded document'));
      expect(admin.pendingVerifications, pendingBefore - 1);
    });

    testWidgets('admin settings signs the console out', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final (admin, _) = await pumpAsAdmin(tester);

      await openTab(tester, 'Dashboard');
      await tester.tap(find.text('Console settings').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminSettingsScreen), findsOneWidget);

      await tester.tap(find.text('Sign out of console'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out of the console?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(admin.signedIn, isFalse);
    });
  });
}
