import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/features/common/screens/chat_screen.dart';
import 'package:jobmate/features/common/screens/help_screen.dart';
import 'package:jobmate/features/common/screens/messages_screen.dart';
import 'package:jobmate/features/common/screens/notifications_screen.dart';
import 'package:jobmate/features/common/screens/profile_screen.dart';
import 'package:jobmate/features/common/screens/report_problem_screen.dart';
import 'package:jobmate/features/common/screens/settings_screen.dart';
import 'package:jobmate/features/common/screens/verification_centre_screen.dart';
import 'package:jobmate/features/common/screens/work_history_screen.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/models/messaging.dart';
import 'package:jobmate/models/user.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:jobmate/state/chat_provider.dart';
import 'package:jobmate/state/giver_provider.dart';
import 'package:jobmate/state/notification_provider.dart';
import 'package:jobmate/state/support_provider.dart';
import 'package:jobmate/state/worker_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Signs in with [identifier] and returns the providers a common screen uses.
  Future<
    ({
      AuthProvider auth,
      WorkerProvider worker,
      GiverProvider giver,
      ChatProvider chat,
      NotificationProvider notifications,
      SupportProvider support,
    })
  >
  pumpSession(WidgetTester tester, String identifier) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);

    auth.completeOnboarding();
    await tester.pumpAndSettle();
    unawaited(auth.signIn(identifier: identifier, password: 'jobmate123'));
    await tester.pump(const Duration(seconds: 2));

    final BuildContext signedIn = tester.element(
      find.byType(MaterialApp).first,
    );
    return (
      auth: auth,
      worker: Provider.of<WorkerProvider>(signedIn, listen: false),
      giver: Provider.of<GiverProvider>(signedIn, listen: false),
      chat: Provider.of<ChatProvider>(signedIn, listen: false),
      notifications: Provider.of<NotificationProvider>(signedIn, listen: false),
      support: Provider.of<SupportProvider>(signedIn, listen: false),
    );
  }

  /// Gives the test a tall surface so long scroll views build every row.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Opens the bottom navigation tab called [label].
  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('Common screens', () {
    testWidgets('messages list opens a thread and sends a message', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');
      unawaited(session.chat.load());
      await tester.pumpAndSettle();

      await openTab(tester, 'Messages');
      expect(find.byType(MessagesScreen), findsOneWidget);
      expect(find.text('4 conversation(s)'), findsOneWidget);
      expect(find.text('Aarav Malhotra'), findsOneWidget);
      final int unreadBefore = session.chat.unreadTotal;
      expect(unreadBefore, greaterThan(0));

      await tester.tap(find.text('Aarav Malhotra'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      // Opening the thread clears only its own unread badge.
      expect(
        session.chat.conversations
            .firstWhere((Conversation c) => c.id == 'c-1')
            .unread,
        0,
      );
      expect(session.chat.unreadTotal, lessThan(unreadBefore));

      const String outgoing = 'Yes, I will be there at 9 AM.';
      await tester.enterText(find.byType(TextField).last, outgoing);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text(outgoing), findsOneWidget);
      expect(
        session.chat.thread('c-1').last.text,
        outgoing,
        reason: 'the sent message must be appended to the thread',
      );
      final Conversation updated = session.chat.conversations.firstWhere(
        (Conversation c) => c.id == 'c-1',
      );
      expect(updated.lastMessage, outgoing);
    });

    testWidgets('notification filters and mark all read', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9811122233');
      unawaited(session.notifications.load());
      await tester.pumpAndSettle();

      await openTab(tester, 'Alerts');
      expect(find.byType(NotificationsScreen), findsOneWidget);
      final int total = session.notifications.items.length;
      expect(session.notifications.unreadCount, greaterThan(0));
      expect(total, greaterThan(0));

      session.notifications.setFilter(NotificationType.payment);
      await tester.pumpAndSettle();
      expect(
        session.notifications.visibleItems.every(
          (AppNotification n) => n.type == NotificationType.payment,
        ),
        isTrue,
        reason: 'the payment filter must only keep payment notifications',
      );
      expect(session.notifications.visibleItems.length, lessThan(total));

      session.notifications.setFilter(null);
      await tester.pumpAndSettle();
      expect(session.notifications.visibleItems.length, total);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(session.notifications.unreadCount, 0);
    });

    testWidgets('verification centre submits a pending verification', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');

      await openTab(tester, 'Profile');
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.text('Verification centre'));
      await tester.pumpAndSettle();
      expect(find.byType(VerificationCentreScreen), findsOneWidget);

      int pendingCount() => session.auth.verificationSummary.all
          .where(
            (VerificationStatus status) => status == VerificationStatus.pending,
          )
          .length;
      final int pendingBefore = pendingCount();
      expect(find.text('Submit for verification'), findsWidgets);

      await tester.tap(find.text('Submit for verification').first);
      await tester.pumpAndSettle();
      // The input dialog is pre-filled, so saving submits straight away.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Submitting has a mock latency, so let it resolve before asserting.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Submitted for review'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(pendingCount(), pendingBefore + 1);
      expect(
        session.auth.verifications.any(
          (VerificationRecord r) =>
              r.status == VerificationStatus.pending &&
              r.documentName.isNotEmpty,
        ),
        isTrue,
      );
    });

    testWidgets('worker work history lists completed jobs', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');
      unawaited(session.worker.load());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      final int completed = session.worker.history.length;
      expect(completed, greaterThan(0));

      await openTab(tester, 'Profile');
      await tester.tap(find.text('Work history'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkHistoryScreen), findsOneWidget);
      expect(find.text('$completed'), findsWidgets);
    });

    testWidgets('report a problem validates then submits a report', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');
      unawaited(session.support.load());
      await tester.pumpAndSettle();

      await openTab(tester, 'Profile');
      await tester.tap(find.text('Help & support'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);

      await tester.tap(find.text('Report a problem').first);
      await tester.pumpAndSettle();
      expect(find.byType(ReportProblemScreen), findsOneWidget);

      // No reason chosen: the form must refuse to submit.
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(find.text('Choose what you want to report'), findsOneWidget);

      await tester.tap(find.text(ReportReason.notPaid.label));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).last,
        'Payment was released on 12 May but never reached my UPI account.',
      );
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AlertDialog, 'Report submitted'),
        findsOneWidget,
      );
      expect(session.support.tickets.length, 1);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // The submit button now shows the submitted state with a reference card.
      expect(find.text('Report submitted'), findsOneWidget);
      expect(
        find.text('Reference ${session.support.tickets.first.id}'),
        findsOneWidget,
      );
    });

    testWidgets('settings sign out returns to the login screen', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');

      await openTab(tester, 'Profile');
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(session.auth.isAuthenticated, isFalse);
      expect(session.auth.user, isNull);
    });

    testWidgets('switch role from profile moves the session to giver', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final session = await pumpSession(tester, '9876543210');
      expect(session.auth.role, UserRole.worker);

      await openTab(tester, 'Profile');
      await tester.tap(find.text('Switch role'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to Work Giver?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Switch role'));
      await tester.pumpAndSettle();

      expect(session.auth.role, UserRole.workGiver);
      expect(session.auth.user?.role, UserRole.workGiver);
      expect(find.text('My jobs'), findsOneWidget);
    });
  });
}
