/// Backend API configuration.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'http://10.211.9.59:5234';

  /// Page size used for list endpoints. The API caps `PageSize` server-side.
  static const int defaultPageSize = 50;
}
