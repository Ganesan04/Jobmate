import 'package:flutter/material.dart';

/// Named route table for the whole app.
///
/// Screens are pushed with [AppRouter.push] / [AppRouter.pushReplacement] so
/// every transition, argument and route name lives in one place.
abstract final class AppRoutes {
  // Entry flow
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';
  static const String profileSetup = '/profile-setup';
  static const String shell = '/shell';

  // Worker
  static const String workerHome = '/worker-home';
  static const String searchJobs = '/search-jobs';
  static const String jobDetails = '/job-details';
  static const String apply = '/apply';
  static const String applications = '/applications';
  static const String applicationDetails = '/application-details';
  static const String acceptedJob = '/accepted-job';
  static const String earnings = '/earnings';

  // Work giver
  static const String giverHome = '/giver-home';
  static const String createJob = '/create-job';
  static const String myJobs = '/my-jobs';
  static const String jobApplications = '/job-applications';
  static const String selectWorker = '/select-worker';
  static const String payment = '/payment';
  static const String rateWorker = '/rate-worker';

  // Common
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String faq = '/faq';
  static const String reportProblem = '/report-problem';
  static const String contactSupport = '/contact-support';
  static const String verificationCentre = '/verification';
  static const String workHistory = '/work-history';
  static const String forgotPassword = '/forgot-password';

  // Admin
  static const String adminLogin = '/admin/login';
  static const String adminShell = '/admin/shell';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminJobs = '/admin/jobs';
  static const String adminDisputes = '/admin/disputes';
  static const String adminVerifications = '/admin/verifications';
  static const String adminSettings = '/admin/settings';
}

/// Builds routes and exposes small push helpers.
abstract final class AppRouter {
  /// Pushes [routeName] onto the navigator.
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replaces the current route (used by the entry flow so Back cannot loop).
  static Future<T?> pushReplacement<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Pops to the first route in the stack.
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }
}
