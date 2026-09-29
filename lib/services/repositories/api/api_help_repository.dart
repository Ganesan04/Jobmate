import '../../../models/enums.dart';
import '../../../models/support.dart';
import '../../api/api_client.dart';
import '../../api/envelope.dart';
import '../../api/json.dart';
import '../../api/wire.dart';
import '../../help_content.dart';
import '../help_repository.dart';

/// [HelpRepository] with real report submission and bundled FAQ copy.
class ApiHelpRepository implements HelpRepository {
  ApiHelpRepository(this._api);

  final ApiClient _api;

  /// Mirrors what the API accepted, so the user can see their own submissions
  /// without an endpoint to read them back.
  final List<SupportTicket> _submitted = <SupportTicket>[];

  @override
  Future<List<HelpArticle>> articles() async => HelpContent.articles;

  @override
  Future<List<HelpArticle>> articlesFor(String category) async =>
      HelpContent.articles
          .where((HelpArticle a) => a.category == category)
          .toList();

  @override
  Future<List<HelpCategory>> helpCategories() async => HelpContent.categories;

  @override
  Future<SupportReport> submitReport({
    required ReportReason reason,
    required String details,
    required String relatedJob,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/api/v1/support-reports',
      body: jsonBody(<String, dynamic>{
        'reason': wireReportReason(reason),
        'details': details.trim(),
        'relatedJobId': relatedJob.isEmpty ? null : relatedJob,
      }, nulls: <String>{'details', 'relatedJobId'}),
    );
    final Map<String, dynamic> data = body.dataMap();
    final SupportReport report = SupportReport(
      id: data.str('id'),
      reason: reportReasonFromWire(data['reason']),
      details: data.str('details'),
      submittedAt: data.dateOr('submittedAt', DateTime.now()),
      relatedJob: data.str('relatedJob'),
    );
    _submitted.insert(
      0,
      SupportTicket(
        id: report.id,
        subject: report.reason.label,
        body: report.details,
        createdAt: report.submittedAt,
        status: report.id.isEmpty ? 'Pending' : 'Open',
      ),
    );
    return report;
  }

  @override
  Future<List<SupportTicket>> myTickets() async =>
      List<SupportTicket>.unmodifiable(_submitted);

  @override
  Future<String> supportPhone() async => HelpContent.supportPhone;

  @override
  Future<String> supportEmail() async => HelpContent.supportEmail;
}
