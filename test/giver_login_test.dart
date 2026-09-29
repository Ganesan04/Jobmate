import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/features/giver/screens/giver_home_screen.dart';
import 'package:jobmate/features/worker/screens/worker_home_screen.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Boots the app and completes onboarding so the login screen is showing.
  Future<AuthProvider> pumpToLogin(WidgetTester tester) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    auth.completeOnboarding();
    await tester.pumpAndSettle();
    return auth;
  }

  /// Taps Sign in and lets the mock repository timers run.
  Future<void> submitLogin(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }

  testWidgets('signing in with the giver account opens the giver home', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpToLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '9876543210 or you@email.com'),
      'aarav@brightevents.in',
    );
    await tester.pump();
    await submitLogin(tester);

    expect(auth.isAuthenticated, isTrue);
    expect(auth.role, UserRole.workGiver);
    expect(auth.user?.name, 'Aarav Malhotra');
    expect(auth.user?.email, 'aarav@brightevents.in');
    expect(find.byType(GiverHomeScreen), findsOneWidget);
    expect(find.byType(WorkerHomeScreen), findsNothing);
  });

  testWidgets('the giver phone number resolves to the same account', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpToLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '9876543210 or you@email.com'),
      '9811122233',
    );
    await tester.pump();
    await submitLogin(tester);

    expect(auth.role, UserRole.workGiver);
    expect(auth.user?.id, 'u-giver-1');
    expect(find.byType(GiverHomeScreen), findsOneWidget);
  });

  testWidgets('the worker account still opens the worker home', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpToLogin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '9876543210 or you@email.com'),
      '9876543210',
    );
    await tester.pump();
    await submitLogin(tester);

    expect(auth.role, UserRole.worker);
    expect(auth.user?.name, 'Ravi Kumar');
    expect(find.byType(WorkerHomeScreen), findsOneWidget);
    expect(find.byType(GiverHomeScreen), findsNothing);
  });

  testWidgets('the Try it as card switches the role before sign in', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpToLogin(tester);

    final Finder giverChip = find.text('Work Giver');
    await tester.ensureVisible(giverChip);
    await tester.pumpAndSettle();
    await tester.tap(giverChip);
    await tester.pumpAndSettle();
    expect(auth.role, UserRole.workGiver, reason: 'card choice is remembered');

    await submitLogin(tester);
    expect(auth.role, UserRole.workGiver);
    expect(find.byType(GiverHomeScreen), findsOneWidget);
  });

  test('a wrong password is still rejected for the giver account', () async {
    final AuthProvider auth = AuthProvider(
      repository: buildFakeRepositories().users,
    );
    final bool ok = await auth.signIn(
      identifier: 'aarav@brightevents.in',
      password: 'wrongpass',
    );
    expect(ok, isFalse);
    expect(auth.isAuthenticated, isFalse);
  });
}
