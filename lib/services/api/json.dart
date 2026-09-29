/// Null-safe readers for decoded JSON.
///
/// The API marks most properties nullable, so every read has to cope with a
/// missing key, an explicit `null`, or a value of an unexpected type.
extension JsonMap on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final Object? value = this[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  /// Like [str] but keeps an explicit null distinct from an empty string.
  String? strOrNull(String key) {
    final Object? value = this[key];
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  int integer(String key, [int fallback = 0]) {
    final Object? value = this[key];
    return _asInt(value) ?? fallback;
  }

  int? intOrNull(String key) => _asInt(this[key]);

  double decimal(String key, [double fallback = 0]) {
    final Object? value = this[key];
    return _asDouble(value) ?? fallback;
  }

  double? decimalOrNull(String key) => _asDouble(this[key]);

  bool flag(String key, [bool fallback = false]) {
    final Object? value = this[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  DateTime? date(String key) => _asDate(this[key]);

  DateTime dateOr(String key, DateTime fallback) => _asDate(this[key]) ?? fallback;

  Map<String, dynamic> object(String key) {
    final Object? value = this[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  /// A nested object that is `null` in the payload stays `null` rather than
  /// being flattened into an empty map, so callers can tell "absent" apart.
  Map<String, dynamic>? objectOrNull(String key) {
    final Object? value = this[key];
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  List<Map<String, dynamic>> objects(String key) {
    final Object? value = this[key];
    if (value is! List) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final Object? item in value)
        if (item is Map) item.cast<String, dynamic>(),
    ];
  }

  List<String> strings(String key) {
    final Object? value = this[key];
    if (value is! List) return const <String>[];
    return <String>[
      for (final Object? item in value)
        if (item != null) item is String ? item : item.toString(),
    ];
  }

  List<int> integers(String key) {
    final Object? value = this[key];
    if (value is! List) return const <int>[];
    return <int>[
      for (final Object? item in value)
        if (_asInt(item) case final int parsed) parsed,
    ];
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) return value;
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// Builds a `Map<String, dynamic>` skipping null values, so optional request
/// fields are omitted rather than sent as `null`.
Map<String, dynamic> jsonBody(
  Map<String, dynamic> values, {
  Set<String> nulls = const <String>{},
}) {
  final Map<String, dynamic> body = <String, dynamic>{};
  values.forEach((String key, Object? value) {
    if (value == null) {
      if (nulls.contains(key)) body[key] = null;
      return;
    }
    body[key] = value;
  });
  return body;
}
