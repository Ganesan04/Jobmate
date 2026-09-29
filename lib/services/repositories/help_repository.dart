import '../../models/enums.dart';
import '../../models/support.dart';

/// Help centre content + support reports.
///
/// Reports are submitted to `POST /api/v1/support-reports`; the FAQ copy is
/// bundled with the app because the API has no help-centre endpoint.
abstract class HelpRepository {
  Future<List<HelpArticle>> articles();

  Future<List<HelpArticle>> articlesFor(String category);

  Future<List<HelpCategory>> helpCategories();

  Future<SupportReport> submitReport({
    required ReportReason reason,
    required String details,
    required String relatedJob,
  });

  /// Reports raised in this session. The API has no "my reports" endpoint for
  /// members, so this is session-scoped rather than persisted server state.
  Future<List<SupportTicket>> myTickets();

  Future<String> supportPhone();

  Future<String> supportEmail();
}
