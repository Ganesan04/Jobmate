import 'json.dart';

/// Reads the API's response envelope without every repository repeating the
/// same `body['data']` unwrapping.
///
/// A paged endpoint answers with
/// `{ success, data: [...], pagination: { page, pageSize, totalItems, ... } }`.
extension ApiEnvelope on Map<String, dynamic> {
  /// The `data` node as a single object. Throws when the API returned a list.
  T dataAs<T>(T Function(Map<String, dynamic> json) parse) =>
      parse(object('data'));

  /// The `data` node as a list, mapping each element through [parse]. A `null`
  /// or empty payload yields an empty list rather than an error, so screens can
  /// show an empty state instead of a failure.
  List<T> dataList<T>(T Function(Map<String, dynamic> json) parse) =>
      objects('data').map(parse).toList();

  /// The `data` node as a raw map, for the handful of endpoints that answer
  /// with an untyped object.
  Map<String, dynamic> dataMap() => object('data');

  /// `data` when the API sent a scalar string, otherwise [fallback].
  String dataString([String fallback = '']) => str('data', fallback);

  bool dataFlag([bool fallback = false]) => flag('data', fallback);

  int dataInt([int fallback = 0]) => integer('data', fallback);

  String? get message => strOrNull('message');

  Pagination? get pagination {
    final Map<String, dynamic>? raw = objectOrNull('pagination');
    return raw == null ? null : Pagination.fromJson(raw);
  }
}

/// Server-side paging state for list endpoints.
class Pagination {
  const Pagination({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json.integer('page', 1),
    pageSize: json.integer('pageSize', 20),
    totalItems: json.integer('totalItems'),
    totalPages: json.integer('totalPages'),
    hasNext: json.flag('hasNext'),
  );

  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;

  bool get hasPrevious => page > 1;
}
