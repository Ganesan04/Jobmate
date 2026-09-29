import 'api/api_client.dart';
import 'api/token_store.dart';
import 'repositories/admin_repository.dart';
import 'repositories/api/api_admin_repository.dart';
import 'repositories/api/api_application_repository.dart';
import 'repositories/api/api_earning_repository.dart';
import 'repositories/api/api_help_repository.dart';
import 'repositories/api/api_job_repository.dart';
import 'repositories/api/api_messaging_repository.dart';
import 'repositories/api/api_notification_repository.dart';
import 'repositories/api/api_user_repository.dart';
import 'repositories/application_repository.dart';
import 'repositories/earning_repository.dart';
import 'repositories/help_repository.dart';
import 'repositories/job_repository.dart';
import 'repositories/messaging_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/user_repository.dart';

/// Composition root for the data layer.
///
/// Everything above this class depends on the repository *interfaces*, so the
/// HTTP client is built once here and shared by every implementation.
class AppRepositories {
  AppRepositories._({
    required this.client,
    required this.jobs,
    required this.applications,
    required this.earnings,
    required this.messaging,
    required this.notifications,
    required this.users,
    required this.admin,
    required this.help,
    this.tokens,
  });

  /// Assembles the graph from already-built repositories.
  ///
  /// The widget tests inject in-memory fakes here, so the production wiring in
  /// [api] stays the only place that knows about [ApiClient]. [client] is null
  /// for a graph that never talks HTTP.
  factory AppRepositories.custom({
    required JobRepository jobs,
    required ApplicationRepository applications,
    required EarningRepository earnings,
    required MessagingRepository messaging,
    required NotificationRepository notifications,
    required UserRepository users,
    required AdminRepository admin,
    required HelpRepository help,
    ApiClient? client,
    TokenStore? tokens,
  }) => AppRepositories._(
    client: client,
    tokens: tokens,
    jobs: jobs,
    applications: applications,
    earnings: earnings,
    messaging: messaging,
    notifications: notifications,
    users: users,
    admin: admin,
    help: help,
  );

  /// Builds the API-backed graph.
  ///
  /// [TokenStore] is loaded during startup so the persisted session is available
  /// before the first request goes out. [baseUrl] overrides
  /// [ApiConfig.baseUrl], which is how the widget tests aim the client at a fake
  /// backend instead of the configured LAN host.
  static Future<AppRepositories> api({
    required TokenStore tokens,
    ApiClient? client,
    String? baseUrl,
  }) async {
    final ApiClient apiClient =
        client ?? ApiClient(tokens: tokens, baseUrl: baseUrl);
    return AppRepositories._(
      client: apiClient,
      tokens: tokens,
      jobs: ApiJobRepository(apiClient),
      applications: ApiApplicationRepository(apiClient),
      earnings: ApiEarningRepository(apiClient),
      messaging: ApiMessagingRepository(apiClient),
      notifications: ApiNotificationRepository(apiClient),
      users: ApiUserRepository(apiClient),
      admin: ApiAdminRepository(apiClient),
      help: ApiHelpRepository(apiClient),
    );
  }

  /// Shared client, exposed so the app can react to an expired session. Null for
  /// an injected graph that does no I/O.
  final ApiClient? client;

  /// Persisted session and onboarding flag. Null for an injected graph.
  final TokenStore? tokens;
  final JobRepository jobs;
  final ApplicationRepository applications;
  final EarningRepository earnings;
  final MessagingRepository messaging;
  final NotificationRepository notifications;
  final UserRepository users;
  final AdminRepository admin;
  final HelpRepository help;

  void dispose() => client?.close();
}
