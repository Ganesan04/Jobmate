import 'package:flutter/material.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/common/screens/chat_screen.dart';
import '../features/common/screens/contact_support_screen.dart';
import '../features/common/screens/help_screen.dart';
import '../features/common/screens/messages_screen.dart';
import '../features/common/screens/notifications_screen.dart';
import '../features/common/screens/profile_screen.dart';
import '../features/common/screens/report_problem_screen.dart';
import '../features/common/screens/settings_screen.dart';
import '../features/common/screens/verification_centre_screen.dart';
import '../features/common/screens/work_history_screen.dart';
import '../features/giver/screens/create_job_screen.dart';
import '../features/giver/screens/giver_home_screen.dart';
import '../features/giver/screens/job_applications_screen.dart';
import '../features/giver/screens/my_jobs_screen.dart';
import '../features/giver/screens/payment_screen.dart';
import '../features/giver/screens/rate_worker_screen.dart';
import '../features/giver/screens/select_worker_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/worker/screens/accepted_job_screen.dart';
import '../features/worker/screens/application_details_screen.dart';
import '../features/worker/screens/applications_screen.dart';
import '../features/worker/screens/apply_screen.dart';
import '../features/worker/screens/earnings_screen.dart';
import '../features/worker/screens/job_details_screen.dart';
import '../features/worker/screens/search_jobs_screen.dart';
import '../features/worker/screens/worker_home_screen.dart';
import 'app_router.dart';
import 'root_gate.dart';

/// Resolves the named routes declared in [AppRoutes] to screens.
///
/// It is a separate file from [app_router] so screens can import the constants
/// without importing every other screen.
abstract final class RouteTable {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? screen = _screenFor(settings.name, settings.arguments);
    if (screen == null) return null;
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (BuildContext context) => screen,
    );
  }

  /// Screens that need an id read it as a plain string argument.
  static String _id(RouteSettings settings) =>
      settings.arguments?.toString() ?? '';

  /// Screens that need several values read them from a string map.
  static Map<String, dynamic> _args(RouteSettings settings) {
    final Object? arguments = settings.arguments;
    if (arguments is Map<String, dynamic>) return arguments;
    if (arguments is Map) return arguments.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static String _arg(RouteSettings settings, String key) =>
      _args(settings)[key]?.toString() ?? '';

  static Widget? _screenFor(String? name, Object? arguments) {
    final RouteSettings settings = RouteSettings(
      name: name,
      arguments: arguments,
    );
    switch (name) {
      // Entry flow — `/` is the stage gate, it re-resolves on every change.
      case AppRoutes.splash:
        return const RootGate();
      case AppRoutes.onboarding:
        return const OnboardingScreen();
      case AppRoutes.login:
        return const LoginScreen();
      case AppRoutes.register:
        return const RegisterScreen();
      case AppRoutes.otp:
        return const OtpScreen();
      case AppRoutes.profileSetup:
        return const ProfileSetupScreen();
      case AppRoutes.forgotPassword:
        return const ForgotPasswordScreen();
      case AppRoutes.shell:
        return const AppShell();

      // Worker
      case AppRoutes.workerHome:
        return const WorkerHomeScreen();
      case AppRoutes.searchJobs:
        return const SearchJobsScreen();
      case AppRoutes.jobDetails:
        return JobDetailsScreen(jobId: _id(settings));
      case AppRoutes.apply:
        return ApplyScreen(jobId: _id(settings));
      case AppRoutes.applications:
        return const ApplicationsScreen();
      case AppRoutes.applicationDetails:
        return ApplicationDetailsScreen(applicationId: _id(settings));
      case AppRoutes.acceptedJob:
        return AcceptedJobScreen(jobId: _id(settings));
      case AppRoutes.earnings:
        return const EarningsScreen();

      // Work giver
      case AppRoutes.giverHome:
        return const GiverHomeScreen();
      case AppRoutes.createJob:
        return const CreateJobScreen();
      case AppRoutes.myJobs:
        return const MyJobsScreen();
      case AppRoutes.jobApplications:
        return JobApplicationsScreen(jobId: _arg(settings, 'jobId'));
      case AppRoutes.selectWorker:
        return SelectWorkerScreen(jobId: _id(settings));
      case AppRoutes.payment:
        return PaymentScreen(
          jobId: _arg(settings, 'jobId'),
          workerId: _arg(settings, 'workerId'),
          workerName: _arg(settings, 'workerName'),
        );
      case AppRoutes.rateWorker:
        return RateWorkerScreen(
          jobId: _arg(settings, 'jobId'),
          workerId: _arg(settings, 'workerId'),
          workerName: _arg(settings, 'workerName'),
        );

      // Common
      case AppRoutes.messages:
        return const MessagesScreen();
      case AppRoutes.chat:
        return ChatScreen(conversationId: _id(settings));
      case AppRoutes.notifications:
        return const NotificationsScreen();
      case AppRoutes.profile:
        return const ProfileScreen();
      case AppRoutes.editProfile:
        return const ProfileSetupScreen(isEdit: true);
      case AppRoutes.settings:
        return const SettingsScreen();
      case AppRoutes.help:
      case AppRoutes.faq:
        return const HelpScreen();
      case AppRoutes.reportProblem:
        return const ReportProblemScreen();
      case AppRoutes.contactSupport:
        return const ContactSupportScreen();
      case AppRoutes.verificationCentre:
        return const VerificationCentreScreen();
      case AppRoutes.workHistory:
        return const WorkHistoryScreen();

      default:
        return null;
    }
  }
}
