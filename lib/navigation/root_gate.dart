import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/shell/app_shell.dart';
import '../state/auth_provider.dart';

/// Root gate: the single place that maps [AppStage] to the entry screen.
///
/// It is mounted as the `/` route, so a stage change (for example verifying an
/// OTP) swaps the whole entry flow without pushing routes on top of each other.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStage stage = context.select<AuthProvider, AppStage>(
      (AuthProvider auth) => auth.stage,
    );
    switch (stage) {
      case AppStage.splash:
        return const SplashGate();
      case AppStage.onboarding:
        return const OnboardingScreen();
      case AppStage.auth:
        return const LoginScreen();
      case AppStage.profileSetup:
        return const ProfileSetupScreen();
      case AppStage.ready:
        return const AppShell();
    }
  }
}
