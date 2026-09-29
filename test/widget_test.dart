import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobmate/app.dart';
import 'package:jobmate/navigation/app_router.dart';
import 'package:jobmate/navigation/route_table.dart';

import 'support/fake_data_layer.dart';

void main() {
  group('route table', () {
    test('resolves every declared route', () {
      const List<String> names = <String>[
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.otp,
        AppRoutes.roleSelection,
        AppRoutes.profileSetup,
        AppRoutes.shell,
        AppRoutes.workerHome,
        AppRoutes.searchJobs,
        AppRoutes.jobDetails,
        AppRoutes.apply,
        AppRoutes.applications,
        AppRoutes.applicationDetails,
        AppRoutes.acceptedJob,
        AppRoutes.earnings,
        AppRoutes.giverHome,
        AppRoutes.createJob,
        AppRoutes.myJobs,
        AppRoutes.jobApplications,
        AppRoutes.selectWorker,
        AppRoutes.payment,
        AppRoutes.rateWorker,
        AppRoutes.messages,
        AppRoutes.chat,
        AppRoutes.notifications,
        AppRoutes.profile,
        AppRoutes.editProfile,
        AppRoutes.settings,
        AppRoutes.help,
        AppRoutes.faq,
        AppRoutes.reportProblem,
        AppRoutes.contactSupport,
        AppRoutes.verificationCentre,
        AppRoutes.workHistory,
        AppRoutes.forgotPassword,
        AppRoutes.adminLogin,
        AppRoutes.adminShell,
        AppRoutes.adminDashboard,
        AppRoutes.adminUsers,
        AppRoutes.adminJobs,
        AppRoutes.adminDisputes,
        AppRoutes.adminVerifications,
        AppRoutes.adminSettings,
      ];

      for (final String name in names) {
        final Route<dynamic>? route = RouteTable.onGenerateRoute(
          RouteSettings(name: name, arguments: 'JOB-1'),
        );
        expect(route, isNotNull, reason: '$name should resolve');
      }
    });

    test('returns null for unknown routes', () {
      expect(
        RouteTable.onGenerateRoute(const RouteSettings(name: '/nope')),
        isNull,
      );
    });

    test('builds argument driven screens', () {
      final Route<dynamic>? chat = RouteTable.onGenerateRoute(
        const RouteSettings(name: AppRoutes.chat, arguments: 'c-1'),
      );
      expect(chat, isNotNull);

      final Route<dynamic>? payment = RouteTable.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.payment,
          arguments: <String, dynamic>{
            'jobId': 'JOB-1',
            'workerId': 'W-1',
            'workerName': 'Ravi Kumar',
          },
        ),
      );
      expect(payment, isNotNull);
    });
  });

  group('app', () {
    testWidgets('boots from the splash screen into the entry flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        JobmateApp(repositories: buildFakeRepositories()),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);

      // The splash schedules the bootstrap delay; drain it so no timer leaks.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Jobmate'), findsWidgets);
    });
  });
}
