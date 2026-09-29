import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session so the app can resume without a fresh sign-in.
///
/// The access token is short lived and the refresh token is rotated by the
/// backend, so both are written together and cleared as a pair.
class TokenStore {
  TokenStore(this._prefs);

  static const String _accessKey = 'jobmate.auth.accessToken';
  static const String _refreshKey = 'jobmate.auth.refreshToken';
  static const String _accessExpiryKey = 'jobmate.auth.accessExpiresAt';
  static const String _onboardingKey = 'jobmate.onboardingSeen';

  final SharedPreferences _prefs;

  /// Loads the persisted session. Must be awaited before the first request.
  static Future<TokenStore> create() async =>
      TokenStore(await SharedPreferences.getInstance());

  String? get accessToken => _nonEmpty(_prefs.getString(_accessKey));
  String? get refreshToken => _nonEmpty(_prefs.getString(_refreshKey));

  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
  }) async {
    await _prefs.setString(_accessKey, accessToken);
    if (refreshToken != null) await _prefs.setString(_refreshKey, refreshToken);
    if (accessTokenExpiresAt != null) {
      await _prefs.setString(_accessExpiryKey, accessTokenExpiresAt.toIso8601String());
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
    await _prefs.remove(_accessExpiryKey);
  }

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
