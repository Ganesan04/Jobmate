/// Errors raised while talking to the Jobmate API.
///
/// The API answers with `{ success, message, errorCode, errors }` where
/// `errors` carries per-field validation messages, so everything the UI needs to
/// render a useful message is captured here.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.errors = const <ApiFieldError>[],
  });

  /// Network failures, timeouts and malformed responses all land here with a
  /// null [statusCode].
  factory ApiException.network(String message) =>
      ApiException(message: message);

  final String message;
  final int? statusCode;
  final String? errorCode;
  final List<ApiFieldError> errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  /// True when the request never reached the server.
  bool get isOffline => statusCode == null;

  /// Field-scoped messages, ready to drop into a form.
  Map<String, String> get fieldErrors => <String, String>{
    for (final ApiFieldError e in errors)
      if (e.field != null && e.field!.isNotEmpty) e.field!: e.message ?? message,
  };

  @override
  String toString() => message;
}

/// One `{ field, message, code }` entry from the API `errors` array.
class ApiFieldError {
  const ApiFieldError({this.field, this.message, this.code});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) => ApiFieldError(
    field: json['field'] as String?,
    message: json['message'] as String?,
    code: json['code'] as String?,
  );

  final String? field;
  final String? message;
  final String? code;
}
