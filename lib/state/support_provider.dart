import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/support.dart';
import '../services/repositories/help_repository.dart';

/// Help centre content, contact details and support reports.
class SupportProvider extends ChangeNotifier {
  SupportProvider({required HelpRepository repository})
    : _repository = repository;

  final HelpRepository _repository;

  List<HelpArticle> _articles = <HelpArticle>[];
  List<HelpCategory> _categories = <HelpCategory>[];
  List<SupportTicket> _tickets = <SupportTicket>[];
  String _phone = '';
  String _email = '';
  String? _selectedCategory;
  bool _submitting = false;

  List<HelpArticle> get articles => _articles;
  List<HelpCategory> get categories => _categories;

  /// Category tiles for the help screen.
  Future<List<HelpCategory>> helpCategories() => _repository.helpCategories();
  List<SupportTicket> get tickets => _tickets;
  String get phone => _phone;
  String get email => _email;
  String? get selectedCategory => _selectedCategory;
  bool get submitting => _submitting;

  List<HelpArticle> get visibleArticles => _selectedCategory == null
      ? _articles
      : _articles
            .where((HelpArticle a) => a.category == _selectedCategory)
            .toList();

  List<String> get articleCategories {
    final Set<String> values = _articles
        .map((HelpArticle a) => a.category)
        .toSet();
    return values.toList();
  }

  Future<void> load() async {
    _articles = await _repository.articles();
    _categories = await _repository.helpCategories();
    _tickets = await _repository.myTickets();
    _phone = await _repository.supportPhone();
    _email = await _repository.supportEmail();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<SupportReport?> submitReport({
    required ReportReason reason,
    required String details,
    required String relatedJob,
  }) async {
    _submitting = true;
    notifyListeners();
    try {
      final SupportReport report = await _repository.submitReport(
        reason: reason,
        details: details,
        relatedJob: relatedJob,
      );
      _tickets = await _repository.myTickets();
      return report;
    } catch (_) {
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
