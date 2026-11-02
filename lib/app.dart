import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app/theme/app_theme.dart';
import 'models/enums.dart';
import 'navigation/app_router.dart';
import 'navigation/route_table.dart';
import 'services/service_locator.dart';
import 'state/auth_provider.dart';
import 'state/chat_provider.dart';
import 'state/giver_provider.dart';
import 'state/job_feed_provider.dart';
import 'state/navigation_state.dart';
import 'state/notification_provider.dart';
import 'state/support_provider.dart';
import 'state/worker_provider.dart';

/// App root: builds the provider graph and owns the theme that follows the
/// active role.
class JobmateApp extends StatefulWidget {
  const JobmateApp({super.key, required this.repositories});

  /// The API-backed data layer, assembled in `main` once the stored session has
  /// been read.
  final AppRepositories repositories;

  @override
  State<JobmateApp> createState() => _JobmateAppState();
}

class _JobmateAppState extends State<JobmateApp> {
  @override
  void dispose() {
    widget.repositories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providersFor(widget.repositories),
      child: _AppView(repositories: widget.repositories),
    );
  }
}

/// Provider graph for the app. Exposed so a test can mount the same tree.
List<SingleChildWidget> providersFor(AppRepositories repositories) {
  return <SingleChildWidget>[
    ChangeNotifierProvider<AuthProvider>(
      create: (_) =>
          AuthProvider(repository: repositories.users, tokens: repositories.tokens),
    ),
    ChangeNotifierProvider<JobFeedProvider>(
      create: (_) => JobFeedProvider(repository: repositories.jobs),
    ),
    ChangeNotifierProvider<WorkerProvider>(
      create: (_) => WorkerProvider(
        applicationRepository: repositories.applications,
        earningRepository: repositories.earnings,
      ),
    ),
    ChangeNotifierProvider<GiverProvider>(
      create: (_) => GiverProvider(
        repository: repositories.applications,
        jobRepository: repositories.jobs,
        earningRepository: repositories.earnings,
      ),
    ),
    ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(repository: repositories.messaging),
    ),
    ChangeNotifierProvider<NotificationProvider>(
      create: (_) =>
          NotificationProvider(repository: repositories.notifications),
    ),
    ChangeNotifierProvider<SupportProvider>(
      create: (_) => SupportProvider(repository: repositories.help),
    ),
    ChangeNotifierProvider<NavigationState>(create: (_) => NavigationState()),
  ];
}

class _AppView extends StatefulWidget {
  const _AppView({required this.repositories});

  final AppRepositories repositories;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  /// Representative body font size, used to read the ambient text scale without
  /// the deprecated `TextScaler.textScaleFactor`.
  static const double _bodyFontSize = 15;

  late final AuthProvider _auth = context.read<AuthProvider>();
  AppStage _lastStage = AppStage.splash;
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    widget.repositories.client?.onSessionExpired = _auth.expireSession;
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    widget.repositories.client?.onSessionExpired = null;
    super.dispose();
  }

  /// User data is fetched once a session is ready, not at launch, so nothing is
  /// requested without a token and a new sign-in never shows the last user's data.
  ///
  /// The session's token only carries the active mode, so worker and giver data
  /// are loaded for that mode alone, and reloaded whenever the user switches.
  void _onAuthChanged() {
    final AppStage stage = _auth.stage;
    final UserRole role = _auth.role;
    final bool becameReady =
        stage == AppStage.ready && _lastStage != AppStage.ready;
    final bool switched =
        stage == AppStage.ready && !becameReady && role != _lastRole;
    if (becameReady) {
      context.read<ChatProvider>().load();
      context.read<NotificationProvider>().load();
      context.read<SupportProvider>().load();
    }
    if (becameReady || switched) {
      if (role == UserRole.worker) {
        context.read<JobFeedProvider>().load();
        context.read<WorkerProvider>().load();
      } else {
        context.read<GiverProvider>().load();
      }
    }
    _lastStage = stage;
    _lastRole = role;
  }

  @override
  Widget build(BuildContext context) {
    final UserRole role = context.select<AuthProvider, UserRole>(
      (AuthProvider auth) => auth.role,
    );
    return MaterialApp(
      title: 'Jobmate',
      debugShowCheckedModeBanner: false,
      theme: role == UserRole.workGiver
          ? buildGiverTheme()
          : buildWorkerTheme(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteTable.onGenerateRoute,
      builder: (BuildContext context, Widget? child) {
        // Font size is clamped to a range the layouts support, but through a
        // plain TextScaler.linear rather than MediaQuery.withClampedTextScaling.
        // Widgets such as the Material date picker re-clamp the ambient scaler
        // down to the scale they measure; when a clamped scaler's lower bound is
        // already reached that clamp collapses to min == max and trips the
        // framework's `maxScale > minScale` assertion. A linear scaler is safe
        // because clamping it is a no-op whenever the range is already honoured.
        final MediaQueryData data = MediaQuery.of(context);
        final double bodyScale = data.textScaler.scale(_bodyFontSize) / _bodyFontSize;
        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(
              bodyScale.clamp(0.9, 1.3).toDouble(),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
