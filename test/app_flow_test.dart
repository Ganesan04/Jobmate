import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/features/auth/screens/login_screen.dart';
import 'package:jobmate/features/auth/screens/onboarding_screen.dart';
import 'package:jobmate/features/shell/app_shell.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  /// Boots the real app with a fresh mock data layer.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
  }

  /// The splash screen runs an indeterminate progress indicator, so the tree
  /// never settles there. Advance the clock instead.
  Future<void> leaveSplash(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('onboarding leads to the login screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await leaveSplash(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    final Finder skip = find.text('Skip');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signing in with the demo account opens the worker shell', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await leaveSplash(tester);

    final Finder skip = find.text('Skip');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ravi@jobmate.in');
    await tester.enterText(find.byType(TextFormField).at(1), 'jobmate123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('stage machine walks from splash to the shell', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final BuildContext context = tester.element(find.byType(MaterialApp).first);
    final AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    // No splash assertion: bootstrap has no fixed delay, so against the instant
    // fake data layer the stage has already moved on by the first frame.

    await leaveSplash(tester);
    expect(auth.stage, AppStage.onboarding);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    auth.completeOnboarding();
    await tester.pumpAndSettle();
    expect(auth.stage, AppStage.auth);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
