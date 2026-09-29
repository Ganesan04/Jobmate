import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';
import 'api_exception.dart';
import 'json.dart';
import 'token_store.dart';

/// The single HTTP entry point for the whole app.
///
/// Responsibilities:
/// * resolves every path against [ApiConfig.baseUrl];
/// * attaches the bearer token and keeps it fresh by refreshing once on a 401;
/// * unwraps the `{ success, message, errorCode, data, pagination }` envelope;
/// * turns non-success responses into [ApiException].
class ApiClient {
  ApiClient({
    required TokenStore tokens,
    http.Client? httpClient,
    String? baseUrl,
  }) : _tokens = tokens,
       _http = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStore _tokens;
  final http.Client _http;

  /// Overrides [ApiConfig.baseUrl], which is what lets the widget tests point at
  /// a fake backend on a random port.
  final String _baseUrl;

  /// Guards against a burst of parallel 401s each firing its own refresh.
  Future<bool>? _refreshInFlight;

  /// Called when refreshing fails, so the app can drop back to the auth screen.
  void Function()? onSessionExpired;

  static const Duration _timeout = Duration(seconds: 20);

  String get baseUrl => _baseUrl;

  /// True when a stored access token is available to send.
  bool get hasSession => _tokens.accessToken != null;

  /// True when the session can be extended without a fresh sign-in.
  bool get canRefresh => _tokens.refreshToken != null;

  // ------------------------------------------------------------- verbs

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?> query = const <String, Object?>{},
    bool authenticated = true,
  }) => _send('POST', path, body: body, query: query, authenticated: authenticated);

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?> query = const <String, Object?>{},
  }) => _send('PUT', path, body: body, query: query);

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?> query = const <String, Object?>{},
  }) => _send('DELETE', path, body: body, query: query);

  // ------------------------------------------------------------ transport

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, Object?> query = const <String, Object?>{},
    bool authenticated = true,
    bool allowRetry = true,
  }) async {
    final Uri uri = _buildUri(path, query);
    final http.Response response = await _dispatch(
      method,
      uri,
      body,
      authenticated: authenticated,
    );

    // One transparent refresh, then one retry of the original request.
    if (response.statusCode == 401 &&
        authenticated &&
        allowRetry &&
        _tokens.refreshToken != null) {
      final bool refreshed = await _refreshTokens();
      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          query: query,
          authenticated: authenticated,
          allowRetry: false,
        );
      }
    }

    return _unwrap(response);
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, dynamic>? body, {
    required bool authenticated,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (authenticated) {
      final String? token = _tokens.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    try {
      final String? payload = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          return await _http
              .get(uri, headers: headers)
              .timeout(_timeout);
        case 'POST':
          return await _http
              .post(uri, headers: headers, body: payload)
              .timeout(_timeout);
        case 'PUT':
          return await _http
              .put(uri, headers: headers, body: payload)
              .timeout(_timeout);
        case 'DELETE':
          return await _http
              .delete(uri, headers: headers, body: payload)
              .timeout(_timeout);
        default:
          throw ApiException(message: 'Unsupported method $method');
      }
    } on TimeoutException {
      throw ApiException.network(
        'The server took too long to respond. Check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      // `package:http` reports an unreachable host and a dropped connection the
      // same way on every platform, which is why this file avoids `dart:io` and
      // stays web-compatible.
      throw ApiException.network(
        'Cannot reach $baseUrl. Make sure the backend is running and the host '
        'in app_config.dart is correct.'
        '${e.message.isEmpty ? '' : ' (${e.message})'}',
      );
    }
  }

  /// Rotates the token pair. Returns false when the refresh token is spent.
  Future<bool> _refreshTokens() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final String? refreshToken = _tokens.refreshToken;
    if (refreshToken == null) return false;
    try {
      final Map<String, dynamic> envelope = _unwrap(
        await _dispatch(
          'POST',
          _buildUri('/api/v1/auth/refresh', const <String, Object?>{}),
          <String, dynamic>{'refreshToken': refreshToken},
          authenticated: false,
        ),
      );
      final Map<String, dynamic> data = _dataMap(envelope);
      final String? access = data.strOrNull('accessToken');
      if (access == null || access.isEmpty) return false;
      await _tokens.save(
        accessToken: access,
        refreshToken: data.strOrNull('refreshToken'),
        accessTokenExpiresAt: data.date('accessTokenExpiresAt'),
      );
      return true;
    } on ApiException {
      await _tokens.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  /// Replaces the stored session after a login or OTP verification.
  Future<void> adoptSession(Map<String, dynamic> authData) async {
    final String? access = authData.strOrNull('accessToken');
    if (access == null || access.isEmpty) return;
    await _tokens.save(
      accessToken: access,
      refreshToken: authData.strOrNull('refreshToken'),
      accessTokenExpiresAt: authData.date('accessTokenExpiresAt'),
    );
  }

  Future<void> clearSession() => _tokens.clear();

  void close() => _http.close();

  // ------------------------------------------------------------- envelope

  /// Validates the envelope and returns the whole decoded body so callers can
  /// read both `data` and `pagination`.
  Map<String, dynamic> _unwrap(http.Response response) {
    final int status = response.statusCode;
    final Map<String, dynamic> body = _decode(response);

    final Object? success = body['success'];
    final bool ok = success is bool ? success : status >= 200 && status < 300;

    if (!ok) {
      throw ApiException(
        message: _errorMessage(body, status),
        statusCode: status,
        errorCode: body.strOrNull('errorCode'),
        errors: <ApiFieldError>[
          for (final Map<String, dynamic> item in _objects(body, 'errors'))
            ApiFieldError.fromJson(item),
        ],
      );
    }
    return body;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final String raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (raw.trim().isEmpty) return <String, dynamic>{'success': true};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return <String, dynamic>{'success': true, 'data': decoded};
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{'success': true};
      }
      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }
  }

  String _errorMessage(Map<String, dynamic> body, int status) {
    final String? message = body.strOrNull('message');
    if (message != null && message.isNotEmpty) return message;
    if (status == 401) return 'Your session has expired. Please sign in again.';
    if (status == 403) return 'You do not have permission to do that.';
    if (status == 404) return 'That item could not be found.';
    if (status >= 500) return 'The server had a problem. Please try again shortly.';
    return 'Request failed (HTTP $status).';
  }

  Uri _buildUri(String path, Map<String, Object?> query) {
    final Uri base = Uri.parse('$_baseUrl$path');
    if (query.isEmpty) return base;
    final Map<String, String> params = <String, String>{};
    query.forEach((String key, Object? value) {
      params[key] = _queryValue(value);
    });
    return base.replace(queryParameters: <String, String>{
      ...base.queryParameters,
      ...params,
    });
  }

  /// List filters such as `Categories` and `Statuses` are sent comma separated,
  /// which is the form ASP.NET model binding splits back into an array.
  String _queryValue(Object? value) {
    if (value is Iterable) return value.join(',');
    return value?.toString() ?? '';
  }

  // ------------------------------------------------------------- shortcuts

  static Map<String, dynamic> _dataMap(Map<String, dynamic> envelope) =>
      envelope.object('data');

  static List<Map<String, dynamic>> _objects(
    Map<String, dynamic> envelope,
    String key,
  ) => envelope.objects(key);
}
