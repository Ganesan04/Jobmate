import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/features/admin/screens/admin_login_screen.dart';
import 'package:jobmate/features/common/screens/profile_screen.dart';
import 'package:jobmate/features/common/screens/settings_screen.dart';
import 'package:jobmate/features/shell/app_shell.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/navigation/app_router.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:jobmate/state/navigation_state.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

void main() {
  Future<AuthProvider> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(JobmateApp(repositories: buildFakeRepositories()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return Provider.of<AuthProvider>(
      tester.element(find.byType(MaterialApp).first),
      listen: false,
    );
  }

  /// Puts the app straight into the signed-in worker state.
  Future<AuthProvider> pumpSignedIn(WidgetTester tester) async {
    final AuthProvider auth = await pumpApp(tester);
    auth.completeOnboarding();
    await tester.pumpAndSettle();
    await auth.signIn(identifier: 'ravi@jobmate.in', password: 'jobmate123');
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('worker shell shows the five worker tabs', (
    WidgetTester tester,
  ) async {
    await pumpSignedIn(tester);

    expect(find.byType(AppShell), findsOneWidget);
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

  testWidgets('switching tabs changes the visible screen', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpSignedIn(tester);
    final BuildContext context = tester.element(find.byType(AppShell));
    final NavigationState navigation = Provider.of<NavigationState>(
      context,
      listen: false,
    );

    expect(navigation.workerIndex, 0);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(navigation.workerIndex, 4);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(auth.role.label, 'Worker');
  });

  testWidgets('settings screen opens from the profile tab and can sign out', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpSignedIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // The profile tab opens settings from the top bar icon button.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    // Confirm dialog, then the stage returns to auth.
    final Finder confirm = find.text('Sign out').last;
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(auth.stage, AppStage.auth);
  });

  testWidgets('switching role swaps the theme and the tab set', (
    WidgetTester tester,
  ) async {
    final AuthProvider auth = await pumpSignedIn(tester);
    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.theme?.colorScheme.primary, isNot(const Color(0xFF7C3AED)));

    final bool ok = await auth.switchRole(UserRole.workGiver);
    expect(ok, isTrue);
    await tester.pumpAndSettle();

    final MaterialApp updated = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(updated.theme?.colorScheme.primary, const Color(0xFF7C3AED));
    expect(find.text('My jobs'), findsWidgets);
  });

  testWidgets('admin console opens from its own route', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    navigator.pushNamed(AppRoutes.adminLogin);
    await tester.pumpAndSettle();
    expect(find.byType(AdminLoginScreen), findsOneWidget);
  });
}
