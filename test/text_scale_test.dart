import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/core/widgets/app_text_field.dart';
import 'package:jobmate/models/enums.dart';
import 'package:jobmate/state/auth_provider.dart';
import 'package:jobmate/state/giver_provider.dart';
import 'package:provider/provider.dart';

import 'support/fake_data_layer.dart';

/// Guards the app-wide font size clamp in `JobmateApp`.
///
/// The Material date picker re-clamps the ambient `TextScaler` down to the scale
/// it measures. While the app wrapped it in `MediaQuery.withClampedTextScaling`,
/// a device whose system font size sat below the app's 0.9 floor saturated that
/// scaler at exactly 0.9, the picker's clamp collapsed to `minScale == maxScale`
/// and `_ClampedTextScaler` tripped its `maxScale > minScale` assertion — a red
/// screen instead of the calendar.
void main() {
  Future<void> reachScheduleStep(WidgetTester tester) async {
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
    unawaited(auth.switchRole(UserRole.workGiver));
    await tester.pump(const Duration(seconds: 1));
    unawaited(giver.load());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed('/create-job');
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 6'), findsOneWidget);
  }

  for (final double scale in <double>[0.8, 0.85, 0.9, 1.0, 1.15]) {
    testWidgets('the schedule date picker opens at a font scale of $scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await reachScheduleStep(tester);

      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('12'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Select a date'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
